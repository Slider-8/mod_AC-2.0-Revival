# Phase 2 handoff — port mod_AC to modern Hooks + MSU

You are picking this up cold. Everything you need is in this repo; the session
that did Phase 1 is gone. Read this file, then `docs/DEFECTS.md`, then
`docs/COMPATIBILITY.md` before touching code.

**Repo:** `C:\Users\igorl\Documents\05_Games_&_Entertainment\Modding\mod_AC`
**Game:** Battle Brothers **1.5.2.3** at `C:\Games\Steam\steamapps\common\Battle Brothers`
(not the default Steam path). Mods deploy to `<game>\data\*.zip` via Vortex.

---

## Where things stand

Phase 1 fixed three defects on the mod's original legacy structure and
**was confirmed working in-game by Igor on 2026-07-26**. Packaged as **v2.0.0**
(SemVer via modern Hooks). Do not re-litigate it.

**Phase 2 complete (v2.1.0).** Registration, hook conversion (D4), D5–D7, D6,
D9, Reforged wolf yield, and D10–D15/D17 are in tree. See `docs/DEFECTS.md`.

**Review for the handoff author:** `docs/PHASE2-REVIEW-REPORT.md` — what was
done, deviations, unverified claims, residual risks.

| Commit | What |
|---|---|
| `c66303f` | Baseline — the mod exactly as published. `git diff c66303f` is the entire delta. |
| `1aada5d` | Alp nightmare crash (Nexus bug 3) |
| `f815b2c` | Refuse taming a nachzerer mid-swallow (Nexus bug 2) |
| `caffee0` | Savegame payload parsing made total |

**Your job is Phase 2: port from the legacy `mod_hooks` API to modern Hooks + MSU.**
That structurally resolves D4, D5, D6, D7, D9 and D10. Phase 1 deliberately did
not touch them, because patching them in place then porting would be double work.

## Decisions already made with Igor — do not reopen

1. **Port to modern Hooks/MSU.** Not a defensive patch on the legacy API.
2. **Soft-detect Reforged.** The mod must work standalone *and* alongside
   Reforged 0.9.1. No hard dependency.
3. **Yield `wolf_item` to Reforged.** If Reforged is present, mod_AC does not
   claim `wolf_item` and the Warwolf companion type is disabled. Standalone,
   behaviour is unchanged.
4. **A nachzerer holding a swallowed actor is not tamable.** Already implemented;
   preserve this behaviour through the port.

## Hard constraints — violating these breaks things silently

1. **Frozen public API.** `mod_druid` and `mod_autopilot_new` reach into this mod
   by name. (`mod_druid` is disabled right now — it errored at launch, see the
   open item in `docs/COMPATIBILITY.md` — but `mod_autopilot_new` is still
   enabled, and druid re-pins these the moment anyone enables it.) The mod ID `mod_AC`, the script path
   `scripts/companions/onequip/companions_unleash`, and the IDs
   `actives.companions_tame`, `actives.raise_companion`,
   `actives.unleash_companion`, `background.companions_beastmaster` **must keep
   resolving**. Full evidence in `docs/COMPATIBILITY.md`. Renaming any of them
   produces no error anywhere — it just quietly disables the other mod's support.

2. **Do not change the save stream shape.** Companion state rides in a payload
   appended to the item's name string, written as the single string that vanilla
   `wardog_item`/`warhound_item`/`wolf_item` already write. It is
   stream-equivalent to vanilla. Adding or removing a read/write breaks every
   existing save. Keep one string.

