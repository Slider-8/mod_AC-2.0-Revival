# Battle Brothers Porting Reference: Legacy mod_hooks -> Modern Hooks + MSU

Target: BB 1.5.2.3, coexisting with Reforged 0.9.1. Source of truth for every
claim below is cited as `file:line` relative to
`.../scratchpad/refs/` (base path omitted for brevity). All code is copied
or lightly adapted from the actual source files; nothing is invented.

Sources read:
- `mod_modern_hooks/` (Modern Hooks framework)
- `mod_msu/` (MSU 1.7.2)
- `stdlib/` (stdlib 2.5)
- `mod_reforged_core_0.9.1_Ks0c9R8EM/` (Reforged 0.9.1)

---

## 1. Registration: mod ID, version, require / conflictWith / compatibilityWith

Modern Hooks registration is a **two-step process** when a mod also wants MSU
services (settings, serialization, keybinds, registry, tooltips):

**Step 1 — register with Hooks** (mandatory, gives you the `Mod` object with
`.require()`, `.conflictWith()`, `.queue()`, `.hook()`, etc.):

```squirrel
::Hooks.register <- function( _modID, _version, _modName, _metaData = null )
```
`mod_modern_hooks/scripts/mods/../modern_hooks/public_globals.nut:1-6` (path:
`mod_modern_hooks/modern_hooks/public_globals.nut:1`). `_version` **must** be
a SemVer string (`https://semver.org`) or `Hooks.errorAndThrow` fires
(`modern_hooks/public_globals.nut:1-6`). Registering the same `_modID` twice
throws (`modern_hooks/private_globals.nut:75-78`).

**Step 2 — wrap with an MSU Mod object** (only if you want MSU systems):

```squirrel
::MSU.Class.Mod <- class
{
	constructor( _id, _version, _name = null )
	{
		...
		::MSU.System.Registry.registerMod(this); // enforces id/version match with step 1
		::MSU.System.Debug.registerMod(this);
		::MSU.System.ModSettings.registerMod(this);
		::MSU.System.Keybinds.registerMod(this);
		::MSU.System.Serialization.registerMod(this);
		::MSU.System.PersistentData.registerMod(this);
		::MSU.System.Tooltips.registerMod(this);
	}
```
`mod_msu/msu/systems/mod.nut:1-37`. `RegistrySystem.registerMod` **requires**
that a Hooks mod with the same ID and identical version string already exists,
or it throws (`mod_msu/msu/systems/registry/registry_system.nut:29-51`):

```squirrel
if (::Hooks.getMod(_mod.getID()) == null)
	throw ::MSU.Exception.KeyNotFound(_mod.getID()); // "Register your mod using the same ID with mod_hooks before creating a ::MSU.Class.Mod"
if (::Hooks.getMod(_mod.getID()).getVersionString() != _mod.getVersionString())
	throw ::MSU.Exception.InvalidValue(_mod.getVersionString());
```

**require / conflictWith** (on the Hooks `Mod` object, `modern_hooks/queue/mod.nut:128-174`):

```squirrel
function require( ... )       // pushes CompatibilityData(Requirement)
function conflictWith( ... )  // pushes CompatibilityData(Incompatibility)
```
Both accept either varargs strings or a single array of strings
(`modern_hooks/queue/mod.nut:128-136`). Each string is parsed as
`"modID[ operator version][ (Display Name)][: details]"` via
`__parseCompatibilityModInfo` (`modern_hooks/queue/mod.nut:83-126`). There is
no separate "compatibilityWith" API in Modern Hooks — `require`/`conflictWith`
are the whole compatibility surface (`modern_hooks/enums.nut:31-34`,
`CompatibilityType = {Requirement, Incompatibility}`). "compatibilityWith" as
worded in the task is **NOT FOUND IN SOURCES** as a distinct method name.

**How Reforged itself does it** — the real, load-bearing example
(`mod_reforged_core_0.9.1_Ks0c9R8EM/mod_reforged/hooks/load.nut:1-45`):

```squirrel
::Reforged <- { Version = "0.9.2", ID = "mod_reforged", Name = "Reforged Mod", ... };

local requiredMods = [
	"vanilla >= 1.5.2-2",
	"mod_modular_vanilla >= 0.8.3",
	"mod_msu >= 1.9.0",
	"mod_nested_tooltips >= 0.5.3",
	"mod_modern_hooks >= 0.4.10"
	"dlc_lindwurm", "dlc_unhold", "dlc_wildmen", "dlc_desert", "dlc_paladins",
	"mod_dynamic_perks >= 0.5.0"
	"mod_dynamic_spawns >= 0.6.0",
	"mod_item_tables >= 0.1.3",
	"mod_upd",
	"mod_stack_based_skills >= 0.5.1",
	"mod_reforged_assets >= 0.1.4"
];

::Reforged.HooksMod <- ::Hooks.register(::Reforged.ID, ::Reforged.Version, ::Reforged.Name);
::Reforged.HooksMod.require(requiredMods);
::include("mod_reforged/mod_conflicts");   // calls .conflictWith([...])
```

