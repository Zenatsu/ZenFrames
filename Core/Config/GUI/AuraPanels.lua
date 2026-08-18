local _, ZF = ...
local AG = ZF.AG
local GUIWidgets = ZF.GUIWidgets
local GUIBuilders = ZF.GUIBuilders
local STYLE = ZF.DesignerStyle
local GUIInternal = ZF.GUIInternal
local GetUnitDB = GUIInternal.GetUnitDB
local GetSavedSubTab = GUIInternal.GetSavedSubTab
local UpdateUnitSettings = GUIInternal.UpdateUnitSettings
local CreateDesignerPreviewToggle = GUIInternal.CreateDesignerPreviewToggle
local AnchorPoints = GUIInternal.AnchorPoints
local AuraAnchorParents = GUIInternal.AuraAnchorParents
local FrameStrataList = GUIInternal.FrameStrataList

local SORTING_DESCRIPTIONS = {
	BLIZZARD = "|cFF00B4FFBlizzard|r's Default Ordering.",
	BLIZZARD_REVERSED = "|cFF00B4FFBlizzard|r's Default Ordering in Reverse.",
	DURATION = "|cFFFFD100Duration-Based|r Ordering.\nAuras with the shortest remaining duration will be displayed first.",
	DURATION_REVERSED = "|cFFFFD100Duration-Based|r Ordering in Reverse.\nAuras with the longest remaining duration will be displayed first.",
}

local function AttachDropdownItemTooltips(dropdown, descLookup)
	for _, dropdownItem in dropdown.pullout:IterateItems() do
		local value = dropdownItem.userdata and dropdownItem.userdata.value
		local desc = descLookup[value]
		if desc then
			dropdownItem:SetCallback("OnEnter", function()
				GameTooltip:SetOwner(dropdownItem.frame, "ANCHOR_CURSOR_RIGHT")
				GameTooltip:SetFrameStrata("TOOLTIP")
				GameTooltip:SetFrameLevel((dropdown.pullout.frame:GetFrameLevel() or 0) + 100)
				GameTooltip:SetToplevel(true)
				GameTooltip:AddLine(desc, 1, 1, 1, false)
				GameTooltip:Show()
				GameTooltip:SetFrameLevel((dropdown.pullout.frame:GetFrameLevel() or 0) + 100)
			end)
			dropdownItem:SetCallback("OnLeave", function() GameTooltip:Hide() end)
		end
	end
end

local function AddAnchorFromToDropdowns(parent, LayoutDB, updateCallback, width)
	local AnchorFromDropdown = AG:Create("Dropdown")
	AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
	AnchorFromDropdown:SetLabel("Anchor From")
	AnchorFromDropdown:SetValue(LayoutDB[1])
	AnchorFromDropdown:SetRelativeWidth(width)
	AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) LayoutDB[1] = value updateCallback() end)
	parent:AddChild(AnchorFromDropdown)

	local AnchorToDropdown = AG:Create("Dropdown")
	AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
	AnchorToDropdown:SetLabel("Anchor To")
	AnchorToDropdown:SetValue(LayoutDB[2])
	AnchorToDropdown:SetRelativeWidth(width)
	AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) LayoutDB[2] = value updateCallback() end)
	parent:AddChild(AnchorToDropdown)
end

local function AddXYPositionSliders(parent, LayoutDB, updateCallback, width)
	local XPosSlider = AG:Create("Slider")
	XPosSlider:SetLabel("X Position")
	XPosSlider:SetValue(LayoutDB[3])
	XPosSlider:SetSliderValues(unpack(STYLE.Sliders.Position))
	XPosSlider:SetRelativeWidth(width)
	XPosSlider:SetCallback("OnValueChanged", function(_, _, value) LayoutDB[3] = value updateCallback() end)
	parent:AddChild(XPosSlider)

	local YPosSlider = AG:Create("Slider")
	YPosSlider:SetLabel("Y Position")
	YPosSlider:SetValue(LayoutDB[4])
	YPosSlider:SetSliderValues(unpack(STYLE.Sliders.Position))
	YPosSlider:SetRelativeWidth(width)
	YPosSlider:SetCallback("OnValueChanged", function(_, _, value) LayoutDB[4] = value updateCallback() end)
	parent:AddChild(YPosSlider)
