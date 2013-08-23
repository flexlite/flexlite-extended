package org.flexlite.domUI.skins
{
	import org.flexlite.domUI.components.Button;
	import org.flexlite.domUI.components.TextInput;
	import org.flexlite.domUI.skins.VectorSkin;

	/**
	 *  
	 * @author foodyi
	 * 
	 */	
	public class NumericStepperSkin extends VectorSkin
	{
		public var decrementButton:Button;
		
		public var incrementButton:Button;
		
		public var textDisplay:TextInput;
		
		override protected function createChildren():void{
			super.createChildren();
			
			textDisplay = new TextInput();
			textDisplay.left = 0;
			textDisplay.right = 19;
			textDisplay.top = 0;
			textDisplay.bottom = 0;
			addElement( textDisplay );
			
			incrementButton = new Button();
			incrementButton.right = 0;
			incrementButton.top = 0;
			incrementButton.skinName = IncrementButtonSkin;
			addElement( incrementButton );
			
			decrementButton = new Button();
			decrementButton.right = 0;
			decrementButton.bottom = 0;
			decrementButton.skinName = DecrementButtonSkin;
			addElement( decrementButton );
			
		}
		
		
	}
}