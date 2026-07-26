// Companion item drops on actor death (D4: hookTree, no SuperName climb)
// Necromancer -> Tome of Reanimation; spider eggs -> webknecht companion.
::AC.HooksMod.hookTree("scripts/entity/tactical/actor", function(q)
{
	q.onDeath = @(__original) function( _killer, _skill, _tile, _fatalityType )
	{
		__original(_killer, _skill, _tile, _fatalityType);
		if ((this.m.Type == this.Const.EntityType.Necromancer || this.m.Type == this.Const.EntityType.SpiderEggs) && (_killer == null || _killer.getFaction() == this.Const.Faction.Player || _killer.getFaction() == this.Const.Faction.PlayerAnimals))
		{
			if (this.Math.rand(1, 1000) <= this.Const.Companions.TameChance.Default)
			{
				local type;
				if (this.m.Type == this.Const.EntityType.Necromancer)
				{
					type = this.Const.Companions.TypeList.TomeReanimation;
				}
				else if (this.m.Type == this.Const.EntityType.SpiderEggs)
				{
					type = this.Const.Companions.TypeList.Spider;
				}
				else
				{
					type = this.Const.Companions.TypeList.Wardog;
				}

				local matchNum = 0;
				local size = this.Tactical.getMapSize();
				for (local x = 0; x < size.X; x = ++x)
				{
					for (local y = 0; y < size.Y; y = ++y)
					{
						local tile = this.Tactical.getTileSquare(x, y);
						if (tile.IsContainingItems)
						{
							foreach (item in tile.Items)
							{
								if (item != null && item.getItemType() == this.Const.Items.ItemType.Accessory && "setType" in item)
								{
									if (item.getType() == type)
										++matchNum;
								}
							}
						}
					}
				}

				local stash = this.World.Assets.getStash().getItems();
				foreach (item in stash)
				{
					if (item != null && item.getItemType() == this.Const.Items.ItemType.Accessory && "setType" in item)
					{
						if (item.getType() == type)
							++matchNum;
					}
				}

				local brothers = this.World.getPlayerRoster().getAll();
				foreach (bro in brothers)
				{
					local acc = bro.getItems().getItemAtSlot(this.Const.ItemSlot.Accessory);
					if (acc != null && "setType" in acc)
					{
						if (acc.getType() == type)
							++matchNum;
					}
				}

				if (matchNum < this.Const.Companions.Library[type].MaxPerCompany)
				{
					local loot = this.new("scripts/items/accessory/wardog_item");
					loot.setType(type);
					loot.updateCompanion();
					loot.drop(_tile);
				}
			}
		}
	}
});
