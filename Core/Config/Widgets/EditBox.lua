local _, ZF = ...
local AceGUI = LibStub("AceGUI-3.0")
local Kit = ZF.NativeKit
local NATIVE = ZF.DesignerStyle.Native

local EditBoxType, EditBoxVersion = "ZF_EditBox", 1
local MultiLineType, MultiLineVersion = "ZF_MultiLineEditBox", 1

local function EditBox_OnFocusGained(editbox)
    AceGUI:SetFocus(editbox.obj)
end

local function AnchorEditBox(self)
    local right = self.button:IsShown() and NATIVE.EditBoxButtonWidth + NATIVE.EditBoxButtonGap or 0
    self.editbox:SetPoint("TOPLEFT", self.frame, "TOPLEFT", NATIVE.InputArtSide, -self.top)
    self.editbox:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -(right + NATIVE.InputArtSide), -self.top)
    self.button:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -self.top)
end

local function ShowButton(self)
    if self.disableButton or self.button:IsShown() then return end
    self.button:Show()
    AnchorEditBox(self)
end

local function HideButton(self)
    if not self.button:IsShown() then return end
    self.button:Hide()
    AnchorEditBox(self)
end

local function EditBox_OnEnterPressed(editbox)
    local self = editbox.obj
    local cancel = self:Fire("OnEnterPressed", editbox:GetText())
    if not cancel then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        HideButton(self)
    end
end

local function EditBox_OnTextChanged(editbox)
    local self = editbox.obj
    local text = editbox:GetText()
    if text ~= self.lasttext then
        self.lasttext = text
        self:Fire("OnTextChanged", text)
        ShowButton(self)
    end
end

local function Button_OnClick(button)
    local self = button.obj
    self.editbox:ClearFocus()
    EditBox_OnEnterPressed(self.editbox)
end

local editBoxMethods = {
    OnAcquire = function(self)
        self:SetWidth(200)
        self:DisableButton(false)
        self:SetLabel()
        self:SetText()
        self:SetDisabled(false)
        self:SetMaxLetters(0)
    end,

    OnRelease = function(self)
        self:ClearFocus()
    end,

    SetLabel = function(self, text)
        self.top = Kit.SetLabelText(self.label, text) and NATIVE.LabelHeight + NATIVE.InputLabelGap or NATIVE.InputLabelGap
        AnchorEditBox(self)
        self:SetHeight(self.top + NATIVE.InputHeight + NATIVE.GroupBottomPadding)
        self.alignoffset = self.top + NATIVE.InputHeight / 2
    end,

    SetText = function(self, text)
        self.lasttext = text or ""
        self.editbox:SetText(text or "")
        self.editbox:SetCursorPosition(0)
        HideButton(self)
    end,

    GetText = function(self)
        return self.editbox:GetText()
    end,

    DisableButton = function(self, disabled)
        self.disableButton = disabled and true or false
        if self.disableButton then
            HideButton(self)
        end
    end,

    SetMaxLetters = function(self, maxLetters)
        self.editbox:SetMaxLetters(maxLetters or 0)
    end,

    SetDisabled = function(self, disabled)
        self.disabled = disabled and true or false
        self.editbox:SetEnabled(not self.disabled)
        if self.disabled then
            self.editbox:ClearFocus()
        end
        Kit.SetTextEnabled(self.editbox, not self.disabled, HIGHLIGHT_FONT_COLOR)
        Kit.SetTextEnabled(self.label, not self.disabled)
    end,

    ClearFocus = function(self)
        self.editbox:ClearFocus()
    end,

    SetFocus = function(self)
        self.editbox:SetFocus()
    end,

    HighlightText = function(self, from, to)
        self.editbox:HighlightText(from, to)
    end,
}

local function EditBoxConstructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    local label = Kit.CreateLabel(frame)
    label:SetPoint("TOPLEFT")
    label:SetPoint("TOPRIGHT")
    label:SetHeight(NATIVE.LabelHeight)

    local editbox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editbox:SetAutoFocus(false)
    editbox:SetHeight(NATIVE.InputHeight)
    editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
    editbox:SetScript("OnTextChanged", EditBox_OnTextChanged)
    editbox:HookScript("OnEditFocusGained", EditBox_OnFocusGained)
    editbox:HookScript("OnEnter", Kit.FireOnEnter)
    editbox:HookScript("OnLeave", Kit.FireOnLeave)

    local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    button:SetSize(NATIVE.EditBoxButtonWidth, NATIVE.InputHeight)
    button:SetText(OKAY)
    button:SetScript("OnClick", Button_OnClick)
    button:Hide()

    local widget = {
        type = EditBoxType,
        frame = frame,
        label = label,
        editbox = editbox,
        button = button,
        top = 0,
    }
    for method, func in pairs(editBoxMethods) do
        widget[method] = func
    end
    editbox.obj = widget
    button.obj = widget
    return AceGUI:RegisterAsWidget(widget)
