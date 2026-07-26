// Outer safety net for item tooltips.
//
// Reforged wraps item.getTooltip and walks World.State.Crafting blueprints,
// calling b.getName() on each. If any blueprint's PreviewCraftable is broken
// (missing scripts, bad Time Crossing items, etc.), getName throws and the
// entire tooltip fails — so swords/armor show nothing.
//
// Companion accessories install their own getTooltip via rawHookTree and often
// never hit that path, which is why only companions still showed tooltips.
//
// This hookTree wraps getTooltip last (file name zz_*) and falls back to a
// minimal tooltip if the inner chain throws. Registered again after Reforged
// when that mod is present (see preload entry).

::AC.HooksMod.hookTree("scripts/items/item", function(q)
{
	q.getTooltip = @(__original) function()
	{
		try
		{
			return __original();
		}
		catch (error)
		{
			::logError("mod_AC: item getTooltip failed (" + error + "); using fallback. Often caused by Reforged crafting blueprints with broken PreviewCraftable/getName.");

			local ret = [];
			try
			{
				ret.push({
					id = 1,
					type = "title",
					text = this.getName()
				});
			}
			catch (e2)
			{
				ret.push({
					id = 1,
					type = "title",
					text = "Item"
				});
			}

			try
			{
				ret.push({
					id = 2,
					type = "description",
					text = this.getDescription()
				});
			}
			catch (e3)
			{
			}

			try
			{
				ret.push({
					id = 3,
					type = "text",
					text = this.getValueString()
				});
			}
			catch (e4)
			{
			}

			return ret;
		}
	}
});
