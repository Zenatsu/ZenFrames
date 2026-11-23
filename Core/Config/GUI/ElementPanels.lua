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
local TopBottomList = GUIInternal.TopBottomList
local FrameStrataList = GUIInternal.FrameStrataList

local HealPredictionPositionList = {["TOPLEFT"] = "Top Left", ["TOPRIGHT"] = "Top Right", ["BOTTOMLEFT"] = "Bottom Left", ["BOTTOMRIGHT"] = "Bottom Right", ["LEFT"] = "Left", ["RIGHT"] = "Right", ["ATTACH"] = "Attach To Missing Health"}
local HealPredictionPositionOrder = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "LEFT", "RIGHT", "ATTACH"}

local function CreatePredictionBarPanel(containerParent, label, subDB, FrameDB, updateCallback, refreshFn, options)
    local width = options.width

    local Panel = GUIWidgets.CreateInlineGroup(containerParent, label)
    local Toggle, BuilderRefresh, panels = GUIBuilders.CreateEnableToggle(Panel, options.toggleLabel, subDB, updateCallback, {width = width})
    panels[1] = Panel

    local ShowOverAbsorbToggle
    if options.showOverAbsorb then
        ShowOverAbsorbToggle = AG:Create("CheckBox")
        ShowOverAbsorbToggle:SetLabel("Show Over Absorb")
        ShowOverAbsorbToggle:SetValue(subDB.ShowOverAbsorb or false)
        ShowOverAbsorbToggle:SetCallback("OnValueChanged", function(_, _, value) subDB.ShowOverAbsorb = subDB.Position == "ATTACH" and value or false updateCallback() refreshFn() end)
        ShowOverAbsorbToggle:SetCallback("OnEnter", function() GameTooltip:SetOwner(ShowOverAbsorbToggle.frame, "ANCHOR_CURSOR") GameTooltip:AddLine("This will add an overlay of your current absorbs when at maximum health.\nThis will only work when the |cFFFFD100Position|r is set to |cFFFFD100Attach To Missing Health|r.", 1, 1, 1, false) GameTooltip:Show() end)
        ShowOverAbsorbToggle:SetCallback("OnLeave", function() GameTooltip:Hide() end)
        ShowOverAbsorbToggle:SetRelativeWidth(width)
        Panel:AddChild(ShowOverAbsorbToggle)
    end

    local UseStripedTextureToggle = AG:Create("CheckBox")
    UseStripedTextureToggle:SetLabel("Use Striped Texture")
    UseStripedTextureToggle:SetValue(subDB.UseStripedTexture)
    UseStripedTextureToggle:SetCallback("OnValueChanged", function(_, _, value) subDB.UseStripedTexture = value updateCallback() end)
    UseStripedTextureToggle:SetRelativeWidth(width)
    Panel:AddChild(UseStripedTextureToggle)

    local MatchParentHeightToggle = AG:Create("CheckBox")
    MatchParentHeightToggle:SetLabel("Match Parent Height")
    MatchParentHeightToggle:SetValue(subDB.MatchParentHeight)
    MatchParentHeightToggle:SetCallback("OnValueChanged", function(_, _, value) subDB.MatchParentHeight = value updateCallback() refreshFn() end)
    MatchParentHeightToggle:SetRelativeWidth(width)
    Panel:AddChild(MatchParentHeightToggle)

    GUIBuilders.CreateColorBlock(Panel, options.colorLabel, subDB, "Color", updateCallback, {hasAlpha = true, width = STYLE.Widths.Pct33})

    local HeightSlider = GUIBuilders.CreateSlider(Panel, "Height", subDB, "Height", updateCallback, {sliderValues = {1, FrameDB.Height - 2, 0.1}, width = STYLE.Widths.Pct33})

    local PositionDropdown = AG:Create("Dropdown")
    PositionDropdown:SetList(HealPredictionPositionList, HealPredictionPositionOrder)
    PositionDropdown:SetLabel("Position")
    PositionDropdown:SetValue(subDB.Position)
    PositionDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
    PositionDropdown:SetCallback("OnValueChanged", function(_, _, value)
        subDB.Position = value
        if ShowOverAbsorbToggle and value ~= "ATTACH" then
            subDB.ShowOverAbsorb = false
            ShowOverAbsorbToggle:SetValue(false)
        end
        updateCallback()
        refreshFn()
    end)
    Panel:AddChild(PositionDropdown)

    Toggle:SetCallback("OnValueChanged", function(_, _, value) subDB.Enabled = value updateCallback() refreshFn() end)

    return { BuilderRefresh = BuilderRefresh, HeightSlider = HeightSlider, ShowOverAbsorbToggle = ShowOverAbsorbToggle }
end

