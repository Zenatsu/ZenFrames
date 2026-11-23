local _, ZF = ...

local function Update3DPortrait(unitFrame, _, unit)
	if not unit or not UnitIsUnit(unitFrame.__unit, unit) then return end

	local unitPortrait = unitFrame.Portrait
	if unitPortrait.PreUpdate then unitPortrait:PreUpdate(unit) end

	local unitGUID = UnitGUID(unit)
	local isAvailable = UnitIsConnected(unit) and UnitIsVisible(unit)
	local isSecretGUID = ZF:IsSecretValue(unitGUID)
	local useFallback = isAvailable and isSecretGUID
	local isSecretPreviousGUID = ZF:IsSecretValue(unitPortrait.guid)
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

local function ComputePortraitZoomTexCoord(zoom)
	zoom = zoom or 0
	local inset = zoom * 0.5
	return inset, 1 - inset, inset, 1 - inset
end

local function ApplyPortraitBorderStyle(border, PortraitDB)
	ZF:ApplyBorderStyle(border, PortraitDB, math.min(PortraitDB.Width, PortraitDB.Height), {0, 0, 0, 0})
end

local function ApplyPortraitEnabledState(unitFrame, unitPortrait, PortraitDB)
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
end

local function PositionPortraitBackdrop(unitFrame, PortraitDB)
	local backdrop = unitFrame.Portrait.Backdrop
	backdrop:ClearAllPoints()
	backdrop:SetSize(PortraitDB.Width, PortraitDB.Height)
	backdrop:SetPoint(PortraitDB.Layout[1], unitFrame.HighLevelContainer, PortraitDB.Layout[2], PortraitDB.Layout[3], PortraitDB.Layout[4])
	unitFrame.Portrait:SetAllPoints(backdrop)
end

local function CreatePortraitBackdrop(unitFrame, unit, PortraitDB)
	local portraitBackdrop = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_PortraitBackdrop", unitFrame.HighLevelContainer, "BackdropTemplate")
	portraitBackdrop:SetSize(PortraitDB.Width, PortraitDB.Height)
	portraitBackdrop:SetPoint(PortraitDB.Layout[1], unitFrame.HighLevelContainer, PortraitDB.Layout[2], PortraitDB.Layout[3], PortraitDB.Layout[4])
	ZF:ApplyBackdropStyle(portraitBackdrop, {26/255, 26/255, 26/255, 1}, {0, 0, 0, 0})

	local border = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_PortraitBorder", portraitBackdrop, "BackdropTemplate")
	border:SetAllPoints(portraitBackdrop)
	ApplyPortraitBorderStyle(border, PortraitDB)
	border:SetFrameLevel(portraitBackdrop:GetFrameLevel() + 10)

	return portraitBackdrop, border
end

local function BuildPortrait(unitFrame, unit, PortraitDB, portraitStyle)
	local portraitBackdrop, border = CreatePortraitBackdrop(unitFrame, unit, PortraitDB)
	local unitPortrait

	if portraitStyle == "3D" then
		unitPortrait = CreateFrame("PlayerModel", ZF:FetchFrameName(unit) .. "_Portrait3D", portraitBackdrop)
		unitPortrait:SetAllPoints(portraitBackdrop)
		unitPortrait:SetCamDistanceScale(1)
		unitPortrait:SetPortraitZoom(1)
		unitPortrait:SetPosition(0, 0, 0)
		unitPortrait.Override = Update3DPortrait

		unitPortrait.Fallback = portraitBackdrop:CreateTexture(ZF:FetchFrameName(unit) .. "_Portrait3DFallback", "ARTWORK")
		unitPortrait.Fallback:SetAllPoints(portraitBackdrop)
		unitPortrait.Fallback:SetTexCoord(ComputePortraitZoomTexCoord(PortraitDB.Zoom))
		unitPortrait.Fallback:Hide()
	else
		unitPortrait = portraitBackdrop:CreateTexture(ZF:FetchFrameName(unit) .. "_Portrait2D", "ARTWORK")
		unitPortrait:SetAllPoints(portraitBackdrop)
		unitPortrait:SetTexCoord(ComputePortraitZoomTexCoord(PortraitDB.Zoom))
		unitPortrait.showClass = PortraitDB.UseClassPortrait
	end

	unitPortrait.Backdrop = portraitBackdrop
	unitPortrait.Border = border
	return unitPortrait
end

local function GetPortraitVariant(unitFrame, unit, PortraitDB)
	local portraitStyle = PortraitDB.Style == "3D" and "3D" or "2D"
	unitFrame.PortraitVariants = unitFrame.PortraitVariants or {}
	local unitPortrait = unitFrame.PortraitVariants[portraitStyle]
	if not unitPortrait then
		unitPortrait = BuildPortrait(unitFrame, unit, PortraitDB, portraitStyle)
		unitFrame.PortraitVariants[portraitStyle] = unitPortrait
	end
	return unitPortrait
end

local function DetachPortrait(unitFrame)
	local unitPortrait = unitFrame.Portrait
	if not unitPortrait then return end
	if unitFrame:IsElementEnabled("Portrait") then unitFrame:DisableElement("Portrait") end
	unitPortrait:Hide()
	unitPortrait.Border:Hide()
	if unitPortrait.Fallback then unitPortrait.Fallback:Hide() end
	unitPortrait.Backdrop:Hide()
	unitFrame.Portrait = nil
end

function ZF:CreateUnitPortrait(unitFrame, unit)
	local PortraitDB = ZF:GetUnitDB(nil, unit).Portrait
	local unitPortrait = GetPortraitVariant(unitFrame, unit, PortraitDB)
	ApplyPortraitEnabledState(unitFrame, unitPortrait, PortraitDB)
	return unitPortrait
end

function ZF:UpdateUnitPortrait(unitFrame, unit)
	local PortraitDB = ZF:GetUnitDB(nil, unit).Portrait

	if PortraitDB.Enabled then
		local unitPortrait = GetPortraitVariant(unitFrame, unit, PortraitDB)
		if unitFrame.Portrait ~= unitPortrait then DetachPortrait(unitFrame) end
		unitFrame.Portrait = unitPortrait
		if not unitFrame:IsElementEnabled("Portrait") then unitFrame:EnableElement("Portrait") end

		PositionPortraitBackdrop(unitFrame, PortraitDB)
		if unitPortrait:IsObjectType("PlayerModel") then
			unitPortrait.Fallback:SetTexCoord(ComputePortraitZoomTexCoord(PortraitDB.Zoom))
			unitPortrait:SetCamDistanceScale(1)
			unitPortrait:SetPortraitZoom(1)
			unitPortrait:SetPosition(0, 0, 0)
		else
			unitPortrait:SetTexCoord(ComputePortraitZoomTexCoord(PortraitDB.Zoom))
			unitPortrait.showClass = PortraitDB.UseClassPortrait
		end
		unitPortrait.Backdrop:Show()

		unitPortrait:Show()
		ApplyPortraitBorderStyle(unitPortrait.Border, PortraitDB)
		unitPortrait.Border:Show()
		unitPortrait:ForceUpdate()
	else
		DetachPortrait(unitFrame)
	end
end
