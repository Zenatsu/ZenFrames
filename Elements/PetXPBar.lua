local _, ZF = ...

local XP_EVENTS = { "UNIT_PET_EXPERIENCE", "UNIT_PET", "UNIT_LEVEL" }
local POLL_INTERVAL = 1
local PREVIEW_VALUE = 60

function ZF:UsesPetXPBar()
	return ZF.IS_FOREVER and UnitClassBase("player") == "HUNTER"
end

local function ReadExperience()
	if not GetPetExperience then return end
	local current, maximum = GetPetExperience()
	if type(current) ~= "number" or type(maximum) ~= "number" then return end
	if ZF:IsSecretValue(current) or ZF:IsSecretValue(maximum) then return end
	return current, maximum
end

ZF.GetPetExperienceValues = ReadExperience

local function RefreshPetXPBar(unitFrame)
	local bar = unitFrame.PetXPBar
	if not bar then return end
	local container = unitFrame.PetXPBarContainer

	if unitFrame.isDesignerPreview or (unitFrame.isUnitPreview and not UnitExists("pet")) then
		bar:SetMinMaxValues(0, 100)
		bar:SetValue(PREVIEW_VALUE)
		container:Show()
		return
	end

	local current, maximum = ReadExperience()
	if current and maximum > 0 then
		bar:SetMinMaxValues(0, maximum)
		bar:SetValue(current)
		container:Show()
	else
		container:Hide()
	end
end

local function CreateDriver(unitFrame)
	local driver = CreateFrame("Frame", nil, unitFrame)
	driver.elapsed = 0
	driver:SetScript("OnEvent", function() RefreshPetXPBar(unitFrame) end)
	driver:SetScript("OnUpdate", function(frame, elapsed)
		frame.elapsed = frame.elapsed + elapsed
		if frame.elapsed < POLL_INTERVAL then return end
		frame.elapsed = 0
		RefreshPetXPBar(unitFrame)
	end)
	return driver
end

local function SetDriverActive(unitFrame, active)
	local driver = unitFrame.PetXPBarDriver
	if not active then
		if driver then
			driver:UnregisterAllEvents()
			driver:Hide()
		end
		return
	end
	driver = driver or CreateDriver(unitFrame)
	unitFrame.PetXPBarDriver = driver
	driver:Show()
	for _, event in ipairs(XP_EVENTS) do
		if C_EventUtils.IsEventValid(event) then driver:RegisterEvent(event) end
	end
end

local function SyncPetXPBar(unitFrame, unit)
	local UnitDB = ZF:GetUnitDB(unitFrame, unit)
	local PetXPBarDB = UnitDB.PetXPBar
	local container = unitFrame.PetXPBarContainer
	local bar = unitFrame.PetXPBar
	unitFrame.PetXPBarDB = PetXPBarDB

	local borderSize = ZF:ApplyBorderStyle(container, PetXPBarDB, PetXPBarDB.Height, { 0, 0, 0, 0 })
	container:ClearAllPoints()
	container:SetPoint(PetXPBarDB.Layout[1], unitFrame, PetXPBarDB.Layout[2], PetXPBarDB.Layout[3], PetXPBarDB.Layout[4])
	container:SetWidth(PetXPBarDB.MatchParentWidth and UnitDB.Frame.Width or PetXPBarDB.Width)
	container:SetHeight(PetXPBarDB.Height)
	if not unitFrame.isDesignerPreview then container:SetFrameStrata(PetXPBarDB.FrameStrata) end

	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", container, "TOPLEFT", borderSize, -borderSize)
	bar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -borderSize, borderSize)
	bar:SetStatusBarTexture(ZF.Media.Foreground)
	bar:SetStatusBarColor(unpack(PetXPBarDB.Foreground))
	bar:SetReverseFill(PetXPBarDB.Inverse and true or false)
	bar.Background:SetTexture(ZF.Media.Background)
	bar.Background:SetVertexColor(unpack(PetXPBarDB.Background))
end

function ZF:CreateUnitPetXPBar(unitFrame, unit)
	if not ZF:UsesPetXPBar() or unitFrame.PetXPBar then return unitFrame.PetXPBar end

	local container = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_PetXPBarContainer", unitFrame, "BackdropTemplate")
	container:Hide()

	local bar = CreateFrame("StatusBar", ZF:FetchFrameName(unit) .. "_PetXPBar", container)
	bar:SetFrameLevel(container:GetFrameLevel() + 1)
	bar:SetStatusBarTexture(ZF.Media.Foreground)
	bar.Background = bar:CreateTexture(nil, "BACKGROUND")
	bar.Background:SetAllPoints(bar)

	unitFrame.PetXPBarContainer = container
	unitFrame.PetXPBar = bar
	SyncPetXPBar(unitFrame, unit)
	return bar
end

function ZF:UpdateUnitPetXPBar(unitFrame, unit)
	if not ZF:UsesPetXPBar() or not unitFrame then return end
	local PetXPBarDB = ZF:GetUnitDB(unitFrame, unit).PetXPBar
	if not PetXPBarDB then return end

	if PetXPBarDB.Enabled then
		ZF:CreateUnitPetXPBar(unitFrame, unit)
		SyncPetXPBar(unitFrame, unit)
		SetDriverActive(unitFrame, not unitFrame.isDesignerPreview)
		RefreshPetXPBar(unitFrame)
	elseif unitFrame.PetXPBar then
		SetDriverActive(unitFrame, false)
		unitFrame.PetXPBarContainer:Hide()
	end
end
