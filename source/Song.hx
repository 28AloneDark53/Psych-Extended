package;

import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import Note;

#if sys
import sys.io.File;
import sys.FileSystem;
#end


typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var offset:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var format:String;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var disableNoteRGB:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
	var validScore:Bool;

	#if PSYCH_EXTENDED_NOTESKINS
	@:optional var playerArrowSkin:String;
	@:optional var opponentArrowSkin:String;
	@:optional var characterPlayingAsDad:Bool;
	#end
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	@:optional var typeOfSection:Int;
	var mustHitSection:Bool;
	@:optional var altAnim:Bool;
	@:optional var gfSection:Bool;
	@:optional var bpm:Float;
	@:optional var changeBPM:Bool;
}

class Song
{
	public static var useOldChartLoadSystem:Bool = false; //for Chart Editor
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	#if PSYCH_EXTENDED_NOTESKINS
	public var playerArrowSkin:String;
	public var opponentArrowSkin:String;
	public var characterPlayingAsDad:Bool;
	#end
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';
	public var format:String = 'psych_v1';

	public static function convert(songJson:Dynamic) // Convert old charts to psych_v1 format
	{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			if (ClientPrefs.data.chartLoadSystem == '1.0x') if(Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');
			else songJson.player3 = null;
		}

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		var sectionsData:Array<SwagSection> = songJson.notes;
		if (ClientPrefs.data.chartLoadSystem == '1.0x')
		{
			if(sectionsData == null) return;
			for (section in sectionsData)
			{
				var beats:Null<Float> = cast section.sectionBeats;
				if (beats == null || Math.isNaN(beats))
				{
					section.sectionBeats = 4;
					if(Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
				}
				for (note in section.sectionNotes)
				{
					var gottaHitNote:Bool = (note[1] < 4) ? section.mustHitSection : !section.mustHitSection;
					note[1] = (note[1] % 4) + (gottaHitNote ? 0 : 4);
					if(note[3] != null && !Std.isOfType(note[3], String))
						note[3] = Note.defaultNoteTypes[note[3]]; //compatibility with Week 7 and 0.1-0.3 psych charts
				}
			}
		}
	}

	private static function onLoadJson(songJson:Dynamic) // This is 0.6.3 Chart Load System Because Chart Editor Doesn't Support 1.0 Charts
	{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}
	}

	public function new(?song, ?notes, ?bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static var chartPath:String;
	public static var loadedSongName:String;
	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		if (ClientPrefs.data.chartLoadSystem == '1.0x')
		{
			trace('Current Chart System: 1.0');
			if(folder == null) folder = jsonInput;
			PlayState.SONG = getChart(jsonInput, folder);
			loadedSongName = folder;
			chartPath = _lastPath.replace('/', '\\');
			if(jsonInput != 'events') StageData.loadDirectory(PlayState.SONG);
			return PlayState.SONG; 
		}
		else
		{
			trace('Current Chart System: 0.4-0.7x');
			var rawJson = null;

			var formattedFolder:String = Paths.formatToSongPath(folder);
			var formattedSong:String = Paths.formatToSongPath(jsonInput);

			#if MODS_ALLOWED
			var moddyFile:String = Paths.modsJson('$formattedFolder/$formattedSong');
			if(FileSystem.exists(moddyFile)) {
				rawJson = File.getContent(moddyFile).trim();
			}
			#end

			if(rawJson == null) {
				var path:String = Paths.json('$formattedFolder/$formattedSong');
				
				#if sys
				if(FileSystem.exists(path))
					rawJson = File.getContent(path);
				else
				#end
					rawJson = Assets.getText(path);
			}
			
			while (!rawJson.endsWith("}"))
			{
				rawJson = rawJson.substr(0, rawJson.length - 1);
				// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
			}

			var songJson:Dynamic = parseJSONshit(rawJson);
			loadedSongName = folder;
			if(jsonInput != 'events') StageData.loadDirectory(songJson);
			onLoadJson(songJson);
			return songJson;
		}
	}

	static var _lastPath:String;
	public static function getChart(jsonInput:String, ?folder:String):SwagSong
	{
		if(folder == null) folder = jsonInput;
		var rawData:String = null;

		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);

		#if MODS_ALLOWED
		_lastPath = Paths.modsJson('$formattedFolder/$formattedSong');
		if(FileSystem.exists(_lastPath))
			rawData = File.getContent(_lastPath);
		#end

		//Base Songs
		if(rawData == null)
		{
			_lastPath = Paths.json('$formattedFolder/$formattedSong');
			#if sys
			if(FileSystem.exists(_lastPath))
				rawData = File.getContent(_lastPath);
			else
			#end
				rawData = Assets.getText(_lastPath);
		}

		return rawData != null ? parseJSON(rawData, jsonInput) : null;
	}

	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
	{
		var songJson:SwagSong = cast Json.parse(rawData);
		if(Reflect.hasField(songJson, 'song'))
		{
			var subSong:SwagSong = Reflect.field(songJson, 'song');
			if(subSong != null && Type.typeof(subSong) == TObject)
				songJson = subSong;
		}
		if(convertTo != null && convertTo.length > 0)
		{
			var fmt:String = songJson.format;
			if(fmt == null) fmt = songJson.format = 'unknown';
			switch(convertTo)
			{
				case 'psych_v1':
					if(!fmt.startsWith('psych_v1')) //Convert to Psych 1.0 format
					{
						trace('converting chart $nameForError with format $fmt to psych_v1 format...');
						songJson.format = 'psych_v1_convert';
						convert(songJson);
					}
			}
		}
		return songJson;
	}
}

/**
 * TO DO: V-Slice Chart Data here.
 */