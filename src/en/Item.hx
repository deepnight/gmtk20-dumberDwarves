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

		var g = new h2d.Graphics(spr);
		g.beginFill(switch type {
			case Gem: 0xffcc00;
		});
		g.drawCircle(0, -Const.GRID*0.5, Const.GRID*0.5);
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

	override function update() {
		super.update();

		// switch type {
		// 	case Gem: suggestTaskAround( Grab(type) );
		// }
	}
}

