local _, RUF = ...

local function RestoreGroupFrame(unitFrame, unit)
	if not unitFrame or not unit then return end
	if InCombatLockdown() then return end
	unitFrame:SetAttribute("unit", unit == "partyplayer" and "player" or unit)
	RegisterUnitWatch(unitFrame)
	RUF:CreateTestAuras(unitFrame, unit)
	RUF:UpdateUnitFrame(unitFrame, unit)
end

local function UpdatePartyTestEnvironment(element)
	if InCombatLockdown() then return end
	if element ~= "all" then return end
	for i = 1, RUF.MAX_PARTY_FRAMES do if RUF["PARTY" .. i] then RestoreGroupFrame(RUF["PARTY" .. i], "party" .. i) end end
	if RUF.PARTYPLAYER then RestoreGroupFrame(RUF.PARTYPLAYER, "partyplayer") end
	RUF:UpdateGroupFrame("party")
	RUF:UpdateUnitTags("party")
end

local function UpdateRaidTestEnvironment(element)
	if InCombatLockdown() then return end
	if element ~= "all" then return end
	for _, header in ipairs(RUF.RAID_HEADERS) do header:Show() end
	RUF:UpdateGroupFrame("raid")
	RUF:UpdateAugmentationRaidFrames()
	RUF:UpdateUnitTags("raid")
end

local function UpdateBossTestEnvironment(element)
	if InCombatLockdown() then return end
	local BossDB = RUF.db.profile.Units.boss
	local BuffsDB = BossDB.Auras.Buffs
	local DebuffsDB = BossDB.Auras.Debuffs
	local CustomDB = BossDB.Auras.Custom
	for i, BossFrame in ipairs(RUF.BOSS_FRAMES) do
		BossFrame:SetAttribute("unit", "boss" .. i)
		RegisterUnitWatch(BossFrame)
		if BossFrame.Castbar then
			BossFrame.Castbar:Hide()
			BossFrame.Castbar:GetParent():Hide()
			if BossDB.CastBar.Enabled then
				if BossFrame:IsElementEnabled("Castbar") then BossFrame:DisableElement("Castbar") end
				BossFrame:EnableElement("Castbar")
			end
		end
		for j = 1, (BossFrame.BuffContainer and BossFrame.BuffContainer.maxFake or 0) do
			local button = BossFrame.BuffContainer["fake" .. j]
			if button then button:Hide() end
		end
		for j = 1, (BossFrame.DebuffContainer and BossFrame.DebuffContainer.maxFake or 0) do
			local button = BossFrame.DebuffContainer["fake" .. j]
			if button then button:Hide() end
		end
		for j = 1, (BossFrame.CustomAuraContainer and BossFrame.CustomAuraContainer.maxFake or 0) do
			local button = BossFrame.CustomAuraContainer["fake" .. j]
			if button then button:Hide() end
		end
		if BuffsDB.Enabled or DebuffsDB.Enabled then
			if not BossFrame:IsElementEnabled("Auras") then BossFrame:EnableElement("Auras") end
			if BossFrame.BuffContainer and BossFrame.BuffContainer.ForceUpdate then BossFrame.BuffContainer:ForceUpdate() end
			if BossFrame.DebuffContainer and BossFrame.DebuffContainer.ForceUpdate then BossFrame.DebuffContainer:ForceUpdate() end
		end
		if CustomDB and CustomDB.Enabled then
			BossFrame.CustomAuras = BossFrame.CustomAuraContainer
			if not BossFrame:IsElementEnabled("CustomAuras") then BossFrame:EnableElement("CustomAuras") end
			if BossFrame.CustomAuraContainer and BossFrame.CustomAuraContainer.ForceUpdate then BossFrame.CustomAuraContainer:ForceUpdate() end
		end
		BossFrame:Hide()
	end
end

function RUF:UpdateTestEnvironment(unit, element)
	if unit == "party" then
		UpdatePartyTestEnvironment(element)
	elseif unit == "raid" then
		UpdateRaidTestEnvironment(element)
	elseif unit == "boss" then
		UpdateBossTestEnvironment(element)
	end
end
