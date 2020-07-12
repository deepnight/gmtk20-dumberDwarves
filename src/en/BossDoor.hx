package en;

class BossDoor extends Entity {
	public static var ME : BossDoor;
	var tf : h2d.Text;
	var timeS : Float;

	public function new(x,y, t:Float) {
		super(x,y);

		hei = Const.GRID*2;
		weight = 100;
		timeS = t+1;
		ME = this;
		spr.set("bossDoor");
		enableShadow();

		tf = new h2d.Text(Assets.fontTiny, spr);
	}

	override function dispose() {
		super.dispose();
		if( ME==this )
			ME = null;
	}

	override function postUpdate() {
		super.postUpdate();

		if( !cd.hasSetS("fx",0.1) )
			fx.bossDoor(this, timeS<=3);
	}

	override function update() {
		super.update();

		if( timeS>0 ) {
			timeS -= tmod/Const.FPS;
			tf.text = Std.string( Std.int(timeS) );
			tf.x = Std.int( -tf.textWidth*0.5-1 );
			tf.y = -20;
			if( timeS<=10 && !cd.hasSetS("jump",1) )
				dz = -0.05;

			if( timeS<=0 ) {
				var b = new en.ai.mob.Boss(cx,cy+1);
				b.dz = -0.2;
				b.dy = 0.06;
				b.lockAiS(2);
				game.announce("Boss has arrived!!", 0xff0000, true);
			}
		}
		else
			tf.visible = false;
	}
}