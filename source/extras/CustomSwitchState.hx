package extras;

#if SCRIPTING_ALLOWED
import scripting.HScript;
#end
import funkin.backend.scripting.events.CancellableEvent;
import editors.ChartingState;
import editors.ChartingStateNew;

// This Shit is Not Optimized 😭
class CustomSwitchState
{
	var eventStop:Bool = false;
	public function switchMenusNew(StatePrefix:String, ?useLoadandSwitch:Bool = false)
	{
		#if SCRIPTING_ALLOWED
		loadScript('classes/CustomSwitchState');
		#end

		call("switchMenus", [StatePrefix, eventStop]);

		FunkinLua.FPSCounterText = null;

		var CP = ClientPrefs.data;
		var switchState = MusicBeatState.switchState;

		//OMG 😱 Rewrited? EDIT: It's still sucks but better than first version
		if (!eventStop) {
			switch (StatePrefix)
			{
				case 'Freeplay':
					#if PsychExtended_ExtraFreeplayMenus
					if (CP.FreeplayStyle == 'NF') switchState(new FreeplayStateNF());
					else if (CP.FreeplayStyle == 'NovaFlare') switchState(new FreeplayStateNOVA());
					else #end switchState(new FreeplayState());
				case 'MainMenu':
					#if PsychExtended_ExtraMainMenus
					if (CP.MainMenuStyle == '0.6.3' || CP.MainMenuStyle == 'Extended') switchState(new MainMenuStateOld());
					else if (CP.MainMenuStyle == 'NovaFlare') switchState(new MainMenuStateNOVA());
					else #end switchState(new MainMenuState());
				case 'StoryMenu':
					switchState(new StoryMenuState());
				case 'Options':
					MusicBeatState.switchState(new options.OptionsState());
				case 'Credits':
					switchState(new CreditsState());
				case 'Title':
					switchState(new TitleState());
				case 'MasterEditor':
					switchState(new editors.MasterEditorMenu());
				case 'NoteOffset':
					switchState(new options.NoteOffsetState());
				case 'Charting':
					//1.0 Chart Editor Support, Let's gooooo
					if (ClientPrefs.data.chartLoadSystem == '1.0x') switchState(new ChartingStateNew());
					else if(useLoadandSwitch && ClientPrefs.data.chartLoadSystem == '1.0x') LoadingState.loadAndSwitchState(new ChartingStateNew(), false);
					else if(useLoadandSwitch) LoadingState.loadAndSwitchState(new ChartingState());
					else switchState(new ChartingState());
				case 'ModsMenu':
					switchState(new ModsMenuState());
				#if ACHIEVEMENTS_ALLOWED
				case 'AchievementsMenu':
					MusicBeatState.switchState(new AchievementsMenuState());
				#end
			}
		}
		call("switchMenusPost", [StatePrefix, eventStop]);

		destroy(); //destroy HScript Later switching
	}

	//Automatic Instance Creator
	public static function switchMenus(StatePrefix:String, ?useLoadandSwitch:Bool = false)
	{
		var createInstance:CustomSwitchState = new CustomSwitchState();
		createInstance.switchMenusNew(StatePrefix, useLoadandSwitch);
	}

	public function destroy() {
		call("destroy");
		#if SCRIPTING_ALLOWED
		stateScripts = FlxDestroyUtil.destroy(stateScripts);
		#end
	}

	/**
	 * SCRIPTING STUFF
	 */
	#if SCRIPTING_ALLOWED
	public var scriptsAllowed:Bool = true;

	/**
	 * Current injected script attached to the state. To add one, create a file at path "data/states/stateName" (ex: data/states/FreeplayState)
	 */
	public var stateScripts:ScriptPack;

	public static var lastScriptName:String = null;
	public static var lastStateName:String = null;

	public var scriptName:String = null;

	public function new(scriptsAllowed:Bool = true, ?scriptName:String) {
		if(lastStateName != (lastStateName = Type.getClassName(Type.getClass(this)))) {
			lastScriptName = null;
		}
		this.scriptName = scriptName != null ? scriptName : lastScriptName;
		lastScriptName = this.scriptName;
	}

	function loadScript(?customPath:String) {
		var className = Type.getClassName(Type.getClass(this));
		if (stateScripts == null)
			(stateScripts = new ScriptPack(className)).setParent(this);
		if (scriptsAllowed) {
			if (stateScripts.scripts.length == 0) {
				var scriptName = this.scriptName != null ? this.scriptName : className.substr(className.lastIndexOf(".")+1);
				var filePath:String = "classes/" + scriptName;
				if (customPath != null)
					filePath = customPath;

				#if MODS_ALLOWED
				var scriptToLoad:String = Paths.menuFolders('scripts/${filePath}.hx');
				if(!FileSystem.exists(scriptToLoad))
					scriptToLoad = Paths.getScriptPath('${filePath}.hx');
				#else
				var scriptToLoad:String = Paths.getScriptPath('${filePath}.hx');
				#end

				var path = scriptToLoad;
				var script = Script.create(path);
				script.remappedNames.set(script.fileName, '${script.fileName}');
				stateScripts.add(script);
				script.load();
				call('create');
			}
			else stateScripts.reload();
		}
	}
	#else
	public function new() {}
	#end

	public function call(name:String, ?args:Array<Dynamic>, ?defaultVal:Dynamic):Dynamic {
		// calls the function on the assigned script
		#if SCRIPTING_ALLOWED
		if(stateScripts != null)
			return stateScripts.call(name, args);
		#end
		return defaultVal;
	}

	public function event<T:CancellableEvent>(name:String, event:T):T {
		#if SCRIPTING_ALLOWED
		if(stateScripts != null)
			stateScripts.call(name, [event]);
		#end
		return event;
	}
}