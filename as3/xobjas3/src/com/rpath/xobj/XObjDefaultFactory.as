/*
# Copyright (c) 2008-2010 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any warranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.
#
*/

package com.rpath.xobj
{
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;

public class XObjDefaultFactory implements IXObjFactory
{
    public function XObjDefaultFactory()
    {
        super();
    }
    
    public static var idMap:Dictionary = new Dictionary(true);
    
    public function newObject(type:Class, id:String):Object
    {
        var result:Object;
        
        result = new type();
        if (id && result.hasOwnProperty("id"))
        {
            result.id = id;
            idMap[id] = result;
        }
        return result;
    }
    
    public function getObjectForId(id:String):Object
    {
        return idMap[id];
    }
    
    public function trackObjectById(item:Object, id:String):void
    {
        if (item)
        {
            item.id = id;
            idMap[id] = item;
        }
    }
    
    public function newCollectionFrom(item:*):*
    {
        var result:ArrayCollection;
        
        if (!(item is Array))
            item = [item];
        
        result = new ArrayCollection(item);
        return result;
    }
    
    
}
}