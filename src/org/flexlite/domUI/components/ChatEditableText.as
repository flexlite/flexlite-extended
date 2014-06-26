package org.flexlite.domUI.components
{
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.engine.TextLine;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.Timer;
	
	import org.flexlite.domCore.dx_internal;
	
	use namespace dx_internal;
	
	/**
	 * 可编辑的聊天图文混排文本
	 * @author dom
	 */
	public class ChatEditableText extends ChatDisplayText
	{
		public function ChatEditableText()
		{
			super();
			updateEditableState();
			drawCaretMask();
		}
		
		private function drawCaretMask():void
		{
			if(!caretMask)
				caretMask = new Shape();
			var g:Graphics = caretMask.graphics;
			g.clear();
			g.lineStyle(1,textColor);
			g.lineTo(0,size);
			g.endFill();
		}
		
		/**
		 * 插入一个表情符
		 * @param key 表情符对应的字符串,字符串内不能含有"["和"]"两个特殊字符，
		 * 此字符串由emoticonFunction()方法解析为显示对象。
		 */		
		public function insertEmoticon(key:String):void
		{
			var oldText:String = text;
			var newText:String = "["+key+"]";
			var insertIndex:int = getInsertIndex(_caretIndex);
			var preStr:String = oldText.substring(0,insertIndex);
			var subStr:String = oldText.substring(insertIndex);
			text = preStr+newText+subStr;
			_caretIndex += 1;
		}
		
		private var sizeChanged:Boolean = false;
		
		override public function set size(value:int):void
		{
			if(super.size==value)
				return;
			super.size = value;
			sizeChanged = true;
			invalidateProperties();
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
			if(sizeChanged)
			{
				drawCaretMask();
				sizeChanged = false;
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
				addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
				addEventListener(FocusEvent.FOCUS_IN,onFocusIn);
				addEventListener(FocusEvent.FOCUS_OUT,onFocusOut);
				addEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
			}
			else
			{
				focusEnabled = false;
				removeEventListener(TextEvent.TEXT_INPUT,onTextInput);
				removeEventListener(MouseEvent.ROLL_OVER,onMouseRollOver);
				removeEventListener(MouseEvent.ROLL_OUT,onMouseRollOut);
				removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
				removeEventListener(FocusEvent.FOCUS_IN,onFocusIn);
				removeEventListener(FocusEvent.FOCUS_OUT,onFocusOut);
			}
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			if(event.keyCode==Keyboard.BACKSPACE)
			{
				var insertIndex:int = getInsertIndex(_caretIndex-1);
				removeIndex(insertIndex);
				if(_caretIndex>0)
					_caretIndex --;
			}
			else if(event.keyCode==Keyboard.DELETE)
			{
				insertIndex = getInsertIndex(_caretIndex);
				removeIndex(insertIndex);
			}
			else if(event.keyCode==Keyboard.LEFT)
			{
				if(_caretIndex>0)
				{
					_caretIndex--;
					updateCaretMask();
				}
			}
			else if(event.keyCode==Keyboard.RIGHT)
			{
				var oldIndex:int = getInsertIndex(_caretIndex);
				if(getInsertIndex(_caretIndex+1)>oldIndex)
				{
					_caretIndex++;
					updateCaretMask();
				}
			}
		}
		
		private function removeIndex(index:int):void
		{
			var oldText:String = text;
			var startIndex:int = index;
			var endIndex:int = index+1;
			if(oldText.charAt(index)=="[")
			{
				if(oldText.charAt(index+1)=="[")
				{
					endIndex ++;
				}
				else
				{
					var str:String = oldText.substr(startIndex+1);
					endIndex = str.indexOf("]")+startIndex+2;
				}
			}
			var preStr:String = oldText.substring(0,startIndex);
			var subStr:String = oldText.substring(endIndex);
			text = preStr+subStr;
		}
		
		private var caretMask:Shape;
		
		private var timer:Timer;
		
		private function onFocusIn(event:FocusEvent):void
		{
			addToDisplayList(caretMask);
			updateCaretMask();
			if(!timer)
			{
				timer = new Timer(500);
				timer.addEventListener(TimerEvent.TIMER,onCaretTick);
			}
			timer.start();
		}
		
		private function onFocusOut(event:FocusEvent):void
		{
			removeFromDisplayList(caretMask);
			timer.stop();
		}
		
		private function onCaretTick(event:TimerEvent):void
		{
			caretMask.visible = !caretMask.visible;
		}
		
		
		/**
		 * 更新当前
		 */		
		private function updateCaretMask():void
		{
			var textLine:TextLine = textLines.length>0?textLines[0]:null;
			if(textLine)
			{
				var count:int = 0;
				var found:Boolean = false;
				var rect:Rectangle;
				while(textLine)
				{
					if(count+textLine.atomCount>=_caretIndex+1)
					{
						found = true;
						break;
					}
					count += textLine.atomCount;
					textLine = textLine.nextLine;
				}
				if(found)
				{
					rect = textLine.getAtomBounds(_caretIndex-count);
					caretMask.x = rect.x;
					caretMask.y = textLine.y - textLine.ascent;
				}
				else
				{
					textLine = textLines[textLines.length-1];
					rect = textLine.getAtomBounds(textLine.atomCount-1);
					caretMask.x = rect.x+rect.width;
					caretMask.y = textLine.y - textLine.ascent;
				}
				
			}
			else
			{
				caretMask.x = 0;
				caretMask.y = 0;
			}
			caretMask.visible = true;
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			if(textLines.length==0)
			{
				_caretIndex = 0;
				if(stage)
					stage.focus = this;
				updateCaretMask();
				return;
			}
			for each(var textLine:TextLine in textLines)
			{
				var startY:Number = textLine.y-textLine.totalAscent;
				var endY:Number = textLine.y+textLine.totalDescent+leading;
				if(event.localY>=startY&&event.localY<endY)
				{
					break;
				}
			}
			var index:int = textLine.getAtomIndexAtPoint(event.stageX,event.stageY);
			var offset:int = 1;
			if(index==-1)
			{
				index = textLine.atomCount-1;
			}
			else
			{
				var rect:Rectangle = textLine.getAtomBounds(index);
				if(rect.x+rect.width*0.5>event.localX)
				{
					offset = 0;
				}
			}
			while(textLine.previousLine)
			{
				textLine = textLine.previousLine;
				index += textLine.atomCount;
			}
			_caretIndex = index+offset;
			if(stage)
				stage.focus = this;
			updateCaretMask();
		}
		
		private function onMouseRollOut(event:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.AUTO;
		}
		
		private function onMouseRollOver(event:MouseEvent):void
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
			text = preStr+newText+subStr;
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
					subLength += index;
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
							realLength += preStr.length;
							if(realLength>showIndex)
							{
								return subLength-(realLength-showIndex);
							}
							quote = "]";
							
						}
						else
						{
							realLength += 1;
							if(realLength>showIndex)
							{
								return subLength-index-(realLength-showIndex);
							}
							quote = "[";
						}
					}
					subLength += 1;
				}
			}
			subLength += text.length;
			realLength += text.length;
			return subLength-Math.max(0,realLength-showIndex);
		}
		
		override protected function createTextLines(maxLineWidth:Number):Rectangle
		{
			var rect:Rectangle = super.createTextLines(maxLineWidth);
			updateCaretMask();
			return rect;
		}
		
	}
	
}