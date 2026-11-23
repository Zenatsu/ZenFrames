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

local function RetrySpawnUnitFrame(unit)
    if unit == "boss" then
        for i, bossFrame in ipairs(ZF.BOSS_FRAMES) do ZF:UpdateUnitFrame(bossFrame, "boss" .. i) end
        ZF:LayoutBossFrames()
    elseif ZF[unit:upper()] then
        ZF:UpdateUnitFrame(ZF[unit:upper()], unit)
    end
end

local function RetryBossReset()
    ZF:LayoutBossFrames()
    ZF:ResetBossFrames()
end

local function IsMouseOverAuraContainer(frame)
    return (frame.BuffContainer and frame.BuffContainer:IsMouseOver())
        or (frame.DebuffContainer and frame.DebuffContainer:IsMouseOver())
        or (frame.CustomAuraContainer and frame.CustomAuraContainer:IsMouseOver())
end

local function PollAuraTooltipSuppression(frame, elapsed)
    frame.ZFAuraPollElapsed = (frame.ZFAuraPollElapsed or 0) + elapsed
    if frame.ZFAuraPollElapsed < 0.05 then return end
    frame.ZFAuraPollElapsed = 0

    if IsMouseOverAuraContainer(frame) then
        if not frame.ZFAuraTooltipSuppressed then
            frame.ZFAuraTooltipSuppressed = true
            UnitFrame_OnLeave(frame)
        end
    elseif frame.ZFAuraTooltipSuppressed then
        frame.ZFAuraTooltipSuppressed = false
        if frame:IsMouseOver() then UnitFrame_OnEnter(frame) end
    end
end

local function OnUnitFrameEnter(frame)
    frame.ZFAuraPollElapsed = 0
    frame:SetScript("OnUpdate", PollAuraTooltipSuppression)
    PollAuraTooltipSuppression(frame, 1)
end

local function OnUnitFrameLeave(frame)
    frame:SetScript("OnUpdate", nil)
    frame.ZFAuraTooltipSuppressed = false
end

local function ApplyScripts(unitFrame)
    unitFrame:RegisterForClicks("AnyUp")
    unitFrame:SetAttribute("*type1", "target")
    unitFrame:SetAttribute("*type2", "togglemenu")
    unitFrame:HookScript("OnEnter", UnitFrame_OnEnter)
    unitFrame:HookScript("OnEnter", OnUnitFrameEnter)
    unitFrame:HookScript("OnLeave", UnitFrame_OnLeave)
    unitFrame:HookScript("OnLeave", OnUnitFrameLeave)
    unitFrame:HookScript("OnAttributeChanged", function(frame, attribute, value)
        if attribute == "unit" then frame.unit = value end
    end)
end

local function NotTargetOfTarget(ctx) return not ctx.isTargetTarget and not ctx.isFocusTarget end
local function IsPlayer(ctx) return ctx.isPlayer end
local function IsTarget(ctx) return ctx.isTarget end
local function IsPlayerOrTarget(ctx) return ctx.isPlayer or ctx.isTarget end
local function IsGroup(ctx) return ctx.isParty or ctx.isRaid end

local UNIT_ELEMENTS = {
    { "CastBar", when = function(ctx) return ctx.UnitDB.CastBar and NotTargetOfTarget(ctx) and not ctx.usesXPBar end },
    { "XPBar", when = function(ctx) return ctx.usesXPBar end },
    { "Container", createFirst = true },
    { "HealthBar" },
    { "DispelHighlight", createWhen = function(ctx) return ctx.UnitDB.HealthBar.DispelHighlight and (ctx.isPlayer or ctx.isTarget or ctx.isFocus or ctx.isParty or ctx.isRaid) end },
    { "HealPrediction" },
    { "Portrait", when = function(ctx) return ctx.UnitDB.Portrait and NotTargetOfTarget(ctx) end },
    { "PowerBar" },
    { "AlternativePowerBar", when = IsPlayer },
    { "SecondaryPowerBar", when = IsPlayer },
    { "RaidTargetMarker" },
    { "LeaderAssistantIndicator", when = function(ctx) return ctx.isPlayer or ctx.isTarget or ctx.isParty or ctx.isRaid end },
    { "ReadyCheckIndicator", when = IsGroup },
    { "ResurrectIndicator", when = IsGroup },
    { "SummonIndicator", when = IsGroup },
    { "RoleIndicator", when = IsGroup },
    { "PhaseIndicator", when = IsGroup },
    { "CombatIndicator", when = IsPlayerOrTarget },
    { "RestingIndicator", when = IsPlayer },
    { "PvPIndicator", when = IsPlayer },
    { "PetHappinessIndicator", when = function(ctx) return ctx.isPet end },
    { "Totems", when = IsPlayer },
    { "ClassificationIndicator", when = IsTarget },
    { "QuestIndicator", when = IsTarget },
    { "MouseoverIndicator" },
    { "TargetGlowIndicator" },
    { "ThreatIndicator" },
    { "Auras" },
    { "Tags", createOnly = true },
}

for _, element in ipairs(UNIT_ELEMENTS) do
    local name = element[1]
    element.create = "CreateUnit" .. name
    if not element.createOnly then element.update = "UpdateUnit" .. name end
end

local function BuildElementContext(unitFrame, unit)
    local normalizedUnit = ZF:GetNormalizedUnit(unit)
    local isPet = unit == "pet"
    return {
        UnitDB = ZF:GetUnitDB(unitFrame, unit),
        isPlayer = unit == "player",
        isTarget = unit == "target",
        isPet = isPet,
        isFocus = unit == "focus",
        isTargetTarget = unit == "targettarget",
        isFocusTarget = unit == "focustarget",
        isParty = normalizedUnit == "party",
        isRaid = normalizedUnit == "raid",
        usesXPBar = isPet and ZF:PetUsesXPBar(),
    }
