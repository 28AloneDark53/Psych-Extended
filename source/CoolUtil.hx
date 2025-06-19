package;

import flixel.util.FlxSave;
import flixel.FlxObject;
import flixel.FlxBasic;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end
import haxe.Json;

#if cpp
@:cppFileCode('#include <thread>')
#end
class CoolUtil
{
	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		trace(snap);
		return (m / snap);
	}
	
	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if(FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}
	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function dominantColor(sprite:flixel.FlxSprite):Int{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth){
			for(row in 0...sprite.frameHeight){
			  var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			  if(colorOfThisPixel != 0){
				  if(countByColor.exists(colorOfThisPixel)){
				    countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
				  }else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687)){
					 countByColor[colorOfThisPixel] = 1;
				  }
			  }
			}
		 }
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[flixel.util.FlxColor.BLACK] = 0;
			for(key in countByColor.keys()){
			if(countByColor[key] >= maxCount){
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}
	
	// 0.7x custom menus support
	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	//uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String, ?library:String = null):Void {
		Paths.sound(sound, library);
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void {
		Paths.music(sound, library);
	}

	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}
	
	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			#if linux
			// TO DO: get linux command
			//Sys.command('explorer.exe $folder');
			#else
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);

			Sys.command('explorer.exe $folder');
			trace('explorer.exe $folder');
			#end
		#else
			FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	/** Quick Function to Fix Save Files for Flixel 5
		if you are making a mod, you are gonna wanna change "ShadowMario" to something else
		so Base Psych saves won't conflict with yours
		@BeastlyGabi
	**/
	public static function getSavePath(folder:String = 'KralOyuncu'):String {
		@:privateAccess
		return #if (flixel < "5.0.0") folder #else FlxG.stage.application.meta.get('company')
			+ '/'
			+ FlxSave.validate(FlxG.stage.application.meta.get('file')) #end;
	}
	
	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		switch(border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}
	
	/**
	* Replacement for `FlxG.mouse.overlaps` because it's currently broken when using a camera with a different position or size.
	* It will be fixed eventually by HaxeFlixel v5.4.0.
	* 
	* @param 	objectOrGroup The object or group being tested.
	* @param 	camera Specify which game camera you want. If null getScreenPosition() will just grab the first global camera.
	* @return 	Whether or not the two objects overlap.
	*/
	@:access(flixel.group.FlxTypedGroup.resolveGroup)
	inline public static function mouseOverlaps(objectOrGroup:FlxBasic, ?camera:FlxCamera):Bool
	{
		var result:Bool = false;
 
		final group = FlxTypedGroup.resolveGroup(objectOrGroup);
		if (group != null)
		{
			group.forEachExists(function(basic:FlxBasic)
			{
				if (mouseOverlaps(basic, camera))
				{
					result = true;
					return;
				}
			});
		}
		else
		{
			final point = FlxG.mouse.getWorldPosition(camera, FlxPoint.weak());
			final object:FlxObject = cast objectOrGroup;
			result = object.overlapsPoint(point, true, camera);
		}
 
		return result;
	}
	
	/**
	 *	@author BrightFyre
	 * Gets data for a song
	 * 
	 * Usage: **CoolUtil.getSongData(name, type);**
	 * @param song Song name
	 * @param type Type of parameter **Artist, BPM, or Name**
	 */
	public static function getSongData(song:String, type:String)
	{
		var artistPrefix:String = 'Kawai Sprite';
		var bpm:String = "150";
		var formattedName:String = 'Tutorial';
		var mechStuff:String = 'CONTROLS\n';
		var hasMech:String = "false";

		switch (song)
		{
			// cuphead
			case 'snake-eyes':
				artistPrefix = 'Mike Geno';
				bpm = "221";
				formattedName = 'Snake Eyes';
			case 'technicolor-tussle':
				artistPrefix = 'BLVKAROT';
				bpm = "140";
				formattedName = 'Technicolor Tussle';
				hasMech = "true";
			case 'knockout':
				artistPrefix = 'Orenji Music';
				bpm = "136";
				formattedName = 'Knockout';
				hasMech = "true";

			// sans
			case 'whoopee':
				artistPrefix = 'YingYang48 & Saster';
				bpm = "120";
				formattedName = 'Whoopee';
				hasMech = "true";
			case 'sansational':
				artistPrefix = 'Tenzubushi';
				bpm = "130";
				formattedName = 'sansational';
				hasMech = "true";
			case 'burning-in-hell':
				artistPrefix = 'TheInnuendo & Saster';
				bpm = "170";
				formattedName = 'Burning In Hell';
				hasMech = "true";
			case 'final-stretch':
				artistPrefix = 'Saru';
				bpm = "175";
				formattedName = 'Final Stretch';

			// bendy
			case 'imminent-demise':
				artistPrefix = 'Saru & CDMusic';
				bpm = "100";
				formattedName = 'Imminent Demise';
			case 'terrible-sin':
				artistPrefix = 'CDMusic & Rozebud';
				bpm = "220";
				formattedName = 'Terrible Sin';
				hasMech = "true";
			case 'last-reel':
				artistPrefix = 'Joan Atlas';
				bpm = "180";
				formattedName = 'Last Reel';
				hasMech = "true";
			case 'nightmare-run':
				artistPrefix = 'Orenji Music & Rozebud';
				bpm = "167";
				formattedName = 'Nightmare Run';
				hasMech = "true";

			// bonus
			case 'satanic-funkin':
				artistPrefix = 'TheInnuendo';
				bpm = "180";
				formattedName = 'Satanic Funkin';
				hasMech = "true";
			case 'bad-to-the-bone':
				artistPrefix = 'Yamahearted';
				bpm = "118";
				formattedName = 'Bad To The Bone';
				hasMech = "true";
			case 'bonedoggle':
				artistPrefix = 'Saster';
				bpm = "150";
				formattedName = 'Bonedoggle';
			case 'ritual':
				artistPrefix = 'BBPanzu & Brandxns';
				bpm = "160";
				formattedName = 'Ritual';
				hasMech = "true";
			case 'freaky-machine':
				artistPrefix = 'DAGames & Saster';
				bpm = "130";
				formattedName = 'Freaky Machine';

			// nightmare
			case 'devils-gambit':
				artistPrefix = 'Saru & TheInnuend0';
				bpm = "175";
				formattedName = 'Devils Gambit';
				hasMech = "true";
			case 'bad-time':
				artistPrefix = 'Tenzubushi';
				bpm = "330";
				formattedName = 'Bad Time';
				hasMech = "true";
			case 'despair':
				artistPrefix = 'CDMusic, Joan Atlas & Rozebud';
				bpm = "375";
				formattedName = 'Despair';
				hasMech = "true";

			// secret
			case 'gose' | 'gose-classic':
				artistPrefix = 'CrystalSlime';
				bpm = "100";
				formattedName = 'Gose';
			case 'saness':
				artistPrefix = 'CrystalSlime';
				bpm = "250";
				formattedName = 'Saness';
				hasMech = "true";
		}

		var daReturn:String = 'MOTHERFUCKER';
		switch (type.toLowerCase())
		{
			case "artist":
				daReturn = artistPrefix;
			case "bpm":
				Conductor.bpm = (Std.parseInt(bpm));
				daReturn = bpm;
			case "name":
				daReturn = formattedName;
			case "mech":
				daReturn = mechStuff;
			case "hasmech":
				trace('this song (' + song + ') has mechanics');
				daReturn = hasMech;
		}

		return daReturn;
	}
	
	public static function fpsLerp(v1:Float, v2:Float, ratio:Float)
	{
		return FlxMath.lerp(v1, v2, getFPSRatio(ratio));
	}

	public static function getFPSRatio(ratio:Float)
	{
		return FlxMath.bound(ratio * FlxG.elapsed * 60, 0, 1);
	}
	
	public static function askToGemini(key:String, input:String):String
	{
		var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" + key;

		var jsonData = '{ "contents": [ { "parts": [ { "text": "' + input + '" } ] } ] }';
	
		var command = [
			"curl",
			"-X", "POST",
			"-H", "Content-Type: application/json",
			"-d", jsonData,
			url
		];
	
		var process = new Process(command[0], command.slice(1));
		var output = process.stdout.readAll().toString();
		process.close();

		try
		{
			var response = Json.parse(output);
	
			return response.candidates[0].content.parts[0].text;
		} catch(e:Dynamic) {
			return 'Error: ' + e;
		}
	}
	
	public static function showPopUp(message:String, title:String):Void
	{
		FlxG.stage.window.alert(message, title);
	}

	@:noUsing public static inline function getMacroAbstractClass(className:String) {
		return Type.resolveClass('${className}_HSC');
	}

	#if cpp
	@:functionCode('
		return std::thread::hardware_concurrency();
	')
	#end
	public static function getCPUThreadsCount():Int
	{
		return 1;
	}
}
