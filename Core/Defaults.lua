local _, ZF = ...

local Defaults = {
    global = {
        UseGlobalProfile = false,
        GlobalProfile = "Default",
        DisplayLoginMessage = true,
        AuraBlacklist = {},
        AuraBlacklistSeeded = false,
    },
    profile = {
        General = {
            TagUpdateInterval = 0.25,
            MoverPreviewMode = "Always",
            MoverPanelDetached = false,
            Separator = "||",
            ToTSeparator = "»",
            UseCustomAbbreviations = false,
            AuraBlacklistDisabled = {},
            Textures = {
                Foreground = "Better Blizzard",
                Background = "Better Blizzard",
            },
            Range = {
                Enabled = true,
                InRange = 1.0,
                OutOfRange = 0.5,
            },
            CooldownText = {
                Advanced = false,
                Layout = {"CENTER", "CENTER", 0, 0},
                FontSize = 12,
                ScaleByIconSize = false,
                CooldownBreakpoints = {
                    {threshold = 0, displayStyle = "decimalSeconds", step = 0.1, rounding = Enum.NumericRuleFormatRounding.Up, format = "|cffffffff%.1f|r", color = {1, 1, 1, 1}},
                    {threshold = 3, displayStyle = "secondsOnly", step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "|cffffffff%d|r", color = {1, 1, 1, 1}},
                    {threshold = 60, displayStyle = "clock", step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "|cffffffff%d:%02d|r", color = {1, 1, 1, 1}, components = {{div = 60}, {mod = 60}}},
                    {threshold = 120, displayStyle = "minutes", step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "|cffffffff%dm|r", color = {1, 1, 1, 1}, components = {{div = 60}}},
                    {threshold = 3600, displayStyle = "hours", step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "|cffffffff%dh|r", color = {1, 1, 1, 1}, components = {{div = 3600}}},
                },
            },
            Fonts = {
                Font = "Friz Quadrata TT",
                FontFlag = "OUTLINE",
                Shadow = {
                    Enabled = false,
                    Color = {0, 0, 0, 1},
                    XPos = 1,
                    YPos = -1,
                }
            },
            Colors = {
                Reaction = {
                    [1] = {204/255, 64/255, 64/255},            -- Hated
                    [2] = {204/255, 64/255, 64/255},            -- Hostile
                    [3] = {204/255, 128/255, 64/255},           -- Unfriendly
                    [4] = {204/255, 204/255, 64/255},           -- Neutral
                    [5] = {64/255, 204/255, 64/255},            -- Friendly
                    [6] = {64/255, 204/255, 64/255},            -- Honored
                    [7] = {64/255, 204/255, 64/255},            -- Revered
                    [8] = {64/255, 204/255, 64/255},            -- Exalted
                },
                Power = {
                    [0] = {0, 0, 1},                    -- Mana
                    [1] = {1, 0, 0},                    -- Rage
                    [2] = {1, 0.5, 0.25},               -- Focus
                    [3] = {1, 1, 0},                    -- Energy
                    [6] = {0, 0.82, 1},                 -- Runic Power
                    [8] = {0.75, 0.52, 0.9},            -- Lunar Power (Astral Power)
                    [11] = {0, 0.5, 1},                 -- Maelstrom
                    [13] = {0.4, 0, 0.8},               -- Insanity
                    [17] = {0.79, 0.26, 0.99},          -- Fury
                    [18] = {1, 0.61, 0},                -- Pain
                },
                SecondaryPower = {
                    [4] = {1, 0.96, 0.41},              -- Combo Points
                    [5] = {0.5, 0.5, 0.5},              -- Runes
                    [7] = {0.58, 0.51, 0.79},           -- Soul Shards
                    [9] = {0.95, 0.9, 0.6},             -- Holy Power
                    [12] = {0.71, 1, 0.92},             -- Chi
                    [16] = {0.41, 0.8, 0.94},           -- Arcane Charges
                    [19] = {100/255, 173/255, 206/255}, -- Essence
                },
                Dispel = {
                    ["Magic"] = {0.2, 0.6, 1 },
                    ["Curse"] = {0.6, 0, 1 },
                    ["Disease"] = {0.6, 0.4, 0 },
                    ["Poison"] = {0, 0.6, 0 },
                    ["Bleed"] = {0.6, 0, 0.1 }
                },
                Status = {
                    Tapped = {0.6, 0.6, 0.6},
                    Disconnected = {0.6, 0.6, 0.6},
                    DeadBackdrop = {1, 0.25, 0.25},
                },
                Threat = {
                    [0] = {0.69, 0.69, 0.69},
                    [1] = {1, 1, 0.47},
                    [2] = {1, 0.6, 0},
                    [3] = {1, 0, 0},
                }
            }
        },
        Units = ZF.DefaultsUnits,
    },
}

function ZF:GetDefaultDB() return Defaults end
