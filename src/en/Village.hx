package en;

class Village extends Entity {

	public function new(x,y, t:Team) {
		super(x,y);

		team = t;

		var g = new h2d.Graphics(spr);
		g.beginFill(team==Red ? 0xff0000 : 0x0000ff);
		g.drawRect(-8,-16,16,16);
	}
}
