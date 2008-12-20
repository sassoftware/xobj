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

    public static function isTypeArray(typeName:String):Boolean
    {
        // TODO: figure out how to generically detect a collection subtype
        return (typeName == "Array");
    }

    public static function isTypeArrayCollection(typeName:String):Boolean
    {
        // TODO: figure out how to generically detect a collection subtype
        return (typeName == "mx.collections::ArrayCollection");
    }
    
    public static function typeNameForProperty(className:String, propName:String):String
    {
        //var className:String = getQualifiedClassName(obj);
        
        if (className == "Object" || className == "mx.utils::ObjectProxy")
            return null;
        
        var propertyClassName:String;
        var propertyCacheKey:String = className + "." + propName;
        
        propertyClassName = typePropertyCache[propertyCacheKey];
            
        if (propertyClassName == null)
        {
            // go look it up (expensive)
            var typeDesc:* = DescribeTypeCache.describeType(className);
            var typeInfo:XML = typeDesc.typeDescription;
            
            propertyClassName = typeInfo..accessor.(@name == propName).@type.toString().replace( /::/, "." );
            if (propertyClassName == null || propertyClassName == "")
            {    
                propertyClassName = typeInfo..variable.(@name == propName).@type.toString().replace( /::/, "." );
            }
            
            if (propertyClassName == null || propertyClassName == "")
                propertyClassName = "Undefined";
            
                
            // cache the result for next time
            typePropertyCache[propertyCacheKey] = propertyClassName;
        }
        
        if (propertyClassName == "Object" || propertyClassName == "mx.utils::ObjectProxy")
            return null;
            
        return (propertyClassName != "Undefined") ? propertyClassName : null;
    }
    
    
    }
}