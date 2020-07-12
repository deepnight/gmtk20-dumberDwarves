enum Affect {
	Stun;
}

enum LevelMark {
}

enum ItemType {
	Gem;
	BaitFull;
	BaitPart;
	Bomb;
}

enum Task {
	Wait(untilFrame:Float);
	Idle;
	Grab(e:en.Item);
	Break(e:en.Breakable);
	BringToCart;
	AttackDwarf(e:en.ai.Dwarf);
	WaitWithItem(e:en.Item);
	ExitLevel;
	FleeBoss(e:en.ai.mob.Boss);
}
