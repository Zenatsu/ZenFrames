local _, ZF = ...
local AG = ZF.AG
local GUIWidgets = ZF.GUIWidgets
local STYLE = ZF.DesignerStyle
local GUIInternal = ZF.GUIInternal
local GetUnitDB = GUIInternal.GetUnitDB
local DisableAurasTestMode = GUIInternal.DisableAurasTestMode
local DisableAllTestModes = GUIInternal.DisableAllTestModes
local GenerateSupportText = GUIInternal.GenerateSupportText
local DesignerUnitTabs = GUIInternal.DesignerUnitTabs
local BuildMainNavigationTree = GUIInternal.BuildMainNavigationTree
local CreateGlobalToggleSettings = GUIInternal.CreateGlobalToggleSettings
local CreateFontSettings = GUIInternal.CreateFontSettings
local CreateTextureSettings = GUIInternal.CreateTextureSettings
local CreateRangeSettings = GUIInternal.CreateRangeSettings
local CreateGlobalTagSettings = GUIInternal.CreateGlobalTagSettings
local CreateCooldownTextSettings = GUIInternal.CreateCooldownTextSettings
local CreateColorSettings = GUIInternal.CreateColorSettings
local CreateTagReferenceSettings = GUIInternal.CreateTagReferenceSettings
local CreateProfileSettings = GUIInternal.CreateProfileSettings
local CreateUnitEnableToggles = GUIInternal.CreateUnitEnableToggles

local ZFGUI = {}
local isGUIOpen = false
local Container
local generalLastTab = "GlobalToggles"

function ZF:IsMainGUIShown()
    return Container ~= nil and Container:IsShown()
end

function ZF:IsMainGUIOpen()
    return isGUIOpen
end

function ZF:SetMainGUIShown(shown)
    if not Container then return end
    if shown then
        Container:Show()
    else
        local realOnClose = Container.events["OnClose"]
        Container.events["OnClose"] = function() end
        Container:Hide()
        Container.events["OnClose"] = realOnClose
    end
end

function ZF:CloseMainGUI()
    if not Container or not isGUIOpen then return end
    local onClose = Container.events and Container.events["OnClose"]
    if onClose then onClose(Container) end
end

