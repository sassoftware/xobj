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
public class XSmartURLDescriptor
{
    public function XSmartURLDescriptor()
    {
        super();
    }
    
    // keys used in constructing URLs
    public var startKey:String = "start";
    public var limitKey:String = "limit";
    
    public var sortKey:String = "order_by";
    public var sortConjunction:String = ",";
    public var sortDescMarker:String = "-";
    public var sortAscMarker:String = "";
    public var rangeUsingHeaders:Boolean = true;
    
    public var filterKey:String = "filter_by";
    public var filterTermStart:String = "[";
    public var filterTermEnd:String = "]";
    public var filterTermConjunction:String = "]";
    public var filterTermSeperator:String = ",";
    
    public var searchKey:String = "search";
}
}