local function CreateHealPredictionSettings(containerParent, unit, updateCallback)
    local FrameDB = GetUnitDB(unit).Frame
    local HealPredictionDB = GetUnitDB(unit).HealPrediction
    local RefreshHealPredictionSettings
    local function DeferredRefresh() RefreshHealPredictionSettings() end

    local IncomingHealRefs = CreatePredictionBarPanel(containerParent, "Incoming Heal Settings", HealPredictionDB.IncomingHeal, FrameDB, updateCallback, DeferredRefresh, {
        toggleLabel = "Show Incoming Heals", width = STYLE.Widths.Pct33, colorLabel = "Incoming Heal Color",
    })
    local AbsorbRefs = CreatePredictionBarPanel(containerParent, "Absorb Settings", HealPredictionDB.Absorbs, FrameDB, updateCallback, DeferredRefresh, {
        toggleLabel = "Show Absorbs", width = STYLE.Widths.Pct25, colorLabel = "Absorb Color", showOverAbsorb = true,
    })
    local HealAbsorbRefs = CreatePredictionBarPanel(containerParent, "Heal Absorb Settings", HealPredictionDB.HealAbsorbs, FrameDB, updateCallback, DeferredRefresh, {
        toggleLabel = "Show Heal Absorbs", width = STYLE.Widths.Pct33, colorLabel = "Heal Absorb Color",
    })

    RefreshHealPredictionSettings = function()
        IncomingHealRefs.BuilderRefresh()
        IncomingHealRefs.HeightSlider:SetDisabled(HealPredictionDB.IncomingHeal.MatchParentHeight or HealPredictionDB.IncomingHeal.Position == "ATTACH")
        AbsorbRefs.BuilderRefresh()
        AbsorbRefs.HeightSlider:SetDisabled(HealPredictionDB.Absorbs.MatchParentHeight or HealPredictionDB.Absorbs.Position == "ATTACH")
        AbsorbRefs.ShowOverAbsorbToggle:SetDisabled(not HealPredictionDB.Absorbs.Enabled or HealPredictionDB.Absorbs.Position ~= "ATTACH")
        HealAbsorbRefs.BuilderRefresh()
        HealAbsorbRefs.HeightSlider:SetDisabled(HealPredictionDB.HealAbsorbs.MatchParentHeight or HealPredictionDB.HealAbsorbs.Position == "ATTACH")
    end

    RefreshHealPredictionSettings()
end

