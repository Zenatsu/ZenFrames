local _, RUF = ...
local oUF = RUF.oUF
local raidFrameIndex = 0
local raidStyleRegistered = false

local function ApplyScripts(unitFrame)
    unitFrame:RegisterForClicks("AnyUp")
    unitFrame:SetAttribute("*type1", "target")
    unitFrame:SetAttribute("*type2", "togglemenu")
    unitFrame:HookScript("OnEnter", UnitFrame_OnEnter)
    unitFrame:HookScript("OnLeave", UnitFrame_OnLeave)
end

function RUF:CreateUnitFrame(unitFrame, unit)
    if not unit or not unitFrame then return end
	if unitFrame:GetParent() == RUF.AUGMENTATION_RAID_HEADER then unitFrame.isAugmentationRaidFrame = true end
    local UnitDB = RUF:GetUnitDB(unitFrame, unit)
    local isPlayer = unit == "player"
    local isTarget = unit == "target"
    local isFocus = unit == "focus"
    local isTargetTarget = unit == "targettarget"
    local isFocusTarget = unit == "focustarget"
    local isParty = RUF:GetNormalizedUnit(unit) == "party"
    local isRaid = RUF:GetNormalizedUnit(unit) == "raid"

    RUF:CreateUnitContainer(unitFrame, unit)
    if UnitDB.CastBar and not isTargetTarget and not isFocusTarget then RUF:CreateUnitCastBar(unitFrame, unit) end
    RUF:CreateUnitHealthBar(unitFrame, unit)
    if UnitDB.HealthBar.DispelHighlight and (isPlayer or isTarget or isFocus or isParty or isRaid) then RUF:CreateUnitDispelHighlight(unitFrame, unit) end
    RUF:CreateUnitHealPrediction(unitFrame, unit)
    if UnitDB.Portrait and not isTargetTarget and not isFocusTarget then RUF:CreateUnitPortrait(unitFrame, unit) end
    RUF:CreateUnitPowerBar(unitFrame, unit)
    if isPlayer then RUF:CreateUnitAlternativePowerBar(unitFrame, unit) end
    if isPlayer then RUF:CreateUnitSecondaryPowerBar(unitFrame, unit) end
    RUF:CreateUnitRaidTargetMarker(unitFrame, unit)
    if isPlayer or isTarget or isParty or isRaid then RUF:CreateUnitLeaderAssistantIndicator(unitFrame, unit) end
	if isParty or isRaid then RUF:CreateUnitReadyCheckIndicator(unitFrame, unit) end
	if isParty or isRaid then RUF:CreateUnitResurrectIndicator(unitFrame, unit) end
	if isParty or isRaid then RUF:CreateUnitSummonIndicator(unitFrame, unit) end
    if isParty or isRaid then RUF:CreateUnitRoleIndicator(unitFrame, unit) end
    if isParty or isRaid then RUF:CreateUnitPhaseIndicator(unitFrame, unit) end
    if isPlayer or isTarget then RUF:CreateUnitCombatIndicator(unitFrame, unit) end
    if isPlayer then RUF:CreateUnitRestingIndicator(unitFrame, unit) end
    if isPlayer then RUF:CreateUnitPvPIndicator(unitFrame, unit) end
    if isPlayer then RUF:CreateUnitTotems(unitFrame, unit) end
    if isTarget then RUF:CreateUnitClassificationIndicator(unitFrame, unit) end
    if isTarget then RUF:CreateUnitQuestIndicator(unitFrame, unit) end
    RUF:CreateUnitMouseoverIndicator(unitFrame, unit)
    RUF:CreateUnitTargetGlowIndicator(unitFrame, unit)
    RUF:CreateUnitThreatIndicator(unitFrame, unit)
    RUF:CreateUnitAuras(unitFrame, unit)
    RUF:CreateUnitTags(unitFrame, unit)
	if isRaid then
		unitFrame.RUFConfiguredUnit = unit
		unitFrame:HookScript("OnAttributeChanged", function(frame, attribute, value)
			if attribute ~= "unit" then return end
			if not value then
				RUF:UnregisterRangeFrame(frame)
				RUF:UnregisterTargetGlowIndicatorFrame(frame)
				if frame.DispelHighlightUnit then RUF:UnregisterDispelHighlightEvents(frame) end
				frame.RUFGroupUnit = nil
				return
			end
			local RaidDB = RUF:GetUnitDB(frame, value)
			if not RaidDB or not RaidDB.Enabled then return end
			if frame.DispelHighlightUnit and frame.DispelHighlightUnit ~= value then RUF:UnregisterDispelHighlightEvents(frame) end
			RUF:RegisterRangeFrame(frame, value)
			RUF:RegisterTargetGlowIndicatorFrame(frame, value)
			if frame.RUFGroupUnit ~= value then
				frame.RUFGroupUnit = value
				if frame.DispelHighlight then RUF:UpdateUnitDispelHighlight(frame, value) end
			end
			if frame.Health then frame.Health:ForceUpdate() end
			if frame.Tags then for configuredTag in pairs(RaidDB.Tags) do RUF:UpdateUnitTag(frame, value, configuredTag) end elseif frame.UpdateTags then frame:UpdateTags() end
			RUF:UpdateUnitPowerBar(frame, value)
			RUF:UpdateUnitRoleIndicator(frame, value)
		end)
	end
    ApplyScripts(unitFrame)
    if isRaid then RUF:RegisterRaidFrame(unitFrame) end
    return unitFrame
