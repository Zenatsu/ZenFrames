# CHANGELOG

## v1.0.8

- Fixed various aura issues displaying properly and not accepting setting changes
- Fixed game stuttering when exiting combat due to frames rebuilding themselves
- Fixed healing absorbs from improperly displaying around combat
- Fixed dispel highlight not displaying properly
- Fixed cast bar textures and icons not displaying properly
- Fixed a few indicators not displaying properly
- Fixed player tooltip not displaying on mouseover

## V1.0.7

- Fixed the addon breaking after the new patch update
- Fixed buffs, debuffs, and custom auras not showing up
- Fixed dispel highlighting (the colored border for dispellable debuffs) not working
- Fixed incoming heal, absorb, and heal absorb bars not showing or updating
- Fixed cast bar not showing spell names, target names, or the interrupt shield icon
- Fixed the role icon (tank/healer/dps) not showing on party and raid frames
- Fixed the ready check icon texture option not applying

## V1.0.6

- Changed target and mouseover indicators style names to better represent what they do
- Added Frame border options: Border Color, Border Thickness, Border Opacity (0 thickness to hide, or set opacity to 0%)

## V1.0.5

- Import Migration fixes (some prefixes persisted casuing potiental refrence issues)
- Replaced the parent editable text box to be a drop down seleciton instead
- Added the addon into the addon compartment afixed to the minimap
- Fixed issue where frames can be stuck behind another frame and not be selected. Clicking the frame agian if there is a fame overlapping will select the next frame in line.
- Added options to the movers UI that changes the preview frames displaying colored boxes and aura (if enabled). None, Always, or Hybrid (only show when selected)
- Added option to detatch the control panel, it will snap below the movers dialog box and become draggable. Still only appears when you select a frame to manipulate.
- Added Focus, Focus Target, Pet, and Target of Target, colored preview bars.

## V1.0.4

- Fixed reload popup strata to sit on top of the GUI

## V1.0.3

- Removed the Cooldown Manager anchor option
- Party, boss, raid, and target frames now show fake preview data while unlocked for moving, even without a real group or target.
- Moved each frame's Layout & Positioning options (size, anchor, growth, spacing, sort, raid groups) out of the Designer and into the mover control panel next to the frame itself.
- Split each Aura tab into separate Buff Config, Layout & Positioning, and Count Settings tabs instead of one long page.
- Fixed the Designer preview darkening after changing any setting.
- Fixed party/boss mover previews losing their fake data or re-randomizing their class color when moved.
- Fixed Threat and Target glow textures rendering incorrectly.
- Clicking empty space while movers are unlocked now deselects the current mover.
- Escape now closes the addon UI instead of always opening the game menu.

## V1.0.2

- Major refactoring and cleanup of core code and the settings menu.
- Fixed party frames' Sort By option sometimes throwing an error.
- Added a proper profile migration system for smoother updates.
- Removed leftover dead code and unused third-party hooks.

## V1.0.1

- Major refactoring of various bits of code.
- Fixed party frame inheriting frame data upon player leaving party.
- Fixed missing threat indicator options in taret, focus, party, and raid frames.
- Added libGlow and changed widget selection border to be a pixel glow ("Marching ants")
- Fixed Color reset buttons from creating empty containers

## V1.0.0

- Major refactor of the origional UUF addon.
- Modified the import function to handle missing data.
- Saved Var's of old UUFDB should import into ZFDB without friction
- Added Designer feature for nameplates, inspiried by platynator.
  - Old Units nav group merged into Designer.
  - Various indicators turned into widgets that can be moved around
  - widgets can be selected and dragged to reposition, syncing live with your saved profile and real unit frame.
  - The preview is a bounded canvas that rejects and snaps back drops made outside its bounds.
  - selecting a widget shows its settings inline below the preview instead of requiring the Units tab.
  