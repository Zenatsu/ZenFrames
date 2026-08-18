local _, ZF = ...
local AG = ZF.AG
local GUIWidgets = ZF.GUIWidgets
local GUIBuilders = ZF.GUIBuilders
local STYLE = ZF.DesignerStyle
local GUIInternal = ZF.GUIInternal
local LSM = ZF.LSM
local GetUnitDB = GUIInternal.GetUnitDB
local UnitDBToUnitPrettyName = GUIInternal.UnitDBToUnitPrettyName
local CreateDesignerPreviewToggle = GUIInternal.CreateDesignerPreviewToggle
local Power = GUIInternal.Power
local Reaction = GUIInternal.Reaction
local Status = GUIInternal.Status
local Threat = GUIInternal.Threat

local function CreateFontSettings(containerParent)
    local FontContainer = GUIWidgets.CreateInlineGroup(containerParent, "Fonts")

    GUIWidgets.CreateInformationTag(FontContainer, "Fonts are applied to all Unit Frames & Elements where appropriate. More fonts can be added via |cFFFFD100SharedMedia|r.")

    local function RefreshFontsAndTags()
        ZF:ResolveLSM()
        ZF:UpdateAllUnitFrames()
        ZF:ForEachUnitDB(function(_, unit) ZF:UpdateUnitTags(unit) end)
    end

    local FontDropdown = AG:Create("LSM30_Font")
    FontDropdown:SetList(LSM:HashTable("font"))
    FontDropdown:SetLabel("Font")
    FontDropdown:SetValue(ZF.db.profile.General.Fonts.Font)
    FontDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
	FontDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) ZF.db.profile.General.Fonts.Font = value RefreshFontsAndTags() end)
    FontContainer:AddChild(FontDropdown)

    local FontFlagDropdown = AG:Create("Dropdown")
    FontFlagDropdown:SetList({[""] = "None", ["OUTLINE"] = "Outline", ["THICKOUTLINE"] = "Thick Outline", ["MONOCHROME"] = "Monochrome", ["MONOCHROMEOUTLINE"] = "Monochrome Outline", ["MONOCHROMETHICKOUTLINE"] = "Monochrome Thick Outline", ["OUTLINE, SLUG"] = "Outline Slug"})
    FontFlagDropdown:SetLabel("Font Flag")
    FontFlagDropdown:SetValue(ZF.db.profile.General.Fonts.FontFlag)
    FontFlagDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
	FontFlagDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) ZF.db.profile.General.Fonts.FontFlag = value RefreshFontsAndTags() end)
    FontContainer:AddChild(FontFlagDropdown)

    local SimpleGroup = AG:Create("SimpleGroup")
    SimpleGroup:SetFullWidth(true)
    SimpleGroup:SetLayout("Flow")
    FontContainer:AddChild(SimpleGroup)

    GUIWidgets.CreateHeader(SimpleGroup, "Font Shadows")

    local _, Refresh, panelsToDisable = GUIBuilders.CreateEnableToggle(SimpleGroup, "Enable Font Shadows", ZF.db.profile.General.Fonts.Shadow, RefreshFontsAndTags, {width = STYLE.Widths.Pct50})
    panelsToDisable[1] = SimpleGroup

    GUIBuilders.CreateColorBlock(SimpleGroup, "Color", ZF.db.profile.General.Fonts.Shadow, "Color", RefreshFontsAndTags, {hasAlpha = true, width = STYLE.Widths.Pct50})
    GUIBuilders.CreateSlider(SimpleGroup, "Offset X", ZF.db.profile.General.Fonts.Shadow, "XPos", RefreshFontsAndTags, {sliderValues = STYLE.Sliders.ShadowOffset, width = STYLE.Widths.Pct50})
    GUIBuilders.CreateSlider(SimpleGroup, "Offset Y", ZF.db.profile.General.Fonts.Shadow, "YPos", RefreshFontsAndTags, {sliderValues = STYLE.Sliders.ShadowOffset, width = STYLE.Widths.Pct50})

    Refresh()
end

