package com.rpath.xobj
{
import flash.utils.Dictionary;

public interface IXObjCollection
{
    function removeAll():void;
    function addItem(value:*):void;
    function elementType():Class;
    function typeMap():Dictionary;
}
}