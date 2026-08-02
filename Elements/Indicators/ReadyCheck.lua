local _, RUF = ...

function RUF:CreateUnitReadyCheckIndicator(unitFrame, unit)
	local ReadyCheckDB = RUF:GetUnitDB(unitFrame, unit).Indicators.ReadyCheckIndicator
	if not ReadyCheckDB then return end

	local ReadyCheckIndicator = RUF:CreateIndicatorTexture(unitFrame, unit, "_ReadyCheckIndicator", ReadyCheckDB.Size, ReadyCheckDB.Layout)
	ReadyCheckIndicator.readyTexture = RUF.ReadyCheckTextures[ReadyCheckDB.Texture] and RUF.ReadyCheckTextures[ReadyCheckDB.Texture]["READY"]
	ReadyCheckIndicator.notReadyTexture = RUF.ReadyCheckTextures[ReadyCheckDB.Texture] and RUF.ReadyCheckTextures[ReadyCheckDB.Texture]["NOTREADY"]
	ReadyCheckIndicator.waitingTexture = RUF.ReadyCheckTextures[ReadyCheckDB.Texture] and RUF.ReadyCheckTextures[ReadyCheckDB.Texture]["WAITING"]

	if ReadyCheckDB.Enabled then
		unitFrame.ReadyCheckIndicator = ReadyCheckIndicator
	else
		RUF:DisableIndicatorElement(unitFrame, "ReadyCheckIndicator", ReadyCheckIndicator)
	end

	return ReadyCheckIndicator
end

function RUF:UpdateUnitReadyCheckIndicator(unitFrame, unit)
	local ReadyCheckDB = RUF:GetUnitDB(unitFrame, unit).Indicators.ReadyCheckIndicator
	if not ReadyCheckDB then return end

	if ReadyCheckDB.Enabled then
		unitFrame.ReadyCheckIndicator = unitFrame.ReadyCheckIndicator or RUF:CreateUnitReadyCheckIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("ReadyCheckIndicator") then unitFrame:EnableElement("ReadyCheckIndicator", RUF:GetNormalizedUnit(unit)) end

		RUF:PositionIndicatorTexture(unitFrame.ReadyCheckIndicator, unitFrame.HighLevelContainer, ReadyCheckDB.Size, ReadyCheckDB.Layout)
		unitFrame.ReadyCheckIndicator.readyTexture = RUF.ReadyCheckTextures[ReadyCheckDB.Texture] and RUF.ReadyCheckTextures[ReadyCheckDB.Texture]["READY"]
		unitFrame.ReadyCheckIndicator.notReadyTexture = RUF.ReadyCheckTextures[ReadyCheckDB.Texture] and RUF.ReadyCheckTextures[ReadyCheckDB.Texture]["NOTREADY"]
		unitFrame.ReadyCheckIndicator.waitingTexture = RUF.ReadyCheckTextures[ReadyCheckDB.Texture] and RUF.ReadyCheckTextures[ReadyCheckDB.Texture]["WAITING"]
		if unitFrame.ReadyCheckIndicator.ForceUpdate then unitFrame.ReadyCheckIndicator:ForceUpdate() end
	elseif unitFrame.ReadyCheckIndicator then
		RUF:DisableIndicatorElement(unitFrame, "ReadyCheckIndicator", unitFrame.ReadyCheckIndicator)
		unitFrame.ReadyCheckIndicator = nil
	end
end
