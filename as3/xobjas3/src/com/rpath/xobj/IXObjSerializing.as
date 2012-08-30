/*
#
# Copyright (c) 2007-2012 rPath, Inc.
#
# All rights reserved
#
*/

package com.rpath.xobj
{
public interface IXObjSerializing
{
    function decodeIntoObject(xobj:XObjXMLDecoder, dataNode:XML, object:Object, info:XObjDecoderInfo, isArray:Boolean, isCollection:Boolean, shouldMakeBindable:Boolean):Object;

}
}