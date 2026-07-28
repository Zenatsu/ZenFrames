local _, RUF = ...
local RehaltedUnitFrames = LibStub("AceAddon-3.0"):NewAddon("RehaltedUnitFrames")

function RehaltedUnitFrames:OnInitialize()
    RUF.db = LibStub("AceDB-3.0"):New("UUFDB", RUF:GetDefaultDB(), true)
    RUF.LDS:EnhanceDatabase(RUF.db, "RehaltedUnitFrames")
    RUF.TAG_UPDATE_INTERVAL = RUF.db.profile.General.TagUpdateInterval or 0.25
    RUF.SEPARATOR = RUF.db.profile.General.Separator or "||"
    RUF.TOT_SEPARATOR = RUF.db.profile.General.ToTSeparator or "»"
    if RUF.db.global.UseGlobalProfile then
        local globalProfile = RUF.db.global.GlobalProfile or RUF.db.global.GlobalProfileName or "Default"
		RUF.db:SetProfile(globalProfile)
	end
	RUF.db.RegisterCallback(RUF, "OnProfileChanged", RUF.RefreshProfiles)
	RUF.db.RegisterCallback(RUF, "OnProfileCopied", RUF.RefreshProfiles)
	RUF.db.RegisterCallback(RUF, "OnProfileReset", RUF.RefreshProfiles)

    local playerSpecializationChangedEventFrame = CreateFrame("Frame")
    playerSpecializationChangedEventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	playerSpecializationChangedEventFrame:SetScript("OnEvent", function(_, event, ...) if InCombatLockdown() then return end if event ~= "PLAYER_SPECIALIZATION_CHANGED" then return end local unit = ... if unit == "player" then C_Timer.After(0.1, RUF.RefreshProfiles) end end)
end

function RehaltedUnitFrames:OnEnable()
    RUF:Init()
    RUF:CreatePositionController()
    RUF:SpawnUnitFrame("player")
    RUF:SpawnUnitFrame("target")
    RUF:SpawnUnitFrame("targettarget")
    RUF:SpawnUnitFrame("focus")
    RUF:SpawnUnitFrame("focustarget")
    RUF:SpawnUnitFrame("pet")
    RUF:SpawnUnitFrame("boss")
    RUF:SpawnUnitFrame("party")
    RUF:SpawnUnitFrame("raid")
	if SCMAPI and SCMAPI.RegisterAnchorParents then SCMAPI.RegisterAnchorParents("UnhaltedUnitFrames", RUF.SCMAnchors) end
end
