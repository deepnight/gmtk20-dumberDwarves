package en.ai;

class Mob extends en.Ai {
	public static var ALL : Array<Mob> = [];

	public function new(x,y) {
		super(x,y);
		ALL.push(this);
		initLife(2);

		spr.anim.registerStateAnim("a_walk", 1, 0.15, function() return isWalking() );
		spr.anim.registerStateAnim("a_idle", 0, 0.1);
	}

	override function onDie(?from:Entity) {
		super.onDie(from);
		fx.gibs(centerX, centerY, from.angTo(this), 0x748954);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function getSpeed():Float {
		return super.getSpeed()*2;
	}


	override function updateAi() {
		super.updateAi();

		if( task==Idle ) {
			for(e in Dwarf.ALL)
				if( distCase(e)<=6 && sightCheckEnt(e) )
					doTask( AttackDwarf(e) );
		}
	}
}