end

local function CreateAuraBuffConfigSettings(containerParent, unit, auraDB, rebuildSelf)
    local AuraDB = GetUnitDB(unit).Auras[auraDB]
    local isCustom = auraDB == "Custom"
    local filterAuraDB = auraDB == "Custom" and (AuraDB.Type == "Debuffs" and "Debuffs" or "Buffs") or auraDB
    local auraTitle = auraDB == "Custom" and filterAuraDB or auraDB
    local function UpdateAuras()
        UpdateUnitSettings(unit, function() ZF:UpdateUnitAuras(ZF[unit:upper()], unit, auraDB) end, "Auras")
    end

    local AuraContainer = GUIWidgets.CreateInlineGroup(containerParent, auraTitle .. " Settings")
    local RefreshAuraGUI
    local Toggle, BuilderRefresh, panelsToDisable = GUIBuilders.CreateEnableToggle(AuraContainer, "Enable " .. STYLE.Palette.SelectedText .. auraDB .. "|r", AuraDB, UpdateAuras, {width = isCustom and STYLE.Widths.Pct50 or STYLE.Widths.Pct33})
    panelsToDisable[1] = AuraContainer

    if auraDB == "Custom" then
        local TypeDropdown = AG:Create("Dropdown")
        TypeDropdown:SetList({["Buffs"] = "Buffs", ["Debuffs"] = "Debuffs"}, {"Buffs", "Debuffs"})
        TypeDropdown:SetLabel("Type")
        TypeDropdown:SetValue(filterAuraDB)
        TypeDropdown:SetRelativeWidth(isCustom and STYLE.Widths.Pct50 or STYLE.Widths.Pct33)
        TypeDropdown:SetCallback("OnValueChanged", function(_, _, value)
            AuraDB.Type = value
            AuraDB.Filter = value == "Buffs" and "HELPFUL" or "HARMFUL"
            UpdateAuras()
            rebuildSelf()
        end)
        AuraContainer:AddChild(TypeDropdown)
    end

    local OnlyShowPlayerToggle = AG:Create("CheckBox")
    OnlyShowPlayerToggle:SetLabel("Only Show Player " .. auraTitle)
    OnlyShowPlayerToggle:SetValue(AuraDB.OnlyShowPlayer)
    OnlyShowPlayerToggle:SetCallback("OnValueChanged", function(_, _, value) AuraDB.OnlyShowPlayer = value UpdateAuras() RefreshAuraGUI() end)
    OnlyShowPlayerToggle:SetCallback("OnEnter", function() GameTooltip:SetOwner(OnlyShowPlayerToggle.frame, "ANCHOR_CURSOR") GameTooltip:AddLine("Overrides |cFFFFD100" .. auraTitle:lower() .. "|r advanced filters. If |cFFFFD100Blacklist|r is checked, it will be respected.", 1, 1, 1, true) GameTooltip:Show() end)
    OnlyShowPlayerToggle:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    OnlyShowPlayerToggle:SetRelativeWidth(isCustom and STYLE.Widths.Pct50 or STYLE.Widths.Pct33)
    AuraContainer:AddChild(OnlyShowPlayerToggle)

    local ShowTypeCheckbox = AG:Create("CheckBox")
    ShowTypeCheckbox:SetLabel("Show " .. auraTitle .. " Type Border")
    ShowTypeCheckbox:SetValue(AuraDB.ShowType)
    ShowTypeCheckbox:SetCallback("OnValueChanged", function(_, _, value) AuraDB.ShowType = value UpdateAuras() end)
    ShowTypeCheckbox:SetRelativeWidth(isCustom and STYLE.Widths.Pct50 or STYLE.Widths.Pct33)
    AuraContainer:AddChild(ShowTypeCheckbox)

    local FilterContainer = GUIWidgets.CreateInlineGroup(containerParent, auraTitle .. " Filters")
    AuraDB.Filters = AuraDB.Filters or {}

    local BlacklistToggle = AG:Create("CheckBox")
    BlacklistToggle:SetLabel("Blacklist")
    BlacklistToggle:SetValue(AuraDB.Blacklist or false)
    BlacklistToggle:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Blacklist = value UpdateAuras() end)
    BlacklistToggle:SetRelativeWidth(auraDB == "Debuffs" and STYLE.Widths.Pct33 or STYLE.Widths.Pct50)
    FilterContainer:AddChild(BlacklistToggle)

    local AdvancedBlacklistButton = AG:Create("Button")
    AdvancedBlacklistButton:SetText("Advanced")
    AdvancedBlacklistButton:SetRelativeWidth(auraDB == "Debuffs" and STYLE.Widths.Pct33 or STYLE.Widths.Pct50)
    AdvancedBlacklistButton:SetCallback("OnClick", function() ZF:ShowAuraBlacklistWindow() end)
    FilterContainer:AddChild(AdvancedBlacklistButton)

    local FilterDropdowns = {}

    for _, filter in ipairs(ZF.AURA_FILTERS[filterAuraDB]) do
        if filter.Group == "General" then
            local filterKey = filter.Key
            local FilterToggle = AG:Create("CheckBox")
            FilterToggle:SetLabel(filter.Title)
            FilterToggle:SetValue(AuraDB.Filters[filterKey] or false)
            FilterToggle:SetRelativeWidth(STYLE.Widths.Pct33)
            FilterToggle:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Filters[filterKey] = value or nil UpdateAuras() RefreshAuraGUI() end)
            FilterToggle:SetCallback("OnEnter", function() GameTooltip:SetOwner(FilterToggle.frame, "ANCHOR_CURSOR") GameTooltip:AddLine(filter.Desc, 1, 1, 1, true) GameTooltip:Show() end)
            FilterToggle:SetCallback("OnLeave", function() GameTooltip:Hide() end)
            FilterContainer:AddChild(FilterToggle)
        end
    end

    GUIWidgets.CreateInformationTag(FilterContainer, "Dropdowns support |cFFFFD100multiple selections|r. |cFFFFCC00Player|r is specifically you, where |cFFFFCC00Others|r are all other players/units.")

    for _, filterGroup in ipairs({"Player (You)", "Others (Not You)"}) do
        local filterList = {}
        local filterDesc = {}
        local filterOrder = {}
        local FilterDropdown = AG:Create("Dropdown")
        for _, filter in ipairs(ZF.AURA_FILTERS[filterAuraDB]) do
            if filter.Group == filterGroup then
                filterList[filter.Key] = filter.Title
                filterDesc[filter.Key] = filter.Desc
                filterOrder[#filterOrder + 1] = filter.Key
            end
        end
        FilterDropdown:SetLabel(filterGroup .. " Filters")
        FilterDropdown:SetMultiselect(true)
        FilterDropdown:SetList(filterList, filterOrder)
        AttachDropdownItemTooltips(FilterDropdown, filterDesc)
        for _, filterKey in ipairs(filterOrder) do FilterDropdown:SetItemValue(filterKey, AuraDB.Filters[filterKey] or false) end
        FilterDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
        FilterDropdown:SetCallback("OnValueChanged", function(_, _, filterKey, value) AuraDB.Filters[filterKey] = value or nil UpdateAuras() end)
        FilterContainer:AddChild(FilterDropdown)
        FilterDropdowns[#FilterDropdowns + 1] = FilterDropdown
    end

    RefreshAuraGUI = function()
        BuilderRefresh()
        BlacklistToggle:SetDisabled(not AuraDB.Enabled)
        GUIWidgets.DeepDisable(FilterContainer, not AuraDB.Enabled or AuraDB.OnlyShowPlayer, BlacklistToggle)
        for _, FilterDropdown in ipairs(FilterDropdowns) do FilterDropdown:SetDisabled(not AuraDB.Enabled or AuraDB.OnlyShowPlayer or (filterAuraDB == "Debuffs" and AuraDB.Filters.Typed)) end
    end
    Toggle:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Enabled = value UpdateAuras() RefreshAuraGUI() end)

    RefreshAuraGUI()

    containerParent:DoLayout()
end

local function CreateAuraLayoutSettings(containerParent, unit, auraDB)
    local AuraDB = GetUnitDB(unit).Auras[auraDB]
    local auraTitle = auraDB == "Custom" and (AuraDB.Type == "Debuffs" and "Debuffs" or "Buffs") or auraDB
    local function UpdateAuras()
        UpdateUnitSettings(unit, function() ZF:UpdateUnitAuras(ZF[unit:upper()], unit, auraDB) end, "Auras")
    end

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, "Layout & Positioning")

	local AnchorParentDropdown = AG:Create("Dropdown")
	AnchorParentDropdown:SetList(AuraAnchorParents[1], AuraAnchorParents[2])
	AnchorParentDropdown:SetLabel("Anchor Parent")
	AnchorParentDropdown:SetValue(AuraDB.AnchorRegion)
	AnchorParentDropdown:SetRelativeWidth(STYLE.Widths.Pct25)
	AnchorParentDropdown:SetCallback("OnValueChanged", function(_, _, value) AuraDB.AnchorRegion = value UpdateAuras() end)
	LayoutContainer:AddChild(AnchorParentDropdown)

    AddAnchorFromToDropdowns(LayoutContainer, AuraDB.Layout, UpdateAuras, STYLE.Widths.Pct25)

    local SortingDropdown = AG:Create("Dropdown")
    SortingDropdown:SetList({
        BLIZZARD = "Blizzard",
        BLIZZARD_REVERSED = "Blizzard Reversed",
        DURATION = "Duration",
        DURATION_REVERSED = "Duration Reversed",
    }, {"BLIZZARD", "BLIZZARD_REVERSED", "DURATION", "DURATION_REVERSED"})
    SortingDropdown:SetLabel("Aura Sorting")
    SortingDropdown:SetValue(AuraDB.Sorting or "BLIZZARD")
    SortingDropdown:SetRelativeWidth(STYLE.Widths.Pct25)
    SortingDropdown:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Sorting = value UpdateAuras() end)
    AttachDropdownItemTooltips(SortingDropdown, SORTING_DESCRIPTIONS)
    LayoutContainer:AddChild(SortingDropdown)

    AddXYPositionSliders(LayoutContainer, AuraDB.Layout, UpdateAuras, STYLE.Widths.Pct25)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel("Size")
    SizeSlider:SetValue(AuraDB.Size)
    SizeSlider:SetSliderValues(unpack(STYLE.Sliders.IconSize))
    SizeSlider:SetRelativeWidth(STYLE.Widths.Pct25)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Size = value UpdateAuras() end)
    LayoutContainer:AddChild(SizeSlider)

    local SpacingSlider = AG:Create("Slider")
    SpacingSlider:SetLabel("Spacing")
    SpacingSlider:SetValue(AuraDB.Layout[5])
    SpacingSlider:SetSliderValues(unpack(STYLE.Sliders.AuraSpacing))
    SpacingSlider:SetRelativeWidth(STYLE.Widths.Pct25)
    SpacingSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Layout[5] = value UpdateAuras() end)
    LayoutContainer:AddChild(SpacingSlider)

    GUIWidgets.CreateHeader(LayoutContainer, "Layout")

    local NumAurasSlider = AG:Create("Slider")
    NumAurasSlider:SetLabel(auraTitle .. " To Display")
    NumAurasSlider:SetValue(AuraDB.Num)
    NumAurasSlider:SetSliderValues(unpack(STYLE.Sliders.AuraCount))
    NumAurasSlider:SetRelativeWidth(STYLE.Widths.Pct50)
    NumAurasSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Num = value UpdateAuras() end)
    LayoutContainer:AddChild(NumAurasSlider)

    local PerRowSlider = AG:Create("Slider")
    PerRowSlider:SetLabel(auraTitle .. " Per Row")
    PerRowSlider:SetValue(AuraDB.Wrap)
    PerRowSlider:SetSliderValues(unpack(STYLE.Sliders.AuraCount))
    PerRowSlider:SetRelativeWidth(STYLE.Widths.Pct50)
    PerRowSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Wrap = value UpdateAuras() end)
    LayoutContainer:AddChild(PerRowSlider)

    local GrowthDirectionDropdown = AG:Create("Dropdown")
    GrowthDirectionDropdown:SetList({ ["LEFT"] = "Left", ["RIGHT"] = "Right"})
    GrowthDirectionDropdown:SetLabel("Growth Direction")
    GrowthDirectionDropdown:SetValue(AuraDB.GrowthDirection)
    GrowthDirectionDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    GrowthDirectionDropdown:SetCallback("OnValueChanged", function(_, _, value) AuraDB.GrowthDirection = value UpdateAuras() end)
    LayoutContainer:AddChild(GrowthDirectionDropdown)

    local WrapDirectionDropdown = AG:Create("Dropdown")
    WrapDirectionDropdown:SetList({ ["UP"] = "Up", ["DOWN"] = "Down"})
    WrapDirectionDropdown:SetLabel("Wrap Direction")
    WrapDirectionDropdown:SetValue(AuraDB.WrapDirection)
    WrapDirectionDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    WrapDirectionDropdown:SetCallback("OnValueChanged", function(_, _, value) AuraDB.WrapDirection = value UpdateAuras() end)
    LayoutContainer:AddChild(WrapDirectionDropdown)

    GUIWidgets.DeepDisable(LayoutContainer, not AuraDB.Enabled)
    containerParent:DoLayout()
