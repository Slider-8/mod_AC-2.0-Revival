// Outer safety net for item tooltips (registered after mod_reforged).
//
// Reforged wraps item.getTooltip and walks crafting blueprints with b.getName().
// Broken PreviewCraftable → throw → no tooltip. Companion getTooltip often runs
// first and builds a full panel, then RF throws and discards it — outer catch
// used to return a minimal fallback (title/desc/worth only). That matched the
// "King" dog screenshot: name + description + worth, no level/attrs/quirks.
//
// Fix: companions (m.Type set) always use ::AC.buildCompanionItemTooltip and
// never rely on RF's blueprint walk. Other items try/catch with a richer fallback.

::AC.HooksMod.hookTree("scripts/items/item", function(q)
{
	q.getTooltip = @(__original) function()
	{
		// Companion accessories: skip Reforged blueprint walk entirely.
		// Type 0 is Wardog — must use != null, not truthiness.
		if ("setType" in this && "m" in this && this.m.Type != null)
		{
			return ::AC.buildCompanionItemTooltip(this);
		}

		try
		{
			return __original();
		}
		catch (error)
		{
			::logError("mod_AC: item getTooltip failed (" + error + "); using fallback. Often Reforged crafting blueprints with broken PreviewCraftable/getName.");

			local ret = [];
			try
			{
				ret.push({ id = 1, type = "title", text = this.getName() });
			}
			catch (e2)
			{
				ret.push({ id = 1, type = "title", text = "Item" });
			}

			try
			{
				ret.push({ id = 2, type = "description", text = this.getDescription() });
			}
			catch (e3)
			{
			}

			try
			{
				ret.push({ id = 3, type = "text", text = this.getValueString() });
			}
			catch (e4)
			{
			}

			if (this.getSlotType() == this.Const.ItemSlot.Accessory)
			{
				ret.push({ id = 4, type = "text", text = "Worn in Accessory Slot" });
			}

			try
			{
				if (this.getIconLarge() != null)
					ret.push({ id = 15, type = "image", image = this.getIconLarge(), isLarge = true });
				else
					ret.push({ id = 15, type = "image", image = this.getIcon() });
			}
			catch (e5)
			{
			}

			return ret;
		}
	}
});
