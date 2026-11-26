local _, ZF = ...
local AceGUI = LibStub("AceGUI-3.0")
local Kit = ZF.NativeKit
local NATIVE = ZF.DesignerStyle.Native

local Type, Version = "ZF_Window", 1

local function CloseButton_OnClick(button)
    PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
    button.obj:Hide()
end

local function Frame_OnHide(frame)
    frame.obj:Fire("OnClose")
end

local function Frame_OnMouseDown()
    AceGUI:ClearFocus()
end

local function Frame_OnDragStart(frame)
    AceGUI:ClearFocus()
    frame:StartMoving()
end

local function Frame_OnDragStop(frame)
    frame:StopMovingOrSizing()
end

local methods = {
    OnAcquire = function(self)
        local frame = self.frame
        frame:SetParent(UIParent)
        frame:SetFrameStrata(NATIVE.WindowStrata)
        frame:SetFrameLevel(NATIVE.WindowLevel)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
        self:SetWidth(NATIVE.WindowDefaultWidth)
        self:SetHeight(NATIVE.WindowDefaultHeight)
        self:SetTitle()
        self:SetStatusText()
        self:EnableResize(false)
        self.statusbar:Show()
        self:Show()
    end,

    OnWidthSet = function(self, width)
        local insets = NATIVE.BodyInsets
        local contentWidth = math.max(width - insets.left - insets.right - NATIVE.ContentPadding * 2, 0)
        self.content:SetWidth(contentWidth)
        self.content.width = contentWidth
    end,

    OnHeightSet = function(self, height)
        local insets = NATIVE.BodyInsets
        local contentHeight = math.max(height - insets.top - insets.bottom - NATIVE.ContentPadding * 2, 0)
        self.content:SetHeight(contentHeight)
        self.content.height = contentHeight
    end,

    SetTitle = function(self, title)
        self.frame:SetTitle(title or "")
    end,

    SetStatusText = function(self, text)
        self.statustext:SetText(text or "")
    end,

    Show = function(self)
        self.frame:Show()
    end,

    Hide = function(self)
        self.frame:Hide()
    end,

    EnableResize = function(self, enabled)
        self.frame:SetResizable(enabled and true or false)
        self.resizeButton:SetShown(enabled and true or false)
    end,
}

local function Constructor()
    local frame = CreateFrame("Frame", "ZenFramesNativeWindow" .. AceGUI:GetNextWidgetNum(Type), UIParent, NATIVE.WindowTemplate)
    frame:Hide()
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetToplevel(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnMouseDown", Frame_OnMouseDown)
    frame:SetScript("OnDragStart", Frame_OnDragStart)
    frame:SetScript("OnDragStop", Frame_OnDragStop)
    frame:SetScript("OnHide", Frame_OnHide)
    local portrait = frame:GetPortrait()
    portrait:SetColorTexture(0, 0, 0, 1)

    local logo = frame.PortraitContainer:CreateTexture(nil, "OVERLAY", nil, 1)
    logo:SetTexture(ZF.Media.Logo)
    logo:SetSize(44, 44)
    logo:SetPoint("CENTER", portrait, "CENTER", 0, 2)
    frame.CloseButton:SetScript("OnClick", CloseButton_OnClick)

    local insets = NATIVE.BodyInsets
    local body = CreateFrame("Frame", nil, frame, Kit.FirstTemplate(NATIVE.BodyTemplate, NATIVE.BodyFallbackTemplate))
    body:ClearAllPoints()
    body:SetPoint("TOPLEFT", frame, "TOPLEFT", insets.left, -insets.top)
    body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -insets.right, insets.bottom)

    local content = CreateFrame("Frame", nil, body)
    content:SetPoint("TOPLEFT", body, "TOPLEFT", NATIVE.ContentPadding, -NATIVE.ContentPadding)
    content:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -NATIVE.ContentPadding, NATIVE.ContentPadding)

    local statusbar = CreateFrame("Frame", nil, frame)
    statusbar:SetPoint("TOPLEFT", body, "BOTTOMLEFT", NATIVE.StatusInset, 0)
    statusbar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -NATIVE.StatusInset, 0)

    local statustext = statusbar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statustext:SetAllPoints(statusbar)
    statustext:SetJustifyH("LEFT")

    local resizeButton = CreateFrame("Button", nil, frame, "PanelResizeButtonTemplate")
    resizeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)

    local widget = {
        type = Type,
        frame = frame,
        body = body,
        content = content,
        statusbar = statusbar,
        statustext = statustext,
        resizeButton = resizeButton,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    frame.CloseButton.obj = widget

    AceGUI:RegisterAsContainer(widget)
    resizeButton:Init(frame, NATIVE.WindowMinWidth, NATIVE.WindowMinHeight, NATIVE.WindowMaxWidth, NATIVE.WindowMaxHeight)
    return widget
end

ZF.AG:RegisterNative("Frame", Type, Constructor, Version)