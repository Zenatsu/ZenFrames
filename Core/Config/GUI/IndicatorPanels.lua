local _, ZF = ...
local AG = ZF.AG
local GUIWidgets = ZF.GUIWidgets
local GUIBuilders = ZF.GUIBuilders
local STYLE = ZF.DesignerStyle
local GUIInternal = ZF.GUIInternal
local GetUnitDB = GUIInternal.GetUnitDB
local GetDefaultUnitDB = GUIInternal.GetDefaultUnitDB
local GetSavedSubTab = GUIInternal.GetSavedSubTab
local UpdateUnitSettings = GUIInternal.UpdateUnitSettings
local StatusTextures = GUIInternal.StatusTextures
local RoleTextures = GUIInternal.RoleTextures

local CLASSIFICATION_ICON_ORDER = {"elite", "rare", "rareelite", "worldboss"}
local CLASSIFICATION_ATLAS_STYLES = { CLASSIFICATION0 = true, CLASSIFICATION1 = true }

local function BuildClassificationMarkup(classKey)
	local classSet = ZF.ClassificationTextures[classKey]
	local parts = {}
	for _, iconKey in ipairs(CLASSIFICATION_ICON_ORDER) do
		local value = classSet[iconKey]
		parts[#parts + 1] = CLASSIFICATION_ATLAS_STYLES[classKey] and GUIWidgets.AtlasMarkup(value, 20) or GUIWidgets.TextureMarkup(value, 20)
	end
	return table.concat(parts, " ")
end

local function BuildReadyCheckMarkup(style)
	local set = ZF.ReadyCheckTextures[style]
	return table.concat({
		GUIWidgets.TextureMarkup(set.READY, 18),
		GUIWidgets.TextureMarkup(set.NOTREADY, 18),
		GUIWidgets.TextureMarkup(set.WAITING, 18),
	}, " ")
end

local SIMPLE_INDICATOR_PANELS = {
	RaidTargetMarker = {
		dbKey = "RaidTargetMarker",
		panelTitle = "Raid Target Marker Settings",
		toggleLabel = "Enable " .. STYLE.Palette.SelectedText .. "Raid Target Marker|r Indicator",
	},
	LeaderAssistant = {
		dbKey = "LeaderAssistant",
		panelTitle = "Leader & Assistant Settings",
		toggleLabel = "Enable " .. STYLE.Palette.SelectedText .. "Leader|r & " .. STYLE.Palette.SelectedText .. "Assistant|r Indicator",
	},
	PvP = {
		dbKey = "PvP",
		panelTitle = "PvP Indicator Settings",
		toggleLabel = "Enable " .. STYLE.Palette.SelectedText .. "PvP|r Indicator",
	},
	Resurrect = {
		dbKey = "Resurrect",
		panelTitle = "Resurrect Indicator Settings",
		toggleLabel = "Enable " .. STYLE.Palette.SelectedText .. "Resurrect|r Indicator",
	},
	Summon = {
		dbKey = "Summon",
		panelTitle = "Summon Indicator Settings",
		toggleLabel = "Enable " .. STYLE.Palette.SelectedText .. "Summon|r Indicator",
		needsSeed = true,
	},
	Phase = {
		dbKey = "Phase",
		panelTitle = "Phase Indicator Settings",
		toggleLabel = "Enable " .. STYLE.Palette.SelectedText .. "Phase|r Indicator",
		needsSeed = true,
	},
	ReadyCheck = {
		dbKey = "ReadyCheck",
		panelTitle = "Ready Check Indicator Settings",
		toggleLabel = "Enable " .. STYLE.Palette.SelectedText .. "Ready Check|r Indicator",
		textureLabel = "Ready Check Texture",
		textureDefault = "Default",
		persistTextureDefault = true,
		textureOrder = {"Default", "White", "HiRes"},
		textureOptions = {
			["Default"] = "|A:UI-LFG-ReadyMark-Raid:18:18|a |A:UI-LFG-DeclineMark-Raid:18:18|a |A:UI-LFG-PendingMark-Raid:18:18|a",
			["White"] = BuildReadyCheckMarkup("White"),
			["HiRes"] = BuildReadyCheckMarkup("HiRes"),
		},
	},
	Quest = {
		dbKey = "Quest",
		getDB = function() return ZF.db.profile.Units.target.Indicators.Quest end,
		panelTitle = "Quest Indicator Settings",
		toggleLabel = "Enable " .. STYLE.Palette.SelectedText .. "Quest|r Indicator",
		textureLabel = "Quest Texture",
		textureDefault = "DEFAULT",
		textureOrder = {"DEFAULT", "QUEST0", "QUEST1"},
		textureOptions = {
			["DEFAULT"] = GUIWidgets.TextureMarkup(ZF.QuestTextures.DEFAULT, 20),
			["QUEST0"] = GUIWidgets.TextureMarkup(ZF.QuestTextures.QUEST0, 20, 6),
			["QUEST1"] = GUIWidgets.TextureMarkup(ZF.QuestTextures.QUEST1, 20),
		},
	},
	Classification = {
		dbKey = "Classification",
		getDB = function() return ZF.db.profile.Units.target.Indicators.Classification end,
		panelTitle = "Classification Indicator Settings",
		toggleLabel = "Enable " .. STYLE.Palette.SelectedText .. "Classification|r Indicator",
		textureLabel = "Classification Texture",
		textureDefault = "CLASSIFICATION3",
		textureOrder = {"CLASSIFICATION0", "CLASSIFICATION1", "CLASSIFICATION2", "CLASSIFICATION3"},
		textureOptions = {
			["CLASSIFICATION0"] = BuildClassificationMarkup("CLASSIFICATION0"),
			["CLASSIFICATION1"] = BuildClassificationMarkup("CLASSIFICATION1"),
			["CLASSIFICATION2"] = BuildClassificationMarkup("CLASSIFICATION2"),
			["CLASSIFICATION3"] = BuildClassificationMarkup("CLASSIFICATION3"),
		},
	},
	Role = {
		dbKey = "Role",
		panelTitle = "Role Indicator Settings",
		toggleLabel = "Enable " .. STYLE.Palette.SelectedText .. "Role|r Indicator",
		needsSeed = true,
		textureLabel = "Role Texture",
		textureOptions = RoleTextures,
		textureOrder = {"Default", "Blizzard", "Color", "White", "ElvUI", "Square"},
		extraWidgets = function(ToggleContainer, DB, updateCallback)
			local TankToggle = AG:Create("CheckBox")
			TankToggle:SetLabel("Show Tank")
			TankToggle:SetValue(DB.ShowTank)
			TankToggle:SetCallback("OnValueChanged", function(_, _, value) DB.ShowTank = value updateCallback() end)
			TankToggle:SetRelativeWidth(STYLE.Widths.Pct33)
			ToggleContainer:AddChild(TankToggle)

			local HealerToggle = AG:Create("CheckBox")
			HealerToggle:SetLabel("Show Healer")
			HealerToggle:SetValue(DB.ShowHealer)
			HealerToggle:SetCallback("OnValueChanged", function(_, _, value) DB.ShowHealer = value updateCallback() end)
			HealerToggle:SetRelativeWidth(STYLE.Widths.Pct33)
			ToggleContainer:AddChild(HealerToggle)

			local DamagerToggle = AG:Create("CheckBox")
			DamagerToggle:SetLabel("Show DPS")
			DamagerToggle:SetValue(DB.ShowDamager)
			DamagerToggle:SetCallback("OnValueChanged", function(_, _, value) DB.ShowDamager = value updateCallback() end)
			DamagerToggle:SetRelativeWidth(STYLE.Widths.Pct33)
			ToggleContainer:AddChild(DamagerToggle)
		end,
	},
}

local function SeedIndicatorDB(unit, dbKey)
	GetUnitDB(unit).Indicators[dbKey] = GetUnitDB(unit).Indicators[dbKey] or {}
	local DB = GetUnitDB(unit).Indicators[dbKey]
	local DefaultDB = GetDefaultUnitDB(unit).Indicators[dbKey]
	for key, value in pairs(DefaultDB) do
		if DB[key] == nil then DB[key] = type(value) == "table" and {unpack(value)} or value end
	end
	return DB
end

local function CreateSimpleIndicatorPanel(spec, containerParent, unit, updateCallback)
	local DB = spec.needsSeed and SeedIndicatorDB(unit, spec.dbKey) or (spec.getDB and spec.getDB() or GetUnitDB(unit).Indicators[spec.dbKey])
	if spec.persistTextureDefault then DB.Texture = DB.Texture or spec.textureDefault end

	local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, spec.panelTitle)
	local _, Refresh, panelsToDisable = GUIBuilders.CreateEnableToggle(ToggleContainer, spec.toggleLabel, DB, updateCallback, spec.textureLabel and {width = STYLE.Widths.Pct50} or nil)
	panelsToDisable[1] = ToggleContainer

	if spec.textureLabel then
		local TextureDropdown = AG:Create("Dropdown")
		TextureDropdown:SetList(spec.textureOptions, spec.textureOrder)
		TextureDropdown:SetLabel(spec.textureLabel)
		TextureDropdown:SetValue(DB.Texture or spec.textureDefault)
		TextureDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
		TextureDropdown:SetCallback("OnValueChanged", function(_, _, value) DB.Texture = value updateCallback() end)
		ToggleContainer:AddChild(TextureDropdown)
	end

	if spec.extraWidgets then spec.extraWidgets(ToggleContainer, DB, updateCallback) end

	panelsToDisable[2] = GUIBuilders.CreateLayoutPositionBlock(containerParent, DB, updateCallback, {includeSize = true})

	Refresh()
