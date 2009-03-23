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
    
    import flash.xml.*;
    
    import mx.utils.ObjectUtil;
    
    import tests.models.*;
    
    
    public class TestTransients extends TestBase
    {
        /** 
         * Ensure transient data is never encoded
         */
        public function testTransient():void
        {
            var obj:TestableObject = new TestableObject();
            obj.someVal = "someval";
            obj.transientVar = "transient";
            obj.xobjTransientVar = "xobjtransient";
            var typeMap:* = {obj: TestableObject};
            
            var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder(typeMap);
            var xmlOutput:XMLDocument = typedEncoder.encodeObject(obj);
    
            // neither the Transient nor the xobjTransient vars should be there
            var expectedString:String = 
                '<obj>\n'+
                '  <booleanVar>false</booleanVar>\n'+
                '  <someVal>someval</someVal>\n'+                
                '</obj>\n';
            
            assertTrue(compareXMLtoString(xmlOutput, expectedString));
            
            // now decode it and validate
            var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder(typeMap);
            var xmlInput:XMLDocument = xmlOutput;
            var o:* = typedDecoder.decodeXML(xmlInput);
            assertTrue(o.obj is TestableObject);
            assertTrue(o.obj.someVal =="someval");
            assertTrue(o.obj.transientVar == null);
            assertTrue(o.obj.xobjTransientVar == null);
            
            // reencode and check round-trip
            xmlOutput = typedEncoder.encodeObject(o);
            assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));
        }
    }
}

