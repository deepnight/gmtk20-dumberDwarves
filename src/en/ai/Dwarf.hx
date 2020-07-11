package en.ai;

class Dwarf extends en.Ai {
	public static var ALL : Array<Dwarf> = [];

	public function new(x,y) {
		super(x,y);

		initLife(5);
		ALL.push(this);
		weight = 8;

		spr.anim.registerStateAnim("d_atk_charge", 1, 0.15, function() return isChargingAction("atk") );
		spr.anim.registerStateAnim("d_walk", 1, 0.15, function() return isWalking() );
		spr.anim.registerStateAnim("d_idle", 0, 0.1);
		// spr.anim.registerStateAnim("a_walk", 1, 0.15, function() return isWalking() );
		// spr.anim.registerStateAnim("a_idle", 0, 0.1);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function getSpeed():Float {
		return super.getSpeed()*1.7;
	}

	var atkA = true;
	override function updateAi() {
		super.updateAi();

		// Attack mobs
		if( canAct() )
			for(e in Mob.ALL)
				if( e.isAlive() && distCase(e)<=1.5 ) {
					dir = dirTo(e);
					dx*=0.8;
					dy*=0.8;
					chargeAction("atk", 0.07, function() {
						spr.anim.play(atkA ? "d_atkA" : "d_atkB").setSpeed(0.2);
						e.hit(1, this);
						if( atkA && path.length==0 ) {
							dx += Math.cos(angTo(e))*0.05;
							dy += Math.sin(angTo(e))*0.05;
						}
						else
							bumpEnt(e, rnd(0.08,0.09));

						game.camera.shakeS(0.2,0.4);
						game.camera.bump(dir*4,0);
						fx.blood(e.headX, e.headY, angTo(e));
						fx.bloodImpact(e.headX, e.headY, angTo(e));

						lockAiS(atkA ? 0.1 : 0.3);
						cd.setS("resetAtk",0.7);
						atkA = !atkA;
					});
					break;
				}
	}

	override function update() {
		super.update();

		if( atkA && !cd.has("resetAtk") )
			atkA = true;
	}
}