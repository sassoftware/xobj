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


////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2005-2007 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

/**
 * This internal utility class is used by SimpleXMLDecoder. The class is
 * basically a dynamic version of the String class (other properties can be
 * attached to it).
 *
 * When you try to get the value of a XObjString, we attempt to convert the
 * value to a number or boolean before returning it.
 *
 * @private
 */


[RemoteClass]  // tell the compiler we can be deep copied 
public dynamic class XObjString
{
    
    [Bindable]
    public var value:String;
    
/*    public var _xobj:XObjMetadata;
*/    
    public function XObjString(val:*=null)
    {
        super();
        
        value = val;
/*        _xobj = new XObjMetadata();
*/    }
    
    public function toString():String
    {
        return value;
    }
    
    public function valueOf():Object
    {
        return XObjXMLDecoder.simpleType(value);
    }
}

}
