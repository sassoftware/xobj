package com.rpath.xobj
{
    import flash.net.registerClassAlias;
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;
    
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
 * When you try to get the value of a ComplexString, we attempt to convert the
 * value to a number or boolean before returning it.
 *
 * @private
 */

[RemoteClass]  // tell the compiler we can be deep copied 
public dynamic class XObjString
{

    public var value:String;

    public var _xobj:XObjMetadata;
    
    public function XObjString(val:*=null)
    {
        super();
            
        value = val;
        _xobj = new XObjMetadata();
    }

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