end

function RUF:LayoutBossFrames()
    local Frame = RUF.db.profile.Units.boss.Frame
    if #RUF.BOSS_FRAMES == 0 then return end
    local bossFrames = RUF.BOSS_FRAMES
    if Frame.GrowthDirection == "UP" then
        bossFrames = {}
        for i = #RUF.BOSS_FRAMES, 1, -1 do bossFrames[#bossFrames+1] = RUF.BOSS_FRAMES[i] end
    end
    local layoutConfig = RUF.LayoutConfig[Frame.Layout[1]]
    local frameHeight = bossFrames[1]:GetHeight()
    local containerHeight = (frameHeight + Frame.Layout[5]) * #bossFrames - Frame.Layout[5]
    local offsetY = containerHeight * layoutConfig.offsetMultiplier
    if layoutConfig.isCenter then offsetY = offsetY - (frameHeight / 2) end
    local initialAnchor = AnchorUtil.CreateAnchor(layoutConfig.anchor, UIParent, Frame.Layout[2], Frame.Layout[3], Frame.Layout[4] + offsetY)
    AnchorUtil.VerticalLayout(bossFrames, initialAnchor, Frame.Layout[5])
end

function RUF:SpawnUnitFrame(unit)
    local UnitDB = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)]
	local augmentationEnabled = unit == "raid" and RUF.db.profile.Units.raid.augmentation.Enabled and RUF:IsAugmentationEvoker()
	if not UnitDB or (not UnitDB.Enabled and not augmentationEnabled) then
        if UnitDB and UnitDB.ForceHideBlizzard then
			if unit == "raid" then RUF:HideBlizzardRaidFrames() else oUF:DisableBlizzard(unit) end
		end
        return
    end
    local FrameDB = UnitDB.Frame
    if unit == "raid" and UnitDB.ForceHideBlizzard then RUF:HideBlizzardRaidFrames() end

	if unit == "raid" then
		if not raidStyleRegistered then
			oUF:RegisterStyle(RUF:FetchFrameName(unit), function(unitFrame)
				raidFrameIndex = raidFrameIndex + 1
				RUF:CreateUnitFrame(unitFrame, "raid" .. raidFrameIndex)
			end)
			raidStyleRegistered = true
		end
	else
		oUF:RegisterStyle(RUF:FetchFrameName(unit), function(unitFrame) RUF:CreateUnitFrame(unitFrame, unit) end)
	end
    oUF:SetActiveStyle(RUF:FetchFrameName(unit))
	if unit == "raid" then
		if UnitDB.Enabled and not RUF.RAID_CONTAINER then RUF:SpawnGroupFrame("raid") end
		if augmentationEnabled then RUF:SpawnAugmentationRaidFrames() end
		return
	elseif unit == "party" then
		return RUF:SpawnGroupFrame(unit)
	end

    if unit == "boss" then
        for i = 1, RUF.MAX_BOSS_FRAMES do
            RUF[unit:upper() .. i] = oUF:Spawn(unit .. i, RUF:FetchFrameName(unit .. i))
            RUF[unit:upper() .. i]:SetSize(FrameDB.Width, FrameDB.Height)
            RUF.BOSS_FRAMES[i] = RUF[unit:upper() .. i]
            RUF[unit:upper() .. i]:SetFrameStrata(FrameDB.FrameStrata)
            RUF:RegisterTargetGlowIndicatorFrame(RUF:FetchFrameName(unit .. i), unit .. i)
            RUF:RegisterRangeFrame(RUF:FetchFrameName(unit .. i), unit .. i)
        end
        RUF:LayoutBossFrames()
    else
        RUF[unit:upper()] = oUF:Spawn(unit, RUF:FetchFrameName(unit))
        RUF:RegisterTargetGlowIndicatorFrame(RUF:FetchFrameName(unit), unit)
        RUF[unit:upper()]:SetFrameStrata(FrameDB.FrameStrata)
        if unit == "player" or unit == "target" or unit == "focus" then RUF:RegisterDispelHighlightEvents(RUF[unit:upper()], unit) end
    end

    if RUF[unit:upper()] then -- boss spawns as BOSS1..n above; there is no single RUF.BOSS frame to size or place
        RUF[unit:upper()]:SetSize(FrameDB.Width, FrameDB.Height)
        RUF:PlaceUnitFrame(RUF[unit:upper()], unit)
    end
    if unit ~= "player" and unit ~= "boss" and unit ~= "party" and unit ~= "raid" then RUF:RegisterRangeFrame(RUF:FetchFrameName(unit), unit) end
	RUF:CreateMover(unit)

	if UnitDB.Enabled then
        if unit == "boss" then
            for i = 1, RUF.MAX_BOSS_FRAMES do
                RegisterUnitWatch(RUF[unit:upper() .. i])
                RUF[unit:upper() .. i]:Show()
            end
        else
            RegisterUnitWatch(RUF[unit:upper()])
            RUF[unit:upper()]:Show()
        end
    else
        if unit == "boss" then
            for i = 1, RUF.MAX_BOSS_FRAMES do
                UnregisterUnitWatch(RUF[unit:upper() .. i])
                RUF[unit:upper() .. i]:Hide()
            end
        else
            UnregisterUnitWatch(RUF[unit:upper()])
            RUF[unit:upper()]:Hide()
        end
    end

    return RUF[unit:upper()]
