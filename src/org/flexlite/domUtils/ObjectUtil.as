package org.flexlite.domUtils
{
	import flash.utils.ByteArray;

	/**
	 * 
	 * @author dom
	 */
	public class ObjectUtil
	{
		/**
		 * 克隆一个数据对象
		 */		
		public static function clone(data:Object):Object
		{
			if(!data)
				return null;
			var bytes:ByteArray = new ByteArray();
			bytes.writeObject(data);
			bytes.position = 0;
			return bytes.readObject();
		}
	}
}