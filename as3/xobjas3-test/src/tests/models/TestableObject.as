/*
#
# Copyright (c) 2009 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found 
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any waranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.
*/

package tests.models
{
    /**
     * A random object for use in validating encoding of objects
     */ 
    public dynamic class TestableObject
    {
        public var someVal:String;
        
        [Transient]
        public var transientVar:String;
        
        [xobjTransient]
        public var xobjTransientVar:String;
        
        public var booleanVar:Boolean;
        
    }
}