end

local function CreateRaidTargetMarkerSettings(containerParent, unit, updateCallback) CreateSimpleIndicatorPanel(SIMPLE_INDICATOR_PANELS.RaidTargetMarker, containerParent, unit, updateCallback) end
local function CreateAssistantSettings(containerParent, unit, updateCallback) CreateSimpleIndicatorPanel(SIMPLE_INDICATOR_PANELS.LeaderAssistant, containerParent, unit, updateCallback) end
local function CreatePvPIndicatorSettings(containerParent, unit, updateCallback) CreateSimpleIndicatorPanel(SIMPLE_INDICATOR_PANELS.PvP, containerParent, unit, updateCallback) end
local function CreateResurrectIndicatorSettings(containerParent, unit, updateCallback) CreateSimpleIndicatorPanel(SIMPLE_INDICATOR_PANELS.Resurrect, containerParent, unit, updateCallback) end
local function CreateSummonIndicatorSettings(containerParent, unit, updateCallback) CreateSimpleIndicatorPanel(SIMPLE_INDICATOR_PANELS.Summon, containerParent, unit, updateCallback) end
local function CreatePhaseIndicatorSettings(containerParent, unit, updateCallback) CreateSimpleIndicatorPanel(SIMPLE_INDICATOR_PANELS.Phase, containerParent, unit, updateCallback) end
local function CreateReadyCheckIndicatorSettings(containerParent, unit, updateCallback) CreateSimpleIndicatorPanel(SIMPLE_INDICATOR_PANELS.ReadyCheck, containerParent, unit, updateCallback) end
local function CreateQuestIndicatorSettings(containerParent, unit, updateCallback) CreateSimpleIndicatorPanel(SIMPLE_INDICATOR_PANELS.Quest, containerParent, unit, updateCallback) end
local function CreateClassificationIndicatorSettings(containerParent, unit, updateCallback) CreateSimpleIndicatorPanel(SIMPLE_INDICATOR_PANELS.Classification, containerParent, unit, updateCallback) end
local function CreateRoleIndicatorSettings(containerParent, unit, updateCallback) CreateSimpleIndicatorPanel(SIMPLE_INDICATOR_PANELS.Role, containerParent, unit, updateCallback) end

