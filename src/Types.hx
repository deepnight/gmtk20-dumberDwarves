enum Affect {
	Stun;
}

enum LevelMark {
}

enum Team {
	Red;
	Blue;
}

enum ItemType {
	Coin;
	Food;
}

enum Task {
	Idle;
	Gather(it:ItemType);
	JudgeOther(e:en.Ai);
	Flee(x:Float, y:Float, distCase:Int);
}

enum JudgeableThing {
	DoingTask(taskId:Int);
	CarryingItem(it:ItemType);
}
