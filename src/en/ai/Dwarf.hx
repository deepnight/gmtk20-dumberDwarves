package en.ai;

class Dwarf extends en.Ai {
	public static var ALL : Array<Dwarf> = [];
	var bubble : Null<h2d.Object>;

	public function new(x,y) {
		super(x,y);

		initLife(5);
		ALL.push(this);
		weight = 8;
		detectRadius = 9;
		atkRange = 1.5;

		spr.anim.registerStateAnim("d_hit", 10, 0.15, function() return hasAffect(Stun) );
		spr.anim.registerStateAnim("d_atk_charge", 3, 0.15, function() return isChargingAction("atk") );
		spr.anim.registerStateAnim("d_act", 2, 0.15, function() return isChargingAction() );
		spr.anim.registerStateAnim("d_walk", 1, rnd(0.11,0.15), function() return isWalking() );
		spr.anim.registerStateAnim("d_idle", 0, 0.1);
	}

	override function dispose() {
		super.dispose();

		ALL.remove(this);

		if( bubble!=null ) {
			bubble.remove();
			bubble = null;
		}
	}

	function setBubble(iconId:String) {
		clearBubble();
		bubble = new h2d.Object();
		game.scroller.add(bubble, Const.DP_UI);

		var bg = Assets.tiles.getBitmap("bubble",0, 0.5,1, bubble);

		var icon = Assets.tiles.getBitmap(iconId,0, 0.5, 0.5, bubble);
		// icon.x = Std.int( bg.tile.width*0.5 );
		icon.y = Std.int( -bg.tile.height*0.5 - 2 );
		icon.setScale(0.66);
		icon.alpha = 0.7;
		icon.smooth = true;
	}

	function clearBubble() {
		if( bubble!=null ) {
			bubble.remove();
			bubble = null;
		}
	}

	override function onDamage(dmg:Int, from:Null<Entity>) {
		super.onDamage(dmg, from);

		setAffectS(Stun,0.7);

		if( from!=null )
			bumpFrom(from, 0.04);
	}

	override function getSpeed():Float {
		return super.getSpeed();
	}


	function takeDecision() {
		var dh = new dn.DecisionHelper(Entity.ALL);
		dh.keepOnly( function(e) return e.isAlive() && e.is(Item) );
		dh.keepOnly( function(e) return distCase(e)<=detectRadius && sightCheckEnt(e) );
		dh.useBest( function(e) {
			if( e.is(Item) ) {
				doTask( Grab(e.as(Item).type) );
			}
		});
	}

	override function doTask(t:Task) {
		if( t==Idle && task!=Idle )
			cd.setS("decision", rnd(1,2));

		super.doTask(t);

		clearBubble();
		switch task {
			case Idle:
			case Grab(it):
				setBubble("i_"+Std.string(it));

			case AttackDwarf(e):
		}
	}

	override function updateAi() {
		super.updateAi();

		switch task {
			case Idle:
				if( !cd.has("pickIdlePt") ) {
					cd.setS("pickIdlePt",rnd(1,1.5));
					var dh = new dn.DecisionHelper( dn.Bresenham.getDisc(cx,cy, 4) );
					dh.keepOnly( function(pt) return !level.hasCollision(pt.x,pt.y) && sightCheckCase(pt.x,pt.y) );
					dh.score( function(pt) return rnd(0,1,true) + distCaseFree(pt.x,pt.y)*0.5 );
					for(d in ALL)
						if( d!=this && distCase(d)<=5 )
							dh.score( function(pt) return d.distCaseFree(pt.x,pt.y)*0.08 );

					dh.useBest( function(pt) {
						goto(pt.x,pt.y);
					});
				}

				if( !cd.hasSetS("decision", 1) )
					takeDecision();

			case Grab(it):
			case AttackDwarf(e):
		}
	}


	var atkA = true;
	override function chargeAtk(e) {
		super.chargeAtk(e);

		chargeAction("atk", 0.12, function() {
			spr.anim.play(atkA ? "d_atkA" : "d_atkB").setSpeed(0.2);
			lockAiS(atkA ? 0.2 : 0.5);
			cd.setS("resetAtk",0.7);
			atkA = !atkA;

			if( !e.isAlive() || distCase(e)>atkRange*2 )
				return;

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
		});
	}

	override function getAttackables() : Array<Entity> {
		return cast Mob.ALL;
	}

	override function postUpdate() {
		super.postUpdate();
		if( bubble!=null ) {
			bubble.x = Std.int( headX );
			bubble.y = Std.int( headY-3 - M.fabs( Math.cos(ftime*0.1)*2 ) );
		}
	}

	override function update() {
		super.update();

		if( atkA && !cd.has("resetAtk") )
			atkA = true;
	}
}