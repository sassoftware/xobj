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



import flash.utils.*;
import flash.xml.*;

import mx.collections.ArrayCollection;
import mx.utils.*;

    
/**
 * The TypedXMLEncoder class takes ActionScript Objects and encodes them to XML
 * using default serialization informed by a typeMap. This allows specific
 * ActionScript classes to be output with developer-provided element tags.
 * 
 */

public class XObjXMLEncoder
{
    
    public var typeMap:* = {};
    
    public var namespaceMap:Dictionary = new Dictionary();
    public var spacenameMap:Dictionary = new Dictionary();
    
    /** Set simpleEncoderCompatible to true if you want Arrays
    * encoded as a wrapper element with subelements
    */
    
    public var simpleEncoderCompatible:Boolean;
    
    /**
     * Used if the object is not typed
     */ 
    public var defaultTag:String = "root";
    
    /**
     * @private
     */
    private static const CLASS_INFO_OPTIONS:Object = {includeReadOnly:true, includeTransient:false};

    //--------------------------------------------------------------------------
    //
    //  Class Methods
    //
    //--------------------------------------------------------------------------



    /**
     * @private
     */
    static internal function encodeDate(rawDate:Date, dateType:String):String
    {
        var s:String = new String();
        var n:Number;
    
        if (dateType == "dateTime" || dateType == "date")
        {
            s = s.concat(rawDate.getUTCFullYear(), "-");
    
            n = rawDate.getUTCMonth()+1;
            if (n < 10) s = s.concat("0");
            s = s.concat(n, "-");
    
            n = rawDate.getUTCDate();
            if (n < 10) s = s.concat("0");
            s = s.concat(n);
        }
    
        if (dateType == "dateTime")
        {
            s = s.concat("T");
        }
    
        if (dateType == "dateTime" || dateType == "time")
        {
            n = rawDate.getUTCHours();
            if (n < 10) s = s.concat("0");
            s = s.concat(n, ":");
    
            n = rawDate.getUTCMinutes();
            if (n < 10) s = s.concat("0");
            s = s.concat(n, ":");
    
            n = rawDate.getUTCSeconds();
            if (n < 10) s = s.concat("0");
            s = s.concat(n, ".");
    
            n = rawDate.getUTCMilliseconds();
            if (n < 10) s = s.concat("00");
            else if (n < 100) s = s.concat("0");
            s = s.concat(n);
        }
    
        s = s.concat("Z");
    
        return s;
    }
    
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
    

    public function XObjXMLEncoder(typeMap:*=null, nmMap: *=null, myXML:XMLDocument=null)
    {
        super();
        
        if (typeMap == null)
            typeMap = {};
        
        if (nmMap == null)
            nmMap = {};
            
        this.typeMap = typeMap;

        for (var prefix:String in nmMap)
        {
            namespaceMap[nmMap[prefix]] = prefix;
            spacenameMap[prefix] = nmMap[prefix];
        }
        
        this.xmlDocument = myXML ? myXML : new XMLDocument();
    }

    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
    
    public var xmlDocument:XMLDocument;
    
    //--------------------------------------------------------------------------
    //
    //  Methods
    //
    //--------------------------------------------------------------------------
    
    /**
     * Encodes an ActionScript object to XML using default serialization
     * with type mapping support. Goal is to be symmetrical with TypedXMLDecoder
     * 
     * @param obj The ActionScript object to encode.
     * 
     * @param qname The qualified name of the child node.
     * 
     * @param parentNode An XMLNode under which to put the encoded
     * value.
     */

    public function encodeObject(obj:Object, parentNode:XMLNode=null):XMLDocument
    {
        var qname:XObjQName;
        
        // is obj a root holder?
        if (XObjMetadata.METADATA_PROPERTY in obj)
        {
            var xobj:XObjMetadata = obj[XObjMetadata.METADATA_PROPERTY];
            if (xobj.elements.length == 1)
            {
                obj = obj[xobj.elements[0].propname];
                qname = xobj.elements[0].qname;
            }
        }
        
        // we want to make sure the type we use for root node is type of object
        var tag:String = tagForType(obj);
        
        // handle untyped objects
        if (!tag)
        {
            tag = defaultTag;
        }
        
        if (qname == null)
            qname = new XObjQName("", tag);
        
        // null parentNode means "make a new document please"
        if (parentNode == null)
        {
            xmlDocument = new XMLDocument();
            parentNode = xmlDocument;
        }
        else if (parentNode != xmlDocument)
        {
            parentNode.parentNode = xmlDocument;
        }
        
        encodeValue(obj, qname, parentNode);
        
        return xmlDocument;
    }

