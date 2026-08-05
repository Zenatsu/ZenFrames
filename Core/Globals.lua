local addonName, ZF = ...
local oUF = ZF.oUF
ZFG = ZFG or {}
ZF.BOSS_FRAMES = {}
ZF.MAX_BOSS_FRAMES = 5
ZF.PARTY_FRAMES = {}
ZF.MAX_PARTY_FRAMES = 4
ZF.RAID_FRAMES = {}
ZF.RAID_PREVIEW_FRAMES = {}
ZF.AUGMENTATION_RAID_FRAMES = {}
ZF.RAID_HEADERS = {}
ZF.AUGMENTATION_RAID_FRAME_COUNT = 0
ZF.MAX_RAID_FRAMES = 40
ZF.MAX_RAID_GROUPS = 8
ZF.MAX_RAID_FRAMES_PER_GROUP = 5
local CooldownDurationFormatter = C_StringUtil.CreateNumericRuleFormatter()

ZF.LSM = LibStub("LibSharedMedia-3.0")
ZF.LDS = LibStub("LibDualSpec-1.0")
ZF.AG = LibStub("AceGUI-3.0")
ZF.LD = LibStub("LibDispel-1.0")
ZF.LG = LibStub("LibCustomGlow-1.0")
ZF.BACKDROP = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, insets = {left = 0, right = 0, top = 0, bottom = 0} }
ZF.INFOBUTTON = "|TInterface\\AddOns\\ZenFrames\\Media\\Textures\\InfoButton.png:16:16|t "
ZF.ADDON_NAME = C_AddOns.GetAddOnMetadata(addonName, "Title")
ZF.ADDON_VERSION = C_AddOns.GetAddOnMetadata(addonName, "Version")
ZF.ADDON_AUTHOR = C_AddOns.GetAddOnMetadata(addonName, "Author")
ZF.ADDON_LOGO = "|TInterface\\AddOns\\ZenFrames\\Media\\Textures\\ZFLogo:11:12|t"
ZF.PRETTY_ADDON_NAME = ZF.ADDON_LOGO .. " " .. ZF.ADDON_NAME

ZF.LSM:Register("statusbar", "Better Blizzard", "Interface\\AddOns\\ZenFrames\\Media\\Textures\\BetterBlizzard.blp")
ZF.LSM:Register("statusbar", "Dragonflight", "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Dragonflight.tga")
ZF.LSM:Register("statusbar", "Skyline", "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Skyline.tga")
ZF.LSM:Register("statusbar", "Stripes", "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Stripes.png")
ZF.LSM:Register("statusbar", "Thin Stripes", "Interface\\AddOns\\ZenFrames\\Media\\Textures\\ThinStripes.png")

ZF.LSM:Register("font", "Expressway", "Interface\\AddOns\\ZenFrames\\Media\\Fonts\\Expressway.ttf")
ZF.LSM:Register("font", "Avante", "Interface\\AddOns\\ZenFrames\\Media\\Fonts\\Avante.ttf")
ZF.LSM:Register("font", "Avantgarde (Book)", "Interface\\AddOns\\ZenFrames\\Media\\Fonts\\AvantGarde\\Book.ttf")
ZF.LSM:Register("font", "Avantgarde (Book Oblique)", "Interface\\AddOns\\ZenFrames\\Media\\Fonts\\AvantGarde\\BookOblique.ttf")
ZF.LSM:Register("font", "Avantgarde (Demi)", "Interface\\AddOns\\ZenFrames\\Media\\Fonts\\AvantGarde\\Demi.ttf")
ZF.LSM:Register("font", "Avantgarde (Regular)", "Interface\\AddOns\\ZenFrames\\Media\\Fonts\\AvantGarde\\Regular.ttf")

