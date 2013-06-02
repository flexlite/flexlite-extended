package org.flexlite.domUtils
{
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	
	/**
	 * 具有属性失效验证功能的事件抛出对象
	 * @author DOM
	 */
	public class InvalidteEventDispatcher extends EventDispatcher
	{
		/**
		 * 构造函数
		 */		
		public function InvalidteEventDispatcher(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		/**
		 * EnterFrame事件抛出显示对象
		 */		
		private var enterFrameSp:Shape = new Shape;
		/**
		 * 添加过事件监听的标志
		 */		
		private var listenForEnterFrame:Boolean = false;
		/**
		 * 标记属性失效
		 */		
		public function invalidateProperties():void
		{
			if(listenForEnterFrame)
				return;
			listenForEnterFrame = true;
			enterFrameSp.addEventListener(Event.ENTER_FRAME,onEnterFrame);
		}
		/**
		 * EnterFrame事件触发
		 */		
		private function onEnterFrame(event:Event):void
		{
			listenForEnterFrame = false;
			enterFrameSp.removeEventListener(Event.ENTER_FRAME,onEnterFrame);
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