end

local function MultiLine_Layout(self)
    local top = self.labelShown and NATIVE.LabelHeight + NATIVE.MultiLineLabelGap or NATIVE.MultiLineArtInset
    local bottom = NATIVE.MultiLineArtInset
    if not self.disableButton then
        bottom = bottom + NATIVE.InputHeight + NATIVE.MultiLineButtonGap
    end
    self.scroll:SetPoint("TOPLEFT", self.frame, "TOPLEFT", NATIVE.MultiLineArtInset, -top)
    self.scroll:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -NATIVE.MultiLineArtInset, bottom)
    self.button:SetShown(not self.disableButton)
    self:SetHeight(top + self.numLines * NATIVE.MultiLineLineHeight + NATIVE.MultiLineArtInset + bottom)
end

local function MultiLine_OnTextChanged(editbox)
    local self = editbox.obj
    local text = editbox:GetText()
    if text ~= self.lasttext then
        self.lasttext = text
        self:Fire("OnTextChanged", text)
    end
end

local function MultiLineButton_OnClick(button)
    local self = button.obj
    self.editbox:ClearFocus()
    self:Fire("OnEnterPressed", self.editbox:GetText())
end

local multiLineMethods = {
    OnAcquire = function(self)
        self.numLines = 4
        self.disableButton = false
        self:SetText()
        self:SetWidth(200)
        self:SetLabel()
        self:SetDisabled(false)
        self:SetMaxLetters(0)
    end,

    OnRelease = function(self)
        self:ClearFocus()
    end,

    SetLabel = function(self, text)
        self.labelShown = Kit.SetLabelText(self.label, text)
        MultiLine_Layout(self)
    end,

    SetNumLines = function(self, numLines)
        self.numLines = math.max(numLines or 4, 1)
        MultiLine_Layout(self)
    end,

    DisableButton = function(self, disabled)
        self.disableButton = disabled and true or false
        MultiLine_Layout(self)
    end,

    SetText = function(self, text)
        self.lasttext = text or ""
        self.editbox:SetText(text or "")
    end,

    GetText = function(self)
        return self.editbox:GetText()
    end,

    SetMaxLetters = function(self, maxLetters)
        self.editbox:SetMaxLetters(maxLetters or 0)
    end,

    SetDisabled = function(self, disabled)
        self.disabled = disabled and true or false
        self.editbox:SetEnabled(not self.disabled)
        if self.disabled then
            self.editbox:ClearFocus()
        end
        self.button:SetEnabled(not self.disabled)
        Kit.SetTextEnabled(self.editbox, not self.disabled, HIGHLIGHT_FONT_COLOR)
        Kit.SetTextEnabled(self.label, not self.disabled)
    end,

    ClearFocus = function(self)
        self.editbox:ClearFocus()
    end,

    SetFocus = function(self)
        self.editbox:SetFocus()
    end,

    HighlightText = function(self, from, to)
        self.editbox:HighlightText(from, to)
    end,

    GetCursorPosition = function(self)
        return self.editbox:GetCursorPosition()
    end,

    SetCursorPosition = function(self, position)
        self.editbox:SetCursorPosition(position)
    end,

    OnWidthSet = function(self, width)
        self.editbox:SetWidth(math.max(width - NATIVE.MultiLineArtInset * 2 - NATIVE.MultiLineScrollBarSpace, 1))
    end,
}

local function MultiLineConstructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    local label = Kit.CreateLabel(frame)
    label:SetPoint("TOPLEFT")
    label:SetPoint("TOPRIGHT")
    label:SetHeight(NATIVE.LabelHeight)

    local scroll = CreateFrame("ScrollFrame", nil, frame, "InputScrollFrameTemplate")
    scroll.CharCount:Hide()

    local editbox = scroll.EditBox
    editbox:HookScript("OnTextChanged", MultiLine_OnTextChanged)
    editbox:HookScript("OnEditFocusGained", EditBox_OnFocusGained)

    local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    button:SetSize(NATIVE.MultiLineButtonWidth, NATIVE.InputHeight)
    button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, NATIVE.MultiLineArtInset)
    button:SetText(ACCEPT)
    button:SetScript("OnClick", MultiLineButton_OnClick)

    local widget = {
        type = MultiLineType,
        frame = frame,
        label = label,
        scroll = scroll,
        editbox = editbox,
        button = button,
        numLines = 4,
    }
    for method, func in pairs(multiLineMethods) do
        widget[method] = func
    end
    editbox.obj = widget
    button.obj = widget
    return AceGUI:RegisterAsWidget(widget)
end

ZF.AG:RegisterNative("EditBox", EditBoxType, EditBoxConstructor, EditBoxVersion)
ZF.AG:RegisterNative("MultiLineEditBox", MultiLineType, MultiLineConstructor, MultiLineVersion)