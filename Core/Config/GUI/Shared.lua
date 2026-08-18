local _, ZF = ...
local LSM = ZF.LSM
local AG = ZF.AG
local GUIWidgets = ZF.GUIWidgets
local GUIBuilders = ZF.GUIBuilders
local STYLE = ZF.DesignerStyle

ZF.GUIInternal = ZF.GUIInternal or {}
local GUIInternal = ZF.GUIInternal

local lastSelectedUnitTabs = {}

local function GetUnitDB(unit)
	return ZF:GetUnitDB(nil, unit)
end

local function GetDefaultUnitDB(unit)
	return ZF:GetUnitDB(nil, unit, ZF:GetDefaultDB().profile.Units)
end

function ZF:SaveSubTab(unit, tabName, subTabValue)
    if not lastSelectedUnitTabs[unit] then lastSelectedUnitTabs[unit] = {} end
    if not lastSelectedUnitTabs[unit].subTabs then lastSelectedUnitTabs[unit].subTabs = {} end
    lastSelectedUnitTabs[unit].subTabs[tabName] = subTabValue
end

local function GetSavedSubTab(unit, tabName, defaultValue)
    return lastSelectedUnitTabs[unit] and lastSelectedUnitTabs[unit].subTabs and lastSelectedUnitTabs[unit].subTabs[tabName] or defaultValue
end

ZF.DESIGNER_PREVIEW_TOGGLES = { Auras = false, DispelHighlight = false, HealPrediction = false, CastBar = false }

local function CreateDesignerPreviewToggle(containerParent, key, updateCallback)
    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel("Preview")
    Toggle:SetValue(ZF.DESIGNER_PREVIEW_TOGGLES[key])
    Toggle:SetCallback("OnValueChanged", function(_, _, value)
        ZF.DESIGNER_PREVIEW_TOGGLES[key] = value
        updateCallback() end)
    containerParent:AddChild(Toggle)
    return Toggle
end

local function UpdateUnitSettings(unit, updateCallback)
	if unit == "boss" then
		ZF:UpdateBossFrame()
	elseif unit == "party" then
		ZF:UpdateGroupFrame("party")
	elseif unit == "raid" then
		ZF:UpdateGroupFrame("raid")
	elseif unit == "augmentation" then
		ZF:UpdateAugmentationRaidFrames()
	elseif updateCallback then
		updateCallback()
	end

    if ZF.DESIGNER_OPTIONS_CONTAINER and ZF:GetDesignerUnit() == unit then
        ZF:UpdateDesignerPreviewFrame()
        ZF:AnchorDesignerOverlays()
    end
end

local UnitDBToUnitPrettyName = {
    player = "Player",
    target = "Target",
    targettarget = "Target of Target",
    focus = "Focus",
    focustarget = "Focus Target",
    pet = "Pet",
    boss = "Boss",
    party = "Party",
    raid = "Raid",
	augmentation = "Augmentation",
}


local CooldownBreakpointStyles = {
    {
        decimalSeconds = "Decimal Seconds (1.1)",
        seconds = "Seconds (10s)",
        secondsOnly = "Seconds (10)",
        clock = "Clock (1:10)",
        minutes = "Minutes (2m)",
        hours = "Hours (1h)",
        days = "Days (1d)",
    },
    {"decimalSeconds", "seconds", "secondsOnly", "clock", "minutes", "hours", "days"},
}

