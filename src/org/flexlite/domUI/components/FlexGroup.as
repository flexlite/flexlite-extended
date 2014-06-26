package org.flexlite.domUI.components
{
	import flash.display.DisplayObject;
	import flash.text.TextField;
	
	import mx.core.IIMESupport;
	import mx.core.UIComponent;
	import mx.managers.IFocusManagerComponent;
	
	import org.flexlite.domCore.dx_internal;
	import org.flexlite.domUI.core.IVisualElement;
	import org.flexlite.domUI.core.IVisualElementContainer;
	import org.flexlite.domUI.events.ElementExistenceEvent;
	
	use namespace dx_internal;
	/**
	 * 元素添加事件
	 */	
	[Event(name="elementAdd", type="org.flexlite.domUI.events.ElementExistenceEvent")]
	
	/**
	 * 元素移除事件 
	 */	
	[Event(name="elementRemove", type="org.flexlite.domUI.events.ElementExistenceEvent")]
	
	/**
	 * FlexLite组件在Flex中运行的容器包装器
	 * @author dom
	 */
	public class FlexGroup extends UIComponent implements IFocusManagerComponent,IIMESupport
	{
		/**
		 * 构造函数
		 */		
		public function FlexGroup()
		{
			super();
			contentGroup.addEventListener(
				ElementExistenceEvent.ELEMENT_ADD, contentGroup_elementAddedHandler);
			contentGroup.addEventListener(
				ElementExistenceEvent.ELEMENT_REMOVE, contentGroup_elementRemovedHandler);
			super.addChild(contentGroup);
		}
		
		public function get enableIME():Boolean
		{
			return stage?stage.focus is TextField:false;
		}
		
		private var _imeMode:String = null;
		
		public function get imeMode():String
		{
			return _imeMode;
		}
		public function set imeMode(value:String):void
		{
			_imeMode = value;
		}
		
		/**
		 * 容器添加元素事件
		 */		
		dx_internal function contentGroup_elementAddedHandler(event:ElementExistenceEvent):void
		{
			event.element.ownerChanged(this);
			dispatchEvent(event);
		}
		/**
		 * 容器移除元素事件
		 */		
		dx_internal function contentGroup_elementRemovedHandler(event:ElementExistenceEvent):void
		{
			event.element.ownerChanged(null);
			dispatchEvent(event);
		}
		/**
		 * @inheritDoc
		 */
		override protected function measure():void
		{
			super.measure();
			contentGroup.validateSize(true);
			measuredWidth = contentGroup.preferredWidth;
			measuredHeight = contentGroup.preferredHeight;
		}
		/**
		 * @inheritDoc
		 */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth,unscaledHeight);
			contentGroup.setLayoutBoundsSize(unscaledWidth,unscaledHeight);
		}
		
		/**
		 * 实体容器
		 */		
		private var contentGroup:ContentGroup = new ContentGroup();
		
		/**
		 * 此容器中的可视元素的数量。
		 * 可视元素包括实现 IVisualElement 接口的类，
		 */
		public function get numElements():int
		{
			return contentGroup.numElements;
		}
		/**
		 * 返回指定索引处的可视元素。
		 * @param index 要检索的元素的索引。
		 * @throws RangeError 如果在子列表中不存在该索引位置。
		 */	
		public function getElementAt(index:int):IVisualElement
		{
			return contentGroup.getElementAt(index);
		}
		/**
		 * 将可视元素添加到此容器中。
		 * 如果添加的可视元素已有一个不同的容器作为父项，则该元素将会从其他容器中删除。
		 * @param element 要添加为此容器的子项的可视元素。
		 */	
		public function addElement(element:IVisualElement):IVisualElement
		{
			return contentGroup.addElement(element);
		}
		/**
		 * 将可视元素添加到此容器中。该元素将被添加到指定的索引位置。索引 0 代表显示列表中的第一个元素。 
		 * 如果添加的可视元素已有一个不同的容器作为父项，则该元素将会从其他容器中删除。
		 * @param element 要添加为此可视容器的子项的元素。
		 * @param index 将该元素添加到的索引位置。如果指定当前占用的索引位置，则该位置以及所有更高位置上的子对象会在子级列表中上移一个位置。
		 * @throws RangeError 如果在子列表中不存在该索引位置。
		 */	
		public function addElementAt(element:IVisualElement, index:int):IVisualElement
		{
			return contentGroup.addElementAt(element,index);
		}
		/**
		 * 从此容器的子列表中删除指定的可视元素。
		 * 在该可视容器中，位于该元素之上的所有元素的索引位置都减少 1。
		 * @param element 要从容器中删除的元素。
		 */
		public function removeElement(element:IVisualElement):IVisualElement
		{
			return contentGroup.removeElement(element);
		}
		/**
		 * 从容器中的指定索引位置删除可视元素。
		 * 在该可视容器中，位于该元素之上的所有元素的索引位置都减少 1。
		 * @param index 要删除的元素的索引。
		 * @throws RangeError 如果在子列表中不存在该索引位置。
		 */		
		public function removeElementAt(index:int):IVisualElement
		{
			return contentGroup.removeElementAt(index);
		}
		/**
		 * 从容器中删除所有可视元素。
		 */
		public function removeAllElements():void
		{
			contentGroup.removeAllElements();
		}
		/**
		 * 返回可视元素的索引位置。若不存在，则返回-1。
		 * @param element 可视元素。
		 */	
		public function getElementIndex(element:IVisualElement):int
		{
			return contentGroup.getElementIndex(element);
		}
		/**
		 * 在可视容器中更改现有可视元素的位置。
		 * @param element 要为其更改索引编号的元素。
		 * @param index 元素的最终索引编号。
		 * @throws RangeError 如果在子列表中不存在该索引位置。
		 */
		public function setElementIndex(element:IVisualElement, index:int):void
		{
			contentGroup.setElementIndex(element,index);
		}
		/**
		 * 交换两个指定可视元素的索引。所有其他元素仍位于相同的索引位置。
		 * @param element1 第一个可视元素。
		 * @param element2 第二个可视元素。
		 */	
		public function swapElements(element1:IVisualElement, element2:IVisualElement):void
		{
			contentGroup.swapElements(element1,element2);
		}
		/**
		 * 交换容器中位于两个指定索引位置的可视元素。所有其他可视元素仍位于相同的索引位置。
		 * @param index1 第一个元素的索引。
		 * @param index2 第二个元素的索引。
		 * @throws RangeError 如果在子列表中不存在该索引位置。
		 */
		public function swapElementsAt(index1:int, index2:int):void
		{
			contentGroup.swapElementsAt(index1,index2);
		}
		
		override public function invalidateDisplayList():void
		{
			super.invalidateDisplayList();
			contentGroup.invalidateDisplayList();
		}
		
		override public function invalidateSize():void
		{
			super.invalidateSize();
			contentGroup.invalidateSize();
		}
		/**
		 * 确定指定的 IVisualElement 是否为容器实例的子代或该实例本身。将进行深度搜索，即，如果此元素是该容器的子代、孙代、曾孙代等，它将返回 true。
		 * @param element 要测试的子对象
		 */
		public function containsElement(element:IVisualElement):Boolean
		{
			return contentGroup.containsElement(element);
		}
		
		private static const errorStr:String = "在此组件中不可用，若此组件为容器类，请使用";
		[Deprecated] 
		/**
		 * @copy org.flexlite.domUI.components.Group#addChild()
		 */		
		override public function addChild(child:DisplayObject):DisplayObject
		{
			throw(new Error("addChild()"+errorStr+"addElement()代替"));
		}
		[Deprecated] 
		/**
		 * @copy org.flexlite.domUI.components.Group#addChildAt()
		 */		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			throw(new Error("addChildAt()"+errorStr+"addElementAt()代替"));
		}
		[Deprecated] 
		/**
		 * @copy org.flexlite.domUI.components.Group#removeChild()
		 */		
		override public function removeChild(child:DisplayObject):DisplayObject
		{
			throw(new Error("removeChild()"+errorStr+"removeElement()代替"));
		}
		[Deprecated] 
		/**
		 * @copy org.flexlite.domUI.components.Group#removeChildAt()
		 */		
		override public function removeChildAt(index:int):DisplayObject
		{
			throw(new Error("removeChildAt()"+errorStr+"removeElementAt()代替"));
		}
		[Deprecated] 
		/**
		 * @copy org.flexlite.domUI.components.Group#setChildIndex()
		 */		
		override public function setChildIndex(child:DisplayObject, index:int):void
		{
			throw(new Error("setChildIndex()"+errorStr+"setElementIndex()代替"));
		}
		[Deprecated] 
		/**
		 * @copy org.flexlite.domUI.components.Group#swapChildren()
		 */		
		override public function swapChildren(child1:DisplayObject, child2:DisplayObject):void
		{
			throw(new Error("swapChildren()"+errorStr+"swapElements()代替"));
		}
		[Deprecated] 
		/**
		 * @copy org.flexlite.domUI.components.Group#swapChildrenAt()
		 */		
		override public function swapChildrenAt(index1:int, index2:int):void
		{
			throw(new Error("swapChildrenAt()"+errorStr+"swapElementsAt()代替"));
		}
	}
}

import mx.core.IInvalidating;
import org.flexlite.domUI.components.Group;

class ContentGroup extends Group
{
	/**
	 * 构造函数
	 */	
	public function ContentGroup()
	{
		super();
	}
	/**
	 * @inheritDoc
	 */
	override protected function invalidateParentSizeAndDisplayList():void
	{
		var p:IInvalidating = parent as IInvalidating;
		if (!p)
			return;
		p.invalidateSize();
		p.invalidateDisplayList();
	}
}