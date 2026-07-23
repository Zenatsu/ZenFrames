local _, RUF = ...

local function RefreshMover(frameMover)
	local unitFrame = frameMover.unit == "boss" and RUF.BOSS1 or frameMover.unit == "party" and RUF.PARTY_CONTAINER or frameMover.unit == "raid" and RUF.RAID_CONTAINER or frameMover.unit == "augmentation" and RUF.AUGMENTATION_RAID_CONTAINER or RUF[frameMover.unit:upper()]
	if not unitFrame then return end
	frameMover:ClearAllPoints()
	if frameMover.unit == "party" or frameMover.unit == "raid" or frameMover.unit == "augmentation" then
		frameMover:SetPoint("TOPLEFT", unitFrame, "TOPLEFT")
		frameMover:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT")
	elseif frameMover.unit == "boss" then
		local topFrame, bottomFrame = unitFrame, unitFrame
		for _, bossFrame in pairs(RUF.BOSS_FRAMES) do
			if bossFrame:GetTop() > topFrame:GetTop() then topFrame = bossFrame end
			if bossFrame:GetBottom() < bottomFrame:GetBottom() then bottomFrame = bossFrame end
		end
		frameMover:SetPoint("TOPLEFT", topFrame, "TOPLEFT")
		frameMover:SetPoint("BOTTOMRIGHT", bottomFrame, "BOTTOMRIGHT")
	else
		frameMover:SetPoint("TOPLEFT", unitFrame, "TOPLEFT")
		frameMover:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT")
	end
end

local function StopMoving(frameMover)
	frameMover:StopMovingOrSizing()

	local unitFrame = frameMover.unit == "boss" and RUF.BOSS1 or frameMover.unit == "party" and RUF.PARTY_CONTAINER or frameMover.unit == "raid" and RUF.RAID_CONTAINER or frameMover.unit == "augmentation" and RUF.AUGMENTATION_RAID_CONTAINER or RUF[frameMover.unit:upper()]
	if not unitFrame then return end

	local moverX, moverY = frameMover:GetCenter()
	local FrameDB = RUF.db.profile.Units[frameMover.unit].Frame
	FrameDB.Layout[3] = FrameDB.Layout[3] + moverX - frameMover.startX
	FrameDB.Layout[4] = FrameDB.Layout[4] + moverY - frameMover.startY

	if frameMover.unit == "boss" then RUF:LayoutBossFrames() elseif frameMover.unit == "augmentation" then RUF:LayoutAugmentationRaidFrames() elseif frameMover.unit == "party" or frameMover.unit == "raid" then RUF:LayoutGroupFrames(frameMover.unit) else RUF:UpdateUnitFrame(unitFrame, frameMover.unit) end
	RefreshMover(frameMover)
end

function RUF:CreateMover(unit)
	RUF.MOVERS = RUF.MOVERS or {}
	if RUF.MOVERS[unit] then return end

	local frameMover = CreateFrame("Button", "RUF_" .. unit .. "Mover", UIParent, "BackdropTemplate")
	frameMover.unit = unit
	frameMover:SetBackdrop(RUF.BACKDROP)
	frameMover:SetBackdropColor(81/255, 81/255, 163/255, 0.8)
	frameMover:SetBackdropBorderColor(0, 0, 0, 1)
	frameMover:SetFrameStrata("TOOLTIP")
	frameMover:SetClampedToScreen(true)
	frameMover:SetMovable(true)
	frameMover:RegisterForClicks("RightButtonUp")
	frameMover:RegisterForDrag("LeftButton")
	frameMover:SetScript("OnClick", function(_, button) if button == "RightButton" then RUF:OpenGUIToUnit(unit) end end)
	frameMover:SetScript("OnDragStart", function() if not InCombatLockdown() then frameMover.startX, frameMover.startY = frameMover:GetCenter() frameMover:StartMoving() end end)
	frameMover:SetScript("OnDragStop", function() if InCombatLockdown() then frameMover:StopMovingOrSizing() RefreshMover(frameMover) else StopMoving(frameMover) end end)
	frameMover:SetScript("OnShow", RefreshMover)

	frameMover.Text = frameMover:CreateFontString(nil, "OVERLAY")
	frameMover.Text:SetPoint("CENTER")
	frameMover.Text:SetFont(RUF.Media.Font, 12, "OUTLINE, SLUG")
	frameMover.Text:SetText(unit == "targettarget" and "Target of Target" or unit == "focustarget" and "Focus Target" or unit == "augmentation" and "Augmentation" or unit:gsub("^%l", string.upper))
	frameMover.Text:SetTextColor(255/255, 255/255, 255/255, 1)

	RUF.MOVERS[unit] = frameMover
	frameMover:Hide()
end

function RUF:ToggleMovers()
	if InCombatLockdown() then RUF:PrettyPrint("Movers cannot be toggled while in combat.") return RUF.MOVERS_UNLOCKED end
	RUF.MOVERS_UNLOCKED = not RUF.MOVERS_UNLOCKED
	for _, mover in pairs(RUF.MOVERS or {}) do mover:SetShown(RUF.MOVERS_UNLOCKED and (mover.unit ~= "augmentation" or RUF:IsAugmentationEvoker())) end
	return RUF.MOVERS_UNLOCKED
end
