/*
# Copyright (c) 2008-2009 rPath, Inc.
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
            return decoder.actualDecodeXML(dataNode, propType, null, true);
        else
            return decoder.actualDecodeXML(dataNode, null, rootObject, true);
    }
    
    public function decodeXMLIntoObject(rootObject:*):Object
    {
        if (!rootObject)
            return null;
        
        return decoder.actualDecodeXML(dataNode, null, rootObject, true);
    }
    
}
}
