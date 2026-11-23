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

local AURA_SLOTS = {
	{ dbKey = "Buffs", containerKey = "BuffContainer", storageKey = "BuffAuras", nameSuffix = "_BuffsContainer", perRow = 4 },
	{ dbKey = "Debuffs", containerKey = "DebuffContainer", storageKey = "DebuffAuras", nameSuffix = "_DebuffsContainer", perRow = 4 },
	{ dbKey = "Custom", containerKey = "CustomAuraContainer", storageKey = "CustomAurasElement", nameSuffix = "_CustomAurasContainer", perRow = 3 },
}

local BUFF_TEST_ICON = 135769
local DEBUFF_TEST_ICON = 135768

local function SlotIsDebuff(slot, AuraDB)
	if slot.dbKey == "Custom" then return AuraDB.Type == "Debuffs" end
	return slot.dbKey == "Debuffs"
end

local function SlotFilter(slot, AuraDB)
	return SlotIsDebuff(slot, AuraDB) and "HARMFUL" or "HELPFUL"
end

local function SlotAnchorParent(unitFrame, AuraDB)
	return AuraDB.AnchorRegion == "Health" and unitFrame.Health or unitFrame
end

local function ResolveAurasDB(unitFrame, unit)
	local AurasDB = ZF:GetUnitDB(unitFrame, unit).Auras
	if not AurasDB or not AurasDB.Buffs or not AurasDB.Debuffs then return nil end
	return AurasDB
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
	local Count = AuraDB.Count
	if Count then
		signature = signature .. "|C:" .. tostring(Count.HideStacks) .. "," .. Count.FontSize .. "," .. table.concat(Count.Layout, ",") .. "," .. table.concat(Count.Color, ",")
	end
	return signature
end

local function StyleAuraButton(unitFrame, storageKey, button)
	local AuraDB = unitFrame[storageKey .. "DB"]
	if not AuraDB then return end

	local buttonBorder = CreateFrame("Frame", nil, button, "BackdropTemplate")
	buttonBorder:SetAllPoints()
	buttonBorder:SetBackdrop({ edgeFile = ZF.Media.Solid, edgeSize = 1, insets = {left = 0, right = 0, top = 0, bottom = 0} })
	buttonBorder:SetBackdropBorderColor(0, 0, 0, 1)

	if button.Icon then button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) end
	if button.Cooldown then
		button.Cooldown:SetDrawEdge(false)
		button.Cooldown:SetReverse(true)
		ZF:ApplyDurationText(button.Cooldown, nil, unitFrame[storageKey .. "DurationDB"])
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

	unitFrame[storageKey .. "DB"] = AuraDB
	unitFrame[storageKey .. "DurationDB"] = ZF:GetUnitDB(unitFrame, unit).Auras.AuraDuration

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
		auras.PostCreateButton = function(_, button) StyleAuraButton(unitFrame, storageKey, button) end

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

local function SyncAuraContainer(container, AuraDB, anchorParent, frameStrata, perRow)
	container:ClearAllPoints()
	container:SetPoint(AuraDB.Layout[1], anchorParent, AuraDB.Layout[2], AuraDB.Layout[3], AuraDB.Layout[4])
	container:SetFrameStrata(frameStrata)
	container:SetSize(ComputeAuraContainerSize(AuraDB, perRow))
end

local function SyncPrivateAuras(unitFrame, unit, AurasDB, toggleElement)
	local PrivateAurasDB = AurasDB.PrivateAuras
	if not PrivateAurasDB then return end
	ConfigurePrivateAuraContainer(unitFrame, unit, PrivateAurasDB)

	if PrivateAurasDB.Enabled then
		unitFrame.PrivateAuras = unitFrame.PrivateAuraContainer
		unitFrame.PrivateAuraContainer:Show()
		if toggleElement then
			if not unitFrame:IsElementEnabled("PrivateAuras") then unitFrame:EnableElement("PrivateAuras") end
			if unitFrame.PrivateAuraContainer.ForceUpdate then unitFrame.PrivateAuraContainer:ForceUpdate() end
		end
	else
		if toggleElement then
			if unitFrame:IsElementEnabled("PrivateAuras") then unitFrame:DisableElement("PrivateAuras") end
			unitFrame.PrivateAuras = nil
		end
		unitFrame.PrivateAuraContainer:Hide()
	end
