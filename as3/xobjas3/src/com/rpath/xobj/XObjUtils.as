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
    import flash.utils.getDefinitionByName;
    import flash.xml.XMLNode;
    
    import mx.collections.ArrayCollection;
    import mx.utils.DescribeTypeCache;

    
    public class XObjUtils
    {


    public static const DEFAULT_NAMESPACE_PREFIX:String = "_default_";

    /**
     * Returns the local name of an XMLNode.
     *
     * @return The local name of an XMLNode.
     */
    public static function getLocalName(xmlNode:XMLNode):String
    {
        return getNCName(xmlNode.nodeName);
    }

    public static function getNCName(name:String):String
    {
        var myPrefixIndex:int = name.indexOf(":");
        if (myPrefixIndex != -1)
        {
            name = name.substring(myPrefixIndex+1);
        }
        return name;
    }


    public static function encodeElementTag(qname:XObjQName, node:XMLNode):String
    {
        var elementTag:String = XObjUtils.getNCName(qname.localName);
        
        var prefix:String = node.getPrefixForNamespace(qname.uri);
        
        if (prefix)
            elementTag =  prefix + ":" + elementTag;
        
        return elementTag;
    }
        
        
        
    /**
     * Return a Class instance based on a string class name
     * @private
      */
    public static function getClassByName(className:String):Class
    {
        var classReference:Class = null;
        
        try
        {
             classReference = getDefinitionByName(className) as Class;
        } 
        catch (e:ReferenceError)
        {
            trace("Request for unknown class "+className);
        }

        return classReference;
     }    
     
    private static var typePropertyCache:Object = {};

    public static function isTypeArray(type:Class):Boolean
    {
        if (type == null)
            return false;
        
        var foo:* = new type();
        return (foo is Array);
    }

    public static function isTypeArrayCollection(type:Class):Boolean
    {
        if (type == null)
            return false;

        var foo:* = new type();
        return (type is ArrayCollection);
    }
    
    public static function typeInfoForProperty(className:String, propName:String):Object
    {
        var isArray:Boolean = false;
        var result:Object = {typeName: null, isArray: false, isArrayCollection: false};
        
        if (className == "Object" || className == "mx.utils::ObjectProxy")
            return result;
        
        var propertyCacheKey:String = className + "." + propName;
        var arrayElementType:String;
        
        result = typePropertyCache[propertyCacheKey];
            
        if (result == null)
        {
            result = {typeName: null, isArray: false, isArrayCollection: false};
            
            // go look it up (expensive)
            var typeDesc:* = DescribeTypeCache.describeType(className);
            var typeInfo:XML = typeDesc.typeDescription;
            
            result.typeName = typeInfo..accessor.(@name == propName).@type.toString().replace( /::/, "." );
            if (result.typeName == null || result.typeName == "")
            {    
                result.typeName = typeInfo..variable.(@name == propName).@type.toString().replace( /::/, "." );
                arrayElementType = typeInfo..variable.(@name == propName).metadata.(@name == 'ArrayElementType').arg.@value.toString().replace( /::/, "." );
            }
            else
                arrayElementType = typeInfo..accessor.(@name == propName).metadata.(@name == 'ArrayElementType').arg.@value.toString().replace( /::/, "." );
            
            if (result.typeName == "Array")
            {
                result.isArray = true;
                result.typeName = null; // assume generic object unless told otherwise
            }
            else if (result.typeName == "ArrayCollection")
            {
                result.isArrayCollection = true;
                result.typeName = null; // assume generic object unless told otherwise
            }
            
            if (arrayElementType != "")
            {
                // use type specified
                result.typeName = arrayElementType;
            }
            
            if (result.typeName == "Object"
                || result.typeName == "mx.utils::ObjectProxy"
                || result.typeName == "Undefined"
                || result.typeName == "*"
                || result.typeName == "")
            {
                result.typeName = null;
            }
                 
            // cache the result for next time
            typePropertyCache[propertyCacheKey] = result;
        }
        
       
        return result;
    }
    

        
    }
}