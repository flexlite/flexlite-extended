package org.flexlite.domUI.components
{
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	import flash.text.engine.ContentElement;
	import flash.text.engine.ElementFormat;
	import flash.text.engine.GraphicElement;
	import flash.text.engine.GroupElement;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextElement;
	import flash.text.engine.TextLine;
	
	import org.flexlite.domCore.dx_internal;
	import org.flexlite.domUI.core.UIComponent;
	import org.flexlite.domUI.events.UIEvent;
	import org.flexlite.domUtils.Recycler;
	
	
	use namespace dx_internal;
	
	/**
	 * 
	 * @author DOM
	 */
	public class ChatDisplayText extends UIComponent
	{
		public function ChatDisplayText()
		{
			super();
			addEventListener(UIEvent.UPDATE_COMPLETE,updateCompleteHandler);
		}
		
		private static var staticTextBlock:TextBlock;
		/**
		 * 对staticTextBlock.recreateTextLine()方法的引用。
		 * 它是player10.1新添加的接口，能够重用TextLine而不用创建新的。
		 * 若当前版本低于10.1，此方法无效。
		 */		
		private static var recreateTextLine:Function;
		/**
		 * textLine对象缓存表
		 */		
		private static var textLineRecycler:Recycler;
		/**
		 * 初始化类静态属性
		 */		
		private static function initClass():void
		{
			staticTextBlock = new TextBlock();
			textLineRecycler = new Recycler();
			if ("recreateTextLine" in staticTextBlock)
				recreateTextLine = staticTextBlock["recreateTextLine"];
		}
		//调用初始化静态属性
		initClass();
		
		/**
		 * 一个验证阶段完成
		 */		
		private function updateCompleteHandler(event:UIEvent):void
		{
			lastUnscaledWidth = NaN;
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
		 * 注意：若要表示单独的"["或"]"，请使用"[["或"]]"避免被转义。
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
		
		private var contentElement:ContentElement;
		
		/**
		 * TextLine对象列表
		 */		
		private var textLines:Vector.<TextLine> = new Vector.<TextLine>();
		
		private var textLinesIsDirty:Boolean = false;

		override protected function commitProperties():void
		{
			super.commitProperties();
			if(textChanged)
			{
				contentElement = parseText(_text);
				textLinesIsDirty = true;
				textChanged = false;
			}
		}
		
		/**
		 * 解析文本
		 */		
		private function parseText(text:String):ContentElement
		{
			var lines:Array = [];
			var quote:String = "[";
			while(text.length>0)
			{
				var index:int = text.indexOf(quote);
				if(index==-1)
				{
					lines.push(text);
					break;
				}
				else
				{
					var preStr:String = text.substring(0,index);
					
					text = text.substring(index+1);
					if(text.charAt(0)==quote)
					{
						lines.push(preStr+quote);
						text = text.substring(1);
						continue;
					}
					else
					{
						if(quote=="]")
						{
							if(emoticonFunction!=null)
							{
								lines.push(emoticonFunction(preStr));
							}
							else
							{
								lines.push("["+preStr+"]");
							}
						}
						else
						{
							lines.push(preStr);
							quote = "]";
						}
					}
				}
			}
			
			text = "";
			var list:Vector.<ContentElement> = new Vector.<ContentElement>();
			while(lines.length>0)
			{
				var line:* = lines.shift();
				if(line is DisplayObject)
				{
					var dp:DisplayObject = line as DisplayObject;
					if(text)
					{
						text = text.split("[[").join("[");
						text = text.split("]]").join("]");
						var textElement:TextElement = new TextElement(text,new ElementFormat());
						list.push(textElement);
						text = "";
					}
					var graphicElement:GraphicElement = new GraphicElement(dp,dp.width,dp.height,new ElementFormat);
					list.push(graphicElement);
				}
				else
				{
					text += line;
				}
			}
			if(text)
			{
				text = text.split("[[").join("[");
				text = text.split("]]").join("]");
				textElement = new TextElement(text,new ElementFormat());
				list.push(textElement);
				text = "";
			}
			if(list.length==1)
				return list[0];
			if(list.length>1)
			{
				var groupElement:GroupElement = new GroupElement(list,new ElementFormat());
				return groupElement;
			}
			return null;
		}
		
		/**
		 * 上一次测量的宽度 
		 */		
		private var lastUnscaledWidth:Number = NaN;
		
		/**
		 * @inheritDoc
		 */
		override protected function measure():void
		{
			//先提交属性，防止样式发生改变导致的测量不准确问题。
			if(invalidatePropertiesFlag)
				validateProperties();
			if (isSpecialCase())
			{
				if (isNaN(lastUnscaledWidth))
				{
					oldPreferWidth = NaN;
					oldPreferHeight = NaN;
				}
				else
				{
					measureUsingWidth(lastUnscaledWidth);
					return;
				}
			}
			
			var availableWidth:Number;
			
			if (!isNaN(explicitWidth))
				availableWidth = explicitWidth;
			else if (maxWidth!=10000)
				availableWidth = maxWidth;
			
			measureUsingWidth(availableWidth);
		}
		
		/**
		 * 特殊情况，组件尺寸由父级决定，要等到父级UpdateDisplayList的阶段才能测量
		 */		
		private function isSpecialCase():Boolean
		{
			return (!isNaN(percentWidth) || (!isNaN(left) && !isNaN(right))) &&
				isNaN(explicitHeight) &&
				isNaN(percentHeight);
		}
		
		/**
		 * 使用指定的宽度进行测量
		 */	
		private function measureUsingWidth(w:Number):void
		{
			if(isNaN(w))
			{
				w = 1000000;
			}
			var rect:Rectangle = createTextLines(w);
			this.measuredHeight = rect.height;
			this.measuredWidth = rect.width;
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function updateDisplayList(unscaledWidth:Number,unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			
			if(isSpecialCase())
			{
				var firstTime:Boolean = isNaN(lastUnscaledWidth) ||
					lastUnscaledWidth != unscaledWidth;
				lastUnscaledWidth = unscaledWidth;
				if (firstTime)
				{
					oldPreferWidth = NaN;
					oldPreferHeight = NaN;
					invalidateSize();
					return;
				}
			}
			//防止在父级validateDisplayList()阶段改变的text属性值，
			//接下来直接调用自身的updateDisplayList()而没有经过measure(),使用的测量尺寸是上一次的错误值。
			if(invalidateSizeFlag)
				validateSize();
			createTextLines(unscaledWidth);
		}
		
		private var lastMaxLineWidth:Number = 0;
		private var lastMeasuredSize:Rectangle = new Rectangle;
		/**
		 * 创建指定文本格式的TextLine对象列表，并返回测量的尺寸。
		 */		
		private function createTextLines(maxLineWidth:Number):Rectangle
		{
			if(!textLinesIsDirty&&lastMaxLineWidth==maxLineWidth)
			{
				return lastMeasuredSize;
			}
			textLinesIsDirty = false;
			releaseTextLines();
			var textBlock:TextBlock = staticTextBlock;
			textBlock.content = contentElement;
			
			var measuredRect:Rectangle = new Rectangle();
			var n:int = 0;
			var nextTextLine:TextLine;
			var nextY:Number = 0;
			var textLine:TextLine;
			
			while (true)
			{
				var recycleLine:TextLine = textLineRecycler.get();
				if (recycleLine&&recreateTextLine!=null)
				{
					nextTextLine = recreateTextLine(
						recycleLine, textLine, maxLineWidth);
				}
				else
				{
					nextTextLine = textBlock.createTextLine(textLine, maxLineWidth);
				}
				if(!nextTextLine)
				{
					break;
				}
				textLine = nextTextLine;
				measuredRect.width = Math.max(measuredRect.width,textLine.width);
				if(n==0)
					nextY = nextTextLine.totalAscent;
				textLines[n++] = textLine;
				textLine.y = nextY;
				nextY += nextTextLine.textHeight;
				addChild(textLine);
			}
			
			if(textLines.length>0)
			{
				textLine = textLines[textLines.length-1];
				measuredRect.height = textLine.y+textLine.height;
			}
			measuredRect.width = Math.ceil(measuredRect.width);
			lastMeasuredSize = measuredRect;
			return measuredRect;
		}
		
		/**
		 * 释放TextLines
		 */		
		private function releaseTextLines():void
		{
			var n:int = textLines.length;
			for (var i:int = 0; i < n; i++)
			{
				var textLine:TextLine = textLines[i];
				if (textLine)
				{
					if(textLine.parent)
						textLine.parent.removeChild(textLine);
					textLine.userData = null;	
					textLineRecycler.push(textLine);
				}
			}
			textLines.length = 0;
		}
	}
}