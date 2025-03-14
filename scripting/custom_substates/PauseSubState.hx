import flixel.group.FlxTypedGroup;
import Difficulty;
import PlayState;
import WeekData;
import Highscore;
import Song;
import flixel.sound.FlxSound;
import scripting.ScriptState;
import flixel.util.FlxStringUtil;
import extras.CustomSwitchState;
import PauseSubState;
import options.OptionsState;

var grpMenuShit:FlxTypedGroup<Alphabet>;

var menuItems:Array<String> = [];
var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to menu'];
var difficultyChoices = [];
var curSelected:Int = 0;

var pauseMusic:FlxSound;
var practiceText:FlxText;
var skipTimeText:FlxText;
var skipTimeTracker:Alphabet;
var curTime:Float = Math.max(0, Conductor.songPosition);

var missingTextBG:FlxSprite;
var missingText:FlxText;

function onCreatePost()
{
	if (Difficulty.list.length < 2) menuItemsOG.remove('Change Difficulty'); //No need to change difficulty if there is only one!

	if (PlayState.chartingMode)
	{
		menuItemsOG.insert(2, 'Leave Charting Mode');
		
		var num:Int = 0;
		if(!PlayState.instance.startingSong)
		{
			num = 1;
			menuItemsOG.insert(3, 'Skip Time');
		}
		menuItemsOG.insert(3 + num, 'End Song');
		menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
		menuItemsOG.insert(5 + num, 'Toggle Botplay');
	}
	else
	{
	    var num:Int = 0;
		if(!PlayState.instance.startingSong)
		{
			num = 1;
			menuItemsOG.insert(3, 'Skip Time');
		}
		menuItemsOG.insert(3 + num, 'End Song');
		menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
		menuItemsOG.insert(5 + num, 'Toggle Botplay');
	}
	menuItems = menuItemsOG;

	for (i in 0...Difficulty.list.length) {
		var diff:String = Difficulty.getString(i);
		difficultyChoices.push(diff);
	}
	difficultyChoices.push('Cancel');

	pauseMusic = new FlxSound();
	try
	{
		var pauseSong:String = getPauseSong();
		if(pauseSong != null) pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
	}
	catch(e:Dynamic) {}
	pauseMusic.volume = 0;
	pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

	FlxG.sound.list.add(pauseMusic);

	var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
	bg.alpha = 0;
	bg.scrollFactor.set();
	add(bg);

	var levelInfo:FlxText = new FlxText(20, 15, 0, PlayState.SONG.song, 32);
	levelInfo.scrollFactor.set();
	levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
	levelInfo.updateHitbox();
	add(levelInfo);

	var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, Std.string(Difficulty.getString()).toUpperCase(), 32);
	levelDifficulty.scrollFactor.set();
	levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
	levelDifficulty.updateHitbox();
	add(levelDifficulty);

	var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, "Blueballed: " + PlayState.deathCounter, 32);
	blueballedTxt.scrollFactor.set();
	blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
	blueballedTxt.updateHitbox();
	add(blueballedTxt);

	practiceText = new FlxText(20, 15 + 101, 0, "PRACTICE MODE", 32);
	practiceText.scrollFactor.set();
	practiceText.setFormat(Paths.font('vcr.ttf'), 32);
	practiceText.x = FlxG.width - (practiceText.width + 20);
	practiceText.updateHitbox();
	practiceText.visible = PlayState.instance.practiceMode;
	add(practiceText);

	var chartingText:FlxText = new FlxText(20, 15 + 101, 0, "CHARTING MODE", 32);
	chartingText.scrollFactor.set();
	chartingText.setFormat(Paths.font('vcr.ttf'), 32);
	chartingText.x = FlxG.width - (chartingText.width + 20);
	chartingText.y = FlxG.height - (chartingText.height + 20);
	chartingText.updateHitbox();
	chartingText.visible = PlayState.chartingMode;
	add(chartingText);

	blueballedTxt.alpha = 0;
	levelDifficulty.alpha = 0;
	levelInfo.alpha = 0;

	levelInfo.x = FlxG.width - (levelInfo.width + 20);
	levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
	blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

	FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
	FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
	FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
	FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

	grpMenuShit = new FlxTypedGroup<Alphabet>();
	add(grpMenuShit);

	missingTextBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
	missingTextBG.scale.set(FlxG.width, FlxG.height);
	missingTextBG.updateHitbox();
	missingTextBG.alpha = 0.6;
	missingTextBG.visible = false;
	add(missingTextBG);
	
	missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
	missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, 'center');
	missingText.scrollFactor.set();
	missingText.visible = false;
	add(missingText);
	
	addVirtualPad('FULL', 'A');
	addVirtualPadCamera();

	regenMenu();
	game.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
}

