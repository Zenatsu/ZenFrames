local _, ZF = ...
local ZenFrames = LibStub("AceAddon-3.0"):NewAddon("ZenFrames")

StaticPopupDialogs["ZF_UUFDB_MIGRATED"] = {
    text = "Hey, welcome to Zen Frames, Your old Unhalted profiles should be copied over but please go over your settings and make sure everything is as you like it, some data might have not carried over properly from the refactor. Love ya, bye!",
    button1 = OKAY,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function ZenFrames:OnInitialize()
    -- One-time move off the inherited UUFDB name: only fires when UUFDB actually has data
    local migratedFromUUFDB = false
    if _G.UUFDB and next(_G.UUFDB) and (not _G.ZFDB or not next(_G.ZFDB)) then
        ZFDB = CopyTable(UUFDB)
        migratedFromUUFDB = true
    end

    ZF:MigrateAllProfiles(_G.ZFDB)
    ZF:MigrateGlobalSettings(_G.ZFDB)

    ZF.db = LibStub("AceDB-3.0"):New("ZFDB", ZF:GetDefaultDB(), true)
    ZF.LDS:EnhanceDatabase(ZF.db, "ZenFrames")
    ZF.TAG_UPDATE_INTERVAL = ZF.db.profile.General.TagUpdateInterval or 0.25
    ZF.SEPARATOR = ZF.db.profile.General.Separator or "||"
    ZF.TOT_SEPARATOR = ZF.db.profile.General.ToTSeparator or "»"
    if ZF.db.global.UseGlobalProfile then
        local globalProfile = ZF.db.global.GlobalProfile or "Default"
		ZF.db:SetProfile(globalProfile)
	end
	ZF.db.RegisterCallback(ZF, "OnProfileChanged", ZF.RefreshProfiles)
	ZF.db.RegisterCallback(ZF, "OnProfileCopied", ZF.RefreshProfiles)
	ZF.db.RegisterCallback(ZF, "OnProfileReset", ZF.RefreshProfiles)

    local playerSpecializationChangedEventFrame = CreateFrame("Frame")
    playerSpecializationChangedEventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	playerSpecializationChangedEventFrame:SetScript("OnEvent", function(_, event, ...) if InCombatLockdown() then return end if event ~= "PLAYER_SPECIALIZATION_CHANGED" then return end local unit = ... if unit == "player" then C_Timer.After(0.1, ZF.RefreshProfiles) end end)

    local guiWasShownBeforeCombat = false
    local combatUIWatcherFrame = CreateFrame("Frame")
    combatUIWatcherFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    combatUIWatcherFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatUIWatcherFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_DISABLED" then
            guiWasShownBeforeCombat = ZF:IsMainGUIShown()
            if guiWasShownBeforeCombat then ZF:SetMainGUIShown(false) end
            ZF:SetMoverOverlayShown(false)
        elseif event == "PLAYER_REGEN_ENABLED" then
            if guiWasShownBeforeCombat then ZF:SetMainGUIShown(true) end
            guiWasShownBeforeCombat = false
            ZF:SetMoverOverlayShown(true)
            ZF:UpdateAllUnitFrames()
        end
    end)

    if migratedFromUUFDB then StaticPopup_Show("ZF_UUFDB_MIGRATED") end
end

function ZenFrames_OnAddonCompartmentClick(addonName, buttonName)
    if InCombatLockdown() then return end
    if ZF:IsMainGUIShown() then
        ZF:CloseMainGUI()
    else
        ZF:CreateGUI()
    end
end

function ZenFrames_OnAddonCompartmentEnter(addonName, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText(ZF.PRETTY_ADDON_NAME)
    GameTooltip:AddLine("Click to open settings.", 1, 1, 1)
    GameTooltip:Show()
end

function ZenFrames_OnAddonCompartmentLeave(addonName, button)
    GameTooltip:Hide()
end

function ZenFrames:OnEnable()
    ZF:Init()
    ZF:SpawnUnitFrame("player")
    ZF:SpawnUnitFrame("target")
    ZF:SpawnUnitFrame("targettarget")
    ZF:SpawnUnitFrame("focus")
    ZF:SpawnUnitFrame("focustarget")
    ZF:SpawnUnitFrame("pet")
    ZF:SpawnUnitFrame("boss")
    ZF:SpawnUnitFrame("party")
    ZF:SpawnUnitFrame("raid")
end
