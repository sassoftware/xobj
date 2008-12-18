package com.rpath.xobj
{
    import mx.rpc.xml.XMLDecoder;
    
    public class SchemaAwareXMLDecoder extends XMLDecoder
    {
        public function SchemaAwareXMLDecoder()
        {
            super();
        }

        protected override function preProcessXML(root:XML):void
        {
            // looks like we have to load up all the schema ourselves ?
            
            super.preProcessXML(root);
        }

        /**
         * We need to override this due to a bug in XMLDecoder's handling of
         * the anyAttribute schema type when used at the end of a type decl
         * to allowfor additional arbitrary attributes. The effect is to 
         * duplicate any defined attrs by failing to observe that they've already
         * been processed.
         * 
         */
        public override function setAttribute(parent:*, name:*, value:*):void
        {
            if (getValue(parent, name))
                return;
            else
                super.setAttribute(parent, name, value);
        }
    
    }
}