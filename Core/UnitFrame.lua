local _, ZF = ...
local oUF = ZF.oUF
local raidFrameIndex = 0
local raidStyleRegistered = false

function ZF:EnsureRaidStyleRegistered()
	if raidStyleRegistered then return end
	oUF:RegisterStyle(ZF:FetchFrameName("raid"), function(unitFrame)
		raidFrameIndex = raidFrameIndex + 1
		ZF:CreateUnitFrame(unitFrame, "raid" .. raidFrameIndex)
	end)
	raidStyleRegistered = true
end

local pendingSpawnUnits = {}
local SpawnUnitFrameRetryFrame = CreateFrame("Frame")
SpawnUnitFrameRetryFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    for unit in pairs(pendingSpawnUnits) do
        pendingSpawnUnits[unit] = nil
        if unit == "boss" then
            for i, bossFrame in ipairs(ZF.BOSS_FRAMES) do ZF:UpdateUnitFrame(bossFrame, "boss" .. i) end
            ZF:LayoutBossFrames()
        elseif ZF[unit:upper()] then
            ZF:UpdateUnitFrame(ZF[unit:upper()], unit)
        end
    end
end)

local function ApplyScripts(unitFrame)
    unitFrame:RegisterForClicks("AnyUp")
    unitFrame:SetAttribute("*type1", "target")
    unitFrame:SetAttribute("*type2", "togglemenu")
    unitFrame:HookScript("OnEnter", UnitFrame_OnEnter)
    unitFrame:HookScript("OnLeave", UnitFrame_OnLeave)
end

function ZF:CreateUnitFrame(unitFrame, unit)
    if not unit or not unitFrame then return end
	if unitFrame:GetParent() == ZF.AUGMENTATION_RAID_HEADER then unitFrame.isAugmentationRaidFrame = true end
    local UnitDB = ZF:GetUnitDB(unitFrame, unit)
    local isPlayer = unit == "player"
    local isTarget = unit == "target"
    local isFocus = unit == "focus"
    local isTargetTarget = unit == "targettarget"
    local isFocusTarget = unit == "focustarget"
    local isParty = ZF:GetNormalizedUnit(unit) == "party"
    local isRaid = ZF:GetNormalizedUnit(unit) == "raid"

    ZF:CreateUnitContainer(unitFrame, unit)
    if UnitDB.CastBar and not isTargetTarget and not isFocusTarget then ZF:CreateUnitCastBar(unitFrame, unit) end
    ZF:CreateUnitHealthBar(unitFrame, unit)
    if UnitDB.HealthBar.DispelHighlight and (isPlayer or isTarget or isFocus or isParty or isRaid) then ZF:CreateUnitDispelHighlight(unitFrame, unit) end
    ZF:CreateUnitHealPrediction(unitFrame, unit)
    if UnitDB.Portrait and not isTargetTarget and not isFocusTarget then ZF:CreateUnitPortrait(unitFrame, unit) end
    ZF:CreateUnitPowerBar(unitFrame, unit)
    if isPlayer then ZF:CreateUnitAlternativePowerBar(unitFrame, unit) end
    if isPlayer then ZF:CreateUnitSecondaryPowerBar(unitFrame, unit) end
    ZF:CreateUnitRaidTargetMarker(unitFrame, unit)
    if isPlayer or isTarget or isParty or isRaid then ZF:CreateUnitLeaderAssistantIndicator(unitFrame, unit) end
	if isParty or isRaid then ZF:CreateUnitReadyCheckIndicator(unitFrame, unit) end
	if isParty or isRaid then ZF:CreateUnitResurrectIndicator(unitFrame, unit) end
	if isParty or isRaid then ZF:CreateUnitSummonIndicator(unitFrame, unit) end
    if isParty or isRaid then ZF:CreateUnitRoleIndicator(unitFrame, unit) end
    if isParty or isRaid then ZF:CreateUnitPhaseIndicator(unitFrame, unit) end
    if isPlayer or isTarget then ZF:CreateUnitCombatIndicator(unitFrame, unit) end
    if isPlayer then ZF:CreateUnitRestingIndicator(unitFrame, unit) end
    if isPlayer then ZF:CreateUnitPvPIndicator(unitFrame, unit) end
    if isPlayer then ZF:CreateUnitTotems(unitFrame, unit) end
    if isTarget then ZF:CreateUnitClassificationIndicator(unitFrame, unit) end
    if isTarget then ZF:CreateUnitQuestIndicator(unitFrame, unit) end
    ZF:CreateUnitMouseoverIndicator(unitFrame, unit)
    ZF:CreateUnitTargetGlowIndicator(unitFrame, unit)
    ZF:CreateUnitThreatIndicator(unitFrame, unit)
    ZF:CreateUnitAuras(unitFrame, unit)
    ZF:CreateUnitTags(unitFrame, unit)
	if isRaid then
		unitFrame.ZFConfiguredUnit = unit
		unitFrame:HookScript("OnAttributeChanged", function(frame, attribute, value)
			if attribute ~= "unit" then return end
			if not value then
				ZF:UnregisterRangeFrame(frame)
				ZF:UnregisterTargetGlowIndicatorFrame(frame)
				if frame.DispelHighlightUnit then ZF:UnregisterDispelHighlightEvents(frame) end
				frame.ZFGroupUnit = nil
				return
			end
			local RaidDB = ZF:GetUnitDB(frame, value)
			if not RaidDB or not RaidDB.Enabled then return end
			if frame.DispelHighlightUnit and frame.DispelHighlightUnit ~= value then ZF:UnregisterDispelHighlightEvents(frame) end
			ZF:RegisterRangeFrame(frame, value)
			ZF:RegisterTargetGlowIndicatorFrame(frame, value)
			if frame.ZFGroupUnit ~= value then
				frame.ZFGroupUnit = value
				if frame.DispelHighlight then ZF:UpdateUnitDispelHighlight(frame, value) end
			end
			if frame.Health then frame.Health:ForceUpdate() end
			if frame.Tags then for configuredTag in pairs(RaidDB.Tags) do ZF:UpdateUnitTag(frame, value, configuredTag) end elseif frame.UpdateTags then frame:UpdateTags() end
			ZF:UpdateUnitPowerBar(frame, value)
			ZF:UpdateUnitRoleIndicator(frame, value)
		end)
	end
    ApplyScripts(unitFrame)
    if isRaid then ZF:RegisterRaidFrame(unitFrame) end
    return unitFrame
