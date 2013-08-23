package org.flexlite.domUI.skins
{
	import flash.display.Graphics;
	
	import org.flexlite.domCore.dx_internal;
	import org.flexlite.domUI.skins.VectorSkin;

	use namespace dx_internal;
	
	public class DecrementButtonSkin extends VectorSkin
	{
		public function DecrementButtonSkin()
		{
			super();
			states = ["up","over","down","disabled"];
			minWidth = 20;
			minHeight = 11;
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			var g:Graphics = graphics;
			g.clear();
			var arrowColor:uint;
			var radius:Object = {tl:0,tr:0,bl:0,br:cornerRadius};
			switch (currentState)
			{			
				case "up":
				case "disabled":
					drawCurrentState(0,0,w,h,borderColors[0],bottomLineColors[0],
						[fillColors[0],fillColors[1]],radius);
					arrowColor = themeColors[0];
					break;
				case "over":
					drawCurrentState(0,0,w,h,borderColors[1],bottomLineColors[1],
						[fillColors[2],fillColors[3]],radius);
					arrowColor = themeColors[1];
					break;
				case "down":
					drawCurrentState(0,0,w,h,borderColors[2],bottomLineColors[2],
						[fillColors[4],fillColors[5]],radius);
					arrowColor = themeColors[1];
					break;
			}
			this.alpha = currentState=="disabled"?0.5:1;
			g.lineStyle(0,0,0);
			g.beginFill(arrowColor);
			
			g.moveTo(w*0.5, h*0.5 + 3);
			g.lineTo(w*0.5-3.5, h*0.5 - 2);
			g.lineTo(w*0.5+3.5, h*0.5 - 2);
			g.lineTo(w*0.5, h*0.5 + 3);
			
			g.endFill();
		}
	}
}