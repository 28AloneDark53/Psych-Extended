package;

import mobile.backend.CrashHandler;
import openfl.events.UncaughtErrorEvent;
#if PsychExtended_ExtraFPSCounters
import extras.debug.FPS as FPSNova;
import debug.FPSNF;
#end
import debug.FPSPsych;
import Highscore;
import flixel.FlxGame;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;
import TitleState;
import mobile.backend.MobileScaleMode;
import openfl.events.KeyboardEvent;
import lime.system.System as LimeSystem;
#if mobile
import mobile.states.CopyState;
#end
#if linux
import lime.graphics.Image;

@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

class Main extends Sprite
{
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: false, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPSPsych;
	#if PsychExtended_ExtraFPSCounters
	public static var fpsVarNova:FPSNova;
	public static var fpsVarNF:FPSNF;
	#end

	public static final platform:String = #if mobile "Phones" #else "PCs" #end;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		#if cpp
		cpp.NativeGc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end
	}

	public function new()
	{
		super();
		#if mobile
		#if android
		StorageUtil.requestPermissions();
		#end
		Sys.setCwd(StorageUtil.getStorageDirectory());
		#end
		CrashHandler.init();

		#if windows
		@:functionCode("
			#include <windows.h>
			#include <winuser.h>
			setProcessDPIAware() // allows for more crisp visuals
			DisableProcessWindowsGhosting() // lets you move the window and such if it's not responding
		")
		#end

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		#if (openfl <= "9.2.0")
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}
		#else
		if (game.zoom == -1.0)
			game.zoom = 1.0;
		#end
		
		var SelectedState:Dynamic = game.initialState;
		/*
		if (FileSystem.exists(Paths.getScriptPath('states/TitleState.hx')) || FileSystem.exists(Paths.modFolders('scripts/states/TitleState.hx')) || FileSystem.exists(Paths.modpackFolders('scripts/states/TitleState.hx'))) SelectedState = MainState;
		else SelectedState = game.initialState;
		*/

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		
		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Highscore.load();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		addChild(new FlxGame(game.width, game.height, #if (mobile && MODS_ALLOWED) CopyState.checkExistingFiles() ? SelectedState : CopyState #else SelectedState #end, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		#if PsychExtended_ExtraFPSCounters
		// NovaFlare Engine FPS Counter
		fpsVarNova = new FPSNova(5, 5);
		addChild(fpsVarNova);
		if(fpsVarNova != null) { fpsVarNova.scaleX = fpsVarNova.scaleY = 1;	fpsVarNova.visible = false; }

		// NF Engine FPS Counter
		fpsVarNF = new FPSNF(10, 3, 0xFFFFFF);
		addChild(fpsVarNF);
		if(fpsVarNF != null) fpsVarNF.visible = false;
		#end

		// PsychEngine FPS Counter
		fpsVar = new FPSPsych(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		if(fpsVar != null) fpsVar.visible = false;

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = #if mobile 30 #else 60 #end;
		#if web
		FlxG.keys.preventDefaultKeys.push(TAB);
		#else
		FlxG.keys.preventDefaultKeys = [TAB];
		#end

		#if android FlxG.android.preventDefaultKeys = [BACK]; #end

		#if mobile
		FlxG.scaleMode = new MobileScaleMode();
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function (w, h) {
			#if PsychExtended_ExtraFPSCounters
			if(fpsVarNF != null)
				fpsVarNF.positionFPS(10, 3, Math.min(w / FlxG.width, h / FlxG.height));
			else #end if(fpsVar != null)
				fpsVar.positionFPS(10, 3, Math.min(w / FlxG.width, h / FlxG.height));

			if (FlxG.cameras != null) {
				for (cam in FlxG.cameras.list) {
					if (cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}

			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
				sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}
