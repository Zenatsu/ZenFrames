local _, ZF = ...
local oUF = ZF.oUF

local TypedDebuffTypes = {
	Magic = oUF.Enum.DispelType.Magic,
	Curse = oUF.Enum.DispelType.Curse,
	Disease = oUF.Enum.DispelType.Disease,
	Poison = oUF.Enum.DispelType.Poison,
	Bleed = oUF.Enum.DispelType.Bleed,
}

local TypedDebuffColorCurve = C_CurveUtil.CreateColorCurve()
TypedDebuffColorCurve:SetType(Enum.LuaCurveType.Step)
for _, dispelIndex in pairs(TypedDebuffTypes) do
	local color = oUF.colors.dispel[dispelIndex]
	if color then TypedDebuffColorCurve:AddPoint(dispelIndex, color) end
end

local function BuildDispelColorCurve(container)
	container.dispelColorCurve = C_CurveUtil.CreateColorCurve()
	container.dispelColorCurve:SetType(Enum.LuaCurveType.Step)
	for _, dispelIndex in next, oUF.Enum.DispelType do
		if oUF.colors.dispel[dispelIndex] then
			container.dispelColorCurve:AddPoint(dispelIndex, oUF.colors.dispel[dispelIndex])
		end
	end
	if not oUF.colors.dispel[0] then container.dispelColorCurve:AddPoint(0, CreateColor(0.8, 0, 0, 1)) end
end

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

local function StyleAuras(_, button, unit, auraType, restyle, auraDB)
	if not button or not unit or not auraType then return end
	local unitFrame = button:GetParent() and button:GetParent():GetParent()
	local AurasDB = ZF:GetUnitDB(unitFrame, unit).Auras
	if not AurasDB then return end
	local AuraDB = auraDB and AurasDB[auraDB] or auraType == "HELPFUL" and AurasDB.Buffs or AurasDB.Debuffs
	if not AuraDB then return end

	if not restyle then
		local buttonBorder = CreateFrame("Frame", nil, button, "BackdropTemplate")
		buttonBorder:SetAllPoints()
		buttonBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, insets = {left = 0, right = 0, top = 0, bottom = 0} })
		buttonBorder:SetBackdropBorderColor(0, 0, 0, 1)
	end

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
	if not restyle and button.Overlay then
		button.Overlay:SetTexture("Interface\\AddOns\\ZenFrames\\Media\\Textures\\AuraOverlay.png")
		button.Overlay:ClearAllPoints()
		button.Overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
		button.Overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
		button.Overlay:SetTexCoord(0, 1, 0, 1)
	end
end

