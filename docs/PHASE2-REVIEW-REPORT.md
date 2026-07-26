# Phase 2 implementation report — for handoff author review

**Audience:** the agent/session that wrote `docs/PHASE2-HANDOFF.md` (and Phase 1).
**Author of this work:** follow-on session (Grok), working from that handoff cold.
**Date of work:** 2026-07-26.
**Package version after this work:** **v2.1.0** (`::Hooks.register` SemVer string).
**Repo:** `mod_AC` — branch `master`. **Not committed** at report time (working tree dirty).

Igor will do long-form in-game regression later. This report is for **code/architecture
review** of whether Phase 2 was executed as the handoff specified, what was
deviated, and what remains unproven.

---

## 1. Handoff contract — accepted as written

Decisions not reopened:

1. Port to modern Hooks + MSU (not defensive patches on legacy only).
2. Soft-detect Reforged; work standalone and with Reforged 0.9.1.
3. Yield `wolf_item` to Reforged when present; standalone Warwolf unchanged.
4. Nachzerer mid-swallow not tamable (Phase 1 behaviour preserved).

Hard constraints treated as binding:

| Constraint | How addressed |
|---|---|
| Frozen mod ID `mod_AC` | `::AC.ID = "mod_AC"`; `Hooks.register` / `MSU.Class.Mod` use same ID |
| Frozen paths/IDs (`companions_unleash`, tame/raise/unleash/beastmaster) | Untouched script paths and skill/background IDs |
| One-string save stream | Still one `writeString` of name+payload; wrap injects payload into `m.Name` then calls parent serialize |
| Already-applied marker before wrap | `o.m.mod_AC_FoundationApplied` at start of foundation body |
| `mod_modular_vanilla` replaces `setStartValuesEx` | **Resolved v2.1.1** — conversion on `houndmaster_background.onAdded` |

Phase 1 (D1–D3 commits `1aada5d` / `f815b2c` / `caffee0`) was not re-litigated.

---

## 2. Suggested handoff order → what was done

| Step | Handoff ask | Status | Where to look |
|---|---|---|---|
| 1 | Register Hooks + MSU; split monolith | **Done** | `scripts/!mods_preload/mod_AC.nut`; `mod_AC/hooks/*.nut` (12 files) |
| 2 | Convert hooks; fix D4 via `hookTree` | **Done** | No remaining `mods_hook*` in ship surface |
| 3 | D5 prose → stable keys | **Done** | `settlement.nut`, `companions_tame.nut`, `resolveTameType` in library |
| 4 | D7 stop persisting DraftList | **Done** | `settlement.nut` temp inject + restore |
| 5 | Reforged wrap + yield wolf | **Done** (partial purity) | Foundation create/serialize wrap; wolf skip when `mod_reforged` |
| 6 | D9 keyed tables + asserts | **Done** (pragmatic) | Library Type assert; `SerializeQuirksByID`; tame no longer chains `TameList` |
| 7 | D10–D17 medium/low | **Done / partial** | See §4 |

Also: version bumped **1.26 → 2.0 (float, brief) → 2.0.0 SemVer → 2.1.0** after full Phase 2.

---

## 3. Architecture after Phase 2

### 3.1 Entry

```
scripts/!mods_preload/mod_AC.nut
  ::AC = { ID, Version="2.1.0", Name }
  ::AC.HooksMod = ::Hooks.register(...)
  .require(["mod_msu >= 1.7.0", "mod_modern_hooks >= 0.4.0"])
  .queue(">mod_msu", function() {
      ::AC.Mod = ::MSU.Class.Mod(...)
      register CSS + LateJS tooltips
      foreach include mod_AC/hooks/*
  })
```

**Requires** MSU + modern hooks (hard). Legacy `mod_hooks` zip may still exist in
Igor’s data folder for other mods; AC no longer calls `::mods_registerMod` /
`::mods_queue` / `::mods_hook*`.

### 3.2 Hook inventory (`mod_AC/hooks/`)

