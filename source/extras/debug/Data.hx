package extras.debug;

class DataGet {
	static public var currentFPS:Float = 0;
	static public var displayedFrameTime:Float;

	static public var memory:Float = 0;
	static public var memType:String = "MB";

	static public var wait:Float = 0;
	static public var number:Float = 0;

	static public function update(){

		wait += FlxG.elapsed * 1000;
		number++;
		if (wait < 50) return;

		/////////////////// →更新

		displayedFrameTime = displayedFrameTime * 0.9 + wait / number * 0.1;
		currentFPS = Math.floor(1000 / displayedFrameTime + 0.5);
		if (currentFPS > ClientPrefs.data.framerate) currentFPS = ClientPrefs.data.framerate;

		/////////////////// →fps计算
		if (FlxG.stage.window.frameRate != ClientPrefs.data.framerate)
				FlxG.stage.window.frameRate = ClientPrefs.data.framerate;

		var mem = FlxMath.roundDecimal(Gc.memInfo64(ClientPrefs.data.memoryType) / 1000000, 1); //转化为MB
		if (Math.abs(mem) < 1000) {
			memory = Math.abs(mem);
			memType = "MB";
		} else {
			memory = Math.ceil(Math.abs(mem / 1024) * 100) / 100;
			memType = "GB";
		}

		/////////////////// →memory计算

		wait = number = 0;
	}

	static public function getMem():Float
	{
		return FlxMath.roundDecimal(Gc.memInfo64(ClientPrefs.data.memoryType) / 1000000, 1); //转化为MB
	}
}

class Display {
	static public function fix(data:Float, isMemory:Bool = false):String
	{
		var returnString:String = '';

		if (data % 1 == 0) 
			if (isMemory && DataGet.memType == 'GB') returnString = Std.string(data) + '.00';
			else returnString = Std.string(data) + '.0';
		else if ((data * 10) % 1 == 0 && isMemory && DataGet.memType == 'GB') returnString = Std.string(data) + '0';
		else returnString = Std.string(data);

		return returnString;
	}
}

class ColorReturn {
	static public function transfer(data:Float, maxData:Float):FlxColor
	{
		var red = 0;
		var green = 0;
		var blue = 126;

		if (data < maxData / 2) {
			red = 255;
			green = Std.int(255 * data / maxData * 2);
		} else {
			red = Std.int(255 * (maxData - data) / maxData * 2);
			green = 255;
		}

		return FlxColor.fromRGB(red, green, blue, 255);
	}
}