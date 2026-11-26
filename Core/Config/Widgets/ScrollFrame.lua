local _, ZF = ...
local AceGUI = LibStub("AceGUI-3.0")
local NATIVE = ZF.DesignerStyle.Native

local Type, Version = "ZF_ScrollFrame", 1

local function SetBarShown(self, shown)
    if self.barShown == shown then return end
    self.barShown = shown
    self.scrollbar:SetShown(shown)
    self.scrollframe:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", shown and -NATIVE.ScrollBarSpace or 0, 0)
    local width = self.frame.width or self.frame:GetWidth()
    if width then
        self:OnWidthSet(width)
    end
end

local function ScrollFrame_OnScrollRangeChanged(scrollframe, _, verticalRange)
    SetBarShown(scrollframe.obj, (verticalRange or 0) > 0.5)
end

local methods = {
    OnAcquire = function(self)
        self.scrollframe:SetVerticalScroll(0)
        SetBarShown(self, false)
    end,

    OnRelease = function(self)
        self.status = nil
        self.scrollframe:SetVerticalScroll(0)
    end,

    SetScroll = function(self, value)
        self.scrollframe:SetVerticalScroll(self.scrollframe:GetVerticalScrollRange() * (value or 0) / 1000)
    end,

    SetStatusTable = function(self, status)
        self.status = status
    end,

    LayoutFinished = function(self, _, height)
        self.content:SetHeight(math.max(height or 0, 1))
        self.scrollframe:UpdateScrollChildRect()
        SetBarShown(self, self.scrollframe:GetVerticalScrollRange() > 0.5)
    end,

    OnWidthSet = function(self, width)
        local contentWidth = math.max(width - (self.barShown and NATIVE.ScrollBarSpace or 0), 0)
        self.content:SetWidth(contentWidth)
        self.content.width = contentWidth
    end,

    OnHeightSet = function(self, height)
        self.content.height = height
    end,
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    local scrollframe = CreateFrame("ScrollFrame", nil, frame)
    scrollframe:SetPoint("TOPLEFT")
    scrollframe:SetPoint("BOTTOMRIGHT")
    scrollframe:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scrollframe)
    content:SetPoint("TOPLEFT")
    content:SetSize(1, 1)
    scrollframe:SetScrollChild(content)

    local scrollbar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    scrollbar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -NATIVE.ScrollBarInset, -NATIVE.ScrollBarInset)
    scrollbar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -NATIVE.ScrollBarInset, NATIVE.ScrollBarInset)
    scrollbar:Hide()

    ScrollUtil.InitScrollFrameWithScrollBar(scrollframe, scrollbar)
    scrollframe:HookScript("OnScrollRangeChanged", ScrollFrame_OnScrollRangeChanged)

    local widget = {
        type = Type,
        frame = frame,
        scrollframe = scrollframe,
        scrollbar = scrollbar,
        content = content,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    scrollframe.obj = widget
    return AceGUI:RegisterAsContainer(widget)
end

ZF.AG:RegisterNative("ScrollFrame", Type, Constructor, Version)