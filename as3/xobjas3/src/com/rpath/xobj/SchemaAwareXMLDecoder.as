/*
#
# Copyright (c) 2008-2009 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found 
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any warranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.
*/

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
         * to allow for additional arbitrary attributes. The effect is to 
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
