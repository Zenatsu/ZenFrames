local _, ZF = ...
local AceGUI = LibStub("AceGUI-3.0")
local Kit = ZF.NativeKit
local NATIVE = ZF.DesignerStyle.Native

local Type, Version = "ZF_TreeGroup", 1

local function GetStatus(self)
    return self.status or self.localstatus
end

local function SplitPath(uniqueValue)
    local path = {}
    for part in tostring(uniqueValue):gmatch("[^\001]+") do
        path[#path + 1] = part
    end
    return path
end

local function Row_OnClick(row)
    local self = row.obj
    AceGUI:ClearFocus()
    if row.hasChildren then
        local groups = GetStatus(self).groups
        groups[row.uniqueValue] = not groups[row.uniqueValue]
        self:RefreshTree()
        return
    end
    self:Fire("OnClick", row.uniqueValue, row.isSelected)
    if not row.isSelected then
        self:SetSelected(row.uniqueValue)
        self:RefreshTree()
    end
end

local function AtlasOrNil(atlas)
    if atlas and C_Texture.GetAtlasExists(atlas) then return atlas end
end

local function SetSlice(texture, info, from, to)
    local left, width = info.leftTexCoord, info.rightTexCoord - info.leftTexCoord
    texture:SetTexture(info.file or info.filename)
    texture:SetTexCoord(left + width * from, left + width * to, info.topTexCoord, info.bottomTexCoord)
end

local function ApplyButtonArt(row, pressed)
    local style = NATIVE.NavButtonStyles[NATIVE.NavButtonStyle] or {}
    local selectedAtlas = AtlasOrNil(style.Selected)
    local atlas = pressed and AtlasOrNil(style.Pressed) or row.isSelected and selectedAtlas or AtlasOrNil(style.Normal)
    local middle, leftCap, rightCap = row.button, row.buttonLeft, row.buttonRight
    middle:ClearAllPoints()
    leftCap:ClearAllPoints()
    rightCap:ClearAllPoints()
    if not atlas then
        middle:Hide()
        leftCap:Hide()
        rightCap:Hide()
    else
        local inset = style.Inset or NATIVE.NavButtonInset
        local cap = style.Cap or NATIVE.NavButtonCap
        local info = C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
        if info and (info.file or info.filename) and cap > 0 and info.height > 0 then
            local capWidth = (row:GetHeight() - inset * 2) * info.width * cap / info.height
            leftCap:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -inset)
            leftCap:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, inset)
            leftCap:SetWidth(capWidth)
            rightCap:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -inset)
            rightCap:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, inset)
            rightCap:SetWidth(capWidth)
            middle:SetPoint("TOPLEFT", leftCap, "TOPRIGHT")
            middle:SetPoint("BOTTOMRIGHT", rightCap, "BOTTOMLEFT")
            SetSlice(leftCap, info, 0, cap)
            SetSlice(middle, info, cap, 1 - cap)
            SetSlice(rightCap, info, 1 - cap, 1)
            leftCap:Show()
            rightCap:Show()
        else
            middle:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -inset)
            middle:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, inset)
            middle:SetAtlas(atlas, false)
            leftCap:Hide()
            rightCap:Hide()
        end
        middle:Show()
    end
    row.selected:SetShown(row.isSelected and not selectedAtlas)
end

local function Row_OnMouseDown(row, mouseButton)
    if mouseButton == "LeftButton" then
        ApplyButtonArt(row, true)
    end
end

local function Row_OnMouseUp(row)
    ApplyButtonArt(row)
end

local function CreateRow(self)
    local row = CreateFrame("Button", nil, self.treeframe)
    row.obj = self
    row:SetHeight(NATIVE.NavRowHeight)
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", Row_OnClick)
    row:SetScript("OnMouseDown", Row_OnMouseDown)
    row:SetScript("OnMouseUp", Row_OnMouseUp)
    local hover = row:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints(row)
    Kit.SetAtlasOrColor(hover, NATIVE.Atlases.NavHover, NATIVE.Fallback.NavHover)

    row.button = row:CreateTexture(nil, "BACKGROUND", nil, -1)
    row.buttonLeft = row:CreateTexture(nil, "BACKGROUND", nil, -1)
    row.buttonRight = row:CreateTexture(nil, "BACKGROUND", nil, -1)

    row.selected = row:CreateTexture(nil, "BACKGROUND")
    row.selected:SetAllPoints(row)
    Kit.SetAtlasOrColor(row.selected, NATIVE.Atlases.NavSelected, NATIVE.Fallback.NavSelected)

    row.arrow = row:CreateTexture(nil, "OVERLAY")

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    row.label:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    return row
end