| File | API | Target | Notes |
|---|---|---|---|
| `asset_manager.nut` | `hook` + `@(__original)` | `states/world/asset_manager` | Wound heal on hour tick |
| `houndmaster_background.nut` | `hook` | `skills/backgrounds/houndmaster_background` | Beastmaster + ser/deser; D10 tooltip by id |
| `settlement.nut` | `hookTree` | `entity/world/settlement` | D5 class/size; D7 draft inject |
| `human.nut` | `hookTree` | `entity/tactical/human` | Grant tame skill (D4) |
| `actor.nut` | `hookTree` | `entity/tactical/actor` | Drop tome/spider (D4) |
| `player.nut` | `hook` | `entity/tactical/player` | XP share + Beastmaster convert |
| `zombie.nut` / `skeleton.nut` | `hookTree` | zombie / skeleton | Reanimate XP |
| `player_party.nut` | `hook` | `entity/world/player_party` | Strength |
| `wardog_*_armor_upgrade.nut` | `hook` | armor upgrade items | Preserve companion state; else `__original` |
| `accessory_foundation.nut` | **`rawHookTree`** | `items/accessory/accessory` | Gated on `setEntity`; marker; wolf yield |

### 3.3 Why `rawHookTree` for foundation (review this)

Handoff preferred modern `hook` + `@(__original)`. Foundation adds many members
with `<-` on the **raw prototype** (legacy style). Converting every method to Q
syntax in one pass risked `newSlotM` errors on fields that already exist on
wardog (`Skill`, `Entity`, …).

Chosen path:

- `rawHookTree("scripts/items/accessory/accessory", …)` once per descendant.
- Guard: `"setEntity" in o` (same as original — only the seven dog/wolf classes).
- Marker: `mod_AC_FoundationApplied`.
- **D6:** wrap `create` via captured `_ac_create` (subclass body runs first).
- **D1 serialize:** wrap via `_ac_onSerialize` / `_ac_onDeserialize`; payload
  temporarily assigned to `m.Name` so stream stays one string.
- **Reforged:** if `mod_reforged` and `o.m.Script == "scripts/entity/tactical/warwolf"`,
  **return before** applying foundation (full yield of `wolf_item`).

Challenge for reviewer: whether create/onSerialize should be full Q
`@(__original)` hooks on the seven exact classes instead of rawHookTree.

### 3.4 Settlement / Beastmaster logic (D5 + D7)

Replaces 22 English Description strings.

```
AC_getHoundmasterDraftSlots():
  Southern culture → 0  (preserves original “no southern prose match”)
  Size >= 3 → 2
  Size == 2 + (medium_forest_fort | medium_lumber_village |
               medium_mountains_fort | medium_mining_village |
               medium_swamp_fort | medium_swamp_village) → 1
  Size == 1 + (small_lumber_village | small_swamp_village) → 1
  else → 0

AC_isBeastmasterTown(): large non-southern OR the size-2 set above
  (original conversion used Large OR Medium lists, not Small)

updateRoster:
  backup = clone m.DraftList
  append houndmaster until slot count met
  __original(_force)
  m.DraftList = backup   // D7: no persistent pollution
```

### 3.5 Taming (D5)

`Const.Companions.resolveTameType(_entity)` in `companions_library.nut`:

- Maps `EntityType` → companion `TypeList` value.
- Frenzied direwolf: skills has `perk.overwhelm` **and** `perk.relentless`
  (direwolf_high onInit adds both; avoids `isKindOf` from Const table `this`).
- Frenzied hyena: `m.IsHigh`.
- Wolf: **null** if `::Hooks.hasMod("mod_reforged")`.
- Lindwurm → Noodle; tail still blocked in tame skill via `isKindOf(..., "lindwurm_tail")`.

`companions_tame.nut` uses `resolveTameType` + `hasMaxTamed(type)` (type is
companion type index, not TameList index).

**`TameList` array kept** for human reference / old habits; **not used** on the
live tame path.

### 3.6 D9 tables

- After `Library` definition: `foreach` assert `entry.Type == i`.
- After Serialize/Deserialize quirk arrays: length equality throw;
  `SerializeQuirksByID[id] <- i`.
