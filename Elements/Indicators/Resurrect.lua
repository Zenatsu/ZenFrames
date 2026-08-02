local _, RUF = ...

function RUF:CreateUnitResurrectIndicator(unitFrame, unit)
	local ResurrectDB = RUF:GetUnitDB(unitFrame, unit).Indicators.ResurrectIndicator
	if not ResurrectDB then return end

	local ResurrectIndicator = RUF:CreateIndicatorTexture(unitFrame, unit, "_ResurrectIndicator", ResurrectDB.Size, ResurrectDB.Layout)
	ResurrectIndicator:SetAtlas("RaidFrame-Icon-Rez")

	if ResurrectDB.Enabled then
		unitFrame.ResurrectIndicator = ResurrectIndicator
	else
		RUF:DisableIndicatorElement(unitFrame, "ResurrectIndicator", ResurrectIndicator)
	end

	return ResurrectIndicator
end

function RUF:UpdateUnitResurrectIndicator(unitFrame, unit)
	local ResurrectDB = RUF:GetUnitDB(unitFrame, unit).Indicators.ResurrectIndicator
	if not ResurrectDB then return end

	if ResurrectDB.Enabled then
		unitFrame.ResurrectIndicator = unitFrame.ResurrectIndicator or RUF:CreateUnitResurrectIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("ResurrectIndicator") then unitFrame:EnableElement("ResurrectIndicator") end

		RUF:PositionIndicatorTexture(unitFrame.ResurrectIndicator, unitFrame.HighLevelContainer, ResurrectDB.Size, ResurrectDB.Layout)
		unitFrame.ResurrectIndicator:ForceUpdate()
	elseif unitFrame.ResurrectIndicator then
		RUF:DisableIndicatorElement(unitFrame, "ResurrectIndicator", unitFrame.ResurrectIndicator)
		unitFrame.ResurrectIndicator = nil
	end
end
