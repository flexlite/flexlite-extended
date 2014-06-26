package org.flexlite.domUtils
{
	/**
	 * 字符串工具类
	 * @author dom
	 */	
	public class StringUtil
	{
		/**
		 * 去掉字符串两端所有连续的不可见字符。
		 * 注意：若目标字符串为null或不含有任何可见字符,将输出空字符串""。
		 * @param str 要格式化的字符串
		 */		
		public static  function trim(str:String):String
		{
			return trimLeft(trimRight(str));
		}
		/**
		 * 去除字符串左边所有连续的不可见字符。
		 * @param str 要格式化的字符串
		 */		
		public static function trimLeft(str:String):String
		{
			if(str==""||str==null)
				return "";
			var char:String = str.charAt(0);
			while(str.length>0&&
				(char==" "||char=="\t"||char=="\n"||char=="\r"||char=="\f"))
			{
				str = str.substr(1);
				char = str.charAt(0);
			}
			return str;
		}
		/**
		 * 去除字符串右边所有连续的不可见字符。
		 * @param str 要格式化的字符串
		 */
		public static function trimRight(str:String):String
		{
			if(str==""||str==null)
				return "";
			var char:String = str.charAt(str.length-1);
			while(str.length>0&&
				(char==" "||char=="\t"||char=="\n"||char=="\r"||char=="\f"))
			{
				str = str.substr(0,str.length-1);
				char = str.charAt(str.length-1);
			}
			return str;
		}
		
		/**
		 * 替换指定的字符串里所有的p为rep
		 */		
		public static function replaceStr(targetStr:String,p:String,rep:String):String
		{
			if(!targetStr)
				return "";
			var arr:Array = targetStr.split(p);
			return arr.join(rep);
		}
		/**
		 * 将颜色数字代码转换为字符串。
		 */		
		public static function toColorString(color:uint):String
		{
			var str:String = color.toString(16).toUpperCase();
			var num:int = 6-str.length;
			for(var i:int=0;i<num;i++)
			{
				str = "0"+str;
			}
			return "0x"+str;
		}
		/**
		 * 格式化文件长度为带单位的字符串
		 * @param length 文件长度,单位:字节。
		 * @param fractionDigits 要近似保留的小数位数,若为-1，则输出完整的大小。
		 */		
		public static function toSizeString(length:Number,fractionDigits:int=-1):String
		{
			var sizeStr:String = "";
			if(fractionDigits==-1)
			{
				if(length>1073741824)
				{
					sizeStr += int(length/1073741824).toString()+"GB";
					length = length%1073741824;
				}
				if(length>1048576)
				{
					if(sizeStr)
						sizeStr += ",";
					sizeStr += int(length/1048576).toString()+"MB";
					length = length%1048576;
				}
				if(length>1204)
				{
					if(sizeStr)
						sizeStr += ",";
					sizeStr += int(length/1204).toString()+"KB";
					length = length%1204;
				}
				if(length>0)
				{
					if(sizeStr)
						sizeStr += ",";
					sizeStr += length.toString()+"B";
				}
			}
			else
			{
				if(length>1073741824)
				{
					sizeStr = Number(length/1073741824).toFixed(fractionDigits)+"GB";
				}
				else if(length>1048576)
				{
					sizeStr = Number(length/1048576).toFixed(fractionDigits)+"MB";
				}
				else if(length>1204)
				{
					sizeStr = Number(length/1204).toFixed(fractionDigits)+"KB";
				}
				else
				{
					sizeStr = length.toString()+"B";
				}
			}
			return sizeStr;
		}
		
		private static var htmlEntities:Array = [["&","&amp;"],["<","&lt;"],[">","&gt;"],["\"","&quot;"],["'","&apos;"]];
		/**
		 * 转换为HTML实体字符
		 */		
		public static function escapeHTMLEntity(str:String):String
		{
			if(!str)
				return "";
			var list:Array = htmlEntities;
			for each(var arr:Array in list)
			{
				var key:String = arr[0];
				var value:String = arr[1];
				str = str.split(key).join(value);
			}
			return str;
		}
		/**
		 * 转换HTML实体字符为普通字符
		 */		
		public static function unescapeHTMLEntity(str:String):String
		{
			if(!str)
				return "";
			var list:Array = htmlEntities;
			for each(var arr:Array in list)
			{
				var key:String = arr[0];
				var value:String = arr[1];
				str = str.split(value).join(key);
			}
			return str;
		}
	}
}