and later, inside a queued function
(`mod_reforged_core_0.9.1_Ks0c9R8EM/mod_reforged/hooks/load.nut:160-165`):

```squirrel
::Reforged.Mod <- ::MSU.Class.Mod(::Reforged.ID, ::Reforged.Version, ::Reforged.Name);
::Reforged.Mod.Registry.addModSource(::MSU.System.Registry.ModSourceDomain.GitHub, "https://github.com/Battle-Modders/mod-reforged");
::Reforged.Mod.Registry.setUpdateSource(::MSU.System.Registry.ModSourceDomain.GitHub);
```

`conflictWith` example
(`mod_reforged_core_0.9.1_Ks0c9R8EM/mod_reforged/mod_conflicts.nut:1-16`):

```squirrel
::Reforged.HooksMod.conflictWith([
	"mod_legends",
	"mod_betterFencing [Is already included and/or enhanced in Reforged]",
	...
]);
```

MSU registers itself identically (`mod_msu/scripts/!mods_preload/msu.nut:1-3`):

```squirrel
::MSU.MH <- ::Hooks.register(::MSU.ID, ::MSU.Version, ::MSU.Name);
::MSU.MH.require("vanilla" + " >= 1.5.0-13");
::MSU.MH.conflictWith("mod_legends < 16.0.0");
```

**For your port**: register AC with `::Hooks.register("mod_ac", "1.26.0", "Accessory Companions")`,
then `.require(["mod_msu >= <version>"])`, `.conflictWith([...])` for any known
incompatible mods, then (only if you use MSU systems) create
`::AC.Mod <- ::MSU.Class.Mod(::AC.ID, ::AC.Version, ::AC.Name)` inside a
queued function that runs after `mod_msu` (see §4 for queue/load-order).

---

## 2. Hook kinds

All hook entry points are methods on the Hooks `Mod` object
(`modern_hooks/queue/mod.nut:188-218`):

| Method | Applies to | Fires more than once on the same class table? | Signature requirement |
|---|---|---|---|
| `hook(_src, function(q){...})` | The exact BB class at script path `_src` only | **No** — one call registers one hook entry in `BBClass[_src].RawHooks`, processed exactly once when that class is `include`d/finalized (`modern_hooks/private_globals.nut:320-334`, `:360-389`) | `function(q)` (1 param besides `this`), validated at `mod.nut:188-194` |
| `hookTree(_src, function(q){...})` | `_src` **and every class that inherits from it** ("descendants") | **No double-wrap of the shared parent.** The hook body runs once per **leaf/descendant class**, not once per ancestor step. `_src` itself is registered once in `BBClass[_src].TreeHooks`/`this.TreeHooks` (`private_globals.nut:336-351`), and at `__finalizeHooks` time the hook function is invoked once per entry in `hookInfo.Target.Descendants` (`private_globals.nut:422-437`), where `Descendants` is populated by `__registerForAncestorTreeHooks` walking the inheritance chain **once per subclass at its own registration time** (`private_globals.nut:308-318`). This is the direct modern replacement for legacy `::mods_hookBaseClass` — the base class body is applied once per concrete descendant, never re-applied to the shared ancestor's prototype multiple times. |
| `rawHook(_src, function(p){...})` | Exact class only, low-level | Same as `hook` — no re-fire; you get the raw prototype `p` instead of a `Q` wrapper (`private_globals.nut:320-327`, `mod.nut:204-210`) | `function(p)` |
| `rawHookTree(_src, function(p){...})` | `_src` + descendants, low-level | Same single-fire-per-descendant semantics as `hookTree`, raw prototype (`private_globals.nut:336-351`, `mod.nut:212-218`) | `function(p)` |

There is no separate "hookNewObject" entry point in Modern Hooks — the
functional equivalent (running code once per **instance** rather than per
class) is the **native-function wrapper** idiom triggered by writing
`q.someMethod = @(__native) function(){...}` instead of `@(__original)`. This
routes through `::Hooks.__Q.setNative`, which patches the class's `onInit` so
that, for every new instance, `_q.__Prototype = this` is rebound and the
wrapped setter is (re)applied per-instance before `__original()` runs
(`modern_hooks/q_object.nut:198-216`). It requires the target class to have
(or inherit) an `onInit` (`q_object.nut:200-202`). This is the closest modern
analogue to legacy `hookNewObject`. A distinct top-level function literally
named `hookNewObject` is **NOT FOUND IN SOURCES**.

`hookBaseClass` (legacy) equivalence: use `hookTree` targeting the actual
shared ancestor script (e.g. `scripts/items/accessory/accessory`) exactly
once. Modern Hooks' finalize step (`private_globals.nut:391-438`) guarantees
the ancestor's own `RawHooks`/native hooks are processed once
(`Processed = true` flag, `private_globals.nut:388`), and `TreeHooks` bodies
are applied once per descendant — so unlike legacy patterns that could
accidentally re-wrap the same function multiple times when multiple
descendants each re-triggered a base-class hook, Modern Hooks tracks
`Processed` per class table and dedupes.

