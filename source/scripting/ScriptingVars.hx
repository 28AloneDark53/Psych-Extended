package scripting;


import flixel.input.keyboard.FlxKey;

class ScriptingVars
{
	public static var currentScriptableState:String = null;
	public static var inPlayState:Bool = false;
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var developerMode:Bool = true;

	public static var isConsoleVisible:Bool = false;

	public static var engineVersion:String = '';
	public static var onlineVersion:String = '';
	public static var outdated:Bool = false;

	public static var globalVars:StringMap<Dynamic> = new StringMap<Dynamic>();

	public static var staticVariables:Map<String, Dynamic> = [];
}