local function CreateStatusSettings(containerParent, unit, statusDB, updateCallback)
    local StatusDB = GetUnitDB(unit).Indicators[statusDB]

    local StatusTextureList = {}
    for key, texture in pairs(StatusTextures[statusDB]) do
        StatusTextureList[key] = texture
    end

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, statusDB .. " Settings")
    local _, Refresh, panelsToDisable = GUIBuilders.CreateEnableToggle(ToggleContainer, "Enable " .. STYLE.Palette.SelectedText .. statusDB .. "|r Indicator", StatusDB, updateCallback, {width = STYLE.Widths.Pct50})
    panelsToDisable[1] = ToggleContainer

    local StatusTextureDropdown = AG:Create("Dropdown")
    StatusTextureDropdown:SetList(StatusTextureList)
    StatusTextureDropdown:SetLabel(statusDB .. " Texture")
    StatusTextureDropdown:SetValue(StatusDB.Texture)
    StatusTextureDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    StatusTextureDropdown:SetCallback("OnValueChanged", function(_, _, value) StatusDB.Texture = value updateCallback() end)
    ToggleContainer:AddChild(StatusTextureDropdown)

    local LayoutContainer = GUIBuilders.CreateLayoutPositionBlock(containerParent, StatusDB, updateCallback, {includeSize = true})
    panelsToDisable[2] = LayoutContainer

    Refresh()