- Foundation serialize uses ByID; unknown quirks still skipped with warning
  (Phase 1 behaviour).

Save format **indices unchanged** (still integer codes in the name payload).

---

## 4. Defect register outcome (vs handoff + DEFECTS.md)

| ID | Claimed status | Evidence in tree |
|---|---|---|
| D1 | FIXED (parser Phase 1 + wrap Phase 2) | `accessory_foundation.nut` serialize wrap; Phase 1 parse still present |
| D2 | FIXED Phase 1 | `companions_nightmare_skill.nut` (unchanged this session) |
| D3 | FIXED Phase 1 | `hasSwallowedSomeone` / refuse in tame |
| D4 | FIXED | hookTree, no SuperName climb |
| D5 | FIXED | resolveTameType + settlement class/size |
| D6 | FIXED | `_ac_create()` then setType (armoured classes first) |
| D7 | FIXED | DraftList backup/restore |
| D8 | WITHDRAWN (handoff) | Still gated on setEntity |
| D9 | FIXED (pragmatic) | Asserts + ByID; TameList not deleted |
| D10 | FIXED | Tooltip match `id == 14` |
| D11 | FIXED (pre-existing correct order) | Nightmare verifies base first |
| D12 | FIXED | `rand(9,11)*0.1` unhold pitch |
| D13 | FIXED | Independent ifs for warwolf projectile decals |
| D14 | FIXED | Warwolf IconLeashed 1→wolf_01, else wolf_02 |
| D15 | FIXED | Regenerative uses companion Type |
| D16 | PARTIAL | Guards on some foundation sounds; checker still warns (guards on prior line / other files) |
| D17 | FIXED (narrow) | Still skip `perk_adrenalin` path on noodle tail |

**Explicitly not “fixed” and still open in handoff spirit:**

- Southern cities recruit-pool report (`UNCONFIRMED`) — southern still excluded.
- Full in-game proof of any of the above (see §5).
- Beastmaster conversion if `mod_modular_vanilla` discards `setStartValuesEx` wraps.

---

## 5. Verification performed (and not)

### Static

```
python tools/check_mod.py --refs .refs
→ 57 .nut files | 0 errors | ~15 warnings (known find/rand patterns)
```

Package: `dist/mod_AC.zip` includes `scripts/`, `gfx/`, `ui/`, `mod_AC/`.

### In-game (Igor)

| Session | Result |
|---|---|
| After Phase 2.1 (register + split, still legacy hook bodies) | Clean AC load; MSU “first time MSU version of Accessory Companions”; unleash wardog worked |
| After Phase 2.2+ full port (v2.1.0) | **Not yet** — Igor deferred (long repro plan) |

**Reviewer must not treat D5–D17 as play-proven.** Only static cleanliness +
earlier 2.1 scaffolding smoke test exist.

### Suggested regression checklist (for Igor / later)

1. Deploy `dist/mod_AC.zip`; confirm log: no `mod_AC` script errors; version 2.1.0 in MSU.
2. Unleash/leash; save/reload levelled quirked companion (D1 stream).
3. Tame under non-English names if possible (D5).
4. Large / medium forest-mountain-swamp / small lumber-swamp towns: drafts; no permanent DraftList growth across many roster refreshes (D7).
5. Beastmaster conversion on hire from large/medium beastmaster towns.
6. Nachzerer mid-swallow refuse (D3).
7. Alp nightmare + kill window (D2).
8. With Reforged: wolf item not AC-warwolf; without Reforged: Warwolf still works.
9. Necromancer/spider-egg drop rates feel 1× not N× (D4).

---

## 6. Risks and intentional deviations (please challenge)

1. **`rawHookTree` foundation vs pure Q hooks**  
   Functional intent matches handoff; style is hybrid. Double-apply protection is
   the marker, not Q idempotency.

2. **`setStartValuesEx` Beastmaster conversion** — **resolved in v2.1.1**  
   Conversion is on `houndmaster_background.onAdded` only.

3. **Frenzied direwolf detection**  
   Uses presence of both overwhelm + relentless perks, not class name. Could
   false-positive if another mod gives both to normal direwolves.

