package org.flexlite.domUI.components
{
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	/**
	 * 可编辑的聊天图文混排文本
	 * @author DOM
	 */
	public class ChatEditableText extends ChatDisplayText
	{
		public function ChatEditableText()
		{
			super();
			updateEditableState();
		}
		
		private var pendingEditable:Boolean = true;
		
		private var _editable:Boolean = true;
		
		private var editableChanged:Boolean = false;
		/**
		 * @inheritDoc
		 */
		public function get editable():Boolean
		{
			if(enabled)
				return _editable;
			return pendingEditable;
		}
		
		public function set editable(value:Boolean):void
		{
			if(_editable==value)
				return;
			if(enabled)
			{
				_editable = value;
				editableChanged = true;
				invalidateProperties();
			}
			else
			{
				pendingEditable = value;
			}
		}
		
		/**
		 * @inheritDoc
		 */		
		override public function set enabled(value:Boolean):void
		{
			if (value == super.enabled)
				return;
			
			super.enabled = value;
			if(enabled)
			{
				if(_editable!=pendingEditable)
					editableChanged = true;
				_editable = pendingEditable;
			}
			else
			{
				if(editable)
					editableChanged = true;
				pendingEditable = _editable;
				_editable = false;
			}
			invalidateProperties();
		}
		
		private var _caretIndex:int = 0;
		/**
		 * 插入点（尖号）位置的索引。如果没有显示任何插入点，则在将焦点恢复到字段时，
		 * 值将为插入点所在的位置（通常为插入点上次所在的位置，如果字段不曾具有焦点，则为 0）。<p/>
		 * 选择范围索引是从零开始的（例如，第一个位置为 0、第二个位置为 1，依此类推）。
		 */	
		public function get caretIndex():int
		{
			return _caretIndex;
		}

		override protected function commitProperties():void
		{
			super.commitProperties();
			if(editableChanged)
			{
				updateEditableState();
				editableChanged = false;
			}
		}
		
		private var oldEditable:Boolean = false;
		
		private function updateEditableState():void
		{
			if(_editable==oldEditable)
				return;
			oldEditable = _editable;
			if(_editable)
			{
				focusEnabled = true;
				addEventListener(TextEvent.TEXT_INPUT,onTextInput);
				addEventListener(MouseEvent.ROLL_OVER,onMouseRollOver);
				addEventListener(MouseEvent.ROLL_OUT,onMouseRollOut);
			}
			else
			{
				focusEnabled = false;
				removeEventListener(TextEvent.TEXT_INPUT,onTextInput);
				removeEventListener(MouseEvent.ROLL_OVER,onMouseRollOver);
				removeEventListener(MouseEvent.ROLL_OUT,onMouseRollOut);
			}
		}
		
		protected function onMouseRollOut(event:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.AUTO;
		}
		
		protected function onMouseRollOver(event:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.IBEAM;
		}
		
		private function onTextInput(event:TextEvent):void
		{
			var oldText:String = text;
			var newText:String = event.text;
			newText = newText.split("[").join("[[");
			var insertIndex:int = getInsertIndex(_caretIndex);
			var preStr:String = oldText.substring(0,insertIndex);
			var subStr:String = oldText.substring(insertIndex);
			text = preStr+event.text+subStr;
			_caretIndex += event.text.length;
		}
		/**
		 * 根据字符串显示的索引，获取text对应的索引。
		 */		
		private function getInsertIndex(showIndex:int):int
		{
			if(showIndex==0)
				return 0;
			var text:String = this.text;
			if(showIndex >= text.length)
				return text.length;
			var quote:String = "[";
			var subLength:int = 0;
			var realLength:int = 0;
			while(text.length>0)
			{
				var index:int = text.indexOf(quote);
				if(index==-1)
				{
					break;
				}
				else
				{
					var preStr:String = text.substring(0,index);
					text = text.substring(index+1);
					subLength += index+1;
					if(quote=="["&&text.charAt(0)==quote)
					{
						text = text.substring(1);
						subLength += 1;
						continue;
					}
					else
					{
						var len:int = 1;
						if(quote=="[")
						{
							len = preStr.length;
							quote = "]";
						}
						realLength += len;
						if(realLength>showIndex)
						{
							return subLength-(realLength-showIndex);
						}
						
					}
				}
				
			}
			subLength += text.length;
			realLength += text.length;
			return subLength-Math.max(0,realLength-showIndex);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			var g:Graphics = this.graphics;
			g.clear();
			g.beginFill(0x009aff,1);
			g.drawRect(0,0,unscaledWidth,unscaledHeight);
			g.endFill();
		}
	}
	
}