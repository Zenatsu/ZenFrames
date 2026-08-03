local _, ZF = ...

function ZF:CreateUnitResurrectIndicator(unitFrame, unit)
	local ResurrectDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Resurrect
	if not ResurrectDB then return end

	local ResurrectIndicator = ZF:CreateIndicatorTexture(unitFrame, unit, "_ResurrectIndicator", ResurrectDB.Size, ResurrectDB.Layout)
	ResurrectIndicator:SetAtlas("RaidFrame-Icon-Rez")

	if ResurrectDB.Enabled then
		unitFrame.ResurrectIndicator = ResurrectIndicator
	else
		ZF:DisableIndicatorElement(unitFrame, "ResurrectIndicator", ResurrectIndicator)
	end

	return ResurrectIndicator
end

function ZF:UpdateUnitResurrectIndicator(unitFrame, unit)
	local ResurrectDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Resurrect
	if not ResurrectDB then return end

	if ResurrectDB.Enabled then
		unitFrame.ResurrectIndicator = unitFrame.ResurrectIndicator or ZF:CreateUnitResurrectIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("ResurrectIndicator") then unitFrame:EnableElement("ResurrectIndicator") end

		ZF:PositionIndicatorTexture(unitFrame.ResurrectIndicator, unitFrame.HighLevelContainer, ResurrectDB.Size, ResurrectDB.Layout)
		unitFrame.ResurrectIndicator:ForceUpdate()
	elseif unitFrame.ResurrectIndicator then
		ZF:DisableIndicatorElement(unitFrame, "ResurrectIndicator", unitFrame.ResurrectIndicator)
		unitFrame.ResurrectIndicator = nil
	end
end