local function CreateTextureSettings(containerParent)
    local TextureContainer = GUIWidgets.CreateInlineGroup(containerParent, "Textures")

    GUIWidgets.CreateInformationTag(TextureContainer,"Textures are applied to all Unit Frames & Elements where appropriate. More textures can be added via |cFFFFD100SharedMedia|r.")

    local ForegroundTextureDropdown = AG:Create("LSM30_Statusbar")
    ForegroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    ForegroundTextureDropdown:SetLabel("Foreground Texture")
    ForegroundTextureDropdown:SetValue(ZF.db.profile.General.Textures.Foreground)
    ForegroundTextureDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    ForegroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) ZF.db.profile.General.Textures.Foreground = value ZF:ResolveLSM() ZF:UpdateAllUnitFrames() end)
    TextureContainer:AddChild(ForegroundTextureDropdown)

    local BackgroundTextureDropdown = AG:Create("LSM30_Statusbar")
    BackgroundTextureDropdown:SetList(LSM:HashTable("statusbar"))
    BackgroundTextureDropdown:SetLabel("Background Texture")
    BackgroundTextureDropdown:SetValue(ZF.db.profile.General.Textures.Background)
    BackgroundTextureDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    BackgroundTextureDropdown:SetCallback("OnValueChanged", function(widget, _, value) widget:SetValue(value) ZF.db.profile.General.Textures.Background = value ZF:ResolveLSM() ZF:UpdateAllUnitFrames() end)
    TextureContainer:AddChild(BackgroundTextureDropdown)

    local MouseoverStyleDropdown = AG:Create("Dropdown")
    MouseoverStyleDropdown:SetList({["SELECT"] = "Set a Highlight Texture...", ["BORDER"] = "Border", ["OVERLAY"] = "Overlay", ["GRADIENT"] = "Gradient" })
    MouseoverStyleDropdown:SetLabel("Highlight Style")
    MouseoverStyleDropdown:SetValue("SELECT")
    MouseoverStyleDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    MouseoverStyleDropdown:SetCallback("OnValueChanged", function(_, _, value) ZF:ForEachUnitDB(function(unitDB) if unitDB.Indicators.Mouseover and unitDB.Indicators.Mouseover.Enabled then unitDB.Indicators.Mouseover.Style = value end end) ZF:UpdateAllUnitFrames() MouseoverStyleDropdown:SetValue("SELECT") end)
    MouseoverStyleDropdown:SetCallback("OnEnter", function() GameTooltip:SetOwner(MouseoverStyleDropdown.frame, "ANCHOR_BOTTOM") GameTooltip:AddLine("Set |cFFFFD100Mouseover Highlight Style|r for all units. |cFFFFD100Color|r & |cFFFFD100Alpha|r can be adjusted per unit.", 1, 1, 1) GameTooltip:Show() end)
    MouseoverStyleDropdown:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    TextureContainer:AddChild(MouseoverStyleDropdown)

    local MouseoverHighlightSlider = AG:Create("Slider")
    MouseoverHighlightSlider:SetLabel("Highlight Opacity")
    MouseoverHighlightSlider:SetValue(0.8)
    MouseoverHighlightSlider:SetSliderValues(unpack(STYLE.Sliders.Opacity))
    MouseoverHighlightSlider:SetRelativeWidth(STYLE.Widths.Pct50)
    MouseoverHighlightSlider:SetIsPercent(true)
    MouseoverHighlightSlider:SetCallback("OnValueChanged", function(_, _, value) ZF:ForEachUnitDB(function(unitDB) if unitDB.Indicators.Mouseover and unitDB.Indicators.Mouseover.Enabled then unitDB.Indicators.Mouseover.HighlightOpacity = value end end) ZF:UpdateAllUnitFrames() end)
    TextureContainer:AddChild(MouseoverHighlightSlider)

    local ForegroundColorPicker = AG:Create("ColorPicker")
    ForegroundColorPicker:SetLabel("Foreground Color")
    ForegroundColorPicker:SetColor(8/255, 8/255, 8/255)
    ForegroundColorPicker:SetRelativeWidth(STYLE.Widths.Pct50)
    ForegroundColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) ZF:ForEachUnitDB(function(unitDB) unitDB.HealthBar.Foreground = {r, g, b} end) ZF:UpdateAllUnitFrames() end)
    TextureContainer:AddChild(ForegroundColorPicker)

    local ForegroundOpacitySlider = AG:Create("Slider")
    ForegroundOpacitySlider:SetLabel("Foreground Opacity")
    ForegroundOpacitySlider:SetValue(0.8)
    ForegroundOpacitySlider:SetSliderValues(unpack(STYLE.Sliders.Opacity))
    ForegroundOpacitySlider:SetRelativeWidth(STYLE.Widths.Pct50)
    ForegroundOpacitySlider:SetIsPercent(true)
    ForegroundOpacitySlider:SetCallback("OnValueChanged", function(_, _, value) ZF:ForEachUnitDB(function(unitDB) unitDB.HealthBar.ForegroundOpacity = value end) ZF:UpdateAllUnitFrames() end)
    TextureContainer:AddChild(ForegroundOpacitySlider)

    local BackgroundColorPicker = AG:Create("ColorPicker")
    BackgroundColorPicker:SetLabel("Background Color")
    BackgroundColorPicker:SetColor(8/255, 8/255, 8/255)
    BackgroundColorPicker:SetRelativeWidth(STYLE.Widths.Pct50)
    BackgroundColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) ZF:ForEachUnitDB(function(unitDB) unitDB.HealthBar.Background = {r, g, b} end) ZF:UpdateAllUnitFrames() end)
    TextureContainer:AddChild(BackgroundColorPicker)

    local BackgroundOpacitySlider = AG:Create("Slider")
    BackgroundOpacitySlider:SetLabel("Background Opacity")
    BackgroundOpacitySlider:SetValue(0.8)
    BackgroundOpacitySlider:SetSliderValues(unpack(STYLE.Sliders.Opacity))
    BackgroundOpacitySlider:SetRelativeWidth(STYLE.Widths.Pct50)
    BackgroundOpacitySlider:SetIsPercent(true)
    BackgroundOpacitySlider:SetCallback("OnValueChanged", function(_, _, value) ZF:ForEachUnitDB(function(unitDB) unitDB.HealthBar.BackgroundOpacity = value end) ZF:UpdateAllUnitFrames() end)
    TextureContainer:AddChild(BackgroundOpacitySlider)

    local CastBarContainer = GUIWidgets.CreateInlineGroup(TextureContainer, "Cast Bar")

    local CastBarForegroundColorPicker = AG:Create("ColorPicker")
    CastBarForegroundColorPicker:SetLabel("Foreground Color")
    CastBarForegroundColorPicker:SetColor(128/255, 128/255, 255/255)
    CastBarForegroundColorPicker:SetRelativeWidth(STYLE.Widths.Pct25)
    CastBarForegroundColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) ZF:ForEachUnitDB(function(unitDB) if unitDB.CastBar then unitDB.CastBar.Foreground = {r, g, b} end end) ZF:UpdateAllUnitFrames() end)
    CastBarContainer:AddChild(CastBarForegroundColorPicker)

    local CastBarBackgroundColorPicker = AG:Create("ColorPicker")
    CastBarBackgroundColorPicker:SetLabel("Background Color")
    CastBarBackgroundColorPicker:SetColor(34/255, 34/255, 34/255)
    CastBarBackgroundColorPicker:SetRelativeWidth(STYLE.Widths.Pct25)
    CastBarBackgroundColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) ZF:ForEachUnitDB(function(unitDB) if unitDB.CastBar then unitDB.CastBar.Background = {r, g, b} end end) ZF:UpdateAllUnitFrames() end)
    CastBarContainer:AddChild(CastBarBackgroundColorPicker)

    local CastBarNotInterruptibleColorPicker = AG:Create("ColorPicker")
    CastBarNotInterruptibleColorPicker:SetLabel("Not Interruptible Color")
    CastBarNotInterruptibleColorPicker:SetColor(255/255, 64/255, 64/255)
    CastBarNotInterruptibleColorPicker:SetRelativeWidth(STYLE.Widths.Pct25)
    CastBarNotInterruptibleColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) ZF:ForEachUnitDB(function(unitDB) if unitDB.CastBar then unitDB.CastBar.NotInterruptibleColor = {r, g, b} end end) ZF:UpdateAllUnitFrames() end)
    CastBarContainer:AddChild(CastBarNotInterruptibleColorPicker)

    local CastBarInterruptCooldownColorPicker = AG:Create("ColorPicker")
    CastBarInterruptCooldownColorPicker:SetLabel("Interrupt on Cooldown Color")
    CastBarInterruptCooldownColorPicker:SetColor(204/255, 204/255, 204/255)
    CastBarInterruptCooldownColorPicker:SetRelativeWidth(STYLE.Widths.Pct25)
    CastBarInterruptCooldownColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) ZF:ForEachUnitDB(function(unitDB) if unitDB.CastBar then unitDB.CastBar.InterruptCooldownColor = {r, g, b} end end) ZF:UpdateAllUnitFrames() end)
    CastBarContainer:AddChild(CastBarInterruptCooldownColorPicker)
