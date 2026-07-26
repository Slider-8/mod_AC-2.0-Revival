# Cross-check: BB_modding_research vs mod_AC (v2.1.6)

Date: 2026-07-26  
Sources: `BB_modding_research/` (README, frameworks, mod_structure, `temp/mod_modern_hooks`),  
plus live tree `078462d`…`748bda5` / current **v2.1.6**.

This is a post-hoc review of whether Phase 2 matches framework research and
whether remaining risks are acceptable.

---

## 1. Research folder (what it is)

| Path | Use for AC |
|---|---|
| `README.md` | Modern register + `@(__original)` cheat sheet |
| `frameworks.md` | Legacy mod_hooks + MSU overview (partly outdated vs Modern Hooks) |
| `mod_structure.md` | Layout, **Squirrel `=` vs `<-`**, load order |
| `spawn_system.md` | DSF — little AC relevance |
| `temp/mod_modern_hooks/` | **Authoritative** for `hook`/`rawHookTree` param rules |
| `temp/mod_msu/`, `mod_modular_vanilla/` | MSU systems, setStartValuesEx replace pattern |

**Gap that hurt us:** Phase 2 implementation initially used only `mod_AC/docs` +
`.refs`, not this research tree. Several load bugs (`function(p)`, `=` vs `<-`)
are spelled out in research / modern_hooks sources.

---

## 2. Alignment with research “modern style”

### Registration — **PASS**

Research pattern:

```squirrel
::MyMod <- { ID, Name, Version = "x.y.z" };
::MyMod.HooksMod <- ::Hooks.register(...);
::MyMod.HooksMod.require(["mod_msu >= 1.7.0"]);
::MyMod.HooksMod.queue(function() {
    ::MyMod.Mod <- ::MSU.Class.Mod(...);
});
```

AC (`scripts/!mods_preload/mod_AC.nut`):

- Same shape with `::AC`, SemVer **2.1.6**, require MSU + modern_hooks  
- Queue `">mod_msu"` then `MSU.Class.Mod` + CSS + `enumerateFiles("mod_AC/hooks")`  
- Matches research README and Reforged-style layout (`mod_AC/hooks/`)

### Hook API param names — **PASS (after hotfixes)**

From `temp/mod_modern_hooks/.../queue/mod.nut`:

| API | Required param name |
|---|---|
| `hook` / `hookTree` | **`q`** |
| `rawHook` / `rawHookTree` | **`p`** |

Current tree:

| File | API | Param |
|---|---|---|
| Most hooks | `hook` / `hookTree` + `@(__original)` | `q` |
| `accessory_foundation.nut` | `rawHookTree` | `function(p)` |

v2.1.1–2.1.2 fixed the fatal `function(o)` mistake. Matches research sources.

### Squirrel `=` vs `<-` — **PASS (after hotfixes)**

`mod_structure.md` lines 87–88:

- `<-` new slot  
- `=` existing slot only  

Armoured dogs inherit `onSerialize` → child table has **no** slot → `p.onSerialize =` threw (v2.1.3–2.1.4). Fixed with `p.onSerialize <-` / `onDeserialize <-`. Matches research.

### UI CSS/JS — **PASS with intentional deviation**

Research shows legacy:

```squirrel
::mods_registerCSS("my_mod/style.css");  // → ui/mods/ prefix via shim
```

AC registers:

```squirrel
::Hooks.registerCSS("ui/mods/companions_tooltip.css");
// registerLateJS intentionally NOT used (v2.1.6)
```

Full `ui/mods/` path matches modern_hooks `registerCSS` contract.  
**Not** registering LateJS that patches `setupUITooltip` is correct under Nested
Tooltips + Reforged (research does not document that fight; runtime did).

### Modular vanilla / Beastmaster — **PASS**

Research notes modular_vanilla extracts hookable pieces. AC no longer wraps
`player.setStartValuesEx` (which modular_vanilla **replaces** without
`__original`). Conversion is on `houndmaster_background.onAdded` (v2.1.1).  
Matches handoff review + research “hooks must compose”.

