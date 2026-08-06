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
        for i, bossFrame in ipairs(ZF.BOSS_FRAMES) do
            if bossFrame.isUnitPreview then ZF:ApplyUnitPreviewContent(bossFrame, "boss" .. i)
            else ZF:UpdateUnitFrame(bossFrame, "boss" .. i) end
        end
        ZF:LayoutBossFrames()
    elseif frameMover.unit == "augmentation" then
        ZF:LayoutAugmentationRaidFrames()
    elseif frameMover.unit == "party" or frameMover.unit == "raid" then
        ZF:LayoutGroupFrames(frameMover.unit)
        if frameMover.unit == "raid" then ZF:RaidLayoutPreviewFrame() end
    else
        local unitFrame = ResolveMoverUnitFrame(frameMover)
        if unitFrame and unitFrame.isUnitPreview then ZF:ApplyUnitPreviewContent(unitFrame, frameMover.unit)
        else ZF:UpdateUnitFrame(unitFrame, frameMover.unit) end
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
local GetMoverModeWindow

local UNIT_PREVIEW_FUNCS = {
	target = {enter = "EnterTargetPreview", exit = "ExitTargetPreview"},
	focus = {enter = "EnterFocusPreview", exit = "ExitFocusPreview"},
	focustarget = {enter = "EnterFocusTargetPreview", exit = "ExitFocusTargetPreview"},
	pet = {enter = "EnterPetPreview", exit = "ExitPetPreview"},
	targettarget = {enter = "EnterTargetTargetPreview", exit = "ExitTargetTargetPreview"},
	party = {enter = "EnterPartyPreview", exit = "ExitPartyPreview"},
	raid = {enter = "EnterRaidPreview", exit = "ExitRaidPreview"},
	boss = {enter = "EnterBossPreview", exit = "ExitBossPreview"},
}

function ZF:ApplyMoverPreviewMode()
	if not ZF.MOVERS_UNLOCKED then return end
	local PreviewMode = ZF.db.profile.General.MoverPreviewMode or "Always"
	for _, funcs in pairs(UNIT_PREVIEW_FUNCS) do ZF[funcs.exit](ZF) end
	if PreviewMode == "Always" then
		for _, funcs in pairs(UNIT_PREVIEW_FUNCS) do ZF[funcs.enter](ZF) end
	elseif PreviewMode == "Hybrid" and ZF.ACTIVE_MOVER then
		local funcs = UNIT_PREVIEW_FUNCS[ZF.ACTIVE_MOVER.unit]
		if funcs then ZF[funcs.enter](ZF) end
	end
end

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

local function CreateMoverControlBoxes(core)
	local XBox = CreateFrame("EditBox", nil, core, "BackdropTemplate")
	XBox:SetSize(40, 14)
	XBox:SetPoint("CENTER", core, "CENTER", -22, -2)
	XBox:SetAutoFocus(false)
	XBox:SetFontObject("GameFontHighlightSmall")
	XBox:SetBackdrop(ZF.BACKDROP)
	XBox:SetBackdropColor(0, 0, 0, 0.6)
	XBox:SetBackdropBorderColor(0, 0, 0, 1)
	XBox:SetScript("OnChar", FilterNumericInput)
	XBox:SetScript("OnEnterPressed", function(self) if ZF.ACTIVE_MOVER then CommitCoordinateBox(self, ZF.ACTIVE_MOVER, 3) end end)
	XBox:SetScript("OnEditFocusLost", function(self) if ZF.ACTIVE_MOVER then CommitCoordinateBox(self, ZF.ACTIVE_MOVER, 3) end end)
	XBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	core.XBox = XBox

	local YBox = CreateFrame("EditBox", nil, core, "BackdropTemplate")
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
	YBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	core.YBox = YBox
end

local miniWidgetCounter = 0
local function NextMiniWidgetName(prefix)
	miniWidgetCounter = miniWidgetCounter + 1
	return "ZF_MoverPanel" .. prefix .. miniWidgetCounter
end

local function CreateMiniEditBox(parent, width, height, onCommit)
	local editBox = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
	editBox:SetSize(width, height)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject("GameFontHighlightSmall")
	editBox:SetBackdrop(ZF.BACKDROP)
	editBox:SetBackdropColor(0, 0, 0, 0.6)
	editBox:SetBackdropBorderColor(0, 0, 0, 1)
	editBox:SetScript("OnChar", FilterNumericInput)
	local function Commit(self)
		self:ClearFocus()
		if InCombatLockdown() then return end
		local value = tonumber(self:GetText())
		if value and onCommit then onCommit(value) end
	end
	editBox:SetScript("OnEnterPressed", Commit)
	editBox:SetScript("OnEditFocusLost", Commit)
	editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	return editBox
end

local function CreateMiniCheckbox(parent, label, onToggle)
	local checkbox = CreateFrame("CheckButton", NextMiniWidgetName("Checkbox"), parent, "UICheckButtonTemplate")
	checkbox:SetSize(20, 20)
	local text = _G[checkbox:GetName() .. "Text"]
	if text then
		text:SetText(label)
		text:SetFontObject("GameFontHighlightSmall")
	end
	checkbox.Text = text
	checkbox:SetScript("OnClick", function(self)
		if InCombatLockdown() then return end
		if onToggle then onToggle(self:GetChecked() and true or false) end
	end)
	return checkbox
end

