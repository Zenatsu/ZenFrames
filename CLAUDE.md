# ZenFrames — Project Notes

WoW unit-frame addon (Lua/oUF-based). Git repo with `dev` (working) → `main` (release) branches. Deployed locally via NTFS junction to `D:\World of Warcraft\_retail_\Interface\AddOns\ZenFrames`.

## Verification loop
Run from the ZenFrames root specifically — `.luacheckrc` won't be picked up otherwise:
```
luac -p <file>
luacheck <file>
```
Baseline warnings that are pre-existing and not worth chasing: unused `self` arguments, a handful of pre-existing shadowing/trailing-whitespace spots. Only investigate genuinely new warning categories after an edit.

## Code style
- No comments, ever — not even "why" comments, unless something is genuinely non-obvious enough to cost real debugging time later.
- Match existing style exactly per-file (indentation is inconsistent tabs-vs-spaces across the codebase; match what's already in the file you're editing, don't normalize it).
- No unnecessary abstraction — this codebase consistently duplicates near-identical Create/Update blocks rather than factoring out shared helpers; match that.

## Architecture conventions

**Frame-level scheme**: every overlay levels itself as `Container:GetFrameLevel() + N`. Taken so far:
- +1 HealthBackground
- +2 HealthBar / PowerBar
- +3 ContainerBorder (Frame border overlay) / TargetGlow overlay
- +4 Threat overlay
- +5 AlternativePowerBar
- +10 SecondaryPowerBar overlay

New overlays need a free N, or a deliberate match to an existing tier. Note `Container` itself is the fixed baseline everything computes from (+0, conceptually) — raising Container's own level does NOT let it render above these, since they're all defined as "Container's level at their own creation time, plus a positive offset." A border/decoration that needs to render above HealthBar has to be its own separate frame, not drawn directly on Container.

**Create/Update duality**: every indicator/element has a `CreateX` (runs once, builds the frame) and `UpdateX` (runs on every settings change / live GUI edit). A fix applied only to Create silently does nothing until reload — the live-editing GUI path always goes through Update. Always check both when fixing a rendering bug.

**Never pass `ZF.BACKDROP` by reference** when a value (edgeSize, border color) needs to vary per-instance — it's one shared table used by movers, panels, and multiple elements. Build a fresh `{bgFile=..., edgeFile=..., edgeSize=..., insets=...}` table instead.

**WoW backdrop `edgeSize = 0` does not reliably hide a border** — it can render as a solid fill instead of nothing. Clamp to a minimum of 1 and drive actual visibility through `SetBackdropBorderColor`'s alpha channel.

**`CreateEnableToggle`'s `Refresh()` runs a blanket `DeepDisable` pass** over every widget in its container, driven by the toggle's own Enabled state — it silently overwrites any per-widget `SetDisabled()` call made before it runs. Any conditional disabled-state (e.g. "only enabled when style X is selected") must be applied *after* `Refresh()`, not during initial widget construction.

**`UpdateUnitSettings(unit, updateCallback, element)`'s third argument is dead** — the function is declared `function(unit, updateCallback)`, only two params, so `element` is silently dropped everywhere it's passed in `GUI.lua`. Don't assume passing a different string changes behavior; the real dispatch happens inside `updateCallback` itself.

**Lua's `cond and nil or X` always resolves to X**, even when `cond` is true — `cond and nil` collapses to `nil` before `or` ever sees `cond`, since `nil` is falsy. This codebase uses and/or ternaries heavily; use an explicit `if/else` whenever the "true" branch could itself be `nil`/`false`.

## AceDB-3.0 semantics (verified against the bundled source, `Libraries/Ace3/AceDB-3.0/AceDB-3.0.lua` — not assumed)

Defaults for nested tables (anything table-valued that isn't a `"*"`/`"**"` wildcard default) are applied via `copyDefaults()` — an **eager, one-time-per-login fill pass**, not a live per-read fallback. It runs once when a section (`db.profile`, `db.global`) is first touched each session, and for every default key currently *absent* from the saved table, does a direct `rawset` — real, physical data from that point on, indistinguishable from something the user typed themselves.

**Practical implication**: deleting a default-seeded entry by removing the key (`t[k] = nil`) does not stick — that key is "absent" again, and the very next login's fill pass silently re-adds it from the defaults table. To make a deletion permanent, write an explicit `false` (or other real non-nil value) instead of removing the key.

This is also why a bad *default* value that's already reached a user's profile can never be fixed by just correcting `Defaults.lua` going forward — the bad value is real physical data now, not a live fallback. Only an explicit `ZF:MigrateProfile` migration step, overwriting the bad value directly, fixes it for people already affected.

`db.global` is always account-wide, shared regardless of profile — matches its documented AceDB semantics, and is independent of `ZF.db.global.UseGlobalProfile` (which only controls `profile`-section sharing).

## Release flow
`dev` is the working branch; merge into `main` for releases. CurseForge's automatic packaging triggers on a GitHub **Release** (a real tag + published release object) — a plain `git push` to `main` never produces a new CurseForge file on its own.

## Known in-progress / deferred work
- Target indicator style rename ("Glow"→displayed "Border", "Border"→displayed "Outline") is UI-label-only so far — the underlying DB values are deliberately unchanged, since the addon has live users and a real rename needs a `ZF:MigrateProfile` step first. One-line comments mark the mismatch in `GUI.lua` and `TargetGlow.lua` at the relevant spots.
- Aura blacklist "Advanced" feature (user-editable spell-ID blacklist, extending the existing `Blacklist` toggle mechanism in `Elements/Auras.lua`) is planned but not yet built. See conversation history / commit messages for the full design once implemented.
