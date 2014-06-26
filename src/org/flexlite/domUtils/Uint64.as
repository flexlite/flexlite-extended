package org.flexlite.domUtils
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	/**
	 * 64位无符号整数
	 * @author dom
	 */
	public class Uint64
	{
		/**
		 * 构造函数
		 * @param lowerUint 低32位整型数字
		 * @param higherUint 高32位整型数字
		 */		
		public function Uint64(lowerUint:uint=0,higherUint:uint=0)
		{
			_lowerUint = lowerUint;
			_higherUint = higherUint;
		}
		
		private var _higherUint:uint = 0;
		/**
		 * 高32位整型数字
		 */
		public function get higherUint():uint
		{
			return _higherUint;
		}
		public function set higherUint(value:uint):void
		{
			if(_higherUint==value)
				return;
			_higherUint = value;
			cacheBytes = null;
			cacheString = [];
		}
		
		private var _lowerUint:uint = 0;
		/**
		 * 低32位整型数字
		 */
		public function get lowerUint():uint
		{
			return _lowerUint;
		}
		public function set lowerUint(value:uint):void
		{
			_lowerUint = value;
			if(_lowerUint==value)
				return;
			cacheBytes = null;
			cacheString = [];
		}
		
		/**
		 * 从字符串生成数字
		 * @param value 要转换为数字的字符串。
		 * @param radix 要用于字符串到数字的转换的基数（从 2 到 36）。如果未指定 radix 参数，则默认值为 10。
		 */		
		public function fromString(value:String,radix:uint=10):void
		{
			if(!value)
			{
				reset();
				return;
			}
			value = value.toLowerCase();
			var div:Number = 4294967296;
			var low:Number = 0;
			var high:Number = 0;
			for(var i:int=0;i<value.length;i++)
			{
				var num:int = value.charCodeAt(i)-48;
				if(num>9)
					num -= 39;
				low = low*radix+num;
				high = high*radix+int(low/div);
				low = low%div;
			}
			this._lowerUint = low;
			this._higherUint = high;
			cacheString = [];
			cacheString[radix] = value;
			cacheBytes = null;
		}
		/**
		 * 从字节流数组中读取uint64数字
		 * @param bytes 包含64位无符号整型的字节流
		 * @param postion 要从字节流中开始读取的偏移量
		 */		
		public function fromBytes(bytes:ByteArray,postion:uint=0):void
		{
			try
			{
				bytes.position = postion;
				if(bytes.endian==Endian.LITTLE_ENDIAN)
				{
					_lowerUint = bytes.readUnsignedInt();
					_higherUint = bytes.readUnsignedInt();
				}
				else
				{
					_higherUint = bytes.readUnsignedInt();
					_lowerUint = bytes.readUnsignedInt();
				}
			}
			catch(e:Error)
			{
				reset();
				return;
			}
			cacheBytes = null;
			cacheString = [];
		}
		/**
		 * 重置为0
		 */		
		private function reset():void
		{
			_higherUint = 0;
			_lowerUint = 0;
			cacheBytes = null
			cacheString = [];
		}
		/**
		 * 克隆一个数字
		 */		
		public function clone():Uint64
		{
			return new Uint64(_lowerUint,_higherUint);
		}
		/**
		 * 缓存的字节流
		 */		
		private var cacheBytes:ByteArray;
		/**
		 * 返回数字的字节流数组形式,存储方式为Endian.LITTLE_ENDIAN。
		 */		
		public function get bytes():ByteArray
		{
			if(cacheBytes)
				return cacheBytes;
			cacheBytes = new ByteArray();
			cacheBytes.endian = Endian.LITTLE_ENDIAN;
			cacheBytes.writeUnsignedInt(_lowerUint);
			cacheBytes.writeUnsignedInt(_higherUint);
			return cacheBytes;
		}
		/**
		 * 缓存的字符串
		 */		
		private var cacheString:Array = [];
		/**
		 * 返回数字的字符串表示形式。
		 * @param radix 指定要用于数字到字符串的转换的基数（从 2 到 36）。如果未指定 radix 参数，则默认值为 10。
		 */		
		public function toString(radix:uint=10):String
		{
			if(radix<2||radix>36)
			{
				throw new RangeError("基数参数必须介于 2 到 36 之间；当前值为 "+radix+"。");
			}
			if(cacheString[radix])
				return cacheString[radix];
			var result:String="";
			var lowUint:uint=_lowerUint;
			var highUint:uint=_higherUint;
			var highRemain:Number;
			var lowRemain:Number;
			var tempNum:Number;
			var MaxLowUint:Number = Math.pow(2,32);
			while(highUint!=0||lowUint!=0)
			{
				highRemain=(highUint%radix);
				tempNum=highRemain*MaxLowUint+lowUint;
				lowRemain=tempNum%radix;
				result=lowRemain.toString(radix)+result;
				highUint=(highUint-highRemain)/radix;
				lowUint=(tempNum-lowRemain)/radix;
			}
			cacheString[radix] = result;
			return cacheString[radix];
		}
	}
}