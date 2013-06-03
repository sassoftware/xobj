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


package tests
{
    import net.digitalprimates.fluint.tests.TestCase;

    public class TestBase extends TestCase
    {
        // NOTE: we don't really need an empty constructor
        // here for example purposes
        public function TestBase()
        {
            super();
        }

        public var testData:TestData;
        
        // here for example purposes
        override protected function setUp():void
        {
            testData = new TestData();
        }
        
        // here for example purposes
        override protected function tearDown():void
        {
            
        }
        
        public function compareXML(a:XML, b:XML):Boolean
        {
            var aString:String = a.toString();
            var bString:String = b.toString();
            var outputXML:XML = new XML(aString);
            var inputXML:XML = new XML(bString);
            
            var xmlInputString:String = inputXML.toXMLString();
            var xmlOutputString:String = outputXML.toXMLString();
            
            return (xmlOutputString == xmlInputString);
        }


        public function compareXMLtoString(a:XML, b:String):Boolean
        {
            var outputXML:XML = new XML(a.toString());
            var inputXML:XML = new XML(b);
            
            var xmlInputString:String = inputXML.toXMLString();
            var xmlOutputString:String = outputXML.toXMLString();
            
            return (xmlOutputString == xmlInputString);
        }
        
        // helper functions here to compare input XML to output XML
        // helper functions to take an object to XML
        // helper function to take XML to an object
        
        // helper functions to compare one object to another
        
    }
}
