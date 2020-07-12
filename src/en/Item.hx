package en;

class Item extends Entity {
	public static var ALL : Array<Item> = [];

	public var type : ItemType;

	public function new(x,y, t:ItemType) {
		super(x,y);

		if( t==null )
			throw "Unknown item type";

		ALL.push(this);
		type = t;
		enableShadow();
		hei = Const.GRID*1.05;

		spr.set("i_"+type.getName());
		cd.setS("jump",rnd(0,1));
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	function suggestTaskAround(t:Task) {
		for(e in Ai.ALL)
			if( e.isAlive() && e.canDetect(this) )
				e.suggestTask(t);
	}

	public function consume(by:Entity) {
		destroy();
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
	}
}

