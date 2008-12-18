package com.rpath.xobj
{
    [RemoteClass]   // tell the compiler we can be deep copied  
    public class XObjQName
    {
        public function XObjQName(uri:String="", localName:String="")
        {
            this.uri=uri;
            this.localName=localName;
        }

        public var localName:String;
        
        public var uri:String;
        
    }
}