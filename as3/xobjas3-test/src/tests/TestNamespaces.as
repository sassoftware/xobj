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


public class TestNamespaces extends TestBase
{


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
        var xmlInput:XML = new XML(testData.namespaces);
        var o:* = typedDecoder.decodeXML(xmlInput);

        assertTrue(o.top.other_tag.other_val == '1')
        assertTrue(o.top.other2_tag.val == '2')
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder();
        var xmlOutput:XML = typedEncoder.encodeObject(o.top);

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
        var xmlInput:XML = new XML(testData.namespaces);
        var o:* = typedDecoder.decodeXML(xmlInput);

        assertTrue(o.top.other_tag.other_val == '1')
        assertTrue(o.top.other3_tag.val == '2')
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder();
        var xmlOutput:XML = typedEncoder.encodeObject(o.top);

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
        var xmlInput:XML = new XML(testData.explicitns);
        var o:* = typedDecoder.decodeXML(xmlInput);

        assertTrue(o.ns_top.ns_element.ns_attr == 'foo')
        
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder();
        var xmlOutput:XML = typedEncoder.encodeObject(o.ns_top);

        var expectedString:String = 
                '<ns:top xmlns:ns="http://somens.xsd">' + 
                '<ns:element ns:attr="foo"/>' + 
                '</ns:top>';

        // check that we remap to original prefixes on the way back out
        assertTrue("encode is fully qualified", compareXMLtoString(xmlOutput, expectedString));
    }

     
    }
}

