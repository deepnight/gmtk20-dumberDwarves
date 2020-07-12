import dn.Process;
import hxd.Key;

class Game extends Process {
	public static var ME : Game;

	public var ca : dn.heaps.Controller.ControllerAccess;
	public var fx : Fx;
	public var camera : Camera;
	public var scroller : h2d.Layers;
	public var level : Level;
	public var hud : ui.Hud;

	public var baits : Int;

	var curGameSpeed = 1.0;
	var slowMos : Map<String, { id:String, t:Float, f:Float }> = new Map();

	public var ledProject : led.Project;

	public function new() {
		super(Main.ME);
		ME = this;
		ca = Main.ME.controller.createAccess("game");
		ca.setLeftDeadZone(0.2);
		ca.setRightDeadZone(0.2);
		createRootInLayers(Main.ME.root, Const.DP_BG);

		scroller = new h2d.Layers();
		root.add(scroller, Const.DP_BG);
		scroller.filter = new h2d.filter.ColorMatrix(); // force rendering for pixel perfect

		Boot.ME.s2d.addEventListener(onEvent);

		// Load L-Ed project
		var raw = hxd.Res.ld.world_json.entry.getText();
		var json = haxe.Json.parse(raw);
		ledProject = led.Project.fromJson(json);

		// Init main components
		camera = new Camera();
		fx = new Fx();
		hud = new ui.Hud();

		startLevel(ledProject.levels[0]);
	}

	public function nextLevel() {
		var next = false;
		for(l in ledProject.levels)
			if( l==level.data )
				next = true;
			else if( next ) {
				startLevel(l);
				break;
			}
	}

	public function startLevel(l:led.Level) {
		for(e in Entity.ALL)
			e.destroy();
		gc();
		fx.clear();

		if( level!=null )
			level.destroy();

		level = new Level(l);

		// Attach entities
		var li = level.data.getLayerInstance("Entities");
		for( ei in li.entityInstances ) {
			var cx = ei.getCx(li.def);
			var cy = ei.getCy(li.def);
			switch ei.def.name {
				case "Hero":
					var e = new en.ai.Dwarf(cx,cy);

				case "Mob":
					switch ei.getStringField("Type") {
						case "Gob": new en.ai.mob.Goblin(cx,cy);
						case _: trace("unknown mob");
					}

				case "MobGen":
					new en.MobGen(cx,cy);

				case "Crate":
					new en.Breakable(cx,cy);

				case "Item":
					var v = new en.Item( cx, cy, ItemType.createByName( ei.getStringField("Type") ) );

				case "Cart":
					var v = new en.Cart( cx, cy );

				case _: trace("Unknown entity "+ei.def.name);
			}
		}

		refillBaits();
		Process.resizeAll();

		announce("Team ready!", "Lead these idiots to steal "+countRemainingGems()+" gems!", 0xffcc00, true);
	}


	function onEvent(e:hxd.Event) {
		switch e.kind {
			case EPush: onMouseDown(e);
			case ERelease: onMouseUp(e);
			case EMove:
			case EOver:
			case EOut: onMouseUp(e);
			case EWheel:
			case EFocus:
			case EFocusLost:
			case EKeyDown:
			case EKeyUp:
			case EReleaseOutside: onMouseUp(e);
			case ETextInput:
			case ECheck:
		}
	}

	public function useBait() {
		if( baits<=0 )
			return false;

		baits--;
		hud.invalidate();

		return true;
	}

	public function refillBaits() {
		if( baits>=Const.BAITS )
			return;

		baits = Const.BAITS;
		hud.invalidate();
	}

	public function popText(x:Float, y:Float, str:String, ?c=0xffffff) {
		var wrapper = new h2d.Object();
		scroller.add( wrapper, Const.DP_UI );
		var tf = new h2d.Text(Assets.fontPixel, wrapper);
		tf.text = str;
		tf.textColor = c;
		tf.x = -Std.int( tf.textWidth*0.5 );
		tf.y = -Std.int( tf.textHeight*0.5 );

		// var p = game.createChildProcess( function(p) {
		// }, function(p) {
		// 	wrapper.remove();
		// });

		wrapper.x = Std.int( x );
		wrapper.y = Std.int( y );
		tw.createMs(wrapper.y, wrapper.y-10, 100).end( function() {
			tw.createMs(wrapper.alpha, 1000|0, 1000).end( wrapper.remove );
		});
	}

	function onMouseDown(e:hxd.Event) {
		var m = new tools.MouseCoords(e.relX, e.relY);

		var dh = new dn.DecisionHelper(en.ai.Dwarf.ALL);
		dh.keepOnly( function(e) return e.isAlive() && M.dist(m.levelX, m.levelY, e.centerX, e.centerY) <= Const.GRID*0.8 );
		dh.score( function(e) return -M.dist(m.levelX, m.levelY, e.footX, e.footY) );
		dh.useBest( function(e) {
			e.slap(m.levelX, m.levelY);
		});

		// No dwarf under cursor
		if( dh.countRemaining()==0 ) {
			var dh = new dn.DecisionHelper(en.Item.ALL);
			dh.keepOnly( function(e) return e.isAlive() && ( e.type==BaitFull || e.type==BaitPart ) && !e.isCarried && M.dist(m.levelX, m.levelY, e.centerX, e.centerY) <= Const.GRID*0.8 );
			dh.score( function(e) return -M.dist(m.levelX, m.levelY, e.footX, e.footY) );
			dh.useBest( function(e) {
				fx.dirtExplosion(e.centerX, e.centerY, 0xa97852);
				e.destroy();
			});

			// No bait under cursor
			if( dh.countRemaining()==0 ) {
				if( useBait() ) {
					var e = new en.Item(m.cx, m.cy, BaitFull);
					e.zr = -2;
				}
				else {
					if( !cd.hasSetS("foodWarn", 1) )
						popText(m.levelX, m.levelY, "No food, steam a GEM to refill", 0xff0000);
				}
			}
		}
	}
	function onMouseUp(e:hxd.Event) {
		var m = new tools.MouseCoords(e.relX, e.relY);
	}

