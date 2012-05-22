/*
#
# Copyright (c) 2005-2009 rPath, Inc.
#
# All rights reserved
#
*/

package tests.models
{   
import com.rpath.xobj.XObjString;

import flash.events.Event;
import flash.net.*;
import flash.utils.*;

import mx.rpc.AsyncToken;
import mx.utils.ObjectUtil;

[RemoteClass]  // tell the compiler we can be deep copied 
[Bindable]
[Event(name="refreshingChange",type="flash.events.Event")]
public dynamic class BaseModel extends Object
{
    public static const REFRESHING_CHANGE_EVENT:String = "refreshingChange";
    public function BaseModel()
    {
        super();
        
        // let's make sure someone didn't forget the [RemoteClass] metadata
        // important for ObjectUtil.copy() to preserve type
        // TODO: figure out if this safety net is expensive
        var className:String = getQualifiedClassName(this);
        
        try
        {
            registerClassAlias(className, (getDefinitionByName(className) as Class));
        }
        catch (e:ReferenceError)
        {
            // modules provide classes that cannot be seen by the application domain
            // not sure what to do about this!
            // TODO: resolve module loading class registration issues
        }
        
    }
    
    [xobjTransient]
    public var pendingCalls:int;
    
    [xobjTransient]
    public var searchCollections:Boolean = false;
    
    public function addRequest(token:AsyncToken):void
    {
        pendingCalls++;
    }
    
    public function removeRequest(token:AsyncToken):void
    {
        pendingCalls--;
    }
    
    [xobjTransient]
    public function get hasPendingCalls():Boolean
    {
        return pendingCalls > 0;
    }
    
    public function set hasPendingCalls(b:Boolean):void
    {
        // nop-op to satisfy data binding
    }
    
    [xobjTransient]
    
    [Bindable(event="refreshingChange")]
    public function get refreshing():Boolean
    {
        return _refreshing;
    }
    
    private var _refreshing:Boolean;
    
    public function set refreshing(value:Boolean):void
    {
        if (_refreshing == value)
            return;
        
        _refreshing = value;
        dispatchEvent(new Event(REFRESHING_CHANGE_EVENT));
    }
    
    
    // deep copy
    public function copy():*
    {
        return ObjectUtil.copy(this);
    }
    
    
    // TODO: make this function walk dynamic props as well as static props
    // which means using getClassInfo(this) rather than describeType(this)      
    
    // cache the classInfo per instance to save on reindexing calls
    private var classInfo:XML;
}
}