end

function ZF:LayoutBossFrames()
    if InCombatLockdown() then return end -- AnchorUtil.VerticalLayout calls SetPoint on the secure-templated boss frames
    local Frame = ZF.db.profile.Units.boss.Frame
    if #ZF.BOSS_FRAMES == 0 then return end
    local bossFrames = ZF.BOSS_FRAMES
    if Frame.GrowthDirection == "UP" then
        bossFrames = {}
        for i = #ZF.BOSS_FRAMES, 1, -1 do bossFrames[#bossFrames+1] = ZF.BOSS_FRAMES[i] end
    end
    local layoutConfig = ZF.LayoutConfig[Frame.Layout[1]]
    local frameHeight = bossFrames[1]:GetHeight()
    local containerHeight = (frameHeight + Frame.Layout[5]) * #bossFrames - Frame.Layout[5]
    local offsetY = containerHeight * layoutConfig.offsetMultiplier
    if layoutConfig.isCenter then offsetY = offsetY - (frameHeight / 2) end
    local initialAnchor = AnchorUtil.CreateAnchor(layoutConfig.anchor, UIParent, Frame.Layout[2], Frame.Layout[3], Frame.Layout[4] + offsetY)
    AnchorUtil.VerticalLayout(bossFrames, initialAnchor, Frame.Layout[5])
end

