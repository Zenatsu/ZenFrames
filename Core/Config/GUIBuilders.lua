local _, ZF = ...
local AG = ZF.AG
local GUIWidgets = ZF.GUIWidgets
local STYLE = ZF.DesignerStyle
ZF.GUIBuilders = {}
local Builders = ZF.GUIBuilders

Builders.AnchorPoints = { { ["TOPLEFT"] = "Top Left", ["TOP"] = "Top", ["TOPRIGHT"] = "Top Right", ["LEFT"] = "Left", ["CENTER"] = "Center", ["RIGHT"] = "Right", ["BOTTOMLEFT"] = "Bottom Left", ["BOTTOM"] = "Bottom", ["BOTTOMRIGHT"] = "Bottom Right" }, { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" } }
Builders.FrameStrataList = { { ["BACKGROUND"] = "Background", ["LOW"] = "Low", ["MEDIUM"] = "Medium", ["HIGH"] = "High", ["DIALOG"] = "Dialog", ["FULLSCREEN"] = "Fullscreen", ["FULLSCREEN_DIALOG"] = "Fullscreen Dialog", ["TOOLTIP"] = "Tooltip" }, { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" } }

function Builders.CreateEnableToggle(parent, label, db, updateCallback, opts)
    opts = opts or {}
    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(label)
    Toggle:SetValue(db.Enabled)
    Toggle:SetRelativeWidth(opts.width or 1)
    parent:AddChild(Toggle)

    local panels = {}
    local function Refresh()
        for _, panel in ipairs(panels) do
            GUIWidgets.DeepDisable(panel, not db.Enabled, Toggle)
        end
    end
    Toggle:SetCallback("OnValueChanged", function(_, _, value)
        db.Enabled = value
        updateCallback()
        Refresh()
    end)

    return Toggle, Refresh, panels
end

function Builders.CreateLayoutPositionBlock(parent, layoutDB, updateCallback, opts)
    opts = opts or {}
    local Container = GUIWidgets.CreateInlineGroup(parent, opts.groupLabel or "Layout & Positioning")

    local AnchorFromDropdown = AG:Create("Dropdown")
    AnchorFromDropdown:SetList(Builders.AnchorPoints[1], Builders.AnchorPoints[2])
    AnchorFromDropdown:SetLabel("Anchor From")
    AnchorFromDropdown:SetValue(layoutDB.Layout[1])
    AnchorFromDropdown:SetRelativeWidth(0.5)
    AnchorFromDropdown:SetCallback("OnValueChanged", function(_, _, value) layoutDB.Layout[1] = value updateCallback() end)
    Container:AddChild(AnchorFromDropdown)

    local AnchorToDropdown = AG:Create("Dropdown")
    AnchorToDropdown:SetList(Builders.AnchorPoints[1], Builders.AnchorPoints[2])
    AnchorToDropdown:SetLabel("Anchor To")
    AnchorToDropdown:SetValue(layoutDB.Layout[2])
    AnchorToDropdown:SetRelativeWidth(0.5)
    AnchorToDropdown:SetCallback("OnValueChanged", function(_, _, value) layoutDB.Layout[2] = value updateCallback() end)
    Container:AddChild(AnchorToDropdown)

    local xyWidth = opts.xyWidth or (opts.includeSize and 0.33 or 0.5)

    local XPosSlider = AG:Create("Slider")
    XPosSlider:SetLabel("X Position")
    XPosSlider:SetValue(layoutDB.Layout[3])
    XPosSlider:SetSliderValues(unpack(STYLE.Sliders.Position))
    XPosSlider:SetRelativeWidth(xyWidth)
    XPosSlider:SetCallback("OnValueChanged", function(_, _, value) layoutDB.Layout[3] = value updateCallback() end)
    Container:AddChild(XPosSlider)

    local YPosSlider = AG:Create("Slider")
    YPosSlider:SetLabel("Y Position")
    YPosSlider:SetValue(layoutDB.Layout[4])
    YPosSlider:SetSliderValues(unpack(STYLE.Sliders.Position))
    YPosSlider:SetRelativeWidth(xyWidth)
    YPosSlider:SetCallback("OnValueChanged", function(_, _, value) layoutDB.Layout[4] = value updateCallback() end)
    Container:AddChild(YPosSlider)

    local SizeSlider
    if opts.includeSize then
        local sizeKey = opts.sizeKey or "Size"
        SizeSlider = AG:Create("Slider")
        SizeSlider:SetLabel(opts.sizeLabel or "Size")
        SizeSlider:SetValue(layoutDB[sizeKey])
        SizeSlider:SetSliderValues(unpack(STYLE.Sliders.FontSize))
        SizeSlider:SetRelativeWidth(opts.sizeWidth or xyWidth)
        SizeSlider:SetCallback("OnValueChanged", function(_, _, value) layoutDB[sizeKey] = value updateCallback() end)
        Container:AddChild(SizeSlider)
    end

    return Container, XPosSlider, YPosSlider, SizeSlider
end

function Builders.CreateColorBlock(parent, label, db, colorKey, updateCallback, opts)
    opts = opts or {}
    local ColorPicker = AG:Create("ColorPicker")
    ColorPicker:SetLabel(label)
    local color = db[colorKey]
    if opts.hasAlpha then
        ColorPicker:SetColor(color[1], color[2], color[3], color[4])
        ColorPicker:SetHasAlpha(true)
        ColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b, a) db[colorKey] = {r, g, b, a} updateCallback() end)
    else
        ColorPicker:SetColor(color[1], color[2], color[3])
        ColorPicker:SetHasAlpha(false)
        ColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) db[colorKey] = {r, g, b} updateCallback() end)
    end
    ColorPicker:SetRelativeWidth(opts.width or 0.5)
    if opts.disabled then ColorPicker:SetDisabled(true) end
    parent:AddChild(ColorPicker)

    local OpacitySlider
    if opts.opacityKey then
        OpacitySlider = AG:Create("Slider")
        OpacitySlider:SetLabel(label .. " Opacity")
        OpacitySlider:SetValue(db[opts.opacityKey])
        OpacitySlider:SetSliderValues(unpack(STYLE.Sliders.Opacity))
        OpacitySlider:SetIsPercent(true)
        OpacitySlider:SetRelativeWidth(opts.opacityWidth or opts.width or 0.5)
        OpacitySlider:SetCallback("OnValueChanged", function(_, _, value) db[opts.opacityKey] = value updateCallback() end)
        parent:AddChild(OpacitySlider)
    end

    return ColorPicker, OpacitySlider
