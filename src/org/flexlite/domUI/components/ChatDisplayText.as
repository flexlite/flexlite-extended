package org.flexlite.domUI.components
{
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	import flash.text.Font;
	import flash.text.engine.ContentElement;
	import flash.text.engine.ElementFormat;
	import flash.text.engine.FontDescription;
	import flash.text.engine.FontLookup;
	import flash.text.engine.GraphicElement;
	import flash.text.engine.GroupElement;
	import flash.text.engine.Kerning;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextElement;
	import flash.text.engine.TextLine;
	
	import org.flexlite.domCore.dx_internal;
	import org.flexlite.domUI.core.UIComponent;
	import org.flexlite.domUI.events.UIEvent;
	import org.flexlite.domUtils.Recycler;
	
	
	use namespace dx_internal;
	
	/**
	 * 聊天图文混排文本
	 * @author dom
	 */
	public class ChatDisplayText extends UIComponent
	{
		public function ChatDisplayText()
		{
			super();
			mouseChildren = false;
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
		 * 注意：若要表示单独的"["，请使用"[["代替，避免被转义,而"]"符不需要特殊写法。
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
		
		
		private var _textAlign:String = "left";
		/**
		 * 文字的水平对齐方式 ,请使用TextFormatAlign中定义的常量。
		 * 默认值：TextFormatAlign.LEFT。
		 */		
		public function get textAlign():String
		{
			return _textAlign;
		}
		
		public function set textAlign(value:String):void
		{
			if(_textAlign==value)
				return;
			_textAlign = value;
			invalidateFormat();
		}
		
		private var _size:int = 12;
		/**
		 * 字号大小，默认值：12。
		 */		
		public function get size():int
		{
			return _size;
		}
		public function set size(value:int):void
		{
			if(_size==value)
				return;
			_size = value;
			invalidateFormat();
		}
		
		private var _textColor:uint=0x000000;
		/**
		 * @inheritDoc
		 */
		public function get textColor():uint
		{
			return _textColor;
		}
		
		public function set textColor(value:uint):void
		{
			if(_textColor==value)
				return;
			_textColor = value;
			invalidateFormat();
		}
		/**
		 * 是否使用嵌入字体
		 */		
		private var fontLookup:String = FontLookup.DEVICE;
		
		private var _fontFamily:String="SimSun";
		/**
		 * 字体名称。默认值：SimSun
		 */	
		public function get fontFamily():String
		{
			return _fontFamily;
		}
		public function set fontFamily(value:String):void
		{
			if(_fontFamily==value)
				return;
			_fontFamily = value;
			var fontList:Array = Font.enumerateFonts(false);
			fontLookup = FontLookup.DEVICE;
			for each(var font:Font in fontList)
			{
				if(font.fontName==value)
				{
					fontLookup = FontLookup.EMBEDDED_CFF;
					break;
				}
			}
			invalidateFormat();
		}
		
		private var _italic:Boolean = false;
		
		/**
		 * 是否为斜体,默认false。
		 */
		public function get italic():Boolean
		{
			return _italic;
		}
		
		public function set italic(value:Boolean):void
		{
			if(_italic==value)
				return;
			_italic = value;
			invalidateFormat();
		}
		
		private var _bold:Boolean = false;
		
		/**
		 * 是否为粗体,默认false。
		 */
		public function get bold():Boolean
		{
			return _bold;
		}
		public function set bold(value:Boolean):void
		{
			if(_bold==value)
				return;
			_bold = value;
			invalidateFormat();
		}
		
		private var _leading:int = 2;
		/**
		 * 行距,默认值为2。
		 */
		public function get leading():int
		{
			return _leading;
		}
		
		public function set leading(value:int):void
		{
			if(_leading==value)
				return;
			_leading = value;
			invalidateFormat();
		}
		
		private var _letterSpacing:Number = 0;
		/**
		 * 字符间距,默认值为0。
		 */
		public function get letterSpacing():Number
		{
			return _letterSpacing;
		}
		public function set letterSpacing(value:Number):void
		{
			if(_letterSpacing==value)
				return;
			_letterSpacing = value;
			invalidateFormat();
		}
		
		/**
		 * 文本格式对象
		 */		
		private var elementFormat:ElementFormat;
		/**
		 * 标记文本格式发生改变
		 */		
		private function invalidateFormat():void
		{
			elementFormat = null;
			invalidateSize();
			invalidateDisplayList();
		}
		
		/**
		 * 创建文本格式对象
		 */		
		private function createElementFormat():ElementFormat
		{
			var fontStyle:String = _italic?"italic":"normal";
			var fontWeight:String = _bold?"bold":"normal";
			var fontDescription:FontDescription = new FontDescription(_fontFamily,fontWeight,fontStyle,fontLookup);
			var elementFormat:ElementFormat = new ElementFormat();
			elementFormat.fontSize = size;
			elementFormat.color = _textColor;
			elementFormat.kerning = Kerning.AUTO;
			elementFormat.fontDescription = fontDescription;
			
			var tracking:Number = isNaN(_letterSpacing)?0:_letterSpacing;
			if(_textAlign=="left")
			{
				elementFormat.trackingRight = tracking;
			}
			else if(_textAlign=="right")
			{
				elementFormat.trackingLeft = tracking;
			}
			else
			{
				elementFormat.trackingLeft = tracking*0.5;
				elementFormat.trackingRight = tracking*0.5;
			}
			
			return elementFormat;
		}
		
		
		private var contentElement:ContentElement;
		
		/**
		 * TextLine对象列表
		 */		
		dx_internal var textLines:Vector.<TextLine> = new Vector.<TextLine>();
		
		private var textLinesIsDirty:Boolean = false;

		override protected function commitProperties():void
		{
			super.commitProperties();
			if(!elementFormat)
			{
				elementFormat = createElementFormat();
				textChanged = true;
			}
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
					if(quote=="["&&text.charAt(0)==quote)
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
							quote = "[";
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
						var textElement:TextElement = new TextElement(text,elementFormat);
						list.push(textElement);
						text = "";
					}
					var graphicElement:GraphicElement = new GraphicElement(dp,dp.width,dp.height,elementFormat);
					list.push(graphicElement);
				}
				else
				{
					text += line;
				}
			}
			if(text)
			{
				textElement = new TextElement(text,elementFormat);
				list.push(textElement);
				text = "";
			}
			if(list.length==1)
				return list[0];
			if(list.length>1)
			{
				var groupElement:GroupElement = new GroupElement(list,elementFormat);
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
		protected function createTextLines(maxLineWidth:Number):Rectangle
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
			if(!contentElement)
				return measuredRect;
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
				nextY += nextTextLine.totalAscent;
				textLines[n++] = textLine;
				textLine.y = nextY;
				nextY += nextTextLine.totalDescent+_leading;
				addToDisplayListAt(textLine,0);
			}
			
			if(textLines.length>0)
			{
				textLine = textLines[textLines.length-1];
				measuredRect.height = Math.ceil(textLine.y+textLine.totalDescent);
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