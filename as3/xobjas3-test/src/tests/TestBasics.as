/*
#
# Copyright (c) 2008 rPath, Inc.
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
        
        assertTrue(o.top is Object);
        assertTrue(o.top.attr1 == "anattr");
        assertTrue(o.top.attr2 == "another");
        assertTrue(o.top.prop == "something");
        assertTrue(o.top.subelement.subattr == "2");
        assertTrue(o.top.subelement is XObjString);
    }
    
    /** testComplex
    * Slightly more complex test with a repeated element that results in an
    * Array property
    */
    public function testComplex():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder();
        var xmlInput:XMLDocument = new XMLDocument(testData.complex);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue(o.top is Object);
        assertTrue(o.top.prop.subprop is Array);
        
        // check array content
        for (var i:int=0; i<o.top.prop.subprop.length; i++)
        {
            assertTrue(o.top.prop.subprop[i] is XObjString);
            assertTrue(o.top.prop.subprop[i] == ['asdf', 'fdsa'][i]);
        }
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder();
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(o);

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
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(o);

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
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(o);

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
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(o);

        var expectedString:String = 
                '<ns:top xmlns:ns="http://somens.xsd">\n' + 
                '  <ns:element ns:attr="foo"/>\n' + 
                '</ns:top>\n';

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

        var typeMap:* = {top:Top};
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder(typeMap);
        var xmlOutput:XMLDocument = typedEncoder.encodeObject(t);

        var expectedString:String = 
                '<top>\n'+
                '  <middle>\n'+
                '    <tag>123</tag>\n'+
                '  </middle>\n'+
                '  <prop>abc</prop>\n'+
                '</top>\n';
        
        assertTrue(compareXMLtoString(xmlOutput, expectedString));

        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder(typeMap);
        var xmlInput:XMLDocument = xmlOutput;
        var o:* = typedDecoder.decodeXML(xmlInput);

        assertTrue(o.top is Top);
        assertTrue(o.top.middle is Middle);
        assertTrue(o.top.middle.tag == 123);
        assertTrue(o.top.middle.foo() == 123);

        // reencode and check round-trip
        xmlOutput = typedEncoder.encodeObject(o);

        assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));

    }

    public function testId():void
    {
    }

}
}

