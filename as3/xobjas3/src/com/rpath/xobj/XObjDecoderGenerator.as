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

import mx.collections.ArrayCollection;
import mx.core.mx_internal;

public class XObjDecoderGenerator
{
    public function XObjDecoderGenerator()
    {
        super();
    }
    
    /** turn this on to track object decoding in support of generating
     * decoder impls using this class
     */
    public static var generateClasses:Boolean = false;
    
    private static var _typeInfoByClassName:Dictionary = new Dictionary();

    /** recordPropertyInfo() builds up an index of all types, and all properties
     * so that we can consider code-generation of decoding classes
     */
    
    public static function recordPropertyInfo(typeInfo:XObjTypeInfo):void
    {
        var props:Dictionary = _typeInfoByClassName[typeInfo.holderClassName];
        if (!props)
        {
            props = new Dictionary();
            _typeInfoByClassName[typeInfo.holderClassName] = props;
        }
        
        props[typeInfo.propName] = typeInfo;
    }
    
    public static function getPropertyInfo(holderClassName:String, propName:String):XObjTypeInfo
    {
        var props:Dictionary = _typeInfoByClassName[holderClassName];
        if (!props)
        {
            props = new Dictionary();
            _typeInfoByClassName[holderClassName] = props;
        }

        var result:XObjTypeInfo;
        
        result = props[propName];
        if (!result)
        {
            result = new XObjTypeInfo();
            result.propName = propName;
            result.holderClassName = holderClassName;
            props[propName] = result;
        }
        
        return result;
    }
    
    private static function getKeys(d:Dictionary):Array
    {
        var a:Array = new Array();
        
        for (var key:Object in d)
        {
            a.push(key);
        }
        
        return a;
    }
    
    public static function dumpClasses():void
    {
        var s:Array = [];
        var classes:Array = getKeys(_typeInfoByClassName);
        
        classes.sort();

        for each (var c:* in classes)
        {
            if (c == null)
                continue;
            
            var clazz:Class = XObjUtils.getClassByName(c);
            if (clazz == null || clazz == Object ||
                clazz == String || clazz == Array ||
                clazz == ArrayCollection)
                continue;
            
            var cname:String = XObjUtils.getUnqualfiedClassName(clazz);
            if (cname == null)
                continue;
            
            s.push("/*");
            s.push("#");
            s.push("# Copyright (c) SAS Institute Inc.");
            s.push("#");
            s.push("*/");
            
            s.push("package com.rpath.rbuilder.models");
            s.push("{");
            s.push("import com.rpath.xobj.XObjDecoder;");
            s.push("import com.rpath.xobj.XObjDecoderInfo;");
            s.push("import com.rpath.xobj.XObjXMLDecoder;");
            s.push("import com.verveguy.rest.RESThref;");
            
            s.push("public class "+ cname +"Decoder extends XObjDecoder");
            s.push("{");
            s.push("");
            s.push("    public function "+ cname +"Decoder()");
            s.push("    {");
            s.push("        super();");
            s.push("    }");
            s.push("");
            s.push("    override public function decodeIntoObject(xobj:XObjXMLDecoder, xml:XML, " +
                "obj:Object, info:XObjDecoderInfo, " +
                "isArray:Boolean, isCollection:Boolean, " +
                "shouldMakeBindable:Boolean):Object");
            s.push("    {");
            
            s.push("        var m:"+cname+" = obj as "+cname+";");
            s.push("        if (!m)");
            s.push("            return null;");
            
            var props:Dictionary = _typeInfoByClassName[c];
            if (props)
            {
                // sort keys
                var propNames:Array = getKeys(props);
                propNames.sort();
                
                for each (var propName:String in propNames)
                {
                    var t:XObjTypeInfo = props[propName];
                    
                    var xe:String = "xml."+ (t.isAttribute ? "@" : "")+t.propName;
                    var op:String = "m."+t.propName;
                    
                    var tname:String = XObjUtils.getUnqualfiedClassName(XObjUtils.getClassByName(t.typeName));
                    
                    if (!tname)
                        tname = "null";
                    
                    s.push("        if ("+xe+".length() > 0)");
                    if (t.isArray)
                    {
                        s.push("            "+op+" = xobj.decodeArray("+xe+", "+op+
                            ", "+tname+", "+t.arrayElementTypeName+");");
                    }
                    else if (t.isCollection)
                    {
                        s.push("            "+op+" = xobj.decodeCollection("+xe+", "+op+
                            ", "+tname+", "+t.arrayElementTypeName+");");
                    }
                    else if (t.isSimpleType)
                    {
                        if (tname == "Boolean")
                            s.push("            "+op+" = isTrue("+xe+");");
                        else
                            s.push("            "+op+" = "+xe+";");
                    }
                    else
                    {
                        s.push("            "+op+" = xobj.decodePart("+xe+", "+op+ 
                            ", "+tname+");");
                    }
                }
            }
            
            s.push("        info.isNullObject = false;");
            s.push("        return m;");
            s.push("    }");
            s.push("}");
            s.push("}");
            s.push("\n--- END ------");
        }
        
        // dump to console
        for each (var line:String in s)
        {
            trace(line);
        }
    }
    
}
}
