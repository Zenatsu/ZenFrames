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
local AnchorPoints = GUIInternal.AnchorPoints
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

    local HeightSlider = AG:Create("Slider")
    HeightSlider:SetLabel("Height")
    HeightSlider:SetValue(subDB.Height)
    HeightSlider:SetSliderValues(1, FrameDB.Height - 2, 0.1)
    HeightSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    HeightSlider:SetCallback("OnValueChanged", function(_, _, value) subDB.Height = value updateCallback() end)
    Panel:AddChild(HeightSlider)

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

    local WidthSlider = AG:Create("Slider")
    WidthSlider:SetLabel("Width")
    WidthSlider:SetValue(CastBarDB.Width)
    WidthSlider:SetSliderValues(unpack(STYLE.Sliders.Dimension))
    WidthSlider:SetRelativeWidth(STYLE.Widths.Pct50)
    WidthSlider:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Width = value updateCallback() end)
    LayoutContainer:AddChild(WidthSlider)

    local HeightSlider = AG:Create("Slider")
    HeightSlider:SetLabel("Height")
    HeightSlider:SetValue(CastBarDB.Height)
    HeightSlider:SetSliderValues(unpack(STYLE.Sliders.Dimension))
    HeightSlider:SetRelativeWidth(STYLE.Widths.Pct50)
    HeightSlider:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Height = value updateCallback() end)
    LayoutContainer:AddChild(HeightSlider)
    panelsToDisable[#panelsToDisable + 1] = HeightSlider

    local HoldTimeSlider = AG:Create("Slider")
    HoldTimeSlider:SetLabel("Interrupted/Failed Hold Time")
    HoldTimeSlider:SetValue(CastBarDB.HoldTime)
    HoldTimeSlider:SetSliderValues(unpack(STYLE.Sliders.HoldTime))
    HoldTimeSlider:SetRelativeWidth(STYLE.Widths.Pct100)
    HoldTimeSlider:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.HoldTime = value updateCallback() end)
    LayoutContainer:AddChild(HoldTimeSlider)
    panelsToDisable[#panelsToDisable + 1] = HoldTimeSlider

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel("Anchor From")
    AnchorFromDropdown:SetValue(CastBarDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)
    panelsToDisable[#panelsToDisable + 1] = AnchorFromDropdown

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel("Anchor To")
    AnchorToDropdown:SetValue(CastBarDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)
    panelsToDisable[#panelsToDisable + 1] = AnchorToDropdown

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel("X Position")
    XPosSlider:SetValue(CastBarDB.Layout[3])
    XPosSlider:SetSliderValues(unpack(STYLE.Sliders.Position))
    XPosSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)
    panelsToDisable[#panelsToDisable + 1] = XPosSlider

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel("Y Position")
    YPosSlider:SetValue(CastBarDB.Layout[4])
    YPosSlider:SetSliderValues(unpack(STYLE.Sliders.Position))
    YPosSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)
    panelsToDisable[#panelsToDisable + 1] = YPosSlider

    local FrameStrataDropdown = AG:Create("Dropdown")
    FrameStrataDropdown:SetList(FrameStrataList[1], FrameStrataList[2])
    FrameStrataDropdown:SetLabel("Frame Strata")
    FrameStrataDropdown:SetValue(CastBarDB.FrameStrata)
    FrameStrataDropdown:SetRelativeWidth(STYLE.Widths.Pct33)
    FrameStrataDropdown:SetCallback("OnValueChanged", function(_, _, value) CastBarDB.FrameStrata = value updateCallback() end)
    LayoutContainer:AddChild(FrameStrataDropdown)

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

    RefreshCastBarBarSettings = function()
        BuilderRefresh()
        WidthSlider:SetDisabled(not CastBarDB.Enabled or CastBarDB.MatchParentWidth)
        ForegroundColorPicker:SetDisabled(not CastBarDB.Enabled or CastBarDB.ColorByClass)
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

    local MaxCharsSlider = AG:Create("Slider")
    MaxCharsSlider:SetLabel("Max Characters")
    MaxCharsSlider:SetValue(SpellNameTextDB.MaxChars)
    MaxCharsSlider:SetSliderValues(unpack(STYLE.Sliders.MaxChars))
    MaxCharsSlider:SetRelativeWidth(STYLE.Widths.Pct25)
    MaxCharsSlider:SetCallback("OnValueChanged", function(_, _, value) SpellNameTextDB.MaxChars = value updateCallback() end)
    SpellNameLayoutContainer:AddChild(MaxCharsSlider)

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

    local HeightSlider = AG:Create("Slider")
    HeightSlider:SetLabel("Height")
    HeightSlider:SetValue(PowerBarDB.Height)
    HeightSlider:SetSliderValues(1, FrameDB.Height - 2, 0.1)
    HeightSlider:SetRelativeWidth(STYLE.Widths.Pct25)
    HeightSlider:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Height = value UpdatePowerBarSettings() end)
    LayoutContainer:AddChild(HeightSlider)

    local ColorContainer = GUIWidgets.CreateInlineGroup(containerParent, "Colors & Toggles")
    panelsToDisable[2] = ColorContainer

    local SmoothUpdatesToggle = AG:Create("CheckBox")
    SmoothUpdatesToggle:SetLabel("Smooth Updates")
    SmoothUpdatesToggle:SetValue(PowerBarDB.Smooth)
    SmoothUpdatesToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.Smooth = value UpdatePowerBarSettings() end)
    SmoothUpdatesToggle:SetRelativeWidth(toggleRelativeWidth)
    ColorContainer:AddChild(SmoothUpdatesToggle)

    local ColorByTypeToggle = AG:Create("CheckBox")
    ColorByTypeToggle:SetLabel("Color By Type")
    ColorByTypeToggle:SetValue(PowerBarDB.ColorByType)
    ColorByTypeToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.ColorByType = value UpdatePowerBarSettings() RefreshPowerBarGUI() end)
    ColorByTypeToggle:SetRelativeWidth(toggleRelativeWidth)
    ColorContainer:AddChild(ColorByTypeToggle)

    local ColorByClassToggle = AG:Create("CheckBox")
    ColorByClassToggle:SetLabel("Color By Class")
    ColorByClassToggle:SetValue(PowerBarDB.ColorByClass)
    ColorByClassToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.ColorByClass = value UpdatePowerBarSettings() RefreshPowerBarGUI() end)
    ColorByClassToggle:SetRelativeWidth(toggleRelativeWidth)
    ColorContainer:AddChild(ColorByClassToggle)

    local ColorBackgroundByTypeToggle = AG:Create("CheckBox")
    ColorBackgroundByTypeToggle:SetLabel("Color Background By Power Type")
    ColorBackgroundByTypeToggle:SetValue(PowerBarDB.ColorBackgroundByType)
    ColorBackgroundByTypeToggle:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.ColorBackgroundByType = value UpdatePowerBarSettings() RefreshPowerBarGUI() end)
    ColorBackgroundByTypeToggle:SetRelativeWidth(toggleRelativeWidth)
    ColorBackgroundByTypeToggle:SetDisabled(true)
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

    local BackgroundMultiplierSlider = AG:Create("Slider")
    BackgroundMultiplierSlider:SetLabel("Background Multiplier")
    BackgroundMultiplierSlider:SetValue(PowerBarDB.BackgroundMultiplier)
    BackgroundMultiplierSlider:SetSliderValues(unpack(STYLE.Sliders.Opacity))
    BackgroundMultiplierSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    BackgroundMultiplierSlider:SetCallback("OnValueChanged", function(_, _, value) PowerBarDB.BackgroundMultiplier = value UpdatePowerBarSettings() end)
    BackgroundMultiplierSlider:SetIsPercent(true)
    ColorContainer:AddChild(BackgroundMultiplierSlider)

    RefreshPowerBarGUI = function()
        BuilderRefresh()
        ForegroundColorPicker:SetDisabled(not PowerBarDB.Enabled or PowerBarDB.ColorByClass or PowerBarDB.ColorByType)
        BackgroundColorPicker:SetDisabled(not PowerBarDB.Enabled or PowerBarDB.ColorBackgroundByType)
        BackgroundMultiplierSlider:SetDisabled(not PowerBarDB.Enabled or not PowerBarDB.ColorBackgroundByType)
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

    local HeightSlider = AG:Create("Slider")
    HeightSlider:SetLabel("Height")
    HeightSlider:SetValue(SecondaryPowerBarDB.Height)
    HeightSlider:SetSliderValues(1, FrameDB.Height - 2, 0.1)
    HeightSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    HeightSlider:SetCallback("OnValueChanged", function(_, _, value) SecondaryPowerBarDB.Height = value updateCallback() end)
    LayoutContainer:AddChild(HeightSlider)

    local ColorContainer = GUIWidgets.CreateInlineGroup(containerParent, "Colors & Toggles")
    panelsToDisable[2] = ColorContainer

    local ColorByTypeToggle = AG:Create("CheckBox")
    ColorByTypeToggle:SetLabel("Color By Type")
    ColorByTypeToggle:SetValue(SecondaryPowerBarDB.ColorByType)
    ColorByTypeToggle:SetCallback("OnValueChanged", function(_, _, value) SecondaryPowerBarDB.ColorByType = value updateCallback() RefreshSecondaryPowerBarGUI() end)
    ColorByTypeToggle:SetRelativeWidth(STYLE.Widths.Pct100)
    ColorContainer:AddChild(ColorByTypeToggle)

    local ForegroundColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Foreground Color", SecondaryPowerBarDB, "Foreground", updateCallback, {hasAlpha = true, width = STYLE.Widths.Pct50})
    GUIBuilders.CreateColorBlock(ColorContainer, "Background Color", SecondaryPowerBarDB, "Background", updateCallback, {hasAlpha = true, width = STYLE.Widths.Pct50})

    RefreshSecondaryPowerBarGUI = function()
        BuilderRefresh()
        ForegroundColorPicker:SetDisabled(not SecondaryPowerBarDB.Enabled or SecondaryPowerBarDB.ColorByClass or SecondaryPowerBarDB.ColorByType)
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

    local WidthSlider = AG:Create("Slider")
    WidthSlider:SetLabel("Width")
    WidthSlider:SetValue(AlternativePowerBarDB.Width)
    WidthSlider:SetSliderValues(unpack(STYLE.Sliders.Dimension))
    WidthSlider:SetRelativeWidth(STYLE.Widths.Pct50)
    WidthSlider:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Width = value updateCallback() end)
    LayoutContainer:AddChild(WidthSlider)

    local HeightSlider = AG:Create("Slider")
    HeightSlider:SetLabel("Height")
    HeightSlider:SetValue(AlternativePowerBarDB.Height)
    HeightSlider:SetSliderValues(unpack(STYLE.Sliders.BarHeight))
    HeightSlider:SetRelativeWidth(STYLE.Widths.Pct50)
    HeightSlider:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Height = value updateCallback() end)
    LayoutContainer:AddChild(HeightSlider)

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel("Anchor From")
    AnchorFromDropdown:SetValue(AlternativePowerBarDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel("Anchor To")
    AnchorToDropdown:SetValue(AlternativePowerBarDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel("X Position")
    XPosSlider:SetValue(AlternativePowerBarDB.Layout[3])
    XPosSlider:SetSliderValues(unpack(STYLE.Sliders.Position))
    XPosSlider:SetRelativeWidth(STYLE.Widths.Pct50)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel("Y Position")
    YPosSlider:SetValue(AlternativePowerBarDB.Layout[4])
    YPosSlider:SetSliderValues(unpack(STYLE.Sliders.Position))
    YPosSlider:SetRelativeWidth(STYLE.Widths.Pct50)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) AlternativePowerBarDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

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

    RefreshAlternativePowerBarGUI = function()
        BuilderRefresh()
        ForegroundColorPicker:SetDisabled(not AlternativePowerBarDB.Enabled or AlternativePowerBarDB.ColorByType)
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

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorFromDropdown:SetLabel("Anchor From")
    AnchorFromDropdown:SetValue(PortraitDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Layout[1] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(AnchorPoints[1], AnchorPoints[2])
    AnchorToDropdown:SetLabel("Anchor To")
    AnchorToDropdown:SetValue(PortraitDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Layout[2] = value updateCallback() end)
    LayoutContainer:AddChild(AnchorToDropdown)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel("X Position")
    XPosSlider:SetValue(PortraitDB.Layout[3])
    XPosSlider:SetSliderValues(unpack(STYLE.Sliders.Position))
    XPosSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Layout[3] = value updateCallback() end)
    LayoutContainer:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel("Y Position")
    YPosSlider:SetValue(PortraitDB.Layout[4])
    YPosSlider:SetSliderValues(unpack(STYLE.Sliders.Position))
    YPosSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Layout[4] = value updateCallback() end)
    LayoutContainer:AddChild(YPosSlider)

    local ZoomSlider = AG:Create("Slider")
    ZoomSlider:SetLabel("Zoom")
    ZoomSlider:SetValue(PortraitDB.Zoom)
    ZoomSlider:SetSliderValues(unpack(STYLE.Sliders.Opacity))
    ZoomSlider:SetRelativeWidth(STYLE.Widths.Pct33)
    ZoomSlider:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Zoom = value updateCallback() end)
    ZoomSlider:SetIsPercent(true)
    LayoutContainer:AddChild(ZoomSlider)

    local WidthSlider = AG:Create("Slider")
    WidthSlider:SetLabel("Width")
    WidthSlider:SetValue(PortraitDB.Width)
    WidthSlider:SetSliderValues(unpack(STYLE.Sliders.PortraitSize))
    WidthSlider:SetRelativeWidth(STYLE.Widths.Pct50)
    WidthSlider:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Width = value updateCallback() end)
    LayoutContainer:AddChild(WidthSlider)

    local HeightSlider = AG:Create("Slider")
    HeightSlider:SetLabel("Height")
    HeightSlider:SetValue(PortraitDB.Height)
    HeightSlider:SetSliderValues(unpack(STYLE.Sliders.PortraitSize))
    HeightSlider:SetRelativeWidth(STYLE.Widths.Pct50)
    HeightSlider:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Height = value updateCallback() end)
    LayoutContainer:AddChild(HeightSlider)

    RefreshPortraitGUI = function()
        BuilderRefresh()
        UseClassPortraitToggle:SetDisabled(not PortraitDB.Enabled or PortraitDB.Style ~= "2D")
        ZoomSlider:SetDisabled(not PortraitDB.Enabled or PortraitDB.Style ~= "2D")
    end
    Toggle:SetCallback("OnValueChanged", function(_, _, value) PortraitDB.Enabled = value updateCallback() RefreshPortraitGUI() end)

    RefreshPortraitGUI()
end

GUIInternal.CreateHealPredictionSettings = CreateHealPredictionSettings
GUIInternal.CreateCastBarSettings = CreateCastBarSettings
GUIInternal.CreatePowerBarSettings = CreatePowerBarSettings
GUIInternal.CreateSecondaryPowerBarSettings = CreateSecondaryPowerBarSettings
GUIInternal.CreateAlternativePowerBarSettings = CreateAlternativePowerBarSettings
GUIInternal.CreatePortraitSettings = CreatePortraitSettings
