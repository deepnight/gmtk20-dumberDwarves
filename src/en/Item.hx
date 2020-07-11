package en;

class Item extends Entity {

	public function new(x,y, t:ItemType) {
		super(x,y);

		var g = new h2d.Graphics(spr);
		g.beginFill(0xffcc00);
		g.drawCircle(0, -Const.GRID*0.5, Const.GRID*0.5);
	}
}
