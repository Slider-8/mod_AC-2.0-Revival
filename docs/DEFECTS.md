# Defect register — Accessory Companions v1.26

Baseline: the mod exactly as published (commit `c66303f`).
Target: Battle Brothers **1.5.2.3**, modern Hooks + MSU, coexisting with Reforged 0.9.1.

Sources: the 3 Nexus bug reports, 439 Nexus comments (11 pages), and a
file-by-file audit against a decompiled vanilla 1.5.x reference.

Status values: `CONFIRMED` (root cause traced to specific lines),
`UNCONFIRMED` (real symptom, cause not yet proven), `UNVERIFIED` (could not be
checked with the available reference).

---

## Critical

### D1 — Companion state is smuggled inside the item's display name `CONFIRMED`
`mod_AC.nut:1700-1804`. Type, Level, XP, Wounds, 8 attributes and the quirk list
are encoded into `m.Name` behind a `"\nmod_AC="` marker; `onSerialize` writes
only that string.

- `onSerialize`/`onDeserialize` are installed with `<-` (**replace**, not wrap),
  so the last mod to register wins. If any other mod also replaces accessory
  serialisation, this mod's payload is never written or never read, and
  `deserializeCompanionName` falls through to `m.Name = _cn`, silently resetting
  the companion to its class default. This — not renaming — is the provable
  mechanism behind "pets revert to base wardogs on load" (2+ users). A load-order
  change between saving and loading is enough to trigger it.
- `arrayBasics[1..3]` / `arrayAttributes[0..7]` are indexed with no length
  check, and `find` results feed `slice(0, findAttributes - 1)` / `(findQuirks - 1)`
  with no null check (`:1754`, `:1766`) → throws **during savegame load**.
- The payload is only ever *written* by this mod. A save made without mod_AC (or
  with another mod holding the `onSerialize` slot) contains vanilla's plain
  `writeString(m.Name)`; loading it with mod_AC then finds no marker and resets
  the companion to its class default. Toggling the mod, or a hook-order change,
  is enough.
- `SerializeQuirks.find(getQuirk.m.ID)` (`:1736`) returns **null** for any quirk
  not in that table, writing `"(null)"` into the payload; on load
  `arrayQuirks[i].tointeger()` then throws. Any mod adding companion quirks
  triggers this.

Note: this defect does **not** explain the translation-mod complaints. Those are
D5 — `TameList.find(target.getName())`. The payload is appended from live fields
at save time, so renaming the item cannot strip it.

Fix (chosen): keep the single-string stream slot — changing the stream shape
would break every existing save — but make the payload self-describing and the
parser total: validate the marker, field counts and ranges, tolerate unknown
quirks, and on any failure log loudly and keep sane defaults instead of throwing.
Wrap `onSerialize`/`onDeserialize` via the original rather than replacing them,
and chain through the immediate parent instead of jumping to `accessory`.

### D2 — Alp nightmare crash `CONFIRMED` — *Nexus bug 3*
`companions_nightmare_skill.nut:42-48`. `getDamage()` reads
`getContainer().getActor().m.Item.m.Level`. The nightmare hit is deferred 400 ms
via `Time.scheduleEvent` (`:91-108`). If the casting Alp dies inside that
window, `companions_alp.nut:266` (`onDeath`) has already set `m.Item = null`, so
the callback dereferences null.

Fix: null-guard `m.Item` in `getDamage()`, and bail out of the delayed effect if
the user is no longer alive.

### D3 — Taming a Nachzerer loses the swallowed brother `CONFIRMED` — *Nexus bug 2*
`companions_tame.nut:283-287` ends the target by hand — `IsDying = true;
IsAlive = false; removeFromMap();` with `die()` **commented out**. That bypasses
`onDeath` → `onAfterDeath`, which is the only place a swallowed actor is
returned to the map (`companions_nacho.nut:342-362`; vanilla equivalent
`ghoul.nut:225-245`). The brother stays flagged `Devoured` and off-map — from
the player's side, dead.

Fix: policy decision required (release the brother before taming, or refuse to
tame a Nachzerer that is mid-swallow). Either way the manual death sequence must
stop skipping the vanilla pipeline.

### D4 — Legacy `hookBaseClass` double-wraps shared parents `CONFIRMED`
`mod_AC.nut:491, 516, 530`. Each hook fires once per **subclass**, then walks
*up* (`while(!("fn" in o)) o = o[o.SuperName];`) and wraps the shared ancestor.

- `entity/world/settlement` — ~47 subclasses.
- `entity/tactical/actor` — dozens. Its `onDeath` body (`:534-606`) runs a full
  map-wide tile scan **plus** stash and roster scans, once per wrap, per death,
  re-rolling the companion drop each time.

Fix: `Mod.hookTree(...)`, which registers once and applies per descendant at
finalize time without re-wrapping the parent.

---

## High

### D5 — Objects identified by localised display strings `CONFIRMED`
Two instances of one mistake:

- `mod_AC.nut:453-507, 646` — settlements matched against 22 hardcoded English
  *description* paragraphs.
- `companions_tame.nut:201` + `companions_library.nut` `TameList` — tameable
  creatures matched by `TameList.find(target.getName())`.

Descriptions and creature names are localised (verified: fully translated per
settlement class in the reference decompile), so under any translation mod both
lookups miss. This is the mechanism behind the top community complaint.

Fix: match on stable identity — settlement script class / `m.Size` / culture,
and `Const.EntityType` for creatures.

### D6 — `create` replaced, breaking the subclass chain `CONFIRMED`
`mod_AC.nut:994`. `o.create <- function() { this.accessory.create(); ... }` is
installed on every accessory subclass and jumps straight to the base, skipping
the subclass's own `create`. Reforged sets `m.StaminaModifier = -3` in exactly
that skipped `wardog_item.create`.

