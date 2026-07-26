# mod_AC — version requirements

Canonical dependency list for **Accessory Companions** (`mod_AC`).  
Source of truth for hard requires: `scripts/!mods_preload/mod_AC.nut`  
(`::Hooks.register` + `::AC.HooksMod.require`).

Current packaged AC version: **2.1.9** (SemVer; MSU tracks save/mod version).

---

## Game

| Component | Requirement | Notes |
|---|---|---|
| Battle Brothers | **1.5.2.3** (target) | Phase 1+2 revival target. Older BB not supported. |

---

## Hard dependencies (load fails without these)

Declared in entry:

```squirrel
::AC.HooksMod.require([
	"mod_msu >= 1.7.0",
	"mod_modern_hooks >= 0.4.0"
]);
```

| Mod ID | Minimum version | Role |
|---|---|---|
| `mod_modern_hooks` | **≥ 0.4.0** | Registration, `hook` / `hookTree` / `rawHookTree`, queues |
| `mod_msu` | **≥ 1.7.0** | `::MSU.Class.Mod`, SemVer, serialization helpers |

**Queue:** main hooks run `>mod_msu`. Outer tooltip guard also runs `>mod_reforged` when that mod exists (see soft deps).

MSU itself requires Modern Hooks on current stacks; install both.

---

## Soft / optional (supported, not required)

| Mod ID | Relation | Behaviour when present |
|---|---|---|
| `mod_reforged` (core) | Soft-detect | `::Hooks.hasMod("mod_reforged")`: yield `wolf_item` / warwolf to RF; queue tooltip guard **after** RF so outer try/cache wraps RF craft walk |
| `mod_reforged_assets` | RF stack | Usually ships with Reforged; AC does not require it by ID |
| `mod_nested_tooltips` | Common with RF/MSU | AC does **not** hard-require it; do **not** LateJS-patch `setupUITooltip` (fights Nested Tooltips) |
| `mod_modular_vanilla` | Common | Replaces `setStartValuesEx`; AC does **not** wrap that — Beastmaster uses `houndmaster_background.onAdded` |

None of the soft mods are listed in `.require([...])`. Missing Reforged is fine (AC keeps its own wolf path).

---

## Downstream consumers (they require AC, not the reverse)

These mods call into AC by frozen IDs/paths. AC does **not** depend on them.  
Full frozen API: [COMPATIBILITY.md](COMPATIBILITY.md).

| Mod | Pins |
|---|---|
| `mod_autopilot_new` | `actives.companions_tame`, `actives.raise_companion`, `actives.unleash_companion`, `background.companions_beastmaster` |
| `mod_druid` | `mod_AC` mod ID, path `scripts/companions/onequip/companions_unleash` (druid currently disabled on this install) |

---

## Not required / leave disabled if broken

Environmental junk that broke **other** tooltips via Reforged crafting blueprints (not AC deps). Safe/disabled leftovers:

| Item | Notes |
|---|---|
| `mod_timecrossing_gunsmith` | Broken preload (`TimeCrossingGunsmith_GetText`); disabled |
| Sniper rifle item scripts | Missing `sniper_rifle` / ammo scripts; leftover content — remove/disable |

AC still recovers full item stats if other mods leave broken blueprints (v2.1.9 cache).

---

## Verified-with stack (this install, 2026-07-26)

Not minimums — versions observed loading successfully with AC **2.1.9**:

| Mod | Version seen in log |
|---|---|
| Battle Brothers | 1.5.2.3 |
| Modern Hooks (`mod_modern_hooks`) | 0.6.0 |
| MSU (`mod_msu`) | 1.9.0 |
| Nested Tooltips (`mod_nested_tooltips`) | 0.5.3 |
| Modular Vanilla (`mod_modular_vanilla`) | 0.9.1 |
| Reforged (`mod_reforged`) | 0.9.2 |
| Reforged assets (`mod_reforged_assets`) | 0.1.4 |

**Long play session (same day, ~17:36–20:55):** AC **2.1.9** — zero `getTooltip`
failures, zero AC fatals after TimeCrossing/sniper leftovers disabled. Full write-up:
[PLAYTEST.md](PLAYTEST.md). Remaining log noise is non-AC (RPGR `Statistics`, UI
procedural assets, zip scan, one Nested Tooltips JS TypeError).

---

## Package / deploy

| Artifact | Rule |
|---|---|
| Zip name | `dist/mod_AC_<SemVer>.zip` (from `AC.Version` in preload entry) |
| Build | `powershell -ExecutionPolicy Bypass -File tools/package.ps1` |
| Mod ID | Always `mod_AC` (frozen) |

---

## When to bump this file

- Change to `.require([...])` floors  
- Change of supported BB version  
- New hard or soft dependency behaviour  
- New frozen public API consumer (also update COMPATIBILITY.md)
