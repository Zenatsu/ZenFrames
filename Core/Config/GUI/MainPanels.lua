local _, ZF = ...
local AG = ZF.AG
local GUIWidgets = ZF.GUIWidgets
local GUIBuilders = ZF.GUIBuilders
local STYLE = ZF.DesignerStyle
local GUIInternal = ZF.GUIInternal
local GetUnitDB = GUIInternal.GetUnitDB
local UnitDBToUnitStylizedName = GUIInternal.UnitDBToUnitStylizedName

local function CreateClearFocusEditBox(parent, label, width)
    local editBox = AG:Create("EditBox")
    editBox:SetLabel(label)
    editBox:SetText("")
    editBox:SetRelativeWidth(width)
    editBox:DisableButton(true)
    editBox:SetCallback("OnEnterPressed", function() editBox:ClearFocus() end)
    editBox:SetCallback("OnTextChanged", function() editBox:ClearFocus() end)
    parent:AddChild(editBox)
    return editBox
end

local function CreateGlobalToggleSettings(containerParent)
    local ToggleContainer = GUIWidgets.CreateInlineGroup(containerParent, "Toggles")

    local ToggleMoversButton = AG:Create("Button")
    ToggleMoversButton:SetText(ZF.MOVERS_UNLOCKED and "Lock Movers" or "Unlock Movers")
    ToggleMoversButton:SetRelativeWidth(STYLE.Widths.Pct33)
    ToggleMoversButton:SetCallback("OnClick", function() ZF:ToggleMovers() end)
    ToggleContainer:AddChild(ToggleMoversButton)

    local DisplayLoginMessageToggle = AG:Create("CheckBox")
    DisplayLoginMessageToggle:SetLabel("Display Login Message")
    DisplayLoginMessageToggle:SetValue(ZF.db.global.DisplayLoginMessage)
    DisplayLoginMessageToggle:SetCallback("OnValueChanged", function(_, _, value) ZF.db.global.DisplayLoginMessage = value end)
    DisplayLoginMessageToggle:SetRelativeWidth(STYLE.Widths.Pct33)
    ToggleContainer:AddChild(DisplayLoginMessageToggle)

    local ShowGameMenuButtonToggle = AG:Create("CheckBox")
    ShowGameMenuButtonToggle:SetLabel("Show Game Menu Button")
    ShowGameMenuButtonToggle:SetValue(ZF.db.global.ShowGameMenuButton)
    ShowGameMenuButtonToggle:SetCallback("OnValueChanged", function(_, _, value)
        ZF.db.global.ShowGameMenuButton = value
        if GameMenuFrame then GameMenuFrame:Layout() end
    end)
    ShowGameMenuButtonToggle:SetRelativeWidth(STYLE.Widths.Pct33)
    ToggleContainer:AddChild(ShowGameMenuButtonToggle)
end

