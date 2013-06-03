/*
 * Copyright (c) SAS Institute Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