---

## 3. Wrapping syntax: `q.fn = @(__original) function fn(...) {...}`

Dispatch logic lives in `::Hooks.__Q.set`
(`modern_hooks/q_object.nut:296-307`):

```squirrel
function set( _q, _key, _value )
{
	if (typeof _value != "function")
		::Hooks.errorAndThrow(...);
	local wrapperParams = _value.getinfos().parameters;
	local numParams = wrapperParams.len()
	if (numParams == 1 || (numParams == 2 && wrapperParams[1] == "__original"))
		return this.setSquirrel(_q, _key, _value);
	else if (numParams == 2 && wrapperParams[1] == "__native")
		return this.setNative(_q, _key, _value);
	::Hooks.errorAndThrow(format("... Use the q.<methodname> = @(__original) function (...) {...} syntax"));
}
```

Rules, straight from this dispatcher:

- **Wrapping an existing function**: assign a lambda whose single
  parameter is literally named `__original` (or `__native` for the
  instance-level variant, see §2), returning an inner named function that
  calls `__original(...)` somewhere inside it:
  ```squirrel
  q.applyShieldDamage = @(__original) { function applyShieldDamage( _damage, _playHitSound = true )
  {
  	if (this.getContainer().getActor().getCurrentProperties().IsSpecializedInShields)
  		_damage *= 2;
  	__original(_damage, _playHitSound);
  }}.applyShieldDamage;
  ```
  (`mod_reforged_core_0.9.1_Ks0c9R8EM/mod_reforged/hooks/load.nut:146-157`,
  real in-repo example). The parameter name **must** be exactly `__original`
  (or `__native`) — `q_object.nut:300-305` checks the literal string.
- **Adding a brand-new function** (no existing function of that name in the
  class or any ancestor): assign with `<-` (newslot), not `=`:
  ```squirrel
  q.addItemType <- function ( _t ) { this.m.ItemType = this.m.ItemType | _t; }
  ```
  (`mod_msu/msu/hooks/items/item.nut:23-26`). This routes through
  `::Hooks.__Q.Q::_newslot` -> `newSlot()`
  (`modern_hooks/q_object.nut:369-372`, `:45-55`), which **requires** the
  value to be a function (`q_object.nut:47-48`) and **warns** (does not
  error) if the key already exists (`q_object.nut:52`) — i.e. `<-` on an
  existing key silently clobbers it with only a warning, so always use `=`
  with `@(__original)`/`@(__native)` to wrap, and `<-` only for genuinely new
  members.
- **The `<-` vs `=` gotcha**: `_set` (i.e. `q.fn = value`) goes through
  `::Hooks.__Q.set`, which enforces the `@(__original)`/`@(__native)`
  parameter-name contract and will `errorAndThrow` if you assign a plain
  function with `=` that doesn't match either shape
  (`q_object.nut:296-307`). `_newslot` (i.e. `q.fn <- value`) goes through
  `newSlot`, which does **not** check for `__original`/`__native` at all — it
  just requires a function value (`q_object.nut:45-55`). Using `<-` to
  "wrap" an existing method will not call the old implementation; it
  silently replaces it (with a warning), breaking anything that relied on
  the original behavior. Conversely using `=` to add a genuinely new field
  will throw because there's nothing in any ancestor to look up
  (`q_object.nut:222-223`, `setSquirrel`'s `errorAndThrow` when
  `findInAncestors` returns null).
- **Data fields**: use `q.m.SomeField <- value` (newslot on the `m` table,
  via `Qm::_newslot` -> `newSlotM`, `q_object.nut:420-423`, `:57-63`), never
  `q.SomeField <- value` directly — a plain (non-function) newslot on `q`
  itself is rejected: "Fields must instead be added to the class's `m`
  table" (`q_object.nut:47-48`).
- **Parameter-count validation**: `setSquirrel` inspects old vs. new
  `getinfos().parameters`/`defparams` and will error (not just warn) if your
  wrapper needs *more required* parameters than the original, or *fewer
  total* parameters than the original — since that would break other
  callers (`q_object.nut:117-196`, `:291`).