function ZF:SpawnUnitFrame(unit)
    local UnitDB = ZF.db.profile.Units[ZF:GetNormalizedUnit(unit)]
	local augmentationEnabled = unit == "raid" and ZF.db.profile.Units.augmentation.Enabled and ZF:IsAugmentationEvoker()
	if not UnitDB or (not UnitDB.Enabled and not augmentationEnabled) then
        if UnitDB and UnitDB.ForceHideBlizzard then
			if unit == "raid" then ZF:HideBlizzardRaidFrames() else oUF:DisableBlizzard(unit) end
		end
        return
    end
    local FrameDB = UnitDB.Frame
    if unit == "raid" and UnitDB.ForceHideBlizzard then ZF:HideBlizzardRaidFrames() end

	if unit == "raid" then
		ZF:EnsureRaidStyleRegistered()
	else
		oUF:RegisterStyle(ZF:FetchFrameName(unit), function(unitFrame) ZF:CreateUnitFrame(unitFrame, unit) end)
	end
    oUF:SetActiveStyle(ZF:FetchFrameName(unit))
	if unit == "raid" then
		if UnitDB.Enabled and not ZF.RAID_CONTAINER then ZF:SpawnGroupFrame("raid") end
		if augmentationEnabled then ZF:SpawnAugmentationRaidFrames() end
		return
	elseif unit == "party" then
		return ZF:SpawnGroupFrame(unit)
	end

    if unit == "boss" then
        for i = 1, ZF.MAX_BOSS_FRAMES do
            ZF[unit:upper() .. i] = oUF:Spawn(unit .. i, ZF:FetchFrameName(unit .. i))
            if not InCombatLockdown() then ZF[unit:upper() .. i]:SetSize(FrameDB.Width, FrameDB.Height) end
            ZF.BOSS_FRAMES[i] = ZF[unit:upper() .. i]
            ZF[unit:upper() .. i]:SetFrameStrata(FrameDB.FrameStrata)
            ZF:RegisterTargetGlowIndicatorFrame(ZF:FetchFrameName(unit .. i), unit .. i)
            ZF:RegisterRangeFrame(ZF:FetchFrameName(unit .. i), unit .. i)
        end
        ZF:LayoutBossFrames()
    else
        ZF[unit:upper()] = oUF:Spawn(unit, ZF:FetchFrameName(unit))
        ZF:RegisterTargetGlowIndicatorFrame(ZF:FetchFrameName(unit), unit)
        ZF[unit:upper()]:SetFrameStrata(FrameDB.FrameStrata)
        if unit == "player" or unit == "target" or unit == "focus" then ZF:RegisterDispelHighlightEvents(ZF[unit:upper()], unit) end
    end

    if ZF[unit:upper()] then -- boss spawns as BOSS1..n above; there is no single ZF.BOSS frame to size or place
        if not InCombatLockdown() then ZF[unit:upper()]:SetSize(FrameDB.Width, FrameDB.Height) end
        ZF:PlaceUnitFrame(ZF[unit:upper()], unit)
    end
    if InCombatLockdown() then -- reload/login mid-combat: PlaceUnitFrame/LayoutBossFrames above no-op'd, retry once combat ends
        pendingSpawnUnits[unit] = true
        SpawnUnitFrameRetryFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
    if unit ~= "player" and unit ~= "boss" and unit ~= "party" and unit ~= "raid" then ZF:RegisterRangeFrame(ZF:FetchFrameName(unit), unit) end
	ZF:CreateMover(unit)

	if UnitDB.Enabled then
        if unit == "boss" then
            for i = 1, ZF.MAX_BOSS_FRAMES do
                RegisterUnitWatch(ZF[unit:upper() .. i])
                ZF[unit:upper() .. i]:Show()
            end
        else
            RegisterUnitWatch(ZF[unit:upper()])
            ZF[unit:upper()]:Show()
        end
    end

    return ZF[unit:upper()]
end

function ZF:PlaceUnitFrame(unitFrame, unit)
    if not unitFrame or unitFrame.isDesignerPreview then return end
    if InCombatLockdown() then return end
    local FrameDB = ZF:GetUnitDB(unitFrame, unit).Frame
    if unit == "player" or unit == "target" then
        unitFrame:ClearAllPoints()
        unitFrame:SetPoint(FrameDB.Layout[1], UIParent, FrameDB.Layout[2], FrameDB.Layout[3], FrameDB.Layout[4])
    elseif unit == "targettarget" or unit == "focus" or unit == "focustarget" or unit == "pet" then
        local parentFrame = _G[FrameDB.AnchorToFrame] or UIParent
        unitFrame:ClearAllPoints()
        unitFrame:SetPoint(FrameDB.Layout[1], parentFrame, FrameDB.Layout[2], FrameDB.Layout[3], FrameDB.Layout[4])
    end
end

