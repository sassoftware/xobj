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