    public function encodeValue(obj:Object, q:*, parentNode:XMLNode):XMLNode
    {
        var qname:XObjQName = new XObjQName();;
        
        if (q is XObjQName)
            qname = q;
        else if (q is QName)
        {
            qname.localName = (q as QName).localName;
            qname.uri = (q as QName).uri;
        }
        else if (q is String)
        {
            qname.localName == q;
            qname.uri="";
        }
            
        if (qname.localName == null || qname.localName == "")
            trace("missing qname");
        
        // we want to encode null as empty element. XML spec is ambiguous on this point
        // TODO: check whether this matches Erik's server-side Python mapping
        if (obj == null)
        {
            var myElement:XMLNode = xmlDocument.createElement("foo");
            parentNode.appendChild(myElement);
            myElement.nodeName = XObjUtils.encodeElementTag(qname, parentNode);
            return myElement;
        }
        else if (qname.localName == XObjMetadata.METADATA_PROPERTY)
        {
            // do nothing
            return parentNode;
        }
        // encoded as meta?
        else if (qname.localName == "attributes")
        {
            // do nothing
            return parentNode;
        }
        else if (obj is XObjString)
        {
            // unwrap XObjStrings to their naked value
            var newNode:XMLNode = encodeValue(obj.value, qname, parentNode);
            // encoded as meta ?
            setAttributes(newNode, obj);
            // re-encode the nodename to pick up possible local namespace overrides
            newNode.nodeName = XObjUtils.encodeElementTag(qname, newNode);
            return newNode;
        }
        else
            return internal_encodeValue(obj, qname, parentNode);
    }
    
    protected function internal_encodeValue(obj:Object, qname:XObjQName, parentNode:XMLNode):XMLNode
    {
        var myElement:XMLNode;
        
        if (obj == null)
            return null;
    
        // Skip properties that are functions
        var typeType:uint = getDataTypeFromObject(obj);
        if (typeType == XObjXMLEncoder.FUNCTION_TYPE)
            return null;
    
        if (typeType == XObjXMLEncoder.XML_TYPE)
        {
            myElement = obj.cloneNode(true);
            parentNode.appendChild(myElement);
            return myElement;
        }
    
        myElement = xmlDocument.createElement("foo");
        
        if (typeType == XObjXMLEncoder.OBJECT_TYPE)
        {
            // link us into the heirarchy so that namespaces
            // will be resolved up the chain correctly
            parentNode.appendChild(myElement);

            // do all attributes first in case any are namespaced
            var attrNames:Object = setAttributes(myElement, obj);

            myElement.nodeName = XObjUtils.encodeElementTag(qname, myElement);
            
            // TODO: this is expensive. Can we optimize?
            var classInfo:Object = XObjUtils.getClassInfo(obj, [XObjMetadata.METADATA_PROPERTY, "attributes", "prototype"], CLASS_INFO_OPTIONS);
            var properties:Array = (classInfo.properties as Array);
            
            var propsDone:Object = {};
            
            // if we observed (or were provided) an ordering of elements
            // then output that set in order first
            if (XObjMetadata.METADATA_PROPERTY in obj)
            {
                var xobj:XObjMetadata = (obj[XObjMetadata.METADATA_PROPERTY] as XObjMetadata);
                
                if (xobj)
                {
                    // walk them in the order we saw them
                    for each (var entry:* in xobj.elements)
                    {
                        //var propName:String = decodePartName(propQName, myElement);
                        var propName:String = entry.propname;
                        
                        if (propName in attrNames)
                            continue;
                        
                        // don't write out things we don't have in the class info
                        // such as [Transient] or write-only props
                        for (var k:int=0; k < properties.length; k++)
                        {
                            var prop:QName = properties[k];
                            if (prop.localName == propName)
                            {
                                // remove elements we've handled to speed up the next iteration
                                // makes a HUGE difference on large collections of objects
                                properties.splice(k,1);
                                encodeValue(obj[propName], entry.qname, myElement);
                                break;
                            }
                        }
                        // now mark those we visited so we don't try again
                        propsDone[propName] = true;
                    }
                }
                    
            }
            var pCount:uint = properties.length;
            
            // walk remaining properties in arbitrary order
            for each (var fieldName:String in properties)
            {
                // already done as an element?
                if (fieldName in propsDone)
                    continue;
                
                // already done as an attribute?
                if (fieldName in attrNames)
                    continue;
                
                var propQName:XObjQName = new XObjQName("", fieldName);
                encodeValue(obj[fieldName], propQName, myElement);
            }
        }
        else if (typeType == XObjXMLEncoder.ARRAY_TYPE)
        {
            if (simpleEncoderCompatible)
            {
                // link us into the heirarchy so that namespaces
                // will be resolved up the chain correctly
                parentNode.appendChild(myElement);
                setAttributes(myElement, obj);
                myElement.nodeName = XObjUtils.encodeElementTag(qname, myElement);
                qname = new XObjQName("", "item");
            }
            else
            {
                // write array elements directly to the parent (no wrapping element required)
                myElement = parentNode;
            }
            
            // encode array elements as repeated instances of this elem qname
            for (var i:int=0; i < obj.length; i++)
            {
                encodeValue(obj[i], qname, myElement);
            }
        }
        else // must be simple type
        {
            parentNode.appendChild(myElement);
            
            myElement.nodeName = XObjUtils.encodeElementTag(qname, parentNode);
            
            // Simple types fall through to here
            var valueString:String;
    
            if (typeType == XObjXMLEncoder.DATE_TYPE)
            {
                valueString = encodeDate(obj as Date, "dateTime");
            }
            else if (typeType == XObjXMLEncoder.NUMBER_TYPE)
            {
                if (obj == Number.POSITIVE_INFINITY)
                    valueString = "INF";
                else if (obj == Number.NEGATIVE_INFINITY)
                    valueString = "-INF";
                else
                {
                    var rep:String = obj.toString();
                    // see if its hex
                    var start:String = rep.substr(0, 2);
                    if (start == "0X" || start == "0x")
                    {
                        valueString = parseInt(rep).toString();
                    }
                    else
                    {
                        valueString = rep;
                    }
                }
            }
            else
            {
                valueString = obj.toString();
            }
    
            var valueNode:XMLNode = xmlDocument.createTextNode(valueString);
            myElement.appendChild(valueNode);
        }
    
        return myElement;
    }

