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

public class XObjDeferredDecode
{
    public function XObjDeferredDecode(xmlDecoder:XObjXMLDecoder, dataNode:XML, propType:Class=null, rootObject:Object=null)
    {
        super();
        this.decoder = xmlDecoder;
        this.dataNode = dataNode;
        this.propType = propType;
        this.rootObject = rootObject;
    }
    
    public var decoder:XObjXMLDecoder;
    public var dataNode:XML;
    public var propType:Class;
    public var rootObject:Object;
    
    
    public function decodeXML():Object
    {
        if (!rootObject)
            return decoder.xobj::actualDecodeXML(dataNode, propType, null, true);
        else
            return decoder.xobj::actualDecodeXML(dataNode, null, rootObject, true);
    }
    
    public function decodeXMLIntoObject(rootObject:*):Object
    {
        if (!rootObject)
            return null;
        
        return decoder.xobj::actualDecodeXML(dataNode, null, rootObject, true);
    }
    
}
}
