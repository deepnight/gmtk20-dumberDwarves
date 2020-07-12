enum Affect {
	Stun;
}

enum LevelMark {
}

enum ItemType {
	Gem;
	Bait;
}

enum Task {
	Idle;
	Grab(it:ItemType);
	AttackDwarf(e:en.ai.Dwarf);
}
