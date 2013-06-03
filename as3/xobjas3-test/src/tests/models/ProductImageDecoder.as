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

import mx.collections.ArrayCollection;

import tests.models.ProductImage;

public class ProductImageDecoder extends XObjDecoder
{
    
    public function ProductImageDecoder()
    {
        super();
    }
    
    override public function decodeIntoObject(xobj:XObjXMLDecoder, xml:XML, obj:Object, info:XObjDecoderInfo, isArray:Boolean, isCollection:Boolean, shouldMakeBindable:Boolean):Object
    {
        var m:ProductImage = obj as ProductImage;
        if (!m)
            return null;
        if (xml.build_log.length() > 0)
            m.build_log = xobj.decodePart(xml.build_log, m.build_log, Object);
        if (xml.imageType.length() > 0)
            m.imageType = xml.imageType;
        if (xml.timeCreated.length() > 0)
            m.timeCreated = xml.timeCreated;
        if (xml.buildCount.length() > 0)
            m.buildCount = xml.buildCount;
        if (xml.creator.length() > 0)
            m.creator = xobj.decodePart(xml.creator, m.creator, Object);
        if (xml.num_image_files.length() > 0)
            m.num_image_files = xml.num_image_files;
        if (xml.jobs.length() > 0)
            m.jobs = xobj.decodePart(xml.jobs, m.jobs, Object);
        if (xml.troveName.length() > 0)
            m.troveName = xml.troveName;
        if (xml.trove_flavor.length() > 0)
            m.trove_flavor = xml.trove_flavor;
        if (xml.troveVersion.length() > 0)
            m.troveVersion = xml.troveVersion;
        if (xml.statusMessage.length() > 0)
            m.statusMessage = xml.statusMessage;
        if (xml.image_type.length() > 0)
            m.image_type = xobj.decodePart(xml.image_type, m.image_type, Object);
        if (xml.@id.length() > 0)
            m.id = xml.@id;
        if (xml.trailingVersion.length() > 0)
            m.trailingVersion = xml.trailingVersion;
        if (xml.files.length() > 0)
            m.files = xobj.decodePart(xml.files, m.files, Object);
        if (xml.stage.length() > 0)
            m.stage = xobj.decodePart(xml.stage, m.stage, Object);
        if (xml.time_created.length() > 0)
            m.time_created = xml.time_created;
        if (xml.trove_last_changed.length() > 0)
            m.trove_last_changed = xml.trove_last_changed;
        if (xml.project_branch.length() > 0)
            m.project_branch = xobj.decodePart(xml.project_branch, m.project_branch, Object);
        if (xml.created_by.length() > 0)
            m.created_by = xobj.decodePart(xml.created_by, m.created_by, Object);
        if (xml.troveFlavor.length() > 0)
            m.troveFlavor = xml.troveFlavor;
        if (xml.name.length() > 0)
            m.name = xml.name;
        if (xml.status.length() > 0)
            m.status = xml.status;
        if (xml.image_id.length() > 0)
            m.image_id = xml.image_id;
        if (xml.troveLastChanged.length() > 0)
            m.troveLastChanged = xml.troveLastChanged;
        if (xml.version.length() > 0)
            m.version = xobj.decodePart(xml.version, m.version, Object);
        if (xml.architecture.length() > 0)
            m.architecture = xml.architecture;
        if (xml.trove_name.length() > 0)
            m.trove_name = xml.trove_name;
        if (xml.project.length() > 0)
            m.project = xobj.decodePart(xml.project, m.project, Object);
        if (xml.imageId.length() > 0)
            m.imageId = xml.imageId;
        if (xml.status_message.length() > 0)
            m.status_message = xml.status_message;
        if (xml.image_count.length() > 0)
            m.image_count = xml.image_count;
        if (xml.stage_name.length() > 0)
            m.stage_name = xml.stage_name;
        if (xml.hostname.length() > 0)
            m.hostname = xml.hostname;
        if (xml.trove_version.length() > 0)
            m.trove_version = xml.trove_version;
        if (xml.trailing_version.length() > 0)
            m.trailing_version = xml.trailing_version;
        if (xml.job_uuid.length() > 0)
            m.job_uuid = xml.job_uuid;
        if (xml.actions.length() > 0)
            // NOTE: more optimal direct decode into array because we know we can
           m.actions = xobj.decodeCollectionMembers(xml.actions.action, m.actions, ArrayCollection, ActionModel);
        info.isNullObject = false;
        return m;
    }
}
}
