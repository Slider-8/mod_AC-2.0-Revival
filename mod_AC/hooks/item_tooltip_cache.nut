// Cache the tooltip built *under* Reforged's item.getTooltip wrap.
//
// RF does: local ret = __original(); then walks Crafting blueprints with
// b.getName() → PreviewCraftable.getName(). Broken craft mods throw *after*
// vanilla (and AC companion) tooltips are already built, so the outer
// zz_item_tooltip_guard catch would otherwise only see the throw.
//
// Registered in the early queue (before/without requiring RF). The late guard
// (queue >mod_reforged) recovers this cache on throw.

::AC.HooksMod.hookTree("scripts/items/item", function(q)
{
	q.getTooltip = @(__original) function()
	{
		local ret = __original();
		// Instance field (not m.) so onSerialize never touches it.
		this.__AC_TooltipCache <- ret;
		return ret;
	}
});