    // set the attributes, and return a list of all propNames consumed
    private function setAttributes(node:XMLNode, obj:*):Object
    {
        var attrNames:Object = {};
        var attributes:Object = {};
        var attrList:Array = [];
        var attrSource:Object = obj;
        
        var useMeta:Boolean = ("attributes" in obj);
        
        if (useMeta)
            attrSource = obj.attributes;
            
        // get them from the __attributes structure
        if (XObjMetadata.METADATA_PROPERTY in obj)
            attrList = obj[XObjMetadata.METADATA_PROPERTY]["attributes"];
        else if (useMeta) // this is for the create case (no __ info available)
        {
            //TODO: synthesize the attrList structure
            
        }
        
        if (attrList.length > 0)
        {
            // we need to find the defaultNS first
            var defaultNS:String = null;
            var needDefault:Boolean = false;
            
            for each (var attr:* in attrList)
            {
                // do all the xmlns entries first, then everything else
                if (attr.propname == "xmlns")
                {
                    defaultNS = attrSource[attr.propname]; // observe the default namespace
                    // assume we need it
                    needDefault = true;
                    // make sure we don't write it out as an element
                    if (!useMeta)
                        attrNames["xmlns"] = true;
                    break;
                }
            }
            
            // we need to do all other xmlns entries *first* to ensure our map is built ahead
            // of subsequent attribute encodings
            var count:int=0;
            while (count < 2)
            {
                for each (attr in attrList)
                {
                    // before encoding any attributes, encode defaultNS if still
                    // required
                    if (count > 0 && needDefault)
                    {
                        attributes["xmlns"] = defaultNS;
                        needDefault = false;
                    }

                    // do all the xmlns entries first, then everything else
                    if (attr.propname == "xmlns") // observe the default namespace
                    {
                        continue;
                    }
                    else if (/xml(ns)?.*/.exec(attr.propname))
                    {
                        if (count > 0)
                            continue;
                        else if (attrSource[attr.propname] == defaultNS)
                        {
                            // strip redundant defaultNS from output
                            // bt put it in localmap for resolution to work
                            needDefault = false;
                            spacenameMap[XObjUtils.DEFAULT_NAMESPACE_PREFIX] = defaultNS;
                        }
                    }
                    else if (count == 0)
                        continue;
                        
                    
                    var name:String;
                                        
                    // finally, encode the attribute!
                    name = encodeAttrName(attr, node);
                    try
                    {
                        attributes[name] = attrSource[attr.propname];
                        if (!useMeta)
                            attrNames[attr.propname] = true;
                    }
                    catch (e:ReferenceError)
                    {
                    }
                }

            node.attributes = attributes;
            
            count++;
            }
        }
        
        return attrNames;
    }
    
    
    private function decodePartName(partQName:XObjQName, node:XMLNode):String
    {
        var partName:String = XObjUtils.getNCName(partQName.localName);
        
        var prefix:String = getLocalPrefixForNamespace(partQName.uri, node);
        
        if (prefix)
            partName =  prefix + "_" + partName;
        
        return partName;
    }

