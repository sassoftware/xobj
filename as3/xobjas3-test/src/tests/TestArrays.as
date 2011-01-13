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
import com.rpath.xobj.*;

import flash.xml.XMLDocument;

import mx.collections.ArrayCollection;

import tests.models.*;

public class TestArrays extends TestBase
{
    /** testArrays 
    * test basic handling of Array and ArrayCollection
    */
    
    private var testValues:Array = [ "a string value 1", "a string value 2"];

    private var arrayCollectionTest1:XML = 
        <top dyn1="foo" dyn2="bar">
          <dyn3>baz</dyn3>
          <simple>simple</simple>
          <middle>
            <tag>1</tag>
          </middle>
          <bottom tag="2">
          </bottom>
            <testableObjects>
                <testableObject someVal="a string value 1">
                    <someNumber>2.3</someNumber>
                </testableObject>
                <testableObject>
                    <someVal>a string value 2</someVal>
                    <someNumber>3.4</someNumber>
                </testableObject>
            </testableObjects>
        </top>
    
    
    public function testArrayCollection():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({top:TopWithArrayCollection});
        var xmlInput:XMLDocument = new XMLDocument(arrayCollectionTest1);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("Top is type Object", o.top is TopWithArrayCollection);
        assertTrue("top has dynamic property 1 from attribute", o.top.dyn1 == "foo");
        assertTrue("top has dynamic property 2 from attribute", o.top.dyn2 == "bar");
        assertTrue("top has dynamic property 3 from element", o.top.dyn3 == "baz");
        
        assertTrue("top has array of TestableObjects from metadata marker", o.top.testableObjects is ArrayCollection);
        
        assertTrue("array of testables is correct length", o.top.testableObjects.length == 2);
        
        var index:int = 0;
        
        for each (var item:* in o.top.testableObjects)
        {
            assertTrue(item is TestableObject);
            
            var testable:TestableObject = item as TestableObject;
            
            assertTrue(testable.someVal == testValues[index]);
            index++;
        }
        
    }

    private var arrayTest1:XML = 
        <top dyn1="foo" dyn2="bar">
          <dyn3>baz</dyn3>
          <simple>simple</simple>
          <middle>
            <tag>1</tag>
          </middle>
          <bottom tag="2">
          </bottom>
            <testableObjects link="foobar">
                <testableObject someVal="a string value 1">
                    <someNumber>2.3</someNumber>
                </testableObject>
                <testableObject>
                    <someVal>a string value 2</someVal>
                    <someNumber>3.4</someNumber>
                </testableObject>
            </testableObjects>
        </top>
        
        
    public function testArray():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({top:TopWithArray});
        var xmlInput:XMLDocument = new XMLDocument(arrayTest1);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("Top is type Object", o.top is TopWithArray);
        assertTrue("top has dynamic property 1 from attribute", o.top.dyn1 == "foo");
        assertTrue("top has dynamic property 2 from attribute", o.top.dyn2 == "bar");
        assertTrue("top has dynamic property 3 from element", o.top.dyn3 == "baz");
        
        assertTrue("top has array of TestableObjects from metadata marker", o.top.testableObjects is Array);
        
        assertTrue("array of testables is correct length", o.top.testableObjects.length == 2);
        assertTrue("array of testables has property", o.top.testableObjects["link"] == "foobar");

        var index:int = 0;
        
        for (index=0; index < o.top.testableObjects.length; index++)
        {
            var item:* = o.top.testableObjects[index];
            assertTrue("item is TestableObject", item is TestableObject);
            var testable:TestableObject = item as TestableObject;
            assertTrue(testable.someVal == testValues[index]);
        }

    }


    private var arrayTest2:XML = 
        <top dyn1="foo" dyn2="bar">
          <dyn3>baz</dyn3>
          <simple>simple</simple>
          <middle>
            <tag>1</tag>
          </middle>
          <bottom tag="2">
          </bottom>
          <testableArray>
            <testableObject someVal="a string value 1">
                <someNumber>2.3</someNumber>
            </testableObject>
            <testableObject>
                <someVal>a string value 2</someVal>
                <someNumber>3.4</someNumber>
            </testableObject>
          </testableArray>
        </top>
    
    
    /** testNestedArray tests for elements nested under a grouping node
    * 
    * This does NOT yet work, since we have no way to disambiguate
    * whether a tree means "object with a single property that is an array"
    * or "array nested in a grouping alias element"
    * 
    * In the example above, <testableArray> is really an alias for the array
    * of testableObjects. The un-nested form works fine, but does require the
    * parent object property to be called testableObject as well, which can be 
    * confusing
    * 
    * THIS DOES NOT WORK YET
    */
    
    public function testNestedArray():void
    {
        // THIS DOESN'T WORK YET
        return;
        
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({top:TopWithNestedArray});
        var xmlInput:XMLDocument = new XMLDocument(arrayTest2);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("Top is type Object", o.top is TopWithNestedArray);
        assertTrue("top has dynamic property 1 from attribute", o.top.dyn1 == "foo");
        assertTrue("top has dynamic property 2 from attribute", o.top.dyn2 == "bar");
        assertTrue("top has dynamic property 3 from element", o.top.dyn3 == "baz");
        
        var t:TopWithNestedArray;
        
        t = o.top;
        
        assertTrue("top has array of TestableObjects from metadata marker", t.testableArray is Array);
        
        assertTrue("array of testables is correct length", t.testableArray.length == 2);
        
        var index:int = 0;
        
        for each (var item:* in t.testableArray)
        {
            assertTrue(item is TestableObject);
            
            var testable:TestableObject = item as TestableObject;
            
            assertTrue(testable.someVal == testValues[index]);
            index++;
        }

    }


}
}

