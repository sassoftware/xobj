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


public class TestBasics extends TestBase
{
    /** testSimple 
    * test basic decoding behavior of a simple XML document
    */
    public function testSimple():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder();
        var xmlInput:XMLDocument = new XMLDocument(testData.simple);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("top is object", o.top is Object);
        assertTrue("attr1 value", o.top.attr1 == "anattr");
        assertTrue("attr2 value", o.top.attr2 == "another");
        assertTrue("prop value", o.top.prop == "something");
        assertTrue("subelement.subaattr value", o.top.subelement.subattr == "2");
        assertTrue("subelement is Object", o.top.subelement is Object);
    }
    
    /** testComplex
    * Slightly more complex test with a repeated element that results in an
    * Array property
    */
    public function testComplex():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({prop: Array});
        var xmlInput:XMLDocument = new XMLDocument(testData.complex);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue(o.top is Object);
        assertTrue(o.top.prop is Array);
        
        // check array content
        for (var i:int=0; i<o.top.prop.length; i++)
        {
            assertTrue(o.top.prop[i] is XObjString);
            assertTrue(o.top.prop[i].toString() == ['asdf', 'fdsa', 'zxcv '][i]);
        }
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder({subprop: XObjString});
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(o.top, null, "top");

        assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));
    }        

    /** testNamespaces
    * test namespaces and prefixes are correctly mapped to properties on decode
    * and that they are correctly mapped back to prefixed tags on encode. 
    * Also check that encoding is symmetrical with decoding.
    * This particular test case has an element tag that defines the namespace
    * that itself is declared within - a specific edge case.
    */
    public function testNamespaces():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder();
        var xmlInput:XMLDocument = new XMLDocument(testData.namespaces);
        var o:* = typedDecoder.decodeXML(xmlInput);

        assertTrue(o.top.other_tag.other_val == '1')
        assertTrue(o.top.other2_tag.val == '2')
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder();
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(o.top, null, "top");

        assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));
    } 

    /** testMappedNamespaces
    * test that we can specify a local prefix other3 for a given namespace
    * allowing us to write code that is insulated from the arbitrary prefixes
    * a given document might choose.
    */
    public function testMappedNamespaces():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder(null, { other3 : 'http://other/other2'});
        var xmlInput:XMLDocument = new XMLDocument(testData.namespaces);
        var o:* = typedDecoder.decodeXML(xmlInput);

        assertTrue(o.top.other_tag.other_val == '1')
        assertTrue(o.top.other3_tag.val == '2')
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder();
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(o.top, null, "top");

        // check that we remap to original prefixes on the way back out
        assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));
    } 

    /** testExplicitNamespace
    * test that when a namespace is redundantly declared as both default and
    * by prefix in the XML, that the result is strictly prefixed on output
    * This is to ensure documents conformant to an XMLSchema that uses
    * attributeFormDefault = qualified and elementFormDefault = qualified
    * are encoded correctly for the schema.
    * 
    * Note that we *always* do this, since an unqualified schema requirement
    * will be satisified by a qualified XML document.
    */
    public function testExplicitNamespace():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder();
        var xmlInput:XMLDocument = new XMLDocument(testData.explicitns);
        var o:* = typedDecoder.decodeXML(xmlInput);

        assertTrue(o.ns_top.ns_element.ns_attr == 'foo')
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder();
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(o.ns_top, null, "ns_top", o._xobj.elements[0].qname);

        var expectedString:String = 
                '<ns:top xmlns:ns="http://somens.xsd">' + 
                '<ns:element ns:attr="foo"/>' + 
                '</ns:top>';

        // check that we remap to original prefixes on the way back out
        assertTrue("encode is fully qualified", compareXMLtoString(xmlOutput, expectedString));
    }


    /** testObjectTree
    * test that we can construct a new object graph and encode it as XML.
    * test that we can then decode it and get back a new graph with correctly
    * typed ActionScript objects.
    */
    public function testObjectTree():void
    {
        var t:Top = new Top();
        t.prop = 'abc';
        t.middle = new Middle();
        t.middle.tag = 123;
        t.bottom = null;
        var typeMap:* = {top:Top};
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder(typeMap);
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(t);

        var expectedString:String = 
                '<top>'+
                '<bottom/>'+
                '<middle>'+
                '<tag>123</tag>'+
                '</middle>'+
                '<prop>abc</prop>'+
                '</top>';
        
        assertTrue(compareXMLtoString(xmlOutput, expectedString));

        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder(typeMap);
        var xmlInput:XMLDocument = xmlOutput;
        var o:* = typedDecoder.decodeXML(xmlInput);

        assertTrue(o.top is Top);
        assertTrue(o.top.middle is Middle);
        assertTrue(o.top.middle.tag == 123);
        assertTrue(o.top.middle.foo() == 123);
        assertTrue(o.top.bottom == null);

        // reencode and check round-trip
        xmlOutput = typedEncoder.encodeObject(o.top);

        assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));

    }

    
    /** testObjectTreeNulls
     * test that we can construct a new object graph and encode it as XML.
     * test that we can then decode it and get back a new graph with correctly
     * typed ActionScript objects.
     */
    public function testObjectTreeNulls():void
    {
        var t:Top = new Top();
        t.prop = 'abc';
        t.middle = new Middle();
        t.middle.tag = 123;
        t.bottom = null;
        var typeMap:* = {top:Top};
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder(typeMap);
        typedEncoder.encodeNullElements = false;
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(t);
        
        var expectedString:String = 
            '<top>'+
            '<middle>'+
            '<tag>123</tag>'+
            '</middle>'+
            '<prop>abc</prop>'+
            '</top>';
        
        assertTrue(compareXMLtoString(xmlOutput, expectedString));
        
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder(typeMap);
        var xmlInput:XMLDocument = xmlOutput;
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue(o.top is Top);
        assertTrue(o.top.middle is Middle);
        assertTrue(o.top.middle.tag == 123);
        assertTrue(o.top.middle.foo() == 123);
        assertTrue(o.top.bottom == null);
        
        // reencode and check round-trip
        xmlOutput = typedEncoder.encodeObject(o.top);
        
        assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));
        
    }
    
    public function testId():void
    {
    }
    
    /** 
     * Ensure boolean data is handled properly
     */
    public function testBoolean():void
    {
        var obj:TestableObject = new TestableObject();
        obj.someVal = "someval";
        obj.booleanVar = true;
        var typeMap:* = {obj: TestableObject};
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder(typeMap);
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(obj);

        // neither the Transient nor the xobjTransient vars should be there
        var expectedString:String = 
                '<obj>'+
                '<booleanVar>true</booleanVar>'+
                '<someVal>someval</someVal>'+
                '</obj>';
        
        assertTrue(compareXMLtoString(xmlOutput, expectedString));
        
        // now decode it and validate
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder(typeMap);
        var xmlInput:XMLDocument = xmlOutput;
        var o:* = typedDecoder.decodeXML(xmlInput);
        assertTrue(o.obj is TestableObject);
        assertTrue(o.obj.someVal =="someval");
        assertTrue(o.obj.booleanVar);
        
        // reencode and check round-trip
        xmlOutput = typedEncoder.encodeObject(o.obj);
        assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));
    }

    public function testNumericStrings():void
    {
        var obj:TestableObject = new TestableObject();
                
        obj.someVal = "1.0";
        // make sure someVal is a string so this is a valid test
        assertTrue(obj.someVal is String);
        obj.booleanVar = true;
        var typeMap:* = {obj: TestableObject};
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder(typeMap);
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(obj);

        // neither the Transient nor the xobjTransient vars should be there
        var expectedString:String = 
                '<obj>'+
                '<booleanVar>true</booleanVar>'+
                '<someVal>1.0</someVal>'+
                '</obj>';
        
        assertTrue(compareXMLtoString(xmlOutput, expectedString));
        
        // now decode it and validate
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder(typeMap);
        var xmlInput:XMLDocument = xmlOutput;
        var o:* = typedDecoder.decodeXML(xmlInput);
        assertTrue(o.obj is TestableObject);
        assertTrue(o.obj.someVal == "1.0");
        assertTrue(o.obj.booleanVar);
        
        // reencode and check round-trip
        xmlOutput = typedEncoder.encodeObject(o.obj);
        assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));
    }
    
    public function testStringNumerics():void
    {
        var obj:TestableNumericObject = new TestableNumericObject();
                
        obj.someNumber = 1.1;
        // make sure someNumber is a Number so this is a valid test
        assertTrue(obj.someNumber is Number);
        obj.booleanVar = true;
        var typeMap:* = {obj: TestableNumericObject};
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder(typeMap);
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(obj);

        // neither the Transient nor the xobjTransient vars should be there
        var expectedString:String = 
                '<obj>'+
                '<booleanVar>true</booleanVar>'+
                '<someNumber>1.1</someNumber>'+
                '</obj>';
        
        assertTrue(compareXMLtoString(xmlOutput, expectedString));
        
        // now decode it and validate
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder(typeMap);
        var xmlInput:XMLDocument = xmlOutput;
        var o:* = typedDecoder.decodeXML(xmlInput);
        assertTrue(o.obj is TestableNumericObject);
        assertTrue(o.obj.someNumber == 1.1);
        assertTrue(o.obj.booleanVar);
        
        // reencode and check round-trip
        xmlOutput = typedEncoder.encodeObject(o.obj);
        assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));
    }

    public function testStringNumerics2():void
    {
        var obj:TestableNumericObject = new TestableNumericObject();
                
        obj.someNumber = 0.5;
        // make sure someNumber is a Number so this is a valid test
        assertTrue(obj.someNumber is Number);
        obj.booleanVar = true;
        var typeMap:* = {obj: TestableNumericObject};
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder(typeMap);
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(obj);

        // neither the Transient nor the xobjTransient vars should be there
        var expectedString:String = 
                '<obj>'+
                '<booleanVar>true</booleanVar>'+
                '<someNumber>0.5</someNumber>'+
                '</obj>';
        
        assertTrue(compareXMLtoString(xmlOutput, expectedString));
        
        // now decode it and validate
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder(typeMap);
        var xmlInput:XMLDocument = xmlOutput;
        var o:* = typedDecoder.decodeXML(xmlInput);
        assertTrue(o.obj is TestableNumericObject);
        assertTrue(o.obj.someNumber == 0.5);
        assertTrue(o.obj.booleanVar);
        
        // reencode and check round-trip
        xmlOutput = typedEncoder.encodeObject(o.obj);
        assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));
    }
    
    }
}

