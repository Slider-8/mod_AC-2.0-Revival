# Defect register — Accessory Companions

Baseline: the mod exactly as published (v1.26, commit `c66303f`).
Current packaged version: **v2.1.9** (Phase 1+2; tooltip cache; companion builder).
Target: Battle Brothers **1.5.2.3**, modern Hooks + MSU, coexisting with Reforged.

Playtest / log sessions: **[PLAYTEST.md](PLAYTEST.md)** (long manual **PASS** for AC on 2.1.9, 2026-07-26).

Status values: `FIXED`, `CONFIRMED` (still open), `UNCONFIRMED`, `UNVERIFIED`, `WITHDRAWN`.

---

## Critical

### D1 — Companion state in name payload — `FIXED` (parser total + wrap)
Save stream still uses one string (vanilla-equivalent). Parser is total (Phase 1).
`onSerialize`/`onDeserialize` now wrap the parent and inject/parse the payload
via `m.Name` without jumping to `accessory` base. Quirk codes use
`SerializeQuirksByID`.

### D2 — Alp nightmare crash — `FIXED` (Phase 1)
### D3 — Nachzerer mid-swallow taming — `FIXED` (Phase 1, refuse)
### D4 — hookBaseClass SuperName double-wrap — `FIXED` (Phase 2.2 hookTree)

---

## High

### D5 — Localised display strings — `FIXED`
- Settlements: `Size` + script class (`isKindOf`), not Description prose.
- Taming: `Const.Companions.resolveTameType` via `EntityType` (+ frenzied checks).

### D6 — create replaced skipping subclass — `FIXED`
Foundation wraps subclass `create` (`_ac_create()` then setType).

### D7 — Persistent `m.DraftList` pollution — `FIXED`
`updateRoster` clones/restores `m.DraftList`; only the vanilla clone sees extras.

### D8 — Foundation on every accessory — `WITHDRAWN` (not a defect)

### D9 — Positional table coupling — `FIXED` (assert + keyed lookups)
- `Library[i].Type == i` asserted at load.
- `SerializeQuirksByID` for save; length assert vs `DeserializeQuirks`.
- Live taming uses `resolveTameType`, not `TameList` index chaining.
- `TameList` retained as documentation only.

---

## Medium / Low

| ID | Status | Notes |
|---|---|---|
| D10 | `FIXED` | Houndmaster tooltip matches `id == 14`, not fixed indices |
| D11 | `FIXED` | Nightmare `onVerifyTarget` already delegates to base first |
| D12 | `FIXED` | Unhold pitch `rand(9,11)*0.1` |
| D13 | `FIXED` | Warwolf arrow/javelin corpse branches independent |
| D14 | `FIXED` | Wolf IconLeashed variants corrected |
| D15 | `FIXED` | Regenerative uses companion Type, not class-name strings |
| D16 | `PARTIALLY FIXED` | Guards on foundation inventory/unleash sounds; remaining sites low-risk |
| D17 | `FIXED` | Noodle tail still skips `perk_adrenalin` script path |

---

## Reforged (decision 3)

When `::Hooks.hasMod("mod_reforged")`:
- Foundation is not applied to `wolf_item` (Script `warwolf`).
- `resolveTameType` returns null for `EntityType.Wolf`.

---

## Runtime tooltip / env (2.1.7–2.1.9)

| Topic | Status |
|---|---|
| RF blueprint `getName` blanks all tooltips | **Mitigated** — early cache + late guard (2.1.9); companions skip RF (2.1.8) |
| Bare name/worth only on weapons/armor | **Fixed** for players (recover cache); root = broken craft mods |
| Long session log (2.1.9, ~3 h) | **No** `getTooltip failed` after leftovers disabled — [PLAYTEST.md](PLAYTEST.md) |

---

## Reported but not reproduced

| Symptom | Status |
|---|---|
| Southern cities empty recruit pools | `UNCONFIRMED` — southern still excluded from AC draft inject (matches original lists) |
| Taming chance feels low | `UNCONFIRMED` — balance; values in `TameChance` |
| Other Nexus reports | unchanged; see prior register |

---

## Not a problem

No vanilla API drift against 1.5.2.3 for paths and EntityTypes used.

---

## D18 — `getSkills` on a non-actor crashes the tame skill on hover

**Status:** FIXED in v2.1.10. **Severity:** HIGH. **Introduced by:** the Phase 1 D3 fix.

Reported from a 2026-07-28 playtest log:

