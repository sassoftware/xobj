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
public class XObjTypeInfo
{
    public function XObjTypeInfo()
    {
        super();
    }
    
    //public var holderClass:Class;
    public var holderClassName:String;
    
    public var propName:String;
    public var elementTag:String;
    public var type:Class;
    public var typeName:String;
    public var isSimpleType:Boolean;

    public var isArray:Boolean;
    public var isCollection:Boolean;
    public var isMember:Boolean;
    public var isDynamic:Boolean;
    public var isAttribute:Boolean;
    
    public var arrayElementTypeName:String;
    public var arrayElementClass:Class;
    
    public var seen:Boolean; // tells us whether we've actually seen this as a property
}
}
