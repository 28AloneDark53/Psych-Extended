package extras.states;

import flixel.util.FlxSpriteUtil;

import haxe.Json;
import haxe.ds.ArraySort;

import sys.thread.Thread;
import sys.thread.Mutex;
import openfl.system.System;

import openfl.filters.BlurFilter;
import openfl.filters.GlowFilter;

import HealthIcon;
import objects.shape.FreeplayShape;
import backend.*;

import editors.ChartingState;
import editors.ChartingStateNew;
import options.OptionsState;

class FreeplayStateNOVA extends MusicBeatState
{
	static public var instance:FreeplayStateNOVA;

	static public var curSelected:Int = 0;
	private static var position:Float = 360 - 45;
	private static var lerpPosition:Float = 360 - 45;
	private static var diffPosition:Float = 0;
	private static var diffLerpPosition:Float = 0;
	static public var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	public var grpSongs:Array<SongRect> = [];
	public var saveGrpSongs:Array<SongRect> = [];
	public var songs:Array<SongMetadata> = [];
	public var saveSongs:Array<SongMetadata> = [];
	public var sortSongs:Array<SongMetadata> = [];

	var camGame:FlxCamera;
	var camAudio:FlxCamera;
	var camUI:FlxCamera;
	public static var camHS:FlxCamera;

	var magenta:FlxSprite;
	var intendedColor:Int;

	var smallMag:SpecRect;

	var extraAudio:ExtraTopRect;
	var extraHS:ExtraTopRect;

	var instDis:ExtraAudio;
	var voiceDis:ExtraAudio;
	var voiceLine:MusicLine;

	var infoRating:InfoText;
	var infoNote:InfoText;
	var infoSpeed:InfoText;

	var timeSave:FlxText;
	var accSave:FlxText;
	var scoreSave:FlxText;
	var result:ResultRect;

	var optionEvent:EventRect;
	var modsEvent:EventRect;
	var randomEvent:EventRect;
	var resetEvent:EventRect;
	var editorEvent:EventRect;
	var ChangersEvent:EventRect;
	var skipEvent:EventRect;
	var eventArray:Array<EventRect> = [];

	var playButton:PlayRect;
	var backButton:BackRect;

	var disLine:Rect;

	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		super.create();

		instance = this;

