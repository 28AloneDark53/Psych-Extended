package extras.debug;

import MainMenuState;

class VersionCounter extends Sprite
{
	public var EngineName:TextField;
	//这调整大小次数多了文本就要跑了

	public var bgSprite:FPSBG;

	public function new(x:Float = 10, y:Float = 10)
	{
		super();

		this.x = x;
		this.y = y;

		bgSprite = new FPSBG();
		addChild(bgSprite);

		this.EngineName = new TextField();

		for(label in [this.EngineName]) {
			label.x = 0;
			label.y = 0;
			label.defaultTextFormat = new TextFormat(Assets.getFont("assets/fonts/FPS.ttf").fontName, 15, 0xFFFFFFFF, false, null, null, CENTER, 0, 0);
			label.multiline = label.wordWrap = false;
			label.selectable = false; 
			label.mouseEnabled = false;
			addChild(label);
		}

		this.EngineName.y = 20;
		this.EngineName.y -= 18;
		this.EngineName.text = 'Psych Extended\nv' + MainMenuState.psychExtendedVersion;
		this.EngineName.visible = true;
		this.EngineName.width = 140;
	}

	public function update():Void
	{
		for(label in [this.EngineName]) {
				if (ClientPrefs.data.rainbowFPS) label.textColor = ColorReturn.transfer(DataGet.currentFPS, ClientPrefs.data.framerate);
				else label.textColor = 0xFFFFFFFF;
				if (!ClientPrefs.data.rainbowFPS && DataGet.currentFPS <= ClientPrefs.data.framerate / 2) label.textColor = 0xFFFF0000;
		}
	}

	public function change(){
		this.EngineName.visible = true;
	}
}