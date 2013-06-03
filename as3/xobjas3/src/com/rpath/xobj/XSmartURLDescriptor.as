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

[Bindable]
public class XSmartURLDescriptor
{
    public function XSmartURLDescriptor()
    {
        super();
    }
    
    // keys used in constructing URLs
    public var paramMarker:String = ";";
    public var paramDelimiter:String = ";";
    
    public var startKey:String = "start_index";
    public var limitKey:String = "limit";
    
    public var sortKey:String = "order_by";
    public var sortConjunction:String = ",";
    public var sortDescMarker:String = "-";
    public var sortAscMarker:String = "";
    
    public var filterKey:String = "filter_by";
    public var filterTermStart:String = "[";
    public var filterTermEnd:String = "]";
    public var filterTermConjunction:String = ",";
    public var filterTermSeperator:String = ",";
    
    public var searchKey:String = "search";
}
}
