# mod_AC — Accessory Companions revival

## Purpose

Revive and modernise [Accessory Companions](https://www.nexusmods.com/battlebrothers/mods/314) (`mod_AC`) for Battle Brothers **1.5.2.3**. Current packaged version: **v2.1.0**. Phase 1+2 complete (modern Hooks/MSU, D1–D15/D17, Reforged wolf yield).

## Ownership

- **Ship surface:** `scripts/`, `gfx/`, `ui/`, `mod_AC/` (what goes into `dist/mod_AC.zip`)
- **Docs / handoff:** `docs/`
- **Tooling:** `tools/`

## Local Contracts

- **Mod ID** stays exactly `mod_AC`.
- **Frozen public API** (other mods reach in by name): script path `scripts/companions/onequip/companions_unleash`; IDs `actives.companions_tame`, `actives.raise_companion`, `actives.unleash_companion`, `background.companions_beastmaster`. Full list in `docs/COMPATIBILITY.md`.
- **Save stream shape** is one string payload on the item name; do not add/remove serialised fields without a migration plan.
- **Decisions locked:** port to Hooks/MSU; soft-detect Reforged and yield `wolf_item` when present; nachzerer mid-swallow is not tamable.
- Game install: `C:\Games\Steam\steamapps\common\Battle Brothers`. Log: `C:\Users\igorl\Documents\Battle Brothers\log.html`.

## Work Guidance

- Phase 1 is done (D1–D3). Do not re-open it.
- Phase 2 complete: entry `scripts/!mods_preload/mod_AC.nut`; hooks in `mod_AC/hooks/`. Prefer EntityType/class keys over prose; never persist DraftList pollution; yield wolf to Reforged.
- Handoff author review package: `docs/PHASE2-REVIEW-REPORT.md`.
- Phase 2 handoff: `docs/PHASE2-HANDOFF.md` — read that, then `docs/DEFECTS.md`, then `docs/COMPATIBILITY.md`, then `docs/reference/PORTING-GUIDE.md` before writing hooks.
- Keep hook phases to ≤5 files; run `python tools/check_mod.py --refs .refs` before claiming static cleanliness.
- In-game verification is the only proof a fix works; static check is necessary but not sufficient.
- Baseline log noise from other mods is expected; only new `mod_AC` lines are regressions.

## Verification

```bash
python tools/check_mod.py
# expected: 0 errors; pre-existing warnings (D7/D16) are catalogued
```

Package:

```bash
powershell -ExecutionPolicy Bypass -Command "Compress-Archive -Path scripts,gfx,ui,mod_AC -DestinationPath dist/mod_AC.zip -Force"
```

## Child DOX Index

| Path | Scope |
|---|---|
| `docs/` | Defects, compatibility, Phase 2 handoff, reference material (no separate AGENTS.md; contracts live in those docs) |
| `scripts/` | Runtime Squirrel sources (ship) |
| `mod_AC/` | Modern entry helpers + per-target hook files (ship) |
| `tools/` | Static checker, reference setup, scrapers |
| `gfx/`, `ui/` | Assets (ship) |
