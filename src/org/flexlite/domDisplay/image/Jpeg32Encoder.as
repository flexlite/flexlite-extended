package org.flexlite.domDisplay.image
{
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.JPEGEncoderOptions;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import mx.graphics.codec.JPEGEncoder;
	
	import org.flexlite.domDisplay.codec.IBitmapEncoder;
	
	
	/**
	 * JPEG32位图编码器,由于AIR3.4的JPEG编码器有色差的bug，暂时使用此编码器替代库里的对应编码器。
	 * @author dom
	 */
	public class Jpeg32Encoder implements IBitmapEncoder
	{
		/**
		 * 构造函数
		 * @param quality 编码质量 1～100,值越高画面质量越好
		 */
		public function Jpeg32Encoder(quality:int = 80)
		{
			encodeOptions = new JPEGEncoderOptions(quality);
		}
		
		public function get codecKey():String
		{
			return "jpeg32";
		}
		
		private var encodeOptions:JPEGEncoderOptions;

		public function encode(bitmapData:BitmapData):ByteArray
		{
			var aBlock:ByteArray = getAlphaDataBlock(bitmapData);
			var aBlockLength:uint = aBlock.length;			
			var encoder:JPEGEncoder = new JPEGEncoder;
			var bBlock:ByteArray = encoder.encode(bitmapData);
			var fBlock:ByteArray = new ByteArray();
			
			fBlock.position = 0;
			fBlock.writeUnsignedInt(aBlockLength);
			fBlock.writeBytes(aBlock,0,aBlock.length);
			fBlock.writeBytes(bBlock,0,bBlock.length);
			return fBlock;
		}
		
		
		
		/**
		 * 提取图像alpha通道数据块
		 * @param source 源图像数据
		 */
		private static function getAlphaDataBlock(source:BitmapData):ByteArray
		{
			var alphaBitmapData:BitmapData = new BitmapData(source.width,source.height,true,0);
			alphaBitmapData.copyChannel(source,source.rect,new Point(),BitmapDataChannel.ALPHA,BitmapDataChannel.ALPHA);
			var bytes:ByteArray = new ByteArray();
			bytes.position = 0;
			bytes.writeUTF("alphaBlock");
			bytes.writeBytes(alphaBitmapData.getPixels(alphaBitmapData.rect));
			bytes.compress();
			return bytes;
		}
	}
}