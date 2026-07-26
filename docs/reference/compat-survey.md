# mod_AC (Accessory Companions) Compatibility Survey

Surveyed 91 installed .zip archives under `C:/Games/Steam/steamapps/common/Battle Brothers/data/`.
78 contain `.nut` files; 24 contain hits on mod_AC's high-specificity touchpoints (exact function/path
names); a further ~13 contain design-level "companion/beastmaster/wardog" keyword hits.

Raw grep dumps (kept for reference, not for re-reading in full):
- `.../scratchpad/hits_specific.txt` — exact-path/function hits
- `.../scratchpad/hits_companion.txt` — broad companion/pet/beastmaster keyword hits
- `.../scratchpad/raw_hits.txt` — full unfiltered dump (23k lines, noisy, low signal)

## Table

| Mod | Touchpoint | Hook style | Verdict | Evidence (file:line) |
|---|---|---|---|---|
| mod_reforged_core (Reforged) | items/accessory/accessory -> getTooltip() | Modern (`::Reforged.HooksMod.hook`) | CONFLICT | mod_reforged/hooks/items/accessory/accessory.nut:1-4 |
| mod_reforged_core (Reforged) | entity/tactical/actor -> onDeath() | Modern (`::Reforged.HooksMod.hookTree`) | ORDER-SENSITIVE | mod_reforged/hooks/entity/tactical/actor.nut:374 |
| mod_reforged_core (Reforged) | entity/tactical/actor -> onActorKilled() (hookTree, affects player/zombie/skeleton too) | Modern (`hookTree`) | ORDER-SENSITIVE | mod_reforged/hooks/entity/tactical/actor.nut:365-372 |
| mod_reforged_core (Reforged) | items/accessory/wardog_item & warhound_item -> create() | Modern (`::Reforged.HooksMod.hook`) | ORDER-SENSITIVE | mod_reforged/hooks/items/accessory/wardog_item.nut:1, warhound_item.nut:1 |
| mod_reforged_core (Reforged) | skills/backgrounds/houndmaster_background -> createPerkTreeBlueprint() | Modern (`::Reforged.HooksMod.hook`) | ORDER-SENSITIVE | mod_reforged/hooks/skills/backgrounds/houndmaster_background.nut:1-4 |
| mod_modular_vanilla | entity/tactical/player -> setStartValuesEx() (full replacement, no `__original` call chain — rewritten copy of vanilla body) | Modern-style hook, but body uses `@() {...}` not `@(__original)` | CONFLICT | mod_modular_vanilla/hooks/entity/tactical/player.nut:70-111 |
| MSU (mod_msu) | states/world/asset_manager -> update() | Modern (`::MSU.MH.hook`) | ORDER-SENSITIVE | msu/hooks/states/world/asset_manager.nut:1-4 |
| mod_stronghold | states/world/asset_manager -> update() (own settlement class also overrides updateRoster()) | LEGACY (`::mods_hookNewObjectOnce`) | ORDER-SENSITIVE | mod_stronghold/hooks/asset_manager.nut:1-4; stronghold_player_base.nut:256 |
| mod_dynamic_perks | entity/tactical/player -> setStartValuesEx() | Modern (`::DynamicPerks.HooksMod.hook`) | ORDER-SENSITIVE | dynamic_perks/hooks/entity/tactical/player.nut:106-110 |
| mod_background_perks | entity/tactical/player -> setStartValuesEx() | Modern (`mod.hook`) | ORDER-SENSITIVE | mod_background_perks.nut:131-135 |
| bro_studio | entity/tactical/player -> setStartValuesEx() (2 wraps) | Modern (`mh.hookTree` / `q.setStartValuesEx = @(__original)`) | ORDER-SENSITIVE | mod_bro_studio.nut:80-96 |
| mod_autopilot_new | skills/actives (companions_tame, raise_companion, unleash_companion) + background.companions_beastmaster (AI scoring, string-ID references to OLD mod_AC's exact skill IDs) | N/A — reads skill IDs, does not hook mod_AC files | DESIGN DEPENDENCY (silently breaks if IDs renamed) | autopilot/hooks/player.nut:106-116; scripts/ai/autopilot_tame.nut:7,18-19; scripts/ai/autopilot_unleash_dog.nut:7,40 |
| mod_druid | onDeath/onActorKilled chain (beast aura) + explicit `::Hooks.hasMod("mod_AC")` compat branch for `scripts/companions/onequip/companions_unleash` | Modern (`mh.hookTree`), cooperative | HARMLESS (already mod_AC-aware) | mod_druid.nut:109-117, 187-191 |
| BackgroundBonuses | skills/backgrounds/houndmaster_background -> getGenericTooltip() (different function from mod_AC's getTooltip/onBuildDescription) | Modern (`::modBackgroundBonuses.HooksMod.hook`) | HARMLESS | mod_backgroundBonuses_combined.nut:1779-1782 |
| mod_find_legendary_maps | states/world/asset_manager -> mfl_getMaps() (new method, not update()) | Modern (`::ModFindLegendaryMaps.Hooks.hook`) | HARMLESS | mfl_asset_manager.nut:1-4 |
| fun_facts | states/world/asset_manager -> consumeFood() | LEGACY (`::mods_hookNewObject`) | HARMLESS | fun_facts/assets_manager.nut:3-6 |
| mod_pufu_cart_upgrades | states/world/asset_manager -> setAmmo() | LEGACY (`::mods_hookExactClass`) | HARMLESS | mod_pufu_cart_upgrades.nut:135-138 |
| mod_replace_restore_equipped_items | states/world/asset_manager -> restoreEquipment() | LEGACY (`::mods_hookNewObjectOnce`) | HARMLESS | mod_RREI/hooks/asset_manager.nut:1-4 |
| mod_ReserveSize | states/world/asset_manager -> getFormation() | LEGACY (`::mods_hookNewObject`) | HARMLESS | mod_reservesize.nut:1-4 |
| mod_rpgr_parameters | states/world/asset_manager -> setCampaignSettings() (wrap) | Modern (`::PRM.Patcher.hookBase`) | HARMLESS | mod_rpgr_parameters/hooks/states/world/asset_manager.nut:1-4 |
| mod_turn_it_in | states/world/asset_manager -> excluded_contracts list (new field, not update) | LEGACY (`::mods_hookNewObject`) | HARMLESS | mod_turn_it_in.nut:4-7 |
| time_crossing_commando | states/world/asset_manager -> refillAmmo() | Modern (`_mod.hook`) | HARMLESS | sniper_rifle_resupply_bridge.nut:29-32 |
| mod_champion_beasts | items/accessory/accessory (inherits, new named-accessory subclass, no method override) | Modern (`::inherit`, not a hook) | HARMLESS | nggh_mod_named_accessory.nut:1-4 |
| stdlib | entity/world/settlement -> updateRoster() (dev/debug helper, calls it, doesn't override) | N/A (caller) | HARMLESS | stdlib/dev.nut:43 |
| The Hassassin Origin, time_crossing_commando, mod_legends_xBreditor_LEGENDS, mod_breditor_reforged_patch | entity/tactical/player -> setStartValuesEx() (one-shot calls creating scenario/debug bros, not hooks) | N/A (callers) | HARMLESS | assassin_scenario.nut:22; time_crossing_commando_*.nut; world_breditor_screen.nut:24,144 |

## Design-level overlaps (own companion/animal/pet systems)

- **mod_druid** (0.5.1): implements its own beast-summoning/Beastform mechanic and already contains
  conditional compatibility code keyed on `::Hooks.hasMod("mod_AC")` that pushes
  `scripts/companions/onequip/companions_unleash` into its watched-skill list. This confirms the OLD mod_AC's
  addon skill script path was `scripts/companions/onequip/companions_unleash` — the revival should keep that
  path stable or expect to patch mod_druid's compat shim.
- **mod_autopilot_new**: AI behavior scripts hard-reference old mod_AC skill/background string IDs
  (`actives.companions_tame`, `actives.raise_companion`, `actives.unleash_companion`,
  `background.companions_beastmaster`). Not a file/function hook, but a silent-breakage risk: if the revived
  mod renames any of these IDs, autopilot's AI simply stops using them (no error, just degraded behavior).
- **mod_reforged_core**: has its own `barbarian_beastmaster` tactical unit, `companion_1h/2h/ranged_background`
  (mercenary "Companion" career backgrounds — unrelated naming collision, NOT an animal-companion system),
  and its own wardog/warhound entity + accessory hooks. Reforged is the single largest overlap surface of any
  installed mod: it touches 5 of mod_AC's ~10 listed touchpoints directly.
- **mod_camps_and_artifacts / mod_dynamic_spawns / mod_reforged (dynamic_spawns submodule)**: reference
  Wardog/Warhound/Beastmaster as spawn-table unit entries only (enemy troop composition) — no method hooks,
  pure data. Confirmed HARMLESS, listed for completeness since they matched the broad keyword scan.