end

local function CreateMouseoverSettings(containerParent, unit, updateCallback)
    local MouseoverDB = GetUnitDB(unit).Indicators.Mouseover

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, "Mouseover Settings")
    local _, Refresh, panelsToDisable = GUIBuilders.CreateEnableToggle(ToggleContainer, "Enable " .. STYLE.Palette.SelectedText .. "Mouseover|r Highlight", MouseoverDB, updateCallback)
    panelsToDisable[1] = ToggleContainer

    GUIBuilders.CreateColorBlock(ToggleContainer, "Highlight Color", MouseoverDB, "Color", updateCallback, {width = STYLE.Widths.Pct33, opacityKey = "HighlightOpacity"})

    local StyleDropdown = AG:Create("Dropdown")
    StyleDropdown:SetList({["BORDER"] = "Border", ["OVERLAY"] = "Overlay", ["GRADIENT"] = "Gradient" })
    StyleDropdown:SetLabel("Highlight Style")
    StyleDropdown:SetValue(MouseoverDB.Style)
    StyleDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
    ToggleContainer:AddChild(StyleDropdown)

    local BorderThicknessSlider = AG:Create("Slider")
    BorderThicknessSlider:SetLabel("Border Thickness")
    BorderThicknessSlider:SetSliderValues(unpack(STYLE.Sliders.BorderThickness))
    BorderThicknessSlider:SetValue(MouseoverDB.BorderThickness)
    BorderThicknessSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    BorderThicknessSlider:SetCallback("OnValueChanged", function(_, _, value)
        MouseoverDB.BorderThickness = value
        updateCallback()
    end)
    ToggleContainer:AddChild(BorderThicknessSlider)

    StyleDropdown:SetCallback("OnValueChanged", function(_, _, value)
        MouseoverDB.Style = value
        BorderThicknessSlider:SetDisabled(value ~= "BORDER")
        updateCallback()
    end)

    Refresh()
    BorderThicknessSlider:SetDisabled(MouseoverDB.Style ~= "BORDER") -- after Refresh, or DeepDisable overrides this
end