function getPauseSong()
{
	var formattedSongName:String = (songName != null ? Paths.formatToSongPath(songName) : '');
	var formattedPauseMusic:String = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);
	if(formattedSongName == 'none' || (formattedSongName != 'none' && formattedPauseMusic == 'none')) return null;

	return (formattedSongName != '') ? formattedSongName : formattedPauseMusic;
}

var cantUnpause:Float = 0.1;
var holdTime:Float = 0;

function onUpdatePost(elapsed:Float)
{
	var daSelected:String = menuItems[curSelected];

	cantUnpause -= elapsed;

	if (pauseMusic.volume < 0.5)
		pauseMusic.volume += 0.01 * elapsed;

	updateSkipTextStuff();

	if (controls.UI_UP_P)
	{
		changeSelection(-1);
	}

	if (controls.UI_DOWN_P)
	{
		changeSelection(1);
	}

	switch (daSelected)
	{
		case 'Skip Time':
			if (controls.UI_LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				curTime -= 1000;
				holdTime = 0;
			}
			if (controls.UI_RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				curTime += 1000;
				holdTime = 0;
			}

			if(controls.UI_LEFT || controls.UI_RIGHT)
			{
				holdTime += elapsed;
				if(holdTime > 0.5)
				{
					curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
				}

				if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
				else if(curTime < 0) curTime += FlxG.sound.music.length;
				updateSkipTimeText();
			}
	}

	if(controls.BACK)
	{
		close();
	}

	if (controls.ACCEPT && (cantUnpause <= 0 || !controls.controllerMode))
	{
		if (menuItems == difficultyChoices)
		{
			try{
				if (menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
				{
					var name:String = PlayState.SONG.song;
					var poop = Highscore.formatSong(name, curSelected);
					PlayState.SONG = Song.loadFromJson(poop, name);
					PlayState.storyDifficulty = curSelected;
					MusicBeatState.resetState();
					FlxG.sound.music.volume = 0;
					PlayState.changedDifficulty = true;
					PlayState.chartingMode = false;
					close();
				}

				menuItems = menuItemsOG;
				regenMenu();
			}catch(e:Dynamic){
				trace('ERROR! $e');

				var errorStr:String = e.toString();
				if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1); //Missing chart
				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		}

		switch (daSelected)
		{
			case "Resume":
				close();
			case 'Change Difficulty':
				menuItems = difficultyChoices;
				deleteSkipTimeText();
				regenMenu();
			case 'Toggle Practice Mode':
				PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
				PlayState.changedDifficulty = true;
				practiceText.visible = PlayState.instance.practiceMode;
			case "Restart Song":
				MusicBeatState.resetState();
				close();
			case "Leave Charting Mode":
				PauseSubState.restartSong(false);
				PlayState.chartingMode = false;
				close();
			case 'Skip Time':
				if(curTime < Conductor.songPosition)
				{
					PlayState.startOnTime = curTime;
					PauseSubState.restartSong();
					close();
				}
				else
				{
					if (curTime != Conductor.songPosition)
					{
						PlayState.instance.clearNotesBefore(curTime);
						PlayState.instance.setSongTime(curTime);
					}
					close();
				}
			case 'End Song':
				PlayState.instance.notes.clear();
				PlayState.instance.unspawnNotes = [];
				PlayState.instance.finishSong(true);
				close();
			case 'Toggle Botplay':
				PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
				PlayState.changedDifficulty = true;
				PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
				PlayState.instance.botplayTxt.alpha = 1;
				PlayState.instance.botplaySine = 0;
			case 'Options':
				OptionsState.stateType = 3;
				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;
				CustomSwitchState.switchMenus('Options');
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				close();
			case "Exit to menu":
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;

				if(PlayState.isStoryMode)
					CustomSwitchState.switchMenus('StoryMenu');
				else
					CustomSwitchState.switchMenus('Freeplay');

				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				PlayState.changedDifficulty = false;
				PlayState.chartingMode = false;
				FlxG.camera.followLerp = 0;
				close();
		} 
		
	}
}

function deleteSkipTimeText()
{
	if(skipTimeText != null)
	{
		skipTimeText.kill();
		remove(skipTimeText);
		skipTimeText.destroy();
	}
	skipTimeText = null;
	skipTimeTracker = null;
}

function onDestroy()
{
	pauseMusic.destroy();
}

function changeSelection(change:Float)
{
	curSelected += change;

	FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

	if (curSelected < 0)
		curSelected = menuItems.length - 1;
	if (curSelected >= menuItems.length)
		curSelected = 0;

	var bullShit:Int = 0;

	for (item in grpMenuShit.members)
	{
		item.targetY = bullShit - curSelected;
		bullShit++;

		item.alpha = 0.6;
		// item.setGraphicSize(Std.int(item.width * 0.8));

		if (item.targetY == 0)
		{
			item.alpha = 1;
			// item.setGraphicSize(Std.int(item.width));

			if(item == skipTimeTracker)
			{
				curTime = Math.max(0, Conductor.songPosition);
				updateSkipTimeText();
			}
		}
	}
	missingText.visible = false;
	missingTextBG.visible = false;
}

function regenMenu()
{
	for (i in 0...grpMenuShit.members.length) {
		var obj = grpMenuShit.members[0];
		obj.kill();
		grpMenuShit.remove(obj, true);
		obj.destroy();
	}

	for (i in 0...menuItems.length) {
		var item = new Alphabet(90, 320, menuItems[i], true);
		item.isMenuItem = true;
		item.targetY = i;
		grpMenuShit.add(item);

		if (menuItems[i] == 'Skip Time')
		{
			skipTimeText = new FlxText(0, 0, 0, '', 64);
			skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, 'center');
			skipTimeText.scrollFactor.set();
			skipTimeText.borderSize = 2;
			skipTimeTracker = item;
			add(skipTimeText);

			updateSkipTextStuff();
			updateSkipTimeText();
		}
	}
	curSelected = 0;
	changeSelection(0);
}

function updateSkipTextStuff()
{
	if (skipTimeText != null && skipTimeTracker != null)
	{
		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}
}

function clearNotesBefore(time:Float)
{
	var i:Int = unspawnNotes.length - 1;
	while (i >= 0) {
		var daNote:Note = unspawnNotes[i];
		if(daNote.strumTime - 350 < time)
		{
			daNote.active = false;
			daNote.visible = false;
			daNote.ignoreNote = true;

			daNote.kill();
			unspawnNotes.remove(daNote);
			daNote.destroy();
		}
		--i;
	}

	i = notes.length - 1;
	while (i >= 0) {
		var daNote:Note = notes.members[i];
		if(daNote.strumTime - 350 < time)
		{
			daNote.active = false;
			daNote.visible = false;
			daNote.ignoreNote = true;

			invalidateNote(daNote);
		}
		--i;
	}
}

function updateSkipTimeText()
{
	skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
}