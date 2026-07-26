// Full companion accessory tooltip (shared by foundation + item tooltip guard).
// _item is a wardog/warhound/wolf-style accessory with companion fields.

::AC.buildCompanionItemTooltip <- function( _item )
{
	if (_item.m.Type == null || _item.m.Attributes == null)
	{
		local name = _item.m.Name;
		try { name = _item.getName(); } catch (e) {}
		return [
			{ id = 1, type = "title", text = name },
			{ id = 2, type = "description", text = _item.m.Description != null ? _item.m.Description : "" },
			{ id = 3, type = "text", text = _item.getValueString() }
		];
	}

	local level = _item.m.Level;
	if (level == null || level < 1)
		level = 1;
	if (level > this.Const.LevelXP.len())
		level = this.Const.LevelXP.len();

	local xpMax = _item.m.XP;
	if (level < this.Const.LevelXP.len())
		xpMax = this.Const.LevelXP[level] - this.Const.LevelXP[level - 1];

	local xpText = "MAX LEVEL";
	if (level < this.Const.LevelXP.len())
		xpText = _item.m.XP + " / " + this.Const.LevelXP[level];

	local woundsCalc = (100 - _item.m.Wounds);
	if (_item.m.Entity != null)
		woundsCalc = this.Math.floor(_item.m.Entity.getHitpointsPct() * 100.0);

	local displayName = _item.m.Name;
	try { displayName = _item.getName(); } catch (e) {}

	local nameText = displayName + " ([color=" + this.Const.UI.Color.PositiveValue + "]" + woundsCalc + "%[/color])";
	local levelText = "Level " + level + ", Health " + woundsCalc + "%";
	if (_item.m.Type == this.Const.Companions.TypeList.TomeReanimation)
	{
		nameText = displayName;
		levelText = "Level " + level;
	}

	local result = [
		{ id = 1, type = "title", text = nameText },
		{ id = 2, type = "description", text = _item.getDescription() },
		{ id = 3, type = "text", text = _item.getValueString() },
		{ id = 4, type = "text", text = "Worn in Accessory Slot" },
		{ id = 5, type = "text", text = "Usable in Combat" },
		{ id = 6, type = "text", text = levelText },
		{
			id = 7,
			type = "progressbar",
			icon = "ui/icons/xp_received.png",
			value = _item.m.XP - this.Const.LevelXP[level - 1],
			valueMax = xpMax,
			text = xpText,
			style = "armor-body-slim"
		}
	];

	local aHit = "Hitpoints" in _item.m.Attributes ? _item.m.Attributes.Hitpoints : 0;
	local aFat = "Stamina" in _item.m.Attributes ? _item.m.Attributes.Stamina : 0;
	local aRes = "Bravery" in _item.m.Attributes ? _item.m.Attributes.Bravery : 0;
	local aIni = "Initiative" in _item.m.Attributes ? _item.m.Attributes.Initiative : 0;
	local aMS = "MeleeSkill" in _item.m.Attributes ? _item.m.Attributes.MeleeSkill : 0;
	local aRS = "RangedSkill" in _item.m.Attributes ? _item.m.Attributes.RangedSkill : 0;
	local aMD = "MeleeDefense" in _item.m.Attributes ? _item.m.Attributes.MeleeDefense : 0;
	local aRD = "RangedDefense" in _item.m.Attributes ? _item.m.Attributes.RangedDefense : 0;

	local bufferHealth;
	local bufferStamina;
	local bufferBravery;
	local bufferInitiative;

	if (aHit < 10 || aFat < 10 || aRes < 10 || aIni < 10)
	{
		bufferHealth = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
		bufferStamina = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
		bufferBravery = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
		bufferInitiative = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
	}
	else
	{
		bufferHealth = "&nbsp;&nbsp;&nbsp;";
		bufferStamina = "&nbsp;&nbsp;&nbsp;";
		bufferBravery = "&nbsp;&nbsp;&nbsp;";
		bufferInitiative = "&nbsp;&nbsp;&nbsp;";
		if (aHit < 100 && aFat < 100 && aRes < 100 && aIni < 100)
		{
			bufferHealth += "&nbsp;&nbsp;";
			bufferStamina += "&nbsp;&nbsp;";
			bufferBravery += "&nbsp;&nbsp;";
			bufferInitiative += "&nbsp;&nbsp;";
		}
	}

	if (aHit < 10)
	{
		bufferHealth += "&nbsp;&nbsp;";
		bufferStamina += "&nbsp;&nbsp;";
		bufferBravery += "&nbsp;&nbsp;";
		bufferInitiative += "&nbsp;&nbsp;";
	}
	else if (aHit >= 10)
	{
		bufferStamina += "&nbsp;&nbsp;";
		bufferBravery += "&nbsp;&nbsp;";
		bufferInitiative += "&nbsp;&nbsp;";
		if (aHit >= 100)
		{
			bufferStamina += "&nbsp;&nbsp;";
			bufferBravery += "&nbsp;&nbsp;";
			bufferInitiative += "&nbsp;&nbsp;";
			if (aHit >= 1000)
			{
				bufferStamina += "&nbsp;&nbsp;";
				bufferBravery += "&nbsp;&nbsp;";
				bufferInitiative += "&nbsp;&nbsp;";
			}
		}
	}
	if (aFat < 10)
	{
		bufferHealth += "&nbsp;&nbsp;";
		bufferStamina += "&nbsp;&nbsp;";
		bufferBravery += "&nbsp;&nbsp;";
		bufferInitiative += "&nbsp;&nbsp;";
	}
	else if (aFat >= 10)
	{
		bufferHealth += "&nbsp;&nbsp;";
		bufferBravery += "&nbsp;&nbsp;";
		bufferInitiative += "&nbsp;&nbsp;";
		if (aFat >= 100)
		{
			bufferHealth += "&nbsp;&nbsp;";
			bufferBravery += "&nbsp;&nbsp;";
			bufferInitiative += "&nbsp;&nbsp;";
		}
	}
	if (aRes < 10)
	{
		bufferHealth += "&nbsp;&nbsp;";
		bufferStamina += "&nbsp;&nbsp;";
		bufferBravery += "&nbsp;&nbsp;";
		bufferInitiative += "&nbsp;&nbsp;";
	}
	else if (aRes >= 10)
	{
		bufferHealth += "&nbsp;&nbsp;";
		bufferStamina += "&nbsp;&nbsp;";
		bufferInitiative += "&nbsp;&nbsp;";
		if (aRes >= 100)
		{
			bufferHealth += "&nbsp;&nbsp;";
			bufferStamina += "&nbsp;&nbsp;";
			bufferInitiative += "&nbsp;&nbsp;";
		}
	}
	if (aIni < 10)
	{
		bufferHealth += "&nbsp;&nbsp;";
		bufferStamina += "&nbsp;&nbsp;";
		bufferBravery += "&nbsp;&nbsp;";
		bufferInitiative += "&nbsp;&nbsp;";
	}
	else if (aIni >= 10)
	{
		bufferHealth += "&nbsp;&nbsp;";
		bufferStamina += "&nbsp;&nbsp;";
		bufferBravery += "&nbsp;&nbsp;";
		if (aIni >= 100)
		{
			bufferHealth += "&nbsp;&nbsp;";
			bufferStamina += "&nbsp;&nbsp;";
			bufferBravery += "&nbsp;&nbsp;";
		}
	}

	result.extend([
		{
			id = 8,
			type = "text",
			text = _item.m.Type == this.Const.Companions.TypeList.TomeReanimation ? "The power of this incantation:" : "This individual\'s base attributes:"
		},
		{
			id = 9,
			type = "text",
			text = "[img]gfx/ui/icons/health_ac.png[/img] " + aHit + bufferHealth + "[img]gfx/ui/icons/melee_skill_ac.png[/img] " + aMS + ""
		},
		{
			id = 10,
			type = "text",
			text = "[img]gfx/ui/icons/fatigue_ac.png[/img] " + aFat + bufferStamina + "[img]gfx/ui/icons/ranged_skill_ac.png[/img] " + aRS + ""
		},
		{
			id = 11,
			type = "text",
			text = "[img]gfx/ui/icons/bravery_ac.png[/img] " + aRes + bufferBravery + "[img]gfx/ui/icons/melee_defense_ac.png[/img] " + aMD + ""
		},
		{
			id = 12,
			type = "text",
			text = "[img]gfx/ui/icons/initiative_ac.png[/img] " + aIni + bufferInitiative + "[img]gfx/ui/icons/ranged_defense_ac.png[/img] " + aRD + ""
		}
	]);

	local quirkString = "";
	local knownQuirks = [];
	if (_item.m.Quirks != null && _item.m.Quirks.len() != 0)
	{
		foreach (quirk in _item.m.Quirks)
		{
			try
			{
				local getQuirk = this.new(quirk);
				if ("getName" in getQuirk)
					knownQuirks.push(getQuirk.getName());
				else if ("Name" in getQuirk.m)
					knownQuirks.push(getQuirk.m.Name);
			}
			catch (error)
			{
			}
		}

		knownQuirks.sort();
		foreach (i, quirkName in knownQuirks)
		{
			quirkString += quirkName;
			if (i < knownQuirks.len() - 1)
				quirkString += ", ";
		}
	}

	if (knownQuirks.len() != 0)
	{
		result.push({
			id = 13,
			type = "text",
			text = _item.m.Type == this.Const.Companions.TypeList.TomeReanimation ? "And its additional effects:" : "And the quirks they possess:"
		});
		result.push({
			id = 14,
			type = "text",
			icon = "ui/icons/perks.png",
			text = quirkString
		});
	}

	if (_item.getIconLarge() != null)
	{
		result.push({
			id = 15,
			type = "image",
			image = _item.getIconLarge(),
			isLarge = true
		});
	}
	else
	{
		result.push({
			id = 15,
			type = "image",
			image = _item.getIcon()
		});
	}

	return result;
};
