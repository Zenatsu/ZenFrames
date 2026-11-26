local _, ZF = ...
local AceGUI = LibStub("AceGUI-3.0")
local Kit = ZF.NativeKit
local NATIVE = ZF.DesignerStyle.Native

local Type, Version = "ZF_CheckBox", 1

local function Frame_OnClick(frame)
    local self = frame.obj
    AceGUI:ClearFocus()
    self:ToggleChecked()
    PlaySound(self.checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    self:Fire("OnValueChanged", self.checked)
end

local function Frame_OnEnter(frame)
    frame.obj.check:LockHighlight()
    frame.obj:Fire("OnEnter")
end

local function Frame_OnLeave(frame)
    frame.obj.check:UnlockHighlight()
    frame.obj:Fire("OnLeave")
end

local methods = {
    OnAcquire = function(self)
        self:SetValue(false)
        self:SetLabel()
        self:SetDisabled(false)
        self:SetWidth(200)
        self:SetHeight(NATIVE.CheckBoxHeight)
    end,

    SetValue = function(self, value)
        self.checked = value and true or false
        self.check:SetChecked(self.checked)
    end,

    GetValue = function(self)
        return self.checked
    end,

    ToggleChecked = function(self)
        self:SetValue(not self.checked)
    end,

    SetLabel = function(self, text)
        Kit.SetLabelText(self.text, text)
    end,

    SetDisabled = function(self, disabled)
        self.disabled = disabled and true or false
        self.frame:SetEnabled(not self.disabled)
        self.check:SetEnabled(not self.disabled)
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

    local check = CreateFrame("CheckButton", nil, frame, "MinimalCheckboxTemplate")
    check:SetPoint("LEFT", frame, "LEFT", -NATIVE.CheckBoxArtInset, 0)
    check:SetSize(NATIVE.CheckBoxSize, NATIVE.CheckBoxSize)
    check:EnableMouse(false)

    local text = frame:CreateFontString(nil, "OVERLAY", NATIVE.ControlFont)
    text:SetPoint("LEFT", check, "RIGHT", 0, 0)
    text:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)

    local widget = {
        type = Type,
        frame = frame,
        check = check,
        text = text,
        alignoffset = NATIVE.CheckBoxHeight / 2,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    return AceGUI:RegisterAsWidget(widget)
end

ZF.AG:RegisterNative("CheckBox", Type, Constructor, Version)