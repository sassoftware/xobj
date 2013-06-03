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
import com.rpath.xobj.IInvalidationAware;

import flash.utils.Dictionary;

import mx.core.FlexGlobals;

public class InvalidationAware implements IInvalidationAware
{
    public function InvalidationAware()
    {
        super();
    }
    
    // INVALIDATION AND COMMITPROPERTIES PATTERN
    
    private var invalidatePropertiesFlag:Boolean;
    
    public function invalidateProperties():void
    {
        if (!invalidatePropertiesFlag)
        {
            invalidatePropertiesFlag = true;
            invalidateObject(this);
        }
    }
    
/*    public function validateNow():void
    {
        
    }
    */
    protected function commitProperties():void
    {
        // override this
    }
    
    // -- INVALIDATION SUPPORT
    private static var invalidObjects:Dictionary = new Dictionary(true);
    private static var validatePending:Boolean = false;
    
    protected static function invalidateObject(obj:InvalidationAware):void
    {
        invalidObjects[obj] = true;
        
        if (!validatePending)
        {
            validatePending = true;
            FlexGlobals.topLevelApplication.callLater(validateObjects);
        }
    }
    
    protected static function validateObjects():void
    {
        var invalidQueue:Dictionary = invalidObjects;
        
        // start a fresh tracker for further invalidations
        // that are a side effect of this pass
        invalidObjects = new Dictionary(true);
        // ready to receive another call
        validatePending = false;
        
        for (var o:* in invalidQueue)
        {
            var rm:InvalidationAware = o as InvalidationAware;
            if (rm)
            {
                // clear the flag first, in case we're reentrant
                // on any given instance
                rm.invalidatePropertiesFlag = false;
                rm.commitProperties();
            }
        }
        
    }
    
}
}
