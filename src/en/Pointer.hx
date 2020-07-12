package en;

class Pointer extends Entity {
	public function new(x,y) {
		super(x,y);

		spr.set("pointer");
	}

	override function update() {
		super.update();

		if( !cd.hasSetS("jump", 1) )
			dz = -0.1;
	}
}