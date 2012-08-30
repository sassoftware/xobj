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
        if (id && ("id" in result))
        {
            result.id = id;
            idMap[id] = result;
        }
        return result;
    }
    
    public function getObjectForId(id:String):Object
    {
        if (id)
            return idMap[id];
        else
            return null;
    }
    
    public function trackObjectById(item:Object, id:String):void
    {
        if (!id)
            return;
        
        if (item)
        {
            if ("id" in item)
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
    
    
    public static var decoderMap:Dictionary = new Dictionary();
    public static var decoderInstanceMap:Dictionary = new Dictionary();
    
    public static function registerDecoderClassForClass(decoderClass:Class, clazz:Class):void
    {
        decoderMap[clazz] = decoderClass;
    }
    
    
    public static function registerDecoderForClass(decoder:XObjDecoder, clazz:Class):void
    {
        decoderInstanceMap[clazz] = decoder;
    }
    
    public function getDecoderForObject(object:Object):IXObjSerializing
    {
        var objClass:Class;
        var decoder:XObjDecoder;
        var decoderClass:Class;
        
        // self serializing?
        if (object is IXObjSerializing)
        {
            return object as IXObjSerializing;
        }
        
        objClass = XObjUtils.getClass(object);
        if (!objClass)
            return null;
        
        decoder = decoderInstanceMap[objClass];
        if (!decoder)
        {
            decoderClass = decoderMap[objClass];
            if (!decoderClass)
            {
                // what about models that link their own decoders?
                if (objClass.hasOwnProperty("decoderClass"))
                {
                    decoderClass = objClass["decoderClass"];
                }
            }
            
            if (decoderClass)
            {
                decoder = new decoderClass();
                decoderInstanceMap[objClass] = decoder;
            }
        }
        
        return decoder;
    }
    
}
}