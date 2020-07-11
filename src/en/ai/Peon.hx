package en.ai;

class Peon extends en.Ai {
	public function new(x,y, t:Team) {
		super(x,y);
		team = t;

		var g = new h2d.Graphics(spr);
		g.beginFill(team==Red ? 0xff0000 : 0x0000ff);
		g.lineStyle(1,0x0);
		g.drawRect(-3,-16,6,16);
	}


	override function updateAi() {
		super.updateAi();
	}
}