local function FilterAura(AuraDB, filterUnit, aura, auraType)
	if AuraDB.Blacklist then
		local spellId = not ZF:IsSecretValue(aura.spellId) and aura.spellId
		local name = not ZF:IsSecretValue(aura.name) and aura.name
		if (spellId and ZF.AURA_BLACKLIST[spellId]) or (name and ZF.AURA_BLACKLIST[name]) then return false end
	end
	if AuraDB.OnlyShowPlayer then return aura.isPlayerAura end
	local setFilters = AuraDB.Filters
	if not setFilters or not next(setFilters) then return true end

	local auraInstanceID = aura.auraInstanceID
	local isPlayer = aura.isPlayerAura
	local cancelFilter = isPlayer and "CancelablePlayer" or "Cancelable"
	local noCancelFilter = isPlayer and "NotCancelablePlayer" or "NotCancelable"

	if setFilters.Player and isPlayer then return true end
	if auraType == "HARMFUL" and setFilters.Typed then
		if C_UnitAuras.GetAuraDispelTypeColor(filterUnit, auraInstanceID, TypedDebuffColorCurve) then return true end
		local dispelName = not ZF:IsSecretValue(aura.dispelName) and aura.dispelName
		if dispelName and TypedDebuffTypes[dispelName] then return true end
	end
	if setFilters.RaidPlayerDispellable and not C_UnitAuras.IsAuraFilteredOutByInstanceID(filterUnit, auraInstanceID, auraType .. "|RAID_PLAYER_DISPELLABLE") then return true end

	if (setFilters[cancelFilter] or setFilters[noCancelFilter]) then
		local isCancellable = not C_UnitAuras.IsAuraFilteredOutByInstanceID(filterUnit, auraInstanceID, auraType .. "|CANCELABLE")
		if setFilters[cancelFilter] and isCancellable then return true end
		if setFilters[noCancelFilter] and not isCancellable then return true end
	end

	if isPlayer then
		if setFilters.CrowdControlPlayer and not C_UnitAuras.IsAuraFilteredOutByInstanceID(filterUnit, auraInstanceID, auraType .. "|CROWD_CONTROL") then return true end
		if setFilters.BigDefensivePlayer and not C_UnitAuras.IsAuraFilteredOutByInstanceID(filterUnit, auraInstanceID, auraType .. "|BIG_DEFENSIVE") then return true end
		if setFilters.ExternalDefensivePlayer and not C_UnitAuras.IsAuraFilteredOutByInstanceID(filterUnit, auraInstanceID, auraType .. "|EXTERNAL_DEFENSIVE") then return true end
		if setFilters.RaidInCombatPlayer and not C_UnitAuras.IsAuraFilteredOutByInstanceID(filterUnit, auraInstanceID, auraType .. "|RAID_IN_COMBAT") then return true end
		if setFilters.RaidPlayer and not C_UnitAuras.IsAuraFilteredOutByInstanceID(filterUnit, auraInstanceID, auraType .. "|RAID") then return true end
	else
		if setFilters.CrowdControl and not C_UnitAuras.IsAuraFilteredOutByInstanceID(filterUnit, auraInstanceID, auraType .. "|CROWD_CONTROL") then return true end
		if setFilters.BigDefensive and not C_UnitAuras.IsAuraFilteredOutByInstanceID(filterUnit, auraInstanceID, auraType .. "|BIG_DEFENSIVE") then return true end
		if setFilters.ExternalDefensive and not C_UnitAuras.IsAuraFilteredOutByInstanceID(filterUnit, auraInstanceID, auraType .. "|EXTERNAL_DEFENSIVE") then return true end
		if setFilters.RaidInCombat and not C_UnitAuras.IsAuraFilteredOutByInstanceID(filterUnit, auraInstanceID, auraType .. "|RAID_IN_COMBAT") then return true end
		if setFilters.Raid and not C_UnitAuras.IsAuraFilteredOutByInstanceID(filterUnit, auraInstanceID, auraType .. "|RAID") then return true end
	end
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

    local shouldEnableAuras = BuffsDB.Enabled or DebuffsDB.Enabled

    if BuffsDB.Enabled then
        unitFrame.Buffs = unitFrame.BuffContainer
        local buffContainerWidth, buffContainerHeight = ComputeAuraContainerSize(BuffsDB, 4)
        unitFrame.BuffContainer:ClearAllPoints()
        unitFrame.BuffContainer:SetSize(buffContainerWidth, buffContainerHeight)
        unitFrame.BuffContainer:SetPoint(BuffsDB.Layout[1], BuffAnchorParent, BuffsDB.Layout[2], BuffsDB.Layout[3], BuffsDB.Layout[4])
        unitFrame.BuffContainer:SetFrameStrata(AurasDB.FrameStrata)
        unitFrame.BuffContainer.size = BuffsDB.Size
        unitFrame.BuffContainer.spacing = BuffsDB.Layout[5]
        unitFrame.BuffContainer.num = BuffsDB.Num
        unitFrame.BuffContainer.initialAnchor = BuffsDB.Layout[1]
        unitFrame.BuffContainer.onlyShowPlayer = BuffsDB.OnlyShowPlayer
        unitFrame.BuffContainer["growthX"] = BuffsDB.GrowthDirection
        unitFrame.BuffContainer["growthY"] = BuffsDB.WrapDirection
        unitFrame.BuffContainer.filter = "HELPFUL"
        ZF:ConfigureAuraSorting(unitFrame.BuffContainer, BuffsDB.Sorting)
        unitFrame.BuffContainer.createdButtons = unitFrame.Buffs.createdButtons or 0
        unitFrame.BuffContainer.anchoredButtons = unitFrame.Buffs.anchoredButtons or 0
        unitFrame.BuffContainer.PostCreateButton = function(_, button) StyleAuras(_, button, unit, "HELPFUL") end
        unitFrame.BuffContainer.PostUpdateButton = function(_, button) StyleAuras(_, button, unit, "HELPFUL", true) end
        unitFrame.BuffContainer.showType = BuffsDB.ShowType
        unitFrame.BuffContainer.showBuffType = BuffsDB.ShowType
        unitFrame.BuffContainer:Show()
    else
        unitFrame.BuffContainer:Hide()
        unitFrame.Buffs = nil
    end

    if DebuffsDB.Enabled then
        unitFrame.Debuffs = unitFrame.DebuffContainer
        local debuffContainerWidth, debuffContainerHeight = ComputeAuraContainerSize(DebuffsDB, 4)
        unitFrame.DebuffContainer:ClearAllPoints()
        unitFrame.DebuffContainer:SetSize(debuffContainerWidth, debuffContainerHeight)
        unitFrame.DebuffContainer:SetFrameStrata(AurasDB.FrameStrata)
        unitFrame.DebuffContainer:SetPoint(DebuffsDB.Layout[1], DebuffAnchorParent, DebuffsDB.Layout[2], DebuffsDB.Layout[3], DebuffsDB.Layout[4])
        unitFrame.DebuffContainer.size = DebuffsDB.Size
        unitFrame.DebuffContainer.spacing = DebuffsDB.Layout[5]
        unitFrame.DebuffContainer.num = DebuffsDB.Num
        unitFrame.DebuffContainer.initialAnchor = DebuffsDB.Layout[1]
        unitFrame.DebuffContainer.onlyShowPlayer = DebuffsDB.OnlyShowPlayer
        unitFrame.DebuffContainer["growthX"] = DebuffsDB.GrowthDirection
        unitFrame.DebuffContainer["growthY"] = DebuffsDB.WrapDirection
        unitFrame.DebuffContainer.filter = "HARMFUL"
        ZF:ConfigureAuraSorting(unitFrame.DebuffContainer, DebuffsDB.Sorting)
        unitFrame.DebuffContainer.createdButtons = unitFrame.Debuffs.createdButtons or 0
        unitFrame.DebuffContainer.anchoredButtons = unitFrame.Debuffs.anchoredButtons or 0
        unitFrame.DebuffContainer.PostCreateButton = function(_, button) StyleAuras(_, button, unit, "HARMFUL") end
        unitFrame.DebuffContainer.PostUpdateButton = function(_, button) StyleAuras(_, button, unit, "HARMFUL", true) end
        unitFrame.DebuffContainer.showType = DebuffsDB.ShowType
        unitFrame.DebuffContainer.showDebuffType = DebuffsDB.ShowType
        unitFrame.DebuffContainer:Show()
    else
        unitFrame.DebuffContainer:Hide()
        unitFrame.Debuffs = nil
    end

    if unitFrame.CustomAuraContainer and CustomDB then
        if CustomDB.Enabled then
            unitFrame.CustomAuras = unitFrame.CustomAuraContainer
            local customContainerWidth, customContainerHeight = ComputeAuraContainerSize(CustomDB, 3)
            unitFrame.CustomAuraContainer:ClearAllPoints()
            unitFrame.CustomAuraContainer:SetSize(customContainerWidth, customContainerHeight)
            unitFrame.CustomAuraContainer:SetFrameStrata(AurasDB.FrameStrata)
            unitFrame.CustomAuraContainer:SetPoint(CustomDB.Layout[1], CustomAnchorParent, CustomDB.Layout[2], CustomDB.Layout[3], CustomDB.Layout[4])
            unitFrame.CustomAuraContainer.size = CustomDB.Size
            unitFrame.CustomAuraContainer.spacing = CustomDB.Layout[5]
            unitFrame.CustomAuraContainer.num = CustomDB.Num
            unitFrame.CustomAuraContainer.initialAnchor = CustomDB.Layout[1]
            unitFrame.CustomAuraContainer.onlyShowPlayer = CustomDB.OnlyShowPlayer
            unitFrame.CustomAuraContainer.growthX = CustomDB.GrowthDirection
            unitFrame.CustomAuraContainer.growthY = CustomDB.WrapDirection
            unitFrame.CustomAuraContainer.filter = CustomAuraFilter
            ZF:ConfigureAuraSorting(unitFrame.CustomAuraContainer, CustomDB.Sorting)
            unitFrame.CustomAuraContainer.FilterAura = function(_, filterUnit, aura, auraType)
				return FilterAura(ZF:GetUnitDB(unitFrame, unit).Auras.Custom, filterUnit, aura, auraType)
            end
            unitFrame.CustomAuraContainer.createdButtons = unitFrame.CustomAuras.createdButtons or 0
            unitFrame.CustomAuraContainer.anchoredButtons = unitFrame.CustomAuras.anchoredButtons or 0
            unitFrame.CustomAuraContainer.PostCreateButton = function(_, button) StyleAuras(_, button, unit, CustomAuraFilter, nil, "Custom") end
            unitFrame.CustomAuraContainer.PostUpdateButton = function(_, button) StyleAuras(_, button, unit, CustomAuraFilter, true, "Custom") end
            unitFrame.CustomAuraContainer.showType = CustomDB.ShowType
            unitFrame.CustomAuraContainer.showBuffType = CustomAuraFilter == "HELPFUL" and CustomDB.ShowType
            unitFrame.CustomAuraContainer.showDebuffType = CustomAuraFilter == "HARMFUL" and CustomDB.ShowType
            unitFrame.CustomAuraContainer:Show()
            if not unitFrame:IsElementEnabled("CustomAuras") then unitFrame:EnableElement("CustomAuras") end
            if unitFrame.CustomAuraContainer.ForceUpdate then unitFrame.CustomAuraContainer:ForceUpdate() end
        else
            if unitFrame:IsElementEnabled("CustomAuras") then unitFrame:DisableElement("CustomAuras") end
            unitFrame.CustomAuraContainer:Hide()
            unitFrame.CustomAuras = nil
        end
    end

    if shouldEnableAuras then
        if not unitFrame:IsElementEnabled("Auras") then unitFrame:EnableElement("Auras") end
        if unitFrame.BuffContainer and unitFrame.BuffContainer.ForceUpdate then unitFrame.BuffContainer:ForceUpdate() end
        if unitFrame.DebuffContainer and unitFrame.DebuffContainer.ForceUpdate then unitFrame.DebuffContainer:ForceUpdate() end
    else
        if unitFrame:IsElementEnabled("Auras") then
            unitFrame:DisableElement("Auras")
        end
    end

    for _, button in ipairs(unitFrame.BuffContainer) do
        if button and button:IsShown() then
            StyleAuras(nil, button, unit, "HELPFUL", true)
        end
    end
    for _, button in ipairs(unitFrame.DebuffContainer) do
        if button and button:IsShown() then
            StyleAuras(nil, button, unit, "HARMFUL", true)
        end
    end
    if unitFrame.CustomAuraContainer and CustomDB then
        for _, button in ipairs(unitFrame.CustomAuraContainer) do
            if button and button:IsShown() then
                StyleAuras(nil, button, unit, CustomAuraFilter, true, "Custom")
            end
        end
    end
    if (unitFrame.isDesignerPreview and ZF.DESIGNER_PREVIEW_TOGGLES.Auras) or unitFrame.isUnitPreview then ZF:CreateTestAuras(unitFrame, unit) end