end

function RUF:PlaceUnitFrame(unitFrame, unit)
    if not unitFrame or unitFrame.isDesignerPreview then return end
    local FrameDB = RUF:GetUnitDB(unitFrame, unit).Frame
    if unit == "player" or unit == "target" then
        local parentFrame = RUF:GetUnitDB(unitFrame, unit).HealthBar.AnchorToCooldownViewer and _G["RUF_CDMAnchor"] or UIParent
        unitFrame:ClearAllPoints()
        unitFrame:SetPoint(FrameDB.Layout[1], parentFrame, FrameDB.Layout[2], FrameDB.Layout[3], FrameDB.Layout[4])
    elseif unit == "targettarget" or unit == "focus" or unit == "focustarget" or unit == "pet" then
        local parentFrame = _G[FrameDB.AnchorParent] or UIParent
        unitFrame:ClearAllPoints()
        unitFrame:SetPoint(FrameDB.Layout[1], parentFrame, FrameDB.Layout[2], FrameDB.Layout[3], FrameDB.Layout[4])
    end
end

function RUF:UpdateUnitFrame(unitFrame, unit)
    local UnitDB = RUF:GetUnitDB(unitFrame, unit)
    local isPlayer = unit == "player"
    local isTarget = unit == "target"
    local isFocus = unit == "focus"
    local isTargetTarget = unit == "targettarget"
    local isFocusTarget = unit == "focustarget"
    local isParty = RUF:GetNormalizedUnit(unit) == "party"
    local isRaid = RUF:GetNormalizedUnit(unit) == "raid"

    if UnitDB.CastBar and not isTargetTarget and not isFocusTarget then RUF:UpdateUnitCastBar(unitFrame, unit) end
    RUF:UpdateUnitHealthBar(unitFrame, unit)
    RUF:UpdateUnitHealPrediction(unitFrame, unit)
    if UnitDB.Portrait and not isTargetTarget and not isFocusTarget then RUF:UpdateUnitPortrait(unitFrame, unit) end
    RUF:UpdateUnitPowerBar(unitFrame, unit)
    if isPlayer then RUF:UpdateUnitAlternativePowerBar(unitFrame, unit) end
    if isPlayer then RUF:UpdateUnitSecondaryPowerBar(unitFrame, unit) end
    RUF:UpdateUnitRaidTargetMarker(unitFrame, unit)
    if isPlayer or isTarget or isParty or isRaid then RUF:UpdateUnitLeaderAssistantIndicator(unitFrame, unit) end
	if isParty or isRaid then RUF:UpdateUnitReadyCheckIndicator(unitFrame, unit) end
	if isParty or isRaid then RUF:UpdateUnitResurrectIndicator(unitFrame, unit) end
	if isParty or isRaid then RUF:UpdateUnitSummonIndicator(unitFrame, unit) end
    if isParty or isRaid then RUF:UpdateUnitRoleIndicator(unitFrame, unit) end
    if isParty or isRaid then RUF:UpdateUnitPhaseIndicator(unitFrame, unit) end
    if isPlayer or isTarget then RUF:UpdateUnitCombatIndicator(unitFrame, unit) end
    if isPlayer then RUF:UpdateUnitRestingIndicator(unitFrame, unit) end
    if isPlayer then RUF:UpdateUnitPvPIndicator(unitFrame, unit) end
    if isPlayer then RUF:UpdateUnitTotems(unitFrame, unit) end
    if isTarget then RUF:UpdateUnitClassificationIndicator(unitFrame, unit) end
    if isTarget then RUF:UpdateUnitQuestIndicator(unitFrame, unit) end
    RUF:UpdateUnitMouseoverIndicator(unitFrame, unit)
    RUF:UpdateUnitTargetGlowIndicator(unitFrame, unit)
    RUF:UpdateUnitThreatIndicator(unitFrame, unit)
    RUF:UpdateUnitAuras(unitFrame, unit)
	if unit ~= "player" then RUF:RegisterRangeFrame(unitFrame, unit == "partyplayer" and "player" or unit) end
	RUF:RegisterTargetGlowIndicatorFrame(unitFrame, unit)
    if not unitFrame.isDesignerPreview then unitFrame:SetFrameStrata(UnitDB.Frame.FrameStrata) end -- preview strata is designer-managed (FULLSCREEN_DIALOG)
end

function RUF:UpdateBossFrames()
    for i in pairs(RUF.BOSS_FRAMES) do
        RUF:UpdateUnitFrame(RUF["BOSS"..i], "boss"..i)
    end
	RUF:UpdateTestEnvironment("boss", "all")
    RUF:LayoutBossFrames()
end

function RUF:UpdateAllUnitFrames()
	for _, unit in ipairs({"player", "target", "targettarget", "focus", "focustarget", "pet"}) do
		if RUF[unit:upper()] then RUF:UpdateUnitFrame(RUF[unit:upper()], unit) end
	end
	RUF:UpdateBossFrames()
	RUF:UpdateGroupFrame("party")
	RUF:UpdateGroupFrame("raid")
	RUF:UpdateAugmentationRaidFrames()
end
