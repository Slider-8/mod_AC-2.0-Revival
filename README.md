# Accessory Companions — revival

Revival of [Accessory Companions](https://www.nexusmods.com/battlebrothers/mods/314)
(original `mod_AC` v1.26 by Vazl, abandoned 2021) for **Battle Brothers 1.5.2.3**.

**Current release: v2.1.3** — Phase 1 + Phase 2 port (load fixes for Modern Hooks
rawHookTree / inherited onSerialize on armoured dogs).
`c66303f` is the mod exactly as published. Every commit after it is a change,
so `git diff c66303f` is the complete delta.

## Status

**Phase 1** — done (D1–D3). In-game load verified 2026-07-26.
**Phase 2** — done for planned work (registration, hook conversion, D4–D15/D17,
Reforged wolf yield). Ready for full in-game regression.

Start docs: **[docs/PHASE2-HANDOFF.md](docs/PHASE2-HANDOFF.md)**, defect table
**[docs/DEFECTS.md](docs/DEFECTS.md)**, implementation review for the prior agent
**[docs/PHASE2-REVIEW-REPORT.md](docs/PHASE2-REVIEW-REPORT.md)**.

Requires **mod_msu ≥ 1.7.0** and **mod_modern_hooks ≥ 0.4.0**.

| Fix | Defect |
|---|---|
| Alp nightmare crash | D2 |
| Nachzerer mid-swallow refuse | D3 |
| Total save payload parse | D1 |
| hookTree (no SuperName double-wrap) | D4 |
| EntityType taming + class/size settlements | D5 |
| Wrap create / serialize | D6 / D1 |
| Non-persistent draft inject | D7 |
| Keyed quirk lookup + library asserts | D9 |
| Tooltip id match, pitch, corpse, icons, regen | D10–D15, D17 |
| Yield `wolf_item` to Reforged | decision 3 |

`mod_druid` is currently **disabled** on this install — see
[docs/COMPATIBILITY.md](docs/COMPATIBILITY.md). Frozen identifiers unchanged.

## Layout

```
scripts/ gfx/ ui/        companion scripts + assets
mod_AC/hooks/            modern hook files
scripts/!mods_preload/mod_AC.nut   Hooks + MSU registration
docs/                    defects, compatibility, handoff, references
tools/check_mod.py       static checker
dist/mod_AC_<version>.zip   Vortex/data package (e.g. mod_AC_2.1.1.zip)
```

Build (reads version from the preload entry):

```bash
powershell -ExecutionPolicy Bypass -File tools/package.ps1
```

## Verification

```bash
python tools/check_mod.py --refs .refs
# expect: 0 errors
```

**In-game** (after deploying `dist/mod_AC_<version>.zip`):

1. Log: `Documents\Battle Brothers\log.html` — no new `mod_AC` errors.
2. Unleash / leash companion; save / reload levelled quirked pet.
3. Tame a beast (works under translation mods).
4. Visit a large town — houndmaster/beastmaster drafts appear without growing forever.
5. With Reforged: vanilla/Reforged wolf item not claimed as AC warwolf.

Baseline log noise from other mods (`TimeCrossingGunsmith_GetText`, `Statistics`,
Legends helmet paths) is expected.

## Constraints

- Frozen public API: mod ID `mod_AC`, path `scripts/companions/onequip/companions_unleash`,
  IDs `actives.companions_tame`, `actives.raise_companion`, `actives.unleash_companion`,
  `background.companions_beastmaster`.
- Save stream: one string on the item name; do not change shape without migration.

## Credits

Original mod by **Vazl**. Vanilla reference:
[ninkjin/Battle-Brothers-Scripts](https://github.com/ninkjin/Battle-Brothers-Scripts).
