package com.rpath.xobj
{


public interface IXObjCollection extends IXObjReference
{
    function removeAll():void;
    function addItem(value:*):void;
    function addItemIfAbsent(value:*):void;
    function removeItemIfPresent(object:Object):Boolean;
    
}

}