	public function onCdbReload() {
	}

	override function onResize() {
		super.onResize();
		scroller.setScale(Const.SCALE);
	}


	function gc() {
		if( Entity.GC==null || Entity.GC.length==0 )
			return;

		for(e in Entity.GC)
			e.dispose();
		Entity.GC = [];
	}

	override function onDispose() {
		super.onDispose();

		Boot.ME.s2d.removeEventListener(onEvent);

		if( ME==this )
			ME = null;

		fx.destroy();
		for(e in Entity.ALL)
			e.destroy();
		gc();
	}


	public function addSlowMo(id:String, sec:Float, speedFactor=0.3) {
		if( slowMos.exists(id) ) {
			var s = slowMos.get(id);
			s.f = speedFactor;
			s.t = M.fmax(s.t, sec);
		}
		else
			slowMos.set(id, { id:id, t:sec, f:speedFactor });
	}


	function updateSlowMos() {
		// Timeout active slow-mos
		for(s in slowMos) {
			s.t -= utmod * 1/Const.FPS;
			if( s.t<=0 )
				slowMos.remove(s.id);
		}

		// Update game speed
		var targetGameSpeed = 1.0;
		for(s in slowMos)
			targetGameSpeed*=s.f;
		curGameSpeed += (targetGameSpeed-curGameSpeed) * (targetGameSpeed>curGameSpeed ? 0.2 : 0.6);

		if( M.fabs(curGameSpeed-targetGameSpeed)<=0.001 )
			curGameSpeed = targetGameSpeed;
	}


	public inline function stopFrame() {
		ucd.setS("stopFrame", 0.2);
	}

	override function preUpdate() {
		super.preUpdate();

		for(e in Entity.ALL) if( !e.destroyed ) e.preUpdate();
	}

	override function postUpdate() {
		super.postUpdate();


		for(e in Entity.ALL) if( !e.destroyed ) e.postUpdate();
		for(e in Entity.ALL) if( !e.destroyed ) e.finalUpdate();
		gc();

		// Update slow-motions
		updateSlowMos();
		setTimeMultiplier( ( 0.2 + 0.8*curGameSpeed ) * ( ucd.has("stopFrame") ? 0.3 : 1 ) );
		Assets.tiles.tmod = tmod;
	}

	public function countRemainingGems() {
		var n = 0;
		for(e in en.Item.ALL)
			if( e.isAlive() && e.type==Gem )
				n++;
		return n;
	}

	public function announce(str:String, ?sub:String, c:UInt, big:Bool) {
		var pad = 10;
		var w = new h2d.Object();
		root.add(w, Const.DP_UI);
		w.scale(Const.DP_UI);

		var tf = new h2d.Text(big ? Assets.fontLarge : Assets.fontMedium, w);
		tf.text = str.toUpperCase();
		tf.textColor = c;
		tf.x = -pad;
		tf.blendMode = Add;

		if( sub!=null ) {
			var stf = new h2d.Text(Assets.fontPixel, w);
			stf.text = sub.toUpperCase();
			stf.textColor = c;
			stf.x = tf.x + tf.textWidth - stf.textWidth;
			stf.y = tf.textHeight;
			stf.blendMode = Add;
		}

		var wid = this.w();
		var hei = this.h();
		w.y = Std.int( hei*0.5-tf.textHeight*0.5*w.scaleY );
		tw.createMs(w.x, -200 > wid-tf.textWidth*w.scaleX, 200, TElasticEnd);
		if( sub==null )
			tw.createMs(w.alpha, 1000|0, 200).end( w.remove );
		else
			tw.createMs(w.alpha, 2500|0, 200).end( w.remove );
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		for(e in Entity.ALL) if( !e.destroyed ) e.fixedUpdate();
	}

	override function update() {
		super.update();

		for(e in Entity.ALL) if( !e.destroyed ) e.update();

		if( !ui.Console.ME.isActive() && !ui.Modal.hasAny() ) {
			#if hl
			// Exit
			if( ca.isKeyboardPressed(Key.ESCAPE) )
				if( !cd.hasSetS("exitWarn",3) )
					trace(Lang.t._("Press ESCAPE again to exit."));
				else
					hxd.System.exit();
			#end

			#if debug
			if( ca.isKeyboardPressed(Key.D) )
				fx.bloodExplosion(50,50);
			if( ca.isKeyboardPressed(Key.N) )
				nextLevel();
			#end

			// Restart
			if( ca.selectPressed() )
				Main.ME.startGame();
		}
	}
}

