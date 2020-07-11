package en;

class Ai extends Entity {
	public static var ALL : Array<Ai> = [];

	var task : Task;
	var moveTarget : CPoint;
	var badThings : Array<JudgeableThing> = [];
	var detectRadius = 4;

	private function new(x,y) {
		super(x,y);

		Game.ME.scroller.add(spr, Const.DP_AI);
		spr.filter = new dn.heaps.filter.PixelOutline();

		ALL.push(this);
		task = Idle;
		moveTarget = new CPoint(-1,-1);
		initLife(3);

		doTask(Idle);
	}

	public function isWalking() {
		return canAct() && moveTarget.cx>=0 && moveTarget.distPx(this)>=5;
	}

	public function canDetect(e:Entity) {
		return isAlive() && e.isAlive() && distCase(e)<=detectRadius;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	function cancelMove() {
		moveTarget.set(-1,-1);
	}

	public function doTask(t:Task) {
		if( isTaskBad(t) )
			return;

		cancelMove();
		task = t;
	}

	public function suggestTask(t:Task) {
		if( task==Idle && !isTaskBad(t) ) {
			switch t {
				case Idle:
				case Gather(it):
					switch it {
						case Coin:
						case Food: if( life>=maxLife ) return; // useless
					}

				case JudgeOther(e):
				case Flee(x, y, distCase):
			}
			doTask(t);
		}
	}

	function isTaskBad(t:Task) {
		if( isJudgeableThingBad( DoingTask(t.getIndex()) ) )
			return true;

		switch t {
			case Idle:
			case Flee(_):

			case JudgeOther(e):

			case Gather(it):
				if( isJudgeableThingBad(CarryingItem(it)) )
					return true;
		}

		return false;
	}

	function isDoingSomethingBad(e:Ai) {
		if( !isTaskBad(e.task) )
			return false;

		switch e.task {
			case Idle:
			case Flee(_):

			case Gather(it):
				return e.isCarryingItem(it);

			case JudgeOther(e):
		}
		return true;
	}

	override function onWrathOfGod(x:Int,y:Int) {
		super.onWrathOfGod(x,y);

		switch task {
			case Idle:
			case Flee(_):

			case JudgeOther(e):
				registerBadThing( DoingTask(task.getIndex()) );

			case Gather(it):
				registerBadThing( CarryingItem(it) );
		}

		doTask( Flee(x,y, 4) );
	}

	function registerBadThing(e:JudgeableThing) {
		for(bad in badThings)
			if( bad.equals(e) )
				return;

		popText(e+" is bad.");
		badThings.push(e);
	}

	function isJudgeableThingBad(e:JudgeableThing) {
		for(bad in badThings)
			if( bad.equals(e) )
				return true;
		return false;
	}

	function getTaskDesc(t:Task) {
		return switch t {
			case Idle: "Idling";
			case Flee(_): "Fleeing";
			case Gather(it): Std.string(it);
			case JudgeOther(e): "Judging";
		}
	}

	function updateAi() {
		// Run task
		if( isTaskBad(task) )
			doTask(Idle);

		switch task {

			case Idle:
				releaseCarriedEnt();
				if( !cd.has("pickIdlePt") ) {
					cd.setS("pickIdlePt",3);
					cd.setS("pickIdlePt",rnd(1,3));
					moveTarget.setPixel(
						footX + rnd(0,Const.GRID*2,true),
						footY + rnd(0,Const.GRID*2,true)
					);
				}

				for(e in Ai.ALL)
					if( e!=this && canDetect(e) && isDoingSomethingBad(e) ) {
						doTask( JudgeOther(e) );
						break;
					}

			case JudgeOther(e):
				if( !cd.hasSetS("judgeFx",0.3) )
					fx.angry(this);

				if( !e.isAlive() || !isDoingSomethingBad(e) )
					doTask(Idle);
				else {
					moveTarget.setEntity(e);
					if( distCase(e)<=1 ) {
						e.hit(1, this);
						popText(getTaskDesc(e.task)+" is BAD!", 0xff0000);
						e.doTask( Flee(footX, footY, 5) );
						doTask( Flee(e.footX, e.footY, 2) );
					}
				}

			case Flee(x,y, d):
				var a = Math.atan2(footY-y, footX-x) + rnd(0,1,true);
				moveTarget.setPixel( footX+Math.cos(a)*d*Const.GRID, footY+Math.sin(a)*d*Const.GRID );
				if( distPxFree(x,y)>=d*Const.GRID )
					doTask(Idle);

			case Gather(it):
				if( !isCarryingItem(it) ) {
					// Seek target
					releaseCarriedEnt();
					cancelMove();
					var dh = new dn.DecisionHelper(Item.ALL);
					dh.keepOnly( function(i) return i.isAlive() && i.type==it );
					dh.remove( function(i) return i.isCarried && i.getCarrier().team==team );
					dh.score( function(i) return -distCase(i) );
					if( dh.countRemaining()<=0 )
						doTask(Idle);
					dh.useBest( function(i) {
						moveTarget.setEntity(i);
						if( distCase(i)<=0.3 ) {
							chargeAction("gather", 1, function() {
								switch it {
									case Coin: carry(i);

									case Food:
										if( life<maxLife )
											life++;
										i.destroy();
										doTask(Idle);
								}

							});
						}
					});
				}
				else {
					// Go back home
					moveTarget.setEntity( getTeamVillage() );
					if( moveTarget.distCase(this)<=0.1 )
						chargeAction("drop", 1, function() {
							getTeamVillage().addTreasure(1);
							carriedEnt.destroy();
						});
				}
		}


		// Movement
		if( moveTarget.cx>=0 && moveTarget.distCase(this)>=0.15 && !cd.has("stepLock") ) {
			var a = Math.atan2(moveTarget.footY-footY, moveTarget.footX-footX);
			var spd = 0.04;
			spd *= switch task {
				case Idle: 0.6;
				case JudgeOther(e): 1.1;
				case Flee(_): 2;
				case _: 1;
			}
			dir = dx>0 ? 1 : -1;
			dx += Math.cos(a)*spd;
			dy += Math.sin(a)*spd;
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

		if( canAct() )
			updateAi();
	}
}
