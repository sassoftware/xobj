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
import com.rpath.xobj.*;

import tests.models.*;


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
        var xmlInput:XML = new XML(simpleTypesTest);
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
    
    private var restBaseType:XML = 
        <configuration id="https://qa4.eng.rpath.com/api/v1/inventory/systems/357/configuration"> 
            <rpath_defaultapppool_managedruntimeversion>v2.0</rpath_defaultapppool_managedruntimeversion> 
            <rpath_defaultapppool_password>Pass@word1</rpath_defaultapppool_password> 
            <rpath_defaultapppool_username>Administrator</rpath_defaultapppool_username> 
            <rpath_defaultapppool_identitytype>SpecificUser</rpath_defaultapppool_identitytype> 
        </configuration>

        
    public function testRESTResourceBaseType():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({configuration:SubModel});
        var xmlInput:XML = new XML(restBaseType);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("configuration is SubModel", o.configuration is SubModel);
        assertTrue("configuration.rpath_defaultapppool_username is String", 
            o.configuration.rpath_defaultapppool_username is String);
        
    }
    
    public function testDoubleDynamicDecode():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({configuration:SubModel});
        var xmlInput:XML = new XML(restBaseType);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("configuration is SubModel", o.configuration is SubModel);
        assertTrue("configuration.rpath_defaultapppool_username is String", 
            o.configuration.rpath_defaultapppool_username is String);
        
        // decode again
        o = typedDecoder.decodeXMLIntoObject(xmlInput, o.configuration);
        assertTrue("configuration is SubModel", o.configuration is SubModel);
        assertTrue("configuration.rpath_defaultapppool_username is String", 
            o.configuration.rpath_defaultapppool_username is String);
      
    }

    private var restBaseType2:XML = 
        <configuration id="https://qa4.eng.rpath.com/api/v1/inventory/systems/357/configuration"> 
            <rpath_defaultapppool_managedruntimeversion>v2.0</rpath_defaultapppool_managedruntimeversion> 
            <rpath_defaultapppool_password>Pass@word1</rpath_defaultapppool_password> 
            <rpath_defaultapppool_username>Administrator</rpath_defaultapppool_username> 
            <rpath_defaultapppool_identitytype>SpecificUser</rpath_defaultapppool_identitytype> 
            <rpath_boolean_thing>false</rpath_boolean_thing> 
        </configuration>

    public function testDynamicBooleanRoundtrips():void
    {
        var typeMap:* = {configuration:SubModel};
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder(typeMap);
        var xmlInput:XML = new XML(restBaseType);
        var o:*;

        o = typedDecoder.decodeXML(xmlInput);
        assertTrue("configuration is SubModel", o.configuration is SubModel);
        assertTrue("configuration.rpath_defaultapppool_username is String", 
            o.configuration.rpath_defaultapppool_username is String);

        assertTrue("configuration.rpath_boolean_thing is undefined", 
            o.configuration.hasOwnProperty("rpath_boolean_thing") == false);

        // now add a dynamic boolean
        
        o.configuration.rpath_boolean_thing = false;
        
        o = typedDecoder.decodeXMLIntoObject(xmlInput, o.configuration);
        assertTrue("configuration.rpath_boolean_thing is Boolean", 
            o.configuration.rpath_boolean_thing is Boolean);
        assertTrue("configuration.rpath_boolean_thing is false", 
            o.configuration.rpath_boolean_thing == false);

        o.configuration.rpath_boolean_thing = true;

        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder(typeMap);
        var xmlOutput:XML = typedEncoder.encodeObject(o.configuration);
        var xmlString:String = xmlOutput.toString();
        
        // reencode
        o = typedDecoder.decodeXMLIntoObject(xmlOutput, o.configuration);
        assertTrue("configuration.rpath_boolean_thing is Boolean", 
            o.configuration.rpath_boolean_thing is Boolean);
        assertTrue("configuration.rpath_boolean_thing is true", 
            o.configuration.rpath_boolean_thing == true);

        // and back again for good measure
        o.configuration.rpath_boolean_thing = false;
        
        typedEncoder = new XObjXMLEncoder(typeMap);
        xmlOutput = typedEncoder.encodeObject(o.configuration);
        xmlString = xmlOutput.toString();
        
        // but delete the property to see whether "false" becomes bool or not
        delete o.configuration["rpath_boolean_thing"];
        
        // reencode
        o = typedDecoder.decodeXMLIntoObject(xmlOutput, o.configuration);
        assertTrue("configuration.rpath_boolean_thing is Boolean", 
            o.configuration.rpath_boolean_thing is Boolean);
        assertTrue("configuration.rpath_boolean_thing is false", 
            o.configuration.rpath_boolean_thing == false);

    }
    
}
}
