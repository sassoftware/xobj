/*
#
# Copyright (c) 2008 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found 
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any waranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.
*/

package com.rpath.xobj
{
    
    [RemoteClass]  // tell the compiler we can be deep copied 
    public class XObjMetadata
    {
        public var attributes:Array;
        public var elements:Array;
        //public var namespaces:Array;

            
        public static const METADATA_PROPERTY:String = "_xobj";
        
        public function XObjMetadata()
        {

            super();
            
            attributes = [];
            elements = [];
            //namespaces = [];
        }

        private static function getMetadata(target:*):XObjMetadata
        {
           var result:XObjMetadata = null;
           
           if (METADATA_PROPERTY in target)
           {
                result = target[METADATA_PROPERTY];
           }
           else
           {
               // doesn't exist. Try creating it
               try
               {
                   target[METADATA_PROPERTY] = new XObjMetadata();
                   result = target[METADATA_PROPERTY];
               }
               catch (e:ReferenceError)
               {
                   // must be nondynamic type
               }
            }
            
            return result;
        }
        
        public static function setElements(target:*, elements:Array):void
        {
            var xobj:XObjMetadata = getMetadata(target);
            if (xobj)
            {
               xobj.elements = elements;
            }
        }

        public static function setAttributes(target:*, attributes:Array):void
        {
            var xobj:XObjMetadata = getMetadata(target);
            if (xobj)
            {
                if (attributes.length == 0)
                    trace("damn!");
                    
                xobj.attributes = attributes;
            }
        }

            
        public function addAttribute(entry:*):void
        {
            attributes.push(entry);
        }
        
        public function addElement(entry:*):void
        {
            elements.push(entry);
        }
        
                
    }
}