local function AddLines(self, lines, tree, level, parentPath)
    local groups = GetStatus(self).groups
    for _, entry in ipairs(tree) do
        if entry.visible ~= false then
            local uniqueValue = parentPath and (parentPath .. "\001" .. entry.value) or entry.value
            local hasChildren = entry.children ~= nil and #entry.children > 0
            local expanded = hasChildren and groups[uniqueValue] and true or false
            lines[#lines + 1] = { text = entry.text, uniqueValue = uniqueValue, level = level, hasChildren = hasChildren, expanded = expanded }
            if expanded then
                AddLines(self, lines, entry.children, level + 1, uniqueValue)
            end
        end
    end
end

local function SetupRow(self, row, line, top)
    local indent = NATIVE.NavIndent
    local height = NATIVE.NavRowHeights[line.level] or NATIVE.NavRowHeight
    local shift = (line.level - 1) * (NATIVE.NavLevelShift + NATIVE.NavLevelIndent)
    row.uniqueValue = line.uniqueValue
    row.isSelected = line.uniqueValue == GetStatus(self).selected
    row:SetHeight(height)
    ApplyButtonArt(row)
    row:ClearAllPoints()
    local scale = NATIVE.NavRowWidthScales[line.level] or 1
    row:SetPoint("TOPLEFT", self.treeframe, "TOPLEFT", shift, -top)
    row:SetWidth(math.max((GetStatus(self).treewidth - shift) * scale, 1))
    row.label:SetFontObject(line.level == 1 and "GameFontNormal" or "GameFontHighlightSmall")
    row.label:SetText(line.text)
    row.label:SetPoint("LEFT", row, "LEFT", indent, 0)
    row.hasChildren = line.hasChildren
    row.arrow:SetShown(line.hasChildren)
    if line.hasChildren then
        Kit.SetAtlasOrColor(row.arrow, NATIVE.Atlases.NavArrow, NATIVE.Fallback.NavArrow)
        row.arrow:SetSize(NATIVE.NavArrowSize, NATIVE.NavArrowSize)
        row.arrow:SetRotation(line.expanded and NATIVE.NavArrowExpandedRotation or NATIVE.NavArrowCollapsedRotation)
        row.arrow:ClearAllPoints()
        row.arrow:SetPoint("RIGHT", row, "RIGHT", -NATIVE.NavArrowInset, 0)
    end
    row:Show()
    return height
end

local methods = {
    OnAcquire = function(self)
        self:SetTreeWidth(NATIVE.NavDefaultWidth, false)
    end,

    OnRelease = function(self)
        self.status = nil
        self.tree = nil
        wipe(self.localstatus.groups)
        self.localstatus.selected = nil
        self.localstatus.fullwidth = nil
        for _, row in ipairs(self.rows) do
            row:Hide()
        end
    end,

    SetStatusTable = function(self, status)
        self.status = status
        status.groups = status.groups or {}
        status.treewidth = status.treewidth or NATIVE.NavDefaultWidth
        self:SetTreeWidth(status.treewidth, status.treesizable)
        self:RefreshTree()
    end,

    SetTree = function(self, tree)
        self.tree = tree
        self:RefreshTree()
    end,

    SetTreeWidth = function(self, treeWidth, resizable)
        if type(treeWidth) ~= "number" then
            treeWidth = NATIVE.NavDefaultWidth
        end
        local status = GetStatus(self)
        status.treewidth = treeWidth
        status.treesizable = resizable and true or false
        self.treeframe:SetWidth(treeWidth)
        self:RefreshTree()
        if status.fullwidth then
            self:OnWidthSet(status.fullwidth)
        end
    end,

    RefreshTree = function(self)
        local lines = {}
        if self.tree then
            AddLines(self, lines, self.tree, 1, nil)
        end
        local top = NATIVE.NavTopOffset
        for index, line in ipairs(lines) do
            local row = self.rows[index] or CreateRow(self)
            self.rows[index] = row
            top = top + SetupRow(self, row, line, top)
        end
        for index = #lines + 1, #self.rows do
            self.rows[index]:Hide()
        end
    end,

    SetSelected = function(self, value)
        local status = GetStatus(self)
        if status.selected ~= value then
            status.selected = value
            self:Fire("OnGroupSelected", value)
        end
    end,

    Select = function(self, uniqueValue, ...)
        local status = GetStatus(self)
        local path = { ... }
        for index = 1, #path do
            status.groups[table.concat(path, "\001", 1, index)] = true
        end
        status.selected = uniqueValue
        self:RefreshTree()
        self:Fire("OnGroupSelected", uniqueValue)
    end,

    SelectByPath = function(self, ...)
        self:Select(table.concat({ ... }, "\001"), ...)
    end,

    SelectByValue = function(self, uniqueValue)
        self:Select(uniqueValue, unpack(SplitPath(uniqueValue)))
    end,

    OnWidthSet = function(self, width)
        local status = GetStatus(self)
        status.fullwidth = width
        local contentWidth = math.max(width - status.treewidth - NATIVE.NavGap, 0)
        self.content:SetWidth(contentWidth)
        self.content.width = contentWidth
    end,

    OnHeightSet = function(self, height)
        self.content:SetHeight(height)
        self.content.height = height
    end,

    LayoutFinished = function(self, _, height)
        if self.noAutoHeight then return end
        self:SetHeight(height or 0)
    end,
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()

    local treeframe = CreateFrame("Frame", nil, frame)
    treeframe:SetPoint("TOPLEFT")
    treeframe:SetPoint("BOTTOMLEFT")
    treeframe:SetWidth(NATIVE.NavDefaultWidth)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", treeframe, "TOPRIGHT", NATIVE.NavGap / 2, 0)
    divider:SetPoint("BOTTOMLEFT", treeframe, "BOTTOMRIGHT", NATIVE.NavGap / 2, 0)
    divider:SetColorTexture(unpack(NATIVE.Fallback.Divider))

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", treeframe, "TOPRIGHT", NATIVE.NavGap, 0)
    content:SetPoint("BOTTOMRIGHT")

    local widget = {
        type = Type,
        frame = frame,
        treeframe = treeframe,
        content = content,
        rows = {},
        localstatus = { groups = {} },
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    return AceGUI:RegisterAsContainer(widget)
end

ZF.AG:RegisterNative("TreeGroup", Type, Constructor, Version)