- Climbing to a superclass explicitly (legacy `q.<Super>` pattern) is
  explicitly rejected and throws with a message that it's unnecessary under
  Modern Hooks, since single-target hooks already climb ancestors
  automatically to find the function being wrapped
  (`q_object.nut:317-327`, `setSquirrel`'s ancestor walk at `:220-223`).

---

## 4. Queue buckets and load order

Buckets, in execution order (`modern_hooks/queue/enums.nut` i.e.
`modern_hooks/enums.nut:1-11`):

```squirrel
::Hooks.QueueBucket <- {
	First = 0, VeryEarly = 1, Early = 2, Normal = 3,
	Late = 4, VeryLate = 5, Last = 6, AfterHooks = 7, FirstWorldInit = 8
};
```

Runner logic (`modern_hooks/private_globals.nut:233-286`):

- `__runQueue()` groups every mod's queued functions by bucket, sorts each
  bucket by inter-mod load-order constraints (`__sortQueue` /
  `ModHooksQueueGraph`), then executes buckets **in ascending numeric
  order** — except `AfterHooks` and `FirstWorldInit`, which are pulled out
  and stashed for later (`private_globals.nut:258-268`) because "by
  definition that bucket is handled later."
- `First..Last` (0-6) run during normal mod load, before
  `::Hooks.__finalizeHooks()` is called (i.e. before any `hook`/`hookTree`
  bodies are actually applied to the game's class tables — finalize happens
  in `scripts/~~modern_hooks.nut:1-4`, which runs after all mods' queues).
  So a `queue(..., bucket)` function itself runs before hooks are finalized,
  but the *hooks it schedules via `.hook()`/`.hookTree()` calls made inside
  that queue function* get applied at `__finalizeHooks()` time regardless of
  bucket — the bucket only orders **when the registration code executes**,
  not when hook bodies run against instances.
- `AfterHooks` (bucket 7) runs via `::Hooks.__runAfterHooksQueue()`, called
  from `scripts/~~modern_hooks.nut:3` **after** `__finalizeHooks()` — i.e.
  after every mod's `hook`/`hookTree` registrations have been applied to
  every BB class. This is the correct bucket for "code that must run after
  all other mods' hooks."
- `FirstWorldInit` (bucket 8) is stashed separately again
  (`private_globals.nut:264-268`) and is presumably fired at first world
  init by the caller of `__runQueue`/`__runAfterHooksQueue` (the trigger
  point beyond `AfterHooksBucket`/`FirstWorldInitBucket` storage is **NOT
  FOUND IN SOURCES** within the files read — only that these two buckets are
  segregated from the main run and exposed as
  `::Hooks.AfterHooksBucket`/`::Hooks.FirstWorldInitBucket`).

Recommended buckets for your three cases:

- **(a) Defining new Const tables** (e.g. new item/skill Const entries): use
  an early bucket — `First` or `VeryEarly` — before anything else might read
  those tables. Reforged puts its dynamic entity-ID allocation logic
  (`::Reforged.Entities.addEntity`) at plain load time inside its main
  queued function (no special bucket beyond the mod-order queue itself,
  `mod_reforged/hooks/load.nut:160-201`), i.e. `Normal` bucket is
  acceptable if no other mod needs to react to the new Const entries
  first — but if compatibility with other content mods matters, prefer
  `First`/`VeryEarly` and combine with load-order strings (below) to run
  after any mod whose IDs you must not collide with.
- **(b) Hooking vanilla classes**: `Normal` (the default when no bucket is
  passed — `modern_hooks/queue/queued_function.nut:9-12`: `if (_bucket ==
  null) _bucket = ::Hooks.QueueBucket.Normal;`) is correct for ordinary
  `hook`/`hookTree` registration calls, unless you specifically need to run
  before another mod's overwrite of the same function (use `Early`, as
  Reforged does for its `shield.applyShieldDamage` hook specifically "so
  that subsequent hooks on this function are not affected",
  `mod_reforged/hooks/load.nut:146-158`).
- **(c) Code that must run after ALL other mods' hooks**: `AfterHooks`
  (bucket 7) — this is its documented purpose and is used exactly this way
  by Reforged for its dynamic-perks/perk-group loading
  (`mod_reforged/mod_reforged_AfterHooks/...` referenced from
  `mod_reforged/hooks/load.nut:218-234`,
  `scripts/mods/mod_reforged/perk_groups/*` include list) and by MSU for its
  AI-behavior script map (`mod_msu/scripts/!mods_preload/msu.nut:38-50`).

**Inter-mod load order** is separate from buckets and is expressed per
`queue()` call as an array of `"<other_mod_id"` / `">other_mod_id"` strings
(load-before / load-after), consumed by `QueuedFunction.setLoadOrderData`
(`modern_hooks/queue/queued_function.nut:27-45`):

```squirrel
function queue( ... )   // Mod.queue, modern_hooks/queue/mod.nut:176-186
{
	local bucket;                                    // optional trailing integer = bucket
	if (typeof vargv[vargv.len()-1] == "integer") bucket = vargv.pop();
	local func = vargv.pop();                        // last non-integer arg = function
	local queueOrderInfo = typeof vargv[0] == "array" ? vargv[0] : vargv;
	this.QueuedFunctions.push(::Hooks.QueuedFunction(this, func, queueOrderInfo, bucket));
}
```
Reforged builds this array automatically from its `requiredMods` list
(`mod_reforged/hooks/load.nut:47-52`) so every queued function runs `>` (i.e.
after) every hard requirement.

---

## 5. Soft-dependency detection (no hard require)

Two parallel, officially-supported registries exist — use the one matching
which layer you're checking:

**Hooks-level** (works for any mod that called `::Hooks.register`, including
mods that never touch MSU):
```squirrel
::Hooks.hasMod <- function( _modID ) { return _modID in this.Mods; }   // public_globals.nut:13-16
::Hooks.getMod <- function( _modID ) { return this.Mods[_modID]; }     // public_globals.nut:18-21
```
Real usage, checking for an optional companion mod
(`mod_reforged_core_0.9.1_Ks0c9R8EM/mod_reforged/hooks/load.nut:229-232`):
```squirrel
if (::Hooks.hasMod("mod_dev_console"))
{
	::Const.AI.ParallelizationMode = true;
}
```
and version-gating against vanilla itself (which is registered as mod ID
`"vanilla"`), e.g. (`mod_msu/msu/hooks/entity/tactical/actor.nut:11`):
```squirrel
if (::Hooks.getMod("vanilla").getVersion() <= ::Hooks.SQClass.ModVersion("1.5.0-15"))
```

**MSU-level** (only for mods that also registered via `::MSU.Class.Mod`):
```squirrel
::MSU.getMod <- function( _modID ) { return ::MSU.System.Registry.getMod(_modID); }
::MSU.hasMod <- function( _modID ) { return ::MSU.System.Registry.hasMod(_modID); }
```
(`mod_msu/msu/systems/registry/load.nut:14-22`), backed by
`RegistrySystem.hasMod`/`getMod`
(`mod_msu/msu/systems/registry/registry_system.nut:113-126`). Real usage,
soft-checking whether another mod is present before touching its data
(`mod_msu/msu/hooks/states/world_state.nut:225-234`):
```squirrel
if (::MSU.System.Registry.hasMod(mod.getID())) { ... }
```

For AC, the correct pattern to soft-detect Reforged and branch behavior
without hard-requiring it:
```squirrel
if (::Hooks.hasMod("mod_reforged"))
{
	local reforgedVersion = ::Hooks.getMod("mod_reforged").getVersion();
	if (reforgedVersion >= ::Hooks.SQClass.ModVersion("0.9.0")) { /* adapt */ }
}
```
Both `::Hooks.getMod(...).getVersion()` returns either a
`::Hooks.SQClass.ModVersion` instance (SemVer mods) or a raw float (legacy
`Adam's Hooks`-style mods, `modern_hooks/queue/mod.nut:13-16`) — comparisons
between the two are handled internally by `ModVersion._cmp`
(`modern_hooks/queue/mod_version.nut:65-127`), so `>=`/`<` work directly on
`getVersion()` results as long as at least one side is the `ModVersion`
class (mixed float/float or float/instance comparisons are also handled via
`CompatibilityData.validateModVersion`,
`modern_hooks/queue/compatibility_data.nut:109-116` — but that helper is
internal to compatibility checking, not a general-purpose comparator you'd
call directly).

---

## 6. MSU settings: slider + checkbox, minimal working example

Page/element API (`mod_msu/msu/systems/mod_settings/settings_page.nut:42-65`):
```squirrel
function addBooleanSetting( _id, _value, _name = null, _description = null )
function addSliderSetting( _id, _value, _values, _labels = null, _name = null, _description = null )
```

Minimal working example, adapted from MSU's own settings registration
(`mod_msu/scripts/mods/msu/settings_screen.nut:1-26`) plus the slider
constructor's own contract
(`mod_msu/msu/systems/mod_settings/elements/slider_setting.nut:1-23`):

```squirrel
// Registration must happen after your ::MSU.Class.Mod(...) exists (see §1).
local page = ::AC.Mod.ModSettings.addPage("General");

// Checkbox
local enableFeature = page.addBooleanSetting("EnableFeature", true, "Enable Feature");
enableFeature.setDescription("Turn the feature on or off.");
enableFeature.addCallback(function(_value) {
	::logInfo("EnableFeature set to " + _value);
});

// Slider (values must contain the initial value; labels optional, defaults to values)
local intensity = page.addSliderSetting("Intensity", 2, [0, 1, 2, 3, 4], null, "Intensity");
intensity.setDescription("How strong the effect is.");
intensity.addCallback(function(_value) {
	::logInfo("Intensity set to " + _value);
});
```

Reading values at runtime, anywhere in your mod:
```squirrel
local isEnabled = ::getModSetting("mod_ac", "EnableFeature").getValue();
local intensity = ::getModSetting("mod_ac", "Intensity").getValue();
```
`getValue()` is defined on `AbstractSetting`
(`mod_msu/msu/systems/mod_settings/abstract_setting.nut:108-111`):
```squirrel
function getValue() { return this.Value; }
```
`SliderSetting extends RangeSetting extends AbstractSetting`
(`mod_msu/msu/systems/mod_settings/elements/slider_setting.nut:1-23`), and
`BooleanSetting extends AbstractSetting` and coerces to bool
(`mod_msu/msu/systems/mod_settings/elements/boolean_setting.nut:1-21`):
```squirrel
::MSU.Class.BooleanSetting <- class extends ::MSU.Class.AbstractSetting
{
	constructor( _id, _value, _name = null, _description = null )
	{
		::MSU.requireBool(_value);
		base.constructor(_id, _value, _name, _description);
	}
	function toggle() { this.set(!this.Value); }
}
```
Persistence across saves is automatic by default
(`Persistence = true` in `AbstractSetting` constructor,
`abstract_setting.nut:19`) — call `setPersistence(false)` if the setting
should NOT be saved (as MSU itself does for pure display-toggle settings,
`mod_msu/msu/msu_mod/msu_mod_modsettings.nut:4-5`).

---

## 7. New Const / EntityType entries and new item/skill IDs

**NOT FOUND IN SOURCES**: neither MSU nor Modern Hooks expose a
mod-author-facing, officially sanctioned helper for allocating new
`::Const.EntityType` IDs without collision. The only concrete implementation
found is Reforged's own ad-hoc helper, which is **not** part of the MSU/Hooks
public API surface — it's Reforged-specific:

```squirrel
local highestID = 0;
foreach (key, value in ::Const.EntityType)
{
	if (typeof value == "integer" && value > highestID) highestID = value;
}

::Reforged.Entities <- {
	function addEntity( _entityTypeKey, _name, _namePlural, _orientationIcon, _defaultFaction, _troopDef, _actorDef, _atID = null )
	{
		local id;
		if (_atID != null) { /* shifts every existing ID >= _atID up by one, then increments highestID */ }
		else { id = ++highestID; }
		::Const.EntityType[_entityTypeKey] <- id;
		::Const.Strings.EntityName.insert(id, _name);
		::Const.Strings.EntityNamePlural.insert(id, _namePlural);
		::Const.EntityIcon.insert(id, _orientationIcon);
		...
	}
}
```
(`mod_reforged_core_0.9.1_Ks0c9R8EM/mod_reforged/hooks/config/!entities.nut:1-49`).
This is inherently fragile in a multi-mod environment: it appends at
`highestID + 1` unless `_atID` is given, meaning **collision safety depends
entirely on load order and on no other mod doing the same "take the current
max and +1" trick concurrently**. There is no registry, no ID space
reservation, and no compatibility check comparable to `require`/`conflictWith`
for entity IDs specifically.

Practical implication for your port: adding new `::Const.EntityType` entries
(or new item/skill script-based IDs, which in BB are generally addressed by
script path/string rather than integer ID except where `EntityType` integers
are involved) should be done as late as reasonably possible (a late bucket,
after `Normal`, ideally in the same style as Reforged: compute
`highestID` immediately before allocating, inside a queued function that
plausibly runs after other content mods have already registered their own
entities) and, if colliding with Reforged specifically matters, checked with
`::Hooks.hasMod("mod_reforged")` (§5) since Reforged pushes many entity types
of its own (`RF_Banshee`, etc., referenced at
`mod_reforged_core_0.9.1_Ks0c9R8EM/mod_reforged/config/items.nut:6`). If your
mod does not need new integer `EntityType`s (i.e. only adds new item/skill
*scripts*, which are identified by file path and string ID, not integer),
this whole concern does not apply — most new items/skills in BB modding are
just new script files under `scripts/items/...` / `scripts/skills/...` with
unique string IDs, which don't collide the way integer Const table entries
can.

---

## 8. Serialization of custom fields on items/actors

MSU's serialization system is **flag-based** (built on the vanilla
`::World.Flags` container, chunked to survive the 65535-byte save-flag
limit) and mod-namespaced. Core entry points, on `Mod.Serialization`
(`mod_msu/msu/systems/serialization/serialization_mod_addon.nut:1-28`):