local miniDropdowns = {}
local miniDropdownStrataHooked = false
local function EnsureMiniDropdownStrataHook()
	if miniDropdownStrataHooked then return end
	miniDropdownStrataHooked = true
	hooksecurefunc("ToggleDropDownMenu", function()
		if not (UIDROPDOWNMENU_OPEN_MENU and miniDropdowns[UIDROPDOWNMENU_OPEN_MENU]) then return end
		for _, list in ipairs({DropDownList1, DropDownList2}) do
			if list then
				list:SetFrameStrata("TOOLTIP")
				list:SetFrameLevel(200)
			end
		end
	end)
end

local function CreateMiniDropdown(parent, width, list, order, onSelect)
	local dropdown = CreateFrame("Frame", NextMiniWidgetName("Dropdown"), parent, "UIDropDownMenuTemplate")
	miniDropdowns[dropdown] = true
	EnsureMiniDropdownStrataHook()
	UIDropDownMenu_SetWidth(dropdown, width)
	UIDropDownMenu_Initialize(dropdown, function(_, level)
		local resolvedList, resolvedOrder = list, order
		if type(list) == "function" then
			resolvedList, resolvedOrder = list(ZF.ACTIVE_MOVER and ZF.ACTIVE_MOVER.unit)
		end
		for _, key in ipairs(resolvedOrder) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = resolvedList[key]
			info.value = key
			info.func = function()
				if InCombatLockdown() then return end
				UIDropDownMenu_SetSelectedValue(dropdown, key)
				UIDropDownMenu_SetText(dropdown, resolvedList[key])
				if onSelect then onSelect(key) end
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end)
	return dropdown
end

local function CreateMiniSlider(parent, width, minValue, maxValue, step, onCommit)
    local slider = CreateFrame("Slider", NextMiniWidgetName("Slider"), parent, "OptionsSliderTemplate")
    slider:SetWidth(width)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    _G[slider:GetName() .. "Low"]:SetText("")
    _G[slider:GetName() .. "High"]:SetText("")
    _G[slider:GetName() .. "Text"]:SetText("")
    
    slider:SetScript("OnValueChanged", function(self, value)
		if self.mcpSuppress or InCombatLockdown() then return end
		if not ControlPanel.isDraggingSlider then
			ControlPanel.isDraggingSlider = true
			local left, top = ControlPanel:GetLeft(), ControlPanel:GetTop()
			if left and top then
				ControlPanel:ClearAllPoints()
				ControlPanel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
			end
		end
		if onCommit then onCommit(value) end
	end)
	slider:SetScript("OnMouseUp", function()
		ControlPanel.isDraggingSlider = false
		MoverControlPanel()
	end)
    return slider
end

local ROW_SPACING = 4

local function IsGridUnit(unit)
	return unit == "boss" or unit == "party" or unit == "raid" or unit == "augmentation"
end

local function IsGroupUnit(unit)
	return unit == "party" or unit == "raid" or unit == "augmentation"
end

local function IsPartyUnit(unit)
	return unit == "party"
end

local function IsRaidUnit(unit)
	return unit == "raid"
end

local function IsAugmentationUnit(unit)
	return unit == "augmentation"
end

local function IsAnyUnit()
	return true
end

local CONTROL_PANEL_TABS = {
	{ key = "Layout", label = "Layout", isRelevant = IsAnyUnit },
	{ key = "Order", label = "Order", isRelevant = IsGridUnit },
	{ key = "Groups", label = "Groups", isRelevant = IsRaidUnit },
}

local function AddControlPanelRow(tabKey, height, isVisibleFn)
	local tab = ControlPanel.tabs[tabKey]
	local row = CreateFrame("Frame", nil, tab.page)
	row:SetHeight(height)
	row.mcpHeight = height
	row.mcpIsVisible = isVisibleFn
	table.insert(tab.rows, row)
	row:Hide()
	return row
end

local function RefreshControlPanelTabs(unit)
	local panel = ControlPanel
	for _, tabDef in ipairs(CONTROL_PANEL_TABS) do
		local tab = panel.tabs[tabDef.key]
		local relevant = tabDef.isRelevant(unit)
		tab.button:SetShown(relevant)
	end
		if panel.activeTab and not panel.tabs[panel.activeTab].button:IsShown() then
		panel.activeTab = nil
	end

	local FrameDB = ZF.db.profile.Units[unit].Frame
	for _, tabDef in ipairs(CONTROL_PANEL_TABS) do
		local tab = panel.tabs[tabDef.key]
		if tabDef.key == panel.activeTab then
			local yOffset = 0
			for _, row in ipairs(tab.rows) do
				local visible = not row.mcpIsVisible or row.mcpIsVisible(unit)
				if visible then
					row:ClearAllPoints()
					row:SetPoint("TOPLEFT", tab.page, "TOPLEFT", 0, -yOffset)
					row:SetPoint("TOPRIGHT", tab.page, "TOPRIGHT", 0, -yOffset)
					row:Show()
					if row.mcpRefresh then row.mcpRefresh(FrameDB, unit) end
					yOffset = yOffset + row.mcpHeight + ROW_SPACING
				else
					row:Hide()
				end
			end
			local pageHeight = yOffset > 0 and (yOffset - ROW_SPACING) or 0
			tab.page:SetHeight(math.max(pageHeight, 0.01))
			tab.page:Show()
			tab.button:SetBackdropBorderColor(unpack(ZF.DesignerStyle.Palette.MoverBorder))
		else
			tab.page:Hide()
			tab.button:SetBackdropBorderColor(0, 0, 0, 1)
		end
	end
end

