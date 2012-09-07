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
import flash.utils.Dictionary;

[RemoteClass]  // tell the compiler we can be deep copied 
public class XObjMetadata
{
    public var attributes:Array;
    public var elements:Array;
    //public var namespaces:Array;
    public var arrayEntryTag:String;  // tag to encode array element with...
    public var rootQName:XObjQName; // tag for this element itself
    public var isList:Boolean;  // means list="true" attribute present on XML
    
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