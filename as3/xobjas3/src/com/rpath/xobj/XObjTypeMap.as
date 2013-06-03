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
public class XObjTypeMap
{
    public function XObjTypeMap()
    {
        super();
    }
    
    public static function elementTypeForElementName(typeMap:*, name:String):Class
    {
        // do we have a type Map?
        if (typeMap as Class)
        {
            return (typeMap as Class);
        }
        else if (typeMap is Function)
        {
            return (typeMap as Function)(name);
        }
        else if (typeMap)
        {
            // assume dict
            return typeMap[name];
        }
        else
            return null;
        
    }
    
    public static function elementTagForMember(obj:*, typeMap:*, member:*):String
    {
        var clazz:Class;
        
        if (member is Class)
        {
            clazz = member;
        }
        else if (member is String)
        {
            clazz = XObjUtils.getClassByName(member);
        }
        else if (member is Object)
        {
            clazz = XObjUtils.getClass(member);
        }
        
        // do we have a type Map?
        if (typeMap as Class)
        {
            if (clazz === typeMap)
                return XObjUtils.getClassName(clazz); // we do not know
        }
        else if (typeMap is Function)
        {
            return XObjUtils.getClassName(clazz); // we do not know
        }
        else if (typeMap)
        {
            // assume dict
            for (var key:String in typeMap)
            {
                if (typeMap[key] === clazz)
                    return key
            }
        }
        else 
        {
            // do we have meta?
            var meta:XObjMetadata = XObjMetadata.getMetadata(obj, false);
            if (meta && meta.arrayEntryTag)
                return meta.arrayEntryTag;
        }

        return "item";  // we do not know
    }
}
}
