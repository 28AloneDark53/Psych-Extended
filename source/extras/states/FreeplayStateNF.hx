package extras.states;

import WeekData;
import Highscore;
import DiffCalc;
import Difficulty;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

import FreeplayState.SongMetadata;
import HealthIcon;
import editors.ChartingState;

import GameplayChangersSubstate;
import ResetScoreSubState;
import options.OptionsState;

import flixel.addons.ui.FlxInputText;
import flixel.group.FlxGroup;
import flixel.addons.ui.FlxInputText;
import flixel.util.FlxStringUtil;
import flixel.ui.FlxBar;

#if MODS_ALLOWED
import sys.FileSystem;
#end

import FreeplayState;
import MusicBeatState;
import flixel.math.FlxRect;
import PlayState;
import LoadingState;
import MainMenuState;
import options.OptionsState;

/*
	Note: This backport only supports Psych Extended & DaffyToons's NF Engine 1.0.2 Build
	Backported by KralOyuncu 2010x

	created by TieGuo
	artists, bug fix by Beihu & 487

	比暂停界面更屎的state出现了XD
	这个玩意铁锅拖了3个月
*/

class FreeplayStateNF extends MusicBeatState {

	var bg:FlxSprite;
	var bgColorChange:FlxTween;
	var songsbg:FlxSprite;
	var difficultyRight:FlxSprite;
	var difficultyLeft:FlxSprite;
	var backButton:FlxSprite;
	var startButton:FlxSprite;
	var backText:FlxText;
	var startText:FlxText;

	var mousechecker:FlxSprite;
	var searching:Bool = false;
	var searchbg:FlxSprite;
	var searchtext:FlxText;

	var listening:Bool = false;
	var listenbg:FlxSprite;

	var songBarSelected:FlxSprite;
	var infoBar:FlxSprite;
	var songNameText:FlxText;
	var songIcon:HealthIcon;

	var accText:FlxText;
	var difficultyText:FlxText;
	var rateText:FlxText;
	var scoreText:FlxText;
	var timeText:FlxText;

	var rate:FlxSprite;
	var timerTween:FlxTimer;
	var swagRect:FlxRect;
	var songs:Array<SongMetadata> = [];
	var songtextsGroup:Array<FlxText> = [];
	var iconsArray:Array<HealthIcon> = [];
	var barsArray:Array<FlxSprite> = [];

	var holdOptions:Bool = false;
	var holdOptionsTime:Float = 0;
	var curHoldOptions:Int;
	var holdOptionsChecker:Array<FlxSprite> = [];
	var bars1Option:FlxSprite;
	var bars2Option:FlxSprite;
	var bars3Option:FlxSprite;
	var bars4Option:FlxSprite;

	var searchButton:FlxSprite;
	var musicButton:FlxSprite;
	var randomButton:FlxSprite;
	var infoButton:FlxSprite;

	var intendedColor:Int;
	var colorTween:FlxTween;

	var font = Paths.font('montserrat.ttf');
	var filePath:String = 'menuExtend/FreeplayStateOld/';

	private static var curSelected:Int = 0;
	private static var curSelectedFloat:Float;
	var lerpSelected:Float = 0;
	public static var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var camGame:FlxCamera;
	var camSong:FlxCamera;
	var camUI:FlxCamera;
	var camInfo:FlxCamera;
	var camSearch:FlxCamera;
	var camListen:FlxCamera;
	var camBG:FlxCamera;
	var camMove:FlxCamera;
	var camUIInfo_Info:FlxCamera;
	var camUIInfo_Song:FlxCamera;
	var camUIInfo_Listen:FlxCamera;
	var camUIInfo_Search:FlxCamera;

	var lookingTheTutorial:Bool = false;
	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		super.create();

