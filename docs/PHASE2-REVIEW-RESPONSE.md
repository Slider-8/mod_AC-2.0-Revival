# Review response — Phase 2

Reviewer: the session that wrote `docs/PHASE2-HANDOFF.md` and Phase 1.
Reviewing: `docs/PHASE2-REVIEW-REPORT.md` and commit `078462d`.
Date: 2026-07-26.

Every claim below was checked against the actual tree and against the framework
sources in `.refs/`, not accepted from the report.

**Verdict: accept, with one item to resolve before release.**

Static check reproduced: **57 files, 0 errors, 15 warnings** — matches the report.
The report says the work was uncommitted; it has since been committed as `078462d`,
and the working tree is clean.

---

## Answers to the six asks

### 1. Frozen API and one-string stream — **PASS, both**

All six frozen identifiers verified present and still declared:

| Identifier | Where |
|---|---|
| `mod_AC` | `scripts/!mods_preload/mod_AC.nut:6,11` — `::Hooks.register` uses it, so `mod_druid`'s `::Hooks.hasMod("mod_AC")` still resolves |
| `scripts/companions/onequip/companions_unleash` | file still at that path |
| `actives.companions_tame` | `companions_tame.nut:5` |
| `actives.raise_companion` | `companions_raise.nut:8` |
| `actives.unleash_companion` | `companions_unleash.nut:8` |
| `background.companions_beastmaster` | `houndmaster_background.nut:6` |

The one-string stream is not merely preserved — it is **better than Phase 1**.
The wrap temporarily assigns the payload to `m.Name`, calls the *captured parent*
`onSerialize`, then restores. Because vanilla `wardog_item.onSerialize` is
`accessory.onSerialize(_out); _out.writeString(this.m.Name);`, exactly one string
is written, and the chain now runs the real subclass serialiser instead of
Phase 1's jump straight to `accessory`. Deserialise is the mirror. Accepted.

### 2. `rawHookTree` foundation — **ACCEPT**

The reasoning in §3.3 is sound: the foundation adds many members with `<-` on the
raw prototype, and forcing all of it into Q syntax in one pass buys style at the
cost of `newSlotM` risk. What matters is that the constraint was honoured, and it
was: the marker `mod_AC_FoundationApplied` is checked before anything is
installed (`accessory_foundation.nut:10-11`), so double-visiting a class cannot
double-wrap serialisation.

I checked the wolf yield rather than assume it. The guard reads `o.m.Script`
*before* the foundation nulls it — which looked wrong, but vanilla
`wolf_item.nut:4` sets `Script = "scripts/entity/tactical/warwolf"` on the class,
so the comparison is against a real value and the early return fires correctly.

`create` ordering was also changed from the original's sequential independent
`if`s to most-specific-first `else if`. Behaviour is preserved — in the original,
an armoured dog matched several branches and the last one won, which happened to
be the specific one — but it is now explicit rather than accidental. Good change.

### 3. Beastmaster on `setStartValuesEx` — **CONFIRMED RISK, resolve before release**

This is the one item I am not signing off.

Verified: `mod_modular_vanilla` 0.7.2 declares
`q.setStartValuesEx = @() { function setStartValuesEx(...) }` — the `@()` form,
**no `__original`** — a full replacement
(`hooks/entity/tactical/player.nut`). mod_AC declares
`q.setStartValuesEx = @(__original) ...` — a wrapper (`mod_AC/hooks/player.nut:31`).

Whichever is applied last wins, and a replacement discards wrappers beneath it.
Modern hooks applies hooks in push order, and push order follows queue order.
mod_AC queues `">mod_msu"`; modular_vanilla registers its player hook from an
**unordered** queue (`mod_modular_vanilla.nut:82`). Nothing constrains their
relative order, so this is luck, not design — and when it loses, the Beastmaster
conversion silently never runs. No error, no log line.

Two things to do:

- **Cheap empirical check:** modular_vanilla is installed right now. Hire from a
  large non-southern town and see whether a drafted Houndmaster becomes a
  Beastmaster. That tells you which way the order currently falls on this machine.
