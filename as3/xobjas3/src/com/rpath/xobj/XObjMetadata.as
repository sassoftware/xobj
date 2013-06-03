/*
 * Copyright (c) SAS Institute Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


package com.rpath.xobj
{
import flash.utils.Dictionary;

[RemoteClass]  // tell the compiler we can be deep copied 
public class XObjMetadata
{
    public var attributes:Array;
    public var elements:Array;
    //public var namespaces:Array;
    public var arrayEntryTag:String;  // tag to encode array element with...
    public var rootQName:XObjQName; // tag for this element itself

    public var isList:Boolean; //special handling for the list="true" marker
    
    public static const METADATA_PROPERTY:String = "_xobj";
    
    private static var _meta:Dictionary = new Dictionary(true);
    
    public function XObjMetadata()
    {
        
        super();
        
        attributes = [];
        elements = [];
        //namespaces = [];
    }
    
    public static function getMetadata(target:*, create:Boolean=true):XObjMetadata
    {
        var result:XObjMetadata = null;
        
        if (!target)
            return null;
        
        if (METADATA_PROPERTY in target)
        {
            result = target[METADATA_PROPERTY];
        }
        else
            result = _meta[target];
            
        if (!result && create) // doesn't exist. Try creating it
        {
            try
            {
                target[METADATA_PROPERTY] = new XObjMetadata();
                target.setPropertyIsEnumerable(METADATA_PROPERTY, false);
                result = target[METADATA_PROPERTY];
            }
            catch (e:Error)
            {
                // must be nondynamic type
                // use our global dict
                result = new XObjMetadata();
                _meta[target] = result;
            }
        }
        
        return result;
    }
    
    public static function setElements(target:*, elements:Array):void
    {
        var xobj:XObjMetadata = getMetadata(target);
        if (xobj)
        {
            xobj.elements = elements;
        }
    }
    
    public static function setAttributes(target:*, attributes:Array):void
    {
        var xobj:XObjMetadata = getMetadata(target);
        if (xobj)
        {
            if (attributes.length == 0)
                trace("damn!");
            
            xobj.attributes = attributes;
        }
    }
    
    public static function addAttribute(target:*, entry:*):void
    {
        var xobj:XObjMetadata = getMetadata(target);
        if (xobj)
        {
            xobj.addAttribute(entry);
        }
    }

    public static function addElement(target:*, entry:*):void
    {
        var xobj:XObjMetadata = getMetadata(target);
        if (xobj)
        {
            xobj.addElement(entry);
        }
    }
    
    public function addAttribute(entry:*):void
    {
        if (entry is String)
            entry = {propname: entry};
        
        attributes.push(entry);
    }
    
    public function addElement(entry:*):void
    {
        elements.push(entry);
    }
    
    /** addAttrIfAbsent checks for attr.propname uniqueness
    */
    
    public function addAttrIfAbsent(attr:*):void
    {
        for each (var entry:Object in attributes)
        {
            if (entry.propname == attr.propname)
                return;
        }
        
        attributes.push(attr);
    }
    
    public static function addAttrIfAbsent(attrList:Array, attr:String):Array
    {
        for each (var entry:Object in attrList)
        {
            if (entry.propname == attr)
                return attrList;
        }
        
        attrList.push({propname: attr});
        return attrList;
    }
    
    public function removeAttr(attr:*):void
    {
        var index:int = 0;
        for each (var entry:Object in attributes)
        {
            if (entry.propname == attr.propname)
            {
                attributes.splice(index, 1);
                break;
            }
            index++;
        }
    }
    
    public static function removeAttr(attrList:Array, attr:String):Array
    {
        var index:int = 0;
        for each (var entry:Object in attrList)
        {
            if (entry.propname == attr)
            {
                attrList.splice(index, 1);
                break;
            }
            index++;
        }
        return attrList;
    }

    public static function isPropByRef(classInfo:Object, propName:String):Boolean
    {
        var metadata:Object;
        var result:Boolean;
        
        if (classInfo)
        {
            metadata = classInfo.metadata;
            if (propName && metadata && (propName in metadata))
            {
                result = ("xobjByReference" in metadata[propName]);
            }
        }
        
        return result;
    }
    
}
}
