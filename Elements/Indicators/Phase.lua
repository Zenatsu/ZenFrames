local _, RUF = ...

function RUF:CreateUnitPhaseIndicator(unitFrame, unit)
	local PhaseDB = RUF:GetUnitDB(unitFrame, unit).Indicators.Phase
	if not PhaseDB then return end

	local PhaseIndicator = CreateFrame("Frame", RUF:FetchFrameName(unit) .. "_PhaseIndicator", unitFrame.HighLevelContainer)
	PhaseIndicator:SetSize(PhaseDB.Size, PhaseDB.Size)
	PhaseIndicator:SetPoint(PhaseDB.Layout[1], unitFrame.HighLevelContainer, PhaseDB.Layout[2], PhaseDB.Layout[3], PhaseDB.Layout[4])
	PhaseIndicator:SetFrameLevel(unitFrame.HighLevelContainer:GetFrameLevel() + 5)
	PhaseIndicator:EnableMouse(true)

	local Icon = PhaseIndicator:CreateTexture(nil, "OVERLAY")
	Icon:SetAllPoints()
	PhaseIndicator.Icon = Icon

	if PhaseDB.Enabled then
		unitFrame.PhaseIndicator = PhaseIndicator
	else
		RUF:DisableIndicatorElement(unitFrame, "PhaseIndicator", PhaseIndicator)
	end

	return PhaseIndicator
end

function RUF:UpdateUnitPhaseIndicator(unitFrame, unit)
	local PhaseDB = RUF:GetUnitDB(unitFrame, unit).Indicators.Phase
	if not PhaseDB then return end

	if PhaseDB.Enabled then
		unitFrame.PhaseIndicator = unitFrame.PhaseIndicator or RUF:CreateUnitPhaseIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("PhaseIndicator") then unitFrame:EnableElement("PhaseIndicator") end

		RUF:PositionIndicatorTexture(unitFrame.PhaseIndicator, unitFrame.HighLevelContainer, PhaseDB.Size, PhaseDB.Layout)
		unitFrame.PhaseIndicator:ForceUpdate()
	elseif unitFrame.PhaseIndicator then
		RUF:DisableIndicatorElement(unitFrame, "PhaseIndicator", unitFrame.PhaseIndicator)
		unitFrame.PhaseIndicator = nil
	end
end