end

local function CreateAuraCountSettings(containerParent, unit, auraDB)
    local AuraDB = GetUnitDB(unit).Auras[auraDB]
    local function UpdateAuras()
        UpdateUnitSettings(unit, function() ZF:UpdateUnitAuras(ZF[unit:upper()], unit, auraDB) end, "Auras")
    end

    local CountContainer = GUIWidgets.CreateInlineGroup(containerParent, "Count Settings")

    GUIBuilders.CreateColorBlock(CountContainer, "Color", AuraDB.Count, "Color", UpdateAuras, {width = STYLE.Widths.Pct50})

    local HideStacksToggle = AG:Create("CheckBox")
    HideStacksToggle:SetLabel("Hide Stacks")
    HideStacksToggle:SetValue(AuraDB.Count.HideStacks or false)
    HideStacksToggle:SetRelativeWidth(STYLE.Widths.Pct50)
    HideStacksToggle:SetCallback("OnValueChanged", function(_, _, value)
        AuraDB.Count.HideStacks = value
        UpdateAuras()
        GUIWidgets.DeepDisable(CountContainer, not AuraDB.Enabled or AuraDB.Count.HideStacks, HideStacksToggle)
    end)
    CountContainer:AddChild(HideStacksToggle)

    AddAnchorFromToDropdowns(CountContainer, AuraDB.Count.Layout, UpdateAuras, STYLE.Widths.Pct50)
    AddXYPositionSliders(CountContainer, AuraDB.Count.Layout, UpdateAuras, STYLE.Widths.Pct33)

    local FontSizeSlider = AG:Create("Slider")
    FontSizeSlider:SetLabel("Font Size")
    FontSizeSlider:SetValue(AuraDB.Count.FontSize)
    FontSizeSlider:SetSliderValues(unpack(STYLE.Sliders.FontSize))
    FontSizeSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    FontSizeSlider:SetCallback("OnValueChanged", function(_, _, value) AuraDB.Count.FontSize = value UpdateAuras() end)
    CountContainer:AddChild(FontSizeSlider)

    HideStacksToggle:SetDisabled(not AuraDB.Enabled)
    GUIWidgets.DeepDisable(CountContainer, not AuraDB.Enabled or AuraDB.Count.HideStacks, HideStacksToggle)
    containerParent:DoLayout()