- **Durable fix:** move the conversion off `setStartValuesEx`.
  `character_background.onAdded()` exists (vanilla
  `skills/backgrounds/character_background.nut:417`), the mod already hooks
  `houndmaster_background`, and the only other mod touching that class is
  Reforged — on `createPerkTreeBlueprint` / `getPerkGroupMultiplier`, different
  functions entirely. So that anchor is uncontested. It is also the more honest
  place for the logic: the rule is "this houndmaster should be a beastmaster",
  which is a fact about the background, not about player construction.

### 4. Settlement allowlist vs the original 22 descriptions — **PASS**

I re-derived the mapping independently from the original prose and terrain
keywords, and it matches the implementation exactly:

- size 3 → all 14 large forts and villages (2 slots)
- size 2 → `medium_forest_fort`, `medium_lumber_village`, `medium_mountains_fort`,
  `medium_mining_village`, `medium_swamp_fort`, `medium_swamp_village` (1 slot)
- size 1 → `small_lumber_village`, `small_swamp_village` (1 slot)
- `AC_isBeastmasterTown` = large OR the size-2 set, not small — matches the
  original, which converted on Large OR Medium only

The southern exclusion is the right call: `city_state` is size 3 and would newly
qualify under a pure size rule, and it is the only settlement with
`Culture.Southern`. Excluding it preserves 1.26 behaviour.

`getCulture()` (`settlement.nut:129`) and `getSize()` (`:59`) both verified to
exist. D7 is genuinely fixed — backup, inject, call original, restore.

### 5. `resolveTameType` coverage — **ACCEPT, with one caveat to watch**

Keying on `Const.EntityType` instead of `getName()` is the correct fix and is
what makes taming work under translation mods — the single most-reported
community complaint. Armoured-dog entries that never appear as enemy entity types
are unreachable by design, which is fine.

The caveat is the one the report already raises: frenzied direwolf is detected by
the presence of both `perk.overwhelm` and `perk.relentless`. That is a heuristic,
not an identity, and another mod granting both to ordinary direwolves would
false-positive. Acceptable for now; worth a comment pointing at a better signal
if one appears.

### 6. Play-verification — **not marked complete**

Recorded as static-only plus the 2.1 scaffolding smoke test. D5–D17 are not
play-proven and this document does not treat them as such.

---

## Additional findings from the review

Neither is a blocker.

1. **`updateRoster` has no exception safety.** `settlement.nut:83-84` calls
   `__original(_force)` and then restores `m.DraftList`. If the original throws,
   the restore never runs and the injected entries persist — reintroducing D7 in
   exactly the scenario where it is hardest to notice. Worth a `try`/`catch` that
   restores and rethrows, particularly since a throw inside roster generation is
   the leading hypothesis for the still-unexplained Nexus bug 1.

2. **`updateCompanion` still indexes `Library[m.Type]` with no null guard**
   (`accessory_foundation.nut`). Unreachable for the seven vanilla classes because
   `create` always sets a type, and wolf is excluded wholesale under Reforged. But
   any third-party accessory that defines `setEntity` and matches none of the
   `isKindOf` branches would leave `Type` null and throw on the next save. This is
   inherited from 1.26, not introduced here.

---

## Verified as correct where I expected trouble

Recording these so nobody re-checks them:

- `::Hooks.registerCSS("ui/mods/companions_tooltip.css")` /
  `registerLateJS("ui/mods/companions_tooltip.js")` — the `ui/mods/` prefix is
  correct. Modern hooks' own legacy shim does exactly
  `::Hooks.registerLateJS("ui/mods/" + path)`
  (`!!zz_modern_hooks_patch_mod_hooks.nut:24`), and Reforged uses the same full-path
  form. Both files exist at those paths.
- `::IO.enumerateFiles("mod_AC/hooks")` + `::include(file)` — same pattern
  Reforged uses (`mod_reforged.nut:186-196`).
- `.queue(">mod_msu", …)` means **after** MSU, despite `>` meaning "before" in the
  *legacy* `mods_queue` syntax. Confirmed by Reforged building its queue as
  `">" + requirement` for each required mod (`mod_reforged.nut:47-55`). The entry
  file's comment is accurate.
