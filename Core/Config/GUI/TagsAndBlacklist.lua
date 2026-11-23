local _, ZF = ...
local AG = ZF.AG
local GUIWidgets = ZF.GUIWidgets
local GUIBuilders = ZF.GUIBuilders
local STYLE = ZF.DesignerStyle
local GUIInternal = ZF.GUIInternal
local GetUnitDB = GUIInternal.GetUnitDB
local GetSavedSubTab = GUIInternal.GetSavedSubTab
local UpdateUnitSettings = GUIInternal.UpdateUnitSettings
local CreateDesignerPreviewToggle = GUIInternal.CreateDesignerPreviewToggle
local designerLastTab = GUIInternal.designerLastTab
local CreateFrameSettings = GUIInternal.CreateFrameSettings
local CreateAugmentationFrameSettings = GUIInternal.CreateAugmentationFrameSettings
local CreateHealPredictionSettings = GUIInternal.CreateHealPredictionSettings
local CreatePowerBarSettings = GUIInternal.CreatePowerBarSettings
local CreateSecondaryPowerBarSettings = GUIInternal.CreateSecondaryPowerBarSettings
local CreateAlternativePowerBarSettings = GUIInternal.CreateAlternativePowerBarSettings
local CreateCastBarSettings = GUIInternal.CreateCastBarSettings
local CreatePortraitSettings = GUIInternal.CreatePortraitSettings
local CreateIndicatorSettings = GUIInternal.CreateIndicatorSettings

local function AppendTagValue(TagDB, unit, tagDB, EditBox, UpdateTag, value)
    local currentTag = TagDB.Tag
    if currentTag and currentTag ~= "" then
        currentTag = currentTag .. "[" .. value .. "]"
    else
        currentTag = "[" .. value .. "]"
    end
    EditBox:SetText(currentTag)
    GetUnitDB(unit).Tags[tagDB].Tag = currentTag
    UpdateTag()
end

