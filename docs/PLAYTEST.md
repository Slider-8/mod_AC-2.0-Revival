# Playtest / log verification log

Manual in-game sessions against packaged **mod_AC**. Log path:
`C:\Users\igorl\Documents\Battle Brothers\log.html` (overwritten each launch).

Status values for this file: session notes only — defect IDs stay in [DEFECTS.md](DEFECTS.md).

---

## Session 2026-07-26 A — tooltips + short combat (~16:26–16:34)

| | |
|---|---|
| **Build** | 2.1.8 → then **2.1.9** (tooltip cache) |
| **Focus** | Item tooltips bare (name/worth only); companion “King” vs full serpent panel |
| **Result** | **PASS** after 2.1.9: Spetum/armor stats restored; companions full builder |
| **AC log** | `getTooltip failed … recovering cached` **once** (by design); no fatals |
| **Env** | TimeCrossing gunsmith + sniper scripts still present → RF `getName` throws |

User later **disabled** TimeCrossing gunsmith and sniper leftovers.

---

## Session 2026-07-26 B — dog XP / perks (~16:30+)

| | |
|---|---|
| **Build** | **2.1.9** |
| **Focus** | Companion tooltip after level-up (XP bar, quirks/perks) |
| **Result** | **PASS** (player-confirmed) |
| **AC log** | Clean aside from load-time `onDeath` vargv warnings |

---

## Session 2026-07-26 C — long manual play (~17:36–20:55, ~3.3 h)

| | |
|---|---|
| **Build** | **2.1.9** |
| **Log window** | first stamp `17:36:38` → last `20:55:22` |
| **Log size** | ~2.1 MB |
| **Focus** | Extended campaign/combat; no AC code changes mid-session |
| **Result** | **PASS for AC** — no AC fatals, no tooltip recovery path fired |

### AC lines (session C)

| Check | Count / note |
|---|---|
| Registered `Accessory Companions (mod_AC) version 2.1.9` | Yes |
| Queue after `mod_msu` | Yes |
| Queue after `mod_msu`, `mod_reforged` (tooltip guard) | Yes |
| `getTooltip failed` / recovering cache / using fallback | **0** |
| `MOD ERROR` / `errorAndQuit` / incompatible | **0** |
| sniper / TimeCrossing | **0** (disabled) |
| `onDeath` vargv wrap warnings | **×6** load-time only (known noise) |

### Non-AC noise (session C) — do not treat as AC regressions

| Issue | Approx | Source |
|---|---|---|
| UI `Failed to load procedural content` … `socket,miniboss,arrow` | **×66** | Missing procedural UI asset |
| `mod_rpgr_parameters` `Statistics` does not exist | **×3** | legendary sword blade hook path at load |
| Item Tables cache fail `legendary_sword_blade_item` | **×1** | same as above |
| `Unable to open file "gfx/ui/items/"` unknown mime | **×2** | UI path glitch |
| Missing font `gfx/fonts/arsenal/Arsenal-Regular.ttf` | **×2** | font/UI pack |
| JS TypeError `entityImage.data('placeholder').css` | **×1** | Nested tooltips / velocity (~20:17) |
| `IOUnexpected file … *.zip` | **×93** | data-folder zip scan |
| Steam Cloud `steam_autocloud.vdf` | occasional | ignore |

### Still open (not failed in these sessions)

Long formal checklist items still useful for a future pass:

1. Unleash / leash + save / reload levelled quirked pet across restart  
2. Tame a beast under a non-English locale if available  
3. Large town drafts (houndmaster/beastmaster) without unbounded DraftList growth  
4. Reforged wolf item not claimed as AC warwolf  
5. Raise companion / edge combat (alp nightmare, nachzerer swallow)  

---

## Summary

| Build | Sessions | AC verdict |
|---|---|---|
| **2.1.9** | tooltips, dog XP, **~3.3 h** manual | **No AC log errors mid-run**; tooltips/cache path idle once leftovers disabled |

Last full log review: **2026-07-26** (session C).

## 2026-07-28 — v2.1.11, taming confirmed working

First **play-proven** result for the targeting path. Source: `log.html` for the
2.1.11 run, plus Igor taming a snake in-game.

| Check | Result |
|---|---|
| Load | `(mod_AC) version 2.1.11` |
| mod_AC script errors | **none** |
| Other script errors | 3 × `the index 'Statistics' does not exist`, all `mod_rpgr_parameters` → `getKrakenBuiltState` on a legendary sword blade — pre-existing baseline, unrelated |
| mod_AC warnings | only the D19 `onDeath` vargv notice, expected and documented |
| Save migration | `MSU Serialization: Loading old save for Accessory Companions (mod_AC), 2.1.10 -> 2.1.11` |
| Tame a snake | **succeeded** |
| Autosave after tame | `Save campaign: autosave_01` / `Finished saving scene.` with no serialization error |

**Now play-proven:** D18 (hover over scenery with Tame selected no longer throws)
and D20 (targeting accepts legitimate targets again). The autosave also exercised
the D1 one-string payload **write** path with a real tamed companion equipped.

**Not yet proven — the read path.** Nothing here loads that save back. The next
useful check is loading `autosave_01` and confirming the snake survives with its
level, XP and quirks intact. A payload that writes cleanly can still fail to parse.

Note on reading these logs: the "successfully tamed" message goes to the in-game
tactical event log, not to `log.html`, so its absence from the file is expected
and is not evidence either way. BB also overwrites `log.html` on every launch —
quit and read it before relaunching, or the evidence is gone.

## 2026-07-28 — v2.1.13/2.1.14, frenzied hyena resolved

Instrumented build confirmed the frenzied hyena is targetable again; the only
remaining rejection is the intended post-failure lockout. Root cause was D21
feeding the wrong `MaxPerCompany` into `hasMaxTamed` -- see D22 in DEFECTS.md.

Also verified in the same log: no `mod_AC` script errors, and the "allied with
user" rejections against the player's own brothers are correct behaviour.

Low taming success rate reviewed and **accepted as intended** -- do not tune
`TameChance` without asking.

Still not exercised: loading a save back with a levelled, quirked companion
equipped (the payload **read** path). That remains the top outstanding check.
