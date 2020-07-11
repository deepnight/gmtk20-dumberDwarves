package en;

class Village extends Entity {
	public static var RED : Village;
	public static var BLUE: Village;

	public function new(x,y, t:Team) {
		super(x,y);

		team = t;
		switch team {
			case Red: RED = this;
			case Blue: BLUE = this;
		}

		var g = new h2d.Graphics(spr);
		g.beginFill(team==Red ? 0xff0000 : 0x0000ff);
		g.drawRect(-8,-16,16,16);
	}

	override function dispose() {
		super.dispose();

		if( RED==this )
			RED = null;

		if( BLUE==this )
			BLUE = null;
	}
}