end

local function CreateRangeSettings(containerParent)
    local RangeDB = ZF.db.profile.General.Range
    local RangeContainer = GUIWidgets.CreateInlineGroup(containerParent, "Range")

    local function RefreshRangeFrames() ZF:UpdateAllRangeFrames() end

    local _, Refresh, panelsToDisable = GUIBuilders.CreateEnableToggle(RangeContainer, "Enable Range Fading", RangeDB, RefreshRangeFrames, {width = STYLE.Widths.Pct33})
    panelsToDisable[1] = RangeContainer

    GUIBuilders.CreateSlider(RangeContainer, "In Range Alpha", RangeDB, "InRange", RefreshRangeFrames, {sliderValues = STYLE.Sliders.Opacity, isPercent = true, width = STYLE.Widths.Pct33})
    GUIBuilders.CreateSlider(RangeContainer, "Out of Range Alpha", RangeDB, "OutOfRange", RefreshRangeFrames, {sliderValues = STYLE.Sliders.Opacity, isPercent = true, width = STYLE.Widths.Pct33})

    Refresh()
end

local function CreateColorSettings(containerParent)
    local ColorsContainer = GUIWidgets.CreateInlineGroup(containerParent, "Colors")
    ZF.db.profile.General.Colors.Status = ZF.db.profile.General.Colors.Status or {}
    for statusType, color in pairs(ZF:GetDefaultDB().profile.General.Colors.Status) do
        ZF.db.profile.General.Colors.Status[statusType] = ZF.db.profile.General.Colors.Status[statusType] or {color[1], color[2], color[3]}
    end
    ZF.db.profile.General.Colors.Threat = ZF.db.profile.General.Colors.Threat or {}
    for threatStatus, color in pairs(ZF:GetDefaultDB().profile.General.Colors.Threat) do
        ZF.db.profile.General.Colors.Threat[threatStatus] = ZF.db.profile.General.Colors.Threat[threatStatus] or {color[1], color[2], color[3]}
    end

    local function PopulateColors()
        ColorsContainer:ReleaseChildren()

        local function UpdateColors()
            ZF:LoadCustomColors()
            ZF:UpdateAllUnitFrames()
        end

        GUIWidgets.CreateInformationTag(ColorsContainer,"Buttons below will reset the colors to their default values as defined by " .. ZF.PRETTY_ADDON_NAME .. ".")

        local ResetAllColorsButton = AG:Create("Button")
        ResetAllColorsButton:SetText("All Colors")
        ResetAllColorsButton:SetCallback("OnClick", function() ZF:CopyTable(ZF:GetDefaultDB().profile.General.Colors, ZF.db.profile.General.Colors) ZF:LoadCustomColors() ZF:UpdateAllUnitFrames() PopulateColors() end)
        ResetAllColorsButton:SetRelativeWidth(STYLE.Widths.Pct100)
        ColorsContainer:AddChild(ResetAllColorsButton)

        local ResetPowerColorsButton = AG:Create("Button")
        ResetPowerColorsButton:SetText("Power Colors")
        ResetPowerColorsButton:SetCallback("OnClick", function() ZF:CopyTable(ZF:GetDefaultDB().profile.General.Colors.Power, ZF.db.profile.General.Colors.Power) PopulateColors() end)
        ResetPowerColorsButton:SetRelativeWidth(STYLE.Widths.Pct33)
        ColorsContainer:AddChild(ResetPowerColorsButton)

        local ResetSecondaryPowerColorsButton = AG:Create("Button")
        ResetSecondaryPowerColorsButton:SetText("Secondary Power Colors")
        ResetSecondaryPowerColorsButton:SetCallback("OnClick", function() ZF:CopyTable(ZF:GetDefaultDB().profile.General.Colors.SecondaryPower, ZF.db.profile.General.Colors.SecondaryPower) PopulateColors() end)
        ResetSecondaryPowerColorsButton:SetRelativeWidth(STYLE.Widths.Pct33)
        ColorsContainer:AddChild(ResetSecondaryPowerColorsButton)

        local ResetReactionColorsButton = AG:Create("Button")
        ResetReactionColorsButton:SetText("Reaction Colors")
        ResetReactionColorsButton:SetCallback("OnClick", function() ZF:CopyTable(ZF:GetDefaultDB().profile.General.Colors.Reaction, ZF.db.profile.General.Colors.Reaction) PopulateColors() end)
        ResetReactionColorsButton:SetRelativeWidth(STYLE.Widths.Pct33)
        ColorsContainer:AddChild(ResetReactionColorsButton)

        local ResetDispelColorsButton = AG:Create("Button")
        ResetDispelColorsButton:SetText("Dispel Colors")
        ResetDispelColorsButton:SetCallback("OnClick", function() ZF:CopyTable(ZF:GetDefaultDB().profile.General.Colors.Dispel, ZF.db.profile.General.Colors.Dispel) PopulateColors() end)
        ResetDispelColorsButton:SetRelativeWidth(STYLE.Widths.Pct33)
        ColorsContainer:AddChild(ResetDispelColorsButton)

        local ResetStatusColorsButton = AG:Create("Button")
        ResetStatusColorsButton:SetText("Status Colors")
        ResetStatusColorsButton:SetCallback("OnClick", function() ZF:CopyTable(ZF:GetDefaultDB().profile.General.Colors.Status, ZF.db.profile.General.Colors.Status) ZF:LoadCustomColors() ZF:UpdateAllUnitFrames() PopulateColors() end)
        ResetStatusColorsButton:SetRelativeWidth(STYLE.Widths.Pct33)
        ColorsContainer:AddChild(ResetStatusColorsButton)

        local ResetThreatColorsButton = AG:Create("Button")
        ResetThreatColorsButton:SetText("Threat Colors")
        ResetThreatColorsButton:SetCallback("OnClick", function() ZF:CopyTable(ZF:GetDefaultDB().profile.General.Colors.Threat, ZF.db.profile.General.Colors.Threat) ZF:LoadCustomColors() ZF:UpdateAllUnitFrames() PopulateColors() end)
        ResetThreatColorsButton:SetRelativeWidth(STYLE.Widths.Pct33)
        ColorsContainer:AddChild(ResetThreatColorsButton)

        GUIWidgets.CreateHeader(ColorsContainer, "Power")

        local PowerOrder = {0, 1, 2, 3, 6, 8, 11, 13, 17, 18}

        for _, powerType in ipairs(PowerOrder) do
            GUIBuilders.CreateColorBlock(ColorsContainer, Power[powerType], ZF.db.profile.General.Colors.Power, powerType, UpdateColors, {width = STYLE.Widths.Pct19})
        end

        GUIWidgets.CreateHeader(ColorsContainer, "Secondary Power")

        local SecondaryPowerOrder = {4, 7, 9, 12, 16, 19}

        for _, secondaryPowerType in ipairs(SecondaryPowerOrder) do
            if ZF.db.profile.General.Colors.SecondaryPower[secondaryPowerType] then
                GUIBuilders.CreateColorBlock(ColorsContainer, Power[secondaryPowerType], ZF.db.profile.General.Colors.SecondaryPower, secondaryPowerType, UpdateColors, {width = STYLE.Widths.Pct20})
            end
        end

        GUIWidgets.CreateHeader(ColorsContainer, "Reaction")

        local ReactionOrder = {1, 2, 3, 4, 5, 6, 7, 8}

        for _, reactionType in ipairs(ReactionOrder) do
            GUIBuilders.CreateColorBlock(ColorsContainer, Reaction[reactionType], ZF.db.profile.General.Colors.Reaction, reactionType, UpdateColors, {width = STYLE.Widths.Pct25})
        end

        GUIWidgets.CreateHeader(ColorsContainer, "Status")

        local StatusOrder = {"Tapped", "Disconnected", "DeadBackdrop"}

        for _, statusType in ipairs(StatusOrder) do
            GUIBuilders.CreateColorBlock(ColorsContainer, Status[statusType], ZF.db.profile.General.Colors.Status, statusType, UpdateColors, {width = STYLE.Widths.Pct25})
        end

        GUIWidgets.CreateHeader(ColorsContainer, "Threat")

        local ThreatOrder = {0, 1, 2, 3}

        for _, threatStatus in ipairs(ThreatOrder) do
            GUIBuilders.CreateColorBlock(ColorsContainer, Threat[threatStatus], ZF.db.profile.General.Colors.Threat, threatStatus, UpdateColors, {width = STYLE.Widths.Pct25})
        end

        GUIWidgets.CreateHeader(ColorsContainer, "Dispel Types")

        local DispelTypes = {"Magic", "Curse", "Disease", "Poison", "Bleed"}

        for _, dispelType in ipairs(DispelTypes) do
            GUIBuilders.CreateColorBlock(ColorsContainer, dispelType, ZF.db.profile.General.Colors.Dispel, dispelType, UpdateColors, {width = STYLE.Widths.Pct20})
        end
        ColorsContainer:DoLayout()
    end
    PopulateColors()
