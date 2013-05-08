package org.flexlite.domCompile.compiler
{
	import flash.utils.Dictionary;
	
	import org.flexlite.domCompile.consts.KeyWords;
	import org.flexlite.domCompile.consts.Modifiers;
	import org.flexlite.domCompile.core.CpClass;
	import org.flexlite.domCompile.core.CpCodeBlock;
	import org.flexlite.domCompile.core.CpFunction;
	import org.flexlite.domCompile.core.CpNotation;
	import org.flexlite.domCompile.core.CpVariable;
	import org.flexlite.domCore.DXML;
	import org.flexlite.domUtils.StringUtil;
	
	/**
	 * DXML文件编译器 
	 * @author DOM
	 */	
	public class DXMLCompiler
	{
		/**
		 * 构造函数
		 */		
		public function DXMLCompiler()
		{
			super();
		}
		
		/**
		 * flexlite-manifest框架清单文件
		 */
		public static var configData:XML;
		/**
		 * 项目配置文件
		 */
		public static var projectConfigData:XML;
		/**
		 * 当前类 
		 */		
		private var currentClass:CpClass;
		/**
		 * 当前要编译的DXML文件 
		 */		
		private var currentXML:XML;
		/**
		 * id缓存字典 
		 */		
		private var idDic:Dictionary;
		/**
		 * 状态代码列表 
		 */		
		private var stateCode:Vector.<CpState>;
		/**
		 * 需要延迟创建的实例id列表
		 */		
		private var stateIds:Array = [];
		/**
		 * 编译指定的XML对象为ActionScript类。
		 * 注意:编译前要先注入flexlite-manifest.xml清单文件给manifestData属性。 清单文件可以用ManifestUtil类生成。
		 * @param xmlData 要编译的dxml文件内容
		 * @param className 要编译成的完整类名，包括包名。
		 */		
		public function compile(xmlData:XML,className:String):String
		{
			if(configData==null)
			{
				throw new Error("还未注入flexlite-manifest框架清单配置数据！");
				return "";
			}
			if(!xmlData||!className)
				return "";
			
			currentXML = new XML(xmlData);	
			className = className.split("::").join(".");
			idDic = new Dictionary;
			stateCode = new Vector.<CpState>();
			stateIds = [];
			currentClass = new CpClass();
			currentClass.notation = new CpNotation(
				"@private\n此类由编译器自动生成，您应修改对应的DXML文件内容，然后重新编译，而不应直接修改其代码。\n@author DXMLCompiler");
			
			
			var index:int = className.lastIndexOf(".");
			if(index!=-1)
			{
				currentClass.packageName = className.substring(0,index);
				currentClass.className = className.substring(index+1);
			}
			else
			{
				currentClass.className = className;
			}
			startCompile();
			var resutlCode:String = currentClass.toCode();
			currentClass = null;
			return resutlCode;
		}
		
		/**
		 * 开始编译
		 */		
		private function startCompile():void
		{
			currentClass.superClass = getPackageByNode(currentXML);
			
			addIds(currentXML.children());
			
			createConstructFunc();
		}
		
		/**
		 * 添加必须的id
		 */		
		private function addIds(items:XMLList):void
		{
			for each(var node:XML in items)
			{
				if(node.hasOwnProperty("@id"))
				{
					createVarForNode(node);
					if(isStateNode(node))//检查节点是否只存在于一个状态里，需要延迟实例化
						stateIds.push(node.@id);
				}
				else if(getPackageByNode(node)!="")
				{
					createIdForNode(node);
					if(isStateNode(node))
						stateIds.push(node.@id);
					if(containsState(node))
					{
						createVarForNode(node);
						
						var parentNode:XML = node.parent() as XML;
						if(isStateNode(node)&&parentNode!=null&&parentNode!=currentXML
							&&!currentClass.containsVar(getNodeId(parentNode)))
						{
							createVarForNode(parentNode);
						}
					}
				}
				addIds(node.children());
			}
		}
		/**
		 * 检测指定节点的属性是否含有视图状态
		 */		
		private static function containsState(node:XML):Boolean
		{
			if(node.hasOwnProperty("@includeIn")||node.hasOwnProperty("@excludeFrom"))
			{
				return true;
			}
			var attributes:XMLList = node.attributes();
			for each(var item:XML in attributes)
			{
				var name:String= item.localName();
				if(name.indexOf(".")!=-1)
				{
					return true;
				}
			}
			return false;
		}
		
		/**
		 * 为指定节点创建id属性
		 */		
		private function createIdForNode(node:XML):void
		{
			var idName:String = getNodeId(node);
			if(idDic[idName]==null)
				idDic[idName] = 1;
			else
				idDic[idName] ++;
			idName += idDic[idName];
			node.@id = idName;
		}
		/**
		 * 获取节点ID
		 */		
		private function getNodeId(node:XML):String
		{
			if(node.hasOwnProperty("@id"))
				return node.@id;
			return "__"+currentClass.className+"_"+node.localName();
		}
		
		/**
		 * 为指定节点创建变量
		 */		
		private function createVarForNode(node:XML):void
		{
			var className:String = node.localName();
			if(isBasicTypeData(className))
			{
				if(!currentClass.containsVar(node.@id))
					currentClass.addVariable(new CpVariable(node.@id,Modifiers.M_PUBLIC,className));
				return;
			}
			var packageName:String = getPackageByNode(node);
			if(packageName=="")
				return;
			if(!currentClass.containsVar(node.@id))
				currentClass.addVariable(new CpVariable(node.@id,Modifiers.M_PUBLIC,packageName));
		}
		/**
		 * 为指定节点创建初始化函数,返回函数名引用
		 */		
		private function createFuncForNode(node:XML):String
		{
			var packageName:String = getPackageByNode(node);
			var className:String = node.localName();
			var isBasicType:Boolean = isBasicTypeData(className);
			if(!isBasicType&&(isProperty(node)||packageName==""))
				return "";
			if(isBasicType)
				return createBasicTypeForNode(node);
			var func:CpFunction = new CpFunction;
			var tailName:String = "_i";
			func.name = node.@id+tailName;
			func.returnType = packageName;
			var cb:CpCodeBlock = new CpCodeBlock;
			var varName:String = "temp";
			if(packageName=="flash.geom.Transform")
			{//Transform需要构造函数参数
				cb.addVar(varName,packageName,"new "+packageName+"(new Shape())");
				currentClass.addImport("flash.display.Shape");
			}
			else
			{
				cb.addVar(varName,packageName,"new "+packageName+"()");
			}
			var containsId:Boolean = currentClass.containsVar(node.@id);
			if(containsId)
			{
				cb.addAssignment(node.@id,varName);
			}
			
			addAttributesToCodeBlock(cb,varName,node);
			
			var children:XMLList = node.children();
			var obj:Object = getDefaultPropByNode(node);
			var property:String = obj.d;
			var isArray:Boolean = obj.array;
			
			initlizeChildNode(cb,children,property,isArray,varName);
			
			cb.addReturn(varName);
			func.codeBlock = cb;
			currentClass.addFunction(func);
			return func.name+"()";
		}
		
		private var basicTypes:Vector.<String> = 
			new <String>["Array","uint","int","Boolean","String","Number","Class","Vector"];
		/**
		 * 检查目标类名是否是基本数据类型
		 */		
		private function isBasicTypeData(className:String):Boolean
		{
			for each(var type:String in basicTypes)
			{
				if(type==className)
					return true;
			}
			return false;
		}
		/**
		 * 为指定基本数据类型节点实例化,返回实例化后的值。
		 */		
		private function createBasicTypeForNode(node:XML):String
		{
			var className:String = node.localName();
			var returnValue:String = "";
			var child:XML;
			var varItem:CpVariable = currentClass.getVariableByName(node.@id);
			switch(className)
			{
				case "Array":
				case "Vector":
					var values:Array = [];
					for each(child in node.children())
				{
					values.push(createFuncForNode(child));
				}
					returnValue = "["+values.join(",")+"]";
					if(className=="Vector")
					{
						returnValue = "new <"+node.@type+">"+returnValue;
					}
					break;
				case "uint":
				case "int":
				case "Boolean":
				case "Class":
					returnValue = node.toString();
					returnValue = StringUtil.trim(returnValue);
					break;
				case "Number":
					returnValue = StringUtil.trim(node.toString());
					if(returnValue.indexOf("%")!=-1)
						returnValue = returnValue.substring(0,returnValue.length-1);
					break;
				case "String":
					returnValue = formatString(node.toString());
					break;
			}
			if(varItem)
				varItem.defaultValue = returnValue;
			return returnValue;
		}
		/**
		 * 将节点属性赋值语句添加到代码块
		 */		
		private function addAttributesToCodeBlock(cb:CpCodeBlock,varName:String,node:XML):void
		{
			var keyList:Array = [];
			var key:String;
			var value:String;
			for each(var item:XML in node.attributes())
			{
				key = item.localName();
				if(!isNormalKey(key))
					continue;
				keyList.push(key);
			}
			keyList.sort();//排序一下防止出现随机顺序
			for each(key in keyList)
			{
				value = node["@"+key].toString();
				key = formatKey(key,value);
				value  = formatValue(key,value,node.@id);
				cb.addAssignment(varName,value,key);
			}
		}
		/**
		 * 初始化子项
		 */		
		private function initlizeChildNode(cb:CpCodeBlock,children:XMLList,
										   property:String,isArray:Boolean,varName:String):void
		{
			if(children.length()==0)
				return;
			var child:XML;
			var childFunc:String = "";
			var directChild:Array = [];
			var prop:String = "";
			for each(child in children)
			{
				prop = child.localName(); 
				if(prop==DECLARATIONS||prop=="states")
				{
					continue;
				}
				if(isProperty(child))
				{
					var childLength:int = child.children().length();
					if(childLength==0)
						continue;
					
					if(childLength>1)
					{
						var values:Array = [];
						for each(var item:XML in child.children())
						{
							values.push(createFuncForNode(item));
						}
						childFunc = "["+values.join(",")+"]";
					}
					else
					{
						var firsChild:XML = child.children()[0];
						childFunc = createFuncForNode(firsChild);
						if(firsChild.localName()!="Array"&&
							prop==property&&isArray)
						{
							childFunc = "["+childFunc+"]";
						}
					}
					if(childFunc!=""&&!isStateNode(child))
					{
						if(childFunc.indexOf("()")==-1)
							prop = formatKey(prop,childFunc);
						cb.addAssignment(varName,childFunc,prop);
					}
				}
				else
				{
					directChild.push(child);
				}
				
			}
			if(directChild.length==0)
				return;
			if(isArray&&(directChild.length>1||directChild[0].localName()!="Array"))
			{
				var arrValue:String = "[";
				var isFirst:Boolean = true;
				for each(child in directChild)
				{
					childFunc = createFuncForNode(child);
					if(childFunc==""||isStateNode(child))
						continue;
					if(isFirst)
					{
						arrValue += childFunc;
						isFirst = false;
					}
					else
					{
						arrValue += ","+childFunc;
					}
				}
				arrValue += "]";
				cb.addAssignment(varName,arrValue,property);
			}
			else
			{
				childFunc = createFuncForNode(directChild[0]);
				if(childFunc!=""&&!isStateNode(child))
					cb.addAssignment(varName,childFunc,property);
			}
		}
		
		/**
		 * 指定节点是否是属性节点
		 */		
		private function isProperty(node:XML):Boolean
		{
			var name:String = node.localName();
			if(name==null)
				return true;
			if(name=="int"||name=="uint")
				return false;
			var firstChar:String = name.charAt(0);
			return firstChar<"A"||firstChar>"Z";
		}
		/**
		 * 是否是普通赋值的key
		 */		
		private function isNormalKey(key:String):Boolean
		{
			if(key==null||key==""||key=="id"||key=="includeIn"
				||key == "excludeFrom"||key.indexOf(".")!=-1)
				return false;
			return true;
		}
		/**
		 * 格式化key
		 */		
		private function formatKey(key:String,value:String):String
		{
			if(key=="skinClass")
			{
				key = "skinName";
			}
			else if(value.indexOf("%")!=-1)
			{
				if(key=="height")
					key = "percentHeight";
				else if(key=="width")
					key = "percentWidth";
			}
			return key;
		}
		/**
		 * 格式化值
		 */		
		private function formatValue(key:String,value:String,id:String):String
		{
			var stringValue:String = value;//除了字符串，其他类型都去除两端多余空格。
			value = StringUtil.trim(value);
			var index:int = value.indexOf("@Embed(");
			if(index!=-1)
			{
				var metadata:String = value.substr(index+1);
				currentClass.addVariable(new CpVariable(id+"_"+key,Modifiers.M_PRIVATE,"Class","",true,false,metadata));
				value = id+"_"+key; 
			}
			else if(key=="skinClass"||key=="skinName"||key=="itemRenderer"||key=="itemRendererSkinName")
			{
				if(isPackageName(value))
				{
					currentClass.addImport(value);
				}
				else
				{
					value = formatString(stringValue);
				}
			}
			else if(value.indexOf("{")!=-1)
			{
				value = value.substr(1,value.length-2);
			}
			else if(isStringKey(key))
			{
				value = formatString(stringValue);
			}
			else if(value.indexOf("%")!=-1
				&&(key=="percentHeight"||key=="percentWidth"))
			{
				value = StringUtil.trim(value);
				value = Number(value.substr(0,value.length-1)).toString();
			}
			else if(value.indexOf("#")==0)
			{
				value = "0x"+value.substr(1);
			}
			else if(isNaN(Number(value))&&value!="true"&&value!="false")
			{
				value = formatString(stringValue);
			}
			return value;
		}
		/**
		 * 格式化字符串
		 */		
		private function formatString(value:String):String
		{
			value = "\""+value+"\"";
			value = value.split("\n").join("\\n");
			value = value.split("\r").join("\\n");
			return value;
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
		
		/**
		 * 创建构造函数
		 */		
		private function createConstructFunc():void
		{
			var cb:CpCodeBlock = new CpCodeBlock;
			cb.addEmptyLine();
			var varName:String = KeyWords.KW_THIS;
			addAttributesToCodeBlock(cb,varName,currentXML);
			
			var declarations:XML;
			for each(var node:XML in currentXML.children())
			{
				if(node.localName()==DECLARATIONS)
				{
					declarations = node;
					break;
				}
			}
			if(declarations&&declarations.children().length()>0)
			{
				for each(var decl:XML in declarations.children())
				{
					var funcName:String = createFuncForNode(decl);
					if(funcName!="")
					{
						cb.addCodeLine(funcName+";");
					}
				}
			}
			
			var obj:Object = getDefaultPropByNode(currentXML);
			var property:String = obj.d;
			var isArray:Boolean = obj.array;
			initlizeChildNode(cb,currentXML.children(),property,isArray,varName);
			
			getStateNames();
			cb.addEmptyLine();
			var id:String;
			if(stateIds.length>0)
			{
				currentClass.addImport(FACTORY_CLASS_PACKAGE);
				for each(id in stateIds)
				{
					var name:String = id+"_factory";
					var value:String = "new "+FACTORY_CLASS_PACKAGE+"("+id+"_i)";
					cb.addVar(name,FACTORY_CLASS_PACKAGE,value);
				}
				cb.addEmptyLine();
			}
			
			//生成视图状态代码
			createStates(currentXML.children());
			var states:Vector.<CpState>;
			for each(var item:XML in currentXML.attributes())
			{
				var itemName:String= item.localName();
				var index:int = itemName.indexOf(".");
				if(index!=-1)
				{
					var key:String = itemName.substring(0,index);
					key = formatKey(key,item);
					var itemValue:String = formatValue(key,item,"this");
					var stateName:String = itemName.substr(index+1);
					states = getStateByName(stateName);
					if(states.length>0)
					{
						for each(var state:CpState in states)
						state.addOverride(new CpSetProperty("",key,itemValue));
					}
				}
			}
			
			for each(state in stateCode)
			{
				if(state.addItems.length>0)
				{
					currentClass.addImport(ADD_ITEMS_PACKAGE);
					break;
				}
			}
			
			for each(state in stateCode)
			{
				if(state.setProperty.length>0)
				{
					currentClass.addImport(SETPROPERTY_PACKAGE);
					break;
				}
			}
			
			//打印视图状态初始化代码
			if(stateCode.length>0)
			{
				currentClass.addImport(STATE_CLASS_PACKAGE);
				cb.addCodeLine("states = [");
				var first:Boolean = true;
				var indentStr:String = "	";
				for each(state in stateCode)
				{
					if(first)
						first = false;
					else
						cb.addCodeLine(indentStr+",");
					var codes:Array = state.toCode().split("\n");
					var codeIndex:int = 0;
					while(codeIndex<codes.length)
					{
						cb.addCodeLine(indentStr+codes[codeIndex]);
						codeIndex++;
					}
				}
				cb.addCodeLine("];");
			}
			
			
			currentClass.constructCode = cb;
		}
		
		/**
		 * 是否含有includeIn和excludeFrom属性
		 */		
		private function isStateNode(node:XML):Boolean
		{
			return node.hasOwnProperty("@includeIn")||node.hasOwnProperty("@excludeFrom");
		}
		
		/**
		 * 获取视图状态名称列表
		 */		
		private function getStateNames():void
		{
			var states:XMLList;
			for each(var item:XML in currentXML.children())
			{
				if(item.localName()=="states")
				{
					states = item.children();
					break;
				}
			}
			if(states==null||states.length()==0)
				return;
			for each(var state:XML in states)
			{
				var stateGroups:Array = [];
				if(state.hasOwnProperty("@stateGroups"))
				{
					var groups:Array = String(state.@stateGroups).split(",");
					for each(var group:String in groups)
					{
						if(StringUtil.trim(group)!="")
						{
							stateGroups.push(StringUtil.trim(group));
						}
					}
				}
				stateCode.push(new CpState(state.@name,stateGroups));
			}
			currentClass.addImport(getPackageByNode(states[0]));
		}
		
		/**
		 * 解析视图状态代码
		 */		
		private function createStates(items:XMLList):void
		{
			for each(var node:XML in items)
			{
				createStates(node.children());
				if(isProperty(node)||getPackageByNode(node)=="")
					continue;
				if(containsState(node))
				{
					var id:String = node.@id;
					var stateName:String;
					var states:Vector.<CpState>;
					var state:CpState;
					if(isStateNode(node))
					{
						var propertyName:String = "";
						var parentNode:XML = node.parent() as XML;
						if(parentNode!=null&&parentNode != currentXML)
							propertyName = parentNode.@id;
						var positionObj:Object = findNearNodeId(node);
						var stateNames:Array = [];
						if(node.hasOwnProperty("@includeIn"))
						{
							stateNames = node.@includeIn.toString().split(".");
						}
						else
						{
							var excludeNames:Array = node.@excludeFrom.toString().split(".");
							for each(state in stateCode)
							{
								if(excludeNames.indexOf(state.name)==-1)
									stateNames.push(state.name);
							}
						}
						
						for each(stateName in stateNames)
						{
							states = getStateByName(stateName);
							if(states.length>0)
							{
								for each(state in states)
								state.addOverride(new CpAddItems(id+"_factory",propertyName,
									positionObj.position,positionObj.relativeTo));
							}
						}
					}
					
					for each(var item:XML in node.attributes())
					{
						var name:String= item.localName();
						var index:int = name.indexOf(".");
						if(index!=-1)
						{
							var key:String = name.substring(0,index);
							key = formatKey(key,item);
							var value:String = formatValue(key,item,node.@id);
							stateName = name.substr(index+1);
							states = getStateByName(stateName);
							if(states.length>0)
							{
								for each(state in states)
								state.addOverride(new CpSetProperty(id,key,value));
							}
						}
					}
				}
			}
			
		}
		/**
		 * 通过视图状态名称获取对应的视图状态
		 */		
		private function getStateByName(name:String):Vector.<CpState>
		{
			var states:Vector.<CpState> = new Vector.<CpState>;
			for each(var state:CpState in stateCode)
			{
				if(state.name == name)
				{
					if(states.indexOf(state)==-1)
						states.push(state);
				}
				else if(state.stateGroups.length>0)
				{
					var found:Boolean = false;
					for each(var g:String in state.stateGroups)
					{
						if(g==name)
						{
							found = true;
							break;
						}
					}
					if(found)
					{
						if(states.indexOf(state)==-1)
							states.push(state);
					}
				}
			}
			return states;
		}
		/**
		 * 寻找节点的临近节点ID和位置
		 */		
		private function findNearNodeId(node:XML):Object
		{
			var parentNode:XML = node.parent();
			var item:XML;
			var targetId:String = "";
			var postion:String;
			var index:int = node.childIndex();
			if(index==0)
			{
				postion = "first";
				return {position:postion,relativeTo:targetId};
			}
			if(index==parentNode.children().length()-1)
			{
				postion = "last";
				return {position:postion,relativeTo:targetId};
			}
			
			postion = "after";
			index--;
			while(index>=0)
			{
				item = parentNode.children()[index];
				if(!isStateNode(item)&&item.hasOwnProperty("@id"))
				{
					targetId = item.@id;
					break;
				}
				index--;
			}
			if(targetId!="")
			{
				createVarForNode(item);
				return {position:postion,relativeTo:targetId};
			}
			
			postion = "before";
			index = node.childIndex();
			index++;
			while(index<parentNode.children().length())
			{
				item = parentNode.children()[index];
				if(!isStateNode(item)&&item.hasOwnProperty("@id"))
				{
					targetId = item.@id;
					break;
				}
				index++;
			}
			if(targetId!="")
			{
				createVarForNode(item);
				return {position:postion,relativeTo:targetId};
			}
			else
			{
				return {position:"last",relativeTo:targetId};
			}
		}
		
		
		
		private static const FACTORY_CLASS_PACKAGE:String = "org.flexlite.domUI.core.DeferredInstanceFromFunction";
		
		private static const FACTORY_CLASS:String = "DeferredInstanceFromFunction";
		
		private static const STATE_CLASS_PACKAGE:String = "org.flexlite.domUI.states.State";
		
		private static const ADD_ITEMS_PACKAGE:String = "org.flexlite.domUI.states.AddItems";
		
		private static const SETPROPERTY_PACKAGE:String = "org.flexlite.domUI.states.SetProperty";
		
		private static const DECLARATIONS:String = "Declarations";
		/**
		 * 使用框架配置文件的默认命名空间 
		 */		
		private static const DEFAULT_NS:Array = 
			[DXML.NS,
				new Namespace("s","library://ns.adobe.com/flex/spark"),
				new Namespace("mx","library://ns.adobe.com/flex/mx"),
				new Namespace("fx","http://ns.adobe.com/mxml/2009")];
		
		/**
		 * 指定的命名空间是否是默认命名空间
		 */		
		private static function isDefaultNs(ns:Namespace):Boolean
		{
			for each(var dns:Namespace in DEFAULT_NS)
			{
				if(ns==dns)
					return true;
			}
			return false;
		}
		
		/**
		 * 根据类名获取对应的包，并自动导入相应的包
		 */		
		private function getPackageByNode(node:XML):String
		{
			var packageName:String = "";
			var config:XML = getConfigNode(node);
			if(config!=null)
				packageName = config.@p;
			if(packageName!=""&&packageName.indexOf(".")!=-1)
			{
				currentClass.addImport(packageName);
			}
			return packageName;
		}
		/**
		 * 获取配置节点
		 */		
		private static function getConfigNode(node:XML):XML
		{
			var ns:Namespace = node.namespace();
			if(!ns)
				return null;
			var className:String = node.localName();
			if(isDefaultNs(ns))
			{
				for each(var component:XML in configData.children())
				{
					if(component.@id==className)
					{
						return component;
					}
				}
			}
			else if(projectConfigData!=null)
			{
				var p:String = ns.uri;
				p = p.substring(0,p.length-1)+className;
				for each(var item:XML in projectConfigData.children())
				{
					if(item.@p==p)
					{
						return item;
					}
				}
			}
			return null;
		}
		/**
		 * 根据包名获取配置节点
		 */		
		private static function getConfigNodeByPackage(packageName:String):XML
		{
			for each(var component:XML in configData.children())
			{
				if(component.@p==packageName)
				{
					return component;
				}
			}
			if(projectConfigData!=null)
			{
				for each(var item:XML in projectConfigData.children())
				{
					if(item.@p == packageName)
					{
						return item;
					}
				}
			}
			return null;
		}
		/**
		 * 根据类名获取对应默认属性
		 */
		private static function getDefaultPropByNode(node:XML):Object
		{
			var config:XML = getConfigNode(node);
			if(config==null)
				return {d:"",array:false};
			findProp(config);
			return {d:config.@d,array:config.@array=="true"};
		}
		/**
		 * 递归查询默认值
		 */		
		private static function findProp(node:XML):String
		{
			if(node.hasOwnProperty("@d"))
			{
				return node.@d;
			}
			
			var superClass:String = node.@s;
			var superNode:XML;
			var item:XML;
			var found:Boolean;
			for each(item in configData.children())
			{
				if(item.@p==superClass)
				{
					superNode = item;
					break;
				}
			}
			if(!found&&projectConfigData!=null)
			{
				for each(item in projectConfigData.children())
				{
					if(item.@p==superClass)
					{
						superNode = item;
						break;
					}
				}
			}
			if(superNode!=null)
			{
				var prop:String = findProp(superNode);
				if(prop!="")
				{
					node.@d = prop;
					if(superNode.hasOwnProperty("@array"))
						node.@array = superNode.@array;
				}
			}
			return node.@d;
		}
		/**
		 * 检查变量是否是包名
		 */		
		private function isPackageName(name:String):Boolean
		{
			return name.indexOf(".")!=-1;
		}
		/**
		 * 指定的变量名是否是工程默认包里的类名
		 */		
		private static function isDefaultPackageClass(name:String):Boolean
		{
			if(projectConfigData==null||name=="")
				return false;
			for each(var item:XML in projectConfigData.children())
			{
				if(item.@p == name)
					return true;
			}
			return false;
		}
	}
}


import org.flexlite.domCompile.core.CodeBase;
import org.flexlite.domCompile.core.ICode;

/**
 * 状态类代码块
 * @author DOM
 */
class CpState extends CodeBase
{
	public function CpState(name:String,stateGroups:Array=null)
	{
		super();
		this.name = name;
		if(stateGroups)
			this.stateGroups = stateGroups;
	}
	/**
	 * 视图状态名称
	 */	
	public var name:String = "";
	
	public var stateGroups:Array = [];
	
	public var addItems:Array = [];
	
	public var setProperty:Array = [];
	
	/**
	 * 添加一个覆盖
	 */	
	public function addOverride(item:ICode):void
	{
		if(item is CpAddItems)
			addItems.push(item);
		else
			setProperty.push(item);
	}
	
	override public function toCode():String
	{
		var indentStr:String = getIndent(1);
		var returnStr:String = "new org.flexlite.domUI.states.State ({name: \""+name+"\",\n"+indentStr+"overrides: [\n";
		var index:int = 0;
		var isFirst:Boolean = true;
		var overrides:Array = addItems.concat(setProperty);
		while(index<overrides.length)
		{
			if(isFirst)
				isFirst = false;
			else
				returnStr += indentStr+indentStr+",\n";
			var item:ICode = overrides[index];
			var codes:Array = item.toCode().split("\n");
			for each(var code:String in codes)
			{
				returnStr += indentStr+indentStr+code+"\n";
			}
			index++;
		}
		returnStr += indentStr+"]\n})";
		return returnStr;
	}
}

/**
 * AddItems类代码块
 * @author DOM
 */
class CpAddItems extends CodeBase
{
	public function CpAddItems(targetFactory:String,propertyName:String,position:String,relativeTo:String)
	{
		super();
		this.targetFactory = targetFactory;
		this.propertyName = propertyName;
		this.position = position;
		this.relativeTo = relativeTo;
	}
	
	/**
	 * 创建项目的工厂类实例 
	 */		
	public var targetFactory:String;
	
	/**
	 * 要添加到的属性 
	 */		
	public var propertyName:String;
	
	/**
	 * 添加的位置 
	 */		
	public var position:String;
	
	/**
	 * 相对的显示元素 
	 */		
	public var relativeTo:String;
	
	override public function toCode():String
	{
		var indentStr:String = getIndent(1);
		var returnStr:String = "new org.flexlite.domUI.states.AddItems().initializeFromObject({\n";
		returnStr += indentStr+"targetFactory:"+targetFactory+",\n";
		returnStr += indentStr+"propertyName:\""+propertyName+"\",\n";
		returnStr += indentStr+"position:\""+position+"\",\n";
		returnStr += indentStr+"relativeTo:\""+relativeTo+"\"\n})";
		return returnStr;
	}
}
/**
 * SetProperty类代码块
 * @author DOM
 */
class CpSetProperty extends CodeBase
{
	public function CpSetProperty(target:String,name:String,value:String)
	{
		super();
		this.target = target;
		this.name = name;
		this.value = value;
	}
	
	/**
	 * 要修改的属性名
	 */		
	public var name:String;
	
	/**
	 * 目标实例名
	 */		
	public var target:String;
	
	/**
	 * 属性值 
	 */		
	public var value:String;
	
	override public function toCode():String
	{
		var indentStr:String = getIndent(1);
		var returnStr:String = "new org.flexlite.domUI.states.SetProperty().initializeFromObject({\n";
		returnStr += indentStr+"target:\""+target+"\",\n";
		returnStr += indentStr+"name:\""+name+"\",\n";
		returnStr += indentStr+"value:"+value+"\n})";
		return returnStr;
	}
}