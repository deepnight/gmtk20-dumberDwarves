package en;

class Ai extends Entity {
	public static var ALL : Array<Ai> = [];

	var task : Task;
	var detectRadius = 5;
	var path : Array<CPoint> = [];
	var origin : CPoint;
	var atkRange = 1.0; // case

	private function new(x,y) {
		super(x,y);

		origin = this.makePoint();
		Game.ME.scroller.add(spr, Const.DP_AI);
		spr.filter = new dn.heaps.filter.PixelOutline();

		ALL.push(this);
		task = Idle;
		enableShadow();

		doTask(Idle);
	}

	public function isWalking() {
		return canAct() && ( M.fabs(dx)>=0.004 || M.fabs(dy)>=0.004 );
	}

	public function canDetect(e:Entity) {
		return isAlive() && e.isAlive() && distCase(e)<=detectRadius;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
		origin = null;
		path = null;
	}

	function cancelPath() {
		path = [];
	}

	public function doTask(t:Task) {
		cancelPath();
		task = t;
	}

	public function suggestTask(t:Task) {
		if( task==Idle )
			doTask(t);
	}

	override function onWrathOfGod(x:Int,y:Int) {
		super.onWrathOfGod(x,y);
		doTask( Idle );
	}

	public function goto(tcx:Int, tcy:Int) {
		path = game.level.pf.getPath(cx,cy, tcx,tcy);

	}

	function updateAi() {
		// Run task
		switch task {

			case Idle:

			case Grab(it):
				if( !isCarryingItem(it) ) {
					// Seek target
					releaseCarriedEnt();
					cancelPath();
					var dh = new dn.DecisionHelper(Item.ALL);
					dh.keepOnly( function(i) return i.isAlive() && i.type==it );
					dh.remove( function(i) return i.isCarried );
					dh.score( function(i) return -distCase(i) );
					if( dh.countRemaining()<=0 )
						doTask(Idle);
					dh.useBest( function(i) {
						goto(i.cx, i.cy);
						if( distCase(i)<=0.8 ) {
							chargeAction("gather", 1, function() {
								switch it {
									case Gem: carry(i);
									case Bait: i.consume(this);
								}
							});
						}
					});
				}
				else {
					var c = en.Cart.ME;
					goto(c.cx, c.cy);
					if( distCase(c)<=1 )
						chargeAction("drop", 1, function() {
							c.dropGem();
							carriedEnt.destroy();
							doTask(Idle);
						});
				}

			case AttackDwarf(e):
				if( distCase(e)>2 || !sightCheckEnt(e) )
					goto(e.cx, e.cy);
				else {
					cancelPath();
					var a = angTo(e);
					var spd = getSpeed();
					dx += Math.cos(a) * spd * tmod;
					dy += Math.sin(a) * spd * tmod;
				}
		}


		// Movement
		// if( moveTarget.cx>=0 && moveTarget.distCase(this)>0.4 && !cd.has("stepLock") ) {
		// 	fx.markerFree(moveTarget.footX, moveTarget.footY, 0.5);
		// 	var a = Math.atan2(moveTarget.footY-footY, moveTarget.footX-footX);
		// 	var spd = 0.09;
		// 	spd *= switch task {
		// 		case Idle: 0.6;
		// 		case _: 1;
		// 	}
		// 	dir = dx>0 ? 1 : dx<0 ? -1 : dir;
		// 	dx += Math.cos(a)*spd;
		// 	dy += Math.sin(a)*spd;
		// 	cd.setS("stepLock",0.4);
		// }

		// Remove reached path nodes
		while( path.length>0 && distCaseFree(path[0].cx, path[0].cy)<=0.3 )
			path.shift();

		// Follow path
		if( path.length>0 && !cd.has("stepLock") ) {
			var pt = path[0];
			dir = pt.footX<footX ? -1 : 1;
			var a = Math.atan2(pt.footY-footY, pt.footX-footX);
			var spd = getSpeed()*10;
			dx += Math.cos(a)*spd;
			dy += Math.sin(a)*spd;
			cd.setS("stepLock",0.4);
		}
	}

	function getAttackables() : Array<Entity> {
		return [];
	}

	function chargeAtk(e:Entity) {}

	function updateAutoAttack() {
		for(e in getAttackables())
			if( e.isAlive() && distCase(e)<=atkRange ) {
				if( isChargingAction() ) {
					cancelAction();
					if( !canAct() )
						return;
				}

				dir = dirTo(e);
				dx*=0.8;
				dy*=0.8;
				chargeAtk(e);
				break;
			}
	}

	function getSpeed() {
		return 0.005;
	}

	inline function lockAtk(s:Float) {
		cd.setS("atkLock",s);
	}

	override function update() {
		super.update();

		if( canAct() )
			updateAi();

		if( !cd.has("atkLock") && !isChargingAction("atk") )
			updateAutoAttack();
	}
}
