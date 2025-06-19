package;

import Conductor.BPMChangeEvent;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxBasic;
import backend.PsychCamera;

#if SCRIPTING_ALLOWED
import scripting.HScript;
#end
import funkin.backend.scripting.events.CancellableEvent;

import flixel.input.actions.FlxActionInput;

class MusicBeatState extends FlxUIState
{
	public static var instance:MusicBeatState;

	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	public function resetMusicVars()
	{
		curSection = 0;
		stepsToDo = 0;

		curStep = 0;
		curBeat = 0;

		curDecStep = 0;
		curDecBeat = 0;
	}

	public var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	#if TOUCH_CONTROLS
	public static var checkHitbox:Bool = false;
	public var _virtualpad:MobilePad;
	public static var mobilec:MobileControls;

	var trackedinputsUI:Array<FlxActionInput> = [];
	var trackedinputsNOTES:Array<FlxActionInput> = [];

	public function checkMobileControlVisible(selectedButton:String) {
		var buttonsVisible:Bool = false;
		for (button in _virtualpad.createdButtons) {
			var buttonName:String = "button" + button;
			var buttonVisibility:Bool = Reflect.getProperty(_virtualpad, buttonName).visible;
			if (button != selectedButton && buttonsVisible != buttonVisibility) buttonsVisible = buttonVisibility;
		}
		return buttonsVisible;
	}

	public function changeMobileControlVisible(selectedButton:String, ?visible:Bool = false) {
		for (button in _virtualpad.createdButtons) {
			var buttonName:String = "button" + button;
			if (button != selectedButton) Reflect.getProperty(_virtualpad, buttonName).visible = visible;
		}
	}

	public function addMobilePad(?DPad:String, ?Action:String) {
		if (_virtualpad != null)
			removeVirtualPad();

		_virtualpad = new MobilePad(DPad, Action);
		add(_virtualpad);

		controls.setMobilePadUI(_virtualpad, DPad, Action);
		trackedinputsUI = controls.trackedInputsUI;
		controls.trackedInputsUI = [];
		_virtualpad.alpha = ClientPrefs.data.mobilePadAlpha;
	}

	public function removeMobilePad() {
		if (trackedinputsUI.length > 0)
			controls.removeVirtualControlsInput(trackedinputsUI);

		if (_virtualpad != null)
			remove(_virtualpad);
	}

	public function addVirtualPad(?DPad:String, ?Action:String)
		return addMobilePad(DPad, Action);

	public function removeVirtualPad()
		return removeMobilePad();

	public function removeMobileControls() {
		if (trackedinputsNOTES.length > 0)
			controls.removeVirtualControlsInput(trackedinputsNOTES);

		if (mobilec != null)
			remove(mobilec);
	}

	public function addMobileControls(?mode:String) {
		mobilec = new MobileControls(mode);

		switch (MobileControls.mode)
		{
			case MOBILEPAD_RIGHT | MOBILEPAD_LEFT | MOBILEPAD_CUSTOM:
				controls.setMobilePadNOTES(mobilec.vpad, "FULL", "NONE");
				MusicBeatState.checkHitbox = false;
			case DUO:
				controls.setMobilePadNOTES(mobilec.vpad, "DUO", "NONE");
				MusicBeatState.checkHitbox = false;
			case HITBOX:
				controls.setHitBox(mobilec.newhbox, mobilec.hbox);
				MusicBeatState.checkHitbox = true;
			default:
		}

		trackedinputsNOTES = controls.trackedInputsNOTES;
		controls.trackedInputsNOTES = [];

		var camcontrol = new flixel.FlxCamera();
		FlxG.cameras.add(camcontrol, false);
		camcontrol.bgColor.alpha = 0;
		mobilec.cameras = [camcontrol];

		add(mobilec);
	}

	public function addMobilePadCamera() {
		var camcontrol = new flixel.FlxCamera();
		camcontrol.bgColor.alpha = 0;
		FlxG.cameras.add(camcontrol, false);
		_virtualpad.cameras = [camcontrol];
	}

	public function addVirtualPadCamera()
		return addMobilePadCamera();

	override function destroy() {
		if (trackedinputsNOTES.length > 0)
			controls.removeVirtualControlsInput(trackedinputsNOTES);

		if (trackedinputsUI.length > 0)
			controls.removeVirtualControlsInput(trackedinputsUI);

		super.destroy();

		if (_virtualpad != null)
			_virtualpad = FlxDestroyUtil.destroy(_virtualpad);

		if (mobilec != null)
			mobilec = FlxDestroyUtil.destroy(mobilec);

		call("destroy");
		#if SCRIPTING_ALLOWED
		stateScripts = FlxDestroyUtil.destroy(stateScripts);
		#end
	}
	#else
	#if SCRIPTING_ALLOWED
	override function destroy() {
		call("destroy");
		#if SCRIPTING_ALLOWED
		stateScripts = FlxDestroyUtil.destroy(stateScripts);
		#end
	}
	#end
	#end

