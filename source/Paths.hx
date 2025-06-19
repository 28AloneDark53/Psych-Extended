package;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import openfl.geom.Rectangle;
import flixel.math.FlxRect;
import haxe.xml.Access;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;
#if SCRIPTING_ALLOWED
import scripting.HScript.Script;
#end

import openfl.media.Sound;

typedef ModsList = {
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.$SOUND_EXT'];
	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() {
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys()) {
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key)
				&& !dumpExclusions.contains(key)) {
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null) {
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
		#if cpp
		cpp.NativeGc.run(true);
		#elseif hl
		hl.Gc.major();
		#end
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredMemory() {
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		openfl.Assets.cache.clear("songs");
	}

	static public var currentModDirectory:String = '';
	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null, ?modsAllowed:Bool = true):String
	{
		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var customFile:String = file;
			if (library != null)
				customFile = '$library/$file';

			var modded:String = modFolders(customFile);
			if(FileSystem.exists(modded)) return modded;
		}
		#end

		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, 'week_assets', 'week_assets/' + currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}
		}

		return getSharedPath(file);
	}

	static public function getLibraryPath(file:String, library = "shared")
	{
		return if (library == "shared") getSharedPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String, ?level:String)
	{
		if(level == null) level = library;
		var returnPath = '$library:assets/$level/$file';
		return returnPath;
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/shared/$file';
	}

	inline public static function getSharedPath(file:String = '')
	{
		return 'assets/shared/$file';
	}

	inline public static function getScriptPath(file:String = '')
	{
		return 'scripting/$file';
	}

	inline static public function script(key:String, ?library:String, isAssetsPath:Bool = false) {
		#if SCRIPTING_ALLOWED
		var scriptToLoad:String = null;
		for(ex in Script.scriptExtensions) {
			#if MODS_ALLOWED
			scriptToLoad = Paths.menuFolders('scripts/${key}.$ex');
			if(!FileSystem.exists(scriptToLoad))
				scriptToLoad = Paths.getScriptPath('${key}.$ex');
			#else
			scriptToLoad = Paths.getScriptPath('${key}.$ex');
			#end

			if(FileSystem.exists(scriptToLoad))
				break;
		}
		return scriptToLoad;
		#end
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function fragShaderPath(key:String)
	{
		return getPath('shaders/$key.frag');
	}

	inline static public function vertShaderPath(key:String)
	{
		return getPath('shaders/$key.vert');
	}

	inline static public function fragShader(key:String)
	{
		return getTextFromFile('shaders/$key.frag');
	}

	inline static public function vertShader(key:String)
	{
		return getTextFromFile('shaders/$key.vert');
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library); //this is doesn't work, I don't know why
	}
	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library); //this is doesn't work, I don't know why
	}
	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		if (ClientPrefs.data.FreakyMenu == 'Extended' && key == 'freakyMenu' && (Paths.fileExists('music/ExtendedMenu.ogg', SOUND, false, null, true) || !Paths.fileExists('music/freakyMenu.ogg', SOUND, false, null, true)))
			file = returnSound('music', 'ExtendedMenu', library);
		return file;
	}

	static public function voices(song:String, postfix:String = null):Sound
	{
		var diff = Difficulty.getString().toLowerCase();
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if(postfix != null) songKey += '-' + postfix;
		var voices = returnSound(null, songKey, 'songs');

		var songKeyDiff:String = '${formatToSongPath(song)}/${diff}/Voices';
		if(postfix != null) songKeyDiff += '-' + postfix;

		#if ERECT_SONGS
		var Nightmare:String = '${formatToSongPath(song)}/Nightmare/Voices';
		if(postfix != null) Nightmare += '-' + postfix;

		if (songKeyDiff.toLowerCase() == Nightmare.toLowerCase() && (checkSound(null, songKeyDiff, 'songs') == false || returnSound(null, songKeyDiff, 'songs') != null)) {
			songKeyDiff = '${formatToSongPath(song)}/erect/Voices';
			if(postfix != null) songKeyDiff += '-' + postfix;
		}
		#end

		var voicesDiff = returnSound(null, songKeyDiff, 'songs');

		if (checkSound(null, songKeyDiff, 'songs') == true || voicesDiff != null) return voicesDiff;
		else return voices;
	}

	inline static public function inst(song:String):Sound
	{
		var diff = Difficulty.getString().toLowerCase();
		var songKey:String = '${formatToSongPath(song)}/Inst';
		var inst = returnSound(null, songKey, 'songs');

		var songKeyDiff:String = '${formatToSongPath(song)}/${diff}/Inst';

		#if ERECT_SONGS
		var Nightmare:String = '${formatToSongPath(song)}/Nightmare/Inst';
		if (songKeyDiff.toLowerCase() == Nightmare.toLowerCase() && (checkSound(null, songKeyDiff, 'songs') == false || returnSound(null, songKeyDiff, 'songs') != null))
			songKeyDiff = '${formatToSongPath(song)}/erect/Inst';
		#end

		var instDiff = returnSound(null, songKeyDiff, 'songs');

		if (checkSound(null, songKeyDiff, 'songs') == true || instDiff != null) return instDiff;
		else return inst;
	}

	inline static public function image(key:String, ?library:String, ?extraLoad:Bool = false):FlxGraphic
	{
		// streamlined the assets process more
		var returnAsset:FlxGraphic = returnGraphic(key, library, extraLoad);
		return returnAsset;
	}

	static public function cacheBitmap(file:String, ?bitmap:BitmapData = null)
	{
		if(bitmap == null)
		{
			#if MODS_ALLOWED
			if (FileSystem.exists(file))
				bitmap = BitmapData.fromFile(file);
			else #end if (OpenFlAssets.exists(file, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(file);

			if(bitmap == null) return null;
		}

		localTrackedAssets.push(file);
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = false;
		currentTrackedAssets.set(file, newGraphic);
		return newGraphic;
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key)))
			return File.getContent(modFolders(key));

		if (FileSystem.exists(getSharedPath(key)))
			return File.getContent(getSharedPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, 'week_assets', 'week_assets/' + currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}
		}
		#end
		var path:String = getPath(key, TEXT);
		if(OpenFlAssets.exists(path, TEXT)) return Assets.getText(path);
		return null;
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/fonts/$key';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String = null, ?onlyMods:Bool = false)
	{
		#if MODS_ALLOWED
		if(!ignoreMods)
		{
			var modKey:String = key;
			if(library == 'songs') modKey = 'songs/$key';

			for(mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$modKey')))
					return true;
			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
				return true;
		}
		#end

		if (!onlyMods)
			if(OpenFlAssets.exists(getPath(key, type)))
				return true;

		#if MODS_ALLOWED
		if (FileSystem.exists(mods('$key'))) {
			return true;
		}
		#end

		return false;
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder);
		#if MODS_ALLOWED
		var jsonExists:Bool = false;

		var json:String = modsImagesJson(key);
		if(FileSystem.exists(json)) jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (jsonExists ? File.getContent(json) : getPath('images/$key' + '.json', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath('images/$key' + '.json', TEXT, parentFolder));
		#end
	}

	// less optimized but automatic handling
	static public function getAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		if(FileSystem.exists(modsXml(key)) || OpenFlAssets.exists(file('images/$key.xml', library), TEXT))
		#else
		if(OpenFlAssets.exists(file('images/$key.xml', library)))
		#end
		{
			return getSparrowAtlas(key, library);
		}
		return getPackerAtlas(key, library);
	}

	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null):FlxAtlasFrames
	{
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		if(keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), parentFolder);
				if(extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
			}
		}
		return parentFrames;
	}

	//used for scripting
	public static function getFixedMobilePath(originalPath:String):String {
		final curStorageType:String = File.getContent(StorageUtil.rootDir + 'storagetype.txt');
		final packageNameLocal = 'com.kraloyuncu.psychextended' #if debugBuild + '.debug' #end;
		var fixedPath:String = originalPath.replace('/storage/emulated/0/Android/data/' + packageNameLocal + "/", '');

		switch(curStorageType) {
			case "EXTERNAL_MEDIA":
				fixedPath = originalPath.replace('/storage/emulated/0/Android/media/' + lime.app.Application.current.meta.get('packageName') + "/", '');
			case "EXTERNAL_DATA":
				fixedPath = originalPath.replace('/storage/emulated/0/Android/data/' + packageNameLocal + "/", '');
			case "EXTERNAL_OBB":
				fixedPath = originalPath.replace('/storage/emulated/0/Android/obb/' + packageNameLocal + "/", '');
			case "EXTERNAL_ONLINE":
				fixedPath = originalPath.replace('/storage/emulated/0/.PsychOnline/', '');
			case "EXTERNAL":
				fixedPath = originalPath.replace('/storage/emulated/0/.PsychEngine/', '');
			case "EXTERNAL_NF":
				fixedPath = originalPath.replace('/storage/emulated/0/.NF Engine/', '');
			case "EXTERNAL_EX":
				fixedPath = originalPath.replace('/storage/emulated/0/.Psych Extended/', '');
		}

		return fixedPath;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if(FileSystem.exists(xml)) {
			xmlExists = true;
		}

		var getXml = file('images/$key.xml', library);
		if (xmlExists)
			getXml = File.getContent(xml)
		else if(!Paths.fileExists('images/$key.xml', TEXT, false, library))
			getXml = file('$key.xml', library);

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library)), getXml);
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var txtExists:Bool = false;

		var txt:String = modsTxt(key);
		if(FileSystem.exists(txt)) {
			txtExists = true;
		}

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library)), (txtExists ? File.getContent(txt) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;

		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	// completely rewritten asset loading? fuck!
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static function returnGraphic(key:String, ?library:String, ?extraLoad:Bool = false) {
		#if MODS_ALLOWED
		var modKey:String = modsImages(key);
		if (extraLoad)
			modKey = modFolders(key + '.png');
		if(FileSystem.exists(modKey)) {
			if(!currentTrackedAssets.exists(modKey)) {
				var newBitmap:BitmapData = BitmapData.fromFile(modKey);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, modKey);
				newGraphic.persist = true;
				currentTrackedAssets.set(modKey, newGraphic);
			}
			localTrackedAssets.push(modKey);
			return currentTrackedAssets.get(modKey);
		}
		#end

		var path = getPath('images/$key.png', IMAGE, library);
		var normalPath = getPath('$key.png', IMAGE, library);
		//trace(path);
		if (OpenFlAssets.exists(path, IMAGE)) {
			if(!currentTrackedAssets.exists(path)) {
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);
				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}
			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}
		else if (OpenFlAssets.exists(normalPath, IMAGE)) {
			if(!currentTrackedAssets.exists(normalPath)) {
				var newGraphic:FlxGraphic = FlxG.bitmap.add(normalPath, false, normalPath);
				newGraphic.persist = true;
				currentTrackedAssets.set(normalPath, newGraphic);
			}
			localTrackedAssets.push(normalPath);
			return currentTrackedAssets.get(normalPath);
		}
		trace('oh no its returning null NOOOO');
		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(path:Null<String>, key:String, ?library:String) {
		#if MODS_ALLOWED
		var modLibPath:String = '';
		if (library != null) modLibPath = '$library/';
		if (path != null) modLibPath += '$path';

		var file:String = modsSounds(modLibPath, key);
		if(FileSystem.exists(file)) {
			if(!currentTrackedSounds.exists(file))
				currentTrackedSounds.set(file, Sound.fromFile(file));
			localTrackedAssets.push(file);
			return currentTrackedSounds.get(file);
		}
		#end

		// I hate this so god damn much
		var gottenPath:String = '$key.$SOUND_EXT';
		if(path != null) gottenPath = '$path/$gottenPath';
		gottenPath = getPath(gottenPath, SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		if(!currentTrackedSounds.exists(gottenPath))
		{
			var retKey:String = (path != null) ? '$path/$key' : key;
			retKey = ((path == 'songs') ? 'songs:' : '') + getPath('$retKey.$SOUND_EXT', SOUND, library);
			if(OpenFlAssets.exists(retKey, SOUND))
				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(retKey));
		}
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	public static function checkSound(path:Null<String>, key:String, ?library:String) {
		#if MODS_ALLOWED
		var modLibPath:String = '';
		if (library != null) modLibPath = '$library/';
		if (path != null) modLibPath += '$path';

		var file:String = modsSounds(modLibPath, key);
		if(FileSystem.exists(file)) {
			return true;
		}
		#end

		// I hate this so god damn much
		var gottenPath:String = '$key.$SOUND_EXT';
		if(path != null) gottenPath = '$path/$gottenPath';
		gottenPath = getPath(gottenPath, SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		var retKey:String = (path != null) ? '$path/$key' : key;
		retKey = ((path == 'songs') ? 'songs:' : '') + getPath('$retKey.$SOUND_EXT', SOUND, library);
		if(OpenFlAssets.exists(retKey, SOUND)) return true;
		return false;
	}

	static public function getFolderContent(key:String, addPath:Bool = false, source:String = "BOTH"):Array<String> {
		var content:Array<String> = [];
		var folder = key.endsWith('/') ? key : key + '/';

		#if MODS_ALLOWED
		if (source == "MODS" || source == "BOTH") {
			var modDirs:Array<String> = [];
			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
				modDirs.push(Mods.currentModDirectory);
			modDirs = modDirs.concat(Mods.getGlobalMods());

			for (mod in modDirs) {
				var modFolder = Paths.mods('$mod/$folder');
				if (FileSystem.exists(modFolder)) {
					for (file in FileSystem.readDirectory(modFolder)) {
						if (!FileSystem.isDirectory('$modFolder/$file')) {
							var path = addPath ? '$folder$file' : file;
							if (!content.contains(path))
								content.push(path);
						}
					}
				}
			}

			// Check modpack folder if enabled
			if (ClientPrefs.data.Modpack) {
				var modpackFolder = Paths.modpack(folder);
				if (FileSystem.exists(modpackFolder)) {
					for (file in FileSystem.readDirectory(modpackFolder)) {
						if (!FileSystem.isDirectory('$modpackFolder/$file')) {
							var path = addPath ? '$folder$file' : file;
							if (!content.contains(path))
								content.push(path);
						}
					}
				}
			}
		}
		#end

		return content;
	}

	public static function readDirectory(directory:String):Array<String>
	{
		#if MODS_ALLOWED
		return FileSystem.readDirectory(directory);
		#else
		var dirs:Array<String> = [];
		for(dir in Assets.list().filter(folder -> folder.startsWith(directory)))
		{
			@:privateAccess
			for(library in lime.utils.Assets.libraries.keys())
			{
				if(library != 'default' && Assets.exists('$library:$dir') && (!dirs.contains('$library:$dir') || !dirs.contains(dir)))
					dirs.push('$library:$dir');
				else if(Assets.exists(dir) && !dirs.contains(dir))
					dirs.push(dir);
			}
		}
		return dirs;
		#end
	}

	public static function returnSoundString(path:String, key:String, ?library:String)
	{
		var folder:String = '';
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);
		if (FileSystem.exists(file))
		{
			if (!currentTrackedSounds.exists(file))
			{
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			localTrackedAssets.push(key);
			return file;
		}
		#end
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		if (!currentTrackedSounds.exists(gottenPath))
			#if MODS_ALLOWED
			currentTrackedSounds.set(gottenPath, Sound.fromFile(#if !mobile './' + #end gottenPath));
			#else
			{
				if (path == 'songs')
					folder = 'songs:';

				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
			}
			#end
		localTrackedAssets.push(gottenPath);
		#if MODS_ALLOWED
		return #if !mobile './' + #end gottenPath;
		#else
		return folder + getPath('$path/$key.$SOUND_EXT', SOUND, library);
		#end
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '', ?doPathFix:Bool = false) {
		if (doPathFix)
			return if (ClientPrefs.data.Modpack) 'modpack/' + key; else 'mods/' + key;
		else
			return if (ClientPrefs.data.Modpack) Sys.getCwd() + 'modpack/' + key; else Sys.getCwd() + 'mods/' + key;
	}

	inline static public function modsFont(key:String) {
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String) {
		return modFolders('data/' + key + '.json');
	}

	inline static public function modsVideo(key:String) {
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsSounds(path:String, key:String) {
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String) {
		return modFolders('images/' + key + '.png');
	}

	inline static public function modsXml(key:String) {
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String) {
		return modFolders('images/' + key + '.txt');
	}

	inline static public function modsImagesJson(key:String)
		return modFolders('images/' + key + '.json');

	static public function menuFolders(key:String) {
		for(mod in Mods.getSelectedMenuMod()){
			var dat:Array<String> = mod.split("|");
			var fileToCheck:String = mods(dat[0] + '/' + key);
			if(FileSystem.exists(fileToCheck) && dat[1] == "1") {
				return fileToCheck;
			}
		}
		return if (ClientPrefs.data.Modpack) Sys.getCwd() + 'modpack/' + key; else Sys.getCwd() + 'mods/' + key;
	}

	static public function modFolders(key:String) {
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) {
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		for(mod in Mods.getGlobalMods()){
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;

		}
		return if (ClientPrefs.data.Modpack) Sys.getCwd() + 'modpack/' + key; else Sys.getCwd() + 'mods/' + key;
	}

	//for HScript TitleState
	inline static public function modpack(key:String = '') {
		return Sys.getCwd() + 'modpack/' + key;
	}

	static public function modpackFolders(key:String) {
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) {
			var fileToCheck:String = modpack(Mods.currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		for(mod in Mods.getGlobalMods()){
			var fileToCheck:String = modpack(mod + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;

		}
		return Sys.getCwd() + 'modpack/' + key;
	}
	#end
	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;

		if(spriteJson != null)
		{
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}
		if(animationJson != null) 
		{
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}
		// is folder or image path
		if(Std.isOfType(folderOrImg, String))
		{
			var originalPath:String = folderOrImg;
			for (i in 0...10)
			{
				var st:String = '$i';
				if(i == 0) st = '';
				if(!changedAtlasJson)
				{
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if(spriteJson != null)
					{
						//trace('found Sprite Json');
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = Paths.image('$originalPath/spritemap$st');
						break;
					}
				}
				else if(Paths.fileExists('images/$originalPath/spritemap$st.png', IMAGE))
				{
					//trace('found Sprite PNG');
					changedImage = true;
					folderOrImg = Paths.image('$originalPath/spritemap$st');
					break;
				}
			}
			if(!changedImage)
			{
				//trace('Changing folderOrImg to FlxGraphic');
				changedImage = true;
				folderOrImg = Paths.image(originalPath);
			}
			if(!changedAnimJson)
			{
				//trace('found Animation Json');
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}
		//trace(folderOrImg);
		//trace(spriteJson);
		//trace(animationJson);
		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end
}