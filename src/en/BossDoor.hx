package en;

class BossDoor extends Entity {
	public static var ME : BossDoor;
	var tf : h2d.Text;
	var timeS : Float;

	public function new(x,y, t:Float) {
		super(x,y);

		timeS = t+1;
		ME = this;
		spr.set("cart");
		game.scroller.add(spr, Const.DP_BG);

		tf = new h2d.Text(Assets.fontTiny, spr);
	}

	override function dispose() {
		super.dispose();
		if( ME==this )
			ME = null;
	}

	override function update() {
		super.update();

		if( timeS>0 ) {
			timeS -= tmod/Const.FPS;
			tf.text = Std.string( Std.int(timeS) );
			if( timeS<=0 ) {
				var b = new en.ai.mob.Boss(cx,cy+1);
				b.dz = -0.2;
				b.dy = 0.06;
				b.lockAiS(2);
			}
		}
		else
			tf.visible = false;
	}
}