package mobile.backend;

import haxe.ds.Map;
import haxe.Json;
import haxe.io.Path;
import openfl.utils.Assets;
import flixel.util.FlxSave;

class MobileData
{
	public static var actionModes:Map<String, MobileButtonsData> = new Map();
	public static var dpadModes:Map<String, MobileButtonsData> = new Map();
	public static var hitboxModes:Map<String, CustomHitboxData> = new Map();

	public static var mode(get, set):Int;
	public static var forcedMode:Null<Int>;
	public static var save:FlxSave;

	public static function init()
	{
		save = new FlxSave();
		save.bind('MobileControls', CoolUtil.getSavePath());

		readDirectory(Paths.getSharedPath('mobile/MobileButton/DPadModes'), dpadModes);
		readDirectory(Paths.getSharedPath('mobile/Hitbox/HitboxModes'), hitboxModes);
		readDirectory(Paths.getSharedPath('mobile/MobileButton/ActionModes'), actionModes);
		#if MODS_ALLOWED
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'mobile/MobileButton/'))
		{
			readDirectory(Path.join([folder, 'DPadModes']), dpadModes);
			readDirectory(Path.join([folder, 'ActionModes']), actionModes);
		}
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'mobile/Hitbox/'))
		{
			readDirectory(Path.join([folder, 'HitboxModes']), hitboxModes);
		}
		#end
	}

	public static function setVirtualPadCustom(virtualPad:MobilePad):Void
	{
		if (save.data.buttons == null)
		{
			save.data.buttons = new Array();
			for (buttons in virtualPad)
				save.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));
		}
		else
		{
			var tempCount:Int = 0;
			for (buttons in virtualPad)
			{
				save.data.buttons[tempCount] = FlxPoint.get(buttons.x, buttons.y);
				tempCount++;
			}
		}

		save.flush();
	}

	public static function getVirtualPadCustom(virtualPad:MobilePad):MobilePad
	{
		var tempCount:Int = 0;

		if (save.data.buttons == null)
			return virtualPad;

		for (buttons in virtualPad)
		{
			if (save.data.buttons[tempCount] != null)
			{
				buttons.x = save.data.buttons[tempCount].x;
				buttons.y = save.data.buttons[tempCount].y;
			}
			tempCount++;
		}

		return virtualPad;
	}
	
	static function readDirectory(folder:String, map:Dynamic)
	{
		folder = folder.contains(':') ? folder.split(':')[1] : folder;

		#if MODS_ALLOWED if (FileSystem.exists(folder)) #end
		for (file in Paths.readDirectory(folder))
		{
			var fileWithNoLib:String = file.contains(':') ? file.split(':')[1] : file;
			if (Path.extension(fileWithNoLib) == 'json')
			{
				file = Path.join([folder, Path.withoutDirectory(file)]);
				var str = #if MODS_ALLOWED File.getContent(file) #else Assets.getText(file) #end;
				var json:MobileButtonsData = cast Json.parse(str);
				var mapKey:String = Path.withoutDirectory(Path.withoutExtension(fileWithNoLib));
				map.set(mapKey, json);
			}
		}
	}

	static function set_mode(mode:Int = 3)
	{
		save.data.mobileControlsMode = mode;
		save.flush();
		return mode;
	}

	static function get_mode():Int
	{
		if (forcedMode != null)
			return forcedMode;

		if (save.data.mobileControlsMode == null)
		{
			save.data.mobileControlsMode = 3;
			save.flush();
		}

		return save.data.mobileControlsMode;
	}
}

typedef MobileButtonsData =
{
	buttons:Array<ButtonsData>
}

typedef CustomHitboxData =
{
	buttons:Array<HitboxData>
}

typedef HitboxData =
{
	button:String, // what Hitbox Button should be used, must be a valid Hitbox Button var from Hitbox as a string.
	//if custom ones isn't setted these will be used
	x:Float, // the button's X position on screen.
	y:Float, // the button's Y position on screen.
	width:Int, // the button's Width on screen.
	height:Int, // the button's Height on screen.
	color:String, // the button color, default color is white.
	//Top
	topX:Null<Float>,
	topY:Null<Float>,
	topWidth:Null<Int>,
	topHeight:Null<Int>,
	//Middle
	middleX:Null<Float>,
	middleY:Null<Float>,
	middleWidth:Null<Int>,
	middleHeight:Null<Int>,
	//Bottom
	bottomX:Null<Float>,
	bottomY:Null<Float>,
	bottomWidth:Null<Int>,
	bottomHeight:Null<Int>
}

typedef ButtonsData =
{
	button:String, // what MobileButton should be used, must be a valid MobileButton var from VirtualPad as a string.
	graphic:String, // the graphic of the button, usually can be located in the VirtualPad xml .
	x:Float, // the button's X position on screen.
	y:Float, // the button's Y position on screen.
	color:String, // the button color, default color is white.
	bg:String // the button background for TouchPad, default background is `bg`.
}