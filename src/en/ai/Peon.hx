package en.ai;

class Peon extends en.Ai {
	public function new(x,y, t:Team) {
		super(x,y);
		team = t;

		spr.anim.registerStateAnim("a_walk", 1, 0.15, function() return isWalking() );
		spr.anim.registerStateAnim("a_idle", 0, 0.1);
	}


	override function updateAi() {
		super.updateAi();
	}
}