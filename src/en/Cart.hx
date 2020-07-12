package en;

class Cart extends Entity {
	public static var ME : Cart;

	public var score : Int;

	public function new(x,y) {
		super(x,y);
		spr.set("cart");
		ME = this;
		weight = 20;
		enableShadow();
	}

	public function onDropGem() {
		score++;
		popText("+1 GEM");
		game.refillBaits();
		if( game.countRemainingGems()>0 )
			game.announce("Gem stolen!", "Food restored. "+game.countRemainingGems()+" gems remaining", 0x1ebae1, false);
		else
			game.announce("Level wiped!", 0xffcc00, true);

		dz = -0.08;

		var g = new h2d.Bitmap(Assets.tiles.getTile("i_Gem"), spr);
		g.tile = g.tile.sub(0,0, g.tile.width, Std.int( g.tile.height*rnd(0.7,1) ));
		g.tile.setCenterRatio(0.5,1);
		g.x = 1 + irnd(0,6,true);
		g.y = -7;
		g.setScale( rnd(0.5,0.8) );
	}

	override function onBeforePhysics() {
		super.onBeforePhysics();
		dy = 0;
		bdy = 0;
	}

	override function postUpdate() {
		super.postUpdate();
		if( score>0 )
			fx.shine(this, 0x0088ff);
	}

	override function dispose() {
		super.dispose();
		if( ME==this )
			ME = null;
	}
}