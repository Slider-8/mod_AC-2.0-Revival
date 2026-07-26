# Accessory Companions (`mod_AC`)

Revival of [Accessory Companions](https://www.nexusmods.com/battlebrothers/mods/314)
(original **v1.26** by **Vazl**, abandoned 2021) for **Battle Brothers 1.5.2.3**.

Tame beasts, equip them as accessories, unleash them in battle, level them with
quirks, and raise fallen companions. Ported to **Modern Hooks + MSU**.

**Current version: [v2.1.9](docs/REQUIREMENTS.md)**  
Repository: [github.com/Slider-8/mod_AC](https://github.com/Slider-8/mod_AC)

---

## Requirements

Full list: **[docs/REQUIREMENTS.md](docs/REQUIREMENTS.md)**.

| | |
|---|---|
| **Game** | Battle Brothers **1.5.2.3** |
| **Required** | [Modern Hooks](https://www.nexusmods.com/battlebrothers/mods/685) **≥ 0.4.0**, [MSU](https://www.nexusmods.com/battlebrothers/mods/479) **≥ 1.7.0** |
| **Optional** | [Reforged](https://www.nexusmods.com/battlebrothers/mods/) — soft-detect; AC yields warwolf/`wolf_item` to RF when present |

---

## Install

1. Install Modern Hooks and MSU (and Reforged if you use that stack).
2. Build or take a package: `dist/mod_AC_2.1.9.zip` (see [Build](#build)).
3. Enable the zip with Vortex / drop into the game `data` folder (same as other mods).
4. Confirm in `Documents\Battle Brothers\log.html`:  
   `Modern Hooks registered Accessory Companions (mod_AC) version 2.1.9`.

---

## Features (unchanged intent from 1.26)

- Companion accessories (dogs, wolves, hyenas, serpents, nachzerers, alps, …)
- Unleash / leash in combat; tame wild beasts; raise fallen companions
- Level, XP, and quirks on the accessory tooltip
- Beastmaster background (from houndmaster) with tame/XP bonuses
- One-string save payload on the item name (legacy-compatible stream)

### Recent revival work (2.x)

| Area | Notes |
|---|---|
| Framework | Modern Hooks registration, SemVer, hook/hookTree conversion |
| Saves | Total payload parse; armoured-dog serialize fixed |
| Reforged | Soft yield of `wolf_item`; tooltip guard after RF crafting walk |
| Tooltips | Full companion panels; non-companion stats recovered if RF blueprints throw |
| Taming / drafts | EntityType resolve; non-persistent settlement draft inject |
| Combat | Alp nightmare fix; nachzerer mid-swallow not tamable |

---

## Status

| Phase | State |
|---|---|
| Phase 1 (crash/save baseline) | Done |
| Phase 2 (Hooks/MSU port, defects D4–D15/D17) | Done for planned code |
| In-game playtest | Partial — load, tooltips, companion XP/perks verified 2026-07-26; longer regression still open |

Defect table and port notes for contributors: [docs/DEFECTS.md](docs/DEFECTS.md),
[docs/PHASE2-HANDOFF.md](docs/PHASE2-HANDOFF.md).

---

## Compatibility

- **Frozen public API** (do not rename): mod ID `mod_AC`; path
  `scripts/companions/onequip/companions_unleash`; skill IDs
  `actives.companions_tame`, `actives.raise_companion`, `actives.unleash_companion`;
  `background.companions_beastmaster`.
  Details: [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md).
- **Save stream:** one string on the item name — do not change shape without a migration.
- Known stack interactions: Modular Vanilla (Beastmaster via `onAdded`), Reforged tooltips/crafting, Autopilot (consumes frozen IDs).

Broken leftover craft mods (e.g. incomplete sniper rifle / Time Crossing gunsmith)
can make Reforged’s blueprint walk throw. AC **2.1.9** recovers full item stats
via a tooltip cache; disabling those leftovers still cleans the log.

---

## Build

```bash
# static check (0 errors expected; known warnings catalogued)
python tools/check_mod.py

# package → dist/mod_AC_<SemVer>.zip  (version from scripts/!mods_preload/mod_AC.nut)
powershell -ExecutionPolicy Bypass -File tools/package.ps1
```

### Layout

```
scripts/!mods_preload/mod_AC.nut   entry (Hooks + MSU)
mod_AC/hooks/                      modern hooks + tooltip cache/guard
mod_AC/companion_tooltip.nut       full companion tooltip builder
scripts/companions/                entities, skills, library (ship)
gfx/  ui/                          icons + tall-tooltip CSS
docs/                              requirements, defects, compatibility
tools/                             package.ps1, check_mod.py
dist/                              built zips (gitignored)
```

---

## Verification (in-game)

After deploying the zip:

1. Log: no new fatal `mod_AC` errors on load.
2. Unleash / leash a companion; save and reload a levelled, quirked pet.
3. Tame a beast.
4. Large town: houndmaster/beastmaster drafts appear without unbounded growth.
5. With Reforged: RF wolf item not claimed as AC warwolf; item tooltips show stats.
6. Companion tooltip shows level, XP, attributes, quirks.

---

## Credits

- Original mod: **Vazl** ([Nexus](https://www.nexusmods.com/battlebrothers/mods/314))
- Vanilla script reference: [ninkjin/Battle-Brothers-Scripts](https://github.com/ninkjin/Battle-Brothers-Scripts)
- Revival / modern port: this repository
