# Compatibility contract

Other published mods reach into this one by name. These identifiers are a
**public API** — renaming any of them silently breaks another mod, with no
error message for the player. Verified against the mod archives actually
installed in `C:/Games/Steam/steamapps/common/Battle Brothers/data`.

## Frozen identifiers — do not rename

| Identifier | Kind | Who depends on it |
|---|---|---|
| `mod_AC` | mod ID | `mod_druid` 0.5.1 — `::Hooks.hasMod("mod_AC")`, `scripts/!mods_preload/mod_druid.nut:190` — **currently disabled, see below** |
| `scripts/companions/onequip/companions_unleash` | script path | `mod_druid` 0.5.1, same line — pushed into its `unleashSkills` list |
| `actives.companions_tame` | skill ID | `mod_autopilot_new` 2.7.0 — `autopilot/hooks/player.nut:107`, `scripts/ai/autopilot_tame.nut:7` |
| `actives.raise_companion` | skill ID | `mod_autopilot_new` 2.7.0 — `autopilot/better_raise_undead.nut:14`, `autopilot/hooks/player.nut:115` |
| `actives.unleash_companion` | skill ID | `mod_autopilot_new` 2.7.0 — `scripts/ai/autopilot_unleash_dog.nut:7` |
| `background.companions_beastmaster` | background ID | `mod_autopilot_new` 2.7.0 — `scripts/ai/autopilot_unleash_dog.nut:40` |

Internal refactoring is fine as long as these keep resolving to something with
the same meaning.

### Open: `mod_druid` errors at launch (disabled 2026-07-26)

Igor disabled `mod_druid` 0.5.1 because Battle Brothers reported an error at
launch. It is not a required mod, and fixing it is deferred.

**Untested hypothesis, worth checking first.** Druid's mod_AC integration is
gated: `mod_druid.nut:190` only pushes
`scripts/companions/onequip/companions_unleash` into its `unleashSkills` list
when `::Hooks.hasMod("mod_AC")` is true, and then `mod.hook`s each entry. That
condition became true for the first time when mod_AC was enabled, so enabling
mod_AC may have activated a previously dormant code path. The timing fits, but
nothing is proven — druid may simply be stale against the current stack.

Note it is a **modern** `mod.hook` aimed at a script owned by a **legacy**
(`::mods_registerMod`) mod. Druid's author clearly knew about mod_AC — the
comment there explicitly handles mod_AC exposing `getEntity()` where vanilla
uses `m.Entity` — so the integration was written deliberately.

To capture the actual error: re-enable `mod_druid`, launch, quit, then read
`C:\Users\igorl\Documents\Battle Brothers\log.html`. BB overwrites that file on
every launch, so the error from the failing run is already gone.

**This does not relax the frozen-identifier rule.** `mod_autopilot_new` is still
enabled and still pins four IDs, and druid will pin the mod ID and script path
again the moment it is re-enabled — including for anyone else running the
revived mod.

## Mods that fight for the same vanilla functions

Ordered by how much care they need.

| Other mod | Shared vanilla target | Their style | Risk |
|---|---|---|---|
| `mod_modular_vanilla` 0.7.2 | `entity/tactical/player.setStartValuesEx` | **replaces**, does not call `__original` | **High** — a replacement discards wrappers registered beneath it. Our Beastmaster conversion currently rides on this function. |
| `mod_reforged_core` 0.9.1 | `items/accessory/accessory.getTooltip` | modern hook | **High** — the exact function our tooltip additions live on |
| `mod_reforged_core` 0.9.1 | `entity/tactical/actor.onDeath` / `onActorKilled` (hookTree) | modern hook | Order-sensitive — propagates to player/zombie/skeleton, all of which we also touch |
| `mod_reforged_core` 0.9.1 | `items/accessory/wardog_item.create`, `warhound_item.create`, `houndmaster_background.createPerkTreeBlueprint` | modern hook | Order-sensitive — different sub-functions, same classes |
| `mod_dynamic_perks`, `mod_background_perks`, `bro_studio` | `player.setStartValuesEx` | modern hook, wrap + call original | Chains correctly if load order is sane; four wrappers on one method is a lot of surface |
| MSU + `mod_stronghold` | `states/world/asset_manager.update` | mixed modern + legacy | Order-sensitive; we wrap the same function |

## Design-level overlap

- `mod_reforged_core` ships its own `wolf_item` accessory. Our foundation
  claims `wolf_item` as `accessory.warwolf`. This needs an explicit decision,
  not an accident of load order.
- `mod_reforged_core`'s `companion_1h/2h/ranged_background` are mercenary
  careers — a naming coincidence, not a competing animal-companion system.

## Rules that follow

1. Always wrap with `__original`; never replace a vanilla function outright.
2. Never assume a tooltip entry's index — match on `id`/content.
3. Detect Reforged at runtime and defer to it for accessory stamina and
   tooltip handling rather than fighting it.
4. Because `mod_modular_vanilla` *replaces* `setStartValuesEx`, do not depend
   on wrapping it. Beastmaster conversion is on `houndmaster_background.onAdded`
   (v2.1.1+), which both vanilla and modular_vanilla reach via `Skills.add`.
