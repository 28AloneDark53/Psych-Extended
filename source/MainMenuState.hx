package;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import editors.MasterEditorMenu;
import options.OptionsState;

//0.6.3 import
import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

enum MainMenuColumn {
	LEFT;
	CENTER;
	RIGHT;
}

class MainMenuState extends MusicBeatState
{
    public static var instance:MainMenuState;
    
	public static var psychEngineVersion:String = '0.6.3'; // This is also used for Discord RPC
	public static var realPsychEngineVersion:String = '0.6.4b';
	public static var psychExtendedVersion:String = '1.0.2';
	public var curSelected:Int = 0;
	public static var curColumn:MainMenuColumn = CENTER;

    var versionShit:FlxText;
    var psychVer:FlxText;
    var fnfVer:FlxText;
    
	var menuItems:FlxTypedGroup<FlxSprite>;
	var leftItem:FlxSprite;
	var rightItem:FlxSprite;
	var debugKeys:Array<FlxKey>;
	private var camAchievement:FlxCamera;

	//Centered/Text options
	public var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		'credits'
	];

	public var leftOption:String = #if ACHIEVEMENTS_ALLOWED 'achievements' #else null #end;
	public var rightOption:String = 'options';

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	override function create()
	{
		instance = this;

		super.create();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;
		FlxG.cameras.add(camAchievement, false);

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = 0.25;
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (num => option in optionShit)
		{
			var item:FlxSprite = createMenuItem(option, 0, (num * 140) + 90);
			item.y += (4 - optionShit.length) * 70; // Offsets for when you have anything other than 4 items
			item.screenCenter(X);
		}

		if (leftOption != null)
			leftItem = createMenuItem(leftOption, 60, 490);
		if (rightOption != null)
		{
			rightItem = createMenuItem(rightOption, FlxG.width - 60, 490);
			rightItem.x -= rightItem.width;
		}

        versionShit = new FlxText(12, FlxG.height - 64, 0, "Psych Extended v" + psychExtendedVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		psychVer = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + realPsychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		fnfVer = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);
		changeItem();

		#if ACHIEVEMENTS_ALLOWED
    	// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
    		var leDate = Date.now();
    	    if (leDate.getDay() == 5 && leDate.getHours() >= 18)
    			Achievements.unlock('friday_night_play');
    
    		#if MODS_ALLOWED
    		Achievements.reloadList();
    		#end
    	#end

		#if TOUCH_CONTROLS
		addMobilePad("NONE", "SELECTOR_1.0");
		_virtualpad.alpha = 1;
		#end

		FlxG.camera.follow(camFollow, null, 0.15);
	}

	function createMenuItem(name:String, x:Float, y:Float):FlxSprite
	{
		var menuItem:FlxSprite = new FlxSprite(x, y);
		//Use mainmenu folder if exist
		if (Paths.fileExists('images/mainmenu_1.0/menu_$name' + '.xml', TEXT, false, null, true) || !Paths.fileExists('images/mainmenu/menu_$name' + '.xml', IMAGE, false, null, true)) {
			menuItem.frames = Paths.getSparrowAtlas('mainmenu_1.0/menu_$name');
			menuItem.animation.addByPrefix('idle', '$name idle', 24, true);
			menuItem.animation.addByPrefix('selected', '$name selected', 24, true);
		}
		else {
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_$name');
			menuItem.animation.addByPrefix('idle', '$name basic', 24);
			menuItem.animation.addByPrefix('selected', '$name white', 24);
		}
		menuItem.animation.play('idle');
		menuItem.updateHitbox();

		menuItem.antialiasing = ClientPrefs.data.antialiasing;
		menuItem.scrollFactor.set();
		menuItems.add(menuItem);
		return menuItem;
	}

	var selectedSomethin:Bool = false;

	var timeNotMoving:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

		super.update(elapsed);

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			if (FlxG.mouse.deltaScreenX != 0 && FlxG.mouse.deltaScreenY != 0) //more accurate than FlxG.mouse.justMoved
			{
				FlxG.mouse.visible = true;
				timeNotMoving = 0;

				var selectedItem:FlxSprite;
				switch(curColumn)
				{
					case CENTER:
						selectedItem = menuItems.members[curSelected];
					case LEFT:
						selectedItem = leftItem;
					case RIGHT:
						selectedItem = rightItem;
				}

				if(leftItem != null && FlxG.mouse.overlaps(leftItem))
				{
					if(selectedItem != leftItem)
					{
						curColumn = LEFT;
						changeItem();
					}
				}
				else if(rightItem != null && FlxG.mouse.overlaps(rightItem))
				{
					if(selectedItem != rightItem)
					{
						curColumn = RIGHT;
						changeItem();
					}
				}
				else
				{
					var dist:Float = -1;
					var distItem:Int = -1;
					for (i in 0...optionShit.length)
					{
						var memb:FlxSprite = menuItems.members[i];
						if(FlxG.mouse.overlaps(memb))
						{
							var distance:Float = Math.sqrt(Math.pow(memb.getGraphicMidpoint().x - FlxG.mouse.screenX, 2) + Math.pow(memb.getGraphicMidpoint().y - FlxG.mouse.screenY, 2));
							if (dist < 0 || distance < dist)
							{
								dist = distance;
								distItem = i;
							}
						}
					}

					if(distItem != -1 && curSelected != distItem)
					{
						curColumn = CENTER;
						curSelected = distItem;
						changeItem();
					}
				}
			}
			else
			{
				timeNotMoving += elapsed;
				#if HIDE_CURSOR if(timeNotMoving > 1) FlxG.mouse.visible = false; #end
			}

			switch(curColumn)
			{
				case CENTER:
					if(controls.UI_LEFT_P && leftOption != null)
					{
						curColumn = LEFT;
						changeItem();
					}
					else if(controls.UI_RIGHT_P && rightOption != null)
					{
						curColumn = RIGHT;
						changeItem();
					}

				case LEFT:
					if(controls.UI_RIGHT_P)
					{
						curColumn = CENTER;
						changeItem();
					}

				case RIGHT:
					if(controls.UI_LEFT_P)
					{
						curColumn = CENTER;
						changeItem();
					}
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				#if HIDE_CURSOR FlxG.mouse.visible = false; #end
				FlxG.sound.play(Paths.sound('cancelMenu'));
				CustomSwitchState.switchMenus('Title');
			}

			if (controls.ACCEPT || (FlxG.mouse.overlaps(menuItems, FlxG.camera) && FlxG.mouse.justPressed))
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				if (optionShit[curSelected] != 'donate')
				{
					selectedSomethin = true;
					#if HIDE_CURSOR FlxG.mouse.visible = false; #end

					if (ClientPrefs.data.flashing)
						FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					var item:FlxSprite;
					var option:String;
					switch(curColumn)
					{
						case CENTER:
							option = optionShit[curSelected];
							item = menuItems.members[curSelected];

						case LEFT:
							option = leftOption;
							item = leftItem;

						case RIGHT:
							option = rightOption;
							item = rightItem;
					}

					call("onSelectItem", [option]);
					FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick:FlxFlicker)
					{
						switch (option)
						{
							case 'story_mode':
								CustomSwitchState.switchMenus('StoryMenu');
							case 'freeplay':
								CustomSwitchState.switchMenus('Freeplay');

							#if MODS_ALLOWED
							case 'mods':
								CustomSwitchState.switchMenus('ModsMenu');
							#end

							#if ACHIEVEMENTS_ALLOWED
							case 'achievements':
								CustomSwitchState.switchMenus('AchievementsMenu');
							#end

							case 'credits':
								CustomSwitchState.switchMenus('Credits');
							case 'options':
								CustomSwitchState.switchMenus('Options');
						}
					});

					for (memb in menuItems)
					{
						if(memb == item)
							continue;

						FlxTween.tween(memb, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
					}
				}
				else CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
			}
			else if (FlxG.keys.anyJustPressed(debugKeys) #if TOUCH_CONTROLS || _virtualpad.buttonE.justPressed #end)
			{
				selectedSomethin = true;
				#if HIDE_CURSOR FlxG.mouse.visible = false; #end
				CustomSwitchState.switchMenus('MasterEditor');
			}
			else if (FlxG.keys.justPressed.TAB #if TOUCH_CONTROLS || _virtualpad.buttonSELECTOR.justPressed #end) //use unused button
			{
				#if TOUCH_CONTROLS removeMobilePad(); #end
				persistentUpdate = false;
				openSubState(new funkin.menus.CustomMenuModSwitchMenu());
			}
		}
	}

	function changeItem(change:Int = 0)
	{
		if(change != 0) curColumn = CENTER;
		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		call("onChangeItem", [curSelected]);
		FlxG.sound.play(Paths.sound('scrollMenu'));

		for (item in menuItems)
		{
			item.animation.play('idle');
			item.centerOffsets();
		}

		var selectedItem:FlxSprite;
		switch(curColumn)
		{
			case CENTER:
				selectedItem = menuItems.members[curSelected];
			case LEFT:
				selectedItem = leftItem;
			case RIGHT:
				selectedItem = rightItem;
		}
		selectedItem.animation.play('selected');
		selectedItem.centerOffsets();
		camFollow.y = selectedItem.getGraphicMidpoint().y;
	}

	override function destroy() {
		instance = null;
		super.destroy();
	}
	
	override function closeSubState() {
		persistentUpdate = true;
		#if TOUCH_CONTROLS
		removeVirtualPad();
		addMobilePad("NONE", "SELECTOR_1.0");
		_virtualpad.alpha = 1;
		#end
		super.closeSubState();
	}
}