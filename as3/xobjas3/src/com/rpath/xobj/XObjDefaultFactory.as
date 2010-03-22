package com.rpath.xobj
{
public class XObjDefaultFactory implements IXObjFactory
{
    public function XObjDefaultFactory()
    {
        super();
    }
    
    public function newObject(type:Class, id:String):Object
    {
        var result:Object;
        
        result = new type();
        if (result.hasOwnProperty("id"))
        {
            result.id = id;
        }
        return result;
    }

}
}