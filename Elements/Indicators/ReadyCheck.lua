local _, ZF = ...

function ZF:CreateUnitReadyCheckIndicator(unitFrame, unit)
	local ReadyCheckDB = ZF:GetUnitDB(unitFrame, unit).Indicators.ReadyCheck
	if not ReadyCheckDB then return end

	local ReadyCheckIndicator = ZF:CreateIndicatorTexture(unitFrame, unit, "_ReadyCheckIndicator", ReadyCheckDB.Size, ReadyCheckDB.Layout)
	ReadyCheckIndicator.readyTexture = ZF.ReadyCheckTextures[ReadyCheckDB.Texture] and ZF.ReadyCheckTextures[ReadyCheckDB.Texture]["READY"]
	ReadyCheckIndicator.notReadyTexture = ZF.ReadyCheckTextures[ReadyCheckDB.Texture] and ZF.ReadyCheckTextures[ReadyCheckDB.Texture]["NOTREADY"]
	ReadyCheckIndicator.waitingTexture = ZF.ReadyCheckTextures[ReadyCheckDB.Texture] and ZF.ReadyCheckTextures[ReadyCheckDB.Texture]["WAITING"]

	if ReadyCheckDB.Enabled then
		unitFrame.ReadyCheckIndicator = ReadyCheckIndicator
	else
		ZF:DisableIndicatorElement(unitFrame, "ReadyCheckIndicator", ReadyCheckIndicator)
	end

	return ReadyCheckIndicator
end

function ZF:UpdateUnitReadyCheckIndicator(unitFrame, unit)
	local ReadyCheckDB = ZF:GetUnitDB(unitFrame, unit).Indicators.ReadyCheck
	if not ReadyCheckDB then return end

	if ReadyCheckDB.Enabled then
		unitFrame.ReadyCheckIndicator = unitFrame.ReadyCheckIndicator or ZF:CreateUnitReadyCheckIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("ReadyCheckIndicator") then unitFrame:EnableElement("ReadyCheckIndicator", ZF:GetNormalizedUnit(unit)) end

		ZF:PositionIndicatorTexture(unitFrame.ReadyCheckIndicator, unitFrame.HighLevelContainer, ReadyCheckDB.Size, ReadyCheckDB.Layout)
		unitFrame.ReadyCheckIndicator.readyTexture = ZF.ReadyCheckTextures[ReadyCheckDB.Texture] and ZF.ReadyCheckTextures[ReadyCheckDB.Texture]["READY"]
		unitFrame.ReadyCheckIndicator.notReadyTexture = ZF.ReadyCheckTextures[ReadyCheckDB.Texture] and ZF.ReadyCheckTextures[ReadyCheckDB.Texture]["NOTREADY"]
		unitFrame.ReadyCheckIndicator.waitingTexture = ZF.ReadyCheckTextures[ReadyCheckDB.Texture] and ZF.ReadyCheckTextures[ReadyCheckDB.Texture]["WAITING"]
		if unitFrame.ReadyCheckIndicator.ForceUpdate then unitFrame.ReadyCheckIndicator:ForceUpdate() end
	elseif unitFrame.ReadyCheckIndicator then
		ZF:DisableIndicatorElement(unitFrame, "ReadyCheckIndicator", unitFrame.ReadyCheckIndicator)
		unitFrame.ReadyCheckIndicator = nil
	end
end
