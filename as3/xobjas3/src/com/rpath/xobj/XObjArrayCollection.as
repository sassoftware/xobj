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

import mx.collections.ArrayCollection;

[Bindable]
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
        return XObjTypeMap.elementTagForMember(this, type, member);
    }

    public function addItemIfAbsent(value:Object):Boolean
    {
        if (getItemIndex(value) == -1)
        {
            addItem(value);
            return true;
        }
        return false;
    }
    
    public function removeItemIfPresent(object:Object):Boolean
    {
        return XObjUtils.removeItemIfPresent(this, object);
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
