package tests.models
{
import com.rpath.xobj.IXObjSerializing;
import com.rpath.xobj.XObjDecoderInfo;
import com.rpath.xobj.XObjXMLDecoder;

[Bindable]
public dynamic class ProductImage implements IXObjSerializing
{
    public function ProductImage()
    {
        super();
    }
    
    //public static const decoderClass:Class = ProductImageDecoder;
    private var _decoder:ProductImageDecoder = new ProductImageDecoder();
    
    // self-decoding
    public function decodeIntoObject(xobj:XObjXMLDecoder, xml:XML, object:Object, info:XObjDecoderInfo, isArray:Boolean, isCollection:Boolean, shouldMakeBindable:Boolean):Object
    {
        return _decoder.decodeIntoObject(xobj, xml,object,info,isArray,isCollection,shouldMakeBindable);
    }
    
}
}