package en;

class MobGen extends Entity {
	public static var ALL : Array<MobGen> = [];

	var children : Array<en.ai.Mob> = [];
	public var maxChildren = 5;
	public var perSpawn = 2;

	public function new(x,y) {
		super(x,y);
		ALL.push(this);
		spr.set("cart");
		game.scroller.add(spr, Const.DP_BG);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
		children = null;
	}

	function spawn() {
		var e = new en.ai.mob.Goblin(cx,cy);
		e.dz = -rnd(0.2,0.4);
		e.dx = rnd(0,0.2,true);
		e.dy = rnd(0,0.2,true);
		return e;
	}

	override function update() {
		super.update();

		// GC
		var i = 0;
		while( i<children.length )
			if( !children[i].isAlive() )
				children.splice(i,1);
			else
				i++;

		// Spawn
		if( !cd.hasSetS("spawn",1) ) {
			var n = perSpawn;
			while( n-->0 && children.length<maxChildren )
				children.push( spawn() );
		}
	}
}