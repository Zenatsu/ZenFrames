local _, ZF = ...

function ZF:CreateUnitReadyCheckIndicator(unitFrame, unit)
	local ReadyCheckDB = ZF:GetUnitDB(unitFrame, unit).Indicators.ReadyCheck
	if not ReadyCheckDB then return end

	local ReadyCheckIndicator = ZF:CreateIndicatorTexture(unitFrame, unit, "_ReadyCheckIndicator", ReadyCheckDB.Size, ReadyCheckDB.Layout)
	ReadyCheckIndicator.PostUpdate = function(textureElement, status)
		local textureSet = ZF.ReadyCheckTextures[ReadyCheckDB.Texture]
		local statusTexture = textureSet and (status == "ready" and textureSet["READY"] or status == "notready" and textureSet["NOTREADY"] or status == "waiting" and textureSet["WAITING"])
		if statusTexture then
			textureElement:SetTexture(statusTexture)
			textureElement:SetTexCoord(0, 1, 0, 1)
		end
	end

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
		if unitFrame.ReadyCheckIndicator.ForceUpdate then unitFrame.ReadyCheckIndicator:ForceUpdate() end
	elseif unitFrame.ReadyCheckIndicator then
		ZF:DisableIndicatorElement(unitFrame, "ReadyCheckIndicator", unitFrame.ReadyCheckIndicator)
		unitFrame.ReadyCheckIndicator = nil
	end
end