end

local function CreateSpecificAuraSettings(containerParent, unit, auraDB)
    local configLabel = auraDB == "Custom" and "Custom Config" or auraDB == "Debuffs" and "Debuff Config" or "Buff Config"

    local function SelectAuraDetailTab(DetailContainer, _, detailTab)
        ZF:SaveSubTab(unit, "AuraDetail", detailTab)
        DetailContainer:ReleaseChildren()
        if detailTab == "BuffConfig" then
            CreateAuraBuffConfigSettings(DetailContainer, unit, auraDB, function() SelectAuraDetailTab(DetailContainer, nil, "BuffConfig") end)
        elseif detailTab == "Layout" then
            CreateAuraLayoutSettings(DetailContainer, unit, auraDB)
        elseif detailTab == "Count" then
            CreateAuraCountSettings(DetailContainer, unit, auraDB)
        end
        containerParent:DoLayout()
    end

    local AuraDetailTabGroup = AG:Create("TabGroup")
    AuraDetailTabGroup:SetLayout("Flow")
    AuraDetailTabGroup:SetFullWidth(true)
    AuraDetailTabGroup:SetTabs({
        { text = configLabel, value = "BuffConfig" },
        { text = "Layout & Positioning", value = "Layout" },
        { text = "Count Settings", value = "Count" },
    })
    AuraDetailTabGroup:SetCallback("OnGroupSelected", SelectAuraDetailTab)
    AuraDetailTabGroup:SelectTab(GetSavedSubTab(unit, "AuraDetail", "BuffConfig"))
    containerParent:AddChild(AuraDetailTabGroup)
    containerParent:DoLayout()
