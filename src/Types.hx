enum Affect {
	Stun;
}

enum LevelMark {
}

enum ItemType {
	Gem;
	BaitFull;
	BaitPart;
}

enum Task {
	Idle;
	Grab(e:en.Item);
	Break(e:en.Breakable);
	BringToCart;
	AttackDwarf(e:en.ai.Dwarf);
}
