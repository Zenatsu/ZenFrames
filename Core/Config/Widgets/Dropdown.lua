local _, ZF = ...
local AceGUI = LibStub("AceGUI-3.0")
local Kit = ZF.NativeKit
local NATIVE = ZF.DesignerStyle.Native

local function CompareKeys(a, b)
    if type(a) == type(b) then
        return a < b
    end
    return tostring(a) < tostring(b)
end

local function SortedKeys(list)
    local order = {}
    for key in pairs(list) do
        order[#order + 1] = key
    end
    table.sort(order, CompareKeys)
    return order
end

local function IsSelected(data)
    return data.widget.value == data.key
end

local function SelectItem(data)
    local self = data.widget
    self.value = data.key
    self:Fire("OnValueChanged", data.key)
end

local function IsItemChecked(data)
    return data.widget.itemValues[data.key] == true
end

local function ToggleItem(data)
    local self = data.widget
    local checked = not self.itemValues[data.key]
    self.itemValues[data.key] = checked or nil
    self:Fire("OnValueChanged", data.key, checked)
end

local function ShowItemTooltip(tooltip, description)
    local data = description:GetData()
    local self = data.widget
    GameTooltip_SetTitle(tooltip, self:GetItemText(data.key))
    GameTooltip_AddHighlightLine(tooltip, self.itemTooltips[data.key], true)
end

local function GenerateMenu(dropdown, rootDescription)
    local self = dropdown.obj
    for _, key in ipairs(self.order) do
        local data = { widget = self, key = key }
        local element
        if self.multiselect then
            element = rootDescription:CreateCheckbox(self:GetItemText(key), IsItemChecked, ToggleItem, data)
        else
            element = rootDescription:CreateRadio(self:GetItemText(key), IsSelected, SelectItem, data)
        end
        if self.disabledItems[key] then
            element:SetEnabled(false)
        end
        if self.itemTooltips and self.itemTooltips[key] then
            element:SetTooltip(ShowItemTooltip)
        end
        if self.decorate then
            self.decorate(self, element, key)
        end
    end
    if #self.order > NATIVE.DropdownMaxVisibleItems then
        rootDescription:SetScrollMode(NATIVE.DropdownItemHeight * NATIVE.DropdownMaxVisibleItems)
    end
end

local function MultiSelectionText(self)
    local texts = {}
    for _, key in ipairs(self.order) do
        if self.itemValues[key] then
            texts[#texts + 1] = self:GetItemText(key)
        end
    end
    if #texts == 0 then
        return NONE
    end
    if #texts > NATIVE.DropdownMaxSummaryItems then
        return NATIVE.DropdownSummaryFormat:format(#texts)
    end
    return table.concat(texts, ", ")
end

local function RefreshMenu(self)
    self.dropdown:GenerateMenu()
end

local methods = {
    OnAcquire = function(self)
        self.list, self.order = {}, {}
        self.itemValues, self.disabledItems = {}, {}
        self.itemTooltips = nil
        self.value = nil
        self.multiselect = false
        self.dropdown:SetSelectionText(nil)
        self:SetLabel()
        self:SetDisabled(false)
        self:SetWidth(200)
        RefreshMenu(self)
    end,

    OnRelease = function(self)
        self:ClearFocus()
    end,

    SetList = function(self, list, order)
        self.list = list or {}
        self.order = order or SortedKeys(self.list)
        RefreshMenu(self)
    end,

    AddItem = function(self, key, text)
        self.list[key] = text
        self.order[#self.order + 1] = key
        RefreshMenu(self)
    end,

    GetItemText = function(self, key)
        return self.list[key]
    end,

    SetValue = function(self, value)
        self.value = value
        RefreshMenu(self)
    end,

    GetValue = function(self)
        return self.value
    end,

    SetMultiselect = function(self, multiselect)
        self.multiselect = multiselect and true or false
        self.dropdown:SetSelectionText(self.multiselect and self.multiSelectionText or nil)
        RefreshMenu(self)
    end,

    GetMultiselect = function(self)
        return self.multiselect
    end,

    SetItemValue = function(self, key, value)
        self.itemValues[key] = value and true or nil
        RefreshMenu(self)
    end,

    SetItemDisabled = function(self, key, disabled)
        self.disabledItems[key] = disabled and true or nil
        RefreshMenu(self)
    end,

    SetItemTooltips = function(self, tooltips)
        self.itemTooltips = tooltips
        RefreshMenu(self)
    end,

    SetLabel = function(self, text)
        local top = Kit.SetLabelText(self.label, text) and NATIVE.LabelHeight + NATIVE.DropdownLabelGap or NATIVE.DropdownArtTop
        self.dropdown:SetPoint("TOPLEFT", self.frame, "TOPLEFT", NATIVE.DropdownArtSide, -top)
        self.dropdown:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -NATIVE.DropdownArtSide, -top)
        self:SetHeight(top + NATIVE.DropdownHeight + NATIVE.DropdownArtBottom)
        self.alignoffset = top + NATIVE.DropdownHeight / 2
    end,

    SetDisabled = function(self, disabled)
        self.disabled = disabled and true or false
        if self.disabled then
            self:ClearFocus()
        end
        self.dropdown:SetEnabled(not self.disabled)
        Kit.SetTextEnabled(self.label, not self.disabled)
    end,

    ClearFocus = function(self)
        if self.dropdown:IsMenuOpen() then
            self.dropdown:CloseMenu()
        end
    end,
}

local function MediaItemText(_, key)
    return key
end

local previewFonts, previewFontCount = {}, 0

local function GetPreviewFont(path)
    local font = previewFonts[path]
    if not font then
        previewFontCount = previewFontCount + 1
        font = CreateFont("ZF_FontPreview" .. previewFontCount)
        font:CopyFontObject(GameFontHighlight)
        font:SetFont(path, NATIVE.FontPreviewSize, "")
        previewFonts[path] = font
    end
    return font
end

local function DecorateFont(self, element, key)
    local path = self.list[key]
    element:AddInitializer(function(button)
        button.fontString:SetFontObject(GetPreviewFont(path))
    end)
end

local function DecorateStatusbar(self, element, key)
    local path = self.list[key]
    element:AddInitializer(function(button)
        local preview = button:AttachTexture()
        preview:SetTexture(path)
        preview:SetDrawLayer("BACKGROUND")
        preview:SetAlpha(NATIVE.StatusbarPreviewAlpha)
        preview:ClearAllPoints()
        preview:SetPoint("TOP", button.fontString, "TOP", 0, NATIVE.StatusbarPreviewPad)
        preview:SetPoint("BOTTOM", button.fontString, "BOTTOM", 0, -NATIVE.StatusbarPreviewPad)
        preview:SetPoint("LEFT", button.fontString, "LEFT", -NATIVE.StatusbarPreviewPad, 0)
        preview:SetPoint("RIGHT", button, "RIGHT", -2, 0)
    end)
end

local function CreateConstructor(widgetType, getItemText, decorate)
    return function()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:Hide()

        local label = Kit.CreateLabel(frame)
        label:SetPoint("TOPLEFT")
        label:SetPoint("TOPRIGHT")
        label:SetHeight(NATIVE.LabelHeight)

        local dropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
        dropdown:SetHeight(NATIVE.DropdownHeight)

        local widget = {
            type = widgetType,
            frame = frame,
            label = label,
            dropdown = dropdown,
            decorate = decorate,
            list = {},
            order = {},
            itemValues = {},
            disabledItems = {},
        }
        for method, func in pairs(methods) do
            widget[method] = func
        end
        if getItemText then
            widget.GetItemText = getItemText
        end
        widget.multiSelectionText = function()
            return MultiSelectionText(widget)
        end
        dropdown.obj = widget
        dropdown:SetupMenu(GenerateMenu)
        dropdown:HookScript("OnEnter", Kit.FireOnEnter)
        dropdown:HookScript("OnLeave", Kit.FireOnLeave)
        return AceGUI:RegisterAsWidget(widget)
    end
end

ZF.AG:RegisterNative("Dropdown", "ZF_Dropdown", CreateConstructor("ZF_Dropdown"), 1)
ZF.AG:RegisterNative("LSM30_Font", "ZF_FontDropdown", CreateConstructor("ZF_FontDropdown", MediaItemText, DecorateFont), 1)
ZF.AG:RegisterNative("LSM30_Statusbar", "ZF_StatusbarDropdown", CreateConstructor("ZF_StatusbarDropdown", MediaItemText, DecorateStatusbar), 1)