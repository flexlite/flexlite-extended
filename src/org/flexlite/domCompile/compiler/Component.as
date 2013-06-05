package org.flexlite.domCompile.compiler
{
	
	/**
	 * 组件数据对象
	 * @author DOM
	 */
	public class Component
	{
		/**
		 * 构造函数
		 */	
		public function Component(item:XML=null)
		{
			if(item)
			{
				id = String(item.@id);
				className = String(item.@p);
				if(item.hasOwnProperty("@s"))
					superClass = String(item.@s);
				if(item.hasOwnProperty("@d"))
					defaultProp = String(item.@d);
				if(item.hasOwnProperty("@array"))
					isArray = Boolean(item.@array=="true");
			}
		}
		/**
		 * 短名ID
		 */	
		public var id:String;
		/**
		 * 完整类名
		 */	
		public var className:String;
		/**
		 * 父级类名
		 */	
		public var superClass:String = "";
		/**
		 * 默认属性
		 */	
		public var defaultProp:String = "";
		/**
		 * 默认属性是否为数组类型
		 */	
		public var isArray:Boolean = false;
	}
}