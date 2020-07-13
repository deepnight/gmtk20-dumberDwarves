package en;

class Label extends Entity {
	public function new(x,y, str:String) {
		super(x,y);

		spr.set("empty");
		var tf = new h2d.Text(Assets.fontTiny, spr);
		tf.text = str;
		tf.maxWidth	= 150;
		tf.x = Std.int(-tf.textWidth*0.5);
		tf.y = Std.int(-tf.textHeight );
	}

	override function postUpdate() {
		super.postUpdate();
		spr.visible = !Console.ME.hasFlag("screen");
	}
}