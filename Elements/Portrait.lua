local _, RUF = ...

local function Update3DPortrait(unitFrame, _, unit)
	if not unit or not UnitIsUnit(unitFrame.unit, unit) then return end

	local unitPortrait = unitFrame.Portrait
	if unitPortrait.PreUpdate then unitPortrait:PreUpdate(unit) end

	local unitGUID = UnitGUID(unit)
	local isAvailable = UnitIsConnected(unit) and UnitIsVisible(unit)
	local isSecretGUID = RUF:IsSecretValue(unitGUID)
	local useFallback = isAvailable and isSecretGUID
	local isSecretPreviousGUID = RUF:IsSecretValue(unitPortrait.guid)
	local portraitChanged = unitPortrait.state ~= isAvailable or unitPortrait.useFallback ~= useFallback or (not isSecretGUID and not isSecretPreviousGUID and unitPortrait.guid ~= unitGUID)

	if useFallback then
		unitPortrait:ClearModel()
		unitPortrait:Hide()
		unitPortrait.Fallback:Show()
		SetPortraitTexture(unitPortrait.Fallback, unit)
	else
		unitPortrait.Fallback:Hide()
		unitPortrait:Show()

		if not isAvailable then
			unitPortrait:SetCamDistanceScale(0.25)
			unitPortrait:SetPortraitZoom(0)
			unitPortrait:SetPosition(0, 0, 0.25)
			unitPortrait:ClearModel()
			unitPortrait:SetModel([[Interface\Buttons\TalkToMeQuestionMark.m2]])
		else
			unitPortrait:SetCamDistanceScale(1)
			unitPortrait:SetPortraitZoom(1)
			unitPortrait:SetPosition(0, 0, 0)
			unitPortrait:ClearModel()
			unitPortrait:SetUnit(unit)
		end
	end

	unitPortrait.guid = unitGUID
	unitPortrait.state = isAvailable
	unitPortrait.useFallback = useFallback

	if unitPortrait.PostUpdate then return unitPortrait:PostUpdate(unit, portraitChanged) end
end

local function CreatePortraitBackdrop(unitFrame, unit, PortraitDB)
	local portraitBackdrop = CreateFrame("Frame", RUF:FetchFrameName(unit) .. "_PortraitBackdrop", unitFrame.HighLevelContainer, "BackdropTemplate")
	portraitBackdrop:SetSize(PortraitDB.Width, PortraitDB.Height)
	portraitBackdrop:SetPoint(PortraitDB.Layout[1], unitFrame.HighLevelContainer, PortraitDB.Layout[2], PortraitDB.Layout[3], PortraitDB.Layout[4])
	RUF:ApplyBackdropStyle(portraitBackdrop, {26/255, 26/255, 26/255, 1}, {0, 0, 0, 0})

	local border = CreateFrame("Frame", RUF:FetchFrameName(unit) .. "_PortraitBorder", portraitBackdrop, "BackdropTemplate")
	border:SetAllPoints(portraitBackdrop)
	RUF:ApplyBackdropStyle(border, {0, 0, 0, 0}, {0, 0, 0, 1})
	border:SetFrameLevel(portraitBackdrop:GetFrameLevel() + 10)

	return portraitBackdrop, border
end

function RUF:CreateUnitPortrait(unitFrame, unit)
	local PortraitDB = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)].Portrait
	local portraitStyle = PortraitDB.Style or "2D"

	if portraitStyle == "3D" then
		local portraitBackdrop, border = CreatePortraitBackdrop(unitFrame, unit, PortraitDB)

		local unitPortrait = CreateFrame("PlayerModel", RUF:FetchFrameName(unit) .. "_Portrait3D", portraitBackdrop)
		unitPortrait:SetAllPoints(portraitBackdrop)
		unitPortrait:SetCamDistanceScale(1)
		unitPortrait:SetPortraitZoom(1)
		unitPortrait:SetPosition(0, 0, 0)
		unitPortrait.Backdrop = portraitBackdrop
		unitPortrait.Override = Update3DPortrait

		unitPortrait.Fallback = portraitBackdrop:CreateTexture(RUF:FetchFrameName(unit) .. "_Portrait3DFallback", "ARTWORK")
		unitPortrait.Fallback:SetAllPoints(portraitBackdrop)
		unitPortrait.Fallback:SetTexCoord((PortraitDB.Zoom or 0) * 0.5, 1 - (PortraitDB.Zoom or 0) * 0.5, (PortraitDB.Zoom or 0) * 0.5, 1 - (PortraitDB.Zoom or 0) * 0.5)
		unitPortrait.Fallback:Hide()

		unitPortrait.Border = border

		if PortraitDB.Enabled then
			unitFrame.Portrait = unitPortrait
			unitFrame.Portrait:Show()
			unitFrame.Portrait.Backdrop:Show()
		else
			if unitFrame:IsElementEnabled("Portrait") then unitFrame:DisableElement("Portrait") end
			unitPortrait:Hide()
			unitPortrait.Border:Hide()
			unitPortrait.Backdrop:Hide()
		end

		return unitPortrait
	end

	local portraitBackdrop, border = CreatePortraitBackdrop(unitFrame, unit, PortraitDB)

	local unitPortrait = portraitBackdrop:CreateTexture(RUF:FetchFrameName(unit) .. "_Portrait2D", "ARTWORK")
	unitPortrait:SetAllPoints(portraitBackdrop)
	unitPortrait:SetTexCoord((PortraitDB.Zoom or 0) * 0.5, 1 - (PortraitDB.Zoom or 0) * 0.5, (PortraitDB.Zoom or 0) * 0.5, 1 - (PortraitDB.Zoom or 0) * 0.5)
	unitPortrait.showClass = PortraitDB.UseClassPortrait
	unitPortrait.Backdrop = portraitBackdrop
	unitPortrait.Border = border

	if PortraitDB.Enabled then
		unitFrame.Portrait = unitPortrait
		unitFrame.Portrait:Show()
		unitFrame.Portrait.Backdrop:Show()
	else
		if unitFrame:IsElementEnabled("Portrait") then unitFrame:DisableElement("Portrait") end
		unitPortrait:Hide()
		unitPortrait.Border:Hide()
		unitPortrait.Backdrop:Hide()
	end

	return unitPortrait
