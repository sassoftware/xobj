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
            addTestCase(new TestNamespaces());
        }

    }
}
