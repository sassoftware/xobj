package com.rpath.xobj
{
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;
    import flash.xml.XMLNode;
    
    public class XObjDeferredDecode
    {
        public function XObjDeferredDecode(xmlDecoder:XObjXMLDecoder, dataNode:XMLNode, propType:Class)
        {
            super();
            this.decoder = xmlDecoder;
            this.dataNode = dataNode;
            this.propType = propType;
        }

        public var decoder:XObjXMLDecoder;
        public var dataNode:XMLNode;
        public var propType:Class;

        
        public function decodeXML():Object
        {
            return decoder.actualDecodeXML(dataNode, propType);
        }

        public function decodeXMLIntoObject(rootObject:*):Object
        {
            return decoder.actualDecodeXML(dataNode, null, rootObject, true);
        }
        
    }
}