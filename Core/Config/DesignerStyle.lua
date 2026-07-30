local _, RUF = ...

RUF.DesignerStyle = {

    -- Sizes and spacing.
    Layout = {
        CanvasHeight  = 210,
        CanvasWidth   = nil,
        TabStripHeight = 60,
        TabStripHeightSecondRow = 20,
        OptionsHeight = 280,
        OptionsWidth  = nil,
        OverlayBleed  = 4,
        OverlayMinHit = 16,
        WindowWidth   = 1100,
        WindowHeight  = 600,
    },

    -- Shared slider min/max/step triples, so every settings panel tunes from one place.
    Sliders = {
        Position  = {-255, 255, 0.1}, -- element X/Y offsets
        FontSize  = {8, 64, 1},
        Dimension = {1, 3000, 0.1},   -- frame width/height
        Opacity   = {0, 1, 0.01},
    },

    -- Shared colors
    Palette = {
        Selected     = {1, 0.82, 0, 1},     -- gold: selected widget outline
        Hovered      = {1, 1, 1, 0.7},      -- soft white: hovered widget outline
        Idle         = {1, 1, 1, 0},        -- alpha 0 when no widget selected
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