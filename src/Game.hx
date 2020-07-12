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
		level = new Level( ledProject.getLevel("Lab") );
		fx = new Fx();
		hud = new ui.Hud();

		// Attach entities
		var li = level.data.getLayerInstance("Entities");
		for( ei in li.entityInstances ) {
			var cx = ei.getCx(li.def);
			var cy = ei.getCy(li.def);
			switch ei.def.name {
				case "Hero":
					var e = new en.ai.Dwarf(cx,cy);

				case "Mob":
					new en.ai.Mob(cx,cy);

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

	function onMouseDown(e:hxd.Event) {
		var m = new tools.MouseCoords(e.relX, e.relY);

		var dh = new dn.DecisionHelper(en.ai.Dwarf.ALL);
		dh.keepOnly( function(e) return e.isAlive() && M.dist(m.levelX, m.levelY, e.centerX, e.centerY) <= Const.GRID*0.9 );
		dh.score( function(e) return -M.dist(m.levelX, m.levelY, e.footX, e.footY) );
		dh.useBest( function(e) {
			e.slap(m.levelX, m.levelY);
		});
		if( dh.countRemaining()==0 ) {
			if( useBait() ) {
				var e = new en.Item(m.cx, m.cy, BaitFull);
				e.zr = -2;
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
			#end

			// Restart
			if( ca.selectPressed() )
				Main.ME.startGame();
		}
	}
}

