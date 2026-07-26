// Companion foundation on wardog/warhound/wolf accessories.
// rawHookTree applies once per descendant; skip non-pet accessories via setEntity.
// Already-applied marker guards against double serialisation wraps (PHASE2 constraint 3).

::AC.HooksMod.rawHookTree("scripts/items/accessory/accessory", function(o)
{
		if ("setEntity" in o)
		{
			// Already-applied marker: prevent double-wrap if a class is visited twice.
			if ("mod_AC_FoundationApplied" in o.m)
				return;

			// Decision 3: yield wolf_item entirely to Reforged when present.
			if (::Hooks.hasMod("mod_reforged") && "Script" in o.m && o.m.Script == "scripts/entity/tactical/warwolf")
				return;

			o.m.mod_AC_FoundationApplied <- true;

			o.m.Skill <- null;
			o.m.Entity <- null;
			o.m.Script <- null;
			o.m.ArmorScript <- null;
			o.m.UnleashSounds <- null;
			o.m.InventorySounds <- null;
			o.m.Type <- null;
			o.m.Level <- 1;
			o.m.XP <- 0;
			o.m.Wounds <- 0;
			o.m.Quirks <- [];
			o.m.Attributes <- {	Hitpoints = 0,
								Stamina = 0,
								Bravery = 0,
								Initiative = 0,
								MeleeSkill = 0,
								RangedSkill = 0,
								MeleeDefense = 0,
								RangedDefense = 0	};

			// D6: wrap subclass create instead of jumping to accessory.create.
			local _ac_create = o.create;
			o.create = function()
			{
				_ac_create();

				// Most specific armoured classes first (they also isKindOf the base).
				if (this.isKindOf(this, "heavily_armored_wardog_item"))
				{
					this.m.ID = "accessory.heavily_armored_wardog";
					this.setType(this.Const.Companions.TypeList.WardogArmorHeavy);
				}
				else if (this.isKindOf(this, "armored_wardog_item"))
				{
					this.m.ID = "accessory.armored_wardog";
					this.setType(this.Const.Companions.TypeList.WardogArmor);
				}
				else if (this.isKindOf(this, "wardog_item"))
				{
					this.m.ID = "accessory.wardog";
					this.setType(this.Const.Companions.TypeList.Wardog);
				}
				else if (this.isKindOf(this, "heavily_armored_warhound_item"))
				{
					this.m.ID = "accessory.heavily_armored_warhound";
					this.setType(this.Const.Companions.TypeList.WarhoundArmorHeavy);
				}
				else if (this.isKindOf(this, "armored_warhound_item"))
				{
					this.m.ID = "accessory.armored_warhound";
					this.setType(this.Const.Companions.TypeList.WarhoundArmor);
				}
				else if (this.isKindOf(this, "warhound_item"))
				{
					this.m.ID = "accessory.warhound";
					this.setType(this.Const.Companions.TypeList.Warhound);
				}
				else if (this.isKindOf(this, "wolf_item"))
				{
					// Decision 3: yield wolf_item to Reforged when present.
					if (!::Hooks.hasMod("mod_reforged"))
					{
						this.m.ID = "accessory.warwolf";
						this.setType(this.Const.Companions.TypeList.Warwolf);
					}
				}
			}

			o.getType <- function()
			{
				return this.m.Type;
			}

			o.setType <- function(_t)
			{
				this.m.Type = _t;
				this.m.Name = this.Const.Companions.Library[this.m.Type].Name();
				this.m.Variant = this.Const.Companions.Library[this.m.Type].Variant();
				this.m.Attributes.Hitpoints = this.Const.Companions.Library[this.m.Type].BasicAttributes.Hitpoints;
				this.m.Attributes.Stamina = this.Const.Companions.Library[this.m.Type].BasicAttributes.Stamina;
				this.m.Attributes.Bravery = this.Const.Companions.Library[this.m.Type].BasicAttributes.Bravery;
				this.m.Attributes.Initiative = this.Const.Companions.Library[this.m.Type].BasicAttributes.Initiative;
				this.m.Attributes.MeleeSkill = this.Const.Companions.Library[this.m.Type].BasicAttributes.MeleeSkill;
				this.m.Attributes.RangedSkill = this.Const.Companions.Library[this.m.Type].BasicAttributes.RangedSkill;
				this.m.Attributes.MeleeDefense = this.Const.Companions.Library[this.m.Type].BasicAttributes.MeleeDefense;
				this.m.Attributes.RangedDefense = this.Const.Companions.Library[this.m.Type].BasicAttributes.RangedDefense;
				this.m.Quirks = [];
				if (this.Const.Companions.Library[this.m.Type].BasicQuirks.len() != 0)
				{
					foreach(quirk in this.Const.Companions.Library[this.m.Type].BasicQuirks)
					{
						if (this.m.Quirks.find(quirk) == null)
							this.m.Quirks.push(quirk);
					}
				}
				this.updateCompanion();
			}

			o.updateVariant <- function()
			{
			}

			o.updateCompanion <- function()
			{
				this.m.ID = this.Const.Companions.Library[this.m.Type].ID;
				this.m.Description = this.Const.Companions.Library[this.m.Type].Description;
				this.m.Value = this.Math.floor(this.Const.Companions.Library[this.m.Type].Value + ((this.m.Level - 1.00) * (this.Const.Companions.Library[this.m.Type].Value / 65.00)));
				this.m.Script = this.Const.Companions.Library[this.m.Type].Script;
				this.m.ArmorScript = this.Const.Companions.Library[this.m.Type].ArmorScript;
				this.m.UnleashSounds = this.Const.Companions.Library[this.m.Type].UnleashSounds;
				this.m.InventorySounds = this.Const.Companions.Library[this.m.Type].InventorySounds;
				this.setEntity(this.m.Entity);
			}

			o.getEntity <- function()
			{
				return this.m.Entity;
			}

			o.setEntity <- function(_e)
			{
				this.m.Entity = _e;

				if (this.m.Entity == null)
				{
					this.m.Icon = this.Const.Companions.Library[this.m.Type].IconLeashed(this.m.Variant);
				}
				else
				{
					this.m.Icon = this.Const.Companions.Library[this.m.Type].IconUnleashed;
				}
			}

			o.getName <- function()
			{
				if (this.m.Entity == null)
				{
					return this.m.Name;
				}
				else
				{
	//					return this.Const.Companions.Library[this.m.Type].NameUnleashed + " (" + this.m.Name + ")";
					return this.m.Name + "\'s Collar";
				}
			}

			o.setName <- function(_n)
			{
				this.m.Name = _n;
			}

			o.getDescription <- function()
			{
				if (this.m.Entity == null)
				{
					return this.m.Description;
				}
				else
				{
					return this.Const.Companions.Library[this.m.Type].DescriptionUnleashed;
				}
			}

			o.getScript <- function()
			{
				return this.m.Script;
			}

			o.getArmorScript <- function()
			{
				return this.m.ArmorScript;
			}

			o.playInventorySound <- function(_eventType)
			{
				if (this.m.InventorySounds != null && this.m.InventorySounds.len() > 0)
					this.Sound.play(this.m.InventorySounds[this.Math.rand(0, this.m.InventorySounds.len() - 1)], this.Const.Sound.Volume.Inventory);
			}

			o.isUnleashed <- function()
			{
				return this.m.Entity != null;
			}

			o.getTooltip <- function()
			{
				local xpMax = this.m.XP;
				if (this.m.Level < this.Const.LevelXP.len())
					xpMax = this.Const.LevelXP[this.m.Level] - this.Const.LevelXP[this.m.Level - 1];

				local xpText = "MAX LEVEL";
				if (this.m.Level < this.Const.LevelXP.len())
					xpText = this.m.XP + " / " + this.Const.LevelXP[this.m.Level];

				local woundsCalc = (100 - this.m.Wounds);
				if (this.m.Entity != null)
					woundsCalc = this.Math.floor(this.m.Entity.getHitpointsPct() * 100.0);

				local nameText = this.getName() + " ([color=" + this.Const.UI.Color.PositiveValue + "]" + woundsCalc + "%[/color])";
				local levelText = "Level " + this.m.Level + ", Health " + woundsCalc + "%"
				if (this.m.Type == this.Const.Companions.TypeList.TomeReanimation)
				{
					nameText = this.getName();
					levelText = "Level " + this.m.Level;
				}

				local result = [
					{
						id = 1,
						type = "title",
						text = nameText
					},
					{
						id = 2,
						type = "description",
						text = this.getDescription()
					},
					{
						id = 3,
						type = "text",
						text = this.getValueString()
					},
					{
						id = 4,
						type = "text",
						text = "Worn in Accessory Slot"
					},
					{
						id = 5,
						type = "text",
						text = "Usable in Combat"
					},
					{
						id = 6,
						type = "text",
						text = levelText
					},
					{
						id = 7,
						type = "progressbar",
						icon = "ui/icons/xp_received.png",
						value = this.m.XP - this.Const.LevelXP[this.m.Level - 1],
						valueMax = xpMax,
						text = xpText,
						style = "armor-body-slim"
					}
				];

				local aHit = this.m.Attributes.Hitpoints;
				local aFat = this.m.Attributes.Stamina;
				local aRes = this.m.Attributes.Bravery;
				local aIni = this.m.Attributes.Initiative;
				local aMS = this.m.Attributes.MeleeSkill;
				local aRS = this.m.Attributes.RangedSkill;
				local aMD = this.m.Attributes.MeleeDefense;
				local aRD = this.m.Attributes.RangedDefense;

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

				local attribs = [
					{
						id = 8,
						type = "text",
						text = this.m.Type == this.Const.Companions.TypeList.TomeReanimation ? "The power of this incantation:" : "This individual\'s base attributes:"
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
				];
				result.extend(attribs);

				local quirkString = "";
				local knownQuirks = [];
				if (this.m.Quirks.len() != 0)
				{
					foreach(i, quirk in this.m.Quirks)
					{
						local getQuirk = this.new(quirk);
						knownQuirks.push(getQuirk.m.Name);
					}
			
					knownQuirks.sort();
					foreach(i, quirk in knownQuirks)
					{
						quirkString += quirk;

						if (i < this.m.Quirks.len() - 1)
						{
							quirkString += ", ";
						}
					}
				}

				if (this.m.Quirks.len() != 0)
				{
					result.push({
						id = 13,
						type = "text",
						text = this.m.Type == this.Const.Companions.TypeList.TomeReanimation ? "And its additional effects:" : "And the quirks they possess:"
					});

					result.push({
						id = 14,
						type = "text",
						icon = "ui/icons/perks.png",
						text = quirkString
					});
				}

				if (this.getIconLarge() != null)
				{
					result.push({
						id = 15,
						type = "image",
						image = this.getIconLarge(),
						isLarge = true
					});
				}
				else
				{
					result.push({
						id = 15,
						type = "image",
						image = this.getIcon()
					});
				}

				return result;
			}

			o.onEquip <- function()
			{
				this.accessory.onEquip();
				local unleash = this.new(this.Const.Companions.Library[this.m.Type].Unleash.Script);
				unleash.setItem(this);
				unleash.applyCompanionModification();
				this.m.Skill = this.WeakTableRef(unleash);
				this.addSkill(unleash);
				local leash = this.new(this.Const.Companions.Library[this.m.Type].Leash.Script);
				leash.setItem(this);
				leash.applyCompanionModification();
				this.addSkill(leash);
			}

			o.onCombatFinished <- function()
			{
				if (this.m.Entity != null)
				{
					this.m.Wounds = this.Math.floor((1.0 - this.m.Entity.getHitpointsPct()) * 100.0);
				}

				this.setEntity(null);
			}

			o.onActorDied <- function(_onTile)
			{
				if (this.m.Type != null && !this.isUnleashed() && _onTile != null && this.getScript() != null && this.Const.Companions.Library[this.m.Type].Unleash.onActorDied)
				{
					local entity = this.Tactical.spawnEntity(this.getScript(), _onTile.Coords.X, _onTile.Coords.Y);
					entity.setItem(this);
					entity.setName(this.getName());
					entity.setVariant(this.getVariant());
					entity.setFaction(this.Const.Faction.PlayerAnimals);
					entity.applyCompanionScaling();
					this.setEntity(entity);

					if (this.getArmorScript() != null)
					{
						local item = this.new(this.getArmorScript());
						entity.getItems().equip(item);
					}

					if (!this.World.getTime().IsDaytime)
					{
						entity.getSkills().add(this.new("scripts/skills/special/night_effect"));
					}

					local healthPercentage = (100.0 - this.m.Wounds) / 100.0;
					entity.setHitpoints(this.Math.max(1, this.Math.floor(healthPercentage * entity.m.Hitpoints)));
					entity.setDirty(true);
					if (this.m.UnleashSounds != null && this.m.UnleashSounds.len() > 0)
					this.Sound.play(this.m.UnleashSounds[this.Math.rand(0, this.m.UnleashSounds.len() - 1)], this.Const.Sound.Volume.Skill, _onTile.Pos);
				}
			}

			o.isAmountShown <- function()
			{
				return true;
			}

			o.getAmountString <- function()
			{
				return "Level " + this.m.Level;
			}

			o.getXPToNextLevelPercentage <- function()
			{
				if (this.m.Level >= this.Const.LevelXP.len())
					return "MAX";

				local tnl = this.Math.floor(((this.m.XP - this.Const.LevelXP[this.m.Level - 1]) / (this.Const.LevelXP[this.m.Level] - this.Const.LevelXP[this.m.Level - 1])) * 100);

				if (tnl > 99)
					tnl = 99;

				return "" + tnl + "%";
			}

			o.addXP <- function(_xp)
			{
				if (this.m.Level >= this.Const.LevelXP.len())
				{
					return;
				}

				_xp = _xp * 0.67;
				_xp = _xp * this.Const.Combat.GlobalXPMult;

				if (this.getContainer() != null && !this.getContainer().isNull() && this.getContainer().getActor() != null && !this.getContainer().getActor().isNull() && this.getContainer().getActor().m.Type == this.Const.EntityType.Player && this.m.Type != this.Const.Companions.TypeList.TomeReanimation)
				{
					local actor = this.getContainer().getActor();
					if (actor.getSkills().hasSkill("background.companions_beastmaster"))
					{
						_xp = _xp * (1.15 + (actor.getLevel() / 66.667));
					}
					else if (actor.getSkills().hasSkill("background.houndmaster"))
					{
						_xp = _xp * (1.1 + (actor.getLevel() / 100.0));
					}
				}

				if (this.m.Level >= 11)
				{
					_xp = _xp * this.Const.Combat.GlobalXPVeteranLevelMult;
				}

				if (this.m.XP + _xp >= this.Const.LevelXP[this.Const.LevelXP.len() - 1])
				{
					this.m.XP = this.Const.LevelXP[this.Const.LevelXP.len() - 1];
					this.updateLevel();
					return;
				}

				this.m.XP += this.Math.floor(_xp);
				this.updateLevel();
			}

			o.updateLevel <- function()
			{
				local applyAttributeBonus = function(attribute)
				{
					local attributeMin = this.Const.AttributesLevelUp[attribute].Min;
					local attributeMax = this.Const.AttributesLevelUp[attribute].Max;
					local attributeValue = this.m.Level <= 11 ? this.Math.rand(attributeMin, attributeMax) : 1;
					switch (attribute)
					{
						case 0:
							this.m.Attributes.Hitpoints += attributeValue;
							break;
						case 1:
							this.m.Attributes.Bravery += attributeValue;
							break;
						case 2:
							this.m.Attributes.Stamina += attributeValue;
							break;
						case 3:
							this.m.Attributes.Initiative += attributeValue;
							break;
						case 4:
							this.m.Attributes.MeleeSkill += attributeValue;
							break;
						case 5:
							this.m.Attributes.RangedSkill += attributeValue;
							break;
						case 6:
							this.m.Attributes.MeleeDefense += attributeValue;
							break;
						case 7:
							this.m.Attributes.RangedDefense += attributeValue;
							break;
					}
				}

				local availableQuirks = [];
				foreach(quirk in this.Const.Companions.AttainableQuirks)
				{
					if (quirk == "scripts/skills/perks/perk_lone_wolf" && this.m.Type == this.Const.Companions.TypeList.Noodle)
						continue;

					if (this.m.Quirks.find(quirk) == null && availableQuirks.find(quirk) == null)
						availableQuirks.push(quirk);
				}
				foreach(quirk in this.Const.Companions.AttainableQuirksBeasts)
				{
					if (this.m.Type == this.Const.Companions.TypeList.TomeReanimation)
						continue;

					if (this.m.Quirks.find(quirk) == null && availableQuirks.find(quirk) == null)
						availableQuirks.push(quirk);
				}
				if (this.Const.DLC.Unhold)
				{
					foreach(quirk in this.Const.Companions.AttainableQuirksDLCUnhold)
					{
						if (this.m.Quirks.find(quirk) == null && availableQuirks.find(quirk) == null)
							availableQuirks.push(quirk);
					}
				}
				if (this.Const.DLC.Wildmen)
				{
					foreach(quirk in this.Const.Companions.AttainableQuirksDLCWildmen)
					{
						if (this.m.Quirks.find(quirk) == null && availableQuirks.find(quirk) == null)
							availableQuirks.push(quirk);
					}
				}
				if (this.Const.DLC.Desert)
				{
					foreach(quirk in this.Const.Companions.AttainableQuirksDLCDesert)
					{
						if (this.m.Quirks.find(quirk) == null && availableQuirks.find(quirk) == null)
							availableQuirks.push(quirk);
					}
				}

				while (this.m.Level < this.Const.LevelXP.len() && this.m.XP >= this.Const.LevelXP[this.m.Level])
				{
					++this.m.Level;
					this.updateCompanion();
					local attributeArray = [0, 1, 2, 3, 4, 5, 6, 7]; // all attributes
					applyAttributeBonus(this.Const.Companions.Library[this.m.Type].PreferredAttribute);
					attributeArray.remove(this.Const.Companions.Library[this.m.Type].PreferredAttribute);

					local bonusesSpent = 1;
					while (bonusesSpent < 3)
					{
						local randomAttribute = this.Math.rand(0, attributeArray.len() - 1);
						applyAttributeBonus(attributeArray[randomAttribute]);
						attributeArray.remove(randomAttribute);
						++bonusesSpent;
					}
					if (this.m.Level <= 11)
					{
						if (availableQuirks.len() != 0)
						{
							local rng = this.Math.rand(0, availableQuirks.len() - 1);
							this.m.Quirks.push(availableQuirks[rng]);
							availableQuirks.remove(rng);
						}

						if (this.m.Level == 11 && this.m.Type != this.Const.Companions.TypeList.TomeReanimation)
						{
							this.m.Quirks.push("scripts/companions/quirks/companions_good_boy");
						}
					}
				}
			}

			o.getLevel <- function()
			{
				return this.m.Level;
			}

			o.setLevel <- function(_l)
			{
				this.m.Level = _l;
			}

			o.getXP <- function()
			{
				return this.m.XP;
			}

			o.setXP <- function(_xp)
			{
				this.m.XP = _xp;
			}

			o.getQuirks <- function()
			{
				return this.m.Quirks;
			}

			o.setQuirks <- function(_q)
			{
				this.m.Quirks = _q;
			}

			o.getAttributes <- function()
			{
				local attr =
				{
					Hitpoints = this.m.Attributes.Hitpoints,
					Stamina = this.m.Attributes.Stamina,
					Bravery = this.m.Attributes.Bravery,
					Initiative = this.m.Attributes.Initiative,
					MeleeSkill = this.m.Attributes.MeleeSkill,
					RangedSkill = this.m.Attributes.RangedSkill,
					MeleeDefense = this.m.Attributes.MeleeDefense,
					RangedDefense = this.m.Attributes.RangedDefense
				};

				return attr;
			}

			o.setAttributes <- function(_a)
			{
				this.m.Attributes.Hitpoints = _a.Hitpoints;
				this.m.Attributes.Stamina = _a.Stamina;
				this.m.Attributes.Bravery = _a.Bravery;
				this.m.Attributes.Initiative = _a.Initiative;
				this.m.Attributes.MeleeSkill = _a.MeleeSkill;
				this.m.Attributes.RangedSkill = _a.RangedSkill;
				this.m.Attributes.MeleeDefense = _a.MeleeDefense;
				this.m.Attributes.RangedDefense = _a.RangedDefense;
			}

			o.getWounds <- function()
			{
				return this.m.Wounds;
			}

			o.setWounds <- function(_w)
			{
				this.m.Wounds = _w;
			}

			o.serializeCompanionName <- function()
			{
				local nameCopy = this.m.Name;
				local serializedName = nameCopy += "\nmod_AC=" + this.m.Type + "," + this.m.Level + "," + this.m.XP + "," + this.m.Wounds + ",A=" + this.m.Attributes.Hitpoints + "," + this.m.Attributes.Stamina + "," + this.m.Attributes.Bravery + "," + this.m.Attributes.Initiative + "," + this.m.Attributes.MeleeSkill + "," + this.m.Attributes.RangedSkill + "," + this.m.Attributes.MeleeDefense + "," + this.m.Attributes.RangedDefense + ",Q=";

				// A quirk added by another mod has no slot in SerializeQuirks, and
				// find() returns null there -- which used to concatenate "(null)"
				// into the payload and blow up tointeger() on the next load.
				local written = 0;
				foreach(quirk in this.m.Quirks)
				{
					local getQuirk = this.new(quirk);
					local code = null;
				if (getQuirk.m.ID in this.Const.Companions.SerializeQuirksByID)
					code = this.Const.Companions.SerializeQuirksByID[getQuirk.m.ID];

					if (code == null)
					{
						this.logWarning("mod_AC: quirk \'" + getQuirk.m.ID + "\' is not in SerializeQuirks and cannot be saved; dropping it.");
						continue;
					}

					if (written > 0) serializedName += ",";
					serializedName += code;
					written = written + 1;
				}

				return serializedName;
			}

			// tointeger() is not total in Squirrel -- an empty or non-numeric field
			// throws, and this runs during savegame load. Returns null on anything
			// that is not a plain integer so callers can decide what to do.
			o.parseCompanionInt <- function(_s)
			{
				if (_s == null || _s.len() == 0)
				{
					return null;
				}

				foreach(i, c in _s)
				{
					if (i == 0 && c == '-' && _s.len() > 1) continue;
					if (c < '0' || c > '9') return null;
				}

				return _s.tointeger();
			}

			o.deserializeCompanionName <- function(_cn)
			{
				local nameMod = "\nmod_AC=";
				local findMod = _cn.find(nameMod);

				if (findMod == null)
				{
					// No payload. Either this item predates the mod, or another mod
					// won the onSerialize slot when the game was saved. Keep whatever
					// the class defaults gave us rather than inventing state.
					this.m.Name = _cn;
					return;
				}

				// Everything below runs while a savegame is being loaded, so it must
				// not throw: a single bad field would otherwise take down the whole
				// load. Anything unparseable leaves the existing value in place.
				local slicedName = _cn.slice(0, findMod);
				local slicedDetails = _cn.slice(findMod + nameMod.len());
				local nameAttributes = "A=";
				local nameQuirks = "Q=";
				local findAttributes = slicedDetails.find(nameAttributes);
				local findQuirks = slicedDetails.find(nameQuirks);

				if (findAttributes == null || findQuirks == null || findQuirks < findAttributes)
				{
					this.logWarning("mod_AC: companion payload on \'" + slicedName + "\' is malformed; keeping default stats.");
					this.m.Name = slicedName;
					return;
				}

				local arrayBasics = split(slicedDetails.slice(0, findAttributes - 1), ",");
				local arrayAttributes = split(slicedDetails.slice(findAttributes + nameAttributes.len(), findQuirks - 1), ",");
				local arrayQuirks = split(slicedDetails.slice(findQuirks + nameQuirks.len()), ",");

				if (arrayBasics.len() < 3 || arrayAttributes.len() < 8)
				{
					this.logWarning("mod_AC: companion payload on \'" + slicedName + "\' is truncated (" + arrayBasics.len() + " basics, " + arrayAttributes.len() + " attributes); keeping default stats.");
					this.m.Name = slicedName;
					return;
				}

				local type = this.parseCompanionInt(arrayBasics[0]);

				if (type == null || type < 0 || type >= this.Const.Companions.Library.len())
				{
					this.logWarning("mod_AC: companion type \'" + arrayBasics[0] + "\' on \'" + slicedName + "\' is not a valid type; keeping default type.");
					this.m.Name = slicedName;
					return;
				}

				this.m.Type = type;

				local level = this.parseCompanionInt(arrayBasics[1]);
				local xp = this.parseCompanionInt(arrayBasics[2]);

				if (level != null) this.m.Level = level;
				if (xp != null) this.m.XP = xp;

				if (arrayBasics.len() >= 4)
				{
					local wounds = this.parseCompanionInt(arrayBasics[3]);
					if (wounds != null) this.m.Wounds = wounds;
				}

				local attributeNames = ["Hitpoints", "Stamina", "Bravery", "Initiative", "MeleeSkill", "RangedSkill", "MeleeDefense", "RangedDefense"];
				foreach(i, key in attributeNames)
				{
					local value = this.parseCompanionInt(arrayAttributes[i]);

					if (value != null)
						this.m.Attributes[key] = value;
				}

				// Quirk codes can be stale if another mod's quirks were saved, or if
				// DeserializeQuirks changed between versions. Skip what we can't map.
				this.m.Quirks = [];
				foreach(code in arrayQuirks)
				{
					local index = this.parseCompanionInt(code);

					if (index == null)
					{
						continue;    // empty trailing field when the companion has no quirks
					}

					if (index < 0 || index >= this.Const.Companions.DeserializeQuirks.len())
					{
						this.logWarning("mod_AC: unknown quirk code " + index + " on \'" + slicedName + "\'; skipping it.");
						continue;
					}

					this.m.Quirks.push(this.Const.Companions.DeserializeQuirks[index]);
				}

				this.m.Name = slicedName;
			}

			// D1: wrap parent serialisation; keep one-string stream shape.
			local _ac_onSerialize = o.onSerialize;
			o.onSerialize = function( _out )
			{
				local oldName = this.m.Name;
				this.m.Name = this.serializeCompanionName();
				_ac_onSerialize(_out);
				this.m.Name = oldName;
			}

			local _ac_onDeserialize = o.onDeserialize;
			o.onDeserialize = function( _in )
			{
				_ac_onDeserialize(_in);
				this.deserializeCompanionName(this.m.Name);
				this.updateCompanion();
			}
		}
});
