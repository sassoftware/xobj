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
