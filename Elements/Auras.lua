local _, ZF = ...

local PLAYER_SCOPED_FILTER_TOKENS = {
	CrowdControlPlayer = "CROWD_CONTROL",
	BigDefensivePlayer = "BIG_DEFENSIVE",
	ExternalDefensivePlayer = "EXTERNAL_DEFENSIVE",
	RaidInCombatPlayer = "RAID_IN_COMBAT",
	CancelablePlayer = "CANCELABLE",
	RaidPlayer = "RAID",
}
local OTHER_SCOPED_FILTER_TOKENS = {
	CrowdControl = "CROWD_CONTROL",
	BigDefensive = "BIG_DEFENSIVE",
	ExternalDefensive = "EXTERNAL_DEFENSIVE",
	RaidInCombat = "RAID_IN_COMBAT",
	Cancelable = "CANCELABLE",
	Raid = "RAID",
}

local function ResolveAuraContext(unitFrame, unit)
	local AurasDB = ZF:GetUnitDB(unitFrame, unit).Auras
	if not AurasDB then return nil end

	local BuffsDB = AurasDB.Buffs
	local DebuffsDB = AurasDB.Debuffs
	local CustomDB = AurasDB.Custom
	local BuffAnchorParent = BuffsDB.AnchorRegion == "Health" and unitFrame.Health or unitFrame
	local DebuffAnchorParent = DebuffsDB.AnchorRegion == "Health" and unitFrame.Health or unitFrame
	local CustomAuraFilter, CustomAnchorParent
	BuffsDB.Filter = "HELPFUL"
	DebuffsDB.Filter = "HARMFUL"
	if CustomDB then
		CustomAuraFilter = CustomDB.Type == "Debuffs" and "HARMFUL" or "HELPFUL"
		CustomAnchorParent = CustomDB.AnchorRegion == "Health" and unitFrame.Health or unitFrame
		CustomDB.Filter = CustomAuraFilter
	end

	return AurasDB, BuffsDB, DebuffsDB, CustomDB, BuffAnchorParent, DebuffAnchorParent, CustomAuraFilter, CustomAnchorParent
end

local function ComputeAuraContainerSize(auraDB, defaultPerRow)
	local perRow = auraDB.Wrap or defaultPerRow
	local rows = math.ceil(auraDB.Num / perRow)
	local width = (auraDB.Size + auraDB.Layout[5]) * perRow - auraDB.Layout[5]
	local height = (auraDB.Size + auraDB.Layout[5]) * rows - auraDB.Layout[5]
	return width, height
end

local function ConfigurePrivateAuraContainer(unitFrame, unit, PrivateAurasDB)
	local privateAuraContainerWidth = PrivateAurasDB.Size * PrivateAurasDB.Num + PrivateAurasDB.Spacing * (PrivateAurasDB.Num - 1)
	local PrivateAuraAnchorParent = PrivateAurasDB.AnchorRegion == "Health" and unitFrame.Health or unitFrame

	if not unitFrame.PrivateAuraContainer then
		unitFrame.PrivateAuraContainer = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_PrivateAurasContainer", unitFrame)
	end

	unitFrame.PrivateAuraContainer:ClearAllPoints()
	unitFrame.PrivateAuraContainer:SetPoint(PrivateAurasDB.Layout[1], PrivateAuraAnchorParent, PrivateAurasDB.Layout[2], PrivateAurasDB.Layout[3], PrivateAurasDB.Layout[4])
	unitFrame.PrivateAuraContainer:SetSize(math.max(privateAuraContainerWidth, 1), PrivateAurasDB.Size)
	unitFrame.PrivateAuraContainer:SetFrameStrata(PrivateAurasDB.FrameStrata)
	unitFrame.PrivateAuraContainer.size = PrivateAurasDB.Size
	unitFrame.PrivateAuraContainer.width = nil
	unitFrame.PrivateAuraContainer.height = nil
	unitFrame.PrivateAuraContainer.spacing = PrivateAurasDB.Spacing
	unitFrame.PrivateAuraContainer.spacingX = nil
	unitFrame.PrivateAuraContainer.spacingY = nil
	unitFrame.PrivateAuraContainer.growthX = PrivateAurasDB.GrowthX
	unitFrame.PrivateAuraContainer.growthY = PrivateAurasDB.GrowthY
	unitFrame.PrivateAuraContainer.initialAnchor = PrivateAurasDB.InitialAnchor
	unitFrame.PrivateAuraContainer.num = PrivateAurasDB.Num
	unitFrame.PrivateAuraContainer.maxCols = PrivateAurasDB.Num
	unitFrame.PrivateAuraContainer.borderScale = PrivateAurasDB.BorderScale == -1 and -100 or PrivateAurasDB.BorderScale
	unitFrame.PrivateAuraContainer.disableCooldown = PrivateAurasDB.DisableCooldown
	unitFrame.PrivateAuraContainer.disableCooldownText = PrivateAurasDB.DisableCooldownText
