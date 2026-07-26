# Defect register — Accessory Companions

Baseline: the mod exactly as published (v1.26, commit `c66303f`).
Current packaged version: **v2.1.2** (Phase 1 + full Phase 2 port; Beastmaster
on `onAdded`; rawHookTree uses required `p` parameter).
Target: Battle Brothers **1.5.2.3**, modern Hooks + MSU, coexisting with Reforged 0.9.1.

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

## Reported but not reproduced

| Symptom | Status |
|---|---|
| Southern cities empty recruit pools | `UNCONFIRMED` — southern still excluded from AC draft inject (matches original lists) |
| Taming chance feels low | `UNCONFIRMED` — balance; values in `TameChance` |
| Other Nexus reports | unchanged; see prior register |

---

## Not a problem

No vanilla API drift against 1.5.2.3 for paths and EntityTypes used.
