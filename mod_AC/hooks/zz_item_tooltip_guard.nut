// Outer safety net for item tooltips (registered after mod_reforged).
//
// Reforged wraps item.getTooltip and walks crafting blueprints with b.getName().
// Broken PreviewCraftable → throw after __original() already built full stats.
// item_tooltip_cache (early queue) stores that result on this.__AC_TooltipCache.
//
// Companions (m.Type set): always ::AC.buildCompanionItemTooltip (skip RF walk).
// Other items: try RF path; on throw return cached full tooltip (stats intact),
// losing only RF craft-hint extras. Minimal name/desc/worth is last resort.

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
			if (!("_TooltipFallbackLogged" in ::AC) || !::AC._TooltipFallbackLogged)
			{
				::AC._TooltipFallbackLogged <- true;
				::logError("mod_AC: item getTooltip failed (" + error + "); recovering cached tooltip if present. Often Reforged crafting blueprints with broken PreviewCraftable/getName. (logged once per session)");
			}

			// Prefer the full panel cached under RF (see item_tooltip_cache.nut).
			if ("__AC_TooltipCache" in this && this.__AC_TooltipCache != null)
			{
				return this.__AC_TooltipCache;
			}

			// Last resort: title / description / worth only.
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
