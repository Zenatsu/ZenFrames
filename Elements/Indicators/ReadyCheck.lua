local _, RUF = ...

function RUF:CreateUnitReadyCheckIndicator(unitFrame, unit)
	local ReadyCheckDB = RUF:GetUnitDB(unitFrame, unit).Indicators.ReadyCheckIndicator
	if not ReadyCheckDB then return end

	local ReadyCheckIndicator = unitFrame.HighLevelContainer:CreateTexture(RUF:FetchFrameName(unit) .. "_ReadyCheckIndicator", "OVERLAY")
	ReadyCheckIndicator:SetSize(ReadyCheckDB.Size, ReadyCheckDB.Size)
	ReadyCheckIndicator:SetPoint(ReadyCheckDB.Layout[1], unitFrame.HighLevelContainer, ReadyCheckDB.Layout[2], ReadyCheckDB.Layout[3], ReadyCheckDB.Layout[4])
	ReadyCheckIndicator.readyTexture = RUF.ReadyCheckTextures[ReadyCheckDB.Texture] and RUF.ReadyCheckTextures[ReadyCheckDB.Texture]["READY"]
	ReadyCheckIndicator.notReadyTexture = RUF.ReadyCheckTextures[ReadyCheckDB.Texture] and RUF.ReadyCheckTextures[ReadyCheckDB.Texture]["NOTREADY"]
	ReadyCheckIndicator.waitingTexture = RUF.ReadyCheckTextures[ReadyCheckDB.Texture] and RUF.ReadyCheckTextures[ReadyCheckDB.Texture]["WAITING"]

	if ReadyCheckDB.Enabled then
		unitFrame.ReadyCheckIndicator = ReadyCheckIndicator
	else
		ReadyCheckIndicator:Hide()
	end

	return ReadyCheckIndicator
end

function RUF:UpdateUnitReadyCheckIndicator(unitFrame, unit)
	local ReadyCheckDB = RUF:GetUnitDB(unitFrame, unit).Indicators.ReadyCheckIndicator
	if not ReadyCheckDB then return end

	if ReadyCheckDB.Enabled then
		unitFrame.ReadyCheckIndicator = unitFrame.ReadyCheckIndicator or RUF:CreateUnitReadyCheckIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("ReadyCheckIndicator") then unitFrame:EnableElement("ReadyCheckIndicator", RUF:GetNormalizedUnit(unit)) end

		unitFrame.ReadyCheckIndicator:ClearAllPoints()
		unitFrame.ReadyCheckIndicator:SetSize(ReadyCheckDB.Size, ReadyCheckDB.Size)
		unitFrame.ReadyCheckIndicator:SetPoint(ReadyCheckDB.Layout[1], unitFrame.HighLevelContainer, ReadyCheckDB.Layout[2], ReadyCheckDB.Layout[3], ReadyCheckDB.Layout[4])
		unitFrame.ReadyCheckIndicator.readyTexture = RUF.ReadyCheckTextures[ReadyCheckDB.Texture] and RUF.ReadyCheckTextures[ReadyCheckDB.Texture]["READY"]
		unitFrame.ReadyCheckIndicator.notReadyTexture = RUF.ReadyCheckTextures[ReadyCheckDB.Texture] and RUF.ReadyCheckTextures[ReadyCheckDB.Texture]["NOTREADY"]
		unitFrame.ReadyCheckIndicator.waitingTexture = RUF.ReadyCheckTextures[ReadyCheckDB.Texture] and RUF.ReadyCheckTextures[ReadyCheckDB.Texture]["WAITING"]
		if unitFrame.ReadyCheckIndicator.ForceUpdate then unitFrame.ReadyCheckIndicator:ForceUpdate() end
	elseif unitFrame.ReadyCheckIndicator then
		if unitFrame:IsElementEnabled("ReadyCheckIndicator") then unitFrame:DisableElement("ReadyCheckIndicator") end
		unitFrame.ReadyCheckIndicator:Hide()
		unitFrame.ReadyCheckIndicator = nil
	end
end