end

local function HasLiveAuraElements(unitFrame)
	return unitFrame.BuffAuras or unitFrame.DebuffAuras or unitFrame.CustomAurasElement or unitFrame.DispelAuras
end

function ZF:UpdateUnitAuras(unitFrame, unit)
	if not unit or not unitFrame then return end
	local AurasDB = ResolveAurasDB(unitFrame, unit)
	if not AurasDB then return end

	SyncPrivateAuras(unitFrame, unit, AurasDB, true)

	for _, slot in ipairs(AURA_SLOTS) do
		local AuraDB = AurasDB[slot.dbKey]
		local container = unitFrame[slot.containerKey]
		if AuraDB and container then SyncAuraContainer(container, AuraDB, SlotAnchorParent(unitFrame, AuraDB), AurasDB.FrameStrata, slot.perRow) end
	end

	for _, slot in ipairs(AURA_SLOTS) do
		local AuraDB = AurasDB[slot.dbKey]
		if AuraDB then RebuildAuraGroup(unitFrame, unit, slot.storageKey, slot.dbKey, AuraDB, SlotFilter(slot, AuraDB), SlotAnchorParent(unitFrame, AuraDB), slot.perRow) end
	end

	if HasLiveAuraElements(unitFrame) then
		if not unitFrame:IsElementEnabled("Auras") then unitFrame:EnableElement("Auras") end
	elseif unitFrame:IsElementEnabled("Auras") then
		unitFrame:DisableElement("Auras")
	end

	if (unitFrame.isDesignerPreview and ZF.DESIGNER_PREVIEW_TOGGLES.Auras) or unitFrame.isUnitPreview then ZF:CreateTestAuras(unitFrame, unit) end
end

function ZF:CreateUnitAuras(unitFrame, unit)
	local AurasDB = ResolveAurasDB(unitFrame, unit)
	if not AurasDB then return end

	for _, slot in ipairs(AURA_SLOTS) do
		local AuraDB = AurasDB[slot.dbKey]
		if AuraDB and not unitFrame[slot.containerKey] then
			local container = CreateFrame("Frame", ZF:FetchFrameName(unit) .. slot.nameSuffix, unitFrame)
			unitFrame[slot.containerKey] = container
			SyncAuraContainer(container, AuraDB, SlotAnchorParent(unitFrame, AuraDB), AurasDB.FrameStrata, slot.perRow)
		end
	end

	SyncPrivateAuras(unitFrame, unit, AurasDB, false)
end

function ZF:HideFakeAuraButtons(container, firstIndex)
	if not container then return end
	for index = firstIndex or 1, container.maxFake or 0 do
		local button = container["fake" .. index]
		if button then button:Hide() end
	end
end

local function FakeGridOffset(index, perRow, size, spacing, leftward, downward)
	local x = ((index - 1) % perRow) * (size + spacing)
	local y = math.floor((index - 1) / perRow) * (size + spacing)
	if leftward then x = -x end
	if downward then y = -y end
	return x, y
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

	local x, y = FakeGridOffset(index, perRow, auraDB.Size, auraDB.Layout[5], auraDB.GrowthDirection == "LEFT", auraDB.WrapDirection == "DOWN")
	button:ClearAllPoints()
	button:SetPoint(auraDB.Layout[1], container, auraDB.Layout[1], x, y)

	button.Icon:SetTexture(iconTextureID)
	button.Icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	button.Icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
	button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	button.Count:SetText(index)
	if auraDB.Count.HideStacks then button.Count:Hide() else button.Count:Show() end
	button.Duration = button.Duration or button:CreateFontString(nil, "OVERLAY")
	ZF:ApplyDurationText(button, button.Duration, ZF:GetUnitDB(unitFrame, unit).Auras.AuraDuration)
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

		ZF:HideFakeAuraButtons(container, auraDB.Num + 1)
		container.maxFake = auraDB.Num
	else
		container:Hide()
	end