end

local function CreatePrivateAuraBuffConfigSettings(containerParent, unit, updateCallback)
    local PrivateAurasDB = GetUnitDB(unit).Auras.PrivateAuras

    local GeneralContainer = GUIWidgets.CreateInlineGroup(containerParent, "Private Aura Settings")
    GUIWidgets.CreateInformationTag(GeneralContainer, "Private Auras are controlled by |cFF00B0F7Blizzard|r. The options below are as far as customization will allow.")

    local _, Refresh, panelsToDisable = GUIBuilders.CreateEnableToggle(GeneralContainer, "Enable " .. STYLE.Palette.SelectedText .. "Private Auras|r", PrivateAurasDB, updateCallback, {width = STYLE.Widths.Pct33})
    panelsToDisable[1] = GeneralContainer

    local DisableCooldownToggle = AG:Create("CheckBox")
    DisableCooldownToggle:SetLabel("Disable Cooldown Spiral")
    DisableCooldownToggle:SetValue(PrivateAurasDB.DisableCooldown)
    DisableCooldownToggle:SetRelativeWidth(STYLE.Widths.Pct33)
    DisableCooldownToggle:SetCallback("OnValueChanged", function(_, _, value) PrivateAurasDB.DisableCooldown = value updateCallback() end)
    GeneralContainer:AddChild(DisableCooldownToggle)

    local DisableCooldownTextToggle = AG:Create("CheckBox")
    DisableCooldownTextToggle:SetLabel("Disable Cooldown Text")
    DisableCooldownTextToggle:SetValue(PrivateAurasDB.DisableCooldownText)
    DisableCooldownTextToggle:SetRelativeWidth(STYLE.Widths.Pct33)
    DisableCooldownTextToggle:SetCallback("OnValueChanged", function(_, _, value) PrivateAurasDB.DisableCooldownText = value updateCallback() end)
    GeneralContainer:AddChild(DisableCooldownTextToggle)

    local BorderScaleSlider = AG:Create("Slider")
    BorderScaleSlider:SetLabel("Border Scale")
    BorderScaleSlider:SetValue(PrivateAurasDB.BorderScale == -100 and -1 or PrivateAurasDB.BorderScale)
    BorderScaleSlider:SetSliderValues(unpack(STYLE.Sliders.BorderScale))
    BorderScaleSlider:SetRelativeWidth(STYLE.Widths.Pct50)
    BorderScaleSlider:SetCallback("OnValueChanged", function(widget, _, value) if value < 0 then value = -1 widget:SetValue(value) end PrivateAurasDB.BorderScale = value updateCallback() end)
    GeneralContainer:AddChild(BorderScaleSlider)

    local FrameStrataDropdown = AG:Create("Dropdown")
    FrameStrataDropdown:SetList(FrameStrataList[1], FrameStrataList[2])
    FrameStrataDropdown:SetLabel("Frame Strata")
    FrameStrataDropdown:SetValue(PrivateAurasDB.FrameStrata)
    FrameStrataDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    FrameStrataDropdown:SetCallback("OnValueChanged", function(_, _, value) PrivateAurasDB.FrameStrata = value updateCallback() end)
    GeneralContainer:AddChild(FrameStrataDropdown)

    Refresh()

    containerParent:DoLayout()