end

function ZF:CreateUnitAuras(unitFrame, unit)
	local AurasDB, BuffsDB, DebuffsDB, CustomDB, BuffAnchorParent, DebuffAnchorParent, CustomAuraFilter, CustomAnchorParent = ResolveAuraContext(unitFrame, unit)
	if not AurasDB then return end

	if not unitFrame.BuffContainer then
		unitFrame.BuffContainer = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_BuffsContainer", unitFrame)
		unitFrame.BuffContainer:SetFrameStrata(AurasDB.FrameStrata)
		local buffContainerWidth, buffContainerHeight = ComputeAuraContainerSize(BuffsDB, 4)
		unitFrame.BuffContainer:SetSize(buffContainerWidth, buffContainerHeight)
		unitFrame.BuffContainer:SetPoint(BuffsDB.Layout[1], BuffAnchorParent, BuffsDB.Layout[2], BuffsDB.Layout[3], BuffsDB.Layout[4])
		unitFrame.BuffContainer.size = BuffsDB.Size
		unitFrame.BuffContainer.spacing = BuffsDB.Layout[5]
		unitFrame.BuffContainer.num = BuffsDB.Num
		unitFrame.BuffContainer.initialAnchor = BuffsDB.Layout[1]
		unitFrame.BuffContainer.onlyShowPlayer = BuffsDB.OnlyShowPlayer
		unitFrame.BuffContainer["growthX"] = BuffsDB.GrowthDirection
		unitFrame.BuffContainer["growthY"] = BuffsDB.WrapDirection
		unitFrame.BuffContainer.filter = "HELPFUL"
		ZF:ConfigureAuraSorting(unitFrame.BuffContainer, BuffsDB.Sorting)
		unitFrame.BuffContainer.FilterAura = function(_, filterUnit, aura)
			return FilterAura(ZF:GetUnitDB(unitFrame, unit).Auras.Buffs, filterUnit, aura, "HELPFUL")
		end
		unitFrame.BuffContainer.PostCreateButton = function(_, button) StyleAuras(_, button, unit, "HELPFUL") end
		unitFrame.BuffContainer.PostUpdateButton = function(_, button) StyleAuras(_, button, unit, "HELPFUL", true) end
		unitFrame.BuffContainer.anchoredButtons = 0
		unitFrame.BuffContainer.createdButtons = 0
		unitFrame.BuffContainer.tooltipAnchor = "ANCHOR_CURSOR"
		unitFrame.BuffContainer.showType = BuffsDB.ShowType
		unitFrame.BuffContainer.showBuffType = BuffsDB.ShowType
		BuildDispelColorCurve(unitFrame.BuffContainer)

		if BuffsDB.Enabled then
			unitFrame.Buffs = unitFrame.BuffContainer
		else
			unitFrame.Buffs = nil
		end
	end

	if not unitFrame.DebuffContainer then
		unitFrame.DebuffContainer = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_DebuffsContainer", unitFrame)
		unitFrame.DebuffContainer:SetFrameStrata(AurasDB.FrameStrata)
		local debuffContainerWidth, debuffContainerHeight = ComputeAuraContainerSize(DebuffsDB, 4)
		unitFrame.DebuffContainer:SetSize(debuffContainerWidth, debuffContainerHeight)
		unitFrame.DebuffContainer:SetPoint(DebuffsDB.Layout[1], DebuffAnchorParent, DebuffsDB.Layout[2], DebuffsDB.Layout[3], DebuffsDB.Layout[4])
		unitFrame.DebuffContainer.size = DebuffsDB.Size
		unitFrame.DebuffContainer.spacing = DebuffsDB.Layout[5]
		unitFrame.DebuffContainer.num = DebuffsDB.Num
		unitFrame.DebuffContainer.initialAnchor = DebuffsDB.Layout[1]
		unitFrame.DebuffContainer.onlyShowPlayer = DebuffsDB.OnlyShowPlayer
		unitFrame.DebuffContainer["growthX"] = DebuffsDB.GrowthDirection
		unitFrame.DebuffContainer["growthY"] = DebuffsDB.WrapDirection
		unitFrame.DebuffContainer.filter = "HARMFUL"
		ZF:ConfigureAuraSorting(unitFrame.DebuffContainer, DebuffsDB.Sorting)
		unitFrame.DebuffContainer.FilterAura = function(_, filterUnit, aura)
			return FilterAura(ZF:GetUnitDB(unitFrame, unit).Auras.Debuffs, filterUnit, aura, "HARMFUL")
		end

		unitFrame.DebuffContainer.anchoredButtons = 0
		unitFrame.DebuffContainer.createdButtons = 0
		unitFrame.DebuffContainer.PostCreateButton = function(_, button) StyleAuras(_, button, unit, "HARMFUL") end
		unitFrame.DebuffContainer.PostUpdateButton = function(_, button) StyleAuras(_, button, unit, "HARMFUL", true) end
		unitFrame.DebuffContainer.tooltipAnchor = "ANCHOR_CURSOR"
		unitFrame.DebuffContainer.showType = DebuffsDB.ShowType
		unitFrame.DebuffContainer.showDebuffType = DebuffsDB.ShowType
		BuildDispelColorCurve(unitFrame.DebuffContainer)

		if DebuffsDB.Enabled then
			unitFrame.Debuffs = unitFrame.DebuffContainer
		else
			unitFrame.Debuffs = nil
		end
	end

	if CustomDB and not unitFrame.CustomAuraContainer then
		unitFrame.CustomAuraContainer = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_CustomAurasContainer", unitFrame)
		unitFrame.CustomAuraContainer:SetFrameStrata(AurasDB.FrameStrata)
		local customContainerWidth, customContainerHeight = ComputeAuraContainerSize(CustomDB, 3)
		unitFrame.CustomAuraContainer:SetSize(customContainerWidth, customContainerHeight)
		unitFrame.CustomAuraContainer:SetPoint(CustomDB.Layout[1], CustomAnchorParent, CustomDB.Layout[2], CustomDB.Layout[3], CustomDB.Layout[4])
		unitFrame.CustomAuraContainer.size = CustomDB.Size
		unitFrame.CustomAuraContainer.spacing = CustomDB.Layout[5]
		unitFrame.CustomAuraContainer.num = CustomDB.Num
		unitFrame.CustomAuraContainer.initialAnchor = CustomDB.Layout[1]
		unitFrame.CustomAuraContainer.onlyShowPlayer = CustomDB.OnlyShowPlayer
		unitFrame.CustomAuraContainer.growthX = CustomDB.GrowthDirection
		unitFrame.CustomAuraContainer.growthY = CustomDB.WrapDirection
		unitFrame.CustomAuraContainer.filter = CustomAuraFilter
		ZF:ConfigureAuraSorting(unitFrame.CustomAuraContainer, CustomDB.Sorting)
		unitFrame.CustomAuraContainer.FilterAura = function(_, filterUnit, aura, auraType)
			return FilterAura(ZF:GetUnitDB(unitFrame, unit).Auras.Custom, filterUnit, aura, auraType)
		end
		unitFrame.CustomAuraContainer.anchoredButtons = 0
		unitFrame.CustomAuraContainer.createdButtons = 0
		unitFrame.CustomAuraContainer.PostCreateButton = function(_, button) StyleAuras(_, button, unit, CustomAuraFilter, nil, "Custom") end
		unitFrame.CustomAuraContainer.PostUpdateButton = function(_, button) StyleAuras(_, button, unit, CustomAuraFilter, true, "Custom") end
		unitFrame.CustomAuraContainer.tooltipAnchor = "ANCHOR_CURSOR"
		unitFrame.CustomAuraContainer.showType = CustomDB.ShowType
		unitFrame.CustomAuraContainer.showBuffType = CustomAuraFilter == "HELPFUL" and CustomDB.ShowType
		unitFrame.CustomAuraContainer.showDebuffType = CustomAuraFilter == "HARMFUL" and CustomDB.ShowType
		BuildDispelColorCurve(unitFrame.CustomAuraContainer)

		if CustomDB.Enabled then
			unitFrame.CustomAuras = unitFrame.CustomAuraContainer
		else
			unitFrame.CustomAuraContainer:Hide()
		end
	end

    if AurasDB.PrivateAuras then
        local PrivateAurasDB = AurasDB.PrivateAuras
        ConfigurePrivateAuraContainer(unitFrame, unit, PrivateAurasDB)

        if PrivateAurasDB.Enabled then
            unitFrame.PrivateAuras = unitFrame.PrivateAuraContainer
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
        if unitFrame:IsElementEnabled("CustomAuras") then unitFrame:DisableElement("CustomAuras") end

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
        if BuffsDB.Enabled or DebuffsDB.Enabled then
            if not unitFrame:IsElementEnabled("Auras") then unitFrame:EnableElement("Auras") end
            if unitFrame.BuffContainer and unitFrame.BuffContainer.ForceUpdate then unitFrame.BuffContainer:ForceUpdate() end
            if unitFrame.DebuffContainer and unitFrame.DebuffContainer.ForceUpdate then unitFrame.DebuffContainer:ForceUpdate() end
        end
        if CustomDB and CustomDB.Enabled then
            unitFrame.CustomAuras = unitFrame.CustomAuraContainer
            if not unitFrame:IsElementEnabled("CustomAuras") then unitFrame:EnableElement("CustomAuras") end
            if unitFrame.CustomAuraContainer and unitFrame.CustomAuraContainer.ForceUpdate then unitFrame.CustomAuraContainer:ForceUpdate() end
        end
		if unitFrame.PrivateAuraContainer then
			for j = 1, (unitFrame.PrivateAuraContainer.maxFake or 0) do
				local button = unitFrame.PrivateAuraContainer["fake" .. j]
				if button then button:Hide() end
			end
		end
    end
end
