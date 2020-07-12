package en;

class MobGen extends Entity {
	public static var ALL : Array<MobGen> = [];

	var children : Array<en.ai.Mob> = [];
	public var maxChildren = 5;
	public var perSpawn = 2;
	public var delay = 5.;

	public function new(x,y) {
		super(x,y);
		ALL.push(this);
		spr.set("gen");
		enableShadow();
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

	override function postUpdate() {
		super.postUpdate();
		spr.alpha = 0.6;
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
		if( !cd.hasSetS("spawn",delay) ) {
			var n = perSpawn;
			dz = -rnd(0.05,0.12);
			while( n-->0 && children.length<maxChildren )
				children.push( spawn() );
		}
	}
}