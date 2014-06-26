package org.flexlite.domUtils
{
	import air.update.ApplicationUpdaterUI;
	
	import flash.desktop.Updater;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	/**
	 * 即将执行更新，重启程序。调用event.preventDefault()可以阻止立即重启，稍后调用
	 */	
	[Event(name="updating", type="flash.events.Event")]
	/**
	 * AIR自动更新工具类
	 * @author dom
	 */
	public class AutoUpdater extends EventDispatcher
	{
		/**
		 * 构造函数
		 */		
		public function AutoUpdater()
		{
			super();
		}
		
		//	服务器update.xml配置文件格式示例：
		//	<config>
		//		<version>1.1.1</version><!--此版本号必须与air文件的真实版本号完全一致-->
		//		<app>http://update.domlib.com/As2TsTool/As2TsTool.air</app>
		//	</config>
		
		/**
		 * 开始检查更新
		 * @param serverUrl 服务器上update.xml配置文件的地址
		 * </config>
		 */		
		public function checkUpdate(serverUrl:String):void
		{
			DomLoader.loadXML(serverUrl,onConfigComp);
		}
		/**
		 * 当前是否可以执行updateNow()。
		 */		
		public function get canUpdate():Boolean
		{
			return Boolean(this.appBytes);
		}
		/**
		 * 立即重启并更新已经下载的新版程序。
		 */		
		public function updateNow():void
		{
			if(!this.appBytes)
				return;
			try
			{
				var appFile:File = File.applicationStorageDirectory.resolvePath("tempApp.air");
				FileUtil.save(appFile.nativePath,this.appBytes);
				var updater:Updater = new Updater();
				updater.update(appFile,remoteVersion);
			}
			catch(e:Error)
			{
			}
		}
		/**
		 * 远程服务器上air文件的版本号
		 */		
		private var remoteVersion:String = "";
		/**
		 * 服务器配置加载完成
		 */		
		private function onConfigComp(xml:XML):void
		{
			if(!xml)
				return;
			var app:String = "";
			if(xml.hasOwnProperty("version"))
			{
				remoteVersion = xml.version[0].toString();
			}
			if(xml.hasOwnProperty("app"))
			{
				app = xml.app[0].toString();
			}
			if(!remoteVersion||!app)
				return;
			var update:ApplicationUpdaterUI = new ApplicationUpdaterUI();
			var shouldUpdate:Boolean = compareVersion(update.currentVersion,remoteVersion);
			if(!shouldUpdate)
				return;
			DomLoader.loadByteArray(app,onBytesComp);
		}
		
		private var appBytes:ByteArray;
		/**
		 * air文件下载完成
		 */		
		private function onBytesComp(data:ByteArray):void
		{
			this.appBytes = data;
			var event:Event = new Event("updating",false,true);
			if(dispatchEvent(event))
			{
				updateNow();
			}
		}
		
		/**
		 * 返回vA是否小于vB
		 */		
		private function compareVersion(versionA:String,versionB:String):Boolean
		{
			var lessThan:Boolean = false;
			var index:int=0;
			var vAs:Array = versionA.split(".");
			var vBs:Array = versionB.split(".");
			for each(var vB:String in vBs)
			{
				var vA:String = vAs[index]?vAs[index]:"0";
				if(int(vB)>int(vA))
				{
					lessThan = true;
					break;
				}
				else if(int(vB)<int(vA))
				{
					break;
				}
				index++;
			}
			return lessThan;
		}
	}
}