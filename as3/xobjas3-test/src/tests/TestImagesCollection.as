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
    public function testLargeImagesCollection100times():void
    {
        var typedDecoder:XObjXMLDecoder = new XObjXMLDecoder({images:ImagesCollection, image:ProductImage});
        var xmlInput:XML = new XML(testData.large_imagecollection);
        
        
        for (var loop:int ; loop < 100 ; loop++)
        {
            var o:* = typedDecoder.decodeXML(xmlInput);
        }
    }

    
}
}