end

local function CreateFrameSettings(containerParent, unit, updateCallback)
    local FrameDB = GetUnitDB(unit).Frame
    local HealthBarDB = GetUnitDB(unit).HealthBar

    local isRaidLike = unit == "raid" or unit == "augmentation"
    local isGroupUnit = unit == "party" or isRaidLike
    local isSoloTarget = unit == "player" or unit == "target"

    local ColorContainer = GUIWidgets.CreateInlineGroup(containerParent, "Colors & Toggles")
    local healthToggleWidth = isSoloTarget and STYLE.Widths.Pct25 or STYLE.Widths.Pct33
    local primaryToggleWidth = isGroupUnit and STYLE.Widths.Pct33 or healthToggleWidth
    local secondaryToggleWidth = isRaidLike and STYLE.Widths.Pct33 or primaryToggleWidth

    if unit == "party" then
        GUIBuilders.CreateReloadPrompt(ColorContainer, "Show Player", FrameDB, "ShowPlayer", {width = primaryToggleWidth})
    end

    local SmoothUpdatesToggle = AG:Create("CheckBox")
    SmoothUpdatesToggle:SetLabel("Smooth Updates")
    SmoothUpdatesToggle:SetValue(HealthBarDB.Smooth ~= false)
    SmoothUpdatesToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.Smooth = value updateCallback("HealthBar") end)
    SmoothUpdatesToggle:SetRelativeWidth(primaryToggleWidth)
    ColorContainer:AddChild(SmoothUpdatesToggle)

    local ColorWhenTappedToggle = AG:Create("CheckBox")
    ColorWhenTappedToggle:SetLabel("Color When Tapped")
    ColorWhenTappedToggle:SetValue(HealthBarDB.ColorWhenTapped)
    ColorWhenTappedToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.ColorWhenTapped = value updateCallback("HealthBar") end)
    ColorWhenTappedToggle:SetRelativeWidth(primaryToggleWidth)
    ColorContainer:AddChild(ColorWhenTappedToggle)

    local ColorWhenDisconnectedToggle = AG:Create("CheckBox")
    ColorWhenDisconnectedToggle:SetLabel("Color When Disconnected")
    ColorWhenDisconnectedToggle:SetValue(HealthBarDB.ColorWhenDisconnected)
    ColorWhenDisconnectedToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.ColorWhenDisconnected = value updateCallback("HealthBar") end)
    ColorWhenDisconnectedToggle:SetRelativeWidth(secondaryToggleWidth)
    ColorContainer:AddChild(ColorWhenDisconnectedToggle)

    if isGroupUnit then
        local ColorBackdropWhenDeadToggle = AG:Create("CheckBox")
        ColorBackdropWhenDeadToggle:SetLabel("Color Backdrop When Dead")
        ColorBackdropWhenDeadToggle:SetValue(HealthBarDB.ColorBackdropWhenDead)
        ColorBackdropWhenDeadToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.ColorBackdropWhenDead = value updateCallback("HealthBar") end)
        ColorBackdropWhenDeadToggle:SetRelativeWidth(secondaryToggleWidth)
        ColorContainer:AddChild(ColorBackdropWhenDeadToggle)
    end

    local InverseGrowthDirectionToggle = AG:Create("CheckBox")
    InverseGrowthDirectionToggle:SetLabel("Inverse Growth Direction")
    InverseGrowthDirectionToggle:SetValue(HealthBarDB.Inverse)
    InverseGrowthDirectionToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.Inverse = value updateCallback("HealthBar") end)
    InverseGrowthDirectionToggle:SetRelativeWidth(secondaryToggleWidth)
    ColorContainer:AddChild(InverseGrowthDirectionToggle)

    GUIWidgets.CreateInformationTag(ColorContainer, "Foreground & Background Opacity can be set using the sliders.")

    local ForegroundColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Foreground Color", HealthBarDB, "Foreground", function() updateCallback("HealthBar") end, {width = STYLE.Widths.Pct25, disabled = HealthBarDB.ColorByClass})

    local ForegroundColorByClassToggle = AG:Create("CheckBox")
    ForegroundColorByClassToggle:SetLabel("Color by Class / Reaction")
    ForegroundColorByClassToggle:SetValue(HealthBarDB.ColorByClass)
    ForegroundColorByClassToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.ColorByClass = value ForegroundColorPicker:SetDisabled(HealthBarDB.ColorByClass) updateCallback("HealthBar") end)
    ForegroundColorByClassToggle:SetRelativeWidth(STYLE.Widths.Pct25)
    ColorContainer:AddChild(ForegroundColorByClassToggle)

    local ForegroundOpacitySlider = AG:Create("Slider")
    ForegroundOpacitySlider:SetLabel("Foreground Opacity")
    ForegroundOpacitySlider:SetValue(HealthBarDB.ForegroundOpacity)
    ForegroundOpacitySlider:SetSliderValues(unpack(STYLE.Sliders.Opacity))
    ForegroundOpacitySlider:SetRelativeWidth(STYLE.Widths.Pct50)
    ForegroundOpacitySlider:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.ForegroundOpacity = value updateCallback("HealthBar") end)
    ForegroundOpacitySlider:SetIsPercent(true)
    ColorContainer:AddChild(ForegroundOpacitySlider)

    local BackgroundColorPicker = GUIBuilders.CreateColorBlock(ColorContainer, "Background Color", HealthBarDB, "Background", function() updateCallback("HealthBar") end, {width = STYLE.Widths.Pct25, disabled = HealthBarDB.ColorBackgroundByClass})

    local BackgroundColorByClassToggle = AG:Create("CheckBox")
    BackgroundColorByClassToggle:SetLabel("Color by Class / Reaction")
    BackgroundColorByClassToggle:SetValue(HealthBarDB.ColorBackgroundByClass)
    BackgroundColorByClassToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.ColorBackgroundByClass = value BackgroundColorPicker:SetDisabled(HealthBarDB.ColorBackgroundByClass) updateCallback("HealthBar") end)
    BackgroundColorByClassToggle:SetRelativeWidth(STYLE.Widths.Pct25)
    ColorContainer:AddChild(BackgroundColorByClassToggle)

    local BackgroundOpacitySlider = AG:Create("Slider")
    BackgroundOpacitySlider:SetLabel("Background Opacity")
    BackgroundOpacitySlider:SetValue(HealthBarDB.BackgroundOpacity)
    BackgroundOpacitySlider:SetSliderValues(unpack(STYLE.Sliders.Opacity))
    BackgroundOpacitySlider:SetRelativeWidth(STYLE.Widths.Pct50)
    BackgroundOpacitySlider:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.BackgroundOpacity = value updateCallback("HealthBar") end)
    BackgroundOpacitySlider:SetIsPercent(true)
    ColorContainer:AddChild(BackgroundOpacitySlider)

    GUIBuilders.CreateColorBlock(ColorContainer, "Border Color", FrameDB, "BorderColor", function() updateCallback("BorderColor") end, {width = STYLE.Widths.Pct25})

    local BorderThicknessSlider = AG:Create("Slider")
    BorderThicknessSlider:SetLabel("Border Thickness")
    BorderThicknessSlider:SetValue(FrameDB.BorderThickness)
    BorderThicknessSlider:SetSliderValues(unpack(STYLE.Sliders.FrameBorderThickness))
    BorderThicknessSlider:SetRelativeWidth(STYLE.Widths.Pct25)
    BorderThicknessSlider:SetCallback("OnValueChanged", function(_, _, value) FrameDB.BorderThickness = value updateCallback("BorderThickness") end)
    ColorContainer:AddChild(BorderThicknessSlider)

    local BorderOpacitySlider = AG:Create("Slider")
    BorderOpacitySlider:SetLabel("Border Opacity")
    BorderOpacitySlider:SetValue(FrameDB.BorderOpacity)
    BorderOpacitySlider:SetSliderValues(unpack(STYLE.Sliders.Opacity))
    BorderOpacitySlider:SetRelativeWidth(STYLE.Widths.Pct25)
    BorderOpacitySlider:SetCallback("OnValueChanged", function(_, _, value) FrameDB.BorderOpacity = value updateCallback("BorderOpacity") end)
    BorderOpacitySlider:SetIsPercent(true)
    ColorContainer:AddChild(BorderOpacitySlider)

    if isSoloTarget or unit == "focus" or isGroupUnit then
        local DispelHighlightContainer = GUIWidgets.CreateInlineGroup(containerParent, "Dispel Highlighting")

        CreateDesignerPreviewToggle(DispelHighlightContainer, "DispelHighlight", function() updateCallback("HealthBar") end)
        local EnableDispelHighlightingToggle = AG:Create("CheckBox")
        EnableDispelHighlightingToggle:SetLabel("Enable Dispel Highlighting")
        EnableDispelHighlightingToggle:SetValue(HealthBarDB.DispelHighlight.Enabled)
        EnableDispelHighlightingToggle:SetRelativeWidth(STYLE.Widths.Pct50)
        EnableDispelHighlightingToggle:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.DispelHighlight.Enabled = value updateCallback("HealthBar") end)
        DispelHighlightContainer:AddChild(EnableDispelHighlightingToggle)

        local DispelHighlightStyleDropdown = AG:Create("Dropdown")
        DispelHighlightStyleDropdown:SetList({["HEALTHBAR"] = "Health Bar", ["GRADIENT"] = "Gradient" })
        DispelHighlightStyleDropdown:SetLabel("Highlight Style")
        DispelHighlightStyleDropdown:SetValue(HealthBarDB.DispelHighlight.Style)
        DispelHighlightStyleDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
        DispelHighlightStyleDropdown:SetCallback("OnValueChanged", function(_, _, value) HealthBarDB.DispelHighlight.Style = value updateCallback("HealthBar") end)
        DispelHighlightContainer:AddChild(DispelHighlightStyleDropdown)
    end

    local CopyContainer = GUIWidgets.CreateInlineGroup(containerParent, "Copy Settings From Another Unit")
    GUIWidgets.CreateInformationTag(CopyContainer, "Copies every setting from the selected unit onto |cFFFFD100" .. (UnitDBToUnitPrettyName[unit] or unit) .. "|r, except its screen position (set via the mover).")

    local copySourceUnit
    local CopySourceDropdown = AG:Create("Dropdown")
    do
        local values, order = {}, {}
        for _, otherUnit in ipairs({"player", "target", "targettarget", "pet", "focus", "focustarget", "party", "raid", "boss", "augmentation"}) do
            if otherUnit ~= unit and (otherUnit ~= "augmentation" or ZF:IsAugmentationEvoker()) then
                values[otherUnit] = UnitDBToUnitPrettyName[otherUnit]
                order[#order + 1] = otherUnit
            end
        end
        CopySourceDropdown:SetList(values, order)
    end
    CopySourceDropdown:SetLabel("Copy From")
    CopySourceDropdown:SetValue(nil)
    CopySourceDropdown:SetRelativeWidth(STYLE.Widths.Pct66)
    CopySourceDropdown:SetCallback("OnValueChanged", function(_, _, value) copySourceUnit = value end)
    CopyContainer:AddChild(CopySourceDropdown)

    local CopyButton = AG:Create("Button")
    CopyButton:SetText("Copy Settings")
    CopyButton:SetRelativeWidth(STYLE.Widths.Pct34)
    CopyButton:SetCallback("OnClick", function()
        if not copySourceUnit then return end
        local sourceLabel = UnitDBToUnitPrettyName[copySourceUnit] or copySourceUnit
        local targetLabel = UnitDBToUnitPrettyName[unit] or unit
        StaticPopupDialogs["ZF_COPY_UNIT_SETTINGS"] = {
            text = ("This will overwrite ALL of |cFFFFD100%s|r's settings with |cFFFFD100%s|r's (screen position kept as-is). This cannot be undone. Continue?"):format(targetLabel, sourceLabel),
            button1 = "Copy",
            button2 = "Cancel",
            showAlert = true,
            OnAccept = function()
                ZF:CopyUnitSettings(copySourceUnit, unit)
                ZF:BuildDesignerSectionOptions(containerParent, unit, "Frame")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("ZF_COPY_UNIT_SETTINGS")
    end)
    CopyContainer:AddChild(CopyButton)
end

local function CreateAugmentationFrameSettings(containerParent)
	local AugmentationDB = ZF.db.profile.Units.augmentation
	local GeneralContainer = GUIWidgets.CreateInlineGroup(containerParent, "Player Filter")
	GUIWidgets.CreateInformationTag(GeneralContainer, "|cFFFFD100Listed|r Raid Members are the only players that will be shown.")

	local NamesEditBox = AG:Create("MultiLineEditBox")
	NamesEditBox:SetLabel("Player Names (Comma Delimited)")
	NamesEditBox:SetText(AugmentationDB.Names or "")
	NamesEditBox:SetNumLines(8)
	NamesEditBox:SetFullWidth(true)
	NamesEditBox:SetCallback("OnEnterPressed", function(_, _, value) AugmentationDB.Names = value ZF:UpdateAugmentationRaidFrames() end)
	GeneralContainer:AddChild(NamesEditBox)
end

GUIInternal.CreateFontSettings = CreateFontSettings
GUIInternal.CreateTextureSettings = CreateTextureSettings
GUIInternal.CreateRangeSettings = CreateRangeSettings
GUIInternal.CreateColorSettings = CreateColorSettings
GUIInternal.CreateFrameSettings = CreateFrameSettings
GUIInternal.CreateAugmentationFrameSettings = CreateAugmentationFrameSettings
