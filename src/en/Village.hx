package en;

class Village extends Entity {

	public function new(x,y) {
		super(x,y);

		team = Red;

		var g = new h2d.Graphics(spr);
		g.beginFill(0xc3773d);
		g.drawRect(-8,-16,16,16);
	}
}
