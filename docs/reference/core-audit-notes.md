# mod_AC.nut core findings (orchestrator's own analysis)

Source: `scripts/!mods_preload/mod_AC.nut` (1812 lines), mod_AC v1.26.
Target: BB 1.5.2.3, modern Hooks + MSU, coexisting with Reforged 0.9.1.

---

## C1. CRITICAL — Companion state is smuggled inside the item's *name* string

`serializeCompanionName()` / `deserializeCompanionName()` (L1700-1791) encode
Type, Level, XP, Wounds, all 8 Attributes and the Quirk list into the item's
`m.Name` as a payload after a `"\nmod_AC="` marker. `onSerialize` (L1793) then
writes only that one string.

Failure modes, all observed in user reports:

1. **Marker lost -> total state loss.** `deserializeCompanionName` L1746-1748:
   if `\nmod_AC=` is absent it silently does `this.m.Name = _cn` and leaves
   Type/Level/XP/Quirks at class defaults. Any mod that rewrites accessory
   names — *notably translation/localisation mods* — strips the marker.
   => matches the #1 reported issue ("taming/pets broken with translation
   mods", 4+ users) and ("pets revert to base Wardogs on load", 2+ users).
2. **No validation -> hard load failure.** L1755-1775 index `arrayBasics[1..3]`
   and `arrayAttributes[0..7]` with no length check, and L1754 / L1766 slice on
   `findAttributes - 1` / `findQuirks - 1` without null-checking `find`.
   A truncated or foreign payload throws index-out-of-range *during load*.
   => matches ("savegames fail to load", 2+ users).
3. **`onSerialize` is REPLACED (`<-`), not wrapped.** L1793/L1799. Whoever
   registers last wins. If Reforged or any other mod also serialises accessory
   state, one side's stream is silently desynced => corrupt saves.
4. `this.accessory.onSerialize(_out)` (L1795) jumps straight to the *base*
   accessory, skipping any intermediate class (e.g. `wardog_item`) that has its
   own serialisation. Stream desync again.

FIX: real fields + real serialisation, wrapped not replaced, with a version
byte and defensive defaults. Never encode state in a user-visible string.

---

## C2. CRITICAL — legacy `mods_hookBaseClass` double-wraps shared parents

Pattern used at L491, L516, L530:

```squirrel
::mods_hookBaseClass("entity/tactical/actor", function(o) {
    while(!("onDeath" in o)) o = o[o.SuperName];   // walk UP to the shared parent
    local onDeath = o.onDeath;
    o.onDeath = function(...) { ... onDeath(...); }
});
```

`mods_hookBaseClass` fires **once per subclass**. The body then walks *up* to
the common ancestor and wraps the function *there*. With N subclasses the same
parent function is wrapped N times, so the mod's logic runs N times per call.

- `entity/world/settlement` — ~47 subclasses.
- `entity/tactical/actor` — dozens of subclasses. The `onDeath` body (L534-606)
  runs a full O(mapWidth x mapHeight) tile scan **plus** a stash scan **plus** a
  roster scan, per wrap, per death. Severe performance hit, and the companion
  drop roll is re-rolled each time => duplicate drops.
- `entity/tactical/human` — L516, same shape.

FIX: modern hooks, hook the parent class exactly once.

---

## C3. CRITICAL — settlements identified by exact English prose

L453-487 hardcode 22 settlement *description strings*; L499-507 and L646 match
`this.m.Description` against them with `.find()`.

- Breaks in every non-English localisation (descriptions are localised — verified:
  the decompiled reference has them fully translated per settlement class).
- Breaks on any BB text edit and on any mod that rewrites descriptions.
- This is the mechanism behind Nexus bug **"Southern Cities do not show recruit pools"**.

Also a genuine Squirrel bug on the same lines: `array.find()` returns the
**index** or null, so `if (!this.m.DraftList.find("houndmaster_background"))`
(L497) is *true* both when absent AND when present at index 0, and
`BeastmasterSettlementsLarge.find(desc)` (L499) is *false* for the first entry
of each list.

FIX: key off the settlement's script class / size / flags, never prose.

---

## C4. HIGH — `create` is replaced, breaking the subclass chain (Reforged conflict)

L994 `o.create <- function() { this.accessory.create(); ... }` is installed onto
every accessory subclass, and calls straight to the **base** accessory `create`,
skipping the subclass's own `create`.

Reforged hooks `scripts/items/accessory/wardog_item` `create` to set
`m.StaminaModifier = -3`
(`refs/mod_reforged_core_0.9.1_Ks0c9R8EM/mod_reforged/hooks/items/accessory/wardog_item.nut`).
Depending on load order mod_AC's replacement bypasses it. Reforged also hooks
`items/accessory/accessory` (`getTooltip`, `onUpdateProperties`) and ships its
own `wolf_item` — which mod_AC also claims (L1033 `isKindOf(this,"wolf_item")`
-> `accessory.warwolf`).

FIX: wrap with `__original`, never replace; soft-detect Reforged and defer to
its stamina/tooltip handling.

---

## C5. HIGH — foundation applied to *every* accessory in the game

L1809-1811 apply `mod_AC_foundation` to `accessory` (all children),
`wardog_item` and `warhound_item` — overlapping trees, so wardog/warhound get it
twice. Every accessory in the game (potions, amulets, ...) gains
`setType/getType/updateCompanion/addXP` plus the companion `m` fields.

Consequence: the mod's own duck-type test `"setType" in acc` (used at L20-27,
L33, L566, L579, L590, L626, L634 and elsewhere) matches **every** accessory,
which is why every call site needs the extra `getType() != null` guard. Fragile,
and it collides with any other mod that adds `setType` to accessories.

FIX: a single explicit companion item class / a marker field owned by this mod.

---

## C6. MEDIUM — vanilla tooltip index assumptions

L98-109 assume the houndmaster background tooltip has `>= 3` entries and that
`tooltip[2].id == 14`, then `insert(3, ...)` / `insert(4, ...)` at fixed
positions. The mod already logs a warning when this fails (L112, L117) — the
author knew it was fragile. Any mod that touches that tooltip shifts the indices.

FIX: match entries by `id`/content, not by position.

---

## Hook surface (for the port)

| Vanilla target | Functions touched |
|---|---|
| `states/world/asset_manager` | `update` |
| `skills/backgrounds/houndmaster_background` | `getTooltip`, `onBuildDescription`, `onChangeAttributes`, `onAddEquipment`, +`applyBeastmasterModification` |
| `entity/world/settlement` | `updateRoster` |
| `entity/tactical/human` | `onInit` |
| `entity/tactical/actor` | `onDeath` |
| `entity/tactical/player` | `onActorKilled`, `setStartValuesEx` |
| `entity/tactical/enemies/zombie` | XP on kill |
| `entity/tactical/skeleton` | XP on kill |
| `entity/world/player_party` | party strength |
| `items/misc/wardog_armor_upgrade_item` | upgrade retains companion state |
| `items/misc/wardog_heavy_armor_upgrade_item` | same |
| `items/accessory/accessory` + `wardog_item` + `warhound_item` | `mod_AC_foundation` |
| UI | `companions_tooltip.css`, `companions_tooltip.js` |
