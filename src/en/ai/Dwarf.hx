package en.ai;

class Dwarf extends en.Ai {
	public static var ALL : Array<Dwarf> = [];

	public function new(x,y) {
		super(x,y);

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
		return super.getSpeed()*1.5;
	}

	var atkB = false;
	override function updateAi() {
		super.updateAi();

		if( canAct() )
		for(e in Mob.ALL)
			if( e.isAlive() && distCase(e)<=1 ) {
				dir = dirTo(e);
				chargeAction("atk", 0.18, function() {
					spr.anim.play(atkB ? "d_atkB" : "d_atkA").setSpeed(0.2);
					atkB = !atkB;
					game.camera.shakeS(0.2,0.4);
					game.camera.bump(dir*4,0);
					e.hit(1, this);
					fx.blood(e.headX, e.headY, angTo(e));
					bumpEnt(e, 0.2);
					lockAiS(0.3);
				});
				break;
			}
	}
}