end

local function CreatePrivateAuraLayoutSettings(containerParent, unit, updateCallback)
    local PrivateAurasDB = GetUnitDB(unit).Auras.PrivateAuras

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, "Layout & Positioning")
    local SizeContainer = GUIWidgets.CreateInlineGroup(containerParent, "Size & Spacing")

	local AnchorParentDropdown = AG:Create("Dropdown")
	AnchorParentDropdown:SetList(AuraAnchorParents[1], AuraAnchorParents[2])
	AnchorParentDropdown:SetLabel("Anchor Parent")
	AnchorParentDropdown:SetValue(PrivateAurasDB.AnchorRegion)
	AnchorParentDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
	AnchorParentDropdown:SetCallback("OnValueChanged", function(_, _, value) PrivateAurasDB.AnchorRegion = value updateCallback() end)
	LayoutContainer:AddChild(AnchorParentDropdown)

    AddAnchorFromToDropdowns(LayoutContainer, PrivateAurasDB.Layout, updateCallback, STYLE.Widths.Pct33)
    AddXYPositionSliders(LayoutContainer, PrivateAurasDB.Layout, updateCallback, STYLE.Widths.Pct50)

    local InitialAnchorDropdown = AG:Create("Dropdown")
    InitialAnchorDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    InitialAnchorDropdown:SetLabel("Initial Aura Anchor")
    InitialAnchorDropdown:SetValue(PrivateAurasDB.InitialAnchor)
    InitialAnchorDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
    InitialAnchorDropdown:SetCallback("OnValueChanged", function(_, _, value) PrivateAurasDB.InitialAnchor = value updateCallback() end)
    LayoutContainer:AddChild(InitialAnchorDropdown)

    local GrowthXDropdown = AG:Create("Dropdown")
    GrowthXDropdown:SetList({["LEFT"] = "Left", ["RIGHT"] = "Right"}, {"LEFT", "RIGHT"})
    GrowthXDropdown:SetLabel("Horizontal Growth")
    GrowthXDropdown:SetValue(PrivateAurasDB.GrowthX)
    GrowthXDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
    GrowthXDropdown:SetCallback("OnValueChanged", function(_, _, value) PrivateAurasDB.GrowthX = value updateCallback() end)
    LayoutContainer:AddChild(GrowthXDropdown)

    local GrowthYDropdown = AG:Create("Dropdown")
    GrowthYDropdown:SetList({["UP"] = "Up", ["DOWN"] = "Down"}, {"UP", "DOWN"})
    GrowthYDropdown:SetLabel("Vertical Growth")
    GrowthYDropdown:SetValue(PrivateAurasDB.GrowthY)
    GrowthYDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
    GrowthYDropdown:SetCallback("OnValueChanged", function(_, _, value) PrivateAurasDB.GrowthY = value updateCallback() end)
    LayoutContainer:AddChild(GrowthYDropdown)

    local SizeSlider = AG:Create("Slider")
    SizeSlider:SetLabel("Size")
    SizeSlider:SetValue(PrivateAurasDB.Size)
    SizeSlider:SetSliderValues(unpack(STYLE.Sliders.PrivateAuraSize))
    SizeSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    SizeSlider:SetCallback("OnValueChanged", function(_, _, value) PrivateAurasDB.Size = value updateCallback() end)
    SizeContainer:AddChild(SizeSlider)

    local SpacingSlider = AG:Create("Slider")
    SpacingSlider:SetLabel("Spacing")
    SpacingSlider:SetValue(PrivateAurasDB.Spacing)
    SpacingSlider:SetSliderValues(unpack(STYLE.Sliders.PrivateAuraSpacing))
    SpacingSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    SpacingSlider:SetCallback("OnValueChanged", function(_, _, value) PrivateAurasDB.Spacing = value updateCallback() end)
    SizeContainer:AddChild(SpacingSlider)

    local NumSlider = AG:Create("Slider")
    NumSlider:SetLabel("Private Auras To Display")
    NumSlider:SetValue(PrivateAurasDB.Num)
    NumSlider:SetSliderValues(unpack(STYLE.Sliders.PrivateAuraCount))
    NumSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    NumSlider:SetCallback("OnValueChanged", function(_, _, value) PrivateAurasDB.Num = value updateCallback() end)
    SizeContainer:AddChild(NumSlider)

    local disabled = not PrivateAurasDB.Enabled
    GUIWidgets.DeepDisable(LayoutContainer, disabled)
    GUIWidgets.DeepDisable(SizeContainer, disabled)
    containerParent:DoLayout()