	override function create() {
		#if SCRIPTING_ALLOWED loadScript(); #end

		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end
		super.create();

		if(!skip) {
			#if PsychExtended_ExtraTransitions
			if (ClientPrefs.data.TransitionStyle == 'NovaFlare')
				openSubState(new CustomFadeTransitionNOVA(0.7, true));
			else
			#end
				openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
	}

	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		// _psychCameraInitialized = true;
		//trace('initialized psych camera ' + Sys.cpuTime());
		return camera;
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		call("update", [elapsed]);

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null) {
		FunkinLua.FPSCounterText = null;
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state)
		{
			resetState();
			return;
		}

		if(FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		if(FlxTransitionableState.skipNextTransIn) FlxG.resetState();
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}
	
	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if(nextState == null)
			nextState = FlxG.state;

		#if PsychExtended_ExtraTransitions
		if (ClientPrefs.data.TransitionStyle == 'NovaFlare')
			FlxG.state.openSubState(new CustomFadeTransitionNOVA(0.6, false));
		else
		#end
			FlxG.state.openSubState(new CustomFadeTransition(0.6, false));

		#if PsychExtended_ExtraTransitions
		if (ClientPrefs.data.TransitionStyle == 'NovaFlare')
		{
			if(nextState == FlxG.state)
				CustomFadeTransitionNOVA.finishCallback = function() FlxG.resetState();
			else
				CustomFadeTransitionNOVA.finishCallback = function() FlxG.switchState(nextState);
		}
		else
		{
		#end
			if(nextState == FlxG.state)
				CustomFadeTransition.finishCallback = function() FlxG.resetState();
			else
				CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
		#if PsychExtended_ExtraTransitions
		}
		#end
	}

	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});
		
		if (curStep % 4 == 0)
			beatHit();
	}

	public var stages:Array<BaseStage> = [];
	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}
	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	/**
	 * SCRIPTING STUFF
	 */
	#if SCRIPTING_ALLOWED
	public var scriptsAllowed:Bool = true;

	/**
	 * Current injected script attached to the state. To add one, create a file at path "data/states/stateName" (ex: data/states/FreeplayState)
	 */
	public var stateScripts:ScriptPack;

	public static var lastScriptName:String = null;
	public static var lastStateName:String = null;

	public var scriptName:String = null;

	public function new(scriptsAllowed:Bool = true, ?scriptName:String) {
		super();
		if(lastStateName != (lastStateName = Type.getClassName(Type.getClass(this)))) {
			lastScriptName = null;
		}
		this.scriptName = scriptName != null ? scriptName : lastScriptName;
		lastScriptName = this.scriptName;
	}

	function loadScript(?customPath:String) {
		var className = Type.getClassName(Type.getClass(this));
		if (stateScripts == null)
			(stateScripts = new ScriptPack(className)).setParent(this);
		if (scriptsAllowed) {
			if (stateScripts.scripts.length == 0) {
				var scriptName = this.scriptName != null ? this.scriptName : className.substr(className.lastIndexOf(".")+1);
				var filePath:String = "states/" + scriptName;
				if (customPath != null)
					filePath = customPath;
				var path = Paths.script(filePath);
				var script = Script.create(path);
				script.remappedNames.set(script.fileName, '${script.fileName}');
				stateScripts.add(script);
				script.load();
				call('create');
			}
			else stateScripts.reload();
		}
	}
	#end

	public function call(name:String, ?args:Array<Dynamic>, ?defaultVal:Dynamic):Dynamic {
		// calls the function on the assigned script
		#if SCRIPTING_ALLOWED
		if(stateScripts != null)
			return stateScripts.call(name, args);
		#end
		return defaultVal;
	}

	public function event<T:CancellableEvent>(name:String, event:T):T {
		#if SCRIPTING_ALLOWED
		if(stateScripts != null)
			stateScripts.call(name, [event]);
		#end
		return event;
	}

	override function closeSubState() {
		super.closeSubState();
		call('onCloseSubState');
	}

	public function closeSubStatePost() {
		call('onCloseSubStatePost');
	}

	public override function createPost() {
		super.createPost();
		persistentUpdate = true;
		call("postCreate");
	}

	public override function tryUpdate(elapsed:Float):Void
	{
		if (persistentUpdate || subState == null) {
			call("preUpdate", [elapsed]);
			update(elapsed);
			call("postUpdate", [elapsed]);
		}

		if (_requestSubStateReset)
		{
			_requestSubStateReset = false;
			resetSubState();
		}
		if (subState != null)
		{
			subState.tryUpdate(elapsed);
		}
	}
}
