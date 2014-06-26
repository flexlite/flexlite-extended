package org.flexlite.domUI.core
{
	/**
	 * 支持样式绑定的组件接口
	 * @author dom
	 */	
	public interface IStyleClient
	{
		/**
		 * 获取样式属性值
		 * @param styleName 样式名
		 */		
		function getStyle(styleName:String):*;
		/**
		 * 设置样式属性值
		 * @param styleName 样式名
		 * @param value 属性值
		 */		
		function setStyle(styleName:String,value:*):void;
	}
}