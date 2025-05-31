package;

import Conductor.BPMChangeEvent;
import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.input.actions.FlxActionInput;
import backend.PsychCamera;

import flixel.input.actions.FlxActionInput;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}
	
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public var _virtualpad:FlxVirtualPad;
	public static var mobilec:MobileControls;
	var trackedinputsUI:Array<FlxActionInput> = [];
	var trackedinputsNOTES:Array<FlxActionInput> = [];
	
	public function addVirtualPad(?DPad:String, ?Action:String) {
		_virtualpad = new FlxVirtualPad(DPad, Action);
		add(_virtualpad);
		controls.setVirtualPadUI(_virtualpad, DPad, Action);
		trackedinputsUI = controls.trackedInputsUI;
		controls.trackedInputsUI = [];
		_virtualpad.alpha = ClientPrefs.data.VirtualPadAlpha;
	}
	
	public function addMobileControls() {
		mobilec = new MobileControls();

		switch (MobileControls.mode)
		{
			case VIRTUALPAD_RIGHT | VIRTUALPAD_LEFT | VIRTUALPAD_CUSTOM:
				controls.setVirtualPadNOTES(mobilec.vpad, "FULL", "NONE");
				MusicBeatState.checkHitbox = false;
			case DUO:
				controls.setVirtualPadNOTES(mobilec.vpad, "DUO", "NONE");
				MusicBeatState.checkHitbox = false;
			case HITBOX:
				if(ClientPrefs.data.hitboxmode == 'Classic') controls.setHitBox(mobilec.hbox);
				else controls.setNewHitBox(mobilec.newhbox);
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

	public function removeVirtualPad() {
		if (trackedinputsUI.length > 0)
			controls.removeVirtualControlsInput(trackedinputsUI);

		if (_virtualpad != null)
			remove(_virtualpad);
	}

	public function addVirtualPadCamera() {
		var camcontrol = new flixel.FlxCamera();
		camcontrol.bgColor.alpha = 0;
		FlxG.cameras.add(camcontrol, false);
		_virtualpad.cameras = [camcontrol];
	}
	
	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		return camera;
	}
	
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

		super.update(elapsed);
	}
	
	public static function getSubState():MusicBeatSubstate {
		var curSubState:Dynamic = FlxG.state.subState;
		var leState:MusicBeatSubstate = curSubState;
		return leState;
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

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
	
	public function sectionHit():Void
	{
		//yep, you guessed it, nothing again, dumbass
	}
	
	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