end

function ZF:CreateUnitFrame(unitFrame, unit)
    if not unit or not unitFrame then return end
	local auxiliaryGroupKey = ZF.AuxiliaryHeaderOwner[unitFrame:GetParent()]
	if auxiliaryGroupKey then
		unitFrame.auxiliaryRaidGroup = auxiliaryGroupKey
		if ZF.AUXILIARY_RAID_GROUPS[auxiliaryGroupKey].ownStyle then unitFrame.isAugmentationRaidFrame = true end
	end
    local ctx = BuildElementContext(unitFrame, unit)
    local isRaid = ctx.isRaid

    for _, element in ipairs(UNIT_ELEMENTS) do
        if element.createFirst then ZF[element.create](ZF, unitFrame, unit) end
    end
    for _, element in ipairs(UNIT_ELEMENTS) do
        local when = element.createWhen or element.when
        if not element.createFirst and (not when or when(ctx)) then ZF[element.create](ZF, unitFrame, unit) end
    end
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
    if InCombatLockdown() then -- AnchorUtil.VerticalLayout calls SetPoint on the secure-templated boss frames
        ZF:RunAfterCombat("BossReset", RetryBossReset)
        return
    end
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
    local UnitDB = ZF:GetUnitDB(nil, unit)
	local auxiliaryGroupNeeded = false
	if unit == "raid" then
		for _, groupKey in ipairs(ZF.AUXILIARY_RAID_GROUP_ORDER) do
			if ZF:IsAuxiliaryRaidGroupActive(groupKey) then auxiliaryGroupNeeded = true break end
		end
	end
	if not UnitDB or (not UnitDB.Enabled and not auxiliaryGroupNeeded) then
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
		oUF:RegisterStyle(ZF:FetchFrameName(unit), function(unitFrame, objectUnit) ZF:CreateUnitFrame(unitFrame, objectUnit or unit) end)
	end
    oUF:SetActiveStyle(ZF:FetchFrameName(unit))
	if unit == "raid" then
		if UnitDB.Enabled and not ZF.RAID_CONTAINER then ZF:SpawnGroupFrame("raid") end
		for _, groupKey in ipairs(ZF.AUXILIARY_RAID_GROUP_ORDER) do
			if ZF:IsAuxiliaryRaidGroupActive(groupKey) then ZF:SpawnAuxiliaryRaidGroup(groupKey) end
		end
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
        ZF:UpdateUnitFrame(ZF[unit:upper()], unit)
    elseif unit == "boss" then
        for i = 1, ZF.MAX_BOSS_FRAMES do
            ZF:UpdateUnitFrame(ZF[unit:upper() .. i], unit .. i)
        end
    end
    if InCombatLockdown() then -- reload/login mid-combat: PlaceUnitFrame/LayoutBossFrames above no-op'd, retry once combat ends
        ZF:RunAfterCombat("Spawn:" .. unit, function() RetrySpawnUnitFrame(unit) end)
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
    local parentFrame
    if unit == "player" or unit == "target" then
        parentFrame = UIParent
        unitFrame:ClearAllPoints()
        unitFrame:SetPoint(FrameDB.Layout[1], parentFrame, FrameDB.Layout[2], FrameDB.Layout[3], FrameDB.Layout[4])
    elseif unit == "targettarget" or unit == "focus" or unit == "focustarget" or unit == "pet" then
        parentFrame = FrameDB.AnchorToFrame ~= "None" and _G[FrameDB.AnchorToFrame] or UIParent
        unitFrame:ClearAllPoints()
        unitFrame:SetPoint(FrameDB.Layout[1], parentFrame, FrameDB.Layout[2], FrameDB.Layout[3], FrameDB.Layout[4])
    else
        return
    end
    local left, right, top, bottom = unitFrame:GetLeft(), unitFrame:GetRight(), unitFrame:GetTop(), unitFrame:GetBottom()
    if left and right and top and bottom and (right < 0 or left > GetScreenWidth() or bottom > GetScreenHeight() or top < 0) then
        FrameDB.Layout[3], FrameDB.Layout[4] = 0, 0
        unitFrame:ClearAllPoints()
        unitFrame:SetPoint(FrameDB.Layout[1], parentFrame, FrameDB.Layout[2], 0, 0)
    end
end

local function RetryUpdateUnitFrame(unit)
    if ZF[unit:upper()] then ZF:UpdateUnitFrame(ZF[unit:upper()], unit) end
end

function ZF:UpdateUnitFrame(unitFrame, unit)
    if InCombatLockdown() then
        ZF:RunAfterCombat("Update:" .. unit, function() RetryUpdateUnitFrame(unit) end)
        return
    end
    local ctx = BuildElementContext(unitFrame, unit)
    local UnitDB = ctx.UnitDB

    for _, element in ipairs(UNIT_ELEMENTS) do
        if element.update and (not element.when or element.when(ctx)) then ZF[element.update](ZF, unitFrame, unit) end
    end
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
	if InCombatLockdown() then
		ZF:RunAfterCombat("BossReset", RetryBossReset)
		return
	end
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

		if (BuffsDB.Enabled or DebuffsDB.Enabled or (CustomDB and CustomDB.Enabled)) and not bossFrame:IsElementEnabled("Auras") then
			bossFrame:EnableElement("Auras")
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
	for _, groupKey in ipairs(ZF.AUXILIARY_RAID_GROUP_ORDER) do ZF:UpdateAuxiliaryRaidGroup(groupKey) end
end