3. **Add an already-applied marker before converting to `__original` wrapping.**
   `mod_AC.nut:1889-1891` register the foundation on overlapping class trees
   (`accessory`'s children *plus* `wardog_item` and `warhound_item` directly), so
   several classes are visited twice. Today that is harmless only because every
   slot uses `<-`, which is idempotent. Wrapping without a guard double-wraps
   serialisation and desyncs the stream. This is the single most likely way to
   corrupt saves during this port.

4. **`mod_modular_vanilla` 0.7.2 is installed and *replaces*
   `entity/tactical/player.setStartValuesEx`** without calling `__original`. A
   replacement discards wrappers registered beneath it. The Beastmaster
   conversion currently rides on that function — it needs a different anchor.

## The work, in suggested order

Keep phases to **5 files or fewer**, run the checker, and commit each separately.

1. **Registration + scaffolding.** ~~Replace `::mods_registerMod` / `::mods_queue`
   with `::Hooks.register` + `require(["mod_msu >= 1.7.0"])`, and an
   `::MSU.Class.Mod`. Split into per-target hook files.~~ **DONE** — entry is
   `scripts/!mods_preload/mod_AC.nut`; hooks live in `mod_AC/hooks/`.
2. **Convert hooks, fixing D4 as you go.** ~~Every
   `mods_hookBaseClass` + SuperName climb becomes `hookTree`.~~ **DONE** —
   see `mod_AC/hooks/*.nut`. Foundation uses `rawHookTree` + already-applied
   marker on `mod_AC_FoundationApplied`.
3. **Replace prose matching (D5).** ~~DONE~~ — settlements use Size/class;
   taming uses `resolveTameType` / EntityType.
4. **Stop mutating `m.DraftList` (D7).** ~~DONE~~ — temp inject + restore around
   `updateRoster`.
5. **Reforged integration.** ~~DONE~~ — wrap create/serialize; yield `wolf_item`
   when `mod_reforged` is present.
6. **Keyed tables (D9).** ~~DONE~~ — library Type asserts; `SerializeQuirksByID`.
7. **Remaining Medium/Low** — ~~DONE~~ for D10–D15, D17; D16 partial.

## Reference material in this repo

| Path | What it is |
|---|---|
| `docs/DEFECTS.md` | 17 defects with root causes; also lists what is reported but **unproven** |
| `docs/COMPATIBILITY.md` | Frozen identifiers + which installed mods contend for the same vanilla functions |
| `docs/reference/PORTING-GUIDE.md` | **Read this before writing any hook.** Modern Hooks/MSU API with `file:line` citations into the actual framework sources — registration, all hook kinds, wrap syntax, queue buckets, soft-dependency detection, MSU settings, serialisation, Reforged's integration surface. Items it could not verify are marked NOT FOUND IN SOURCES; trust that marking. |
| `docs/reference/compat-survey.md` | Full survey of ~90 installed mods vs this mod's hook surface |
| `docs/reference/core-audit-notes.md` | Original line-by-line audit of `mod_AC.nut` |
| `docs/reference/nexus-posts-scrape.txt` | All 439 Nexus comments, scraped. Source for the "reported but unreproduced" list. |
| `tools/check_mod.py` | Static checker — the closest thing to a compile step |
| `tools/setup_refs.sh` | Rebuilds the vanilla + framework trees the checker needs |
| `tools/nexus_scrape.py` | CDP scraper, if you need to re-read Nexus |

## Setup

```bash
cd "C:/Users/igorl/Documents/05_Games_&_Entertainment/Modding/mod_AC"
bash tools/setup_refs.sh          # clones vanilla + unzips MSU/Reforged/hooks into .refs/
python tools/check_mod.py --refs .refs
```

Expected after Phase 2.1: **57 files, 0 errors, 18 warnings**. The warnings are
catalogued as D7/D16 — do not treat them as new. Keep errors at zero.
Run as `python tools/check_mod.py --refs .refs` from the repo root.

Two things about the vanilla reference:
- It is a **Chinese-localised** decompile. Structure and identifiers are
  accurate; **never** use it to compare English strings.
- You cannot fall back to the shipped game files: BB 1.5.x `.cnut` files are
  encrypted (`RIQS` magic, high entropy), so grepping `data_*.dat` for strings
  or code will not work.

## Verifying your work

Static checking is necessary but not sufficient — Squirrel has no offline test
harness, so **you cannot claim a fix works**. Only Igor running the game can.

Ask him to test, and tell him exactly what to do. When he does:

- The game log is `C:\Users\igorl\Documents\Battle Brothers\log.html`.
- That log **already contains unrelated errors** from other mods
  (`the index 'Statistics' does not exist`, `TimeCrossingGunsmith_GetText`).
  Establish that baseline first; only new `mod_AC` lines are regressions.
- Highest-value regression checks after the port: save/reload with a levelled,
  quirked companion equipped; unleash and leash; tame something; upgrade wardog
  armour; enter a town and check recruits still appear.

## Still unexplained — do not claim you fixed it

**Nexus bug 1, "Southern Cities do not show recruit pools."** Unreproduced and
unexplained. `city_state` is the only settlement with `Culture.Southern` /
`isSouthern() == true`, and *none* of the mod's 22 description strings correspond
to it, so the settlement hook should append nothing there. The obvious theory
(prose matching) does not hold. If Igor can reproduce it with a log, that is real
evidence; until then leave it listed as `UNCONFIRMED` in `docs/DEFECTS.md`.

Phase 1 twice recorded findings that turned out to be wrong (D8, withdrawn; and a
"stream desync" claim that was not real). Both were caught by checking the vanilla
source rather than reasoning from the mod alone. Do the same: verify against
`.refs/vanilla` before asserting anything, and mark what you could not verify.
