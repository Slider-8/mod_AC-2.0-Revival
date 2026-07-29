# Defect register — Accessory Companions

Baseline: the mod exactly as published (v1.26, commit `c66303f`).
Current packaged version: **v2.1.9** (Phase 1+2; tooltip cache; companion builder).
Target: Battle Brothers **1.5.2.3**, modern Hooks + MSU, coexisting with Reforged.

Playtest / log sessions: **[PLAYTEST.md](PLAYTEST.md)** (long manual **PASS** for AC on 2.1.9, 2026-07-26).

Status values: `FIXED`, `CONFIRMED` (still open), `UNCONFIRMED`, `UNVERIFIED`, `WITHDRAWN`.

---

## Critical

### D1 - Companion state in name payload - `FIXED, PLAY-PROVEN 2026-07-28`
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

---

## D21 — Frenzied hyena resolved via `in` on an inherited `m` field

**Status:** FIXED in v2.1.12. **Severity:** MEDIUM. **Same root cause family as D20.**

`resolveTameType` distinguished a frenzied hyena with:

```squirrel
if (("IsHigh" in _entity.m) && _entity.m.IsHigh) return TL.HyenaFrenzied;
```

`hyena_high` declares its own empty `m = {}` and only assigns `IsHigh` inside
`create()`; the field is declared on the parent `hyena`'s `m`. So the `in` test is
not reliable -- the D20 trap again, one level down, on a field rather than a method.

**Fix:** call vanilla's own accessor, `hyena.nut:5 isHigh()`. Method calls resolve
through the inheritance chain; `in` does not.

**Symptom it actually causes:** a frenzied hyena tamed as an ordinary Hyena
(type 9 instead of 10) -- wrong stats, wrong per-company cap. It does **not**
produce "invalid target", because both branches return a valid type. See the note
below.

**Residual risk:** a third-party hyena that reports `EntityType.Hyena` without
deriving from vanilla `hyena` would have no `isHigh()` and would throw here.
`mod_champion_beasts` is installed on this machine; its beasts appear to subclass
vanilla, so this is theoretical, but it is the reason a `getName()` fallback was
not used instead.

---

## D22 — "invalid target" on frenzied hyena — `UNDIAGNOSED`

Reported 2026-07-28 on v2.1.11. **Not explained by D21** and not yet reproduced
from evidence -- the log for that run contains no `mod_AC` error at all, which is
expected because a rejected target is a silent predicate result, not an exception.

Gates in `onVerifyTarget` that can silently reject, in order, with what would have
to be true for each:

| Gate | Would require |
|---|---|
| `isKindOf(target, "actor")` | hyena not derived from actor -- very unlikely, snakes pass |
| `getFlags().has("taming_protection")` | **a previous failed tame attempt on that same beast** |
| `hasSwallowedSomeone` | not applicable to hyenas |
| `isAlliedWith` | hyena allied to the player |
| `resolveTameType == null` | ruled out -- `hyena_high` inherits `m.Type = EntityType.Hyena` from `hyena.create()`, so both branches return a type |
| `hasMaxTamed` | 4+ hyena companions already held (Hyena `MaxPerCompany = 4`) |
| base `skill.onVerifyTarget` | out of range -- the skill is `MaxRange = 1`, adjacency only |

**Leading candidate: intended behaviour.** `companions_tame.nut:348` adds the
`taming_protection` flag on a *failed* attempt, and the skill's own description
says "Failing the attempt makes further attempts on the same beast impossible."
The flag is cleared in `onCombatFinished`, so it lasts the rest of that battle.

Do not "fix" this until it is distinguished from a genuine defect. The question
that separates them: was the frenzied hyena rejected on the **very first** hover,
before any attempt was made on it, and was the brother standing adjacent?

---

## D22 — RESOLVED: frenzied hyena was working as designed

Superseded the `UNDIAGNOSED` entry above. Root cause found 2026-07-28 from the
2.1.11 log plus the reported click sequence.

The message in the in-game combat log was **the mod's own**, not an exception:

```squirrel
// companions_tame.nut, failure branch
this.Tactical.EventLog.logEx(... + " failed to tame " + ...);
target.getFlags().add("taming_protection");
```