---

## 3. Architecture review (current design)

### What is solid

| Area | Assessment |
|---|---|
| Entry + SemVer + hard require MSU/MH | Correct modern pattern |
| Split hooks under `mod_AC/hooks/` | Matches research layout |
| Frozen mod ID `mod_AC` | Preserved for druid/autopilot |
| D4 hookTree (settlement, human, actor, …) | Correct D4 fix |
| D5 EntityType taming + settlement class/size | Correct vs prose |
| D7 temp DraftList + try/catch restore | Correct; research-aligned safety |
| D9 library Type assert + SerializeQuirksByID | Adequate |
| Reforged wolf yield | Soft-detect; skip foundation on warwolf Script |
| Static check | 0 errors / 15 known warnings |

### Hybrid foundation (`rawHookTree` + `<-`) — **ACCEPT with caveats**

Research prefers Q-style:

```squirrel
q.fn = @(__original) { function fn(...) { ... }}.fn;
```

AC foundation uses **raw** prototype + `<-` for many members. Reasons still valid:

- Many new methods/fields on pet accessories  
- Armoured classes partial method tables  
- Avoid `newSlotM` errors on existing `m` fields  

Caveats:

1. **Serialize is replace-via-`<-`**, not `@(__original)` — last mod to assign
   `onSerialize` on that class wins (same as original AC risk; stream shape OK).  
2. **getTooltip is full replace** on pet classes — shadows Reforged’s accessory
   `getTooltip` wrap for those items (by design; companion tooltips are custom).  
3. **`create` capture** only when `"create" in p` — true for all seven pet classes.

### Remaining technical risks

| Risk | Severity | Notes |
|---|---|---|
| `actor` hookTree `onDeath` vargv warnings | Low | Log noise; drop logic still runs |
| Frenzied direwolf = overwhelm+relentless | Low | Heuristic; research has no better API note |
| Southern cities excluded | By design | Matches 1.26 prose lists |
| Non-AC item tooltips | Env | If still broken after 2.1.6, check Reforged crafting `getName` in log |
| Play verification incomplete | High for release | Long test checklist still open |
| Research docs partly legacy | Meta | Prefer `temp/mod_modern_hooks` over frameworks.md for API |

### Research vs PORTING-GUIDE

`docs/reference/PORTING-GUIDE.md` is richer and more accurate for Modern Hooks
than `frameworks.md` (which still leads with `mods_registerMod`).  
**Order for agents:** research `temp/` sources + PORTING-GUIDE > research
markdown summaries > training memory.

---

## 4. Defect / version map (quick)

| Version | Fix |
|---|---|
| 2.1.0 | Phase 2 bulk port |
| 2.1.1 | Beastmaster → `onAdded` |
| 2.1.2 | rawHookTree `function(p)` |
| 2.1.3–2.1.4 | armoured `onSerialize` / `<-` |
| 2.1.5 | getTooltip harden; JS chain attempt |
| 2.1.6 | **no** LateJS tooltip patch |

Package: `dist/mod_AC_2.1.6.zip` via `tools/package.ps1`.

---

## 5. Verdict

| Question | Answer |
|---|---|
| Does the mod match modern registration research? | **Yes** |
| Did we apply Modern Hooks param / slot rules correctly *now*? | **Yes** (after runtime fixes) |
| Did we ignore research early and pay for it? | **Yes** — document as lesson |
| Release-ready without long playtest? | **No** — architecture OK; playproof incomplete |
| Next code priority if tooltips still odd? | Confirm 2.1.6 deployed; then non-AC log errors (Reforged blueprint `getName`) |

**Overall:** Phase 2 design is consistent with BB research **modern** patterns
and with the handoff review (post–2.1.1). Remaining work is **play verification**
and optional polish (onDeath vargv, D16 guards), not another structural port.
