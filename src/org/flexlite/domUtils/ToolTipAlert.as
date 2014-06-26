package org.flexlite.domUtils
{
	import flash.utils.setTimeout;
	
	import mx.core.IToolTip;
	import mx.managers.ToolTipManager;
	
	/**
	 * 
	 * @author dom
	 */
	public class ToolTipAlert
	{
		/**
		 * 在应用程序中心显示一个ToolTip文本，并在一定时间后移除。
		 * @param message 要显示的文本内容
		 * @param duration 在这个时间后移除，单位毫秒
 		 * @param offsetX ToolTip坐标的x偏移量
		 * @param offsetY ToolTip坐标的y偏移量
		 */		
		public static function show(message:String,duration:int=5000,offsetX:Number=0,offsetY:Number=0):void
		{
			var tooltip:IToolTip = ToolTipManager.createToolTip(message,0,0);
			tooltip.x = (tooltip.parent.width-tooltip.width)*0.5+offsetX;
			tooltip.y = (tooltip.parent.height-tooltip.height)*0.5+offsetY;
			setTimeout(function():void{
				ToolTipManager.destroyToolTip(tooltip);
			},5000);
		}
	}
}