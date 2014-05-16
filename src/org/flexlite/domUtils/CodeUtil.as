package org.flexlite.domUtils
{
	
	/**
	 * 代码解析工具类
	 * @author DOM
	 */
	public class CodeUtil
	{
		/**
		 * 删除每行多余的缩进。
		 * @param codeText 要处理的代码字符串
		 * @param numIndent 每行要删除的缩进数量。默认删除一个\t或一个空白
		 */			
		public static function removeIndent(codeText:String,numIndent:int=1):String
		{
			var lines:Array = codeText.split("\n");
			for(var i:int=lines.length-1;i>=0;i--)
			{
				var line:String = lines[i];
				var count:int = numIndent;
				while(count>0)
				{
					var char:String = line.charAt(0);
					if(char=="\t")
					{
						line = line.substring(1);
					}
					else if(char==" ")
					{
						var index:int = 4;
						while(index>0)
						{
							if(line.charAt(0)==" ")
								line = line.substring(1);
							index--;
						}
						
					}
					count--;
				}
				lines[i] = line;
				
			}
			codeText = lines.join("\n");
			return codeText;
		}
		/**
		 * 每行增加相同数量缩进。
		 * @param codeText 要处理的代码字符串
		 * @param numIndent 要增加的缩进数量，使用\t字符
		 * @param ignoreFirstLine 是否忽略第一行，默认false。
		 */		
		public static function addIndent(codeText:String,numIndent:int=1,ignoreFirstLine:Boolean=false):String
		{
			var lines:Array = codeText.split("\n");
			for(var i:int=lines.length-1;i>=0;i--)
			{
				if(i==0&&ignoreFirstLine)
					continue;
				var line:String = lines[i];
				var count:int = numIndent;
				while(count>0)
				{
					line = "\t"+line;
					count--;
				}
				lines[i] = line;
			}
			codeText = lines.join("\n");
			return codeText;
		}
		
		/**
		 * 判断一个字符串是否为合法变量名,第一个字符为字母,下划线或$开头，第二个字符开始为字母,下划线，数字或$
		 */		
		public static function isVariableWord(word:String):Boolean
		{
			if(!word)
				return false;
			var char:String = word.charAt(0);
			if(!isVariableFirstChar(char))
			{
				return false;
			}
			var length:int = word.length;
			for(var i:int=1;i<length;i++)
			{
				char = word.charAt(i);
				if(!isVariableChar(char))
				{
					return false;
				}
			}
			return true;
		}
		/**
		 * 是否为合法变量字符,字符为字母,下划线，数字或$
		 */		
		public static function isVariableChar(char:String):Boolean
		{
			return (char<="Z"&&char>="A"||char<="z"&&char>="a"||
				char<="9"&&char>="0"||char=="_"||char=="$")
		}
		/**
		 * 是否为合法变量字符串的第一个字符,字符为字母,下划线或$
		 */		
		public static function isVariableFirstChar(char:String):Boolean
		{
			return (char<="Z"&&char>="A"||char<="z"&&char>="a"||
				char=="_"||char=="$")
		}
		
		/**
		 * 判断一段代码中是否含有某个变量字符串，且该字符串的前后都不是变量字符。
		 */		
		public static function containsVariable(key:String,codeText:String):Boolean
		{
			var contains:Boolean = false;
			while(codeText.length>0)
			{
				var index:int = codeText.indexOf(key);
				if(index==-1)
					break;
				var lastChar:String = codeText.charAt(index+key.length);
				var firstChar:String = codeText.charAt(index-1);
				if(!isVariableChar(firstChar)&&!isVariableChar(lastChar))
				{
					contains = true;
					break;
				}
				else
				{
					codeText = codeText.substring(index+key.length);
				}
			}
			return contains;
		}
		
		/**
		 * 获取第一个词,遇到空白字符或 \n \r \t 后停止。
		 */
		public static function getFirstWord(str:String):String
		{
			str = StringUtil.trimLeft(str);
			var index:int = str.indexOf(" ");
			if(index==-1)
				index = int.MAX_VALUE;
			var rIndex:int = str.indexOf("\r");
			if(rIndex==-1)
				rIndex = int.MAX_VALUE;
			var nIndex:int = str.indexOf("\n");
			if(nIndex==-1)
				nIndex = int.MAX_VALUE;
			var tIndex:int = str.indexOf("\t");
			if(tIndex==-1)
				tIndex = int.MAX_VALUE;
			index = Math.min(index,rIndex,nIndex,tIndex);
			str = str.substr(0,index);
			return StringUtil.trim(str);
		}
		/**
		 * 移除第一个词
		 * @param str 要处理的字符串
		 * @param word 要移除的词，若不传入则自动获取。
		 */		
		public static function removeFirstWord(str:String,word:String=""):String
		{
			if(!word)
			{
				word = getFirstWord(str);
			}
			var index:int = str.indexOf(word);
			if(index==-1)
				return str;
			return str.substring(index+word.length);
		}
		/**
		 * 获取最后一个词,遇到空白字符或 \n \r \t 后停止。
		 */
		public static function getLastWord(str:String):String
		{
			str = StringUtil.trimRight(str);
			var index:int = str.lastIndexOf(" ");
			var rIndex:int = str.lastIndexOf("\r");
			var nIndex:int = str.lastIndexOf("\n");
			var tIndex:int = str.indexOf("\t");
			index = Math.max(index,rIndex,nIndex,tIndex);
			str = str.substring(index+1);
			return StringUtil.trim(str);
		}
		/**
		 * 移除最后一个词
		 * @param str 要处理的字符串
		 * @param word 要移除的词，若不传入则自动获取。
		 */		
		public static function removeLastWord(str:String,word:String=""):String
		{
			if(!word)
			{
				word = getLastWord(str);
			}
			var index:int = str.lastIndexOf(word);
			if(index==-1)
				return str;
			return str.substring(0,index);
		}
		/**
		 * 获取字符串起始的第一个变量，返回的字符串两端均没有空白。若第一个非空白字符就不是合法变量字符，则返回空字符串。
		 */		
		public static function getFirstVariable(str:String):String
		{
			str = StringUtil.trimLeft(str);
			var word:String = "";
			var length:int = str.length;
			for(var i:int=0;i<length;i++)
			{
				var char:String = str.charAt(i);
				if(isVariableChar(char))
				{
					word += char;
				}
				else
				{
					break;
				}
			}
			return StringUtil.trim(word);
		}
		/**
		 * 移除第一个变量
		 * @param str 要处理的字符串
		 * @param word 要移除的变量，若不传入则自动获取。
		 */		
		public static function removeFirstVariable(str:String,word:String=""):String
		{
			if(!word)
			{
				word = getFirstVariable(str);
			}
			var index:int = str.indexOf(word);
			if(index==-1)
				return str;
			return str.substring(index+word.length);
		}
		/**
		 * 获取字符串末尾的最后一个变量,返回的字符串两端均没有空白。若最后一个非空白字符就不是合法变量字符，则返回空字符串。
		 */		
		public static function getLastVariable(str:String):String
		{
			str = StringUtil.trimRight(str);
			var word:String = "";
			for(var i:int=str.length-1;i>=0;i--)
			{
				var char:String = str.charAt(i);
				if(isVariableChar(char))
				{
					word = char+word;
				}
				else
				{
					break;
				}
			}
			return StringUtil.trim(word);
		}
		/**
		 * 移除最后一个变量
		 * @param str 要处理的字符串
		 * @param word 要移除的变量，若不传入则自动获取。
		 */		
		public static function removeLastVariable(str:String,word:String=""):String
		{
			if(!word)
			{
				word = getLastVariable(str);
			}
			var index:int = str.lastIndexOf(word);
			if(index==-1)
				return str;
			return str.substring(0,index);
		}
		/**
		 * 获取一对括号的结束点,例如"class A{ function B(){} } class",返回24
		 */		
		public static function getBracketEndIndex(codeText:String,left:String="{",right:String="}"):int
		{
			var indent:int = 0;
			var text:String = "";
			while(codeText.length>0)
			{
				var index:int = codeText.indexOf(left);
				if(index==-1)
					index = int.MAX_VALUE;
				var endIndex:int = codeText.indexOf(right);
				if(endIndex==-1)
					endIndex = int.MAX_VALUE;
				index = Math.min(index,endIndex);
				if(index==-1)
				{
					return -1;
				}
				text += codeText.substring(0,index+1);
				codeText = codeText.substring(index+1);
				if(index==endIndex)
					indent--;
				else
					indent++;
				if(indent==0)
				{
					break;
				}
			}
			return text.length-1;
		}
		/**
		 * 从后往前搜索，获取一对括号的起始点,例如"class A{ function B(){} } class",返回7
		 */		
		public static function getBracketStartIndex(codeText:String,left:String="{",right:String="}"):int
		{
			var indent:int = 0;
			while(codeText.length>0)
			{
				var index:int = codeText.lastIndexOf(left);
				var endIndex:int = codeText.lastIndexOf(right);
				index = Math.max(index,endIndex);
				if(index==-1)
				{
					return -1;
				}
				codeText = codeText.substring(0,index);
				if(index==endIndex)
					indent++;
				else
					indent--;
				if(indent==0)
				{
					break;
				}
			}
			return codeText.length;
		}
	}
}