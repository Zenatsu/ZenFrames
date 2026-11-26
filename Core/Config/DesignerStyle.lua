local _, ZF = ...

ZF.DesignerStyle = {

    -- Sizes and spacing.
    Layout = {
        CanvasHeight  = 210,
        CanvasWidth   = nil,
        TabStripHeight = 60,
        OptionsHeight = 560,
        OptionsWidth  = nil,
        OverlayBleed  = 4,
        OverlayMinHit = 16,
        WindowWidth   = 1100,
        WindowHeight  = 880,
        InfoLabelHeight = 24,
        InfoLabelFontSize = 12,
        AuraBlacklistWindowWidth = 420,
        AuraBlacklistWindowHeight = 530,
        AuraBlacklistRowScrollHeight = 380,
    },

    -- Shared AceGUI SetRelativeWidth percentages, so every row-split reads from one place.
    Widths = {
        Pct100 = 1,
        Pct75  = 0.75,
        Pct70  = 0.7,
        Pct66  = 0.66,
        Pct60  = 0.6,
        Pct50  = 0.5,
        Pct40  = 0.4,
        Pct34  = 0.34,
        Pct33  = 0.33,
        Pct30  = 0.3,
        Pct29  = 0.29,
        Pct25  = 0.25,
        Pct20  = 0.2,
        Pct19  = 0.19,
    },

    Movers = {
        NudgeStep = 1,
        NudgeStepFine = 0.1,
        ControlPanelCoreHeight = 90,
        ControlPanelCoreWidth = 150,
        TabStripWidth = 52,
        TabButtonHeight = 30,
        TabPageWidth = 200,
        TabPagePadding = 6,
        TabGap = 2,
        PanelLayout = "TooltipDefaultDarkLayout",
    },

    -- Shared slider min/max/step triples, so every settings panel tunes from one place.
    Sliders = {
        Position  = {-255, 255, 0.1}, -- element X/Y offsets
        FontSize  = {8, 64, 1},
        Dimension = {1, 3000, 0.1},   -- frame width/height
        Opacity   = {0, 1, 0.01},
        BorderThickness = {1, 10, 1},        -- Mouseover / Target Indicator border thickness
        FrameBorderThickness = {0, 10, 1},   -- Frame settings border thickness
        IconSize = {8, 64, 1},               -- Totem icon size, tag icon size
        Spacing = {0, 100, 1},               -- Totems indicator spacing
        HoldTime = {0, 5, 0.1},              -- Cast bar interrupted/failed hold time
        MaxChars = {1, 64, 1},               -- Spell name text max characters
        BarHeight = {1, 64, 0.1},            -- Alternative power bar height
        PortraitSize = {8, 128, 0.1},        -- Portrait width/height
        AuraSpacing = {-5, 5, 1},            -- Buff/debuff/custom aura spacing
        AuraCount = {1, 24, 1},              -- Aura count / per-row
        BorderScale = {-1, 3, 0.1},          -- Private aura border scale
        PrivateAuraSize = {8, 128, 1},       -- Private aura icon size
        PrivateAuraSpacing = {-20, 100, 1},  -- Private aura spacing
        PrivateAuraCount = {1, 12, 1},       -- Private auras to display
        TagUpdateRate = {1, 10, 0.5},        -- Tag updates per second
        ShadowOffset = {-5, 5, 1},           -- Font shadow X/Y offset
    },

    -- Shared colors
    Palette = {
        Selected     = {1, 0.82, 0, 1},     -- gold: selected widget outline
        Hovered      = {1, 1, 1, 0.7},      -- soft white: hovered widget outline
        Idle         = {1, 1, 1, 0},        -- alpha 0 when no widget selected
        MoverBorder  = {1, 0.82, 0, 1},      -- gold Mover Border
        SelectedText = "|cFFFFD100",        -- gold
        ErrorText    = "|cFFFF4040",        -- red
    },

    -- Outline around the preview canvas
    Canvas = {
        Backdrop = { bgFile = ZF.Media.Solid,
            edgeFile = ZF.Media.Solid, edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0} },
        Fill   = {0, 0, 0, 0},   -- transparent outline only
        Border = {1, 1, 1, 0.4}, -- white at 40%
        Padding = {left=0, right=0, top=0, bottom=0}
    },

    -- Panel drawn behind the widget-options
     OptionsPanel = {
        Backdrop = { bgFile = ZF.Media.Solid,
            edgeFile = ZF.LSM:Fetch("border", "Blizzard Tooltip"),
            edgeSize = 16,
            insets = {left = 5, right = 5, top = 5, bottom = 5} },
        Fill   = {0, 0, 0, 0.35},
        Border = {1, 1, 1, 1},
        Padding = {left=6, right=6, top=0, bottom=6},
    },

    Overlays = {
        Backdrop = { bgFile = ZF.Media.Solid,
            edgeFile = ZF.Media.Solid, edgeSize = 1,
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

        Native = {
        WindowTemplate = "PortraitFrameTemplate",
        BodyTemplate = "CollectionsBackgroundTemplate",
        BodyFallbackTemplate = "InsetFrameTemplate",
        WindowStrata = "DIALOG",
        WindowLevel = 100,
        WindowDefaultWidth = 700,
        WindowDefaultHeight = 500,
        WindowMinWidth = 600,
        WindowMinHeight = 400,
        WindowMaxWidth = 1800,
        WindowMaxHeight = 1200,
        BodyInsets = {left = 4, top = 60, right = 6, bottom = 26},
        ContentPadding = 12,
        StatusInset = 14,
        PopupLevelOffset = 20,
        NavDefaultWidth = 50,
        NavRowHeight = 30,
        NavRowHeights = { 50, 30 },
        NavLevelShift = 5,
        NavRowWidthScales = { 1, 0.75 },
        NavIndent = 22,
        NavLevelIndent = 14,
        CanvasBorderAtlas = "spec-thumbnailborder-on",
        CanvasBorderSlice = 24,
        CanvasBorderOutset = 4,
        NavArrowSize =32,
        NavArrowInset = 16,
        NavArrowCollapsedRotation = 0,
        NavArrowExpandedRotation = math.pi * 3 / 2,
        NavGap = 12,
        NavTopOffset = 20,
        NavButtonStyle = "Delve",
        NavButtonInset = 1,
        NavButtonCap = 0.15,
        NavButtonStyles = {
            None = {},
            Delve = { Normal = "UI-Journeys-Delve-Companion-button", Pressed = "UI-Journeys-Delve-Companion-button-pressed" },
            Centaur = { Normal = "dragonflight-landingpage-renownbutton-centaur", Selected = "dragonflight-landingpage-renownbutton-centaur-hover", Inset = -8 },
        },
        LabelFont = "GameFontNormalSmall",
        ControlFont = "GameFontHighlight",
        GroupTitleFont = "GameFontNormal",
        HeadingFont = "GameFontNormal",
        LabelHeight = 16,
        DividerHeight = 2,
        GroupTitleHeight = 28,
        GroupBottomPadding = 6,
        HeadingHeight = 26,
        CheckBoxHeight = 28,
        CheckBoxSize = 20,
        CheckBoxArtInset = 2,
        InputHeight = 20,
        InputArtSide = 6,
        InputLabelGap = 6,
        EditBoxButtonWidth = 52,
        EditBoxButtonGap = 6,
        SliderBarHeight = 22,
        SliderLabelGap = 4,
        SliderValueWidth = 56,
        SliderValueGap = 12,
        DropdownHeight = 25,
        DropdownLabelGap = 8,
        DropdownArtTop = 7,
        DropdownArtBottom = 9,
        DropdownArtSide = 8,
        DropdownItemHeight = 20,
        DropdownMaxVisibleItems = 15,
        DropdownMaxSummaryItems = 2,
        DropdownSummaryFormat = "%d selected",
        FontPreviewSize = 13,
        StatusbarPreviewAlpha = 0.6,
        StatusbarPreviewPad = 2,
        ColorSwatchHeight = 28,
        SwatchInset = 6,
        SwatchLabelGap = 8,
        DisabledAlpha = 0.5,
        MultiLineLabelGap = 8,
        MultiLineArtInset = 6,
        MultiLineScrollBarSpace = 18,
        MultiLineLineHeight = 14,
        MultiLineButtonGap = 6,
        MultiLineButtonWidth = 90,
        OptionsHeight = 530,
        TabHeight = 32,
        TabRowPitch = 26,
        TabStartX = 6,
        TabSpacing = 2,
        TabPadding = 6,
        TabBoxInset = 10,
        TabBoxBackgroundAlpha = 0.5,
        ScrollBarSpace = 14,
        ScrollBarInset = 2,
        Atlases = {
            NavSelected = "Options_List_Active",
            NavHover = "Options_List_Hover",
            NavArrow = "gearupdate-arrow-bullet-point",
            Divider = "Options_HorizontalDivider",
        },
        Fallback = {
            NavSelected = {1, 0.82, 0, 0.25},
            NavHover = {1, 1, 1, 0.08},
            NavArrow = {1, 0.82, 0, 1},
            Divider = {1, 1, 1, 0.15},
        },
    },
}