end

local function CreatePrivateAuraSettings(containerParent, unit, updateCallback)
    local function SelectPrivateDetailTab(DetailContainer, _, detailTab)
        ZF:SaveSubTab(unit, "AuraDetail", detailTab)
        DetailContainer:ReleaseChildren()
        if detailTab == "Layout" then
            CreatePrivateAuraLayoutSettings(DetailContainer, unit, updateCallback)
        else
            CreatePrivateAuraBuffConfigSettings(DetailContainer, unit, updateCallback)
        end
        containerParent:DoLayout()
    end

    local PrivateDetailTabGroup = AG:Create("TabGroup")
    PrivateDetailTabGroup:SetLayout("Flow")
    PrivateDetailTabGroup:SetFullWidth(true)
    PrivateDetailTabGroup:SetTabs({
        { text = "Buff Config", value = "BuffConfig" },
        { text = "Layout & Positioning", value = "Layout" },
    })
    PrivateDetailTabGroup:SetCallback("OnGroupSelected", SelectPrivateDetailTab)
    local startTab = GetSavedSubTab(unit, "AuraDetail", "BuffConfig")
    if startTab == "Count" then startTab = "BuffConfig" end
    PrivateDetailTabGroup:SelectTab(startTab)
    containerParent:AddChild(PrivateDetailTabGroup)
    containerParent:DoLayout()
