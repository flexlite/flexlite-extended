package org.flexlite.domCompile.compiler
{
	
	/**
	 * DXML配置管理器接口
	 * @author dom
	 */
	public interface IDXMLConfig
	{
		/**
		 * 添加一个项目内的自定义组件,若要添加的组件已经存在，则覆盖原始组件。
		 * @param className 组件完整类名
		 * @param superClass 父级完整类名
		 */
		function addComponent(className:String,superClass:String):Component;
		
		/**
		 * 移除一个项目内的自定义组件
		 * @param className 组件完整类名
		 */		
		function removeComponent(className:String):Component;
		
		/**
		 * 是否含有某个组件
		 * @param className 组件完整类名
		 */		
		function hasComponent(className:String):Boolean;
		/**
		 * 检查指定的类名是否存在于配置中，若不存在则执行相应的处理。
		 * @param className 要检查的类名
		 */	
		function checkComponent(className:String):void;
		
		/**
		 * 根据类的短名ID和命名空间获取完整类名(以"."分隔)
		 * @param id 类的短名ID
		 * @param ns 命名空间
		 */				
		function getClassNameById(id:String,ns:Namespace):String;
		
		/**
		 * 根据ID获取对应的默认属性
		 * @param id 类的短名ID
		 * @param ns 命名空间
		 * @return {name:属性名(String),isArray:该属性是否为数组(Boolean)}
		 */		
		function getDefaultPropById(id:String,ns:Namespace):Object;
		
		/**
		 * 获取指定属性的类型,返回基本数据类型："uint","int","Boolean","String","Number","Class"。
		 * @param prop 属性名
		 * @param className 要查询的完整类名
		 * @param value 属性值
		 */			
		function getPropertyType(prop:String,className:String,value:String):String;
	}
}