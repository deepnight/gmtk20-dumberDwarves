package en;

class Ai extends Entity {
	public static var ALL : Array<Ai> = [];

	var task : Task;
	var moveTarget : CPoint;

	private function new(x,y) {
		super(x,y);

		ALL.push(this);
		task = Idle;
		moveTarget = new CPoint(-1,-1);

		doTask( Gather(Coin) );
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	function cancelMove() {
		moveTarget.set(-1,-1);
	}

	public function doTask(t:Task) {
		cancelMove();
		task = t;
	}

	function updateAi() {
		// Run task
		switch task {
			case Idle:
				if( !cd.has("pickIdlePt") ) {
					cd.setS("pickIdlePt",3);
					cd.setS("pickIdlePt",rnd(1,3));
					moveTarget.setPixel(
						footX + rnd(0,Const.GRID*2,true),
						footY + rnd(0,Const.GRID*2,true)
					);
				}

			case Gather(it):
				if( grabbedEnt==null || !grabbedEnt.is(Item) || grabbedEnt.as(Item).type!=it ) {
					// Seek target
					releaseGrab();
					cancelMove();
					var dh = new dn.DecisionHelper(Item.ALL);
					dh.keepOnly( function(i) return i.isAlive() && i.type==it );
					dh.remove( function(i) return i.isGrabbed && i.getGrabber().team==team );
					dh.score( function(i) return -distCase(i) );
					if( dh.countRemaining()<=0 )
						doTask(Idle);
					dh.useBest( function(i) {
						moveTarget.setEntity(i);
						if( distCase(i)<=0.3 ) {
							chargeAction("gather", 1, function() {
								grab(i);
							});
						}
					});
				}
				else {
					// Go back home
					moveTarget.setEntity( getTeamVillage() );
					if( moveTarget.distCase(this)<=0.1 )
						chargeAction("drop", 1, function() {
							grabbedEnt.destroy();
						});
				}
		}

		// Movement
		if( moveTarget.cx>=0 && moveTarget.distCase(this)>=0.15 && !cd.has("stepLock") ) {
			var a = Math.atan2(moveTarget.footY-footY, moveTarget.footX-footX);
			var s = 0.03;
			dir = dx>0 ? 1 : -1;
			dx += Math.cos(a)*s;
			dy += Math.sin(a)*s;
			cd.setS("stepLock",0.4);
		}

	}


	override function update() {
		super.update();

		// Circular collisions
		var repel = 0.02;
		for(e in ALL )
			if( e!=this && e.isAlive() && M.fabs(e.cx-cx)<=2 && M.fabs(e.cy-cy)<=2 ) {
				var d = distPx(e);
				var r = 16;
				if( distPx(e)<=r ) {
					var a = Math.atan2(e.footY-footY, e.footX-footX) + rnd(0,0.05,true);
					var pow = 1-d/r;
					e.dx += Math.cos(a) * repel*pow * tmod;
					e.dy += Math.sin(a) * repel*pow * tmod;

					dx += -Math.cos(a) * repel*pow * tmod;
					dy += -Math.sin(a) * repel*pow * tmod;
				}
			}

		if( !isChargingAction() )
			updateAi();
	}
}