end

function GUIInternal.CreateAuraSettings(containerParent, unit, updateCallback)
    local AurasDB = GetUnitDB(unit).Auras

    CreateDesignerPreviewToggle(containerParent, "Auras", updateCallback)

    local Spacer = AG:Create("Label")
    Spacer:SetText("")
    Spacer:SetRelativeWidth(STYLE.Widths.Pct29)
    containerParent:AddChild(Spacer)

    local FrameStrataDropdown = AG:Create("Dropdown")
    FrameStrataDropdown:SetList(FrameStrataList[1], FrameStrataList[2])
    FrameStrataDropdown:SetLabel("Frame Strata")
    FrameStrataDropdown:SetValue(AurasDB.FrameStrata)
    FrameStrataDropdown:SetRelativeWidth(STYLE.Widths.Pct30)
    FrameStrataDropdown:SetCallback("OnValueChanged", function(_, _, value) AurasDB.FrameStrata = value updateCallback() end)
    containerParent:AddChild(FrameStrataDropdown)

    local function SelectAuraTab(AuraContainer, _, AuraTab)
        ZF:SaveSubTab(unit, "Auras", AuraTab)
        AuraContainer:ReleaseChildren()
        if AuraTab == "Buffs" then
            CreateSpecificAuraSettings(AuraContainer, unit, "Buffs", updateCallback)
        elseif AuraTab == "Debuffs" then
            CreateSpecificAuraSettings(AuraContainer, unit, "Debuffs", updateCallback)
        elseif AuraTab == "Custom" and AurasDB.Custom then
            CreateSpecificAuraSettings(AuraContainer, unit, "Custom", updateCallback)
        elseif AuraTab == "PrivateAuras" and AurasDB.PrivateAuras then
            CreatePrivateAuraSettings(AuraContainer, unit, updateCallback)
        end
        containerParent:DoLayout()
    end

    local AuraContainerTabGroup = AG:Create("TabGroup")
    AuraContainerTabGroup:SetLayout("Flow")
    AuraContainerTabGroup:SetFullWidth(true)
    local auraTabs = { { text = "Buffs", value = "Buffs" }, { text = "Debuffs", value = "Debuffs" } }
    if AurasDB.Custom then auraTabs[#auraTabs + 1] = { text = "Custom", value = "Custom" } end
    if AurasDB.PrivateAuras then auraTabs[#auraTabs + 1] = { text = "Private Auras", value = "PrivateAuras" } end
    AuraContainerTabGroup:SetTabs(auraTabs)
    AuraContainerTabGroup:SetCallback("OnGroupSelected", SelectAuraTab)
    AuraContainerTabGroup:SelectTab(GetSavedSubTab(unit, "Auras", "Buffs"))
    containerParent:AddChild(AuraContainerTabGroup)

    containerParent:DoLayout()
end
