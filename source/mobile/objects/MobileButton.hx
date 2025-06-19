package mobile.objects;

import flixel.input.FlxInput;
import flixel.input.FlxPointer;
import flixel.input.IFlxInput;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
#if mac
import flixel.input.mouse.FlxMouseButton;
#end

/**
 * A simple button class that calls a function when clicked by the touch.
 * @author: KralOyuncu2010x (ArkoseLabs)
 */
class MobileButton extends TypedMobileButton<FlxSprite>
{
	/**
	 * Used with public variable status, means not highlighted or pressed.
	 */
	public static inline var NORMAL:Int = 0;

	/**
	 * Used with public variable status, means highlighted (usually from touch over).
	 */
	public static inline var HIGHLIGHT:Int = 1;

	/**
	 * Used with public variable status, means pressed (usually from touch click).
	 */
	public static inline var PRESSED:Int = 2;

	/**
	 * A simple tag that returns the button's graphic name in upper case.
	**/
	public var tag:String;

	/**
	 * A Small invisible bounds used for colision
	**/
	public var bounds:FlxSprite = new FlxSprite();

	/**
	 * Creates a new `MobileButton` object
	 * and a callback function on the UI thread.
	 *
	 * @param   X		 The x position of the button.
	 * @param   Y		 The y position of the button.
	 */
	public function new(X:Float = 0, Y:Float = 0):Void
	{
		super(X, Y);
	}

	public inline function centerInBounds()
	{
		setPosition(bounds.x + ((bounds.width - frameWidth) / 2), bounds.y + ((bounds.height - frameHeight) / 2));
	}

	public inline function centerBounds()
	{
		bounds.setPosition(x + ((frameWidth - bounds.width) / 2), y + ((frameHeight - bounds.height) / 2));
	}
}

/**
 * A simple button class that calls a function when clicked by the touch.
 */
#if !display
@:generic
#end
class TypedMobileButton<T:FlxSprite> extends FlxSprite implements IFlxInput
{
	/**
	 * The label that appears on the button. Can be any `FlxSprite`.
	 */
	public var label(default, set):T;

	/**
	 * What offsets the `label` should have for each status.
	 */
	public var labelOffsets:Array<FlxPoint> = [FlxPoint.get(), FlxPoint.get(), FlxPoint.get(0, 1)];

	/**
	 * What alpha value the label should have for each status. Default is `[0.8, 1.0, 0.5]`.
	 * Multiplied with the button's `alpha`.
	 */
	public var labelAlphas:Array<Float> = [0.8, 1.0, 0.5];

	/**
	 * What animation should be played for each status.
	 * Default is ['normal', 'highlight', 'pressed'].
	 */
	public var statusAnimations:Array<String> = ['normal', 'highlight', 'pressed'];

	/**
	 * Whether you can press the button simply by releasing the touch button over it (default).
	 * If false, the input has to be pressed while hovering over the button.
	 */
	public var allowSwiping:Bool = true;

	/**
	 * Whether the button can use multiple fingers on it.
	 */
	public var multiTouch:Bool = false;

	/**
	 * Maximum distance a pointer can move to still trigger event handlers.
	 * If it moves beyond this limit, onOut is triggered.
	 * Defaults to `Math.POSITIVE_INFINITY` (i.e. no limit).
	 */
	public var maxInputMovement:Float = Math.POSITIVE_INFINITY;
	
	/**
	 * Shows the current state of the button, either `MobileButton.NORMAL`,
	 * `MobileButton.HIGHLIGHT` or `MobileButton.PRESSED`.
	 */
	public var status(default, set):Int;

	/**
	 * The properties of this button's `onUp` event (callback function, sound).
	 */
	public var onUp(default, null):MobileButtonEvent;

	/**
	 * The properties of this button's `onDown` event (callback function, sound).
	 */
	public var onDown(default, null):MobileButtonEvent;

	/**
	 * The properties of this button's `onOver` event (callback function, sound).
	 */
	public var onOver(default, null):MobileButtonEvent;

