class Level extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	public var wid = 32;
	public var hei = 16;

	var marks : Map< LevelMark, Map<Int,Bool> > = new Map();
	var invalidated = true;
	public var data : led.Level;

	var fastCollGrid: Map<Int,Int>;
	public var pf : dn.pathfinder.AStar<CPoint>;

	public function new(data:led.Level) {
		super(Game.ME);
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
		// Debug level render
		root.removeChildren();
		var g = new h2d.Graphics(root);
		for(cx in 0...wid)
		for(cy in 0...hei) {
			if( hasCollision(cx,cy) )
				g.beginFill(0x0);
			else
				g.beginFill( C.makeColorHsl(rnd(0,0.03), 0.6, 0.4) );
			g.drawRect(cx*Const.GRID, cy*Const.GRID, Const.GRID, Const.GRID);
		}
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}