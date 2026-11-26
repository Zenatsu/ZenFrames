local _, ZF = ...
local AceGUI = LibStub("AceGUI-3.0")
local Kit = ZF.NativeKit
local NATIVE = ZF.DesignerStyle.Native

local Type, Version = "ZF_Slider", 1

local function FormatValue(self, value)
    if value == nil then return "" end
    if self.isPercent then
        return tostring(Kit.RoundToStep(value * 100, (self.step or 0.01) * 100)) .. "%"
    end
    return tostring(Kit.RoundToStep(value, self.step))
end

local function UpdateText(self)
    if not self.editbox:HasFocus() then
        self.editbox:SetText(FormatValue(self, self.value))
    end
end

local function SetSliderValue(self, value)
    self.updating = true
    self.stepper:SetValue(value)
    self.updating = nil
end

local function Stepper_OnValueChanged(self, value)
    if self.updating then return end
    value = Kit.RoundToStep(value, self.step)
    if value == self.value then return end
    self.value = value
    UpdateText(self)
    self:Fire("OnValueChanged", value)
end

local function EditBox_OnEnterPressed(editbox)
    local self = editbox.obj
    local value = tonumber((editbox:GetText():gsub("%%", "")))
    if value and self.minValue then
        if self.isPercent then
            value = value / 100
        end
        value = Kit.RoundToStep(math.min(math.max(value, self.minValue), self.maxValue), self.step)
        if value ~= self.value then
            self.value = value
            SetSliderValue(self, value)
            self:Fire("OnValueChanged", value)
        end
    end
    editbox:ClearFocus()
    UpdateText(self)
end

local function EditBox_OnEscapePressed(editbox)
    editbox:ClearFocus()
    UpdateText(editbox.obj)
end

local methods = {
    OnAcquire = function(self)
        self.value = nil
        self.minValue, self.maxValue, self.step = nil, nil, nil
        self:SetIsPercent(false)
        self:SetLabel()
        self:SetDisabled(false)
        self:SetWidth(200)
    end,

    SetValue = function(self, value)
        self.value = value
        if self.minValue and value ~= nil then
            SetSliderValue(self, value)
        end
        UpdateText(self)
    end,

    GetValue = function(self)
        return self.value
    end,

    SetSliderValues = function(self, minValue, maxValue, step)
        self.minValue, self.maxValue, self.step = minValue, maxValue, step
        local steps = math.max(1, math.floor((maxValue - minValue) / step + 0.5))
        self.updating = true
        self.stepper:Init(self.value or minValue, minValue, maxValue, steps)
        self.updating = nil
        UpdateText(self)
    end,

    SetIsPercent = function(self, isPercent)
        self.isPercent = isPercent and true or false
        UpdateText(self)
    end,

    SetLabel = function(self, text)
        local top = Kit.SetLabelText(self.label, text) and NATIVE.LabelHeight + NATIVE.SliderLabelGap or 0
        local right = NATIVE.SliderValueWidth + NATIVE.SliderValueGap
        self.stepper:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -top)
        self.stepper:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -right, -top)
        self:SetHeight(top + NATIVE.SliderBarHeight + NATIVE.GroupBottomPadding)
        self.alignoffset = top + NATIVE.SliderBarHeight / 2
    end,

    SetDisabled = function(self, disabled)
        self.disabled = disabled and true or false
        self.stepper:SetEnabled(not self.disabled)
        self.editbox:SetEnabled(not self.disabled)
        if self.disabled then
            self.editbox:ClearFocus()
        end
        Kit.SetTextEnabled(self.label, not self.disabled)
        Kit.SetTextEnabled(self.editbox, not self.disabled, HIGHLIGHT_FONT_COLOR)
    end,
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    local label = Kit.CreateLabel(frame)
    label:SetPoint("TOPLEFT")
    label:SetPoint("TOPRIGHT")
    label:SetHeight(NATIVE.LabelHeight)

    local stepper = CreateFrame("Frame", nil, frame, "MinimalSliderWithSteppersTemplate")
    stepper:SetHeight(NATIVE.SliderBarHeight)

    local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editbox:SetSize(NATIVE.SliderValueWidth, NATIVE.InputHeight)
    editbox:SetPoint("LEFT", stepper, "RIGHT", NATIVE.SliderValueGap, 0)
    editbox:SetAutoFocus(false)
    editbox:SetJustifyH("CENTER")
    editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
    editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)

    local widget = {
        type = Type,
        frame = frame,
        label = label,
        stepper = stepper,
        editbox = editbox,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    editbox.obj = widget
    stepper.Slider.obj = widget
    stepper:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, Stepper_OnValueChanged, widget)
    stepper.Slider:HookScript("OnEnter", Kit.FireOnEnter)
    stepper.Slider:HookScript("OnLeave", Kit.FireOnLeave)
    return AceGUI:RegisterAsWidget(widget)
end

ZF.AG:RegisterNative("Slider", Type, Constructor, Version)