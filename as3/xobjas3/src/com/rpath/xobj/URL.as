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
import mx.utils.URLUtil;

/** URL provides more "intelligent" String instances that
 * wrap up some of the functionality of the URLUtil helper
 * as well as make URL's more typesafe in general usage
 */

public class URL
{
    
    public function URL(v:*="", useHTTPS:Boolean=false)
    {
        super();
        
        this.useHTTPS = useHTTPS;
        if (v is URL)
        {
            this.value = (v as URL).value;
        }
        else
        {
            this.value = v;
        }
    }
    
    public var useHTTPS:Boolean;
    
    public function get value():String
    {
        return _value;
    }
    
    private var _value:String;
    
    public function set value(value:String):void
    {
        _value = value;
        if (_value && useHTTPS && !isHTTPS)
        {
            // make the URL HTTPS
            if (_value.indexOf("http://") == 0)
            {
                _value = _value.replace("http://", "https://");
            }
        }
    }
    public function get isHTTPS():Boolean
    {
        return URLUtil.isHttpsURL(value);
    }
    
    public function get isHTTP():Boolean
    {
        return URLUtil.isHttpURL(value);
    }
    
    public function hasQuery():Boolean
    {
        return value.indexOf("?") != -1;
    }
    
    public function toString():String
    {
        return value;
    }
    
}
}