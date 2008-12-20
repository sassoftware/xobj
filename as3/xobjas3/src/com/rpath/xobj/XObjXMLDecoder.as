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
            //return the value as a string, a boolean or a number.
            //numbers that start with 0 are left as strings
            //bForceObject removed since we'll take care of converting to a String or Number object later
            if (val is String && String(val) == "")
            {
                result = val.toString();    
            }
            else if (isNaN(Number(val)) || (val.charAt(0) == '0') || ((val.charAt(0) == '-') && (val.charAt(1) == '0')) || val.charAt(val.length -1) == 'E')
            {
                var valStr:String = val.toString();

                //Bug 101205: Also check for boolean
                var valStrLC:String = valStr.toLowerCase();
                if (valStrLC == "true")
                    result = true;
                else if (valStrLC == "false")
                    result = false;
                else
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
            makeAttributesMeta:Boolean = false)
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
    }

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
        var result:*;
        var nullObject:Boolean;
        var isSimpleType:Boolean = false;
        var shouldMakeBindable:Boolean = false;
        var isTypedProperty:Boolean = false;
        var isTypedNode:Boolean = false;
        var isSpecifiedType:Boolean = false;
        var elementSet:Array = [];
        var attributeSet:Array = [];
        
        if (dataNode == null)
            return null;
            
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
        
        // OK, so now we know what type to instantiate
        
        result = new resultType();
        
        // track whether we actually have any values at all
        nullObject = true;
        
        // so what type did we eventually use?
        var resultTypeName:String = getQualifiedClassName(result);
        
        // thus, what type of assignment function should we use?
        var assign:Function;
        
        if (XObjUtils.isTypeArray(resultTypeName))
            assign = assignToArray;
        else
            assign = assignToProperty;

        // OK. Now we're ready to decode some actual data!
        
        if ((children.length == 1) && (children[0].nodeType == XMLNodeType.TEXT_NODE))
        {
            nullObject = false;
            // If exactly one text node subtype, we must want a simple
            // value.
            
            //TODO: if the propType is provided then we SHOULD NOT assume simpleType. Further, if we 
            //end up adding attrs to it (see below), we want propType not ComplexString
            
            isSimpleType = true;
            
            result = XObjXMLDecoder.simpleType(children[0].nodeValue);
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

                    // record the order we see the elements in for encoding purposes
                    // this is an attempt to "fake" XMLSchema sequence constraint of
                    // ordered elements. Collapse sequenced repetitions to a single entry
                    if (partQName != lastPartName.qname)
                    {
                        lastPartName = {};
                        lastPartName.qname = partQName;
                        elementSet.push(lastPartName);
                    }
                    
                    // TODO: allow type map entries to be full QNames, not just local names
                    var partName:* = decodePartName(partQName, partNode);
                    lastPartName.propname = partName;
                    
                    var partTypeName:String = XObjUtils.typeNameForProperty(resultTypeName, partName);
                    var partObj:*;
                    
                    if (partTypeName != null)
                    {
                        var partClass:Class = XObjUtils.getClassByName(partTypeName);
                        if (partClass)
                            partObj = decodeXML(partNode, partClass);
                        else
                            partObj = decodeXML(partNode);
                    }
                    else
                        partObj = decodeXML(partNode);
    
                    if (seenProperties[partName])
                    {
                           // Enable processing multiple copies of the same element (sequences)
                        var existing:Object = result[partName];
                    }
                    
                    if ((seenProperties[partName] && existing != null))
                    {
                        if (existing is Array)
                        {
                            existing.push(partObj);
                        }
                        else if (existing is ArrayCollection)
                        {
                            existing.source.push(partObj);
                        }
                        else
                        {
                            // make it an array
                            if (existing)
                                existing = [existing];
                            else
                                existing = [];
                           
                            existing.push(partObj);
    
                            if (shouldMakeBindable)
                                existing = new ArrayCollection(existing as Array);
    
                            assign(result, partName, existing);
                        }
                    }
                    // check the type of the property we're about to add, is it an array?
                    else if (XObjUtils.isTypeArray(partTypeName))
                    {
                        if (partObj is Array)
                            assign(result, partName, partObj);
                        else if (partObj is ArrayCollection)
                            assign(result, partName, partObj.source);
                        else if (partObj is ObjectProxy)
                        {
                            partObj = partObj.item;
                            // this is getting ugly
                            if (partObj is Array)
                                assign(result, partName, partObj);
                            else if (partObj is ArrayCollection)
                                assign(result, partName, partObj.source);
                            else
                                assign(result, partName, [partObj]);
                        }
                        else
                            assign(result, partName, [partObj]);
                    }
                    else if (XObjUtils.isTypeArrayCollection(partTypeName))
                    {
                        if (partObj is Array)
                            assign(result, partName, new ArrayCollection(partObj));
                        else if (partObj is ArrayCollection)
                            assign(result, partName, partObj);
                        else if (partObj is ObjectProxy)
                        {
                            partObj = partObj.item;
                            // this is getting ugly
                            if (partObj is Array)
                                assign(result, partName, new ArrayCollection(partObj));
                            else if (partObj is ArrayCollection)
                                assign(result, partName, partObj);
                            else
                                assign(result, partName, new ArrayCollection([partObj]));
                        }
                        else 
                            assign(result, partName, new ArrayCollection([partObj]));
                    }
                    else
                    {
                        assign(result, partName, partObj);
                    }
    
                    seenProperties[partName] = true;
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
    
    private function assignToProperty(result:*, propName:String, value:*):void
    {
        result[propName] = value;
    }
    
    private function assignToArray(result:*, propName:String, value:*):void
    {
        // propName is ignored in this case
        result.push(value);
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
    
        
    private var makeObjectsBindable:Boolean;
    private var makeAttributesMeta:Boolean;
}

}