ZF.StatusTextures = {
    Combat = {
        ["COMBAT0"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Combat\\Combat0.tga",
        ["COMBAT1"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Combat\\Combat1.tga",
        ["COMBAT2"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Combat\\Combat2.tga",
        ["COMBAT3"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Combat\\Combat3.tga",
        ["COMBAT4"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Combat\\Combat4.tga",
        ["COMBAT5"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Combat\\Combat5.tga",
        ["COMBAT6"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Combat\\Combat6.tga",
        ["COMBAT7"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Combat\\Combat7.tga",
        ["COMBAT8"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Combat\\Combat8.png",
    },
    Resting = {
        ["RESTING0"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Resting\\Resting0.tga",
        ["RESTING1"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Resting\\Resting1.tga",
        ["RESTING2"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Resting\\Resting2.tga",
        ["RESTING3"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Resting\\Resting3.tga",
        ["RESTING4"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Resting\\Resting4.tga",
        ["RESTING5"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Resting\\Resting5.tga",
        ["RESTING6"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Resting\\Resting6.tga",
        ["RESTING7"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Resting\\Resting7.tga",
        ["RESTING8"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Status\\Resting\\Resting8.png",
    },
}

ZF.ClassificationTextures = {
    ["CLASSIFICATION0"] = {
        ["elite"] = "nameplates-icon-elite-gold",
        ["rare"] = "nameplates-icon-elite-silver",
        ["rareelite"] = "nameplates-icon-elite-silver",
        ["worldboss"] = "nameplates-icon-elite-gold",
    },
    ["CLASSIFICATION1"] = {
        ["elite"] = "VignetteEvent-SuperTracked",
        ["rare"] = "VignetteEvent",
        ["rareelite"] = "VignetteKillElite-SuperTracked",
        ["worldboss"] = "vignettekillboss",
    },
    ["CLASSIFICATION2"] = {
        ["elite"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Classification\\Classic\\Elite.png",
        ["rare"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Classification\\Classic\\Rare.png",
        ["rareelite"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Classification\\Classic\\RareElite.png",
        ["worldboss"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Classification\\Classic\\WorldBoss.png",
    },
    ["CLASSIFICATION3"] = {
        ["elite"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Classification\\Minimalist\\Elite.png",
        ["rare"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Classification\\Minimalist\\Rare.png",
        ["rareelite"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Classification\\Minimalist\\RareElite.png",
        ["worldboss"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Classification\\Minimalist\\WorldBoss.png",
    },
}

ZF.QuestTextures = {
    ["DEFAULT"] = "Interface\\TargetingFrame\\PortraitQuestBadge",
    ["QUEST0"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Quest\\Quest01.png",
    ["QUEST1"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Quest\\Quest02.png",
}

ZF.RoleTextures = {
    ["Blizzard"] = {
        ["TANK"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\Blizzard\\Tank.tga",
        ["HEALER"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\Blizzard\\Healer.tga",
        ["DAMAGER"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\Blizzard\\DPS.tga",
    },
    ["Color"] = {
        ["TANK"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\Color\\Tank.tga",
        ["HEALER"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\Color\\Healer.tga",
        ["DAMAGER"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\Color\\DPS.tga",
    },
    ["White"] = {
        ["TANK"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\White\\Tank.png",
        ["HEALER"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\White\\Healer.png",
        ["DAMAGER"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\White\\DPS.png",
    },
    ["ElvUI"] = {
        ["TANK"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\ElvUI\\Tank.tga",
        ["HEALER"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\ElvUI\\Healer.tga",
        ["DAMAGER"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\ElvUI\\DPS.tga",
    },
	["Square"] = {
		["TANK"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\Square\\Tank.png",
		["HEALER"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\Square\\Healer.png",
		["DAMAGER"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Role\\Square\\DPS.png",
	},
}

ZF.ReadyCheckTextures = {
	["White"] = {
		["READY"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\ReadyCheck\\White\\Ready.png",
		["NOTREADY"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\ReadyCheck\\White\\NotReady.png",
		["WAITING"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\ReadyCheck\\White\\Pending.png",
	},
    ["HiRes"] = {
		["READY"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\ReadyCheck\\HiRes\\Ready.png",
		["NOTREADY"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\ReadyCheck\\HiRes\\NotReady.png",
		["WAITING"] = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\ReadyCheck\\HiRes\\Pending.png",
	},
}

ZF.InterruptSpellIDs = {
	["DEATHKNIGHT"] = {47528},
	["DEMONHUNTER"] = {183752},
	["DRUID"] = {106839, 78675, 38675},
	["EVOKER"] = {351338},
	["HUNTER"] = {187707, 147362},
	["MAGE"] = {2139},
	["MONK"] = {116705},
	["PALADIN"] = {96231, 31935},
	["PRIEST"] = {15487},
	["ROGUE"] = {1766},
	["SHAMAN"] = {57994},
	["WARLOCK"] = {19647, 132409, 89766, 119910, 1276467},
	["WARRIOR"] = {6552},
}

function ZF:PrettyPrint(MSG) print(ZF.ADDON_NAME .. ":|r " .. MSG) end

function ZF:GetInterruptSpellID()
	local playerInterrupt = ZF.InterruptSpellIDs[UnitClassBase("player")]
	if not playerInterrupt then return end
	for i = 1, #playerInterrupt do
		local spellID = playerInterrupt[i]
		if C_SpellBook.IsSpellKnownOrInSpellBook then
			if C_SpellBook.IsSpellKnownOrInSpellBook(spellID) or C_SpellBook.IsSpellKnownOrInSpellBook(spellID, Enum.SpellBookSpellBank.Pet) then return spellID end
		elseif IsSpellKnown and IsSpellKnown(spellID) then
			return spellID
		end
	end
end

function ZF:IsInterruptOnCooldown()
	local spellID = ZF:GetInterruptSpellID()
	if not spellID then return false end
	if C_Spell.GetSpellCooldown then
		local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
		return cooldownInfo and cooldownInfo.isEnabled and cooldownInfo.isActive and not cooldownInfo.isOnGCD or false
	end
	return false
end

function ZF:FetchFrameName(unit)
    local UnitToFrame = {
        ["player"] = "ZF_Player",
        ["target"] = "ZF_Target",
        ["targettarget"] = "ZF_TargetTarget",
        ["focus"] = "ZF_Focus",
        ["focustarget"] = "ZF_FocusTarget",
        ["pet"] = "ZF_Pet",
        ["augmentation"] = "ZF_Augmentation",
        ["boss"] = "ZF_Boss",
        ["party"] = "ZF_Party",
        ["partyplayer"] = "ZF_PartyPlayer",
        ["raid"] = "ZF_Raid",
    }
    if not unit then return end
    if unit:match("^boss(%d+)$") then local unitID = unit:match("^boss(%d+)$") return "ZF_Boss" .. unitID end
    if unit:match("^party(%d+)$") then local unitID = unit:match("^party(%d+)$") return "ZF_Party" .. unitID end
    if unit:match("^raid(%d+)$") then local unitID = unit:match("^raid(%d+)$") return "ZF_Raid" .. unitID end
    if ZF.DESIGNER_PREVIEW_ACTIVE and UnitToFrame[unit] then return UnitToFrame[unit] .. "DesignerPreview" end
    return UnitToFrame[unit]
end

function ZF:ResolveLSM()
    local LSM = ZF.LSM
    local General = ZF.db.profile.General
    ZF.Media = ZF.Media or {}
    ZF.Media.Font = LSM:Fetch("font", General.Fonts.Font) or STANDARD_TEXT_FONT
    ZF.Media.Foreground = LSM:Fetch("statusbar", General.Textures.Foreground) or "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
    ZF.Media.Background = LSM:Fetch("statusbar", General.Textures.Background) or "Interface\\Buttons\\WHITE8X8"
end

function ZF:GetCooldownDurationComponents(displayStyle, minValue)
    if displayStyle == "clock" then
        if minValue >= 86400 then
            return {{div = 86400}, {div = 3600, mod = 24}}
        elseif minValue >= 3600 then
            return {{div = 3600}, {div = 60, mod = 60}}
        end
        return {{div = 60}, {mod = 60}}
    elseif displayStyle == "minutes" then
        return {{div = 60}}
    elseif displayStyle == "hours" then
        return {{div = 3600}}
    elseif displayStyle == "days" then
        return {{div = 86400}}
    end
end

function ZF:ApplyCooldownText(icon, textRegion, unit, unitFrame)
    if not icon then return end
    local CooldownTextDB = ZF.db.profile.General.CooldownText
    for _, breakpoint in ipairs(CooldownTextDB.CooldownBreakpoints) do
        if breakpoint.displayStyle == "secondsOnly" then breakpoint.min = 1 end
    end
    if icon.SetCountdownFormatter then
        CooldownDurationFormatter:SetBreakpoints(CooldownTextDB.CooldownBreakpoints)
        icon:SetCountdownFormatter(CooldownDurationFormatter)
    end
	if CooldownTextDB.Advanced and unit then CooldownTextDB = ZF:GetUnitDB(unitFrame, unit).Auras.AuraDuration end
    if not textRegion then
        C_Timer.After(0.01, function()
            for _, region in ipairs({icon:GetRegions()}) do
                if region:GetObjectType() == "FontString" then
					ZF:ApplyCooldownText(icon, region, unit, unitFrame)
                    return
                end
            end
        end)
        return
    end

    local FontsDB = ZF.db.profile.General.Fonts
    if CooldownTextDB.ScaleByIconSize then
        local iconWidth = icon:GetWidth()
        local scaleFactor = iconWidth > 0 and iconWidth / 36 or 1
        local fontSize = CooldownTextDB.FontSize * scaleFactor
        if fontSize < 1 then fontSize = 12 end
        textRegion:SetFont(ZF.Media.Font, fontSize, FontsDB.FontFlag)
    else
        textRegion:SetFont(ZF.Media.Font, CooldownTextDB.FontSize, FontsDB.FontFlag)
    end
    textRegion:ClearAllPoints()
    textRegion:SetPoint(CooldownTextDB.Layout[1], icon, CooldownTextDB.Layout[2], CooldownTextDB.Layout[3], CooldownTextDB.Layout[4])
    if FontsDB.Shadow.Enabled then
        textRegion:SetShadowColor(FontsDB.Shadow.Color[1], FontsDB.Shadow.Color[2], FontsDB.Shadow.Color[3], FontsDB.Shadow.Color[4])
        textRegion:SetShadowOffset(FontsDB.Shadow.XPos, FontsDB.Shadow.YPos)
    else
        textRegion:SetShadowColor(0, 0, 0, 0)
        textRegion:SetShadowOffset(0, 0)
    end
end

function ZF:SetTestPredictionBar(bar, value, maxValue, enabled)
    if not bar then return end
    if not enabled then bar:Hide() return end
    bar:SetMinMaxValues(0, maxValue)
    bar:SetValue(value)
    bar:Show()
end

local function SetupSlashCommands()
    SLASH_ZF1 = "/zf"
    SLASH_ZF2 = "/ZenFrames"
    SLASH_ZF3 = "/uf"
    SlashCmdList["ZF"] = function() ZF:CreateGUI() end
    if ZF.db.global.DisplayLoginMessage then ZF:PrettyPrint("'|cFF990007/zf|r' for in-game configuration.") end

    -- RL command
    SLASH_ZFRELOAD1 = "/rl"
    SlashCmdList["ZFRELOAD"] = function() C_UI.Reload() end
end

function ZF:LoadCustomColors()
    local General = ZF.db.profile.General

    -- Map power type enums to their string names
    local PowerTypesToString = {
        [Enum.PowerType.Mana or 0] = "MANA",
        [Enum.PowerType.Rage or 1] = "RAGE",
        [Enum.PowerType.Focus or 2] = "FOCUS",
        [Enum.PowerType.Energy or 3] = "ENERGY",
        [Enum.PowerType.ComboPoints or 4] = "COMBO_POINTS",
        [Enum.PowerType.Runes or 5] = "RUNES",
        [Enum.PowerType.RunicPower or 6] = "RUNIC_POWER",
        [Enum.PowerType.SoulShards or 7] = "SOUL_SHARDS",
        [Enum.PowerType.LunarPower or 8] = "LUNAR_POWER",
        [Enum.PowerType.HolyPower or 9] = "HOLY_POWER",
        [Enum.PowerType.Alternate or 10] = "ALTERNATE",
        [Enum.PowerType.Maelstrom or 11] = "MAELSTROM",
        [Enum.PowerType.Chi or 12] = "CHI",
        [Enum.PowerType.Insanity or 13] = "INSANITY",
        [Enum.PowerType.ArcaneCharges or 16] = "ARCANE_CHARGES",
        [Enum.PowerType.Fury or 17] = "FURY",
        [Enum.PowerType.Pain or 18] = "PAIN",
        [Enum.PowerType.Essence or 19] = "ESSENCE",
    }

    for powerType, color in pairs(General.Colors.Power) do
        local powerTypeString = PowerTypesToString[powerType]
        if powerTypeString then
            oUF.colors.power[powerTypeString] = oUF:CreateColor(color[1], color[2], color[3])
            oUF.colors.power[powerType] = oUF.colors.power[powerTypeString]
        end
    end

    for powerType, color in pairs(General.Colors.SecondaryPower) do
        local powerTypeString = PowerTypesToString[powerType]
        if powerTypeString then
            oUF.colors.power[powerTypeString] = oUF:CreateColor(color[1], color[2], color[3])
            oUF.colors.power[powerType] = oUF.colors.power[powerTypeString]
        end
    end

    for reaction, color in pairs(General.Colors.Reaction) do
        oUF.colors.reaction[reaction] = oUF:CreateColor(color[1], color[2], color[3])
    end

    local DefaultStatusColors = ZF:GetDefaultDB().profile.General.Colors.Status
    local StatusColors = General.Colors.Status or DefaultStatusColors
    local tappedColor = StatusColors.Tapped or DefaultStatusColors.Tapped
    local disconnectedColor = StatusColors.Disconnected or DefaultStatusColors.Disconnected
    local deadBackdropColor = StatusColors.DeadBackdrop or DefaultStatusColors.DeadBackdrop
    oUF.colors.tapped = oUF:CreateColor(tappedColor[1], tappedColor[2], tappedColor[3])
    oUF.colors.disconnected = oUF:CreateColor(disconnectedColor[1], disconnectedColor[2], disconnectedColor[3])
    oUF.colors.deadBackdrop = oUF:CreateColor(deadBackdropColor[1], deadBackdropColor[2], deadBackdropColor[3])

    local DefaultThreatColors = ZF:GetDefaultDB().profile.General.Colors.Threat
    local ThreatColors = General.Colors.Threat or DefaultThreatColors
    for threatStatus, defaultColor in pairs(DefaultThreatColors) do
        local color = ThreatColors[threatStatus] or defaultColor
        oUF.colors.threat[threatStatus] = oUF:CreateColor(color[1], color[2], color[3])
    end

    if General.Colors.Dispel then
        local dispelMap = {
            Magic = oUF.Enum.DispelType.Magic,
            Curse = oUF.Enum.DispelType.Curse,
            Disease = oUF.Enum.DispelType.Disease,
            Poison = oUF.Enum.DispelType.Poison,
            Bleed = oUF.Enum.DispelType.Bleed,
        }
        for dispelType, index in pairs(dispelMap) do
            local color = General.Colors.Dispel[dispelType]
            if color then
                oUF.colors.dispel[index] = oUF:CreateColor(color[1], color[2], color[3])
            end
        end
        ZF.dispelColorGeneration = (ZF.dispelColorGeneration or 0) + 1
    end

    for _, obj in next, oUF.objects do
        if obj.UpdateTags then
            obj:UpdateTags()
        end
    end
end

function ZF:Init()
    SetupSlashCommands()
    ZF:ResolveLSM()
    ZF:LoadCustomColors()
    ZF:SetTagUpdateInterval()
end

function ZF:CopyTable(originalTable, destinationTable)
    for key, value in pairs(originalTable) do
        if type(value) == "table" then
            destinationTable[key] = destinationTable[key] or {}
            ZF:CopyTable(value, destinationTable[key])
        else
            destinationTable[key] = value
        end
    end
end

function ZF:SetJustification(anchorFrom)
    if anchorFrom == "TOPLEFT" or anchorFrom == "LEFT" or anchorFrom == "BOTTOMLEFT" then
        return "LEFT"
    elseif anchorFrom == "TOPRIGHT" or anchorFrom == "RIGHT" or anchorFrom == "BOTTOMRIGHT" then
        return "RIGHT"
    else
        return "CENTER"
    end
end

function ZF:GetUnitColor(unit)
    if UnitIsPlayer(unit) or UnitInPartyIsAI(unit) then
        local _, class = UnitClass(unit)
        local classColor = class and RAID_CLASS_COLORS[class]
        if classColor then return classColor.r, classColor.g, classColor.b end
    end
    local reaction = UnitReaction(unit, "player")
    if reaction and ZF.db.profile.General.Colors.Reaction[reaction] then
        local r, g, b = unpack(ZF.db.profile.General.Colors.Reaction[reaction])
        return r, g, b
    end
    return 1, 1, 1
end

function ZF:GetClassColor(unitFrame)
    local _, class = UnitClass(unitFrame.unit)
    local classColor = RAID_CLASS_COLORS[class]
    if classColor then
        return {classColor.r, classColor.g, classColor.b, 1}
    end
end

function ZF:GetNormalizedUnit(unit)
    local normalizedUnit = unit == "vehicle" and "player" or unit == "partyplayer" and "party" or unit:match("^boss%d+$") and "boss" or unit:match("^party%d+$") and "party" or unit:match("^raid%d+$") and "raid" or unit
    return normalizedUnit
end

function ZF:GetUnitDB(unitFrame, unit, units)
	units = units or ZF.db.profile.Units
	local normalizedUnit = unitFrame and unitFrame.isAugmentationRaidFrame and "augmentation" or ZF:GetNormalizedUnit(unit)
	return units[normalizedUnit]
end

function ZF:ForEachUnitDB(callback)
	for unit, unitDB in pairs(ZF.db.profile.Units) do callback(unitDB, unit) end
end

function ZF:IsAugmentationEvoker()
	if UnitClassBase("player") ~= "EVOKER" then return false end
	local specializationIndex = C_SpecializationInfo.GetSpecialization()
	return specializationIndex and C_SpecializationInfo.GetSpecializationInfo(specializationIndex) == 1473 or false
end

function ZF:RequiresAlternativePowerBar()
    local SpecsNeedingAltPower = {
        PRIEST = { 258 },           -- Shadow
        MAGE   = { 62, 63, 64 },        -- Fire, Frost
        PALADIN = { 70 },           -- Ret
        SHAMAN  = { 262, 263 },     -- Ele, Enh
        EVOKER  = { 1467, 1473 },   -- Dev, Aug
        DRUID = { 102, 103, 104 },    -- Balance, Feral, Guardian
    }
    local class = select(2, UnitClass("player"))
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    local specID = GetSpecializationInfo(specIndex)
    local classSpecs = SpecsNeedingAltPower[class]
    if not classSpecs then return false end
    for _, requiredSpec in ipairs(classSpecs) do if specID == requiredSpec then return true end end
    return false
end

ZF.LayoutConfig = {
    TOPLEFT     = { anchor="TOPLEFT",   offsetMultiplier=0   },
    TOP         = { anchor="TOP",       offsetMultiplier=0   },
    TOPRIGHT    = { anchor="TOPRIGHT",  offsetMultiplier=0   },
    BOTTOMLEFT  = { anchor="TOPLEFT",   offsetMultiplier=1   },
    BOTTOM      = { anchor="TOP",       offsetMultiplier=1   },
    BOTTOMRIGHT = { anchor="TOPRIGHT",  offsetMultiplier=1   },
    CENTER      = { anchor="CENTER",    offsetMultiplier=0.5, isCenter=true },
    LEFT        = { anchor="LEFT",      offsetMultiplier=0.5, isCenter=true },
    RIGHT       = { anchor="RIGHT",     offsetMultiplier=0.5, isCenter=true },
}

function ZF:SetTagUpdateInterval()
    oUF.Tags:SetEventUpdateTimer(ZF.TAG_UPDATE_INTERVAL)
end

function ZF:CreatePrompt(title, text, onAccept, onCancel, acceptText, cancelText)
    StaticPopupDialogs["ZF_PROMPT_DIALOG"] = {
        text = text or "",
        button1 = acceptText or ACCEPT,
        button2 = cancelText or CANCEL,
        OnAccept = function(self, data)
            if data and data.onAccept then
                data.onAccept()
            end
        end,
        OnCancel = function(self, data)
            if data and data.onCancel then
                data.onCancel()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        showAlert = true,
    }
    local promptDialog = StaticPopup_Show("ZF_PROMPT_DIALOG", title, text)
    if promptDialog then
        promptDialog.data = { onAccept = onAccept, onCancel = onCancel }
        promptDialog:SetFrameStrata("TOOLTIP")
    end
    return promptDialog
end

function ZFG:UpdateAllTags()
    for _, obj in next, oUF.objects do
        if obj.UpdateTags then
            obj:UpdateTags()
        end
    end
end

-- Thanks Details / Plater for this.
function ZF:CleanTruncateUTF8String(text)
    local DetailsFramework = _G.DF
    if DetailsFramework and DetailsFramework.CleanTruncateUTF8String then
        return DetailsFramework:CleanTruncateUTF8String(text)
    end
    return text
end

function ZF:IsSecretValue(value)
    return issecretvalue and issecretvalue(value)
end

function ZF:GetSecondaryPowerType()
    local class = select(2, UnitClass("player"))
    local spec = C_SpecializationInfo.GetSpecialization()

    if class == "ROGUE" then
        return Enum.PowerType.ComboPoints
    elseif class == "DRUID" then
        local form = GetShapeshiftFormID()
        if form == 1 then return Enum.PowerType.ComboPoints end
    elseif class == "PALADIN" then
        return Enum.PowerType.HolyPower
    elseif class == "WARLOCK" then
        return Enum.PowerType.SoulShards
    elseif class == "MAGE" then
        if spec == 1 then return Enum.PowerType.ArcaneCharges end
    elseif class == "MONK" then
        if spec == 3 then return Enum.PowerType.Chi end
    elseif class == "EVOKER" then
        return Enum.PowerType.Essence
    end

    return nil
end

function ZF:HasActiveSecondaryPowerBar(unitFrame, unit)
	local SecondaryPowerBarDB = ZF:GetUnitDB(unitFrame, unit).SecondaryPowerBar
    return SecondaryPowerBarDB and SecondaryPowerBarDB.Enabled and (unitFrame.Runes or unitFrame.ClassPower)
end

local function NormalizeBarPosition(value, fallback)
    if value == "TOP" or value == "BOTTOM" then
        return value
    end
    return fallback
end

function ZF:GetConfiguredPowerBarPosition(unit, unitFrame)
	local PowerBarDB = ZF:GetUnitDB(unitFrame, unit).PowerBar
    if not PowerBarDB then return "BOTTOM" end
    if PowerBarDB.Position then
        return NormalizeBarPosition(PowerBarDB.Position, "BOTTOM")
    end
    if PowerBarDB.SwapPositionWithSecondary then
        return "TOP"
    end
    return "BOTTOM"
end

function ZF:GetConfiguredSecondaryPowerBarPosition(unit, unitFrame)
	local UnitDB = ZF:GetUnitDB(unitFrame, unit)
    local SecondaryPowerBarDB = UnitDB.SecondaryPowerBar
    if not SecondaryPowerBarDB then return "TOP" end
    if SecondaryPowerBarDB.Position then
        return NormalizeBarPosition(SecondaryPowerBarDB.Position, "TOP")
    end
    if UnitDB.PowerBar and UnitDB.PowerBar.SwapPositionWithSecondary then
        return "BOTTOM"
    end
    return "TOP"
end

function ZF:GetSecondaryPowerBarStackOffset(unitFrame, unit)
    if not ZF:HasActiveSecondaryPowerBar(unitFrame, unit) then return 0 end

	local PowerBarDB = ZF:GetUnitDB(unitFrame, unit).PowerBar
    if not (PowerBarDB and PowerBarDB.Enabled and unitFrame.Power) then
        return 0
    end

	if ZF:GetConfiguredPowerBarPosition(unit, unitFrame) ~= ZF:GetConfiguredSecondaryPowerBarPosition(unit, unitFrame) then
        return 0
    end

    return PowerBarDB.Height + 1
end

function ZF:UpdateHealthBarLayout(unitFrame, unit)
	local PowerBarDB = ZF:GetUnitDB(unitFrame, unit).PowerBar
	local SecondaryPowerBarDB = ZF:GetUnitDB(unitFrame, unit).SecondaryPowerBar

    local topDepth = 0
    local bottomDepth = 0

    local hasPrimaryPower = PowerBarDB and PowerBarDB.Enabled and unitFrame.Power
    local hasSecondaryPower = ZF:HasActiveSecondaryPowerBar(unitFrame, unit)

    if hasPrimaryPower then
		if ZF:GetConfiguredPowerBarPosition(unit, unitFrame) == "TOP" then
            topDepth = topDepth + PowerBarDB.Height + 1
        else
            bottomDepth = bottomDepth + PowerBarDB.Height + 1
        end
    end

    if hasSecondaryPower then
		if ZF:GetConfiguredSecondaryPowerBarPosition(unit, unitFrame) == "TOP" then
            topDepth = topDepth + SecondaryPowerBarDB.Height + 1
        else
            bottomDepth = bottomDepth + SecondaryPowerBarDB.Height + 1
        end
    end

    local topOffset = -1 - topDepth
    local bottomOffset = 1 + bottomDepth

    unitFrame.HealthBackground:ClearAllPoints()
    unitFrame.HealthBackground:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", 1, topOffset)
    unitFrame.HealthBackground:SetPoint("BOTTOMRIGHT", unitFrame.Container, "BOTTOMRIGHT", -1, bottomOffset)

    unitFrame.Health:ClearAllPoints()
    unitFrame.Health:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", 1, topOffset)
    unitFrame.Health:SetPoint("BOTTOMRIGHT", unitFrame.Container, "BOTTOMRIGHT", -1, bottomOffset)
end


ZF.AURA_FILTERS = {
    Buffs = {
        {Key = "RaidPlayerDispellable", Group = "General", Title = "Player Dispellable", Desc = "Show buffs marked as dispellable by the |cFFFFD100player|r."},
        {Key = "Player", Group = "Player (You)", Title = "All", Desc = "Show every buff applied by the |cFFFFD100player|r or their vehicle."},
        {Key = "CrowdControlPlayer", Group = "Player (You)", Title = "Crowd Control", Desc = "Show crowd-control buffs applied by the |cFFFFD100player|r."},
        {Key = "BigDefensivePlayer", Group = "Player (You)", Title = "Big Defensive", Desc = "Show major defensive buffs applied by the |cFFFFD100player|r."},
        {Key = "ExternalDefensivePlayer", Group = "Player (You)", Title = "External Defensive", Desc = "Show external defensive buffs applied by the |cFFFFD100player|r."},
        {Key = "RaidInCombatPlayer", Group = "Player (You)", Title = "Raid in Combat", Desc = "Show |cFFFFD100player|r-cast buffs marked for raid frames while in combat."},
        {Key = "CancelablePlayer", Group = "Player (You)", Title = "Cancelable", Desc = "Show cancelable buffs applied by the player."},
        {Key = "NotCancelablePlayer", Group = "Player (You)", Title = "Not Cancelable", Desc = "Show non-cancelable buffs applied by the player."},
        {Key = "RaidPlayer", Group = "Player (You)", Title = "Raid", Desc = "Show player-cast buffs marked for raid frames."},
        {Key = "CrowdControl", Group = "Others (Not You)", Title = "Crowd Control", Desc = "Show crowd-control buffs applied by |cFFFFD100other|r units."},
        {Key = "BigDefensive", Group = "Others (Not You)", Title = "Big Defensive", Desc = "Show major defensive buffs applied by |cFFFFD100other|r units."},
        {Key = "ExternalDefensive", Group = "Others (Not You)", Title = "External Defensive", Desc = "Show external defensive buffs applied by |cFFFFD100other|r units."},
        {Key = "RaidInCombat", Group = "Others (Not You)", Title = "Raid in Combat", Desc = "Show |cFFFFD100other|r-cast buffs marked for raid frames while in combat."},
        {Key = "Cancelable", Group = "Others (Not You)", Title = "Cancelable", Desc = "Show cancelable buffs applied by |cFFFFD100other|r units."},
        {Key = "NotCancelable", Group = "Others (Not You)", Title = "Not Cancelable", Desc = "Show non-cancelable buffs applied by |cFFFFD100other|r units."},
        {Key = "Raid", Group = "Others (Not You)", Title = "Raid", Desc = "Show |cFFFFD100other|r-cast buffs marked for raid frames."},
    },
    Debuffs = {
        {Key = "Typed", Group = "General", Title = "Typed", Desc = "Show debuffs with a debuff type, such as |cFF3296FFMagic|r, |cFF9600FFCurse|r, |cFF966400Disease|r, |cFF009600Poison|r, or |cFFC80000Bleed|r."},
        {Key = "RaidPlayerDispellable", Group = "General", Title = "Player Dispellable", Desc = "Show debuffs marked as dispellable by the |cFFFFD100player|r."},
        {Key = "Player", Group = "Player (You)", Title = "All", Desc = "Show every debuff applied by the |cFFFFD100player|r or their vehicle."},
        {Key = "CrowdControlPlayer", Group = "Player (You)", Title = "Crowd Control", Desc = "Show crowd-control debuffs applied by the |cFFFFD100player|r."},
        {Key = "BigDefensivePlayer", Group = "Player (You)", Title = "Big Defensive", Desc = "Show major defensive debuffs applied by the |cFFFFD100player|r."},
        {Key = "ExternalDefensivePlayer", Group = "Player (You)", Title = "External Defensive", Desc = "Show external defensive debuffs applied by the |cFFFFD100player|r."},
        {Key = "RaidInCombatPlayer", Group = "Player (You)", Title = "Raid in Combat", Desc = "Show |cFFFFD100player|r-cast debuffs marked for raid frames while in combat."},
        {Key = "CancelablePlayer", Group = "Player (You)", Title = "Cancelable", Desc = "Show cancelable debuffs applied by the |cFFFFD100player|r."},
        {Key = "NotCancelablePlayer", Group = "Player (You)", Title = "Not Cancelable", Desc = "Show non-cancelable debuffs applied by the |cFFFFD100player|r."},
        {Key = "RaidPlayer", Group = "Player (You)", Title = "Raid", Desc = "Show |cFFFFD100player|r-cast debuffs marked for raid frames."},
        {Key = "CrowdControl", Group = "Others (Not You)", Title = "Crowd Control", Desc = "Show crowd-control debuffs applied by |cFFFFD100other|r units."},
        {Key = "BigDefensive", Group = "Others (Not You)", Title = "Big Defensive", Desc = "Show major defensive debuffs applied by |cFFFFD100other|r units."},
        {Key = "ExternalDefensive", Group = "Others (Not You)", Title = "External Defensive", Desc = "Show external defensive debuffs applied by |cFFFFD100other|r units."},
        {Key = "RaidInCombat", Group = "Others (Not You)", Title = "Raid in Combat", Desc = "Show |cFFFFD100other|r-cast debuffs marked for raid frames while in combat."},
        {Key = "Cancelable", Group = "Others (Not You)", Title = "Cancelable", Desc = "Show cancelable debuffs applied by |cFFFFD100other|r units."},
        {Key = "NotCancelable", Group = "Others (Not You)", Title = "Not Cancelable", Desc = "Show non-cancelable debuffs applied by |cFFFFD100other|r units."},
        {Key = "Raid", Group = "Others (Not You)", Title = "Raid", Desc = "Show |cFFFFD100other|r-cast debuffs marked for raid frames."},
    }
}

ZF.AURA_BLACKLIST = {
    -- Rogue Poisons
    [2823] = true,      -- Deadly Poison
    [315584] = true,    -- Instant Poison
    [3408] = true,      -- Crippling Poison
    [381637] = true,    -- Atrophic Poison
    [381664] = true,    -- Amplifying Poison
    [8679] = true,      -- Wound Poison

    -- Shaman Imbuements
    [319773] = true,    -- Windfury Weapon
    [319778] = true,    -- Flametongue Weapon
    [382021] = true,    -- Earthliving Weapon
    [382022] = true,    -- Earthliving Weapon
    [457496] = true,    -- Tidecaller's Guard
    [457481] = true,    -- Tidecaller's Guard
    [462757] = true,    -- Thunderstrike Ward
    [462742] = true,    -- Thunderstrike Ward

    -- Skyriding
    [404464] = true,    -- Flight Style: Skyriding
    [404468] = true,    -- Flight Style: Steady
    [427490] = true,    -- Ride Along
    [447959] = true,    -- Ride Along - Enabled
    [447960] = true,    -- Ride Along - Inactive

    -- Other
    [160455] = true,    -- Hunter Pet Fatigued
    [26013] = true,     -- Deserter
    [264689] = true,    -- Hunter Pet Fatigued
    [377234] = true,    -- Thrill of the Skies
    [390435] = true,    -- Exhaustion
    [433568] = true,    -- Rite of Sanctification
    [433583] = true,    -- Rite of Adjuration
    [57723] = true,     -- Exhaustion
    [57724] = true,     -- Sated
    [71041] = true,     -- Dungeon Deserter
    [80354] = true,     -- Temporal Displacement
    [95809] = true,     -- Hunter Pet Insanity
}

local RefreshProfilesRetryFrame = CreateFrame("Frame")
RefreshProfilesRetryFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	ZF:RefreshProfiles()
end)

function ZF:RefreshProfiles()
	if InCombatLockdown() then
		RefreshProfilesRetryFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	ZF:ResolveLSM()
	ZF:LoadCustomColors()
	ZF:UpdateAllUnitFrames()
	ZF:ForEachUnitDB(function(_, unit) ZF:UpdateUnitTags(unit) end)
end

local function MergeMatchingKeys(source, target)
	for key, sourceValue in pairs(source) do
		local targetValue = target[key]
		if targetValue ~= nil then
			if type(sourceValue) == "table" and type(targetValue) == "table" then
				MergeMatchingKeys(sourceValue, targetValue)
			else
				target[key] = sourceValue
			end
		end
	end
end

-- Overwrites current select unit with target unit's settings. Non-reverseable.
function ZF:CopyUnitSettings(sourceUnit, targetUnit)
	local sourceDB = ZF:GetUnitDB(nil, sourceUnit)
	local targetDB = ZF:GetUnitDB(nil, targetUnit)
	if sourceDB == targetDB then return end

	local preservedX, preservedY = targetDB.Frame.Layout[3], targetDB.Frame.Layout[4]
	MergeMatchingKeys(sourceDB, targetDB)
	targetDB.Frame.Layout[3], targetDB.Frame.Layout[4] = preservedX, preservedY

	if targetUnit == "party" or targetUnit == "raid" then
		ZF:UpdateGroupFrame(targetUnit)
	elseif targetUnit == "boss" then
		ZF:UpdateBossFrame()
	elseif targetUnit == "augmentation" then
		ZF:UpdateAugmentationRaidFrames()
	else
		local liveFrame = ZF[targetUnit:upper()]
		if liveFrame then ZF:UpdateUnitFrame(liveFrame, targetUnit) end
	end
	ZF:UpdateUnitTags(targetUnit)

	if ZF.DESIGNER_OPTIONS_CONTAINER and ZF:GetDesignerUnit() == targetUnit then
		ZF:UpdateDesignerPreviewFrame()
		ZF:AnchorDesignerOverlays()
	end
end
