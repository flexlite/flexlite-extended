package org.flexlite.domCompile.utils
{
	import flash.system.ApplicationDomain;
	import flash.utils.describeType;
	
	import org.flexlite.domUtils.StringUtil;
	
	/**
	 * 框架清单文件生成工具
	 * @author dom
	 */
	public class ManifestUtil
	{
		/**
		 * 创建flexlite-mainifest文件
		 * @param flexLiteDomain FlexLite库的程序域，将FlexLite.swc解压得到FlexLite.swf,然后加载它即可得到程序域。
		 */		
		public static function createMainifest(flexLiteDomain:ApplicationDomain):XML
		{
			var definitionNames:Vector.<String> = flexLiteDomain.getQualifiedDefinitionNames();
			var list:Array = [];
			var item:XML;
			for each(var definition:String in definitionNames)
			{
				if(definition.indexOf("org.flexlite.domUI")==-1)
					continue;
				item = parseOneClass(flexLiteDomain.getDefinition(definition) as Class);
				if(item)
					list.push(item);
			}
			list.sortOn("@id");
			var manifest:XML = <componentPackage/>;
			for each(item in list)
			{
				manifest.appendChild(item);
			}
			for each(item in extraNodes.children())
			{
				manifest.appendChild(item);
			}
			return manifest;
		}
		
		/**
		 * 解析一个类
		 */		
		private static function parseOneClass(clazz:Class):XML
		{
			var info:XML = describeType(clazz);
			var show:Boolean;
			var d:String;
			var array:Boolean;
			var states:Array = [];
			
			var found:Boolean = false;
			for each(var meta:XML in info.factory.metadata)
			{
				if(meta.@name=="DXML")
				{
					found = true;
					try
					{
						if(meta.arg.(@key=="show")[0].@value=="true")
							show = true;
					}
					catch(e:Error){}
				}
				else if(meta.@name=="DefaultProperty")
				{
					try
					{
						d = String(meta.arg.(@key=="name")[0].@value);
						if(meta.arg.(@key=="array")[0].@value=="true")
							array = true;
					}
					catch(e:Error){}
				}
				else if(meta.@name=="SkinState")
				{
					try
					{
						var state:String = String(meta.arg[0].@value);
						if(state)
							states.splice(0,0,state);
					}
					catch(e:Error){}
				}
			}
			if(!found)
				return null;
			var p:String = StringUtil.replaceStr(info.@name,"::",".");
			var s:String = StringUtil.replaceStr(info.factory.extendsClass[0].@type,"::",".");
			var id:String = p.substr(p.lastIndexOf(".")+1);
			var component:XML = <component id={id} p={p} s={s}/>;
			if(d)
				component.@d = d;
			if(show)
				component.@show = "true";
			if(array)
				component.@array = "true";
			if(states.length>0)
				component.@state = states.join(",");
			return component;
		}
		
		/**
		 * 额外附加的节点列表
		 */		
		private static var extraNodes:XML = 
			<componentPackage>
			  <component id="BevelFilter" p="flash.filters.BevelFilter" s="flash.filters.BitmapFilter"/>
			  <component id="BlurFilter" p="flash.filters.BlurFilter" s="flash.filters.BitmapFilter"/>
			  <component id="ColorMatrixFilter" p="flash.filters.ColorMatrixFilter" s="flash.filters.BitmapFilter"/>
			  <component id="ConvolutionFilter" p="flash.filters.ConvolutionFilter" s="flash.filters.BitmapFilter"/>
			  <component id="DropShadowFilter" p="flash.filters.DropShadowFilter" s="flash.filters.BitmapFilter"/>
			  <component id="GlowFilter" p="flash.filters.GlowFilter" s="flash.filters.BitmapFilter"/>
			  <component id="GradientBevelFilter" p="flash.filters.GradientBevelFilter" s="flash.filters.BitmapFilter"/>
			  <component id="GradientGlowFilter" p="flash.filters.GradientGlowFilter" s="flash.filters.BitmapFilter"/>
			  <component id="Transform" p="flash.geom.Transform" s="Object"/>
			  <component id="ColorTransform" p="flash.geom.ColorTransform" s="Object"/>
			  <component id="Matrix" p="flash.geom.Matrix" s="Object"/>
			  <component id="Matrix3D" p="flash.geom.Matrix3D" s="Object"/>
			  <component id="Point" p="flash.geom.Point" s="Object"/>
			  <component id="Object" p="Object"/>
		   </componentPackage>;
	}
}