package tests.models
{
import com.verveguy.rest.RESThref;

import mx.collections.ArrayCollection;

[Bindable]
public dynamic class ImagesCollection extends RESThref
{
    [ArrayElementType("tests.models.ProductImage")]
    public var image:ArrayCollection = new ArrayCollection();
}
}