# Accessory Companions — revival

Revival of [Accessory Companions](https://www.nexusmods.com/battlebrothers/mods/314)
(`mod_AC` v1.26, by Vazl, abandoned 2021) for **Battle Brothers 1.5.2.3**.

`c66303f` is the mod exactly as published. Every commit after it is a change,
so `git diff c66303f` is the complete delta.

## Status

**Phase 1 (bug fixes on the original structure) — done.**
**Phase 2 (port to modern Hooks + MSU) — not started.**

Nothing here has been tested in-game yet. See *Verification* below.

| Fix | Defect | Commit |
|---|---|---|
| Alp nightmare crash | D2 — *Nexus bug 3* | `1aada5d` |
| Nachzerer taming loses swallowed brother | D3 — *Nexus bug 2* | `f815b2c` |
| Savegame payload parsing made total | D1 | `caffee0` |

Still open: D4–D17 in [docs/DEFECTS.md](docs/DEFECTS.md), most of which are
resolved by the Phase 2 port rather than by patching in place.

## Layout

```
scripts/ gfx/ ui/     the mod itself — this is what ships
docs/DEFECTS.md       17 defects, root causes, and what is still unproven
docs/COMPATIBILITY.md identifiers other mods depend on; who fights us for hooks
tools/check_mod.py    static checker, stands in for a compile step
dist/mod_AC.zip       packaged build, installable via Vortex
```

## Verification

Squirrel has no test harness outside the game, so verification is two-layer.

**Static** — must be clean before any commit:

```bash
python tools/check_mod.py
```

Current: 45 files, **0 errors, 18 warnings**. The warnings are pre-existing
`rand(0, len-1)` and `.find()` patterns catalogued as D16/D7.

**In-game** — not yet done, and it is the part that actually matters:

1. Deploy `dist/mod_AC.zip` via Vortex and start the game.
2. Check `Documents\Battle Brothers\log.html` for `mod_AC` errors.
   Note the baseline: that log already contains unrelated errors from other
   mods (`the index 'Statistics' does not exist`, `TimeCrossingGunsmith_GetText`).
   Only new `mod_AC` lines count as regressions.
3. Targeted repros:
   - **D2** — have a companion Alp cast Nightmare, then kill it within the
     400 ms delay. Previously crashed.
   - **D3** — let a tier-3 Nachzerer swallow a brother, then try to tame it.
     It should now refuse; killing it normally should still return the brother.
   - **D1** — save and reload with a levelled, quirked companion equipped.
     Level, XP, wounds, attributes and quirks should all survive.
   - **Unfixed, needs a repro:** enter a southern city (`city_state`) and check
     whether the recruit pool is empty. This is Nexus bug 1 and its cause is
     still unknown — see the note in DEFECTS.md.

## Constraints worth knowing before editing

- `mod_druid` and `mod_autopilot_new` reach into this mod **by name**. The mod
  ID, one script path and four skill/background IDs are frozen public API —
  see [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md).
- The foundation is registered on overlapping class trees, so some classes are
  visited twice. Every slot currently uses `<-`, which is idempotent. **Do not
  convert serialisation to wrap-with-`__original` without first adding an
  already-applied marker**, or the save stream will be double-written.
- Companion state travels in a payload appended to the item's name string.
  Phase 2 should keep the one-string stream shape; changing it breaks every
  existing save.

## Credits

Original mod by **Vazl**. Vanilla reference from the community decompile at
[ninkjin/Battle-Brothers-Scripts](https://github.com/ninkjin/Battle-Brothers-Scripts)
(structurally accurate; string literals are Chinese-localised).
