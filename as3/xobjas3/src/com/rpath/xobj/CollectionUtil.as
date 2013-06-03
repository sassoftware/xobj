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


package com.rpath.xobj
{
import mx.collections.ArrayCollection;
import mx.collections.ICollectionView;
import mx.collections.IList;
import mx.collections.ListCollectionView;
import mx.collections.Sort;
import mx.collections.SortField;
import mx.collections.XMLListCollection;

public class CollectionUtil
{
    public static function objectToCollection ( object:Object ) : ICollectionView
    {
        var collection:ICollectionView;
        
        if (object is Array)
        {
            collection = new ArrayCollection(object as Array);
        }
        else if (object is ICollectionView)
        {
            collection = ICollectionView(object);
        }
        else if (object is IList)
        {
            collection = new ListCollectionView(IList(object));
        }
        else if (object is XMLList)
        {
            collection = new XMLListCollection(object as XMLList);
        }
        else
        {
            collection = new ArrayCollection([object]);
        }
        
        return collection;
    }
    
    public static function filterCollection ( source:Array,
                                              indexString:String, 
                                              prefix:String ) : Array
    {
        var output:Array = [];
        
        if ( prefix == "" )
        {
            return output;
        }
        
        
        var i:Number = 0;
        var pos:Number = 0;
        var index:int = 0;
        var count:int = 0;
        
        while(i > -1){
            
            pos = indexString.indexOf(prefix, i);
            
            if(pos > -1)
            {
                index = int( indexString.substring(indexString.indexOf("<", pos)+1, indexString.indexOf(">", pos)) );
                
                output.push(source[index]);
                count++;
                
                //fix : Bug # 1628014: once a match was found this index was not being advanced to the new row in the grid so multiple rows were being returned
                //in the case of the same term applying twice in a row.
                i = indexString.indexOf(">", pos);
            }
            else
            {
                i = pos;
            }
        }
        return output;
    }
    
    /** idAandB computes the intersection of two collections
     by the id properties of the objects within them
     **/
    
    public static function idAandB(objA:*, objB:*):Array
    {
        var results:Array = [];
        var collA:ICollectionView;
        var collB:ICollectionView;
        
        collA = CollectionUtil.objectToCollection(objA);
        collB = CollectionUtil.objectToCollection(objB);
        
        try
        {
            //TODO: figure out if Array.sortOn() would be faster
            // sort both lists
            var sort:Sort = new Sort();
            sort.fields = [ new SortField('id')];
            collA.sort = sort;
            collA.refresh();
            
            collB.sort = sort;
            collB.refresh();
            
            var index:int = 0;
            var lenB:int = collB.length;
            for each (var item:* in collA)
            {
                if (index >= lenB)
                    break;
                
                if (item.id == collB[index].id)
                {
                    results.push(item);
                    index++;
                }
            }         
        }
        catch (e:Error)
        {
            // chances are that one or more objects were missing id properties
            return [];
        }
        
        return results;
    }
    
    
    
    /** idDisjoint computes the set of objects in A that are NOT in B
     **/
    
    public static function idANotB(objA:*, objB:*):Array
    {
        var results:Array = [];
        var collA:ICollectionView;
        var collB:ICollectionView;
        
        collA = CollectionUtil.objectToCollection(objA);
        collB = CollectionUtil.objectToCollection(objB);
        
        try
        {
            //TODO: figure out if Array.sortOn() would be faster
            // sort both lists
            var sort:Sort = new Sort();
            sort.fields = [ new SortField('id')];
            collA.sort = sort;
            collA.refresh();
            
            collB.sort = sort;
            collB.refresh();
            
            var indexA:int = 0;
            var indexB:int = 0;
            var lenA:int = collA.length;
            var lenB:int = collB.length;
            
            for (indexA=0; indexA < collA.length; indexA++)
            {
                if (indexB >= lenB)
                    break;
                
                var item:* = collA[indexA];
                if (item.id == collB[indexB].id)
                {
                    indexB++;
                }
                else
                {
                    results.push(item);
                }
            }
            
            // make sure we also include the remainder of collA
            // TODO: arrays would be quicker here, using splice
            while (indexA < lenA)
            {
                results.push(collA[indexA]);
                indexA++;
            }
        }
        catch (e:Error)
        {
            // chances are that one or more objects were missing id properties
            return [];
        }
        
        return results;
    }
    
    
}
}
