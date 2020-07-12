import h2d.Sprite;
import dn.heaps.HParticle;
import dn.Tweenie;


class Fx extends dn.Process {
	var game(get,never) : Game; inline function get_game() return Game.ME;
	var level(get,never) : Level; inline function get_level() return Game.ME.level;

	public var pool : ParticlePool;

	public var bgAddSb    : h2d.SpriteBatch;
	public var bgNormalSb    : h2d.SpriteBatch;
	public var topAddSb       : h2d.SpriteBatch;
	public var topNormalSb    : h2d.SpriteBatch;

	public function new() {
		super(Game.ME);

		pool = new ParticlePool(Assets.tiles.tile, 2048, Const.FPS);

		bgAddSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(bgAddSb, Const.DP_FX_BG);
		bgAddSb.blendMode = Add;
		bgAddSb.hasRotationScale = true;

		bgNormalSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(bgNormalSb, Const.DP_FX_BG);
		bgNormalSb.hasRotationScale = true;

		topNormalSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(topNormalSb, Const.DP_FX_FRONT);
		topNormalSb.hasRotationScale = true;

		topAddSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(topAddSb, Const.DP_FX_FRONT);
		topAddSb.blendMode = Add;
		topAddSb.hasRotationScale = true;
	}

	override public function onDispose() {
		super.onDispose();

		pool.dispose();
		bgAddSb.remove();
		bgNormalSb.remove();
		topAddSb.remove();
		topNormalSb.remove();
	}

	public function clear() {
		pool.killAll();
	}

	public inline function allocTopAdd(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(topAddSb, t, x, y);
	}

	public inline function allocTopNormal(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(topNormalSb, t,x,y);
	}

	public inline function allocBgAdd(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(bgAddSb, t,x,y);
	}

	public inline function allocBgNormal(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(bgNormalSb, t,x,y);
	}

	public inline function getTile(id:String) : h2d.Tile {
		return Assets.tiles.getTileRandom(id);
	}

	public function killAll() {
		pool.killAll();
	}

	public function markerEntity(e:Entity, ?c=0xFF00FF, ?short=false) {
		#if debug
		if( e==null )
			return;

		markerCase(e.cx, e.cy, short?0.03:3, c);
		#end
	}