```squirrel
function isSavedVersionAtLeast( _version, _metaData )
function flagSerialize( _id, _object, _flags = null )
function flagDeserialize( _id, _defaultValue, _object = null, _flags = null )
```
delegating to the system (`mod_msu/msu/systems/serialization/serialization_system.nut:1-80`):
```squirrel
function flagSerialize( _mod, _id, _object, _flags = null )
{
	if (::MSU.isBBObject(_object))
		throw ::MSU.Exception.InvalidType("_object"); // use <object>.onSerialize(emulator) instead for BB engine objects
	...
	local outEmulator = ::MSU.Class.FlagSerializationEmulator(_mod, _id, _flags);
	::MSU.Serialization.serialize(_object, outEmulator);
	outEmulator.storeDataInFlagContainer();
}

function flagDeserialize( _mod, _id, _defaultValue, _object = null, _flags = null )
{
	...
	local inEmulator = ::MSU.Class.FlagDeserializationEmulator(_mod, _id, _flags);
	if (!inEmulator.loadDataFromFlagContainer()) return _defaultValue;
	if (!::MSU.Mod.Serialization.isSavedVersionAtLeast("1.3.0-a", inEmulator.getMetaData()))
		return _object == null ? ::MSU.Utils.deserialize(inEmulator) : ::MSU.Utils.deserializeInto(_object, inEmulator); // legacy path
	return _object == null ? ::MSU.Serialization.deserialize(inEmulator) : ::MSU.Serialization.deserializeInto(_object, inEmulator);
}
```

