package psychlua;

import tea.SScript;

#if hscript
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
#end

import haxe.Exception;

#if (SScript >= "3.0.0")
class HScript extends SScript
{
	public var parentLua:FunkinLua;
	
	public static function initHaxeModule(parent:FunkinLua)
	{
		#if (SScript >= "3.0.0")
		if(parent.hscript == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent);
		}
		#end
	}

	override public function new(parent:FunkinLua)
	{
		super("", false);
		parentLua = parent;
		preset();
	}
	override function preset()
	{
		#if (SScript >= "3.0.0")
		super.preset();
		set('FlxG', flixel.FlxG);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxCamera', flixel.FlxCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('PlayState', PlayState);
		set('game', PlayState.instance);
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('CustomSubstate', psychlua.CustomSubstate);
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('StringTools', StringTools);

		set('setVar-SScript', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});
		set('getVar-SScript', function(name:String)
		{
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		set('removeVar-SScript', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
		set('debugPrint-SScript', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			FunkinLua.luaTrace(text, true, false, color);
		});
		// For adding your own callbacks
		
		// not very tested but should work
		set('createGlobalCallback-SScript', function(name:String, func:Dynamic)
		{
			#if LUA_ALLOWED
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);
			#end
			FunkinLua.customFunctions.set(name, func);
		});
		
		// tested
		set('createCallback-SScript', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if(funk == null) funk = parentLua;
			funk.addLocalCallback(name, func);
		});
		
		set('addHaxeLibrary-SScript', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';
				set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic) {
				FunkinLua.lastCalledScript = parentLua;
				FunkinLua.luaTrace(parentLua.scriptName + ":" + parentLua.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
		});
		set('parentLua', parentLua);
	}

	public function executeCode(codeToRun:String, ?funcToRun:String = null, ?funcArgs:Array<Dynamic>):SCall
	{
		doString(codeToRun);
		
	    if (funcToRun != null)
		{
			var callValue = call(funcToRun, funcArgs);
			if (callValue.succeeded)
				return callValue.returnValue;
			else
			{
				var e = callValue.exceptions[0];
				if (e != null)
				{
					FunkinLua.luaTrace(parentLua.scriptName + ":" + parentLua.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
				}
				return null;
			}
		}
		return null;
	}
	
	public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic>):SCall
	{
		if (funcToRun == null)
			return null;
		return call(funcToRun, funcArgs);
	}
	
	public static function implement(funk:FunkinLua)
	{
	    #if LUA_ALLOWED
		funk.addLocalCallback("runHaxeCode-SScript", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null) {
			var retVal:SCall = null;
			#if (SScript >= "3.0.0")
			initHaxeModule(funk);
			if(varsToBring != null)
			{
				for (key in Reflect.fields(varsToBring))
				{
					//trace('Key $key: ' + Reflect.field(varsToBring, key));
					funk.hscript.set(key, Reflect.field(varsToBring, key));
				}
			}
			retVal = funk.hscript.executeCode(codeToRun, funcToRun, funcArgs);
			if (funcToRun != null && funcArgs != null && retVal != null && !retVal.succeeded)
			{
				var e = retVal.exceptions[0];
				if (e != null)
					FunkinLua.luaTrace(funk.scriptName + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
				return null;
			}
			#else
			FunkinLua.luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
			if(retVal != null && !LuaUtils.isOfTypes(retVal.returnValue, [Bool, Int, Float, String, Array])) retVal = null;
			return retVal;
		});
		
		funk.addLocalCallback("runHaxeFunction-SScript", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			#if (SScript >= "3.0.0")
			var callValue = funk.hscript.executeFunction(funcToRun, funcArgs);
			if (!callValue.succeeded)
			{
				var e = callValue.exceptions[0];
				if (e != null)
					FunkinLua.luaTrace(e.message, true);
				return null;
			}
			else
				return callValue.returnValue;
			#else
			FunkinLua.luaTrace("runHaxeFunction: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		
		// This function is unnecessary because import already exists in SScript as a native feature
		funk.addLocalCallback("addHaxeLibrary-SScript", function(libName:String, ?libPackage:String = '') {
			#if (SScript >= "3.0.0")
			initHaxeModule(funk);
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';
					
				var c = Type.resolveClass(str + libName);
				if (c != null)
					funk.hscript.set(libName, c);
			}
			catch (e:Dynamic) {
				FunkinLua.luaTrace(funk.scriptName + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#else
			FunkinLua.luaTrace("addHaxeLibrary: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		#end
	}
	#end
}
#end

#if hscript
class HScriptBase
{
	#if hscript
	public static var parser:Parser = new Parser();
	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;
	public var parentLua:FunkinLua;

	public function get_variables()
	{
		return interp.variables;
	}
	
	public static function initHaxeModule(parent:FunkinLua)
	{
		#if hscript
		if(parent.hscriptBase == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscriptBase = new HScriptBase(parent);
		}
		#end
	}

	public function new(parent:FunkinLua)
	{
		interp = new Interp();
		parentLua = parent;
		interp.variables.set('FlxG', flixel.FlxG);
		interp.variables.set('FlxSprite', flixel.FlxSprite);
		interp.variables.set('FlxCamera', flixel.FlxCamera);
		interp.variables.set('FlxTimer', flixel.util.FlxTimer);
		interp.variables.set('FlxTween', flixel.tweens.FlxTween);
		interp.variables.set('FlxEase', flixel.tweens.FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('game', PlayState.instance);
		interp.variables.set('Paths', Paths);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('ClientPrefs', ClientPrefs);
		interp.variables.set('Character', Character);
		interp.variables.set('Alphabet', Alphabet);
		interp.variables.set('CustomSubstate', CustomSubstate);
		#if (!flash && sys)
		interp.variables.set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		interp.variables.set('ShaderFilter', openfl.filters.ShaderFilter);
		interp.variables.set('StringTools', StringTools);

		interp.variables.set('setVar', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});
		interp.variables.set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		interp.variables.set('removeVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
		interp.variables.set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			FunkinLua.luaTrace(text, true, false, color);
		});
		// For adding your own callbacks
		
		// not very tested
		interp.variables.set('createGlobalCallback', function(name:String, func:Dynamic) Lua_helper.add_callback(parentLua.lua, name, func));
		
		// tested
		interp.variables.set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if(funk == null) funk = parentLua;
			funk.addLocalCallback(name, func);
		});
		
		interp.variables.set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';
				interp.variables.set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic) {
				FunkinLua.luaTrace(parentLua.scriptName + ":" + parentLua.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
		});
		interp.variables.set('parentLua', parentLua);
	}

	public function execute(codeToRun:String, ?funcToRun:String = null, ?funcArgs:Array<Dynamic>):Dynamic
	{
		@:privateAccess
		HScriptBase.parser.line = 1;
		HScriptBase.parser.allowTypes = true;
		var expr:Expr = HScriptBase.parser.parseString(codeToRun);
		try {
			var value:Dynamic = interp.execute(HScriptBase.parser.parseString(codeToRun));
			return (funcToRun != null) ? executeFunction(funcToRun, funcArgs) : value;
		}
		catch(e:Exception)
		{
			FunkinLua.luaTrace(parentLua.scriptName + ":" + parentLua.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			return null;
		}
	}
	
	public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic>)
	{
		if(funcToRun != null)
		{
			//trace('Executing $funcToRun');
			if(interp.variables.exists(funcToRun))
			{
				//trace('$funcToRun exists, executing...');
				if(funcArgs == null) funcArgs = [];
				try {
					return Reflect.callMethod(null, interp.variables.get(funcToRun), funcArgs);
				}
				catch(e) FunkinLua.luaTrace(parentLua.scriptName + ":" + parentLua.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
		}
		return null;
	}
	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua)
	{
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null) {
			var retVal:Dynamic = null;
			#if hscript
			initHaxeModule(funk);
			try {
				if(varsToBring != null)
				{
					for (key in Reflect.fields(varsToBring))
					{
						//trace('Key $key: ' + Reflect.field(varsToBring, key));
						funk.hscriptBase.interp.variables.set(key, Reflect.field(varsToBring, key));
					}
				}
				retVal = funk.hscriptBase.execute(codeToRun, funcToRun, funcArgs);
			}
			catch (e:Dynamic) {
				FunkinLua.luaTrace(funk.scriptName + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#else
			FunkinLua.luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
			if(retVal != null && !LuaUtils.isOfTypes(retVal, [Bool, Int, Float, String, Array])) retVal = null;
			return retVal;
		});
		
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			try {
				return funk.hscriptBase.executeFunction(funcToRun, funcArgs);
			}
			catch(e:Exception)
			{
				FunkinLua.luaTrace(Std.string(e));
				return null;
			}
		});
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			#if hscript
			initHaxeModule(funk);
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';
				funk.hscriptBase.variables.set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic) {
				FunkinLua.luaTrace(funk.scriptName + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#end
		});
		#end
	}
	#end
}
#end