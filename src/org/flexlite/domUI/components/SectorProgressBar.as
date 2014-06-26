package org.flexlite.domUI.components
{
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.events.Event;
	
	import mx.events.ResizeEvent;
	
	import org.flexlite.domUI.components.supportClasses.Range;
	import org.flexlite.domUI.effects.animation.Animation;
	import org.flexlite.domUI.effects.animation.MotionPath;
	
	/**
	 * 扇形进度条
	 * @author dom
	 */
	public class SectorProgressBar extends Range
	{
		public function SectorProgressBar()
		{
			super();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function get hostComponentKey():Object
		{
			return SectorProgressBar;
		}
		
		/**
		 * [SkinPart]进度高亮显示对象。
		 */		
		public var thumb:DisplayObject;
		/**
		 * [SkinPart]遮罩对象，将在这个对象上，以其中心为原点，以短边长的一半为半径吗，绘制扇形遮罩。
		 */		
		public var sectorMask:Spacer;
		/**
		 * [SkinPart]进度条文本
		 */
		public var labelDisplay:Label;
		
		private var _labelFunction:Function;
		/**
		 * 进度条文本格式化回调函数。示例：labelFunction(value:Number,maximum:Number):String;
		 */
		public function get labelFunction():Function
		{
			return _labelFunction;
		}
		public function set labelFunction(value:Function):void
		{
			if(_labelFunction == value)
				return;
			_labelFunction = value;
			invalidateDisplayList();
		}
		
		/**
		 * 将当前value转换成文本
		 */		
		protected function valueToLabel(value:Number,maximum:Number):String
		{
			if(labelFunction!=null)
			{
				return labelFunction(value,maximum);
			}
			return value+" / "+maximum;
		}
		
		private var _slideDuration:Number = 500;
		
		/**
		 * value改变时调整thumb长度的缓动动画时间，单位毫秒。设置为0则不执行缓动。默认值500。
		 */		
		public function get slideDuration():Number
		{
			return _slideDuration;
		}
		
		public function set slideDuration(value:Number):void
		{
			if(_slideDuration==value)
				return;
			_slideDuration = value;
			if(animator&&animator.isPlaying)
			{
				animator.stop();
				super.value = slideToValue;
			}
		}
		
		/**
		 * 动画实例
		 */	
		private var animator:Animation = null;
		/**
		 * 动画播放结束时要到达的value。
		 */		
		private var slideToValue:Number;
		
		/**
		 * 进度条的当前值。
		 * 注意：当组件添加到显示列表后，若slideDuration不为0。设置此属性，并不会立即应用。而是作为目标值，开启缓动动画缓慢接近。
		 * 若需要立即重置属性，请先设置slideDuration为0，或者把组件从显示列表移除。
		 */
		override public function get value():Number
		{
			return super.value;
		}
		override public function set value(newValue:Number):void
		{
			if(super.value == newValue)
				return;
			if (_slideDuration == 0||!stage)
			{
				super.value = newValue;
			}
			else
			{
				validateProperties();//最大值最小值发生改变时要立即应用，防止当前起始值不正确。
				slideToValue = nearestValidValue(newValue, snapInterval);
				if(slideToValue==super.value)
					return;
				if (!animator)
				{
					animator = new Animation(animationUpdateHandler);
					animator.easer = null;
				}
				if (animator.isPlaying)
				{
					setValue(nearestValidValue(animator.motionPaths[0].valueTo, snapInterval));
					animator.stop();
				}
				var duration:Number = _slideDuration * 
					(Math.abs(super.value - slideToValue) / (maximum - minimum));
				animator.duration = duration===Infinity?0:duration;
				animator.motionPaths = new <MotionPath>[
					new MotionPath("value", super.value, slideToValue)];
				animator.play();
			}
		}
		
		/**
		 * 动画播放更新数值
		 */	
		private function animationUpdateHandler(animation:Animation):void
		{
			setValue(nearestValidValue(animation.currentValue["value"], snapInterval));
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function setValue(value:Number):void
		{
			super.setValue(value);
			invalidateDisplayList();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			updateSkinDisplayList();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function partAdded(partName:String, instance:Object):void
		{
			if(instance==sectorMask)
			{
				sectorMask.addEventListener(ResizeEvent.RESIZE,onSectorMaskResize);
				if(thumb)
					thumb.mask = sectorMask;
			}
			else if(instance==thumb)
			{
				if(sectorMask)
					thumb.mask = sectorMask;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function partRemoved(partName:String, instance:Object):void
		{
			if(instance==sectorMask)
			{
				sectorMask.removeEventListener(ResizeEvent.RESIZE,onSectorMaskResize);
			}
		}
		
		private var trackResizedOrMoved:Boolean = false;
		/**
		 * track的位置或尺寸发生改变
		 */		
		private function onSectorMaskResize(event:Event):void
		{
			updateSkinDisplayList();
		}
		
		/**
		 * 更新皮肤部件大小和可见性。
		 */		
		protected function updateSkinDisplayList():void
		{
			trackResizedOrMoved = false;
			var currentValue:Number = isNaN(value)?0:value;
			var maxValue:Number = isNaN(maximum)?0:maximum;
			if(sectorMask&&sectorMask.width>0&&sectorMask.height>0)
			{
				var maskWidth:Number = sectorMask.width;
				var maskHeight:Number = sectorMask.height;
				var centerX:Number = maskWidth*0.5;
				var centerY:Number = maskHeight*0.5;
				var radius:Number = Math.min(maskWidth,maskHeight)*0.5;
				var endAngle:Number = Math.round((currentValue/maxValue)*360);
				drawSector(sectorMask.graphics,endAngle,radius,centerX,centerY);
			}
			if(labelDisplay)
			{
				labelDisplay.text = valueToLabel(currentValue,maxValue);
			}
		}
		
		/**
		 * 绘制一个扇形
		 * @param graphics 要绘制到的Graphics对象
		 * @param endAngle 结束角度
		 * @param radius 半径
		 * @param centerX 中心点x
		 * @param centerY 中心点y
		 * @param fillColor 填充颜色
		 * @param lineColor 线条颜色
		 * @param lineWeight 线条粗细，设置为0不绘制线条。
		 * @param startAngle 起始角度，以x轴正向为0°，顺时针递增。
		 */		
		private function drawSector(graphics:Graphics,endAngle:Number,radius:Number,
								   centerX:Number,centerY:Number,fillColor:uint = 0x009afff,
								   lineColor:uint=0x000000,lineWeight:uint=1,startAngle:Number = 0):void
		{
			graphics.lineStyle(lineWeight,lineColor);
			graphics.beginFill(fillColor);
			graphics.moveTo(centerX,centerY);
			graphics.lineTo(centerX+radius*Math.cos(startAngle),centerY+radius*Math.sin(startAngle));
			var divAngle:Number = 45;
			var n:uint = int(endAngle/divAngle);
			while(n>0)
			{
				startAngle+=Math.PI/4;
				var controlX:Number = centerX+radius/Math.cos(Math.PI/8)*Math.cos(startAngle-Math.PI/8);
				var controlY:Number = centerY+radius/Math.cos(Math.PI/8)*Math.sin(startAngle-Math.PI/8);
				var anchorX:Number = centerX+radius*Math.cos(startAngle);
				var anchorY:Number = centerY+radius*Math.sin(startAngle);
				graphics.curveTo(controlX,controlY,anchorX,anchorY);
				n--;
			}
			if(endAngle%divAngle)
			{
				var am:Number = endAngle%divAngle*Math.PI/180;
				controlX = centerX+radius/Math.cos(am/2)*Math.cos(startAngle+am/2);
				controlY = centerY+radius/Math.cos(am/2)*Math.sin(startAngle+am/2);
				anchorX = centerX+radius*Math.cos(startAngle+am);
				anchorY = centerY+radius*Math.sin(startAngle+am);
				graphics.curveTo(controlX,controlY,anchorX,anchorY);
			}
			graphics.lineTo(centerX,centerY);
			graphics.endFill();
		}
	}
}