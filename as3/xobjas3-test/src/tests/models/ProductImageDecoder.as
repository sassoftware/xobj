/*
#
# Copyright (c) 2007-2012 rPath, Inc.
#
# All rights reserved
#
*/

package tests.models
{
import com.rpath.xobj.XObjDecoder;
import com.rpath.xobj.XObjDecoderInfo;
import com.rpath.xobj.XObjDefaultFactory;
import com.rpath.xobj.XObjXMLDecoder;

import mx.managers.SystemManager;

[Mixin]
public class ProductImageDecoder extends XObjDecoder
{
    
    public static function init(mgr:SystemManager):void
    {
        //XObjDefaultFactory.registerDecoderClassForClass(ProductImageDecoder, ProductImage);
    }
    
    public function ProductImageDecoder()
    {
        super();
    }
    
    override public function decodeIntoObject(xobj:XObjXMLDecoder, xml:XML, object:Object, info:XObjDecoderInfo, isArray:Boolean, isCollection:Boolean, shouldMakeBindable:Boolean):Object
    {
        var image:ProductImage = object as ProductImage;
        
        if (!image)
            return null;
        
        image.id = xml.@id;
        image.imageId = int(xml.imageId);
        image.hostname = String(xml.hostname);
        image.release = xml.release;
        image.imageType = xml.imageType;
        image.name = xml.name;
        image.troveName = xml.troveName;
        image.troveVersion = xml.troveVersion;
        image.trailingVersion = xml.trailingVersion.toString();
        image.troveFlavor = xml.troveFlavor;
        image.troveLastChanged = xml.troveLastChanged;
        image.version = { href: xml.version.@href.toString() };
        image.stage = { href: xml.stage.@href.toString()};
        image.creator = { href: xml.creator.@href.toString() };
        image.updater = { href: xml.updater.@href.toString() };
        image.timeCreated = xml.timeCreated;
        image.buildCount = xml.buildCount;
        image.status = xml.status;
        image.statusMessage = xml.statusMessage;
        
        image.files = xobj.decodeArray(xml.files);
        
        info.isNullObject = false;
        
        return image;
    }
    
}
}