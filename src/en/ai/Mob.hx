package en.ai;

class Mob extends en.Ai {
	public static var ALL : Array<Mob> = [];

	public function new(x,y) {
		super(x,y);
		ALL.push(this);
		initLife(3);
		detectRadius = 5;
		atkRange = 0.8;
		weight = 1;

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
				if( distCase(e)<=detectRadius && sightCheckEnt(e) ) {
					// TODO alert friends
					doTask( AttackDwarf(e) );
				}
		}
	}

	override function chargeAtk(e:Entity) {
		super.chargeAtk(e);

		bumpTo(e, 0.05);
		chargeAction("atk", 0.5, function() {
			dir = dirTo(e);

			spr.anim.play("a_atk").setSpeed(0.2);
			lockAiS(1);


			if( !e.isAlive() || distCase(e)>2 )
				return;

			lockAtk(1);
			e.hit(1, this);
			fx.bloodImpact(e.headX, e.headY, angTo(e));
		});
}

	override function getAttackables() {
		return cast Dwarf.ALL;
	}
}