local _, RUF = ...
local AG = RUF.AG
local GUIWidgets = RUF.GUIWidgets
local STYLE = RUF.DesignerStyle
RUF.GUIBuilders = {}
local Builders = RUF.GUIBuilders

Builders.AnchorPoints = { { ["TOPLEFT"] = "Top Left", ["TOP"] = "Top", ["TOPRIGHT"] = "Top Right", ["LEFT"] = "Left", ["CENTER"] = "Center", ["RIGHT"] = "Right", ["BOTTOMLEFT"] = "Bottom Left", ["BOTTOM"] = "Bottom", ["BOTTOMRIGHT"] = "Bottom Right" }, { "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT" } }
Builders.FrameStrataList = { { ["BACKGROUND"] = "Background", ["LOW"] = "Low", ["MEDIUM"] = "Medium", ["HIGH"] = "High", ["DIALOG"] = "Dialog", ["FULLSCREEN"] = "Fullscreen", ["FULLSCREEN_DIALOG"] = "Fullscreen Dialog", ["TOOLTIP"] = "Tooltip" }, { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" } }

-- Creates the enable checkbox and returns a local Refresh() closure the caller owns.
-- Caller appends every panel that should grey out when disabled into the returned
-- `panels` table (in any order, even after this call returns), then calls Refresh()
-- once after building the rest of the section to set the initial state.
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

-- Anchor From/To dropdowns + X/Y position sliders, optionally + a Size slider.
-- opts.includeSize (bool) draws the Size slider and narrows X/Y to 0.33 width to share
-- the row with it; without it X/Y each take 0.5 width. opts.xyWidth/opts.sizeWidth override
-- those widths; opts.sizeKey/opts.sizeLabel let callers whose DB field is named FontSize
-- (text elements) reuse this instead of the default .Size (icon/indicator elements);
-- opts.groupLabel overrides the "Layout & Positioning" inline group title.
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

-- A ColorPicker, either with its own alpha channel (opts.hasAlpha) or paired with a
-- separate Opacity slider (opts.opacityKey names the DB field it writes to). Two
-- distinct shapes exist in the current codebase -- not every caller needs both halves.
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
