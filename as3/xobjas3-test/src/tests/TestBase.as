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

package tests
{
    import flash.xml.XMLNode;
    
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
        
        public function compareXML(a:XMLNode, b:XMLNode):Boolean
        {
            var aString:String = a.toString();
            var bString:String = b.toString();
            var outputXML:XML = new XML(aString);
            var inputXML:XML = new XML(bString);
            
            var xmlInputString:String = inputXML.toXMLString();
            var xmlOutputString:String = outputXML.toXMLString();
            
            return (xmlOutputString == xmlInputString);
        }


        public function compareXMLtoString(a:XMLNode, b:String):Boolean
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