end

local function BuildAuraSortOptions(sorting)
	local sortMethod = (sorting == "DURATION" or sorting == "DURATION_REVERSED") and AuraContainerSortMethod.ExpirationOnly or AuraContainerSortMethod.Default
	local sortDirection = (sorting == "BLIZZARD_REVERSED" or sorting == "DURATION_REVERSED") and AuraContainerSortDirection.Reverse or AuraContainerSortDirection.Normal
	return sortMethod, sortDirection
end

local function BuildAuraBlacklist(AuraDB)
	if not AuraDB.Blacklist then return nil end
	local disabled = ZF.db.profile.General.AuraBlacklistDisabled
	if not next(disabled) then
		return { excludeSpellIDs = ZF.db.global.AuraBlacklist }
	end
	local effective = {}
	for spellId in pairs(ZF.db.global.AuraBlacklist) do
		if not disabled[spellId] then effective[spellId] = true end
	end
	return { excludeSpellIDs = effective }
end

local function BuildAuraGroupFilters(AuraDB, baseFilter)
	if AuraDB.OnlyShowPlayer then
		return { baseFilter .. "|PLAYER" }
	end

	local setFilters = AuraDB.Filters
	local filterStrings = {}

	if setFilters then
		if setFilters.Player then filterStrings[#filterStrings + 1] = baseFilter .. "|PLAYER" end
		if setFilters.RaidPlayerDispellable then filterStrings[#filterStrings + 1] = baseFilter .. "|RAID_PLAYER_DISPELLABLE" end
		for filterKey, token in pairs(PLAYER_SCOPED_FILTER_TOKENS) do
			if setFilters[filterKey] then filterStrings[#filterStrings + 1] = baseFilter .. "|PLAYER|" .. token end
		end
		for filterKey, token in pairs(OTHER_SCOPED_FILTER_TOKENS) do
			if setFilters[filterKey] then filterStrings[#filterStrings + 1] = baseFilter .. "|" .. token end
		end
	end

	if #filterStrings == 0 then filterStrings[1] = baseFilter end
	return filterStrings
end

local function BuildAuraGroupSignature(AuraDB, filterStrings, sortMethod, sortDirection, width)
	local signature = AuraDB.Size .. "|" .. AuraDB.Num .. "|" .. width .. "|" .. AuraDB.Layout[1] .. "|" .. AuraDB.GrowthDirection .. "|" .. AuraDB.WrapDirection .. "|" .. tostring(sortMethod) .. "|" .. tostring(sortDirection) .. "|" .. (AuraDB.ShowType and "1" or "0") .. "|" .. table.concat(filterStrings, ",")
	if AuraDB.Blacklist then signature = signature .. "|BL:" .. tostring(ZF.auraBlacklistGeneration or 0) end
	return signature
end

local function StyleAuraButton(unitFrame, unit, auraDB, element, button)
	local AuraDB = ZF:GetUnitDB(unitFrame, unit).Auras[auraDB]
	if not AuraDB then return end

	local buttonBorder = CreateFrame("Frame", nil, button, "BackdropTemplate")
	buttonBorder:SetAllPoints()
	buttonBorder:SetBackdrop({ edgeFile = ZF.Media.Solid, edgeSize = 1, insets = {left = 0, right = 0, top = 0, bottom = 0} })
	buttonBorder:SetBackdropBorderColor(0, 0, 0, 1)

	if button.Icon then button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) end
	if button.Cooldown then
		button.Cooldown:SetDrawEdge(false)
		button.Cooldown:SetReverse(true)
		ZF:ApplyCooldownText(button.Cooldown, nil, unit, unitFrame)
	end
	if button.Count then
		if AuraDB.Count.HideStacks then
			button.Count:Hide()
		else
			local FontsDB = ZF.db.profile.General.Fonts
			button.Count:ClearAllPoints()
			button.Count:SetPoint(AuraDB.Count.Layout[1], button, AuraDB.Count.Layout[2], AuraDB.Count.Layout[3], AuraDB.Count.Layout[4])
			ZF:ApplyFontStringStyle(button.Count, ZF.Media.Font, AuraDB.Count.FontSize, FontsDB.FontFlag, AuraDB.Count.Color, FontsDB.Shadow)
			button.Count:Show()
		end
	end
end

local function RebuildAuraGroup(unitFrame, unit, storageKey, auraDB, AuraDB, baseFilter, anchorParent, defaultPerRow)
	if not AuraDB or not AuraDB.Enabled then
		if unitFrame[storageKey] then unitFrame[storageKey]:Hide() end
		unitFrame[storageKey] = nil
		unitFrame[storageKey .. "Signature"] = nil
		return nil
	end

	local width = ComputeAuraContainerSize(AuraDB, defaultPerRow)
	local sortMethod, sortDirection = BuildAuraSortOptions(AuraDB.Sorting)
	local filterStrings = BuildAuraGroupFilters(AuraDB, baseFilter)
	local signature = BuildAuraGroupSignature(AuraDB, filterStrings, sortMethod, sortDirection, width)

	local auras = unitFrame[storageKey]
	if not auras or unitFrame[storageKey .. "Signature"] ~= signature then
		if auras then auras:Hide() end

		local candidateFilters = BuildAuraBlacklist(AuraDB)
		auras = unitFrame:CreateAuras({
			initialAnchor = AuraDB.Layout[1],
			growthX = AuraDB.GrowthDirection,
			growthY = AuraDB.WrapDirection,
			layoutLimit = width,
		})
		auras.maxFrameCount = AuraDB.Num
		auras.size = AuraDB.Size
		auras.showCount = true
		auras.showBuffBorder = baseFilter == "HELPFUL" and AuraDB.ShowType or nil
		auras.showDebuffBorder = baseFilter == "HARMFUL" and AuraDB.ShowType or nil
		auras.tooltipAnchor = "ANCHOR_CURSOR"
		auras.PostCreateButton = function(_, button) StyleAuraButton(unitFrame, unit, auraDB, auras, button) end

		for _, filterString in ipairs(filterStrings) do
			auras:AddGroup(filterString, {
				sortMethod = sortMethod,
				sortDirection = sortDirection,
				candidateFilters = candidateFilters,
			})
		end

		auras:SetUnit(unitFrame.__unit or unit)
		auras:ForceUpdate()

		unitFrame[storageKey] = auras
		unitFrame[storageKey .. "Signature"] = signature
	end

	auras:ClearAllPoints()
	auras:SetPoint(AuraDB.Layout[1], anchorParent, AuraDB.Layout[2], AuraDB.Layout[3], AuraDB.Layout[4])
	auras:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 15)
	auras:Show()

	return auras
end

function ZF:UpdateUnitAuras(unitFrame, unit)
    if not unit or not unitFrame then return end
    local AurasDB, BuffsDB, DebuffsDB, CustomDB, BuffAnchorParent, DebuffAnchorParent, CustomAuraFilter, CustomAnchorParent = ResolveAuraContext(unitFrame, unit)
    if not AurasDB then return end

    if AurasDB.PrivateAuras then
        local PrivateAurasDB = AurasDB.PrivateAuras
        ConfigurePrivateAuraContainer(unitFrame, unit, PrivateAurasDB)

        if PrivateAurasDB.Enabled then
            unitFrame.PrivateAuras = unitFrame.PrivateAuraContainer
            unitFrame.PrivateAuraContainer:Show()
            if not unitFrame:IsElementEnabled("PrivateAuras") then unitFrame:EnableElement("PrivateAuras") end
            if unitFrame.PrivateAuraContainer.ForceUpdate then unitFrame.PrivateAuraContainer:ForceUpdate() end
        else
            if unitFrame:IsElementEnabled("PrivateAuras") then unitFrame:DisableElement("PrivateAuras") end
            unitFrame.PrivateAuras = nil
            unitFrame.PrivateAuraContainer:Hide()
        end
    end

    unitFrame.BuffContainer:ClearAllPoints()
    unitFrame.BuffContainer:SetPoint(BuffsDB.Layout[1], BuffAnchorParent, BuffsDB.Layout[2], BuffsDB.Layout[3], BuffsDB.Layout[4])
    unitFrame.BuffContainer:SetFrameStrata(AurasDB.FrameStrata)
    local buffContainerWidth, buffContainerHeight = ComputeAuraContainerSize(BuffsDB, 4)
    unitFrame.BuffContainer:SetSize(buffContainerWidth, buffContainerHeight)

    unitFrame.DebuffContainer:ClearAllPoints()
    unitFrame.DebuffContainer:SetPoint(DebuffsDB.Layout[1], DebuffAnchorParent, DebuffsDB.Layout[2], DebuffsDB.Layout[3], DebuffsDB.Layout[4])
    unitFrame.DebuffContainer:SetFrameStrata(AurasDB.FrameStrata)
    local debuffContainerWidth, debuffContainerHeight = ComputeAuraContainerSize(DebuffsDB, 4)
    unitFrame.DebuffContainer:SetSize(debuffContainerWidth, debuffContainerHeight)

    if unitFrame.CustomAuraContainer and CustomDB then
        unitFrame.CustomAuraContainer:ClearAllPoints()
        unitFrame.CustomAuraContainer:SetPoint(CustomDB.Layout[1], CustomAnchorParent, CustomDB.Layout[2], CustomDB.Layout[3], CustomDB.Layout[4])
        unitFrame.CustomAuraContainer:SetFrameStrata(AurasDB.FrameStrata)
        local customContainerWidth, customContainerHeight = ComputeAuraContainerSize(CustomDB, 3)
        unitFrame.CustomAuraContainer:SetSize(customContainerWidth, customContainerHeight)
    end

    RebuildAuraGroup(unitFrame, unit, "BuffAuras", "Buffs", BuffsDB, "HELPFUL", BuffAnchorParent, 4)
    RebuildAuraGroup(unitFrame, unit, "DebuffAuras", "Debuffs", DebuffsDB, "HARMFUL", DebuffAnchorParent, 4)
    if CustomDB then
        RebuildAuraGroup(unitFrame, unit, "CustomAurasElement", "Custom", CustomDB, CustomAuraFilter, CustomAnchorParent, 3)
    end

    if unitFrame.BuffAuras or unitFrame.DebuffAuras or unitFrame.CustomAurasElement or unitFrame.DispelAuras then
        if not unitFrame:IsElementEnabled("Auras") then unitFrame:EnableElement("Auras") end
    elseif unitFrame:IsElementEnabled("Auras") then
        unitFrame:DisableElement("Auras")
    end

    if (unitFrame.isDesignerPreview and ZF.DESIGNER_PREVIEW_TOGGLES.Auras) or unitFrame.isUnitPreview then ZF:CreateTestAuras(unitFrame, unit) end
end

function ZF:CreateUnitAuras(unitFrame, unit)
	local AurasDB, BuffsDB, DebuffsDB, CustomDB, BuffAnchorParent, DebuffAnchorParent, _, CustomAnchorParent = ResolveAuraContext(unitFrame, unit)
	if not AurasDB then return end

	if not unitFrame.BuffContainer then
		unitFrame.BuffContainer = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_BuffsContainer", unitFrame)
		unitFrame.BuffContainer:SetFrameStrata(AurasDB.FrameStrata)
		local buffContainerWidth, buffContainerHeight = ComputeAuraContainerSize(BuffsDB, 4)
		unitFrame.BuffContainer:SetSize(buffContainerWidth, buffContainerHeight)
		unitFrame.BuffContainer:SetPoint(BuffsDB.Layout[1], BuffAnchorParent, BuffsDB.Layout[2], BuffsDB.Layout[3], BuffsDB.Layout[4])
	end

	if not unitFrame.DebuffContainer then
		unitFrame.DebuffContainer = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_DebuffsContainer", unitFrame)
		unitFrame.DebuffContainer:SetFrameStrata(AurasDB.FrameStrata)
		local debuffContainerWidth, debuffContainerHeight = ComputeAuraContainerSize(DebuffsDB, 4)
		unitFrame.DebuffContainer:SetSize(debuffContainerWidth, debuffContainerHeight)
		unitFrame.DebuffContainer:SetPoint(DebuffsDB.Layout[1], DebuffAnchorParent, DebuffsDB.Layout[2], DebuffsDB.Layout[3], DebuffsDB.Layout[4])
	end

	if CustomDB and not unitFrame.CustomAuraContainer then
		unitFrame.CustomAuraContainer = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_CustomAurasContainer", unitFrame)
		unitFrame.CustomAuraContainer:SetFrameStrata(AurasDB.FrameStrata)
		local customContainerWidth, customContainerHeight = ComputeAuraContainerSize(CustomDB, 3)
		unitFrame.CustomAuraContainer:SetSize(customContainerWidth, customContainerHeight)
		unitFrame.CustomAuraContainer:SetPoint(CustomDB.Layout[1], CustomAnchorParent, CustomDB.Layout[2], CustomDB.Layout[3], CustomDB.Layout[4])
	end

    if AurasDB.PrivateAuras then
        local PrivateAurasDB = AurasDB.PrivateAuras
        ConfigurePrivateAuraContainer(unitFrame, unit, PrivateAurasDB)

        if PrivateAurasDB.Enabled then
            unitFrame.PrivateAuras = unitFrame.PrivateAuraContainer
            unitFrame.PrivateAuraContainer:Show()
        else
            unitFrame.PrivateAuraContainer:Hide()
        end
    end
end

function ZF:UpdateUnitAurasStrata(unit)
    if not unit then return end
    local normalizedUnit = ZF:GetNormalizedUnit(unit)
    local unitFrame = ZF[unit:upper()]
    local unitDB = ZF.db.profile.Units[normalizedUnit]
    if unit == "party" then
        if not unitDB or not unitDB.Auras then return end
        for i = 1, ZF.MAX_PARTY_FRAMES do
            ZF:UpdateUnitAurasStrata("party" .. i)
        end
        if ZF.PARTYPLAYER and unitDB.Auras.PrivateAuras and ZF.PARTYPLAYER.PrivateAuraContainer then ZF.PARTYPLAYER.PrivateAuraContainer:SetFrameStrata(unitDB.Auras.PrivateAuras.FrameStrata) end
        return
	end
	if unit == "augmentation" then
		ZF:ForEachAugmentationRaidFrame(function(raidFrame, frameUnit)
			local augmentationDB = ZF:GetUnitDB(raidFrame, frameUnit)
			if raidFrame.BuffContainer then raidFrame.BuffContainer:SetFrameStrata(augmentationDB.Auras.FrameStrata) end
			if raidFrame.DebuffContainer then raidFrame.DebuffContainer:SetFrameStrata(augmentationDB.Auras.FrameStrata) end
			if raidFrame.CustomAuraContainer then raidFrame.CustomAuraContainer:SetFrameStrata(augmentationDB.Auras.FrameStrata) end
			if raidFrame.PrivateAuraContainer and augmentationDB.Auras.PrivateAuras then raidFrame.PrivateAuraContainer:SetFrameStrata(augmentationDB.Auras.PrivateAuras.FrameStrata) end
		end, false)
		return
	end
    if not unitFrame or not unitDB or not unitDB.Auras then return end
    if unitFrame.BuffContainer then unitFrame.BuffContainer:SetFrameStrata(unitDB.Auras.FrameStrata) end
    if unitFrame.DebuffContainer then unitFrame.DebuffContainer:SetFrameStrata(unitDB.Auras.FrameStrata) end
    if unitFrame.CustomAuraContainer then unitFrame.CustomAuraContainer:SetFrameStrata(unitDB.Auras.FrameStrata) end
    if unitFrame.PrivateAuraContainer and unitDB.Auras.PrivateAuras then unitFrame.PrivateAuraContainer:SetFrameStrata(unitDB.Auras.PrivateAuras.FrameStrata) end
end

local function CreateFakeAuraButton(container, auraDB, General, unit, unitFrame, index, iconTextureID, perRow, frameStrata)
	local button = container["fake" .. index]
	if not button then
		button = CreateFrame("Button", nil, container, "BackdropTemplate")
		button:SetBackdrop(ZF.BACKDROP)
		button:SetBackdropColor(0, 0, 0, 0)
		button:SetBackdropBorderColor(0, 0, 0, 1)
		button:SetFrameStrata(frameStrata)

		button.Icon = button:CreateTexture(nil, "BORDER")
		button.Icon:SetAllPoints()

		button.Count = button:CreateFontString(nil, "OVERLAY")
		container["fake" .. index] = button
	end

	button:SetSize(auraDB.Size, auraDB.Size)
	button.Count:ClearAllPoints()
	button.Count:SetPoint(auraDB.Count.Layout[1], button, auraDB.Count.Layout[2], auraDB.Count.Layout[3], auraDB.Count.Layout[4])
	ZF:ApplyFontStringStyle(button.Count, ZF.Media.Font, auraDB.Count.FontSize, General.Fonts.FontFlag, auraDB.Count.Color, General.Fonts.Shadow)

	local row = math.floor((index - 1) / perRow)
	local col = (index - 1) % perRow
	local x = col * (auraDB.Size + auraDB.Layout[5])
	local y = row * (auraDB.Size + auraDB.Layout[5])
	if auraDB.GrowthDirection == "LEFT" then x = -x end
	if auraDB.WrapDirection == "DOWN" then y = -y end

	button:ClearAllPoints()
	button:SetPoint(auraDB.Layout[1], container, auraDB.Layout[1], x, y)

	button.Icon:SetTexture(iconTextureID)
	button.Icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	button.Icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
	button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	button.Count:SetText(index)
	if auraDB.Count.HideStacks then button.Count:Hide() else button.Count:Show() end
	button.Duration = button.Duration or button:CreateFontString(nil, "OVERLAY")
	ZF:ApplyCooldownText(button, button.Duration, unit, unitFrame)
	button.Duration:SetText("10m")
	button:Show()
end

local function RefreshTestAuraContainer(container, auraDB, anchorParent, frameStrata, General, unit, unitFrame, iconTextureID, defaultPerRow)
	if not container then return end
	if auraDB.Enabled then
		container:ClearAllPoints()
		container:SetPoint(auraDB.Layout[1], anchorParent, auraDB.Layout[2], auraDB.Layout[3], auraDB.Layout[4])
		container:SetFrameStrata(frameStrata)
		container:Show()
		for _, button in ipairs(container) do
			if button then button:Hide() end
		end

		local perRow = auraDB.Wrap or defaultPerRow
		for j = 1, auraDB.Num do
			CreateFakeAuraButton(container, auraDB, General, unit, unitFrame, j, iconTextureID, perRow, frameStrata)
		end

		local maxFake = auraDB.Num
		for j = maxFake + 1, (container.maxFake or maxFake) do
			local button = container["fake" .. j]
			if button then button:Hide() end
		end
		container.maxFake = auraDB.Num
	else
		container:Hide()
	end
end

function ZF:CreateTestAuras(unitFrame, unit)
    if not unit then return end
    if not unitFrame then return end
    local General = ZF.db.profile.General
    local AurasDB = ZF:GetUnitDB(unitFrame, unit).Auras
    local BuffsDB = AurasDB.Buffs
    local DebuffsDB = AurasDB.Debuffs
    local CustomDB = AurasDB.Custom
	local BuffAnchorParent = BuffsDB.AnchorRegion == "Health" and unitFrame.Health or unitFrame
	local DebuffAnchorParent = DebuffsDB.AnchorRegion == "Health" and unitFrame.Health or unitFrame
	local CustomAnchorParent = CustomDB and CustomDB.AnchorRegion == "Health" and unitFrame.Health or unitFrame
    if (unitFrame.isDesignerPreview and ZF.DESIGNER_PREVIEW_TOGGLES.Auras) or unitFrame.isUnitPreview then
        if unitFrame:IsElementEnabled("Auras") then unitFrame:DisableElement("Auras") end

		if unitFrame.PrivateAuraContainer and AurasDB.PrivateAuras then
			local PrivateAurasDB = AurasDB.PrivateAuras
			if PrivateAurasDB.Enabled then
				unitFrame.PrivateAuraContainer:Show()

				for j = 1, PrivateAurasDB.Num do
					local button = unitFrame.PrivateAuraContainer["fake" .. j]
					if not button then
						button = CreateFrame("Frame", nil, unitFrame.PrivateAuraContainer, "BackdropTemplate")
						button:SetBackdrop(ZF.BACKDROP)
						button:SetBackdropColor(0, 0, 0, 0)
						button:SetBackdropBorderColor(0, 0, 0, 1)

						button.Icon = button:CreateTexture(nil, "BORDER")
						button.Icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
						button.Icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
						button.Icon:SetTexture(135768)
						button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

						button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
						button.Cooldown:SetAllPoints()
						button.Cooldown:SetDrawEdge(false)
						button.Cooldown:SetReverse(true)
						button.Cooldown:SetCooldown(GetTime(), 600)
						unitFrame.PrivateAuraContainer["fake" .. j] = button
					end

					local column = (j - 1) % PrivateAurasDB.Num
					local row = math.floor((j - 1) / PrivateAurasDB.Num)
					local x = column * (PrivateAurasDB.Size + PrivateAurasDB.Spacing)
					local y = row * (PrivateAurasDB.Size + PrivateAurasDB.Spacing)
					if PrivateAurasDB.GrowthX == "LEFT" then x = -x end
					if PrivateAurasDB.GrowthY == "DOWN" then y = -y end

					button:SetSize(PrivateAurasDB.Size, PrivateAurasDB.Size)
					button:SetFrameStrata(PrivateAurasDB.FrameStrata)
					button:ClearAllPoints()
					button:SetPoint(PrivateAurasDB.InitialAnchor, unitFrame.PrivateAuraContainer, PrivateAurasDB.InitialAnchor, x, y)
					button.Cooldown:SetDrawSwipe(not PrivateAurasDB.DisableCooldown)
					button.Cooldown:SetHideCountdownNumbers(PrivateAurasDB.DisableCooldownText)
					button.Cooldown:SetShown(not PrivateAurasDB.DisableCooldown or not PrivateAurasDB.DisableCooldownText)
					button:Show()
				end

				local maxFake = PrivateAurasDB.Num
				for j = maxFake + 1, (unitFrame.PrivateAuraContainer.maxFake or maxFake) do
					local button = unitFrame.PrivateAuraContainer["fake" .. j]
					if button then button:Hide() end
				end
				unitFrame.PrivateAuraContainer.maxFake = PrivateAurasDB.Num
			else
				for j = 1, (unitFrame.PrivateAuraContainer.maxFake or 0) do
					local button = unitFrame.PrivateAuraContainer["fake" .. j]
					if button then button:Hide() end
				end
			end
		end

        RefreshTestAuraContainer(unitFrame.BuffContainer, BuffsDB, BuffAnchorParent, AurasDB.FrameStrata, General, unit, unitFrame, 135769, 4)
        RefreshTestAuraContainer(unitFrame.DebuffContainer, DebuffsDB, DebuffAnchorParent, AurasDB.FrameStrata, General, unit, unitFrame, 135768, 4)
        if CustomDB then
            RefreshTestAuraContainer(unitFrame.CustomAuraContainer, CustomDB, CustomAnchorParent, AurasDB.FrameStrata, General, unit, unitFrame, CustomDB.Type == "Debuffs" and 135768 or 135769, 3)
        end
    else
        if unitFrame.BuffContainer then
            for j = 1, (unitFrame.BuffContainer.maxFake or 0) do
                local button = unitFrame.BuffContainer["fake" .. j]
                if button then button:Hide() end
            end
        end
        if unitFrame.DebuffContainer then
            for j = 1, (unitFrame.DebuffContainer.maxFake or 0) do
                local button = unitFrame.DebuffContainer["fake" .. j]
                if button then button:Hide() end
            end
        end
        if unitFrame.CustomAuraContainer then
            for j = 1, (unitFrame.CustomAuraContainer.maxFake or 0) do
                local button = unitFrame.CustomAuraContainer["fake" .. j]
                if button then button:Hide() end
            end
        end
        if unitFrame.BuffAuras or unitFrame.DebuffAuras or unitFrame.CustomAurasElement or unitFrame.DispelAuras then
            if not unitFrame:IsElementEnabled("Auras") then unitFrame:EnableElement("Auras") end
        end
		if unitFrame.PrivateAuraContainer then
			for j = 1, (unitFrame.PrivateAuraContainer.maxFake or 0) do
				local button = unitFrame.PrivateAuraContainer["fake" .. j]
				if button then button:Hide() end
			end
		end
    end
end
