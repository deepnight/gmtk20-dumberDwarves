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
	Break(e:en.Breakable);
	AttackDwarf(e:en.ai.Dwarf);
}