		persistentUpdate = persistentDraw = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		if(WeekData.weeksList.length < 1)
		{
			if (ClientPrefs.data.loadingScreen) FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new editors.WeekEditorState()),
				function() CustomSwitchState.switchMenus('MainMenu')));
			return;
		}

		loadSong();

		camGame = new FlxCamera();

		camSong = new FlxCamera();
		camSong.bgColor = 0x00;

		camInfo = new FlxCamera();
		camInfo.bgColor = 0x00;

		camSearch = new FlxCamera(searching ? 0 : -FlxG.width);
		camSearch.bgColor = 0x00;

		camListen = new FlxCamera(listening ? 0 : -FlxG.width);
		camListen.bgColor = 0x00;

		camUI = new FlxCamera();
		camUI.bgColor = 0x00;

		camBG = new FlxCamera(-FlxG.width);
		camBG.bgColor = 0x00;

		camMove = new FlxCamera();
		camMove.bgColor = 0x00;

		camUIInfo_Info = new FlxCamera();
		camUIInfo_Info.bgColor = 0x00;

		camUIInfo_Song = new FlxCamera();
		camUIInfo_Song.bgColor = 0x00;

		camUIInfo_Listen = new FlxCamera();
		camUIInfo_Listen.bgColor = 0x00;

		camUIInfo_Search = new FlxCamera();
		camUIInfo_Search.bgColor = 0x00;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camSong, false);
		FlxG.cameras.add(camInfo, false);
		//FlxG.cameras.add(camUI, false);
		FlxG.cameras.add(camSearch, false);
		FlxG.cameras.add(camListen, false);
		FlxG.cameras.add(camUI, false);
		FlxG.cameras.add(camBG, false);

		var list = [camUIInfo_Info, camUIInfo_Song, camUIInfo_Listen, camUIInfo_Search];
		for (i in list) {
			FlxG.cameras.add(i, false);
			i.alpha = 0;
			var cambg = new FlxSprite((i == camUIInfo_Song ? Std.int(FlxG.width/2) : 0), 0).makeGraphic(Std.int(FlxG.width/2), FlxG.height, FlxColor.BLACK);
			cambg.camera = i;
			cambg.alpha = 0.5;
			add(cambg);
		}

		FlxG.cameras.add(camMove, false);

		songsbg = new FlxSprite(700, -75).makeGraphic(550, 900, FlxColor.WHITE);
		songsbg.camera = camGame;
		songsbg.angle = 15;
		songsbg.updateHitbox();
		songsbg.alpha = 1;
		add(songsbg);

		if(curSelected >= songs.length) curSelected = 0;

		Mods.currentModDirectory = songs[curSelected].folder;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.camera = camGame;
		add(bg);
		bg.screenCenter();

		mousechecker = new FlxSprite(114, 514).makeGraphic(1, 1, FlxColor.WHITE);

		mousechecker.updateHitbox();
		mousechecker.alpha = 0.1;
		add(mousechecker);
		mousechecker.camera = camUI;

		addSongTxt();

		bg.color = songs[curSelected].color;
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		camSong.scroll.x = -curSelected * 20 * 0.75;

		songBarSelected = new FlxSprite().loadGraphic(Paths.image(filePath + 'songBarSelected'));
		songBarSelected.antialiasing = ClientPrefs.data.antialiasing;
		songBarSelected.camera = camUI;
		add(songBarSelected);
		songBarSelected.screenCenter();

		songIcon = new HealthIcon('');
		add(songIcon);
		songIcon.scale.set(0.5, 0.5);
		songIcon.camera = camUI;
		songIcon.x = 1120;
		songIcon.y = 300;
		songIcon.updateHitbox();

		songNameText = new FlxText(0, 0, 0, "", 32);
		songNameText.setFormat(font, 40, FlxColor.BLACK, LEFT/*FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT*/);
		songNameText.camera = camUI;
		songNameText.antialiasing = ClientPrefs.data.antialiasing;
		songNameText.x = 660;
		songNameText.y = 348;
		add(songNameText);

		rate = new FlxSprite().loadGraphic(Paths.image(filePath + 'rateBG'));
		rate.antialiasing = ClientPrefs.data.antialiasing;
		rate.camera = camInfo;
		rate.updateHitbox();
		rate.x = 61;
		rate.y = 304;
		//add(rate);

		difficultyRight = new FlxSprite().loadGraphic(Paths.image(filePath + 'difficultyRight'));
		difficultyRight.antialiasing = ClientPrefs.data.antialiasing;
		difficultyRight.camera = camInfo;
		difficultyRight.updateHitbox();
		add(difficultyRight);

		difficultyLeft = new FlxSprite().loadGraphic(Paths.image(filePath + 'difficultyLeft'));
		difficultyLeft.antialiasing = ClientPrefs.data.antialiasing;
		difficultyLeft.camera = camInfo;
		difficultyLeft.updateHitbox();
		add(difficultyLeft);

		for (i in 1...9)
		{
			var back:FlxSprite = new FlxSprite().loadGraphic(Paths.image(filePath + 'infoBar' + i));
			back.antialiasing = ClientPrefs.data.antialiasing;
			back.camera = camInfo;
			back.updateHitbox();
			add(back);

			if (i == 3) add(rate);

			if (i >= 4 && i <= 7)
				holdOptionsChecker.push(back);
		}

		var RateBarText = new FlxText(0, 0, 0, "RATE:", 32);
		RateBarText.setFormat(font, 21, FlxColor.BLACK, LEFT/*FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT*/);
		RateBarText.camera = camInfo;
		RateBarText.antialiasing = ClientPrefs.data.antialiasing;
		RateBarText.x = 0;
		RateBarText.y = 305;
		add(RateBarText);

		var diffText:FlxText = new FlxText(360, 355, 0, "DIFFICULTY", 15);
		diffText.setFormat(font, 15, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		diffText.camera = camInfo;
		diffText.antialiasing = ClientPrefs.data.antialiasing;
		add(diffText);

		difficultyText = new FlxText(300, 360, 0, "difficulty", 55);
		difficultyText.setFormat(font, 55, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		difficultyText.camera = camInfo;
		difficultyText.antialiasing = ClientPrefs.data.antialiasing;
		add(difficultyText);

		var ateText = new FlxText(60, 273, 0, "Rate: ", 30);
		ateText.setFormat(font, 25, FlxColor.WHITE, 'left', FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		ateText.camera = camInfo;
		ateText.antialiasing = ClientPrefs.data.antialiasing;
		add(ateText);

		rateText = new FlxText(130, 273, 0, "rate", 30);
		rateText.setFormat(font, 25, FlxColor.WHITE, 'left', FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		rateText.camera = camInfo;
		rateText.antialiasing = ClientPrefs.data.antialiasing;
		add(rateText);

		var ccText = new FlxText(75+115, 273, 0, "Acc: ", 30);
		ccText.setFormat(font, 25, FlxColor.WHITE, 'left', FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		ccText.camera = camInfo;
		ccText.antialiasing = ClientPrefs.data.antialiasing;
		add(ccText);

		accText = new FlxText(75+175, 273, 0, "acc", 30);
		accText.setFormat(font, 25, FlxColor.WHITE, 'left', FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		accText.camera = camInfo;
		accText.antialiasing = ClientPrefs.data.antialiasing;
		add(accText);

		var coreText = new FlxText(75+270, 273, 0, "Score: ", 30);
		coreText.setFormat(font, 25, FlxColor.WHITE, 'left', FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		coreText.camera = camInfo;
		coreText.antialiasing = ClientPrefs.data.antialiasing;
		add(coreText);

		scoreText = new FlxText(75+355, 273, 0, "score", 30);
		scoreText.setFormat(font, 25, FlxColor.WHITE, 'left', FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		scoreText.camera = camInfo;
		scoreText.antialiasing = ClientPrefs.data.antialiasing;
		add(scoreText);

		timeText = new FlxText(50, 240, 0, "time", 28);
		timeText.setFormat(font, 28, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		timeText.camera = camInfo;
		timeText.antialiasing = ClientPrefs.data.antialiasing;
		add(timeText);

		var alpha = 0;
		bars1Option = new FlxSprite().loadGraphic(Paths.image(filePath + 'optionbar'));
		bars1Option.camera = camInfo;
		bars1Option.scale.set(0.66, 0.65);
		bars1Option.antialiasing = ClientPrefs.data.antialiasing;
		bars1Option.alpha = alpha;
		add(bars1Option);

		bars2Option = new FlxSprite().loadGraphic(Paths.image(filePath + 'optionbar'));
		bars2Option.camera = camInfo;
		bars2Option.scale.set(0.62, 0.65);
		bars2Option.antialiasing = ClientPrefs.data.antialiasing;
		bars2Option.alpha = alpha;
		add(bars2Option);

		bars3Option = new FlxSprite().loadGraphic(Paths.image(filePath + 'optionbar'));
		bars3Option.camera = camInfo;
		bars3Option.scale.set(0.65, 0.65);
		bars3Option.antialiasing = ClientPrefs.data.antialiasing;
		bars3Option.alpha = alpha;
		add(bars3Option);

		bars4Option = new FlxSprite().loadGraphic(Paths.image(filePath + 'optionbar'));
		bars4Option.camera = camInfo;
		bars4Option.scale.set(0.62, 0.65);
		bars4Option.antialiasing = ClientPrefs.data.antialiasing;
		bars4Option.alpha = alpha;
		add(bars4Option);

		bars1Option.setPosition(-52-1.5, 395.5);
		bars2Option.setPosition(195+8, 395.5);
		bars3Option.setPosition(-82, 457.5);
		bars4Option.setPosition(170+6, 457.5);

		var options = new FlxText(140, 457, 0, "Options", 28);
		options.setFormat(font, 28, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		options.camera = camInfo;
		options.antialiasing = ClientPrefs.data.antialiasing;
		add(options);

		var options = new FlxText(380, 445, 0, "Gameplay\nChanger", 28);
		options.setFormat(font, 25, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		options.camera = camInfo;
		options.antialiasing = ClientPrefs.data.antialiasing;
		add(options);

		var options = new FlxText(80, 520, 0, "Reset Score", 28);
		options.setFormat(font, 28, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		options.camera = camInfo;
		options.antialiasing = ClientPrefs.data.antialiasing;
		add(options);

		var options = new FlxText(330, 520, 0, "Chart Editor", 28);
		options.setFormat(font, 28, FlxColor.WHITE, LEFT);
		options.camera = camInfo;
		options.antialiasing = ClientPrefs.data.antialiasing;
		add(options);

		for (i in [0, 3]) {
			var back:FlxSprite = new FlxSprite().loadGraphic(Paths.image(filePath + 'overlaps' + i));
			back.antialiasing = ClientPrefs.data.antialiasing;
			back.camera = camUI;
			back.updateHitbox();
			add(back);
		}

		startButton = new FlxSprite().loadGraphic(Paths.image(filePath + 'overlaps2'));
		startButton.antialiasing = ClientPrefs.data.antialiasing;
		startButton.camera = camUI;
		startButton.updateHitbox();
		add(startButton);

		backButton = new FlxSprite().loadGraphic(Paths.image(filePath + 'overlaps1'));
		backButton.antialiasing = ClientPrefs.data.antialiasing;
		backButton.camera = camUI;
		backButton.updateHitbox();
		add(backButton);

		startText = new FlxText(1140, 640, 0, "PLAY", 28);
		startText.setFormat(font, 35, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		startText.camera = camUI;
		startText.antialiasing = ClientPrefs.data.antialiasing;
		add(startText);

		backText = new FlxText(30, 30, 0, "EXIT", 28);
		backText.setFormat(font, 35, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		backText.camera = camUI;
		backText.antialiasing = ClientPrefs.data.antialiasing;
		add(backText);

		searchbg = new FlxSprite(-150, -200).makeGraphic(750, 1000, FlxColor.BLACK);
		searchbg.camera = camSearch;
		searchbg.angle = 15;
		searchbg.updateHitbox();
		searchbg.alpha = 0.75;
		add(searchbg);

		listenbg = new FlxSprite(-150, -200).makeGraphic(750, 1000, FlxColor.BLACK);
		listenbg.camera = camListen;
		listenbg.angle = 15;
		listenbg.updateHitbox();
		listenbg.alpha = 0.75;
		add(listenbg);

		randomButton = new FlxSprite().loadGraphic(Paths.image(filePath + 'random'));
		randomButton.camera = camUI;
		add(randomButton);

		musicButton = new FlxSprite().loadGraphic(Paths.image(filePath + 'musicplayer'));
		musicButton.camera = camUI;
		add(musicButton);

		searchButton = new FlxSprite().loadGraphic(Paths.image(filePath + 'search'));
		searchButton.camera = camUI;
		add(searchButton);

		infoButton = new FlxSprite().loadGraphic(Paths.image(filePath + 'info'));
		infoButton.camera = camUI;
		add(infoButton);

		for (i in [randomButton, musicButton, searchButton, infoButton]) {
			i.scale.set(60/1500, 60/1500);
			i.updateHitbox();
		}
		searchButton.setPosition(800, 0);
		musicButton.setPosition(20, 665);
		randomButton.setPosition(500, 665);
		infoButton.setPosition(200, 0);

		var optionsText = new FlxText(850, 8, 0, 'E to Search Song');
		optionsText.setFormat(font, 25, FlxColor.WHITE, LEFT);
		optionsText.camera = camUI;
		add(optionsText);
		optionsText.scale.x = 0.9;

		var optionsText = new FlxText(70, 675, 0, 'M to Listen Song');
		optionsText.setFormat(font, 25, FlxColor.WHITE, LEFT);
		optionsText.camera = camUI;
		add(optionsText);
		optionsText.scale.x = 0.9;

		var optionsText = new FlxText(550, 675, 0, 'O to get a Random Song');
		optionsText.setFormat(font, 25, FlxColor.WHITE, LEFT);
		optionsText.camera = camUI;
		add(optionsText);
		optionsText.scale.x = 0.9;

		var optionsText = new FlxText(250, 8, 0, 'I to see the tutorial');
		optionsText.setFormat(font, 25, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.TRANSPARENT);
		optionsText.camera = camUI;
		add(optionsText);
		optionsText.scale.x = 0.9;

		makeInfoMenu();
		makeSearchUI();
		makeListenMenu();

		var blackBG = new FlxSprite(0, 0).makeGraphic(1280, 720, FlxColor.BLACK);
		blackBG.antialiasing = ClientPrefs.data.antialiasing;
		blackBG.camera = camBG;
		add(blackBG);

		curSelectedFloat = curSelected;
		changeSong(0);

		camSong.scroll.x = FlxMath.lerp(-(curSelected) * 20 * 0.75, camSong.scroll.x, 0);
		camSong.scroll.y = FlxMath.lerp((curSelected) * 75 * 0.75, camSong.scroll.y, 0);
	}

	var startMouseY:Float;
	var lastCurSelected:Int;
	var canMove:Bool;
	public static var vocals:FlxSound = null;
	public static var instPlaying:Int = 0;
	var leftcolor:FlxTween;
	var rightcolor:FlxTween;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		mousechecker.setPosition(FlxG.mouse.getScreenPosition(camUI).x, FlxG.mouse.getScreenPosition(camUI).y);

		if (!lookingTheTutorial) {
			if (FlxG.mouse.x > FlxG.width/2 || (!searching && ! listening)) {
				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSong(-2 * FlxG.mouse.wheel);
					curSelectedFloat = curSelected;
				}

				if (controls.UI_DOWN_P) {
					changeSong(1);
					curSelectedFloat = curSelected;
				} else if (controls.UI_UP_P) {
					changeSong(-1);
					curSelectedFloat = curSelected;
				}
			}

			if (!searching && !listening) {
				if ((FlxG.mouse.justPressed && FlxG.pixelPerfectOverlap(difficultyLeft, mousechecker, 25)) || controls.UI_LEFT_P) {
					changeDiff(-1);
					difficultyLeft.color = FlxColor.fromRGB(0, 255, 0);
					if (leftcolor != null) leftcolor.cancel();
					leftcolor = FlxTween.color(difficultyLeft, 1, difficultyLeft.color, 0xFFFFFFFF, {
						onComplete: function(twn:FlxTween) {
							leftcolor = null;
		   				}
		   			});
				}
				if ((FlxG.mouse.justPressed && FlxG.pixelPerfectOverlap(difficultyRight, mousechecker, 25)) || controls.UI_RIGHT_P) {
					changeDiff(1);
					difficultyRight.color = FlxColor.fromRGB(255, 0, 0);
					if (rightcolor != null) rightcolor.cancel();
					rightcolor = FlxTween.color(difficultyRight, 1, difficultyRight.color, 0xFFFFFFFF, {
						onComplete: function(twn:FlxTween) {
							rightcolor = null;
		   				}
		   			});
				}
			}

			if ((overlapButton(searchButton) && !searching && FlxG.mouse.justPressed) || FlxG.keys.justPressed.E) {
				searching = true;
				listening = false;
				backText.text = 'BACK';
			}

			if ((overlapButton(musicButton) && !listening && FlxG.mouse.justPressed) || FlxG.keys.justPressed.M) {
				listening = true;
				searching = false;
				backText.text = 'BACK';
			}

			if ((overlapButton(randomButton) && FlxG.mouse.justPressed) || FlxG.keys.justPressed.O) {
				curSelected = FlxG.random.int(0, songs.length-1);
				changeSong(0);
				curSelectedFloat = curSelected;
			}

			if ((overlapButton(infoButton) && FlxG.mouse.justPressed) || FlxG.keys.justPressed.I) {
				lookingTheTutorial = true;
			}

			if (searching) searchUpdate(elapsed);
			if (listening) listenUpdate(elapsed);
			checkButton(elapsed);
			mouseControl(elapsed);

			if (controls.RESET) {
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			} else if (FlxG.keys.justPressed.CONTROL) {
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
			} else if (FlxG.keys.justPressed.P) {
				persistentUpdate = false;
				if (playingSong != -1 || playmusiconexit) {
					if (waitTimer != null) waitTimer.cancel();
					//FlxG.sound.music.volume = 0.1;
				}
				OptionsState.stateType = 2;
				CustomSwitchState.switchMenus('Options');
			}

			camSearch.x = FlxMath.lerp(searching ? 0 : -1280, camSearch.x, FlxMath.bound(1 - (elapsed * 6), 0, 1));
			camListen.x = FlxMath.lerp(listening ? 0 : -1280, camListen.x, FlxMath.bound(1 - (elapsed * 6), 0, 1));
			camInfo.x = FlxMath.lerp((!listening && !searching) ? 0 : -1280, camInfo.x, FlxMath.bound(1 - (elapsed * 6), 0, 1));

			camSong.scroll.x = FlxMath.lerp(-(curSelectedFloat) * 20 * 0.75, camSong.scroll.x, FlxMath.bound(1 - (elapsed * 9), 0, 1));
			camSong.scroll.y = FlxMath.lerp((curSelectedFloat) * 75 * 0.75, camSong.scroll.y, FlxMath.bound(1 - (elapsed * 9), 0, 1));
		}

		changeInfoMenu(elapsed);

		if ((controls.ACCEPT || FlxG.mouse.justReleased) && camUIInfo_Song.alpha > 0.99 && lookingTheTutorial) {
			lookingTheTutorial = false;
			curSelectedFloat = curSelected;
		}
	}

	override function closeSubState()
	{
		super.closeSubState();
		persistentUpdate = true;
		closeSubStatePost();
	}

	function overlapButton(tag:FlxSprite)
		return FlxG.mouse.x > tag.x && FlxG.mouse.x < tag.x + 500 && FlxG.mouse.y > tag.y && FlxG.mouse.y < tag.y + 50;

	function changeInfoMenu(elapsed:Float) {
		var list = [camUIInfo_Info, camUIInfo_Song, camUIInfo_Listen, camUIInfo_Search];
		if (!lookingTheTutorial) {
			for (i in list) setAlpha(i, -2);
		} else {
			if (listening) {
				setAlpha(camUIInfo_Listen, 2);
				setAlpha(camUIInfo_Info, -2);
				setAlpha(camUIInfo_Search, -2);
			} else if (searching) {
				setAlpha(camUIInfo_Listen, -2);
				setAlpha(camUIInfo_Info, -2);
				setAlpha(camUIInfo_Search, 2);
			} else {
				setAlpha(camUIInfo_Listen, -2);
				setAlpha(camUIInfo_Info, 2);
				setAlpha(camUIInfo_Search, -2);
			}
			setAlpha(camUIInfo_Song, 2);
		}
	}

	function setAlpha(obj:FlxCamera, multiple:Int) {
		if (obj.alpha > 0 && multiple <= 0)
			obj.alpha += FlxG.elapsed*multiple;
		else if (obj.alpha < 1.0 && multiple > 0)
			obj.alpha += FlxG.elapsed*multiple;
	}

	function makeInfoMenu() {
		addSimpleText('Choose song by using mouse wheel, \n(put mouse at right part of the screen) \ntouching screen, pressing UI down and up keys', [640, 150], 30, [0.9, 1], camUIInfo_Song, 'center');
		addSimpleBox([FlxG.width - 220, FlxG.height - 120], [220, 120], camUIInfo_Song);
		addSimpleText('Press Accept key or touch it to start (↓)', [640, 550], 30, [0.9, 1], camUIInfo_Song, 'center');

		addSimpleText('Your best result (↓)', [0, 185], 30, [0.9, 1], camUIInfo_Info, 'center');
		addSimpleText('Holding to use (↑)', [0, 600], 30, [0.9, 1], camUIInfo_Info, 'center');
		addSimpleBox([0, 0], [220, 120], camUIInfo_Info);
		addSimpleText('(↑) Press Back key or touch it to exit', [0, 115], 30, [0.9, 1], camUIInfo_Info, 'center');

		addSimpleText('UI left and right key or touch bar to change time', [-50, 460], 30, [0.75, 0.75], camUIInfo_Listen, 'left');
		addSimpleText('Press Q and E keys or touch it to change playback rate', [-50, 580], 30, [0.75, 0.75], camUIInfo_Listen, 'left');

		addSimpleText('Change song by using mouse wheel, \n(put mouse at right part of the screen) \ntouching screen, pressing UI down and up keys\n\ntouch or press number keys(1-6) to choose song', [0, 250], 30, [0.9, 1], camUIInfo_Search, 'center');
	}

	function addSimpleText(string:String, pos:Dynamic, size:Int, scale:Dynamic, cam:FlxCamera, alignment:Dynamic) {
		var text = new FlxText(pos[0], pos[1], Std.int(FlxG.width/2), string);
		text.setFormat(font, size, FlxColor.WHITE, alignment == 'center' ? CENTER : (alignment == 'left' ? LEFT : RIGHT));
		text.camera = cam;
		text.scale.set(scale[0], scale[1]);
		add(text);
	}

	function addSimpleBox(pos:Dynamic, size:Dynamic, cam:FlxCamera) {
		var sprite = new FlxSprite(pos[0], pos[1]).makeGraphic(size[0], size[1], FlxColor.WHITE);
		sprite.camera = cam;
		sprite.alpha = 0.3;
		add(sprite);
	}

	var listeningSongName:FlxText;
	var playingSongName:FlxText;
	var listeningSongTime:FlxText;
	var playingSong:Int = -1;
	var maxTime:Float = 0;

	var playText:FlxText;
	var playButton:FlxSprite;
	var pauseText:FlxText;
	var pauseButton:FlxSprite;
	var pausedsong:Bool = false;

	var progressBar:FlxSprite;
	var timeLeft:FlxSprite;
	var timeRight:FlxSprite;
	var changingTime:Bool = false;

	var songPlaybackRate:Float = 1;
	var songPlaybackRateText:FlxText;
	var rateLeft:FlxSprite;
	var rateRight:FlxSprite;
	var resetButton:FlxSprite;
	function makeListenMenu() {
		//startMusic(false);
		listeningSongName = new FlxText(40, 190, 0, songs[curSelected].songName);
		listeningSongName.setFormat(font, 50, FlxColor.WHITE, 'center');
		listeningSongName.camera = camListen;
		add(listeningSongName);

		playingSongName = new FlxText(50, 235, 0, 'Playing: ' + (playingSong == -1 ? 'Freaky Menu' : songs[playingSong].songName));
		playingSongName.setFormat(font, 30, FlxColor.WHITE, CENTER);
		playingSongName.camera = camListen;
		add(playingSongName);
		playingSongName.x = 60 + (450-playingSongName.width)/2;

		listeningSongTime = new FlxText(120, 350, 500, '-:-/-:-');
		listeningSongTime.setFormat(font, 30, FlxColor.WHITE, CENTER);
		listeningSongTime.camera = camListen;
		add(listeningSongTime);

		playText = new FlxText(50, 350, 0, 'PLAY(1)');
		playText.setFormat(font, 30, FlxColor.WHITE, LEFT);
		playText.camera = camListen;
		add(playText);

		playButton = new FlxSprite(40, 340).makeGraphic(145, 60, FlxColor.WHITE);
		playButton.camera = camListen;
		playButton.alpha = 0;
		add(playButton);

		pauseText = new FlxText(50, 440, 0, 'PAUSE(2)');
		pauseText.setFormat(font, 30, FlxColor.WHITE, LEFT);
		pauseText.camera = camListen;
		add(pauseText);

		pauseButton = new FlxSprite(40, 430).makeGraphic(165, 60, FlxColor.WHITE);
		pauseButton.camera = camListen;
		pauseButton.alpha = 0;
		add(pauseButton);

		timeLeft = new FlxSprite(215, 445).makeGraphic(160, 30, FlxColor.WHITE);
		timeLeft.camera = camListen;
		timeLeft.alpha = 0.25;
		add(timeLeft);

		timeRight = new FlxSprite(375, 445).makeGraphic(160, 30, FlxColor.WHITE);
		timeRight.camera = camListen;
		timeRight.alpha = 0.25;
		add(timeRight);

		progressBar = new FlxSprite(225, 455).makeGraphic(1, 10, FlxColor.WHITE);
		progressBar.camera = camListen;
		add(progressBar);

		rateLeft = new FlxSprite(320-50, 530).makeGraphic(100, 60, FlxColor.WHITE);
		rateLeft.camera = camListen;
		rateLeft.alpha = 0.25;
		add(rateLeft);

		rateRight = new FlxSprite(370, 530).makeGraphic(100, 60, FlxColor.WHITE);
		rateRight.camera = camListen;
		rateRight.alpha = 0.25;
		add(rateRight);

		songPlaybackRateText = new FlxText(290, 540, 150, '1.0');
		songPlaybackRateText.setFormat(font, 30, FlxColor.WHITE, CENTER);
		songPlaybackRateText.camera = camListen;
		add(songPlaybackRateText);

		var rateResetText = new FlxText(50, 540, 0, 'RESET(3)');
		rateResetText.setFormat(font, 30, FlxColor.WHITE, LEFT);
		rateResetText.camera = camListen;
		add(rateResetText);

		resetButton = new FlxSprite(40, 530).makeGraphic(165, 60, FlxColor.WHITE);
		resetButton.camera = camListen;
		resetButton.alpha = 0;
		add(resetButton);
		setplaybackrate();
	}

	function startMusic(play:Bool)
	{
		destroyFreeplayVocals();
		var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
		if (ClientPrefs.data.chartLoadSystem == '1.0x') Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
		else PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());

		if (PlayState.SONG.needsVoices)
		{
			vocals = new FlxSound();
			try
			{
				vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
			}
			catch(e:Dynamic) {}
			FlxG.sound.list.add(vocals);
			vocals.persist = true;
			vocals.looped = true;
		}
		else if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
			vocals = null;
		}

		if (play) {
			FlxG.sound.music.stop();
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
			maxTime = FlxG.sound.music.length;
			if(vocals != null)
			{
				vocals.play();

				vocals.volume = 0.8;
			}
			listeningSongTime.text = timeConverter(0) + '/' + timeConverter(maxTime);

			playingSong = curSelected;

			playingSongName.scale.set(1, 1);
			playingSongName.updateHitbox();

			playingSongName.text = 'Playing: ' + (playingSong == -1 ? 'Freaky Menu' : songs[playingSong].songName);
			playingSongName.x = 60 + (450-playingSongName.width)/2;
			if (playingSongName.width > 450) {
				playingSongName.scale.set(450/playingSongName.width, 450/playingSongName.width);
			}

			setplaybackrate();
		}
		if (waitTimer != null) waitTimer.cancel();
	}

	var waitTimer:FlxTimer;
	var playmusiconexit:Bool = false;
	function listenUpdate(elapsed:Float) {
		if (playButton.alpha > 0)
			playButton.alpha -= elapsed;

		if (playingSong == curSelected)
			playText.text = 'STOP(1)';
		else
			playText.text = 'PLAY(1)';

		if (FlxG.mouse.overlaps(playButton) && FlxG.mouse.justPressed) {
			playButton.alpha = 0.75;

			if (playText.text.indexOf('STOP') != -1) {
				destroyFreeplayVocals();
				FlxG.sound.music.stop();
				playingSong = -1;
				playmusiconexit = true;
				if (waitTimer != null) waitTimer.cancel();
				waitTimer = new FlxTimer().start(1, function(tmr:FlxTimer) {
					if (playingSong == -1) {
						waitTimer = null;
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.volume = 0.1;
						playmusiconexit = false;

						playingSongName.scale.set(1, 1);
						playingSongName.updateHitbox();

						playingSongName.text = 'Playing: ' + (playingSong == -1 ? 'Freaky Menu' : songs[playingSong].songName);
						playingSongName.x = 60 + (450-playingSongName.width)/2;
						if (playingSongName.width > 450) {
							playingSongName.scale.set(450/playingSongName.width, 450/playingSongName.width);
						}
					}
				});
				return;
			}

			if (playingSong != curSelected)
				startMusic(true);
		}

		if (pauseButton.alpha > 0)
			pauseButton.alpha -= elapsed;

		if (rateLeft.alpha > 0)
			rateLeft.alpha -= elapsed;

		if (rateRight.alpha > 0)
			rateRight.alpha -= elapsed;

		if ((FlxG.mouse.justPressed && FlxG.mouse.overlaps(rateLeft)) || FlxG.keys.justPressed.Q) {
			rateLeft.alpha = 0.75;
			if (songPlaybackRate > 0.1)
				songPlaybackRate -= 0.05;
			songPlaybackRate = FlxMath.roundDecimal(songPlaybackRate, 2);
			setplaybackrate();
		}

		if ((FlxG.mouse.justPressed && FlxG.mouse.overlaps(rateRight)) || FlxG.keys.justPressed.E) {
			rateRight.alpha = 0.75;
			if (songPlaybackRate < 4)
				songPlaybackRate += 0.05;
			songPlaybackRate = FlxMath.roundDecimal(songPlaybackRate, 2);
			setplaybackrate();
		}

		if (resetButton.alpha > 0)
			resetButton.alpha -= elapsed;

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(resetButton)) {
			resetButton.alpha = 0.75;
			songPlaybackRate = 1;
			setplaybackrate();
		}

		if (playingSong != -1) {
			if ((FlxG.mouse.overlaps(pauseButton) && FlxG.mouse.justPressed)) {
				pauseButton.alpha = 0.75;

				if (pausedsong) {
					FlxG.sound.music.play();
					if (vocals != null) vocals.play();
				} else {
					FlxG.sound.music.pause();
					if (vocals != null) vocals.pause();
				}

				if (vocals != null) {
					vocals.time = FlxG.sound.music.time;
				}

				pausedsong = !pausedsong;
			}

			if ((FlxG.mouse.overlaps(timeLeft) && !pausedsong) || controls.UI_LEFT_P || controls.UI_LEFT) {
				if (FlxG.mouse.justPressed || controls.UI_LEFT_P) {
					FlxG.sound.music.pause();
					if (vocals != null) vocals.pause();
					changingTime = true;
				}

				if ((FlxG.mouse.pressed || controls.UI_LEFT) && changingTime) {
					timeLeft.alpha = 0.25;
					timeRight.alpha = 0;
					FlxG.sound.music.time -= 12000*elapsed;
					if (FlxG.sound.music.time <= 0)
						FlxG.sound.music.time = 0;
				}
			}else if ((FlxG.mouse.overlaps(timeRight) && !pausedsong) || controls.UI_RIGHT_P || controls.UI_RIGHT) {
				if (FlxG.mouse.justPressed || controls.UI_RIGHT_P) {
					FlxG.sound.music.pause();
					if (vocals != null) vocals.pause();
					changingTime = true;
				}

				if ((FlxG.mouse.pressed || controls.UI_RIGHT) && changingTime) {
					timeRight.alpha = 0.25;
					timeLeft.alpha = 0;
					FlxG.sound.music.time += 12000*elapsed;
					if (FlxG.sound.music.time >= maxTime)
						FlxG.sound.music.time = maxTime;
				}
			}

			if (changingTime && FlxG.mouse.justReleased) {
				changingTime = false;
				FlxG.sound.music.play();
				if (vocals != null) {
					vocals.play();
					vocals.time = FlxG.sound.music.time;
				}
				timeLeft.alpha = 0;
				timeRight.alpha = 0;
			}

			listeningSongTime.text = timeConverter(FlxG.sound.music.time) + '/' + timeConverter(maxTime);
			progressBar.scale.x = FlxG.sound.music.time/FlxG.sound.music.length*300;
			progressBar.updateHitbox();
		} else {
			progressBar.scale.x = 0;
			timeLeft.alpha = 0;
			timeRight.alpha = 0;
		}
	}

	function setplaybackrate() {
		songPlaybackRateText.text = '< ' + Std.string(songPlaybackRate) + 'x >';
		if (vocals != null) vocals.pitch = songPlaybackRate;
		FlxG.sound.music.pitch = songPlaybackRate;
	}

	public static function destroyFreeplayVocals() {
		if(FreeplayStateNF.vocals != null) {
			FreeplayStateNF.vocals.stop();
			FreeplayStateNF.vocals.destroy();
		}
		FreeplayStateNF.vocals = null;
	}

	function closeListenMenu() {
		listening = false;
	}

	override function destroy() {
		super.destroy();
	}
   
	function timeConverter(time:Float) {
		var secondsTotal:Int = Math.floor(time / 1000);
		return FlxStringUtil.formatTime(secondsTotal, false);
	}

	var searchInput:FlxInputText;
	public static var searchSelected:Int = 0;
	var searchSelectedObj:FlxSprite;
	var searchTextGroup:Array<FlxText> = [];
	var searchCheckGroup:Array<FlxSprite> = [];
	var oldText:String = '';
	var searchtextno:FlxText;
	var playSine:Float = 0;
	function makeSearchUI() {
		searchtext = new FlxText(60, 150, 0, 'Type Song Name...');
		searchtext.setFormat(font, 28, FlxColor.WHITE, LEFT);
		searchtext.camera = camSearch;
		add(searchtext);
		searchtext.alpha = 0.5;

		var underbar = new FlxSprite(60, 190).makeGraphic(450, 2, FlxColor.WHITE);
		underbar.camera = camSearch;
		underbar.updateHitbox();
		add(underbar);

		searchInput = new FlxInputText(60, 150, 450, '', 30, 0x00FFFFFF);
		searchInput.focusGained = () -> FlxG.stage.window.textInputEnabled = true; 
		searchInput.backgroundColor = FlxColor.TRANSPARENT;
		searchInput.fieldBorderColor = FlxColor.TRANSPARENT;
		searchInput.font = font;
		searchInput.antialiasing = ClientPrefs.data.antialiasing;
		searchInput.camera = camSearch;
		add(searchInput);

		for (i in 0...6) {
			var searchobj = new FlxText(125-i*15, 260+i*60, 0, '');
			searchobj.setFormat(font, 35, FlxColor.WHITE, LEFT);
			searchobj.camera = camSearch;
			searchTextGroup.push(searchobj);

			var underbar = new FlxSprite(125-i*15, 260+i*60).makeGraphic(1, 1, FlxColor.WHITE);
			underbar.camera = camSearch;
			underbar.updateHitbox();
			underbar.alpha = 0;
			add(underbar);
			searchCheckGroup.push(underbar);

			add(searchobj);
		}

		searchtextno = new FlxText(100, 380, 0, 'NO SONG');
		searchtextno.setFormat(font, 35, FlxColor.RED, 'left');
		searchtextno.camera = camSearch;
		add(searchtextno);
		searchtextno.alpha = 0.9;
		searchtextno.visible = false;
	}

	function closeSearchMenu() {
		searching = false;
	}

	public static var songsSearched:Array<SongMetadata> = [];
	var startMouseYsearch:Float = 0;
	var fakecurSelected = 0;
	var lastSelectedSearch = 0;
	function searchUpdate(elapsed:Float) {
		searchtext.visible = searchInput.text == '';

		if (oldText != searchInput.text) {
			oldText = searchInput.text;
			if (searchInput.text == '') return;
			songsSearched = [];
			for (i in 0...songs.length) {
				if ((songs[i].songName.toLowerCase()).indexOf(searchInput.text.toLowerCase()) != -1) {
					songs[i].searchnum = i;
					songsSearched.push(songs[i]);
				}
			}
			if (songsSearched.length < 1) {
				songsSearched.push(new SongMetadata('', 0, 'no', 0x00FFFFFF));
				searchtextno.visible = true;
			} else
				searchtextno.visible = false;
			searchChangeSong(0);
		}

		playSine += 180 * elapsed;
		searchtextno.alpha = 1 - Math.sin((Math.PI * playSine) / 180);

		if (FlxG.mouse.justPressed && FlxG.pixelPerfectOverlap(searchbg, mousechecker, 0))
		{
			startMouseYsearch = FlxG.mouse.y;
			fakecurSelected = searchSelected;
			lastSelectedSearch = searchSelected;
		}

		if (FlxG.mouse.pressed && FlxG.pixelPerfectOverlap(searchbg, mousechecker, 0))
		{
			searchSelected = Math.floor(fakecurSelected - (FlxG.mouse.y - startMouseYsearch) / (75*0.75));

			if (searchSelected > songsSearched.length-6)
				searchSelected = songsSearched.length-6;

			if (searchSelected < 0)
				searchSelected = 0;

			/*
				奇怪了你怎么把我那个修炸了
				把这加回来顺便加个备注
				写个
				//别删这里否则搜索会炸

				写这个给谁看。

				如果有人优化的话
			*/
		}

		if (lastSelectedSearch != searchSelected) {
			lastSelectedSearch = searchSelected;
			searchChangeSong(0);
		}

		for (i in 0...searchTextGroup.length) {
			if (FlxG.mouse.overlaps(searchCheckGroup[i]) && FlxG.mouse.justPressed && searchTextGroup[i].text != '') {
				curSelected = songsSearched[searchSelected + i].searchnum;
				curSelectedFloat = curSelected;
				changeSong(0);
			}
		}

		var numkeys = [FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR, FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX];
		for (i in 0...numkeys.length) {
			if (numkeys[i] == true) {
				curSelected = songsSearched[searchSelected + i].searchnum;
				curSelectedFloat = curSelected;
				changeSong(0);
			}
		}

		if (FlxG.mouse.x <= FlxG.width/2.5) {
			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				searchChangeSong(-2 * FlxG.mouse.wheel);
			}

			if (controls.UI_UP_P)
				searchChangeSong(-1);
			else if (controls.UI_DOWN_P)
				searchChangeSong(1);
		}
	}

	function searchChangeSong(num:Int) {
		searchSelected += num;
		if (searchSelected > songsSearched.length-6)
			searchSelected = songsSearched.length-6;

		if (searchSelected < 0)
			searchSelected = 0;

		for (i in 0...searchTextGroup.length) {
			var id:Int = 0;
				id = i+searchSelected;
			if (songsSearched[id] != null)
				searchTextGroup[i].text = songsSearched[id].songName;
			else
				searchTextGroup[i].text = '';

			searchCheckGroup[i].makeGraphic(Std.int(searchTextGroup[i].width), Std.int(searchTextGroup[i].height), FlxColor.WHITE);
   		}
	}

	var selectedThing:String = 'Nothing';
	var buttonControl:Bool = true;
	function checkButton(elapsed:Float) {
		if (FlxG.mouse.justPressed && buttonControl) {
			if (FlxG.pixelPerfectOverlap(startButton, mousechecker, 25)) {
				selectedThing = 'start';
			} else if (FlxG.pixelPerfectOverlap(backButton, mousechecker, 25)) {
				selectedThing = 'back';
			} else
				selectedThing = 'Nothing';
		}

		if (FlxG.mouse.justReleased || controls.ACCEPT || controls.BACK) {
			if ((selectedThing == 'start' && FlxG.pixelPerfectOverlap(startButton, mousechecker, 25)) || controls.ACCEPT) {
				var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
				var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
				try
				{
					if (ClientPrefs.data.chartLoadSystem == '1.0x') Song.loadFromJson(poop, songLowercase);
					else PlayState.SONG = Song.loadFromJson(poop, songLowercase);
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = curDifficulty;

					if(colorTween != null) {
						colorTween.cancel();
					}

					if(bgColorChange != null) {
						bgColorChange.cancel();
					}

					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
				catch(e:Dynamic)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));

					return;
				}
				destroyFreeplayVocals();
				FlxG.sound.music.stop();
				if (ClientPrefs.data.loadingScreen && ClientPrefs.data.TransitionStyle == 'NovaFlare') {
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
				}
				LoadingState.prepareToSong();
				LoadingState.loadAndSwitchState(new PlayState());
				#if HIDE_CURSOR FlxG.mouse.visible = false; #end

				//FlxG.sound.music.volume = 0;

				//destroyFreeplayVocals();
				buttonControl = false;
			} else if ((selectedThing == 'back' && FlxG.pixelPerfectOverlap(backButton, mousechecker, 25)) || controls.BACK) {
				if (searching) {closeSearchMenu(); backText.text = 'EXIT'; return;}
				if (listening) {closeListenMenu(); backText.text = 'EXIT'; return;}
				Mods.loadTopMod();
				#if HIDE_CURSOR FlxG.mouse.visible = false; #end
				if(colorTween != null) {
					colorTween.cancel();
				}
				if(bgColorChange != null) {
					bgColorChange.cancel();
				}
				if (playingSong != -1 || playmusiconexit) {
					destroyFreeplayVocals();
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					if (waitTimer != null) waitTimer.cancel();
					//FlxG.sound.music.volume = 0.1;
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				CustomSwitchState.switchMenus('MainMenu');
				buttonControl = false;
			}
			selectedThing = 'Nothing';
		}
		if (FlxG.mouse.pressed){
			startButton.x = FlxMath.lerp(selectedThing == 'start' ? 15 : 0, startButton.x, FlxMath.bound(1 - (elapsed * 12), 0, 1));
			backButton.x = FlxMath.lerp(selectedThing == 'back' ? -15 : 0, backButton.x, FlxMath.bound(1 - (elapsed * 12), 0, 1));

			startText.x = FlxMath.lerp(selectedThing == 'start' ? 1155 : 1140, startText.x, FlxMath.bound(1 - (elapsed * 12), 0, 1));
			backText.x = FlxMath.lerp(selectedThing == 'back' ? 15 : 30, backText.x, FlxMath.bound(1 - (elapsed * 12), 0, 1));
		}
	}

	function mouseControl(elapsed:Float){
		if (FlxG.mouse.justPressed && !canMove && selectedThing == 'Nothing')
		{
			curSelectedFloat = curSelected;
			lastCurSelected = curSelected;
			startMouseY = FlxG.mouse.y;

			if (FlxG.mouse.x >= 700 && FlxG.mouse.y > 50 && FlxG.mouse.y < FlxG.height - 50)
				canMove = true;
			else
				canMove = false;
		}

		if (FlxG.mouse.pressed && canMove)
		{
			if (!(FlxG.mouse.x >= 700 && FlxG.mouse.y > 50 && FlxG.mouse.y < FlxG.height - 50)){
				canMove = false;
				if (curSelectedFloat < -3)
					curSelected = songs.length - 1;
				else if (curSelectedFloat > songs.length + 2)
					curSelected = 0;

				curSelectedFloat = curSelected;
				changeSong(0);
				return;
			}

			var checkCurSelected:Int = curSelected;
			curSelectedFloat = lastCurSelected - (FlxG.mouse.y - startMouseY) / (75*0.75);
			if (curSelectedFloat < (songs.length - 1) && curSelectedFloat > 0)
			{
				curSelected = Math.floor(curSelectedFloat+0.5);
			} else {
				if (curSelectedFloat >= (songs.length - 1) && curSelectedFloat <= songs.length +2)
					curSelected = songs.length - 1;
				else if (curSelectedFloat <= 0 && curSelectedFloat >= -3)
					curSelected = 0;
			}
			if (checkCurSelected != curSelected) changeSong(0);
		}

		if (FlxG.mouse.justReleased && canMove)
		{
			if (curSelectedFloat < -3)
				curSelected = songs.length - 1;
			else if (curSelectedFloat > songs.length + 2)
				curSelected = 0;

			curSelectedFloat = curSelected;
			changeSong(0);
			canMove = false;
		}

		var optionsGroup:Array<FlxSprite> = [bars1Option, bars2Option, bars3Option, bars4Option];
		for (i in 0...holdOptionsChecker.length) {
			if (FlxG.mouse.justPressed && FlxG.pixelPerfectOverlap(holdOptionsChecker[i], mousechecker, 25) && !searching && !listening) {
				holdOptions = true;
				curHoldOptions = i;
			}

			if (curHoldOptions != i || !holdOptions) {
				if (optionsGroup[i].alpha > 0)
					optionsGroup[i].alpha -= elapsed*2;

				if (optionsGroup[i].alpha <= 0)
					optionsGroup[i].alpha = 0;
			}
		}

		if (!FlxG.pixelPerfectOverlap(holdOptionsChecker[curHoldOptions], mousechecker, 25))
			holdOptions = false;

		if (FlxG.mouse.pressed && holdOptions && !searching && !listening && optionsGroup[curHoldOptions] != null) {
			if (optionsGroup[curHoldOptions].alpha <= 1)
				optionsGroup[curHoldOptions].alpha += elapsed * 3;

			if (optionsGroup[curHoldOptions].alpha > 1)
				optionsGroup[curHoldOptions].alpha = 1;
		}

		if (searching || listening) holdOptions = false;

		if (FlxG.mouse.justReleased) {
			holdOptions = false;
		}

		if (optionsGroup[curHoldOptions].alpha >= 0.99) {
			holdOptions = false;
			persistentUpdate = false;
			switch(curHoldOptions) {
				case 0: //Options
					if (playingSong != -1 || playmusiconexit) {
						if (waitTimer != null) waitTimer.cancel();
						//FlxG.sound.music.volume = 0.1;
					}  
					OptionsState.stateType = 2;
					CustomSwitchState.switchMenus('Options');
				case 1: // Gameplay Changer
					openSubState(new GameplayChangersSubstate());
				case 2: // Reset Score
					openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
				case 3: // idk
					var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
					var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
					if (ClientPrefs.data.chartLoadSystem == '1.0x') Song.loadFromJson(poop, songLowercase);
					else PlayState.SONG = Song.loadFromJson(poop, songLowercase);
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = curDifficulty;
					if(colorTween != null) colorTween.cancel();
					if (rightcolor != null) rightcolor.cancel();
					if (leftcolor != null) rightcolor.cancel();
					CustomSwitchState.switchMenus('Charting', true);
			}
		}
	}

	var modCheck = Mods.currentModDirectory;

	function changeSong(iiiiint:Int)
	{
		curSelected += iiiiint;
		if (curSelected > songs.length-1)
			curSelected = 0;
		else if (curSelected < 0)
			curSelected = songs.length-1;

		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();

		bgCheck();
		changeDiff(0);

		songNameText.text = songs[curSelected].songName;
		songNameText.scale.x = 1;
		var length = 450;
		if (songNameText.width > length) songNameText.scale.x =  length / songNameText.width;
		songNameText.offset.x = songNameText.width * (1 -songNameText.scale.x) / 2;

		listeningSongName.text = songs[curSelected].songName;
		listeningSongName.x = 70 + (450-listeningSongName.width)/2;
		if (listeningSongName.width > 450) {
			listeningSongName.scale.set(450/listeningSongName.width, 450/listeningSongName.width);
		}

		songIcon.changeIcon(songs[curSelected].songCharacter);
		songIcon.updateHitbox();
	}

	function changeDiff(value:Int)
	{
		curDifficulty += value;
		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty > Difficulty.list.length - 1)
			curDifficulty = 0;
		var rate:Float = 0;

		try {
			var song = songs[curSelected].songName.toLowerCase();
			if (Paths.fileExists('data/' + Paths.formatToSongPath(song) + '/' + Paths.formatToSongPath(song) + Difficulty.getFilePath(curDifficulty)+'.json', TEXT)) {
				var poop:String = Highscore.formatSong(song, curDifficulty);
				rate = DiffCalc.CalculateDiff(Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase())) / 4;
			}
		} catch(e:Dynamic) {
			rate = -1;
			songNameText.text = 'ERROR';
		}

		rateCheck(rate);
		updateInfoText();
	}

	function updateInfoText()
	{
		try {
		difficultyText.text = Difficulty.list[curDifficulty];
		difficultyText.x = (820 - difficultyText.width) / 2;
		if (difficultyText.width > 300)
			difficultyText.scale.set(300/difficultyText.width, 300/difficultyText.width);

		var score:Int = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		scoreText.text = Std.string(score);

		scoreText.scale.x = 1;
		scoreText.updateHitbox();

		if (scoreText.width > 120) {
			scoreText.scale.x = 120 / scoreText.width;
			scoreText.updateHitbox();
		}

		var rating:Float = Math.floor(Highscore.getRating(songs[curSelected].songName, curDifficulty)*10000)/100;
		accText.text = rating + '%';
		accText.scale.x = 0.9;
		accText.updateHitbox();
		if (accText.width > 90) {
			accText.scale.x = 90 / accText.width * 0.9;
			accText.updateHitbox();
		}

		timeText.text = Highscore.getTime(songs[curSelected].songName, curDifficulty);
		} catch(e:Dynamic) {
			songNameText.text = 'ERROR';
		}
	}

	function returnSearchSong(string:String) {
		var coolSongs:Array<SongMetadata> = [];
		for (i in songs) {
			if (i.songName.indexOf(string) != -1)
				coolSongs.push(i);
		}

		return coolSongs;
	}

	function loadSong()
	{
		songs = [];
		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();
	}

	function addSongTxt()
	{
		songtextsGroup = [];
		iconsArray = [];
		barsArray =  [];

		for (i in 0...songs.length)
		{
			var songText = new FlxText(750 - i*20 * 0.75, i*75 * 0.75 + 355, 0, songs[i].songName, 30);
			songText.setFormat(font, 30, FlxColor.WHITE, LEFT);
			songText.camera = camSong;
			var length = 400;
			if (songText.width > length) songText.scale.x =  length / songText.width;
			songText.offset.x += songText.width * (1 -songText.scale.x) / 2;
			songtextsGroup.push(songText);

			Mods.currentModDirectory = songs[i].folder;

			var barShadow:FlxSprite = new FlxSprite().loadGraphic(Paths.image(filePath + 'songBarShadow'));
			add(barShadow);
			barShadow.camera = camSong;
			barShadow.scale.set(1, 1);
			barShadow.x = songText.x - 750;
			barShadow.y = songText.y -300;
			barShadow.updateHitbox();
			barShadow.color = songs[i].color;
			barsArray.push(barShadow);

			var bar:FlxSprite = new FlxSprite().loadGraphic(Paths.image(filePath + 'songBar'));
			add(bar);
			bar.camera = camSong;
			bar.scale.set(1, 1);
			bar.x = songText.x - 750;
			bar.y = songText.y - 300;
			bar.updateHitbox();
			barsArray.push(bar);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			add(icon);
			icon.scale.set(0.35, 0.35);
			icon.camera = camSong;
			icon.x = songText.x + 370;
			icon.y = songText.y + songText.height / 2 - icon.height / 2;
			icon.updateHitbox();
			icon.scrollFactor.set(1,1);
			iconsArray.push(icon);

			add(songText);
			camSong.alpha = 0.6;
		}
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	 function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function bgCheck()
	{
		if (bg.color == songs[curSelected].color)
			return;

		if (modCheck != Mods.currentModDirectory){
			modCheck = Mods.currentModDirectory;

			if (bgColorChange != null) bgColorChange.cancel();
			if (colorTween != null) colorTween.cancel();
	   
			bgColorChange = FlxTween.color(bg, 0.35, bg.color, FlxColor.BLACK, {
				onComplete: function(twn:FlxTween) {
					bg.loadGraphic(Paths.image('menuDesat'));
					bg.screenCenter();

					bgColorChange = FlxTween.color(bg, 0.35, FlxColor.BLACK, songs[curSelected].color);
				}
			});
		}else{
		  	var newColor:Int = songs[curSelected].color;
	  		if(newColor != intendedColor) {
	  
	  			if (bgColorChange != null) bgColorChange.cancel();
				if (colorTween != null){
					colorTween.cancel();
					bg.loadGraphic(Paths.image('menuDesat'));
					bg.screenCenter();
				}

	   			intendedColor = newColor;
	   			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
					onComplete: function(twn:FlxTween) {
						colorTween = null;
   					}
   				});
			}
		}
	}

	var saveVar:Float = 0;
	function rateCheck(Rate:Float = 0)
	{
		rateText.text = Std.string(Math.floor(Rate*100)/100);
		if (rateText.width*0.9 > 65) rateText.scale.x = 65/rateText.width*0.9;
		else rateText.scale.x = 0.9;
		rateText.updateHitbox();

		if (Rate == -1) {rateText.text = 'RATE ERROR'; return;}
		if (Rate > 20) Rate = 20;
		var showWidth = 0;

		if (timerTween != null){
			saveVar = swagRect.width;
			timerTween.cancel();
		}
		timerTween = new FlxTimer().start(0.0001, function(tmr:FlxTimer) {
			showWidth++;
			swagRect = rate.clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, 0, 0);
			swagRect.x = 0;
			swagRect.y = 0;
			swagRect.width = saveVar + (rate.width * (Rate / 20) - saveVar) * showWidth / 20;
			swagRect.height = rate.height;
			rate.clipRect = swagRect;

			if (showWidth == 20){ 
				tmr.cancel();
				saveVar = swagRect.width;
			}
		}, 0);
	}
}