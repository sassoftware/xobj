package com.rpath.xobj
{
public interface IXObjCollection
{
    function removeAll():void;
    function addItem(value:*):void;
    function elementType():Class;
}
}