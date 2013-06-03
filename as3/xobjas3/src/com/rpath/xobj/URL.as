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
    
    public function set url(s:String):void
    {
        value = s;
    }
    
    public function get url():String
    {
        return value;
    }
}
}