local function CreateLabel(parent, text)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetJustifyH("LEFT")
	label:SetText(text)
	return label
end

local function CommitFrameField(key, value)
	if not ZF.ACTIVE_MOVER then return end
	ZF.db.profile.Units[ZF.ACTIVE_MOVER.unit].Frame[key] = value
	RelayoutUnit(ZF.ACTIVE_MOVER)
	RefreshMover(ZF.ACTIVE_MOVER)
	MoverControlPanel()
end

local function CommitLayoutField(layoutIndex, value)
	if not ZF.ACTIVE_MOVER then return end
	ZF.db.profile.Units[ZF.ACTIVE_MOVER.unit].Frame.Layout[layoutIndex] = value
	RelayoutUnit(ZF.ACTIVE_MOVER)
	RefreshMover(ZF.ACTIVE_MOVER)
	MoverControlPanel()
end

local FIELD_ROW_HEIGHT = 20
local DROPDOWN_ROW_HEIGHT = 32

local AnchorParentFrameLabels = {
	["None"] = "None",
	["ZF_Player"] = "Player",
	["ZF_Target"] = "Target",
	["ZF_Focus"] = "Focus",
	["ZF_Pet"] = "Pet",
	["ZF_TargetTarget"] = "Target's Target",
	["ZF_FocusTarget"] = "Focus's Target",
}
local AnchorParentFrameOrder = {"None", "ZF_Player", "ZF_Target", "ZF_Focus", "ZF_Pet", "ZF_TargetTarget", "ZF_FocusTarget"}

