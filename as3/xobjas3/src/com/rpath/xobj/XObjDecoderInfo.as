/*
#
# Copyright (c) 2007-2012 rPath, Inc.
#
# All rights reserved
#
*/

package com.rpath.xobj
{
public final class XObjDecoderInfo
{
    public function XObjDecoderInfo()
    {
        super();
    }
    
    public var memberClass:Class;
    public var resultID:String;
    public var resultClass:Class;
    public var resultTypeName:String;
    public var isSpecifiedType:Boolean;
    public var isNullObject:Boolean;
    public var isSimpleType:Boolean;
    public var isRootNode:Boolean;
}
}