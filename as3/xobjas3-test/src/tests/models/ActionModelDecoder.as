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


package tests.models
{
import com.rpath.xobj.XObjDecoder;
import com.rpath.xobj.XObjDecoderInfo;
import com.rpath.xobj.XObjXMLDecoder;
public class ActionModelDecoder extends XObjDecoder
{
    
    public function ActionModelDecoder()
    {
        super();
    }
    
    override public function decodeIntoObject(xobj:XObjXMLDecoder, xml:XML, obj:Object, info:XObjDecoderInfo, isArray:Boolean, isCollection:Boolean, shouldMakeBindable:Boolean):Object
    {
        var m:ActionModel = obj as ActionModel;
        if (!m)
            return null;
        if (xml.descriptor.length() > 0)
            m.descriptor = xobj.decodePart(xml.descriptor, m.descriptor, Object);
        if (xml.name.length() > 0)
            m.name = xml.name;
        if (xml.enabled.length() > 0)
            m.enabled = isTrue(xml.enabled);
        if (xml.job_type.length() > 0)
            m.job_type = xobj.decodePart(xml.job_type, m.job_type, Object);
        if (xml.description.length() > 0)
            m.description = xml.description;
        if (xml.resources.length() > 0)
            m.resources = xobj.decodePart(xml.resources, m.resources, Object);
        if (xml.key.length() > 0)
            m.key = xml.key;
        info.isNullObject = false;
        return m;
    }
}
}
