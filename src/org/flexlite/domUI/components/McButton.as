package org.flexlite.domUI.components
{
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	import org.flexlite.domCore.IMovieClip;
	import org.flexlite.domCore.dx_internal;
	
	use namespace dx_internal;
	
	
	[DXML(show="true")]
	
	/**
	 * 影片剪辑按钮控件,可以直接使用三帧的影片剪辑作为皮肤，第一帧：up，第二帧：over，第三帧：down。
	 * @author dom
	 */	
	public class McButton extends Button
	{
		/**
		 * 构造函数
		 */		
		public function McButton()
		{
			super();
		}   
		
		/**
		 * 影片剪辑的状态帧标签索引字典
		 */		
		private var frameDic:Dictionary;
		
		/**
		 * @inheritDoc
		 */
		override protected function attachSkin(skin:Object):void
		{
			super.attachSkin(skin);
			if(skin is MovieClip||skin is IMovieClip)
			{
				frameDic = getFrameDic(skin,["up","over","down"]);
				frameDic["disabled"] = frameDic["up"];
			}
			if(skin is MovieClip)
			{
				(skin as MovieClip).gotoAndStop(frameDic["up"]);
			}
			else if(skin is IMovieClip)
			{
				(skin as IMovieClip).gotoAndStop(frameDic["up"]);
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function validateSkinState():void
		{
			super.validateSkinState();
			var curSkin:Object = skinObject;
			if(curSkin is MovieClip)
			{
				(curSkin as MovieClip).gotoAndStop(frameDic[getCurrentSkinState()]);
			}
			else if(curSkin is IMovieClip)
			{
				(curSkin as IMovieClip).gotoAndStop(frameDic[getCurrentSkinState()]);
			}
		}
		
		/**
		 * 获取状态列表对应的帧索引字典类
		 */		
		public static function getFrameDic(skin:Object,stateList:Array):Dictionary
		{
			var mc:MovieClip = skin as MovieClip;
			var dxrMc:IMovieClip = skin as IMovieClip;
			var totalFrames:int = mc?mc.totalFrames:dxrMc.totalFrames;
			var frameDic:Dictionary = new Dictionary;
			var state:String;
			var index:int;
			if(totalFrames < stateList.length)
			{
				for each(state in stateList)
				{
					frameDic[state] = mc?1:0;
				}
				return frameDic;
			}
			
			var frameLabelV:Array = mc?mc.currentLabels:dxrMc.frameLabels;
			if(frameLabelV == null || frameLabelV.length == 0)
			{
				index = 0;
				for each(state in stateList)
				{
					index++;
					frameDic[state] = mc?index:index-1;
				}
				return frameDic;
			}
			
			index = 0
			for each(state in stateList)
			{
				index++;
				frameDic[state] = getFrameByLabel(state,frameLabelV,mc?index:index-1);
			}
			return frameDic;
		}
		
		/**
		 * 检查标签列表里是否含有指定的标签,若含有，返回对应的帧索引，若不存在，返回传入的defualtFrame值
		 */		
		private static function getFrameByLabel(fname:String,frameLabelV:Array,defualtFrame:int):int
		{
			for each(var frameLabel:FrameLabel in frameLabelV) 
			{
				if(frameLabel.name == fname)
				{
					return frameLabel.frame;
				}
			}
			return defualtFrame;
		}
		
	}
}
