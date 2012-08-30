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

package
{
import com.rpath.xobj.XObjDefaultFactory;

import tests.models.ProductImage;
import tests.models.ProductImageDecoder;

// force loader
ProductImageDecoder;

    
    /** 
     * TestSuites is a static helper class that
     * returns the array of test suites to execute
     */
    
    public class TestSuites
    {
        
        public static function suites() : Array
        {
            var suiteArray:Array = new Array();
    
            suiteArray.push(new TestSuite1());
            return suiteArray;
        }
    }
}