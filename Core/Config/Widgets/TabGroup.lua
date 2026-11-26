local _, ZF = ...
local AceGUI = LibStub("AceGUI-3.0")
local NATIVE = ZF.DesignerStyle.Native

local Type, Version = "ZF_TabGroup", 1

local function GetStatus(self)
    return self.status or self.localstatus
end

local function Tab_OnClick(tab)
    if tab.isDisabled then return end
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
    tab.obj:SelectTab(tab.value)
end

local function Tab_OnShow(tab)
    if tab.targetWidth then
        PanelTemplates_TabResize(tab, NATIVE.TabPadding, tab.targetWidth)
    end
end

local function CreateTab(self)
    local tab = CreateFrame("Button", nil, self.frame, "PanelTopTabButtonTemplate")
    tab.obj = self
    tab:SetScript("OnClick", Tab_OnClick)
    tab:HookScript("OnShow", Tab_OnShow)
    return tab
end

local function UpdateTabStates(self)
    local selected = GetStatus(self).selected
    for _, tab in ipairs(self.tabs) do
        if tab:IsShown() then
            if tab.isDisabled then
                PanelTemplates_SetDisabledTabState(tab)
            elseif tab.value == selected then
                PanelTemplates_SelectTab(tab)
            else
                PanelTemplates_DeselectTab(tab)
            end
        end
    end
end

local function LayoutTabs(self)
    local tablist = self.tablist
    if not tablist then return end
    local width = (self.frame.width or self.frame:GetWidth() or 0) - NATIVE.TabStartX
    local spacing = NATIVE.TabSpacing
    local widths = {}
    for index, info in ipairs(tablist) do
        local tab = self.tabs[index]
        if not tab then
            tab = CreateTab(self)
            self.tabs[index] = tab
        end
        tab.value = info.value
        tab.isDisabled = info.disabled and 1 or nil
        tab.targetWidth = nil
        tab:SetText(info.text)
        tab:Show()
        PanelTemplates_TabResize(tab, NATIVE.TabPadding)
        widths[index] = tab:GetWidth()
    end
    for index = #tablist + 1, #self.tabs do
        self.tabs[index]:Hide()
    end

    local function RowWidth(first, last)
        local total = 0
        for index = first, last do
            total = total + widths[index] + spacing
        end
        return total - spacing
    end

    local rowEnds, used = {}, 0
    for index = 1, #tablist do
        if used > 0 and used + widths[index] > width then
            rowEnds[#rowEnds + 1] = index - 1
            used = 0
        end
        used = used + widths[index] + spacing
    end
    rowEnds[#rowEnds + 1] = #tablist

    local rows = #rowEnds
    while rows > 1 do
        local previousStart = (rowEnds[rows - 2] or 0) + 1
        local previousEnd = rowEnds[rows - 1]
        local previousCount = previousEnd - previousStart + 1
        local lastCount = rowEnds[rows] - previousEnd
        if previousCount - lastCount < 2 or RowWidth(previousEnd, rowEnds[rows]) > width then break end
        rowEnds[rows - 1] = previousEnd - 1
    end

    local first = 1
    for row, last in ipairs(rowEnds) do
        local extra = 0
        if rows > 1 then
            extra = math.max((width - RowWidth(first, last)) / (last - first + 1), 0)
        end
        local x = 0
        for index = first, last do
            local tab = self.tabs[index]
            tab.targetWidth = extra > 0 and widths[index] + extra or nil
            if tab.targetWidth then
                PanelTemplates_TabResize(tab, NATIVE.TabPadding, tab.targetWidth)
            end
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x + NATIVE.TabStartX, -(row - 1) * NATIVE.TabRowPitch)
            x = x + tab:GetWidth() + spacing
        end
        first = last + 1
    end
    local stripHeight = NATIVE.TabHeight + (rows - 1) * NATIVE.TabRowPitch
    if stripHeight ~= self.stripHeight then
        self.stripHeight = stripHeight
        self.box:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -stripHeight)
    end
    UpdateTabStates(self)
end

local methods = {
    OnAcquire = function(self)
        self.tablist = nil
        self.stripHeight = NATIVE.TabHeight
        self.box:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -NATIVE.TabHeight)
    end,

    OnRelease = function(self)
        self.status = nil
        self.tablist = nil
        wipe(self.localstatus)
        for _, tab in ipairs(self.tabs) do
            tab:Hide()
        end
    end,

    SetStatusTable = function(self, status)
        self.status = status
    end,

    SetTabs = function(self, tabs)
        self.tablist = tabs
        LayoutTabs(self)
    end,

    SelectTab = function(self, value)
        GetStatus(self).selected = value
        local found = false
        for _, tab in ipairs(self.tabs) do
            if tab:IsShown() and tab.value == value then
                found = true
            end
        end
        UpdateTabStates(self)
        if found then
            self:Fire("OnGroupSelected", value)
        end
    end,

    OnWidthSet = function(self, width)
        local contentWidth = math.max(width - NATIVE.TabBoxInset * 2, 0)
        self.content:SetWidth(contentWidth)
        self.content.width = contentWidth
        LayoutTabs(self)
    end,

    OnHeightSet = function(self, height)
        local contentHeight = math.max(height - self.stripHeight - NATIVE.TabBoxInset * 2, 0)
        self.content:SetHeight(contentHeight)
        self.content.height = contentHeight
    end,

    LayoutFinished = function(self, _, height)
        if self.noAutoHeight then return end
        self:SetHeight((height or 0) + self.stripHeight + NATIVE.TabBoxInset * 2)
    end,
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()
    frame.tabPadding = NATIVE.TabPadding

    local box = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
    box:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -NATIVE.TabHeight)
    box:SetPoint("BOTTOMRIGHT")
    box.Bg:SetAlpha(NATIVE.TabBoxBackgroundAlpha)

    local content = CreateFrame("Frame", nil, box)
    content:SetPoint("TOPLEFT", box, "TOPLEFT", NATIVE.TabBoxInset, -NATIVE.TabBoxInset)
    content:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -NATIVE.TabBoxInset, NATIVE.TabBoxInset)

    local widget = {
        type = Type,
        frame = frame,
        box = box,
        content = content,
        tabs = {},
        localstatus = {},
        stripHeight = NATIVE.TabHeight,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    return AceGUI:RegisterAsContainer(widget)
end

ZF.AG:RegisterNative("TabGroup", Type, Constructor, Version)