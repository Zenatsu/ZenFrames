local _, RUF = ...

function RUF:CreateThreatIndicatorOverlay(unitFrame, unit)
	local ThreatIndicator = CreateFrame("Frame", RUF:FetchFrameName(unit) .. "_ThreatIndicator", unitFrame.Container, "BackdropTemplate")
	ThreatIndicator:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 4)
	ThreatIndicator:SetBackdrop({ edgeFile = "Interface\\AddOns\\UnhaltedUnitFrames\\Media\\Textures\\Glow.tga", edgeSize = 3, insets = {left = -3, right = -3, top = -3, bottom = -3} })
	ThreatIndicator:SetBackdropColor(0, 0, 0, 0)
	ThreatIndicator:SetBackdropBorderColor(1, 1, 1, 1)
	ThreatIndicator:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", -3, 3)
	ThreatIndicator:SetPoint("BOTTOMRIGHT", unitFrame.Container, "BOTTOMRIGHT", 3, -3)
	ThreatIndicator:SetAlpha(0)
	ThreatIndicator:Hide()
	ThreatIndicator.PostUpdate = function(element, _, status, color)
		if status and status > 0 and color then
			element:SetBackdropBorderColor(color:GetRGB())
			element:SetAlpha(1)
		else
			element:SetAlpha(0)
		end
	end

	return ThreatIndicator
end

function RUF:CreateUnitThreatIndicator(unitFrame, unit)
	local ThreatDB = RUF:GetUnitDB(unitFrame, unit).Indicators.Threat
	if not ThreatDB then return end

	local ThreatIndicator = RUF:CreateThreatIndicatorOverlay(unitFrame, unit)
	if ThreatDB.Enabled then
		unitFrame.ThreatIndicator = ThreatIndicator
	else
		if ThreatIndicator then ThreatIndicator:Hide() end
	end

	return ThreatIndicator
end

function RUF:UpdateUnitThreatIndicator(unitFrame, unit)
	local ThreatDB = RUF:GetUnitDB(unitFrame, unit).Indicators.Threat
	if not ThreatDB then return end

	if ThreatDB.Enabled then
		unitFrame.ThreatIndicator = unitFrame.ThreatIndicator or RUF:CreateUnitThreatIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("ThreatIndicator") then unitFrame:EnableElement("ThreatIndicator") end
		if unitFrame.ThreatIndicator then unitFrame.ThreatIndicator:ForceUpdate() end
	elseif unitFrame.ThreatIndicator then
		if unitFrame:IsElementEnabled("ThreatIndicator") then unitFrame:DisableElement("ThreatIndicator") end
		unitFrame.ThreatIndicator:SetAlpha(0)
		unitFrame.ThreatIndicator:Hide()
		unitFrame.ThreatIndicator = nil
	end
end