local function CreateTagCategoryDropdown(parent, category, label, TagDB, unit, tagDB, EditBox, UpdateTag)
    local Dropdown = AG:Create("Dropdown")
    Dropdown:SetList(ZF:FetchTagData(category)[1], ZF:FetchTagData(category)[2])
    Dropdown:SetLabel(label)
    Dropdown:SetValue(nil)
    Dropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    Dropdown:SetCallback("OnValueChanged", function(_, _, value)
        AppendTagValue(TagDB, unit, tagDB, EditBox, UpdateTag, value)
        Dropdown:SetValue(nil)
    end)
    if category == "Misc" then Dropdown:SetDisabled(#ZF:FetchTagData("Misc") == 0) end
    parent:AddChild(Dropdown)
    return Dropdown
end

local function CreateTagSetting(containerParent, unit, tagDB, updateCallback)
	local TagDB = GetUnitDB(unit).Tags[tagDB]
	local function UpdateTag()
		ZF:UpdateUnitTags(unit, tagDB)
        if updateCallback then updateCallback() end
	end

    local TagContainer = GUIWidgets.CreateInlineGroup(containerParent, "Tag Settings")

    local EditBox = AG:Create("EditBox")
    EditBox:SetLabel("Tag")
    EditBox:SetText(TagDB.Tag)
    EditBox:SetRelativeWidth(STYLE.Widths.Pct50)
    EditBox:DisableButton(true)
    EditBox:SetCallback("OnEnterPressed", function(_, _, value) TagDB.Tag = value EditBox:SetText(TagDB.Tag) UpdateTag() end)
    TagContainer:AddChild(EditBox)

    local ColorPicker = AG:Create("ColorPicker")
    ColorPicker:SetLabel("Color")
    ColorPicker:SetColor(TagDB.Color[1], TagDB.Color[2], TagDB.Color[3], 1)
    ColorPicker:SetFullWidth(true)
    ColorPicker:SetCallback("OnValueChanged", function(_, _, r, g, b) TagDB.Color = {r, g, b} UpdateTag() end)
    ColorPicker:SetHasAlpha(false)
    ColorPicker:SetRelativeWidth(STYLE.Widths.Pct50)
    TagContainer:AddChild(ColorPicker)

    local LayoutContainer = GUIBuilders.CreateLayoutPositionBlock(containerParent, TagDB, UpdateTag, {includeSize = true, sizeKey = "FontSize", sizeLabel = "Font Size", xyWidth = STYLE.Widths.Pct33})
    GUIBuilders.CreateDropdown(LayoutContainer, "Frame Strata", TagDB, "FrameStrata", UpdateTag, {list = GUIBuilders.FrameStrataList[1], order = GUIBuilders.FrameStrataList[2], width = STYLE.Widths.Pct33})

    local TagSelectionContainer = GUIWidgets.CreateInlineGroup(containerParent, "Tag Selection")
    GUIWidgets.CreateInformationTag(TagSelectionContainer, "You can use the dropdowns below to quickly add tags.\n|cFFFFD100Prefix|r indicates that this should be added to the start of the tag string.")

    CreateTagCategoryDropdown(TagSelectionContainer, "Health", "Health Tags", TagDB, unit, tagDB, EditBox, UpdateTag)
    CreateTagCategoryDropdown(TagSelectionContainer, "Power", "Power Tags", TagDB, unit, tagDB, EditBox, UpdateTag)
    CreateTagCategoryDropdown(TagSelectionContainer, "Name", "Name Tags", TagDB, unit, tagDB, EditBox, UpdateTag)
    CreateTagCategoryDropdown(TagSelectionContainer, "Misc", "Misc Tags", TagDB, unit, tagDB, EditBox, UpdateTag)

    containerParent:DoLayout()
end

local CreateTagsSettings

local function BubbleDesignerLayout(container)
    local hops = 0
    local ancestor = container
    while ancestor and ancestor.parent and hops < 2 do
        ancestor = ancestor.parent
        ancestor:DoLayout()
        hops = hops+1
    end
end

function ZF:BuildDesignerSectionOptions(container, unit, tabValue)
    if not (container and container.frame) then return end
    if tabValue then
        designerLastTab[unit] = tabValue
    else
        tabValue = designerLastTab[unit] or "Frame"
    end
    container:ReleaseChildren()

    local function RefreshDesignerPreview()
        ZF:UpdateDesignerPreviewFrame()
        ZF:AnchorDesignerOverlays()
    end

    local playerHasSecondaryPower = UnitClassBase("player") == "DEATHKNIGHT" or ZF:GetSecondaryPowerType() ~= nil

    if tabValue == "Frame" then
        CreateFrameSettings(container, unit, function(element) UpdateUnitSettings(unit, function() ZF:UpdateUnitFrame(ZF[unit:upper()], unit) end, element) end)
    elseif tabValue == "HealPrediction" then
        CreateDesignerPreviewToggle(container, "HealPrediction", function() UpdateUnitSettings(unit, function() ZF:UpdateUnitHealPrediction(ZF[unit:upper()], unit) end, "HealPrediction") end)
        CreateHealPredictionSettings(container, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitHealPrediction(ZF[unit:upper()], unit) end, "HealPrediction") end)
    elseif tabValue == "Auras" then
        GUIInternal.CreateAuraSettings(container, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitAuras(ZF[unit:upper()], unit) end, "Auras") end)
    elseif tabValue == "PowerBar" then
        CreatePowerBarSettings(container, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitPowerBar(ZF[unit:upper()], unit) end, "PowerBar") end)
    elseif tabValue == "SecondaryPowerBar" and unit == "player" and playerHasSecondaryPower then
        CreateSecondaryPowerBarSettings(container, unit, function() ZF:UpdateUnitSecondaryPowerBar(ZF[unit:upper()], unit) RefreshDesignerPreview() end)
    elseif tabValue == "AlternativePowerBar" and unit == "player" and ZF:RequiresAlternativePowerBar() then
        CreateAlternativePowerBarSettings(container, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitAlternativePowerBar(ZF[unit:upper()], unit) end) end)
    elseif tabValue == "CastBar" then
        CreateDesignerPreviewToggle(container, "CastBar", function() UpdateUnitSettings(unit, function() ZF:UpdateUnitCastBar(ZF[unit:upper()], unit) end, "CastBar") end)
        CreateCastBarSettings(container, unit)
    elseif tabValue == "PetXPBar" and unit == "pet" and ZF:UsesPetXPBar() then
        GUIInternal.CreatePetXPBarSettings(container, unit)
    elseif tabValue == "Portrait" then
        CreatePortraitSettings(container, unit, function() UpdateUnitSettings(unit, function() ZF:UpdateUnitPortrait(ZF[unit:upper()], unit) end, "Portrait") end)
    elseif tabValue == "Indicators" then
        CreateIndicatorSettings(container, unit)
    elseif tabValue == "Tags" then
        CreateTagsSettings(container, unit)
    elseif tabValue == "Players" then
        CreateAugmentationFrameSettings(container)
    end

    container:DoLayout()
    BubbleDesignerLayout(container)
end

