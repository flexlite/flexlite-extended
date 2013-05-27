package org.flexlite.domUI.skins
{
	import org.flexlite.domUI.components.UIAsset;
	import org.flexlite.domUI.skins.vector.ButtonSkin;

	public class IconButtonSkin extends ButtonSkin
	{
		public function IconButtonSkin()
		{
			super();
		}
		
		public var iconDisplay:UIAsset;
		
		override protected function createChildren():void{
			super.createChildren();
			iconDisplay = new UIAsset();
			addElement( iconDisplay );
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void{
			super.updateDisplayList(w,h);
			
			if( iconDisplay )
			{
				iconDisplay.x = w*.5 - iconDisplay.width*.5;
				iconDisplay.y = h*.5 - iconDisplay.height*.5;
			}
		}
	}
}