local function CreateTargetIndicatorSettings(containerParent, unit, updateCallback)
    local TargetIndicatorDB = GetUnitDB(unit).Indicators.Target
    TargetIndicatorDB.Style = TargetIndicatorDB.Style or "Glow"

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, "Target Indicator Settings")
    local _, Refresh, panelsToDisable = GUIBuilders.CreateEnableToggle(ToggleContainer, "Enable " .. STYLE.Palette.SelectedText .. "Target Indicator|r", TargetIndicatorDB, updateCallback, {width = STYLE.Widths.Pct33})
    panelsToDisable[1] = ToggleContainer

    GUIBuilders.CreateColorBlock(ToggleContainer, "Indicator Color", TargetIndicatorDB, "Color", updateCallback, {width = STYLE.Widths.Pct33})

    local StyleDropdown = AG:Create("Dropdown")
    StyleDropdown:SetList({["Glow"] = "Border", ["Border"] = "Outline"}, {"Glow", "Border"}) -- labels swapped, DB values unchanged
    StyleDropdown:SetLabel("Indicator Style")
    StyleDropdown:SetValue(TargetIndicatorDB.Style)
    StyleDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
    ToggleContainer:AddChild(StyleDropdown)

    local BorderThicknessSlider = AG:Create("Slider")
    BorderThicknessSlider:SetLabel("Border Thickness")
    BorderThicknessSlider:SetSliderValues(unpack(STYLE.Sliders.BorderThickness))
    BorderThicknessSlider:SetValue(TargetIndicatorDB.BorderThickness)
    BorderThicknessSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    BorderThicknessSlider:SetCallback("OnValueChanged", function(_, _, value)
        TargetIndicatorDB.BorderThickness = value
        updateCallback()
    end)
    ToggleContainer:AddChild(BorderThicknessSlider)

    StyleDropdown:SetCallback("OnValueChanged", function(_, _, value)
        TargetIndicatorDB.Style = value
        BorderThicknessSlider:SetDisabled(value ~= "Glow")
        updateCallback()
    end)

    Refresh()
    BorderThicknessSlider:SetDisabled(TargetIndicatorDB.Style ~= "Glow") -- after Refresh, or DeepDisable overrides this
end

local function CreateThreatIndicatorSettings(containerParent, unit, updateCallback)
    GetUnitDB(unit).Indicators.Threat = GetUnitDB(unit).Indicators.Threat or {}
    local DefaultThreatDB = GetDefaultUnitDB(unit).Indicators.Threat
    for key, value in pairs(DefaultThreatDB) do
        if GetUnitDB(unit).Indicators.Threat[key] == nil then GetUnitDB(unit).Indicators.Threat[key] = type(value) == "table" and {unpack(value)} or value end
    end
    local ThreatIndicatorDB = GetUnitDB(unit).Indicators.Threat

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, "Threat Indicator Settings")
    local _, Refresh, panelsToDisable = GUIBuilders.CreateEnableToggle(ToggleContainer, "Enable " .. STYLE.Palette.SelectedText .. "Threat|r Indicator", ThreatIndicatorDB, updateCallback)
    panelsToDisable[1] = ToggleContainer

    GUIWidgets.CreateInformationTag(ToggleContainer, "Threat indicator can only be seen |cFFFF0000during combat|r.")

    Refresh()
end

