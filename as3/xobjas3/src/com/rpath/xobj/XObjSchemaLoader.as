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
import flash.utils.Dictionary;

import mx.collections.ISort;
import mx.collections.Sort;
import mx.collections.SortField;
import mx.rpc.events.FaultEvent;
import mx.rpc.events.SchemaLoadEvent;
import mx.rpc.events.XMLLoadEvent;
import mx.rpc.xml.Schema;
import mx.rpc.xml.SchemaLoader;
import mx.rpc.xml.SchemaManager;
import mx.rpc.xml.SchemaTypeRegistry;

[Bindable]
public class XObjSchemaLoader
{
    public var schemaName:String;
    public var schemaUrl:String;
    
    private var schemaManager:SchemaManager;
    private var schemaLoader:SchemaLoader;
    private var schema:Schema;
    
    public var schemaLoaded:Boolean;
    
    public var message:String;
    
    public var schemaXML:XML;
    public var schemaStr:String;
    
    public var loadCompleteHandler:Function;
    public var loadFailedHandler:Function;
    public var loadStatusHandler:Function;
    
    public function XObjSchemaLoader(schemaName:String=null, schemaUrl:String=null, loadCompleteHandler:Function=null, loadFailedHandler:Function=null, loadStatusHandler:Function=null)
    {
        this.schemaName = schemaName;
        this.schemaUrl = schemaUrl;
        this.loadCompleteHandler = loadCompleteHandler;
        this.loadFailedHandler = loadFailedHandler;
        this.loadStatusHandler = loadStatusHandler;
    }
    
    public function loadSchema():void
    {
        schemaManager = new SchemaManager();
        schemaLoader = new SchemaLoader();
        
        schemaLoader = new SchemaLoader();
        schemaLoader.addEventListener(SchemaLoadEvent.LOAD, schemaLoader_loadHandler);
        schemaLoader.addEventListener(XMLLoadEvent.LOAD, schemaLoader_xmlLoadHandler);
        schemaLoader.addEventListener(FaultEvent.FAULT, schemaLoader_faultHandler);
        
        schemaLoader.load(schemaUrl);
    }
    
    private function schemaLoader_xmlLoadHandler(event:XMLLoadEvent):void
    {
        message = "Loading schema " + schemaName + " from " + event.location + "...";
        processStatus();
    }
    
    private function schemaLoader_loadHandler(event:SchemaLoadEvent):void
    {
        setXMLSchema(event.schema);
        processCompletion();
    }
    
    private function schemaLoader_faultHandler(event:FaultEvent):void
    {
        message = "Failed loading schema " + schemaName + " from " + schemaUrl + ": " + event.fault.faultString;
        processFailure();
    }
    
    private function setXMLSchema(value:Schema):void
    {
        schema = value;
        
        if (schema)
        {
            schemaXML = schema.xml;
            schemaStr = schema.xml.toString();
            
            //Add the loaded schema to the SchemaManager
            schemaManager.addSchema(schema);
            
            var schemaTypeRegistry:SchemaTypeRegistry;
            schemaTypeRegistry = SchemaTypeRegistry.getInstance();
        }
        
        schemaLoaded = true;
        message = null;
    }
    
    private function processCompletion():void
    {
        if (loadCompleteHandler != null)
            loadCompleteHandler();
    }
    
    private function processFailure():void
    {
        if (loadFailedHandler != null)
            loadFailedHandler();
    }
    
    private function processStatus():void
    {
        if (loadStatusHandler != null)
            loadStatusHandler();
    }
}
}
