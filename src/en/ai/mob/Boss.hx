package en.ai.mob;

class Boss extends en.ai.Mob {
	public static var ME : Boss;

	public function new(x,y) {
		super(x,y);
		ME = this;
		initLife(9999);
		atkRange = 2;
		weight = 1;
		sprScaleX = sprScaleY = 3;

		spr.anim.registerStateAnim("a_atk_charge", 2, 0.15, function() return isChargingAction("atk") );
		spr.anim.registerStateAnim("a_walk", 1, 0.15, function() return isWalking() );
		spr.anim.registerStateAnim("a_idle", 0, 0.1);
	}

	override function dispose() {
		super.dispose();
		if( ME==this )
			ME = null;
	}

	override function getSpeed():Float {
		return super.getSpeed()*0.55;
	}

	override function onBeforePhysics() {
		super.onBeforePhysics();
		bdx*=Math.pow(0.1,tmod);
		bdy*=Math.pow(0.1,tmod);
	}

	override function chargeAtk(e:Entity) {
		super.chargeAtk(e);

		bumpTo(e, 0.05);
		chargeAction("atk", 2, function() {
			dir = dirTo(e);

			spr.anim.play("a_atk").setSpeed(0.2);
			lockAiS(1);

			var a = angTo(e);
			fx.bossAtk(footX+Math.cos(a)*atkRange*Const.GRID, footY+Math.sin(a)*atkRange*Const.GRID);
			game.camera.shakeS(0.4, 1);

			if( !e.isAlive() || distCase(e)>atkRange*2 || !sightCheckEnt(e) )
				return;

			lockAtk(1);
			e.hit(99999, this);
			game.addSlowMo("boss",0.5, 0.3);
			fx.bloodImpact(e.headX, e.headY, angTo(e));
		});
	}


	override function updateAggro() {
		if( Dwarf.ALL.length==0 )
			return;

		if( task==Idle )
			doTask( AttackDwarf(Dwarf.ALL[0]) );

		if( !cd.hasSetS("aggroBoss", 1) ) {
			var dh = new dn.DecisionHelper(Dwarf.ALL);
			dh.keepOnly( function(e) return e.isAlive() );
			dh.score( function(e) return -distCase(e)*0.2 );
			dh.score( function(e) return sightCheckEnt(e) ? 3 : 0 );
			dh.useBest( function(e) {
				doTask( AttackDwarf(e) );
			});
		}
	}

	override function showTaskFocus(e:Entity) {
		super.showTaskFocus(e);
		fx.focus(this, e, 0xff0000);
	}


	override function postUpdate() {
		super.postUpdate();
		if( isChargingAction("atk") && !cd.has("blinkBoss") ) {
			if( getActionRemainingSec("atk")<=1 ) {
				blink(0xffff00, 0.1);
				cd.setS("blinkBoss", 0.15);
			}
			// else {
				// blink(0xff0000);
				// cd.setS("blinkBoss", 0.4);
			// }
		}
	}

}