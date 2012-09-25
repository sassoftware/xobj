/*
# Copyright (c) 2008-2010 rPath, Inc.
#
# This program is distributed under the terms of the MIT License as found
# in a file called LICENSE. If it is not present, the license
# is always available at http://www.opensource.org/licenses/mit-license.php.
#
# This program is distributed in the hope that it will be useful, but
# without any warranty; without even the implied warranty of merchantability
# or fitness for a particular purpose. See the MIT License for full details.
#
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
    
    public function XObjSchemaLoader(schemaUrl:String=null, loadCompleteHandler:Function=null, loadFailedHandler:Function=null, loadStatusHandler:Function=null)
    {
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
        message = "Loading schema " + event.location + "...";
        processStatus();
    }
    
    private function schemaLoader_loadHandler(event:SchemaLoadEvent):void
    {
        setXMLSchema(event.schema);
        processCompletion();
    }
    
    private function schemaLoader_faultHandler(event:FaultEvent):void
    {
        message = event.fault.faultString;
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