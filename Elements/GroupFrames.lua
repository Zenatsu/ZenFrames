local _, ZF = ...
local oUF = ZF.oUF
local GroupRosterEventFrame = CreateFrame("Frame")
local OnGroupRosterEvent

local function RefreshGroupsAfterCombat()
	OnGroupRosterEvent(GroupRosterEventFrame, "PLAYER_REGEN_ENABLED")
end

local function QueueGroupRefresh()
	ZF:RunAfterCombat("GroupRefresh", RefreshGroupsAfterCombat)
end

local BlizzardRaidHiddenParent = CreateFrame("Frame", "ZF_BlizzardRaidHiddenParent", UIParent)
BlizzardRaidHiddenParent:Hide()

local function ClearGroupFrameUnit(unitFrame)
    ZF:UnregisterRangeFrame(unitFrame)
    ZF:UnregisterTargetGlowIndicatorFrame(unitFrame)
    if unitFrame.DispelHighlightUnit then ZF:UnregisterDispelHighlightEvents(unitFrame) end
    unitFrame.ZFGroupUnit = nil
end

local function RefreshGroupFrameIndicators(frame, unit, rangeUnit, UnitDB, onlyUpdateRoles)
    if not onlyUpdateRoles then
        if frame.DispelHighlightUnit and frame.DispelHighlightUnit ~= unit then ZF:UnregisterDispelHighlightEvents(frame) end
        ZF:RegisterRangeFrame(frame, rangeUnit or unit)
        ZF:RegisterTargetGlowIndicatorFrame(frame, unit)
        if frame.ZFGroupUnit ~= unit then
            frame.ZFGroupUnit = unit
            if frame.DispelHighlight then ZF:UpdateUnitDispelHighlight(frame, unit) end
        end
    end
    if UnitDB.PowerBar.Enabled and UnitDB.PowerBar.OnlyShowHealers then ZF:UpdateUnitPowerBar(frame, unit) end
    ZF:UpdateUnitRoleIndicator(frame, unit)
end

local UNIT_GROWTH_ANCHOR = {
    RIGHT = {point = "RIGHT", xSign = -1, ySign = 0},
    LEFT = {point = "LEFT", xSign = 1, ySign = 0},
    UP = {point = "TOP", xSign = 0, ySign = -1},
    DOWN = {point = "BOTTOM", xSign = 0, ySign = 1},
}

local function ComputeUnitGrowthAnchor(unitGrowth, spacing)
    local anchor = UNIT_GROWTH_ANCHOR[unitGrowth] or UNIT_GROWTH_ANCHOR.LEFT
    return anchor.point, anchor.xSign * spacing, anchor.ySign * spacing
end

local GROUP_GROWTH_HORIZONTAL_ANCHOR = { LEFT = "RIGHT", RIGHT = "LEFT" }
local GROUP_GROWTH_VERTICAL_ANCHOR = { UP = "BOTTOM", DOWN = "TOP" }
local GROUP_GROWTH_COLUMN_ANCHOR = { RIGHT = "LEFT", LEFT = "RIGHT", UP = "BOTTOM" }

local PARTY_GROWTH_ANCHOR = {
    UP = {anchor = "BOTTOMLEFT", xSign = 0, ySign = 1},
    LEFT = {anchor = "TOPRIGHT", xSign = -1, ySign = 0},
    RIGHT = {anchor = "TOPLEFT", xSign = 1, ySign = 0},
    DOWN = {anchor = "TOPLEFT", xSign = 0, ySign = -1},
}

local function ComputeGroupAnchorPoint(unitGrowth, groupGrowth)
    local horizontalAnchor = GROUP_GROWTH_HORIZONTAL_ANCHOR[groupGrowth] or (unitGrowth == "RIGHT" and "RIGHT" or "LEFT")
    local verticalAnchor = GROUP_GROWTH_VERTICAL_ANCHOR[groupGrowth] or (unitGrowth == "DOWN" and "BOTTOM" or "TOP")
    return horizontalAnchor, verticalAnchor
end

local function CreateBackdropContainer(frameName)
    local container = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
    container:SetBackdrop(ZF.BACKDROP)
    container:SetBackdropColor(0, 0, 0, 0)
    container:SetBackdropBorderColor(0, 0, 0, 0)
    return container
end

local function PositionGroupContainer(container, FrameDB, visibilityState)
    container:ClearAllPoints()
    container:SetPoint(FrameDB.Layout[1], UIParent, FrameDB.Layout[2], FrameDB.Layout[3], FrameDB.Layout[4])
    container:SetFrameStrata(FrameDB.FrameStrata)
    RegisterStateDriver(container, "visibility", visibilityState)
end

local function HideBlizzardFrame(frameName)
	local frame = _G[frameName]
	if not frame then return end
	if InCombatLockdown() and frame:IsProtected() then
		QueueGroupRefresh()
		return
	end
	frame:UnregisterAllEvents()
	frame:Hide()
	frame:SetParent(BlizzardRaidHiddenParent)
