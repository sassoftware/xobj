package com.rpath.xobj
{
import flash.utils.Dictionary;
import mx.collections.ArrayCollection;

public class XObjDefaultFactory implements IXObjFactory
{
    public function XObjDefaultFactory()
    {
        super();
    }
    
    public static var idMap:Dictionary = new Dictionary(true);
    
    public function newObject(type:Class, id:String):Object
    {
        var result:Object;
        
        result = new type();
        if (id && result.hasOwnProperty("id"))
        {
            result.id = id;
            idMap[id] = result;
        }
        return result;
    }
    
    public function getObjectForId(id:String):Object
    {
        return idMap[id];
    }
    
    public function trackObjectById(item:Object, id:String):void
    {
        if (item)
        {
            item.id = id;
            idMap[id] = item;
        }
    }
    
    public function newCollectionFrom(item:*):*
    {
        var result:ArrayCollection;
        
        if (!(item is Array))
            item = [item];
        
        result = new ArrayCollection(item);
        return result;
    }
        

}
}