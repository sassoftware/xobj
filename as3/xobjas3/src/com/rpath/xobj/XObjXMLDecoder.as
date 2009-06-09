/*
#
# Copyright (c) 2008 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found 
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any waranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.
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
   
import flash.utils.Dictionary;
import flash.utils.getQualifiedClassName;
import flash.xml.XMLDocument;
import flash.xml.XMLNode;
import flash.xml.XMLNodeType;

import mx.collections.ArrayCollection;
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
    public static function simpleType(val:Object):Object
    {
        var result:Object = val;

        if (val != null)
        {
            var testNum:Number = Number(val);
            var valStr:String = val.toString();
            var lowerVal:String  = val.toString().toLowerCase();
            
            //return the value as a string, a boolean or a number.
            //numbers that start with 0 are left as strings
            //bForceObject removed since we'll take care of converting to a String or Number object later
            if (val is String && String(val) == "")
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
            defer:Boolean=false)
    {
        super();
        this.typeMap = typeMap;
                
        for (var prefix:String in nmMap)
        {
            namespaceMap[nmMap[prefix]] = prefix;
            spacenameMap[prefix] = nmMap[prefix];
        }
        
        this.makeObjectsBindable = makeObjectsBindable;
        this.makeAttributesMeta = makeAttributesMeta;
        this.deferred = defer;
    }

    public var deferred:Boolean;
    
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


    public function actualDecodeXML(dataNode:XMLNode, propType:Class = null, rootObject:* = null, isRootNode:Boolean = false):Object
    {
        var result:*;
        var nullObject:Boolean;
        var isSimpleType:Boolean = false;
        var shouldMakeBindable:Boolean = false;
        var isTypedProperty:Boolean = false;
        var isTypedNode:Boolean = false;
        var isSpecifiedType:Boolean = false;
        var elementSet:Array = [];
        var attributeSet:Array = [];
        var nextNodeIsRoot:Boolean = false;
        var doneRootDupe:Boolean = false;
        
        if (dataNode == null)
            return null;
        
        if (dataNode is XMLDocument)
            nextNodeIsRoot = true;
            
        var children:Array = dataNode.childNodes;

        /* lots of work follows to figure out the type we should really 
        use
        
        It could be from the parent object specifically typing the property we're
        about to decode (isTypedproperty == true)
        
        Or it could be the element name maps to a type in the TypeMap
        
        */
        
        isTypedProperty = (propType != null);
        
        var nodeType:Class = typeForTag(dataNode.nodeName);
        isTypedNode = (nodeType != null);

        //TODO: make sure we don't obscure typeMap entries with
        // generic Array or ArrayCollection requests
        if (isTypedNode && 
            (XObjUtils.isTypeArray(propType) || XObjUtils.isTypeArrayCollection(propType)))
        {
            propType = nodeType;
        }
        
        
        isSpecifiedType = isTypedProperty || isTypedNode;
        
        var resultType:Class;

        if (isSpecifiedType) // did we ask for a specific type?
        {
            if (isTypedProperty && (nodeType != propType))
            {
                // mismatched type expectations. Go with the property since that the type we're
                // obligated to meet
                resultType = propType;
            } 
            else if (isTypedProperty)
            {
                resultType = propType;
            }
            else if (isTypedNode)
            {
                resultType = nodeType;
            }
            
            // assume we should NEVER make specified types bindable
            shouldMakeBindable = false;
        }
        else // type not specified, so what type *should* we use?
        {
            // special case handling of empty terminal nodes (no value)
            if (children.length == 0)
            {
                isSimpleType = true;
                resultType = XObjString;
            }
            else
            {
                resultType = Object;
            }
            
            // should we make this bindable?
            shouldMakeBindable = (makeObjectsBindable 
                && (nodeType == Object)
                && !(result is ObjectProxy)
                && (resultType != String));
            
            if (shouldMakeBindable)
            {                
                result = new ObjectProxy(result);
            }
            
                    
        }
        
        // OK, so now we know what type we want
        if (rootObject && !nextNodeIsRoot)
        {
            result = rootObject;
        }
        else
        {
            result = new resultType();
        }

        // track whether we actually have any values at all
        nullObject = true;
        
        // so what type did we eventually use?
        var resultTypeName:String = getQualifiedClassName(result);
        
        // thus, what type of assignment function should we use?
        var assign:Function;
        
        if (XObjUtils.isTypeArray(resultType) || XObjUtils.isTypeArrayCollection(resultType))
            assign = assignToArray;
        else
            assign = assignToProperty;

        // OK. Now we're ready to decode some actual data!
        if ((children.length == 1) && (children[0].nodeType == XMLNodeType.TEXT_NODE))
        {
            nullObject = false;

            var temp:* = XObjXMLDecoder.simpleType(children[0].nodeValue);
            if (!isSpecifiedType || 
                (result is String) || (resultTypeName == "com.rpath.xobj.XObjString") || (result is int) || (result is Number) || (result is Boolean))
            {
                isSimpleType = true;
                result = temp;
            }
            else
            {
                try
                {
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
            if (children.length > 0)
            {
                nullObject = false;
                var seenProperties:Object = {};
                var lastPartName:Object = {qname: null, propname: null};
                

                for (var i:uint = 0; i < children.length; i++)
                {
                    var partNode:XMLNode = children[i];
                    
                    // skip text nodes, which are part of mixed content
                    if (partNode.nodeType != XMLNodeType.ELEMENT_NODE)
                    {
                        continue;
                    }

                    var partQName:XObjQName = new XObjQName(partNode.namespaceURI, XObjUtils.getNCName(partNode.nodeName));
                    // TODO: allow type map entries to be full QNames, not just local names
                    var partName:* = decodePartName(partQName, partNode);
                    var propertyIsArray:Boolean = false;
                    var propertyIsArrayCollection:Boolean = false;

                    // record the order we see the elements in for encoding purposes
                    // this is an attempt to "fake" XMLSchema sequence constraint of
                    // ordered elements. Collapse sequenced repetitions to a single entry
                    if (!XObjQName.equal(partQName,lastPartName.qname))
                    {
                        lastPartName = {};
                        lastPartName.qname = partQName;
                        elementSet.push(lastPartName);
                    }
                    
                    lastPartName.propname = partName;
                  
                    // what type do we want?
                    var typeInfo:XObjTypeInfo = null;
                    var partTypeName:String = null;
                    var partClass:Class = null;
                    var partObj:*;

                    // look up characteristics of the result.propName type
                    typeInfo = XObjUtils.typeInfoForProperty(result, resultTypeName, partName);
                    partTypeName = typeInfo.typeName;
                    propertyIsArray = typeInfo.isArray;
                    propertyIsArrayCollection = typeInfo.isArrayCollection;

                    // if we've seen this property before, force it to be an array
                    if (seenProperties[partName])
                    {
                        propertyIsArray = true;
                    }
                      
                    // assume we need a new part instance
                    partObj = null;
                    
                    // now, should we decode into a new object, or decode into an existing instance?
                    if (nextNodeIsRoot)
                    {
                        // we're about to read the root element
                        partObj = rootObject;
                    }
                    // else should we reuse existing property object?
                    else if (!propertyIsArray 
                    
                        && result.hasOwnProperty(partName))
                    {
                        var existing:* = result[partName];
                        if (existing && (existing is Object)
                            && !((existing is Array) 
                                || (existing is ArrayCollection)
                                || (existing is String)
                                || (existing is Boolean)
                                || (existing is Number)
                                )
                            )
                        {
                            // reuse it
                            partObj = existing;
                        }
                    }
                    
                    // if we have a partObj we need to use its class to decode into
                    if (partObj)
                    {
                        partClass = XObjUtils.classOf(partObj);
                    }
                    else
                    {
                        partClass = XObjUtils.getClassByName(partTypeName);
                    }
                    
                    // now finally, decode the part
                    partObj = actualDecodeXML(partNode, partClass, partObj, nextNodeIsRoot);

                    // and assign the result property based on array characteristics
                    result = assign(result, partName, partObj, seenProperties[partName], propertyIsArray, propertyIsArrayCollection, shouldMakeBindable);
                    
                    seenProperties[partName] = true;

                    // should we keep an extra, well-known ref to the object?
                    if (nextNodeIsRoot && !doneRootDupe)
                    {
                        result = assign(result, "root", partObj, seenProperties[partName], propertyIsArray, propertyIsArrayCollection, shouldMakeBindable);
                        doneRootDupe = true;
                    }
                }
            }
        }

        // Cycle through the attributes
        var attributes:Object = dataNode.attributes;
        for (var attribute:String in attributes)
        {
            
            nullObject = false;
            // result can be null if it contains no children.
            if (result == null)
            {
                result = {};
                
                if (shouldMakeBindable)
                    result = new ObjectProxy(result);
            }

            // If result is not currently an Object (it is a Number, Boolean,
            // or String), then convert it to be a ComplexString so that we
            // can attach attributes to it.  (See comment in ComplexString.as)
            if (isSimpleType && !(result is XObjString))
            {
                result = new XObjString(result.toString());
                isSimpleType = false;
            }

            var attrObj:* = decodeAttrName(attribute, dataNode);

            // track the list of attrs so we can decode them later
            
            attributeSet.push(attrObj);

            var attrName:String = attrObj.propname;

            var attr:* = XObjXMLDecoder.simpleType(attributes[attribute]);
            
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
                result[attrName] = attr;
                
            
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
                if ( partName == "item")
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
        if (nullObject)
            result = null;
            
        return result;
    }

    import flash.utils.flash_proxy;

    private function assignToProperty(result:*, propName:String, value:*,
        seenBefore:Boolean, makeArray:Boolean, makeArrayCollection:Boolean, makeBindable:Boolean):*
    {
        if (result == null)
            return result;
        
        if (makeArray || makeArrayCollection)
        {
            var existing:* = result[propName];
            
            if (existing == null)
            {
                if (makeArrayCollection)
                {
                    existing = new ArrayCollection([]);
                    if (!(value is Array) && !(value is ArrayCollection))
                    {
                        (existing as ArrayCollection).addItem(value);
                    }
                    else
                    {
                        value = makeCollection(value);
                        for each (var v:* in value)
                        {
                            (existing as ArrayCollection).addItem(v);
                        }
                    }
                }
                else
                {
                    existing = [];
                    existing = (existing as Array).concat(value);
                }
            }
            else if (existing is Array)
            {
                if (!seenBefore)
                {
                    (existing as Array).splice(0, (existing as Array).length);
                }
                
                existing = (existing as Array).concat(value);
            }
            else if (existing is ArrayCollection)
            {
                if (!seenBefore)
                {
                    (existing as ArrayCollection).removeAll();
                }
                
                if (!(value is Array) && !(value is ArrayCollection))
                {
                    (existing as ArrayCollection).addItem(value);
                }
                else
                {
                    value = makeCollection(value);
                    for each (var v1:* in value)
                    {
                        (existing as ArrayCollection).addItem(v1);
                    }
                }
            }
            else
            {
                if (!seenBefore)
                {
                    // throw away old, (non decoded) value
                    if (makeArrayCollection)
                    {
                        existing = new ArrayCollection([]);
                    }
                    else
                    {
                        existing = [];
                    }
                }
                else
                {
                    // throw away old, (non decoded) value
                    if (makeArrayCollection)
                    {
                        existing = new ArrayCollection([existing]);
                    }
                    else
                    {
                        existing = [existing];
                    }
                }

                if (makeArrayCollection)
                {
                    if (!(value is Array) && !(value is ArrayCollection))
                    {
                        (existing as ArrayCollection).addItem(value);
                    }
                    else
                    {
                        value = makeCollection(value);
                        for each (var v2:* in value)
                        {
                            (existing as ArrayCollection).addItem(v2);
                        }
                    }
                }
                else
                {
                    existing = (existing as Array).concat(value);
                }
            }
            
            if ((makeArrayCollection || makeBindable) && !(existing is ArrayCollection))
                existing = new ArrayCollection(existing as Array);
                
            value = existing;
        }

        result[propName] = value;

        return result;
    }
    
    private function assignToArray(result:*, propName:String, value:*,
        seenBefore:Boolean, makeArray:Boolean, makeArrayCollection:Boolean, makeBindable:Boolean):*
    {
        if (result == null)
            return result;

        if (result is Array)
        {
            if (!seenBefore)
            {
                (result as Array).splice(0, (result as Array).length);
            }
            result.push(value);
        }
        else if (result is ArrayCollection)
        {
            if (!seenBefore)
            {
                (result as ArrayCollection).removeAll();
            }
            result.addItem(value);
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
            prefix= node.getPrefixForNamespace(uri);
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
    
    public function makeCollection(v:*):ArrayCollection
    {
        if (v is ArrayCollection)
            return v;
        else if (v is Array)
            return new ArrayCollection(v);
        else
            return new ArrayCollection([v]);
    }
    
    private var makeObjectsBindable:Boolean;
    private var makeAttributesMeta:Boolean;
}

}