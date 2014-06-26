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
	import org.flexlite.domCore.Injector;
	import org.flexlite.domUtils.StringUtil;
	
	/**
	 * DXML文件编译器 
	 * @author dom
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
		 * flexlite-manifest框架清单文件<br/>
		 * 注意：要使编译器正常工作,必须对此属性赋值,或调用Injector注入自定义的IDxmlConfig实例,二选一。
		 */
		public static var configData:XML;
		/**
		 * 配置管理器实例
		 */		
		private var dxmlConfig:IDXMLConfig;
		
		/**
		 * 获取重复的ID名
		 */		
		public function getRepeatedIds(xml:XML):Array
		{
			var result:Array = [];
			getIds(xml,result);
			repeatedIdDic = new Dictionary();
			return result;
		}
		
		private var repeatedIdDic:Dictionary = new Dictionary();
		
		private function getIds(xml:XML,result:Array):void
		{
			if(xml.namespace()!=DXML.FS&&xml.hasOwnProperty("@id"))
			{
				var id:String = xml.@id;
				if(repeatedIdDic[id])
				{
					if(result.indexOf(id)==-1)
						result.push(id);
				}
				else
				{
					repeatedIdDic[id] = true;
				}
			}
			for each(var node:XML in xml.children())
			{
				getIds(node,result);
			}
		}
		
		/**
		 * 当前类 
		 */		
		private var currentClass:CpClass;
		/**
		 * 当前编译的类名
		 */		
		private var currentClassName:String;
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
		 * 需要单独创建的实例id列表
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
			if(!xmlData||!className)
				return "";
			if(!dxmlConfig)
			{
				try
				{
					dxmlConfig = Injector.getInstance(IDXMLConfig);
				}
				catch(e:Error)
				{
					if(!configData)
					{
						throw new Error("还未注入flexlite-manifest框架清单配置数据！");
					}
					dxmlConfig = new DXMLConfig(configData);
				}
			}
			currentXML = new XML(xmlData);	
			delayAssignmentDic = new Dictionary();
			className = className.split("::").join(".");
			currentClassName = className;
			idDic = new Dictionary;
			stateCode = new Vector.<CpState>();
			declarations = null;
			currentClass = new CpClass();
			stateIds = [];
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
		
		private var declarations:XML;
		/**
		 * 开始编译
		 */		
		private function startCompile():void
		{
			currentClass.superClass = getPackageByNode(currentXML);
			
			getStateNames();
			if(stateCode.length>0&&!currentXML.hasOwnProperty("@currentState"))
			{
				currentXML.@currentState = stateCode[0].name;
			}
			
			for each(var node:XML in currentXML.children())
			{
				if(node.localName()==DECLARATIONS)
				{
					declarations = node;
					break;
				}
			}
			
			if(declarations)
			{//清理声明节点里的状态标志
				for each(node in declarations.children())
				{
					if(node.hasOwnProperty("@includeIn"))
						delete node.@includeIn;
					if(node.hasOwnProperty("@excludeFrom"))
						delete node.@excludeFrom;
				}
			}
			
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
				if(node.namespace()==DXML.FS)
				{
				}
				else if(node.hasOwnProperty("@id"))
				{
					createVarForNode(node);
					if(isStateNode(node))//检查节点是否只存在于一个状态里，需要单独实例化
						stateIds.push(String(node.@id));
				}
				else if(getPackageByNode(node)!="")
				{
					createIdForNode(node);
					if(isStateNode(node))
						stateIds.push(String(node.@id));
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
			var id:String = node.@id;
			func.name = id+tailName;
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
			var obj:Object = dxmlConfig.getDefaultPropById(node.localName(),node.namespace());
			var property:String = obj.name;
			var isArray:Boolean = obj.isArray;
			
			initlizeChildNode(cb,children,property,isArray,varName);
			if(delayAssignmentDic[id])
			{
				cb.concat(delayAssignmentDic[id]);
			}
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
		 * 延迟赋值字典
		 */		
		private var delayAssignmentDic:Dictionary = new Dictionary();
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
				value  = formatValue(key,value,node);
				if(currentClass.containsVar(value))
				{//赋的值对象是一个id
					var id:String = node.@id;
					var codeLine:String = id+" = temp;";
					if(!currentClass.containsVar(id))
						createVarForNode(node);
					if(!cb.containsCodeLine(codeLine))
					{
						cb.addCodeLineAt(codeLine,1);
					}
					var delayCb:CpCodeBlock = new CpCodeBlock();
					if(varName==KeyWords.KW_THIS)
					{
						delayCb.addAssignment(varName,value,key);
					}
					else
					{
						
						delayCb.startIf(id);
						delayCb.addAssignment(id,value,key);
						delayCb.endBlock();
					}
					delayAssignmentDic[value] = delayCb;
				}
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
				if(prop==DECLARATIONS||prop=="states"||child.namespace()==DXML.FS)
				{
					continue;
				}
				if(isProperty(child))
				{
					var childLength:int = child.children().length();
					if(childLength==0)
						continue;
					var isContainerProp:Boolean = (prop==property&&isArray);
					if(childLength>1)
					{
						var values:Array = [];
						for each(var item:XML in child.children())
						{
							childFunc = createFuncForNode(item);
							if(!isContainerProp||!isStateNode(item))
								values.push(childFunc);
						}
						childFunc = "["+values.join(",")+"]";
					}
					else
					{
						var firsChild:XML = child.children()[0];
						if(isContainerProp)
						{
							if(firsChild.localName()=="Array")
							{
								values = [];
								for each(item in firsChild.children())
								{
									childFunc = createFuncForNode(item);
									if(!isContainerProp||!isStateNode(item))
										values.push(childFunc);
								}
								childFunc = "["+values.join(",")+"]";
							}
							else
							{
								childFunc = createFuncForNode(firsChild);
								if(!isStateNode(item))
									childFunc = "["+childFunc+"]";
								else
									childFunc = "[]";
							}
						}
						else
						{
							childFunc = createFuncForNode(firsChild);
						}
					}
					if(childFunc!="")
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
				var childs:Array = [];
				for each(child in directChild)
				{
					childFunc = createFuncForNode(child);
					if(childFunc==""||isStateNode(child))
						continue;
					childs.push(childFunc);
				}
				cb.addAssignment(varName,"["+childs.join(",")+"]",property);
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
		 * 命名空间为fs的属性名列表
		 */		
		public static var fsKeys:Vector.<String> = new <String>["id","locked","includeIn","excludeFrom"];
		/**
		 * 是否是普通赋值的key
		 */		
		private function isNormalKey(key:String):Boolean
		{
			if(!key||key.indexOf(".")!=-1||fsKeys.indexOf(key)!=-1)
				return false;
			return true;
		}
		/**
		 * 格式化key
		 */		
		private function formatKey(key:String,value:String):String
		{
			if(value.indexOf("%")!=-1)
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
		private function formatValue(key:String,value:String,node:XML):String
		{
			var stringValue:String = value;//除了字符串，其他类型都去除两端多余空格。
			value = StringUtil.trim(value);
			var index:int = value.indexOf("@Embed(");
			if(index!=-1)
			{
				var id:String = node.hasOwnProperty("@id")?node.@id:"this";
				var metadata:String = value.substr(index+1);
				currentClass.addVariable(new CpVariable(id+"_"+key,Modifiers.M_PRIVATE,"Class","",true,false,metadata));
				value = id+"_"+key; 
			}
			else if(value.indexOf("{")!=-1)
			{
				value = value.substr(1,value.length-2);
			}
			else
			{
				var className:String = dxmlConfig.getClassNameById(node.localName(),node.namespace());
				var type:String = dxmlConfig.getPropertyType(key,className,value);
				switch(type)
				{
					case "Class":
						if(value==currentClassName)//防止无限循环。
							return "null";
						currentClass.addImport(value);
						break;
					case "uint":
						if(value.indexOf("#")==0)
							value = "0x"+value.substring(1);
						break;
					case "Number":
						if(value.indexOf("%")!=-1)
							value = Number(value.substr(0,value.length-1)).toString();
						break;
					case "String":
						value = formatString(stringValue);
						break;
					default:
						break;
				}
			}
			return value;
		}
		/**
		 * 格式化字符串
		 */		
		private function formatString(value:String):String
		{
			value = StringUtil.unescapeHTMLEntity(value);
			value = value.split("\n").join("\\n");
			value = value.split("\r").join("\\n");
			value = value.split("\"").join("\\\"");
			value = "\""+value+"\"";
			return value;
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
			
			var obj:Object =  dxmlConfig.getDefaultPropById(currentXML.localName(),currentXML.namespace());
			var property:String = obj.name;
			var isArray:Boolean = obj.isArray;
			initlizeChildNode(cb,currentXML.children(),property,isArray,varName);
			var id:String;
			if(stateIds.length>0)
			{
				for each(id in stateIds)
				{
					cb.addCodeLine(id+"_i();");
				}
				cb.addEmptyLine();
			}
			cb.addEmptyLine();

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
					var itemValue:String = formatValue(key,item,currentXML);
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
					checkIdForState(node);
					var stateName:String;
					var states:Vector.<CpState>;
					var state:CpState;
					if(isStateNode(node))
					{
						var propertyName:String = "";
						var parentNode:XML = node.parent() as XML;
						if(parentNode.localName()=="Array")
							parentNode = parentNode.parent() as XML;
						if(isProperty(parentNode))
							parentNode = parentNode.parent() as XML;
						if(parentNode!=null&&parentNode != currentXML)
						{
							propertyName = parentNode.@id;
							checkIdForState(parentNode);
						}
						var positionObj:Object = findNearNodeId(node);
						var stateNames:Array = [];
						if(node.hasOwnProperty("@includeIn"))
						{
							stateNames = node.@includeIn.toString().split(",");
						}
						else
						{
							var excludeNames:Array = node.@excludeFrom.toString().split(",");
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
								{
									state.addOverride(new CpAddItems(id,propertyName,
										positionObj.position,positionObj.relativeTo));
								}
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
							var value:String = formatValue(key,item,node);
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
		 * 检查指定的ID是否创建了类成员变量，若没创建则为其创建。
		 */		
		private function checkIdForState(node:XML):void
		{
			if(!node||currentClass.containsVar(node.@id))
			{
				return;
			}
			createVarForNode(node);
			var id:String = node.@id;
			var funcName:String = id+"_i";
			var func:CpFunction = currentClass.getFuncByName(funcName);
			if(!func)
				return;
			var codeLine:String = id+" = temp;";
			var cb:CpCodeBlock = func.codeBlock;
			if(!cb)
				return;
			if(!cb.containsCodeLine(codeLine))
			{
				cb.addCodeLineAt(codeLine,1);
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
			var targetId:String = "";
			var postion:String;
			var index:int = -1;
			var totalCount:int = 0;
			var preItem:XML;
			var afterItem:XML;
			var found:Boolean = false;
			for each(var item:XML in parentNode.children())
			{
				if(isProperty(item))
					continue;
				if(item==node)
				{
					found = true;
					index = totalCount;
				}
				else
				{
					if(found&&!afterItem&&!isStateNode(item))
					{
						afterItem = item;
					}
				}
				if(!found&&!isStateNode(item))
					preItem = item;
				totalCount++;
			}
			if(index==0)
			{
				postion = "first";
				return {position:postion,relativeTo:targetId};
			}
			if(index==totalCount-1)
			{
				postion = "last";
				return {position:postion,relativeTo:targetId};
			}
			if(afterItem)
			{
				postion = "before";
				targetId = afterItem.@id;
				if(targetId)
				{
					checkIdForState(afterItem);
					return {position:postion,relativeTo:targetId};
				}
				
			}
			//若有多个状态节点，由于是按数组顺序添加的，使用after会导致状态节点反序。
//			if(preItem)
//			{
//				postion = "after";
//				targetId = preItem.@id;
//				if(targetId)
//				{
//					checkIdForState(preItem);
//					return {position:postion,relativeTo:targetId};
//				}
//				
//			}
			return {position:"last",relativeTo:targetId};
		}
		
		
		private static const STATE_CLASS_PACKAGE:String = "org.flexlite.domUI.states.State";
		
		private static const ADD_ITEMS_PACKAGE:String = "org.flexlite.domUI.states.AddItems";
		
		private static const SETPROPERTY_PACKAGE:String = "org.flexlite.domUI.states.SetProperty";
		
		private static const DECLARATIONS:String = "Declarations";
		
		/**
		 * 根据类名获取对应的包，并自动导入相应的包
		 */		
		private function getPackageByNode(node:XML):String
		{
			var packageName:String = 
				dxmlConfig.getClassNameById(node.localName(),node.namespace());
			dxmlConfig.checkComponent(packageName);
			if(packageName&&packageName.indexOf(".")!=-1)
			{
				currentClass.addImport(packageName);
			}
			return packageName;
		}
		
		/**
		 * 检查变量是否是包名
		 */		
		private function isPackageName(name:String):Boolean
		{
			return name.indexOf(".")!=-1;
		}
		
	}
}


import org.flexlite.domCompile.core.CodeBase;
import org.flexlite.domCompile.core.ICode;

/**
 * 状态类代码块
 * @author dom
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
 * @author dom
 */
class CpAddItems extends CodeBase
{
	public function CpAddItems(target:String,propertyName:String,position:String,relativeTo:String)
	{
		super();
		this.target = target;
		this.propertyName = propertyName;
		this.position = position;
		this.relativeTo = relativeTo;
	}
	
	/**
	 * 创建项目的工厂类实例 
	 */		
	public var target:String;
	
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
		returnStr += indentStr+"target:\""+target+"\",\n";
		returnStr += indentStr+"propertyName:\""+propertyName+"\",\n";
		returnStr += indentStr+"position:\""+position+"\",\n";
		returnStr += indentStr+"relativeTo:\""+relativeTo+"\"\n})";
		return returnStr;
	}
}
/**
 * SetProperty类代码块
 * @author dom
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