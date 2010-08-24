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
*/

package com.rpath.xobj
{
    public class XObjTypeInfo
    {
        public function XObjTypeInfo()
        {
        }

        public var type:Class;
        public var typeName:String;
        public var arrayElementTypeName:String;
        public var isArray:Boolean;
        public var isArrayCollection:Boolean;
        
    }
}
