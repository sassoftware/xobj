package com.rpath.xobj
{
public interface IXObjFactory
{
    function newObject(type:Class, id:String):Object;
    function getObjectForId(id:String):Object;
    function trackObjectById(item:Object, id:String):void;
    function newCollectionFrom(item:*):*;
}
}