	/**
	 * The properties of this button's `onOut` event (callback function, sound).
	 */
	public var onOut(default, null):MobileButtonEvent;

	/**
	 * The alpha's the button should use depednging on the status.
	**/
	public var statusAlphas:Array<Float> = [1.0, 1.0, 0.6];

	/**
	 * The brightness the button should use depednging on the status.
	**/
	public var statusBrightness:Array<Float> = [1.0, 0.95, 0.7];

	/**
	 * How much to add/substract from the current indicator value for the label.
	**/
	public var labelStatusDiff:Float = 0.05;

	/**
	 * IF YOU'RE USING SPRITE GROUPS YOU MUST SET THIS TO THE GROUP'S ALPHA LIKE IN TouchPad.
	**/
	public var parentAlpha(default, set):Float = 1;

	public var statusIndicatorType(default, set):StatusIndicators = ALPHA;

	public var brightShader:ButtonBrightnessShader = new ButtonBrightnessShader();

	public var justReleased(get, never):Bool;
	public var released(get, never):Bool;
	public var pressed(get, never):Bool;
	public var justPressed(get, never):Bool;

	/**
	 * We cast label to a `FlxSprite` for internal operations to avoid Dynamic casts in C++
	 */
	var _spriteLabel:FlxSprite;

	/** 
	 * We don't need an ID here, so let's just use `Int` as the type.
	 */
	var input:FlxInput<Int>;

	/**
	 * The input currently pressing this button, if none, it's `null`. Needed to check for its release.
	 */
	var currentInput:IFlxInput;

	var lastStatus = -1;
	public var canChangeLabelAlpha:Bool = true;

	/**
	 * Creates a new `FlxTypedButton` object with a gray background.
	 *
	 * @param   X		 The x position of the button.
	 * @param   Y		 The y position of the button.
	 */
	public function new(X:Float = 0, Y:Float = 0):Void
	{
		super(X, Y);

		if (statusIndicatorType == BRIGHTNESS && ClientPrefs.data.mobilePadTexture == 'TouchPad')
			shader = brightShader;
		else
			loadDefaultGraphic();

		onUp = new MobileButtonEvent();
		onDown = new MobileButtonEvent();
		onOver = new MobileButtonEvent();
		onOut = new MobileButtonEvent();

		status = multiTouch ? MobileButton.NORMAL : MobileButton.HIGHLIGHT;

		// Since this is a UI element, the default scrollFactor is (0, 0)
		scrollFactor.set();

		if (ClientPrefs.data.mobilePadTexture != 'TouchPad') {
			statusAnimations[MobileButton.HIGHLIGHT] = 'normal';
			labelAlphas[MobileButton.HIGHLIGHT] = 1;
		}

		input = new FlxInput(0);
	}

	override public function graphicLoaded():Void
	{
		super.graphicLoaded();

		if (ClientPrefs.data.mobilePadTexture != 'TouchPad') {
			setupAnimation('normal', MobileButton.NORMAL);
			setupAnimation('pressed', MobileButton.PRESSED);
		}
	}

	function loadDefaultGraphic():Void
		loadGraphic('flixel/images/ui/button.png', true, 80, 20);

