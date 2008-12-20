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
    [RemoteClass]   // tell the compiler we can be deep copied  
    public class XObjQName
    {
        public function XObjQName(uri:String="", localName:String="")
        {
            this.uri=uri;
            this.localName=localName;
        }

        public var localName:String;
        
        public var uri:String;
        
    }
}