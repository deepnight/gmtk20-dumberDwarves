package en.ai;

class Peon extends en.Ai {
	public function new(x,y, t:Team) {
		super(x,y);
		team = t;
	}


	override function updateAi() {
		super.updateAi();
	}
}