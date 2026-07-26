this.companions_regenerative <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "quirk.regenerative";
		this.m.Name = "Regenerative";
		this.m.Description = "Regenerates health";
		this.m.Icon = "skills/status_effect_79.png";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.Order = this.Const.SkillOrder.VeryLast;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsHidden = false;
	}

	function getTooltip()
	{
		return [
			{
				id = 1,
				type = "title",
				text = this.getName()
			},
			{
				id = 2,
				type = "description",
				text = this.getDescription()
			}
		];
	}

	function onTurnStart()
	{
		local actor = this.getContainer().getActor();
		local healthMissing = actor.getHitpointsMax() - actor.getHitpoints();
		local healthAdded = this.Math.min(healthMissing, this.Math.floor(actor.getHitpointsMax() * 0.1));

		// D15: key on companion Type, not hard-coded class-name strings.
		local reduced = false;
		if (("m" in actor) && ("Item" in actor.m) && actor.m.Item != null && ("getType" in actor.m.Item) && actor.m.Item.getType() != null)
		{
			local t = actor.m.Item.getType();
			local TL = this.Const.Companions.TypeList;
			if (t == TL.Noodle || t == TL.Unhold || t == TL.UnholdArmor || t == TL.Schrat)
				reduced = true;
		}
		if (reduced)
		{
			healthAdded = this.Math.min(healthMissing, this.Math.floor(actor.getHitpointsMax() * 0.05));
		}

		if (healthAdded <= 0)
		{
			return;
		}

		actor.setHitpoints(actor.getHitpoints() + healthAdded);
		actor.setDirty(true);

		if (!actor.isHiddenToPlayer())
		{
			this.spawnIcon("status_effect_79", actor.getTile());
			this.Tactical.EventLog.log(this.Const.UI.getColorizedEntityName(actor) + " heals for " + healthAdded + " points");
		}
	}
});