local function CreateTotemsIndicatorSettings(containerParent, unit, updateCallback)
    local TotemsIndicatorDB = GetUnitDB(unit).Indicators.Totems

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, "Totems Settings")
    local _, Refresh, panelsToDisable = GUIBuilders.CreateEnableToggle(ToggleContainer, "Enable " .. STYLE.Palette.SelectedText .. "Totems|r", TotemsIndicatorDB, updateCallback)
    panelsToDisable[1] = ToggleContainer

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, "Layout & Positioning")
    panelsToDisable[2] = LayoutContainer
    local TotemAnchorFromDropdown = AG:Create("Dropdown")
    TotemAnchorFromDropdown:SetList(GUIBuilders.AnchorPoints[1], GUIBuilders.AnchorPoints[2])
    TotemAnchorFromDropdown:SetLabel("Anchor From")
    TotemAnchorFromDropdown:SetValue(TotemsIndicatorDB.Layout[1])
    TotemAnchorFromDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
    TotemAnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(TotemAnchorFromDropdown)

    local TotemAnchorToDropdown = AG:Create("Dropdown")
    TotemAnchorToDropdown:SetList(GUIBuilders.AnchorPoints[1], GUIBuilders.AnchorPoints[2])
    TotemAnchorToDropdown:SetLabel("Anchor To")
    TotemAnchorToDropdown:SetValue(TotemsIndicatorDB.Layout[2])
    TotemAnchorToDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
    TotemAnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(TotemAnchorToDropdown)

    local GrowthDirectionDropdown = AG:Create("Dropdown")
    GrowthDirectionDropdown:SetList({["RIGHT"] = "Right", ["LEFT"] = "Left"})
    GrowthDirectionDropdown:SetLabel("Growth Direction")
    GrowthDirectionDropdown:SetValue(TotemsIndicatorDB.GrowthDirection)
    GrowthDirectionDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
    GrowthDirectionDropdown:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.GrowthDirection = value updateCallback() end)
    LayoutContainer:AddChild(GrowthDirectionDropdown)

    local TotemXPosSlider = AG:Create("Slider")
    TotemXPosSlider:SetLabel("X Position")
    TotemXPosSlider:SetValue(TotemsIndicatorDB.Layout[3])
    TotemXPosSlider:SetSliderValues(unpack(STYLE.Sliders.Position))
    TotemXPosSlider:SetRelativeWidth(STYLE.Widths.Pct25)
    TotemXPosSlider:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(TotemXPosSlider)

    local TotemYPosSlider = AG:Create("Slider")
    TotemYPosSlider:SetLabel("Y Position")
    TotemYPosSlider:SetValue(TotemsIndicatorDB.Layout[4])
    TotemYPosSlider:SetSliderValues(unpack(STYLE.Sliders.Position))
    TotemYPosSlider:SetRelativeWidth(STYLE.Widths.Pct25)
    TotemYPosSlider:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(TotemYPosSlider)

    local SpacingSlider = AG:Create("Slider")
    SpacingSlider:SetLabel("Totems Indicator Spacing")
    SpacingSlider:SetValue(TotemsIndicatorDB.Layout[5])
    SpacingSlider:SetSliderValues(unpack(STYLE.Sliders.Spacing))
    SpacingSlider:SetRelativeWidth(STYLE.Widths.Pct25)
    SpacingSlider:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Layout[5] = value updateCallback() end)
    LayoutContainer:AddChild(SpacingSlider)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel("Icon Size")
    SizeSlider:SetValue(TotemsIndicatorDB.Size)
    SizeSlider:SetSliderValues(unpack(STYLE.Sliders.IconSize))
    SizeSlider:SetRelativeWidth(STYLE.Widths.Pct25)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) TotemsIndicatorDB.Size = value updateCallback() end)
    LayoutContainer:AddChild(SizeSlider)

    Refresh()
end

local IndicatorTabsByCategory = {
    player = {
        { text = "Raid Target Marker", value = "RaidTargetMarker" },
        { text = "Leader & Assistant", value = "LeaderAssistant" },
        { text = "Resting", value = "Resting" },
        { text = "Combat", value = "Combat" },
        { text = "PvP", value = "PvP" },
        { text = "Mouseover", value = "Mouseover" },
        { text = "Threat Indicator", value = "ThreatIndicator" },
        { text = "Totems", value = "Totems" },
    },
    target = {
        { text = "Raid Target Marker", value = "RaidTargetMarker" },
        { text = "Leader & Assistant", value = "LeaderAssistant" },
        { text = "Combat", value = "Combat" },
        { text = "Mouseover", value = "Mouseover" },
        { text = "Target Indicator", value = "TargetIndicator" },
        { text = "Threat Indicator", value = "ThreatIndicator" },
        { text = "Classification", value = "Classification" },
        { text = "Quest", value = "Quest" },
    },
    group = {
        { text = "Raid Target Marker", value = "RaidTargetMarker" },
        { text = "Leader & Assistant", value = "LeaderAssistant" },
        { text = "Mouseover", value = "Mouseover" },
        { text = "Target Indicator", value = "TargetIndicator" },
        { text = "Threat Indicator", value = "ThreatIndicator" },
        { text = "Role", value = "Role" },
        { text = "Phase", value = "Phase" },
        { text = "Ready Check", value = "ReadyCheckIndicator" },
        { text = "Resurrect", value = "ResurrectIndicator" },
        { text = "Summon", value = "Summon" },
    },
    minor = {
        { text = "Raid Target Marker", value = "RaidTargetMarker" },
        { text = "Mouseover", value = "Mouseover" },
        { text = "Target Indicator", value = "TargetIndicator" },
        { text = "Threat Indicator", value = "ThreatIndicator" },
    },
    passive = {
        { text = "Raid Target Marker", value = "RaidTargetMarker" },
        { text = "Mouseover", value = "Mouseover" },
        { text = "Target Indicator", value = "TargetIndicator" },
    },
}

