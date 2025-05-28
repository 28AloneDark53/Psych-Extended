package scripting;

#if SCRIPTING_ALLOWED
import flixel.addons.ui.FlxUIState;
import scripting.state.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import scripting.state.HScript;

class HScriptClassHandler
{
	public static var instance:HScriptClassHandler;
	public var hscriptArray:Array<HScript> = [];
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	function new() {
		create();
	}

	public function create()
	{
		instance = this;
	}

	function destroy() {
		instance = null;
		for (script in hscriptArray)
			if(script != null)
			{
				if(script.exists('onDestroy')) script.call('onDestroy');
				else if (script.exists('destroy')) script.call('destroy');
				script.destroy();
			}
		hscriptArray = null;
	}

	public function startHScriptsNamed(scriptFile:String, ?disableModCheck:Bool = false)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders('scripts/classes/' + scriptFile);
		var scriptNotFromFirstEnabledMod:Bool = (FileSystem.exists(scriptToLoad) && Mods.getTopMod() != Mods.currentModDirectory); //Class Special
		if(!FileSystem.exists(scriptToLoad) || disableModCheck || scriptNotFromFirstEnabledMod)
			scriptToLoad = Paths.getScriptPath('classes/' + scriptFile);
		#else
		var scriptToLoad:String = Paths.getScriptPath('classes/' + scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		try
		{
			var newScript = new HScript(null, file);
			trace('initialized hscript interp successfully: $file');
			hscriptArray.push(newScript);
		}
		catch(e:IrisError)
		{
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			Iris.error(Printer.errorToString(e, false), pos);
			var newScript:HScript = cast (Iris.instances.get(file), HScript);
			if(newScript != null)
				newScript.destroy();
		}
	}

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		return callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;

		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(FunkinLua.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;

		for(script in hscriptArray)
		{
			@:privateAccess
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var callValue = script.call(funcToCall, args);
			if(callValue != null)
			{
				var myValue:Dynamic = callValue.returnValue;

				if((myValue == FunkinLua.Function_StopHScript || myValue == FunkinLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if(myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;
			}
		}

		switch (funcToCall) //Codename Engine Functions (if you're using `update` function in your code, Don't add `onUpdate`)
		{
			case 'onCreate': callOnScripts('create', args, ignoreStops, exclusions, excludeValues);
			case 'onCreatePost': callOnScripts('postCreate', args, ignoreStops, exclusions, excludeValues);
			case 'onUpdate': callOnScripts('update', args, ignoreStops, exclusions, excludeValues);
			case 'onUpdatePost': callOnScripts('postUpdate', args, ignoreStops, exclusions, excludeValues);
			case 'onDestroy': callOnScripts('destroy', args, ignoreStops, exclusions, excludeValues);
			case 'onCloseSubState': callOnScripts('closeSubState', args, ignoreStops, exclusions, excludeValues);
			case 'onCloseSubStatePost': callOnScripts('postCloseSubState', args, ignoreStops, exclusions, excludeValues);
		}

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			script.set(variable, arg);
		}
	}

	//get Current State (used for Error Thing)
	public static function getCurrentState():HScriptStateHandler {
		var curState:Dynamic = FlxG.state;
		var leState:HScriptStateHandler = curState;
		return leState;
	}

	public function switchMenusNew(StatePrefix:String, ?skipTrans:Bool = false, ?skipTransCustom:String = '') {}
}
#else
typedef HScriptClassHandler = MusicBeatState;
#end