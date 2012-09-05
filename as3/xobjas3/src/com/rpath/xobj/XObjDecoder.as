/*
#
# Copyright (c) 2007-2012 rPath, Inc.
#
# All rights reserved
#
*/

package com.rpath.xobj
{
public class XObjDecoder implements IXObjSerializing
{
    public function XObjDecoder()
    {
        super();
    }
    
    public function decodeIntoObject(xobj:XObjXMLDecoder, dataNode:XML, object:Object, info:XObjDecoderInfo, isArray:Boolean, isCollection:Boolean, shouldMakeBindable:Boolean):Object
    {
        return object;
    }
    
    public function isTrue(xml:XMLList):Boolean
    {
        var l:String = xml.toString().toLowerCase();
        return (l == "true" || l == 'T' || l == "1");
    }
}
}