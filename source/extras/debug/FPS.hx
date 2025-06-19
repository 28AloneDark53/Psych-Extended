package extras.debug;

/*
	author: beihu235
	bilibili: https://b23.tv/SnqG443
	github: https://github.com/beihu235
	youtube: https://youtube.com/@beihu235?si=NHnWxcUWPS46EqUt
	discord: @beihu235

	thanks Chiny help me adjust data
	github: https://github.com/dmmchh
*/

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class FPS extends Sprite
{
	public function new(x:Float = 10, y:Float = 10)
	{
		super();

		this.x = x;
		this.y = y;

		create();
	}

	public static var fpsShow:FPSCounter;
	public static var extraShow:ExtraCounter;	
	public static var versionShow:VersionCounter;

	public var isHiding = true;

	function create()
	{
		fpsShow = new FPSCounter(10, 10);
		addChild(fpsShow);
		fpsShow.update();

		extraShow = new ExtraCounter(10, 70);
		addChild(extraShow);
		extraShow.update();

		versionShow = new VersionCounter(10, 130);
		addChild(versionShow);

		extraShow.visible = true;
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		if(isPointInFPSCounter() && FlxG.mouse.justPressed){
			isHiding = !isHiding;
			hide();
		}

		DataGet.update();

		if (DataGet.number != 0) return;

		fpsShow.update();
		extraShow.update();
		versionShow.update();
	}

	public function change()
	{
		extraShow.visible = true;
		versionShow.y = 130;
		versionShow.change();
	}

	var helloAlpha1:FlxTween;
	var helloAlpha2:FlxTween;

	function hide():Void
	{
		if(isHiding){
			helloAlpha1 = FlxTween.tween(extraShow, {alpha: 0}, 0.2, {ease: FlxEase.quadOut});
			helloAlpha2 = FlxTween.tween(versionShow, {alpha: 0}, 0.2, {ease: FlxEase.quadOut});
		}else{
			helloAlpha1 = FlxTween.tween(extraShow, {alpha: 1}, 0.2, {ease: FlxEase.quadOut});
			helloAlpha2 = FlxTween.tween(versionShow, {alpha: 1}, 0.2, {ease: FlxEase.quadOut});
		}
	}
	private function isPointInFPSCounter():Bool
	{
		var global = fpsShow.localToGlobal(new openfl.geom.Point(0, 0));
		var fpsX = global.x;
		var fpsY = global.y;
		var fpsWidth = fpsShow.width;
		var fpsHeight = fpsShow.height;

		var mx = Lib.current.stage.mouseX;
		var my = Lib.current.stage.mouseY;

		return mx >= fpsX && mx <= fpsX + fpsWidth
			&& my >= fpsY && my <= fpsY + fpsHeight;
	}
}