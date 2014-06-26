package org.flexlite.domUtils.loader
{
	import flash.system.Capabilities;
	import flash.utils.getDefinitionByName;

	[ExcludeClass]
	/**
	 * 在Mac下加载本地文件时，转换路径为url的工具类。
	 * @author dom
	 */
	public class PathHelper
	{
		
		private static var checked:Boolean = false;
		private static var needConvert:Boolean = false;
		private static var FileClass:Class;
		/**
		 * 转换Mac路径为url
		 * @param path 要检查的路径。
		 */		
		public static function path2Url(path:String):String
		{
			if(!checked)
				checkEnvironment();
			if(!needConvert||!path||path.charAt(0)!="/")
				return path;
			path = path.split("\\").join("/");
			var file:Object = FileClass.applicationDirectory.resolvePath(path.substring(1));
			if(file.exists)
			{
				return path;
			}
			return "file://"+path;
		}
		
		private static function checkEnvironment():void
		{
			checked = true;
			if(Capabilities.playerType!="Desktop"||
				Capabilities.os.indexOf("Windows")!=-1)
				return;
			try
			{
				FileClass = getDefinitionByName("flash.filesystem.File") as Class;
			}
			catch(e:Error)
			{}
			if(!FileClass)
				return;
			needConvert = true;
		}
	}
}