local function CreateGlobalTagSettings(containerParent)
    local TagContainer = GUIWidgets.CreateInlineGroup(containerParent, "Tag Settings")

    local UseCustomAbbreviationsCheckbox = AG:Create("CheckBox")
    UseCustomAbbreviationsCheckbox:SetLabel("Custom Abbreviations")
    UseCustomAbbreviationsCheckbox:SetValue(ZF.db.profile.General.UseCustomAbbreviations)
    UseCustomAbbreviationsCheckbox:SetCallback("OnValueChanged", function(_, _, value) ZF.db.profile.General.UseCustomAbbreviations = value ZF:ForEachUnitDB(function(_, unit) ZF:UpdateUnitTags(unit) end) end)
    UseCustomAbbreviationsCheckbox:SetRelativeWidth(STYLE.Widths.Pct25)
    TagContainer:AddChild(UseCustomAbbreviationsCheckbox)

    local TagIntervalSlider = AG:Create("Slider")
    TagIntervalSlider:SetLabel("Tag Updates Per Second")
    TagIntervalSlider:SetValue(1 / ZF.db.profile.General.TagUpdateInterval)
    TagIntervalSlider:SetSliderValues(unpack(STYLE.Sliders.TagUpdateRate))
    TagIntervalSlider:SetRelativeWidth(STYLE.Widths.Pct25)
    TagIntervalSlider:SetCallback("OnValueChanged", function(_, _, value) ZF.TAG_UPDATE_INTERVAL = 1 / value ZF.db.profile.General.TagUpdateInterval = 1 / value ZF:SetTagUpdateInterval() ZF:ForEachUnitDB(function(_, unit) ZF:UpdateUnitTags(unit) end) end)
    TagContainer:AddChild(TagIntervalSlider)

    local SeparatorDropdown = AG:Create("Dropdown")
    SeparatorDropdown:SetList(ZF.SEPARATOR_TAGS[1], ZF.SEPARATOR_TAGS[2])
    SeparatorDropdown:SetLabel("Tag Separator")
    SeparatorDropdown:SetValue(ZF.db.profile.General.Separator)
    SeparatorDropdown:SetRelativeWidth(STYLE.Widths.Pct25)
    SeparatorDropdown:SetCallback("OnValueChanged", function(_, _, value) ZF.db.profile.General.Separator = value ZF:ForEachUnitDB(function(_, unit) ZF:UpdateUnitTags(unit) end) end)
    SeparatorDropdown:SetCallback("OnEnter", function() GameTooltip:SetOwner(SeparatorDropdown.frame, "ANCHOR_BOTTOM") GameTooltip:AddLine("The separator chosen here is only applied to custom tags which are combined. Such as |cFFFFD100[curhpperhp]|r or |cFFFFD100[curhpperhp:abbr]|r", 1, 1, 1) GameTooltip:Show() end)
    SeparatorDropdown:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    TagContainer:AddChild(SeparatorDropdown)

    local ToTSeparatorDropdown = AG:Create("Dropdown")
    ToTSeparatorDropdown:SetList(ZF.TOT_SEPARATOR_TAGS[1], ZF.TOT_SEPARATOR_TAGS[2])
    ToTSeparatorDropdown:SetLabel("ToT Separator")
    ToTSeparatorDropdown:SetValue(ZF.db.profile.General.ToTSeparator)
    ToTSeparatorDropdown:SetRelativeWidth(STYLE.Widths.Pct25)
    ToTSeparatorDropdown:SetCallback("OnValueChanged", function(_, _, value)
        ZF.db.profile.General.ToTSeparator = value
        ZF.TOT_SEPARATOR = value
        ZF:ForEachUnitDB(function(_, unit) ZF:UpdateUnitTags(unit) end)
    end)
    ToTSeparatorDropdown:SetCallback("OnEnter", function()
        GameTooltip:SetOwner(ToTSeparatorDropdown.frame, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Used as the prefix separator for Target of Target tags like |cFFFFD100[name:target]|r on your target frame.", 1, 1, 1)
        GameTooltip:Show()
    end)
    ToTSeparatorDropdown:SetCallback("OnLeave", function() GameTooltip:Hide() end)
    TagContainer:AddChild(ToTSeparatorDropdown)
end

local function CreateUnitEnableToggles(containerParent, unit)
    local UnitDB = GetUnitDB(unit)
    GUIBuilders.CreateReloadPrompt(containerParent, "Enable " .. STYLE.Palette.SelectedText .. (UnitDBToUnitStylizedName[unit] or unit) .. "|r", UnitDB, "Enabled", {width = unit == "augmentation" and STYLE.Widths.Pct50 or STYLE.Widths.Pct33})

    if unit ~= "augmentation" then
        local HideBlizzardToggle = GUIBuilders.CreateReloadPrompt(containerParent, "Hide Blizzard " .. STYLE.Palette.SelectedText .. (UnitDBToUnitStylizedName[unit] or unit) .. "|r", UnitDB, "ForceHideBlizzard", {width = STYLE.Widths.Pct33})
        HideBlizzardToggle:SetDisabled(UnitDB.Enabled)
    end
end

local function CreateTagReferenceSettings(containerParent)

    local function DrawTagContainer(TagContainer, TagGroup)
        local TagsList, TagOrder = ZF:FetchTagData(TagGroup)[1], ZF:FetchTagData(TagGroup)[2]

        local SortedTagsList = {}
        for _, tag in ipairs(TagOrder) do
            if TagsList[tag] then
                SortedTagsList[tag] = TagsList[tag]
            end
        end

        for _, Tag in ipairs(TagOrder) do
            local Desc = SortedTagsList[Tag]
            local TagDesc = AG:Create("Label")
            TagDesc:SetText(Desc)
            TagDesc:SetFont(STANDARD_TEXT_FONT, STYLE.Layout.InfoLabelFontSize, "OUTLINE")
            TagDesc:SetRelativeWidth(STYLE.Widths.Pct50)
            TagContainer:AddChild(TagDesc)

            local TagValue = AG:Create("EditBox")
            TagValue:SetText("[" .. Tag .. "]")
            TagValue:SetCallback("OnTextChanged", function() TagValue:ClearFocus() TagValue:SetText("[" .. Tag .. "]") end)
            TagValue:SetRelativeWidth(STYLE.Widths.Pct50)
            TagContainer:AddChild(TagValue)
        end
    end

    local function SelectedGroup(TagContainer, _, TagGroup)
        TagContainer:ReleaseChildren()
        DrawTagContainer(TagContainer, TagGroup)
        TagContainer:DoLayout()
    end

    local GUIContainerTabGroup = AG:Create("TabGroup")
    GUIContainerTabGroup:SetLayout("Flow")
    GUIContainerTabGroup:SetTabs({
        { text = "Health", value = "Health" },
        { text = "Name", value = "Name" },
        { text = "Power", value = "Power" },
        { text = "Miscellaneous", value = "Misc" },
    })
    GUIContainerTabGroup:SetCallback("OnGroupSelected", SelectedGroup)
    GUIContainerTabGroup:SelectTab("Health")
    GUIContainerTabGroup:SetFullWidth(true)
    containerParent:AddChild(GUIContainerTabGroup)
    containerParent:DoLayout()
end

local function CreateProfileSettings(containerParent)
    local profileKeys = {}
    local specProfilesList = {}
    local numSpecs = GetNumSpecializations()
    local SelectProfileDropdown, CopyFromProfileDropdown, DeleteProfileDropdown, ResetProfileButton, UseGlobalProfileToggle, GlobalProfileDropdown

    local ProfileContainer = GUIWidgets.CreateInlineGroup(containerParent, "Profile Management")

    local function DeepDisableProfileContainerExceptGlobalControls(disabled)
        for _, child in ipairs(ProfileContainer.children) do
            if child ~= UseGlobalProfileToggle and child ~= GlobalProfileDropdown then
                GUIWidgets.DeepDisable(child, disabled)
            end
        end
    end

    local ActiveProfileHeading = AG:Create("Heading")
    ActiveProfileHeading:SetFullWidth(true)
    ProfileContainer:AddChild(ActiveProfileHeading)

    local function RefreshProfiles()
        wipe(profileKeys)
        local tmp = {}
        for _, name in ipairs(ZF.db:GetProfiles(tmp, true)) do profileKeys[name] = name end
        local profilesToDelete = {}
        for k, v in pairs(profileKeys) do profilesToDelete[k] = v end
        profilesToDelete[ZF.db:GetCurrentProfile()] = nil
        SelectProfileDropdown:SetList(profileKeys)
        CopyFromProfileDropdown:SetList(profileKeys)
        GlobalProfileDropdown:SetList(profileKeys)
        DeleteProfileDropdown:SetList(profilesToDelete)
        for i = 1, numSpecs do
            specProfilesList[i]:SetList(profileKeys)
            specProfilesList[i]:SetValue(ZF.db:GetDualSpecProfile(i))
        end
        SelectProfileDropdown:SetValue(ZF.db:GetCurrentProfile())
        GlobalProfileDropdown:SetValue((ZF.db.global.GlobalProfile and ZF.db.global.GlobalProfile ~= "" and ZF.db.global.GlobalProfile) or "Default")
        CopyFromProfileDropdown:SetValue(nil)
        DeleteProfileDropdown:SetValue(nil)
        if not next(profilesToDelete) then
            DeleteProfileDropdown:SetDisabled(true)
        else
            DeleteProfileDropdown:SetDisabled(false)
        end
        ResetProfileButton:SetText("Reset |cFFFFD100" .. ZF.db:GetCurrentProfile() .. "|r Profile")
        local isUsingGlobal = ZF.db.global.UseGlobalProfile
        ActiveProfileHeading:SetText( "Active Profile: |cFFFFFFFF" .. ZF.db:GetCurrentProfile() .. (isUsingGlobal and " (|cFFFFD100Global|r)" or "") .. "|r" )
        if ZF.db:IsDualSpecEnabled() then
            SelectProfileDropdown:SetDisabled(true)
            CopyFromProfileDropdown:SetDisabled(true)
            GlobalProfileDropdown:SetDisabled(true)
            DeleteProfileDropdown:SetDisabled(true)
            UseGlobalProfileToggle:SetDisabled(true)
        else
            SelectProfileDropdown:SetDisabled(isUsingGlobal)
            CopyFromProfileDropdown:SetDisabled(isUsingGlobal)
            GlobalProfileDropdown:SetDisabled(not isUsingGlobal)
            DeleteProfileDropdown:SetDisabled(isUsingGlobal or not next(profilesToDelete))
            UseGlobalProfileToggle:SetDisabled(false)
        end
    end

    ZFG.RefreshProfiles = RefreshProfiles

    SelectProfileDropdown = AG:Create("Dropdown")
    SelectProfileDropdown:SetLabel("Select...")
    SelectProfileDropdown:SetRelativeWidth(STYLE.Widths.Pct25)
    SelectProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) ZF.db:SetProfile(value) ZF:UpdateAllUnitFrames() RefreshProfiles() end)
    ProfileContainer:AddChild(SelectProfileDropdown)

    CopyFromProfileDropdown = AG:Create("Dropdown")
    CopyFromProfileDropdown:SetLabel("Copy From...")
    CopyFromProfileDropdown:SetRelativeWidth(STYLE.Widths.Pct25)
    CopyFromProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) ZF:CreatePrompt("Copy Profile", "Are you sure you want to copy from |cFFFFD100" .. value .. "|r?\nThis will |cFFFF4040overwrite|r your current profile settings.", function() ZF.db:CopyProfile(value) ZF:UpdateAllUnitFrames() RefreshProfiles() end) end)
    ProfileContainer:AddChild(CopyFromProfileDropdown)

    DeleteProfileDropdown = AG:Create("Dropdown")
    DeleteProfileDropdown:SetLabel("Delete...")
    DeleteProfileDropdown:SetRelativeWidth(STYLE.Widths.Pct25)
    DeleteProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) if value ~= ZF.db:GetCurrentProfile() then ZF:CreatePrompt("Delete Profile", "Are you sure you want to delete |cFFFFD100" .. value .. "|r?", function() ZF.db:DeleteProfile(value) ZF:UpdateAllUnitFrames() RefreshProfiles() end) end end)
    ProfileContainer:AddChild(DeleteProfileDropdown)

    ResetProfileButton = AG:Create("Button")
    ResetProfileButton:SetText("Reset |cFFFFD100" .. ZF.db:GetCurrentProfile() .. "|r Profile")
    ResetProfileButton:SetRelativeWidth(STYLE.Widths.Pct25)
    ResetProfileButton:SetCallback("OnClick", function() ZF.db:ResetProfile() ZF:ResolveLSM() ZF:UpdateAllUnitFrames() RefreshProfiles() end)
    ProfileContainer:AddChild(ResetProfileButton)

    local CreateProfileEditBox = AG:Create("EditBox")
    CreateProfileEditBox:SetLabel("Profile Name:")
    CreateProfileEditBox:SetText("")
    CreateProfileEditBox:SetRelativeWidth(STYLE.Widths.Pct50)
    CreateProfileEditBox:DisableButton(true)
    CreateProfileEditBox:SetCallback("OnEnterPressed", function() CreateProfileEditBox:ClearFocus() end)
    ProfileContainer:AddChild(CreateProfileEditBox)

    local CreateProfileButton = AG:Create("Button")
    CreateProfileButton:SetText("Create Profile")
    CreateProfileButton:SetRelativeWidth(STYLE.Widths.Pct50)
    CreateProfileButton:SetCallback("OnClick", function() local profileName = strtrim(CreateProfileEditBox:GetText() or "") if profileName ~= "" then ZF.db:SetProfile(profileName) ZF:UpdateAllUnitFrames() RefreshProfiles() CreateProfileEditBox:SetText("") end end)
    ProfileContainer:AddChild(CreateProfileButton)

    local GlobalProfileHeading = AG:Create("Heading")
    GlobalProfileHeading:SetText("Global Profile Settings")
    GlobalProfileHeading:SetFullWidth(true)
    ProfileContainer:AddChild(GlobalProfileHeading)

    GUIWidgets.CreateInformationTag(ProfileContainer, "If |cFFFFD100Use Global Profile Settings|r is enabled, the profile selected below will be used as your active profile.\nThis is useful if you want to use the same profile across multiple characters.")

    UseGlobalProfileToggle = AG:Create("CheckBox")
    UseGlobalProfileToggle:SetLabel("Use Global Profile Settings")
    UseGlobalProfileToggle:SetValue(ZF.db.global.UseGlobalProfile)
    UseGlobalProfileToggle:SetRelativeWidth(STYLE.Widths.Pct50)
    UseGlobalProfileToggle:SetCallback("OnValueChanged", function(_, _, value) RefreshProfiles() ZF.db.global.UseGlobalProfile = value ZF.db.global.GlobalProfile = (ZF.db.global.GlobalProfile and ZF.db.global.GlobalProfile ~= "" and ZF.db.global.GlobalProfile) or "Default" if value then ZF.db:SetProfile(ZF.db.global.GlobalProfile) end GlobalProfileDropdown:SetDisabled(not value) DeepDisableProfileContainerExceptGlobalControls(value) ZF:UpdateAllUnitFrames() RefreshProfiles() end)
    ProfileContainer:AddChild(UseGlobalProfileToggle)

    GlobalProfileDropdown = AG:Create("Dropdown")
    GlobalProfileDropdown:SetLabel("Global Profile...")
    GlobalProfileDropdown:SetRelativeWidth(STYLE.Widths.Pct50)
    GlobalProfileDropdown:SetList(profileKeys)
    GlobalProfileDropdown:SetValue((ZF.db.global.GlobalProfile and ZF.db.global.GlobalProfile ~= "" and ZF.db.global.GlobalProfile) or "Default")
    GlobalProfileDropdown:SetCallback("OnValueChanged", function(_, _, value) ZF.db:SetProfile(value) ZF.db.global.GlobalProfile = value ZF:UpdateAllUnitFrames() RefreshProfiles() end)
    ProfileContainer:AddChild(GlobalProfileDropdown)

    local SpecProfileContainer = GUIWidgets.CreateInlineGroup(ProfileContainer, "Specialization Profiles")

    local UseDualSpecializationToggle = AG:Create("CheckBox")
    UseDualSpecializationToggle:SetLabel("Enable Specialization Profiles")
    UseDualSpecializationToggle:SetValue(ZF.db:IsDualSpecEnabled())
    UseDualSpecializationToggle:SetRelativeWidth(STYLE.Widths.Pct100)
    UseDualSpecializationToggle:SetCallback("OnValueChanged", function(_, _, value) ZF.db:SetDualSpecEnabled(value) for i = 1, numSpecs do specProfilesList[i]:SetDisabled(not value) end ZF:UpdateAllUnitFrames() RefreshProfiles() end)
    UseDualSpecializationToggle:SetDisabled(ZF.db.global.UseGlobalProfile)
    SpecProfileContainer:AddChild(UseDualSpecializationToggle)

    for i = 1, numSpecs do
        local _, specName = C_SpecializationInfo.GetSpecializationInfo(i)
        specProfilesList[i] = AG:Create("Dropdown")
        specProfilesList[i]:SetLabel(string.format("%s", specName or ("Spec %d"):format(i)))
        specProfilesList[i]:SetList(profileKeys)
        specProfilesList[i]:SetCallback("OnValueChanged", function(_, _, value) ZF.db:SetDualSpecProfile(value, i) end)
        specProfilesList[i]:SetRelativeWidth(numSpecs == 2 and STYLE.Widths.Pct50 or numSpecs == 3 and STYLE.Widths.Pct33 or STYLE.Widths.Pct25)
        specProfilesList[i]:SetDisabled(not ZF.db:IsDualSpecEnabled() or ZF.db.global.UseGlobalProfile)
        SpecProfileContainer:AddChild(specProfilesList[i])
    end

    RefreshProfiles()

    local SharingContainer = GUIWidgets.CreateInlineGroup(containerParent, "Profile Sharing")

    local ExportingHeading = AG:Create("Heading")
    ExportingHeading:SetText("Exporting")
    ExportingHeading:SetFullWidth(true)
    SharingContainer:AddChild(ExportingHeading)

    GUIWidgets.CreateInformationTag(SharingContainer, "You can export your profile by pressing |cFFFFD100Export Profile|r button below & share the string with other |cFFFFD100Zen|r Frames users.")

    local ExportingEditBox = CreateClearFocusEditBox(SharingContainer, "Export String...", STYLE.Widths.Pct70)

    local ExportProfileButton = AG:Create("Button")
    ExportProfileButton:SetText("Export Profile")
    ExportProfileButton:SetRelativeWidth(STYLE.Widths.Pct30)
    ExportProfileButton:SetCallback("OnClick", function() ExportingEditBox:SetText(ZF:ExportSavedVariables()) ExportingEditBox:HighlightText() ExportingEditBox:SetFocus() end)
    SharingContainer:AddChild(ExportProfileButton)

    local ImportingHeading = AG:Create("Heading")
    ImportingHeading:SetText("Importing")
    ImportingHeading:SetFullWidth(true)
    SharingContainer:AddChild(ImportingHeading)

    GUIWidgets.CreateInformationTag(SharingContainer, "If you have an exported string, paste it in the |cFFFFD100Import String|r box below & press |cFFFFD100Import Profile|r.")

    local ImportingEditBox = CreateClearFocusEditBox(SharingContainer, "Import String...", STYLE.Widths.Pct70)

    local ImportProfileButton = AG:Create("Button")
    ImportProfileButton:SetText("Import Profile")
    ImportProfileButton:SetRelativeWidth(STYLE.Widths.Pct30)
    ImportProfileButton:SetCallback("OnClick", function() if ImportingEditBox:GetText() ~= "" then ZF:ImportSavedVariables(ImportingEditBox:GetText()) ImportingEditBox:SetText("") end end)
    SharingContainer:AddChild(ImportProfileButton)
    GlobalProfileDropdown:SetDisabled(not ZF.db.global.UseGlobalProfile)
    if ZF.db.global.UseGlobalProfile then DeepDisableProfileContainerExceptGlobalControls(true) end

    local DefaultsExportHeading = AG:Create("Heading")
    DefaultsExportHeading:SetText("Export Profile (Table)")
    DefaultsExportHeading:SetFullWidth(true)
    SharingContainer:AddChild(DefaultsExportHeading)

    GUIWidgets.CreateInformationTag(SharingContainer, "Export the active profile as a readable Lua table matching the structure used by |cFFFFD100Defaults.lua|r.\nThis is intended for |cFFFFD100advanced|r users or |cFFFFD100developers|r.")

    local DefaultsExportEditBox = AG:Create("MultiLineEditBox")
    DefaultsExportEditBox:SetLabel("Export Table...")
    DefaultsExportEditBox:SetText("")
    DefaultsExportEditBox:SetNumLines(14)
    DefaultsExportEditBox:SetFullWidth(true)
    DefaultsExportEditBox:DisableButton(true)
    SharingContainer:AddChild(DefaultsExportEditBox)

    local ExportDefaultsButton = AG:Create("Button")
    ExportDefaultsButton:SetText("Export Profile (Table)")
    ExportDefaultsButton:SetFullWidth(true)
    ExportDefaultsButton:SetCallback("OnClick", function() DefaultsExportEditBox:SetText(ZF:ExportDefaultsTable()) DefaultsExportEditBox:HighlightText() DefaultsExportEditBox:SetFocus() end)
    SharingContainer:AddChild(ExportDefaultsButton)
end

GUIInternal.CreateGlobalToggleSettings = CreateGlobalToggleSettings
GUIInternal.CreateGlobalTagSettings = CreateGlobalTagSettings
GUIInternal.CreateUnitEnableToggles = CreateUnitEnableToggles
GUIInternal.CreateTagReferenceSettings = CreateTagReferenceSettings
GUIInternal.CreateProfileSettings = CreateProfileSettings