function ZF:CreateGUI()
    if isGUIOpen then return end
    if InCombatLockdown() then return end

    isGUIOpen = true

    Container = AG:Create("Frame")
    Container:SetTitle(ZF.PRETTY_ADDON_NAME)
    Container:SetLayout("Fill")
    Container:SetWidth(STYLE.Layout.WindowWidth)
    Container:SetHeight(STYLE.Layout.WindowHeight)
    Container:EnableResize(false)
    Container:SetCallback("OnClose", function(widget) AG:Release(widget) isGUIOpen = false DisableAllTestModes() end)

    Container.frame:EnableKeyboard(true)
    Container.frame:SetPropagateKeyboardInput(true)
    Container.frame:SetScript("OnKeyDown", function(self, key)
        if key ~= "ESCAPE" then return end
        self:SetPropagateKeyboardInput(false)
        ZF:CloseAddonUI()
    end)
    Container.frame:SetScript("OnKeyUp", function(self) self:SetPropagateKeyboardInput(true) end)

    local designerPreviewRequestToken = 0

    local function SelectTab(GUIContainer, _, MainTab)
		MainTab = MainTab:match("[^\001]+$")
		if MainTab == "Designer" then
			ZFGUI.MainNavigationStatus.groups["Designer"] = true
			ZFGUI.MainNavigationStatus.selected = "Designer\001DesignerPlayer"
			GUIContainer:RefreshTree(true)
			MainTab = "DesignerPlayer"
		end
		if ZF.DESIGNER_PREVIEW_FRAME then ZF.DESIGNER_PREVIEW_FRAME:Hide() end
		if ZF.DESIGNER_DISABLED_LABEL then ZF.DESIGNER_DISABLED_LABEL:Hide() end
		GUIContainer:ReleaseChildren()
		ZF:ForEachUnitDB(function(_, unit) DisableAurasTestMode(unit) end)

        local Wrapper = AG:Create("SimpleGroup")
        Wrapper:SetFullWidth(true)
        Wrapper:SetFullHeight(true)
        Wrapper:SetLayout("Fill")
        GUIContainer:AddChild(Wrapper)
        local PreviewContainer, DesignerOptionsScroll, DesignerTabGroup, DesignerTabContentScroll

        if MainTab == "General" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            local function SelectGlobalTab(GlobalTabContainer, _, GlobalTab)
                generalLastTab = GlobalTab
                GlobalTabContainer:ReleaseChildren()
                if GlobalTab == "GlobalToggles" then CreateGlobalToggleSettings(GlobalTabContainer)
                elseif GlobalTab == "GlobalFonts" then CreateFontSettings(GlobalTabContainer)
                elseif GlobalTab == "GlobalTextures" then CreateTextureSettings(GlobalTabContainer)
                elseif GlobalTab == "GlobalRange" then CreateRangeSettings(GlobalTabContainer)
                elseif GlobalTab == "GlobalTags" then CreateGlobalTagSettings(GlobalTabContainer)
                elseif GlobalTab == "CooldownText" then CreateCooldownTextSettings(GlobalTabContainer)
                end
                ScrollFrame:DoLayout()
            end

            local GlobalTabGroup = AG:Create("TabGroup")
            GlobalTabGroup:SetLayout("Flow")
            GlobalTabGroup:SetFullWidth(true)
            GlobalTabGroup:SetTabs({
                { text = "Toggles", value = "GlobalToggles" },
                { text = "Fonts", value = "GlobalFonts" },
                { text = "Textures", value = "GlobalTextures" },
                { text = "Range", value = "GlobalRange" },
                { text = "Tag Settings", value = "GlobalTags" },
                { text = "Cooldown Text", value = "CooldownText" },
            })
            GlobalTabGroup:SetCallback("OnGroupSelected", SelectGlobalTab)
            GlobalTabGroup:SelectTab(generalLastTab)
            ScrollFrame:AddChild(GlobalTabGroup)

            CreateColorSettings(ScrollFrame)

            ScrollFrame:DoLayout()
        elseif MainTab == "Tags" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)
            CreateTagReferenceSettings(ScrollFrame)
            ScrollFrame:DoLayout()
        elseif MainTab == "Profiles" then
            local ScrollFrame = GUIWidgets.CreateScrollFrame(Wrapper)

            CreateProfileSettings(ScrollFrame)

            ScrollFrame:DoLayout()
        elseif DesignerUnitTabs[MainTab] then
            local unit = DesignerUnitTabs[MainTab]
            Wrapper:SetLayout("List")

            PreviewContainer = AG:Create("SimpleGroup")
            PreviewContainer:SetLayout("Fill")
            if STYLE.Layout.CanvasWidth then
                PreviewContainer:SetFullWidth(false)
                PreviewContainer:SetWidth(STYLE.Layout.CanvasWidth)
            else
                PreviewContainer:SetFullWidth(true)
            end
            PreviewContainer:SetAutoAdjustHeight(false)
            PreviewContainer:SetHeight(STYLE.Layout.CanvasHeight)
            Wrapper:AddChild(PreviewContainer)
            DesignerOptionsScroll = AG:Create("SimpleGroup")
            DesignerOptionsScroll:SetLayout("Flow")
            if STYLE.Layout.OptionsWidth then
                DesignerOptionsScroll:SetFullWidth(false)
                DesignerOptionsScroll:SetWidth(STYLE.Layout.OptionsWidth)
            else
                DesignerOptionsScroll:SetFullWidth(true)
            end
            Wrapper:AddChild(DesignerOptionsScroll)

            local DesignerSettingsContainer = AG:Create("SimpleGroup")
            DesignerSettingsContainer:SetFullWidth(true)
            DesignerSettingsContainer:SetLayout("Flow")
            DesignerOptionsScroll:AddChild(DesignerSettingsContainer)

            CreateUnitEnableToggles(DesignerSettingsContainer, unit)

            local ToggleMoversButton = AG:Create("Button")
            ToggleMoversButton:SetText("Unlock Movers")
            ToggleMoversButton:SetRelativeWidth(STYLE.Widths.Pct33)
            ToggleMoversButton:SetCallback("OnClick", function() ZF:ToggleMovers() end)
            DesignerSettingsContainer:AddChild(ToggleMoversButton)

            local hasCastBarPortrait = unit ~= "targettarget" and unit ~= "focustarget" and unit ~= "party" and unit ~= "raid" and unit ~= "Augmentation"
            local playerHasSecondaryPower = unit == "player" and (UnitClassBase("player") == "DEATHKNIGHT" or ZF:GetSecondaryPowerType() ~= nil)
            local requiresAlternativePowerBar = unit == "player" and ZF:RequiresAlternativePowerBar()
            local designerTab = {
                { text = "Frame", value = "Frame" },
                { text = "Heal Prediction", value = "HealPrediction" },
                { text = "Auras", value = "Auras" },
                { text = "Power Bar", value = "PowerBar" },
            }
            if hasCastBarPortrait then
                designerTab[#designerTab + 1] = { text = "Cast Bar", value = "CastBar" }
                designerTab[#designerTab + 1] = { text = "Portrait", value = "Portrait" }
            end
            designerTab[#designerTab + 1] = { text = "Indicators", value = "Indicators" }
            designerTab[#designerTab + 1] = { text = "Tags", value = "Tags" }

            if unit == "augmentation" then
                designerTab[#designerTab + 1] = { text = "Players", value = "Players"}
            end

            local nextPowerTabIndex = 4
            if playerHasSecondaryPower then
                table.insert(designerTab, nextPowerTabIndex, { text = "Secondary Power Bar", value = "SecondaryPowerBar"})
                nextPowerTabIndex = nextPowerTabIndex +1
            end
            if requiresAlternativePowerBar then
                table.insert(designerTab, nextPowerTabIndex, { text = "Alternative Power Bar", value = "AlternativePowerBar"})
            end

            local tabStripHeight = STYLE.Layout.TabStripHeight

            DesignerTabGroup = AG:Create("TabGroup")
            DesignerTabGroup:SetLayout("Flow")
            DesignerTabGroup:SetFullWidth(true)
            DesignerTabGroup:SetTabs(designerTab)
            DesignerTabGroup:SetCallback("OnGroupSelected", function(_, _, DesignerTab)
                local selected = ZF:GetDesignerSelectedEntry()
                if not (selected and selected.designerTab == DesignerTab) then
                    ZF:ClearDesignerSelection()
                end
                ZF:BuildDesignerSectionOptions(ZF.DESIGNER_OPTIONS_CONTAINER, unit, DesignerTab) end)

            DesignerTabContentScroll = GUIWidgets.CreateScrollFrame(DesignerTabGroup)
            DesignerTabContentScroll:SetHeight(STYLE.Layout.OptionsHeight - tabStripHeight)
            ZF.DESIGNER_OPTIONS_CONTAINER = DesignerTabContentScroll
            ZF.DESIGNER_TAB_GROUP = DesignerTabGroup
            DesignerSettingsContainer:AddChild(DesignerTabGroup)
            local startTab = GUIInternal.designerLastTab[unit] or "Frame"
            if startTab == "SecondaryPowerBar" and not playerHasSecondaryPower then startTab = "Frame" end
            if startTab == "AlternativePowerBar" and not requiresAlternativePowerBar then startTab = "Frame" end
            if (startTab == "CastBar" or startTab == "Portrait") and not hasCastBarPortrait then startTab = "Frame" end
            DesignerTabGroup:SelectTab(startTab)
        end
        if DesignerUnitTabs[MainTab] then
            local unit = DesignerUnitTabs[MainTab]
            local canvasFrame = PreviewContainer.frame
            designerPreviewRequestToken = designerPreviewRequestToken + 1
            local requestToken = designerPreviewRequestToken
            if GetUnitDB(unit).Enabled then
                C_Timer.After(0, function()
                    if requestToken ~= designerPreviewRequestToken then return end
                    if canvasFrame:IsShown() then ZF:ShowDesignerPreview(canvasFrame, unit, DesignerTabContentScroll) end
                end)
            else
                ZF:HideDesignerPreview()
                if not ZF.DESIGNER_DISABLED_LABEL then
                    ZF.DESIGNER_DISABLED_LABEL = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                end
                ZF.DESIGNER_DISABLED_LABEL:SetParent(canvasFrame)
                ZF.DESIGNER_DISABLED_LABEL:ClearAllPoints()
                ZF.DESIGNER_DISABLED_LABEL:SetPoint("CENTER", canvasFrame, "CENTER", 0, 0)
                ZF.DESIGNER_DISABLED_LABEL:SetText("Unit Frame Disabled")
                ZF.DESIGNER_DISABLED_LABEL:Show()
            end
        else
            designerPreviewRequestToken = designerPreviewRequestToken + 1
            ZF:HideDesignerPreview()
        end
        GenerateSupportText(Container)
    end

    local mainNavigationTree = BuildMainNavigationTree()
    local mainNavigationValues = {}
    for _, entry in ipairs(mainNavigationTree) do
        mainNavigationValues[entry.value] = true
		for _, child in ipairs(entry.children or {}) do mainNavigationValues[entry.value .. "\001" .. child.value] = true end
    end

    ZFGUI.MainNavigationStatus = ZFGUI.MainNavigationStatus or {}

    local ContainerTreeGroup = AG:Create("TreeGroup")
    ContainerTreeGroup:SetLayout("Fill")
    ContainerTreeGroup:SetFullWidth(true)
    ContainerTreeGroup:SetFullHeight(true)
    ContainerTreeGroup:SetStatusTable(ZFGUI.MainNavigationStatus)
    ContainerTreeGroup:SetTreeWidth(220, false)
    ContainerTreeGroup:SetTree(mainNavigationTree)
    ContainerTreeGroup:SetCallback("OnGroupSelected", SelectTab)
    Container:AddChild(ContainerTreeGroup)
    ZFGUI.MainNavigation = ContainerTreeGroup

    local initialSection = ZFGUI.MainNavigationStatus.selected
    if not initialSection or not mainNavigationValues[initialSection] then
        initialSection = "General"
    end
    ContainerTreeGroup:SelectByValue(initialSection)
end

function ZF:OpenGUIToUnit(unit)
    if InCombatLockdown() then return end
	if unit == "augmentation" and not ZF:IsAugmentationEvoker() then return end
    ZF:CreateGUI()
	if ZFGUI.MainNavigation then ZFGUI.MainNavigation:SelectByValue("Designer\001Designer" .. (unit == "augmentation" and "Aug" or unit == "targettarget" and "TargetTarget" or unit == "focustarget" and "FocusTarget" or unit:gsub("^%l", string.upper))) end
end
