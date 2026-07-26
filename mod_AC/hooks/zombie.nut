// Reanimated zombies grant companion XP on kill
::AC.HooksMod.hookTree("scripts/entity/tactical/enemies/zombie", function(q)
{
	q.onActorKilled = @(__original) function( _actor, _tile, _skill )
	{
		if (this.getFaction() == this.Const.Faction.Player || this.getFaction() == this.Const.Faction.PlayerAnimals)
		{
			local XPgroup = _actor.getXPValue();
			local brothers = this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player);
			foreach (bro in brothers)
			{
				bro.addXP(this.Math.max(1, this.Math.floor(XPgroup / brothers.len())));

				local acc = bro.getItems().getItemAtSlot(this.Const.ItemSlot.Accessory);
				if (acc != null && "setType" in acc)
				{
					if (acc.getType() != null)
						acc.addXP(this.Math.max(1, this.Math.floor(XPgroup / brothers.len())));
				}
			}
		}
		__original(_actor, _tile, _skill);
	}
});
