local _, ZF = ...
local AceGUI = LibStub("AceGUI-3.0")
local Kit = ZF.NativeKit
local NATIVE = ZF.DesignerStyle.Native

local InlineGroupType, InlineGroupVersion = "ZF_InlineGroup", 1
local HeadingType, HeadingVersion = "ZF_Heading", 1

local inlineGroupMethods = {
    OnAcquire = function(self)
        self:SetTitle("")
        self:SetWidth(300)
        self:SetHeight(100)
    end,

    SetTitle = function(self, title)
        local hasTitle = Kit.SetLabelText(self.titletext, title)
        self.divider:SetShown(hasTitle)
        self.topOffset = hasTitle and NATIVE.GroupTitleHeight or 0
        self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -self.topOffset)
    end,

    LayoutFinished = function(self, _, height)
        if self.noAutoHeight then return end
        self:SetHeight((height or 0) + self.topOffset + NATIVE.GroupBottomPadding)
    end,

    OnWidthSet = function(self, width)
        self.content:SetWidth(width)
        self.content.width = width
    end,

    OnHeightSet = function(self, height)
        local contentHeight = math.max(height - self.topOffset - NATIVE.GroupBottomPadding, 0)
        self.content:SetHeight(contentHeight)
        self.content.height = contentHeight
    end,
}

local function InlineGroupConstructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    local titletext = Kit.CreateLabel(frame, NATIVE.GroupTitleFont)
    titletext:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -4)
    titletext:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -4)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(NATIVE.DividerHeight)
    divider:SetPoint("TOPLEFT", titletext, "BOTTOMLEFT", -2, -4)
    divider:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    Kit.SetAtlasOrColor(divider, NATIVE.Atlases.Divider, NATIVE.Fallback.Divider)

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, NATIVE.GroupBottomPadding)

    local widget = {
        type = InlineGroupType,
        frame = frame,
        content = content,
        titletext = titletext,
        divider = divider,
        topOffset = 0,
    }
    for method, func in pairs(inlineGroupMethods) do
        widget[method] = func
    end
    return AceGUI:RegisterAsContainer(widget)
end

local headingMethods = {
    OnAcquire = function(self)
        self:SetText()
        self:SetFullWidth()
        self:SetHeight(NATIVE.HeadingHeight)
    end,

    SetText = function(self, text)
        if Kit.SetLabelText(self.label, text) then
            self.left:SetPoint("RIGHT", self.label, "LEFT", -6, 0)
            self.right:Show()
        else
            self.left:SetPoint("RIGHT", self.frame, "RIGHT", -2, 0)
            self.right:Hide()
        end
    end,
}

local function HeadingConstructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    local label = Kit.CreateLabel(frame, NATIVE.HeadingFont)
    label:SetPoint("CENTER")
    label:SetJustifyH("CENTER")

    local left = frame:CreateTexture(nil, "BACKGROUND")
    left:SetHeight(NATIVE.DividerHeight)
    left:SetPoint("LEFT", frame, "LEFT", 2, 0)
    Kit.SetAtlasOrColor(left, NATIVE.Atlases.Divider, NATIVE.Fallback.Divider)

    local right = frame:CreateTexture(nil, "BACKGROUND")
    right:SetHeight(NATIVE.DividerHeight)
    right:SetPoint("LEFT", label, "RIGHT", 6, 0)
    right:SetPoint("RIGHT", frame, "RIGHT", -2, 0)
    Kit.SetAtlasOrColor(right, NATIVE.Atlases.Divider, NATIVE.Fallback.Divider)

    local widget = {
        type = HeadingType,
        frame = frame,
        label = label,
        left = left,
        right = right,
    }
    for method, func in pairs(headingMethods) do
        widget[method] = func
    end
    return AceGUI:RegisterAsWidget(widget)
end

ZF.AG:RegisterNative("InlineGroup", InlineGroupType, InlineGroupConstructor, InlineGroupVersion)
ZF.AG:RegisterNative("Heading", HeadingType, HeadingConstructor, HeadingVersion)