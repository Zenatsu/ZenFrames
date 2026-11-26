local _, ZF = ...
local AceGUI = LibStub("AceGUI-3.0")
local Kit = ZF.NativeKit
local NATIVE = ZF.DesignerStyle.Native

local Type, Version = "ZF_ColorPicker", 1

local function OpenColorPicker(self)
    local function OnColorChanged()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        local a = self.hasAlpha and ColorPickerFrame:GetColorAlpha() or 1
        self:SetColor(r, g, b, a)
        self:Fire("OnValueChanged", r, g, b, a)
    end

    local function OnCancel(previous)
        self:SetColor(previous.r, previous.g, previous.b, previous.a)
        self:Fire("OnValueChanged", self.r, self.g, self.b, self.a)
    end

    ColorPickerFrame:SetupColorPickerAndShow({
        r = self.r,
        g = self.g,
        b = self.b,
        opacity = self.a,
        hasOpacity = self.hasAlpha,
        swatchFunc = OnColorChanged,
        opacityFunc = OnColorChanged,
        cancelFunc = OnCancel,
    })
    ColorPickerFrame:SetFrameLevel(self.frame:GetFrameLevel() + NATIVE.PopupLevelOffset)
    ColorPickerFrame:SetClampedToScreen(true)
end

local function Frame_OnClick(frame)
    AceGUI:ClearFocus()
    OpenColorPicker(frame.obj)
end

local function Frame_OnEnter(frame)
    frame.obj.swatch:SetBorderColor(NORMAL_FONT_COLOR)
    frame.obj:Fire("OnEnter")
end

local function Frame_OnLeave(frame)
    frame.obj.swatch:SetBorderColor(HIGHLIGHT_FONT_COLOR)
    frame.obj:Fire("OnLeave")
end

local methods = {
    OnAcquire = function(self)
        self:SetHasAlpha(false)
        self:SetColor(0, 0, 0, 1)
        self:SetLabel()
        self:SetDisabled(false)
        self:SetWidth(200)
        self:SetHeight(NATIVE.ColorSwatchHeight)
    end,

    SetLabel = function(self, text)
        Kit.SetLabelText(self.text, text)
    end,

    SetColor = function(self, r, g, b, a)
        self.r, self.g, self.b, self.a = r or 0, g or 0, b or 0, a or 1
        self.swatch:SetColorRGB(self.r, self.g, self.b)
        self.swatch.Color:SetAlpha(self.a)
    end,

    SetHasAlpha = function(self, hasAlpha)
        self.hasAlpha = hasAlpha and true or false
    end,

    SetDisabled = function(self, disabled)
        self.disabled = disabled and true or false
        self.frame:SetEnabled(not self.disabled)
        self.swatch:SetAlpha(self.disabled and NATIVE.DisabledAlpha or 1)
        Kit.SetTextEnabled(self.text, not self.disabled, HIGHLIGHT_FONT_COLOR)
    end,
}

local function Constructor()
    local frame = CreateFrame("Button", nil, UIParent)
    frame:Hide()
    frame:EnableMouse(true)
    frame:SetMotionScriptsWhileDisabled(true)
    frame:SetScript("OnClick", Frame_OnClick)
    frame:SetScript("OnEnter", Frame_OnEnter)
    frame:SetScript("OnLeave", Frame_OnLeave)

    local swatch = CreateFrame("Frame", nil, frame, "ColorSwatchTemplate")
    swatch:SetPoint("LEFT", frame, "LEFT", NATIVE.SwatchInset, 0)
    swatch:EnableMouse(false)

    local text = frame:CreateFontString(nil, "OVERLAY", NATIVE.ControlFont)
    text:SetPoint("LEFT", swatch, "RIGHT", NATIVE.SwatchLabelGap, 0)
    text:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)

    local widget = {
        type = Type,
        frame = frame,
        swatch = swatch,
        text = text,
        alignoffset = NATIVE.ColorSwatchHeight / 2,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    return AceGUI:RegisterAsWidget(widget)
end

ZF.AG:RegisterNative("ColorPicker", Type, Constructor, Version)