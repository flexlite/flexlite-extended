package org.flexlite.domUI.managers
{
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.EventPhase;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	
	import org.flexlite.domCore.dx_internal;
	import org.flexlite.domUI.components.Group;
	import org.flexlite.domUI.core.DomGlobals;
	import org.flexlite.domUI.core.IContainer;
	import org.flexlite.domUI.core.IUIComponent;
	import org.flexlite.domUI.core.IVisualElement;
	import org.flexlite.domUI.core.IVisualElementContainer;

	use namespace dx_internal;
	
	/**
	 * 可以多个实例共存的系统管理器
	 * @author dom
	 */	
	public class SystemManager2 extends Group implements ISystemManager
	{
		/**
		 * 构造函数
		 */		
		public function SystemManager2()
		{
			super();
			mouseEnabledWhereTransparent = false;
			addEventListener(Event.ADDED_TO_STAGE,onAddToStage);
			addEventListener(Event.REMOVED_FROM_STAGE,onRemoved);
		}
		/**
		 * 从舞台移除
		 */		
		private function onRemoved(event:Event):void
		{
			var index:int = DomGlobals._systemManagers.indexOf(this);
			if(index!=-1)
				DomGlobals._systemManagers.splice(index,1);
			removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, true);
			removeEventListener(MouseEvent.MOUSE_WHEEL, mouseEventHandler, true);
			removeEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler, true);
			stage.removeEventListener(FocusEvent.MOUSE_FOCUS_CHANGE,mouseFocusChangeHandler);
			stage.removeEventListener(Event.ACTIVATE, activateHandler);
			removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
			stage.removeEventListener(FocusEvent.FOCUS_IN, focusInHandler, true);
		}
		/**
		 * 添加到舞台
		 */		
		private function onAddToStage(event:Event):void
		{
			stage.stageFocusRect=false;
			var index:int = DomGlobals._systemManagers.indexOf(this);
			if(index==-1)
				DomGlobals._systemManagers.push(this);
			addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, true, 1000);
			addEventListener(MouseEvent.MOUSE_WHEEL, mouseEventHandler, true, 1000);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler, true, 1000);
			stage.addEventListener(FocusEvent.MOUSE_FOCUS_CHANGE,mouseFocusChangeHandler);
			stage.addEventListener(Event.ACTIVATE, activateHandler);
			addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown);
			stage.addEventListener(FocusEvent.FOCUS_IN, focusInHandler, true);
		}
		/**
		 * @inheritDoc
		 */
		override public function addEventListener(type:String, listener:Function,
												useCapture:Boolean = false,
												priority:int = 0,
												useWeakReference:Boolean = true/*将弱引用的默认值改成true*/):void
		{
			super.addEventListener(type,listener,useCapture,priority,useWeakReference);
		}
		/**
		 * 屏蔽FP原始的焦点处理过程
		 */		
		private function mouseFocusChangeHandler(event:FocusEvent):void
		{
			if (event.isDefaultPrevented())
				return;
			
			if (event.relatedObject is TextField)
			{
				var tf:TextField = event.relatedObject as TextField;
				if (tf.type == "input" || tf.selectable)
				{
					return;
				}
			}
			event.preventDefault();
		}
		
		/**
		 * 当前的焦点对象。
		 */		
		private var currentFocus:IUIComponent;
		/**
		 * 鼠标按下事件
		 */		
		private function onMouseDown(event:MouseEvent):void
		{
			var focus:IUIComponent = getTopLevelFocusTarget(InteractiveObject(event.target));
			if (!focus)
				return;
			
			if (focus != currentFocus && !(focus is TextField))
			{
				focus.setFocus();
			}
		}
		/**
		 * 焦点改变时更新currentFocus
		 */		
		private function focusInHandler(event:FocusEvent):void
		{
			currentFocus = getTopLevelFocusTarget(InteractiveObject(event.target));
		}
		/**
		 * 获取鼠标按下点的焦点对象
		 */		
		private function getTopLevelFocusTarget(target:InteractiveObject):IUIComponent
		{
			if(!contains(target))
				return null;
			while (target != this)
			{
				if (target is IUIComponent&&
					IUIComponent(target).focusEnabled&&
					IUIComponent(target).enabled)
				{
					return target as IUIComponent;
				}
				target = target.parent;
				if (target == null)
					break;
			}
			return null;
		}
		
		/**
		 * 窗口激活时重新设置焦点
		 */		
		private function activateHandler(event:Event):void
		{
			if(currentFocus)
				currentFocus.setFocus();
		}
		
		/**
		 * 过滤鼠标事件为可以取消的
		 */		
		private function mouseEventHandler(e:MouseEvent):void
		{
			if (!e.cancelable&&e.eventPhase!=EventPhase.BUBBLING_PHASE)
			{
				e.stopImmediatePropagation();
				var cancelableEvent:MouseEvent = null;
				if ("clickCount" in e)
				{
					var mouseEventClass:Class = MouseEvent;
					
					cancelableEvent = new mouseEventClass(e.type, e.bubbles, true, e.localX,
						e.localY, e.relatedObject, e.ctrlKey, e.altKey,
						e.shiftKey, e.buttonDown, e.delta, 
						e["commandKey"], e["controlKey"], e["clickCount"]);
				}
				else
				{
					cancelableEvent = new MouseEvent(e.type, e.bubbles, true, e.localX, 
						e.localY, e.relatedObject, e.ctrlKey, e.altKey,
						e.shiftKey, e.buttonDown, e.delta);
				}
				
				e.target.dispatchEvent(cancelableEvent);               
			}
		}
		
		/**
		 * 过滤键盘事件为可以取消的
		 */		
		private function keyDownHandler(e:KeyboardEvent):void
		{
			if (!e.cancelable)
			{
				switch (e.keyCode)
				{
					case Keyboard.UP:
					case Keyboard.DOWN:
					case Keyboard.PAGE_UP:
					case Keyboard.PAGE_DOWN:
					case Keyboard.HOME:
					case Keyboard.END:
					case Keyboard.LEFT:
					case Keyboard.RIGHT:
					case Keyboard.ENTER:
					{
						e.stopImmediatePropagation();
						var cancelableEvent:KeyboardEvent =
							new KeyboardEvent(e.type, e.bubbles, true, e.charCode, e.keyCode, 
								e.keyLocation, e.ctrlKey, e.altKey, e.shiftKey)              
						e.target.dispatchEvent(cancelableEvent);
					}
				}
			}
		}
		
		override protected function invalidateParentSizeAndDisplayList():void
		{
			super.invalidateParentSizeAndDisplayList();
			dispatchEvent(new Event("invalidateParentSizeAndDisplayList"));
		}
		/**
		 * @inheritDoc
		 */
		override public function set name(value:String):void{}

		private var _popUpContainer:SystemContainer;
		/**
		 * 弹出窗口层容器。
		 */		
		public function get popUpContainer():IContainer
		{
			if (!_popUpContainer)
			{
				_popUpContainer = new SystemContainer(this,
					new QName(dx_internal, "noTopMostIndex"),
					new QName(dx_internal, "topMostIndex"));
			}
			
			return _popUpContainer;
		}
		
		private var _toolTipContainer:SystemContainer;
		/**
		 * 工具提示层容器。
		 */		
		public function get toolTipContainer():IContainer
		{
			if (!_toolTipContainer)
			{
				_toolTipContainer = new SystemContainer(this,
					new QName(dx_internal, "topMostIndex"),
					new QName(dx_internal, "toolTipIndex"));
			}
			
			return _toolTipContainer;
		}
		
		private var _cursorContainer:SystemContainer;
		/**
		 * 鼠标样式层容器。
		 */		
		public function get cursorContainer():IContainer
		{
			if (!_cursorContainer)
			{
				_cursorContainer = new SystemContainer(this,
					new QName(dx_internal, "toolTipIndex"),
					new QName(dx_internal, "cursorIndex"));
			}
			
			return _cursorContainer;
		}
		
		private var _noTopMostIndex:int = 0;
		/**
		 * 弹出窗口层的起始索引(包括)
		 */		
		dx_internal function get noTopMostIndex():int
		{
			return _noTopMostIndex;
		}
		
		dx_internal function set noTopMostIndex(value:int):void
		{
			var delta:int = value - _noTopMostIndex;
			_noTopMostIndex = value;
			topMostIndex += delta;
		}
		
		private var _topMostIndex:int = 0;
		/**
		 * 弹出窗口层结束索引(不包括)
		 */		
		dx_internal function get topMostIndex():int
		{
			return _topMostIndex;
		}
		
		dx_internal function set topMostIndex(value:int):void
		{
			var delta:int = value - _topMostIndex;
			_topMostIndex = value;
			toolTipIndex += delta;
		}
		
		private var _toolTipIndex:int = 0;
		/**
		 * 工具提示层结束索引(不包括)
		 */		
		dx_internal function get toolTipIndex():int
		{
			return _toolTipIndex;
		}
		
		dx_internal function set toolTipIndex(value:int):void
		{
			var delta:int = value - _toolTipIndex;
			_toolTipIndex = value;
			cursorIndex += delta;
		}
		
		private var _cursorIndex:int = 0;
		/**
		 * 鼠标样式层结束索引(不包括)
		 */		
		dx_internal function get cursorIndex():int
		{
			return _cursorIndex;
		}
		
		dx_internal function set cursorIndex(value:int):void
		{
			var delta:int = value - _cursorIndex;
			_cursorIndex = value;
		}
		
		//==========================================================================
		//                                复写容器操作方法
		//==========================================================================
		/**
		 * @inheritDoc
		 */
		override public function addElement(element:IVisualElement):IVisualElement
		{
			var addIndex:int = _noTopMostIndex;
			if (element.parent == this)
				addIndex--;
			return addElementAt(element, addIndex);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function addElementAt(element:IVisualElement,index:int):IVisualElement
		{
			if (element.parent==this)
			{
				var oldIndex:int = getElementIndex(element);
				if(oldIndex<_noTopMostIndex)
					noTopMostIndex--;
				else if(oldIndex>=_noTopMostIndex&&oldIndex<_topMostIndex)
					topMostIndex--;
				else if(oldIndex>=_topMostIndex&&oldIndex<_toolTipIndex)
					toolTipIndex--;
				else 
					cursorIndex--;
			}
			
			if(index<=_noTopMostIndex)
				noTopMostIndex++;
			else if(index>_noTopMostIndex&&index<=_topMostIndex)
				topMostIndex++;
			else if(index>_topMostIndex&&index<=_toolTipIndex)
				toolTipIndex++;
			else 
				cursorIndex++;
			
			return super.addElementAt(element,index);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function removeElement(element:IVisualElement):IVisualElement
		{
			return removeElementAt(super.getElementIndex(element));
		}

		/**
		 * @inheritDoc
		 */
		override public function removeElementAt(index:int):IVisualElement
		{
			var element:IVisualElement = super.removeElementAt(index);
			if(index<_noTopMostIndex)
				noTopMostIndex--;
			else if(index>=_noTopMostIndex&&index<_topMostIndex)
				topMostIndex--;
			else if(index>=_topMostIndex&&index<_toolTipIndex)
				toolTipIndex--;
			else 
				cursorIndex--;
			return element;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function removeAllElements():void
		{
			while(_noTopMostIndex>0)
			{
				super.removeElementAt(0);
				noTopMostIndex--;
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function containsElement(element:IVisualElement):Boolean
		{
			if (super.containsElement(element))
			{
				if (element.parent == this)
				{
					var elementIndex:int = super.getElementIndex(element);
					if (elementIndex < _noTopMostIndex)
						return true;
				}
				else
				{
					for (var i:int = 0; i < _noTopMostIndex; i++)
					{
						var myChild:IVisualElement = super.getElementAt(i);
						if (myChild is IVisualElementContainer)
						{
							if (IVisualElementContainer(myChild).containsElement(element))
								return true;
						}
					}
				}
			}
			return false;
		}
		
		
		override dx_internal function elementRemoved(element:IVisualElement, index:int, notifyListeners:Boolean=true):void
		{
			if(notifyListeners)
			{
				element.dispatchEvent(new Event("removeFromSystemManager"));
			}
			super.elementRemoved(element,index,notifyListeners);
		}
		
		//==========================================================================
		//                                保留容器原始操作方法
		//==========================================================================
		dx_internal function get raw_numElements():int
		{
			return super.numElements;
		}
		dx_internal function raw_getElementAt(index:int):IVisualElement
		{
			return super.getElementAt(index);
		}
		dx_internal function raw_addElement(element:IVisualElement):IVisualElement
		{
			var index:int = super.numElements;
			if (element.parent == this)
				index--;
			return raw_addElementAt(element, index);
		}
		dx_internal function raw_addElementAt(element:IVisualElement, index:int):IVisualElement
		{
			if (element.parent==this)
			{
				var oldIndex:int = getElementIndex(element);
				if(oldIndex<_noTopMostIndex)
					noTopMostIndex--;
				else if(oldIndex>=_noTopMostIndex&&oldIndex<_topMostIndex)
					topMostIndex--;
				else if(oldIndex>=_topMostIndex&&oldIndex<_toolTipIndex)
					toolTipIndex--;
				else 
					cursorIndex--;
			}
			return super.addElementAt(element,index);
		}
		dx_internal function raw_removeElement(element:IVisualElement):IVisualElement
		{
			return super.removeElementAt(super.getElementIndex(element));
		}
		dx_internal function raw_removeElementAt(index:int):IVisualElement
		{
			return super.removeElementAt(index);
		}
		dx_internal function raw_removeAllElements():void
		{
			while(super.numElements>0)
			{
				super.removeElementAt(0);
			}
		}
		dx_internal function raw_getElementIndex(element:IVisualElement):int
		{
			return super.getElementIndex(element);
		}
		dx_internal function raw_setElementIndex(element:IVisualElement, index:int):void
		{
			super.setElementIndex(element,index);
		}
		dx_internal function raw_swapElements(element1:IVisualElement, element2:IVisualElement):void
		{
			super.swapElementsAt(super.getElementIndex(element1), super.getElementIndex(element2));
		}
		dx_internal function raw_swapElementsAt(index1:int, index2:int):void
		{
			super.swapElementsAt(index1,index2);
		}
		dx_internal function raw_containsElement(element:IVisualElement):Boolean
		{
			return super.containsElement(element);
		}
	}
}