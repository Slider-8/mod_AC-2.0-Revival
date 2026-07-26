// D5/D7: contribute houndmaster drafts without prose matching or polluting m.DraftList.
// Classification uses Size + script class (stable), not English Description strings.
// Southern city_states are excluded (original lists never matched them).

::AC.HooksMod.hookTree("scripts/entity/world/settlement", function(q)
{
	// Returns how many "houndmaster_background" entries to inject into the
	// *cloned* draft list for this roster roll: 0, 1, or 2.
	// 2 = Beastmaster-large (all size-3 non-southern); conversion also uses this.
	// 1 on size-2 forest/mountain/swamp = Beastmaster-medium.
	// 1 on size-1 lumber/swamp villages = Houndmaster-small only.
	q.AC_getHoundmasterDraftSlots <- function()
	{
		if (this.getCulture() == this.Const.World.Culture.Southern)
			return 0;

		local size = this.getSize();

		if (size >= 3)
			return 2;

		if (size == 2)
		{
			if (this.isKindOf(this, "medium_forest_fort") || this.isKindOf(this, "medium_lumber_village") || this.isKindOf(this, "medium_mountains_fort") || this.isKindOf(this, "medium_mining_village") || this.isKindOf(this, "medium_swamp_fort") || this.isKindOf(this, "medium_swamp_village"))
				return 1;
			return 0;
		}

		if (size == 1)
		{
			if (this.isKindOf(this, "small_lumber_village") || this.isKindOf(this, "small_swamp_village"))
				return 1;
		}

		return 0;
	}

	// True for settlements that convert drafted Houndmasters into Beastmasters.
	// Original: Large OR Medium prose lists (not small).
	q.AC_isBeastmasterTown <- function()
	{
		if (this.getCulture() == this.Const.World.Culture.Southern)
			return false;

		local size = this.getSize();

		if (size >= 3)
			return true;

		if (size == 2)
		{
			if (this.isKindOf(this, "medium_forest_fort") || this.isKindOf(this, "medium_lumber_village") || this.isKindOf(this, "medium_mountains_fort") || this.isKindOf(this, "medium_mining_village") || this.isKindOf(this, "medium_swamp_fort") || this.isKindOf(this, "medium_swamp_village"))
				return true;
		}

		return false;
	}

	// Temporarily extend m.DraftList for the duration of updateRoster so the
	// vanilla clone sees our entries, then restore the persistent field (D7).
	q.updateRoster = @(__original) function( _force = false )
	{
		local slots = this.AC_getHoundmasterDraftSlots();

		if (slots <= 0)
		{
			return __original(_force);
		}

		local backup = clone this.m.DraftList;
		local already = 0;
		foreach (entry in this.m.DraftList)
		{
			if (entry == "houndmaster_background")
				++already;
		}

		for (local i = already; i < slots; i = ++i)
		{
			this.m.DraftList.push("houndmaster_background");
		}

		// Restore even if roster generation throws, so injected entries never
		// persist into the save (review: D7 reintroduction risk).
		try
		{
			__original(_force);
		}
		catch (error)
		{
			this.m.DraftList = backup;
			throw error;
		}

		this.m.DraftList = backup;
	}
});