end

function RUF:UpdateUnitPortrait(unitFrame, unit)
	local PortraitDB = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)].Portrait
	local portraitStyle = PortraitDB.Style or "2D"

	if PortraitDB.Enabled then
		local isPlayerModel = unitFrame.Portrait and unitFrame.Portrait:IsObjectType("PlayerModel")
		if unitFrame.Portrait and ((portraitStyle == "3D" and not isPlayerModel) or (portraitStyle ~= "3D" and (isPlayerModel or not unitFrame.Portrait.Backdrop))) then
			if unitFrame:IsElementEnabled("Portrait") then unitFrame:DisableElement("Portrait") end
			unitFrame.Portrait.Border:Hide()
			unitFrame.Portrait.Border = nil
			if unitFrame.Portrait.Backdrop then
				unitFrame.Portrait.Backdrop:Hide()
				unitFrame.Portrait.Backdrop = nil
			end
			if unitFrame.Portrait.Fallback then
				unitFrame.Portrait.Fallback:Hide()
				unitFrame.Portrait.Fallback = nil
			end
			unitFrame.Portrait:Hide()
			unitFrame.Portrait = nil
		end

		if not unitFrame.Portrait then unitFrame.Portrait = RUF:CreateUnitPortrait(unitFrame, unit) end
		if not unitFrame:IsElementEnabled("Portrait") then unitFrame:EnableElement("Portrait") end

		if unitFrame.Portrait:IsObjectType("PlayerModel") then
			unitFrame.Portrait.Backdrop:ClearAllPoints()
			unitFrame.Portrait.Backdrop:SetSize(PortraitDB.Width, PortraitDB.Height)
			unitFrame.Portrait.Backdrop:SetPoint(PortraitDB.Layout[1], unitFrame.HighLevelContainer, PortraitDB.Layout[2], PortraitDB.Layout[3], PortraitDB.Layout[4])
			unitFrame.Portrait:SetAllPoints(unitFrame.Portrait.Backdrop)
			unitFrame.Portrait.Fallback:SetTexCoord((PortraitDB.Zoom or 0) * 0.5, 1 - (PortraitDB.Zoom or 0) * 0.5, (PortraitDB.Zoom or 0) * 0.5, 1 - (PortraitDB.Zoom or 0) * 0.5)
			unitFrame.Portrait:SetCamDistanceScale(1)
			unitFrame.Portrait:SetPortraitZoom(1)
			unitFrame.Portrait:SetPosition(0, 0, 0)
			unitFrame.Portrait.Backdrop:Show()
		else
			unitFrame.Portrait.Backdrop:ClearAllPoints()
			unitFrame.Portrait.Backdrop:SetSize(PortraitDB.Width, PortraitDB.Height)
			unitFrame.Portrait.Backdrop:SetPoint(PortraitDB.Layout[1], unitFrame.HighLevelContainer, PortraitDB.Layout[2], PortraitDB.Layout[3], PortraitDB.Layout[4])
			unitFrame.Portrait:SetAllPoints(unitFrame.Portrait.Backdrop)
			unitFrame.Portrait:SetTexCoord((PortraitDB.Zoom or 0) * 0.5, 1 - (PortraitDB.Zoom or 0) * 0.5, (PortraitDB.Zoom or 0) * 0.5, 1 - (PortraitDB.Zoom or 0) * 0.5)
			unitFrame.Portrait.showClass = PortraitDB.UseClassPortrait
			unitFrame.Portrait.Backdrop:Show()
		end

		unitFrame.Portrait:Show()
		unitFrame.Portrait.Border:Show()
		unitFrame.Portrait:ForceUpdate()
	else
		if not unitFrame.Portrait then return end
		if unitFrame:IsElementEnabled("Portrait") then unitFrame:DisableElement("Portrait") end
		unitFrame.Portrait:Hide()
		unitFrame.Portrait.Border:Hide()
		if unitFrame.Portrait.Fallback then unitFrame.Portrait.Fallback:Hide() end
		if unitFrame.Portrait.Backdrop then unitFrame.Portrait.Backdrop:Hide() end
		unitFrame.Portrait = nil
	end
end
