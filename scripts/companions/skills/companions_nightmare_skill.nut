this.companions_nightmare_skill <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "actives.nightmare";
		this.m.Name = "Nightmare";
		this.m.Description = "";
		this.m.KilledString = "Died of nightmares";
		this.m.Icon = "skills/active_117.png";
		this.m.IconDisabled = "skills/active_117.png";
		this.m.Overlay = "active_117";
		this.m.SoundOnUse = [
			"sounds/enemies/dlc2/alp_nightmare_01.wav",
			"sounds/enemies/dlc2/alp_nightmare_02.wav",
			"sounds/enemies/dlc2/alp_nightmare_03.wav",
			"sounds/enemies/dlc2/alp_nightmare_04.wav",
			"sounds/enemies/dlc2/alp_nightmare_05.wav",
			"sounds/enemies/dlc2/alp_nightmare_06.wav"
		];
		this.m.IsUsingActorPitch = true;
		this.m.Type = this.Const.SkillType.Active;
		this.m.Order = this.Const.SkillOrder.OffensiveTargeted;
		this.m.Delay = 400;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = true;
		this.m.IsStacking = false;
		this.m.IsAttack = true;
		this.m.IsUsingHitchance = false;
		this.m.IsIgnoredAsAOO = true;
		this.m.IsUsingHitchance = false;
		this.m.IsDoingForwardMove = false;
		this.m.IsVisibleTileNeeded = false;
		this.m.DirectDamageMult = 1.0;
		this.m.ActionPointCost = 4;
		this.m.FatigueCost = 10;
		this.m.MinRange = 1;
		this.m.MaxRange = 2;
		this.m.MaxLevelDifference = 4;
	}

	function getDamage( _actor )
	{
		// The nightmare hit is resolved 400ms after onUse. If the alp dies inside
		// that window its onDeath has already cleared m.Item, so the Good Boy bonus
		// has to tolerate the item being gone.
		local bonusMin = 0;
		local bonusMax = 0;
		local container = this.getContainer();
		local user = container == null ? null : container.getActor();

		if (user != null && user.m.Item != null && user.getSkills().hasSkill("quirk.good_boy"))
		{
			bonusMin = (user.m.Item.m.Level - 10.0) * 0.5;
			bonusMax = (user.m.Item.m.Level - 10.0) * 1.0;
		}

		local bonusRng = this.Math.floor(this.Math.rand(bonusMin, bonusMax));
		return this.Math.max(5 + bonusRng, (25 - this.Math.floor(_actor.getCurrentProperties().getBravery() * 0.25)) + bonusRng);
	}

	function isUsable()
	{
		if (!this.skill.isUsable())
		{
			return false;
		}

		local b = this.getContainer().getActor().getAIAgent().getBehavior(this.Const.AI.Behavior.ID.AttackDefault);
		local targets = b.queryTargetsInMeleeRange(this.getMinRange(), this.getMaxRange());
		local myTile = this.getContainer().getActor().getTile();

		foreach( t in targets )
		{
			if (this.onVerifyTarget(myTile, t.getTile()))
			{
				return true;
			}
		}

		return false;
	}

	function onVerifyTarget( _originTile, _targetTile )
	{
		if (!this.skill.onVerifyTarget(_originTile, _targetTile))
		{
			return false;
		}

		// Only valid against a sleeping target. Checked after the base class so
		// that its empty-tile guard runs first.
		local target = _targetTile.getEntity();
		return target != null && target.getSkills().getSkillByID("effects.sleeping") != null;
	}

	function onUpdate( _properties )
	{
		_properties.DamageRegularMin += 10;
		_properties.DamageRegularMax += 25;
		_properties.IsIgnoringArmorOnAttack = true;
	}

	function onUse( _user, _targetTile )
	{
		local tag = {
			User = _user,
			TargetTile = _targetTile
		};

		if (_targetTile.IsVisibleForPlayer || !_user.isHiddenToPlayer())
		{
			this.Time.scheduleEvent(this.TimeUnit.Virtual, 400, this.onDelayedEffect.bindenv(this), tag);
		}
		else
		{
			this.onDelayedEffect(tag);
		}

		return true;
	}

	function onDelayedEffect( _tag )
	{
		local targetTile = _tag.TargetTile;
		local user = _tag.User;

		// 400ms is long enough for either side to die or be removed from the map.
		if (user == null || !user.isAlive() || targetTile == null || targetTile.IsEmpty)
		{
			return;
		}

		local target = targetTile.getEntity();

		if (target == null || !target.isAlive())
		{
			return;
		}

		local hitInfo = clone this.Const.Tactical.HitInfo;
		hitInfo.DamageRegular = this.Math.rand(this.getDamage(target), this.getDamage(target) + 5);
		hitInfo.DamageDirect = 1.0;
		hitInfo.BodyPart = this.Const.BodyPart.Body;
		hitInfo.BodyDamageMult = 1.0;
		hitInfo.FatalityChanceMult = 0.0;
		target.onDamageReceived(user, this, hitInfo);
	}
});
