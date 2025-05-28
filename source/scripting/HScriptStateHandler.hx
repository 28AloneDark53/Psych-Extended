package scripting;

#if SCRIPTING_ALLOWED
import scripting.state.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import scripting.state.HScript;

class HScriptStateHandler extends MusicBeatState
{
	public var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public static var instance:HScriptStateHandler;
	public var hscriptArray:Array<HScript> = [];
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	#if HXVIRTUALPAD_ALLOWED
	public var _hxvirtualpad:FlxVirtualPad;
	#end

	override function create()
	{
		instance = this;
		super.create();

		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		add(luaDebugGroup);

		Iris.warn = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(WARN, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (HScriptStateHandler.instance != null) HScriptStateHandler.instance.addTextToDebug('WARNING: $msgInfo', FlxColor.YELLOW);
		}
		Iris.error = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(ERROR, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (HScriptStateHandler.instance != null) HScriptStateHandler.instance.addTextToDebug('ERROR: $msgInfo', FlxColor.RED);
		}
		Iris.fatal = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(FATAL, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (HScriptStateHandler.instance != null) HScriptStateHandler.instance.addTextToDebug('FATAL: $msgInfo', 0xFFBB0000);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		super.stepHit();
		if(curStep >= lastStepHit) return;
		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if(lastBeatHit >= curBeat) return;
		super.beatHit();
		lastBeatHit = curBeat;
		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	var lastSectionHit:Int = -1;

	override function sectionHit()
	{
		if (lastSectionHit >= curSection) return;
		super.sectionHit();
		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	public function addTextToDebug(text:String, color:FlxColor) 
	{
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);
		newText.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]]; //fix camera issue
		newText.cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]]; //fix camera issue 2
		luaDebugGroup.add(newText);

		Sys.println(text);
	}

	override function destroy() {
		instance = null;
		for (script in hscriptArray)
			if(script != null)
			{
				if(script.exists('onDestroy')) script.call('onDestroy');
				else if (script.exists('destroy')) script.call('destroy');
				script.destroy();
			}
		hscriptArray = null;
		super.destroy();
		#if HXVIRTUALPAD_ALLOWED
		if (_hxvirtualpad != null)
			_hxvirtualpad = FlxDestroyUtil.destroy(_hxvirtualpad);
		#end
	}

	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders('scripts/states/' + scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getScriptPath('states/' + scriptFile);
		#else
		var scriptToLoad:String = Paths.getScriptPath('states/' + scriptFile);
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
		var newScript:HScript = null;
		try
		{
			(newScript = new HScript(null, file)).setParent(this);
			if (newScript.exists('onCreate')) newScript.call('onCreate');
			else if (newScript.exists('create')) newScript.call('create');
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

	#if HXVIRTUALPAD_ALLOWED
	public function addHxVirtualPad(DPad:String, Action:String)
	{
		if (_hxvirtualpad != null)
			removeHxVirtualPad();

		_hxvirtualpad = new FlxVirtualPad(DPad, Action);
		add(_hxvirtualpad);

		controls.setVirtualPadUI(_hxvirtualpad, DPad, Action);
		trackedinputsUI = controls.trackedInputsUI;
		controls.trackedInputsUI = [];
		_hxvirtualpad.alpha = ClientPrefs.data.VirtualPadAlpha;
	}

	public function addHxVirtualPadCamera()
	{
		var camcontrol = new flixel.FlxCamera();
		camcontrol.bgColor.alpha = 0;
		FlxG.cameras.add(camcontrol, false);
		_hxvirtualpad.cameras = [camcontrol];
	}

	public function removeHxVirtualPad()
	{
		if (trackedinputsUI.length > 0)
			controls.removeVirtualControlsInput(trackedinputsUI);

		if (_hxvirtualpad != null)
			remove(_hxvirtualpad);
	}

	public static function checkVPadPress(buttonPostfix:String, type = 'justPressed') {
		var buttonName = "button" + buttonPostfix;
		var button = Reflect.getProperty(HScriptStateHandler.getState()._hxvirtualpad, buttonName); //Access Spesific HxVirtualPad Button
		return Reflect.getProperty(button, type);
		return false;
	}
	#end

	public static function getState():HScriptStateHandler {
		var curState:Dynamic = FlxG.state;
		var leState:HScriptStateHandler = curState;
		return leState;
	}
}
#else
typedef HScriptStateHandler = MusicBeatState;
#end