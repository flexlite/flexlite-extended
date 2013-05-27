package org.flexlite.domUI.components
{
	/**
	 * @example
	 * var iconButton:IconButton = new IconButton();
	 * iconButton.skinName = IconButtonSkin;
	 * iconButton.icon = Class,String, or DisplayObject
	 * 
	 * @author foodyi
	 * 
	 */	
	public class IconButton extends Button
	{
		/**
		 * 构造函数
		 */		
		public function IconButton()
		{
			super();	
		}
		
		private var _icon:Object;
		/**
		 * 要显示的图标，可以是类定义，位图数据，显示对象或路径字符。
		 */
		public function get icon():Object
		{
			return _icon;
		}
		public function set icon(value:Object ):void
		{
			if(_icon==value)
				return;
			_icon = value;
			if(iconDisplay)
				iconDisplay.skinName = _icon;
		}
		/**
		 * [SkinPart]图标显示对象
		 */		
		public var iconDisplay:UIAsset;
		
		
		override protected function partAdded(partName:String, instance:Object):void
		{
			super.partAdded( partName,instance )
			if( instance == iconDisplay )
			{
				iconDisplay.skinName = _icon;
			}
			
		}
		
		
	}
}