local function AnchorParentList(unit)
	local ownFrame = ZF:FetchFrameName(unit)
	local order = {}
	for _, key in ipairs(AnchorParentFrameOrder) do
		if key ~= ownFrame then order[#order + 1] = key end
	end
	return AnchorParentFrameLabels, order
end

local function CreateFrameLayoutRows()

    local dimMin, dimMax, dimStep = unpack(ZF.DesignerStyle.Sliders.Dimension)
   	local sizeSliderRow = AddControlPanelRow("Layout", 20)
	local WidthSlider = CreateMiniSlider(sizeSliderRow, 80, 20, 500, 1, function(value) CommitFrameField("Width", value) end)
	WidthSlider:SetPoint("LEFT", sizeSliderRow, "LEFT", 4, 0)
	local HeightSlider = CreateMiniSlider(sizeSliderRow, 80, 20, 500, 1, function(value) CommitFrameField("Height", value) end)
	HeightSlider:SetPoint("LEFT", WidthSlider, "RIGHT", 12, 0)
	sizeSliderRow.mcpRefresh = function(FrameDB)
		WidthSlider.mcpSuppress = true
		WidthSlider:SetValue(FrameDB.Width)
		WidthSlider.mcpSuppress = false
		HeightSlider.mcpSuppress = true
		HeightSlider:SetValue(FrameDB.Height)
		HeightSlider.mcpSuppress = false
	end

	local sizeRow = AddControlPanelRow("Layout", FIELD_ROW_HEIGHT)
	local WidthLabel = CreateLabel(sizeRow, "W")
	WidthLabel:SetPoint("LEFT", sizeRow, "LEFT", 4, 0)
	local WidthBox = CreateMiniEditBox(sizeRow, 50, 16, function(value) CommitFrameField("Width", value) end)
	WidthBox:SetPoint("LEFT", WidthLabel, "RIGHT", 4, 0)

	local HeightLabel = CreateLabel(sizeRow, "H")
	HeightLabel:SetPoint("LEFT", WidthBox, "RIGHT", 12, 0)
	local HeightBox = CreateMiniEditBox(sizeRow, 50, 16, function(value) CommitFrameField("Height", value) end)
	HeightBox:SetPoint("LEFT", HeightLabel, "RIGHT", 4, 0)

	sizeRow.mcpRefresh = function(FrameDB)
		if not WidthBox:HasFocus() then WidthBox:SetText(string.format("%.0f", FrameDB.Width)) end
		if not HeightBox:HasFocus() then HeightBox:SetText(string.format("%.0f", FrameDB.Height)) end
	end

	local anchorFromRow = AddControlPanelRow("Layout", DROPDOWN_ROW_HEIGHT)
	local AnchorFromLabel = CreateLabel(anchorFromRow, "From")
	AnchorFromLabel:SetPoint("LEFT", anchorFromRow, "LEFT", 4, 2)
	local AnchorFromDropdown = CreateMiniDropdown(anchorFromRow, 85, ZF.GUIBuilders.AnchorPoints[1], ZF.GUIBuilders.AnchorPoints[2], function(value) CommitLayoutField(1, value) end)
	AnchorFromDropdown:SetPoint("LEFT", AnchorFromLabel, "RIGHT", -4, -2)
	anchorFromRow.mcpRefresh = function(FrameDB)
		UIDropDownMenu_SetSelectedValue(AnchorFromDropdown, FrameDB.Layout[1])
		UIDropDownMenu_SetText(AnchorFromDropdown, ZF.GUIBuilders.AnchorPoints[1][FrameDB.Layout[1]])
	end

	local anchorToRow = AddControlPanelRow("Layout", DROPDOWN_ROW_HEIGHT)
	local AnchorToLabel = CreateLabel(anchorToRow, "To")
	AnchorToLabel:SetPoint("LEFT", anchorToRow, "LEFT", 4, 2)
	local AnchorToDropdown = CreateMiniDropdown(anchorToRow, 85, ZF.GUIBuilders.AnchorPoints[1], ZF.GUIBuilders.AnchorPoints[2], function(value) CommitLayoutField(2, value) end)
	AnchorToDropdown:SetPoint("LEFT", AnchorToLabel, "RIGHT", -4, -2)
	anchorToRow.mcpRefresh = function(FrameDB)
		UIDropDownMenu_SetSelectedValue(AnchorToDropdown, FrameDB.Layout[2])
		UIDropDownMenu_SetText(AnchorToDropdown, ZF.GUIBuilders.AnchorPoints[1][FrameDB.Layout[2]])
	end

	local anchorParentRow = AddControlPanelRow("Layout", DROPDOWN_ROW_HEIGHT, function(unit)
		return ZF.db.profile.Units[unit].Frame.AnchorToFrame ~= nil
	end)
	local AnchorParentLabel = CreateLabel(anchorParentRow, "Parent")
	AnchorParentLabel:SetPoint("LEFT", anchorParentRow, "LEFT", 4, 2)
	local AnchorParentDropdown = CreateMiniDropdown(anchorParentRow, 115, AnchorParentList, nil, function(value)
		CommitFrameField("AnchorToFrame", value)
		CommitLayoutField(3, 0)
		CommitLayoutField(4, 0)
	end)
	AnchorParentDropdown:SetPoint("LEFT", AnchorParentLabel, "RIGHT", -4, -2)
	anchorParentRow.mcpRefresh = function(FrameDB, unit)
		local list = AnchorParentList(unit)
		UIDropDownMenu_SetSelectedValue(AnchorParentDropdown, FrameDB.AnchorToFrame)
		UIDropDownMenu_SetText(AnchorParentDropdown, list[FrameDB.AnchorToFrame])
	end

	local strataRow = AddControlPanelRow("Layout", DROPDOWN_ROW_HEIGHT)
	local StrataLabel = CreateLabel(strataRow, "Strata")
	StrataLabel:SetPoint("LEFT", strataRow, "LEFT", 4, 2)
	local StrataDropdown = CreateMiniDropdown(strataRow, 90, ZF.GUIBuilders.FrameStrataList[1], ZF.GUIBuilders.FrameStrataList[2], function(value) CommitFrameField("FrameStrata", value) end)
	StrataDropdown:SetPoint("LEFT", StrataLabel, "RIGHT", -4, -2)
	strataRow.mcpRefresh = function(FrameDB)
		UIDropDownMenu_SetSelectedValue(StrataDropdown, FrameDB.FrameStrata)
		UIDropDownMenu_SetText(StrataDropdown, ZF.GUIBuilders.FrameStrataList[1][FrameDB.FrameStrata])
	end
end

local RaidGrowthDirectionList = {
	{
		["RIGHT_DOWN"] = "Right to Left, then Down",
		["RIGHT_UP"] = "Right to Left, then Up",
		["LEFT_DOWN"] = "Left to Right, then Down",
		["LEFT_UP"] = "Left to Right, then Up",
		["UP_RIGHT"] = "Top to Bottom, then Right",
		["UP_LEFT"] = "Top to Bottom, then Left",
		["DOWN_RIGHT"] = "Bottom to Top, then Right",
		["DOWN_LEFT"] = "Bottom to Top, then Left",
	},
	{"RIGHT_DOWN", "RIGHT_UP", "LEFT_DOWN", "LEFT_UP", "UP_RIGHT", "UP_LEFT", "DOWN_RIGHT", "DOWN_LEFT"},
}
local PartyGrowthDirectionList = {
	{["UP"] = "Up", ["DOWN"] = "Down", ["LEFT"] = "Left", ["RIGHT"] = "Right"},
	{"UP", "DOWN", "LEFT", "RIGHT"},
}
local BossGrowthDirectionList = {
	{["UP"] = "Up", ["DOWN"] = "Down"},
	{"UP", "DOWN"},
}

local function GrowthDirectionListFor(unit)
	if unit == "raid" or unit == "augmentation" then return RaidGrowthDirectionList[1], RaidGrowthDirectionList[2] end
	if unit == "party" then return PartyGrowthDirectionList[1], PartyGrowthDirectionList[2] end
	return BossGrowthDirectionList[1], BossGrowthDirectionList[2]
end

local function CreateGridUnitRows()
	local growthRow = AddControlPanelRow("Order", DROPDOWN_ROW_HEIGHT, IsGridUnit)
	local GrowthLabel = CreateLabel(growthRow, "Growth")
	GrowthLabel:SetPoint("LEFT", growthRow, "LEFT", 4, 2)
	local GrowthDropdown = CreateMiniDropdown(growthRow, 85, GrowthDirectionListFor, nil, function(value) CommitFrameField("GrowthDirection", value) end)
	GrowthDropdown:SetPoint("LEFT", GrowthLabel, "RIGHT", -4, -2)
	growthRow.mcpRefresh = function(FrameDB, unit)
		local list = GrowthDirectionListFor(unit)
		UIDropDownMenu_SetSelectedValue(GrowthDropdown, FrameDB.GrowthDirection)
		UIDropDownMenu_SetText(GrowthDropdown, list[FrameDB.GrowthDirection])
	end

	
    local SpacingSliderRow= AddControlPanelRow("Order", 20, IsGridUnit)
    local SpacingSlider = CreateMiniSlider(SpacingSliderRow, 180, -1, 100, 0.1, function(value) CommitLayoutField(5, value) end)
    SpacingSlider:SetPoint("LEFT", SpacingSliderRow, "LEFT", 4, 0)
    SpacingSliderRow.mcpRefresh = function(FrameDB)
        SpacingSlider.mcpSuppress = true
        SpacingSlider:SetValue(FrameDB.Layout[5])
        SpacingSlider.mcpSuppress = false
    end

    local SpacingRow = AddControlPanelRow("Order", FIELD_ROW_HEIGHT, IsGridUnit)
	local SpacingLabel = CreateLabel(SpacingRow, "Spacing")
	SpacingLabel:SetPoint("LEFT", SpacingRow, "LEFT", 4, 0)
	local SpacingBox = CreateMiniEditBox(SpacingRow, 50, 16, function(value) CommitLayoutField(5, value) end)
	SpacingBox:SetPoint("LEFT", SpacingLabel, "RIGHT", 4, 0)
	SpacingRow.mcpRefresh = function(FrameDB)
		if not SpacingBox:HasFocus() then SpacingBox:SetText(string.format("%.1f", FrameDB.Layout[5])) end
	end

	local UnitsPerColumnSliderRow = AddControlPanelRow("Order", 20, IsAugmentationUnit)
	local UnitsPerColumnSlider = CreateMiniSlider(UnitsPerColumnSliderRow, 180, 1, ZF.MAX_RAID_FRAMES, 1, function(value) CommitFrameField("UnitsPerColumn", value) end)
	UnitsPerColumnSlider:SetPoint("LEFT", UnitsPerColumnSliderRow, "LEFT", 4, 0)
	UnitsPerColumnSliderRow.mcpRefresh = function(FrameDB)
		UnitsPerColumnSlider.mcpSuppress = true
		UnitsPerColumnSlider:SetValue(FrameDB.UnitsPerColumn or ZF.MAX_RAID_FRAMES_PER_GROUP)
		UnitsPerColumnSlider.mcpSuppress = false
	end

	local UnitsPerColumnRow = AddControlPanelRow("Order", FIELD_ROW_HEIGHT, IsAugmentationUnit)
	local UnitsPerColumnLabel = CreateLabel(UnitsPerColumnRow, "Per Row")
	UnitsPerColumnLabel:SetPoint("LEFT", UnitsPerColumnRow, "LEFT", 4, 0)
	local UnitsPerColumnBox = CreateMiniEditBox(UnitsPerColumnRow, 50, 16, function(value) CommitFrameField("UnitsPerColumn", value) end)
	UnitsPerColumnBox:SetPoint("LEFT", UnitsPerColumnLabel, "RIGHT", 4, 0)
	UnitsPerColumnRow.mcpRefresh = function(FrameDB)
		if not UnitsPerColumnBox:HasFocus() then UnitsPerColumnBox:SetText(string.format("%.0f", FrameDB.UnitsPerColumn or ZF.MAX_RAID_FRAMES_PER_GROUP)) end
	end
end

local RaidSortByList = {
	{["GROUP"] = "Group", ["INDEX"] = "Index"},
	{"GROUP", "INDEX"},
}
local AugmentationSortByList = {
	{["NAMELIST"] = "Player List", ["NAME"] = "Name"},
	{"NAMELIST", "NAME"},
}
local PartySortByList = {
	{["ROLE"] = "Role", ["INDEX"] = "Index", ["NAME"] = "Name"},
	{"ROLE", "INDEX", "NAME"},
}
local RoleOrderList = {
	{["TANK"] = "Tank", ["HEALER"] = "Healer", ["DAMAGER"] = "DPS"},
	{"TANK", "HEALER", "DAMAGER"},
}

local function SortByListFor(unit)
	if unit == "raid" then return RaidSortByList[1], RaidSortByList[2] end
	if unit == "augmentation" then return AugmentationSortByList[1], AugmentationSortByList[2] end
	return PartySortByList[1], PartySortByList[2]
end

local function CommitRoleOrder(index, value)
	if not ZF.ACTIVE_MOVER then return end
	ZF.db.profile.Units[ZF.ACTIVE_MOVER.unit].Frame.RoleOrder[index] = value
	RelayoutUnit(ZF.ACTIVE_MOVER)
	RefreshMover(ZF.ACTIVE_MOVER)
	MoverControlPanel()
end

local function CommitGroupToggle(index, value)
    if not ZF.ACTIVE_MOVER then return end
    local FrameDB = ZF.db.profile.Units[ZF.ACTIVE_MOVER.unit].Frame
    FrameDB.Groups = FrameDB.Groups or {}
    FrameDB.Groups[index] = value
    RelayoutUnit(ZF.ACTIVE_MOVER)
    RefreshMover(ZF.ACTIVE_MOVER)
    MoverControlPanel()
end

local function CreateGroupUnitRows()
	local sortByRow = AddControlPanelRow("Order", DROPDOWN_ROW_HEIGHT, IsGroupUnit)
	local SortByLabel = CreateLabel(sortByRow, "Sort")
	SortByLabel:SetPoint("LEFT", sortByRow, "LEFT", 4, 2)
	local SortByDropdown = CreateMiniDropdown(sortByRow, 85, SortByListFor, nil, function(value) CommitFrameField("SortBy", value) end)
	SortByDropdown:SetPoint("LEFT", SortByLabel, "RIGHT", -4, -2)
	sortByRow.mcpRefresh = function(FrameDB, unit)
		local list = SortByListFor(unit)
		local displayValue = (unit == "augmentation" and FrameDB.SortBy ~= "NAME") and "NAMELIST" or FrameDB.SortBy
		UIDropDownMenu_SetSelectedValue(SortByDropdown, displayValue)
		UIDropDownMenu_SetText(SortByDropdown, list[displayValue])
	end

	for i = 1, 3 do
		local roleOrderRow = AddControlPanelRow("Order", DROPDOWN_ROW_HEIGHT, IsPartyUnit)
		local RoleOrderLabel = CreateLabel(roleOrderRow, "Order " .. i)
		RoleOrderLabel:SetPoint("LEFT", roleOrderRow, "LEFT", 4, 2)
		local RoleOrderDropdown = CreateMiniDropdown(roleOrderRow, 70, RoleOrderList[1], RoleOrderList[2], function(value) CommitRoleOrder(i, value) end)
		RoleOrderDropdown:SetPoint("LEFT", RoleOrderLabel, "RIGHT", -4, -2)
		roleOrderRow.mcpRefresh = function(FrameDB)
			if FrameDB.SortBy ~= "ROLE" then
				UIDropDownMenu_DisableDropDown(RoleOrderDropdown)
			else
				UIDropDownMenu_EnableDropDown(RoleOrderDropdown)
			end
			UIDropDownMenu_SetSelectedValue(RoleOrderDropdown, FrameDB.RoleOrder[i])
			UIDropDownMenu_SetText(RoleOrderDropdown, RoleOrderList[1][FrameDB.RoleOrder[i]])
		end
	end
end

local function CreateRaidGroupRows()
    local AutoAdjustRow = AddControlPanelRow("Groups", FIELD_ROW_HEIGHT)
    local AutoAdjustCheckBox = CreateMiniCheckbox(AutoAdjustRow, "Groups per Difficulty", function(value) CommitFrameField("AutoAdjustGroups", value) end)
    AutoAdjustCheckBox:SetPoint("LEFT", AutoAdjustRow, "LEFT", 4, 0)
    AutoAdjustRow.mcpRefresh = function(FrameDB)
        AutoAdjustCheckBox:SetChecked(FrameDB.AutoAdjustGroups)
     end

     local groupRows = {}
     local PER_ROW = 4
     for i = 1, ZF.MAX_RAID_GROUPS do
        local rowIndex = math.ceil(i / PER_ROW)
        local colIndex = (i - 1) % PER_ROW
        if colIndex == 0 then
            groupRows[rowIndex] = AddControlPanelRow("Groups", FIELD_ROW_HEIGHT)
            groupRows[rowIndex].mcpCheckboxes = {}
        end
        local row = groupRows[rowIndex]
        local checkbox = CreateMiniCheckbox(row, "G" .. i, function(value) CommitGroupToggle(i, value) end)
        if colIndex == 0 then
            checkbox:SetPoint("LEFT", row, "LEFT", 4, 0)
        else
            checkbox:SetPoint("LEFT", row.mcpLastCheckbox, "RIGHT", 24, 0)
        end
        row.mcpLastCheckbox = checkbox
        table.insert(row.mcpCheckboxes, {checkbox = checkbox, index = i})
    end
    for _, row in pairs(groupRows) do
        row.mcpRefresh = function(FrameDB)
            FrameDB.Groups = FrameDB.Groups or {}
            for _, entry in ipairs(row.mcpCheckboxes) do
                entry.checkbox:SetChecked(FrameDB.Groups[entry.index])
                if FrameDB.AutoAdjustGroups then entry.checkbox:Disable() else entry.checkbox:Enable() end
            end
        end
    end
end



local function GetMoverControlPanel()
    if ControlPanel then return ControlPanel end
    local coreHeight = ZF.DesignerStyle.Movers.ControlPanelCoreHeight
    local coreWidth = ZF.DesignerStyle.Movers.ControlPanelCoreWidth
    local tabStripWidth = ZF.DesignerStyle.Movers.TabStripWidth
    local tabButtonHeight = ZF.DesignerStyle.Movers.TabButtonHeight
    local tabPageWidth = ZF.DesignerStyle.Movers.TabPageWidth
    ControlPanel = CreateFrame("Frame", "ZF_MoverControlPanel", UIParent, "BackdropTemplate")
    ControlPanel:SetSize(coreWidth, coreHeight)
    ControlPanel:SetFrameStrata("TOOLTIP")
    ControlPanel:SetClampedToScreen(true)
    ControlPanel:SetBackdrop(ZF.BACKDROP)
    ControlPanel:SetBackdropColor(0, 0, 0, .9)
    ControlPanel:SetBackdropBorderColor(unpack(ZF.DesignerStyle.Palette.MoverBorder))
	ControlPanel:EnableMouse(true)
	ControlPanel:SetMovable(true)
	ControlPanel:RegisterForDrag("LeftButton")
	ControlPanel:SetScript("OnDragStart", function(self)
		if not ZF.db.profile.General.MoverPanelDetached or InCombatLockdown() then return end
		self:StartMoving()
	end)
	ControlPanel:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local left, top = self:GetLeft(), self:GetTop()
		if left and top then ZF.db.profile.General.MoverPanelPosition = {left, top} end
	end)
	ControlPanel.tabs = {}

	local TabStrip = CreateFrame("Frame", nil, ControlPanel)
	TabStrip:SetPoint("TOPLEFT", ControlPanel, "TOPRIGHT", 2, 0)
	TabStrip:SetSize(tabStripWidth, #CONTROL_PANEL_TABS * (tabButtonHeight + 2))
	ControlPanel.TabStrip = TabStrip

	for index, tabDef in ipairs(CONTROL_PANEL_TABS) do
		local page = CreateFrame("Frame", nil, ControlPanel, "BackdropTemplate")
		page:SetPoint("TOPLEFT", TabStrip, "TOPRIGHT", 2, 0)
		page:SetWidth(tabPageWidth)
		page:SetHeight(0.01)
		page:SetBackdrop(ZF.BACKDROP)
		page:SetBackdropColor(0, 0, 0, .9)
		page:SetBackdropBorderColor(unpack(ZF.DesignerStyle.Palette.MoverBorder))
		page:Hide()

		local button = CreateFrame("Button", nil, TabStrip, "BackdropTemplate")
		button:SetSize(tabStripWidth, tabButtonHeight)
		button:SetPoint("TOP", TabStrip, "TOP", 0, -((index - 1) * (tabButtonHeight + 2)))
		button:SetBackdrop(ZF.BACKDROP)
		button:SetBackdropColor(0, 0, 0, .9)
		button:SetBackdropBorderColor(0, 0, 0, 1)
		local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		text:SetPoint("CENTER")
		text:SetText(tabDef.label)
		button:SetScript("OnClick", function()
			if InCombatLockdown() then return end
			if ControlPanel.activeTab == tabDef.key then
				ControlPanel.activeTab = nil
			else
				ControlPanel.activeTab = tabDef.key
			end
			MoverControlPanel()
		end)

		ControlPanel.tabs[tabDef.key] = { page = page, button = button, rows = {} }
	end

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
	CreateFrameLayoutRows()
	CreateGridUnitRows()
	CreateGroupUnitRows()
	CreateRaidGroupRows()
    ControlPanel:Hide()
    return ControlPanel
end

MoverControlPanel = function()
    local panel = GetMoverControlPanel()
    if not ZF.ACTIVE_MOVER then panel:Hide() return end
    if ZF.db.profile.General.MoverPanelDetached then
        if not panel.detachedPositionApplied then
            local pos = ZF.db.profile.General.MoverPanelPosition
            panel:ClearAllPoints()
            if pos then
                panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos[1], pos[2])
            else
                panel:SetPoint("TOP", GetMoverModeWindow(), "BOTTOM", 0, -8)
            end
            panel.detachedPositionApplied = true
        end
    elseif not panel.isDraggingSlider then
        panel:ClearAllPoints()
        panel:SetPoint("TOP", ZF.ACTIVE_MOVER, "BOTTOM", 0, -4)
        panel.detachedPositionApplied = false
    end
    local FrameDB = ZF.db.profile.Units[ZF.ACTIVE_MOVER.unit].Frame
    if not panel.XBox:HasFocus() then panel.XBox:SetText(string.format("%.1f", FrameDB.Layout[3])) end
    if not panel.YBox:HasFocus() then panel.YBox:SetText(string.format("%.1f", FrameDB.Layout[4])) end
    RefreshControlPanelTabs(ZF.ACTIVE_MOVER.unit)
    panel:Show()
