package en;

class Ai extends Entity {
	public static var ALL : Array<Ai> = [];

	var task : Task;
	var detectRadius = 5;
	var path : Array<CPoint> = [];
	var origin : CPoint;
	var atkRange = 1.0; // case
	var bubble : Null<h2d.Object>;
	var prohibiteds : Array<{ e:Entity, sec:Float }> = [];

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

	public function prohibit(e:Entity) {
		if( !e.isAlive() )
			return;

		for(p in prohibiteds)
			if( p.e==e )
				return;

		prohibiteds.push({
			e: e,
			sec: 10,
		});
	}

	public function isProhibited(e:Entity) {
		for(p in prohibiteds)
			if( p.e==e )
				return true;
		return false;
	}

	public function isItemProhibited(it:ItemType) {
		for(p in prohibiteds)
			if( p.e.is(Item) && p.e.as(Item).type==it )
				return true;
		return false;
	}

	public function isWalking() {
		return canAct() && ( M.fabs(dx)>=0.004 || M.fabs(dy)>=0.004 );
	}

	public function canDetect(e:Entity) {
		return isAlive() && e.isAlive() && distCase(e)<=detectRadius && sightCheckEnt(e);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
		origin = null;
		path = null;
		prohibiteds = null;


		if( bubble!=null ) {
			bubble.remove();
			bubble = null;
		}
	}

	function setBubble(iconId:String, resize=true) {
		clearBubble();
		bubble = new h2d.Object();
		game.scroller.add(bubble, Const.DP_UI);

		var bg = Assets.tiles.getBitmap("bubble",0, 0.5,1, bubble);

		var icon = Assets.tiles.getBitmap(iconId,0, 0.5, 0.5, bubble);
		icon.x = 1;
		icon.y = Std.int( -bg.tile.height*0.5 - 3 );
		if( resize )
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

	function cancelPath() {
		path = [];
	}

	public function doTask(t:Task) {
		cancelPath();
		task = t;
		clearBubble();
	}

	override function slap(x:Int,y:Int) {
		super.slap(x,y);

		switch task {
			case Idle:
				popText("??");

			case Grab(i):
				prohibit(i);
				releaseCarriedEnt(true);

			case Break(e):
				prohibit(e);

			case WaitWithItem(e):
				prohibit(e);
				releaseCarriedEnt(true);

			case BringToCart:
				if( isCarrying(Item) )
					prohibit( carriedEnt );
				releaseCarriedEnt(true);

			case AttackDwarf(e):
		}

		doTask( Idle );
	}


	function showTaskFocus(e:Entity) {}


	public function goto(tcx:Int, tcy:Int) {
		path = game.level.pf.getPath(cx,cy, tcx,tcy);

	}

	function updateAi() {
		// Run task
		switch task {

			case Idle:

			case WaitWithItem(e):
				if( carriedEnt==null )
					doTask(Idle);

			case Grab(i):
 				if( !i.isAlive() || i.isCarried && i.getCarrier()!=this ) {
					// Lost target
					doTask(Idle);
					return;
				}

				// Seek target
				releaseCarriedEnt();
				goto(i.cx,i.cy);
				showTaskFocus(i);
				setBubble("i_"+Std.string(i.type), i.type!=Bomb);
				if( distCase(i)<=0.8 ) {
					var t = switch i.type {
						case BaitFull, BaitPart: 0.4;
						case _: 1;
					}
					chargeAction("pick", t, function() {
						switch i.type {
							case Gem:
								carry(i);
								doTask(BringToCart);

							case BaitFull, BaitPart:
								i.consume(this);
								doTask(Idle);

							case Bomb:
								carry(i);
								doTask(WaitWithItem(i));
						}
					});
				}

			case BringToCart:
				if( carriedEnt==null ) {
					doTask(Idle);
					return;
				}
				var c = en.Cart.ME;
				showTaskFocus(c);
				setBubble("i_Cart", false);
				goto(c.cx, c.cy);
				if( distCase(c)<=1 )
					chargeAction("drop", 1, function() {
						carriedEnt.destroy();
						c.onDropGem();
						doTask(Idle);
					});

			case Break(e):
				setBubble("crate");
				showTaskFocus(e);
				goto(e.cx,e.cy);

			case AttackDwarf(e):
				if( !e.isAlive() ) {
					// Lost target
					doTask(Idle);
					return;
				}

				if( distCase(e)>2 || !sightCheckEnt(e) ) {
					showTaskFocus(e);
					goto(e.cx, e.cy);
				}
				else {
					cancelPath();
					var a = angTo(e);
					var spd = getSpeed();
					dx += Math.cos(a) * spd * tmod;
					dy += Math.sin(a) * spd * tmod;
				}
		}

		// Remove reached path nodes
		while( path.length>0 && distCaseFree(path[0].cx, path[0].cy)<=0.3 )
			path.shift();

		// Follow path
		if( path.length>0 && !cd.has("stepLock") ) {
			var pt = path[0];
			dir = pt.footX<footX ? -1 : 1;
			var a = Math.atan2(pt.footY-footY, pt.footX-footX);
			var spd = getSpeed()*10;
			switch task {
				case Idle:
				case Grab(e): switch e.type {
					case Gem: spd*=2;
					case BaitFull, BaitPart: spd*=1.5;
					case Bomb:
				}
				case WaitWithItem(e):
				case Break(e):
				case BringToCart: spd*=2;
				case AttackDwarf(e):
			}
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
		if( isChargingAction("atk") || !canAct() && !isChargingAction() )
			return;

		for(e in getAttackables())
			if( e.isAlive() && distCase(e)<=atkRange ) {
				cancelAction();
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

		if( !cd.has("atkLock") )
			updateAutoAttack();

		// Garbage collect prohibiteds
		var i = 0;
		while( i<prohibiteds.length ) {
			var p = prohibiteds[i];
			p.sec -= tmod/Const.FPS;

			if( !p.e.isAlive() || p.sec<=0 )
				prohibiteds.splice(i,1);
			else {
				if( !p.e.cd.hasSetS("prohibFx", 0.5) && !p.e.isCarried && ( !p.e.is(Item) || p.e.as(Item).type!=BaitPart ) )
					fx.prohibited(p.e);
				i++;
			}
		}
	}
}
