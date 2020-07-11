package en.ai;

class Dwarf extends en.Ai {
	public function new(x,y) {
		super(x,y);

		spr.anim.registerStateAnim("d_walk", 1, 0.15, function() return isWalking() );
		spr.anim.registerStateAnim("d_idle", 0, 0.1);
		// spr.anim.registerStateAnim("a_walk", 1, 0.15, function() return isWalking() );
		// spr.anim.registerStateAnim("a_idle", 0, 0.1);
	}


	override function updateAi() {
		super.updateAi();
	}
}