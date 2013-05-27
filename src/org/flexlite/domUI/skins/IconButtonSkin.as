package org.flexlite.domUI.skins
{
	import org.flexlite.domUI.components.UIAsset;
	import org.flexlite.domUI.skins.vector.ButtonSkin;
	/**
	 * 图标按钮默认皮肤
	 * @author foodyi
	 */	
	public class IconButtonSkin extends ButtonSkin
	{
		public function IconButtonSkin()
		{
			super();
		}
		
		public var iconDisplay:UIAsset;
		
		override protected function createChildren():void{
			iconDisplay = new UIAsset();
			addElement( iconDisplay );
			super.createChildren();
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void{
			super.updateDisplayList(w,h);
			
			if( iconDisplay )
			{
				iconDisplay.x = w*.5 - iconDisplay.layoutBoundsWidth*.5;
				iconDisplay.y = h*.5 - iconDisplay.layoutBoundsHeight*.5;
			}
		}
	}
}