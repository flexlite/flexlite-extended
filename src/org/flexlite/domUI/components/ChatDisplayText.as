package org.flexlite.domUI.components
{
	import flash.text.engine.ElementFormat;
	
	import org.flexlite.domUI.core.UIComponent;
	
	
	/**
	 * 
	 * @author DOM
	 */
	public class ChatDisplayText extends UIComponent
	{
		public function ChatDisplayText()
		{
			super();
		}
		/**
		 * 表情符转义函数,示例：emoticonFunction(key:String):DisplayObject;
		 */		
		public var emoticonFunction:Function;
		
		private var _text:String = "";
		private var textChanged:Boolean = false;
		/**
		 * 要显示的文本。文本中的表情用一对"[]"符表示，例如"[wx]",中括号内的"wx"对应一个唯一的表情显示对象。
		 * 显示时将会截取中括号内的"wx"，传值给emoticonFunction函数以获得对应的显示对象,并替换掉"[wx]"。
		 */
		public function get text():String
		{
			return _text;
		}

		public function set text(value:String):void
		{
			if(_text==value)
				return;
			_text = value;
			textChanged = true;
			invalidateProperties();
			invalidateSize();
			invalidateDisplayList();
		}

		override protected function commitProperties():void
		{
			super.commitProperties();
			if(textChanged)
			{
				createTextLines();
				textChanged = false;
			}
		}
		
		/**
		 * 创建指定文本格式的TextLine对象
		 */		
		private function createTextLines():void
		{
			
		}
	}
}