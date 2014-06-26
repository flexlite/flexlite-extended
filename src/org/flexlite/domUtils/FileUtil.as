package org.flexlite.domUtils
{
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	/**
	 * 常用文件操作方法工具类
	 * @author dom
	 */
	public class FileUtil
	{
		/**
		 * 保存数据到指定文件，返回是否保存成功
		 * @param path 文件完整路径名
		 * @param data 要保存的数据
		 */		
		public static function save(path:String,data:Object):Boolean
		{
			path = escapePath(path);
			var file:File = new File(File.applicationDirectory.resolvePath(path).nativePath);
			if(file.exists)
			{//如果存在，先删除，防止出现文件名大小写不能覆盖的问题
				deletePath(file.nativePath);
			}
			if(file.isDirectory)
				return false;
			var fs:FileStream = new FileStream;
			try
			{
				fs.open(file,FileMode.WRITE);
				if(data is ByteArray)
				{
					fs.writeBytes(data as ByteArray);
				}
				else if(data is String)
				{
					fs.writeUTFBytes(data as String);
				}
				else
				{
					fs.writeObject(data);
				}
			}
			catch(e:Error)
			{
				fs.close();
				return false;
			}
			fs.close();
			return true;
		}
		
		/**
		 * 打开文件的简便方法,返回打开的FileStream对象，若打开失败，返回null。
		 * @param path 要打开的文件路径
		 */		
		public static function open(path:String):FileStream
		{
			path = escapePath(path);
			var file:File = new File(File.applicationDirectory.resolvePath(path).nativePath);
			var fs:FileStream = new FileStream;
			try
			{
				fs.open(file,FileMode.READ);
			}
			catch(e:Error)
			{
				return null;
			}
			return fs;
		}
		/**
		 * 打开文件字节流的简便方法,返回打开的字节流数据，若失败，返回null.
		 * @param path 要打开的文件路径
		 */
		public static function openAsByteArray(path:String):ByteArray
		{
			path = escapePath(path);
			var fs:FileStream = open(path);
			if(!fs)
				return null;
			fs.position = 0;
			var bytes:ByteArray = new ByteArray();
			fs.readBytes(bytes);
			fs.close();
			return bytes;
		}
		/**
		 * 打开文本文件的简便方法,返回打开文本的内容，若失败，返回"".
		 * @param path 要打开的文件路径
		 */	
		public static function openAsString(path:String):String
		{
			path = escapePath(path);
			var fs:FileStream = open(path);
			if(!fs)
				return "";
			fs.position = 0;
			var content:String = fs.readUTFBytes(fs.bytesAvailable);
			fs.close();
			return content;
		}
		
		/**
		 * 打开浏览文件对话框
		 * @param onSelect 回调函数：单个文件或单个目录：onSelect(file:File);多个文件：onSelect(fileList:Array)
		 * @param type 浏览类型：1：选择单个文件，2：选择多个文件，3：选择目录 
		 * @param typeFilter 文件类型过滤数组
		 * @param title 对话框标题
		 * @param defaultPath 默认路径
		 */		
		public static function browseForOpen(onSelect:Function,type:int=1,typeFilter:Array=null,title:String="浏览文件",defaultPath:String=""):void
		{
			defaultPath = escapePath(defaultPath);
			var file:File;
			if(defaultPath=="")
				file = new File;
			else
				file = File.applicationDirectory.resolvePath(defaultPath);
			switch(type)
			{
				case 1:
					file.addEventListener(Event.SELECT,function(e:Event):void{
						onSelect(e.target as File);
					});
					file.browseForOpen(title,typeFilter);
					break;
				case 2:
					file.addEventListener(FileListEvent.SELECT_MULTIPLE,function(e:FileListEvent):void{
						onSelect(e.files);
					});
					file.browseForOpenMultiple(title,typeFilter);
					break;
				case 3:
					file.addEventListener(Event.SELECT,function(e:Event):void{
						onSelect(e.target as File);
					});
					file.browseForDirectory(title);
					break;
			}
		}
		
		/**
		 * 打开保存文件对话框,选择要保存的路径。要同时保存数据请使用browsewAndSave()方法。
		 * @param onSelect 回调函数：onSelect(file:File)
		 * @param defaultPath 默认路径
		 * @param title 对话框标题
		 */		
		public static function browseForSave(onSelect:Function,defaultPath:String=null,title:String="保存文件"):void
		{
			defaultPath = escapePath(defaultPath);
			var file:File
			if(defaultPath!=null)
				file = File.applicationDirectory.resolvePath(defaultPath);
			else
				file = new File;
			file.addEventListener(Event.SELECT,function(e:Event):void{
				onSelect(e.target as File);
			});
			file.browseForSave(title);
		}
		
		/**
		 * 打开保存文件对话框，并保存数据。
		 * @param data
		 * @param onSelect 回调函数：onSelect(file:File)
		 * @param title 对话框标题
		 */		
		public static function browseAndSave(data:Object,defaultPath:String=null,title:String="保存文件"):void
		{
			defaultPath = escapePath(defaultPath);
			var file:File
			if(defaultPath!=null)
				file = File.applicationDirectory.resolvePath(defaultPath);
			else
				file = new File;
			file.addEventListener(Event.SELECT,function(e:Event):void{
				save(file.nativePath,data);
			});
			file.browseForSave(title);
		}
		
		/**
		 * 移动文件或目录,返回是否移动成功
		 * @param source 文件源路径
		 * @param dest 文件要移动到的目标路径
		 * @param overwrite 是否覆盖同名文件
		 */		
		public static function moveTo(source:String,dest:String,overwrite:Boolean=false):Boolean
		{
			source = escapePath(source);
			dest = escapePath(dest);
			if(source==dest)
				return true;
			var file:File = new File(File.applicationDirectory.resolvePath(source).nativePath);
			//必须创建绝对位置的File才能移动成功。
			var destFile:File = new File(File.applicationDirectory.resolvePath(dest).nativePath);
			if(destFile.exists)
				deletePath(destFile.nativePath);
			try
			{
				file.moveTo(destFile,overwrite);
			}
			catch(e:Error)
			{
				return false;
			}
			return true;
		}
		
		/**
		 * 复制文件或目录,返回是否复制成功
		 * @param source 文件源路径
		 * @param dest 文件要移动到的目标路径
		 * @param overwrite 是否覆盖同名文件
		 */	
		public static function copyTo(source:String,dest:String,overwrite:Boolean=false):Boolean
		{
			source = escapePath(source);
			dest = escapePath(dest);
			if(source==dest)
				return true;
			var file:File = File.applicationDirectory.resolvePath(source);
			//必须创建绝对位置的File才能移动成功。
			var destFile:File = new File(File.applicationDirectory.resolvePath(dest).nativePath);
			if(destFile.exists)
				deletePath(destFile.nativePath);
			try
			{
				file.copyTo(destFile,overwrite);
			}
			catch(e:Error)
			{
				return false;
			}
			return true;
		}
		
		/**
		 * 删除文件或目录，返回是否删除成功
		 * @param path 要删除的文件源路径
		 * @param moveToTrash 是否只是移动到回收站，默认false，直接删除。
		 */		
		public static function deletePath(path:String,moveToTrash:Boolean = false):Boolean
		{
			path = escapePath(path);
			var file:File = new File(File.applicationDirectory.resolvePath(path).nativePath);
			if(moveToTrash)
			{
				try
				{
					file.moveToTrash();
				}
				catch(e:Error)
				{
					return false;
				}
			}
			else
			{
				if(file.isDirectory)
				{
					try
					{
						file.deleteDirectory(true);
					}
					catch(e:Error)
					{
						return false;
					}
				}
				else
				{
					try
					{
						file.deleteFile();
					}
					catch(e:Error)
					{
						return false;
					}
				}
			}
			return true;
		}
		
		/**
		 * 返回指定文件的父级文件夹路径,返回字符串的结尾已包含分隔符。
		 */		
		public static function getDirectory(path:String):String
		{
			path = escapeUrl(path);
			var endIndex:int = path.lastIndexOf("/");
			if(endIndex==-1)
			{
				return "";
			}
			return path.substr(0,endIndex+1);
		}
		/**
		 * 获得路径的扩展名
		 */		
		public static function getExtension(path:String):String
		{
			path = escapeUrl(path);
			var index:int = path.lastIndexOf(".");
			if(index==-1)
				return "";
			var i:int = path.lastIndexOf("/");
			if(i>index)
				return "";
			return path.substring(index+1);
		}
		/**
		 * 获取路径的文件名(不含扩展名)或文件夹名
		 */		
		public static function getFileName(path:String):String
		{
			if(path==null||path=="")
				return "";
			path = escapeUrl(path);
			var startIndex:int = path.lastIndexOf("/");
			var endIndex:int;
			if(startIndex>0&&startIndex==path.length-1)
			{
				path = path.substring(0,path.length-1);
				startIndex = path.lastIndexOf("/");
				endIndex = path.length;
				return path.substring(startIndex+1,endIndex);
			}
			endIndex = path.lastIndexOf(".");
			if(endIndex==-1)
				endIndex = path.length;
			return path.substring(startIndex+1,endIndex);
		}
		
		/**
		 * 搜索指定文件夹及其子文件夹下所有的文件 
		 * @param dir 要搜索的文件夹
		 * @param extension 要搜索的文件扩展名，例如："png"。不设置表示获取所有类型文件。注意：若设置了filterFunc，则忽略此参数。
		 * @param filterFunc 过滤函数：filterFunc(file:File):Boolean,参数为遍历过程中的每一个文件夹或文件，返回true则加入结果列表或继续向下查找。
		 * @return File对象列表
		 */		
		public static function search(dir:String,extension:String=null,filterFunc:Function=null):Array
		{
			dir = escapePath(dir);
			var file:File = File.applicationDirectory.resolvePath(dir);
			var result:Array = [];
			if(!file.isDirectory)
				return result;
			extension = extension?extension.toLowerCase():"";
			findFiles(file,result,extension,filterFunc);
			return result;
		}
		/**
		 * 递归搜索文件
		 */		
		private static function findFiles(dir:File,result:Array,
										  extension:String=null,filterFunc:Function=null):void
		{
			var fileList:Array = dir.getDirectoryListing();
			for each(var file:File in fileList)
			{
				if(file.isDirectory)
				{
					if(filterFunc!=null)
					{
						if(filterFunc(file))
						{
							findFiles(file,result,extension,filterFunc);
						}
					}
					else
					{
						findFiles(file,result,extension,filterFunc);
					}
				}
				else if(filterFunc!=null)
				{
					if(filterFunc(file))
					{
						result.push(file);
					}
				}
				else if(extension)
				{
					if(file.extension&&file.extension.toLowerCase() == extension)
					{
						result.push(file);
					}
				}
				else
				{
					result.push(file);
				}
			}
		}
		
		/**
		 * 将url转换为本地路径
		 */		
		public static function url2Path(url:String):String
		{
			url = escapePath(url);
			var file:File = File.applicationDirectory.resolvePath(url);
			return escapeUrl(file.nativePath);
		}
		/**
		 * 将本地路径转换为url
		 */		
		public static function path2Url(path:String):String
		{
			path = escapePath(path);
			return File.applicationDirectory.resolvePath(path).url;
		}
		/**
		 * 指定路径的文件或文件夹是否存在
		 */		
		public static function exists(path:String):Boolean
		{
			path = escapePath(path);
			var file:File = File.applicationDirectory.resolvePath(path);
			return file.exists;
		}
		/**
		 * 转换本机路径或url为Unix风格路径。
		 */		
		public static function escapePath(path:String):String
		{
			if(!path)
				return "";
			if(path.indexOf("file:")==0)
			{
				try
				{
					var file:File = new File();
					file.url = path;
					path = file.nativePath;
				}
				catch(e:Error)
				{
				}
			}
			path = path.split("\\").join("/");
			return path;
		}
		/**
		 * 转换url中的反斜杠为斜杠
		 */
		public static function escapeUrl(url:String):String
		{
			return Boolean(!url)?"":url.split("\\").join("/");
		}
	}
}