end

local function CreateFakePrivateAuraButton(container, index)
	local button = CreateFrame("Frame", nil, container, "BackdropTemplate")
	button:SetBackdrop(ZF.BACKDROP)
	button:SetBackdropColor(0, 0, 0, 0)
	button:SetBackdropBorderColor(0, 0, 0, 1)

	button.Icon = button:CreateTexture(nil, "BORDER")
	button.Icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	button.Icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
	button.Icon:SetTexture(DEBUFF_TEST_ICON)
	button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	button.Cooldown:SetAllPoints()
	button.Cooldown:SetDrawEdge(false)
	button.Cooldown:SetReverse(true)
	button.Cooldown:SetCooldown(GetTime(), 600)
	container["fake" .. index] = button
	return button
end

local function RefreshTestPrivateAuras(container, PrivateAurasDB)
	if not PrivateAurasDB.Enabled then
		ZF:HideFakeAuraButtons(container)
		return
	end
	container:Show()

	for j = 1, PrivateAurasDB.Num do
		local button = container["fake" .. j] or CreateFakePrivateAuraButton(container, j)
		local x, y = FakeGridOffset(j, PrivateAurasDB.Num, PrivateAurasDB.Size, PrivateAurasDB.Spacing, PrivateAurasDB.GrowthX == "LEFT", PrivateAurasDB.GrowthY == "DOWN")

		button:SetSize(PrivateAurasDB.Size, PrivateAurasDB.Size)
		button:SetFrameStrata(PrivateAurasDB.FrameStrata)
		button:ClearAllPoints()
		button:SetPoint(PrivateAurasDB.InitialAnchor, container, PrivateAurasDB.InitialAnchor, x, y)
		button.Cooldown:SetDrawSwipe(not PrivateAurasDB.DisableCooldown)
		button.Cooldown:SetHideCountdownNumbers(PrivateAurasDB.DisableCooldownText)
		button.Cooldown:SetShown(not PrivateAurasDB.DisableCooldown or not PrivateAurasDB.DisableCooldownText)
		button:Show()
	end

	ZF:HideFakeAuraButtons(container, PrivateAurasDB.Num + 1)
	container.maxFake = PrivateAurasDB.Num
end

function ZF:CreateTestAuras(unitFrame, unit)
	if not unit then return end
	if not unitFrame then return end
	local General = ZF.db.profile.General
	local AurasDB = ZF:GetUnitDB(unitFrame, unit).Auras

	if (unitFrame.isDesignerPreview and ZF.DESIGNER_PREVIEW_TOGGLES.Auras) or unitFrame.isUnitPreview then
		if unitFrame:IsElementEnabled("Auras") then unitFrame:DisableElement("Auras") end

		if unitFrame.PrivateAuraContainer and AurasDB.PrivateAuras then
			RefreshTestPrivateAuras(unitFrame.PrivateAuraContainer, AurasDB.PrivateAuras)
		end

		for _, slot in ipairs(AURA_SLOTS) do
			local AuraDB = AurasDB[slot.dbKey]
			if AuraDB then
				local iconTextureID = SlotIsDebuff(slot, AuraDB) and DEBUFF_TEST_ICON or BUFF_TEST_ICON
				RefreshTestAuraContainer(unitFrame[slot.containerKey], AuraDB, SlotAnchorParent(unitFrame, AuraDB), AurasDB.FrameStrata, General, unit, unitFrame, iconTextureID, slot.perRow)
			end
		end
	else
		for _, slot in ipairs(AURA_SLOTS) do
			ZF:HideFakeAuraButtons(unitFrame[slot.containerKey])
		end
		if HasLiveAuraElements(unitFrame) then
			if not unitFrame:IsElementEnabled("Auras") then unitFrame:EnableElement("Auras") end
		end
		ZF:HideFakeAuraButtons(unitFrame.PrivateAuraContainer)
	end
end
