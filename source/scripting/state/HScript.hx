package scripting.state;

import flixel.FlxBasic;
import Character;
import psychlua.LuaUtils;
import psychlua.FunkinLua;
import scripting.ScriptingVars;
import psychlua.CustomSubstate;

#if SCRIPTING_ALLOWED
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import scripting.state.HScript;
import scripting.substate.ScriptSubstate;
import crowplexus.hscript.Parser;

import haxe.ValueException;

typedef HScriptInfos = {
	> haxe.PosInfos,
	var ?funcName:String;
	var ?showLine:Null<Bool>;
}

class HScript extends Iris
{
	public var filePath:String;
	public var modFolder:String;
	public var returnValue:Dynamic;
	public static var myClass:Dynamic;
	public var publicVariables:Map<String, Dynamic> = [];

	public function setParent(parent:Dynamic) {
		interp.scriptObject = parent;
	}

	public function setPublicMap(map:Map<String, Dynamic>) {
		this.interp.publicVariables = map;
	}

	public var origin:String;
	override public function new(?parent:Dynamic, ?file:String, ?varsToBring:Any = null, ?manualRun:Bool = false)
	{
		if(ScriptState.instance == FlxG.state) myClass = ScriptState.instance;
		else myClass = HScriptStateHandler.getState();

		if (file == null)
			file = '';

		filePath = file;
		if (filePath != null && filePath.length > 0)
		{
			this.origin = filePath;
			#if MODS_ALLOWED
			var myFolder:Array<String> = filePath.split('/');
			#if android
			var fixedPath:String = Paths.getFixedMobilePath(filePath);
			myFolder = fixedPath.split('/');
			#end

			if(myFolder[0] + '/' == Paths.mods(#if android '', true #end) && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
				this.modFolder = myFolder[1];
			#end
		}
		var scriptThing:String = file;
		var scriptName:String = null;
		if(parent == null && file != null)
		{
			var f:String = file.replace('\\', '/');
			if(f.contains('/') && !f.contains('\n')) {
				scriptThing = File.getContent(f);
				scriptName = f;
			}
		}
		super(scriptThing, new IrisConfig(scriptName, false, false));
		preset();
		parser.preprocessorValues = crowplexus.iris.macro.DefineMacro.defines;
		interp.staticVariables = ScriptingVars.staticVariables;
		interp.allowStaticVariables = interp.allowPublicVariables = true;
		this.varsToBring = varsToBring;
		if (!manualRun) {
			try {
				var ret:Dynamic = execute();
				returnValue = ret;
			} catch(e:IrisError) {
				returnValue = null;
				this.destroy();
				throw e;
			}
		}
	}

	var varsToBring(default, set):Any = null;
	override function preset() {
		super.preset();

		if(ScriptState.instance == FlxG.state) myClass = ScriptState.instance;
		else myClass = HScriptStateHandler.getState();

		// Some very commonly used classes
		set('Type', Type);
		#if sys
		set('File', File);
		set('FileSystem', FileSystem);
		#end
		set('FlxG', flixel.FlxG);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxText', flixel.text.FlxText);
		set('FlxCamera', flixel.FlxCamera);
		set('PsychCamera', backend.PsychCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('FlxColor', psychlua.HScript.CustomFlxColor);
		set('Countdown', backend.BaseStage.Countdown);
		set('PlayState', PlayState);
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		#if ACHIEVEMENTS_ALLOWED
		set('Achievements', Achievements);
		#end
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('Note', Note);
		set('CustomSubstate', CustomSubstate);
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		//set('ErrorHandledRuntimeShader', shaders.ErrorHandledShader.ErrorHandledRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('CustomShader', funkin.backend.shaders.CustomShader); //CustomShader from CNE
		set('StringTools', StringTools);
		#if flxanimate
		set('FlxAnimate', FlxAnimate);
		#end

		// Some very commonly used classes for State Scripting
		set('File', sys.io.File);
		set('Json', haxe.Json);
		set('Lib', openfl.Lib);
		set('ScriptingVars', scripting.ScriptingVars);
		set('CustomSwitchState', extras.CustomSwitchState);
		set('CoolUtil', CoolUtil);
		set('Reflect', Reflect);
		set('MusicBeatState', MusicBeatState);
		set('AttachedText', AttachedText);
		set('MenuCharacter', MenuCharacter);
		set('DialogueCharacterEditorState', editors.DialogueCharacterEditorState);
		set('DialogueEditorState', editors.DialogueEditorState);
		set('MenuCharacterEditorState', editors.MenuCharacterEditorState);
		set('WeekEditorState', editors.WeekEditorState);
		set('GameplayChangersSubstate', GameplayChangersSubstate);
		set('ControlsSubState', options.ControlsSubState);
		set('NoteOffsetState', options.NoteOffsetState);
		set('NotesSubState', options.NotesSubState);
		set('ScriptState', scripting.state.ScriptState);
		set('ScriptSubstate', scripting.substate.ScriptSubstate);

		set('FlxFlicker', flixel.effects.FlxFlicker);
		set('FlxBackdrop', flixel.addons.display.FlxBackdrop);
		set('FlxOgmo3Loader', flixel.addons.editors.ogmo.FlxOgmo3Loader);
		set('FlxTilemap', flixel.tile.FlxTilemap);
		set('Process', sys.io.Process);

		//Codename Engine
		set('FunkinText', funkin.backend.FunkinText); //Not Tested! (EDIT: after the 7 hours later, I can tell It's works)
		set('FunkinShader', funkin.backend.shaders.FunkinShader);
		set('CustomShader', funkin.backend.shaders.CustomShader);

		//ScriptedState Functions
		set("switchToScriptState", function(name:String, ?doTransition:Bool = true)
		{
			FlxTransitionableState.skipNextTransIn = !doTransition;
			FlxTransitionableState.skipNextTransOut = !doTransition;
			MusicBeatState.switchState(new ScriptState(name));
		});
		set('openScriptSubState', function(substate:String)
		{
			FlxG.state.openSubState(new ScriptSubstate(substate));
		});
		
		set("setGlobalVar", function(id:String, data:Dynamic)
		{
			ScriptingVars.globalVars.set(id, data);
		});
		set("getGlobalVar", function(id:String)
		{
			return ScriptingVars.globalVars.get(id);
		});
		set("existsGlobalVar", function(id:String)
		{
			return ScriptingVars.globalVars.exists(id);
		});
		set("removeGlobalVar", function(id:String)
		{
			ScriptingVars.globalVars.remove(id);
		});
		
		set('fpsLerp', function(v1:Float, v2:Float, ratio:Float)
		{
			return CoolUtil.fpsLerp(v1, v2, ratio);
		});
	
		set('getFPSRatio', function(ratio:Float)
		{
			return CoolUtil.getFPSRatio(ratio);
		});

		// Functions & Variables

		//Originals
		set('setVar', function(name:String, value:Dynamic) {
			myClass.variables.set(name, value);
			return value;
		});
		set('getVar', function(name:String) {
			var result:Dynamic = null;
			if(myClass.variables.exists(name)) result = myClass.variables.get(name);
			return result;
		});
		set('removeVar', function(name:String)
		{
			if(myClass.variables.exists(name))
			{
				myClass.variables.remove(name);
				return true;
			}
			return false;
		});

		//Substate
		set('setSubstateVar', function(name:String, value:Dynamic) {
			HScriptSubStateHandler.variables.set(name, value);
			return value;
		});
		set('getSubstateVar', function(name:String) {
			var result:Dynamic = null;
			if(HScriptSubStateHandler.variables.exists(name)) result = HScriptSubStateHandler.variables.get(name);
			return result;
		});
		set('removeSubstateVar', function(name:String)
		{
			if(HScriptSubStateHandler.variables.exists(name))
			{
				HScriptSubStateHandler.variables.remove(name);
				return true;
			}
			return false;
		});

		//PlayState
		set('setPlayStateVar', function(name:String, value:Dynamic) {
			PlayState.instance.variables.set(name, value);
			return value;
		});
		set('getPlayStateVar', function(name:String) {
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		set('removePlayStateVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});

		//Script State
		set('setScriptStateVar', function(name:String, value:Dynamic) {
			ScriptSubstate.variables.set(name, value);
			return value;
		});
		set('getScriptStateVar', function(name:String) {
			var result:Dynamic = null;
			if(ScriptState.instance.variables.exists(name)) result = ScriptState.instance.variables.get(name);
			return result;
		});
		set('removeScriptStateVar', function(name:String)
		{
			if(ScriptState.instance.variables.exists(name))
			{
				ScriptState.instance.variables.remove(name);
				return true;
			}
			return false;
		});

		//Script SubState
		set('setScriptSubstateVar', function(name:String, value:Dynamic) {
			ScriptState.instance.variables.set(name, value);
			return value;
		});
		set('getScriptSubstateVar', function(name:String) {
			var result:Dynamic = null;
			if(ScriptSubstate.variables.exists(name)) result = ScriptSubstate.variables.get(name);
			return result;
		});
		set('removeScriptSubstateVar', function(name:String)
		{
			if(ScriptSubstate.variables.exists(name))
			{
				ScriptSubstate.variables.remove(name);
				return true;
			}
			return false;
		});

		//Others
		set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			myClass.addTextToDebug(text, color);
		});

		set('getModSetting', function(saveTag:String, ?modName:String = null) {
			if(modName == null)
			{
				if(this.modFolder == null)
				{
					Iris.error('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', this.interp.posInfos());
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
		});

		// For adding your own callbacks
		#if LUAVPAD_ALLOWED
		set('getSpesificVPadButton', function(buttonPostfix:String):Dynamic
		{
			var buttonName = "button" + buttonPostfix;
			return Reflect.getProperty(myClass._hxvirtualpad, buttonName); //This Needs to be work
			return null;
		});
		#end

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';

				set(libName, Type.resolveClass(str + libName));
			}
			catch (e:IrisError) {
				Iris.error(Printer.errorToString(e, false), this.interp.posInfos());
			}
		});
		set('parentLua', null);
		set('this', this);
		set('game', FlxG.state);
		set('state', FlxG.state);
		set('substate', FlxG.state.subState);
		set('controls', PlayerSettings.player1.controls);

		set('buildTarget', FunkinLua.getBuildTarget());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);

		set('Function_Stop', FunkinLua.Function_Stop);
		set('Function_Continue', FunkinLua.Function_Continue);
		set('Function_StopLua', FunkinLua.Function_StopLua); //doesnt do much cuz HScript has a lower priority than Lua
		set('Function_StopHScript', FunkinLua.Function_StopHScript);
		set('Function_StopAll', FunkinLua.Function_StopAll);
	}

	override function call(funcToRun:String, ?args:Array<Dynamic>):IrisCall {
		if(ScriptState.instance == FlxG.state) myClass = ScriptState.instance;
		else myClass = HScriptStateHandler.getState();

		if (funcToRun == null || interp == null) return null;

		if (!exists(funcToRun)) {
			Iris.error('No function named: $funcToRun', this.interp.posInfos());
			return null;
		}

		try {
			var func:Dynamic = interp.variables.get(funcToRun); // function signature
			final ret = Reflect.callMethod(null, func, args ?? []);
			return {funName: funcToRun, signature: func, returnValue: ret};
		}
		catch(e:IrisError) {
			var pos:HScriptInfos = cast this.interp.posInfos();
			pos.funcName = funcToRun;
			Iris.error(Printer.errorToString(e, false), pos);
		}
		catch (e:ValueException) {
			var pos:HScriptInfos = cast this.interp.posInfos();
			pos.funcName = funcToRun;
			Iris.error('$e', pos);
		}
		return null;
	}

	override public function destroy()
	{
		origin = null;
		super.destroy();
	}

	function set_varsToBring(values:Any) {
		if (varsToBring != null)
			for (key in Reflect.fields(varsToBring))
				if (exists(key.trim()))
					interp.variables.remove(key.trim());

		if (values != null)
		{
			for (key in Reflect.fields(values))
			{
				key = key.trim();
				set(key, Reflect.field(values, key));
			}
		}

		return varsToBring = values;
	}
}
#else
class HScript
{
	//Nothing
}
#end