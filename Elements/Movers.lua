local _, ZF = ...
local MoverControlPanel

local function ResolveMoverUnitFrame(frameMover)
    return frameMover.unit == "boss" and ZF.BOSS1
        or frameMover.unit == "party" and ZF.PARTY_CONTAINER
        or frameMover.unit == "raid" and ZF.RAID_CONTAINER
        or frameMover.unit == "augmentation" and ZF.AUGMENTATION_RAID_CONTAINER
        or ZF[frameMover.unit:upper()]
end

local function RelayoutUnit(frameMover)
    if frameMover.unit == "boss" then
        ZF:LayoutBossFrames()
    elseif frameMover.unit == "augmentation" then
        ZF:LayoutAugmentationRaidFrames()
    elseif frameMover.unit == "party" or frameMover.unit == "raid" then
        ZF:LayoutGroupFrames(frameMover.unit)
        if frameMover.unit == "raid" then ZF:RaidLayoutPreviewFrame() end
    else
        ZF:UpdateUnitFrame(ResolveMoverUnitFrame(frameMover), frameMover.unit)
    end
end

local function RefreshMover(frameMover)
	local unitFrame = ResolveMoverUnitFrame(frameMover)
	if not unitFrame then return end
	frameMover:ClearAllPoints()
	if frameMover.unit == "party" or frameMover.unit == "raid" or frameMover.unit == "augmentation" then
		frameMover:SetPoint("TOPLEFT", unitFrame, "TOPLEFT")
		frameMover:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT")
	elseif frameMover.unit == "boss" then
		local topFrame, bottomFrame = unitFrame, unitFrame
		for _, bossFrame in pairs(ZF.BOSS_FRAMES) do
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

local function NudgeMover(frameMover, dx, dy)
    if InCombatLockdown() then return end
    local FrameDB = ZF.db.profile.Units[frameMover.unit].Frame
    FrameDB.Layout[3] = FrameDB.Layout[3] + dx
    FrameDB.Layout[4] = FrameDB.Layout[4] + dy
    RelayoutUnit(frameMover)
    RefreshMover(frameMover)
	MoverControlPanel()
end

local function UpdateMoverVisual(frameMover)
    if frameMover == ZF.ACTIVE_MOVER then
        frameMover:SetBackdropBorderColor(unpack(ZF.DesignerStyle.Palette.MoverBorder))
        ZF.LG.PixelGlow_Start(frameMover, ZF.DesignerStyle.Palette.MoverBorder, nil, nil, nil, 4, nil, nil, false) 
						-- Args: r (The target frame), color(R,G,B,A), N(Number of Dashes), frequency(Animation speed), length(How long the dashes are), th(Line Thickness), xOffset, yOffset(X/Y offset from the source frame), border(Draw a dark border under the dashes), key(Internal namespace for multi glow frames), frameLevel(frame level in which to draw the glow)
    elseif frameMover.hovered then
        frameMover:SetBackdropBorderColor(unpack(ZF.DesignerStyle.Palette.Hovered))
        ZF.LG.PixelGlow_Stop(frameMover)
    else
        frameMover:SetBackdropBorderColor(unpack(ZF.DesignerStyle.Palette.MoverBorder))
        ZF.LG.PixelGlow_Stop(frameMover)
    end
end

local ControlPanel