end

local function AttachTooltip(widget, tooltipText, anchor)
    if not tooltipText then return end
    widget:SetCallback("OnEnter", function()
        GameTooltip:SetOwner(widget.frame, anchor)
        GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    widget:SetCallback("OnLeave", function() GameTooltip:Hide() end)
end

function Builders.CreateCheckbox(parent, label, db, key, updateCallback, opts)
    opts = opts or {}
    local Checkbox = AG:Create("CheckBox")
    Checkbox:SetLabel(label)
    Checkbox:SetValue(db[key])
    Checkbox:SetRelativeWidth(opts.width or 1)
    if opts.disabled then Checkbox:SetDisabled(true) end
    Checkbox:SetCallback("OnValueChanged", function(_, _, value)
        db[key] = value
        if opts.onChanged then opts.onChanged(value) end
        updateCallback()
    end)
    AttachTooltip(Checkbox, opts.tooltip, "ANCHOR_CURSOR")
    parent:AddChild(Checkbox)
    return Checkbox
end

function Builders.CreateSlider(parent, label, db, key, updateCallback, opts)
    opts = opts or {}
    local Slider = AG:Create("Slider")
    Slider:SetLabel(label)
    Slider:SetValue(db[key])
    Slider:SetSliderValues(unpack(opts.sliderValues))
    Slider:SetRelativeWidth(opts.width or 1)
    if opts.isPercent then Slider:SetIsPercent(true) end
    if opts.disabled then Slider:SetDisabled(true) end
    Slider:SetCallback("OnValueChanged", function(_, _, value)
        db[key] = value
        if opts.onChanged then opts.onChanged(value) end
        updateCallback()
    end)
    AttachTooltip(Slider, opts.tooltip, "ANCHOR_CURSOR")
    parent:AddChild(Slider)
    return Slider
end

function Builders.CreateDropdown(parent, label, db, key, updateCallback, opts)
    opts = opts or {}
    local Dropdown = AG:Create("Dropdown")
    Dropdown:SetList(opts.list, opts.order)
    Dropdown:SetLabel(label)
    Dropdown:SetValue(db[key])
    Dropdown:SetRelativeWidth(opts.width or 1)
    if opts.disabled then Dropdown:SetDisabled(true) end
    Dropdown:SetCallback("OnValueChanged", function(_, _, value)
        db[key] = value
        if opts.onChanged then opts.onChanged(value) end
        updateCallback()
    end)
    AttachTooltip(Dropdown, opts.tooltip, "ANCHOR_BOTTOM")
    parent:AddChild(Dropdown)
    return Dropdown
end

function Builders.CreateReloadPrompt(parent, label, db, key, opts)
    opts = opts or {}
    local Toggle = AG:Create("CheckBox")
    Toggle:SetLabel(label)
    Toggle:SetValue(db[key])
    Toggle:SetRelativeWidth(opts.width or 1)
    parent:AddChild(Toggle)

    Toggle:SetCallback("OnValueChanged", function(_, _, value)
        StaticPopupDialogs["ZF_RELOAD_UI"] ={
            text = "You must reload to apply this change, do you want to reload now?",
            button1 = "Reload",
            button2 = "Later",
            showAlert = true,
            OnAccept = function() db[key] = value C_UI.Reload() end,
            OnCancel = function() Toggle:SetValue(db[key]) parent:DoLayout() end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        local popup = StaticPopup_Show("ZF_RELOAD_UI")
        if popup then popup:SetFrameStrata("TOOLTIP") end
    end)

    return Toggle
end