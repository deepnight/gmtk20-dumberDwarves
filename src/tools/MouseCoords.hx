package tools;

class MouseCoords {
	public var gx : Float;
	public var gy : Float;

	public var levelX(get,never) : Int;
	inline function get_levelX() return M.round( ( gx - game.scroller.x ) / Const.SCALE );

	public var levelY(get,never) : Int;
	inline function get_levelY() return M.round( ( gy - game.scroller.y ) / Const.SCALE );

	public var cx(get,never) : Int;
	inline function get_cx() return M.floor( levelX / Const.GRID );

	public var cy(get,never) : Int;
	inline function get_cy() return M.floor( levelY / Const.GRID );

	var game(get,never) : Game; inline function get_game() return Game.ME;

	public function new(gx:Float,gy:Float) {
		this.gx = gx;
		this.gy = gy;
	}
}