function ZF:UpdateUnitFrame(unitFrame, unit)
    if InCombatLockdown() then return end
    local UnitDB = ZF:GetUnitDB(unitFrame, unit)
    local isPlayer = unit == "player"
    local isTarget = unit == "target"
    local isFocus = unit == "focus"
    local isTargetTarget = unit == "targettarget"
    local isFocusTarget = unit == "focustarget"
    local isParty = ZF:GetNormalizedUnit(unit) == "party"
    local isRaid = ZF:GetNormalizedUnit(unit) == "raid"

    if UnitDB.CastBar and not isTargetTarget and not isFocusTarget then ZF:UpdateUnitCastBar(unitFrame, unit) end
    ZF:UpdateUnitHealthBar(unitFrame, unit)
    ZF:UpdateUnitHealPrediction(unitFrame, unit)
    if UnitDB.Portrait and not isTargetTarget and not isFocusTarget then ZF:UpdateUnitPortrait(unitFrame, unit) end
    ZF:UpdateUnitPowerBar(unitFrame, unit)
    if isPlayer then ZF:UpdateUnitAlternativePowerBar(unitFrame, unit) end
    if isPlayer then ZF:UpdateUnitSecondaryPowerBar(unitFrame, unit) end
    ZF:UpdateUnitRaidTargetMarker(unitFrame, unit)
    if isPlayer or isTarget or isParty or isRaid then ZF:UpdateUnitLeaderAssistantIndicator(unitFrame, unit) end
	if isParty or isRaid then ZF:UpdateUnitReadyCheckIndicator(unitFrame, unit) end
	if isParty or isRaid then ZF:UpdateUnitResurrectIndicator(unitFrame, unit) end
	if isParty or isRaid then ZF:UpdateUnitSummonIndicator(unitFrame, unit) end
    if isParty or isRaid then ZF:UpdateUnitRoleIndicator(unitFrame, unit) end
    if isParty or isRaid then ZF:UpdateUnitPhaseIndicator(unitFrame, unit) end
    if isPlayer or isTarget then ZF:UpdateUnitCombatIndicator(unitFrame, unit) end
    if isPlayer then ZF:UpdateUnitRestingIndicator(unitFrame, unit) end
    if isPlayer then ZF:UpdateUnitPvPIndicator(unitFrame, unit) end
    if isPlayer then ZF:UpdateUnitTotems(unitFrame, unit) end
    if isTarget then ZF:UpdateUnitClassificationIndicator(unitFrame, unit) end
    if isTarget then ZF:UpdateUnitQuestIndicator(unitFrame, unit) end
    ZF:UpdateUnitMouseoverIndicator(unitFrame, unit)
    ZF:UpdateUnitTargetGlowIndicator(unitFrame, unit)
    ZF:UpdateUnitThreatIndicator(unitFrame, unit)
    ZF:UpdateUnitAuras(unitFrame, unit)
	if unit ~= "player" and not unitFrame.isDesignerPreview then ZF:RegisterRangeFrame(unitFrame, unit == "partyplayer" and "player" or unit) end
	if not unitFrame.isDesignerPreview then ZF:RegisterTargetGlowIndicatorFrame(unitFrame, unit) end
    if not unitFrame.isDesignerPreview then unitFrame:SetFrameStrata(UnitDB.Frame.FrameStrata) end -- preview strata is designer-managed (FULLSCREEN_DIALOG)
end

local function HideFakeAuraButtons(container)
	if not container then return end
	for index = 1, container.maxFake or 0 do
		local button = container["fake" .. index]
		if button then button:Hide() end
	end
end

function ZF:ResetBossFrames()
	if InCombatLockdown() then return end
	local BossDB = ZF.db.profile.Units.boss
	local BuffsDB = BossDB.Auras.Buffs
	local DebuffsDB = BossDB.Auras.Debuffs
	local CustomDB = BossDB.Auras.Custom

	for index, bossFrame in ipairs(ZF.BOSS_FRAMES) do
		bossFrame:SetAttribute("unit", "boss" .. index)
		RegisterUnitWatch(bossFrame)

		if bossFrame.Castbar then
			bossFrame.Castbar:Hide()
			bossFrame.Castbar:GetParent():Hide()
			if BossDB.CastBar.Enabled then
				if bossFrame:IsElementEnabled("Castbar") then bossFrame:DisableElement("Castbar") end
				bossFrame:EnableElement("Castbar")
			end
		end

		HideFakeAuraButtons(bossFrame.BuffContainer)
		HideFakeAuraButtons(bossFrame.DebuffContainer)
		HideFakeAuraButtons(bossFrame.CustomAuraContainer)

		if BuffsDB.Enabled or DebuffsDB.Enabled then
			if not bossFrame:IsElementEnabled("Auras") then bossFrame:EnableElement("Auras") end
			if bossFrame.BuffContainer and bossFrame.BuffContainer.ForceUpdate then bossFrame.BuffContainer:ForceUpdate() end
			if bossFrame.DebuffContainer and bossFrame.DebuffContainer.ForceUpdate then bossFrame.DebuffContainer:ForceUpdate() end
		end

		if CustomDB and CustomDB.Enabled then
			bossFrame.CustomAuras = bossFrame.CustomAuraContainer
			if not bossFrame:IsElementEnabled("CustomAuras") then bossFrame:EnableElement("CustomAuras") end
			if bossFrame.CustomAuraContainer and bossFrame.CustomAuraContainer.ForceUpdate then bossFrame.CustomAuraContainer:ForceUpdate() end
		end

		bossFrame:Hide()
	end
end

function ZF:UpdateBossFrame()
    for i in pairs(ZF.BOSS_FRAMES) do
        ZF:UpdateUnitFrame(ZF["BOSS"..i], "boss"..i)
    end
	ZF:ResetBossFrames()
    ZF:LayoutBossFrames()
end

function ZF:UpdateAllUnitFrames()
	for _, unit in ipairs({"player", "target", "targettarget", "focus", "focustarget", "pet"}) do
		if ZF[unit:upper()] then ZF:UpdateUnitFrame(ZF[unit:upper()], unit) end
	end
	ZF:UpdateBossFrame()
	ZF:UpdateGroupFrame("party")
	ZF:UpdateGroupFrame("raid")
	ZF:UpdateAugmentationRaidFrames()
end
