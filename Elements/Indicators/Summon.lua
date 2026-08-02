local _, RUF = ...

function RUF:CreateUnitSummonIndicator(unitFrame, unit)
	local SummonDB = RUF:GetUnitDB(unitFrame, unit).Indicators.Summon
	if not SummonDB then return end

	local SummonIndicator = RUF:CreateIndicatorTexture(unitFrame, unit, "_SummonIndicator", SummonDB.Size, SummonDB.Layout)

	if SummonDB.Enabled then
		unitFrame.SummonIndicator = SummonIndicator
	else
		RUF:DisableIndicatorElement(unitFrame, "SummonIndicator", SummonIndicator)
	end

	return SummonIndicator
end

function RUF:UpdateUnitSummonIndicator(unitFrame, unit)
	local SummonDB = RUF:GetUnitDB(unitFrame, unit).Indicators.Summon
	if not SummonDB then return end

	if SummonDB.Enabled then
		unitFrame.SummonIndicator = unitFrame.SummonIndicator or RUF:CreateUnitSummonIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("SummonIndicator") then unitFrame:EnableElement("SummonIndicator") end

		RUF:PositionIndicatorTexture(unitFrame.SummonIndicator, unitFrame.HighLevelContainer, SummonDB.Size, SummonDB.Layout)
		unitFrame.SummonIndicator:ForceUpdate()
	elseif unitFrame.SummonIndicator then
		RUF:DisableIndicatorElement(unitFrame, "SummonIndicator", unitFrame.SummonIndicator)
		unitFrame.SummonIndicator = nil
	end
end
