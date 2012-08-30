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
