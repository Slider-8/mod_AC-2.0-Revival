// Accessory Companions — modern Hooks + MSU entry point.
// Phase 2 complete: modern hooks, D4–D17 addressed (see docs/DEFECTS.md).
// Frozen mod ID: mod_AC

::AC <- {
	ID = "mod_AC",
	Version = "2.1.8",
	Name = "Accessory Companions"
};

::AC.HooksMod <- ::Hooks.register(::AC.ID, ::AC.Version, ::AC.Name);
::AC.HooksMod.require([
	"mod_msu >= 1.7.0",
	"mod_modern_hooks >= 0.4.0"
]);

// After MSU so ::MSU.Class.Mod is available. Hook files register via ::AC.HooksMod.
::AC.HooksMod.queue(">mod_msu", function()
{
	::AC.Mod <- ::MSU.Class.Mod(::AC.ID, ::AC.Version, ::AC.Name);

	// CSS only for tall companion tooltips. Do NOT register LateJS that patches
	// TooltipModule.setupUITooltip — that fights MSU Nested Tooltips / Reforged
	// and can blank tooltips on non-companion items.
	::Hooks.registerCSS("ui/mods/companions_tooltip.css");

	// Shared full companion tooltip builder (used by foundation + outer guard).
	::include("mod_AC/companion_tooltip");

	foreach (file in ::IO.enumerateFiles("mod_AC/hooks"))
	{
		// Tooltip guard is registered in a later queue so it wraps Reforged.
		if (file.find("zz_item_tooltip_guard") != null)
			continue;

		::include(file);
	}
});

// After Reforged (when present) so our getTooltip try/catch is outside RF's
// crafting-blueprint walk that throws on broken PreviewCraftable.getName().
::AC.HooksMod.queue([
	">mod_msu",
	">mod_reforged"
], function()
{
	::include("mod_AC/hooks/zz_item_tooltip_guard");
});
