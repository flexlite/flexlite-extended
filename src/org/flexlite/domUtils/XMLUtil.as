package org.flexlite.domUtils
{
	
	/**
	 * XML工具类
	 * @author DOM
	 */
	public class XMLUtil
	{
		/**
		 * 获取node在xmlStr中的对应文本区域的起始和结束索引
		 * @param xmlStr xml的文本
		 * @param node 要定位的xml子节点
		 * @return 一个数组，[起始索引,子项起始索引,子项结束索引,结束索引]
		 */		
		public static function getIndexOfXMLString(xmlStr:String,node:XML):Array
		{
			if(!node)
				return null;
			try
			{
				new XML(xmlStr);
			}
			catch(e:Error)
			{
				return null;
			}
			var path:Array = [];
			while(node)
			{
				var index:int = node.childIndex();
				path.splice(0,0,index==-1?0:index);
				node = node.parent();
			}
			return findRangeByPath(xmlStr,path);
		}
		
		/**
		 * 根据xml路径返回指定节点在xmlStr中的起始结束索引
		 */			
		private static function findRangeByPath(xmlStr:String,path:Array):Array
		{
			var index:int;
			var subLength:int = 0;
			var closed:Boolean = true;
			var nodeText:String = "";
			var openNum:int = 0;
			var startIndex:int = -1;
			var childStartIndex:int = -1;
			var childEndIndex:int = -1;
			var endIndex:int = -1;
			while(xmlStr.length>0)
			{
				if(closed)
				{
					index = xmlStr.indexOf("<");
					if(index==-1)
						break;
					xmlStr = xmlStr.substring(index);
					subLength += index;
					closed = false;
				}
				else
				{
					var isNote:Boolean = false;
					if(xmlStr.substr(0,4)=="<!--")
					{
						index = xmlStr.indexOf("-->")+2;
						isNote = true;
					}
					else
						index = xmlStr.indexOf(">");
					nodeText = xmlStr.substring(0,index+1);
					xmlStr = xmlStr.substring(index+1);
					subLength += index+1;
					closed = true;
					if(nodeText.charAt(1)=="?"||isNote)
						continue;
					var type:int = getNodeType(nodeText);
					switch(type)
					{
						case 1:
							if(path.length>0&&openNum==0)
							{
								path[0]--;
								if(path[0]==-1)
								{
									path.splice(0);
								}
							}
							break;
						case 2:
							openNum++;
							if(path.length>0&&path[0]==0)
							{
								path.splice(0,1);
								openNum = 0;
							}
							break;
						case 3:
							openNum--;
							if(path.length>0&&openNum==0)
							{
								path[0]--;
							}
							break;
					}
					if(path.length==0)
					{
						if(startIndex==-1)
						{
							startIndex = subLength-nodeText.length;
							childStartIndex = subLength;
							if(type==1)
							{
								endIndex = childEndIndex = subLength;
								break;
							}
						}
						else if(openNum==-1)
						{
							childEndIndex = subLength-nodeText.length;
							endIndex = subLength;
							break;
						}
					}
				}
			}
			
			return [startIndex,childStartIndex,childEndIndex,endIndex];
		}
		
		/**
		 * 返回一个节点的类型，1:完整节点,2:开启节点,3:闭合节点,4:注释节点
		 */		
		private static function getNodeType(node:String):int
		{
			if(node.charAt(node.length-2)=="/")
				return 1;
			if(node.charAt(1)=="/")
				return 3;
			return 2;
		}
	}
}