function CreateTagsSettings(containerParent, unit)

    local function SelectTagTab(TagContainer, _, TagTab)
        ZF:SaveSubTab(unit, "Tags", TagTab)
        TagContainer:ReleaseChildren()
        CreateTagSetting(TagContainer, unit, TagTab, function() UpdateUnitSettings(unit, nil, "Tags") end)
        containerParent:DoLayout()
    end

    local TagContainerTabGroup = AG:Create("TabGroup")
    TagContainerTabGroup:SetLayout("Flow")
    TagContainerTabGroup:SetFullWidth(true)
    TagContainerTabGroup:SetTabs({
        { text = "Tag One", value = "TagOne"},
        { text = "Tag Two", value = "TagTwo"},
        { text = "Tag Three", value = "TagThree"},
        { text = "Tag Four", value = "TagFour"},
        { text = "Tag Five", value = "TagFive"},
    })
    TagContainerTabGroup:SetCallback("OnGroupSelected", SelectTagTab)
    TagContainerTabGroup:SelectTab(GetSavedSubTab(unit, "Tags", "TagOne"))
    containerParent:AddChild(TagContainerTabGroup)

    containerParent:DoLayout()
end

StaticPopupDialogs["ZF_INVALID_SPELL_ID"] = {
    text = "Not a valid spell ID.",
    button1 = OKAY,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["ZF_RESTORE_DEFAULT_BLACKLIST"] = {
    text = "This will remove all custom entries and restore to the default blacklist. Continue?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        ZF:RestoreDefaultAuraBlacklist()
        ZF:RefreshAuraBlacklistWindow()
        ZF:UpdateAllUnitFrames()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local AuraBlacklistWindow
local selectedSpellIds = {}

local function UpdateDeleteSelectedButtonState()
    if not AuraBlacklistWindow or not AuraBlacklistWindow.DeleteSelectedButton then return end
    AuraBlacklistWindow.DeleteSelectedButton:SetDisabled(not next(selectedSpellIds))
end

local function CreateAuraBlacklistWindow(RowScroll)
    RowScroll:ReleaseChildren()
    wipe(selectedSpellIds)
    local ids = {}
    for spellId in pairs (ZF.db.global.AuraBlacklist) do ids[#ids + 1] = spellId end
    table.sort(ids)

    for _, spellId in ipairs(ids) do
        local info = C_Spell.GetSpellInfo(spellId)
        local Row = AG:Create("SimpleGroup")
        Row:SetLayout("Flow")
        Row:SetFullWidth(true)

        local RowHighlight = Row.frame.RowHighlight
        if not RowHighlight then
            RowHighlight = Row.frame:CreateTexture(nil, "BACKGROUND")
            RowHighlight:SetAllPoints()
            RowHighlight:SetColorTexture(STYLE.Palette.Selected[1], STYLE.Palette.Selected[2], STYLE.Palette.Selected[3], 0.15)
            Row.frame.RowHighlight = RowHighlight
        end
        RowHighlight:SetShown(selectedSpellIds[spellId] or false)

        local SelectCheckbox = AG:Create("CheckBox")
        SelectCheckbox:SetLabel("")
        SelectCheckbox:SetValue(selectedSpellIds[spellId] or false)
        SelectCheckbox:SetWidth(30)
        SelectCheckbox:SetCallback("OnValueChanged", function(_,_, value)
            selectedSpellIds[spellId] = value or nil
            UpdateDeleteSelectedButtonState()
            RowHighlight:SetShown(value)
            end)
        Row:AddChild(SelectCheckbox)

        local NameLabel = AG:Create("Label")
        NameLabel:SetText(("|T%s:26:26|t %s |cFF999999(%d)|r"):format(info and info.iconID or 134400, info and info.name or "Unknown Spell", spellId))
        NameLabel:SetFont(ZF.Media.Font, 14, ZF.db.profile.General.Fonts.FontFlag)
        NameLabel:SetRelativeWidth(STYLE.Widths.Pct60)
        Row:AddChild(NameLabel)

        local DeleteButton = AG:Create("Button")
        DeleteButton:SetText("Delete")
        DeleteButton:SetRelativeWidth(STYLE.Widths.Pct20)
        DeleteButton:SetCallback("OnClick", function()
            ZF.db.global.AuraBlacklist[spellId] = nil
            ZF.auraBlacklistGeneration = (ZF.auraBlacklistGeneration or 0) +1
            ZF:RefreshAuraBlacklistWindow()
            ZF:UpdateAllUnitFrames()
        end)
        Row:AddChild(DeleteButton)
        RowScroll:AddChild(Row)
    end
    UpdateDeleteSelectedButtonState()
end

function ZF:ShowAuraBlacklistWindow()
    if InCombatLockdown() then return end

    if not AuraBlacklistWindow then
        AuraBlacklistWindow = AG:Create("Frame")
        AuraBlacklistWindow:SetTitle("Aura Blacklist - Advanced")
        AuraBlacklistWindow:SetLayout("Flow")
        AuraBlacklistWindow:SetWidth(STYLE.Layout.AuraBlacklistWindowWidth)
        AuraBlacklistWindow:SetHeight(STYLE.Layout.AuraBlacklistWindowHeight)
        AuraBlacklistWindow:EnableResize(false)
        AuraBlacklistWindow:SetCallback("OnClose", function(widget) widget:Hide() end)

        AuraBlacklistWindow.frame:SetBackdrop({
            bgFile = "Interface\\FrameGeneral\\UI-Background-Marble",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = false, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        AuraBlacklistWindow.frame:SetBackdropColor(1,1,1,1)
        AuraBlacklistWindow.statustext:GetParent():Hide()

        local AddRow = AG:Create("SimpleGroup")
        AddRow:SetLayout("Flow")
        AddRow:SetFullWidth(true)

        local IDEditBox = AG:Create("EditBox")
        IDEditBox:SetLabel("Spell ID")
        IDEditBox:SetRelativeWidth(STYLE.Widths.Pct60)
        IDEditBox:DisableButton(true)

        local function TryAddSpell()
            local spellId = tonumber(IDEditBox:GetText())
            if not spellId or not C_Spell.GetSpellInfo(spellId) then
                local popup = StaticPopup_Show("ZF_INVALID_SPELL_ID")
                if popup then popup:SetFrameStrata("TOOLTIP") end
                return
            end
            ZF.db.global.AuraBlacklist[spellId] = true
            ZF.auraBlacklistGeneration = (ZF.auraBlacklistGeneration or 0) + 1
            IDEditBox:SetText("")
            ZF:RefreshAuraBlacklistWindow()
            ZF:UpdateAllUnitFrames()
        end

        IDEditBox:SetCallback("OnEnterPressed", TryAddSpell)

        local AddButton = AG:Create("Button")
        AddButton:SetText("Add")
        AddButton:SetRelativeWidth(STYLE.Widths.Pct40)
        AddButton:SetCallback("OnClick", TryAddSpell)

        AddRow:AddChild(IDEditBox)
        AddRow:AddChild(AddButton)
        AuraBlacklistWindow:AddChild(AddRow)

        local RowScroll = GUIWidgets.CreateScrollFrame(AuraBlacklistWindow)
        RowScroll:SetHeight(STYLE.Layout.AuraBlacklistRowScrollHeight)
        AuraBlacklistWindow.RowScroll = RowScroll

        local BottomRow = AG:Create("SimpleGroup")
        BottomRow:SetLayout("Flow")
        BottomRow:SetFullWidth(true)

        local RestoreButton = AG:Create("Button")
        RestoreButton:SetText("Restore to Default")
        RestoreButton:SetRelativeWidth(STYLE.Widths.Pct50)
        RestoreButton:SetCallback("OnClick", function()
            local popup = StaticPopup_Show("ZF_RESTORE_DEFAULT_BLACKLIST")
            if popup then popup:SetFrameStrata("TOOLTIP") end
        end)
        BottomRow:AddChild(RestoreButton)

        local DeleteSelectedButton = AG:Create("Button")
        DeleteSelectedButton:SetText("Delete Selected")
        DeleteSelectedButton:SetRelativeWidth(STYLE.Widths.Pct50)
        DeleteSelectedButton:SetDisabled(true)
        DeleteSelectedButton:SetCallback("OnClick", function()
            for spellId in pairs(selectedSpellIds) do
                ZF.db.global.AuraBlacklist[spellId] = nil
            end
            wipe(selectedSpellIds)
            ZF.auraBlacklistGeneration = (ZF.auraBlacklistGeneration or 0) + 1
            ZF:RefreshAuraBlacklistWindow()
            ZF:UpdateAllUnitFrames()
        end)
        AuraBlacklistWindow.DeleteSelectedButton = DeleteSelectedButton
        BottomRow:AddChild(DeleteSelectedButton)
        AuraBlacklistWindow:AddChild(BottomRow)
    end

    CreateAuraBlacklistWindow(AuraBlacklistWindow.RowScroll)
    AuraBlacklistWindow:Show()
    AuraBlacklistWindow.frame:Raise()
end

function ZF:RefreshAuraBlacklistWindow()
    if not AuraBlacklistWindow or not AuraBlacklistWindow:IsShown() then return end
    CreateAuraBlacklistWindow(AuraBlacklistWindow.RowScroll)
end