local function CreateCastBarBarSettings(containerParent, unit, updateCallback)
    local CastBarDB = GetUnitDB(unit).CastBar
    local DefaultCastBarDB = GetDefaultUnitDB(unit).CastBar
    if not CastBarDB.InterruptCooldownColor then CastBarDB.InterruptCooldownColor = {unpack(DefaultCastBarDB.InterruptCooldownColor)} end
    local isPlayerorPet = unit == "player" or unit == "pet"
    local RefreshCastBarBarSettings

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, "Cast Bar Settings")
    local Toggle, BuilderRefresh, panelsToDisable = GUIBuilders.CreateEnableToggle(LayoutContainer, "Enable " .. STYLE.Palette.SelectedText .. "Cast Bar|r", CastBarDB, updateCallback, {width = STYLE.Widths.Pct33})

    local MatchParentWidthToggle = AG:Create("CheckBox")
    MatchParentWidthToggle:SetLabel("Match Frame Width")
    MatchParentWidthToggle:SetValue(CastBarDB.MatchParentWidth)
    MatchParentWidthToggle:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.MatchParentWidth = value updateCallback() RefreshCastBarBarSettings() end)
    MatchParentWidthToggle:SetRelativeWidth(STYLE.Widths.Pct33)
    LayoutContainer:AddChild(MatchParentWidthToggle)
    panelsToDisable[#panelsToDisable + 1] = MatchParentWidthToggle

    local InverseGrowthDirectionToggle = AG:Create("CheckBox")
    InverseGrowthDirectionToggle:SetLabel("Inverse Growth Direction")
    InverseGrowthDirectionToggle:SetValue(CastBarDB.Inverse)
    InverseGrowthDirectionToggle:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Inverse = value updateCallback() end)
    InverseGrowthDirectionToggle:SetRelativeWidth(STYLE.Widths.Pct33)
    LayoutContainer:AddChild(InverseGrowthDirectionToggle)

    local WidthSlider = GUIBuilders.CreateSlider(LayoutContainer, "Width", CastBarDB, "Width", updateCallback, {sliderValues = STYLE.Sliders.Dimension, width = STYLE.Widths.Pct50})

    local HeightSlider = GUIBuilders.CreateSlider(LayoutContainer, "Height", CastBarDB, "Height", updateCallback, {sliderValues = STYLE.Sliders.Dimension, width = STYLE.Widths.Pct50})
    panelsToDisable[#panelsToDisable + 1] = HeightSlider

    local HoldTimeSlider = GUIBuilders.CreateSlider(LayoutContainer, "Interrupted/Failed Hold Time", CastBarDB, "HoldTime", updateCallback, {sliderValues = STYLE.Sliders.HoldTime, width = STYLE.Widths.Pct100})
    panelsToDisable[#panelsToDisable + 1] = HoldTimeSlider

    local _, XPosSlider, YPosSlider, _, AnchorFromDropdown, AnchorToDropdown = GUIBuilders.CreateLayoutPositionBlock(nil, CastBarDB, updateCallback, {container = LayoutContainer, xyWidth = STYLE.Widths.Pct33})
    panelsToDisable[#panelsToDisable + 1] = AnchorFromDropdown
    panelsToDisable[#panelsToDisable + 1] = AnchorToDropdown
    panelsToDisable[#panelsToDisable + 1] = XPosSlider
    panelsToDisable[#panelsToDisable + 1] = YPosSlider

    GUIBuilders.CreateDropdown(LayoutContainer, "Frame Strata", CastBarDB, "FrameStrata", updateCallback, {list = FrameStrataList[1], order = FrameStrataList[2], width = STYLE.Widths.Pct33})

    local ColorContainer = GUIWidgets.CreateInlineGroup(containerParent, "Colors & Toggles")

    if isPlayerorPet then
        local ClassColorToggle = AG:Create("CheckBox")
        ClassColorToggle:SetLabel("Foreground: Color by Class")
        ClassColorToggle:SetValue(CastBarDB.ColorByClass)
        ClassColorToggle:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.ColorByClass = value updateCallback() RefreshCastBarBarSettings() end)
        ClassColorToggle:SetRelativeWidth(STYLE.Widths.Pct50)
        ColorContainer:AddChild(ClassColorToggle)
        panelsToDisable[#panelsToDisable + 1] = ClassColorToggle
    end

    local ForegroundColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Foreground", CastBarDB, "Foreground", updateCallback, {hasAlpha = true, width = STYLE.Widths.Pct50})
    local BackgroundColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Background", CastBarDB, "Background", updateCallback, {hasAlpha = true, width = STYLE.Widths.Pct50})
    panelsToDisable[#panelsToDisable + 1] = BackgroundColorPicker
    local NotInterruptibleColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Not Interruptible", CastBarDB, "NotInterruptibleColor", updateCallback, {hasAlpha = true, width = STYLE.Widths.Pct50})
    panelsToDisable[#panelsToDisable + 1] = NotInterruptibleColorPicker
    local InterruptCooldownColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Interrupt on Cooldown", CastBarDB, "InterruptCooldownColor", updateCallback, {hasAlpha = true, width = STYLE.Widths.Pct50})
    panelsToDisable[#panelsToDisable + 1] = InterruptCooldownColorPicker
    local InterruptedFailedColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Interrupted / Failed", CastBarDB, "InterruptedFailedColor", updateCallback, {hasAlpha = true, width = STYLE.Widths.Pct50})
    panelsToDisable[#panelsToDisable + 1] = InterruptedFailedColorPicker

    local ColorRowBreak = AG:Create("Label")
    ColorRowBreak:SetText("")
    ColorRowBreak:SetFullWidth(true)
    ColorContainer:AddChild(ColorRowBreak)

    local _, _, BorderOpacitySlider = GUIBuilders.CreateBorderBlock(ColorContainer, CastBarDB, updateCallback, function() RefreshCastBarBarSettings() end, panelsToDisable)

    RefreshCastBarBarSettings = function()
        BuilderRefresh()
        WidthSlider:SetDisabled(not CastBarDB.Enabled or CastBarDB.MatchParentWidth)
        ForegroundColorPicker:SetDisabled(not CastBarDB.Enabled or CastBarDB.ColorByClass)
        BorderOpacitySlider:SetDisabled(not CastBarDB.Enabled or CastBarDB.BorderThickness == 0)
    end
    Toggle:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Enabled = value updateCallback() RefreshCastBarBarSettings() end)

    RefreshCastBarBarSettings()
end

local function CreateCastBarIconSettings(containerParent, unit, updateCallback)
    local CastBarIconDB = GetUnitDB(unit).CastBar.Icon

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, "Icon Settings")
    local _, Refresh, panelsToDisable = GUIBuilders.CreateEnableToggle(LayoutContainer, "Enable " .. STYLE.Palette.SelectedText .. "Cast Bar Icon|r", CastBarIconDB, updateCallback, {width = STYLE.Widths.Pct50})

    local PositionDropdown = AG:Create("Dropdown")
    PositionDropdown:SetList({["LEFT"] = "Left", ["RIGHT"] = "Right"})
    PositionDropdown:SetLabel("Position")
    PositionDropdown:SetValue(CastBarIconDB.Position)
    PositionDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    PositionDropdown:SetCallback("OnValueChanged", function(_, _, value) CastBarIconDB.Position = value updateCallback() end)
    LayoutContainer:AddChild(PositionDropdown)
    panelsToDisable[1] = PositionDropdown

    Refresh()
end

local function CreateCastBarSpellNameTextSettings(containerParent, unit, updateCallback)
    local CastBarDB = GetUnitDB(unit).CastBar
    local CastBarTextDB = CastBarDB.Text
    local SpellNameTextDB = CastBarTextDB.SpellName

    local SpellNameContainer = GUIWidgets.CreateInlineGroup(containerParent, "Spell Name Settings")
    local _, Refresh, panelsToDisable = GUIBuilders.CreateEnableToggle(SpellNameContainer, "Enable " .. STYLE.Palette.SelectedText .. "Spell Name Text|r", SpellNameTextDB, updateCallback, {width = STYLE.Widths.Pct33})
    panelsToDisable[1] = SpellNameContainer

    local ShowTargetToggle = AG:Create("CheckBox")
    ShowTargetToggle:SetLabel("Show Target")
    ShowTargetToggle:SetValue(CastBarDB.ShowTarget)
    ShowTargetToggle:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.ShowTarget = value updateCallback() end)
    ShowTargetToggle:SetRelativeWidth(STYLE.Widths.Pct33)
    SpellNameContainer:AddChild(ShowTargetToggle)

    GUIBuilders.CreateColorBlock(SpellNameContainer, "Color", SpellNameTextDB, "Color", updateCallback, {width = STYLE.Widths.Pct33})

    local SpellNameLayoutContainer = GUIBuilders.CreateLayoutPositionBlock(SpellNameContainer, SpellNameTextDB, updateCallback, {includeSize = true, sizeKey = "FontSize", sizeLabel = "Font Size", groupLabel = "Layout", xyWidth = STYLE.Widths.Pct25, sizeWidth = STYLE.Widths.Pct25})

    GUIBuilders.CreateSlider(SpellNameLayoutContainer, "Max Characters", SpellNameTextDB, "MaxChars", updateCallback, {sliderValues = STYLE.Sliders.MaxChars, width = STYLE.Widths.Pct25})

    Refresh()
end

local function CreateCastBarDurationTextSettings(containerParent, unit, updateCallback)
    local CastBarTextDB = GetUnitDB(unit).CastBar.Text
    local DurationTextDB = CastBarTextDB.Duration

     local DurationContainer = GUIWidgets.CreateInlineGroup(containerParent, "Duration Settings")
    local _, Refresh, panelsToDisable = GUIBuilders.CreateEnableToggle(DurationContainer, "Enable " .. STYLE.Palette.SelectedText .. "Duration Text|r", DurationTextDB, updateCallback, {width = STYLE.Widths.Pct50})
    panelsToDisable[1] = DurationContainer

    GUIBuilders.CreateColorBlock(DurationContainer, "Color", DurationTextDB, "Color", updateCallback, {width = STYLE.Widths.Pct50})

    GUIBuilders.CreateLayoutPositionBlock(DurationContainer, DurationTextDB, updateCallback, {includeSize = true, sizeKey = "FontSize", sizeLabel = "Font Size", groupLabel = "Layout"})

    Refresh()
end

local function CreateCastBarSettings(containerParent, unit)
	local function UpdateCastBar() UpdateUnitSettings(unit, function() ZF:UpdateUnitCastBar(ZF[unit:upper()], unit) end, "CastBar") end

    local function SelectCastBarTab(CastBarContainer, _, CastBarTab)
        ZF:SaveSubTab(unit, "CastBar", CastBarTab)
        CastBarContainer:ReleaseChildren()
        if CastBarTab == "Bar" then
            CreateCastBarBarSettings(CastBarContainer, unit, UpdateCastBar)
        elseif CastBarTab == "Icon" then
            CreateCastBarIconSettings(CastBarContainer, unit, UpdateCastBar)
        elseif CastBarTab == "SpellName" then
            CreateCastBarSpellNameTextSettings(CastBarContainer, unit, UpdateCastBar)
        elseif CastBarTab == "Duration" then
            CreateCastBarDurationTextSettings(CastBarContainer, unit, UpdateCastBar)
        end
    end

    local CastBarTabGroup = AG:Create("TabGroup")
    CastBarTabGroup:SetLayout("Flow")
    CastBarTabGroup:SetFullWidth(true)
    CastBarTabGroup:SetTabs({
        {text = "Bar", value = "Bar"},
        {text = "Icon" , value = "Icon"},
        {text = "Text: |cFFFFFFFFSpell Name|r", value = "SpellName"},
        {text = "Text: |cFFFFFFFFDuration|r", value = "Duration"},
    })
    CastBarTabGroup:SetCallback("OnGroupSelected", SelectCastBarTab)
    CastBarTabGroup:SelectTab(GetSavedSubTab(unit, "CastBar", "Bar"))
    containerParent:AddChild(CastBarTabGroup)
end

local function CreateXPBarSettings(containerParent, unit)
    local XPBarDB = GetUnitDB(unit).XPBar
    local function UpdateXPBar() UpdateUnitSettings(unit, function() ZF:UpdateUnitXPBar(ZF[unit:upper()], unit) end, "XPBar") end
    local RefreshXPBarSettings

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, "XP Bar Settings")
    local Toggle, BuilderRefresh, panelsToDisable = GUIBuilders.CreateEnableToggle(LayoutContainer, "Enable " .. STYLE.Palette.SelectedText .. "XP Bar|r", XPBarDB, UpdateXPBar, {width = STYLE.Widths.Pct33})

    local MatchParentWidthToggle = AG:Create("CheckBox")
    MatchParentWidthToggle:SetLabel("Match Frame Width")
    MatchParentWidthToggle:SetValue(XPBarDB.MatchParentWidth)
    MatchParentWidthToggle:SetCallback("OnValueChanged", function(_, _, value) XPBarDB.MatchParentWidth = value UpdateXPBar() RefreshXPBarSettings() end)
    MatchParentWidthToggle:SetRelativeWidth(STYLE.Widths.Pct33)
    LayoutContainer:AddChild(MatchParentWidthToggle)
    panelsToDisable[#panelsToDisable + 1] = MatchParentWidthToggle

    local InverseGrowthDirectionToggle = AG:Create("CheckBox")
    InverseGrowthDirectionToggle:SetLabel("Inverse Growth Direction")
    InverseGrowthDirectionToggle:SetValue(XPBarDB.Inverse)
    InverseGrowthDirectionToggle:SetCallback("OnValueChanged", function(_, _, value) XPBarDB.Inverse = value UpdateXPBar() end)
    InverseGrowthDirectionToggle:SetRelativeWidth(STYLE.Widths.Pct33)
    LayoutContainer:AddChild(InverseGrowthDirectionToggle)
    panelsToDisable[#panelsToDisable + 1] = InverseGrowthDirectionToggle

    local WidthSlider = GUIBuilders.CreateSlider(LayoutContainer, "Width", XPBarDB, "Width", UpdateXPBar, {sliderValues = STYLE.Sliders.Dimension, width = STYLE.Widths.Pct50})

    local HeightSlider = GUIBuilders.CreateSlider(LayoutContainer, "Height", XPBarDB, "Height", UpdateXPBar, {sliderValues = STYLE.Sliders.Dimension, width = STYLE.Widths.Pct50})
    panelsToDisable[#panelsToDisable + 1] = HeightSlider

    local _, XPosSlider, YPosSlider, _, AnchorFromDropdown, AnchorToDropdown = GUIBuilders.CreateLayoutPositionBlock(nil, XPBarDB, UpdateXPBar, {container = LayoutContainer, xyWidth = STYLE.Widths.Pct33})
    panelsToDisable[#panelsToDisable + 1] = AnchorFromDropdown
    panelsToDisable[#panelsToDisable + 1] = AnchorToDropdown
    panelsToDisable[#panelsToDisable + 1] = XPosSlider
    panelsToDisable[#panelsToDisable + 1] = YPosSlider

    local FrameStrataDropdown = GUIBuilders.CreateDropdown(LayoutContainer, "Frame Strata", XPBarDB, "FrameStrata", UpdateXPBar, {list = FrameStrataList[1], order = FrameStrataList[2], width = STYLE.Widths.Pct33})
    panelsToDisable[#panelsToDisable + 1] = FrameStrataDropdown

    local ColorContainer = GUIWidgets.CreateInlineGroup(containerParent, "Colors & Toggles")
    local ForegroundColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Foreground", XPBarDB, "Foreground", UpdateXPBar, {hasAlpha = true, width = STYLE.Widths.Pct50})
    panelsToDisable[#panelsToDisable + 1] = ForegroundColorPicker
    local BackgroundColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Background", XPBarDB, "Background", UpdateXPBar, {hasAlpha = true, width = STYLE.Widths.Pct50})
    panelsToDisable[#panelsToDisable + 1] = BackgroundColorPicker

    local _, _, BorderOpacitySlider = GUIBuilders.CreateBorderBlock(ColorContainer, XPBarDB, UpdateXPBar, function() RefreshXPBarSettings() end, panelsToDisable)

    RefreshXPBarSettings = function()
        BuilderRefresh()
        WidthSlider:SetDisabled(not XPBarDB.Enabled or XPBarDB.MatchParentWidth)
        BorderOpacitySlider:SetDisabled(not XPBarDB.Enabled or XPBarDB.BorderThickness == 0)
    end
    Toggle:SetCallback("OnValueChanged", function(_, _, value) XPBarDB.Enabled = value UpdateXPBar() RefreshXPBarSettings() end)

    RefreshXPBarSettings()
end

local function CreatePowerBarSettings(containerParent, unit, updateCallback)
    local FrameDB = GetUnitDB(unit).Frame
    local PowerBarDB = GetUnitDB(unit).PowerBar
    local isGroupPowerBar = unit == "party" or unit == "raid"
    local toggleRelativeWidth = isGroupPowerBar and STYLE.Widths.Pct50 or STYLE.Widths.Pct25
    local RefreshPowerBarGUI

    local function UpdatePowerBarSettings()
        updateCallback()
        if unit == "player" and ZF.PLAYER then
            ZF:UpdateUnitSecondaryPowerBar(ZF.PLAYER, unit)
        end
    end

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, "Power Bar Settings")
    local Toggle, BuilderRefresh, panelsToDisable = GUIBuilders.CreateEnableToggle(LayoutContainer, "Enable " .. STYLE.Palette.SelectedText .. "Power Bar|r", PowerBarDB, UpdatePowerBarSettings, {width = STYLE.Widths.Pct25})
    panelsToDisable[1] = LayoutContainer

    local InverseGrowthDirectionToggle = AG:Create("CheckBox")
    InverseGrowthDirectionToggle:SetLabel("Inverse Growth Direction")
    InverseGrowthDirectionToggle:SetValue(PowerBarDB.Inverse)
    InverseGrowthDirectionToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Inverse = value UpdatePowerBarSettings() end)
    InverseGrowthDirectionToggle:SetRelativeWidth(STYLE.Widths.Pct25)
    LayoutContainer:AddChild(InverseGrowthDirectionToggle)

    local PositionDropdown = AG:Create("Dropdown")
    PositionDropdown:SetList(TopBottomList[1], TopBottomList[2])
    PositionDropdown:SetLabel("Position")
    PositionDropdown:SetValue(ZF:GetConfiguredPowerBarPosition(unit))
    PositionDropdown:SetRelativeWidth(STYLE.Widths.Pct25)
    PositionDropdown:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Position = value UpdatePowerBarSettings() end)
    LayoutContainer:AddChild(PositionDropdown)

    GUIBuilders.CreateSlider(LayoutContainer, "Height", PowerBarDB, "Height", UpdatePowerBarSettings, {sliderValues = {1, FrameDB.Height - 2, 0.1}, width = STYLE.Widths.Pct25})

    local ColorContainer = GUIWidgets.CreateInlineGroup(containerParent, "Colors & Toggles")
    panelsToDisable[2] = ColorContainer

    local SmoothUpdatesToggle = AG:Create("CheckBox")
    SmoothUpdatesToggle:SetLabel("Smooth Updates")
    SmoothUpdatesToggle:SetValue(PowerBarDB.Smooth)
    SmoothUpdatesToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Smooth = value UpdatePowerBarSettings() end)
    SmoothUpdatesToggle:SetRelativeWidth(toggleRelativeWidth)
    ColorContainer:AddChild(SmoothUpdatesToggle)

    local ColorByTypeToggle, ColorByClassToggle

    ColorByTypeToggle = AG:Create("CheckBox")
    ColorByTypeToggle:SetLabel("Color By Type")
    ColorByTypeToggle:SetValue(PowerBarDB.ColorByType)
    ColorByTypeToggle:SetCallback("OnValueChanged", function(_, _, value)
        PowerBarDB.ColorByType = value
        if value then PowerBarDB.ColorByClass = false ColorByClassToggle:SetValue(false) end
        UpdatePowerBarSettings()
        RefreshPowerBarGUI()
    end)
    ColorByTypeToggle:SetRelativeWidth(toggleRelativeWidth)
    ColorContainer:AddChild(ColorByTypeToggle)

    ColorByClassToggle = AG:Create("CheckBox")
    ColorByClassToggle:SetLabel("Color By Class")
    ColorByClassToggle:SetValue(PowerBarDB.ColorByClass)
    ColorByClassToggle:SetCallback("OnValueChanged", function(_, _, value)
        PowerBarDB.ColorByClass = value
        if value then PowerBarDB.ColorByType = false ColorByTypeToggle:SetValue(false) end
        UpdatePowerBarSettings()
        RefreshPowerBarGUI()
    end)
    ColorByClassToggle:SetRelativeWidth(toggleRelativeWidth)
    ColorContainer:AddChild(ColorByClassToggle)

    local ColorBackgroundByTypeToggle = AG:Create("CheckBox")
    ColorBackgroundByTypeToggle:SetLabel("Color Background By Power Type")
    ColorBackgroundByTypeToggle:SetValue(PowerBarDB.ColorBackgroundByType)
    ColorBackgroundByTypeToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.ColorBackgroundByType = value UpdatePowerBarSettings() RefreshPowerBarGUI() end)
    ColorBackgroundByTypeToggle:SetRelativeWidth(toggleRelativeWidth)
    ColorContainer:AddChild(ColorBackgroundByTypeToggle)

    local OnlyShowHealersToggle
    if isGroupPowerBar then
        OnlyShowHealersToggle = AG:Create("CheckBox")
        OnlyShowHealersToggle:SetLabel("Only Show Healer Mana")
        OnlyShowHealersToggle:SetValue(PowerBarDB.OnlyShowHealers or false)
        OnlyShowHealersToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.OnlyShowHealers = value UpdatePowerBarSettings() end)
        OnlyShowHealersToggle:SetRelativeWidth(toggleRelativeWidth)
        ColorContainer:AddChild(OnlyShowHealersToggle)

        local ColorRowBreak = AG:Create("Label")
        ColorRowBreak:SetText("")
        ColorRowBreak:SetFullWidth(true)
        ColorContainer:AddChild(ColorRowBreak)
    end

    local ForegroundColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Foreground Color", PowerBarDB, "Foreground", UpdatePowerBarSettings, {hasAlpha = true, width = STYLE.Widths.Pct33})
    local BackgroundColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Background Color", PowerBarDB, "Background", UpdatePowerBarSettings, {hasAlpha = true, width = STYLE.Widths.Pct33})

    local BackgroundMultiplierSlider = GUIBuilders.CreateSlider(ColorContainer, "Background Multiplier", PowerBarDB, "BackgroundMultiplier", UpdatePowerBarSettings, {sliderValues = STYLE.Sliders.Opacity, width = STYLE.Widths.Pct33, isPercent = true})

    GUIBuilders.CreateColorBlock(ColorContainer, "Border Color", PowerBarDB, "BorderColor", UpdatePowerBarSettings, {width = STYLE.Widths.Pct25})

    local BorderToggle = AG:Create("CheckBox")
    BorderToggle:SetLabel("Border")
    BorderToggle:SetValue(PowerBarDB.BorderThickness > 0)
    BorderToggle:SetRelativeWidth(STYLE.Widths.Pct25)
    BorderToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.BorderThickness = value and 1 or 0 UpdatePowerBarSettings() RefreshPowerBarGUI() end)
    ColorContainer:AddChild(BorderToggle)

    local BorderOpacitySlider = AG:Create("Slider")
    BorderOpacitySlider:SetLabel("Border Opacity")
    BorderOpacitySlider:SetValue(PowerBarDB.BorderOpacity)
    BorderOpacitySlider:SetSliderValues(unpack(STYLE.Sliders.Opacity))
    BorderOpacitySlider:SetRelativeWidth(STYLE.Widths.Pct25)
    BorderOpacitySlider:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.BorderOpacity = value UpdatePowerBarSettings() end)
    BorderOpacitySlider:SetIsPercent(true)

    ColorContainer:AddChild(BorderOpacitySlider)

    RefreshPowerBarGUI = function()
        BuilderRefresh()
        ForegroundColorPicker:SetDisabled(not PowerBarDB.Enabled or PowerBarDB.ColorByClass or PowerBarDB.ColorByType)
        BackgroundColorPicker:SetDisabled(not PowerBarDB.Enabled or PowerBarDB.ColorBackgroundByType)
        BackgroundMultiplierSlider:SetDisabled(not PowerBarDB.Enabled or not PowerBarDB.ColorBackgroundByType)
        BorderOpacitySlider:SetDisabled(not PowerBarDB.Enabled or PowerBarDB.BorderThickness == 0)
    end
    Toggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Enabled = value UpdatePowerBarSettings() RefreshPowerBarGUI() end)

    RefreshPowerBarGUI()
end

local function CreateSecondaryPowerBarSettings(containerParent, unit, updateCallback)
    local FrameDB = GetUnitDB(unit).Frame
    local SecondaryPowerBarDB = GetUnitDB(unit).SecondaryPowerBar
    local RefreshSecondaryPowerBarGUI

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, "Power Bar Settings")
    local Toggle, BuilderRefresh, panelsToDisable = GUIBuilders.CreateEnableToggle(LayoutContainer, "Enable " .. STYLE.Palette.SelectedText .. "Secondary Power Bar|r", SecondaryPowerBarDB, updateCallback, {width = STYLE.Widths.Pct33})
    panelsToDisable[1] = LayoutContainer

    local PositionDropdown = AG:Create("Dropdown")
    PositionDropdown:SetList(TopBottomList[1], TopBottomList[2])
    PositionDropdown:SetLabel("Position")
    PositionDropdown:SetValue(ZF:GetConfiguredSecondaryPowerBarPosition(unit))
    PositionDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
    PositionDropdown:SetCallback("OnValueChanged", function(_, _, value) SecondaryPowerBarDB.Position = value updateCallback() end)
    LayoutContainer:AddChild(PositionDropdown)

    GUIBuilders.CreateSlider(LayoutContainer, "Height", SecondaryPowerBarDB, "Height", updateCallback, {sliderValues = {1, FrameDB.Height - 2, 0.1}, width = STYLE.Widths.Pct33})

    local ColorContainer = GUIWidgets.CreateInlineGroup(containerParent, "Colors & Toggles")
    panelsToDisable[2] = ColorContainer

    local ColorByTypeToggle = AG:Create("CheckBox")
    ColorByTypeToggle:SetLabel("Color By Type")
    ColorByTypeToggle:SetValue(SecondaryPowerBarDB.ColorByType)
    ColorByTypeToggle:SetCallback("OnValueChanged", function(_, _, value) SecondaryPowerBarDB.ColorByType = value updateCallback() RefreshSecondaryPowerBarGUI() end)
    ColorByTypeToggle:SetRelativeWidth(STYLE.Widths.Pct100)
    ColorContainer:AddChild(ColorByTypeToggle)

    local ForegroundColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Foreground Color", SecondaryPowerBarDB, "Foreground", updateCallback, {hasAlpha = true, width = STYLE.Widths.Pct50})
    local BackgroundColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Background Color", SecondaryPowerBarDB, "Background", updateCallback, {hasAlpha = true, width = STYLE.Widths.Pct50})

    local Spacer = AG:Create("Label")
    Spacer:SetText("")
    Spacer:SetRelativeWidth(STYLE.Widths.Pct29)
    ColorContainer:AddChild(Spacer)

    GUIBuilders.CreateColorBlock(ColorContainer, "Border Color", SecondaryPowerBarDB, "BorderColor", updateCallback, {width = STYLE.Widths.Pct25})

    local BorderToggle = AG:Create("CheckBox")
    BorderToggle:SetLabel("Border")
    BorderToggle:SetValue(SecondaryPowerBarDB.BorderThickness > 0)
    BorderToggle:SetRelativeWidth(STYLE.Widths.Pct25)
    BorderToggle:SetCallback("OnValueChanged", function(_, _, value) SecondaryPowerBarDB.BorderThickness = value and 1 or 0 updateCallback() RefreshSecondaryPowerBarGUI() end)
    ColorContainer:AddChild(BorderToggle)

    local BorderOpacitySlider = GUIBuilders.CreateSlider(ColorContainer, "Border Opacity", SecondaryPowerBarDB, "BorderOpacity", updateCallback, {sliderValues = STYLE.Sliders.Opacity, width = STYLE.Widths.Pct25, isPercent = true})

    RefreshSecondaryPowerBarGUI = function()
        BuilderRefresh()
        ForegroundColorPicker:SetDisabled(not SecondaryPowerBarDB.Enabled or SecondaryPowerBarDB.ColorByClass or SecondaryPowerBarDB.ColorByType)
        BackgroundColorPicker:SetDisabled(not SecondaryPowerBarDB.Enabled)
        BorderOpacitySlider:SetDisabled(not SecondaryPowerBarDB.Enabled or SecondaryPowerBarDB.BorderThickness == 0)
    end
    Toggle:SetCallback("OnValueChanged", function(_, _, value) SecondaryPowerBarDB.Enabled = value updateCallback() RefreshSecondaryPowerBarGUI() end)

    RefreshSecondaryPowerBarGUI()
end

local function CreateAlternativePowerBarSettings(containerParent, unit, updateCallback)
    local AlternativePowerBarDB = GetUnitDB(unit).AlternativePowerBar
    local RefreshAlternativePowerBarGUI

    GUIWidgets.CreateInformationTag(containerParent, "The |cFFFFD100Alternative Power Bar|r will display |cFF4080FFMana|r for classes that have an alternative resource.")

    local AlternativePowerBarSettings = GUIWidgets.CreateInlineGroup(containerParent, "Alternative Power Bar Settings")
    local Toggle, BuilderRefresh, panelsToDisable = GUIBuilders.CreateEnableToggle(AlternativePowerBarSettings, "Enable " .. STYLE.Palette.SelectedText .. "Alternative Power Bar|r", AlternativePowerBarDB, updateCallback, {width = STYLE.Widths.Pct50})

    local InverseGrowthDirectionToggle = AG:Create("CheckBox")
    InverseGrowthDirectionToggle:SetLabel("Inverse Growth Direction")
    InverseGrowthDirectionToggle:SetValue(AlternativePowerBarDB.Inverse)
    InverseGrowthDirectionToggle:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Inverse = value updateCallback() end)
    InverseGrowthDirectionToggle:SetRelativeWidth(STYLE.Widths.Pct50)
    AlternativePowerBarSettings:AddChild(InverseGrowthDirectionToggle)
    panelsToDisable[1] = InverseGrowthDirectionToggle

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, "Layout & Positioning")
    panelsToDisable[2] = LayoutContainer

    GUIBuilders.CreateSlider(LayoutContainer, "Width", AlternativePowerBarDB, "Width", updateCallback, {sliderValues = STYLE.Sliders.Dimension, width = STYLE.Widths.Pct50})

    GUIBuilders.CreateSlider(LayoutContainer, "Height", AlternativePowerBarDB, "Height", updateCallback, {sliderValues = STYLE.Sliders.BarHeight, width = STYLE.Widths.Pct50})

    GUIBuilders.CreateLayoutPositionBlock(nil, AlternativePowerBarDB, updateCallback, {container = LayoutContainer})

    local ColorContainer = GUIWidgets.CreateInlineGroup(containerParent, "Colors & Toggles")
    panelsToDisable[3] = ColorContainer

    local ColorByTypeToggle = AG:Create("CheckBox")
    ColorByTypeToggle:SetLabel("Color By Type")
    ColorByTypeToggle:SetValue(AlternativePowerBarDB.ColorByType)
    ColorByTypeToggle:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.ColorByType = value updateCallback() RefreshAlternativePowerBarGUI() end)
    ColorByTypeToggle:SetRelativeWidth(STYLE.Widths.Pct33)
    ColorContainer:AddChild(ColorByTypeToggle)

    local ForegroundColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Foreground Color", AlternativePowerBarDB, "Foreground", updateCallback, {hasAlpha = true, width = STYLE.Widths.Pct33})
    GUIBuilders.CreateColorBlock(ColorContainer, "Background Color", AlternativePowerBarDB, "Background", updateCallback, {hasAlpha = true, width = STYLE.Widths.Pct33})

    local _, _, BorderOpacitySlider = GUIBuilders.CreateBorderBlock(ColorContainer, AlternativePowerBarDB, updateCallback, function() RefreshAlternativePowerBarGUI() end)

    RefreshAlternativePowerBarGUI = function()
        BuilderRefresh()
        ForegroundColorPicker:SetDisabled(not AlternativePowerBarDB.Enabled or AlternativePowerBarDB.ColorByType)
        BorderOpacitySlider:SetDisabled(not AlternativePowerBarDB.Enabled or AlternativePowerBarDB.BorderThickness == 0)
    end
    Toggle:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Enabled = value updateCallback() RefreshAlternativePowerBarGUI() end)

    RefreshAlternativePowerBarGUI()
end

local function CreatePortraitSettings(containerParent, unit, updateCallback)
    local PortraitDB = GetUnitDB(unit).Portrait
    PortraitDB.Style = PortraitDB.Style or "2D"
    local RefreshPortraitGUI

    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, "Portrait Settings")

    GUIWidgets.CreateInformationTag(ToggleContainer, "|cFFFFD1003D Portraits|r will |cFFFF4040NOT|r work in instances, as they are now secret. |cFFFFD1002D Portraits|r will be used as a fallback if this is the case.")

    local Toggle, BuilderRefresh, panelsToDisable = GUIBuilders.CreateEnableToggle(ToggleContainer, "Enable " .. STYLE.Palette.SelectedText .. "Portrait|r", PortraitDB, updateCallback, {width = STYLE.Widths.Pct33})
    panelsToDisable[1] = ToggleContainer

    local UseClassPortraitToggle = AG:Create("CheckBox")
    UseClassPortraitToggle:SetLabel("Use Class Portrait")
    UseClassPortraitToggle:SetValue(PortraitDB.UseClassPortrait)
    UseClassPortraitToggle:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.UseClassPortrait = value updateCallback() end)
    UseClassPortraitToggle:SetRelativeWidth(STYLE.Widths.Pct33)
    ToggleContainer:AddChild(UseClassPortraitToggle)

    local PortraitStyleDropdown = AG:Create("Dropdown")
    PortraitStyleDropdown:SetList({["2D"] = "2D", ["3D"] = "3D"})
    PortraitStyleDropdown:SetLabel("Portrait Style")
    PortraitStyleDropdown:SetValue(PortraitDB.Style)
    PortraitStyleDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
    PortraitStyleDropdown:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Style = value updateCallback() RefreshPortraitGUI() end)
    ToggleContainer:AddChild(PortraitStyleDropdown)

    local LayoutContainer = GUIWidgets.CreateInlineGroup(containerParent, "Layout & Positioning")
    panelsToDisable[2] = LayoutContainer

    GUIBuilders.CreateLayoutPositionBlock(nil, PortraitDB, updateCallback, {container = LayoutContainer, xyWidth = STYLE.Widths.Pct33})

    local ZoomSlider = GUIBuilders.CreateSlider(LayoutContainer, "Zoom", PortraitDB, "Zoom", updateCallback, {sliderValues = STYLE.Sliders.Opacity, width = STYLE.Widths.Pct33, isPercent = true})

    GUIBuilders.CreateSlider(LayoutContainer, "Width", PortraitDB, "Width", updateCallback, {sliderValues = STYLE.Sliders.PortraitSize, width = STYLE.Widths.Pct50})

    GUIBuilders.CreateSlider(LayoutContainer, "Height", PortraitDB, "Height", updateCallback, {sliderValues = STYLE.Sliders.PortraitSize, width = STYLE.Widths.Pct50})

    local BorderContainer = GUIWidgets.CreateInlineGroup(containerParent, "Border")
    panelsToDisable[3] = BorderContainer

    local _, _, BorderOpacitySlider = GUIBuilders.CreateBorderBlock(BorderContainer, PortraitDB, updateCallback, function() RefreshPortraitGUI() end)

    RefreshPortraitGUI = function()
        BuilderRefresh()
        UseClassPortraitToggle:SetDisabled(not PortraitDB.Enabled or PortraitDB.Style ~= "2D")
        ZoomSlider:SetDisabled(not PortraitDB.Enabled or PortraitDB.Style ~= "2D")
        BorderOpacitySlider:SetDisabled(not PortraitDB.Enabled or PortraitDB.BorderThickness == 0)
    end
    Toggle:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Enabled = value updateCallback() RefreshPortraitGUI() end)

    RefreshPortraitGUI()
end

GUIInternal.CreateHealPredictionSettings = CreateHealPredictionSettings
GUIInternal.CreateCastBarSettings = CreateCastBarSettings
GUIInternal.CreateXPBarSettings = CreateXPBarSettings
GUIInternal.CreatePowerBarSettings = CreatePowerBarSettings
GUIInternal.CreateSecondaryPowerBarSettings = CreateSecondaryPowerBarSettings
GUIInternal.CreateAlternativePowerBarSettings = CreateAlternativePowerBarSettings
GUIInternal.CreatePortraitSettings = CreatePortraitSettings
