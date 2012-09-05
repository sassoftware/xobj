/*
#
# Copyright (c) 2007-2012 rPath, Inc.
#
# All rights reserved
#
*/

package com.rpath.xobj
{
import flash.utils.Dictionary;

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
    
    /** stashTypeInfo builds up an index of all types, and all properties
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
    
    private static var _typeInfoByClassName:Dictionary = new Dictionary();
    
    public static function dumpClasses():void
    {
        var s:Array = [];
        
        for (var c:* in _typeInfoByClassName)
        {
            if (c == null)
                continue;
            
            var clazz:Class = XObjUtils.getClassByName(c);
            if (clazz == null)
                continue;
            
            var cname:String = XObjUtils.getUnqualfiedClassName(clazz);
            if (cname == null)
                continue;
            
            s.push("/*");
            s.push("#");
            s.push("# Copyright (c) 2007-2012 rPath, Inc.");
            s.push("#");
            s.push("# All rights reserved");
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
                for each (var t:XObjTypeInfo in props)
                {
                    var xe:String = "xml."+ (t.isAttribute ? "@" : "")+t.propName;
                    var op:String = "m."+t.propName;
                    
                    var tname:String = XObjUtils.getUnqualfiedClassName(XObjUtils.getClassByName(t.typeName));
                    
                    s.push("        if ("+xe+".length() > 0)");
                    if (t.isArray)
                    {
                        s.push("            "+op+" = xobj.decodeArray("+xe+", "+op+
                            ", "+t.arrayElementClass+");");
                    }
                    else if (t.isCollection)
                    {
                        s.push("            "+op+" = xobj.decodeCollection("+xe+", "+op+
                            ", "+t.arrayElementClass+");");
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