end

function ZF:HideBlizzardRaidFrames()
	HideBlizzardFrame("CompactRaidFrameManager")
	HideBlizzardFrame("CompactRaidFrameContainer")
	for groupIndex = 1, ZF.MAX_RAID_GROUPS do HideBlizzardFrame("CompactRaidGroup" .. groupIndex) end
	for frameIndex = 1, ZF.MAX_RAID_FRAMES do HideBlizzardFrame("CompactRaidFrame" .. frameIndex) end
end

function ZF:RegisterRaidFrame(unitFrame)
	if not unitFrame or unitFrame.isZFUnitFrame then return end
	unitFrame.isZFUnitFrame = true
	local raidFrames = unitFrame.auxiliaryRaidGroup and ZF.AUXILIARY_RAID_FRAMES[unitFrame.auxiliaryRaidGroup] or ZF.RAID_FRAMES
	raidFrames[#raidFrames + 1] = unitFrame
end

function ZF:ForEachRaidFrame(callback, includeInactive, ...)
	for _, raidFrame in ipairs(ZF.RAID_FRAMES) do
		if raidFrame then
			local assignedUnit = raidFrame:GetAttribute("unit")
			local unit = assignedUnit or includeInactive and raidFrame.ZFConfiguredUnit
			callback(raidFrame, unit, assignedUnit, ...)
		end
	end
end

function ZF:ForEachAuxiliaryRaidFrame(groupKey, callback, includeInactive, ...)
	for _, raidFrame in ipairs(ZF.AUXILIARY_RAID_FRAMES[groupKey]) do
		if raidFrame then
			local assignedUnit = raidFrame:GetAttribute("unit")
			local unit = assignedUnit or includeInactive and raidFrame.ZFConfiguredUnit
			callback(raidFrame, unit, assignedUnit, ...)
		end
	end
end

function ZF:LayoutAuxiliaryRaidGroup(groupKey)
	if InCombatLockdown() then return end
	local container, header = ZF.AUXILIARY_RAID_CONTAINERS[groupKey], ZF.AUXILIARY_RAID_HEADERS[groupKey]
	if not container or not header then return end
	local entry = ZF.AUXILIARY_RAID_GROUPS[groupKey]
	local FrameDB = ZF.db.profile.Units[groupKey].Frame
	local unitGrowth, groupGrowth = (FrameDB.GrowthDirection or "RIGHT_DOWN"):match("^(%a+)_(%a+)$")
	unitGrowth = unitGrowth or "RIGHT"
	groupGrowth = groupGrowth or "DOWN"
	local spacing = FrameDB.Layout[5] or 0
	local frameCount = math.max(entry.membership == "ROSTER_NAMES" and (ZF.AUXILIARY_RAID_FRAME_COUNTS[groupKey] or 0) or entry.maxUnits, 1)
	local unitsPerColumn = FrameDB.UnitsPerColumn or ZF.MAX_RAID_FRAMES_PER_GROUP
	local columns = math.ceil(frameCount / unitsPerColumn)
	local rows = math.min(frameCount, unitsPerColumn)
	local point, xOffset, yOffset = ComputeUnitGrowthAnchor(unitGrowth, spacing)
	local columnAnchorPoint = GROUP_GROWTH_COLUMN_ANCHOR[groupGrowth] or "TOP"
	local columnWidth = (unitGrowth == "UP" or unitGrowth == "DOWN") and FrameDB.Width or (FrameDB.Width + spacing) * rows - spacing
	local columnHeight = (unitGrowth == "UP" or unitGrowth == "DOWN") and (FrameDB.Height + spacing) * rows - spacing or FrameDB.Height

	container:ClearAllPoints()
	container:SetPoint(FrameDB.Layout[1], UIParent, FrameDB.Layout[2], FrameDB.Layout[3], FrameDB.Layout[4])
	container:SetFrameStrata(FrameDB.FrameStrata)
	container:SetSize((groupGrowth == "LEFT" or groupGrowth == "RIGHT") and (columnWidth + spacing) * columns - spacing or columnWidth, (groupGrowth == "UP" or groupGrowth == "DOWN") and (columnHeight + spacing) * columns - spacing or columnHeight)

	for childIndex = 1, entry.maxUnits do
		local child = header:GetAttribute("child" .. childIndex)
		if child then
			child:ClearAllPoints()
			child:SetSize(FrameDB.Width, FrameDB.Height)
			child:SetFrameStrata(FrameDB.FrameStrata)
		end
	end
	header:SetAttribute("point", point)
	header:SetAttribute("xOffset", xOffset)
	header:SetAttribute("yOffset", yOffset)
	header:SetAttribute("initial-width", FrameDB.Width)
	header:SetAttribute("initial-height", FrameDB.Height)
	header:SetAttribute("oUF-initialConfigFunction", ("self:SetWidth(%s); self:SetHeight(%s)"):format(FrameDB.Width, FrameDB.Height))
	header:SetAttribute("unitsPerColumn", unitsPerColumn)
	header:SetAttribute("maxColumns", math.ceil(entry.maxUnits / unitsPerColumn))
	header:SetAttribute("columnSpacing", spacing)
	header:SetAttribute("columnAnchorPoint", columnAnchorPoint)
	header:SetFrameStrata(FrameDB.FrameStrata)
	header:SetSize(container:GetSize())
	header:ClearAllPoints()
	local horizontalAnchor, verticalAnchor = ComputeGroupAnchorPoint(unitGrowth, groupGrowth)
	header:SetPoint(verticalAnchor .. horizontalAnchor, container, verticalAnchor .. horizontalAnchor)
end

local function BuildRaidRosterLookup()
	local byFullName, byShortName = {}, {}
	for raidIndex = 1, GetNumGroupMembers() do
		local rosterName = GetRaidRosterInfo(raidIndex)
		if rosterName then
			byFullName[rosterName:lower()] = rosterName
			local shortName = Ambiguate(rosterName, "short"):lower()
			local existing = byShortName[shortName]
			if not existing then
				byShortName[shortName] = rosterName
			elseif type(existing) == "string" then
				byShortName[shortName] = {existing, rosterName}
			else
				existing[#existing + 1] = rosterName
			end
		end
	end
	return byFullName, byShortName
end

local function ResolveConfiguredRosterNames(configuredNames, byFullName, byShortName)
	local names, seen = {}, {}
	for configuredName in (configuredNames or ""):gmatch("[^,;\n]+") do
		local configuredNameLower = strtrim(configuredName):lower()
		if configuredNameLower ~= "" then
			local rosterName = byFullName[configuredNameLower]
			local candidates = not rosterName and byShortName[configuredNameLower]
			if type(candidates) == "string" then
				rosterName = candidates
			elseif candidates then
				for _, shortName in ipairs(candidates) do
					if not seen[shortName] then rosterName = shortName break end
				end
			end
			if rosterName and not seen[rosterName] then
				seen[rosterName] = true
				names[#names + 1] = rosterName
			end
		end
	end
	return names
end

function ZF:IsAuxiliaryRaidGroupActive(groupKey)
	local UnitDB = ZF.db.profile.Units[groupKey]
	if not UnitDB.Enabled then return false end
	if groupKey == "augmentation" then return ZF:IsAugmentationEvoker() end
	return true
end

function ZF:UpdateAuxiliaryRaidGroup(groupKey)
	local entry = ZF.AUXILIARY_RAID_GROUPS[groupKey]
	local UnitDB = ZF.db.profile.Units[groupKey]
	local isActive = ZF:IsAuxiliaryRaidGroupActive(groupKey)
	local header = ZF.AUXILIARY_RAID_HEADERS[groupKey]
	if not header then
		if isActive then ZF:SpawnUnitFrame("raid") end
		return
	end
	if InCombatLockdown() then
		QueueGroupRefresh()
		return
	end
	local container = ZF.AUXILIARY_RAID_CONTAINERS[groupKey]

	if not isActive then
		ZF.AUXILIARY_RAID_FRAME_COUNTS[groupKey] = 0
		if entry.membership == "ROSTER_NAMES" then
			if header:GetAttribute("nameList") ~= "" then
				header:SetAttribute("nameList", "")
				ZF:ForEachAuxiliaryRaidFrame(groupKey, ClearGroupFrameUnit, true)
			end
		else
			ZF:ForEachAuxiliaryRaidFrame(groupKey, ClearGroupFrameUnit, true)
		end
		if container:IsShown() then container:Hide() end
		if ZF.MOVERS and ZF.MOVERS[groupKey] and ZF.MOVERS[groupKey]:IsShown() then ZF.MOVERS[groupKey]:Hide() end
		return
	end

	local active = true
	if entry.membership == "ROSTER_NAMES" then
		local rosterByFullName, rosterByShortName = BuildRaidRosterLookup()
		local names = ResolveConfiguredRosterNames(UnitDB.Names, rosterByFullName, rosterByShortName)
		active = #names > 0
		ZF.AUXILIARY_RAID_FRAME_COUNTS[groupKey] = #names
		local nameList = table.concat(names, ",")
		local activeNameList = active and nameList or ""
		local sortMethod = UnitDB.Frame.SortBy == "NAME" and "NAME" or "NAMELIST"
		if header:GetAttribute("sortMethod") ~= sortMethod then header:SetAttribute("sortMethod", sortMethod) end
		if header:GetAttribute("nameList") ~= activeNameList then header:SetAttribute("nameList", activeNameList) end
	end

	ZF:ForEachAuxiliaryRaidFrame(groupKey, function(raidFrame, unit, assignedUnit)
		if not assignedUnit then
			ClearGroupFrameUnit(raidFrame)
			return
		end
		raidFrame:SetSize(UnitDB.Frame.Width, UnitDB.Frame.Height)
		raidFrame:SetFrameStrata(UnitDB.Frame.FrameStrata)
		ZF:UpdateUnitFrame(raidFrame, unit)
		raidFrame.ZFGroupUnit = assignedUnit
	end, true)
	ZF:LayoutAuxiliaryRaidGroup(groupKey)
	container:SetShown(active)
	if ZF.MOVERS and ZF.MOVERS[groupKey] then ZF.MOVERS[groupKey]:SetShown(isActive and ZF.MOVERS_UNLOCKED) end
end

function ZF:SpawnAuxiliaryRaidGroup(groupKey)
	local entry = ZF.AUXILIARY_RAID_GROUPS[groupKey]
	if not ZF:IsAuxiliaryRaidGroupActive(groupKey) then return end
	local prettyKey = groupKey:gsub("^%l", string.upper)
	ZF.AUXILIARY_RAID_CONTAINERS[groupKey] = ZF.AUXILIARY_RAID_CONTAINERS[groupKey] or CreateBackdropContainer("ZF_" .. prettyKey .. "RaidContainer")
	local container = ZF.AUXILIARY_RAID_CONTAINERS[groupKey]
	if not ZF.AUXILIARY_RAID_HEADERS[groupKey] then
		local FrameDB = ZF.db.profile.Units[groupKey].Frame
		local unitsPerColumn = FrameDB.UnitsPerColumn or ZF.MAX_RAID_FRAMES_PER_GROUP
		local membershipKey = entry.membership == "ROSTER_NAMES" and "nameList" or "groupFilter"
		local membershipValue = entry.membership == "ROSTER_NAMES" and "" or entry.membership
		local defaultSort = entry.membership == "ROSTER_NAMES" and "NAMELIST" or "INDEX"
		local header = oUF:SpawnHeader("ZF_" .. prettyKey .. "RaidHeader", nil,
			"showRaid", true,
			"showParty", false,
			"showPlayer", true,
			"showSolo", false,
			membershipKey, membershipValue,
			"sortMethod", FrameDB.SortBy == "NAME" and "NAME" or defaultSort,
			"initial-width", FrameDB.Width,
			"initial-height", FrameDB.Height,
			"oUF-initialConfigFunction", ("self:SetWidth(%s); self:SetHeight(%s)"):format(FrameDB.Width, FrameDB.Height),
			"unitsPerColumn", unitsPerColumn,
			"maxColumns", math.ceil(entry.maxUnits / unitsPerColumn)
		)
		header:SetParent(container)
		header:SetVisibility("raid")
		ZF.AUXILIARY_RAID_HEADERS[groupKey] = header
		ZF.AuxiliaryHeaderOwner[header] = groupKey
	end
	ZF:CreateMover(groupKey)
	ZF:UpdateAuxiliaryRaidGroup(groupKey)
end

function ZF:SpawnGroupFrame(groupType)
	if InCombatLockdown() then QueueGroupRefresh() return end
	local FrameDB = ZF.db.profile.Units[groupType].Frame
	if groupType == "party" then
		ZF.PARTY_CONTAINER = ZF.PARTY_CONTAINER or CreateBackdropContainer("ZF_PartyContainer")
		PositionGroupContainer(ZF.PARTY_CONTAINER, FrameDB, "[group:party,nogroup:raid] show; hide")
		for i = 1, ZF.MAX_PARTY_FRAMES do
			local partyFrame = oUF:Spawn("party" .. i, ZF:FetchFrameName("party" .. i))
			partyFrame.partyIndex = i + 1
			partyFrame:SetParent(ZF.PARTY_CONTAINER)
			partyFrame:SetSize(FrameDB.Width, FrameDB.Height)
			partyFrame:SetFrameStrata(FrameDB.FrameStrata)
			ZF["PARTY" .. i] = partyFrame
			ZF.PARTY_FRAMES[i] = partyFrame
			ZF:RegisterTargetGlowIndicatorFrame(ZF:FetchFrameName("party" .. i), "party" .. i)
			ZF:RegisterRangeFrame(ZF:FetchFrameName("party" .. i), "party" .. i)
			ZF:RegisterDispelHighlightEvents(partyFrame, "party" .. i)
		end
		if FrameDB.ShowPlayer then
			local partyPlayerFrame = oUF:Spawn("player", ZF:FetchFrameName("partyplayer"))
			partyPlayerFrame.partyIndex = 1
			partyPlayerFrame:SetParent(ZF.PARTY_CONTAINER)
			partyPlayerFrame:SetSize(FrameDB.Width, FrameDB.Height)
			partyPlayerFrame:SetFrameStrata(FrameDB.FrameStrata)
			ZF.PARTYPLAYER = partyPlayerFrame
			ZF.PARTY_FRAMES[#ZF.PARTY_FRAMES + 1] = partyPlayerFrame
			ZF:RegisterTargetGlowIndicatorFrame(partyPlayerFrame, "partyplayer")
			ZF:RegisterRangeFrame(partyPlayerFrame, "player")
			ZF:RegisterDispelHighlightEvents(partyPlayerFrame, "player")
		end
		ZF:CreateMover(groupType)
		for i = 1, ZF.MAX_PARTY_FRAMES do RegisterUnitWatch(ZF["PARTY" .. i]) end
		ZF.PARTY_CONTAINER:Show()
	elseif groupType == "raid" then
		ZF.RAID_CONTAINER = ZF.RAID_CONTAINER or CreateBackdropContainer("ZF_RaidContainer")
		PositionGroupContainer(ZF.RAID_CONTAINER, FrameDB, "show")
		local unitGrowth = (FrameDB.GrowthDirection or "RIGHT_DOWN"):match("^(%a+)_")
		local spacing = FrameDB.Layout[5] or 0
		local point, unitXOffset, unitYOffset = ComputeUnitGrowthAnchor(unitGrowth, spacing)

		for groupIndex = 1, ZF.MAX_RAID_GROUPS do
			local headerName = "ZF_RaidHeader" .. groupIndex
			local header = oUF:SpawnHeader(headerName, nil,
				"showRaid", true,
				"showParty", false,
				"showPlayer", true,
				"showSolo", false,
				"groupFilter", (not FrameDB.Groups or FrameDB.Groups[groupIndex]) and tostring(groupIndex) or "0",
				"initial-width", FrameDB.Width,
				"initial-height", FrameDB.Height,
				"oUF-initialConfigFunction", ("self:SetWidth(%s); self:SetHeight(%s)"):format(FrameDB.Width, FrameDB.Height),
				"point", point,
				"xOffset", unitXOffset,
				"yOffset", unitYOffset,
				"unitsPerColumn", ZF.MAX_RAID_FRAMES_PER_GROUP,
				"maxColumns", 1,
				"sortMethod", FrameDB.SortBy == "INDEX" and "INDEX" or nil
			)
			header:SetSize(FrameDB.Width, FrameDB.Height)
			header:SetParent(ZF.RAID_CONTAINER)
			header:SetVisibility("raid")
			header:SetAttribute("startingIndex", -(ZF.MAX_RAID_FRAMES_PER_GROUP - 1))
			header:Show()
			header:SetAttribute("startingIndex", 1)
			ZF.RAID_HEADERS[groupIndex] = header
		end
		ZF:CreateMover(groupType)
		ZF.RAID_CONTAINER:Show()
		for _, header in ipairs(ZF.RAID_HEADERS) do header:Show() end
	end
	ZF:LayoutGroupFrames(groupType)
	ZF:UpdateGroupFrame(groupType)
end

function ZF:UpdateGroupFrame(groupType)
	local UnitDB = ZF.db.profile.Units[groupType]
	if not UnitDB or not UnitDB.Enabled then
		local container = groupType == "party" and ZF.PARTY_CONTAINER or ZF.RAID_CONTAINER
		if container then if not InCombatLockdown() then UnregisterStateDriver(container, "visibility") end container:Hide() end
		if groupType == "party" then
			for _, partyFrame in ipairs(ZF.PARTY_FRAMES) do ClearGroupFrameUnit(partyFrame) end
		else
			ZF:ForEachRaidFrame(ClearGroupFrameUnit, true)
		end
		return
	end
	if InCombatLockdown() then QueueGroupRefresh() return end
	if groupType == "party" then
		if not ZF.PARTY_CONTAINER then ZF:SpawnGroupFrame("party") else
			PositionGroupContainer(ZF.PARTY_CONTAINER, UnitDB.Frame, "[group:party,nogroup:raid] show; hide")
		end
		for i = 1, ZF.MAX_PARTY_FRAMES do if ZF["PARTY" .. i] then ZF:UpdateUnitFrame(ZF["PARTY" .. i], "party" .. i) end end
		if ZF.PARTYPLAYER then ZF:UpdateUnitFrame(ZF.PARTYPLAYER, "partyplayer") end
	elseif groupType == "raid" then
		if not ZF.RAID_CONTAINER then ZF:SpawnGroupFrame("raid") else
			PositionGroupContainer(ZF.RAID_CONTAINER, UnitDB.Frame, "show")
		end
		ZF:ForEachRaidFrame(function(raidFrame, unit, assignedUnit)
			if not unit or unit == "raid" then
				ClearGroupFrameUnit(raidFrame)
				return
			end
			raidFrame:SetSize(UnitDB.Frame.Width, UnitDB.Frame.Height)
			raidFrame:SetFrameStrata(UnitDB.Frame.FrameStrata)
			if raidFrame.DispelHighlightUnit and raidFrame.DispelHighlightUnit ~= unit then ZF:UnregisterDispelHighlightEvents(raidFrame) end
			ZF:UpdateUnitFrame(raidFrame, unit)
			if assignedUnit then
				raidFrame.ZFGroupUnit = assignedUnit
			else
				ClearGroupFrameUnit(raidFrame)
			end
		end, true)
	end
	ZF:LayoutGroupFrames(groupType)
end

function ZF:UpdateGroupIndicators(groupType, onlyUpdateRoles)
	local UnitDB = ZF.db.profile.Units[groupType]
	if not UnitDB or not UnitDB.Enabled then return end
	if groupType == "party" then
		for i = 1, ZF.MAX_PARTY_FRAMES do
			local partyFrame = ZF["PARTY" .. i]
			if partyFrame then
				RefreshGroupFrameIndicators(partyFrame, "party" .. i, nil, UnitDB, onlyUpdateRoles)
			end
		end
		if ZF.PARTYPLAYER then
			RefreshGroupFrameIndicators(ZF.PARTYPLAYER, "partyplayer", "player", UnitDB, onlyUpdateRoles)
		end
	elseif groupType == "raid" then
		ZF:ForEachRaidFrame(function(raidFrame, unit)
			if unit and unit ~= "raid" then
				RefreshGroupFrameIndicators(raidFrame, unit, nil, UnitDB, onlyUpdateRoles)
			elseif not onlyUpdateRoles then
				ClearGroupFrameUnit(raidFrame)
			end
		end, false)
	end
	if groupType == "party" then ZF:LayoutGroupFrames(groupType) end
end

function ZF:IsRaidGroupShown(Frame, groupIndex)
	if Frame.AutoAdjustGroups then
		local _, _, difficultyID = GetInstanceInfo()
		local autoGroupCount = (difficultyID == 14 or difficultyID == 15) and 6 or difficultyID == 16 and 4 or difficultyID == 233 and 5 or 8
		return groupIndex <= autoGroupCount
	end
	return Frame.Groups == nil or Frame.Groups[groupIndex] ~= false
end

local function IsRaidGroupExclusionActive()
	return (ZF.db.profile.Units.maintank.Enabled and not ZF.db.profile.Units.maintank.IncludeInRaidGroups)
		or (ZF.db.profile.Units.mainassist.Enabled and not ZF.db.profile.Units.mainassist.IncludeInRaidGroups)
end

local function BuildRaidGroupExclusionSet()
	local excludeMainTank = ZF.db.profile.Units.maintank.Enabled and not ZF.db.profile.Units.maintank.IncludeInRaidGroups
	local excludeMainAssist = ZF.db.profile.Units.mainassist.Enabled and not ZF.db.profile.Units.mainassist.IncludeInRaidGroups
	if not excludeMainTank and not excludeMainAssist then return nil end
	local exclude = {}
	for raidIndex = 1, GetNumGroupMembers() do
		local unit = "raid" .. raidIndex
		if (excludeMainTank and GetPartyAssignment("MAINTANK", unit)) or (excludeMainAssist and GetPartyAssignment("MAINASSIST", unit)) then
			exclude[raidIndex] = true
		end
	end
	return exclude
end

function ZF:LayoutGroupFrames(groupType)
	if InCombatLockdown() then QueueGroupRefresh() return end
	local Frame = ZF.db.profile.Units[groupType].Frame
	if groupType == "party" then
		if not ZF.PARTY_CONTAINER or #ZF.PARTY_FRAMES == 0 then return end
		ZF.PARTY_CONTAINER:ClearAllPoints()
		ZF.PARTY_CONTAINER:SetPoint(Frame.Layout[1], UIParent, Frame.Layout[2], Frame.Layout[3], Frame.Layout[4])
		ZF.PARTY_CONTAINER:SetFrameStrata(Frame.FrameStrata)
		local partyFrames = {}
		for _, partyFrame in ipairs(ZF.PARTY_FRAMES) do partyFrames[#partyFrames + 1] = partyFrame end
		table.sort(partyFrames, function(firstFrame, secondFrame)
			if Frame.SortBy == "NAME" then
				return (UnitName(firstFrame.__unit) or firstFrame.__unit or "") < (UnitName(secondFrame.__unit) or secondFrame.__unit or "")
			elseif Frame.SortBy == "ROLE" then
				local firstRole = UnitGroupRolesAssigned(firstFrame.__unit)
				local secondRole = UnitGroupRolesAssigned(secondFrame.__unit)
				if firstRole ~= secondRole then
					for _, orderedRole in ipairs(Frame.RoleOrder or {}) do
						if firstRole == orderedRole then return true end
						if secondRole == orderedRole then return false end
					end
				end
			end
			return (firstFrame.partyIndex or 0) < (secondFrame.partyIndex or 0)
		end)
		local spacing = Frame.Layout[5] or 0
		local horizontal = Frame.GrowthDirection == "LEFT" or Frame.GrowthDirection == "RIGHT"
		ZF.PARTY_CONTAINER:SetSize(math.max(horizontal and (Frame.Width + spacing) * #partyFrames - spacing or Frame.Width, Frame.Width), math.max(horizontal and Frame.Height or (Frame.Height + spacing) * #partyFrames - spacing, Frame.Height))
		local growth = PARTY_GROWTH_ANCHOR[Frame.GrowthDirection] or PARTY_GROWTH_ANCHOR.DOWN
		for index, partyFrame in ipairs(partyFrames) do
			partyFrame:ClearAllPoints()
			partyFrame:SetSize(Frame.Width, Frame.Height)
			partyFrame:SetFrameStrata(Frame.FrameStrata)
			local step = index - 1
			partyFrame:SetPoint(growth.anchor, ZF.PARTY_CONTAINER, growth.anchor, growth.xSign * step * (Frame.Width + spacing), growth.ySign * step * (Frame.Height + spacing))
		end
	elseif groupType == "raid" then
		if not ZF.RAID_CONTAINER then return end
		local unitGrowth, groupGrowth = (Frame.GrowthDirection or "RIGHT_DOWN"):match("^(%a+)_(%a+)$")
		unitGrowth = unitGrowth or "RIGHT"
		groupGrowth = groupGrowth or "DOWN"
		local spacing = Frame.Layout[5] or 0
		local shownGroups = 0
		for groupIndex = 1, ZF.MAX_RAID_GROUPS do if ZF:IsRaidGroupShown(Frame, groupIndex) then shownGroups = shownGroups + 1 end end
		local headerWidth = (unitGrowth == "UP" or unitGrowth == "DOWN") and Frame.Width or (Frame.Width + spacing) * ZF.MAX_RAID_FRAMES_PER_GROUP - spacing
		local headerHeight = (unitGrowth == "UP" or unitGrowth == "DOWN") and (Frame.Height + spacing) * ZF.MAX_RAID_FRAMES_PER_GROUP - spacing or Frame.Height
		local point, unitXOffset, unitYOffset = ComputeUnitGrowthAnchor(unitGrowth, spacing)
		local horizontalAnchor, verticalAnchor = ComputeGroupAnchorPoint(unitGrowth, groupGrowth)
		ZF.RAID_CONTAINER:ClearAllPoints()
		ZF.RAID_CONTAINER:SetPoint(Frame.Layout[1], UIParent, Frame.Layout[2], Frame.Layout[3], Frame.Layout[4])
		ZF.RAID_CONTAINER:SetFrameStrata(Frame.FrameStrata)
		ZF.RAID_CONTAINER:SetSize(math.max((groupGrowth == "LEFT" or groupGrowth == "RIGHT") and (headerWidth + spacing) * shownGroups - spacing or headerWidth, Frame.Width), math.max((groupGrowth == "UP" or groupGrowth == "DOWN") and (headerHeight + spacing) * shownGroups - spacing or headerHeight, Frame.Height))
		local shownGroupIndex = 0
		local exclude = BuildRaidGroupExclusionSet()
		for groupIndex, header in ipairs(ZF.RAID_HEADERS) do
			local showGroup = ZF:IsRaidGroupShown(Frame, groupIndex)
			if showGroup then shownGroupIndex = shownGroupIndex + 1 end
			for childIndex = 1, ZF.MAX_RAID_FRAMES_PER_GROUP do
				local child = header:GetAttribute("child" .. childIndex)
				if child then child:ClearAllPoints() end
			end
			header:SetAttribute("point", point)
			header:SetAttribute("xOffset", unitXOffset)
			header:SetAttribute("yOffset", unitYOffset)
			header:SetAttribute("initial-width", Frame.Width)
			header:SetAttribute("initial-height", Frame.Height)
			header:SetAttribute("oUF-initialConfigFunction", ("self:SetWidth(%s); self:SetHeight(%s)"):format(Frame.Width, Frame.Height))
			header:SetAttribute("unitsPerColumn", ZF.MAX_RAID_FRAMES_PER_GROUP)
			header:SetAttribute("maxColumns", 1)
			if exclude and showGroup then
				local names = {}
				for raidIndex = 1, GetNumGroupMembers() do
					local rosterName, _, subgroup = GetRaidRosterInfo(raidIndex)
					if rosterName and subgroup == groupIndex and not exclude[raidIndex] then
						names[#names + 1] = rosterName
					end
				end
				header:SetAttribute("groupFilter", nil)
				header:SetAttribute("nameList", table.concat(names, ","))
				header:SetAttribute("sortMethod", Frame.SortBy == "NAME" and "NAME" or "NAMELIST")
			else
				header:SetAttribute("nameList", nil)
				header:SetAttribute("groupFilter", showGroup and tostring(groupIndex) or "0")
				header:SetAttribute("sortMethod", Frame.SortBy == "INDEX" and "INDEX" or nil)
			end
			if showGroup then header:Show() else header:Hide() end
			header:SetFrameStrata(Frame.FrameStrata)
			header:SetSize(headerWidth, headerHeight)
			header:ClearAllPoints()
			header:SetPoint(verticalAnchor .. horizontalAnchor, ZF.RAID_CONTAINER, verticalAnchor .. horizontalAnchor, groupGrowth == "RIGHT" and (shownGroupIndex - 1) * (headerWidth + spacing) or groupGrowth == "LEFT" and -((shownGroupIndex - 1) * (headerWidth + spacing)) or 0, groupGrowth == "UP" and (shownGroupIndex - 1) * (headerHeight + spacing) or groupGrowth == "DOWN" and -((shownGroupIndex - 1) * (headerHeight + spacing)) or 0)
		end
	end
end

local function ReattachPartyFrame(unitFrame, unit)
	if not unitFrame or not unit or InCombatLockdown() then return end
	local realUnit = (unit == "partyplayer") and "player" or unit
	unitFrame:SetAttribute("unit", realUnit)
	RegisterUnitWatch(unitFrame)
	ZF:CreateTestAuras(unitFrame, unit)
	ZF:UpdateUnitFrame(unitFrame, unit)
end

function ZF:ResetPartyFrames()
	if InCombatLockdown() then return end
	for i = 1, ZF.MAX_PARTY_FRAMES do
		local partyFrame = ZF["PARTY" .. i]
		if partyFrame then ReattachPartyFrame(partyFrame, "party" .. i) end
	end
	if ZF.PARTYPLAYER then ReattachPartyFrame(ZF.PARTYPLAYER, "partyplayer") end
	ZF:UpdateGroupFrame("party")
	ZF:UpdateUnitTags("party")
end

function ZF:ResetRaidFrames()
	if InCombatLockdown() then return end
	for _, raidHeader in ipairs(ZF.RAID_HEADERS) do raidHeader:Show() end
	ZF:UpdateGroupFrame("raid")
	for _, groupKey in ipairs(ZF.AUXILIARY_RAID_GROUP_ORDER) do ZF:UpdateAuxiliaryRaidGroup(groupKey) end
	ZF:UpdateUnitTags("raid")
end

GroupRosterEventFrame:RegisterEvent("ADDON_LOADED")
GroupRosterEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
GroupRosterEventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
GroupRosterEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
GroupRosterEventFrame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
GroupRosterEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
OnGroupRosterEvent = function(_, event, addonName)
	if not ZF.db or not ZF.Initialized then
		if event == "PLAYER_REGEN_ENABLED" then QueueGroupRefresh() end
		return
	end
	local RaidDB = ZF.db.profile.Units.raid
	if event == "ADDON_LOADED" then
		if addonName == "Blizzard_CompactRaidFrames" and RaidDB and RaidDB.ForceHideBlizzard then ZF:HideBlizzardRaidFrames() end
		return
	end
	if InCombatLockdown() then QueueGroupRefresh() return end
	if event == "GROUP_ROSTER_UPDATE" then
		if RaidDB and RaidDB.ForceHideBlizzard then ZF:HideBlizzardRaidFrames() end
		ZF:UpdateGroupIndicators("party")
		for _, groupKey in ipairs(ZF.AUXILIARY_RAID_GROUP_ORDER) do ZF:UpdateAuxiliaryRaidGroup(groupKey) end
		if IsRaidGroupExclusionActive() then ZF:LayoutGroupFrames("raid") end
		for _, partyFrame in ipairs(ZF.PARTY_FRAMES) do
			local unitGUID = UnitGUID(partyFrame.__unit)
			if unitGUID ~= nil and not ZF:IsSecretValue(unitGUID) and unitGUID ~= partyFrame.unitGUID then
				partyFrame.unitGUID = unitGUID
				partyFrame:UpdateAllElements("GROUP_ROSTER_UPDATE")
			end
		end
	elseif event == "PLAYER_ROLES_ASSIGNED" then
		ZF:UpdateGroupIndicators("party", true)
		ZF:UpdateGroupIndicators("raid", true)
		for _, groupKey in ipairs(ZF.AUXILIARY_RAID_GROUP_ORDER) do ZF:UpdateAuxiliaryRaidGroup(groupKey) end
		if IsRaidGroupExclusionActive() then ZF:LayoutGroupFrames("raid") end
	elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_DIFFICULTY_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
		if (RaidDB and RaidDB.Frame.AutoAdjustGroups) or IsRaidGroupExclusionActive() then ZF:LayoutGroupFrames("raid") end
		for _, groupKey in ipairs(ZF.AUXILIARY_RAID_GROUP_ORDER) do ZF:UpdateAuxiliaryRaidGroup(groupKey) end
		if event == "PLAYER_ENTERING_WORLD" then
			ZF:UpdateGroupIndicators("party", true)
			ZF:UpdateGroupIndicators("raid", true)
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if RaidDB and RaidDB.ForceHideBlizzard then ZF:HideBlizzardRaidFrames() end
		ZF:UpdateGroupFrame("party")
		ZF:UpdateGroupFrame("raid")
		ZF:UpdateGroupIndicators("party")
		ZF:UpdateGroupIndicators("raid")
		for _, groupKey in ipairs(ZF.AUXILIARY_RAID_GROUP_ORDER) do ZF:UpdateAuxiliaryRaidGroup(groupKey) end
	end
end

GroupRosterEventFrame:SetScript("OnEvent", OnGroupRosterEvent)
