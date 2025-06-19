package states.stages.erect;

import shaders.DropShadowShader;
import shaders.WiggleEffectRuntime;
import flixel.addons.effects.FlxTrail;
import openfl.utils.Assets as OpenFlAssets;

class SchoolEvilErect extends BaseStage
{
	var bg:BGSprite;
	var wiggle:WiggleEffectRuntime;

	override function create()
	{
		var _song = PlayState.SONG;
		if (_song.gameOverSound == null || _song.gameOverSound.trim().length < 1)
			GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
		if (_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1)
			GameOverSubstate.loopSoundName = 'gameOver-pixel';
		if (_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1)
			GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
		if (_song.gameOverChar == null || _song.gameOverChar.trim().length < 1)
			GameOverSubstate.characterName = 'bf-pixel-dead';

		var posX = 410;
		var posY = 390;

		bg = new BGSprite('weeb/erect/evilSchoolBG', posX, posY, 0.8, 0.9);
		bg.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
		bg.antialiasing = false;
		add(bg);

		setDefaultGF('gf-pixel');

		FlxG.sound.playMusic(Paths.music('LunchboxScary'), 0);
		FlxG.sound.music.fadeIn(1, 0, 0.8);
		if(isStoryMode && !seenCutscene)
		{
			initDoof();
			setStartCallback(schoolIntro);
		}
	}

	override function createPost()
	{
		var trail:FlxTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
		if (ClientPrefs.data.shaders)
		{
			wiggle = new WiggleEffectRuntime(2, 4, 0.017, WiggleEffectTypeClone.DREAMY);
			bg.shader = wiggle;
		}
		addBehindDad(trail);
		if (ClientPrefs.data.shaders)
			{
				applyShader(boyfriend, boyfriend.curCharacter);
				applyShader(gf, gf.curCharacter);
				applyShader(dad, dad.curCharacter);
				
			}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		wiggle?.update(elapsed);
	}

	// Ghouls event
	var bgGhouls:BGSprite;

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch (eventName)
		{
			case "Trigger BG Ghouls":
				if (!ClientPrefs.data.lowQuality)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}
		}
	}

	override function eventPushed(event:Note.EventNote)
	{
		// used for preloading assets used on events
		switch (event.event)
		{
			case "Trigger BG Ghouls":
				if (!ClientPrefs.data.lowQuality)
				{
					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * PlayState.daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					bgGhouls.animation.finishCallback = function(name:String)
					{
						if (name == 'BG freaks glitch instance')
							bgGhouls.visible = false;
					}
					addBehindGF(bgGhouls);
				}
		}
	}
	function applyShader(sprite:FlxSprite, char_name:String)
		{
			var rim = new DropShadowShader();
			rim.setAdjustColor(-66, -10, 24, -23);
			rim.color = 0xFF641B1B;
			rim.antialiasAmt = 0;
			rim.attachedSprite = sprite;
			rim.distance = 5;
			switch (char_name)
			{
				case "bf-pixel":
					{
						rim.angle = 90;
						sprite.shader = rim;
	
						// rim.loadAltMask('assets/week6/images/weeb/erect/masks/bfPixel_mask.png');
						rim.altMaskImage = Paths.image("weeb/erect/masks/bfPixel_mask").bitmap;
						rim.maskThreshold = 1;
						rim.useAltMask = true;
	
						sprite.animation.callback = function(anim, frame, index)
						{
							rim.updateFrameInfo(sprite.frame);
						};
					}
				case "pico-pixel":
					{
						rim.angle = 90;
						sprite.shader = rim;
	
						// rim.loadAltMask('assets/week6/images/weeb/erect/masks/bfPixel_mask.png');
						rim.altMaskImage = Paths.image("weeb/erect/masks/picoPixel_mask").bitmap;
						rim.maskThreshold = 1;
						rim.useAltMask = true;
	
						sprite.animation.callback = function(anim, frame, index)
						{
							rim.updateFrameInfo(sprite.frame);
						};
					}
				case "gf-pixel":
					{
						rim.setAdjustColor(-42, -10, 5, -25);
						rim.angle = 90;
						sprite.shader = rim;
						rim.distance = 3;
						rim.threshold = 0.3;
						rim.altMaskImage = Paths.image("weeb/erect/masks/gfPixel_mask").bitmap;
						rim.maskThreshold = 1;
						rim.useAltMask = true;
	
						sprite.animation.callback = function(anim, frame, index)
						{
							rim.updateFrameInfo(sprite.frame);
						};
					}
				case "nene-pixel":
					{
						rim.setAdjustColor(-42, -10, 5, -25);
						rim.angle = 90;
						sprite.shader = rim;
						rim.distance = 3;
						rim.threshold = 0.3;
						rim.altMaskImage = Paths.image("weeb/erect/masks/nenePixel_mask").bitmap;
						rim.maskThreshold = 1;
						rim.useAltMask = true;
						sprite.animation.callback = function(anim, frame, index)
						{
							rim.updateFrameInfo(sprite.frame);
						};
					}
	
				case "spirit":
					{
						rim.angle = 90;
						sprite.shader = rim;
						rim.setAdjustColor(0, -10, 44, -13);
						rim.useAltMask = false;
	
						sprite.animation.callback = function(anim, frame, index)
						{
							rim.updateFrameInfo(sprite.frame);
						};
					}
				default:
					{
						rim.angle = 90;
						sprite.shader = rim;
						sprite.animation.callback = function(anim, frame, index)
						{
							rim.updateFrameInfo(sprite.frame);
						};
					}
			}
		}

	var doof:DialogueBox = null;
	function initDoof()
	{
		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		#if MODS_ALLOWED
		if (!FileSystem.exists(file))
		#else
		if (!OpenFlAssets.exists(file))
		#end
		{
			startCountdown();
			return;
		}

		doof = new DialogueBox(false, CoolUtil.coolTextFile(file));
		doof.cameras = [camHUD];
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = PlayState.instance.startNextDialogue;
		doof.skipDialogueThing = PlayState.instance.skipDialogue;
	}

	function schoolIntro():Void
	{
		inCutscene = true;
		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();
		add(red);

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;
		camHUD.visible = false;

		new FlxTimer().start(2.1, function(tmr:FlxTimer)
		{
			if (doof != null)
			{
				add(senpaiEvil);
				senpaiEvil.alpha = 0;
				new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
				{
					senpaiEvil.alpha += 0.15;
					if (senpaiEvil.alpha < 1)
					{
						swagTimer.reset();
					}
					else
					{
						senpaiEvil.animation.play('idle');
						FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
						{
							remove(senpaiEvil);
							senpaiEvil.destroy();
							remove(red);
							red.destroy();
							FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
							{
								add(doof);
								camHUD.visible = true;
							}, true);
						});
						new FlxTimer().start(3.2, function(deadTime:FlxTimer)
						{
							FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
						});
					}
				});
			}
		});
	}
}
