// Preserve companion state through heavy armor upgrade
::AC.HooksMod.hook("scripts/items/misc/wardog_heavy_armor_upgrade_item", function(q)
{
	q.onUse = @(__original) function( _actor, _item = null )
	{
		local dog = _item == null ? _actor.getItems().getItemAtSlot(this.Const.ItemSlot.Accessory) : _item;
		if (dog == null || !("setType" in dog))
		{
			return __original(_actor, _item);
		}
		if (dog.getType() != this.Const.Companions.TypeList.Wardog && dog.getType() != this.Const.Companions.TypeList.WardogArmor && dog.getType() != this.Const.Companions.TypeList.Warhound && dog.getType() != this.Const.Companions.TypeList.WarhoundArmor)
		{
			return __original(_actor, _item);
		}

		local new_dog;
		if (dog.getType() == this.Const.Companions.TypeList.Wardog || dog.getType() == this.Const.Companions.TypeList.WardogArmor)
		{
			new_dog = this.new("scripts/items/accessory/heavily_armored_wardog_item");
			new_dog.setType(this.Const.Companions.TypeList.WardogArmorHeavy);
		}
		else
		{
			new_dog = this.new("scripts/items/accessory/heavily_armored_warhound_item");
			new_dog.setType(this.Const.Companions.TypeList.WarhoundArmorHeavy);
		}

		new_dog.setName(dog.getName());
		new_dog.setVariant(dog.getVariant());
		new_dog.setLevel(dog.getLevel());
		new_dog.setXP(dog.getXP());
		new_dog.setWounds(dog.getWounds());
		new_dog.setAttributes(dog.getAttributes());
		new_dog.setQuirks(dog.getQuirks());
		new_dog.setEntity(dog.getEntity());
		new_dog.updateCompanion();
		_actor.getItems().unequip(dog);
		_actor.getItems().equip(new_dog);
		this.Sound.play("sounds/combat/armor_leather_impact_03.wav", this.Const.Sound.Volume.Inventory);
		return true;
	}
});
