# CHANGELOG

## v1.1.0hf1

- Fixed a Lua error on Forever from a missing spell-learned event

## v1.1.0

- Added WoW Forever support.
- Fixed the unit frame's tooltip showing at the same time as a buff/debuff tooltip when the aura icons overlap the frame
- Fixed dead totems leaving a black box on the Totems indicator
- Fixed the target frame fading as if out of range while in melee range as a Warrior
- Fixed a possible Lua error in the range fade check during combat

## v1.0.10

- Added Main Tank and Main Assistant Frames. Toggleable through the raid mover frame options.
- Added Border options to additional frames.
- Added a configurable color for the Alternate power type (was stuck at the default)
- Added Secondary Power Bar "Background Color" control
- Fixed the interrupt-cooldown color indicator on cast bars throwing an error against Blizzard's newer cooldown API
- Fixed Augmentation Evoker Designer crashing when opening the Cast Bar/Portrait tabs
- Fixed Classification indicator settings not applying live in the Designer
- Fixed party frames missing-health overlay using the wrong unit reference
- Fixed Dispel Highlight rendering behind the Alternative Power Bar
- Fixed the Private Auras "Anchor Parent" dropdown showing blank on a fresh profile
- Fixed several Power tag issues
- Fixed the "Percentage Health with Sign" tag being missing from the tag picker
- Fixed Aura Count style changes (font/color/hide stacks) not applying live
- Fixed a spec-change profile refresh being dropped entirely if it happened mid-combat instead of applying after
- Fixed the Game Menu button losing its position on accounts without a Macros button (e.g. Trial/Starter Edition)
- Fixed a data-corruption risk when importing a profile into an already-existing profile
- Fixed the Aura Blacklist "Restore Defaults" window corrupting the look of other windows for the rest of the session
- Fixed dead raid members sometimes showing a leftover red health bar instead of an empty one
- Fixed new mid-combat raid joiners not appearing in the roster grid when Main Tank/Main Assist frames are set to exclude themselves from it (still recovers once combat ends, but no longer needed a second event to trigger the recovery)
- Fixed the Player Designer's Cast Bar options spilling out past the bottom of the window
- Fixed clicking the Cast Bar widget in the Designer not selecting a sub-tab

## v1.0.9hf1

- Fixed "Restore to Defaults" pop-up confirm window frame layer
- Removed redundant "okay" button when adding a spell ID
- Added toggle for the Game Menu button
- Changed Advanced button behavor: If blacklist is not toggled, the button is disabled

## v1.0.9

- Major restructoring of the addon, nothing on the UI or UX side should be affected (profiles should be intact)
- Added an Advanced blacklist feature
  - You can add your own spell ID to blacklist a spell of your choice
  - You can remove any spell ID in the blacklist, including the default offered ID's
  - You can restore the list back to the default offered ID's

## v1.0.8hf1

- Fixed buff container being hidden behind health bars (affected multiple different frames)
- Fixed Target Designer Target Frame preview. (This one is on me, I was too focused on fixing auras that I didn't check in other places for more broke things)

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
  