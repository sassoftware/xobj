/*
# Copyright (c) 2008-2010 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any warranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.
#
*/

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
    function elementTagForMember(member:*):String;

}

}