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
        var xmlInput:XML = new XML(arrayCollectionTest1);
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
        var xmlInput:XML = new XML(arrayTest1);
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

    private var arrayTestRepeated:XML = 
        <top dyn1="foo" dyn2="bar">
          <dyn3>baz</dyn3>
          <simple>simple</simple>
          <middle>
            <tag>1</tag>
          </middle>
          <bottom tag="2">
          </bottom>
            <testableObject someVal="a string value 1">
                <someNumber>2.3</someNumber>
            </testableObject>
            <testableObject>
                <someVal>a string value 2</someVal>
                <someNumber>3.4</someNumber>
            </testableObject>
        </top>
    
    
    /** testRepeatedArray tests for elements nested under a grouping node
    * 
    * each of the <testableObject> elements above should end up as a member of 
    * an array called testableObject:Array
    * 
    * Note: to make this work, we have to provide a BIG HINT to Xobj that
    * the <testableObject> element is a TestableObject and NOT the array itself
    * because the property name in our result object *must match* the element tag
     */
    
    public function testRepeatedArray():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({top:TopWithNestedArray, testableObject: TestableObject});
        var xmlInput:XML = new XML(arrayTestRepeated);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("Top is type Object", o.top is TopWithNestedArray);
        assertTrue("top has dynamic property 1 from attribute", o.top.dyn1 == "foo");
        assertTrue("top has dynamic property 2 from attribute", o.top.dyn2 == "bar");
        assertTrue("top has dynamic property 3 from element", o.top.dyn3 == "baz");
        
        var t:TopWithNestedArray;
        
        t = o.top;
        
        assertTrue("top has array of TestableObjects from metadata marker", t.testableObject is Array);
        
        assertTrue("array of testables is correct length", t.testableObject.length == 2);
        
        var index:int = 0;
        
        for each (var item:* in t.testableObject)
        {
            assertTrue(item is TestableObject);
            
            var testable:TestableObject = item as TestableObject;
            
            assertTrue(testable.someVal == testValues[index]);
            index++;
        }
        
    }

    private var arrayNestedTest:XML = 
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
    * In the example above, <testableArray> is really an alias for the array
    * of testableObjects.
    */
    
    public function testNestedArray():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({top:TopWithNestedArray});
        var xmlInput:XML = new XML(arrayNestedTest);
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

    private var testListMarkerXML:XML = 
        <top dyn1="foo" dyn2="bar">
          <dyn3>baz</dyn3>
          <simple>simple</simple>
          <middle>
            <tag>1</tag>
          </middle>
          <bottom tag="2">
          </bottom>
          <testableDynamicArray list="true">
            <testableObject someVal="a string value 1">
                <someNumber>2.3</someNumber>
            </testableObject>
          </testableDynamicArray>
        </top>
    
    
    /** testNestedArray tests for elements nested under a grouping node
     * 
     * In the example above, <testableArray> is really an alias for the array
     * of testableObjects.
     */
    
    public function testListMarker():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({top:TopWithNestedArray, testableObject: TestableObject});
        var xmlInput:XML = new XML(testListMarkerXML);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("Top is type Object", o.top is TopWithNestedArray);
        assertTrue("top has dynamic property 1 from attribute", o.top.dyn1 == "foo");
        assertTrue("top has dynamic property 2 from attribute", o.top.dyn2 == "bar");
        assertTrue("top has dynamic property 3 from element", o.top.dyn3 == "baz");
        
        var t:TopWithNestedArray;
        
        t = o.top;
        
        assertTrue("top has array of TestableObjects from metadata marker", t.testableDynamicArray is XObjArrayCollection);
        
        assertTrue("array of testables is correct length", t.testableDynamicArray.length == 1);
        
        var index:int = 0;
        
        for each (var item:* in t.testableDynamicArray)
        {
            assertTrue(item is TestableObject);
            
            var testable:TestableObject = item as TestableObject;
            
            assertTrue(testable.someVal == testValues[index]);
            index++;
        }
        
    }

    

}
}