```
Script Error: the index 'getSkills' does not exist
hasSwallowedSomeone -> scripts/companions/player/companions_tame.nut : 173
onVerifyTarget      -> scripts/companions/player/companions_tame.nut : 202
updateCursorAndTooltip -> scripts/states/tactical_state.nut : 1836
onMouseInput        -> scripts/states/tactical_state.nut : 502
```

`onVerifyTarget` runs for **every tile the cursor crosses**, not only on click, so
with the Tame skill selected it is handed whatever entity sits on the hovered
tile. The accessors are split across two classes:

| Accessor | Defined on |
|---|---|
| `isAlive()`, `getFlags()` | `entity/tactical/entity.nut:38`, `:24` |
| `getType()`, `getSkills()` | `entity/tactical/actor.nut:86`, `:116` |

The existing guards only used entity-base accessors, so a non-actor entity passed
them and then hit `getSkills()`. Note the same trap sits one line further on:
`resolveTameType` calls `getType()`, so guarding only `hasSwallowedSomeone` would
have moved the crash rather than removed it.

**Fix:** reject non-actors once at the boundary in `onVerifyTarget`, plus
defensive guards in `hasSwallowedSomeone` and `Const.Companions.resolveTameType`
(the latter is a shared entry point also reached from `onUse`).

**Lesson:** `onVerifyTarget` is a hover path. Anything it touches must tolerate
arbitrary tile contents.

---

## D19 — `onDeath` vargv warning is expected noise, do NOT "fix" it

**Status:** WON'T FIX (correct as-is). **Severity:** none.

The log carries several of these:

```
Mod mod_AC is wrapping a vargv-using function onDeath in bb class
scripts/entity/tactical/actor ... with a non-vargv function with a greater
number of non-vargv parameters (used to be 0, wrapper returned function with 4)
```

This is **warning-level by deliberate design** in modern hooks. From its own
source (`modern_hooks/q_object.nut:140-146`): a vargv function wrapped by a
non-vargv one with *equal or more* params "could be a case of intermediate
safe-wrapper by a mod", so it only warns. It escalates to a thrown error only
when the wrapper has **fewer** params, which would break existing calls.

Our wrapper takes `(_killer, _skill, _tile, _fatalityType)` — exactly the true
vanilla signature (`vanilla/scripts/entity/tactical/actor.nut:1773`). Some other
mod in the load order has installed a vargv passthrough beneath us; MSU is not
the culprit (its own wrapper uses the same four fixed params,
`msu/hooks/entity/tactical/actor.nut:131`).

Rewriting our wrapper to use vargv would be cargo-culting: it would silence a
warning while making the parameter contract *less* explicit. Leave it.

---

## D20 — `in` does not see inherited members; the D18 guard rejected every target

**Status:** FIXED in v2.1.11. **Severity:** CRITICAL (Tame skill fully unusable).
**Introduced by:** the D18 fix in v2.1.10. Lived for exactly one release.

The D18 fix guarded the hover path with:

```squirrel
if (!("getType" in target) || !("getSkills" in target)) return false;
```

That guard is false for **every** entity, actors included, so the Tame skill
reported "invalid target" against everything — snakes in an ordinary fight, in
Igor's report.

**Why.** Battle Brothers does not use Squirrel classes for entities; it builds
tables via `this.inherit(...)`, with the parent reachable through a `SuperName`
slot. Method *calls* resolve up that chain, but the `in` operator only inspects a
table's **own** slots. So `target.getSkills()` works while `"getSkills" in target`
is false.

The evidence was in the original mod all along — its own idiom

```squirrel
while(!("onDeath" in o)) o = o[o.SuperName];   // walk UP to the shared parent
```

only makes sense *because* `in` cannot see inherited members. I had already
quoted that line in the audit notes and still wrote the broken guard.

**Fix.** Use `isKindOf`, which does walk the chain and is what the mod already
used elsewhere (`isKindOf(target, "lindwurm_tail")`):

```squirrel
if (!this.isKindOf(target, "actor")) return false;
```

`resolveTameType` gets **no** guard: `this` is the Const table there, so
`isKindOf` is out of reach, and the `in` form does not work. Both of its callers
sit behind `onVerifyTarget`, so anything reaching it is already an actor.

**Rules this leaves behind.**

- `"name" in obj` is only valid for slots **that table owns** — e.g. `setType`,
  which the companion foundation attaches directly. Existing uses of that form in
  this mod are correct for exactly that reason.
- For anything inherited from a vanilla base, use `isKindOf`.
- A static check cannot catch this, and neither can a clean load. Only running the
  skill does. Treat any change to targeting predicates as play-test-required.