	public function markerCase(cx:Int, cy:Int, ?sec=3.0, ?c=0xFF00FF) {
		#if debug
		var p = allocTopAdd(getTile("fxCircle"), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.lifeS = sec;

		var p = allocTopAdd(getTile("pixel"), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(2);
		p.lifeS = sec;
		#end
	}

	public function markerFree(x:Float, y:Float, ?sec=3.0, ?c=0xFF00FF) {
		#if debug
		var p = allocTopAdd(getTile("fxDot"), x,y);
		p.setCenterRatio(0.5,0.5);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(3);
		p.lifeS = sec;
		#end
	}

	public function markerText(cx:Int, cy:Int, txt:String, ?t=1.0) {
		#if debug
		var tf = new h2d.Text(Assets.fontTiny, topNormalSb);
		tf.text = txt;

		var p = allocTopAdd(getTile("fxCircle"), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.colorize(0x0080FF);
		p.alpha = 0.6;
		p.lifeS = 0.3;
		p.fadeOutSpeed = 0.4;
		p.onKill = tf.remove;

		tf.setPosition(p.x-tf.textWidth*0.5, p.y-tf.textHeight*0.5);
		#end
	}

	inline function collides(p:HParticle, offX=0., offY=0.) {
		return level.hasCollision( Std.int((p.x+offX)/Const.GRID), Std.int((p.y+offY)/Const.GRID) );
	}

	public function flashBangS(c:UInt, a:Float, ?t=0.1) {
		var e = new h2d.Bitmap(h2d.Tile.fromColor(c,1,1,a));
		game.root.add(e, Const.DP_FX_FRONT);
		e.scaleX = game.w();
		e.scaleY = game.h();
		e.blendMode = Add;
		game.tw.createS(e.alpha, 0, t).end( function() {
			e.remove();
		});
	}

	public function angry(e:Entity) {
		var n = irnd(3,4);
		for(i in 0...n) {
			var a = -M.PIHALF + 0.5 - 1*i/(n-1);
			var d = irnd(5,7);
			var p = allocTopNormal(getTile("pixel"), e.headX+Math.cos(a)*d, e.headY+Math.sin(a)*d);
			p.setFadeS(rnd(0.7,1), 0, 0.1);
			p.moveAwayFrom(e.headX, e.headY, rnd(0.2, 0.3));
			p.lifeS = 0.1;
		}
	}

	function _bloodPhysics(p:HParticle) {
		if( collides(p) ) {
			p.groundY = null;
			p.gy = 0;
			p.dx = p.dy = 0;
		}
	}

	function _flatten(p:HParticle) {
		p.rotation = rnd(0,0.2,true);
		p.scaleX*=1.1;
		p.scaleY*=0.8;
		p.dx*=rnd(0,0.1);
		p.dy*=rnd(0,0.1);
		p.groundY = null;
		p.gy = 0;
	}

	public function blood(x:Float, y:Float, ang:Float) {
		for(i in 0...30) {
			var a = ang+rnd(0,0.2,true);
			var p = allocBgNormal( getTile("fxGib"), x+rnd(0,5,true), y+rnd(0,5,true));
			p.setFadeS(rnd(0.7,1), 0, rnd(6,8));
			p.colorize(0x880000);
			p.rotation = rnd(0,M.PI2);
			p.setScale( rnd(1,1.5,true) );
			p.scaleMul = rnd(0.990, 0.995);

			p.moveAng(a, rnd(3,10));
			p.gy = rnd(0.2, 0.3);
			p.frict = rnd(0.90, 0.93);
			p.groundY = p.y + Math.sin(a)*rnd(20,40) + rnd(2,8);
			p.onTouchGround = _flatten;

			p.onUpdate = _bloodPhysics;
		}
	}

	public function bloodImpact(x:Float, y:Float, ang:Float) {
		for(i in 0...3) {
			var p = allocTopAdd(getTile("fxImpact"), x+rnd(0,2,true),y+4+rnd(0,2,true));
			p.setFadeS(rnd(0.3,0.8), 0, 0.07);
			p.colorize(0xffcc00);
			p.scaleY = rnd(1.2,1.7,true);
			p.rotation = ang + rnd(0,0.1,true);
			p.dsX = rnd(0.1,0.2);
			p.dsFrict = 0.9;
			p.scaleXMul = rnd(0.994, 0.996);
			p.lifeS = rnd(0.06,0.08);
		}

		for(i in 0...40) {
			var a = ang+rnd(0,0.3,true);
			var p = allocTopNormal( getTile("fxGib"), x+rnd(0,5,true), y+rnd(0,5,true));
			p.setFadeS(rnd(0.4,0.6), 0, rnd(1,2));
			p.colorize(0xdd0000);
			p.rotation = rnd(0,M.PI2);
			p.setScale(rnd(0.3,0.7,true));
			p.scaleMul = rnd(0.990, 0.995);
			p.moveAng(a, rnd(1,3));
			p.gy = rnd(0.002,0.010);
			p.frict = rnd(0.90, 0.93);
			p.lifeS = rnd(0.6,1.1);
			p.onUpdate = _bloodPhysics;
		}
	}


	public function bloodExplosion(x:Float,y:Float) {
		for(i in 0...70) {
			var p = allocBgNormal( getTile("fxGib"), x+rnd(0,5,true), y+rnd(0,5,true));
			p.setFadeS(rnd(0.4,0.6), 0, rnd(1,2));
			p.colorize(0xdd0000);
			p.rotation = rnd(0,M.PI2);
			p.setScale(rnd(0.8,1.5,true));
			p.scaleMul = rnd(0.995, 0.999);
			p.moveAwayFrom(x,y, rnd(7,9));
			p.gy = rnd(0.002,0.010);
			p.frict = rnd(0.84, 0.93);
			p.lifeS = rnd(8,10);
			p.onUpdate = _bloodPhysics;
		}

		for(i in 0...20) {
			var p = allocBgNormal( getTile("fxSplatter"), x+rnd(0,5,true), y+rnd(0,5,true));
			p.setFadeS(rnd(0.4,0.6), 0, rnd(1,2));
			p.setCenterRatio(0.3,0.5);
			p.colorize( C.interpolateInt(0x550000,0xdd0000,rnd(0,1)) );
			p.setScale(rnd(0.8,1));
			// p.scaleMul = rnd(0.995, 0.999);
			p.moveAwayFrom(x,y, rnd(1,2));
			p.rotation = p.getMoveAng();
			p.frict = rnd(0.84, 0.87);
			p.lifeS = rnd(8,10);
			p.onUpdate = _bloodPhysics;
		}
	}

	public function gibs(x:Float, y:Float, ang:Float, c:UInt) {
		var n = 40;
		for(i in 0...n) {
			var a = ang+rnd(0,0.3,true);
			var p = allocBgNormal( getTile("fxGib"), x+rnd(0,3,true), y+rnd(0,6,true));
			p.setFadeS(rnd(0.7,1), 0, rnd(13,15));
			p.colorize( i<=n*0.4 ? 0x880000 : C.toBlack(c,rnd(0,0.4)) );
			p.rotation = rnd(0,M.PI2);
			p.setScale( rnd(0.6,1,true) );
			p.scaleMul = rnd(0.997, 0.999);

			p.moveAng(a, rnd(0.2,0.6));
			p.gy = rnd(0.01, 0.08);
			p.frict = rnd(0.96, 0.98);
			p.groundY = p.y + rnd(5,16);
			// p.groundY = p.y + Math.sin(a)*rnd(20,40) + rnd(2,8);
			p.onTouchGround = _flatten;

			p.onUpdate = _bloodPhysics;
			p.lifeS = rnd(10,12);
		}
	}



	public function dirtExplosion(x:Float,y:Float, c:UInt) {
		for(i in 0...70) {
			var p = allocBgNormal( getTile("fxGib"), x+rnd(0,5,true), y+rnd(0,5,true));
			p.setFadeS(rnd(0.4,0.6), 0, rnd(1,2));
			p.colorize(c);
			p.rotation = rnd(0,M.PI2);
			p.setScale(rnd(0.4,0.7,true));
			p.scaleMul = rnd(0.995, 0.999);
			p.moveAwayFrom(x,y, rnd(1,2));
			p.frict = rnd(0.84, 0.93);
			p.lifeS = rnd(8,10);
			p.onUpdate = _bloodPhysics;
		}
	}


	public function explosion(x:Float, y:Float) {
		// Core
		var n = 20;
		for(i in 0...n) {
			var p = allocTopAdd( getTile("fxExplosion"), x+rnd(0,5,true), y+rnd(0,10,true));
			p.playAnimAndKill(Assets.tiles, "fxExplosion", 0.3);
			p.colorize( C.interpolateInt(0xff0000,0xffcc88,rnd(0,1)) );
			p.setFadeS(rnd(0.7,1), 0, 0.1);
			p.rotation = rnd(0,M.PIHALF);
			p.setScale( rnd(0.7, 1) );
			p.ds = rnd(0.1,0.2);
			p.dsFrict = rnd(0.8,0.9);

			p.moveAwayFrom(x,y, rnd(0.5,1));
			p.frict = rnd(0.92, 0.95);

			p.delayS = i/n * 0.2 + rnd(0,0.1,true);
			p.lifeS = 3;
		}

		// Lines
		n = 40;
		var a = rnd(0,M.PI);
		for(i in 0...n) {
			var a = a + i/n * M.PI2 + rnd(0,0.2,true);
			var p = allocTopAdd(getTile("fxLineDir"), x+Math.cos(a)*4, y+Math.sin(a)*4);
			p.scaleX = rnd(0.5,1);
			p.moveAwayFrom(x,y, rnd(5,7));
			p.setCenterRatio(0,0.5);
			p.colorize(0xffcc00);
			p.frict = rnd(0.89,0.90);
			p.rotation = a;
			p.scaleXMul = rnd(0.97,0.99);
			p.lifeS = rnd(0.5,1);
		}

		// Smoke
		var n = 10;
		for(i in 0...n) {
			var p = allocTopNormal( getTile("fxSmoke"), x+rnd(0,5,true), y+rnd(0,10,true));
			p.colorize(0x0);
			p.setFadeS(0, 0.4, rnd(3,8));
			p.rotation = rnd(0,M.PI2);
			p.setScale( rnd(0.7, 1,true) );
			p.scaleMul = rnd(1.001, 1.003);

			p.moveAwayFrom(x,y, rnd(0.2,0.6));
			p.frict = rnd(0.96, 0.98);

			p.lifeS = rnd(3,8);
		}
	}


	public function bossAtk(x:Float, y:Float) {
		// Core
		var n = 20;
		for(i in 0...n) {
			var p = allocBgAdd( getTile("fxExplosion"), x+rnd(0,10,true), y+rnd(0,5,true));
			p.playAnimAndKill(Assets.tiles, "fxExplosion", 0.5);
			p.colorize( 0xddaa55 );
			p.setFadeS(rnd(0.7,1), 0, 0.1);
			// p.rotation = rnd(0,M.PIHALF);
			p.setScale( rnd(0.9, 2) );
			p.scaleY *= 0.6;
			// p.ds = rnd(0.1,0.2);
			// p.dsFrict = rnd(0.8,0.9);

			p.moveAwayFrom(x,y, rnd(0.5,1));
			p.frict = rnd(0.92, 0.95);

			p.delayS = 0.1 + i/n * 0.1;
			p.lifeS = 3;
		}

		// Lines
		n = 50;
		var a = rnd(0,M.PI);
		for(i in 0...n) {
			var p = allocTopAdd(getTile("fxLineDir"), x+rnd(0,20,true), y-rnd(30,50));
			p.scaleX = rnd(1,3);
			p.scaleY = rnd(1,2);
			p.dy = rnd(5,8);
			p.setCenterRatio(1,0.5);
			p.colorize(0xffcc00);
			p.frict = rnd(0.93,0.95);
			p.rotation = M.PIHALF;
			p.groundY = y+rnd(0,5,true);
			p.scaleXMul = rnd(0.88,0.89);
			p.lifeS = rnd(0.2,0.3);
			p.onBounce = function() {
				p.dy = 0;
			}
		}
	}

	public function shine(e:Entity, c:UInt) {
		var p = allocTopAdd(getTile("fxStar"), e.footX+rnd(-7,2), e.footY-e.hei*rnd(0.4,0.9));
		p.colorize(c);
		p.dr = rnd(0.1,0.2);
		p.setFadeS(1, rnd(0.03,0.15), rnd(0.1,0.2));
		p.setScale(rnd(1,2));
		p.lifeS = 0.1;
	}

	public function focus(from:Entity, to:Entity, ?c=0x7cebff) {
		var p = allocBgAdd( getTile("fxLineDir"), from.headX, from.headY);
		var a = Math.atan2(to.headY-from.headY, to.headX-from.headX);
		var d = M.dist(from.headX, from.headY, to.headX, to.headY);
		p.setFadeS(0.5, 0.1, 0.1);
		p.rotation = a+M.PI;
		p.scaleX = d/p.t.width;
		p.colorize(c);
		p.setCenterRatio(1,0.5);
		p.lifeS = 0.1;
	}

	public function emptyBone(e:Entity) {
		var p = allocBgNormal(getTile("emptyBone"), e.footX, e.footY-4);
		p.setFadeS(1,0,5);
		p.dy = -rnd(2,3);
		p.dr = rnd(0.1, 0.2, true);
		p.dx = rnd(1,2,true);
		p.groundY = e.footY;
		p.bounceMul = 0;
		p.frict = 0.93;
		p.gy = 0.2;
		p.lifeS = 6;
		p.onBounce = function() {
			p.dy = p.gy = 0;
			p.rotation = rnd(0,0.3,true);
			p.dr = 0;
		}
	}

	public function prohibited(e:Entity) {
		var p = allocTopNormal(getTile("fxProhib"), e.centerX, e.centerY);
		p.colorize(0xff0000);
		p.lifeS = 0.2;
	}


	override function update() {
		super.update();

		pool.update(game.tmod);
	}
}