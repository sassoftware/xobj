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
import flash.utils.Dictionary;

import mx.collections.ISort;
import mx.collections.Sort;
import mx.collections.SortField;

[Bindable]
public class XSmartURL extends URL
{
    public function XSmartURL(s:*=null)
    {
        // unwrap the URL passed in
        if (s is XSmartURL)
        {
            s = (s as XSmartURL).baseURL;
        }
        
        super(s);
        
        // keep track of the base URL distinct from
        // our current value
        baseURL = new URL(this.value);
    }
    
    
    public function get baseURL():URL
    {
        return _baseURL;
    }
    
    private var _baseURL:URL;
    
    public function set baseURL(value:URL):void
    {
        _baseURL = value;
        recomputeQualifiedURL();
    }
    
    
    /** descriptor provides the encoding chars to use 
     * which is a poor man's metadata right now
     */
    [xobjTransient]
    private var _descriptor:XSmartURLDescriptor;
    
    public function get descriptor():XSmartURLDescriptor
    {
        return _descriptor;
    }
    
    public function set descriptor(value:XSmartURLDescriptor):void
    {
        _descriptor = value;
        recomputeQualifiedURL();
    }
    
    /** paging support
     */
    
    [xobjTransient]
    public var rangeRequest:Boolean;
    
    [xobjTransient]
    private var _startIndex:Number;
    
    public function get startIndex():Number
    {
        return _startIndex;
    }
    
    public function set startIndex(value:Number):void
    {
        _startIndex = value;
        rangeRequest = true;
        recomputeQualifiedURL();
    }
    
    [xobjTransient]
    private var _limit:Number;
    
    public function get limit():Number
    {
        return _limit;
    }
    
    public function set limit(value:Number):void
    {
        _limit = value;
        rangeRequest = true;
        recomputeQualifiedURL();
    }
    
    
    /** filterTerms is an array of (field, operator, value) clauses
     * that are assumed to be AND clauses
     */
    private var _filterTerms:Array =[];
    
    [xobjTransient]
    public function get filterTerms():Array
    {
        return _filterTerms;
    }
    
    [xobjTransient]
    public function set filterTerms(value:Array):void
    {
        _filterTerms = value;
        recomputeQualifiedURL();
    }
    
    
    /** sortTerms are an ordered set of (asc, desc) fields to order by
     */
    private var _sortTerms:ISort;
    
    [xobjTransient]
    public function get sortTerms():ISort
    {
        return _sortTerms;
    }
    
    [xobjTransient]
    public function set sortTerms(value:ISort):void
    {
        _sortTerms = value;
        recomputeQualifiedURL();
    }
    
    
    /** freeSearch is for google-like full text searching
     */
    private var _freeSearch:String;
    
    [xobjTransient]
    public function get freeSearch():String
    {
        return _freeSearch;
    }
    
    [xobjTransient]
    public function set freeSearch(value:String):void
    {
        _freeSearch = value;
        recomputeQualifiedURL();
    }
    
    
    /** url takes the baseURL and modifies it to encode the query, 
     * page, etc. params requested
     */
    
    // TODO: optimize this via setter/getter pairs on query terms
    [xobjTransient]
    public function get qualifiedURL():String
    {
        return _qualifiedURL;
    }
    
    private var _qualifiedURL:String;
    
    [xobjTransient]
    public function set qualifiedURL(s:String):void
    {
        _qualifiedURL = s;
    }
    
    [xobjTransient]
    public function recomputeQualifiedURL():void
    {
        if (!baseURL)
            return;
        
        var fullURL:String = baseURL.value;
        
        if (!fullURL)
            return;
        
        var queryFrag:String = queryFragment();
        
        if (queryFrag)
        {
            if (fullURL.indexOf(descriptor.paramDelimiter) != -1)
            {
                fullURL = fullURL + descriptor.paramDelimiter + queryFrag;
            }
            else
            {
                fullURL = fullURL + descriptor.paramMarker + queryFrag;
            }
        }
        
        qualifiedURL = fullURL;
    }
    
    
    [xobjTransient]
    public function queryFragment():String
    {
        var params:Dictionary = new Dictionary();
        var query:String = "";
        
        if (!descriptor)
            return query;
        
        if (rangeRequest)
        {
            if (descriptor.startKey)
                params[descriptor.startKey] = startIndex;
            if (descriptor.limitKey)
                params[descriptor.limitKey] = limit;
        }
        
        // TODO: use descriptor to tell us how to express sort
        if (sortTerms)
        {
            var terms:String = "";
            
            if (sortTerms.fields && sortTerms.fields.length > 0)
            {
                var first:Boolean = true;
                
                for each (var term:SortField in sortTerms.fields)
                {
                    if (!term || !term.name)
                        continue;
                    
                    terms = terms
                        + (first ? "": descriptor.sortConjunction) 
                        + (term.descending ? descriptor.sortDescMarker: descriptor.sortAscMarker) 
                        + term.name;
                    first = false;
                }
                
                if (terms)
                {
                    params[descriptor.sortKey] = terms;
                }
            }
        }
        
        if (filterTerms)
        {
            var search:String = "";
            first = true;
            for each (var searchTerm:FilterTerm in filterTerms)
            {
                if (searchTerm.value == null)
                {
                    continue;
                }
                
                search = search 
                    + (first ? "": descriptor.filterTermConjunction)
                    + descriptor.filterTermStart
                    + searchTerm.field + descriptor.filterTermSeperator+ searchTerm.operator +descriptor.filterTermSeperator + searchTerm.value
                    + descriptor.filterTermEnd;
                first = false;
            }
            
            if (search)
            {
                params[descriptor.filterKey] = search;
            }
        }
        
        // Google like full text searching
        if (freeSearch)
        {
            params[descriptor.searchKey] = freeSearch;
        }
        
        
        first = true;
        for (var param:String in params)
        {
            query = query + (first ? "" : descriptor.paramDelimiter) + param + "=" + params[param];
            first = false;
        }
        
        return query;
    }
    
    public function addSearchTerm(term:FilterTerm):void
    {
        if (!filterTerms)
            filterTerms = [];
        
        filterTerms.push(term);
        
        recomputeQualifiedURL();
    }
    
    public function removeSearchTerm(term:FilterTerm):void
    {
        var index:int = filterTerms.indexOf(term);
        if (index != -1)
        {
            filterTerms.splice(index,1);
        }
        
        recomputeQualifiedURL();
    }
    
    /* TODO: decide if headers really belong on resource spec */
    [xobjTransient]
    public var headers:Dictionary;
    [xobjTransient]
    public var hasHeaders:Boolean;
    
    [xobjTransient]
    public function setHeader(name:String, value:String):void
    {
        headers[name] = value;
        hasHeaders = true;
    }
    
    public function copy():*
    {
        return XObjUtils.shallowCopy(this);
    }
}
}