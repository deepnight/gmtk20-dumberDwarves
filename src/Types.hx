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
	Grab(e:en.Item);
	AttackDwarf(e:en.ai.Dwarf);
}
