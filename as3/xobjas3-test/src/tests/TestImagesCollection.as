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

import flash.xml.XMLDocument;

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
        var xmlInput:XMLDocument = new XMLDocument(testData.imagecollection);
        var o:* = typedDecoder.decodeXML(xmlInput);
        
        assertTrue("images is object", o.images is ImagesCollection);
        assertTrue("images is array collection", o.images.image is ArrayCollection);
        
        var index:int = 0;
        for (index = 0; index < o.images.image.length; index++)
        {
            var image:ProductImage = o.images.image[index];
            assertTrue("image id is right", image.imageId == index);
            index++;
        }

    }


    
}
}

