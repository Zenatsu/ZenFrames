local _, RUF = ...

--[[=============================================================================
---------------------------RUF DESIGNER STYLE SHEET------------------------------
--------------------------------CHEAT SHEET -------------------------------------
COLOR TABLES: {r, g, b, a}, each 0 to 1 (NOT 0-255). e.g {1, 0.82, 0, 1} = gold.
  a = alpha: 0 invisible, 1 solid. Web color? Divide each 0-255 value by 255.
COLOR ESCAPE STRINGS: "|cAARRGGBB" .. text .. "|r" colors text inline.
  AA RR GG BB are hex 00-FF. "|cFFFFD100" = opaque gold. "|r" = end color.
BACKDROPS: one table drives a frame's fill AND border.
  bgFile   = texture path stretched across the middle (the fill)
  edgeFile = texture path for the border strip around the edge
  edgeSize = border thickness in pixels
  tile = true, tileSize = N  -> repeat bgFile instead of stretching it
  insets = {left,right,top,bottom} -> pull the fill inward so a fat border
           does not overlap it (roughly match edgeSize)
  After SetBackdrop(), the frame is tinted with:
    SetBackdropColor(r,g,b,a)       -> tints the FILL  (bgFile)
    SetBackdropBorderColor(r,g,b,a) -> tints the BORDER (edgeFile)
  "Interface\\Buttons\\WHITE8X8" = a plain white pixel. Tint it for flat
  fills and crisp 1px borders -- RUF's house look (see RUF.BACKDROP,
  Core/Globals.lua line 27).
TEXTURE PATHS: double every backslash. Blizzard art works too, e.g.
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12.
  Addon art: "Interface\\AddOns\\RehaltedUnitFrames\\Media\\Textures\\...".
LSM NAMES: fetch a path by friendly name instead of hardcoding:
  RUF.LSM:Fetch("border", "Blizzard Tooltip") -- also: "None",
    "Blizzard Dialog", "Blizzard Dialog Gold", "Blizzard Party",
    "Blizzard Chat Bubble", "Blizzard Achievement Wood"
  RUF.LSM:Fetch("background", "Blizzard Marble") -- also: "Solid",
    "Blizzard Dialog Background" (+" Dark", +" Gold"), "Blizzard Rock",
    "Blizzard Parchment", "Blizzard Tooltip"
  RUF.LSM:Fetch("font", "Expressway") -- also: "Avante", "Avantgarde
    (Book / Book Oblique / Demi / Regular)", "Friz Quadrata TT"
  RUF.LSM:Fetch("statusbar", "Thin Stripes") -- also: "Better Blizzard",
    "Dragonflight", "Skyline", "Stripes", "Blizzard Raid Bar", "Solid"
FONT FLAGS (3rd arg to SetFont): "" = none, "OUTLINE", "THICKOUTLINE",
  "MONOCHROME" -- combine like "OUTLINE, MONOCHROME".
REFRESH RULES: editing THIS FILE always needs /rl (Lua files load once).
  Live /run tweaks: colors/fonts/backdrops -> RUFDebug:RefreshDesignerStyle()
  sizes/offsets -> close and reopen the Designer tab.
=================================================================================]]

RUF.DesignerStyle = {

    -- Sizes and spacing.
    Layout = {
        CanvasHeight  = 210,
        CanvasWidth   = nil,
        TabStripHeight = 32,
        OptionsHeight = 280,
        OptionsWidth  = nil,
        OverlayBleed  = 4,
        OverlayMinHit = 16,
    },

    -- Shared colors
    Palette = {
        Selected     = {1, 0.82, 0, 1},     -- gold: selected widget outline
        Hovered      = {1, 1, 1, 0.7},      -- soft white: hovered widget outline
        Idle         = {1, 1, 1, 0},        -- alpha 0 when no widget selected
        Accent       = {0.5, 0.5, 1, 0.85}, -- RUF periwinkle (scrollbar thumb)
        SelectedText = "|cFFFFD100",        -- gold
        ErrorText    = "|cFFFF4040",        -- red
    },

    -- Outline around the preview canvas
    Canvas = {
        Backdrop = { bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0} },
        Fill   = {0, 0, 0, 0},   -- transparent outline only
        Border = {1, 1, 1, 0.4}, -- white at 40%
        Padding = {left=0, right=0, top=0, bottom=0}
    },

    -- Panel drawn behind the widget-options
     OptionsPanel = {
        Backdrop = { bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = RUF.LSM:Fetch("border", "Blizzard Tooltip"),
            edgeSize = 16,
            insets = {left = 5, right = 5, top = 5, bottom = 5} },
        Fill   = {0, 0, 0, 0.35},
        Border = {1, 1, 1, 1},
        Padding = {left=6, right=6, top=0, bottom=6},
    },

    Overlays = {
        Backdrop = { bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0} },
        Fill = {0, 0, 0, 0}, -- keep transparent so widgets stay readable
        Padding = {left=0, right=0, top=0, bottom=0}
    },

    -- The helper text line under the canvas.
    StatusText = {
        Size = 12,
        Outline = "OUTLINE",
        CanvasBottomInset = 6,    -- px above the canvas bottom edge
        FallbackOffsetY = -12,
        DropMessageSeconds = 1.5, -- how long the red warning lasts
    },

    -- Fake data so the preview bars are not empty or full.
    Preview = {
        SampleHealth = 70,          -- out of 100
        SamplePower  = 45,          -- out of 100
        SampleAbsorb = 20,          -- out of 100
        SampleHealAbsorb = 15,      -- out of 100
        SampleIncomingHeal = 25,    -- out of 100
        FallbackFontSize = 16,      -- overlay size fallback
    },
}