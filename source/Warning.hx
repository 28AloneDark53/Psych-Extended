package;

class Warning {
	public static var warningTextBG:FlxSprite;
	public static var warningText:FlxText;
	public static var WarningIsVisible:Bool;
	public static function destroy() {
		if (warningText != null && warningTextBG != null) {
			warningText.destroy();
			warningTextBG.destroy();
			WarningIsVisible = false;
		}
	}

	public static function create(Text:String) {
		warningTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		warningTextBG.alpha = 0.6;
		warningTextBG.visible = false;
		FlxG.state.add(warningTextBG);

		warningText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		warningText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		warningText.scrollFactor.set();
		warningText.visible = false;
		FlxG.state.add(warningText);

		warningText.text = Text;
		warningText.screenCenter(Y);
		warningText.visible = true;
		warningTextBG.visible = true;
		WarningIsVisible = true;
	}
}