package org.flexlite.domCompile.compiler
{
	
	/**
	 * DXML配置管理器接口
	 * @author DOM
	 */
	public interface IDxmlConfig
	{
		/**
		 * 添加一个项目内的自定义组件,若要添加的组件已经存在，则覆盖原组件。
		 * @param className 组件完整类名
		 * @param superClass 组件父级完整类名
		 */
		function addComponent(className:String,superClass:String):void;
		
		/**
		 * 是否含有某个组件
		 * @param className 组件完整类名
		 */		
		function hasComponent(className:String):Boolean;
		
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