/*
# Copyright (c) 2008-2010 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any warranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.
#
*/

package com.rpath.xobj
{

// BASED ON ORIGINAL CODE IN ADOBE'S SimpleXMLDecoder

////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2005-2007 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////


/*

TODO: refactor all the __elements and __attributes structures into an _xobj
structure

TODO: Check mapping to primitive type (int) slots

TODO: fix handling of arrays of simpleTypes that need to be locally typemapped

TODO: add __namespaces to the _xobj structure

TODO: keep track of the element qname we (de)coded something with in the _xobj

TODO: add some kind of "Type mapping" memory to the _xobj structure.

TODO: explore looking up XMLSchema types using simple parsing ?
*/

import com.adobe.utils.DateUtil;

import flash.utils.Dictionary;
import flash.utils.getQualifiedClassName;
import flash.xml.XMLDocument;
import flash.xml.XMLNode;
import flash.xml.XMLNodeType;

import mx.collections.ICollectionView;
import mx.collections.IList;
import mx.collections.ListCollectionView;
import mx.rpc.xml.*;
import mx.utils.ObjectProxy;


/**
 * The TypedXMLDecoder class deserializes XML into a graph of ActionScript objects
 * that can be strongly typed based on a provided typeMapping. This is done without
 * first converting the XML to a graph of "plain old Objects" the way the 
 * Adobe standard SimpleXMLDecoder does.
 * 
 * It also attempts to preserve key information related to any XMLSchema in use
 * without being an XMLSchema driven decoder. Specifically, it seeks to preserve
 * namespaces in use, the ordering of elements the distinction
 * between elements and attributes present in the XML so that subsequent re-encoding
 * of the object graph will preserve those characteristics.
 * 
 * The objects created can be of any ActionScript type, provided that they are 
 * dynamic. The dynamic requirement is due to two key behaviors of this decoder
 * 
 * 1/ Any elements and attributes encountered in the XML will be added as dyanmic
 * properties to the unmarshalled instances
 * 
 * 2/ The preservation of namespaces, element ordering and attributes requires
 * the addition of an _xobj metadata structure to each unmarshalled instance.
 * 
 * Further work could be done to eliminate this requirement by requiring any Type
 * mapped to support an IXObj interface that would provide methods for metadata
 * maintenance and the addition of properties.
 * 
 * As the decoder walks the XML, elements are mapped to AS3 Types via a typeMapping
 * dictionary. This dictionary is passed into the constructor of this class
 * allowing each instance of TypedXMLDecoder to be reused for decoding multiple
 * documents with the same desired mapping.
 * 
 * Note that you do not need to provide an entry for every possible element->Type 
 * mapping, but rather only for the root elements you expect or for any elements you
 * specifically want to type. The decoder will introspect the unmarshalled instance
 * type to determine the intended type of any subelements *and this introspection
 * will override any explicit mapping you provide*. i.e. your coded types win
 * 
 * In the absence of introspective type information, the typeMap will be consulted.
 * 
 * In the absence of a typeMap entry, a plain Object (or ObejctProxy) will be created
 * depending on the setting of the makeObjectBindable constructor option.
 * 
 * 
 * Private methods of this class have been declared protected rather than private
 * to leave the dooor open for extension by subclassing.
 */


public class XObjXMLDecoder
{
    
    public var typeMap:* = {};
    
    public var namespaceMap:Dictionary = new Dictionary();
    public var spacenameMap:Dictionary = new Dictionary();
    
    //--------------------------------------------------------------------------
    //
    //  Class Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     *  @private
     * 
     * This method is marked public so that the ComplexString type can use it
     */
    public static function simpleType(val:Object, resultType:Class=null):Object
    {
        var result:Object = val;
        
        if (val != null)
        {
            var testNum:Number = Number(val);
            var valStr:String = val.toString();
            var lowerVal:String  = val.toString().toLowerCase();
            
            //return the value as a string, a boolean or a number.
            //numbers that start with 0 are left as strings
            //ForceObject removed since we'll take care of converting to a String or Number object later
            // make sure to check if String here so "1.0" is a String, not the number 1 (RBL-4931)
            if ((val is String) && ((String(val) == "") || (resultType == String)))
            {
                result = valStr;    
            }
            else if (lowerVal == "true")
            {
                result = true;
            }
            else if (lowerVal == "false")
            {
                result = false;
            }
            else if (resultType == int)
            {
                result = Number(val);
            }
            else if (resultType == Number)
            {
                result = Number(val);
            }
            else if (!isFinite(testNum) || isNaN(testNum)
                || (val.charAt(0) == '0') // starts with a leading zero
                || ((val.charAt(0) == '-') && (val.charAt(1) == '0')) // starts with -0
                || lowerVal.charAt(lowerVal.length -1) == 'e') // TODO: wtf?
            {
                result = valStr;
            }
            else
            {
                result = Number(val);
            }
        }
        else if (val == "")
        {
            // do something with NULL values?
            var foo:String = "bar";
        }
        
        return result;
    }
    
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Constructor.
     * 
     * typeMap should be of the form { element_tag : AS3 Type, ... } 
     * 
     * e.g. 
     * 
     *      {   image: com.rpath.catalog.VirtualImage, 
     *          cloud: com.rpath.catalog.Cloud }
     * 
     * 
     */
    public function XObjXMLDecoder(typeMap:* = null, nmMap:* = null,
                                   makeObjectsBindable:Boolean = false,
                                   makeAttributesMeta:Boolean = false,
                                   defer:Boolean=false,
                                   objectFactory:IXObjFactory=null,
                                   ignoreWhitespace:Boolean=false)
    {
        super();
        
        if (!ignoreWhitespace)
        {
            XML.ignoreWhitespace = false;
            XML.prettyPrinting = false;
        }
        
        this.typeMap = typeMap;
        
        for (var prefix:String in nmMap)
        {
            namespaceMap[nmMap[prefix]] = prefix;
            spacenameMap[prefix] = nmMap[prefix];
        }
        
        this.makeObjectsBindable = makeObjectsBindable;
        this.makeAttributesMeta = makeAttributesMeta;
        this.deferred = defer;
        
        if (objectFactory == null)
        {
            objectFactory = new XObjDefaultFactory();
        }
        
        this.objectFactory = objectFactory;
    }
    
    public var deferred:Boolean;
    
    public var objectFactory:IXObjFactory;
    
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     *  Converts a tree of XMLNodes into a tree of ActionScript Objects.
     *
     *  @param dataNode An XMLNode to be converted into a tree of ActionScript Objects.
     *
     *  @return A tree of ActionScript Objects.
     */
    public function decodeXML(dataNode:XMLNode, propType:Class = null):Object
    {
        if (!deferred)
            return actualDecodeXML(dataNode, propType);
        else
            return new XObjDeferredDecode(this, dataNode, propType);
    }
    
    public function decodeXMLIntoObject(dataNode:XMLNode, rootObject:Object):Object
    {
        if (!rootObject)
            return null;
        
        if (!deferred)
            return actualDecodeXML(dataNode, null, rootObject);
        else
            return new XObjDeferredDecode(this, dataNode, null, rootObject);
    }
    
    /**
     * 
     * actualDecodeXML is the workhorse function that does the heavy lifting of 
     * decoding a given XMLNode
     * 
     * In addition to the node, the caller can pass an optional propertyType
     * that specifies what data type the node should be decoded as.
     * 
     * If propType is null, various heuristics, including a typeMap lookup
     * are used to infer the desired type.
     * 
     * memberClass allows you to dictate what type should be used for decoded
     * child elements if not otherwise computable from result properties
     * 
     */
    
    public function actualDecodeXML(dataNode:XMLNode, expectedResultClass:Class = null, 
                                    rootObject:* = null, isRootNode:Boolean = false, 
                                    memberClass:Class = null):Object
    {
        var result:*;
        var isNullObject:Boolean;
        var isSimpleType:Boolean = false;
        var shouldMakeBindable:Boolean = false;
        var isTypedProperty:Boolean = false;
        var isSpecifiedType:Boolean = false;
        var elementSet:Array = [];
        var attributeSet:Array = [];
        var nextNodeIsRoot:Boolean = false;
        var doneRootDupe:Boolean = false;
        var resultClass:Class;
        
        if (dataNode == null)
            return null;
        
        if (dataNode is XMLDocument)
            nextNodeIsRoot = true;
        
        // does the node have an id? If so, we may already know this object
        // for example, doing a GET into a previously fetched instance
        var resultID:String = getIDAttr(dataNode);
        
        // see whether we alreadyhave an object with this IDif (resultID)
        var existingObj:Object;
        if (resultID)
        {
            existingObj = objectFactory.getObjectForId(resultID);
        }
        
        /* figure out what type the result object should be.
        
        1. did the caller pass in an object to populate via rootObject?
        2. do we have the object already by ID?
        3. was a particular type specified by the caller?
        4. is there a typeMap entry for the object?
        
        */
        // flag to track whether we were told or not
        isSpecifiedType = rootObject || expectedResultClass;
        
        if (rootObject && !nextNodeIsRoot)
        {
            result = rootObject;
            // also track the ID we got, if any, since this may have been a POST
            if (existingObj)
            {
                if (existingObj != result)
                {
                    // hmmm. mismatched objects ???
                    trace("mismatched objects for ID "+resultID);
                }
            }
            else // no old obj
            {
                objectFactory.trackObjectById(result, resultID);
            }
        }
        else
        {
            // use if if we have it
            result = existingObj;
        }
        
        // now look up type info if available
        if (result)
        {
            resultClass = XObjUtils.getClass(result);
            // assume we should NEVER make specified types bindable
            shouldMakeBindable = false;
        }
        else // otherwise, we need to create a new result object
        {
            // was a type specified?
            if (expectedResultClass)
            {
                // use what was asked for
                resultClass = expectedResultClass;
                // assume we should NEVER make specified types bindable
                shouldMakeBindable = false;
            }
            else
            {
                // is there a typeMap entry for this element?
                var nodeType:Class = typeForTag(dataNode.nodeName);
                
                if (nodeType)
                {
                    resultClass = nodeType;
                    // assume we should NEVER make specified types bindable
                    shouldMakeBindable = false;
                }
                else
                {
                    // go with plain object, and allow bindable flag to kick in
                    resultClass = Object;
                }
            }
        }
        
        if (!result)
        {
            // finally, create the right kind of result object via whatever
            // factory we were given
            result = objectFactory.newObject(resultClass, resultID);
            
            if (result == null)
            {
                throw new Error("Cannot determine which object type to instantiate");
            }
        }
        
        // so what type did we eventually use?
        var resultTypeName:String = getQualifiedClassName(result);
        
        // TODO: pass these in from caller, since we already know them up
        // there
        var isCollection:Boolean = false;
        var isArray:Boolean = false;
        
        if (XObjUtils.isArray(result))
        {
            isArray = true;
        }
        else if (XObjUtils.isCollection(result))
        {
            isCollection = true;
            try
            {
                result.disableAutoUpdate();
            }
            catch (e:ReferenceError)
            {
            }
        }
        
        // If we're the root object (and a collection)
        // OR this collection is NOT byReference (i.e. it's embedded)
        // then FLUSH the array/collection to ensure uniqueness of results
        
        // TODO: consider role of [xobjByReference] metadata tag on parent
        // object to detemrine isByReference in this case. QuerySet is a 
        // good case study in why this may be more consistent
        
        if (isRootNode || !XObjUtils.isByReference(result))
        {
            if (isArray && (result as Array).length > 0)
            {
                //trace("flushing array");
                (result as Array).splice(0);
            }
            else if (isCollection && (result as IList).length > 0)
            {
                //trace("flushing collection");
                (result as IList).removeAll();
            }
        }
        
        // Now start looking at the child XML nodes
        
        var children:Array = dataNode.childNodes;
        
        // track whether we actually have any values at all
        isNullObject = true;
        
        // OK. Now we're ready to decode some actual data!
        if ((children.length == 1) && (children[0].nodeType == XMLNodeType.TEXT_NODE))
        {
            isNullObject = false;
            
            var temp:* = XObjXMLDecoder.simpleType(children[0].nodeValue, resultClass);
            if (!isSpecifiedType
                || (result is String)
                || (result is int) 
                || (result is Number) 
                || (result is Boolean))
            {
                isSimpleType = true;
                result = temp;
            }
            else
            {
                try
                {
                    if (result is IXObjHref)
                    {
                        result.value = temp;
                    }
                    else if (result is Date)
                    {
                        try
                        {
                            result = parseRPATHWHACKYDATETIME(temp);
                        }
                        catch (e:Error)
                        {
                            try
                            {
                                result = DateUtil.parseW3CDTF(temp);
                            }
                            catch (e:Error)
                            {
                                try
                                {
                                    result = DateUtil.parseRFC822(temp);
                                }
                                catch (e:Error)
                                {
                                    result = new Date();
                                    result.time = Date.parse(temp);
                                }
                            }
                        }
                    }
                    else
                        result.value = temp;
                }
                catch (e:Error)
                {
                    // give up
                }
            }
            
        }
        else 
        {
            if (children.length > 0 && !(result is XML))
            {
                var seenProperties:Dictionary = new Dictionary();
                var lastPartName:Object = {qname: null, propname: null};
                // loop through all children. TODO: break this into async slices 
                // as we did with FilterIndex creation and maintenance?
                
                for (var i:uint = 0; i < children.length; i++)
                {
                    var partNode:XMLNode = children[i];
                    var typeInfo:XObjTypeInfo = null;
                    var partClass:Class = null;
                    var partClassName:String = null;
                    var nextCollClass:Class = null;
                    var isMember:Boolean;
                    var partID:String
                    var partQName:XObjQName;
                    var elementName:*;
                    // assume elementName maps directly to propertyName for now
                    var propertyName:*;
                    var propertyIsArray:Boolean
                    var propertyIsCollection:Boolean;
                    var partObj:*;
                    
                    // skip text nodes, which are part of mixed content
                    if (partNode.nodeType != XMLNodeType.ELEMENT_NODE)
                    {
                        continue;
                    }
                    
                    isNullObject = false;
                    partID = getIDAttr(partNode);
                    
                    // Step 1: 
                    // figure out the name of the element and thus, the propertyName
                    // to use
                    partQName = new XObjQName(partNode.namespaceURI, XObjUtils.getNCName(partNode.nodeName));
                    
                    // TODO: allow type map entries to be full QNames, not just local names
                    elementName = decodePartName(partQName, partNode);
                    
                    // assume elementName maps directly to propertyName for now
                    propertyName = elementName;
                    propertyIsArray = false;
                    propertyIsCollection = false;
                    
                    // record the order we see the elements in for encoding purposes
                    // this is an attempt to "fake" XMLSchema sequence constraint of
                    // ordered elements. Collapse sequenced repetitions to a single entry
                    if (!XObjQName.equal(partQName,lastPartName.qname))
                    {
                        lastPartName = {};
                        lastPartName.qname = partQName;
                        elementSet.push(lastPartName);
                    }
                    
                    lastPartName.propname = propertyName;
                    
                    // Step 2: check if we have an existing part object to reuse
                    // (the case where we're reading into an existing object, 
                    // or where objects create complex members at construction time)
                    
                    // assume we need a new part instance
                    partObj = null;
                    
                    // now, do we already know this object?
                    partObj = objectFactory.getObjectForId(partID);
                    
                    // Get part type information
                    
                    // look up characteristics of the result.propertyName type
                    typeInfo = XObjUtils.typeInfoForProperty(result, resultTypeName, propertyName);
                    partClass = typeInfo.type;
                    partClassName = typeInfo.typeName;
                    propertyIsArray = typeInfo.isArray;
                    propertyIsCollection = typeInfo.isCollection;
                    isMember = typeInfo.isMember;
                    
                    // make sure we can pass on an [ArrayElementType()] metadata
                    // we observe on this property (which will not be visible
                    // to recursive calls)
                    nextCollClass = typeInfo.arrayElementClass;
                    
                    // now, should we decode into a new object, or decode into an existing instance?
                    if (rootObject && nextNodeIsRoot)
                    {
                        // we're about to read the root element
                        partObj = rootObject;
                        partClass = XObjUtils.getClass(partObj);
                        partClassName = XObjUtils.getClassName(partObj);
                    }
                        // else should we reuse an existing property object?
                        // NOTE: do not reuse if this is an implied array 
                        // (hence seenProperties test)
                    else if (!seenProperties[propertyName]
                        && result.hasOwnProperty(propertyName))
                    {
                        var existing:* = result[propertyName];
                        
                        // we do not want to reuse simple objects
                        if (existing && (existing is Object)
                            && !(
                                //(existing is Array) 
                                //|| (existing is ICollectionView)
                                //||
                                (existing is String)
                                || (existing is Boolean)
                                || (existing is int)
                                || (existing is Number)
                                || (existing is Date)
                            )
                        )
                        {
                            // reuse any complex objects provided we don't have
                            // an ID conflict
                            if (partID)
                            {
                                var existingByID:* = objectFactory.getObjectForId(partID);
                                if (!existingByID)
                                {
                                    partObj = existing;
                                    partID = getIDProperty(partObj);
                                    if (partID)
                                    {
                                        // register it!
                                        objectFactory.trackObjectById(partObj, partID);
                                    }
                                }
                                else if (existing === existingByID)
                                {
                                    partObj = existing;
                                }
                                else if (existing != existingByID)
                                {
                                    // ID conflict. Use OLD object!
                                    partObj = existingByID;
                                    
                                    // hack to support RESTHref pointing to real object
                                    // related to RBL-8840 where we dropped version and stage
                                    // since href points to already fetched actual object
                                    // basically, <stage href="..">name</stage> is BAD form
                                    // for partial object pointers (named pointers? ewww)
                                    
                                    if (existing is IXObjHref)
                                    {
                                        try
                                        {
                                            existing.value = existingByID.name;
                                            //existing.referenced = existingByID;
                                        }
                                        catch (e:Error)
                                        {
                                            // can't pull that swizzle here
                                        }
                                    }
                                }
                            }
                            else // node has no ID, so use whatever we get
                            {
                                partObj = existing;
                                partID = getIDProperty(partObj);
                                if (partID)
                                {
                                    // register it!
                                    objectFactory.trackObjectById(partObj, partID);
                                }
                            }
                            
                            // use whatever class info we were given
                            if (partObj)
                            {
                                partClass = XObjUtils.getClass(partObj);
                                partClassName = XObjUtils.getClassName(partObj);
                            }
                        }
                        else
                        {
                            // we have the property, but no value.
                            // NB: ObjectProxy always says yes to hasOwnProperty()
                            if (!partClass && !(result is ObjectProxy))
                            {
                                // must be plain old Object, but our TypeInfo
                                // method ignores them...compensate
                                partClass = Object;
                            }
                        }
                    }
                    
                    
                    // Step 3: 
                    // decide what partClass to use if we don't already know
                    // from the above
                    
                    // OK. so is this actually a known property? Array elements
                    // will be uknown property names by definition (have to be
                    // so since a collection property that matched an element would be 
                    // assigned to the property, not made a member of the 
                    // collection)
                    
                    if (!partObj && !partClass)
                    {
                        // important: are we *in* an generic array or collection object?
                        
                        if (!(result is IXObjCollection)
                            && (isArray || isCollection))
                        {
                            // we need to handle collection type objects with special care
                            // since if the element doesn't map to a property, it's a member
                            
                            isMember = true;
                        }
                        else
                        {
                            // treat as regular property of our result object
                        }
                    }
                    
                    if (isMember)
                    {
                        // we were told what type to use on the way in?
                        if (memberClass)  
                        {
                            // parent object determined type for us. let it trump
                            partClass = memberClass;
                        }
                        
                    }
                    
                    if (!partClass)
                    {
                        // if we're an xobj ref, it's supposed to be able to tell
                        // us what types to use for members
                        var xobjRef:IXObjReference = result as IXObjReference;
                        
                        // XObjRefs can tell us their desired member types
                        if (xobjRef)
                        {
                            // ask the IXObjReference for the type it wants to use
                            partClass = xobjRef.elementTypeForElementName(elementName);
                        }
                    }
                    
                    if (!partClass)
                    {
                        // if we still don't know, fall all the way back to global
                        // typemap
                        partClass = typeForTag(elementName);
                    }
                    
                    // now, is the property we're about to decode itself an array
                    // or a collection?
                    if (propertyIsArray || propertyIsCollection)
                    {
                        // there's a "collapsed" subcase here to handle...
                        
                        if (nextCollClass && typeForTag(elementName) == nextCollClass)
                        {
                            // this is a pathological case that requires us to
                            // 'jump' the partClass to be the element type
                            // of this nested array...
                            partClass = nextCollClass;
                            nextCollClass = null;
                            partObj = null; // force new instance to be created
                        }
                    }
                    else
                    {
                        // firstly, auto-promote to array for unknown repeated elements in XML
                        // if we've seen this property before, force it to be an array
                        
                        if (seenProperties[propertyName])
                        {
                            try
                            {
                                if (!((result[propertyName] is Array) || (result[propertyName] is ListCollectionView)))
                                {
                                    if (shouldMakeBindable)
                                    {
                                        result[propertyName] = objectFactory.newCollectionFrom(result[propertyName]);
                                    }
                                    else
                                    {
                                        try
                                        {
                                            result[propertyName] = [result[propertyName]];
                                        }
                                        catch (e:TypeError)
                                        {
                                            if (e.errorID == 1034)
                                            {// must be a non-array thingy. IGNORE
                                                //trace("Ignoring TypeError on promote to Array on" + propertyName);
                                            }
                                            else
                                                throw e;
                                            
                                        }
                                    }
                                }
                                partObj = null; // we need a fresh object next element
                                propertyIsArray = true;
                            }
                            catch (e:ReferenceError)
                            {
                                trace("Property "+propertyName+" not found on "+ XObjUtils.getClassName(result) +". Check dynamic or missing prop");
                            }
                        }
                    }
                    
                    // now finally, decode the part itself, using the type information
                    // and possibly, the existing partObj to decode into
                    partObj = actualDecodeXML(partNode, partClass, partObj, nextNodeIsRoot, nextCollClass);
                    
                    // and assign the result property based on array characteristics
                    if (isMember)
                    {
                        result = assignToArray(result, propertyName, partObj, false, propertyIsArray, propertyIsCollection, shouldMakeBindable);
                    }
                    else
                    {
                        result = assignToProperty(result, propertyName, partObj, false, propertyIsArray, propertyIsCollection, shouldMakeBindable);
                        // and track possible repeated elements
                        seenProperties[propertyName] = true;
                        
                        // we don't want any props on raw arrays to be 
                        // part of iterating the array members...
                        if (isArray )
                        {
                            // TODO: figure out the clean way to do this. namespace?
                            // result.setPropertyIsEnumerable(propertyName, false);
                        }        
                    }
                    
                    // should we keep an extra, well-known ref to the object?
                    if (nextNodeIsRoot && !doneRootDupe)
                    {
                        result = assignToProperty(result, "root", partObj, false, propertyIsArray, propertyIsCollection, shouldMakeBindable);
                        doneRootDupe = true;
                    }
                    
                    nextNodeIsRoot = false; // don't use root twice!
                }
            }
            else if (children.length > 0 && (result is XML))
            {
                var tempXML:XML;
                
                // XML needs special handling as "embedded" XML
                isNullObject = false;
                
                if (children.length > 1)
                {
                    // if there's more than one child, use the element *itself* 
                    // as the root node. This will preserve any attributes on it
                    tempXML = new XML(dataNode);
                }
                else
                {
                    // otherwise, grab the first child as the root
                    tempXML = new XML((children[0] as XMLNode).toString());
                }
                
                isSimpleType = false;
                result = tempXML;
            }
            else if (children.length == 0)
            {
                // empty node
            }
        }
        
        // and turn on change events again once we're done
        if (isCollection)
        {
            try
            {
                result.enableAutoUpdate();
            }
            catch (e:ReferenceError)
            {
            }
        }
        
        // Cycle through the attributes
        var attributes:Object = dataNode.attributes;
        for (var attribute:String in attributes)
        {
            
            // result can be null if it contains no children.
            if (result == null)
            {
                result = new XObjString();
                isSimpleType = false;
            }
                // If result is not currently an Object (it is a Number, Boolean,
                // or String), or if the object is empty but has attrs
                // and is of literal type Object (not a typed entity)
                // then convert it to be an XObjString so that we
                // can attach attributes to it.  (See comment in XObjString.as)
            else if (isSimpleType && !(result is XObjString))
            {
                result = new XObjString(result.toString());
                isSimpleType = false;
            }
            
            isNullObject = false;
            
            var attrObj:* = decodeAttrName(attribute, dataNode);
            
            // track the list of attrs so we can decode them later
            
            attributeSet.push(attrObj);
            
            var attrName:String = attrObj.propname;
            
            var attr:* = XObjXMLDecoder.simpleType(attributes[attribute], resultClass);
            
            if (makeAttributesMeta)
            {
                try
                {
                    if (!("attributes" in result))
                        result.attributes = {};
                    result.attributes[attrName] = attr;
                }
                catch (e:Error)
                {
                    // probably not a dynamic class. Throw away the attributes...
                    
                }
            }
            else
            {
                try
                {
                    result[attrName] = attr;
                    if (isArray)
                    {
                        // TODO: figure out the clean way to do this. namespaces?
                        //result.setPropertyIsEnumerable(attrName, false);
                    }
                }
                catch (e:TypeError)
                {
                    if ((result[attrName] is IXObjHref)
                        && (attr is String))
                    {
                        result[attrName].id = attr;
                    }
                    else 
                        throw e;
                }
                catch (e:Error)
                {
                    //throw new Error("Failed to set attribute "+attrName+"("+attr+") on "+resultTypeName+". Check that class is dynamic or attribute name is spelled correctly");
                    trace("Failed to set attribute "+attrName+"("+attr+") on "+resultTypeName+". Check that class is dynamic or attribute name is spelled correctly");
                }
            }
            
        }
        
        // finally, did we build a new untyped object with a single property named 'item'
        // which is the magic sentinal SimpleXMLEncoder seems to use?
        
        if (!isSpecifiedType)
        {
            var count:int;
            
            for (var p:String in result)
            {
                count++;
                if (count > 1)
                    break;
            }
            
            if (count == 1)
            {
                if ( elementName == "item")
                    result = result[p];
            }
        }
        
        // track the set of attributes we added, if any
        if (attributeSet.length > 0)
            XObjMetadata.setAttributes(result, attributeSet);
        
        // stash the order of elements on the result as hidden metadata
        if (elementSet.length > 0)
            XObjMetadata.setElements(result, elementSet);
        
        // so did we actually do anything to the object?
        if (isNullObject)
            result = null;
        
        // and finally, give the object a chance to process commitProperties()
        // if it is IInvalidationAware
        if (result is IInvalidationAware)
        {
            (result as IInvalidationAware).invalidateProperties();
        }
        
        
        // Last question, should we make this bindable?
        shouldMakeBindable = 
            (makeObjectsBindable 
                && (nodeType == Object)
                && !(result is ObjectProxy)
                && (resultClass != String));
        
        if (result && shouldMakeBindable)
        {                
            result = new ObjectProxy(result);
        }
        
        return result;
    }
    
    private function assignToProperty(result:*, propName:String, value:*,
                                      seenBefore:Boolean, makeArray:Boolean, makeCollection:Boolean, makeBindable:Boolean):*
    {
        // don't put nulls into arrays or collections.
        // skip if result empty
        if (result == null 
            || ((makeArray || makeCollection) && (value == null)))
            return result;
        
        // are we reusing an existing property value?
        if (result.hasOwnProperty(propName) && result[propName] === value)
            return result;
        
        if (makeArray || makeCollection)
        {
            var existing:* = result[propName];
            
            if (existing == null)
            {
                if (makeCollection)
                {
                    if (value is ICollectionView)
                    {
                        // use the new one after all
                        existing = value;
                    }
                    else
                    {
                        existing = objectFactory.newCollectionFrom([]);
                        if (!(value is Array) && !(value is ListCollectionView))
                        {
                            (existing as ListCollectionView).addItem(value);
                        }
                        else
                        {
                            value = toCollection(value);
                            for each (var v:* in value)
                            {
                                (existing as ListCollectionView).addItem(v);
                            }
                        }
                    }
                }
                else if (makeArray)
                {
                    if (value is Array)
                    {
                        // use the new one after all
                        existing = value;
                    }
                    else
                    {
                        if (value is Array)
                            existing = value;
                        else
                            existing = [value];
                    }
                }
            }
            else if (existing is Array)
            {
                /*if (!seenBefore)
                {
                (existing as Array).splice(0);
                }*/
                XObjUtils.addItemIfAbsent(existing, value);
            }
            else if (existing is ListCollectionView || existing is IXObjCollection)
            {
                /*if (!seenBefore)
                {
                existing.removeAll();
                }*/
                
                if (!(value is Array) && !(value is ListCollectionView)
                    && !(value is IXObjCollection))
                {
                    XObjUtils.addItemIfAbsent(existing, value);
                }
                else
                {
                    // are they type equivalent?
                    if (value is XObjUtils.classOf(existing))
                    {
                        // use the new collection, repalcing the old
                        existing = value;
                    }
                    else
                    {
                        value = toCollection(value);
                        for each (var v1:* in value)
                        {
                            XObjUtils.addItemIfAbsent(existing, v1);
                        }
                    }
                }
            }
            else
            {
                if (!seenBefore)
                {
                    // throw away old, (non decoded) value
                    if (makeCollection)
                    {
                        existing = objectFactory.newCollectionFrom([]);
                    }
                    else
                    {
                        existing = [];
                    }
                }
                else
                {
                    // keep whatever is there now, but promote
                    if (makeCollection)
                    {
                        existing = objectFactory.newCollectionFrom([existing]);
                    }
                    else
                    {
                        existing = [existing];
                    }
                }
                
                if (makeCollection)
                {
                    if (!(value is Array) && !(value is ListCollectionView))
                    {
                        (existing as ListCollectionView).addItem(value);
                    }
                    else
                    {
                        value = toCollection(value);
                        for each (var v2:* in value)
                        {
                            (existing as ListCollectionView).addItem(v2);
                        }
                    }
                }
                else
                {
                    (existing as Array).push(value);
                }
            }
            
            if ((makeCollection || makeBindable) && !(existing is ListCollectionView))
                existing = objectFactory.newCollectionFrom(existing as Array);
            
            value = existing;
        }
        
        try
        {
            // are we just being asked to point at something?
            if ((result[propName] is IXObjHref) && !(value is IXObjHref))
                (result[propName] as IXObjHref).href = getIDProperty(value);
            else
                result[propName] = value;
        }
        catch (e:ReferenceError)
        {
            //throw new Error("Failed to set property "+propName+"("+value+") on "+ XObjUtils.getClassName(result)+". Check that class is dynamic or property name is spelled correctly");
            trace("Failed to set property "+propName+"("+value+") on "+ XObjUtils.getClassName(result)+". Check that class is dynamic or property name is spelled correctly");
        }
        
        return result;
    }
    
    private function assignToArray(result:*, propName:String, value:*,
                                   seenBefore:Boolean, makeArray:Boolean, makeCollection:Boolean, makeBindable:Boolean):*
    {
        if (result == null)
            return result;
        
        if (result is Array)
        {
            /*if (!seenBefore)
            {
            (result as Array).splice(0);
            }*/
            XObjUtils.addItemIfAbsent(result, value);
        }
        else if (result is ListCollectionView || result is IXObjCollection)
        {
            /*if (!seenBefore)
            {
            result.removeAll();
            }*/
            XObjUtils.addItemIfAbsent(result, value);
        }
        
        return result;
    }
    
    
    
    private function typeForTag(tag:String):Class
    {
        if (!typeMap || !tag)
            return null;
        
        // find the corresponding type in the map
        var typeName:* = typeMap[tag];
        
        if (typeName)
        {
            if (typeName is Class)
                return typeName;
                
            else if (typeName is String)
            {
                var type:Class = XObjUtils.getClassByName(typeName);
                
                if (type)
                    return type;
            }
        }
        
        return null;
    }
    
    public function getLocalPrefixForNamespace(uri:String, node:XMLNode):String
    {
        var prefix:String;
        
        prefix = namespaceMap[uri];
        if (!prefix)
        {
            prefix = XObjUtils.safeGetPrefixForNamespace(node, uri);
        }
        else if (prefix == XObjUtils.DEFAULT_NAMESPACE_PREFIX)
        {
            prefix = "";
        }
        return prefix;
    }
    
    
    public function decodePartName(partQName:XObjQName, node:XMLNode):String
    {
        var partName:String = XObjUtils.getNCName(partQName.localName);
        
        var prefix:String = getLocalPrefixForNamespace(partQName.uri, node);
        
        if (prefix == null || prefix == "")
        {
            // implied default namespace
            partName =  partName;
        }
        else
        {
            partName =  prefix + "_" + partName;
        }
        
        return partName;
    }
    
    
    public function decodeAttrName(name:String, node:XMLNode):*
    {
        // we need to map ovf:msgid to a local prefix
        var parts:Array = name.split(":");
        if (parts[0] == "xmlns")
        {
            // special case these.
            name =  name.replace(/:/,"_");
        }
        else
        {
            var ns:String = node.getNamespaceForPrefix(parts[0]);
            if (ns == null)
            {
                // this tells us we "topped out" and can't resolve the ns
                name = name.replace(/:/,"_");
            }
            else
            {
                var qname:XObjQName = new XObjQName(ns, parts[1]);
                name = decodePartName(qname, node);
            }
        }
        
        return {qname: qname, propname: name};
    }
    
    public function toCollection(v:*):ListCollectionView
    {
        if (v is ListCollectionView)
            return v;
        else if (v is Array)
            return objectFactory.newCollectionFrom(v);
        else
            return objectFactory.newCollectionFrom([v]);
    }
    
    private var makeObjectsBindable:Boolean;
    private var makeAttributesMeta:Boolean;
    
    private function getIDAttr(part:XMLNode):String
    {
        if (!part)
            return null;
        
        if ("id" in part.attributes)
            return part.attributes["id"];
        else if ("href" in part.attributes)
            return part.attributes["href"];
        
        return null;
    }
    
    private function getIDProperty(part:Object):String
    {
        if (!part)
            return null;
        
        if ("id" in part)
            return part["id"];
        else if ("href" in part)
            return part["href"];
        
        return null;
    }
    
    /** whacky rPath datetime format which is ISO8601 with the 
     * required 'T' element replaced with a SPACE
     */
    
    public function parseRPATHWHACKYDATETIME(str:String):Date
    {
        var newStr:String = str.replace(" ","T");
        
        return DateUtil.parseW3CDTF(newStr);
    }

}

}