enum Affect {
	Stun;
}

enum LevelMark {
}

enum ItemType {
	Gem;
}

enum Task {
	Idle;
	Grab(it:ItemType);
}
