package org.flexlite.domCompile.compiler
{
	import flash.utils.Dictionary;
	
	import org.flexlite.domCore.DXML;
	
	/**
	 * DXML配置管理器
	 * @author DOM
	 */
	public class DxmlConfig implements IDxmlConfig
	{
		/**
		 * 构造函数
		 */		
		public function DxmlConfig(manifest:XML)
		{
			parseManifest(manifest);
		}
		
		/**
		 * 组件清单列表
		 */		
		private var componentDic:Dictionary = new Dictionary();
		/**
		 * 框架组件ID到完整类名映射列表
		 */		
		private var idDic:Dictionary = new Dictionary();
		/**
		 * 解析框架清单文件
		 */		
		private function parseManifest(manifest:XML):void
		{
			for each(var item:XML in manifest.component)
			{
				var component:Component = new Component(item);
				componentDic[component.className] = component;
				idDic[component.id] = component.className;
			}
			for each(component in componentDic)
			{
				if(!component.defaultProp)
					findProp(component);
			}
		}
		/**
		 * 递归查找默认属性
		 */		
		private function findProp(component:Component):String
		{
			if(component.defaultProp)
				return component.defaultProp;
			var superComp:Component = componentDic[component.superClass];
			if(superComp)
			{
				var prop:String = findProp(superComp);
				if(prop)
				{
					component.defaultProp = prop;
					component.isArray = superComp.isArray;
				}
			}
			return component.defaultProp;
		}
		
		/**
		 * @inheritDoc
		 */
		public function addComponent(className:String,superClass:String):void
		{
			if(!className)
				return;
			if(superClass==null)
				superClass = "";
			className = className.split("::").join(".");
			superClass = superClass.split("::").join(".");
			var id:String = className;
			var index:int = className.lastIndexOf(".");
			if(index!=-1)
			{
				id = className.substring(index+1);
			}
			var component:Component = new Component();
			component.id = id;
			component.className = className;
			component.superClass = superClass;
			componentDic[className] = component;
		}
		
		/**
		 * @inheritDoc
		 */		
		public function hasComponent(className:String):Boolean
		{
			return componentDic[className];
		}
		
		/**
		 * @inheritDoc
		 */
		public function getClassNameById(id:String, ns:Namespace):String
		{
			var name:String = "";
			if(!ns||isDefaultNs(ns))
			{
				name = idDic[id];
			}
			else
			{
				name = ns.uri;
				name = name.substring(0,name.length-1)+id;
			}
			return name;
		}
		
		/**
		 * 使用框架配置文件的默认命名空间 
		 */		
		private const DEFAULT_NS:Array = 
			[DXML.NS,
				new Namespace("s","library://ns.adobe.com/flex/spark"),
				new Namespace("mx","library://ns.adobe.com/flex/mx"),
				new Namespace("fx","http://ns.adobe.com/mxml/2009")];
		
		/**
		 * 指定的命名空间是否是默认命名空间
		 */		
		private function isDefaultNs(ns:Namespace):Boolean
		{
			for each(var dns:Namespace in DEFAULT_NS)
			{
				if(ns==dns)
					return true;
			}
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getDefaultPropById(id:String, ns:Namespace):Object
		{
			var data:Object = {name:"",isArray:false};
			var className:String = getClassNameById(id,ns);
			var component:Component = componentDic[className];
			while(component)
			{
				if(component.defaultProp)
					break;
				className = component.superClass;
				component = componentDic[className];
			}
			if(!component)
				return data;
			data.name = component.defaultProp;
			data.isArray = component.isArray;
			return data;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getPropertyType(prop:String,className:String,value:String):String
		{
			var type:String = "";
			if(prop=="toolTipClass"||prop=="itemRenderer")
				type = "Class";
			else if(prop=="percentHeight"||prop=="percentWidth")
				type = "Number";
			else if(prop=="skinName"||prop=="itemRendererSkinName")
			{
				if(value.indexOf(".")!=-1)
				{
					type = "Class";
				}
				else
				{
					type = "String";
				}
			}
			else if(isStringKey(prop))
				type = "String";
			else if(value.indexOf("#")==0&&!isNaN(Number("0x"+value.substring(1))))
				type = "uint";
			else if(!isNaN(Number(value)))
				type = "Number";
			else if(value=="true"||value=="false")
				type = "Boolean";
			else
				type = "String";
			return type;
		}
		
		/**
		 * 类型为字符串的属性名列表
		 */		
		private var stringKeyList:Array = ["text","label"];
		/**
		 * 判断一个属性是否是字符串类型。
		 */		
		private function isStringKey(key:String):Boolean
		{
			for each(var str:String in stringKeyList)
			{
				if(str==key)
					return true;
			}
			return false;
		}
	}
}
/**
 * 组件数据对象
 * @author DOM
 */
class Component
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