	function setupAnimation(animationName:String, frameIndex:Int):Void
	{
		// make sure the animation doesn't contain an invalid frame
		frameIndex = Std.int(Math.min(frameIndex, #if (flixel < "5.3.0") animation.frames #else animation.numFrames #end - 1));
		animation.add(animationName, [frameIndex]);
	}

	/**
	 * Called by the game state when state is changed (if this object belongs to the state)
	 */
	override public function destroy():Void
	{
		label = FlxDestroyUtil.destroy(label);
		_spriteLabel = null;

		onUp = FlxDestroyUtil.destroy(onUp);
		onDown = FlxDestroyUtil.destroy(onDown);
		onOver = FlxDestroyUtil.destroy(onOver);
		onOut = FlxDestroyUtil.destroy(onOut);

		if (ClientPrefs.data.mobilePadTexture != 'TouchPad') {
			labelOffsets = FlxDestroyUtil.putArray(labelOffsets);
			labelAlphas = null;
		}
		currentInput = null;
		input = null;

		super.destroy();
	}

	/**
	 * Called by the game loop automatically, handles touch over and click detection.
	 */
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (visible)
		{
			// Update the button, but only if at least either touches are enabled
			#if FLX_POINTER_INPUT
			updateButton();
			#end

			// Trigger the animation only if the button's input status changes.
			if (lastStatus != status && ClientPrefs.data.mobilePadTexture != 'TouchPad')
			{
				updateStatusAnimation();
				lastStatus = status;
			}
		}

		input.update();
	}

	function updateStatusAnimation():Void
		animation.play(statusAnimations[status]);

	/**
	 * Just draws the button graphic and text label to the screen.
	 */
	override public function draw():Void
	{
		super.draw();

		if (_spriteLabel != null && _spriteLabel.graphic != null && _spriteLabel.pixels != null && _spriteLabel.visible && ClientPrefs.data.mobilePadTexture == 'TouchPad')
		{
			if (_spriteLabel.cameras != cameras)
				_spriteLabel.cameras = cameras;
			_spriteLabel.draw();
		}
		else if (_spriteLabel != null && _spriteLabel.visible && ClientPrefs.data.mobilePadTexture != 'TouchPad')
		{
			_spriteLabel.cameras = cameras;
			_spriteLabel.draw();
		}
	}

	#if FLX_DEBUG
	/**
	 * Helper function to draw the debug graphic for the label as well.
	 */
	override public function drawDebug():Void
	{
		super.drawDebug();

		if (_spriteLabel != null)
			_spriteLabel.drawDebug();
	}
	#end

	/**
	 * Basic button update logic - searches for overlaps with touches and
	 * the touch and calls `updateStatus()`.
	 */
	function updateButton():Void
	{
		var overlapFound = checkTouchOverlap();

		if (currentInput != null && currentInput.justReleased && overlapFound)
			onUpHandler();

		if (status != MobileButton.NORMAL && (!overlapFound || (currentInput != null && currentInput.justReleased)))
			onOutHandler();
	}

	function checkTouchOverlap():Bool
	{
		var overlap = false;

		for (camera in cameras)
		{
			#if mac
			var button = FlxMouseButton.getByID(FlxMouseButtonID.LEFT);
			if (checkInput(FlxG.mouse, button, button.justPressedPosition, camera))
			#else
			for (touch in FlxG.touches.list)
				if (checkInput(touch, touch, touch.justPressedPosition, camera))
			#end
			overlap = true;
		}

		return overlap;
	}

	function checkInput(pointer:FlxPointer, input:IFlxInput, justPressedPosition:FlxPoint, camera:FlxCamera):Bool
	{
		if (maxInputMovement != Math.POSITIVE_INFINITY
			&& justPressedPosition.distanceTo(pointer.getScreenPosition(FlxPoint.weak())) > maxInputMovement
			&& input == currentInput)
		{
			currentInput = null;
		}
		else if (overlapsPoint(pointer.getWorldPosition(camera, _point), true, camera))
		{
			updateStatus(input);
			return true;
		}

		return false;
	}

	/**
	 * Updates the button status by calling the respective event handler function.
	 */
	function updateStatus(input:IFlxInput):Void
	{
		if (input.justPressed)
		{
			currentInput = input;
			onDownHandler();
		}
		else if (status == MobileButton.NORMAL)
		{
			// Allow 'swiping' to press a button (dragging it over the button while pressed)
			if (allowSwiping && input.pressed)
				onDownHandler();
			else
				onOverHandler();
		}
	}

	public function updateLabelPosition()
	{
		if (_spriteLabel != null && ClientPrefs.data.mobilePadTexture == 'TouchPad')
		{
			_spriteLabel.x = ((width - _spriteLabel.width) / 2) + (pixelPerfectPosition ? Math.floor(x) : x);
			_spriteLabel.y = ((height - _spriteLabel.height) / 2) + (pixelPerfectPosition ? Math.floor(y) : y);
		}
		else if (_spriteLabel != null && ClientPrefs.data.mobilePadTexture != 'TouchPad')
		{
			_spriteLabel.x = (pixelPerfectPosition ? Math.floor(x) : x) + labelOffsets[status].x;
			_spriteLabel.y = (pixelPerfectPosition ? Math.floor(y) : y) + labelOffsets[status].y;
		}
	}

	function updateLabelAlpha()
	{
		if (_spriteLabel != null && labelAlphas.length > status)
			_spriteLabel.alpha = alpha * labelAlphas[status];
	}
	
	public function updateLabelScale()
	{
		if (_spriteLabel != null)
			_spriteLabel.scale.set(scale.x, scale.y);
	}

	public function indicateStatus()
	{
		switch (statusIndicatorType)
		{
			case ALPHA:
				alpha = statusAlphas[status];
			case BRIGHTNESS:
				brightShader.brightness.value = [statusBrightness[status]];
			case NONE: // no balls
		}
	}

	/**
	 * Internal function that handles the onUp event.
	 */
	function onUpHandler():Void
	{
		status = MobileButton.NORMAL;
		input.release();
		currentInput = null;
		onUp.fire(); // Order matters here, because onUp.fire() could cause a state change and destroy this object.
	}

	/**
	 * Internal function that handles the onDown event.
	 */
	function onDownHandler():Void
	{
		status = MobileButton.PRESSED;
		input.press();
		onDown.fire(); // Order matters here, because onDown.fire() could cause a state change and destroy this object.
	}

	/**
	 * Internal function that handles the onOver event.
	 */
	function onOverHandler():Void
	{
		status = MobileButton.HIGHLIGHT;
		onOver.fire(); // Order matters here, because onOver.fire() could cause a state change and destroy this object.
	}

	/**
	 * Internal function that handles the onOut event.
	 */
	function onOutHandler():Void
	{
		status = MobileButton.NORMAL;
		input.release();
		onOut.fire(); // Order matters here, because onOut.fire() could cause a state change and destroy this object.
	}

	function set_label(Value:T):T
	{
		if (Value != null)
		{
			// use the same FlxPoint object for both
			Value.scrollFactor.put();
			Value.scrollFactor = scrollFactor;
		}

		label = Value;
		_spriteLabel = label;

		updateLabelPosition();
		
		if (statusIndicatorType == BRIGHTNESS && label != null && brightShader != null && ClientPrefs.data.mobilePadTexture == 'TouchPad')
			label.shader = brightShader;

		return Value;
	}

	function set_status(Value:Int):Int
	{
		status = Value;
		if (ClientPrefs.data.mobilePadTexture == 'TouchPad') indicateStatus();
		else updateLabelAlpha();
		return status;
	}

	override function set_alpha(Value:Float):Float
	{
		super.set_alpha(Value);
		if (ClientPrefs.data.mobilePadTexture == 'TouchPad')
		{
			if (_spriteLabel != null && canChangeLabelAlpha)
				_spriteLabel.alpha = alpha == 0 ? 0 : alpha + labelStatusDiff;
			return Value;
		}
		else
		{
			updateLabelAlpha();
			return alpha;
		}
	}
	
	override function set_visible(Value:Bool):Bool
	{
		if (ClientPrefs.data.mobilePadTexture == 'TouchPad')
		{
	 		super.set_visible(Value);
	 		if (_spriteLabel != null)
	 			_spriteLabel.visible = Value;
	 	}
	 	return Value;
	}

	override function set_x(Value:Float):Float
	{
		super.set_x(Value);
		updateLabelPosition();
		return x;
	}

	override function set_y(Value:Float):Float
	{
		super.set_y(Value);
		updateLabelPosition();
		return y;
	}
	
	override function set_color(Value:FlxColor):Int
	{
		if (_spriteLabel != null)
	 		_spriteLabel.color = Value;
	 	
		if (ClientPrefs.data.mobilePadTexture == 'TouchPad')
	 		brightShader.color = Value;
	 	
	 	super.set_color(Value);
		return Value;
	}

	override private function set_width(Value:Float)
	{
	 	super.set_width(Value);
	 	updateLabelScale();
	 	return Value;
	}

	override private function set_height(Value:Float)
	{
		super.set_height(Value);
	 	updateLabelScale();
	 	return Value;
	}

	override public function updateHitbox()
	{
	 	super.updateHitbox();
	 	if (_spriteLabel != null)
	 		_spriteLabel.updateHitbox();
	}

	function set_parentAlpha(Value:Float):Float
	{
		statusAlphas = [
			Value,
			Value - 0.05,
			(parentAlpha - 0.45 == 0 && parentAlpha > 0)
			? 0.25 : parentAlpha - 0.45
		];
		indicateStatus();
		return parentAlpha = Value;
	}

	function set_statusIndicatorType(Value:StatusIndicators)
	{
		if (Value == BRIGHTNESS)
		{
			shader = brightShader;
			if (_spriteLabel != null)
				_spriteLabel.shader = brightShader;
		}
		else
		{
			shader = null;
			if (_spriteLabel != null)
				_spriteLabel.shader = null;
		}
		statusIndicatorType = Value;
		return Value;
	}

	inline function get_justReleased():Bool
		return input.justReleased;

	inline function get_released():Bool
		return input.released;

	inline function get_pressed():Bool
		return input.pressed;

	inline function get_justPressed():Bool
		return input.justPressed;
}

/** 
 * Helper function for `MobileButton` which handles its events.
 */
private class MobileButtonEvent implements IFlxDestroyable
{
	/**
	 * The callback function to call when this even fires.
	 */
	public var callback:Void->Void;