For BB engine objects (items, actors) specifically, the explicit error above
tells you the sanctioned path is the object's own `onSerialize`/`onDeserialize`
hooks combined with `<Mod>.Serialization.getSerializationEmulator()` /
`getDeserializationEmulator()` — i.e. hook the item/actor class's
`onSerialize`/`onDeserialize` functions (standard `q.onSerialize =
@(__original) function(_out) { __original(_out); /* write your custom field
into _out via the emulator */ }`) rather than calling `flagSerialize`
directly on a BB instance.

**AbstractSetting** shows the canonical serialize/deserialize pair pattern
used throughout MSU, including the version-gated legacy fallback that avoids
corrupting old saves (`mod_msu/msu/systems/mod_settings/abstract_setting.nut:184-224`):
```squirrel
function flagSerialize( _out )
{
	this.getMod().Serialization.flagSerialize(this.getSerDeFlag(), this.__getSerializationTable());
}

function flagDeserialize( _in )
{
	if (::MSU.Mod.Serialization.isSavedVersionAtLeast("1.2.0-rc.1", _in.getMetaData()))
	{
		this.__setFromSerializationTable(this.getMod().Serialization.flagDeserialize(this.getSerDeFlag(), this.__getSerializationTable()));
	}
	else if (::MSU.Mod.Serialization.isSavedVersionAtLeast("0.0.1", _in.getMetaData()))
	{
		// manual per-property flag reads/removals for pre-1.2.0-rc.1 saves
		...
	}
	else
	{
		// vanilla save with no MSU data at all — placeholder, no-op
	}
}
```

