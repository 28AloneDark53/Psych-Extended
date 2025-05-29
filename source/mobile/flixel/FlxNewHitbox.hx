package mobile.flixel;

//new
import flixel.graphics.FlxGraphic;
//old
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;

/**
 * A zone with 4 hint's (A hitbox).
 * It's really easy to customize the layout.
 *
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class FlxNewHitbox extends FlxSpriteGroup
{
	public var buttonLeft:VirtualButton = new VirtualButton(0, 0);
	public var buttonDown:VirtualButton = new VirtualButton(0, 0);
	public var buttonUp:VirtualButton = new VirtualButton(0, 0);
	public var buttonRight:VirtualButton = new VirtualButton(0, 0);
	
	public var buttonExtra1:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra2:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra3:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra4:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra5:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra6:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra7:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra8:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra9:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra10:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra11:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra12:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra13:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra14:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra15:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra16:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra17:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra18:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra19:VirtualButton = new VirtualButton(0, 0);
	public var buttonExtra20:VirtualButton = new VirtualButton(0, 0);
	public static var hitbox_hint:FlxSprite;

	/**
	 * Create the zone.
	 */
	public function new(?MobileCType:Float = -1):Void
	{
		super();
		if (ClientPrefs.data.hitboxmode != 'New' && ClientPrefs.data.hitboxmode != 'Classic'){
			if (!MobileData.hitboxModes.exists(ClientPrefs.data.hitboxmode))
				throw 'The Custom Hitbox File doesn\'t exists.';

			for (buttonData in MobileData.hitboxModes.get(ClientPrefs.data.hitboxmode).buttons)
			{
				Reflect.setField(this, buttonData.button,
					createHint(buttonData.x, buttonData.y, buttonData.width, buttonData.height, CoolUtil.colorFromString(buttonData.color)));
				add(Reflect.field(this, buttonData.button));
			}
		}
		else if (ClientPrefs.data.extraKeys == 0 && MobileCType == -1 || MobileCType == 0){
			add(buttonLeft = createHint(0, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 1), 0xFFC24B99));
			add(buttonDown = createHint(FlxG.width / 4, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 1), 0xFF00FFFF));
			add(buttonUp = createHint(FlxG.width / 2, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 1), 0xFF12FA05));
			add(buttonRight = createHint((FlxG.width / 2) + (FlxG.width / 4), 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 1), 0xFFF9393F));
			if (ClientPrefs.data.hitboxhint){
				hitbox_hint = new FlxSprite(0, 0).loadGraphic(Paths.image('mobilecontrols/hitbox/hitbox_hint'));
				add(hitbox_hint);
			}
		}else {
			if (ClientPrefs.data.hitboxLocation == 'Bottom') {
				add(buttonLeft = createHint(0, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFFC24B99));
				add(buttonDown = createHint(FlxG.width / 4, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFF00FFFF));
				add(buttonUp = createHint(FlxG.width / 2, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFF12FA05));
				add(buttonRight = createHint((FlxG.width / 2) + (FlxG.width / 4), 0, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFFF9393F));
				if (ClientPrefs.data.hitboxhint){
					hitbox_hint = new FlxSprite(0, -150).loadGraphic(Paths.image('mobilecontrols/hitbox/hitbox_hint'));
					add(hitbox_hint);
				}

				var customKeys = ClientPrefs.data.extraKeys;
				if (MobileCType != -1) customKeys = Std.int(MobileCType);
				if (MobileCType == 1.1)
					add(buttonExtra1 = createHint(0, (FlxG.height / 5) * 4, FlxG.width, Std.int(FlxG.height / 5), 0xFF0000));
				switch (customKeys) {
					case 1:
						add(buttonExtra1 = createHint(0, (FlxG.height / 5) * 4, FlxG.width, Std.int(FlxG.height / 5), 0xFFFF00));
					case 2:
						add(buttonExtra1 = createHint(0, (FlxG.height / 5) * 4, Std.int(FlxG.width / 2), Std.int(FlxG.height / 5), 0xFF0000));
						add(buttonExtra2 = createHint(FlxG.width / 2, (FlxG.height / 5) * 4, Std.int(FlxG.width / 2), Std.int(FlxG.height / 5), 0xFFFF00));
					case 3:
						add(buttonExtra1 = createHint(0, (FlxG.height / 5) * 4, Std.int(FlxG.width / 3), Std.int(FlxG.height / 5), 0xFF0000));
						add(buttonExtra2 = createHint(FlxG.width / 3 - 1, (FlxG.height / 5) * 4, Std.int(FlxG.width / 3 + 2), Std.int(FlxG.height / 5), 0xFFFF00));
						add(buttonExtra3 = createHint(FlxG.width / 3 * 2, (FlxG.height / 5) * 4, Std.int(FlxG.width / 3), Std.int(FlxG.height / 5), 0x0000FF));
					case 4:
						add(buttonExtra1 = createHint(0, (FlxG.height / 5) * 4, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0xFF0000));
						add(buttonExtra2 = createHint(FlxG.width / 4, (FlxG.height / 5) * 4, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0xFFFF00));
						add(buttonExtra3 = createHint(FlxG.width / 4 * 2, (FlxG.height / 5) * 4, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0x0000FF));
						add(buttonExtra4 = createHint(FlxG.width / 4 * 3, (FlxG.height / 5) * 4, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0x00FF00));
				}
			}else if (ClientPrefs.data.hitboxLocation == 'Top'){// Top
				add(buttonLeft = createHint(0, (FlxG.height / 5) * 1, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFFC24B99));
				add(buttonDown = createHint(FlxG.width / 4, (FlxG.height / 5) * 1, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFF00FFFF));
				add(buttonUp = createHint(FlxG.width / 2, (FlxG.height / 5) * 1, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFF12FA05));
				add(buttonRight = createHint((FlxG.width / 2) + (FlxG.width / 4), (FlxG.height / 5) * 1, Std.int(FlxG.width / 4), Std.int(FlxG.height * 0.8), 0xFFF9393F));
				if (ClientPrefs.data.hitboxhint){
					hitbox_hint = new FlxSprite(0, 0).loadGraphic(Paths.image('mobilecontrols/hitbox/hitbox_hint'));
					add(hitbox_hint);
				}

				var customKeys = ClientPrefs.data.extraKeys;
				if (MobileCType != -1) customKeys = Std.int(MobileCType);
				if (MobileCType == 1.1)
					add(buttonExtra1 = createHint(0, 0, FlxG.width, Std.int(FlxG.height / 5), 0xFF0000));
				switch (customKeys) {
					case 1:
						add(buttonExtra1 = createHint(0, 0, FlxG.width, Std.int(FlxG.height / 5), 0xFFFF00));
					case 2:
						add(buttonExtra1 = createHint(0, 0, Std.int(FlxG.width / 2), Std.int(FlxG.height / 5), 0xFF0000));
						add(buttonExtra2 = createHint(FlxG.width / 2, 0, Std.int(FlxG.width / 2), Std.int(FlxG.height / 5), 0xFFFF00));
					case 3:
						add(buttonExtra1 = createHint(0, 0, Std.int(FlxG.width / 3), Std.int(FlxG.height / 5), 0xFF0000));
						add(buttonExtra2 = createHint(FlxG.width / 3, 0, Std.int(FlxG.width / 3), Std.int(FlxG.height / 5), 0xFFFF00));
						add(buttonExtra3 = createHint(FlxG.width / 3 * 2, 0, Std.int(FlxG.width / 3), Std.int(FlxG.height / 5), 0x0000FF));
					case 4:
						add(buttonExtra1 = createHint(0, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0xFF0000));
						add(buttonExtra2 = createHint(FlxG.width / 4, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0xFFFF00));
						add(buttonExtra3 = createHint(FlxG.width / 4 * 2, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0x0000FF));
						add(buttonExtra4 = createHint(FlxG.width / 4 * 3, 0, Std.int(FlxG.width / 4), Std.int(FlxG.height / 5), 0x00FF00));
				}
			}else{ //middle
				add(buttonLeft = createHint(0, 0, Std.int(FlxG.width / 5), Std.int(FlxG.height * 1), 0xFF00FF));
				add(buttonDown = createHint(FlxG.width / 5 * 1, 0, Std.int(FlxG.width / 5), Std.int(FlxG.height * 1), 0x00FFFF));
				add(buttonUp = createHint(FlxG.width / 5 * 3, 0, Std.int(FlxG.width / 5), Std.int(FlxG.height * 1), 0x00FF00));
				add(buttonRight = createHint(FlxG.width / 5 * 4 , 0, Std.int(FlxG.width / 5), Std.int(FlxG.height * 1), 0xFF0000));
				if (ClientPrefs.data.hitboxhint){
					hitbox_hint = new FlxSprite(0, 0).loadGraphic(Paths.image('mobilecontrols/hitbox/hitbox_hint'));
					add(hitbox_hint);
				}

				var customKeys = ClientPrefs.data.extraKeys;
				if (MobileCType != -1) customKeys = Std.int(MobileCType);
				if (MobileCType == 1.1)
					add(buttonExtra1 = createHint(FlxG.width / 5 * 2, 0, Std.int(FlxG.width / 5), Std.int(FlxG.height * 1), 0xFF0000));
				switch (customKeys) {
					case 1:
						add(buttonExtra1 = createHint(FlxG.width / 5 * 2, 0, Std.int(FlxG.width / 5), Std.int(FlxG.height * 1), 0xFFFF00));
					case 2:
						add(buttonExtra1 = createHint(FlxG.width / 5 * 2, 0, Std.int(FlxG.width / 5), Std.int(FlxG.height * 0.5), 0xFF0000));
						add(buttonExtra2 = createHint(FlxG.width / 5 * 2, FlxG.height / 2, Std.int(FlxG.width / 5), Std.int(FlxG.height * 0.5), 0xFFFF00));
					case 3:
						add(buttonExtra1 = createHint(FlxG.width / 5 * 2, 0, Std.int(FlxG.width / 5), Std.int(FlxG.height / 3), 0xFF0000));
						add(buttonExtra2 = createHint(FlxG.width / 5 * 2, FlxG.height / 3, Std.int(FlxG.width / 5), Std.int(FlxG.height / 3), 0xFFFF00));
						add(buttonExtra3 = createHint(FlxG.width / 5 * 2, FlxG.height / 3 * 2, Std.int(FlxG.width / 5), Std.int(FlxG.height / 3), 0x0000FF));
					case 4:
						add(buttonExtra1 = createHint(FlxG.width / 5 * 2, 0, Std.int(FlxG.width / 5), Std.int(FlxG.height * 0.25), 0xFF0000));
						add(buttonExtra2 = createHint(FlxG.width / 5 * 2, FlxG.height / 4, Std.int(FlxG.width / 5), Std.int(FlxG.height * 0.25), 0xFFFF00));
						add(buttonExtra3 = createHint(FlxG.width / 5 * 2, FlxG.height / 4 * 2, Std.int(FlxG.width / 5), Std.int(FlxG.height * 0.25), 0x0000FF));
						add(buttonExtra4 = createHint(FlxG.width / 5 * 2, FlxG.height / 4 * 3, Std.int(FlxG.width / 5), Std.int(FlxG.height * 0.25), 0x00FF00));
				}
			}
		}
		scrollFactor.set();
	}

	/**
	 * Clean up memory.
	 */
	override function destroy():Void
	{
		super.destroy();

		buttonLeft = null;
		buttonDown = null;
		buttonUp = null;
		buttonRight = null;
		
		buttonExtra1 = null;
		buttonExtra2 = null;
		buttonExtra3 = null;
		buttonExtra4 = null;
		
		for (field in Reflect.fields(this))
			if (Std.isOfType(Reflect.field(this, field), MobileButton))
				Reflect.setField(this, field, FlxDestroyUtil.destroy(Reflect.field(this, field)));
	}

	private function createHintGraphic(Width:Int, Height:Int, Color:Int = 0xFFFFFF):BitmapData
	{
		var guh:Float = ClientPrefs.data.hitboxalpha;
		var shape:Shape = new Shape();
		shape.graphics.beginFill(Color);
		if (ClientPrefs.data.hitboxtype == "No Gradient")
		{
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(Width, Height, 0, 0, 0);

			shape.graphics.beginGradientFill(RADIAL, [Color, Color], [0, guh], [60, 255], matrix, PAD, RGB, 0);
			shape.graphics.drawRect(0, 0, Width, Height);
			shape.graphics.endFill();
		}
		else if (ClientPrefs.data.hitboxtype == "No Gradient (Old)")
		{
			shape.graphics.lineStyle(10, Color, 1);
			shape.graphics.drawRect(0, 0, Width, Height);
			shape.graphics.endFill();
		}
		else if (ClientPrefs.data.hitboxtype == "Gradient")
		{
			shape.graphics.lineStyle(3, Color, 1);
			shape.graphics.drawRect(0, 0, Width, Height);
			shape.graphics.lineStyle(0, 0, 0);
			shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
			shape.graphics.endFill();
			shape.graphics.beginGradientFill(RADIAL, [Color, FlxColor.TRANSPARENT], [guh, 0], [0, 255], null, null, null, 0.5);
			shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
			shape.graphics.endFill();
		}
		
		/*
		shape.graphics.lineStyle(10, Color, 1);
		shape.graphics.drawRect(0, 0, Width, Height);
		shape.graphics.endFill();
		*/

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}

	private function createHint(X:Float, Y:Float, Width:Int, Height:Int, Color:Int = 0xFFFFFF):VirtualButton
	{
		var hint:VirtualButton = new VirtualButton(X, Y);
		hint.loadGraphic(createHintGraphic(Width, Height, Color));
		hint.solid = false;
		hint.immovable = true;
		hint.scrollFactor.set();
		hint.alpha = 0.00001;
		hint.onDown.callback = hint.onOver.callback = function()
		{
			if (hint.alpha != ClientPrefs.data.hitboxalpha)
				hint.alpha = ClientPrefs.data.hitboxalpha;
		}
		hint.onUp.callback = hint.onOut.callback = function()
		{
			if (hint.alpha != 0.00001)
				hint.alpha = 0.00001;
		}
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}
}
