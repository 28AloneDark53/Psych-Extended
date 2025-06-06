import flixel.addons.display.FlxGridOverlay;
import lime.utils.Assets;
import Alphabet;
import backend.Mods;
import AttachedSprite;
import Alphabet.Alignment;
import flixel.text.FlxText.FlxTextAlign;


var curSelected:Int = -1;

var grpOptions:FlxTypedGroup<Alphabet>;
var iconArray:Array<AttachedSprite> = [];
var creditsStuff:Array<Array<String>> = [];

var bg:FlxSprite;
var descText:FlxText;
var intendedColor:Int;
var colorTween:FlxTween;
var descBox:AttachedSprite;

var offsetThing:Float = -75;

var defaultList:Array<Array<String>> = [ //Name - Icon name - Description - Link - BG Color
	['Psych Extended'],
	['KralOyuncu 2010X',	 'KralOyuncuV3',	'Creator of Psych Extended\n(Only Person Working on Psych Extended for now)',											'https://youtube.com/@kraloyuncurbx',		'378FC7'],
	[''],
	['Needed Credits'],
	['beihu',				 'beihu',			'Owner of NovaFlare Engine\n(I used some codes from NovaFlare)',	'https://youtube.com/@hoyou235',			'FFC0CB'],
	[''],
	['Psych Engine Team'],
	['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',								'https://twitter.com/Shadow_Mario_',	'444444'],
	['RiverOaken',			'river',			'Main Artist/Animator of Psych Engine',							'https://twitter.com/RiverOaken',		'B42F71'],
	['shubs',				'shubs',			'Additional Programmer of Psych Engine',						'https://twitter.com/yoshubs',			'5E99DF'],
	[''],
	['Former Engine Members'],
	['bb-panzu',			'bb',				'Ex-Programmer of Psych Engine',								'https://twitter.com/bbsub3',			'3E813A'],
	[''],
	['Engine Contributors'],
	['iFlicky',				'flicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',		'https://twitter.com/flicky_i',			'9E29CF'],
	['SqirraRNG',			'sqirra',			'Crash Handler and Base code for\nChart Editor\'s Waveform',	'https://twitter.com/gedehari',			'E1843A'],
	['EliteMasterEric',		'mastereric',		'Runtime Shaders support',										'https://twitter.com/EliteMasterEric',	'FFBD40'],
	['PolybiusProxy',		'proxy',			'.MP4 Video Loader Library (hxCodec)',							'https://twitter.com/polybiusproxy',	'DCD294'],
	['KadeDev',				'kade',				'Fixed some cool stuff on Chart Editor\nand other PRs',			'https://twitter.com/kade0912',			'64A250'],
	['Keoiki',				'keoiki',			'Note Splash Animations',										'https://twitter.com/Keoiki_',			'D2D2D2'],
	['Nebula the Zorua',	'nebula',			'LUA JIT Fork and some Lua reworks',							'https://twitter.com/Nebula_Zorua',		'7D40B2'],
	['Smokey',				'smokey',			'Sprite Atlas Support',											'https://twitter.com/Smokey_5_',		'483D92'],
	[''],
	["Funkin' Crew"],
	['ninjamuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",							'https://twitter.com/ninja_muffin99',	'CF2D2D'],
	['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",								'https://twitter.com/PhantomArcade3K',	'FADC45'],
	['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",								'https://twitter.com/evilsk8r',			'5ABD4B'],
	['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",								'https://twitter.com/kawaisprite',		'378FC7']
];

function create()
{
	persistentUpdate = true;
	bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
	add(bg);
	bg.screenCenter();

	grpOptions = new FlxTypedGroup();
	add(grpOptions);

	#if MODS_ALLOWED
	for (mod in Mods.parseList().enabled) pushModCreditsToList(mod);
	#end

	for(i in defaultList){
		creditsStuff.push(i);
	}

	for (i in 0...creditsStuff.length)
	{
		var isSelectable:Bool = !unselectableCheck(i);
		var optionText:Alphabet = new Alphabet(FlxG.width / 2, 300, creditsStuff[i][0], !isSelectable);
		optionText.isMenuItem = true;
		optionText.targetY = i;
		optionText.changeX = false;
		optionText.snapToPosition();
		grpOptions.add(optionText);

		if(isSelectable) {
			if(creditsStuff[i][5] != null)
			{
				Mods.currentModDirectory = creditsStuff[i][5];
			}

			var str:String = 'credits/missing_icon';
			if (Paths.image('credits/' + creditsStuff[i][1]) != null) str = 'credits/' + creditsStuff[i][1];
			var icon:AttachedSprite = new AttachedSprite(str);
			icon.xAdd = optionText.width + 10;
			icon.sprTracker = optionText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
			Mods.currentModDirectory = '';

			if(curSelected == -1) curSelected = i;
		}
		else optionText.alignment = Alignment.CENTERED;
	}

	descBox = new AttachedSprite();
	descBox.makeGraphic(1, 1, FlxColor.BLACK);
	descBox.xAdd = -10;
	descBox.yAdd = -10;
	descBox.alphaMult = 0.6;
	descBox.alpha = 0.6;
	add(descBox);

	descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
	descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, FlxTextAlign.CENTER);
	descText.scrollFactor.set();
	descBox.sprTracker = descText;
	add(descText);

	bg.color = getCurrentBGColor();
	intendedColor = bg.color;
	changeSelection(0);

	#if TOUCH_CONTROLS addVirtualPad("UP_DOWN", "A_B"); #end
}

function getCurrentBGColor() {
	var bgColor:String = creditsStuff[curSelected][4];
	bgColor = '0xFF' + bgColor;
	return Std.parseInt(bgColor);
}

var moveTween:FlxTween = null;
function changeSelection(change:Int = 0)
{
	FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	do {
		curSelected += change;
		if (curSelected < 0)
			curSelected = creditsStuff.length - 1;
		if (curSelected >= creditsStuff.length)
			curSelected = 0;
	} while(unselectableCheck(curSelected));

	var newColor:Int =  getCurrentBGColor();
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

	var bullShit:Int = 0;

	for (item in grpOptions.members)
	{
		item.targetY = bullShit - curSelected;
		bullShit++;

		if(!unselectableCheck(bullShit-1)) {
			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}
	}

	descText.text = creditsStuff[curSelected][2];
	descText.y = FlxG.height - descText.height + offsetThing - 60;

	if(moveTween != null) moveTween.cancel();
	moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});

	descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
	descBox.updateHitbox();
}


var quitting:Bool = false;
var holdTime:Float = 0;
function update(elapsed:Float)
{
	if(!quitting)
	{
		if(creditsStuff.length > 1)
		{
			var shiftMult:Int = 1;
			if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

			var upP = controls.UI_UP_P;
			var downP = controls.UI_DOWN_P;

			if (upP)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
			}
		}

		if(controls.ACCEPT && (creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length > 4)) {
			CoolUtil.browserLoad(creditsStuff[curSelected][3]);
		}
		if (controls.BACK)
		{
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			CustomSwitchState.switchMenus('MainMenu');
			quitting = true;
		}
	}

	for (item in grpOptions.members)
	{
		if(!item.bold)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 12, 0, 1);
			if(item.targetY == 0)
			{
				var lastX:Float = item.x;
				item.screenCenter(FlxAxes.X);
				item.x = FlxMath.lerp(lastX, item.x - 70, lerpVal);
			}
			else
			{
				item.x = FlxMath.lerp(item.x, 200 + -40 * Math.abs(item.targetY), lerpVal);
			}
		}
	}
}

function unselectableCheck(num:Int):Bool {
	return creditsStuff[num].length <= 1;
}

#if MODS_ALLOWED
function pushModCreditsToList(folder:String)
{
	var creditsFile:String = null;
	/* this shit is doesn't work, if you want you can fix
	if(folder != null && folder.trim().length > 0) creditsFile = Paths.mods(folder + '/data/credits.txt');
	else */
	creditsFile = Paths.mods('data/credits.txt');

	if (FileSystem.exists(creditsFile))
	{
		var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
		for(i in firstarray)
		{
			var arr:Array<String> = i.replace('\\n', '\n').split("::");
			if(arr.length >= 5) arr.push(folder);
			creditsStuff.push(arr);
		}
		creditsStuff.push(['']);
	}
}
#end