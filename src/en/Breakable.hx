package en;

class Breakable extends Entity {
	public static var ALL : Array<Breakable> = [];

	public function new(x,y) {
		super(x,y);
		initLife(3);
		spr.set("crate");
		ALL.push(this);
		weight = 3;
		enableShadow();
		bumpFrict*=0.8;
		toBack();
	}

	override function onDie(?from:Entity) {
		super.onDie(from);
		fx.dirtExplosion(centerX, centerY, 0xb57a40);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}
}