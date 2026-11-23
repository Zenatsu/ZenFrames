local _, ZF = ...

local SINGLE_UNITS = { "player", "target", "targettarget", "focus", "focustarget", "pet" }

local STRATA_ORDER = {
	BACKGROUND = 1,
	LOW = 2,
	MEDIUM = 3,
	HIGH = 4,
	DIALOG = 5,
	FULLSCREEN = 6,
	FULLSCREEN_DIALOG = 7,
	TOOLTIP = 8,
}

local AURA_BLOCKERS = {
	{ dbKey = "Buffs", field = "BuffContainer", label = "buffs" },
	{ dbKey = "Debuffs", field = "DebuffContainer", label = "debuffs" },
	{ dbKey = "Custom", field = "CustomAuraContainer", label = "custom auras" },
}

local OUTLINE_COLOR = { 1, 0.1, 0.1, 1 }
local OUTLINE_FRAME_LEVEL = 200

local outlinePool = {}
local activeOutlines = 0
local conflictsByUnit = {}

local function GetScaledRect(frame)
	local left, bottom, width, height = frame:GetRect()
	if not left then return end
	local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
	return left * scale, bottom * scale, (left + width) * scale, (bottom + height) * scale
end

local function Outranks(blocker, victim)
	local blockerStrata = STRATA_ORDER[blocker:GetFrameStrata()] or 0
	local victimStrata = STRATA_ORDER[victim:GetFrameStrata()] or 0
	if blockerStrata ~= victimStrata then return blockerStrata > victimStrata end
	return blocker:GetFrameLevel() > victim:GetFrameLevel()
end

local function GetUnitLabel(unit)
	local mover = ZF.MOVERS and ZF.MOVERS[unit]
	return mover and mover.Text and mover.Text:GetText() or unit
end

local function CollectBlockers(unit, unitFrame, blockers)
	local unitLabel = GetUnitLabel(unit)

	if unitFrame.Totems then
		for index = 1, #unitFrame.Totems do
			local totem = unitFrame.Totems[index]
			if totem:IsShown() and totem:IsMouseEnabled() then
				blockers[#blockers + 1] = { frame = totem, owner = unitFrame, label = unitLabel .. " totem " .. index }
			end
		end
	end

	local happiness = unitFrame.PetHappinessIndicator
	if happiness and happiness.Hover and happiness.Hover:IsShown() and happiness.Hover:IsMouseEnabled() then
		blockers[#blockers + 1] = { frame = happiness.Hover, owner = unitFrame, label = unitLabel .. " happiness icon" }
	end

	local AurasDB = ZF:GetUnitDB(nil, unit).Auras
	if AurasDB then
		for _, spec in ipairs(AURA_BLOCKERS) do
			local groupDB = AurasDB[spec.dbKey]
			local container = unitFrame[spec.field]
			if groupDB and groupDB.Enabled and container and container:IsShown() then
				blockers[#blockers + 1] = { frame = container, owner = unitFrame, label = unitLabel .. " " .. spec.label }
			end
		end
	end
end

local function AcquireOutline()
	activeOutlines = activeOutlines + 1
	local outline = outlinePool[activeOutlines]
	if outline then return outline end

	outline = CreateFrame("Frame", nil, UIParent)
	outline:SetFrameStrata("FULLSCREEN_DIALOG")
	outline:SetFrameLevel(OUTLINE_FRAME_LEVEL)
	outline.edges = {}
	for index = 1, 4 do
		local edge = outline:CreateTexture(nil, "OVERLAY")
		edge:SetColorTexture(unpack(OUTLINE_COLOR))
		outline.edges[index] = edge
	end
	outlinePool[activeOutlines] = outline
	return outline
end

local function LayoutOutline(outline, left, bottom, right, top)
	local thickness = PixelUtil.GetNearestPixelSize(1, UIParent:GetEffectiveScale(), 1)
	outline:ClearAllPoints()
	outline:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
	outline:SetSize(right - left, top - bottom)

	local topEdge, bottomEdge, leftEdge, rightEdge = unpack(outline.edges)
	topEdge:ClearAllPoints()
	topEdge:SetPoint("TOPLEFT", outline, "TOPLEFT")
	topEdge:SetPoint("TOPRIGHT", outline, "TOPRIGHT")
	topEdge:SetHeight(thickness)
	bottomEdge:ClearAllPoints()
	bottomEdge:SetPoint("BOTTOMLEFT", outline, "BOTTOMLEFT")
	bottomEdge:SetPoint("BOTTOMRIGHT", outline, "BOTTOMRIGHT")
	bottomEdge:SetHeight(thickness)
	leftEdge:ClearAllPoints()
	leftEdge:SetPoint("TOPLEFT", outline, "TOPLEFT")
	leftEdge:SetPoint("BOTTOMLEFT", outline, "BOTTOMLEFT")
	leftEdge:SetWidth(thickness)
	rightEdge:ClearAllPoints()
	rightEdge:SetPoint("TOPRIGHT", outline, "TOPRIGHT")
	rightEdge:SetPoint("BOTTOMRIGHT", outline, "BOTTOMRIGHT")
	rightEdge:SetWidth(thickness)
	outline:Show()
end

local function HideAllOutlines()
	for index = 1, #outlinePool do outlinePool[index]:Hide() end
	activeOutlines = 0
end

function ZF:RefreshMouseConflicts()
	HideAllOutlines()
	conflictsByUnit = {}
	if not ZF.MOVERS_UNLOCKED then return end

	local blockers = {}
	for _, unit in ipairs(SINGLE_UNITS) do
		local unitFrame = ZF[unit:upper()]
		if unitFrame then CollectBlockers(unit, unitFrame, blockers) end
	end

	for _, unit in ipairs(SINGLE_UNITS) do
		local victim = ZF[unit:upper()]
		local mover = ZF.MOVERS and ZF.MOVERS[unit]
		local victimLeft, victimBottom, victimRight, victimTop
		if victim and mover and mover:IsShown() and victim:IsShown() then
			victimLeft, victimBottom, victimRight, victimTop = GetScaledRect(victim)
		end

		if victimLeft then
			for _, blocker in ipairs(blockers) do
				if blocker.owner ~= victim and Outranks(blocker.frame, victim) then
					local blockerLeft, blockerBottom, blockerRight, blockerTop = GetScaledRect(blocker.frame)
					if blockerLeft then
						local left = math.max(victimLeft, blockerLeft)
						local bottom = math.max(victimBottom, blockerBottom)
						local right = math.min(victimRight, blockerRight)
						local top = math.min(victimTop, blockerTop)
						if left < right and bottom < top then
							LayoutOutline(AcquireOutline(), left, bottom, right, top)
							local list = conflictsByUnit[unit] or {}
							conflictsByUnit[unit] = list
							list[#list + 1] = blocker.label
						end
					end
				end
			end
		end
	end
end

function ZF:ShowMouseConflictTooltip(mover)
	local labels = conflictsByUnit[mover.unit]
	if not labels then return end
	GameTooltip:SetOwner(mover, "ANCHOR_TOP")
	GameTooltip:SetText("Mouseover conflict", 1, 0.3, 0.3)
	GameTooltip:AddLine("Hover and right-click are blocked where these overlap:", 1, 1, 1, true)
	for _, label in ipairs(labels) do GameTooltip:AddLine(label, 0.8, 0.8, 0.8) end
	GameTooltip:Show()
end

function ZF:HideMouseConflictTooltip(mover)
	if GameTooltip:GetOwner() == mover then GameTooltip:Hide() end
end
