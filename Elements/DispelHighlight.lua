local _, ZF = ...
local oUF = ZF.oUF

local DispelHighlightFrames = {}
local DispelTypes
local DispelColorMap = {}
local DispelColorMapGeneration = 0

local function RefreshDispelColorMap()
	wipe(DispelColorMap)
	if DispelTypes then
		for dispelType, color in pairs(oUF.colors.dispel) do
			if DispelTypes[dispelType] then DispelColorMap[dispelType] = color end
		end
	end
	DispelColorMapGeneration = ZF.dispelColorGeneration or 0
end

local DispelEventFrame = CreateFrame("Frame")
DispelEventFrame:RegisterEvent("SPELLS_CHANGED")
DispelEventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
DispelEventFrame:SetScript("OnEvent", function()
	DispelTypes = ZF.LD and ZF.LD:GetMyDispelTypes()
	RefreshDispelColorMap()
	for unitFrame in pairs(DispelHighlightFrames) do ZF:UpdateUnitDispelState(unitFrame, unitFrame.DispelHighlightUnit) end
end)

local function ApplyDispelHighlightStyle(texture, unitFrame, DispelHighlightDB)
	texture:ClearAllPoints()
	if DispelHighlightDB.Style == "GRADIENT" then
		texture:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 1, -1)
		texture:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", -1, 1)
		texture:SetTexture(ZF.Media.Gradient)
		texture:SetAlpha(1)
	else
		local barTexture = unitFrame.Health and unitFrame.Health:GetStatusBarTexture()
		if barTexture then
			texture:SetAllPoints(barTexture)
		else
			texture:SetAllPoints(unitFrame.Health)
		end
		texture:SetTexture(ZF.Media.Solid)
		texture:SetAlpha(0.75)
	end
end

function ZF:CreateUnitDispelHighlight(unitFrame, unit)
	if not unitFrame.DispelHighlight then
		local auras = unitFrame:CreateAuras()
		auras:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 3)
		auras:AddGroup("HARMFUL|RAID", {
			maxFrameCount = 1,
			CreateButton = function(_, _, button)
				button:SetSize(1, 1)
				local highlight = button:CreateTexture(ZF:FetchFrameName(unit) .. "_DispelHighlight", "OVERLAY")
				highlight:SetBlendMode("BLEND")
				highlight:Hide()
				unitFrame.DispelHighlight = highlight
				ApplyDispelHighlightStyle(highlight, unitFrame, ZF:GetUnitDB(unitFrame, unit).HealthBar.DispelHighlight)
				button:AddDispelTypeTexture(highlight, {
					style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
					showWhenHarmful = true,
					customDispelColorMap = DispelColorMap,
				})
			end,
		})
		unitFrame.DispelAuras = auras
	end

	ZF:UpdateUnitDispelHighlight(unitFrame, unit)
end

function ZF:UpdateUnitDispelHighlight(unitFrame, unit)
	if not unitFrame.DispelHighlight then return end
	local DispelHighlightDB = ZF:GetUnitDB(unitFrame, unit).HealthBar.DispelHighlight
	unitFrame.DispelHighlightDB = DispelHighlightDB
	if DispelHighlightDB.Enabled then
		ZF:RegisterDispelHighlightEvents(unitFrame, unit)
		ApplyDispelHighlightStyle(unitFrame.DispelHighlight, unitFrame, DispelHighlightDB)
		ZF:UpdateUnitDispelState(unitFrame, unit)
	else
		ZF:UnregisterDispelHighlightEvents(unitFrame)
		unitFrame.DispelAuras:Hide()
	end
end

function ZF:UpdateUnitDispelState(unitFrame, unit)
	if not unitFrame.DispelHighlight then return end
	local DispelHighlightDB = unitFrame.DispelHighlightDB
	if not DispelHighlightDB.Enabled then
		unitFrame.DispelAuras:Hide()
		return
	end
	local unitToken = unit == "partyplayer" and "player" or unit

	if not ZF.LD then
		unitFrame.DispelAuras:Hide()
		return
	end

	if not UnitIsUnit(unitToken, "player") and not UnitIsFriend("player", unitToken) then
		unitFrame.DispelAuras:Hide()
		return
	end

	DispelTypes = DispelTypes or ZF.LD:GetMyDispelTypes()
	if DispelColorMapGeneration ~= (ZF.dispelColorGeneration or 0) then RefreshDispelColorMap() end
	if not (DispelTypes.Magic or DispelTypes.Curse or DispelTypes.Disease or DispelTypes.Poison or DispelTypes.Bleed) then
		unitFrame.DispelAuras:Hide()
		return
	end

	if not unitFrame:IsElementEnabled("Auras") then unitFrame:EnableElement("Auras") end
	if unitFrame.DispelAuras then
		unitFrame.DispelAuras:Show()
		unitFrame.DispelAuras:ForceUpdate()
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
