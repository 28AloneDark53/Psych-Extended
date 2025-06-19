package mobile.objects;

import flixel.util.FlxSave;

class Config {
	var save:FlxSave;
	var isExtend:Bool = false;

	public function new(saveName:String) {
		save = new FlxSave();
		save.bind(saveName);

		if (saveName == 'saved-extendControls') isExtend = true;
	}

	public function getcontrolmode():Int {
		if (save.data.buttonsmode != null) 
			return save.data.buttonsmode[0];
		return 0;
	}

	public function setcontrolmode(mode:Int = 0):Int {
		if (save.data.buttonsmode == null) save.data.buttonsmode = new Array();
		save.data.buttonsmode[0] = mode;
		save.flush();
		return save.data.buttonsmode[0];
	}

	public function savecustom(_pad:MobilePad) {
		if (save.data.buttons == null)
		{
			save.data.buttons = new Array();
			if (!isExtend){
				for (buttons in _pad){
					save.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));
				}
			}
			else{
				save.data.buttons[0] = FlxPoint.get(_pad.buttonExtra2.x, _pad.buttonExtra2.y);
				save.data.buttons[1] = FlxPoint.get(_pad.buttonExtra1.x, _pad.buttonExtra1.y);
				save.data.buttons[2] = FlxPoint.get(_pad.buttonExtra3.x, _pad.buttonExtra3.y);
				save.data.buttons[3] = FlxPoint.get(_pad.buttonExtra4.x, _pad.buttonExtra4.y);
			}
		}else{
			if (!isExtend){
				var tempCount:Int = 0;
				for (buttons in _pad){
					save.data.buttons[tempCount] = FlxPoint.get(buttons.x, buttons.y);
					tempCount++;
				}
			}
			else{
				save.data.buttons[0] = FlxPoint.get(_pad.buttonExtra2.x, _pad.buttonExtra2.y);
				save.data.buttons[1] = FlxPoint.get(_pad.buttonExtra1.x, _pad.buttonExtra1.y);
				save.data.buttons[2] = FlxPoint.get(_pad.buttonExtra3.x, _pad.buttonExtra3.y);
				save.data.buttons[3] = FlxPoint.get(_pad.buttonExtra4.x, _pad.buttonExtra4.y);
			}
		}
		save.flush();
	}

	public function loadcustom(_pad:MobilePad):MobilePad {
		if (save.data.buttons == null) 
			return _pad; 
		var tempCount:Int = 0;
		if (!isExtend){
			for(buttons in _pad){
				buttons.x = save.data.buttons[tempCount].x;
				buttons.y = save.data.buttons[tempCount].y;
				tempCount++;
			}
		}
		else{
			if (_pad.buttonExtra2 != null){
				_pad.buttonExtra2.x = save.data.buttons[0].x;
				_pad.buttonExtra2.y = save.data.buttons[0].y;
			}
			if (_pad.buttonExtra1 != null){
				_pad.buttonExtra1.x = save.data.buttons[1].x;
				_pad.buttonExtra1.y = save.data.buttons[1].y;
			}
			if (_pad.buttonExtra3 != null){
				_pad.buttonExtra3.x = save.data.buttons[2].x;
				_pad.buttonExtra3.y = save.data.buttons[2].y;
			}
			if (_pad.buttonExtra4 != null){
				_pad.buttonExtra4.x = save.data.buttons[3].x;
				_pad.buttonExtra4.y = save.data.buttons[3].y;
			}
		}
		return _pad;
	}
}

class MobileControls extends FlxSpriteGroup {
	public static var mode:ControlsGroup = HITBOX;

	public var hbox:HitboxOld;
	public var newhbox:Hitbox;
	public var vpad:MobilePad;
	public var current:CurrentManager;

	var config:Config;
	var extendConfig:Config;

