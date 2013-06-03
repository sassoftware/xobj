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
    

    public class TestEmbeddedXML extends TestBase
    {
        public var xmlInput:XML = 
            <management_interface id="https://dhcp171.eng.rpath.com/api/inventory/management_interfaces/2">
              <description>Windows Management Instrumentation (WMI)</description>
              <management_interface_id>2</management_interface_id>
              <systems/>
              <created_date>2010-10-06T02:09:13.298997+00:00</created_date>
              <credentials_descriptor><descriptor xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.rpath.com/permanent/descriptor-1.0.xsd" xsi:schemaLocation="http://www.rpath.com/permanent/descriptor-1.0.xsd descriptor-1.0.xsd"><metadata></metadata><dataFields><field><name>domain</name><descriptions><desc>Windows Domain</desc></descriptions><type>str</type><default></default><required>true</required></field><field><name>user</name><descriptions><desc>User</desc></descriptions><type>str</type><default></default><required>true</required></field><field><name>password</name><descriptions><desc>Password</desc></descriptions><password>true</password><type>str</type><default></default><required>true</required></field></dataFields></descriptor></credentials_descriptor>
              <port>135</port>
              <name>wmi</name>
              <credentials_readonly>False</credentials_readonly>
            </management_interface>

        /** 
         * Ensure transient data is never encoded
         */
        public function testEmbeddedXML():void
        {
            var obj:TestEmbedded = new TestEmbedded();
            var typeMap:* = {management_interface: TestEmbedded};

            // now decode it and validate
            var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder(typeMap);
            
            var o:* = typedDecoder.decodeXML(new XML(xmlInput));
            var testObj:TestEmbedded = o.management_interface as TestEmbedded;
            
            assertTrue(testObj != null);
            assertTrue(testObj.credentials_descriptor is XML);
        }
    }
}
