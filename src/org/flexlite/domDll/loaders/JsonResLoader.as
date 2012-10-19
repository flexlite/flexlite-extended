package org.flexlite.domDll.loaders
{
	import com.adobe.serialization.json.JSON;
	
	import flash.utils.ByteArray;
	
	/**
	 * JSON文件加载器
	 * @author DOM
	 */
	public class JsonResLoader extends ResLoaderBase
	{
		public function JsonResLoader()
		{
			super();
		}
		
		override public function getRes(key:String):*
		{
			if(sharedMap.has(key))
				return sharedMap.get(key);
			var bytes:ByteArray = fileDic[key];
			if(!bytes)
				return null;
			try
			{
				bytes.uncompress();
			}
			catch(e:Error){}
			bytes.position = 0;
			var resultStr:String = bytes.readUTFBytes(bytes.length);
			var data:Object;
			try
			{
				data = com.adobe.serialization.json.JSON.decode(resultStr);
			}
			catch(e:Error){}
			sharedMap.set(key,data);
			return data;
		}
	}
}