package extras;
import scripting.HScriptClassHandler;

// This Shit is Not Optimized 😭
class CustomSwitchState extends HScriptClassHandler
{
	function new() {super();}

	override public function switchMenusNew(StatePrefix:String, ?skipTrans:Bool = false, ?skipTransCustom:String = '')
	{
		#if SCRIPTING_ALLOWED
		startHScriptsNamed('CustomSwitchState.hx');
		startHScriptsNamed('global.hx');
		#end

		var disableOriginals:Bool = false;
		#if SCRIPTING_ALLOWED callOnScripts('onSwitchMenus', [StatePrefix, disableOriginals]); #end

		FunkinLua.FPSCounterText = null;
		if (skipTransCustom == 'TransIn' || skipTrans) FlxTransitionableState.skipNextTransIn = true;
		if (skipTransCustom == 'TransOut' || skipTrans) FlxTransitionableState.skipNextTransOut = true;

		var CP = ClientPrefs.data;
		var switchState = MusicBeatState.switchState;

		//OMG 😱 Rewrited? EDIT: It's still sucks but better than first version
		if (!disableOriginals) {
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
					LoadingState.loadAndSwitchState(new options.OptionsState());
				case 'Credits':
					switchState(new CreditsState());
				case 'Title':
					switchState(new TitleState());
				case 'MasterEditor':
					switchState(new editors.MasterEditorMenu());
				case 'NoteOffset':
					switchState(new options.NoteOffsetState());
				case 'ModsMenu':
					switchState(new ModsMenuState());
				#if ACHIEVEMENTS_ALLOWED
				case 'AchievementsMenu':
					LoadingState.loadAndSwitchState(new AchievementsMenuState());
				#end
			}
		}
		#if SCRIPTING_ALLOWED callOnScripts('onSwitchMenusPost', [StatePrefix]); #end

		destroy(); //destroy HScript Later switching
	}

	public static function switchMenus(StatePrefix:String, ?skipTrans:Bool = false, ?skipTransCustom:String = '') //do not break the Mods
	{
		var createInstance:CustomSwitchState = new CustomSwitchState();
		createInstance.switchMenusNew(StatePrefix, skipTrans, skipTransCustom);
	}
}