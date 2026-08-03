local _, ZF = ...
local oUF = ZF.oUF

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
	DispelTypes = ZF.LD and ZF.LD:GetMyDispelTypes()
	for unitFrame in pairs(DispelHighlightFrames) do ZF:UpdateUnitDispelState(unitFrame, unitFrame.DispelHighlightUnit) end
end)

local function ApplyDispelHighlightStyle(texture, unitFrame, DispelHighlightDB)
	texture:ClearAllPoints()
	if DispelHighlightDB.Style == "GRADIENT" then
		texture:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 1, -1)
		texture:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -1, 1)
		texture:SetTexture("Interface\\AddOns\\ZenFrames\\Media\\Textures\\Gradient.png")
		texture:SetAlpha(1)
	else
		local barTexture = unitFrame.Health and unitFrame.Health:GetStatusBarTexture()
		if barTexture then
			texture:SetAllPoints(barTexture)
		else
			texture:SetAllPoints(unitFrame.Health)
		end
		texture:SetTexture("Interface\\Buttons\\WHITE8X8")
		texture:SetAlpha(0.75)
	end
end

function ZF:UpdateDispelColorCurve(unitFrame)
    if not unitFrame.dispelColorCurve then return end
    unitFrame.dispelColorCurve:ClearPoints()
    for dispelType, index in pairs(dispelTypeMap) do
        local color = oUF.colors.dispel[index]
        if color then
            unitFrame.dispelColorCurve:AddPoint(index, color)
        end
    end
    unitFrame.dispelColorCurveGeneration = ZF.dispelColorGeneration
end

function ZF:CreateUnitDispelHighlight(unitFrame, unit)
	local DispelHighlightDB = ZF:GetUnitDB(unitFrame, unit).HealthBar.DispelHighlight
	if not unitFrame.DispelHighlight then
		local DispelHighlight = unitFrame.Health:CreateTexture(ZF:FetchFrameName(unit) .. "_DispelHighlight", "OVERLAY")
		ApplyDispelHighlightStyle(DispelHighlight, unitFrame, DispelHighlightDB)
		DispelHighlight:SetBlendMode("BLEND")
		DispelHighlight:Hide()

		unitFrame.DispelHighlight = DispelHighlight

		if not unitFrame.dispelColorCurve then
			unitFrame.dispelColorCurve = C_CurveUtil.CreateColorCurve()
			unitFrame.dispelColorCurve:SetType(Enum.LuaCurveType.Step)
			ZF:UpdateDispelColorCurve(unitFrame)
		end
	end

	ZF:UpdateUnitDispelHighlight(unitFrame, unit)
end

function ZF:UpdateUnitDispelHighlight(unitFrame, unit)
	if not unitFrame.DispelHighlight then return end
	local DispelHighlightDB = ZF:GetUnitDB(unitFrame, unit).HealthBar.DispelHighlight
	if unitFrame.DispelHighlight then
		if DispelHighlightDB.Enabled then
			ZF:RegisterDispelHighlightEvents(unitFrame, unit)
			ApplyDispelHighlightStyle(unitFrame.DispelHighlight, unitFrame, DispelHighlightDB)
			ZF:UpdateUnitDispelState(unitFrame, unit)
		else
			ZF:UnregisterDispelHighlightEvents(unitFrame)
			unitFrame.DispelHighlight:Hide()
		end
	end
end

function ZF:UpdateUnitDispelState(unitFrame, unit)
	if not unitFrame.DispelHighlight then return end
	if not ZF:GetUnitDB(unitFrame, unit).HealthBar.DispelHighlight.Enabled then
		unitFrame.DispelHighlight:Hide()
		return
	end
	local unitToken = unit == "partyplayer" and "player" or unit

	local LibDispel = ZF.LD
	if not LibDispel then
		unitFrame.DispelHighlight:Hide()
		return
	end

	if unitFrame.dispelColorCurve and unitFrame.dispelColorCurveGeneration ~= ZF.dispelColorGeneration then
		ZF:UpdateDispelColorCurve(unitFrame)
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

function ZF:RegisterDispelHighlightEvents(unitFrame, unit)
    if not unitFrame.DispelHighlight then return end
    if unit == "raid" then return end
    if not ZF:GetUnitDB(unitFrame, unit).HealthBar.DispelHighlight.Enabled then return end
    local unitToken = unit == "partyplayer" and "player" or unit

    unitFrame.DispelHighlightUnit = unit
    if not unitFrame.DispelHighlightHandler then
        unitFrame.DispelHighlightHandler = CreateFrame("Frame")
        unitFrame.DispelHighlightHandler:SetScript("OnEvent", function() ZF:UpdateUnitDispelState(unitFrame, unitFrame.DispelHighlightUnit) end)
    end

    unitFrame.DispelHighlightHandler:RegisterUnitEvent("UNIT_AURA", unitToken)
	DispelHighlightFrames[unitFrame] = true
end

function ZF:UnregisterDispelHighlightEvents(unitFrame)
    if not unitFrame.DispelHighlightHandler then return end

    unitFrame.DispelHighlightHandler:UnregisterAllEvents()
	DispelHighlightFrames[unitFrame] = nil
    unitFrame.DispelHighlightUnit = nil
end