	public function new(?CustomMode:String) {
		super();

		config = new Config('saved-controls');
		extendConfig = new Config('saved-extendControls');

		mode = getModeFromNumber(config.getcontrolmode());

		switch (mode){
			case MOBILEPAD_RIGHT:
				initControler(0);
			case MOBILEPAD_LEFT:
				initControler(1);
			case MOBILEPAD_CUSTOM:
				initControler(2);
			case DUO:
				initControler(3);
			case HITBOX:
				if(ClientPrefs.data.hitboxmode == 'Classic') initControler(4);
				else initControler(5, CustomMode);
			case KEYBOARD:
				// nothing
		}
		current = new CurrentManager(this);
	}

	function initControler(vpadMode:Int, ?CustomMode:String) {
		switch (vpadMode){
			case 0:
				vpad = new MobilePad("RIGHT_FULL", "controlExtend");
				add(vpad);
				vpad = extendConfig.loadcustom(vpad);
			case 1:
				vpad = new MobilePad("FULL", "controlExtend");
				add(vpad);
				vpad = extendConfig.loadcustom(vpad);
			case 2:
				vpad = new MobilePad("FULL", "controlExtend");
				vpad = config.loadcustom(vpad);
				add(vpad);
				vpad = extendConfig.loadcustom(vpad);
			case 3:
				vpad = new MobilePad("DUO", "controlExtend");
				add(vpad);
				vpad = extendConfig.loadcustom(vpad);
			case 4:
				hbox = new HitboxOld(0.75, ClientPrefs.data.antialiasing);
				add(hbox);
			case 5:
				if (CustomMode != null) newhbox = new Hitbox(CustomMode);
				else newhbox = new Hitbox();
				add(newhbox);
			default:
				newhbox = new Hitbox();
				add(newhbox);
		}
	}

	public static function getModeFromNumber(modeNum:Int):ControlsGroup {
		return switch (modeNum){
			case 0: 
				MOBILEPAD_RIGHT;
			case 1: 
				MOBILEPAD_LEFT;
			case 2: 
				MOBILEPAD_CUSTOM;
			case 3: 
				DUO;
			case 4:
				HITBOX;
			case 5: 
				KEYBOARD;
			default: 
				HITBOX;
		}
	}
}

enum ControlsGroup {
	MOBILEPAD_RIGHT;
	MOBILEPAD_LEFT;
	MOBILEPAD_CUSTOM;
	DUO;
	HITBOX;
	KEYBOARD;
}

class CurrentManager {
	public var buttonLeft:MobileButton;
	public var buttonDown:MobileButton;
	public var buttonUp:MobileButton;
	public var buttonRight:MobileButton;
	public var buttonExtra1:MobileButton;
	public var buttonExtra2:MobileButton;
	public var buttonExtra3:MobileButton;
	public var buttonExtra4:MobileButton;

	public function new(control:MobileControls){
		if(MobileControls.mode == HITBOX && ClientPrefs.data.hitboxmode != 'Classic') {
			buttonLeft = control.newhbox.buttonLeft;
			buttonDown = control.newhbox.buttonDown;
			buttonUp = control.newhbox.buttonUp;
			buttonRight = control.newhbox.buttonRight;
			buttonExtra1 = control.newhbox.buttonExtra1;
			buttonExtra2 = control.newhbox.buttonExtra2;
			buttonExtra3 = control.newhbox.buttonExtra3;
			buttonExtra4 = control.newhbox.buttonExtra4;
		} else if (ClientPrefs.data.hitboxmode != 'Classic' && MobileControls.mode != KEYBOARD) {
			buttonLeft = control.vpad.buttonLeft;
			buttonDown = control.vpad.buttonDown;
			buttonUp = control.vpad.buttonUp;
			buttonRight = control.vpad.buttonRight;
			buttonExtra1 = control.vpad.buttonExtra1;
			buttonExtra2 = control.vpad.buttonExtra2;
			buttonExtra3 = control.vpad.buttonExtra3;
			buttonExtra4 = control.vpad.buttonExtra4;
		}
	}
}