package org.flexlite.domUI.components
{
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.Font;
	import flash.text.engine.EastAsianJustifier;
	import flash.text.engine.ElementFormat;
	import flash.text.engine.FontDescription;
	import flash.text.engine.FontLookup;
	import flash.text.engine.FontMetrics;
	import flash.text.engine.Kerning;
	import flash.text.engine.LineJustification;
	import flash.text.engine.SpaceJustifier;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextElement;
	import flash.text.engine.TextLine;
	import flash.text.engine.TextLineValidity;
	
	import org.flexlite.domUI.core.IDisplayText;
	import org.flexlite.domUI.core.UIComponent;
	import org.flexlite.domUI.events.UIEvent;
	import org.flexlite.domUtils.Recycler;
	
	
	/**
	 * 一行或多行不可编辑的文本控件,基于FTE。
	 * @author DOM
	 */	
	public class Text extends UIComponent implements IDisplayText
	{
		/**
		 * 构造函数
		 */		
		public function Text()
		{
			super();
			mouseChildren = false;
			addEventListener(UIEvent.UPDATE_COMPLETE, updateCompleteHandler);
			backgroundShape = new Shape();
			addChild(backgroundShape);
		}
		/**
		 * 显示设置的宽度
		 */		
		private var _widthConstraint:Number = NaN;
		/**
		 * 一次验证过程完成
		 */		
		private function updateCompleteHandler(event:UIEvent):void
		{
			_widthConstraint = NaN;
		}
		
		//类静态属性
		private static var staticTextBlock:TextBlock;
		private static var staticTextElement:TextElement;
		private static var staticSpaceJustifier:SpaceJustifier;
		private static var staticEastAsianJustifier:EastAsianJustifier;
		private static var truncationIndicator:String = "...";
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
			staticTextElement = new TextElement();
			staticSpaceJustifier = new SpaceJustifier();
			staticEastAsianJustifier = new EastAsianJustifier();
			textLineRecycler = new Recycler();
			if ("recreateTextLine" in staticTextBlock)
				recreateTextLine = staticTextBlock["recreateTextLine"];
		}
		//调用初始化静态属性
		initClass();
		
		private var visibleChanged:Boolean = false;
		/**
		 * @inheritDoc
		 */		
		override public function set visible(value:Boolean):void
		{        
			super.visible = value;
			visibleChanged = true;
			invalidateDisplayList();
		}
		
		private var toolTipSet:Boolean = false;
		/**
		 * @inheritDoc
		 */
		override public function set toolTip(value:Object):void
		{
			super.toolTip = value;
			toolTipSet = (value != null);
		}
		
		private var _isTruncated:Boolean = false;
		/**
		 * 文本是否已经被截断的标志。截断文本是指使用"..."替换未显示完全的文本。它与剪裁文本不同，后者只是不显示多余的文本。<p/>
		 * 如果 maxDisplayedLines 为 0，则不会发生截断。相反，如果文本不在组件的界限内，则将只是剪辑文本。<p/>
		 * 如果 maxDisplayedLines 为正整数，则会根据需要截断文本以将行数减少至此整数。<p/>
		 * 如果 maxDisplayedLines 为 -1，则会截断该文本以显示将完全放在组件的高度内的行。<p/>
		 */		
		public function get isTruncated():Boolean
		{
			return _isTruncated;
		}
		/**
		 * 设置isTruncated的值，并抛出事件。
		 */		
		private function setIsTruncated(value:Boolean):void
		{
			if (_isTruncated == value)
				return;
			_isTruncated = value;
			if (!toolTipSet)
				super.toolTip = _isTruncated ? text : null;
			dispatchEvent(new Event("isTruncatedChanged"));
		}
		
		private var _maxDisplayedLines:int = -1;
		/**
		 * 确定是否截断文本以及在何处截断文本的整数。默认值：-1。 <br/>
		 * 截断文本意味着使用截断指示符（如 "..."）替换超额文本。截断指示符与区域设置相关；
		 * 它是由 "core" 资源包中的 "truncationIndicator" 资源指定的。<p/>
		 * 如果值为 0，则不会发生截断。相反，如果文本不在组件的界限内，则将只是剪辑文本。<p/>
		 * 如果值为正整数，则会根据需要截断文本以将行数减少至此整数。<p/>
		 * 如果值为 -1，则会截断该文本以显示将完全放在组件的高度内的行。<p/>
		 */		
		public function get maxDisplayedLines():int
		{
			return _maxDisplayedLines;
		}
		public function set maxDisplayedLines(value:int):void
		{
			if (value == _maxDisplayedLines)
				return;
			_maxDisplayedLines = value;
			invalidateTextLines();
			invalidateSize();
			invalidateDisplayList();
		}
		
		/**
		 * 需要从新生成TextLine的标志
		 */		
		private var invalidateCompose:Boolean = true; 
		
		private function invalidateTextLines():void
		{
			invalidateCompose = true;
		}
		
		private var _text:String = "";
		/**
		 * @inheritDoc
		 */
		public function get text():String 
		{
			return _text;
		}
		public function set text(value:String):void
		{
			if (value == _text)
				return;
			_text = value;
			invalidateTextLines();
			invalidateSize();
			invalidateDisplayList();
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
			invalidateTextLines();
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
		
		private var _verticalAlign:String = "top";
		/**
		 * 垂直对齐方式,支持VerticalAlign.TOP,VerticalAlign.BOTTOM,VerticalAlign.MIDDLE和VerticalAlign.JUSTIFY(两端对齐);
		 * 默认值：VerticalAlign.TOP。
		 */
		public function get verticalAlign():String
		{
			return _verticalAlign;
		}
		public function set verticalAlign(value:String):void
		{
			if(_verticalAlign==value)
				return;
			_verticalAlign = value;
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
		 * 字体名称。默认值：Arial
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
		
		private var _underline:Boolean = false;
		/**
		 * 是否有下划线,默认false。
		 */
		public function get underline():Boolean
		{
			return _underline;
		}
		public function set underline(value:Boolean):void
		{
			if(_underline==value)
				return;
			_underline = value;
			invalidateFormat();
		}
		
		private var _lineHeight:Object = "120%";
		/**
		 * 行高。可以使用百分比字符串或者Number,默认值：120%。
		 */
		public function get lineHeight():Object
		{
			return _lineHeight;
		}
		public function set lineHeight(value:Object):void
		{
			if(_lineHeight==value)
				return;
			_lineHeight = value;
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
		
		private var _lineThrough:Boolean=false;
		/**
		 * 是否有删除线。
		 */		
		public function get lineThrough():Boolean
		{
			return _lineThrough;
		}
		public function set lineThrough(value:Boolean):void
		{
			if(_lineThrough==value)
				return;
			_lineThrough = value;
			invalidateFormat();
		}
		
		private var _paddingBottom:Number=0;
		/**
		 * 文字距离下边缘的内边距
		 */
		public function get paddingBottom():Number
		{
			return _paddingBottom;
		}
		public function set paddingBottom(value:Number):void
		{
			if(_paddingBottom==value)
				return;
			_paddingBottom = value;
			invalidateTextLines();
			invalidateSize();
			invalidateDisplayList();
		}
		
		private var _paddingLeft:Number=0;
		/**
		 * 文字距离左边缘的内边距
		 */
		public function get paddingLeft():Number
		{
			return _paddingLeft;
		}
		public function set paddingLeft(value:Number):void
		{
			if(_paddingLeft==value)
				return;
			_paddingLeft = value;
			invalidateTextLines();
			invalidateSize();
			invalidateDisplayList();
		}
		
		private var _paddingRight:Number=0;
		/**
		 * 文字距离右边缘的内边距
		 */
		public function get paddingRight():Number
		{
			return _paddingRight;
		}
		public function set paddingRight(value:Number):void
		{
			if(_paddingRight==value)
				return;
			_paddingRight = value;
			invalidateTextLines();
			invalidateSize();
			invalidateDisplayList();
		}
		
		private var _paddingTop:Number=0;
		/**
		 * 文字距离上边缘的内边距
		 */
		public function get paddingTop():Number
		{
			return _paddingTop;
		}
		public function set paddingTop(value:Number):void
		{
			if(_paddingTop==value)
				return;
			_paddingTop = value;
			invalidateTextLines();
			invalidateSize();
			invalidateDisplayList();
		}
		
		/**
		 * 创建textLines时所用的边界矩形。
		 */		
		private var bounds:Rectangle = new Rectangle(0, 0, NaN, NaN);
		/**
		 * TextLine对象列表
		 */		
		private var textLines:Vector.<DisplayObject> = new Vector.<DisplayObject>();
		
		private var _measuredOneTextLine:Boolean = false;
		/**
		 * @inheritDoc
		 */
		override protected function measure():void
		{
			var constrainedWidth:Number =
				!isNaN(_widthConstraint) ? _widthConstraint : explicitWidth;
			var allLinesComposed:Boolean =
				composeTextLines(Math.max(constrainedWidth, size), Math.max(explicitHeight, size));
			invalidateDisplayList();
			var newMeasuredHeight:Number = Math.ceil(bounds.bottom);
			if (!isNaN(_widthConstraint) && measuredHeight == newMeasuredHeight)
				return;
			super.measure();
			
			measuredWidth = Math.ceil(bounds.right);
			measuredHeight = newMeasuredHeight;
			_measuredOneTextLine = allLinesComposed && 
				textLines.length == 1; 
		}
		/**
		 * @inheritDoc
		 */
		override public function setLayoutBoundsSize(width:Number,height:Number):void
		{
			super.setLayoutBoundsSize(width, height);
			if (_widthConstraint == width)
				return;
			if (canSkipMeasurement())
				return;
			if (!isNaN(explicitHeight))
				return;
			var constrainedWidth:Boolean = !isNaN(width) && (width != measuredWidth) && (width != 0); 
			if (!constrainedWidth)
				return;
			if (_measuredOneTextLine && width > measuredWidth)
				return;
			_widthConstraint = width;
			invalidateSize();
		}
		
		/**
		 * 文本需要剪裁的标志
		 */		
		private var isOverset:Boolean = false;
		/**
		 * 文本背景显示对象
		 */		
		private var backgroundShape:Shape;
		/**
		 * @inheritDoc
		 */
		override protected function updateDisplayList(unscaledWidth:Number, 
													  unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			var compose:Boolean = false;
			var clipText:Boolean = false;
			var contentHeight:Number = Math.ceil(bounds.bottom);
			var contentWidth:Number = Math.ceil(bounds.right);
			if (invalidateCompose || 
				composeForAlignStyles(unscaledWidth, unscaledHeight, contentWidth, contentHeight))
			{
				compose = true;
			}
			else if (unscaledHeight != contentHeight)
			{
				
				if (composeOnHeightChange(unscaledHeight, contentHeight))
				{
					compose = true;
				}
				else if (unscaledHeight < contentHeight)
				{
					clipText = true;                   
				}
			}
			if (!compose && unscaledWidth != contentWidth)
			{
				if (composeOnWidthChange(unscaledWidth, contentWidth))
				{
					compose = true;
				}
			}
			if (compose)
				composeTextLines(unscaledWidth, unscaledHeight);
			if (isOverset)
				clipText = true;
			clip(clipText, unscaledWidth, unscaledHeight);
			
			var g:Graphics = backgroundShape.graphics;
			g.clear();
			g.beginFill(0xFFFFFF,0);
			g.drawRect(0,0,unscaledWidth,unscaledHeight);
			g.endFill();
		}
		
		private var _composeWidth:Number;
		private var _composeHeight:Number;
			
		private function composeForAlignStyles(unscaledWidth:Number, 
											   unscaledHeight:Number,
											   contentWidth:Number,
											   contentHeight:Number):Boolean
		{
			var width:Number = isNaN(_composeWidth) ? 
				contentWidth : _composeWidth;
			if (unscaledWidth != width)
			{
				if (textAlign != "left")
					return true;
			}
			var height:Number = isNaN(_composeHeight) ? 
				contentHeight : _composeHeight;
			if (unscaledHeight != height)
			{
				var topAligned:Boolean = (verticalAlign == "top");
				
				if (!topAligned)
					return true;
			}
			
			return false;   
		}

		private function composeOnHeightChange(unscaledHeight:Number,
											   contentHeight:Number):Boolean
		{
			if (unscaledHeight > contentHeight &&
				(isOverset || !isNaN(_composeHeight)))
				return true;
			
			if (maxDisplayedLines != 0)
			{
				
				if (maxDisplayedLines == -1)            
					return true;
				if (maxDisplayedLines > 0 &&
					(unscaledHeight < contentHeight ||
						textLines.length != maxDisplayedLines))
				{
					return true;
				}
			}
			
			return false;                
		}
		
		private function composeOnWidthChange(unscaledWidth:Number, 
											  contentWidth:Number):Boolean
		{
			if (isNaN(_composeWidth) || _composeWidth != unscaledWidth)
				return true;
			return false;
		}
		/**
		 * 添加TextLines到显示列表
		 */		
		private function addTextLines():void
		{
			var n:int = textLines.length;
			if (n == 0)
				return;
			
			for (var i:int = n - 1; i >= 0; i--)
			{
				var textLine:DisplayObject = textLines[i];		
				
				addChildAt(textLine, 1);
			}
		}
		/**
		 * 从显示列表移除TextLines
		 */		
		private function removeTextLines():void
		{
			var n:int = textLines.length;		
			if (n == 0)
				return;
			
			for (var i:int = 0; i < n; i++)
			{
				var textLine:DisplayObject = textLines[i];	
				var parent:UIComponent = textLine.parent as UIComponent;
				if (parent)
					UIComponent(textLine.parent).removeChild(textLine);
			}
		}
		/**
		 * 释放TextLines
		 */		
		private function releaseTextLines(
			textLinesVector:Vector.<DisplayObject> = null):void
		{
			if (!textLinesVector)
				textLinesVector = textLines;
			
			var n:int = textLinesVector.length;
			for (var i:int = 0; i < n; i++)
			{
				var textLine:TextLine = textLinesVector[i] as TextLine;
				if (textLine)
				{
					if (textLine.validity != TextLineValidity.INVALID && 
						textLine.validity != TextLineValidity.STATIC)
					{
						textLine.validity = TextLineValidity.INVALID;
					}
					
					textLine.userData = null;	
					textLineRecycler.push(textLine);
				}
			}
			
			textLinesVector.length = 0;
		}
		/**
		 * 检查文本是否超出边界
		 */		
		private function isTextOverset(composeWidth:Number, 
									   composeHeight:Number):Boolean
		{        
			
			var compositionRect:Rectangle =
				new Rectangle(0, 0, composeWidth, composeHeight);
			compositionRect.inflate(0.25, 0.25);
			var contentRect:Rectangle = bounds;
			var isOverset:Boolean = (contentRect.top < compositionRect.top || 
				contentRect.left < compositionRect.left ||
				(!isNaN(compositionRect.bottom) &&
					contentRect.bottom > compositionRect.bottom) ||
				(!isNaN(compositionRect.right) &&
					contentRect.right > compositionRect.right));
			return isOverset;                                                     
		} 
		/**
		 * 设置了scrollRect的标志
		 */		
		private var hasScrollRect:Boolean = false;
		/**
		 * 剪裁文本显示区域
		 */		
		private function clip(clipText:Boolean, w:Number, h:Number):void
		{
			
			if (clipText)
			{
				var r:Rectangle = scrollRect;
				if (r)
				{
					r.x = 0;
					r.y = 0;
					r.width = w;
					r.height = h;
				}
				else
				{
					r = new Rectangle(0, 0, w, h);
				}
				scrollRect = r;
				hasScrollRect = true;
			}
			else if (hasScrollRect)
			{
				scrollRect = null;
				hasScrollRect = false;
			}
		}
		
		/**
		 * 生成TextLine对象列表
		 */		
		private function composeTextLines(width:Number = NaN,
										  height:Number = NaN):Boolean
		{
			_composeWidth = width;
			_composeHeight = height;
			
			setIsTruncated(false);
			
			if (!elementFormat)
				elementFormat = createElementFormat(); 
			bounds.x = 0;
			bounds.y = 0;
			bounds.width = width;
			bounds.height = height;
			removeTextLines();
			releaseTextLines();
			var allLinesComposed:Boolean = createTextLines(elementFormat);
			if (text != null && text.length > 0 &&
				maxDisplayedLines &&
				!doesComposedTextFit(height, width, allLinesComposed, maxDisplayedLines))
			{
				truncateText(width, height);
			}
			releaseLinesFromTextBlock();
			addTextLines();
			isOverset = isTextOverset(width, height);
			invalidateCompose = false;     
			
			return allLinesComposed;           
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
		
		/**
		 * 创建指定文本格式的TextLine对象
		 */		
		private function createTextLines(elementFormat:ElementFormat):Boolean
		{
			staticTextElement.text = text != null && text.length > 0 ? text : "\u2029";
			staticTextElement.elementFormat = elementFormat;
			staticTextBlock.content = staticTextElement;
			staticTextBlock.bidiLevel = 0;
			var lineJustification:String;
			if (textAlign == "justify")
			{
				lineJustification = LineJustification.ALL_INCLUDING_LAST;
			}
			else
			{
				lineJustification = LineJustification.UNJUSTIFIED;
			}
			staticSpaceJustifier.lineJustification = lineJustification;
			staticTextBlock.textJustifier = staticSpaceJustifier;
			return createTextLinesFromTextBlock(staticTextBlock, textLines, bounds);
		}
		/**
		 * 从TextBlock对象生成TextLine列表
		 */		
		private function createTextLinesFromTextBlock(textBlock:TextBlock,
													  textLines:Vector.<DisplayObject>,
													  bounds:Rectangle):Boolean
		{
			
			releaseTextLines(textLines);
			
			var innerWidth:Number = bounds.width - _paddingLeft - _paddingRight;
			var innerHeight:Number = bounds.height - _paddingTop - _paddingBottom;
			
			var measureWidth:Boolean = isNaN(innerWidth);
			if (measureWidth)
				innerWidth = maxWidth;
			
			var maxLineWidth:Number = innerWidth;
			
			if (innerWidth < 0 || innerHeight < 0 || !textBlock)
			{
				bounds.width = 0;
				bounds.height = 0;
				return false;
			}
			
			var fontSize:Number = staticTextElement.elementFormat.fontSize;
			var actualLineHeight:Number;
			if (_lineHeight is Number)
			{
				actualLineHeight = Number(_lineHeight);
			}
			else if (_lineHeight is String)
			{
				var len:int = _lineHeight.length;
				var percent:Number =
					Number(String(_lineHeight).substring(0, len - 1));
				actualLineHeight = percent / 100 * fontSize;
			}
			if (isNaN(actualLineHeight))
				actualLineHeight = 1.2 * fontSize;
			
			var maxTextWidth:Number = 0;
			var totalTextHeight:Number = 0;
			var n:int = 0;
			var nextTextLine:TextLine;
			var nextY:Number = 0;
			var textLine:TextLine;
			
			var createdAllLines:Boolean = false;
			var extraLine:Boolean;
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
					nextTextLine = textBlock.createTextLine(
						textLine, maxLineWidth);
				}
				if (!nextTextLine)
				{
					createdAllLines = !extraLine;
					break;
				}
				nextY += (n == 0 ? nextTextLine.ascent : actualLineHeight);
				if (verticalAlign == "top" && 
					nextY - nextTextLine.ascent > innerHeight)
				{
					
					if (!extraLine) 
						extraLine = true;
					else
						break;
				}
				textLine = nextTextLine;
				textLines[n++] = textLine;
				textLine.y = nextY;
				maxTextWidth = Math.max(maxTextWidth, textLine.textWidth);
				totalTextHeight += textLine.textHeight;
				
				if (_lineThrough || _underline)
				{
					var elementFormat:ElementFormat =
						TextElement(textBlock.content).elementFormat;
					var fontMetrics:FontMetrics;
					fontMetrics = elementFormat.getFontMetrics();
					
					var shape:Shape = new Shape();
					var g:Graphics = shape.graphics;
					if (_lineThrough)
					{
						g.lineStyle(fontMetrics.strikethroughThickness, 
							elementFormat.color, elementFormat.alpha);
						g.moveTo(0, fontMetrics.strikethroughOffset);
						g.lineTo(textLine.textWidth, fontMetrics.strikethroughOffset);
					}
					if (_underline)
					{
						g.lineStyle(fontMetrics.underlineThickness, 
							elementFormat.color, elementFormat.alpha);
						g.moveTo(0, fontMetrics.underlineOffset);
						g.lineTo(textLine.textWidth, fontMetrics.underlineOffset);
					}
					
					textLine.addChild(shape);
				}
			}
			if (n == 0)
			{
				bounds.width = _paddingLeft + _paddingRight;
				bounds.height = _paddingTop + _paddingBottom;
				return false;
			}
			if (measureWidth)
				innerWidth = maxTextWidth;
			
			if (isNaN(bounds.height))
				innerHeight = textLine.y + textLine.descent;
			innerWidth = Math.ceil(innerWidth);
			innerHeight = Math.ceil(innerHeight);
			
			var leftAligned:Boolean = 
				textAlign == "left" ||
				textAlign == "justify";
			var centerAligned:Boolean = textAlign == "center";
			var rightAligned:Boolean = textAlign == "right"; 
			var leftOffset:Number = bounds.left + _paddingLeft;
			var centerOffset:Number = leftOffset + innerWidth / 2;
			var rightOffset:Number =  leftOffset + innerWidth;
			var topOffset:Number = bounds.top + _paddingTop;
			var bottomOffset:Number = innerHeight - (textLine.y + textLine.descent);
			var middleOffset:Number = bottomOffset / 2;
			bottomOffset += topOffset;
			middleOffset += topOffset;
			var leading:Number = (innerHeight - totalTextHeight) / (n - 1);
			
			var previousTextLine:TextLine;
			var y:Number = 0;
			
			var minX:Number = innerWidth;
			var minY:Number = innerHeight;
			var maxX:Number = 0;
			
			var clipping:Boolean = (n) ? (textLines[n - 1].y + TextLine(textLines[n - 1]).descent > innerHeight) : false;
			for (var i:int = 0; i < n; i++)
			{
				textLine = TextLine(textLines[i]);
				
				if (leftAligned)
					textLine.x = leftOffset;
				else if (centerAligned)
					textLine.x = centerOffset - textLine.textWidth / 2;
				else if (rightAligned)
					textLine.x = rightOffset - textLine.textWidth;            
				
				if (verticalAlign == "top" || !createdAllLines || clipping)
				{
					textLine.y += topOffset;
				}
				else if (verticalAlign == "middle")
				{
					textLine.y += middleOffset;
				}
				else if (verticalAlign == "bottom")
				{
					textLine.y += bottomOffset;
				}
				else if (verticalAlign == "justify")
				{
					y += i == 0 ?
						topOffset + textLine.ascent :
						previousTextLine.descent + leading + textLine.ascent;
					
					textLine.y = y;
					previousTextLine = textLine;
				}
				minX = Math.min(minX, textLine.x);             
				minY = Math.min(minY, textLine.y - textLine.ascent);
				maxX = Math.max(maxX, textLine.x + textLine.textWidth); 
			}
			
			bounds.x = minX - _paddingLeft;
			bounds.y = minY - _paddingTop;
			bounds.right = maxX + _paddingRight;
			bounds.bottom = textLine.y + textLine.descent + _paddingBottom;
			
			return createdAllLines;
		}
		/**
		 * 检查文本是否能放进指定的尺寸和行数内
		 */		
		private function doesComposedTextFit(height:Number, width:Number,
											 createdAllLines:Boolean,
											 lineCountLimit:int):Boolean
		{
			
			if (!createdAllLines)
				return false;
			if (lineCountLimit != -1 && textLines.length > lineCountLimit)
				return false;
			
			if (textLines.length <= 1 || isNaN(height))
				return true;
			var lastLine:TextLine = TextLine(textLines[textLines.length - 1]);        
			var lastLineExtent:Number = lastLine.y + lastLine.descent;
			
			return lastLineExtent <= height;
		}
		/**
		 * 根据指定尺寸截断文本
		 */		
		private function truncateText(width:Number, height:Number):void
		{
			var lineCountLimit:int = maxDisplayedLines;
			var somethingFit:Boolean = false;
			var truncLineIndex:int = 0;    
			
			truncLineIndex = computeLastAllowedLineIndex(height, lineCountLimit);
			var extraLine:Boolean;
			if (truncLineIndex + 1 < textLines.length)
			{
				truncLineIndex++;
				extraLine = true;
			}
			
			if (truncLineIndex >= 0)
			{
				staticTextElement.text = truncationIndicator;
				var indicatorLines:Vector.<DisplayObject> =
					new Vector.<DisplayObject>();
				var indicatorBounds:Rectangle = new Rectangle(0, 0, width, NaN);
				
				var indicatorFits:Boolean = createTextLinesFromTextBlock(staticTextBlock, 
					indicatorLines, 
					indicatorBounds);
				
				releaseLinesFromTextBlock();
				truncLineIndex -= (indicatorLines.length - 1);
				if (truncLineIndex >= 0 && indicatorFits)
				{
					var measuredTextLine:TextLine = 
						TextLine(indicatorLines[indicatorLines.length - 1]);      
					var allowedWidth:Number = 
						measuredTextLine.specifiedWidth -
						measuredTextLine.unjustifiedTextWidth;                          
					
					measuredTextLine = null;                                        
					releaseTextLines(indicatorLines);
					var truncateAtCharPosition:int = getTruncationPosition(
						TextLine(textLines[truncLineIndex]), allowedWidth, extraLine);
					do
					{
						var truncText:String = text.slice(0, truncateAtCharPosition) +
							truncationIndicator;
						bounds.x = 0;
						bounds.y = 0;
						bounds.width = width;
						bounds.height = height;
						
						staticTextElement.text = truncText;
						
						var createdAllLines:Boolean = createTextLinesFromTextBlock(
							staticTextBlock, textLines, bounds);
						
						if (doesComposedTextFit(height, width,
							createdAllLines, 
							lineCountLimit))
							
						{
							somethingFit = true;
							break; 
						}       
						if (truncateAtCharPosition == 0)
							break;
						var oldCharPosition:int = truncateAtCharPosition;
						truncateAtCharPosition = getNextTruncationPosition(
							truncLineIndex, truncateAtCharPosition);  
						
						if (oldCharPosition == truncateAtCharPosition)
							break;
					}
					while (true);
				}
			}
			if (!somethingFit)
			{
				releaseTextLines();
				
				bounds.x = 0;
				bounds.y = 0;
				bounds.width = _paddingLeft + _paddingRight;
				bounds.height = _paddingTop + _paddingBottom;
			}
			setIsTruncated(true);
		}
		/**
		 * 根据指定的高度和行数限制计算出最后一行索引
		 */		
		private function computeLastAllowedLineIndex(height:Number,
													 lineCountLimit:int):int
		{           
			var truncationLineIndex:int = textLines.length - 1;
			
			if (truncationLineIndex < 0)
				return truncationLineIndex;
			
			if (!isNaN(height))
			{
				do
				{
					var textLine:TextLine = TextLine(textLines[truncationLineIndex]);
					if (textLine.y + textLine.descent <= height)
						break;
					
					truncationLineIndex--;
				}
				while (truncationLineIndex >= 0);
			}   
			if (lineCountLimit != -1 && lineCountLimit <= truncationLineIndex)
				truncationLineIndex = lineCountLimit - 1;            
			
			return truncationLineIndex;            
		}
		/**
		 * 获取文本截断位置
		 */		
		private function getTruncationPosition(line:TextLine, 
											   allowedWidth:Number, 
											   extraLine:Boolean):int
		{           
			var consumedWidth:Number = 0;
			var charPosition:int = line.textBlockBeginIndex;
			
			while (charPosition < line.textBlockBeginIndex + line.rawTextLength)
			{
				var atomIndex:int = line.getAtomIndexAtCharIndex(charPosition);
				if (extraLine)
				{
					
					if (charPosition != line.textBlockBeginIndex &&
						line.getAtomWordBoundaryOnLeft(atomIndex))
					{
						break;
					}
				}
				else
				{
					var atomBounds:Rectangle = line.getAtomBounds(atomIndex); 
					consumedWidth += atomBounds.width;
					if (consumedWidth > allowedWidth)
						break;
				}
				
				charPosition = line.getAtomTextBlockEndIndex(atomIndex);
			}
			
			return charPosition;
		}
		/**
		 * 获取下一个文本截断位置
		 */		
		private function getNextTruncationPosition(truncationLineIndex:int,
												   truncateAtCharPosition:int):int
		{
			truncateAtCharPosition--; 
			var line:TextLine = TextLine(textLines[truncationLineIndex]);
			do
			{
				if (truncateAtCharPosition >= line.textBlockBeginIndex && 
					truncateAtCharPosition < line.textBlockBeginIndex + line.rawTextLength)
				{
					break;
				}
				
				if (truncateAtCharPosition < line.textBlockBeginIndex)
				{
					truncationLineIndex--;
					if (truncationLineIndex < 0)
						return truncateAtCharPosition;
				}
				else
				{
					truncationLineIndex++;
					if (truncationLineIndex >= textLines.length)
						return truncateAtCharPosition;
				}
				
				line = TextLine(textLines[truncationLineIndex]);
			}
			while (true);
			var atomIndex:int = 
				line.getAtomIndexAtCharIndex(truncateAtCharPosition);
			var nextTruncationPosition:int = 
				line.getAtomTextBlockBeginIndex(atomIndex);
			
			return nextTruncationPosition;
		}
		/**
		 * 从TextBlock里释放TextLine对象。
		 */		
		private function releaseLinesFromTextBlock():void
		{
			var firstLine:TextLine = staticTextBlock.firstLine;
			var lastLine:TextLine = staticTextBlock.lastLine;
			
			if (firstLine)
				staticTextBlock.releaseLines(firstLine, lastLine);        
		}
	}
	
}
