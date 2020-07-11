package en;

class Peon extends Entity {

	public function new(x,y) {
		super(x,y);

		team = Red;

		var g = new h2d.Graphics(spr);
		g.beginFill(0x00ff00);
		g.lineStyle(1,0x0);
		g.drawRect(-3,-16,6,16);
	}
}
