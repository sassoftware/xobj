package tests.models
{
import mx.collections.ArrayCollection;

[Bindable]
public dynamic class ImagesCollection 
{
    [ArrayElementType("tests.models.ProductImage")]
    public var image:ArrayCollection = new ArrayCollection();
}
}