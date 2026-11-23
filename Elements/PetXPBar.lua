local _, ZF = ...

local XP_EVENTS = { "UNIT_PET_EXPERIENCE", "UNIT_PET", "UNIT_LEVEL" }
local POLL_INTERVAL = 1
local PREVIEW_VALUE = 60

function ZF:PetUsesXPBar()
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

local function RefreshXPBar(unitFrame)
	local bar = unitFrame.XPBar
	if not bar then return end
	local container = unitFrame.XPBarContainer

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
	driver:SetScript("OnEvent", function() RefreshXPBar(unitFrame) end)
	driver:SetScript("OnUpdate", function(frame, elapsed)
		frame.elapsed = frame.elapsed + elapsed
		if frame.elapsed < POLL_INTERVAL then return end
		frame.elapsed = 0
		RefreshXPBar(unitFrame)
	end)
	return driver
end

local function SetDriverActive(unitFrame, active)
	local driver = unitFrame.XPBarDriver
	if not active then
		if driver then
			driver:UnregisterAllEvents()
			driver:Hide()
		end
		return
	end
	driver = driver or CreateDriver(unitFrame)
	unitFrame.XPBarDriver = driver
	driver:Show()
	for _, event in ipairs(XP_EVENTS) do
		if C_EventUtils.IsEventValid(event) then driver:RegisterEvent(event) end
	end
end

local function SyncXPBar(unitFrame, unit)
	local UnitDB = ZF:GetUnitDB(unitFrame, unit)
	local XPBarDB = UnitDB.XPBar
	local container = unitFrame.XPBarContainer
	local bar = unitFrame.XPBar
	unitFrame.XPBarDB = XPBarDB

	local borderSize = ZF:ApplyBorderStyle(container, XPBarDB, XPBarDB.Height, { 0, 0, 0, 0 })
	container:ClearAllPoints()
	container:SetPoint(XPBarDB.Layout[1], unitFrame, XPBarDB.Layout[2], XPBarDB.Layout[3], XPBarDB.Layout[4])
	container:SetWidth(XPBarDB.MatchParentWidth and UnitDB.Frame.Width or XPBarDB.Width)
	container:SetHeight(XPBarDB.Height)
	if not unitFrame.isDesignerPreview then container:SetFrameStrata(XPBarDB.FrameStrata) end

	bar:ClearAllPoints()
	bar:SetPoint("TOPLEFT", container, "TOPLEFT", borderSize, -borderSize)
	bar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -borderSize, borderSize)
	bar:SetStatusBarTexture(ZF.Media.Foreground)
	bar:SetStatusBarColor(unpack(XPBarDB.Foreground))
	bar:SetReverseFill(XPBarDB.Inverse and true or false)
	bar.Background:SetTexture(ZF.Media.Background)
	bar.Background:SetVertexColor(unpack(XPBarDB.Background))
end

function ZF:CreateUnitXPBar(unitFrame, unit)
	if not ZF:PetUsesXPBar() or unitFrame.XPBar then return unitFrame.XPBar end

	local container = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_XPBarContainer", unitFrame, "BackdropTemplate")
	container:Hide()

	local bar = CreateFrame("StatusBar", ZF:FetchFrameName(unit) .. "_XPBar", container)
	bar:SetFrameLevel(container:GetFrameLevel() + 1)
	bar:SetStatusBarTexture(ZF.Media.Foreground)
	bar.Background = bar:CreateTexture(nil, "BACKGROUND")
	bar.Background:SetAllPoints(bar)

	unitFrame.XPBarContainer = container
	unitFrame.XPBar = bar
	SyncXPBar(unitFrame, unit)
	return bar
end

function ZF:UpdateUnitXPBar(unitFrame, unit)
	if not ZF:PetUsesXPBar() or not unitFrame then return end
	local XPBarDB = ZF:GetUnitDB(unitFrame, unit).XPBar
	if not XPBarDB then return end

	if XPBarDB.Enabled then
		ZF:CreateUnitXPBar(unitFrame, unit)
		SyncXPBar(unitFrame, unit)
		SetDriverActive(unitFrame, not unitFrame.isDesignerPreview)
		RefreshXPBar(unitFrame)
	elseif unitFrame.XPBar then
		SetDriverActive(unitFrame, false)
		unitFrame.XPBarContainer:Hide()
	end
end
