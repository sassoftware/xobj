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

import mx.collections.ArrayCollection;

import tests.models.*;


public class TestImagesCollection extends TestBase
{
    /** testImagesCollection 
     * test basic decoding behavior of involving metadata
     */
    public function testImagesCollection():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({images:ImagesCollection, image:ProductImage});
        var xmlInput:XML = new XML(testData.imagecollection);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("images is object", o.images is ImagesCollection);
        assertTrue("images is array collection", o.images[0] is ProductImage);
        
        var index:int = 0;
        for (index = 0; index < o.images.length; index++)
        {
            var image:ProductImage = o.images[index];
            assertTrue("elements are ProductImage", image != null);
            assertTrue("image id is right", image.imageId == index);
        }
        
        //re-encode list and cross-check
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder({images:ImagesCollection, image:ProductImage});
        var xmlOutput:XML = typedEncoder.encodeObject(o.images);
        
        //TODO: figure out how to actually compare XML that isn't sort-stable
        //assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));
    }
    
    
    /** testLargeImagesCollection 
     * same as above but for timing purposes
     */
    public function testLargeImagesCollection():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({images:ImagesCollection, image:ProductImage});
        var xmlInput:XML = new XML(testData.large_imagecollection);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("images is object", o.images is ImagesCollection);
        assertTrue("images is array collection", o.images[0] is ProductImage);
        
        var index:int = 0;
        for (index = 0; index < o.images.length; index++)
        {
            var image:ProductImage = o.images[index];
            assertTrue("elements are ProductImage", image != null);
        }
        
        //re-encode list and cross-check
        var typedEncoder:XObjXMLEncoder = new XObjXMLEncoder({images:ImagesCollection, image:ProductImage});
        var xmlOutput:XML = typedEncoder.encodeObject(o.images);
        
        //TODO: figure out how to actually compare XML that isn't sort-stable
        //assertTrue("encode matches input", compareXML(xmlOutput, xmlInput));
    }
    
    
    /** testLargeImagesCollection100times 
     * same as above but for timing purposes
     */
    /*public function testLargeImagesCollection100times():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({images:ImagesCollection, image:ProductImage});
        var xmlInput:XML = new XML(testData.large_imagecollection);
        
        
        for (var loop:int ; loop < 100 ; loop++)
        {
            var o:* = typedDecoder.decodeXML(xmlInput);
        }
    }*/
    
    
}
}