`log.html` for that run contains no `mod_AC` error at all -- only the three
pre-existing `mod_rpgr_parameters` `Statistics` rows.

**The chance formula makes a healthy target unwinnable:**

```squirrel
chance = (1.0 - target.getHitpointsPct()) * TameChance.Default   // Default = 30
if (rooted) chance *= 1.25
if (this.Math.rand(1, 1000) <= chance) { /* success */ }
```

At full health `getHitpointsPct()` is 1.0, so `chance` is **0** and the roll can
never succeed. The attempt still counts: the failure branch adds
`taming_protection`, and every later attempt on that beast is rejected by
`onVerifyTarget` for the rest of the battle. Cleared in `onCombatFinished`.

Worst case is not much better. The roll is out of **1000** while `chance` peaks at
the constant itself, so a target on 1 HP gives:

| Situation | Best possible chance |
|---|---|
| Default | 30/1000 = **3.0%** |
| Beastmaster background | 45/1000 = **4.5%** |
| Rooted, Beastmaster | 56/1000 = **5.6%** |

And failure locks the beast out, so in practice each beast is worth **one ~3%
roll per battle**. The snake that succeeded on 2.1.11 was a wounded target and a
lucky roll.

**Not a code defect.** This is original 1.26 balance, and it is the real
explanation behind the most common complaint on the Nexus page ("taming does
nothing / the chance is so small"). The author's own answer there was to raise
`TameChance` in `companions_library.nut`. Tuning it is a product decision, not a
bug fix -- see the note in PLAYTEST.md.

**Worth improving regardless of tuning:** the skill gives no feedback that a
full-health target is a guaranteed loss. `getHitchance()` returns `chance / 10.0`,
so the UI does show 0.0% -- but nothing explains *why*, and nothing warns that
spending the attempt burns the beast for the battle.

---

## Tamable-entity coverage audit (2026-07-28, v2.1.12)

Full cross-check of `resolveTameType` against the library and vanilla. **All clean.**

- All **16** `Const.EntityType` values it tests exist in vanilla.
- All **15** tamable types resolve to a library entry with a script that exists on
  disk: Wardog, Warhound, Warwolf, Direwolf, DirewolfFrenzied, Hyena,
  HyenaFrenzied, Spider, Snake, Nacho, Alp, Schrat, Noodle, Unhold, UnholdArmor.
- The **5** library types not reachable by taming are correct: `WardogArmor`,
  `WardogArmorHeavy`, `WarhoundArmor`, `WarhoundArmorHeavy` (armour upgrades) and
  `TomeReanimation` (necromancer drop).
- TypeList count == Library count == 20; the D9 `entry.Type == i` assert covers
  alignment at load.
- Both `ArmorScript` paths are vanilla items and exist in the vanilla reference.

Reproduce with the audit script kept at `tools/audit_tame.py`.

---

## D22 — CLOSED: frenzied hyena targetable again (fixed by D21)

**Status:** FIXED in v2.1.12 (the D21 `isHigh()` change), **confirmed in play on
v2.1.13**. Supersedes both the `UNDIAGNOSED` entry and the working-as-designed
entry above -- the second of which was wrong, see below.

The instrumented 2.1.13 build settled it. Log from that run:

```
mod_AC tame reject: taming_protection flag already set | name=Frenzied Hyena type=113
mod_AC tame reject: allied with user | name=<own brothers> type=-1
```

Two things follow. The hyena is **no longer rejected on first hover** -- the only
rejection left is the intended post-failure lockout, after Igor had already spent
an attempt. And `type=113` is `Const.EntityType.Hyena`, confirmed by
`config/spawnlist_master.nut:479` where `HyenaHIGH` is declared with
`ID = this.Const.EntityType.Hyena`. Frenzied hyenas share the base entity type,
so `resolveTameType` enters the Hyena branch correctly.

**Why D21 fixed it.** The only behavioural change between the broken 2.1.11 and
the working 2.1.12 was the frenzied-hyena check. With the old
`("IsHigh" in _entity.m)` form returning false, a frenzied hyena resolved to
`Hyena` (type 9, `MaxPerCompany = 4`) instead of `HyenaFrenzied` (type 10,
`MaxPerCompany = 2`). With enough ordinary hyena companions already held,
`hasMaxTamed(9)` returned true and the beast was rejected as an invalid target --
while the frenzied cap it should have been measured against was nowhere near met.

So D21 was never merely cosmetic. Mis-typing the beast fed the wrong per-company
cap into `hasMaxTamed`, and that is what produced "invalid target".

**Correction to the earlier entry.** The "working as designed / 0% at full
health" diagnosis was wrong for this report. It described a real property of the
chance formula, but the target was wounded and it was a first attempt, so that
mechanism did not apply. The instrumentation existed because reasoning had
already failed twice here.

**Balance is intended.** Igor confirmed the low success rate is acceptable and
should not be tuned. `TameChance.Default` / `.Beastmaster` stay at 30 / 45.

**Diagnostics retained.** `Const.Companions.DebugTame` (default `false`) turns the
per-gate reject logging back on. Seven gates in `onVerifyTarget` all fail as a
bare `return false` with identical UI feedback, so this is the only practical way
to tell them apart from outside. Leave the switch in place.

---

## D22 — REOPENED as `UNEXPLAINED`: the closure above was wrong

**Correction, 2026-07-28.** The entry above closed D22 by claiming D21 fixed it
via a wrong `MaxPerCompany`. That explanation is **dead**.

It required the player to already hold enough ordinary hyenas to hit
`Hyena.MaxPerCompany = 4`. Igor holds **no hyenas at all** -- one tamed snake and
several bought war dogs. Wardogs are type 0 (cap 12) and the snake is type 12;
neither counts toward either hyena type. So `hasMaxTamed` returns false whether
the beast resolves as `Hyena` (cap 4) or `HyenaFrenzied` (cap 2), and that gate
could not have rejected it under either version.

**What is still true:**

- The D21 change is correct on its own merits and stays. `("IsHigh" in _entity.m)`
  is not a reliable test (D20 family); `isHigh()` is.
- Frenzied hyenas share `EntityType.Hyena` (`type=113` in the log, corroborated by
  `config/spawnlist_master.nut:479`), so `resolveTameType` enters the Hyena branch.
- On v2.1.13 the beast was targetable, and the only logged rejection was
  `taming_protection flag already set` -- i.e. after an attempt had been spent.

**What is not established:** why v2.1.11 rejected it. Note that *both* branches of
the 2.1.11 hyena check returned a non-null type, so `resolveTameType` could not
have returned null either. Neither of the two gates D21 could plausibly influence
explains the report.

**Leading remaining hypothesis:** the v2.1.11 target already carried
`taming_protection` from an earlier attempt in that same battle instance, and the
"first attempt" was first only since the most recent reload. Unverified, and it
contradicts the report as given, so it is a hypothesis and nothing more.

**How to settle it if it recurs:** set `Const.Companions.DebugTame = true` and
reproduce. The gate that rejects is then named in `log.html`. Do not ship another
root-cause claim for this without such a line.

**Process note.** This is the third confident wrong diagnosis on this defect
(full-health chance; then wrong cap). Each was a plausible mechanism reached for
without evidence that it was the *active* one. The instrumentation exists
precisely because reasoning keeps failing here -- use it first next time.

---

## D23 — Softlock on the companion's turn after unleash-on-owner-death

**Report (2026-07-29).** A human brother died of bleeding at the end of his own
turn. His equipped Winter warhound was unleashed by the on-death path. The game
stopped on the dog's turn and had to be killed.

**Log evidence** (`Documents\Battle Brothers\log.html`, 14:03:42):

```
Leon Wild H Fl is unconscious.
ff: onKill ... Skill = "effects.bleeding", Self = true
onRemovedFromMap activeEntity null. Leon Wild H Fl (1773057)
Spawned Entity type "scripts/companions/types/companions_warhound" at (14,11)
onPlacedOnMap activeEntity null. Warhound (2583362)
Turn started for Winter
<nothing further>
Shutting down engine core.        (21s later, user killed the process)
```

**No Squirrel exception was thrown.** This is a spin, not a crash. That matters:
it rules out every "index does not exist" family of cause and points at a loop
that never terminates.

### Established mechanism

1. Vanilla `actor.onDeath` order is `removeFromMap()` -> `Items.onActorDied(tile)`
   -> `onAfterDeath(tile)` (`.refs/vanilla/scripts/entity/tactical/actor.nut:3511`).
   So the mod's spawn runs *inside* the owner's death resolution.
2. Every companion sets `m.IsActingImmediately = true`. In `actor.onPlacedOnMap`
   that routes to `Tactical.TurnSequenceBar.insertEntity(this)` rather than
   `addEntity` (`actor.nut:2233`), i.e. the dog is inserted to act **next**.
   Combined with (1), the dog becomes active with no gap after the owner's turn.
3. `onRemovedFromMap activeEntity null` / `onPlacedOnMap activeEntity null` are
   **Reforged** diagnostics, not vanilla and not ours -- see
   `mod_reforged/hooks/experimental_modules/ai_agent_fixes.nut:310,328`. They mean
   Reforged could not invalidate the active agent's cached behavior because no
   entity was active at that instant. Both fired here.
4. Reforged's `ai_agent_fixes` is loaded unconditionally: `mod_reforged.nut:198`
   is `foreach (file in ::IO.enumerateFiles("mod_reforged"))`, which recurses into
   `hooks/experimental_modules/`. There is no setting that disables it; the only
   related MSU setting, `Debug_AIAgentFixes`, controls *logging* only.

### Leading hypothesis — NOT CONFIRMED

Reforged replaces `agent.think` with:

```squirrel
q.RF_canExecute <- function() {
    return this.m.RF_AgentState.isExecuting()
        || (!::Time.hasEventScheduled(::TimeUnit.Virtual) && !::Tactical.getNavigator().IsTravelling);
}
q.think = @(__original) function( _evaluateOnly = false ) {
    if (!_evaluateOnly && !this.RF_canExecute()) { __original(true); return; }
    __original(_evaluateOnly);
}
```

If a Virtual-time event stays pending (or the navigator stays `IsTravelling`),
`think` degrades to evaluate-only **forever**: the behavior is never executed, the
turn never ends, nothing is logged, and no exception is raised. This is the only
silent non-terminating path found in the whole stack, and it matches the symptom
exactly. The death sequence that spawned the dog is a plausible source of such a
pending event.

`mod_AC` itself schedules only one Virtual event and it is unrelated to this path
(`companions_nightmare_skill.nut:113`, alp only).

**This is a mechanism, not a proven cause. Do not ship it as a fix.**

### How to confirm

Enable the MSU setting **Reforged -> Debug -> `AIAgentFixes`**, reproduce, and read
`log.html`. A stall shows as repeating `evaluate -- Winter (...)` lines with no
matching `execute -- Winter` line. If instead `execute` lines appear and repeat,
the loop is inside a behavior, not the gate.

### Fixed under this defect (independent of the hang)

`accessory_foundation.onActorDied` had dropped vanilla's occupancy guard.
Vanilla `wardog_item.onActorDied` scans the six neighbours when the death tile is
not empty and **refuses to spawn at all** when none is free
(`.refs/vanilla/scripts/items/accessory/wardog_item.nut`). mod_AC spawned
unconditionally at the corpse tile. Restored, with the same fall-back-then-abort
shape as vanilla.

This is a genuine regression and worth fixing on its own, but it **did not cause
this hang**: the log shows Leon was removed from the map at (14,11) immediately
before the dog spawned there, so the tile was free and the guard would not have
fired.

**Checked and deliberately not changed:** the Noodle needs a second tile for its
tail, and the unleash *skill* enforces that via `findTailTile`, which
`onActorDied` does not. No fix needed -- `companions_noodle.nut:319-356` leaves
`m.Tail` null when no neighbour is free, and every consumer null-checks it. The
companion is degraded, not broken.

**Status:** `PARTIALLY FIXED` — occupancy guard restored; the softlock itself is
`UNCONFIRMED` pending the instrumented repro above.
