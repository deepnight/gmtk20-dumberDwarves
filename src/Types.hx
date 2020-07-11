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
}

enum Task {
	Idle;
	Gather(it:ItemType);
	JudgeOther(e:en.Ai);
}

enum JudgeableThing {
	DoingTask(taskId:Int);
	CarryingItem(it:ItemType);
}
