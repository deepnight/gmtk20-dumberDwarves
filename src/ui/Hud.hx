package ui;

class Hud extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;
	public var level(get,never) : Level; inline function get_level() return Game.ME.level;

	var flow : h2d.Flow;
	var invalidated = true;

	public function new() {
		super(Game.ME);

		createRootInLayers(game.root, Const.DP_UI);
		root.filter = new h2d.filter.ColorMatrix(); // force pixel perfect rendering

		flow = new h2d.Flow(root);
		flow.layout = Vertical;
		flow.backgroundTile = h2d.Tile.fromColor(0x0);
		flow.padding = 2;
	}

	override function onResize() {
		super.onResize();
		root.setScale(Const.UI_SCALE);
		flow.x = 2;
		flow.y = Std.int( h()/Const.UI_SCALE*0.5 - flow.outerHeight*0.5 );
	}

	public inline function invalidate() invalidated = true;

	function render() {
		flow.removeChildren();
		for(i in 0...Const.BAITS) {
			var active = i+1<=game.baits;
			var e = Assets.tiles.h_get("uiBait"+(active?"On":"Off"), flow);
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
