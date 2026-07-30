## V1.0.1
- Major refactoring of various bits of code.
- Fixed party frame inheriting frame data upon player leaving party.
- Fixed missing threat indicator options in taret, focus, party, and raid frames.
- Added libGlow and changed widget selection border to be a pixel glow ("Marching ants")
- Fixed Color reset buttons from creating empty containers
## V1.0.0
- Major refactor of the origional UUF addon.
- Modified the import function to handle missing data.
- Saved Var's of old UUFDB should import into RUFDB without friction
- Added Designer feature for nameplates, inspiried by platynator.
  - Old Units nav group merged into Designer.
  - Various indicators turned into widgets that can be moved around
  - widgets can be selected and dragged to reposition, syncing live with your saved profile and real unit frame.
  - The preview is a bounded canvas that rejects and snaps back drops made outside its bounds.
  - selecting a widget shows its settings inline below the preview instead of requiring the Units tab.