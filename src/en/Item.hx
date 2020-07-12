package en;

class Item extends Entity {
	public static var ALL : Array<Item> = [];

	public var type : ItemType;
	var bombTimerS = 0.;

	public function new(x,y, t:ItemType) {
		super(x,y);

		if( t==null )
			throw "Unknown item type";

		game.scroller.add(spr, Const.DP_FRONT);
		ALL.push(this);
		type = t;
		enableShadow();
		hei = Const.GRID*1.05;

		if( type!=Gem )
			spr.filter = new dn.heaps.filter.PixelOutline();

		spr.set("i_"+type.getName());
		cd.setS("jump",rnd(0,1));
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	public function consume(by:en.Ai) {
		switch type {
			case Gem:
			case Bomb:

			case BaitFull:
				type = BaitPart;
				spr.set("i_"+type.getName());
				dz = -0.1;
				blink(0xffcc00);
				by.prohibit(this);

			case BaitPart:
				fx.emptyBone(this);
				destroy();
		}
	}

	override function postUpdate() {
		super.postUpdate();
		if( type==Gem && !cd.hasSetS("shine",0.1) )
			fx.shine(this, 0x78deff);
	}

	override function update() {
		super.update();

		if( !isCarried && type==Gem && zr==0 && !cd.hasSetS("jump",1) )
			dz = -0.05;

		if( type==Bomb && isCarried ) {
			bombTimerS += tmod/Const.FPS;
			if( !cd.hasSetS("warn",0.2) )
				blink(0xffffff, 0);

			if( bombTimerS>=2 ) {
				game.announce("Dwarf obliterated", 0xff0000);
				getCarrier().hit(99,this);
				fx.flashBangS(0xffcc00, 0.5, 0.5);
				game.camera.shakeS(2, 0.2);
				fx.explosion(centerX, centerY);
				destroy();
			}
		}
	}
}

