// Accessory Companions — modern Hooks + MSU entry point.
// Phase 2 complete: modern hooks, D4–D17 addressed (see docs/DEFECTS.md).
// Frozen mod ID: mod_AC

::AC <- {
	ID = "mod_AC",
	Version = "2.1.6",
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

	foreach (file in ::IO.enumerateFiles("mod_AC/hooks"))
	{
		::include(file);
	}
});
