package mobile.backend;

import lime.system.System as LimeSystem;
import haxe.io.Path;
import haxe.Exception;
#if android
import android.Tools;
import android.callback.CallBack;
#end

/**
 * A storage class for mobile.
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class StorageUtil
{
	#if sys
	// root directory, used for handling the saved storage type and path
	public static final rootDir:String = LimeSystem.applicationStorageDirectory;

	public static function getStorageDirectory(?force:Bool = false):String
	{
		var daPath:String = '';
		#if android
		if (!FileSystem.exists(rootDir + 'storagetype.txt'))
			File.saveContent(rootDir + 'storagetype.txt', ClientPrefs.data.storageType);
		var curStorageType:String = File.getContent(rootDir + 'storagetype.txt');
		daPath = force ? StorageType.fromStrForce(curStorageType) : StorageType.fromStr(curStorageType);
		daPath = Path.addTrailingSlash(daPath);
		#elseif ios
		daPath = LimeSystem.documentsDirectory;
		#else
		daPath = Sys.getCwd();
		#end

		return daPath;
	}

	public static function createDirectories(directory:String):Void
	{
		try
		{
			if (FileSystem.exists(directory) && FileSystem.isDirectory(directory))
				return;
		}
		catch (e:haxe.Exception)
		{
			trace('Something went wrong while looking at directory. (${e.message})');
		}

		var total:String = '';
		if (directory.substr(0, 1) == '/')
			total = '/';

		var parts:Array<String> = directory.split('/');
		if (parts.length > 0 && parts[0].indexOf(':') > -1)
			parts.shift();

		for (part in parts)
		{
			if (part != '.' && part != '')
			{
				if (total != '' && total != '/')
					total += '/';

				total += part;

				try
				{
					if (!FileSystem.exists(total))
						FileSystem.createDirectory(total);
				}
				catch (e:Exception)
					trace('Error while creating directory. (${e.message}');
			}
		}
	}

    #if !FILE_DIALOG_FOR_MOBILE
	public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):Void
	{
		try
		{
			if (!FileSystem.exists('saves'))
				FileSystem.createDirectory('saves');

			File.saveContent('saves/$fileName', fileData);
			if (alert)
				CoolUtil.showPopUp('$fileName has been saved.', "Success!");
		}
		catch (e:Exception)
			if (alert)
				CoolUtil.showPopUp('$fileName couldn\'t be saved.\n(${e.message})', "Error!")
			else
				trace('$fileName couldn\'t be saved. (${e.message})');
	}
	#end

	#if android
	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions(['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO', 'READ_MEDIA_VISUAL_USER_SELECTED']);
		else
			AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);

		if (!AndroidEnvironment.isExternalStorageManager())
		{
			if (AndroidVersion.SDK_INT >= AndroidVersionCode.S)
				AndroidSettings.requestSetting('REQUEST_MANAGE_MEDIA');
			AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
		}

		if ((AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU
			&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_MEDIA_IMAGES'))
			|| (AndroidVersion.SDK_INT < AndroidVersionCode.TIRAMISU
				&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')))
			CoolUtil.showPopUp('If you accepted the permissions you are all good!' + '\nIf you didn\'t then expect a crash' + '\nPress OK to see what happens',
				'Notice!');

		try
		{
			if (!FileSystem.exists(StorageUtil.getStorageDirectory()))
				createDirectories(StorageUtil.getStorageDirectory());
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp('Please create directory to\n' + StorageUtil.getStorageDirectory(true) + '\nPress OK to close the game', 'Error!');
			LimeSystem.exit(1);
		}
	}

	public static function checkExternalPaths(?splitStorage = false):Array<String>
	{
		var process = new Process('grep -o "/storage/....-...." /proc/mounts | paste -sd \',\'');
		var paths:String = process.stdout.readAll().toString();
		if (splitStorage)
			paths = paths.replace('/storage/', '');
		return paths.split(',');
	}

	public static function getExternalDirectory(externalDir:String):String
	{
		var daPath:String = '';
		for (path in checkExternalPaths())
			if (path.contains(externalDir))
				daPath = path;

		daPath = haxe.io.Path.addTrailingSlash(daPath.endsWith("\n") ? daPath.substr(0, daPath.length - 1) : daPath);
		return daPath;
	}
	#end
	#end
}

#if android
@:runtimeValue
enum abstract StorageType(String) from String to String
{
    final forcedPath = '/storage/emulated/0/';
	final packageNameLocal = 'com.kraloyuncu.psychextended' #if debugBuild + '.debug' #end;
	final fileLocalONLINE = 'PsychOnline';
	final fileLocal = 'PsychEngine';
	final fileLocalNF = 'NF Engine';
	final fileLocalEX = 'Psych Extended'; //idk why

	var EXTERNAL_DATA = "EXTERNAL_DATA";
	var EXTERNAL_OBB = "EXTERNAL_OBB";
	var EXTERNAL_MEDIA = "EXTERNAL_MEDIA";
	var EXTERNAL = "EXTERNAL";
	var EXTERNAL_ONLINE = "EXTERNAL_ONLINE";
	var EXTERNAL_NF = "EXTERNAL_NF";
	var EXTERNAL_EX = "EXTERNAL_EX";
	var EXTERNAL_PE = "EXTERNAL_PE";

	public static function fromStr(str:String):StorageType
	{
		final EXTERNAL_DATA = AndroidContext.getExternalFilesDir();
		final EXTERNAL_OBB = AndroidContext.getObbDir();
		final EXTERNAL_MEDIA = AndroidEnvironment.getExternalStorageDirectory() + '/Android/media/' + lime.app.Application.current.meta.get('packageName');
		final EXTERNAL = AndroidEnvironment.getExternalStorageDirectory() + '/.' + fileLocal;
		final EXTERNAL_NF = AndroidEnvironment.getExternalStorageDirectory() + '/.' + fileLocalNF;
		final EXTERNAL_EX = AndroidEnvironment.getExternalStorageDirectory() + '/.' + lime.app.Application.current.meta.get('file');
		final EXTERNAL_ONLINE = AndroidEnvironment.getExternalStorageDirectory() + '/.' + fileLocalONLINE;

		return switch (str)
		{
			case "EXTERNAL_DATA": EXTERNAL_DATA;
			case "EXTERNAL_OBB": EXTERNAL_OBB;
			case "EXTERNAL_MEDIA": EXTERNAL_MEDIA;
			case "EXTERNAL": EXTERNAL;
			case "EXTERNAL_NF": EXTERNAL_NF;
			case "EXTERNAL_EX": EXTERNAL_EX;
			case "EXTERNAL_ONLINE": EXTERNAL_ONLINE;
			default: StorageUtil.getExternalDirectory(str) + '.' + fileLocal;
		}
	}

	public static function fromStrForce(str:String):StorageType
	{
		final EXTERNAL_DATA = forcedPath + 'Android/data/' + packageNameLocal + '/files';
		final EXTERNAL_OBB = forcedPath + 'Android/obb/' + packageNameLocal;
		final EXTERNAL_MEDIA = forcedPath + 'Android/media/' + packageNameLocal;
		final EXTERNAL_ONLINE = forcedPath + '.' + fileLocalONLINE;
		final EXTERNAL = forcedPath + '.' + fileLocal;
		final EXTERNAL_NF = forcedPath + '.' + fileLocalNF;
		final EXTERNAL_EX = forcedPath + '.' + fileLocalEX;

		return switch (str)
		{
			
			case "EXTERNAL_DATA": EXTERNAL_DATA;
			case "EXTERNAL_OBB": EXTERNAL_OBB;
			case "EXTERNAL_MEDIA": EXTERNAL_MEDIA;
			case "EXTERNAL": EXTERNAL;
			case "EXTERNAL_NF": EXTERNAL_NF;
			case "EXTERNAL_EX": EXTERNAL_EX;
			case "EXTERNAL_ONLINE": EXTERNAL_ONLINE;
			default: StorageUtil.getExternalDirectory(str) + '.' + fileLocal;
		}
	}
}
#end