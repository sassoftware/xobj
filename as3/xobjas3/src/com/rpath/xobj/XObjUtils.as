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
    import flash.utils.getQualifiedClassName;
    import flash.xml.XMLNode;
    
    import mx.collections.ArrayCollection;
    import mx.utils.DescribeTypeCache;
    import mx.utils.ObjectProxy;
    import mx.utils.object_proxy;
    use namespace object_proxy;
    
    public class XObjUtils
    {


        public static const DEFAULT_NAMESPACE_PREFIX:String = "_default_";
        
        /**
         * @private
         */ 
        private static var CLASS_INFO_CACHE:Object = {};
    
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

        /**
         * Return a Class instance based on a string class name
         * @private
          */
        public static function classOf(obj:*):Class
        {
            var className:String = getQualifiedClassName(obj);
            var classReference:Class = getClassByName(className);
            
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
            return (foo is ArrayCollection);
        }
        
        public static function typeInfoForProperty(object:*, className:String, propName:String):Object
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
                // very important to use the instance object here, not the classname
                // using the classname results in the typeInfo cache
                // returning class not instance info later on! Bad cache!
                var typeDesc:* = DescribeTypeCache.describeType(object);
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
                else if (result.typeName == "mx.collections.ArrayCollection")
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
    
        /**
         * Use our own version of getClassInfo to support various metadata
         * tags we use.  See ObjectUtil.getClassInfo for more info about
         * the basic functionality of this method.
         */  
        public static function getClassInfo(obj:Object,
                                            excludes:Array = null,
                                            options:Object = null):Object
        {   
            var n:int;
            var i:int;
    
            if (obj is ObjectProxy)
                obj = ObjectProxy(obj).object_proxy::object;
    
            if (options == null)
                options = { includeReadOnly: true, uris: null, includeTransient: true };
    
            var result:Object;
            var propertyNames:Array = [];
            var cacheKey:String;
    
            var className:String;
            var classAlias:String;
            var properties:XMLList;
            var prop:XML;
            var dynamic:Boolean = false;
            var metadataInfo:Object;
    
            if (typeof(obj) == "xml")
            {
                className = "XML";
                properties = obj.text();
                if (properties.length())
                    propertyNames.push("*");
                properties = obj.attributes();
            }
            else
            {
                var classInfo:XML = DescribeTypeCache.describeType(obj).typeDescription;
                className = classInfo.@name.toString();
                classAlias = classInfo.@alias.toString();
                dynamic = (classInfo.@isDynamic.toString() == "true");
    
                if (options.includeReadOnly)
                    properties = classInfo..accessor.(@access != "writeonly") + classInfo..variable;
                else
                    properties = classInfo..accessor.(@access == "readwrite") + classInfo..variable;
    
                var numericIndex:Boolean = false;
            }
    
            // If type is not dynamic, check our cache for class info...
            if (!dynamic)
            {
                cacheKey = getCacheKey(obj, excludes, options);
                result = CLASS_INFO_CACHE[cacheKey];
                if (result != null)
                    return result;
            }
    
            result = {};
            result["name"] = className;
            result["alias"] = classAlias;
            result["properties"] = propertyNames;
            result["dynamic"] = dynamic;
            result["metadata"] = metadataInfo = recordMetadata(properties);
            
            var excludeObject:Object = {};
            if (excludes)
            {
                n = excludes.length;
                for (i = 0; i < n; i++)
                {
                    excludeObject[excludes[i]] = 1;
                }
            }
    
            //TODO this seems slightly fragile, why not use the 'is' operator?
            var isArray:Boolean = (className == "Array");
            var isDict:Boolean  = (className == "flash.utils::Dictionary");
            
            if (isDict)
            {
                // dictionaries can have multiple keys of the same type,
                // (they can index by reference rather than QName, String, or number),
                // which cannot be looked up by QName, so use references to the actual key
                for (var key:* in obj)
                {
                    propertyNames.push(key);
                }
            }
            else if (dynamic)
            {
                for (var p:String in obj)
                {
                    if (excludeObject[p] != 1)
                    {
                        if (isArray)
                        {
                             var pi:Number = parseInt(p);
                             if (isNaN(pi))
                                propertyNames.push(new QName("", p));
                             else
                                propertyNames.push(pi);
                        }
                        else
                        {
                            propertyNames.push(new QName("", p));
                        }
                    }
                }
                numericIndex = isArray && !isNaN(Number(p));
            }
    
            if (isArray || isDict || className == "Object")
            {
                // Do nothing since we've already got the dynamic members
            }
            else if (className == "XML")
            {
                n = properties.length();
                for (i = 0; i < n; i++)
                {
                    p = properties[i].name();
                    if (excludeObject[p] != 1)
                        propertyNames.push(new QName("", "@" + p));
                }
            }
            else
            {
                n = properties.length();
                var uris:Array = options.uris;
                var uri:String;
                var qName:QName;
                for (i = 0; i < n; i++)
                {
                    prop = properties[i];
                    p = prop.@name.toString();
                    uri = prop.@uri.toString();
                    
                    if (excludeObject[p] == 1)
                        continue;
                        
                    if (!options.includeTransient && internalHasMetadata(metadataInfo, p, "Transient"))
                        continue;
                        
                    if (internalHasMetadata(metadataInfo, p, "xobjTransient"))
                        continue;
                    
                    if (uris != null)
                    {
                        if (uris.length == 1 && uris[0] == "*")
                        {   
                            qName = new QName(uri, p);
                            try
                            {
                                obj[qName]; // access the property to ensure it is supported
                                propertyNames.push();
                            }
                            catch(e:Error)
                            {
                                // don't keep property name 
                            }
                        }
                        else
                        {
                            for (var j:int = 0; j < uris.length; j++)
                            {
                                uri = uris[j];
                                if (prop.@uri.toString() == uri)
                                {
                                    qName = new QName(uri, p);
                                    try
                                    {
                                        obj[qName];
                                        propertyNames.push(qName);
                                    }
                                    catch(e:Error)
                                    {
                                        // don't keep property name 
                                    }
                                }
                            }
                        }
                    }
                    else if (uri.length == 0)
                    {
                        qName = new QName(uri, p);
                        try
                        {
                            obj[qName];
                            propertyNames.push(qName);
                        }
                        catch(e:Error)
                        {
                            // don't keep property name 
                        }
                    }
                }
            }
    
            propertyNames.sort(Array.CASEINSENSITIVE |
                               (numericIndex ? Array.NUMERIC : 0));
    
            // dictionary keys can be indexed by an object reference
            // there's a possibility that two keys will have the same toString()
            // so we don't want to remove dupes
            if (!isDict)
            {
                // for Arrays, etc., on the other hand...
                // remove any duplicates, i.e. any items that can't be distingushed by toString()
                for (i = 0; i < propertyNames.length - 1; i++)
                {
                    // the list is sorted so any duplicates should be adjacent
                    // two properties are only equal if both the uri and local name are identical
                    if (propertyNames[i].toString() == propertyNames[i + 1].toString())
                    {
                        propertyNames.splice(i, 1);
                        i--; // back up
                    }
                }
            }
    
            // For normal, non-dynamic classes we cache the class info
            if (!dynamic)
            {
                cacheKey = getCacheKey(obj, excludes, options);
                CLASS_INFO_CACHE[cacheKey] = result;
            }
    
            return result;
        }
        
        public static function getSuperclasses(object:*):Array
        {
            var result:Array = [];
            var classInfo:XML = DescribeTypeCache.describeType(object).typeDescription;
            
            for each (var superClass:XML in classInfo.extendsClass)
            {
                result.push(getClassByName(superClass.@type));
            }
            return result;
        }
        
            
        /**
         *  @private
         */
        private static function internalHasMetadata(metadataInfo:Object, propName:String, metadataName:String):Boolean
        {
            if (metadataInfo != null)
            {
                var metadata:Object = metadataInfo[propName];
                if (metadata != null)
                {
                    if (metadata[metadataName] != null)
                        return true;
                }
            }
            return false;
        }
    
        /**
         *  @private
         */
        private static function recordMetadata(properties:XMLList):Object
        {
            var result:Object = null;
    
            try
            {
                for each (var prop:XML in properties)
                {
                    var propName:String = prop.attribute("name").toString();
                    var metadataList:XMLList = prop.metadata;
    
                    if (metadataList.length() > 0)
                    {
                        if (result == null)
                            result = {};
    
                        var metadata:Object = {};
                        result[propName] = metadata;
    
                        for each (var md:XML in metadataList)
                        {
                            var mdName:String = md.attribute("name").toString();
                            
                            var argsList:XMLList = md.arg;
                            var value:Object = {};
    
                            for each (var arg:XML in argsList)
                            {
                                var argKey:String = arg.attribute("key").toString();
                                if (argKey != null)
                                {
                                    var argValue:String = arg.attribute("value").toString();
                                    value[argKey] = argValue;
                                }
                            }
    
                            var existing:Object = metadata[mdName];
                            if (existing != null)
                            {
                                var existingArray:Array;
                                if (existing is Array)
                                    existingArray = existing as Array;
                                else
                                    existingArray = [];
                                existingArray.push(value);
                                existing = existingArray;
                            }
                            else
                            {
                                existing = value;
                            }
                            metadata[mdName] = existing;
                        }
                    }
                }
            }
            catch(e:Error)
            {
            }
            
            return result;
        }
    
    
        /**
         *  @private
         */
        private static function getCacheKey(o:Object, excludes:Array = null, options:Object = null):String
        {
            var key:String = getQualifiedClassName(o);
    
            if (excludes != null)
            {
                for (var i:uint = 0; i < excludes.length; i++)
                {
                    var excl:String = excludes[i] as String;
                    if (excl != null)
                        key += excl;
                }
            }
    
            if (options != null)
            {
                for (var flag:String in options)
                {
                    key += flag;
                    var value:String = options[flag] as String;
                    if (value != null)
                        key += value;
                }
            }
            return key;
        }
    }
}