local function FilterNumericInput(self, char)
    if not self:GetText():match("^%-?%d*%.?%d*$") then
        local cursor = self:GetCursorPosition()
        self:SetText(self:GetText():sub(1, cursor - #char) .. self:GetText():sub(cursor + 1))
        self:SetCursorPosition(cursor - #char)
    end
end

local function CommitCoordinateBox(editBox, frameMover, layoutIndex)
    editBox:ClearFocus()
    if InCombatLockdown() then RefreshMover(frameMover) return end
    local value = tonumber(editBox:GetText())
    if not value then RefreshMover(frameMover) return end
    ZF.db.profile.Units[frameMover.unit].Frame.Layout[layoutIndex] = value
    RelayoutUnit(frameMover)
    RefreshMover(frameMover)
	MoverControlPanel()
end

local function CreateMoverControlBoxes(panel)
	local XBox = CreateFrame("EditBox", nil, ControlPanel, "BackdropTemplate")
	XBox:SetSize(40, 14)
	XBox:SetPoint("CENTER", ControlPanel, "CENTER", -22, -2)
	XBox:SetAutoFocus(false)
	XBox:SetFontObject("GameFontHighlightSmall")
	XBox:SetBackdrop(ZF.BACKDROP)
	XBox:SetBackdropColor(0, 0, 0, 0.6)
	XBox:SetBackdropBorderColor(0, 0, 0, 1)
	XBox:SetScript("OnChar", FilterNumericInput)
	XBox:SetScript("OnEnterPressed", function(self) if ZF.ACTIVE_MOVER then CommitCoordinateBox(self, ZF.ACTIVE_MOVER, 3) end end)
	XBox:SetScript("OnEditFocusLost", function(self) if ZF.ACTIVE_MOVER then CommitCoordinateBox(self, ZF.ACTIVE_MOVER, 3) end end)
	ControlPanel.XBox = XBox

	local YBox = CreateFrame("EditBox", nil, ControlPanel, "BackdropTemplate")
	YBox:SetSize(40, 14)
	YBox:SetPoint("LEFT", XBox, "RIGHT", 4, 0)
	YBox:SetAutoFocus(false)
	YBox:SetFontObject("GameFontHighlightSmall")
	YBox:SetBackdrop(ZF.BACKDROP)
	YBox:SetBackdropColor(0, 0, 0, 0.6)
	YBox:SetBackdropBorderColor(0, 0, 0, 1)
	YBox:SetScript("OnChar", FilterNumericInput)
	YBox:SetScript("OnEnterPressed", function(self) if ZF.ACTIVE_MOVER then CommitCoordinateBox(self, ZF.ACTIVE_MOVER, 4) end end)
	YBox:SetScript("OnEditFocusLost", function(self) if ZF.ACTIVE_MOVER then CommitCoordinateBox(self, ZF.ACTIVE_MOVER, 4) end end)
	ControlPanel.YBox = YBox
end

local function GetMoverControlPanel()
    if ControlPanel then return ControlPanel end
    ControlPanel = CreateFrame("Frame", "ZF_MoverControlPanel", UIParent, "BackdropTemplate")
    ControlPanel:SetSize(150, 90)
    ControlPanel:SetFrameStrata("TOOLTIP")
    ControlPanel:SetClampedToScreen(true)
    ControlPanel:SetBackdrop(ZF.BACKDROP)
    ControlPanel:SetBackdropColor(0, 0, 0, .9)
    ControlPanel:SetBackdropBorderColor(unpack(ZF.DesignerStyle.Palette.MoverBorder))
	ControlPanel:EnableMouse(true)

    local NudgeDirections = {
        Up    = {0, 1, 0},
        Down  = {0, -1, math.rad(180)},
        Left  = {-1, 0, math.rad(90)},
        Right = {1, 0, math.rad(-90)},
    }
    local anchors = {
        Up    = {"TOP", 0, -2},
        Down  = {"BOTTOM", 0, 2},
        Left  = {"LEFT", 2, 0},
        Right = {"RIGHT", -2, 0},
    }
    for direction, info in pairs(NudgeDirections) do
        local dxSign, dySign, rotation = info[1], info[2], info[3]
        local anchorPoint, xOff, yOff = anchors[direction][1], anchors[direction][2], anchors[direction][3]
        local button = CreateFrame("Button", nil, ControlPanel)
        button:SetSize(32, 32)
        button:SetPoint(anchorPoint, ControlPanel, anchorPoint, xOff, yOff)
		button:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
		button:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-down")
        button:GetNormalTexture():SetRotation(rotation)
        button:GetPushedTexture():SetRotation(rotation)
        button:SetScript("OnClick", function()
            if ZF.ACTIVE_MOVER then NudgeMover(ZF.ACTIVE_MOVER, dxSign * ZF.DesignerStyle.Movers.NudgeStep, dySign * ZF.DesignerStyle.Movers.NudgeStep) end
        end)
    end

	CreateMoverControlBoxes(ControlPanel)
    ControlPanel:Hide()
    return ControlPanel
end

MoverControlPanel = function()
    local panel = GetMoverControlPanel()
    if not ZF.ACTIVE_MOVER then panel:Hide() return end
    panel:ClearAllPoints()
    panel:SetPoint("TOP", ZF.ACTIVE_MOVER, "BOTTOM", 0, -4)
    local FrameDB = ZF.db.profile.Units[ZF.ACTIVE_MOVER.unit].Frame
    if not panel.XBox:HasFocus() then panel.XBox:SetText(string.format("%.1f", FrameDB.Layout[3])) end
    if not panel.YBox:HasFocus() then panel.YBox:SetText(string.format("%.1f", FrameDB.Layout[4])) end
    panel:Show()
end

function ZF:SetMoverSelection(frameMover)
    if not frameMover and not ZF.ACTIVE_MOVER then return end
    ZF.ACTIVE_MOVER = frameMover
    local moverList = {}
    for _, mover in pairs(ZF.MOVERS or {}) do moverList[#moverList + 1] = mover end
    for _, mover in ipairs(moverList) do UpdateMoverVisual(mover) end
    MoverControlPanel()
end

local function StopMoving(frameMover)
	frameMover:StopMovingOrSizing()

	local unitFrame = ResolveMoverUnitFrame(frameMover)
	if not unitFrame then return end

	local moverX, moverY = frameMover:GetCenter()
	local FrameDB = ZF.db.profile.Units[frameMover.unit].Frame
	FrameDB.Layout[3] = FrameDB.Layout[3] + moverX - frameMover.startX
	FrameDB.Layout[4] = FrameDB.Layout[4] + moverY - frameMover.startY

	RelayoutUnit(frameMover)
	RefreshMover(frameMover)
	MoverControlPanel()
end

function ZF:CreateMover(unit)
	ZF.MOVERS = ZF.MOVERS or {}
	if ZF.MOVERS[unit] then return end

	local frameMover = CreateFrame("Button", "ZF_" .. unit .. "Mover", UIParent, "BackdropTemplate")
	frameMover.unit = unit
	frameMover:SetBackdrop(ZF.BACKDROP)
	frameMover:SetBackdropColor(0, 0, 0, 0)
	UpdateMoverVisual(frameMover)
	frameMover:SetFrameStrata("FULLSCREEN_DIALOG")
	frameMover:SetClampedToScreen(true)
	frameMover:SetMovable(true)
	frameMover:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	frameMover:RegisterForDrag("LeftButton")
	frameMover:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			if ZF.MOVERS_UNLOCKED then ZF:ToggleMovers() end
			ZF:OpenGUIToUnit(unit)
		elseif button == "LeftButton" then
			ZF:SetMoverSelection(self)
		end
	end)
	frameMover:SetScript("OnDragStart", function()
		if InCombatLockdown() then return end
		ZF:SetMoverSelection(frameMover)
		frameMover.startX, frameMover.startY = frameMover:GetCenter()
		frameMover:StartMoving()
	end)
	frameMover:SetScript("OnDragStop", function() if InCombatLockdown() then frameMover:StopMovingOrSizing() RefreshMover(frameMover) else StopMoving(frameMover) end end)
	frameMover:SetScript("OnShow", RefreshMover)
	frameMover:SetScript("OnEnter", function(self) self.hovered = true UpdateMoverVisual(self) end)
	frameMover:SetScript("OnLeave", function(self) self.hovered = false UpdateMoverVisual(self) end)

	frameMover.Text = frameMover:CreateFontString(nil, "OVERLAY")
	frameMover.Text:SetPoint("CENTER")
	frameMover.Text:SetFont(ZF.Media.Font, 12, "OUTLINE, SLUG")
	frameMover.Text:SetText(unit == "targettarget" and "Target of Target" or unit == "focustarget" and "Focus Target" or unit == "augmentation" and "Augmentation" or unit:gsub("^%l", string.upper))
	frameMover.Text:SetTextColor(255/255, 255/255, 255/255, 1)

	frameMover:SetScript("OnHide", function(self) if ZF.ACTIVE_MOVER == self then ZF:SetMoverSelection(nil) end end)

	GetMoverControlPanel()

	ZF.MOVERS[unit] = frameMover
	frameMover:Hide()
end

local ModeWindow

local function GetMoverModeWindow()
    if ModeWindow then return ModeWindow end
    ModeWindow = CreateFrame("Frame", "ZF_MoverModeWindow", UIParent, "BackdropTemplate")
    ModeWindow:SetSize(260, 90)
    ModeWindow:SetPoint("TOP", UIParent, "TOP", 0, -100)
    ModeWindow:SetFrameStrata("TOOLTIP")
    ModeWindow:SetBackdrop(ZF.BACKDROP)
    ModeWindow:SetBackdropColor(0, 0, 0, 0.9)
    ModeWindow:SetBackdropBorderColor(unpack(ZF.DesignerStyle.Palette.MoverBorder))
    ModeWindow:EnableMouse(true)

    local Instructions = ModeWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    Instructions:SetPoint("TOP", ModeWindow, "TOP", 0, -10)
    Instructions:SetWidth(240)
    Instructions:SetJustifyH("CENTER")
    Instructions:SetText("Click a mover to select it.\nClick arrows or drag to move.\nArrow keys nudge the selected mover by 0.1px.\nRight-click a mover for its settings.")

    local ExitButton = CreateFrame("Button", nil, ModeWindow, "UIPanelButtonTemplate")
    ExitButton:SetSize(80, 22)
    ExitButton:SetPoint("BOTTOM", ModeWindow, "BOTTOM", 0, 8)
    ExitButton:SetText("Exit")
    ExitButton:SetScript("OnClick", function() ZF:ToggleMovers() end)

    ModeWindow:EnableKeyboard(true)
    ModeWindow:SetPropagateKeyboardInput(true)
    ModeWindow:SetScript("OnKeyDown", function(self, key)
        if not ZF.ACTIVE_MOVER or InCombatLockdown() then return end
        local dx, dy = 0, 0
        if key == "LEFT" then dx = -ZF.DesignerStyle.Movers.NudgeStepFine
        elseif key == "RIGHT" then dx = ZF.DesignerStyle.Movers.NudgeStepFine
        elseif key == "UP" then dy = ZF.DesignerStyle.Movers.NudgeStepFine
        elseif key == "DOWN" then dy = -ZF.DesignerStyle.Movers.NudgeStepFine
        else return end
        self:SetPropagateKeyboardInput(false)
        NudgeMover(ZF.ACTIVE_MOVER, dx, dy)
    end)
    ModeWindow:SetScript("OnKeyUp", function(self) self:SetPropagateKeyboardInput(true) end)

    ModeWindow:Hide()
    return ModeWindow
end

function ZF:ToggleMovers()
	if InCombatLockdown() then ZF:PrettyPrint("Movers cannot be toggled while in combat.") return ZF.MOVERS_UNLOCKED end
	ZF.MOVERS_UNLOCKED = not ZF.MOVERS_UNLOCKED
	for _, mover in pairs(ZF.MOVERS or {}) do 
		mover:SetShown(ZF.MOVERS_UNLOCKED and (mover.unit ~= "augmentation" or ZF:IsAugmentationEvoker())) end
	if ZF.MOVERS_UNLOCKED then 
        ZF:EnterPartyPreview() 
        ZF:EnterBossPreview()
        ZF:EnterRaidPreview() 
    else 
        ZF:ExitPartyPreview()
        ZF:ExitBossPreview()
        ZF:ExitRaidPreview()
    end
	ZF:SetMainGUIShown(not ZF.MOVERS_UNLOCKED)
	GetMoverModeWindow():SetShown(ZF.MOVERS_UNLOCKED)
	if not ZF.MOVERS_UNLOCKED then 
        ZF:SetMoverSelection(nil) 
    end
    
	return ZF.MOVERS_UNLOCKED
end
