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
    
    import net.digitalprimates.fluint.tests.TestSuite;
    
    import tests.*;

    public class TestSuite1 extends TestSuite
    {
        public function TestSuite1()
        {
            addTestCase(new TestEmbeddedXML());
            addTestCase(new TestBasics());
            addTestCase(new TestTransients());
            addTestCase(new TestRefresh());
            addTestCase(new TestArrays());
            addTestCase(new TestDataTypes());
            addTestCase(new TestImagesCollection());
        }

    }
}