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
    import mx.collections.ArrayCollection;
    
    public dynamic class TopWithArrayCollection
    {
        public function TopWithArrayCollection()
        {
        }

        public var middle:Middle;
        public var bottom:Middle;
        
        [ArrayElementType("tests.models.TestableObject")]
        public var testableObject:ArrayCollection;
    }
}