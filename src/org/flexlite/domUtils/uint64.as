package org.flexlite.domUtils
{
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	/**
	 * 64位无符号整数
	 * @author DOM
	 */
	public class uint64
	{
		/**
		 * 构造函数
		 * @param value 要转换为数字的字符串。
		 * @param radix 要用于字符串到数字的转换的基数（从 2 到 36）。如果未指定 radix 参数，则默认值为 10。
		 */		
		public function uint64(value:String="",radix:uint=10)
		{
			if(value)
			{
				fromString(value,radix);
			}
		}
		/**
		 * 高32位数字
		 */		
		private var highByte:uint = 0;
		/**
		 * 低32位数字
		 */		
		private var lowByte:uint = 0;
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
			this.lowByte = low;
			this.highByte = high;
			cacheString = new Dictionary();
			cacheString[radix] = value;
			cacheBytes = null;
		}
		/**
		 * 从字节流数组中读取数字
		 * @param bytes 包含64位无符号整型的数字
		 */		
		public function fromBytes(bytes:ByteArray):void
		{
			if(!bytes||bytes.length<64)
			{
				reset();
				return;
			}
			bytes.position = 0;
			highByte = bytes.readUnsignedInt();
			lowByte = bytes.readUnsignedInt();
			cacheBytes = bytes;
			cacheString = new Dictionary();
		}
		/**
		 * 重置
		 */		
		private function reset():void
		{
			highByte = 0;
			lowByte = 0;
			cacheBytes = null
			cacheString = new Dictionary();
		}
		
		private var cacheBytes:ByteArray;
		/**
		 * 返回数字的字节流数组形式
		 */		
		public function get bytes():ByteArray
		{
			if(cacheBytes)
				return cacheBytes;
			cacheBytes = new ByteArray();
			cacheBytes.writeUnsignedInt(highByte);
			cacheBytes.writeUnsignedInt(lowByte);
			return cacheBytes;
		}
		/**
		 * 缓存的字符串
		 */		
		private var cacheString:Dictionary = new Dictionary();
		/**
		 * 返回数字的字符串表示形式。
		 * @param radix 指定要用于数字到字符串的转换的基数（从 2 到 36）。如果未指定 radix 参数，则默认值为 10。
		 */		
		public function toString(radix:uint=10):String
		{
			if(cacheString[radix]!==undefined)
				return cacheString[radix];
			
			var highNums:Array = readNumberArray(highByte.toString(radix));
			var lowNums:Array = readNumberArray(lowByte.toString(radix));
			var mutli:Number = 4294967296;
			var multiNums:Array = readNumberArray(mutli.toString(radix));
			
			var result:Array = [];
			var length:int = 64;
			for(var i:int=0;i<length;i++)
				result[i] = 0;
			
			length = highNums.length;
			var multiLength:int = multiNums.length;
			for(i=0;i<length;i++)
			{
				for(var j:int=0;j<multiLength;j++)
				{
					result[i+j]+=highNums[i]*multiNums[j];
					result[i+j+1]+=int(result[i+j]/radix); 
					result[i+j]%=radix;
				}
			}
			
			length = result.length;
			var lowLen:int = lowNums.length;
			for(i=0;i<length-1;i++)
			{
				if(i>=lowLen)
					lowNums[i] = 0;
				result[i] += lowNums[i];
				result[i+1] += int(result[i]/radix);
				result[i] %= radix;
			}
			
			var finalResult:Array = [];
			var found:Boolean = false;
			for(i=result.length;i>=0;i--)
			{
				if(!found)
				{
					if(!result[i])
						continue;
					else
						found = true;
				}
				finalResult.push(result[i].toString(radix));
			}
			cacheString[radix] = finalResult.join("");
			return cacheString[radix];
		}
		/**
		 * 从字符串读取数字列表，数字的低位在数组低位。
		 */		
		private function readNumberArray(str:String):Array
		{
			var numbers:Array = [];
			var num:Number;
			for(var i:int=str.length-1;i>=0;i--)
			{
				num = str.charCodeAt(i)-48;
				if(num>9)
					num -= 39;
				numbers.push(num);
			}
			return numbers;
		}
	}
}