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

TODO: Check mapping to primitive type (int) slots

TODO: fix handling of arrays of simpleTypes that need to be locally typemapped

TODO: add namespaces to the _xobj structure

TODO: keep track of the element qname we (de)coded something with in the _xobj

TODO: add some kind of "Type mapping" memory to the _xobj structure.

TODO: explore looking up XMLSchema types using simple parsing ?
*/

import flash.utils.Dictionary;
import flash.utils.getQualifiedClassName;
import flash.xml.XMLNodeType;

import mx.collections.ArrayCollection;
import mx.collections.ICollectionView;
import mx.collections.IList;
import mx.collections.ListCollectionView;
import mx.rpc.xml.*;
import mx.utils.ObjectProxy;

use namespace xobj;

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
 * The objects created can be of any ActionScript type.
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
    public static var useStaticDecoders:Boolean = true;
    
    public var objectFactory:IXObjFactory;
    
    public var typeMap:* = {};
    
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

    // PRIMARY INTERFACES
    
    /**
     *  Converts a tree of XMLLists into a tree of ActionScript Objects.
     *
     *  @param dataNode An XMLList to be converted into a tree of ActionScript Objects.
     *
     *  @return A tree of ActionScript Objects.
     */
    public function decodeXML(dataNode:XML, propType:Class = null):Object
    {
        if (!deferred)
            return actualDecodeXML(dataNode, propType, null, true);
        else
            return new XObjDeferredDecode(this, dataNode, propType);
    }
    
    public function decodeRawXML(xml:XML, propType:Class = null):Object
    {
        return decodeXML(xml, propType);
    }
    
    public function decodeRawXMLInto(xml:XML, rootObject:Object):Object
    {
        return decodeXMLIntoObject(xml, rootObject);
    }
    
    public function decodeXMLIntoObject(dataNode:XML, rootObject:Object):Object
    {
        if (!rootObject)
            return null;
        
        if (!deferred)
            return actualDecodeXML(dataNode, null, rootObject, true);
        else
            return new XObjDeferredDecode(this, dataNode, null, rootObject);
    }

    // STATIC DECODER SUPPORT FUNCTIONS
    
    /** decodePart() allows for a static decoder to request that one of its
    * member elements (typically, a subobject) be decoded
    */
    
    public function decodePart(xml:Object, result:Object, resultClass:Class=null, info:XObjDecoderInfo=null, isArray:Boolean=false, isCollection:Boolean=false, shouldMakeBindable:Boolean=false):*
    {
        if (!xml)
            return null;
        if (xml is XMLList)
            xml = (xml as XMLList)[0];
        
        return xobj::actualDecodeXML(xml as XML, resultClass, result, false, info);
    }
    
    /** decodeArray() allows for a static decoder to request that one of its
     * member elements which is an array of objects be decoded
     */

    public function decodeArray(xml:Object, result:Object=null, resultClass:Class=null, memberClass:Class=null, info:XObjDecoderInfo=null, shouldMakeBindable:Boolean=false):*
    {
        if (xml is XMLList)
            xml = (xml as XMLList)[0];
        
        if (!info)
        {
            info = new XObjDecoderInfo();
        }
        
        info.resultClass = resultClass;
        info.memberClass = memberClass;
        
        return xobj::actualDecodeXML(xml as XML, info.resultClass, result, false, info);
    }
    
    /** decodeCollection() allows a static decoder to request the xobj machinery
     * reflectively decode a collection. Provides all the support for "identified
     * collections" (those with an id) and proper type mapping, etc.
     */
    
    public function decodeCollection(xml:Object, result:Object=null, resultClass:Class=null, memberClass:Class=null, info:XObjDecoderInfo=null, shouldMakeBindable:Boolean=false):*
    {
        if (xml is XMLList)
            xml = (xml as XMLList)[0];
        
        if (!info)
        {
            info = new XObjDecoderInfo();
        }
        
        info.resultClass = resultClass;
        info.memberClass = memberClass;
        
        return xobj::actualDecodeXML(xml as XML, info.resultClass, result, false, info);
    }
    
    
    /** decodeCollectionMembers() allows for direct decoding into a collection
     * avoiding the reflective step in between. Useful for hand-coded decoders
     * that understand how to directly reference the XML list and types required
     * 
     * Note: does not support looking up "identified" collections (those with 
     * and id property)
     */
    
    public function decodeCollectionMembers(xml:Object, result:Object=null, resultClass:Class=null, memberClass:Class=null, info:XObjDecoderInfo=null, shouldMakeBindable:Boolean=false):*
    {
        if (xml is XML)
            xml = (xml as XML).children();
        
        if (!result && resultClass)
            result = new resultClass();
        
        if (!result)
            result = new ArrayCollection();
        
        if (!info)
            info = new XObjDecoderInfo();
        
        info.resultClass = resultClass;
        info.memberClass = memberClass;
        
        for each (var elem:XML in (xml as XMLList))
        {
            var newObj:Object = xobj::actualDecodeXML(elem, memberClass);
            result.addObject(newObj);
        }
        
        return result;
    }
    
    
    xobj var namespaceMap:Dictionary = new Dictionary();
    xobj var spacenameMap:Dictionary = new Dictionary();
    

    /**
     *  @private
     * 
     * This method is marked public so that the ComplexString type can use it
     */
    public static function simpleType(val:Object, resultType:Class=null):Object
    {
        var result:Object = val;
        
        if (val == null)
            return null;
        
        var valStr:String = val.toString();
        
        if (valStr != "")
        {
            var testNum:Number = Number(val);
            var lowerVal:String  = val.toString().toLowerCase();
            
            //return the value as a string, a boolean or a number.
            //numbers that start with 0 are left as strings
            //ForceObject removed since we'll take care of converting to a String or Number object later
            // make sure to check if String here so "1.0" is a String, not the number 1 (RBL-4931)
            if (resultType == String)
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
                || (valStr.charAt(0) == '0') // starts with a leading zero
                || ((valStr.charAt(0) == '-') && (valStr.charAt(1) == '0')) // starts with -0
                || lowerVal.charAt(lowerVal.length -1) == 'e') // TODO: wtf?
            {
                result = valStr;
            }
            else
            {
                result = Number(val);
            }
        }
        else if (valStr == "")
        {
            // TODO: do something with NULL values?
            var foo:String = "bar";
        }
        
        return result;
    }
    
    
    xobj var deferred:Boolean;
    
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
    
    
    /**
     * 
     * actualDecodeXML is the workhorse function that does the heavy lifting of 
     * decoding a given XML object and will return the resulting AS3 object
     * 
     * Caller can pass in an object to populate with the decoded data or can 
     * allow one to be located or created by this method.
     * 
     * Location of the result object is done by looking at the dataNode.@id
     * attribute and consulting a weak object cache.
     * 
     * Alternatively, an expectedResultClass can be passed to inform the creation
     * of a new instance object.
     * 
     * If expectedResultClass is null, various heuristics, including a typeMap 
     * lookup are used to infer the desired type.
     * 
     * Every XML attribute is mapped to a property of the result object
     * 
     * Every XML element is mapped to a property of the result object with 
     * special handling for nested elements that are collection members
     * 
     * For this purpose, memberClass allows you to dictate what type should be used 
     * for decode child elements if not otherwise computable from result properties
     * 
     * Note that throughout, reflection is used on the result object to infer
     * the object types that should be used for properties as well as members
     * 
     * TODO: shouldMakeBindable is broken. We maintain it redundantly (always false)
     * then recompute it at the end
     */
    
    xobj function actualDecodeXML(dataNode:XML, expectedResultClass:Class = null, 
                                  rootObject:* = null, isRootNode:Boolean = false, 
                                  info:XObjDecoderInfo=null):Object
    {
        var result:*;
        var shouldMakeBindable:Boolean = false;
        var isTypedProperty:Boolean = false;
        var doneRootDupe:Boolean = false;
        var meta:XObjMetadata;
        //var resultID:String;
        
        if (dataNode == null)
            return null;
        
        if (info == null)
            info = new XObjDecoderInfo();
        
        // flag to track whether we were told or not
        info.isSpecifiedType = rootObject || expectedResultClass;
        info.isRootNode = isRootNode;
        
        result = findExistingObject(dataNode, rootObject, info);
        
        // now look up type info if available
        if (result)
        {
            info.resultClass = XObjUtils.getClass(result);
            // assume we should NEVER make specified types bindable
            shouldMakeBindable = false;
        }
        else // otherwise, we need to create a new result object
        {
            // was a type specified?
            if (expectedResultClass)
            {
                // use what was asked for
                info.resultClass = expectedResultClass;
                // assume we should NEVER make specified types bindable
                shouldMakeBindable = false;
            }
            else
            {
                // is there a typeMap entry for this element?
                // TODO: NOTE: we use localName only (no namespace support)
                var nodeType:Class
                nodeType = typeForTag(dataNode.localName());
                //nodeType = typeForTag(dataNode.name());  //namespaced
                
                if (nodeType)
                {
                    info.resultClass = nodeType;
                    // assume we should NEVER make specified types bindable
                    shouldMakeBindable = false;
                }
                else
                {
                    // is this marked as a list="true" to hint us?
                    if (getIsListAttr(dataNode))
                    {
                        info.resultClass = XObjArrayCollection;
                    }
                    else
                    {// go with plain object, and allow bindable flag to kick in
                        info.resultClass = Object;
                    }
                }
            }
        }
        
        if (!result)
        {
            // finally, create the right kind of result object via whatever
            // factory we were given
            result = objectFactory.newObject(info.resultClass, info.resultID);
            
            if (result == null)
            {
                throw new Error("Cannot determine which object type to instantiate");
            }
        }
        
        if (isRootNode)
        {
            // note the element used to decode
            meta = XObjMetadata.getMetadata(result);
            if (!meta.rootQName)
            {
                meta.rootQName = new XObjQName(dataNode.namespace(), null, dataNode.localName());
            }
        }
        
        // so what type did we eventually use?
        info.resultTypeName = getQualifiedClassName(result);
        
        // Now, is this a collection or not
        // TODO: if we knew the result already, these are known in caller
        // so pass them in instead of looking them up again
        
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
        // object to determine isByReference in this case. QuerySet is a 
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
        
        // Decode the part
        result = decodeInto(dataNode, result, info, isArray, isCollection, shouldMakeBindable);
        
        // so did we actually do anything to the object?
        if (info.isNullObject && !isRootNode)
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
                && (info.resultClass != String));
        
        if (result && shouldMakeBindable)
        {                
            result = new ObjectProxy(result);
        }
        
        // should we keep an extra, well-known ref to the object?
        if (isRootNode && !doneRootDupe)
        {
            var wrappedResult:Object;
            
            wrappedResult = { root: result };
            var rootQName:XObjQName = new XObjQName(dataNode.namespace(), null, dataNode.localName());
            wrappedResult[decodePartName(rootQName, dataNode)] = result;
            result = wrappedResult;
            //assignToProperty(result, "root", partObj, false, propertyIsArray, propertyIsCollection, shouldMakeBindable);
            doneRootDupe = true;
        }
        
        return result;
    }
    
    
    xobj function decodeInto(xml:Object, result:Object, info:XObjDecoderInfo=null, isArray:Boolean=false, isCollection:Boolean=false, shouldMakeBindable:Boolean=false):Object
    {
        if (!xml)
            return null;
        if (xml is XMLList)
            xml = (xml as XMLList)[0];
        
        var useStatics:Boolean = XObjXMLDecoder.useStaticDecoders;
        
        if (result == null)
            useStatics = false;  // TODO: allow caller to pass in class...
        
        if (useStatics)
        {
            var decoder:IXObjSerializing = objectFactory.getDecoderForObject(result);
            if (decoder == null)
                useStatics = false;
        }
        
        if (useStatics)
        {
            result = decoder.decodeIntoObject(this, (xml as XML), result, info, isArray, isCollection, shouldMakeBindable);
        }
        else
        {
            result = decodeReflectively((xml as XML), result, info, isArray, isCollection, shouldMakeBindable);
        }
        
        return result;
    }
    
    
    private function decodeReflectively(dataNode:XML, result:Object, info:XObjDecoderInfo, isArray:Boolean, isCollection:Boolean, shouldMakeBindable:Boolean):Object
    {
        var isSimpleType:Boolean = false;
        var elementSet:Array = [];
        var attributeSet:Array = [];
        
        if (!info)
            info = new XObjDecoderInfo();
        
        // Now start looking at the child XML nodes
        
        var children:XMLList = dataNode.children();
        
        // track whether we actually have any values at all
        info.isNullObject = true;
        info.isSimpleType = true;
        
        // OK. Now we're ready to decode some actual data!
        if ((children.length() == 1) && (children[0].nodeKind() == "text"))
        {
            info.isNullObject = false;
            
            var temp:* = XObjXMLDecoder.simpleType(children[0], info.resultClass);
            if (!info.isSpecifiedType
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
                            result = XObjUtils.parseRPATHWHACKYDATETIME(temp);
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
            if (children.length() > 0 && !(result is XML))
            {
                var seenProperties:Dictionary = new Dictionary();
                var lastPartName:Object = {qname: null, propname: null};
                // loop through all children. TODO: break this into async slices 
                // as we did with FilterIndex creation and maintenance?
                
                for (var i:uint = 0; i < children.length(); i++)
                {
                    var partNode:XML = children[i];
                    var typeInfo:XObjTypeInfo = null;
                    var partClass:Class = null;
                    var partClassName:String = null;
                    var nextCollClass:Class = null;
                    var isMember:Boolean;
                    //var partID:String
                    var partQName:XObjQName;
                    var elementName:*;
                    // assume elementName maps directly to propertyName for now
                    var propertyName:*;
                    var propertyIsArray:Boolean
                    var propertyIsCollection:Boolean;
                    var partObj:*;
                    var partInfo:XObjDecoderInfo;
                    
                    // skip text nodes, which are part of mixed content
                    if (partNode.nodeKind() != "element")
                    {
                        continue;
                    }
                    
                    info.isNullObject = false;
                    
                    partInfo = new XObjDecoderInfo();
                    
                    partInfo.resultID = getIDAttr(partNode);
                    
                    // Step 1: 
                    // figure out the name of the element and thus, the propertyName
                    // to use
                    partQName = new XObjQName(partNode.namespace(), null, partNode.localName());
                    
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
                    partObj = objectFactory.getObjectForId(partInfo.resultID);
                    
                    // Get part type information
                    
                    // look up characteristics of the result.propertyName type
                    typeInfo = XObjUtils.typeInfoForProperty(result, info.resultTypeName, propertyName);
                    
                    partClass = typeInfo.type;
                    partClassName = typeInfo.typeName;
                    propertyIsArray = typeInfo.isArray;
                    propertyIsCollection = typeInfo.isCollection;
                    isMember = typeInfo.isMember;
                    
                    // make sure we can pass on an [ArrayElementType()] metadata
                    // we observe on this property (which will not be visible
                    // to recursive calls)
                    nextCollClass = typeInfo.arrayElementClass;
                    
                    if (!seenProperties[propertyName]
                        && result.hasOwnProperty(propertyName))
                    {
                        var existing:* = result[propertyName];
                        
                        if (!(existing == undefined))
                        {
                            // we do not want to reuse simple objects
                            if ((existing is Object)
                                && !(
                                    //(existing is Array) 
                                    //|| (existing is ICollectionView)
                                    //||
                                    (existing is String)
                                    || (existing is Boolean)
                                    || (existing is int)
                                    || (existing is Number)
                                    || (existing is Date)
                                ))
                            {
                                // reuse any complex objects provided we don't have
                                // an ID conflict
                                if (partInfo.resultID != null)
                                {
                                    var existingByID:* = objectFactory.getObjectForId(partInfo.resultID);
                                    if (!existingByID)
                                    {
                                        partObj = existing;
                                        partInfo.resultID = getIDProperty(partObj);
                                        if (partInfo.resultID)
                                        {
                                            // register it!
                                            objectFactory.trackObjectById(partObj, partInfo.resultID);
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
                                    partInfo.resultID = getIDProperty(partObj);
                                    if (partInfo.resultID)
                                    {
                                        // register it!
                                        objectFactory.trackObjectById(partObj, partInfo.resultID);
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
                                // simple existing value.
                                // Ignore type. Allow decode to deduce afresh
                                // This prevents auto-promote of simple types to Objects on 
                                // refetch into same instance
                            }
                        }
                        else  // we have the property, but no value.
                        {
                            // NB: ObjectProxy always says yes to hasOwnProperty()
                            if (!partClass && !(result is ObjectProxy))
                            {
                                // must be plain old Object, but our TypeInfo
                                // method ignores them...compensate
                                partClass = Object;
                            }
                        }
                    }
                        // else we have to check for it being a member of a collection/array if
                        // it is NOT a property of the result object
                    else if (!(result is IXObjCollection)  // but only if it's not a self-aware collection!
                        && (isArray || isCollection) && !result.hasOwnProperty(propertyName))
                    {
                        // we need to handle collection type objects with special care
                        // since if the element doesn't map to a property, it's a member
                        
                        isMember = true;
                    }
                    
                    // Step 3: 
                    // decide what partClass to use if we don't already know
                    // from the above
                    
                    if (isMember)
                    {
                        // we were told what type to use on the way in?
                        if (info.memberClass)  
                        {
                            // parent object determined type for us. let it trump
                            partClass = info.memberClass;
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
                    partInfo.memberClass = nextCollClass;
                    partObj = actualDecodeXML(partNode, partClass, partObj, false, partInfo);
                    
                    // and assign the result property based on array characteristics
                    if (isMember)
                    {
                        result = assignToArray(result, propertyName, partObj, false, propertyIsArray, propertyIsCollection, shouldMakeBindable);
                        
                        // make a note of the propertyName that was a member for better round-trip support of untyped object heirarchies
                        var meta:XObjMetadata = XObjMetadata.getMetadata(result);
                        meta.arrayEntryTag = propertyName;
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
                    
                    if (XObjDecoderGenerator.generateClasses && partObj != null)
                    {
                        // Stash everything we know for debug/class gen
                        var sinfo:XObjTypeInfo = new XObjTypeInfo();
                        sinfo.holderClassName = XObjUtils.getClassName(result);
                        sinfo.isAttribute = false;
                        sinfo.isSimpleType = partInfo ? partInfo.isSimpleType : false;
                        sinfo.isArray = propertyIsArray;
                        sinfo.isCollection = propertyIsCollection;
                        sinfo.arrayElementClass = partInfo.memberClass;
                        sinfo.propName = propertyName;
                        sinfo.typeName = partClassName ? partClassName : XObjUtils.getClassName(partObj);
                        sinfo.isMember = isMember;
                        sinfo.isDynamic = typeInfo.isDynamic;
                        sinfo.seen = true;
                        XObjDecoderGenerator.recordPropertyInfo(sinfo);
                    }
                }
            }
            else if (children.length() > 0 && (result is XML))
            {
                var tempXML:XML;
                
                // XML needs special handling as "embedded" XML
                info.isNullObject = false;
                
                if (children.length() > 1)
                {
                    // if there's more than one child, use the element *itself* 
                    // as the root node. This will preserve any attributes on it
                    tempXML = new XML(dataNode);
                }
                else
                {
                    // otherwise, grab the first child as the root
                    tempXML = new XML(children[0]);
                }
                
                isSimpleType = false;
                result = tempXML;
            }
            else if (children.length() == 0)
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
        var attributes:XMLList = dataNode.attributes();
        for each (var attributeXML:XML in attributes)
        {
            //var attribute:String = attributeXML.name();
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
            
            info.isNullObject = false;
            
            var attrObj:* = decodeAttrName(attributeXML.localName(), attributeXML);
            
            // track the list of attrs so we can decode them later
            attributeSet.push(attrObj);
            
            var attrName:String = attrObj.propname;
            var attrValue:* = XObjXMLDecoder.simpleType(attributeXML.toString(), info.resultClass);
            
            if (makeAttributesMeta)
            {
                try
                {
                    if (!("attributes" in result))
                        result.attributes = {};
                    result.attributes[attrName] = attrValue;
                }
                catch (e:Error)
                {
                    // probably not a dynamic class. Stash on global tracking dict...
                    if (attrValue)
                        attrObj.value = attrValue;
                    XObjMetadata.addAttribute(result, attrObj);
                }
            }
            else
            {
                try
                {
                    result[attrName] = attrValue;
                    if (isArray)
                    {
                        // TODO: figure out the clean way to do this. namespaces?
                        //result.setPropertyIsEnumerable(attrName, false);
                    }
                }
                catch (e:TypeError)
                {
                    if ((result[attrName] is IXObjHref)
                        && (attrValue is String))
                    {
                        result[attrName].id = attrValue;
                    }
                    else 
                    {
                        // Prob not a dynamic class. Stash on global tracking dict...
                        if (attrValue)
                            attrObj.value = attrValue;
                        XObjMetadata.addAttribute(result, attrObj);
                    }
                }
                catch (e:Error)
                {
                    //throw new Error("Failed to set attribute "+attrName+"("+attr+") on "+resultTypeName+". Check that class is dynamic or attribute name is spelled correctly");
                    trace("Failed to set attribute "+attrName+"("+attrValue+") on "+ info.resultTypeName+". Check that class is dynamic or attribute name is spelled correctly");
                }
            }
            
            if (XObjDecoderGenerator.generateClasses)
            {
                // Stash everything we know for debug/class gen
                sinfo = new XObjTypeInfo();
                sinfo.holderClass = XObjUtils.getClass(result);
                sinfo.holderClassName = XObjUtils.getClassName(result);
                sinfo.propName = attrName;
                sinfo.type = XObjUtils.getClass(attrValue);
                sinfo.typeName = XObjUtils.getClassName(attrValue);
                sinfo.isSimpleType = true;
                sinfo.seen = true;
                sinfo.isAttribute = true;
                sinfo.isDynamic = false; // TODO
                XObjDecoderGenerator.recordPropertyInfo(sinfo);
            }
        }
        
        // finally, did we build a new untyped object with a single property named 'item'
        // which is the magic sentinal SimpleXMLEncoder seems to use?
        
        if (!info.isSpecifiedType)
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
        
        // note our final disposition
        info.isSimpleType = isSimpleType;
        
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
            if (!(value is IXObjHref) && (result[propName] is IXObjHref))
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
    
    xobj function getLocalPrefixForNamespace(uri:String, node:XML):String
    {
        var prefix:String;
        var decls:* = node.namespaceDeclarations();
        
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
    
    
    xobj function decodePartName(partQName:XObjQName, node:XML):String
    {
        var prefix:String;
        var partName:String = XObjUtils.getNCName(partQName.localName);
        
        // map local namespaces
        prefix = namespaceMap[node.namespace().uri];
        if (!prefix)
            prefix = node.namespace().prefix;
        
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
    
    
    xobj function decodeAttrName(name:*, node:XML):*
    {
        var attr:Object = {};
        var namespace:Namespace = node.namespace();
        var prefix:String = namespace.prefix;
        var newName:String;
        
        if (!prefix)
        {
            // this tells us we "topped out" and can't resolve the ns
            newName = name;
        }
        else
        {
            var qname:XObjQName = new XObjQName(namespace, null, name);
            newName = decodePartName(qname, node);
        }
        
        attr.qname = qname;
        attr.propname = newName;
        // also pull attr value
        if (node.attribute(name).toString())
            attr.value = node.attribute(name)[0].toString();
        return attr;
    }
    
    xobj function toCollection(v:*):ListCollectionView
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
    
    private function getIDAttr(part:XML):String
    {
        var result:String;
        
        if (part)
        {
            result = part.@id;
            
            if (!result)
            {
                result = part.@href;
            }
        }
        
        return result;
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
    
    private function getIsListAttr(part:XML):Boolean
    {
        if (!part)
            return false;
        
        var p:String = part.@list;
        
        if (p)
            return p == "true";
        
        return false;
    }
    
    
    private function findExistingObjectOLD(dataNode:XML, rootObject:Object, info:XObjDecoderInfo):Object
    {
        var result:Object;
        var existingObj:Object;
        
        // does the node have an id? If so, we may already know this object
        // for example, doing a GET into a previously fetched instance
        info.resultID = getIDAttr(dataNode);
        var resultID:String = info.resultID;
        
        // see whether we alreadyhave an object with this ID
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
        
        if (rootObject)
        {
            result = rootObject;
            // also track the ID we got, if any, since this may have been a POST
            if (existingObj)
            {
                if (existingObj != result)
                {
                    // hmmm. mismatched objects ???
                    trace("mismatched objects for ID "+ resultID);
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
        
        return result;
    }
    
    private function findExistingObject(dataNode:XML, rootObject:Object, info:XObjDecoderInfo):Object
    {
        var result:Object;
        var existingObj:Object;
        
        // does the node have an id? If so, we may already know this object
        // for example, doing a GET into a previously fetched instance
        info.resultID = getIDAttr(dataNode);
        var resultID:String = info.resultID;
        
        // see whether we already have an object with this ID
        if (resultID)
        {
            existingObj = objectFactory.getObjectForId(resultID);
        }
        
        if (existingObj)  // always use the existing object
        {
            if (info.isRootNode && rootObject && rootObject != existingObj)
            {
                // root nodes are special. We're forcibly decoding into
                // an object we were given for the purpose
                // existingObject doesn't match is a corner-case
                // that we have to tolerate for now due to the need for
                // type-swizzling by some legacy code
                result = rootObject;
                // update id cache to new object
                objectFactory.trackObjectById(result, resultID);
            }
            else
            {
                // use if if we have it
                result = existingObj;
            }
        }
        else
        {
            if (rootObject)
            {
                result = rootObject;
               
                // track the new object
                objectFactory.trackObjectById(result, resultID);
            }
        }
        
        return result;
    }
    
}

}