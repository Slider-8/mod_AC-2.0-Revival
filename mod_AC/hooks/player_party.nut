// Equipped companions contribute to party strength
::AC.HooksMod.hook("scripts/entity/world/player_party", function(q)
{
	q.updateStrength = @(__original) function()
	{
		__original();
		local company = this.World.getPlayerRoster().getAll();
		if (company.len() > this.World.Assets.getBrothersScaleMax())
		{
			company.sort(this.onLevelCompare);
		}

		foreach (i, bro in company)
		{
			if (i >= this.World.Assets.getBrothersScaleMax())
			{
				break;
			}

			local companion = bro.getItems().getItemAtSlot(this.Const.ItemSlot.Accessory);
			if (companion != null && "setType" in companion)
			{
				this.m.Strength += this.Math.round(companion.m.Level * (this.Const.Companions.Library[companion.getType()].PartyStrength / 8.25));
			}
		}
	}
});
