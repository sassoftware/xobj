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

public class TestRefresh extends TestBase
{
    /** testRefreshSimple 
    * test basic refresh reload behavior of a simple XML document
    */
    
    private var testValues:Array = [ "a string value 1", "a string value 2"];

    private var refresh1:XML = 
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
    
    
    public function testRefreshBaseData():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({top:TopWithArray});
        var xmlInput:XML = new XML(refresh1);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("Top is type Object", o.top is TopWithArray);
        assertTrue("top has dynamic property 1 from attribute", o.top.dyn1 == "foo");
        assertTrue("top has dynamic property 2 from attribute", o.top.dyn2 == "bar");
        assertTrue("top has dynamic property 3 from element", o.top.dyn3 == "baz");
        
        assertTrue("top has array of TestableObjects from metadata marker", o.top.testableObjects is Array);
        
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
    
    public function testRefreshWithArray():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({top:TopWithArray});
        var xmlInput:XML = new XML(refresh1);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        // quick sanity check
        assertTrue("top has dynamic property 1 from attribute", o.top.dyn1 == "foo");
        
        assertTrue("o.top and o.root are same instance", o.top === o.root);
        
        assertTrue("o.top is correct type", o.top is TopWithArray);
        
        var t:TopWithArray = o.top;
        
        // mutate the object state
        
        t.dyn1 = "foobarbaz";
        assertTrue("top dyn1 changed", t.dyn1 == "foobarbaz");
        
        var arr:Array = t.testableObjects;
        
        var newObj:*;
        
        // now, refresh the object by re-reading XML into itself
        newObj = typedDecoder.decodeXMLIntoObject(xmlInput, t);
        
        var newT:TopWithArray;
        
        newT = newObj.root;
        
        assertTrue("refreshed into same instance object", t === newT);
        
        assertTrue("top dyn1 refreshed", t.dyn1 == "foo");
        
        assertTrue("testable array is same instance", t.testableObjects === arr);
        
        // now change the arr instance and reload again
        arr = [];
        t.testableObjects = arr;
        assertTrue("testable array is empty", t.testableObjects.length == 0);

        // now, refresh the object by re-reading XML into itself
        newObj = typedDecoder.decodeXMLIntoObject(xmlInput, t);
        newT = newObj.root;

        assertTrue("refreshed into same instance object", t === newT);

        assertTrue("testable array is not empty", t.testableObjects.length > 0);
        assertTrue("testable array is same instance", t.testableObjects === arr);
    }


    public function testRefreshWithArrayCollection():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({top:TopWithArrayCollection});
        var xmlInput:XML = new XML(refresh1);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        // quick sanity check
        assertTrue("top has dynamic property 1 from attribute", o.top.dyn1 == "foo");
        
        assertTrue("o.top and o.root are same instance", o.top === o.root);
        
        assertTrue("o.top is correct type", o.top is TopWithArrayCollection);
        
        var t:TopWithArrayCollection = o.top;
        
        // mutate the object state
        
        t.dyn1 = "foobarbaz";
        assertTrue("top dyn1 changed", t.dyn1 == "foobarbaz");
        
        var arr:ArrayCollection = t.testableObjects;
        
        var newObj:*;
        
        // now, refresh the object by re-reading XML into itself
        newObj = typedDecoder.decodeXMLIntoObject(xmlInput, t);
        
        var newT:TopWithArrayCollection;
        
        newT = newObj.root;
        
        assertTrue("refreshed into same instance object", t === newT);
        
        assertTrue("top dyn1 refreshed", t.dyn1 == "foo");
        
        assertTrue("testable arraycollection is same instance", t.testableObjects === arr);
        
        // now change the arr instance and reload again
        arr = new ArrayCollection();
        t.testableObjects = arr;
        assertTrue("testable arraycollection is empty", t.testableObjects.length == 0);

        // now, refresh the object by re-reading XML into itself
        newObj = typedDecoder.decodeXMLIntoObject(xmlInput, t);
        newT = newObj.root;

        assertTrue("refreshed into same instance object", t === newT);

        assertTrue("testable arraycollection is not empty", t.testableObjects.length > 0);
        assertTrue("testable arraycollection is same instance", t.testableObjects === arr);
    }
        
}
}

