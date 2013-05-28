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
		public function IconButton()
		{
			super();	
		}
		
		private var _icon:Object;
		
		public var iconDisplay:UIAsset;
		
		
		public function set icon( value:Object ):void
		{
			_icon = value;
			partAdded("iconDisplay",iconDisplay);
			
		}
		
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