4. **Settlement class list**  
   Medium set is a fixed `isKindOf` allowlist decoded from original prose. If
   vanilla/mod adds new forest-fort class names, they won’t get AC drafts until
   the list is extended.

5. **Southern exclusion**  
   Size-3 rule would have included `city_state`; we exclude `Culture.Southern`
   to match original prose behaviour. Does **not** fix Nexus bug 1 if that bug
   is real and caused by something else.

6. **D9 not a full redesign**  
   `Library` remains an array; `TameList` remains. Coupling is **checked**, not
   erased. Serialize codes remain positional integers (correct for save compat).

7. **Hard require MSU / modern hooks**  
   Players on bare mod_hooks-only stacks cannot load AC 2.x. Matches handoff
   Phase 2 goal; is a compatibility break vs 1.26 standalone.

8. **Version 2.1.0**  
   SemVer required by modern Hooks. Phase 1 alone had been labeled 2.0; full
   Phase 2 is 2.1.0.

9. **Uncommitted**  
   At report time: modified sources + untracked `mod_AC/` + `AGENTS.md`. No
   git commit of Phase 2 yet.

---

## 7. Files touched (implementation surface)

**New**

- `mod_AC/hooks/*.nut` (12 hook files)
- `AGENTS.md` (DOX)
- `docs/PHASE2-REVIEW-REPORT.md` (this file)

**Heavily rewritten**

- `scripts/!mods_preload/mod_AC.nut` (entry only; ~30 lines)

**Edited**

- `scripts/companions/companions_library.nut` — assert, `resolveTameType`, D14 icon
- `scripts/companions/companions_quirks.nut` — ByID + length assert
- `scripts/companions/player/companions_tame.nut` — EntityType path
- `scripts/companions/quirks/companions_regenerative.nut` — D15
- `scripts/companions/types/companions_unhold.nut` — D12
- `scripts/companions/types/companions_warwolf.nut` — D13
- `scripts/companions/types/companions_noodle_tail.nut` — D17 comment/skip
- `README.md`, `docs/DEFECTS.md`, `docs/PHASE2-HANDOFF.md`

**Unchanged on purpose**

- All companion entity/skill scripts except the medium/low fixes above
- Save payload **shape** (marker + fields)
- Frozen IDs/paths for druid/autopilot

---

## 8. How to review efficiently

```bash
cd "…/mod_AC"
# Entire Phase 1+2 delta from published baseline:
git diff c66303f --stat

# Phase 2 uncommitted work (current tree):
git status
git diff -- scripts/ mod_AC/ docs/ README.md AGENTS.md

# Static:
python tools/check_mod.py --refs .refs
```

Priority review targets:

1. `mod_AC/hooks/accessory_foundation.nut` — create/serialize wrap, marker, wolf yield  
2. `mod_AC/hooks/settlement.nut` — D5/D7  
3. `scripts/companions/companions_library.nut` — `resolveTameType` + asserts  
4. `scripts/companions/player/companions_tame.nut` — tame path  
5. `mod_AC/hooks/player.nut` — Beastmaster + modular_vanilla risk  

---

## 9. Ask of the reviewing agent

1. Confirm frozen API and one-string stream were not violated.  
2. Accept or reject `rawHookTree` foundation approach.  
3. Flag whether Beastmaster must move off `setStartValuesEx` before release.  
4. Sanity-check settlement allowlist vs original 22 descriptions.  
5. Sanity-check `resolveTameType` coverage vs old `TameList` names (including
   armored dog names that may never appear as enemy EntityTypes).  
6. Do **not** mark play-verification complete until Igor’s long test returns.

---

## 10. One-line summary

Phase 2 was implemented end-to-end against the handoff (modern registration,
split hooks, D4–D7/D9, Reforged wolf yield, most medium/low defects), packaged
as **v2.1.0**, statically clean (0 errors), briefly smoke-tested only through
scaffolding; **full in-game regression is still Igor’s job**, and modular_vanilla
vs Beastmaster remains the highest structural residual risk.
