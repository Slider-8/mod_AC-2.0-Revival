// Companion XP share + Houndmaster->Beastmaster conversion (D5: class/size, not prose)
::AC.HooksMod.hook("scripts/entity/tactical/player", function(q)
{
	q.onActorKilled = @(__original) function( _actor, _tile, _skill )
	{
		__original(_actor, _tile, _skill);
		local XPkiller = this.Math.floor(_actor.getXPValue() * this.Const.XP.XPForKillerPct);
		local XPgroup = _actor.getXPValue() * (1.0 - this.Const.XP.XPForKillerPct);
		local brothers = this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player);
		foreach (bro in brothers)
		{
			local cAcc = bro.getItems().getItemAtSlot(this.Const.ItemSlot.Accessory);
			if (cAcc != null && "setType" in cAcc)
			{
				if (cAcc.getType() != null)
					cAcc.addXP(this.Math.max(1, this.Math.floor(XPgroup / brothers.len())));
			}
		}

		local kAcc = this.getItems().getItemAtSlot(this.Const.ItemSlot.Accessory);
		if (kAcc != null && "setType" in kAcc)
		{
			if (kAcc.getType() != null)
				kAcc.addXP(XPkiller);
		}
	}

	// Note: mod_modular_vanilla *replaces* setStartValuesEx without calling
	// __original in some versions. If that discards this wrap, Beastmaster
	// conversion needs a different anchor (COMPATIBILITY.md).
	q.setStartValuesEx = @(__original) function( _backgrounds, _addTraits = true )
	{
		__original(_backgrounds, _addTraits);

		local town = this.World.State.getCurrentTown();
		if (this.m.Background == null || this.m.Background.m.ID != "background.houndmaster" || town == null)
			return;

		if (!("AC_isBeastmasterTown" in town) || !town.AC_isBeastmasterTown())
			return;

		this.m.Background = null;
		this.m.Title = "";
		this.m.Talents = [];
		this.m.Items.clear();

		local remove = this.m.Skills.query(this.Const.SkillType.Background);
		foreach (r in remove)
		{
			if (r.getID() != "special.mood_check" && r.getID() != "special.VA11")
				this.m.Skills.removeByID(r.getID());
		}
		remove = this.m.Skills.query(this.Const.SkillType.Trait);
		foreach (r in remove)
		{
			if (r.getID() != "special.mood_check" && r.getID() != "special.VA11")
				this.m.Skills.removeByID(r.getID());
		}

		local background = this.new("scripts/skills/backgrounds/houndmaster_background");
		background.applyBeastmasterModification();
		this.m.Skills.add(background);
		this.m.Background = background;
		this.m.Ethnicity = this.m.Background.getEthnicity();
		background.buildAttributes();
		background.buildDescription();

		if (_addTraits)
		{
			local maxTraits = this.Math.rand(this.Math.rand(0, 1) == 0 ? 0 : 1, 2);
			local traits = [
				background
			];

			for (local i = 0; i < maxTraits; i = ++i)
			{
				for (local j = 0; j < 10; j = ++j)
				{
					local trait = this.Const.CharacterTraits[this.Math.rand(0, this.Const.CharacterTraits.len() - 1)];
					local nextTrait = false;

					for (local k = 0; k < traits.len(); k = ++k)
					{
						if (traits[k].getID() == trait[0] || traits[k].isExcluded(trait[0]))
						{
							nextTrait = true;
							break;
						}
					}

					if (!nextTrait)
					{
						traits.push(this.new(trait[1]));
						break;
					}
				}
			}

			for (local i = 1; i < traits.len(); i = ++i)
			{
				this.m.Skills.add(traits[i]);

				if (traits[i].getContainer() != null)
				{
					traits[i].addTitle();
				}
			}
		}

		background.addEquipment();
		background.setAppearance();
		background.buildDescription(true);
		this.m.Skills.update();
		local p = this.m.CurrentProperties;
		this.m.Hitpoints = p.Hitpoints;

		if (_addTraits)
		{
			this.fillTalentValues();
			this.fillAttributeLevelUpValues(this.Const.XP.MaxLevelWithPerkpoints - 1);
		}
	}
});
