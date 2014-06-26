package org.flexlite.domDisplay.codec
{
	import com.codeazur.as3swf.utils.ObjCUtils;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import org.flexlite.domCore.Injector;
	import org.flexlite.domCore.dx_internal;
	import org.flexlite.domDisplay.DxrData;
	import org.flexlite.domDisplay.image.Jpeg32Encoder;
	import org.flexlite.domDisplay.image.JpegXREncoder;
	import org.flexlite.domDisplay.image.PngEncoder;
	import org.flexlite.domUtils.CRC32Util;
	
	use namespace dx_internal;

	/**
	 * DXR动画编码器
	 * 注意：在AIR里，影片剪辑若不在显示列表，切换帧时会有残影的bug，转换前请先将MC都加到显示列表里。FP里没有这个问题。
	 * @author dom
	 */	
	public class DxrEncoder extends DxrDrawer
	{
		/**
		 * 构造函数
		 */		
		public function DxrEncoder()
		{
			if(!injected)
			{
				injected = true;
				doInject();
			}
		}
		
		private static var injected:Boolean = false;
		/**
		 * 执行位图解码器注入
		 */		
		private static function doInject():void
		{
			if(!Injector.hasMapRule(IBitmapEncoder,"png"))
				Injector.mapClass(IBitmapEncoder,PngEncoder,"png");
			if(!Injector.hasMapRule(IBitmapEncoder,"jpegxr"))
				Injector.mapClass(IBitmapEncoder,JpegXREncoder,"jpegxr");
			if(!Injector.hasMapRule(IBitmapEncoder,"jpeg32"))
				Injector.mapClass(IBitmapEncoder,Jpeg32Encoder,"jpeg32");
		}
		/**
		 * 默认位图编解码器标识符
		 */		
		public static const DEFAULT_CODEC:String = "jpeg32";
		/**
		 * 将多个MovieClip对象编码为Dxr动画数据，合并到一个文件，返回文件的字节流数组
		 * @param mcList MovieClip对象列表,也可以传入显示对象列表,当做单帧处理
		 * @param keyList MovieClip在文件中的导出键名列表
		 * @param codecList 位图编解码器标识符列表,"jpegxr"|"jpeg32"|"png",留空默认值为"jpeg32"
		 * @param compress 二进制压缩格式，仅支持CompressionAlgorithm.ZLIB和CompressionAlgorithm.LZMA(需要11.4支持),
		 * 输入其他任何值都认为不启用二进制压缩。默认值：CompressionAlgorithm.ZLIB。
		 * @param maxBitmapWidth 单张位图最大宽度
		 * @param maxBitmapHeight 单张位图最大高度
		 */	
		public function encode(mcList:Array,keyList:Array=null,codecList:Array=null,compress:String="zlib",
							   maxBitmapWidth:Number=4000,maxBitmapHeight:Number=4000):ByteArray
		{
			var dxrDataList:Array = drawMcList(mcList,keyList,codecList);
			return encodeDxrDataList(dxrDataList,compress,maxBitmapWidth,maxBitmapHeight);
		}
		
		/**
		 * 绘制多个MovieClip对象，返回对应的dxrData列表
		 * @param mcList MovieClip列表
		 * @param keyList 导出键名列表,如果留空,编码器会为每个dxrData自动生成一个唯一的key
		 * @param codecList 位图编解码器标识符列表,"jpegxr"|"jpeg32"|"png",留空默认值为"jpeg32"
		 */		
		public function drawMcList(mcList:Array,keyList:Array=null,codecList:Array=null):Array
		{
			var dxrDataList:Array = [];
			var index:int = 0;
			for each(var mc:DisplayObject in mcList)
			{
				var codec:String = codecList?codecList[index]:DEFAULT_CODEC;
				var key:String = keyList?keyList[index]:null;
				var dxrData:DxrData = drawDxrData(mc,key,codec);
				if(!key)
				{
					generateKey(dxrData);
				}
				dxrDataList.push(dxrData);
				index++;
			}
			return dxrDataList;
		}
		/**
		 * 绘制一个显示对象，转换为DxrData对象。<br/>
		 * 注意：绘制的结果是其原始显示对象，不包含alpha,scale,rotation,或matrix值。但包含滤镜和除去alpha的colorTransfrom。
		 * @param dp 要绘制的显示对象，可以是MovieClip
		 * @param key DxrData对象的导出键名
		 * @param codec 位图编解码器标识符,"jpegxr"|"jpeg32"|"png",留空默认值为"jpeg32"
		 */	
		public function drawDxrData(dp:DisplayObject,key:String="",codec:String="jpeg32"):DxrData
		{
			var dxrData:DxrData = new DxrData(key,codec);
			if(dp is MovieClip)
			{
				var mc:MovieClip = dp as MovieClip;
				var oldFrame:int = mc.currentFrame;
				var isPlaying:Boolean = mc.isPlaying;
				var totalFrames:int = mc.totalFrames;
				for(var frame:int=0;frame<totalFrames;frame++)
				{
					mc.gotoAndStop(frame+1);
					drawDisplayObject(mc,dxrData,frame);
				}
				if(isPlaying)
					mc.gotoAndPlay(oldFrame);
				else
					mc.gotoAndStop(oldFrame);
				dxrData._frameLabels = mc.currentLabels;
			}
			else
			{
				drawDisplayObject(dp,dxrData,0);
			}
			if(dp.scale9Grid)
				dxrData._scale9Grid = dp.scale9Grid.clone();
			return dxrData;
		}
		/**
		 * 调整偏移量用的容器
		 */		
		private var container:Sprite
		/**
		 * 复写父级方法，修正非整数的偏移量。
		 */		
		override dx_internal function drawDisplayObject(dp:DisplayObject, dxrData:DxrData, frame:int):void
		{
			var dpRect:Rectangle = dp.getBounds(dp);
			var offsetX:Number = dpRect.x%1;
			var offsetY:Number = dpRect.y%1;
			var stage:Stage = dp.stage;
			if(stage&&(Math.abs(offsetX)>0||Math.abs(offsetY)>0))
			{
				if(!container)
				{
					container = new Sprite();
					container.visible = false;
				}
				stage.addChild(container);
				var oldX:Number = dp.x;
				var oldY:Number = dp.y;
				var oldScaleX:Number = dp.scaleX;
				var oldScaleY:Number = dp.scaleY;
				var oldParent:DisplayObjectContainer = dp.parent;
				var oldIndex:int = oldParent.getChildIndex(dp);
				container.addChild(dp);
				dp.x = -dpRect.x;
				dp.y = -dpRect.y;
				dp.scaleX = dp.scaleY = 1;
				super.drawDisplayObject(container,dxrData,frame);
				var offsetPoint:Point = dxrData.frameOffsetList[frame];
				offsetPoint.x = offsetPoint.x +Math.round(dpRect.x);
				offsetPoint.y = offsetPoint.y +Math.round(dpRect.y);
				oldParent.addChildAt(dp,oldIndex);
				dp.x = oldX;
				dp.y = oldY;
				dp.scaleX = oldScaleX;
				dp.scaleY = oldScaleY;
				stage.removeChild(container);
			}
			else
			{
				super.drawDisplayObject(dp,dxrData,frame);
			}
		}
		
		/**
		 * 将多个DxrData对象编码合并到一个文件，返回文件的字节流数组
		 * @param dxrDataList DxrData对象列表
		 * @param compress 二进制压缩格式，仅支持CompressionAlgorithm.ZLIB和CompressionAlgorithm.LZMA(需要11.4支持),
		 * 输入其他任何值都认为不启用二进制压缩。默认值：CompressionAlgorithm.ZLIB。
		 * @param maxBitmapWidth 单张位图最大宽度
		 * @param maxBitmapHeight 单张位图最大高度
		 */		
		public function encodeDxrDataList(dxrDataList:Array,compress:String="zlib",
							   maxBitmapWidth:Number=4000,maxBitmapHeight:Number=4000):ByteArray
		{
			var dxrFile:Object = {keyList:{}};
			for each(var dxrData:DxrData in dxrDataList)
			{
				dxrFile.keyList[dxrData.key] = encodeDxrData(dxrData,maxBitmapWidth,maxBitmapHeight);
			}
			var bytes:ByteArray = writeObject(dxrFile,compress);
			return bytes;
		}
		/**
		 * 将DXR 转换为文件字节流数据
		 * @param keyObject 文件信息描述对象 
		 * @param compress 二进制压缩格式，仅支持CompressionAlgorithm.ZLIB和CompressionAlgorithm.LZMA(需要11.4支持),
		 * 输入其他任何值都认为不启用二进制压缩。默认值：CompressionAlgorithm.ZLIB。
		 */		
		public static function writeObject(keyObject:Object,compress:String="zlib"):ByteArray
		{
			var bytes:ByteArray = new ByteArray();
			bytes.position = 0;
			bytes.writeUTF("dxr");
			if(compress!="zlib"&&compress!="lzma")
			{
				compress = "false";
			}
			bytes.writeUTF(compress);
			var dxrBytes:ByteArray = new ByteArray();
			dxrBytes.writeObject(keyObject);
			if(compress!="false")
			{
				dxrBytes.compress(compress);
			}
			bytes.writeBytes(dxrBytes);
			return bytes;
		}
		
		/**
		 * 编码单个DxrData对象
		 * @param dxrData 要编码的DxrData对象
		 * @param maxBitmapWidth 单张位图最大宽度
		 * @param maxBitmapHeight 单张位图最大高度
		 */		
		private function encodeDxrData(dxrData:DxrData,maxBitmapWidth:Number=4000,maxBitmapHeight:Number=4000):Object
		{
			var copyFrom:Array = compareBitmap(dxrData);
			var copyFromIndex:int;
			var bitmapEncoder:IBitmapEncoder = Injector.getInstance(IBitmapEncoder,dxrData.codecKey);
			var data:Object = {codec:bitmapEncoder.codecKey,bitmapList:[],frameInfo:[]};
			var frameInfo:Array;
			var tempBmData:BitmapData = new BitmapData(maxBitmapWidth,maxBitmapHeight,true,0);
			var bitmapIndex:int = 0;
			var currentX:Number = 0;
			var currentY:Number = 0;
			var maxHeight:Number = 0;
			var index:int = 0;
			var tempBmRect:Rectangle;
			var pageData:BitmapData;
			var offsetPoint:Point;
			for each(var frameBmData:BitmapData in dxrData.frameList)
			{
				var offsetRect:Rectangle = getColorRect(frameBmData);
				offsetPoint = dxrData.frameOffsetList[index];
				if(offsetRect.width>maxBitmapWidth||offsetRect.height>maxBitmapHeight)
				{
					throw new Error("DXR动画："+dxrData.key+" 的第"+index
						+"帧超过了所设置的最大位图尺寸:"+maxBitmapWidth+"x"+maxBitmapHeight+"!");
				}
				if(copyFrom[index]!==undefined)
				{
					copyFromIndex = copyFrom[index];
					frameInfo = data.frameInfo[copyFromIndex];
					frameInfo = frameInfo.concat();
					frameInfo[5] = offsetPoint.x+offsetRect.x;
					frameInfo[6] = offsetPoint.y+offsetRect.y;
					if(frameInfo.length<9)
					{
						frameInfo[7] = frameInfo[8] = 0;
					}
					frameInfo[9] = copyFromIndex;
					data.frameInfo[index] = frameInfo;
					index++;
					continue;
				}
				if(offsetRect.width>maxBitmapWidth-currentX)
				{
					currentY += maxHeight;
					currentX = 0;
					maxHeight = 0;
				}
				if(offsetRect.height>maxBitmapHeight-currentY)
				{
					tempBmRect = getColorRect(tempBmData);
					tempBmRect.x = 0;
					tempBmRect.y = 0;
					pageData = new BitmapData(tempBmRect.width,tempBmRect.height,true,0);
					pageData.copyPixels(tempBmData,tempBmRect,new Point(0,0),null,null,true);
					data.bitmapList[bitmapIndex] = bitmapEncoder.encode(pageData);
					tempBmData = new BitmapData(maxBitmapWidth,maxBitmapHeight,true,0);
					currentX = 0;
					currentY = 0;
					maxHeight = 0;
					bitmapIndex++;
				}
				tempBmData.copyPixels(frameBmData,offsetRect,new Point(currentX,currentY),null,null,true);
				frameInfo = [bitmapIndex,currentX,currentY,offsetRect.width,offsetRect.height,
					offsetPoint.x+offsetRect.x,offsetPoint.y+offsetRect.y];
				var filterOffset:Point = dxrData.filterOffsetList[index];
				if(filterOffset)
				{
					frameInfo[7] = filterOffset.x;
					frameInfo[8] = filterOffset.y;
				}
				data.frameInfo[index] = frameInfo;
				maxHeight = Math.max(maxHeight,offsetRect.height);
				currentX += offsetRect.width; 
				index++;
			}
			tempBmRect = getColorRect(tempBmData);
			if(tempBmRect.width>=1&&tempBmRect.height>=1)
			{
				pageData = new BitmapData(tempBmRect.width,tempBmRect.height,true,0);
				pageData.copyPixels(tempBmData,tempBmRect,new Point(0,0),null,null,true);
				data.bitmapList[bitmapIndex] = bitmapEncoder.encode(pageData);
			}
			else if(bitmapIndex==0)
			{
				data.bitmapList[bitmapIndex] = bitmapEncoder.encode(new BitmapData(1,1,true,0));
			}
			
			if(dxrData._scale9Grid)
			{
				var rect:Rectangle = dxrData._scale9Grid;
				data.scale9Grid = [rect.left,rect.top,rect.right,rect.bottom];
			}
			
			if(dxrData._frameLabels&&dxrData._frameLabels.length>0)
			{
				var fls:Array = [];
				for each(var frameLabel:FrameLabel in dxrData._frameLabels)
				{
					fls.push([frameLabel.frame,frameLabel.name]);
				}
				data.frameLabels = fls;
			}
			return data;
		}
		/**
		 * 比较位图，获取位图数据相同的索引映射表。
		 */		
		private function compareBitmap(dxrData:DxrData):Array
		{
			var copyFrom:Array = [];
			var frameList:Array = dxrData.frameList;
			var length:int = frameList.length;
			var frameA:BitmapData;
			var frameB:BitmapData;
			for(var i:int=0;i<length;i++)
			{
				if(copyFrom[i]!==undefined)
					continue;
				frameA = frameList[i];
				for(var j:int=i+1;j<length;j++)
				{
					if(copyFrom[j]!==undefined)
						continue;
					frameB = frameList[j];
					if(frameA==frameB||frameA.compare(frameB)==0)
					{
						copyFrom[j] = i;
					}
				}
			}
			return copyFrom;
		}
		
		/**
		 * 为指定的dxrData生成唯一的key
		 * @param dxrData 要赋值key的DxrData对象
		 */			
		public static function generateKey(dxrData:DxrData):void
		{
			var buf:ByteArray = new ByteArray();
			for each(var bd:BitmapData in dxrData.frameList)
			{
				buf.writeBytes(bd.getPixels(bd.rect));
			}
			var crc32:uint = CRC32Util.getCRC32(buf);
			dxrData._key = "DXR__"+crc32.toString(16).toUpperCase();
		}
	}
}