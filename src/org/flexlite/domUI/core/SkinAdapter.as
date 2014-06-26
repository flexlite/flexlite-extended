package org.flexlite.domUI.core
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import org.flexlite.domDisplay.DxrBitmap;
	import org.flexlite.domDisplay.DxrData;
	import org.flexlite.domDisplay.DxrMovieClip;
	import org.flexlite.domDisplay.DxrShape;
	import org.flexlite.domDisplay.IDxrDisplay;
	import org.flexlite.domDll.Dll;
	import org.flexlite.domUI.core.ISkinAdapter;
	
	
	/**
	 * 皮肤适配器示例
	 * @author dom
	 */
	public class SkinAdapter implements ISkinAdapter
	{
		/**
		 * 构造函数
		 */		
		public function SkinAdapter()
		{
		}
		
		/**
		 * @inheritDoc
		 */		
		public function getSkin(skinName:Object, compFunc:Function, oldSkin:DisplayObject=null):void
		{
			var dp:Object;
			if(skinName is Class)
			{
				dp = new skinName();
				if( dp is BitmapData )
				{
					dp = new Bitmap(dp as BitmapData,"auto",true);
				}
				compFunc(dp,skinName);
			}
			else if(skinName is String)
			{
				Dll.getResAsync(skinName as String,onParseStringComp,{skinName:skinName, compFunc:compFunc, oldSkin:oldSkin});
			}
			else if(skinName is ByteArray)
			{
				var loader:Loader = new Loader;
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,function(event:Event):void{
					compFunc(skinName,skinName);
				});
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(event:Event):void{
					if(loader.content is Bitmap)
					{
						var bitmapData:BitmapData = (loader.content as Bitmap).bitmapData;
						compFunc(new Bitmap(bitmapData,"auto",true),skinName);
					}
					else
					{
						compFunc(loader.content,skinName);
					}
				});
				loader.loadBytes(skinName as ByteArray);
			}
			else if(skinName is BitmapData)
			{
				var skin:Bitmap;
				if(oldSkin is Bitmap)
				{
					skin = oldSkin as Bitmap;
					skin.bitmapData = skinName as BitmapData;
				}
				else
				{
					skin = new Bitmap(skinName as BitmapData,"auto",true);
				}
				compFunc(skin,skinName);
			}
			else if(skinName is DxrData)
			{
				parseDxrData(skinName as DxrData,skinName, compFunc, oldSkin);
			}
			else
			{
				compFunc(skinName,skinName);
			}
		}
		
		/**
		 * 解析字符串
		 */		
		private function onParseStringComp(data:*,other:Object):void
		{
			var skinName:Object = other.skinName;
			var compFunc:Function = other.compFunc;
			var oldSkin:DisplayObject = other.oldSkin;
			if(data==null)
			{
				trace("素材加载失败："+skinName);
				compFunc(skinName,skinName);
			}
			else if(data is DxrData)
			{
				parseDxrData(data,skinName, compFunc, oldSkin);
			}	
			else if(data is BitmapData)
			{
				var skin:Bitmap;
				if(oldSkin is Bitmap)
				{
					skin = oldSkin as Bitmap;
					skin.bitmapData = data as BitmapData;
				}
				else
				{
					skin = new Bitmap(data as BitmapData,"auto",true);
				}
				compFunc(skin,skinName);
			}
			else if(data is Class)
			{
				var dp:Object = new data();
				if( dp is BitmapData )
				{
					dp = new Bitmap(dp as BitmapData,"auto",true);
				}
				compFunc(dp,skinName);
			}
			else
			{
				compFunc(data,skinName);
			}
		}
		
		/**
		 * 解析DxrData
		 */		
		private function parseDxrData(data:DxrData,skinName:Object, compFunc:Function, oldSkin:DisplayObject):void
		{
			var dxrDisplay:IDxrDisplay;
			if(data.totalFrames>1)
			{
				dxrDisplay = oldSkin is DxrMovieClip?(oldSkin as DxrMovieClip):new DxrMovieClip();
			}
			else if(data.scale9Grid)
			{
				dxrDisplay = oldSkin is DxrShape?(oldSkin as DxrShape):new DxrShape();
			}
			else
			{
				dxrDisplay = oldSkin is DxrBitmap?(oldSkin as DxrBitmap):new DxrBitmap();
				var offset:Point = data.getFrameOffset(0);
				(dxrDisplay as DxrBitmap).x = offset.x;
				(dxrDisplay as DxrBitmap).y = offset.y;
			}
			dxrDisplay.dxrData = data;
			compFunc(dxrDisplay,skinName);
		}
	}
}