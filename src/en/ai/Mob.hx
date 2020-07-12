package en.ai;

class Mob extends en.Ai {
	public static var ALL : Array<Mob> = [];

	private function new(x,y) {
		super(x,y);
		ALL.push(this);
		detectRadius = 7;
		weight = 1;
	}

	override function onDamage(dmg:Int, from:Null<Entity>) {
		super.onDamage(dmg, from);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}


	override function updateAi() {
		super.updateAi();

		// Aggro dwarf
		if( task==Idle ) {
			for(e in Dwarf.ALL)
				if( distCase(e)<=detectRadius && sightCheckEnt(e) ) {
					for(m in ALL)
						if( m!=this && m.isAlive() && distCase(m)<=4 && sightCheckEnt(m) )
							m.doTask( AttackDwarf(e) );
					doTask( AttackDwarf(e) );
				}
		}
	}

	override function getAttackables() {
		return cast Dwarf.ALL;
	}
}