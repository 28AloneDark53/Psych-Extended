package states.stages.erect;

import shaders.AdjustColorShader;
import shaders.DropShadowShader;
import openfl.utils.Assets as OpenFlAssets;

class SchoolErect extends BaseStage
{

	override function create()
	{
		PlayState.SONG.splashSkin = "pixelNoteSplash";
		var repositionShit = -200;

		var bgSky:BGSprite = new BGSprite('weeb/erect/weebSky', repositionShit + 38, -78, 0.2, 0.2);
		add(bgSky);
		bgSky.antialiasing = false;

		var foliage:BGSprite = new BGSprite('weeb/erect/weebBackTrees', repositionShit, -10, 0.5, 0.5);
		add(foliage);
		foliage.antialiasing = false;

		var bgSchool:BGSprite = new BGSprite('weeb/erect/weebSchool', repositionShit, -15, 0.8, 0.90);
		add(bgSchool);
		bgSchool.antialiasing = false;

		var bgStreet:BGSprite = new BGSprite('weeb/erect/weebStreet', repositionShit, 0, 0.95, 0.95);
		add(bgStreet);
		bgStreet.antialiasing = false;

		var widShit = Std.int(bgSky.width * PlayState.daPixelZoom);

		if (!ClientPrefs.data.lowQuality)
		{
			var fgTrees:BGSprite = new BGSprite('weeb/erect/weebTreesBack', repositionShit + 15, -15, 0.9, 0.9);
			fgTrees.setGraphicSize(Std.int(widShit));
			fgTrees.updateHitbox();
			add(fgTrees);
			fgTrees.antialiasing = false;
		}

		var bgTrees:FlxSprite = new FlxSprite(repositionShit - 410, -900);
		bgTrees.frames = Paths.getPackerAtlas('weeb/erect/weebTrees');
		bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
		bgTrees.animation.play('treeLoop');
		bgTrees.scrollFactor.set(0.85, 0.85);
		add(bgTrees);
		bgTrees.antialiasing = false;

		if (!ClientPrefs.data.lowQuality)
		{
			var treeLeaves:BGSprite = new BGSprite('weeb/erect/petals', repositionShit + 30, 0, 0.85, 0.85, ['PETALS ALL'], true);
			treeLeaves.setGraphicSize(widShit * 0.95);
			treeLeaves.updateHitbox();
			add(treeLeaves);
			treeLeaves.antialiasing = false;
		}

		bgSky.setGraphicSize(widShit);
		foliage.setGraphicSize(widShit);
		bgSchool.setGraphicSize(widShit);
		bgStreet.setGraphicSize(widShit);
		bgTrees.setGraphicSize(Std.int(widShit * 1.5));

		bgSky.updateHitbox();
		foliage.updateHitbox();
		bgSchool.updateHitbox();
		bgStreet.updateHitbox();
		bgTrees.updateHitbox();

		setDefaultGF('gf-pixel');

		switch (songName)
		{
			case 'senpai':
				FlxG.sound.playMusic(Paths.music('Lunchbox'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			case 'roses':
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
		}
		if(isStoryMode && !seenCutscene)
		{
			if(songName == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
			initDoof();
			setStartCallback(schoolIntro);
		}
	}

	override function createPost(){
		var _song = PlayState.SONG;
		if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
		if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
		if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
		if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';

		if(ClientPrefs.data.shaders) {
		applyShader(boyfriend,boyfriend.curCharacter);
		applyShader(gf,gf.curCharacter);
		applyShader(dad,dad.curCharacter);
		}
		camFollow_set(800, 500);
		camGame.snapToTarget();
	}

	function applyShader(sprite:FlxSprite, char_name:String)
	{
		var rim = new DropShadowShader();
		rim.setAdjustColor(-66, -10, 24, -23);
		rim.color = 0xFF52351d;
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

			case "senpai" | "senpai-angry":
				{
					rim.angle = 90;
					sprite.shader = rim;
					rim.altMaskImage = Paths.image("weeb/erect/masks/senpai_mask").bitmap;
					rim.maskThreshold = 1;
					rim.useAltMask = true;

					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
			case "speakerTop":
				{
					rim.angle = 90;
					sprite.shader = rim;
					rim.altMaskImage = Paths.image("weeb/erect/masks/senpai_mask").bitmap;
					rim.maskThreshold = 1;
					rim.useAltMask = true;

					sprite.animation.callback = function(anim, frame, index)
					{
						rim.updateFrameInfo(sprite.frame);
					};
				}
			default:
				{
					rim.angle = 90;
					rim.threshold = 0.1;
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
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		if(songName == 'senpai') add(black);

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
				tmr.reset(0.3);
			else
			{
				if (doof != null)
					add(doof);
				else
					startCountdown();

				remove(black);
				black.destroy();
			}
		});
	}
}
