package psychlua;

import Type.ValueType;
import haxe.Constraints;

//
// Functions that use a high amount of Reflections, which are somewhat CPU intensive
//

class ReflectionFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		Lua_helper.add_callback(lua, "getProperty", function(variable:String) {
			var result:Dynamic = null;
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1)
				result = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1]);
			else
				result = LuaUtils.getVarInArray(LuaUtils.getTargetInstance(), variable);
			return result;
		});
		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic) {
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(killMe), killMe[killMe.length-1], value);
				return true;
			}
			LuaUtils.setVarInArray(LuaUtils.getTargetInstance(), variable, value);
			return true;
		});
		Lua_helper.add_callback(lua, "getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic) {
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(shitMyPants.length>1)
				realObject = LuaUtils.getPropertyLoop(shitMyPants, true, false);
			if(Std.isOfType(realObject, FlxTypedGroup))
			{
				var result:Dynamic = LuaUtils.getGroupStuff(realObject.members[index], variable);
				return result;
			}
			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				var result:Dynamic = null;
				if(Type.typeof(variable) == ValueType.TInt)
					result = leArray[variable];
				else
					result = LuaUtils.getGroupStuff(leArray, variable);
				return result;
			}
			FunkinLua.luaTrace("getPropertyFromGroup: Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic) {
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
			if(shitMyPants.length>1)
				realObject = LuaUtils.getPropertyLoop(shitMyPants, true, false);
			if(Std.isOfType(realObject, FlxTypedGroup)) {
				LuaUtils.setGroupStuff(realObject.members[index], variable, value);
				return;
			}
			var leArray:Dynamic = realObject[index];
			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
					return;
				}
				LuaUtils.setGroupStuff(leArray, variable, value);
			}
		});
		Lua_helper.add_callback(lua, "removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false) {
			if(Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), obj), FlxTypedGroup)) {
				var sex = Reflect.getProperty(LuaUtils.getTargetInstance(), obj).members[index];
				if(!dontDestroy)
					sex.kill();
				Reflect.getProperty(LuaUtils.getTargetInstance(), obj).remove(sex, true);
				if(!dontDestroy)
					sex.destroy();
				return;
			}
			Reflect.getProperty(LuaUtils.getTargetInstance(), obj).remove(Reflect.getProperty(LuaUtils.getTargetInstance(), obj)[index]);
		});

		Lua_helper.add_callback(lua, "getPropertyFromClass", function(classVar:String, variable:String) {
			@:privateAccess
			//Little 0.7x File Organization Support (Now You Can Play Funkindelix Psych 0.7x Port Fully Functional)
			var extraControl = MusicBeatState.mobilec.current;
			if (classVar.startsWith('backend.')) classVar = classVar.replace('backend.', '');
			if (classVar.startsWith('objects.')) classVar = classVar.replace('objects.', '');
			if (classVar.startsWith('states.')) classVar = classVar.replace('states.', '');

			//Old ClientPrefs And Custom PauseMenu Support
			if (variable == 'globalAntialiasing') variable = 'data.antialiasing';
			if (classVar == 'ClientPrefs' && !classVar.startsWith('data.')) variable = 'data.' + variable;
			#if PsychExtended_ExtraPauseMenus
			if (classVar == 'PauseSubState' && ClientPrefs.data.PauseMenuStyle == 'NovaFlare') classVar = 'extras.substates.PauseSubStateNOVA';
			#end
			//Normal Code
			var myClass:Dynamic = classCheck(classVar);
			var variableplus:String = varCheck(myClass, variable);
			var killMe:Array<String> = variable.split('.');
			#if TOUCH_CONTROLS
			if (MusicBeatState.mobilec != null && myClass == 'flixel.FlxG' && variableplus.indexOf('key') != -1 && extraControl.buttonExtra1 != null && extraControl.buttonExtra2 != null && extraControl.buttonExtra3 != null && extraControl.buttonExtra4 != null){
				var check:Dynamic;
				check = specialKeyCheck(variableplus); //fuck you old lua 🙃
				if (check != null) return check;
			}
			#end

			if(killMe.length > 1) {
				var coverMeInPiss:Dynamic = LuaUtils.getVarInArray(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length-1) {
					coverMeInPiss = LuaUtils.getVarInArray(coverMeInPiss, killMe[i]);
				}
				return LuaUtils.getVarInArray(coverMeInPiss, killMe[killMe.length-1]);
			}
			return LuaUtils.getVarInArray(Type.resolveClass(classVar), variable);
		});
		Lua_helper.add_callback(lua, "setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic) {
			@:privateAccess
			//Little 0.7x File Organization Support (Now You Can Play Funkindelix Psych 0.7x Port Fully Functional)
			if (classVar.startsWith('backend.')) classVar = classVar.replace('backend.', '');
			if (classVar.startsWith('objects.')) classVar = classVar.replace('objects.', '');
			if (classVar.startsWith('states.')) classVar = classVar.replace('states.', '');

			//Old ClientPrefs And Custom PauseMenu Support
			if (variable == 'globalAntialiasing') variable = 'data.antialiasing';
			if (classVar == 'ClientPrefs' && !classVar.startsWith('data.')) variable = 'data.' + variable;
			#if PsychExtended_ExtraPauseMenus
			if (classVar == 'PauseSubState' && ClientPrefs.data.PauseMenuStyle == 'NovaFlare') classVar = 'extras.substates.PauseSubStateNOVA';
			#end
			//Normal Code
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				var coverMeInPiss:Dynamic = LuaUtils.getVarInArray(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length-1) {
					coverMeInPiss = LuaUtils.getVarInArray(coverMeInPiss, killMe[i]);
				}
				LuaUtils.setVarInArray(coverMeInPiss, killMe[killMe.length-1], value);
				return true;
			}
			LuaUtils.setVarInArray(Type.resolveClass(classVar), variable, value);
			return true;
		});

		Lua_helper.add_callback(lua, "callMethod", function(funcToRun:String, ?args:Array<Dynamic> = null) {
			return callMethodFromObject(PlayState.instance, funcToRun, args);

		});
		Lua_helper.add_callback(lua, "callMethodFromClass", function(className:String, funcToRun:String, ?args:Array<Dynamic> = null) {
			return callMethodFromObject(Type.resolveClass(className), funcToRun, args);
		});

		Lua_helper.add_callback(lua, "createInstance", function(variableToSave:String, className:String, ?args:Array<Dynamic> = null) {
			variableToSave = variableToSave.trim().replace('.', '');
			if(!PlayState.instance.variables.exists(variableToSave))
			{
				if(args == null) args = [];
				var myType:Dynamic = Type.resolveClass(className);

				if(myType == null)
				{
					FunkinLua.luaTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, false, FlxColor.RED);
					return false;
				}

				var obj:Dynamic = Type.createInstance(myType, args);
				if(obj != null)
					PlayState.instance.variables.set(variableToSave, obj);
				else
					FunkinLua.luaTrace('createInstance: Failed to create $variableToSave, arguments are possibly wrong.', false, false, FlxColor.RED);

				return (obj != null);
			}
			else FunkinLua.luaTrace('createInstance: Variable $variableToSave is already being used and cannot be replaced!', false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "addInstance", function(objectName:String, ?inFront:Bool = false) {
			if(PlayState.instance.variables.exists(objectName))
			{
				var obj:Dynamic = PlayState.instance.variables.get(objectName);
				if (inFront)
					LuaUtils.getTargetInstance().add(obj);
				else
				{
					if(!PlayState.instance.isDead)
						PlayState.instance.insert(PlayState.instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), obj);
					else
						GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), obj);
				}
			}
			else FunkinLua.luaTrace('addInstance: Can\'t add what doesn\'t exist~ ($objectName)', false, false, FlxColor.RED);
		});
	}

	static function callMethodFromObject(classObj:Dynamic, funcStr:String, args:Array<Dynamic> = null)
	{
		if(args == null) args = [];

		var split:Array<String> = funcStr.split('.');
		var funcToRun:Function = null;
		var obj:Dynamic = classObj;
		//trace('start: $obj');
		if(obj == null)
		{
			return null;
		}

		for (i in 0...split.length)
		{
			obj = LuaUtils.getVarInArray(obj, split[i].trim());
			//trace(obj, split[i]);
		}

		funcToRun = cast obj;
		//trace('end: $obj');
		return funcToRun != null ? Reflect.callMethod(obj, funcToRun, args) : null;
	}

		public static function varCheck(className:Dynamic, variable:String):String{
		return variable;
	}

	public static function classCheck(className:String):Dynamic
	{
		return Type.resolveClass(className);
	}

	#if TOUCH_CONTROLS
	public static function specialKeyCheck(keyName:String):Dynamic
	{
		var textfix:Array<String> = keyName.trim().split('.');
		var type:String = textfix[1].trim();
		var key:String = textfix[2].trim();
		var extraControl:Dynamic = null;

		for (num in 1...5){
			var extraControl = MusicBeatState.mobilec.current;
			if (extraControl.buttonExtra1 != null && extraControl.buttonExtra2 != null && extraControl.buttonExtra3 != null && extraControl.buttonExtra4 != null) {
				if (ClientPrefs.data.extraKeys >= num && key == Reflect.field(ClientPrefs.data, 'extraKeyReturn' + num)){
					if (MusicBeatState.mobilec.newhbox != null)
						extraControl = Reflect.getProperty(MusicBeatState.mobilec.newhbox, 'buttonExtra' + num);
					else
						extraControl = Reflect.getProperty(MusicBeatState.mobilec.vpad, 'buttonExtra' + num);
					if (Reflect.getProperty(extraControl, type))
						return true;
				}
			}
		}
		return null;
	}
	#end
}