package org.flexlite.domUtils
{
	import flash.display.Shape;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	
	/**
	 * 具有属性失效验证功能的事件抛出对象
	 * @author dom
	 */
	public class InvalidteEventDispatcher extends EventDispatcher
	{
		/**
		 * 构造函数
		 * @param stage 若传入舞台引用，将可以在Render阶段执行失效验证。
		 */		
		public function InvalidteEventDispatcher(stage:Stage=null)
		{
			super();
			this.stage = stage;
		}
		
		private var stage:Stage;
		/**
		 * EnterFrame事件抛出显示对象
		 */		
		private var enterFrameSp:Shape = new Shape;
		/**
		 * 添加过事件监听的标志
		 */		
		private var invalidateFlag:Boolean = false;
		/**
		 * 标记属性失效
		 */		
		public function invalidateProperties():void
		{
			if(invalidateFlag)
				return;
			invalidateFlag = true;
			enterFrameSp.addEventListener(Event.ENTER_FRAME,validateProperties);
			if(stage)
			{
				stage.addEventListener(Event.RENDER,validateProperties);
				stage.invalidate();
			}
		}
		
		/**
		 * 延迟应用属性事件
		 */		
		private function validateProperties(event:Event=null):void
		{
			invalidateFlag = false;
			enterFrameSp.removeEventListener(Event.ENTER_FRAME,validateProperties);
			if(stage)
				stage.removeEventListener(Event.RENDER,validateProperties);
			commitProperties();
		}	
		
		/**
		 * 验证失效的属性
		 */		
		protected function commitProperties():void
		{
			
		}
	}
}