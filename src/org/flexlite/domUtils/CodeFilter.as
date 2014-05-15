package org.flexlite.domUtils
{
	/**
	 * 过滤代码中的所有常量和注释内容的工具类
	 * @author DOM
	 */
	public class CodeFilter
	{
		/**
		 * 构造函数
		 */		
		public function CodeFilter()
		{
		}
		/**
		 * 占位符
		 */		
		public static const NBSP:String = "\a3\a";
		/**
		 * 注释行
		 */		
		private var commentLines:Array = [];
		/**
		 * 移除代码注释和字符串常量
		 */		
		public function removeComment(codeText:String):String
		{
			var trimText:String = "";
			codeText = codeText.split("\\\"").join("\a1\a");
			codeText = codeText.split("\\\'").join("\a2\a");
			var constArray:Array = [];
			while(codeText.length>0)
			{
				var quoteIndex:int = codeText.indexOf("\"");
				if(quoteIndex==-1)
					quoteIndex = int.MAX_VALUE;
				var squoteIndex:int = codeText.indexOf("'");
				if(squoteIndex==-1)
					squoteIndex = int.MAX_VALUE;
				var commentIndex:int = codeText.indexOf("/**");
				if(commentIndex==-1)
					commentIndex = int.MAX_VALUE;
				var lineCommonentIndex:int = codeText.indexOf("//");
				if(lineCommonentIndex==-1)
					lineCommonentIndex = int.MAX_VALUE;
				var index:int = Math.min(quoteIndex,squoteIndex,commentIndex,lineCommonentIndex);
				if(index==int.MAX_VALUE)
				{
					trimText += codeText;
					break;
				}
				trimText += codeText.substring(0,index)+NBSP;
				codeText = codeText.substring(index);
				switch(index)
				{
					case quoteIndex:
						codeText = codeText.substring(1);
						index = codeText.indexOf("\"");
						if(index==-1)
							index = codeText.length-1;
						constArray.push("\""+codeText.substring(0,index+1));
						codeText = codeText.substring(index+1);
						break;
					case squoteIndex:
						codeText = codeText.substring(1);
						index = codeText.indexOf("'");
						if(index==-1)
							index=codeText.length-1;
						constArray.push("'"+codeText.substring(0,index+1));
						codeText = codeText.substring(index+1);
						break;
					case commentIndex:
						index = codeText.indexOf("*/");
						if(index==-1)
							index=codeText.length-1;
						constArray.push(codeText.substring(0,index+2));
						codeText = codeText.substring(index+2);
						break;
					case lineCommonentIndex:
						index = codeText.indexOf("\n");
						if(index==-1)
							index=codeText.length-1;
						constArray.push(codeText.substring(0,index+1));
						codeText = codeText.substring(index+1);
						break;
				}
			}
			codeText = trimText.split("\a1\a").join("\\\"");
			codeText = codeText.split("\a2\a").join("\\\'");
			var length:int = constArray.length;
			for(var i:int=0;i<length;i++)
			{
				var constStr:String = constArray[i];
				constStr = constStr.split("\a1\a").join("\\\"");
				constStr = constStr.split("\a2\a").join("\\\'");
				constArray[i] = constStr;
			}
			commentLines = constArray;
			return codeText;
		}
		/**
		 *  删除整段字符后，同步删除对应包含的注释行。
		 */		
		public function updateCommentLines(preStr:String,removeStr:String):void
		{
			var preArr:Array = preStr.split(NBSP);
			var removeArr:Array = removeStr.split(NBSP);
			commentLines.splice(preArr.length-1,removeArr.length-1);
		}
		/**
		 * 更新缩进后，同步更新对应包含的注释行。
		 * @param preStr 发生改变字符串之前的字符串内容
		 * @param changeStr 发生改变的字符串
		 * @param numIndent 要添加或减少的缩进。整数表示添加，负数减少。
		 */			
		public function updateCommentIndent(preStr:String,changeStr:String,numIndent:int=1):void
		{
			var preArr:Array = preStr.split(NBSP);
			var removeArr:Array = changeStr.split(NBSP);
			var length:int = preArr.length-1+removeArr.length-1;
			for(var i:int=preArr.length-1;i<length;i++)
			{
				if(numIndent>0)
				{
					commentLines[i] = CodeUtil.addIndent(commentLines[i],numIndent,true);
				}
				else
				{
					commentLines[i] = CodeUtil.removeIndent(commentLines[i],-numIndent);
				}
			}
		}
		/**
		 * 回复注释行
		 */		
		public function recoveryComment(codeText:String):String
		{
			//还原注释和字符串常量
			var constArray:Array = this.commentLines;
			var strArr:Array = codeText.split(NBSP);
			codeText = strArr.shift();
			var length:int = strArr.length;
			for(var i:int=0;i<length;i++)
			{
				codeText += constArray[i]+strArr[i];
			}
			return codeText;
		}
	}
}