Fix: wrap via `@(__original)`.

### D7 — Persistent pollution of `m.DraftList` `CONFIRMED`
`mod_AC.nut:497-507` appends to `this.m.DraftList` — the settlement's persistent
field. Vanilla deliberately does `draftList = clone this.m.DraftList`
(`settlement.nut:1416`) so per-roll contributions do **not** persist. The mod's
additions are written into the savegame.

Also on those lines: `array.find()` returns an **index**, and `0` is falsy, so
`if (!this.m.DraftList.find("houndmaster_background"))` is true both when absent
and when first, and `BeastmasterSettlementsLarge.find(desc)` is false for the
first entry of each list.

### D8 — ~~Foundation applied to every accessory~~ `WITHDRAWN — not a defect`
Originally recorded as "every accessory in the game gains companion fields".
That was wrong. The foundation body is gated on `if ("setEntity" in o)`
(`mod_AC.nut:972`), and exactly seven vanilla classes define or inherit
`setEntity`: `wardog_item`, `warhound_item`, `wolf_item` and the four
armoured variants. Potions, trophies and amulets are untouched, and the
`"setType" in acc` duck-test is a legitimate way to pick out those seven.

What *is* real, and narrower: `mod_AC.nut:1889-1891` register the foundation on
overlapping trees (`accessory`'s children **plus** `wardog_item` and
`warhound_item` directly), so those classes are visited more than once. Today
that is harmless only because every slot is installed with `<-`, which is
idempotent. Any change to wrap-instead-of-replace **must** add an
already-applied marker first, or serialisation will be double-wrapped and the
stream will desync. Severity: MEDIUM, and a trap for the port rather than a
live bug.

Note on stream shape: vanilla `wardog_item`/`warhound_item`/`wolf_item` each
write exactly one string (`m.Name`); the mod's replacement also writes exactly
one string (name + payload). The two are stream-equivalent, so there is **no**
desync from the replacement itself — an earlier claim in this document that it
"skips intermediate classes → stream desync" was also incorrect.

### D9 — Positional coupling across three parallel tables `CONFIRMED`
`companions_library.nut` — `TameList`, `TypeList` and `Library` (20 entries) are
index-aligned with nothing enforcing it; `companions_tame.nut:232` chains
`Library[TameList.find(name)].Type`. `companions_quirks.nut` has the same shape
with `SerializeQuirks`/`DeserializeQuirks` (63 entries each) — and those two
*are* the save format, so drift silently corrupts quirks on load. Currently
consistent; structurally fragile.

Fix: keyed structures, and a load-time assertion that the tables agree.

---

## Medium / Low

| ID | Where | Issue |
|---|---|---|
| D10 | `mod_AC.nut:98-109` | Vanilla tooltip patched by hardcoded index positions (`tooltip[2].id == 14`, `insert(3,…)`). The mod already logs a warning when this fails. Match on `id`, not position. |
| D11 | `companions_nightmare_skill.nut:72-82` | `onVerifyTarget` dereferences `_targetTile.getEntity()` *before* delegating to the base class, where vanilla's empty-tile guard lives (`skill.nut:882`). Throws on an empty tile. |
| D12 | `companions_unhold.nut:51` | `Math.rand(0.9, 1.1)` truncates to `rand(0,1)`. Vanilla uses `rand(9,11) * 0.1` (`unhold.nut:48`). Audio pitch only. |
| D13 | `companions_warwolf.nut:100-124` | Arrow/javelin corpse-decal checks chained as `else if` onto an exhaustive if/else → dead code. Every sibling file uses independent `if`. |
| D14 | `companions_library.nut:242` | Wolf `IconLeashed` variant mapping inverted. |
| D15 | `companions_regenerative.nut:38` | Hardcoded `isKindOf` class-name strings; silently stop applying if scripts are renamed. |
| D16 | 6 sites | `Math.rand(0, x.len()-1)` on containers that can be empty (see checker output). |
| D17 | `companions_noodle_tail.nut:617` | `UNVERIFIED` — possible perk ID mismatch (`perk_adrenalin` vs `perk.adrenaline`). |

---

## Reported but not reproduced

| Symptom | Source | Status |
|---|---|---|
| Southern cities show no recruit pools | Nexus bug 1 (1 reporter, 2024) | `UNCONFIRMED` — `city_state` is the **only** settlement with `Culture.Southern`, and none of the mod's 22 description strings correspond to it, so the settlement hook should append nothing there. D5/D7 are real defects but do not obviously explain this report. Needs an in-game repro with `log.html`. |
| Taming chance feels broken even at low target HP | 3+ comments | `UNCONFIRMED` — author's own answer was "raise `TameChance` in `companions_library.nut`". Likely balance, not a defect. Worth exposing as an MSU setting. |
| Alp crash on ranged hit + teleport | 2+ comments | `UNCONFIRMED` — plausibly the same null `m.Item` window as D2. |
| Nachzerer AI only eats corpses, won't fight | 2+ comments | `UNCONFIRMED` — behaviour tuning, not traced. |
| Spider/serpent invisible after taming | 2+ comments | `UNCONFIRMED` — not traced. |
| Lindwurm freezes on turn start | 2+ comments | `UNCONFIRMED` — reported against mod versions 1.17-1.18. |

---

## Not a problem

No vanilla API drift. Every `"scripts/..."` path the mod references resolves
against 1.5.2.3, and all 16 `Const.EntityType.*` values it uses still exist.
The mod's failures are logic and architecture, not a moved or renamed API.
