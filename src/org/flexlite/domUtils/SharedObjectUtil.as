package org.flexlite.domUtils
{
	import flash.net.SharedObject;
	
	/**
	 * 本地缓存工具类 
	 * @author dom
	 */	
	public class SharedObjectUtil
	{
		/**
		 * 为本地存储对象添加数据 
		 * @param name SharedObject对象的名称。
		 * @param key 要读取的键
		 * @param data 要存储的值
		 */		
		public static function write(name:String,key:String,data:*):void
		{
			try
			{
				var sharedObject:SharedObject = SharedObject.getLocal(name,"/");
				sharedObject.data[key] = data;
				sharedObject.flush(1000);
			}
			catch(e:Error){}
		}
		
		/**
		 * 读取本机存储对象数据  
		 * @param name SharedObject对象的名称。
		 * @param key 要读取的键
		 */		
		public static function read(name:String,key:String):*
		{
			try
			{
				var sharedObject:SharedObject = SharedObject.getLocal(name,"/");
				return sharedObject.data[key];
			}
			catch(e:Error){}
			return null;
		}
	}
}