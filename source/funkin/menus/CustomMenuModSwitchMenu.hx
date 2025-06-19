package funkin.menus;

import haxe.io.Path;
import sys.FileSystem;
import flixel.tweens.FlxTween;
#if SCRIPTING_ALLOWED
import scripting.HScript;
#end

//Tooked from https://github.com/CodenameCrew/CodenameEngine/blob/main/source/funkin/menus/ModSwitchMenu.hx
class CustomMenuModSwitchMenu extends MusicBeatSubstate {
	var mods:Array<String> = [];
	var alphabets:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 0;
	var fadeCamera:FlxCamera = new FlxCamera();

	public override function create() {
		super.create();

		var bg = new FlxSprite(0, 0).makeSolid(1280, 720, 0xFF000000);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);

		bg.alpha = 0;
		FlxTween.tween(bg, {alpha: 0.5}, 0.25, {ease: FlxEase.cubeOut});

		mods = Mods.enabledMods; //Get Enabled ones instead of every single mod
		mods.push(null);

		alphabets = new FlxTypedGroup<Alphabet>();
		for(mod in mods) {
			var a = new Alphabet(100, 360, mod == null ? "DISABLE MENUS" : mod, true);
			a.isMenuItem = true;
			a.scrollFactor.set();
			alphabets.add(a);
		}
		add(alphabets);
		changeSelection(0, true);

		#if TOUCH_CONTROLS
		addMobilePad("UP_DOWN", "A_B");
		#end
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		fadeCamera.bgColor.alpha = 0;
		FlxG.cameras.add(fadeCamera, false);
	}

	public override function update(elapsed:Float) {
		if (controls.ACCEPT) {
			Mods.selectMenuMod(mods[curSelected]);

			#if SCRIPTING_ALLOWED
			Script.staticVariables = []; //make sure nothings left from previous mod
			#end
			//Restart the game
			TitleState.initialized = false;
			TitleState.closedState = false;
			FlxG.sound.music.fadeOut(0.3);
			fadeCamera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
		}

		if (controls.BACK) {
			close();
		}

		super.update(elapsed);

		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}
	}

	public function changeSelection(change:Int, force:Bool = false) {
		if (change == 0 && !force) return;

		curSelected += change;
		if (curSelected < 0)
			curSelected = alphabets.length - 1;
		if (curSelected >= alphabets.length)
			curSelected = 0;

		for(k=>alphabet in alphabets.members) {
			alphabet.alpha = 0.6;
			alphabet.targetY = k - curSelected;
		}
		alphabets.members[curSelected].alpha = 1;
	}
}