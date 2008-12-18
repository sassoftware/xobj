package com.rpath.xobj
{
    import flash.xml.XMLNode;
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;
    import flash.xml.XMLNodeType;
    
    import mx.collections.ArrayCollection;
    import mx.utils.DescribeTypeCache;
    import mx.utils.ObjectProxy;

    
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
        if (className != "Object")
        {
            var classReference:Class = getDefinitionByName(className) as Class;
            return classReference;
        } 
        else
        {
            return Object;
        }

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