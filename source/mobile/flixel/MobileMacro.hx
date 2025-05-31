package mobile.flixel;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class MobileMacro {
	public static macro function createExtraHitboxButtons(extraButtons:Int):Array<Field> {
		var fields = Context.getBuildFields();

		for (i in 1...extraButtons + 1) {
			var buttonName = 'buttonExtra$i';
			var buttonType = macro :VirtualButton;
			var buttonExpr = macro new VirtualButton(0, 0);

			fields.push({
				name: buttonName,
				access: [APublic],
				kind: FVar(buttonType, buttonExpr),
				pos: Context.currentPos()
			});
		}

		return fields;
	}

	public static macro function createExtraVPadButtons(extraButtons:Int):Array<Field> {
		var fields = Context.getBuildFields();

		for (i in 1...extraButtons + 1) {
			var buttonName = 'buttonExtra$i';
			var buttonType = macro :MobileButton;
			var buttonExpr = macro new MobileButton(0, 0);

			fields.push({
				name: buttonName,
				access: [APublic],
				kind: FVar(buttonType, buttonExpr),
				pos: Context.currentPos()
			});
		}

		return fields;
	}

	public static macro function createVPadButtons(letters:Array<String>):Array<Field> {
		var fields = Context.getBuildFields();
		var typePath:ComplexType = TPath({ pack: [], name: "MobileButton" });

		for (letter in letters) {
			var varName = "button" + letter.toUpperCase();
			fields.push({
				name: varName,
				access: [APublic],
				kind: FVar(
					typePath,
					macro new MobileButton(0, 0)
				),
				pos: Context.currentPos()
			});
		}
		
		return fields;
	}
}
#end