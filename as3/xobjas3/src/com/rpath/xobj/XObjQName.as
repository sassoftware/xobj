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
[RemoteClass]   // tell the compiler we can be deep copied  
public class XObjQName
{
    public function XObjQName(meta:*, uri:String="", localName:String="", prefix:String="")
    {
        var xml:XML = meta as XML;
        
        if (meta is Namespace)
        {
            this.ns = (meta as Namespace);
            this.localName=localName;
        }
        else if (xml != null)
        {
            this.ns = xml.namespace();
            this.localName = xml.localName();
        }
        else
        {
            this.uri = uri;
            this.prefix = prefix;
            this.localName=localName;
            if ((uri != null) && (prefix != null))
                this.ns = new Namespace(prefix, uri);
        }
    }
    
    
    public function get ns():Namespace
    {
        return _ns;
    }
    
    private var _ns:Namespace;
    
    public function set ns(value:Namespace):void
    {
        _ns = value;
        if (ns)
        {
            uri = ns.uri;
            prefix= ns.prefix;
        }
    }
    
    public var localName:String;
    public var uri:String;
    public var prefix:String;
    
    public static function equal(a: XObjQName, b:XObjQName):Boolean
    {
        if (a == null || b == null)
            return false;
        
        if ((a.uri == b.uri) && (a.localName == b.localName))
            return true;
        
        return false;
    }
    
    public function get namespace():Namespace
    {
        return ns;
    }
    
}
}
