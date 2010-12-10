package com.rpath.xobj
{
import mx.collections.ICollectionView;


public interface IXObjCollection extends IXObjReference, ICollectionView
{
    function removeAll():void;
    function addItem(value:Object):void;
    function addItemIfAbsent(value:Object):Boolean;
    function removeItemIfPresent(object:Object):Boolean;
    
    function isElementMember(propname:String):Boolean;
}

}