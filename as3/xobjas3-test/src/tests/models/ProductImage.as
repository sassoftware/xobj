package tests.models
{
import mx.collections.ArrayCollection;

ActionModel;  //force stupid linker

[Bindable]
public dynamic class ProductImage
{
    public function ProductImage()
    {
        super();
    }
    
    public var id:String;
    
    public static const decoderClass:Class = ProductImageDecoder;
    
    [ElementType(ActionModel)]
    public var actions:ArrayCollection;
    
}
}