    private function getLocalPrefixForNamespace(uri:String, node:XMLNode):String
    {
        var prefix:String;
        
        prefix = namespaceMap[uri];
        if (!prefix)
        {
            prefix= node.getPrefixForNamespace(uri);
        }
        return prefix;
    }
        
    private function encodeAttrName(attr:*, node:XMLNode):String
    {
        var name:String = attr.propname;
        
        if (/xml(ns)?.*/.exec(name) )
        {
            // pluck out the namespaces...we need them early
            name = name.replace(/_/,":");
        }
        else 
        {
            var myPrefixIndex:int = name.indexOf("_");
            var prefix:String;
            
            if (myPrefixIndex != -1)
                prefix = name.substr(0,myPrefixIndex);
            else
                prefix = "";
                
            prefix = localPrefixToDocPrefix(prefix, node);
            
            // we need to map the possibly local prefix to the namespace
            // and then map that back to the right document prefix
            name = (prefix == "" ? "" : prefix +":") + name.substring(myPrefixIndex+1);
        }
        return name;
    }
    
    
    private function localPrefixToDocPrefix(prefix:String, node:XMLNode):String
    {
        var ns:String;
        
        if (prefix=="" || prefix == null)
        {
            prefix = "";
            ns = spacenameMap[XObjUtils.DEFAULT_NAMESPACE_PREFIX];
        }
        else 
            ns = spacenameMap[prefix];
            
        if (ns == null)
        {
            ns = node.getNamespaceForPrefix(prefix);
        }
        if (ns == null)
        {
            // can't find it anywhere..no default. 
        }
        
        var newPrefix:String = node.getPrefixForNamespace(ns);
        
        // assume default namespace
        if (newPrefix == null)
            newPrefix = "";
            
        return newPrefix;
    }
    

    /**
     *  @private
     */
    private function getDataTypeFromObject(obj:Object):uint
    {
        if (obj is Number)
            return XObjXMLEncoder.NUMBER_TYPE;
        else if (obj is Boolean)
            return XObjXMLEncoder.BOOLEAN_TYPE;
        else if (obj is String)
            return XObjXMLEncoder.STRING_TYPE;
        else if (obj is XMLDocument)
            return XObjXMLEncoder.XML_TYPE;
        else if (obj is Date)
            return XObjXMLEncoder.DATE_TYPE;
        else if (obj is Array)
            return XObjXMLEncoder.ARRAY_TYPE;
        else if (obj is ArrayCollection)
            return XObjXMLEncoder.ARRAY_TYPE;
        else if (obj is Function)
            return XObjXMLEncoder.FUNCTION_TYPE;
        else if (obj is Object)
            return XObjXMLEncoder.OBJECT_TYPE;
        else
            // Otherwise force it to string
            return XObjXMLEncoder.STRING_TYPE;
    }
    
    
    private static const NUMBER_TYPE:uint   = 0;
    private static const STRING_TYPE:uint   = 1;
    private static const OBJECT_TYPE:uint   = 2;
    private static const DATE_TYPE:uint     = 3;
    private static const BOOLEAN_TYPE:uint  = 4;
    private static const XML_TYPE:uint      = 5;
    private static const ARRAY_TYPE:uint    = 6;  // An array with a wrapper element
    private static const MAP_TYPE:uint      = 7;
    private static const ANY_TYPE:uint      = 8;
    // We don't appear to use this type anywhere, commenting out
    //private static const COLL_TYPE:uint     = 10; // A collection (no wrapper element, just maxOccurs)
    private static const ROWSET_TYPE:uint   = 11;
    private static const QBEAN_TYPE:uint    = 12; // CF QueryBean
    private static const DOC_TYPE:uint      = 13;
    private static const SCHEMA_TYPE:uint   = 14;
    private static const FUNCTION_TYPE:uint = 15; // We currently do not serialize properties of type function
    private static const ELEMENT_TYPE:uint  = 16;
    private static const BASE64_BINARY_TYPE:uint = 17;
    private static const HEX_BINARY_TYPE:uint = 18;
    
        
    private function tagForType(obj:*):String
    {
        if (!typeMap || !obj)
            return null;
        
        if (obj is ObjectProxy)
            obj = (obj as ObjectProxy).object_proxy::object;
        
        if (!obj)
            return null;
            
        var className:String = getQualifiedClassName(obj);
        var clazz:Class = getDefinitionByName(className) as Class;
        
        // find the corresponding type in the map
        for (var tag:String in typeMap)
        {
            if (typeMap[tag] == clazz)
                return tag;
        }
        
        // can't find it, so return something sensible, stripping off ActionScript
        // namespace
        
        className = getQualifiedClassName(clazz);
        return className.replace(/.*::/, "");
    }

}
}
