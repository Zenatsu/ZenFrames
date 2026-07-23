local _, RUF = ...

function RUF:CreateUnitResurrectIndicator(unitFrame, unit)
	local ResurrectDB = RUF:GetUnitDB(unitFrame, unit).Indicators.ResurrectIndicator
	if not ResurrectDB then return end

	local ResurrectIndicator = unitFrame.HighLevelContainer:CreateTexture(RUF:FetchFrameName(unit) .. "_ResurrectIndicator", "OVERLAY")
	ResurrectIndicator:SetSize(ResurrectDB.Size, ResurrectDB.Size)
	ResurrectIndicator:SetPoint(ResurrectDB.Layout[1], unitFrame.HighLevelContainer, ResurrectDB.Layout[2], ResurrectDB.Layout[3], ResurrectDB.Layout[4])
	ResurrectIndicator:SetAtlas("RaidFrame-Icon-Rez")

	if ResurrectDB.Enabled then
		unitFrame.ResurrectIndicator = ResurrectIndicator
	else
		ResurrectIndicator:Hide()
	end

	return ResurrectIndicator
end

function RUF:UpdateUnitResurrectIndicator(unitFrame, unit)
	local ResurrectDB = RUF:GetUnitDB(unitFrame, unit).Indicators.ResurrectIndicator
	if not ResurrectDB then return end

	if ResurrectDB.Enabled then
		unitFrame.ResurrectIndicator = unitFrame.ResurrectIndicator or RUF:CreateUnitResurrectIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("ResurrectIndicator") then unitFrame:EnableElement("ResurrectIndicator") end

		unitFrame.ResurrectIndicator:ClearAllPoints()
		unitFrame.ResurrectIndicator:SetSize(ResurrectDB.Size, ResurrectDB.Size)
		unitFrame.ResurrectIndicator:SetPoint(ResurrectDB.Layout[1], unitFrame.HighLevelContainer, ResurrectDB.Layout[2], ResurrectDB.Layout[3], ResurrectDB.Layout[4])
		unitFrame.ResurrectIndicator:ForceUpdate()
	elseif unitFrame.ResurrectIndicator then
		if unitFrame:IsElementEnabled("ResurrectIndicator") then unitFrame:DisableElement("ResurrectIndicator") end
		unitFrame.ResurrectIndicator:Hide()
		unitFrame.ResurrectIndicator = nil
	end
end
