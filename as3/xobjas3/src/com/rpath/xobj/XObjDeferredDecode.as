/*
# Copyright (c) 2008-2009 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any waranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.
#
*/

package com.rpath.xobj
{
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;
    import flash.xml.XMLNode;
    
    public class XObjDeferredDecode
    {
        public function XObjDeferredDecode(xmlDecoder:XObjXMLDecoder, dataNode:XMLNode, propType:Class=null, rootObject:Object=null)
        {
            super();
            this.decoder = xmlDecoder;
            this.dataNode = dataNode;
            this.propType = propType;
            this.rootObject = rootObject;
        }

        public var decoder:XObjXMLDecoder;
        public var dataNode:XMLNode;
        public var propType:Class;
        public var rootObject:Object;

        
        public function decodeXML():Object
        {
            if (!rootObject)
                return decoder.actualDecodeXML(dataNode, propType);
            else
                return decoder.actualDecodeXML(dataNode, null, rootObject, false);
        }

        public function decodeXMLIntoObject(rootObject:*):Object
        {
            if (!rootObject)
                return null;
            
            return decoder.actualDecodeXML(dataNode, null, rootObject, false);
        }
        
    }
}
