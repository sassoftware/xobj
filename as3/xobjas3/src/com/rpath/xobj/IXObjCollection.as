/*
 * Copyright (c) SAS Institute Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
