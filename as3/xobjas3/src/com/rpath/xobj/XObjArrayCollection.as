/*
#
# Copyright (c) 2007-2011 rPath, Inc.
#
# All rights reserved
#
*/

package com.rpath.xobj
{
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;

public class XObjArrayCollection extends ArrayCollection implements IXObjCollection
{
    public function XObjArrayCollection(source:Array=null, typeMap:*=null)
    {
        super(source);
        
        if (!typeMap)
            this.type = {};
        
        this.type = typeMap;
    }
    
    
    // the type of objects we expect in the collection
    // null means unknown type. Can be a single Class
    // or a Dictionary of typeMap entries
    [xobjTransient]
    public function get type():*
    {
        return _type;
    }
    
    private var _type:*;
    
    public function set type(t:*):void
    {
        _type = t;
    }
    
    public function elementType():Class
    {
        return (type as Class);
    }
    
    public function typeMap():Dictionary
    {
        return (type as Dictionary);
    }
    
    public function elementTypeForElementName(name:String):Class
    {
        return XObjTypeMap.elementTypeForElementName(type, name);
    }
    
    public function elementTagForMember(member:*):String
    {
        return XObjTypeMap.elementTagForMember(type, member);
    }

    public function addItemIfAbsent(value:Object):Boolean
    {
        return XObjUtils.addItemIfAbsent(this, value);
    }
    
    public function removeItemIfPresent(object:Object):Boolean
    {
        return XObjUtils.removeItemIfPresent(this, public);
    }

    public function isElementMember(propName:String):Boolean
    {
       return XObjUtils.isElementMember(this, propName);
    }
    
    [xobjTransient]
    public function get isByReference():Boolean
    {
        return _isByReference;
    }
    
    private var _isByReference:Boolean;
    
    public function set isByReference(b:Boolean):void
    {
        _isByReference = b;
    }

}
}