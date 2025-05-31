package mobile.flixel;

import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.Assets;

typedef MobileButton = VirtualButton; // don't judge me for this

//More button support (Some buttons doesn't have a texture)
@:build(mobile.flixel.MobileMacro.createVPadButtons(["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]))
@:build(mobile.flixel.MobileMacro.createExtraVPadButtons(30)) //Psych Extended Allows to Create 30 Extra Button with Json for now
class FlxVirtualPad extends FlxSpriteGroup {
	//DPad
	public var buttonLeft:MobileButton = new MobileButton(0, 0);
	public var buttonUp:MobileButton = new MobileButton(0, 0);
	public var buttonRight:MobileButton = new MobileButton(0, 0);
	public var buttonDown:MobileButton = new MobileButton(0, 0);

	//PAD DUO MODE
	public var buttonLeft2:MobileButton = new MobileButton(0, 0);
	public var buttonUp2:MobileButton = new MobileButton(0, 0);
	public var buttonRight2:MobileButton = new MobileButton(0, 0);
	public var buttonDown2:MobileButton = new MobileButton(0, 0);

	public var buttonCEUp:MobileButton = new MobileButton(0, 0);
	public var buttonCEDown:MobileButton = new MobileButton(0, 0);
	public var buttonCEG:MobileButton = new MobileButton(0, 0);
	
	public var dPad:FlxSpriteGroup;
	public var actions:FlxSpriteGroup;
	
	/**
	 * Create a gamepad.
	 *
	 * @param   DPadMode     The D-Pad mode. `LEFT_FULL` for example.
	 * @param   ActionMode   The action buttons mode. `A_B_C` for example.
	 */

	public function new(DPad:String, Action:String, ?Sizeable:Bool = false, ?ExtraSizeable:Bool = false) {
		super();
		
		dPad = new FlxSpriteGroup();
		dPad.scrollFactor.set();

		actions = new FlxSpriteGroup();
		actions.scrollFactor.set();
		
		if (DPad != "NONE")
		{
			if (!MobileData.dpadModes.exists(DPad))
				throw 'The virtualPad dpadMode "$DPad" doesn\'t exists.';

			for (buttonData in MobileData.dpadModes.get(DPad).buttons)
			{
				Reflect.setField(this, buttonData.button,
					createMobileButton(buttonData.x, buttonData.y, buttonData.graphic, CoolUtil.colorFromString(buttonData.color), Sizeable));
				dPad.add(add(Reflect.field(this, buttonData.button)));
			}
		}

		if (Action != "NONE" && Action != "controlExtend")
		{
			if (!MobileData.actionModes.exists(Action))
				throw 'The virtualPad actionMode "$Action" doesn\'t exists.';

			for (buttonData in MobileData.actionModes.get(Action).buttons)
			{
				Reflect.setField(this, buttonData.button,
					createMobileButton(buttonData.x, buttonData.y, buttonData.graphic, CoolUtil.colorFromString(buttonData.color)));
				actions.add(add(Reflect.field(this, buttonData.button)));
			}
		}

		switch (Action){			
			case "controlExtend":
			    if (Type.getClass(FlxG.state) != PlayState || Type.getClass(FlxG.state) == PlayState && ClientPrefs.data.extraKeys >= 1) actions.add(add(buttonExtra1 = createMobileButton(FlxG.width * 0.5 - 44 * 3, FlxG.height * 0.5 - 127 * 0.5, "f", 0xFF0000, false, ExtraSizeable)));
				if (Type.getClass(FlxG.state) != PlayState || Type.getClass(FlxG.state) == PlayState && ClientPrefs.data.extraKeys >= 2) actions.add(add(buttonExtra2 = createMobileButton(FlxG.width * 0.5, FlxG.height * 0.5 - 127 * 0.5, "g", 0xFFFF00, false, ExtraSizeable)));
				if (Type.getClass(FlxG.state) != PlayState || Type.getClass(FlxG.state) == PlayState && ClientPrefs.data.extraKeys >= 3) actions.add(add(buttonExtra3 = createMobileButton(FlxG.width * 0.5, FlxG.height * 0.5 - 127 * 0.5, "x", 0x99062D, false, ExtraSizeable)));
				if (Type.getClass(FlxG.state) != PlayState || Type.getClass(FlxG.state) == PlayState && ClientPrefs.data.extraKeys >= 4) actions.add(add(buttonExtra4 = createMobileButton(FlxG.width * 0.5, FlxG.height * 0.5 - 127 * 0.5, "y", 0x4A35B9, false, ExtraSizeable)));
			case "NONE":
		}
	}
	
	public function createMobileButton(x:Float, y:Float, Frames:String, ColorS:Int, ?Sizeable:Bool = false, ?ExtraSizeable:Bool = false):Dynamic
	{
	    if (ClientPrefs.data.virtualpadTexture == 'TouchPad')
	        return createTouchButton(x, y, Frames, ColorS, Sizeable, ExtraSizeable);
	    else
	        return createVirtualButton(x, y, Frames, ColorS, Sizeable, ExtraSizeable);
	}
	
	public function createTouchButton(x:Float, y:Float, Frames:String, ?ColorS:Int = 0xFFFFFF, ?Sizeable = false, ?ExtraSizeable:Bool = false):VirtualButton {
	    var button = new VirtualButton(x, y);
		button.label = new FlxSprite();
		final buttonPath:Dynamic = Paths.image('touchpad/' + ClientPrefs.data.VirtualPadSkin + '/${Frames.toUpperCase()}');
		final bgPath:Dynamic = Paths.image('touchpad/' + ClientPrefs.data.VirtualPadSkin + '/bg');
			
		if (Frames == "modding" && FileSystem.exists(buttonPath)) button.loadGraphic(buttonPath);
		if (Frames == "modding" && !FileSystem.exists(buttonPath)) button.loadGraphic(Paths.image('touchpad/original/${Frames.toUpperCase()}'));
		else if (FileSystem.exists(bgPath)) button.loadGraphic(bgPath);
		else button.loadGraphic(Paths.image('touchpad/original/bg'));
		
		if (Frames != "modding" && FileSystem.exists(buttonPath)) button.label.loadGraphic(buttonPath);
		else if (Frames != "modding" && !FileSystem.exists(buttonPath)) button.label.loadGraphic(Paths.image('touchpad/original/${Frames.toUpperCase()}'));

		if (Sizeable) button.scale.set(0.243 * ClientPrefs.data.vpadsize, 0.243 * ClientPrefs.data.vpadsize);
		else if (ExtraSizeable) button.scale.set(0.243 * ClientPrefs.data.extravpadsize, 0.243 * ClientPrefs.data.extravpadsize);
		else button.scale.set(0.243, 0.243);
		button.updateHitbox();
		button.updateLabelPosition();

		button.statusBrightness = [1, 0.8, 0.4];
		button.statusIndicatorType = BRIGHTNESS;
		button.indicateStatus();

		button.bounds.makeGraphic(Std.int(button.width - 50), Std.int(button.height - 50), FlxColor.TRANSPARENT);
		button.centerBounds();

		button.immovable = true;
		button.solid = button.moves = false;
		button.label.antialiasing = button.antialiasing = ClientPrefs.data.antialiasing;
		button.tag = Frames.toUpperCase();
		if (ColorS != -1 && ClientPrefs.data.coloredvpad) button.color = ColorS;
		button.parentAlpha = button.alpha;

		return button;
	}
	
	public function createVirtualButton(x:Float, y:Float, Frames:String, ?ColorS:Int = 0xFFFFFF, ?Sizeable = false, ?ExtraSizeable:Bool = false):VirtualButton {
	    var frames:FlxGraphic;
	    
        final path:String = 'shared:assets/shared/images/virtualpad/' + ClientPrefs.data.VirtualPadSkin + '/$Frames.png';
		#if MODS_ALLOWED
		final modsPath:String = Paths.modsImages('virtualpad/' + ClientPrefs.data.VirtualPadSkin + '/$Frames');
		if(sys.FileSystem.exists(modsPath))
			frames = FlxGraphic.fromBitmapData(BitmapData.fromFile(modsPath));
		else #end if(Assets.exists(path))
			frames = FlxGraphic.fromBitmapData(Assets.getBitmapData(path));
		else
			frames = FlxGraphic.fromBitmapData(Assets.getBitmapData('shared:assets/shared/images/virtualpad/original/default.png'));
			
		var button = new VirtualButton(x, y);
        button.frames = FlxTileFrames.fromGraphic(frames, FlxPoint.get(Std.int(frames.width / 2), frames.height));
        
        //button.scale.set(0.243, 0.243);
        if (Sizeable) button.scale.set(button.scale.x * ClientPrefs.data.vpadsize, button.scale.y * ClientPrefs.data.vpadsize); //Pls Work
        if (ExtraSizeable) button.scale.set(button.scale.x * ClientPrefs.data.extravpadsize, button.scale.y * ClientPrefs.data.extravpadsize); //Pls Work
        button.updateHitbox();
        button.updateLabelPosition();
    
        button.bounds.makeGraphic(Std.int(button.width - 50), Std.int(button.height - 50), FlxColor.TRANSPARENT);
        button.centerBounds();
    
        button.immovable = true;
        button.solid = button.moves = false;
        button.antialiasing = ClientPrefs.data.antialiasing;
        button.tag = Frames.toUpperCase();
    
        if (ColorS != -1 && ClientPrefs.data.coloredvpad) button.color = ColorS;
        //button.parentAlpha = button.alpha;
    
        return button;
    }
	
	override public function destroy():Void
	{
		super.destroy();
		for (field in Reflect.fields(this))
			if (Std.isOfType(Reflect.field(this, field), MobileButton))
				Reflect.setField(this, field, FlxDestroyUtil.destroy(Reflect.field(this, field)));
	}
}