		#if !mobile
		FlxG.mouse.visible = true;
		#end

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		if(WeekData.weeksList.length < 1)
		{
			if (ClientPrefs.data.loadingScreen) FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new editors.WeekEditorState()),
				function() CustomSwitchState.switchMenus('MainMenu')));
			return;
		}

		camGame = initPsychCamera();

		for (i in 0...WeekData.weeksList.length)
		{
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				var muscan:String = song[3];
				if (song[3] == null) muscan = 'N/A';
				var charter:Array<String> = song[4];
				if (song[4] == null) charter = ['N/A', 'N/A', 'N/A'];
				addSong(song[0], i, song[1], muscan, charter, colors);
			}
		}

		sortSongs = songs.copy();
		saveSongs = songs.copy();

		ArraySort.sort(sortSongs, function(a:SongMetadata, b:SongMetadata) {
			return Reflect.compare(a.songName.toLowerCase(), b.songName.toLowerCase());
		});

		Mods.loadTopMod();

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scale.x = FlxG.width * 1.05 / magenta.width;
		magenta.scale.y = FlxG.height * 1.05 / magenta.height;
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		add(magenta);

		var specBG:SpecRectBG = new SpecRectBG(0, 0);
		specBG.alpha = 0.3;
		add(specBG);

		for (i in 0...songs.length)
		{
			Mods.currentModDirectory = songs[i].folder;

			var songRect:SongRect = new SongRect(660, 50 + i * 100, songs[i].songName, songs[i].songCharacter, songs[i].musican, songs[i].color);
			add(songRect);
			songRect.member = i;
			grpSongs.push(songRect);

			if (i == curSelected) songRect.lerpPosX = songRect.posX;
		}

		saveGrpSongs = grpSongs.copy();

		WeekData.setDirectoryFromWeek();

		var upBG:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, Std.int(FlxG.height * 0.25), FlxColor.BLACK);
		upBG.alpha = 0.7;
		add(upBG);

		var searchMenu:SearchButton = new SearchButton(640, 20, FlxG.width - 640 - 20, 80);
		add(searchMenu);

		var order:OrderRect = new OrderRect(searchMenu.x, searchMenu.y + searchMenu.height + 15, searchMenu.width, 50, useSort);
		add(order);

		smallMag = new SpecRect(0, 0, 'menuDesat');
		add(smallMag);

		var infoBG:Rect = new Rect(12, FlxG.height * 0.42, FlxG.width * 0.45 - 12, FlxG.height * 0.15, 20, 20, FlxColor.BLACK, 0.5);
		add(infoBG);

		infoSpeed = new InfoText(infoBG.x + 15, infoBG.y + 7, "speed", 5);
		add(infoSpeed);

		infoNote = new InfoText(infoBG.x + 15, infoBG.y + 38, "note count", 10);
		add(infoNote);

		infoRating = new InfoText(infoBG.x + 15, infoBG.y + 70, "rating", 20);
		add(infoRating);

		var extraBG:Rect = new Rect(12, FlxG.height * 0.585, FlxG.width * 0.45 - 12, FlxG.height * 0.3, 20, 20, FlxColor.BLACK, 0.5);
		add(extraBG);

		extraAudio = new ExtraTopRect(extraBG.x, extraBG.y, extraBG.width / 2, 50, 11, true, 'Audio DisPlay', 0, FlxColor.BLACK, extraChange);
		add(extraAudio);

		extraHS = new ExtraTopRect(extraBG.x + extraAudio.width, extraBG.y, extraBG.width / 2, 50, 11, false, 'History Score', 0, FlxColor.BLACK, extraChange);
		add(extraHS);

		camAudio = new FlxCamera(Std.int(extraAudio.x), Std.int(extraAudio.y + extraAudio.height), Std.int(extraBG.width), Std.int(extraBG.height - extraAudio.height));
		camAudio.bgColor = 0x00;
		camHS = new FlxCamera(Std.int(extraAudio.x), Std.int(extraAudio.y + extraAudio.height), Std.int(extraBG.width), Std.int(extraBG.height - extraAudio.height));
		camHS.bgColor = 0x00;
		camHS.visible = false;
		FlxG.cameras.add(camAudio, false);
		FlxG.cameras.add(camHS, false);

		voiceDis = new ExtraAudio(10, 10, Std.int(camAudio.width / 2 - 20), 90, FlxG.sound.music);
		add(voiceDis);
		voiceDis.audioDis.stopUpdate = true;
		voiceDis.camera = camAudio;
		voiceDis.alpha = 0.7;

		instDis = new ExtraAudio(Std.int(camAudio.width) - 10 - Std.int(camAudio.width / 2 - 20) + 1, 10, Std.int(camAudio.width / 2 - 20), 90, FlxG.sound.music);
		add(instDis);
		instDis.audioDis.stopUpdate = true;
		instDis.camera = camAudio;
		instDis.alpha = 0.7;

		voiceLine = new MusicLine(Std.int(extraAudio.x) + 10, Std.int(extraAudio.y + extraAudio.height) + 110, 545);
		add(voiceLine);

		timeSave = new FlxText(10, 0, 0, '', 15);
		timeSave.font = Paths.font('montserrat.ttf');
		timeSave.antialiasing = ClientPrefs.data.antialiasing;
		timeSave.camera = camHS;
		add(timeSave);

		accSave = new FlxText(10, 20, 0, '', 15);
		accSave.font = Paths.font('montserrat.ttf');
		accSave.antialiasing = ClientPrefs.data.antialiasing;
		accSave.camera = camHS;
		add(accSave);

		scoreSave = new FlxText(10 + camHS.width * 0.4, 20, 0, '', 15);
		scoreSave.font = Paths.font('montserrat.ttf');
		scoreSave.antialiasing = ClientPrefs.data.antialiasing;
		scoreSave.camera = camHS;
		add(scoreSave);

		result = new ResultRect(10, camHS.y + 10, camHS.width - 20, 110);
		result.updateRect();
		result.x = 20;
		result.y = 515;
		result.visible = false;
		add(result);

		var bottomBG:FlxSprite = new FlxSprite(0, FlxG.height * 0.9).makeGraphic(FlxG.width, Std.int(FlxG.height * 0.1));
		bottomBG.color = FlxColor.BLACK;
		bottomBG.alpha = 0.6;
		add(bottomBG);

		optionEvent = new EventRect(215, bottomBG.y, "option", 0x63d6ff, specEvent);
		add(optionEvent);
		modsEvent = new EventRect(optionEvent.x + optionEvent.width - 1, bottomBG.y, "mods", 0xd1fc52, specEvent);
		add(modsEvent);
		ChangersEvent = new EventRect(modsEvent.x + modsEvent.width - 1, bottomBG.y, "changers", 0xff354e, specEvent);
		add(ChangersEvent);
		editorEvent = new EventRect(ChangersEvent.x + ChangersEvent.width - 1, bottomBG.y, "editor", 0xff617e, specEvent);
		add(editorEvent);
		resetEvent = new EventRect(editorEvent.x + editorEvent.width - 1, bottomBG.y, "reset", 0xfd6dff, specEvent);
		add(resetEvent);
		randomEvent = new EventRect(resetEvent.x + resetEvent.width - 1, bottomBG.y, "random", 0x6dff6d, specEvent, true);
		add(randomEvent);
		skipEvent = new EventRect(randomEvent.x + randomEvent.width - 1, bottomBG.y, "skip", 0x61edfa, specEvent, true);
		add(skipEvent);
		eventArray.push(optionEvent);
		eventArray.push(modsEvent);
		eventArray.push(ChangersEvent);
		eventArray.push(editorEvent);
		eventArray.push(resetEvent);
		eventArray.push(randomEvent);
		eventArray.push(skipEvent);

		disLine = new Rect(0, bottomBG.y - 4, FlxG.width, 4, 0, 0, FlxColor.WHITE, 0);
		add(disLine);

		playButton = new PlayRect(FlxG.width, bottomBG.y, 200, bottomBG.height, "PLAY", 0xFC4EFF, startGame);
		add(playButton);

		backButton = new BackRect(0, bottomBG.y, 200, bottomBG.height, "BACK", 0x41E9FF, backMenu);
		add(backButton);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		changeSelection(0, false, true);
		songsRectPosUpdate(true);
	}

	public var ignoreCheck:Bool = false; //最高级控制更新
	var isPressed:Bool = false; //修复出判定释放
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (ignoreCheck) return;

		if (vocals != null && (Math.abs(vocals.time - FlxG.sound.music.time) > 5)) {
			vocals.time = FlxG.sound.music.time;
		}

		var reduceAlpha:Bool = true;
		for (i in 0...eventArray.length){
			if (FlxG.mouse.overlaps(eventArray[i]))
			{
				eventMember = i;
				disLine.color = eventArray[i].background.color;
				disLine.alpha += elapsed * 8;
				reduceAlpha = false;
			}
			eventArray[i].posUpdate(elapsed); //Make sure the choice is right
		}
		if (reduceAlpha) disLine.alpha -= elapsed * 8;

		mouseMove();

		if (FlxG.mouse.x >= 660 && FlxG.mouse.x <= FlxG.width && FlxG.mouse.y >= FlxG.height * 0.25 && FlxG.mouse.y <= FlxG.height * 0.9)
		{
			position += FlxG.mouse.wheel * 180;
			if (FlxG.mouse.pressed) 
			{
				isPressed = true;
				position += moveData;
				lerpPosition = position;
				songsRectPosUpdate(true);
			}
			if (FlxG.mouse.justReleased)
			{
				position += avgSpeed * 1.5 * (0.0166 / elapsed) * Math.pow(1.1, Math.abs(avgSpeed * 0.8));
				if (Math.abs(avgSpeed * (0.0166 / elapsed)) < 5) {
					for (i in 0...grpSongs.length)
					{
						if (FlxG.mouse.overlaps(grpSongs[i]) && !grpSongs[i].ignoreCheck)
						{
							if (curSelected != i)
							{
								curSelected = i;
								changeSelection();
							}
						}
					}
				}

				try{
					updateInfo(); //难度数据更新
				} catch (e:Dynamic) {
					infoNote.data = 0;
					infoRating.data = 0;
					infoSpeed.data = 0; //搜索后无歌曲的数据更新
				}
			}
		} else {
			if (FlxG.mouse.pressed && isPressed == true) 
			{
				isPressed = false;
				position += avgSpeed * 1.5 * (0.0166 / elapsed) * Math.pow(1.1, Math.abs(avgSpeed * 0.8));
			}
		}

		if (position > 360 - 45) position = FlxMath.lerp(360 - 45, position, Math.exp(-elapsed * 15));
		if (position < 360 - 45 - 100 * (songs.length - 1) - Difficulty.list.length * 70) position = FlxMath.lerp(360 - 45 - 100 * (songs.length - 1) - Difficulty.list.length * 70, position, Math.exp(-elapsed * 15));

		if (Math.abs(lerpPosition - position) < 1) lerpPosition = position;
		else lerpPosition = FlxMath.lerp(position, lerpPosition, Math.exp(-elapsed * 15));

		songsRectPosUpdate(false);
	}

	override function closeSubState()
	{
		super.closeSubState();

		new FlxTimer().start(0.1, function(tmr:FlxTimer){
			ignoreCheck = false;
		});
		closeSubStatePost();
	}

	var pressCheck:Bool = false;
	function backMenu() {
		Mods.loadTopMod();
		if (!pressCheck){
			pressCheck = true;
			FlxG.sound.music.stop();
			destroyFreeplayVocals();
			FlxG.sound.music.volume = 0;
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);

			CustomSwitchState.switchMenus('MainMenu');
		}
	}

	var startCheck:Bool = false;
	function startGame() {
		if (Math.abs(lerpPosition - position) > 1) return;
		if (!musicMutex.tryAcquire()) return;

		if (startCheck) return;
		startCheck = true;
		var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);

		try
		{
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			if (ClientPrefs.data.chartLoadSystem == '1.0x') Song.loadFromJson(poop, songLowercase);
			else PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
		}
		catch(e:Dynamic)
		{
			trace('ERROR! $e');

			var errorStr:String = e.toString();
			if(errorStr.startsWith('[lime.utils.Assets] ERROR:')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1); //Missing chart

			missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
			missingText.screenCenter(Y);
			missingText.visible = true;
			missingTextBG.visible = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			startCheck = false;
			return;
		}
		destroyFreeplayVocals();
		if (ClientPrefs.data.loadingScreen && ClientPrefs.data.TransitionStyle == 'NovaFlare') {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		LoadingState.prepareToSong();
		LoadingState.loadAndSwitchState(new PlayState());
		#if HIDE_CURSOR FlxG.mouse.visible = false; #end
	}

	var closeCheck = false;
	function extraChange() {
		if (FlxG.mouse.overlaps(extraHS))
		{
			camAudio.visible = false;
			voiceLine.visible = false;
			camHS.visible = true;
			result.visible = true;
		} else {
			camAudio.visible = true;
			voiceLine.visible = true;
			camHS.visible = false;
			result.visible = false;
		}
	}

	var eventMember:Int = -1;
	var eventPressCheck:Bool = false;
	function specEvent() {
		switch (eventMember)
		{
			case 0:
				if (!eventPressCheck)
				{
					if (Math.abs(lerpPosition - position) > 1) return;
					if (!musicMutex.tryAcquire()) return;
					eventPressCheck = true;
					destroyFreeplayVocals();
					FlxG.sound.music.stop();

					FlxG.sound.playMusic(Paths.music('freakyMenu'), 1);

					OptionsState.stateType = 1;
					CustomSwitchState.switchMenus('Options');
				}
			case 1:
				if (Math.abs(lerpPosition - position) > 1) return;
				if (!musicMutex.tryAcquire()) return;
				ignoreCheck = true;
				destroyFreeplayVocals();
				FlxG.sound.music.stop();

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 1);

				ModsMenuState.isFreePlay = true;
				CustomSwitchState.switchMenus('ModsMenu');
			case 2:
				if (Math.abs(lerpPosition - position) > 1) return;
				ignoreCheck = true;
				openSubState(new GameplayChangersSubstate());
			case 3:
				if (Math.abs(lerpPosition - position) > 1) return;
				if (!musicMutex.tryAcquire()) return;
				if (!eventPressCheck)
				{
					eventPressCheck = true;
					destroyFreeplayVocals();
					FlxG.sound.music.stop();
					if (ClientPrefs.data.chartLoadSystem == '1.0x') ChartingStateNew.isFreePlay = true;
					else ChartingState.isFreePlay = true;
					CustomSwitchState.switchMenus('Charting', true);
				}
			case 4: 
				if (Math.abs(lerpPosition - position) > 1) return;
				ignoreCheck = true;
				openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			case 5:
				randomSel();
			case 6:
				if (songs.length > 21 && curSelected <= 21) {
					curSelected = 22;
					changeSelection(0);
				}
		}
	}

	function randomSel() {
		var data = FlxG.random.int(0, songs.length-1);
		if (curSelected != data) {
			curSelected = data;
			changeSelection(0);
		} else {
			randomSel();
		}
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	var saveMouseY:Int = 0;
	var moveData:Int = 0;
	var avgSpeed:Float = 0;
	function mouseMove()
	{
		if (FlxG.mouse.justPressed) 
		{
			saveMouseY = FlxG.mouse.y;
			avgSpeed = 0;
		}
		moveData = FlxG.mouse.y - saveMouseY;
		saveMouseY = FlxG.mouse.y;
		avgSpeed = avgSpeed * 0.75 + moveData * 0.25;
	}

	function songsRectPosUpdate(forceUpdate:Bool = false) 
	{
		for (i in 0...grpSongs.length){
			grpSongs[i].y = lerpPosition + i * 100 + grpSongs[i].lerpPosY;
			grpSongs[i].x = 660 + Math.abs(grpSongs[i].y + grpSongs[i].background.height / 2 - FlxG.height / 2) / FlxG.height / 2 * 250 + grpSongs[i].lerpPosX;
		}
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	public function changeSelection(change:Int = 0, playSound:Bool = true, start:Bool = false)
	{
		if (songs.length < 1) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length-1);
		position = 315 - 100 - curSelected * 100;
		_updateSongLastDifficulty();

		grpSongs[curSelected].onFocus = true;

		for (i in 0...grpSongs.length)
		{
			if (curSelected != i) grpSongs[i].onFocus = false;
		}

		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();

		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var newColor:Int = FlxColor.fromRGB(songs[curSelected].color[0], songs[curSelected].color[1], songs[curSelected].color[2]);
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(magenta);
			FlxTween.color(magenta, 1, magenta.color, intendedColor);
		}

		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		createDiff(start);
		updateRect();
		try{
			updateInfo(); //难度数据更新
		} catch (e:Dynamic) {
			infoNote.data = 0;
			infoRating.data = 0;
			infoSpeed.data = 0; //搜索后无歌曲的数据更新
		}
		updateVoice();
		_updateSongLastDifficulty();

		missingText.visible = false;
		missingTextBG.visible = false;
	}

	inline private function _updateSongLastDifficulty()
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);

	function createDiff(start:Bool = false) //start用于解决搜索难度rect一直重置位置
	{
		for (num in 0...grpSongs.length) 
		{
			grpSongs[num].posY = Difficulty.list.length * 70;
			if (start && num > curSelected) grpSongs[num].lerpPosY = Difficulty.list.length * 70;
		}

		grpSongs[curSelected].createDiff(FlxColor.fromRGB(songs[curSelected].color[0], songs[curSelected].color[1], songs[curSelected].color[2]), songs[curSelected].charter, start);
		updateDiff();
	}

	public function updateDiff() {
		timeSave.text = 'Played Time: ' + Std.string(Highscore.getTime(songs[curSelected].songName, curDifficulty));
		accSave.text =  'Accurate: ' + Std.string(FlxMath.roundDecimal(Highscore.getRating(songs[curSelected].songName, curDifficulty) * 100, 2)) + '%';
		scoreSave.text =  'Score: ' + Std.string(Highscore.getScore(songs[curSelected].songName, curDifficulty));

		var details:Array<Dynamic> = Highscore.getDetails(songs[curSelected].songName, curDifficulty);
		result.updateRect(details[9], details[10], details[2]);
	}

	var rectMutex:Mutex = new Mutex();
	function updateRect() {
		var extraLoad:Bool = false;
		var filesLoad = 'data/' + songs[curSelected].songName + '/background';
		if (FileSystem.exists(Paths.modFolders(filesLoad + '.png'))){
			extraLoad = true;
		} else {
			filesLoad = 'menuDesat';
			extraLoad = false;
		}
		magenta.loadGraphic(Paths.image(filesLoad, null, extraLoad));
		var scale = Math.max(FlxG.width * 1.05 / magenta.width, FlxG.height * 1.05 / magenta.height);
		magenta.scale.x = magenta.scale.y = scale;
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.antialiasing = ClientPrefs.data.antialiasing;

		smallMag.updateRect(magenta.pixels);
	}

	var rateMutex:Mutex = new Mutex();
	var rates:StarRating = new StarRating();
	function updateInfo() {

		var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
		var jsonData:SwagSong = null;
		var speed:Float = 0;
		var count:Int = 0;
		try
		{
		jsonData = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
		speed = jsonData.speed;
		} catch(a:Any){
			return;
		}

		var thread = Thread.create(() -> {
			rateMutex.acquire();
			for (i in jsonData.notes) // sections
			{
				for (ii in i.sectionNotes) // notes
				{
					var gottaHitNote:Bool = i.mustHitSection;
					if ((ii[1] >= 4 && !gottaHitNote) || (ii[1] <= 3 && gottaHitNote))
						count++;
				}
			}

			//var rate = DiffCalc.CalculateDiff(Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase())) / 5;
			//rate = FlxMath.roundDecimal(rate, 2);

			var rate1 = rates.calculateFullDifficulty(Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase()));
			var rate = rate1.stars;
			speed = FlxMath.roundDecimal(speed, 2);

			infoNote.maxData = Math.floor(rate * 300);
			infoNote.data = count;
			infoRating.data = rate;
			infoSpeed.data = speed;

			rateMutex.release();
		});
	}

	public var useSort:Bool = false;
	public function updateSearch(text:String) 
	{
		if (grpSongs.length > 0) 
		{
			grpSongs[curSelected].onFocus = false;
			grpSongs[curSelected].desDiff();
		}

		songs = [];
		grpSongs = [];

		if (!useSort) {
			for (i in 0...saveSongs.length){
				if (saveSongs[i].songName.trim().toLowerCase().indexOf(text.trim().toLowerCase()) != -1)
				songs.push(saveSongs[i]);
			}
		} else {
			for (i in 0...sortSongs.length){
				if (sortSongs[i].songName.trim().toLowerCase().indexOf(text.trim().toLowerCase()) != -1)
				songs.push(sortSongs[i]);
			}
		}
 
		for (rect in 0...saveGrpSongs.length)
		{
			saveGrpSongs[rect].ignoreCheck = true;
			saveGrpSongs[rect].alpha = 0.6;
			saveGrpSongs[rect].haveAdd = false;
			if (songs.length == 0) saveGrpSongs[rect].alpha = 0;
		}

		var data:Int = 0;
		for (song in 0...songs.length){
			var added:Bool = false;
			for (rect in 0...saveGrpSongs.length){
				var rect = saveGrpSongs[rect];
				if (rect.name.trim().toLowerCase() == songs[song].songName.trim().toLowerCase() && !rect.haveAdd && !added)
				{
					added = true;

					rect.member = data;
					rect.haveAdd = true;
					data++;
					rect.ignoreCheck = false;
					grpSongs.push(rect);
				}
			}
		}

		changeSelection();

		if (grpSongs[curSelected] != null)
		{
			grpSongs[curSelected].onFocus = true;
			grpSongs[curSelected].lerpPosX = grpSongs[curSelected].posX;
			grpSongs[curSelected].createDiff(FlxColor.fromRGB(songs[curSelected].color[0], songs[curSelected].color[1], songs[curSelected].color[2]), songs[curSelected].charter, true);
		}

		if (grpSongs.length > 0)
		{
			for (num in 0...grpSongs.length)
			{
				if (num > curSelected) grpSongs[num].lerpPosY = grpSongs[num].posY;
				else grpSongs[num].lerpPosY = 0;
			}
		}

		position = 315 - 100 - curSelected * 100;
		songsRectPosUpdate(true);

		if (songs.length > 0) updateVoice();
	}

	var musicMutex:Mutex = new Mutex();
	var timer:FlxTimer = new FlxTimer();
	var playedSongName:String = '';
	function updateVoice() {
		if (timer != null) timer.cancel;

		timer.start(0.5, function(tmr:FlxTimer){

			if (songs[curSelected] == null) return;

			var thread = Thread.create(() -> {
				musicMutex.acquire();

				if (songs[curSelected].songName == playedSongName)
				{
					musicMutex.release();
					return;
				}

				playedSongName = songs[curSelected].songName;

				destroyFreeplayVocals();
				FlxG.sound.music.stop();

				voiceDis.audioDis.stopUpdate = true;
				instDis.audioDis.stopUpdate = true;

				try
				{
					var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
					if (ClientPrefs.data.chartLoadSystem == '1.0x') Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					else PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());

					if (PlayState.SONG.needsVoices)
					{
						vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
						FlxG.sound.list.add(vocals);
						vocals.persist = vocals.looped = true;
						vocals.volume = 0.8;
					}
					else if (vocals != null)
					{
						vocals.stop();
						vocals.destroy();
						vocals = null;
					}
				}catch(e:Any){
					musicMutex.release();
					return;
				}

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
				if (vocals != null) vocals.play();
				if (opponentVocals != null) opponentVocals.play();

				try{
					voiceDis.audioDis.changeAnalyzer(FlxG.sound.music);
					if (vocals != null) instDis.audioDis.changeAnalyzer(vocals);
					else instDis.audioDis.clearUpdate();
				} catch(e:Any){
					instDis.audioDis.clearUpdate();
				}

				musicMutex.release();
			});
		});
	}

	var waitTime:FlxTimer = new FlxTimer();
	public function updateMusicTime(data:Int, bigJump:Bool) {
		FlxG.sound.music.pause();
		if(opponentVocals != null) opponentVocals.pause();
		if(vocals != null) vocals.pause();

		if (bigJump) FlxG.sound.music.time += Math.floor(FlxG.sound.music.length / 100) * data;
		else FlxG.sound.music.time += 1000 * data;
		if (FlxG.sound.music.time < 0) FlxG.sound.music.time = FlxG.sound.music.length;
		if (FlxG.sound.music.time > FlxG.sound.music.length) FlxG.sound.music.time = 0;
		if(vocals != null) vocals.time = FlxG.sound.music.time;
		if(opponentVocals != null) opponentVocals.time = FlxG.sound.music.time;

		if (waitTime != null) waitTime.cancel();
		waitTime.start(0.1, function(tmr:FlxTimer){
			FlxG.sound.music.resume();
			if(opponentVocals != null) opponentVocals.resume();
			if(vocals != null) vocals.resume();
		});
	}

	public function updateMusicRate(data:Int) {
		FlxG.sound.music.pitch += 0.05 * data;
		FlxG.sound.music.pitch = FlxMath.roundDecimal(FlxG.sound.music.pitch, 2);
		if (FlxG.sound.music.pitch < 0.5) FlxG.sound.music.pitch = 0.5;
		if (FlxG.sound.music.pitch > 4) FlxG.sound.music.pitch = 4;
		if(vocals != null) vocals.pitch = FlxG.sound.music.pitch;
		if(opponentVocals != null) opponentVocals.pitch = FlxG.sound.music.pitch;
	}

	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end
			return character.vocals_file;
		}
		return null;
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, songMusican:String, songCharter:Array<String>, color:Array<Int>)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, songMusican, songCharter, color));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Array<Int> = [0, 0, 0];
	public var folder:String = "";
	public var lastDifficulty:String = null;
	public var bg:Dynamic;
	public var searchnum:Int = 0;
	public var musican:String = 'N/A';
	public var charter:Array<String> = ['N/A', 'N/A', 'N/A'];

	public function new(song:String, week:Int, songCharacter:String, musican:String, charter:Array<String>, color:Array<Int>)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		this.bg = Paths.image('menuDesat', null, false);
		this.searchnum = 0;
		this.musican = musican;
		this.charter = charter;
		if(this.folder == null) this.folder = '';
	}
}