local IndicatorCategoryByUnit = {
    player = "player",
    target = "target",
    party = "group",
    raid = "group",
    augmentation = "group",
    focus = "minor",
    pet = "minor",
    targettarget = "passive",
    focustarget = "passive",
    boss = "passive",
}

local function CreateIndicatorSettings(containerParent, unit)
    local function SelectIndicatorTab(IndicatorContainer, _, IndicatorTab)
        ZF:SaveSubTab(unit, "Indicators", IndicatorTab)
        IndicatorContainer:ReleaseChildren()
        if IndicatorTab == "RaidTargetMarker" then
            CreateRaidTargetMarkerSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitRaidTargetMarker(ZF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "LeaderAssistant" then
            CreateAssistantSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitLeaderAssistantIndicator(ZF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "Role" then
            CreateRoleIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, nil, "Indicators") end)
        elseif IndicatorTab == "Phase" then
            CreatePhaseIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, nil, "Indicators") end)
		elseif IndicatorTab == "ReadyCheckIndicator" then
			CreateReadyCheckIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, nil, "Indicators") end)
		elseif IndicatorTab == "ResurrectIndicator" then
			CreateResurrectIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, nil, "Indicators") end)
		elseif IndicatorTab == "Summon" then
			CreateSummonIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, nil, "Indicators") end)
        elseif IndicatorTab == "Resting" then
            CreateStatusSettings(IndicatorContainer, unit, "Resting", function() UpdateUnitSettings(unit, function() ZF:UpdateUnitRestingIndicator(ZF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "Combat" then
            CreateStatusSettings(IndicatorContainer, unit, "Combat", function() UpdateUnitSettings(unit, function() ZF:UpdateUnitCombatIndicator(ZF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "PvP" and unit == "player" then
            CreatePvPIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitPvPIndicator(ZF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "Mouseover" then
            CreateMouseoverSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitMouseoverIndicator(ZF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "TargetIndicator" then
            CreateTargetIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitTargetGlowIndicator(ZF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "ThreatIndicator" then
            CreateThreatIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitThreatIndicator(ZF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "Totems" then
            CreateTotemsIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitTotems(ZF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "Quest" and unit == "target" then
            CreateQuestIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitQuestIndicator(ZF[unit:upper()], unit) end, "Indicators") end)
        elseif IndicatorTab == "Classification" and unit == "target" then
            CreateClassificationIndicatorSettings(IndicatorContainer, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitQuestIndicator(ZF[unit:upper()], unit) end, "Indicators") end)
        end
    end

    local IndicatorContainerTabGroup = AG:Create("TabGroup")
    IndicatorContainerTabGroup:SetLayout("Flow")
    IndicatorContainerTabGroup:SetFullWidth(true)
    local tabs = IndicatorTabsByCategory[IndicatorCategoryByUnit[unit]]
    if tabs then
        IndicatorContainerTabGroup:SetTabs(tabs)
    end
    IndicatorContainerTabGroup:SetCallback("OnGroupSelected", SelectIndicatorTab)
    IndicatorContainerTabGroup:SelectTab(GetSavedSubTab(unit, "Indicators", "RaidTargetMarker"))
    containerParent:AddChild(IndicatorContainerTabGroup)
end

GUIInternal.CreateIndicatorSettings = CreateIndicatorSettings