local CooldownBreakpointSettings = {
    decimalSeconds = {step = 0.1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%.1f"},
    seconds = {step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%ds"},
    secondsOnly = {step = 1, rounding = Enum.NumericRuleFormatRounding.Up, min = 1, format = "%d"},
    clock = {step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%d:%02d"},
    minutes = {step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%dm"},
    hours = {step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%dh"},
    days = {step = 1, rounding = Enum.NumericRuleFormatRounding.Up, format = "%dd"},
}

local AnchorPoints = { { ["TOPLEFT"] = "Top Left", ["TOP"] = "Top", ["TOPRIGHT"] = "Top Right", ["LEFT"] = "Left", ["CENTER"] = "Center", ["RIGHT"] = "Right", ["BOTTOMLEFT"] = "Bottom Left", ["BOTTOM"] = "Bottom", ["BOTTOMRIGHT"] = "Bottom Right" }, { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT", } }
local AuraAnchorParents = {{Frame = "Unit Frame", Health = "Health Bar"}, {"Frame", "Health"}}
local FrameStrataList = {{ ["BACKGROUND"] = "Background", ["LOW"] = "Low", ["MEDIUM"] = "Medium", ["HIGH"] = "High", ["DIALOG"] = "Dialog", ["FULLSCREEN"] = "Fullscreen", ["FULLSCREEN_DIALOG"] = "Fullscreen Dialog", ["TOOLTIP"] = "Tooltip" }, { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }}
local TopBottomList = {{ ["TOP"] = "Top", ["BOTTOM"] = "Bottom" }, { "TOP", "BOTTOM" }}
local Power = {
    [0] = "Mana",
    [1] = "Rage",
    [2] = "Focus",
    [3] = "Energy",
    [4] = "Combo Points",
    [5] = "Runes",
    [6] = "Runic Power",
    [7] = "Soul Shards",
    [8] = "Astral Power",
    [9] = "Holy Power",
    [11] = "Maelstrom",
    [12] = "Chi",
    [13] = "Insanity",
    [17] = "Fury",
    [16] = "Arcange Charges",
    [18] = "Pain",
    [19] = "Essences",
}

local Reaction = {
    [1] = "Hated",
    [2] = "Hostile",
    [3] = "Unfriendly",
    [4] = "Neutral",
    [5] = "Friendly",
    [6] = "Honored",
    [7] = "Revered",
    [8] = "Exalted",
}

local Status = {
    Tapped = "Tapped",
    Disconnected = "Disconnected",
    DeadBackdrop = "Dead Backdrop",
}

local Threat = {
    [0] = "No Threat",
    [1] = "High Threat",
    [2] = "Insecure Tanking",
    [3] = "Secure Tanking",
}

local StatusTextures = {
    Combat = { ["DEFAULT"] = "|TInterface\\CharacterFrame\\UI-StateIcon:20:20:0:0:64:64:32:64:0:31|t" },
    Resting = { ["DEFAULT"] = "|TInterface\\CharacterFrame\\UI-StateIcon:18:18:0:0:64:64:0:32:0:27|t" },
}
for i = 0, 8 do
    StatusTextures.Combat["COMBAT" .. i] = GUIWidgets.TextureMarkup(ZF.StatusTextures.Combat["COMBAT" .. i], 18)
    StatusTextures.Resting["RESTING" .. i] = GUIWidgets.TextureMarkup(ZF.StatusTextures.Resting["RESTING" .. i], 18)
end

local RoleTextures = {
	["Default"] = "|A:UI-LFG-RoleIcon-Tank-Micro-Raid:18:18|a |A:UI-LFG-RoleIcon-Healer-Micro-Raid:18:18|a |A:UI-LFG-RoleIcon-DPS-Micro-Raid:18:18|a",
}
for _, style in ipairs({"Blizzard", "Color", "White", "ElvUI", "Square"}) do
	local roleSet = ZF.RoleTextures[style]
	RoleTextures[style] = table.concat({
		GUIWidgets.TextureMarkup(roleSet.TANK, 18),
		GUIWidgets.TextureMarkup(roleSet.HEALER, 18),
		GUIWidgets.TextureMarkup(roleSet.DAMAGER, 18),
	}, " ")
end

local function DisableAurasTestMode(unit)
	if unit == "augmentation" then
		ZF:ForEachAugmentationRaidFrame(function(unitFrame, frameUnit)
			if frameUnit then ZF:CreateTestAuras(unitFrame, frameUnit) end
		end, false)
	elseif unit == "boss" then
		ZF:ResetBossFrames()
	elseif unit == "party" or unit == "raid" then
		if unit == "party" then
			for i = 1, ZF.MAX_PARTY_FRAMES do
				if ZF["PARTY" .. i] then ZF:CreateTestAuras(ZF["PARTY" .. i], "party" .. i) end
			end
			if ZF.PARTYPLAYER then ZF:CreateTestAuras(ZF.PARTYPLAYER, "partyplayer") end
		else
			ZF:ForEachRaidFrame(function(raidFrame, frameUnit) if frameUnit then ZF:CreateTestAuras(raidFrame, frameUnit) end end, false)
		end
	else
		ZF:CreateTestAuras(ZF[unit:upper()], unit)
	end
end

local function DisableAllTestModes()
	ZF.MOVERS_UNLOCKED = false
	ZF:ForEachUnitDB(function(_, unit)
		if unit == "party" or unit == "raid" or unit == "augmentation" then
			DisableAurasTestMode(unit)
		elseif ZF[unit:upper()] then
			ZF:CreateTestAuras(ZF[unit:upper()], unit)
			ZF:CreateTestCastBar(ZF[unit:upper()], unit)
		end
	end)
	ZF:ResetBossFrames()
	ZF:ResetPartyFrames()
	ZF:ResetRaidFrames()
    ZF:HideDesignerPreview()
	for _, frameMover in pairs(ZF.MOVERS or {}) do frameMover:Hide() end
end

local function GenerateSupportText(parentFrame)
    local SupportOptions = {
        "This is just a stand-in until I decide to do something with it."
    }
    parentFrame.statustext:SetText(SupportOptions[math.random(1, #SupportOptions)])
end

local DesignerUnitTabs = {
	DesignerPlayer = "player",
	DesignerTarget = "target",
	DesignerTargetTarget = "targettarget",
	DesignerPet = "pet",
	DesignerFocus = "focus",
	DesignerFocusTarget = "focustarget",
    DesignerParty = "party",
    DesignerRaid = "raid",
    DesignerBoss = "boss",
    DesignerAug = "augmentation",
}

local function BuildMainNavigationTree()
    local designerUnitSubmenu = {
        {text = "Player", value = "DesignerPlayer"},
        {text = "Target", value = "DesignerTarget"},
        {text = "Target of Target", value = "DesignerTargetTarget"},
        {text = "Pet", value = "DesignerPet"},
        {text = "Focus", value = "DesignerFocus"},
        {text = "Focus Target", value = "DesignerFocusTarget"},
        {text = "Party", value = "DesignerParty"},
        {text = "Raid", value = "DesignerRaid"},
        {text = "Boss", value = "DesignerBoss"},
    }
    if ZF:IsAugmentationEvoker() then table.insert(designerUnitSubmenu, 2, {text = "Augmentation", value = "DesignerAug"}) end
    return {
		{text = "General", value = "General" },
        {text = "Unit Designer", value = "Designer", children = designerUnitSubmenu},
		{text = "Tags", value = "Tags" },
		{text = "Profiles", value = "Profiles" },
	}
end

GUIInternal.GetUnitDB = GetUnitDB
GUIInternal.GetDefaultUnitDB = GetDefaultUnitDB
GUIInternal.GetSavedSubTab = GetSavedSubTab
GUIInternal.CreateDesignerPreviewToggle = CreateDesignerPreviewToggle
GUIInternal.UpdateUnitSettings = UpdateUnitSettings
GUIInternal.UnitDBToUnitPrettyName = UnitDBToUnitPrettyName
GUIInternal.CooldownBreakpointStyles = CooldownBreakpointStyles
GUIInternal.CooldownBreakpointSettings = CooldownBreakpointSettings
GUIInternal.AnchorPoints = AnchorPoints
GUIInternal.AuraAnchorParents = AuraAnchorParents
GUIInternal.FrameStrataList = FrameStrataList
GUIInternal.TopBottomList = TopBottomList
GUIInternal.Power = Power
GUIInternal.Reaction = Reaction
GUIInternal.Status = Status
GUIInternal.Threat = Threat
GUIInternal.StatusTextures = StatusTextures
GUIInternal.RoleTextures = RoleTextures
GUIInternal.DisableAurasTestMode = DisableAurasTestMode
GUIInternal.DisableAllTestModes = DisableAllTestModes
GUIInternal.GenerateSupportText = GenerateSupportText
GUIInternal.DesignerUnitTabs = DesignerUnitTabs
GUIInternal.BuildMainNavigationTree = BuildMainNavigationTree
GUIInternal.designerLastTab = {}