end

function ZF:SetMoverSelection(frameMover)
    if not frameMover and not ZF.ACTIVE_MOVER then return end
    if ControlPanel then ControlPanel.isDraggingSlider = false end
    if ZF.db.profile.General.MoverPreviewMode == "Hybrid" then
        local prevFuncs = ZF.ACTIVE_MOVER and UNIT_PREVIEW_FUNCS[ZF.ACTIVE_MOVER.unit]
        if prevFuncs and ZF.ACTIVE_MOVER ~= frameMover then ZF[prevFuncs.exit](ZF) end
        local nextFuncs = frameMover and UNIT_PREVIEW_FUNCS[frameMover.unit]
        if nextFuncs then ZF[nextFuncs.enter](ZF) end
    end
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

local MOVER_BASE_LEVEL = (100)
local nextMoverBack = MOVER_BASE_LEVEL - 1

local function GetOverlappingMover(frameMover)
	local overLapping = {}
	local left, right, top, bottom = frameMover:GetLeft(), frameMover:GetRight(), frameMover:GetTop(), frameMover:GetBottom()
	if not (left and right and top and bottom) then return overLapping end
	for _, other in pairs(ZF.MOVERS or {}) do
		if other ~= frameMover and other:IsShown() then
			local oLeft, oRight, oTop, oBottom = other:GetLeft(), other:GetRight(), other:GetTop(), other:GetBottom()
			if oLeft and left < oRight and right > oLeft and bottom <oTop and top > oBottom then
				overLapping[#overLapping +1] = other
			end
		end
	end
	return overLapping
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
	frameMover:SetFrameLevel(MOVER_BASE_LEVEL)
	frameMover:SetMovable(true)
	frameMover:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	frameMover:RegisterForDrag("LeftButton")
	frameMover:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			if ZF.MOVERS_UNLOCKED then ZF:ToggleMovers() end
			ZF:OpenGUIToUnit(unit)
		elseif button == "LeftButton" then
			if self == ZF.ACTIVE_MOVER then
				local overLapping = GetOverlappingMover(self)
				if #overLapping > 0 then
					local topOther, topLevel = nil, -math.huge
					for _, other in ipairs(overLapping) do
						local lvl = other:GetFrameLevel()
						if lvl > topLevel then topOther, topLevel = other, lvl end
					end
					self:SetFrameLevel(nextMoverBack)
					nextMoverBack = nextMoverBack - 1
					ZF:SetMoverSelection(topOther)
					return
				end
			end
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

function GetMoverModeWindow()
    if ModeWindow then return ModeWindow end
    ModeWindow = CreateFrame("Frame", "ZF_MoverModeWindow", UIParent, "BackdropTemplate")
    ModeWindow:SetSize(260, 185)
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
    Instructions:SetText("Click a frame to select it.\nDrag a frame to move it.\nPress arrow buttons to nudge by 1px.\nArrow keys nudge by 0.1px.\nRight-click a frame for its settings.")

    local PreviewModeLabels = { None = "None", Always = "Always", Hybrid = "Hybrid (Selected)" }
    local PreviewModeOrder = { "None", "Always", "Hybrid" }

    local PreviewLabel = ModeWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    PreviewLabel:SetPoint("TOP", Instructions, "BOTTOM", 0, -10)
    PreviewLabel:SetText("Preview Bars")

    local PreviewDropdown = CreateMiniDropdown(ModeWindow, 130, PreviewModeLabels, PreviewModeOrder, function(value) ZF.db.profile.General.MoverPreviewMode = value ZF:ApplyMoverPreviewMode() end)
    PreviewDropdown:SetPoint("TOP", PreviewLabel, "BOTTOM", -4, -2)
    UIDropDownMenu_SetSelectedValue(PreviewDropdown, ZF.db.profile.General.MoverPreviewMode)
    UIDropDownMenu_SetText(PreviewDropdown, PreviewModeLabels[ZF.db.profile.General.MoverPreviewMode])

	local DetachCheckbox = CreateFrame("CheckButton", nil, ModeWindow, "UICheckButtonTemplate")
    DetachCheckbox:SetSize(20, 20)
    DetachCheckbox:SetPoint("TOPLEFT", PreviewDropdown, "BOTTOMLEFT", -6, -10)
    DetachCheckbox:SetChecked(ZF.db.profile.General.MoverPanelDetached)
    DetachCheckbox:SetScript("OnClick", function(self)
        ZF.db.profile.General.MoverPanelDetached = self:GetChecked()
        GetMoverControlPanel().detachedPositionApplied = false
        MoverControlPanel()
    end)

    local DetachLabel = ModeWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    DetachLabel:SetPoint("LEFT", DetachCheckbox, "RIGHT", 2, 0)
    DetachLabel:SetText("Detach Control Panel (Draggable)")

    local ExitButton = CreateFrame("Button", nil, ModeWindow, "UIPanelButtonTemplate")
    ExitButton:SetSize(80, 22)
    ExitButton:SetPoint("BOTTOM", ModeWindow, "BOTTOM", 0, 8)
    ExitButton:SetText("Exit")
    ExitButton:SetScript("OnClick", function() ZF:ToggleMovers() end)

    ModeWindow:EnableKeyboard(true)
    ModeWindow:SetPropagateKeyboardInput(true)
    ModeWindow:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            ZF:CloseAddonUI()
            return
        end
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

local function ShowMoverButtons(shown)
	for _, mover in pairs(ZF.MOVERS or {}) do
		mover:SetShown(shown and (mover.unit ~= "augmentation" or ZF:IsAugmentationEvoker()))
		if shown then mover:SetFrameLevel(MOVER_BASE_LEVEL) end
	end
	if shown then nextMoverBack = MOVER_BASE_LEVEL - 1 end
end

local ClickCatcher

local function GetMoverClickCatcher()
	if ClickCatcher then return ClickCatcher end
	ClickCatcher = CreateFrame("Button", "ZF_MoverClickCatcher", UIParent)
	ClickCatcher:SetAllPoints(UIParent)
	ClickCatcher:SetFrameStrata("DIALOG")
	ClickCatcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	ClickCatcher:SetScript("OnClick", function() ZF:SetMoverSelection(nil) end)
	ClickCatcher:Hide()
	return ClickCatcher
end

function ZF:SetMoverOverlayShown(shown)
	if not ZF.MOVERS_UNLOCKED then return end
	if shown then
		ShowMoverButtons(true)
		GetMoverModeWindow():Show()
		GetMoverClickCatcher():Show()
		MoverControlPanel()
	else
		ShowMoverButtons(false)
		GetMoverModeWindow():Hide()
		GetMoverClickCatcher():Hide()
		GetMoverControlPanel():Hide()
	end
end

function ZF:ToggleMovers(skipReopenGUI)
	if InCombatLockdown() then ZF:PrettyPrint("Movers cannot be toggled while in combat.") return ZF.MOVERS_UNLOCKED end
	ZF.MOVERS_UNLOCKED = not ZF.MOVERS_UNLOCKED
	ShowMoverButtons(ZF.MOVERS_UNLOCKED)
	if ZF.MOVERS_UNLOCKED then
		ZF:ApplyMoverPreviewMode()
    else
        for _, funcs in pairs(UNIT_PREVIEW_FUNCS) do ZF[funcs.exit](ZF) end
    end
	if not skipReopenGUI then ZF:SetMainGUIShown(not ZF.MOVERS_UNLOCKED) end
	GetMoverModeWindow():SetShown(ZF.MOVERS_UNLOCKED)
	GetMoverClickCatcher():SetShown(ZF.MOVERS_UNLOCKED)
	if not ZF.MOVERS_UNLOCKED then
        ZF:SetMoverSelection(nil)
    end

	return ZF.MOVERS_UNLOCKED
end

function ZF:CloseAddonUI()
	if ZF.MOVERS_UNLOCKED then ZF:ToggleMovers(true) end
	ZF:CloseMainGUI()
end