**Pitfalls that corrupt saves, directly evidenced in sources**:
- Calling `flagSerialize`/`flagDeserialize` on a live BB engine object
  (`::MSU.isBBObject(_object) == true`) is explicitly rejected with a thrown
  exception rather than silently corrupting data — but only because MSU
  checks for it; if you bypass MSU and hand-roll flag storage for a BB
  object without going through `onSerialize`/`onDeserialize`, nothing else
  will catch the mistake (`serialization_system.nut:24-28`, `:40-44`).
- **Version gating is mandatory**: every deserialize path in MSU checks
  `isSavedVersionAtLeast` before assuming the new flag format exists, and
  falls back to raw `::World.Flags.get(...)`/`.remove(...)` reads keyed by
  `"ModSetting." + modID + "." + settingID + "." + property"` for saves from
  before the structured format existed (`abstract_setting.nut:189-223`). If
  your port skips this and assumes your data format has always existed,
  loading an old save (or a save from before you added a new custom field)
  will read garbage/`null` instead of a sane default.
- **65535-byte flag-value limit**: `stdlib.Flags.pack`/`unpack` chunk any
  packed payload larger than 64000 bytes into multiple flag keys
  (`stdlib/stdlib/flags.nut:1-17`, comment: "Anything over 65535 will break
  a savegame"). If you serialize a large custom structure via raw
  `::World.Flags.set` without chunking, you risk exceeding this limit and
  corrupting the save. Use MSU's serialization emulators (which are built
  for this) rather than hand-rolling `::World.Flags` calls for anything
  beyond a single primitive.
- Removing a mod's flags is a manual concern: `ModSettingsSystem.setSettingFromPersistence`
  explicitly checks `!this.Panels.contains(_modID)` /
  `!this.getPanel(_modID).hasSetting(_settingID)` and warns-and-skips rather
  than crashing when a previously-saved mod/setting no longer exists
  (`mod_msu/msu/systems/mod_settings/mod_settings_system.nut:117-132`) — your
  own custom-field deserialization should follow the same defensive pattern
  (tolerate missing keys) since uninstalling/downgrading AC between saves is
  a realistic scenario.

---

## 9. Reforged-specific integration surface

**Global surface**: Reforged exposes a single global table `::Reforged`
(`mod_reforged_core_0.9.1_Ks0c9R8EM/mod_reforged/hooks/load.nut:1-22`):
```squirrel
::Reforged <- {
	Version = "0.9.2", ID = "mod_reforged", Name = "Reforged Mod",
	ItemTable = {},
	Spawns = { Units = {}, UnitBlocks = {}, Parties = {} },
	DebugFlag = { AI = "AI", onAnySkillExecutedFully = "...", AIAgentFixes = "..." },
	QueueBucket = { Late = [], VeryLate = [], AfterHooks = [], FirstWorldInit = [] }
};
::Reforged.HooksMod <- ::Hooks.register(...);   // the Hooks Mod object
::Reforged.Mod <- ::MSU.Class.Mod(...);          // the MSU Mod object, set later in the queue
```
`::Reforged.HooksMod` and `::Reforged.Mod` are the two handles other mods
would use to soft-detect Reforged and inspect its version (§5). Its own
`QueueBucket.{Late,VeryLate,AfterHooks,FirstWorldInit}` arrays are an
internal convenience for Reforged's own sub-files to register deferred work
that Reforged itself drains at the matching Modern-Hooks bucket
(`mod_reforged/hooks/load.nut:204-244`) — these are not a public API for
other mods to push into; they are Reforged's private staging arrays (no
guard against external mods pushing into them was found, but doing so is
unsupported and undocumented — treat as internal).

