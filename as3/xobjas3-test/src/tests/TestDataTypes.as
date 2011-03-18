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

import tests.models.*;

import flash.xml.XMLDocument;


public class TestDataTypes extends TestBase
{
    /** testSimple 
    * test basic decoding behavior of a simple XML document
    */
    
    
    private var simpleTypesTest:XML = 
        <top>
          <simpleType>
            <aString>Something here to say I wonder?</aString>
            <aNumber>2009.988</aNumber>
            <anInt>27</anInt>
            <aBoolean>true</aBoolean>
            <aDate>Thu Jan 8 08:45:41 GMT-0500 2009</aDate>
         </simpleType>
        </top>
        

        
    public function testSimpleTypes():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({simpleType:TestableSimpleTypes});
        var xmlInput:XMLDocument = new XMLDocument(simpleTypesTest);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("top is object", o.top is Object);
        assertTrue("simpleType value", o.top.simpleType != null);
        assertTrue("simpleType value", o.top.simpleType.aString is String);
        assertTrue("simpleType value", o.top.simpleType.aString == 'Something here to say I wonder?');
        assertTrue("simpleType value", o.top.simpleType.aNumber is Number);
        assertTrue("simpleType value", o.top.simpleType.aNumber == 2009.988);
        assertTrue("simpleType value", o.top.simpleType.anInt is int);
        assertTrue("simpleType value", o.top.simpleType.anInt == 27);
        assertTrue("simpleType value", o.top.simpleType.aBoolean is Boolean);
        assertTrue("simpleType value", o.top.simpleType.aBoolean == true);
        assertTrue("simpleType value", o.top.simpleType.aDate is Date);
        
        var dateString:String = (o.top.simpleType.aDate as Date).toString();
        
        assertTrue("simpleType value", dateString == "Thu Jan 8 08:45:41 GMT-0500 2009");
       
    }
    
    }
}

