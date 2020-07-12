class Level extends dn.Process {
	static var PALETTES = [
		"#605383",
		"#6c835a",
	];

	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	public var wid = 32;
	public var hei = 16;

	var marks : Map< LevelMark, Map<Int,Bool> > = new Map();
	var invalidated = true;
	public var levelId : Int;
	public var data : led.Level;

	var fastCollGrid: Map<Int,Int>;
	public var pf : dn.pathfinder.AStar<CPoint>;

	public function new(idx:Int, data:led.Level) {
		super(Game.ME);
		levelId = idx;
		this.data = data;
		wid = Std.int(data.pxWid/Const.GRID);
		hei= Std.int(data.pxHei/Const.GRID);
		createRootInLayers(Game.ME.scroller, Const.DP_BG);

		initCollisions();
		pf = new dn.pathfinder.AStar( function(x,y) return new CPoint(x,y,0.5,0.5) );
		pf.init(wid, hei, hasCollision);
	}

	public function initCollisions() {
		fastCollGrid = new Map();

		var li = data.getLayerInstance("Collisions");
		for(cy in 0...hei)
		for(cx in 0...wid)
			fastCollGrid.set( coordId(cx,cy), li.getIntGrid(cx,cy) );
	}

	public inline function isValid(cx,cy) return cx>=0 && cx<wid && cy>=0 && cy<hei;
	public inline function coordId(cx,cy) return cx + cy*wid;


	public inline function hasMark(mid:LevelMark, cx:Int, cy:Int) {
		return !isValid(cx,cy) || !marks.exists(mid) ? false : marks.get(mid).exists( coordId(cx,cy) );
	}

	public function setMark(mid:LevelMark, cx:Int, cy:Int) {
		if( isValid(cx,cy) && !hasMark(mid,cx,cy) ) {
			if( !marks.exists(mid) )
				marks.set(mid, new Map());
			marks.get(mid).set( coordId(cx,cy), true );
		}
	}

	public function removeMark(mid:LevelMark, cx:Int, cy:Int) {
		if( isValid(cx,cy) && hasMark(mid,cx,cy) )
			marks.get(mid).remove( coordId(cx,cy) );
	}

	public inline function hasCollision(cx,cy) : Bool {
		return isValid(cx,cy) ? fastCollGrid.get(coordId(cx,cy))==0 : true;
	}

	public function render() {
		root.removeChildren();

		var col = C.hexToInt( PALETTES[ M.imin(levelId,PALETTES.length) ] );
		root.filter = C.getColorizeFilterH2d(col, 0.5);

		// Ground
		var tg = new h2d.TileGroup(Assets.tiles.tile, root);
		for(cx in 0...wid)
		for(cy in 0...hei) {
			if( hasCollision(cx,cy) )
				continue;
			var t = Assets.tiles.getTileRandom("gStone");
			t.setCenterRatio();
			tg.add(
				Std.int( (cx+.5)*Const.GRID ),
				Std.int( (cy+.5)*Const.GRID ),
				t
			);
		}

		// Walls
		var tg = new h2d.TileGroup(Assets.tiles.tile, root);
		// tg.filter = new h2d.filter.Group([
		// 	new h2d.filter.DropShadow(4, M.PIHALF, 0x0, 0.3, 0),
		// 	new h2d.filter.Glow(C.brightnessInt(col,0.2), 1, 128, true),
		// ]);
		tg.filter = new h2d.filter.DropShadow(4, M.PIHALF, 0x0, 0.3, 0);
		for(cx in 0...wid)
		for(cy in 0...hei) {
			if( !hasCollision(cx,cy) )
				continue;

			var t = Assets.tiles.getTileRandom("wall");
			t.setCenterRatio();
			tg.add(
				Std.int( (cx+.5)*Const.GRID ),
				Std.int( (cy+.5)*Const.GRID ),
				t
			);
			if( !hasCollision(cx,cy+1) ) {
				var t = Assets.tiles.getTileRandom("wallDetail");
				t.setCenterRatio();
				tg.addAlpha(
					Std.int( (cx+.5)*Const.GRID ),
					Std.int( (cy+.5)*Const.GRID ),
					rnd(0.2,0.4), t
				);

			}
		}

		for(li in data.layerInstances)
			if( li.def.type==Tiles )
				li.render(root);
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}