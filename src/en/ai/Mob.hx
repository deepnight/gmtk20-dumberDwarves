package en.ai;

class Mob extends en.Ai {
	public static var ALL : Array<Mob> = [];

	public function new(x,y) {
		super(x,y);
		ALL.push(this);
		initLife(2);

		spr.anim.registerStateAnim("a_atk_charge", 2, 0.15, function() return isChargingAction("atk") );
		spr.anim.registerStateAnim("a_walk", 1, 0.15, function() return isWalking() );
		spr.anim.registerStateAnim("a_idle", 0, 0.1);
	}

	override function onDamage(dmg:Int, from:Null<Entity>) {
		super.onDamage(dmg, from);
		lockAiS(rnd(0.6,0.8));
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


		// Attack player
		if( canAct() )
			for(e in Dwarf.ALL)
				if( e.isAlive() && distCase(e)<=0.8 ) {
					dir = dirTo(e);
					dx*=0.5;
					dy*=0.5;
					bumpTo(e, 0.05);
					chargeAction("atk", 0.5, function() {
						spr.anim.play("a_atk").setSpeed(0.2);
						lockAiS(1);


						if( !e.isAlive() || distCase(e)>2 )
							return;
						e.hit(1, this);
						// bumpEnt(e, rnd(0.08,0.09));

						// fx.blood(e.headX, e.headY, angTo(e));
						fx.bloodImpact(e.headX, e.headY, angTo(e));

					});
					break;
				}
	}
}