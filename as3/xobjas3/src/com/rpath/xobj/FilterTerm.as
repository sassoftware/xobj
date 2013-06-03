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

[RemoteClass]
[Bindable]
public class FilterTerm
{
    public function FilterTerm(field:String,
                               value:String,
                               operator:String = EQUAL)
    {
        super();
        
        this.field = field;
        this.operator = operator;
        this.value = value;
    }
    
    /**
     * The field/property to filter on (LHS)
     */
    public var field:String;
    
    /**
     * The logical operator to apply (see static consts below)
     */
    public var operator:String;
    
    /**
     * The value to test the field against (RHS)
     */
    public var value:String;
    
    public static const EQUAL:String = "EQUAL";
    public static const NOT_EQUAL:String = "NOT_EQUAL";
    
    public static const IS_NULL:String = "IS_NULL";
    public static const IS_NOT_NULL:String = "IS_NOT_NULL";
    
    public static const LESS_THAN:String = "LESS_THAN";
    public static const LESS_THAN_OR_EQUAL:String = "LESS_THAN_OR_EQUAL";
    public static const GREATER_THAN:String = "GREATER_THAN";
    public static const GREATER_THAN_OR_EQUAL:String = "GREATER_THAN_OR_EQUAL";
    public static const LIKE:String = "LIKE";
    public static const NOT_LIKE:String = "NOT_LIKE";
    public static const IN:String = "IN";
    public static const NOT_IN:String = "NOT_IN";
/*  NOT YET IMPLEMENTED  
    public static const MATCHING:String = "MATCHING";
    public static const NOT_MATCHING:String = "NOT_MATCHING";
*/    
    public static const YES:String = "YES";
    public static const NO:String = "NO";
    
    
}
}
