/*
#
# Copyright (c) 2009 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found 
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any warranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.
*/

package com.rpath.xobj
{
import flash.errors.StackOverflowError;
import flash.utils.Dictionary;
import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;
import flash.xml.XMLNode;

import mx.collections.ArrayList;
import mx.collections.ICollectionView;
import mx.collections.IList;
import mx.utils.ArrayUtil;
import mx.utils.DescribeTypeCache;
import mx.utils.ObjectProxy;
import mx.utils.ObjectUtil;
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
    
    public static function safeGetPrefixForNamespace(node:XMLNode, uri:String):String
    {
        var result:String;
        
        try
        {
            result = node.getPrefixForNamespace(uri);
        }
        catch (e:StackOverflowError)
        {
            // occasional bug in flash runtime???
            trace("getPrefixForNamespace stack overflow caught");
            result = "";
        }
        
        return result;
    }
    
    
    public static function encodeElementTag(qname:XObjQName, node:XMLNode):String
    {
        var elementTag:String = XObjUtils.getNCName(qname.localName);
        
        var prefix:String = XObjUtils.safeGetPrefixForNamespace(node, qname.uri);
        
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
        
        if (!className)
            return null;
        
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
    
    public static function getClassName(obj:*):String
    {
        var className:String = (obj == null) ? null : getQualifiedClassName(obj);
        
        className = className.replace( /::/, "." );
        return className;
    }
    
    /**
     * Return a Class instance based on a string class name
     * @private
     */
    public static function classOf(obj:*):Class
    {
        var className:String = getClassName(obj);
        var classReference:Class = getClassByName(className);
        
        return classReference;
    }
    
    public static function getClass(obj:*):Class
    {
        return classOf(obj);
    }
    
    public static function newInstanceOfSameClass(value:*):*
    {
        var clazz:Class = XObjUtils.classOf(value);
        var newObj:Object = new clazz();
        return newObj;
    }
    
    private static var typePropertyCache:Dictionary = new Dictionary(true);
    
    private static var arrayTypeCache:Dictionary = new Dictionary(true);
    private static var listCollectionTypeCache:Dictionary = new Dictionary(true);
    
    public static function isTypeArray(type:*):Boolean
    {
        var result:Boolean;
        
        if (type == null || type == "")
            return false;
        
        if (type == "*")
            return true; // unknown type can be array...
        
        if (type is String)
            type = getClassByName(type);
        
        result = arrayTypeCache[type];
        if (arrayTypeCache[type] == undefined)
        {
            var typeDesc:* = DescribeTypeCache.describeType(type);
            var typeDescInfo:XML = typeDesc.typeDescription;
            
            try
            {
                // TODO: better way to detect an arry subclass?
                var foo:* = new type();
                result = isArray(foo);
                // do the array collection test while we're here, to save time
                listCollectionTypeCache[type] = isCollection(foo);
            }
            catch (e:VerifyError) // Means we're an non-constructable interface
            {
                var impl:XML;
                var interfaceType:String;
                
                for each (impl in typeDescInfo..implementsInterface)
                {
                    interfaceType = impl.@type.toString().replace( /::/, "." );
                    if (isTypeArray(interfaceType))
                    {
                        result = true;
                        break;
                    }
                }
            }
            
            arrayTypeCache[type] = result;
        }
        return result;
    }
    
    public static function isArray(obj:Object):Boolean
    {
        return (obj is Array || obj is ArrayList || obj is Vector);
    }
    
    public static function isTypeCollection(type:*):Boolean
    {
        var result:Boolean;
        
        if (type == null || type == "")
            return false;
        
        if (type == "*")
            return true; // unknown type can be arraycollection too...
        
        if (type is String)
            type = getClassByName(type);
        
        if (type == IXObjCollection || type == ICollectionView)
            return true;
        
        result = listCollectionTypeCache[type];
        if (listCollectionTypeCache[type] == undefined)
        {
            var typeDesc:* = DescribeTypeCache.describeType(type);
            var typeDescInfo:XML = typeDesc.typeDescription;
            
            try
            {
                // TODO: better way to detect an arry subclass?
                var foo:* = new type();
                result = isCollection(foo);
                
                // do the array test while we're here, to save time
                arrayTypeCache[type] = isArray(foo);
            }
            catch (e:VerifyError) // Means we're an non-constructable interface
            {
                var impl:XML;
                var interfaceType:String;
                
                for each (impl in typeDescInfo..implementsInterface)
                {
                    interfaceType = impl.@type.toString().replace( /::/, "." );
                    if (isTypeCollection(interfaceType))
                    {
                        result = true;
                        break;
                    }
                }
            }
            
            listCollectionTypeCache[type] = result;
        }
        return result;
    }
    
    public static function isCollection(obj:Object):Boolean
    {
        return (obj is ICollectionView) || (obj is IXObjCollection);
    }
    
    public static function typeInfoForProperty(object:*, className:String, propName:String):XObjTypeInfo
    {
        var isArray:Boolean = false;
        var typeInfo:XObjTypeInfo;
        var shouldCache:Boolean = true;
        var isDynamic:Boolean;
        
        if (className == "Object" || className == "mx.utils::ObjectProxy")
            return new XObjTypeInfo();
        
        if (className == "String")
        {
            // Simple String doesn't have any properties
            return new XObjTypeInfo();
        }
        
        if (!propName)
            return new XObjTypeInfo();
        
        var propertyCacheKey:String = className + "." + propName;
        var arrayElementType:String;
        
        typeInfo = typePropertyCache[propertyCacheKey];
        
        if (typeInfo == null)
        {
            typeInfo = new XObjTypeInfo();
            
            // go look it up (expensive)
            // very important to use the instance object here, not the classname
            // using the classname results in the typeInfo cache
            // returning class not instance info later on! Bad cache!
            var typeDesc:* = DescribeTypeCache.describeType(object);
            var typeDescInfo:XML = typeDesc.typeDescription;
            
            if (typeDescInfo.@isDynamic == 'true')
            {
                isDynamic = true;
            }
            
            var accessorList:XMLList = typeDescInfo..accessor.(@name == propName);
            
            if (accessorList.length() > 0)
                typeInfo.typeName = accessorList[0].@type.toString().replace( /::/, "." );
            
            if (!typeInfo.typeName)
            {    
                typeInfo.typeName = typeDescInfo..variable.(@name == propName).@type.toString().replace( /::/, "." );
                
                if (!typeInfo.typeName)
                {
                    // neither accessor nor variable. It's either a function or a dynamic property
                    if (propName in object)
                    {
                        var val:* = object[propName];
                        if (val is Function)
                        {
                            // can't handle these...
                        }
                        else
                        {
                            // must be dynamic property or simply an error (no such property)
                            typeInfo.typeName = XObjUtils.getClassName(val);
                            // don't cache if dynamic
                            if (isDynamic)
                                shouldCache = false;
                        }
                    }
                    else
                    {
                        // bad request. no such property
                    }
                }
                else
                {
                    arrayElementType = typeDescInfo..variable.(@name == propName).metadata.(@name == 'ArrayElementType').arg.@value.toString().replace( /::/, "." );
                    if (!arrayElementType)
                    {
                        // maybe it's a specific desired type using xobj metadata marker
                        arrayElementType = typeDescInfo..variable.(@name == propName).metadata.(@name == 'ElementType').arg.@value.toString().replace( /::/, "." );
                    }
                }
            }
            else
            {
                arrayElementType = typeDescInfo..accessor.(@name == propName).metadata.(@name == 'ArrayElementType').arg.@value.toString().replace( /::/, "." );
                if (!arrayElementType)
                {
                    // maybe it's a specific desired type using xobj metadata marker
                    arrayElementType = typeDescInfo..accessor.(@name == propName).metadata.(@name == 'ElementType').arg.@value.toString().replace( /::/, "." );
                }
            }
            
            if (arrayElementType)
            {
                typeInfo.isCollection = true;
                typeInfo.arrayElementTypeName = arrayElementType;
                typeInfo.arrayElementClass = XObjUtils.getClassByName(typeInfo.arrayElementTypeName);
            }
            else // can't infer, so go ask directly
            {
                typeInfo.isArray = isTypeArray(typeInfo.typeName);
                typeInfo.isCollection = isTypeCollection(typeInfo.typeName);
            }
            
            if (typeInfo.typeName == "Object"
                || typeInfo.typeName == "mx.utils::ObjectProxy"
                || typeInfo.typeName == "Undefined"
                || typeInfo.typeName == "*"
                || typeInfo.typeName == "")
            {
                typeInfo.typeName = null;
            }
            
            // and finally, lookup the actual Class object for the typeName
            if (typeInfo.typeName)
            {
                typeInfo.type = XObjUtils.getClassByName(typeInfo.typeName);
            }
            
            // ask if this is a member of not
            if (object is IXObjCollection)
            {
                typeInfo.isMember = (object as IXObjCollection).isElementMember(propName);
            }
            
            // cache the result for next time
            if (shouldCache)
                typePropertyCache[propertyCacheKey] = typeInfo;
        }
        
        
        return typeInfo;
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
    
    public static function getClassHeirarchy(object:*):Array
    {
        var result:Array = getSuperclasses(object);
        
        result.splice(0,0, classOf(object));
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
    
    public static function addItemIfAbsent(set:*, item:*):Boolean
    {
        var result:Boolean;
        var arr:Array = set as Array;
        var coll:IList = set as IList;
        var xobjColl:IXObjCollection = set as IXObjCollection;
        
        if (xobjColl)
        {
            xobjColl.addItemIfAbsent(item);
            result = true;
        }
        else if (arr)
        {
            if (arr.indexOf(item) == -1)
            {
                arr.push(item);
                result = true;
            }
        }
        else if (coll)
        {
            if (coll.getItemIndex(item) == -1)
            {
                coll.addItem(item);
                result = true;
            }
        }
        
        
        return result;
    }
    
    public static function removeItemIfPresent(set:*, item:*):Boolean
    {
        var result:Boolean;
        var arr:Array = set as Array;
        var coll:IList = set as IList;
        var index:int;
        var xobjColl:IXObjCollection = set as IXObjCollection;
        
        if (arr)
        {
            index = arr.indexOf(item);
            if (index > -1)
            {
                arr.splice(index,1);
                result = true;
            }
        }
        else if (coll)
        {
            index = coll.getItemIndex(item);
            if (index > -1)
            {
                coll.removeItemAt(index);
                result = true;
            }
        }
        else if (xobjColl)
        {
            xobjColl.removeItemIfPresent(item);
            result = true;
        }
        return result;            
    }
    
    public static function shallowCopy(value:*):*
    {
        var clazz:Class = XObjUtils.classOf(value);
        
        return copyCast(value, clazz);
    }
    
    public static function copyCast(value:*, clazz:Class):*
    {
        var newObj:Object = new clazz();
        var hasID:Boolean = newObj.hasOwnProperty("id");
        var tempID:String;
        
        // TODO: why did we need this again?
        if (hasID)
            tempID = newObj.id
        
        XObjUtils.copyProps(newObj, value);
        
        if (hasID)
            newObj.id = tempID;
        
        return newObj;
        
    }
    
    
    /*
    CopyProps copies the properties from an object, typically obtained from a remote
    service, across to a given target object
    
    We do this so that non-typed objects from the wire can be marshalled into typed objects
    locally 
    */
    
    import flash.utils.describeType;
    
    static public function copyProps(newObj:*, otherObj:*, copyTransients:Boolean=false) : void
    {
        // are these actually the same instance?
        if (newObj === otherObj)
            return;
        
        // NOTE DO NOT CHANGE THIS TO XOBJUTILS VERSION
        // we actually WANT xobjTransients copied across in this case
        // since this method is used for cloning obejcts and when pulling
        // fresh data off the wire in PUT/GET/POST cases
        
        var otarget:Object = ObjectUtil.getClassInfo(newObj);
        var osource:Object = ObjectUtil.getClassInfo(otherObj);
        var targetTypeInfo:XML = DescribeTypeCache.describeType(newObj).typeDescription;
        var sourceTypeInfo:XML = DescribeTypeCache.describeType(otherObj).typeDescription;
        var access:String;
        
        // first copy all the properties defined on the target instance
        for each (var prop:* in otarget.properties)
        {
            try
            {
                // NOTE: we use an intermediate var to trip any exception before
                // attempting to assign to ensure setters aren't called unless prop exists
                var x:* = otherObj[prop.localName];
                if (x == undefined) continue;
                
                var propType:String = targetTypeInfo..accessor.(@name==prop.localName).@type;
                if (propType == "")
                    propType = targetTypeInfo..variable.(@name==prop.localName).@type;
                
                var transient:String = targetTypeInfo..accessor.(@name==prop.localName)..metadata.(@name=='Transient').@name;
                
                if (!copyTransients && transient != "")
                    continue;
                
                if (propType == "Array")
                {
                    if (x is ObjectProxy)
                        newObj[prop.localName] = ArrayUtil.toArray(x.item);
                    else
                        newObj[prop.localName] = ArrayUtil.toArray(x);
                }
                else if (propType == "mx.collections::ArrayCollection")
                {
                    if (x is ObjectProxy)
                        newObj[prop.localName] = CollectionUtil.objectToCollection(x.item);
                    else
                        newObj[prop.localName] = CollectionUtil.objectToCollection(x);
                }
                else
                    newObj[prop.localName] = x;
            }
            catch (exception:Error)
            {
                // ignore errors since they're either "no such property" or they are "readonly" 
                // and it's quicker to simply ignore the exceptions than do all that XML munging
                // into the classInfo structs
            }
        }
        
        // the copy all the props from the source instance to pick up dynamic stuff from server
        for each (var prop2:* in osource.properties)
        {
            // yes, we might copy the same prop in both cases, but it's cheap...
            try
            {
                // NOTE: we use an intermediate var to trip any exception before
                // attempting to assign to ensure setters aren't called unless prop exists
                var x2:* = otherObj[prop2.localName];
                if (x2 == undefined) continue;
                
                transient = sourceTypeInfo..accessor.(@name==prop2.localName)..metadata.(@name=='Transient').@name;
                
                if (!copyTransients && transient != "")
                    continue;
                
                newObj[prop2.localName] = x2;
            }
            catch (error:Error)
            {
                // again, ignore errors since they're either "no such property" or they are "readonly" 
                // and it's quicker to simply ignore the exceptions than do all that XML munging
                // into the classInfo structs
            }
        }
        
    }
    
    public static function isByReference(obj:Object):Boolean
    {
        return ((obj is IXObjReference) && (obj as IXObjReference).isByReference)
            || (("isByReference" in obj) && obj["isByReference"]);
    }
    
    public static function isElementMember(obj:Object, propName:String):Boolean
    {
        var bMember:Boolean = !obj.hasOwnProperty(propName);
        return bMember;
    }
}
}