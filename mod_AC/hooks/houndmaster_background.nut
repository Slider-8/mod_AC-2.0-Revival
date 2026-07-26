// Beastmaster hide-in-Houndmaster + draft serialisation
::AC.HooksMod.hook("scripts/skills/backgrounds/houndmaster_background", function(q)
{
	q.applyBeastmasterModification <- function()
	{
		this.m.ID = "background.companions_beastmaster";
		this.m.Name = "Beastmaster";
		this.m.Icon = "ui/backgrounds/background_beastmaster_ac.png";
		this.m.BackgroundDescription = "Beastmasters are used to handle various beasts.";
		this.m.GoodEnding = "Beasts were not simply \'beasts\' to %name%, despite his title as \'beastmaster.\' To him, they were the most loyal friends of his life. After leaving the company, he discovered an ingenious way to breed the animals specifically tailored to the desires of the nobility. Wanted a brutish beast for a guard? He could do it. Wanted something small and cuddly for the children? He could do that, too. The former mercenary now earns an incredible earning doing what he loves - working with beasts.";
		this.m.BadEnding = "What\'s merely a beast to one man is a loyal companion to %name%. After leaving the company, the beastmaster went out to work for the nobility. Unfortunately, he refused to let hundreds of his beasts be used as a battle vanguard to be thrown away for some short-lived tactical advantage. He was hanged for his \'traitorous ideals\'.";
		this.m.HiringCost = 100;
		this.m.DailyCost = 21;
		this.m.Excluded = [
			"trait.fear_beasts",
			"trait.hate_beasts",
			"trait.craven",
			"trait.dastard",
			"trait.fainthearted",
			"trait.insecure",
			"trait.ailing",
			"trait.bleeder",
			"trait.tiny",
			"trait.fragile",
			"trait.asthmatic",
			"trait.clubfooted",
			"trait.clumsy",
			"trait.cocky"
		];
		this.m.ExcludedTalents = [
			this.Const.Attributes.RangedSkill,
			this.Const.Attributes.RangedDefense
		];
		this.m.Titles = [
			"the Beastmaster",
			"the Tamer"
		];
		this.m.Faces = this.Const.Faces.AllMale;
		this.m.Hairs = this.Const.Hair.UntidyMale;
		this.m.HairColors = this.Const.HairColors.All;
		this.m.Beards = this.Const.Beards.Untidy;
		this.m.Bodies = this.Const.Bodies.AllMale;
		this.m.IsLowborn = false;
		this.m.Level = this.Math.rand(1, 3);
	}

	// Beastmaster conversion lives here, not on player.setStartValuesEx.
	// mod_modular_vanilla *replaces* setStartValuesEx without calling __original,
	// which would silently drop a player-side wrap. onAdded is uncontested and
	// runs from Skills.add(background) inside every setStartValuesEx path
	// (vanilla and modular_vanilla), before attributes/equipment are built.
	q.onAdded = @(__original) function()
	{
		if (this.m.IsNew && this.m.ID == "background.houndmaster")
		{
			if (!(("State" in this.Tactical) && this.Tactical.State != null && this.Tactical.State.isScenarioMode()))
			{
				local town = null;
				if (("State" in this.World) && this.World.State != null)
					town = this.World.State.getCurrentTown();

				if (town != null && ("AC_isBeastmasterTown" in town) && town.AC_isBeastmasterTown())
					this.applyBeastmasterModification();
			}
		}

		__original();
	}

	// D10: match tooltip entries by id, not fixed array indices.
	q.getTooltip = @(__original) function()
	{
		local tooltip = __original();
		local insertAt = tooltip.len();

		foreach (i, entry in tooltip)
		{
			if (("id" in entry) && entry.id == 14)
			{
				entry.text = "Beasts unleashed by this character will start at confident morale.";
				insertAt = i + 1;
				break;
			}
		}

		tooltip.insert(insertAt, { id = 4, type = "text", icon = "ui/icons/xp_received.png", text = "Beasts handled by this character gain more experience." });

		if (this.m.ID == "background.companions_beastmaster")
		{
			tooltip.insert(insertAt + 1, { id = 5, type = "text", icon = "ui/icons/special.png", text = "Higher chance of success when taming beasts." });
		}

		return tooltip;
	}

	q.onBuildDescription = @(__original) function()
	{
		if (this.m.ID == "background.companions_beastmaster")
		{
			return "{%name%\'s affection for beasts started after his father won a serpent in a shooting contest. | When a direwolf saved him from a bear, %name% dedicated his life to beasts of all sorts. | Seeing a webknecht stave off a would-be robber, %name%\'s fondness for beasts only grew. | A young, bird-hunting %name% quickly saw the honor, loyalty, and workmanship of a trained beast. | Once bitten by a wild hyena, %name% confronted his fear of beasts by learning to train them.} {The beastmaster spent many years working for a local lord. He gave up the post after the liege struck one of his post-ferals down just for sport. | Quick with training the wildlife, the beastmaster put his post-ferals into a lucrative traveling tradeshow. | The man made a great deal of money on the beast-fighting circuits, his post-ferals renowned for their easily commanded - and unleashed - ferocity. | Employed by lawmen, the beastmaster used his strong-nosed post-ferals to hunt down many a criminal element. | Used by a local lord, many of the beastmaster\'s post-ferals found their way onto the battlefield. | For many years, the beastmaster used his post-ferals to help lift the spirits of orphaned children and the crippled.} {Now, though, %name% seeks a change of vocation. | When he heard word of a mercenary\'s pay, %name% decided to try his hand at being a sellsword. | Approached by a sellsword to buy one of his creatures, %name% became more interested in the prospect of he, himself, becoming a mercenary. | Tired of training creatures for this purpose or that, %name% seeks to train himself for... well, this purpose or that. | An interesting prospect, you can only hope %name% is as loyal as the creatures he once commanded.}";
		}
		else
		{
			return __original();
		}
	}

	q.onChangeAttributes = @(__original) function()
	{
		if (this.m.ID == "background.companions_beastmaster")
		{
			local c = {
				Hitpoints = [10, 5],
				Bravery = [10, 10],
				Stamina = [10, 5],
				MeleeSkill = [0, 0],
				RangedSkill = [0, 0],
				MeleeDefense = [6, 6],
				RangedDefense = [0, 0],
				Initiative = [10, 5]
			};
			return c;
		}
		else
		{
			return __original();
		}
	}

	q.onAddEquipment = @(__original) function()
	{
		if (this.m.ID == "background.companions_beastmaster")
		{
			local items = this.getContainer().getActor().getItems();

			///// mainhand
			local r = this.Math.rand(1, 3);
			if (r == 1)
			{
				local rr;
				if (this.Const.DLC.Wildmen)
				{
					rr = this.Math.rand(1, 2);
				}
				else
				{
					rr = this.Math.rand(1, 1);
				}

				if (rr == 1)
				{
					items.equip(this.new("scripts/items/weapons/battle_whip"));
				}
				else if (rr == 2)
				{
					items.equip(this.new("scripts/items/weapons/barbarians/thorned_whip"));
				}
			}
			else
			{
				local rr;
				if (this.Const.DLC.Wildmen)
				{
					rr = this.Math.rand(1, 20);
				}
				else
				{
					rr = this.Math.rand(1, 15);
				}

				if (rr == 1)
				{
					items.equip(this.new("scripts/items/weapons/dagger"));
				}
				else if (rr == 2)
				{	
					items.equip(this.new("scripts/items/weapons/shortsword"));
				}
				else if (rr == 3)
				{
					items.equip(this.new("scripts/items/weapons/falchion"));
				}
				else if (rr == 4)
				{
					items.equip(this.new("scripts/items/weapons/bludgeon"));
				}
				else if (rr == 5)
				{
					items.equip(this.new("scripts/items/weapons/morning_star"));
				}
				else if (rr == 6)
				{
					items.equip(this.new("scripts/items/weapons/militia_spear"));
				}
				else if (rr == 7)
				{
					items.equip(this.new("scripts/items/weapons/boar_spear"));
				}
				else if (rr == 8)
				{
					items.equip(this.new("scripts/items/weapons/hatchet"));
				}
				else if (rr == 9)
				{
					items.equip(this.new("scripts/items/weapons/hand_axe"));
				}
				else if (rr == 10)
				{
					items.equip(this.new("scripts/items/weapons/reinforced_wooden_flail"));
				}
				else if (rr == 11)
				{
					items.equip(this.new("scripts/items/weapons/flail"));
				}
				else if (rr == 12)
				{
					items.equip(this.new("scripts/items/weapons/butchers_cleaver"));
				}
				else if (rr == 13)
				{
					items.equip(this.new("scripts/items/weapons/scramasax"));
				}
				else if (rr == 14)
				{
					items.equip(this.new("scripts/items/weapons/pickaxe"));
				}
				else if (rr == 15)
				{
					items.equip(this.new("scripts/items/weapons/military_pick"));
				}
				else if (rr == 16)
				{
					items.equip(this.new("scripts/items/weapons/barbarians/claw_club"));
				}
				else if (rr == 17)
				{
					items.equip(this.new("scripts/items/weapons/barbarians/crude_axe"));
				}
				else if (rr == 18)
				{
					items.equip(this.new("scripts/items/weapons/barbarians/axehammer"));
				}
				else if (rr == 19)
				{
					items.equip(this.new("scripts/items/weapons/barbarians/antler_cleaver"));
				}
				else if (rr == 20)
				{
					items.equip(this.new("scripts/items/weapons/barbarians/blunt_cleaver"));
				}
			}

			///// offhand
			r = this.Math.rand(1, 3);
			if (r == 1)
			{
				items.equip(this.new("scripts/items/tools/throwing_net"));
			}
			else
			{
				local rr = this.Math.rand(1, 2);
				if (rr == 1)
				{
					items.equip(this.new("scripts/items/shields/buckler_shield"));
				}
				else if (rr == 2)
				{
					items.equip(this.new("scripts/items/shields/wooden_shield"));
				}
			}

			///// helmet
			if (this.Const.DLC.Wildmen)
			{
				r = this.Math.rand(1, 6);
			}
			else
			{
				r = this.Math.rand(1, 4);
			}

			if (r == 1)
			{
				items.equip(this.new("scripts/items/helmets/mouth_piece"));
			}
			else if (r == 2)
			{
				items.equip(this.new("scripts/items/helmets/open_leather_cap"));
			}
			else if (r == 3)
			{
				items.equip(this.new("scripts/items/helmets/full_leather_cap"));
			}
			else if (r == 4)
			{
				items.equip(this.new("scripts/items/helmets/rusty_mail_coif"));
			}
			else if (r == 5)
			{
				items.equip(this.new("scripts/items/helmets/barbarians/leather_headband"));
			}
			else if (r == 6)
			{
				items.equip(this.new("scripts/items/helmets/barbarians/bear_headpiece"));
			}

			///// armor
			if (this.Const.DLC.Wildmen)
			{
				r = this.Math.rand(1, 10);
			}
			else
			{
				r = this.Math.rand(1, 5);
			}

			if (r == 1)
			{
				items.equip(this.new("scripts/items/armor/ragged_surcoat"));
			}
			else if (r == 2)
			{
				items.equip(this.new("scripts/items/armor/blotched_gambeson"));
			}
			else if (r == 3)
			{
				items.equip(this.new("scripts/items/armor/padded_leather"));
			}
			else if (r == 4)
			{
				items.equip(this.new("scripts/items/armor/patched_mail_shirt"));
			}
			else if (r == 5)
			{
				items.equip(this.new("scripts/items/armor/worn_mail_shirt"));
			}
			else if (r == 6)
			{
				items.equip(this.new("scripts/items/armor/barbarians/thick_furs_armor"));
			}
			else if (r == 7)
			{
				items.equip(this.new("scripts/items/armor/barbarians/animal_hide_armor"));
			}
			else if (r == 8)
			{
				items.equip(this.new("scripts/items/armor/barbarians/reinforced_animal_hide_armor"));
			}
			else if (r == 9)
			{
				items.equip(this.new("scripts/items/armor/barbarians/scrap_metal_armor"));
			}
			else if (r == 10)
			{
				items.equip(this.new("scripts/items/armor/barbarians/hide_and_bone_armor"));
			}
		}
		else
		{
			__original();
		}
	}

	q.serializeRawDescription <- function()
	{
		if (this.m.ID == "background.companions_beastmaster")
		{
			local cloneRawDescription = this.m.RawDescription;
			local serializedRawDescription = cloneRawDescription + "\nmod_AC=Beastmaster";
			return serializedRawDescription;
		}

		return this.m.RawDescription;
	}

	q.deserializeRawDescription <- function(_rd)
	{
		local nameMod = "\nmod_AC=Beastmaster";
		local findMod = _rd.find(nameMod);
		if (findMod != null)
		{
			local slicedRaw = _rd.slice(0, findMod);
			this.m.RawDescription = slicedRaw;
			this.applyBeastmasterModification();
		}
		else
		{
			this.m.RawDescription = _rd;
		}
	}

	q.onSerialize <- function(_out)
	{
		this.skill.onSerialize(_out);
		_out.writeString(this.m.Description);
		_out.writeString(this.serializeRawDescription());
		_out.writeU8(this.m.Level);
		_out.writeBool(this.m.IsNew);
		_out.writeF32(this.m.DailyCostMult);
	}

	q.onDeserialize <- function(_in )
	{
		this.skill.onDeserialize(_in);
		this.m.Description = _in.readString();
		this.deserializeRawDescription(_in.readString());
		this.m.Level = _in.readU8();
		this.m.IsNew = _in.readBool();

		if (_in.getMetaData().getVersion() >= 39)
		{
			this.m.DailyCostMult = _in.readF32();
		}
		else
		{
			this.m.DailyCostMult = 1.0;
		}
	}
});
