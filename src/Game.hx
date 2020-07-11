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

	public var redVillage : en.Village;

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

		// Load L-Ed project
		var raw = hxd.Res.ld.world_json.entry.getText();
		var json = haxe.Json.parse(raw);
		ledProject = led.Project.fromJson(json);

		camera = new Camera();
		level = new Level( ledProject.getLevel("Lab") );
		fx = new Fx();
		hud = new ui.Hud();

		var li = level.data.getLayerInstance("Entities");
		for( ei in li.entityInstances ) {
			switch ei.def.name {
				case "Peon":
					new en.ai.Peon( ei.getCx(li.def), ei.getCy(li.def), stringToTeam( ei.getStringField("Team") ) );

				case "Village":
					var e = new en.Village( ei.getCx(li.def), ei.getCy(li.def), stringToTeam( ei.getStringField("Team") ) );
					if( e.team==Red )
						redVillage = e;

				case "Item":
					var v = new en.Item(
						ei.getCx(li.def),
						ei.getCy(li.def),
						ItemType.createByName( ei.getStringField("Type") )
					);

				case _: trace("Unknown entity "+ei.def.name);
			}
		}

		Process.resizeAll();
		trace(Lang.t._("Game is ready."));
	}

	function stringToTeam(s:String) : Team {
		return switch s.toLowerCase() {
			case "red" : Red;
			case "blue" : Blue;
			case _: throw "Unknown team string "+s;
		}
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

			// Restart
			if( ca.selectPressed() )
				Main.ME.startGame();
		}
	}
}

