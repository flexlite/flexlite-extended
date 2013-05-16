package org.flexlite.domDisplay.utils
{
	import flash.display.DisplayObject;
	import flash.utils.ByteArray;
	
	import org.flexlite.domDisplay.codec.DxrDecoder;
	import org.flexlite.domDisplay.codec.DxrEncoder;
	import org.flexlite.domUtils.CRC32Util;
	import org.flexlite.domUtils.FileUtil;
	
	/**
	 * DXR拆分合并工具
	 * @author DOM
	 */
	public class DxrUtil
	{
		/**
		 * 从Dxr文件中移除指定的键值列表。
		 * @param dxrPath dxr文件路径
		 * @param keys 要移除的键值列表
		 * @param newPath 修改完成后存储的路径，不设置则覆盖源文件(若要删除的文件已经不存在key，则直接删除源文件)。
		 */		
		public static function remove(dxrPath:String,keys:Array,newPath:String=""):void
		{
			var bytes:ByteArray = FileUtil.openAsByteArray(dxrPath);
			if(!bytes)
				return;
			bytes = removeFromBytes(bytes,keys);
			if(!bytes)
			{
				if(!newPath)
					FileUtil.deletePath(dxrPath);
				return;
			}
			if(!newPath)
				newPath = dxrPath;
			FileUtil.save(dxrPath,bytes);
		}
		/**
		 * 为Dxr文件字节流移除指定的键值列表，返回修改后的文件字节流,若已经不存在key则返回null。
		 * @param bytes dxr文件字节流
		 * @param keys 要移除的键值列表
		 */		
		public static function removeFromBytes(bytes:ByteArray,keys:Array):ByteArray
		{
			if(!bytes)
				return null;
			var keyObject:Object = DxrDecoder.readObject(bytes);
			for(var key:String in keyObject.keyList)
			{
				if(keys.indexOf(key)!=-1)
					delete keyObject.keyList[key];
			}
			var has:Boolean = false;
			for(key in keyObject.keyList)
			{
				has = true;
				break;
			}
			if(!has)
				return null;
			return DxrEncoder.writeObject(keyObject);
		}
		/**
		 * 合并指定的dxr文件列表。该操作不会删除原始文件。
		 * @param dxrPathList dxr文件路径列表
		 * @param fileName 合并后的文件名，若不指定则自动生成。
		 */		
		public static function merge(dxrPathList:Array,fileName:String = ""):void
		{
			if(!dxrPathList||dxrPathList.length==0)
				return;
			var bytesList:Array = [];
			for each(var path:String in dxrPathList)
			{
				var bytes:ByteArray = FileUtil.openAsByteArray(path);
				if(!bytes)
					continue;
				bytesList.push(bytes);
			}
			var dxrBytes:ByteArray = mergeBytes(bytesList);
			if(!dxrBytes)
				return;
			if(!fileName)
			{
				var dxrPath:String = dxrPathList[0];
				var name:String = FileUtil.getFileName(dxrPath);
				var index:int = name.indexOf("__");
				if(index!=-1)
					name = name.substr(0,index);
				fileName = FileUtil.getDirectory(dxrPath)+name+"__"+CRC32Util.getCRC32(dxrBytes).toString(16);
			}
			FileUtil.save(fileName,dxrBytes);
		}
		/**
		 * 合并指定的Dxr字节流列表
		 */		
		public static function mergeBytes(dxrBytesList:Array):ByteArray
		{
			if(!dxrBytesList||dxrBytesList.length==0)
				return null;
			var hasKey:Boolean = false;
			var keyList:Object = {};
			for each(var bytes:ByteArray in dxrBytesList)
			{
				if(!bytes)
					continue;
				var keyObject:Object = DxrDecoder.readObject(bytes);
				if(!keyObject)
					continue;
				for(var key:String in keyObject.keyList)
				{
					hasKey = true;
					keyList[key] = keyObject.keyList[key];
				}
			}
			if(!hasKey)
				return null;
			return DxrEncoder.writeObject({keyList:keyList});
		}
		
		/**
		 * 为指定的显示对象生成唯一的key
		 * @param dp 要绘制的显示对象，可以是MovieClip
		 */			
		public static function generateKey(dp:DisplayObject):String
		{
			var dxrEncoder:DxrEncoder = new DxrEncoder();
			return dxrEncoder.drawDxrData(dp).key;
		}
	}
}