**Documented compatibility hooks for other mods**: Reforged does not appear
to expose a formal "extension point" API (no `Reforged.registerX`/
`Reforged.addCompanionMod`-style function was found in any read file).
Compatibility is handled unilaterally, via:
1. `::Reforged.HooksMod.conflictWith([...])` — an explicit denylist of known
   incompatible mods by ID, with human-readable reasons
   (`mod_reforged/mod_conflicts.nut:1-16`).
2. `::Reforged.checkConflictWithFilename()` — a **filename-scan-based**
   conflict check for mods that don't register with Hooks at all, run once
   at load and then deleted (`mod_reforged/mod_conflicts.nut:19-78`,
   invoked and cleaned up at `mod_reforged/hooks/load.nut:167-168`). It
   scans `data/` for known-incompatible filenames and calls
   `::Hooks.errorAndQuit(reason)` if found — this means **Reforged will hard
   -abort game load** if it detects certain named files, not merely warn.
   None of the AC-relevant paths (`items/accessory/*`,
   `skills/backgrounds/houndmaster_background`) appear in this denylist, so
   AC is not automatically blocked by filename, but you should still check
   your own `mod_ac` filenames don't collide with any entry there.
3. `::Hooks.hasMod("mod_dev_console")`-style soft checks for optional
   companion mods (`mod_reforged/hooks/load.nut:229-232`).

**What Reforged does to `items/accessory/*`**
(`mod_reforged_core_0.9.1_Ks0c9R8EM/mod_reforged/hooks/items/accessory/accessory.nut:1-34`):
```squirrel
::Reforged.HooksMod.hook("scripts/items/accessory/accessory", function(q) {
	q.getTooltip = @(__original) { function getTooltip() { ... } }.getTooltip;
	q.onUpdateProperties = @() { function onUpdateProperties( _properties )
	{
		if (this.getCurrentSlotType() != ::Const.ItemSlot.Bag)
		{
			_properties.Stamina += this.getStaminaModifier();
		}
	}}.onUpdateProperties;
});
```
This is a `hook` (single class, not `hookTree`) on the shared
`accessory` base class itself. It **overwrites** `onUpdateProperties`
(vanilla's is empty, per the comment at line 24) and wraps `getTooltip`. Any
AC hook that also wraps `getTooltip` or `onUpdateProperties` on this same
class must chain through `@(__original)` (§3) rather than assigning with
`<-`, or it will silently discard Reforged's stamina-modifier logic. There
are also per-accessory-item hooks for specific accessories
(`iron_will_potion_item.nut`, `wardog_item.nut`, `warhound_item.nut`,
`wolf_item.nut` in the same directory) — if AC's original mod hooked any of
these specific vanilla accessory items, check each individually for the same
wrap-vs-overwrite risk.

**What Reforged does to `skills/backgrounds/houndmaster_background`**
(`mod_reforged_core_0.9.1_Ks0c9R8EM/mod_reforged/hooks/skills/backgrounds/houndmaster_background.nut:1-23`):
```squirrel
::Reforged.HooksMod.hook("scripts/skills/backgrounds/houndmaster_background", function(q) {
	q.createPerkTreeBlueprint = @() { function createPerkTreeBlueprint()
	{
		return ::new(::DynamicPerks.Class.PerkTree).init({ DynamicMap = { ... } });
	}}.createPerkTreeBlueprint;

	q.getPerkGroupMultiplier = @() { function getPerkGroupMultiplier( _groupID, _perkTree )
	{
		switch (_groupID) { case "pg.special.rf_leadership": return 2; }
	}}.getPerkGroupMultiplier;
});
```
Both `createPerkTreeBlueprint` and `getPerkGroupMultiplier` are
**overwritten** (assigned with `@()` — zero-arg lambda, meaning "replace
entirely," per the `set()` dispatch table in §3: a 1-param lambda with no
`__original`/`__native` second param routes to `setSquirrel` but since the
returned function ignores `oldFunction`, this is a full replacement, not a
chain). If AC's mod defines its own perk tree or multiplier logic for the
Houndmaster background, it **must** wrap through `@(__original)` referencing
Reforged's replacement (assuming AC hooks after Reforged in load order) or
it will collide — whichever mod's hook runs last on this class wins outright
for these two specific methods unless chained. Given Reforged requires
`mod_dynamic_perks` and builds a `DynamicPerks.Class.PerkTree`
(`houndmaster_background.nut:2-13`), if AC's Houndmaster changes assume the
vanilla static perk tree structure instead, they are very likely
incompatible with Reforged's dynamic perk-group system for this background
specifically and need explicit compatibility handling (e.g. detect
`::Hooks.hasMod("mod_reforged")` and adapt to `DynamicMap`-based perk groups
rather than assuming vanilla's `PerkTreeBlueprint` shape).
