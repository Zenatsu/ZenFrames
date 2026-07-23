local _, RUF = ...
local oUF = RUF.oUF

local dispelTypeMap = {
    Magic = oUF.Enum.DispelType.Magic,
    Curse = oUF.Enum.DispelType.Curse,
    Disease = oUF.Enum.DispelType.Disease,
    Poison = oUF.Enum.DispelType.Poison,
    Bleed = oUF.Enum.DispelType.Bleed,
}

local DispelHighlightFrames = {}
local DispelTypes

local DispelEventFrame = CreateFrame("Frame")
DispelEventFrame:RegisterEvent("SPELLS_CHANGED")
DispelEventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
DispelEventFrame:SetScript("OnEvent", function()
	DispelTypes = RUF.LD and RUF.LD:GetMyDispelTypes()
	for unitFrame in pairs(DispelHighlightFrames) do RUF:UpdateUnitDispelState(unitFrame, unitFrame.DispelHighlightUnit) end
end)

function RUF:UpdateDispelColorCurve(unitFrame)
    if not unitFrame.dispelColorCurve then return end
    unitFrame.dispelColorCurve:ClearPoints()
    for dispelType, index in pairs(dispelTypeMap) do
        local color = oUF.colors.dispel[index]
        if color then
            unitFrame.dispelColorCurve:AddPoint(index, color)
        end
    end
    unitFrame.dispelColorCurveGeneration = RUF.dispelColorGeneration
end

function RUF:CreateUnitDispelHighlight(unitFrame, unit)
	local DispelHighlightDB = RUF:GetUnitDB(unitFrame, unit).HealthBar.DispelHighlight
	if not unitFrame.DispelHighlight then
		local DispelHighlight = unitFrame.Health:CreateTexture(RUF:FetchFrameName(unit) .. "_DispelHighlight", "OVERLAY")
		DispelHighlight:ClearAllPoints()
		if DispelHighlightDB.Style == "GRADIENT" then
			DispelHighlight:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 1, -1)
			DispelHighlight:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -1, 1)
			DispelHighlight:SetTexture("Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Gradient.png")
			DispelHighlight:SetAlpha(1)
		else
			local barTexture = unitFrame.Health and unitFrame.Health:GetStatusBarTexture()
			if barTexture then
				DispelHighlight:SetAllPoints(barTexture)
			else
				DispelHighlight:SetAllPoints(unitFrame.Health)
			end
			DispelHighlight:SetTexture("Interface\\Buttons\\WHITE8X8")
			DispelHighlight:SetAlpha(0.75)
		end
		DispelHighlight:SetBlendMode("BLEND")
		DispelHighlight:Hide()

		unitFrame.DispelHighlight = DispelHighlight

		if not unitFrame.dispelColorCurve then
			unitFrame.dispelColorCurve = C_CurveUtil.CreateColorCurve()
			unitFrame.dispelColorCurve:SetType(Enum.LuaCurveType.Step)
			RUF:UpdateDispelColorCurve(unitFrame)
		end
	end

	RUF:UpdateUnitDispelHighlight(unitFrame, unit)
end

function RUF:UpdateUnitDispelHighlight(unitFrame, unit)
	if not unitFrame.DispelHighlight then return end
	local DispelHighlightDB = RUF:GetUnitDB(unitFrame, unit).HealthBar.DispelHighlight
	if unitFrame.DispelHighlight then
		if DispelHighlightDB.Enabled then
			RUF:RegisterDispelHighlightEvents(unitFrame, unit)
			unitFrame.DispelHighlight:ClearAllPoints()
			if DispelHighlightDB.Style == "GRADIENT" then
				unitFrame.DispelHighlight:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 1, -1)
				unitFrame.DispelHighlight:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -1, 1)
				unitFrame.DispelHighlight:SetTexture("Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Gradient.png")
				unitFrame.DispelHighlight:SetAlpha(1)
			else
				local barTexture = unitFrame.Health and unitFrame.Health:GetStatusBarTexture()
				if barTexture then
					unitFrame.DispelHighlight:SetAllPoints(barTexture)
				else
					unitFrame.DispelHighlight:SetAllPoints(unitFrame.Health)
				end
				unitFrame.DispelHighlight:SetTexture("Interface\\Buttons\\WHITE8X8")
				unitFrame.DispelHighlight:SetAlpha(0.75)
			end
			RUF:UpdateUnitDispelState(unitFrame, unit)
		else
			RUF:UnregisterDispelHighlightEvents(unitFrame)
			unitFrame.DispelHighlight:Hide()
		end
	end
end

function RUF:UpdateUnitDispelState(unitFrame, unit)
	if not unitFrame.DispelHighlight then return end
	if not RUF:GetUnitDB(unitFrame, unit).HealthBar.DispelHighlight.Enabled then
		unitFrame.DispelHighlight:Hide()
		return
	end
	local unitToken = unit == "partyplayer" and "player" or unit

	local LibDispel = RUF.LD
	if not LibDispel then
		unitFrame.DispelHighlight:Hide()
		return
	end

	if unitFrame.dispelColorCurve and unitFrame.dispelColorCurveGeneration ~= RUF.dispelColorGeneration then
		RUF:UpdateDispelColorCurve(unitFrame)
	end

	if not UnitIsUnit(unitToken, "player") and not UnitIsFriend("player", unitToken) then
		unitFrame.DispelHighlight:Hide()
		return
	end

	DispelTypes = DispelTypes or LibDispel:GetMyDispelTypes()
	if not (DispelTypes.Magic or DispelTypes.Curse or DispelTypes.Disease or DispelTypes.Poison or DispelTypes.Bleed) then
		unitFrame.DispelHighlight:Hide()
		return
	end

	local bestAura = C_UnitAuras.GetAuraDataByIndex(unitToken, 1, "HARMFUL|RAID")
	local bestAuraInstanceID = bestAura and bestAura.auraInstanceID or nil

	if bestAuraInstanceID then
		local color = C_UnitAuras.GetAuraDispelTypeColor(unitToken, bestAuraInstanceID, unitFrame.dispelColorCurve)

		if color then
			unitFrame.DispelHighlight:SetVertexColor(color:GetRGBA())
			unitFrame.DispelHighlight:Show()
		else
			unitFrame.DispelHighlight:Hide()
		end
	else
		unitFrame.DispelHighlight:Hide()
	end
end

function RUF:RegisterDispelHighlightEvents(unitFrame, unit)
    if not unitFrame.DispelHighlight then return end
    if unit == "raid" then return end
    if not RUF:GetUnitDB(unitFrame, unit).HealthBar.DispelHighlight.Enabled then return end
    local unitToken = unit == "partyplayer" and "player" or unit

    unitFrame.DispelHighlightUnit = unit
    if not unitFrame.DispelHighlightHandler then
        unitFrame.DispelHighlightHandler = CreateFrame("Frame")
        unitFrame.DispelHighlightHandler:SetScript("OnEvent", function() RUF:UpdateUnitDispelState(unitFrame, unitFrame.DispelHighlightUnit) end)
    end

    unitFrame.DispelHighlightHandler:RegisterUnitEvent("UNIT_AURA", unitToken)
	DispelHighlightFrames[unitFrame] = true
end

function RUF:UnregisterDispelHighlightEvents(unitFrame)
    if not unitFrame.DispelHighlightHandler then return end

    unitFrame.DispelHighlightHandler:UnregisterAllEvents()
	DispelHighlightFrames[unitFrame] = nil
    unitFrame.DispelHighlightUnit = nil
end
