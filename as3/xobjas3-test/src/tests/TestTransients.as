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
            var xmlOutput:XML = typedEncoder.encodeObject(obj);
    
            // neither the Transient nor the xobjTransient vars should be there
            var expectedString:String = 
                '<obj>'+
                '<booleanVar>false</booleanVar>'+
                '<someVal>someval</someVal>'+                
                '</obj>';
            
            assertTrue(compareXMLtoString(xmlOutput, expectedString));
            
            // now decode it and validate
            var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder(typeMap);
            var xmlInput:XML = xmlOutput;
            var o:* = typedDecoder.decodeXML(xmlInput);
            assertTrue(o.obj is TestableObject);
            assertTrue(o.obj.someVal =="someval");
            assertTrue(o.obj.transientVar == null);
            assertTrue(o.obj.xobjTransientVar == null);
            
            // reencode and check round-trip
            xmlOutput = typedEncoder.encodeObject(o.obj);
            assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));
        }
    }
}
