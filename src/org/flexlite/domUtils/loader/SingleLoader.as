package org.flexlite.domUtils.loader
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;

	/**
	 * 对单个Loader类加载过程的封装
	 * @author DOM
	 */	
	public class SingleLoader
	{
		private var loader:Loader;
		public function SingleLoader()
		{
		}		
		
		private var format:int;
		private static const FORMAT_LOADER:int = 0;
		private static const FORMAT_BITMAP:int = 1;
		private static const FORMAT_BITMAP_DATA:int= 2;
		private static const FORMAT_EXTERNAL_CLASS:int= 3;
		private static const FORMAT_EXTERNAL_CLASSES:int = 4;
		
		private var className:String = "";
		
		private var appDomain:ApplicationDomain;
		/**
		 * 根据url获取指定文件的Loader显示对象
		 * @param url 文件的url路径
		 * @param onComp 返回结果时的回调函数 onComp(data:Loader)
		 * @param onProgress 加载进度回调函数 onProgress(event:ProgressEvent)
		 * @param onIoError 加载失败回调函数 onIoError(event:IOErrorEvent)
		 * @param appDomain 加载使用的程序域
		 */		
		public function loadLoader(url:String,onComp:Function,onProgress:Function=null,onIoError:Function=null,appDomain:ApplicationDomain=null):void
		{
			format = FORMAT_LOADER;
			this.appDomain = appDomain;
			load(url,onComp,onProgress,onIoError);
		}
		/**
		 * 根据url获取指定文件的Bitmap显示对象
		 * @param url 文件的url路径
		 * @param onComp 返回结果时的回调函数 onComp(data:Bitmap)
		 * @param onProgress 加载进度回调函数 onProgress(event:ProgressEvent)
		 * @param onIoError 加载失败回调函数 onIoError(event:IOErrorEvent)
		 */		
		public function loadBitmap(url:String,onComp:Function,onProgress:Function=null,onIoError:Function=null):void
		{
			format = FORMAT_BITMAP;
			load(url,onComp,onProgress,onIoError);
		}
		/**
		 * 根据url获取指定文件的BitmapData数据
		 * @param url 文件的url路径
		 * @param onComp 返回结果时的回调函数 onComp(data:BitmapData)
		 * @param onProgress 加载进度回调函数 onProgress(event:ProgressEvent)
		 * @param onIoError 加载失败回调函数 onIoError(event:IOErrorEvent)
		 */		
		public function loadBitmapData(url:String,onComp:Function,onProgress:Function=null,onIoError:Function=null):void
		{
			format = FORMAT_BITMAP_DATA;
			load(url,onComp,onProgress,onIoError);
		}
		
		/**
		 * 根据url获取指定文件的Class类定义数据
		 * @param url 文件的url路径
		 * @param className 要获取的类名
		 * @param onComp 返回结果时的回调函数 onComp(data:Class)
		 * @param onProgress 加载进度回调函数 onProgress(event:ProgressEvent)
		 * @param onIoError 加载失败回调函数 onIoError(event:IOErrorEvent)
		 * @param appDomain 加载使用的程序域
		 */	
		public function loadExternalClass(url:String,className:String,onComp:Function,onProgress:Function=null,onIoError:Function=null,appDomain:ApplicationDomain=null):void
		{
			format = FORMAT_EXTERNAL_CLASS;
			this.appDomain = appDomain;
			this.className = className;
			load(url,onComp,onProgress,onIoError);
		}
		
		/**
		 * 根据url获取指定文件的所有Class类定义和键名数据
		 * @param url 文件的url路径
		 * @param onComp 返回结果时的回调函数 onComp(clslist:Array, keylist:Array)
		 * @param onProgress 加载进度回调函数 onProgress(event:ProgressEvent)
		 * @param onIoError 加载失败回调函数 onIoError(event:IOErrorEvent)
		 * @param appDomain 加载使用的程序域
		 */	
		public function loadExternalClasses(url:String,onComp:Function,onProgress:Function=null,onIoError:Function=null,appDomain:ApplicationDomain=null):void
		{
			format = FORMAT_EXTERNAL_CLASSES;
			this.appDomain = appDomain;
			load(url,onComp,onProgress,onIoError);
		}
		
		private function load(url:String,compFunc:Function,progressFunc:Function=null,ioErrorFunc:Function=null):void
		{
			if(loader == null)
			{
				loader = new Loader();
			}
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onComp);
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,onProgress);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,ioError);
			this.compFunc = compFunc;
			this.progressFunc = progressFunc;
			this.ioErrorFunc = ioErrorFunc;
			if(appDomain)
			{
				var ldc:LoaderContext = new LoaderContext(false,appDomain);
				appDomain = null;
				loader.load(new URLRequest(url),ldc);
			}
			else
			{
				loader.load(new URLRequest(url));
			}
		}
		/**
		 * 从字节流加载Loader显示对象
		 * @param bytes 文件的字节流对象
		 * @param compFunc 返回结果时的回调函数 onComp(data:Loader)
		 * @param progressFunc 加载进度回调函数 onProgress(event:ProgressEvent)
		 * @param ioErrorFunc 加载失败回调函数 onIoError(event:IOErrorEvent)
		 * @param appDomain 加载使用的程序域
		 */			
		public function loadLoaderFromBytes(bytes:ByteArray,compFunc:Function,progressFunc:Function=null,ioErrorFunc:Function=null,appDomain:ApplicationDomain=null):void
		{
			if(loader == null)
			{
				loader = new Loader();
			}
			format = FORMAT_LOADER;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onComp);
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,onProgress);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,ioError);
			this.compFunc = compFunc;
			this.progressFunc = progressFunc;
			this.ioErrorFunc = ioErrorFunc;
			var ldc:LoaderContext;
			if(appDomain)
			{
				ldc = new LoaderContext(false,appDomain);
				
			}
			else
			{
				ldc = new LoaderContext();
			}
			ldc.allowCodeImport = true;
			loader.loadBytes(bytes,ldc);
		}
		
		/**
		 * 加载完成回调函数 
		 */		
		private var compFunc:Function;
		/**
		 * 加载完成
		 */		
		private function onComp(e:Event):void
		{
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,onComp);
			loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS,onProgress);
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,ioError);
			if(compFunc!=null)
			{
				switch(format)
				{
					case FORMAT_LOADER:
						compFunc(loader);
						loader = null;
						break;
					case FORMAT_BITMAP:
						var bm:Bitmap = loader.contentLoaderInfo.content as Bitmap;
						compFunc(bm);
						loader.unload();
						break;
					case FORMAT_BITMAP_DATA:
						var bm2:Bitmap = loader.contentLoaderInfo.content as Bitmap;
						var bd:BitmapData;
						if(bm2!=null)
						{
							bd = bm2.bitmapData;
						}
						compFunc(bd);
						loader.unload();
						break;
					case FORMAT_EXTERNAL_CLASS:
						var appDomain:ApplicationDomain = loader.contentLoaderInfo.applicationDomain;
						var classData:Class;
						if(appDomain.hasDefinition(className))
						{
							classData = appDomain.getDefinition(className) as Class;
						}
						compFunc(classData);
						loader.unload();
						break;
					case FORMAT_EXTERNAL_CLASSES:
						var classList:Array = [];
						var keyList:Array = [];
						var tmpAppDomain:ApplicationDomain = loader.contentLoaderInfo.applicationDomain;
						var linkNameList:Vector.<String> = tmpAppDomain.getQualifiedDefinitionNames();
						for each(var linkname:String in linkNameList)
						{
							if (linkname.indexOf("_fla::") < 0 && linkname.indexOf(".") < 0)
								keyList.push(linkname);
						}
						var tmpClassData:Class;
						for each (var linkName:String in linkNameList)
						{
							if(tmpAppDomain.hasDefinition(linkName))
							{
								tmpClassData = tmpAppDomain.getDefinition(linkName) as Class;
								classList.push(tmpClassData);
							}
						}
						compFunc(classList, keyList);
						loader.unload();
						break;
					default:;
				}
				
			}
		}
		
		/**
		 * 进度条回调函数 
		 */		
		private var progressFunc:Function;
		/**
		 * 加载进度
		 */		
		private function onProgress(event:ProgressEvent):void
		{
			if(progressFunc!=null)
				progressFunc(event);
		}
		/**
		 * 加载失败回调函数 
		 */		
		private var ioErrorFunc:Function;
		/**
		 * 加载失败
		 */		
		private function ioError(event:IOErrorEvent):void
		{
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE,onComp);
			loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS,onProgress);
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,ioError);
			if(ioErrorFunc!=null)
			{
				ioErrorFunc(event);
			}
		}
	}
}