	#if FLX_SOUND_SYSTEM
	/**
	 * The sound to play when this event fires.
	 */
	public var sound:FlxSound;
	#end

	/**
	 * @param   Callback   The callback function to call when this even fires.
	 * @param   sound	  The sound to play when this event fires.
	 */
	public function new(?Callback:Void->Void, ?sound:FlxSound):Void
	{
		callback = Callback;

		#if FLX_SOUND_SYSTEM
		this.sound = sound;
		#end
	}

	/**
	 * Cleans up memory.
	 */
	public inline function destroy():Void
	{
		callback = null;

		#if FLX_SOUND_SYSTEM
		sound = FlxDestroyUtil.destroy(sound);
		#end
	}

	/**
	 * Fires this event (calls the callback and plays the sound)
	 */
	public inline function fire():Void
	{
		if (callback != null)
			callback();

		#if FLX_SOUND_SYSTEM
		if (sound != null)
			sound.play(true);
		#end
	}
}

class ButtonBrightnessShader extends FlxShader
{
	public var color(default, set):Null<FlxColor> = FlxColor.WHITE;

	@:glFragmentSource('
		#pragma header

		uniform float brightness;

		void main()
		{
			vec4 col = flixel_texture2D(bitmap, openfl_TextureCoordv);
			col.rgb *= brightness;

			gl_FragColor = col;
		}
	')
	public function new()
	{
		super();
	}

	private function set_color(?laColor:FlxColor)
	{
		if (laColor == null)
		{
			colorMultiplier.value = [1, 1, 1, 1];
			hasColorTransform.value = hasTransform.value = [false];
			return color = laColor;
		}
		hasColorTransform.value = hasTransform.value = [true];
		colorMultiplier.value = [laColor.redFloat, laColor.blueFloat, laColor.greenFloat, laColor.alphaFloat];
		return color = laColor;
	}
}

enum StatusIndicators
{
	// isn't very good looking
	ALPHA;
	// best one in my opinion
	BRIGHTNESS;
	// used when u make ur own status indicator like in hitbox
	NONE;
}