local _, RUF = ...
local oUF = RUF.oUF
local GroupRosterEventFrame = CreateFrame("Frame")

local BlizzardRaidHiddenParent = CreateFrame("Frame", "RUF_BlizzardRaidHiddenParent", UIParent)
BlizzardRaidHiddenParent:Hide()

function RUF:HideBlizzardRaidFrames()
	for i = 1, RUF.MAX_RAID_GROUPS + RUF.MAX_RAID_FRAMES + 2 do
		local frameName = i == 1 and "CompactRaidFrameManager" or i == 2 and "CompactRaidFrameContainer" or i <= RUF.MAX_RAID_GROUPS + 2 and "CompactRaidGroup" .. (i - 2) or "CompactRaidFrame" .. (i - RUF.MAX_RAID_GROUPS - 2)
		local raidFrame = _G[frameName]
		if raidFrame then
			raidFrame:UnregisterAllEvents()
			raidFrame:Hide()
			if not InCombatLockdown() or not raidFrame:IsProtected() then raidFrame:SetParent(BlizzardRaidHiddenParent) end
		end
	end
end

function RUF:RegisterRaidFrame(unitFrame)
	if not unitFrame or unitFrame.isRUFUnitFrame then return end
	unitFrame.isRUFUnitFrame = true
	local raidFrames = unitFrame.isAugmentationRaidFrame and RUF.AUGMENTATION_RAID_FRAMES or RUF.RAID_FRAMES
	raidFrames[#raidFrames + 1] = unitFrame
end

function RUF:ForEachRaidFrame(callback, includeInactive, ...)
	for _, raidFrame in ipairs(RUF.RAID_FRAMES) do
		if raidFrame then
			local assignedUnit = raidFrame:GetAttribute("unit")
			local unit = assignedUnit or includeInactive and raidFrame.RUFConfiguredUnit
			callback(raidFrame, unit, assignedUnit, ...)
		end
	end
end

function RUF:ForEachAugmentationRaidFrame(callback, includeInactive, ...)
	for _, raidFrame in ipairs(RUF.AUGMENTATION_RAID_FRAMES) do
		if raidFrame then
			local assignedUnit = raidFrame:GetAttribute("unit")
			local unit = assignedUnit or includeInactive and raidFrame.RUFConfiguredUnit
			callback(raidFrame, unit, assignedUnit, ...)
		end
	end
end

function RUF:LayoutAugmentationRaidFrames()
	if not RUF.AUGMENTATION_RAID_CONTAINER or not RUF.AUGMENTATION_RAID_HEADER then return end
	local FrameDB = RUF.db.profile.Units.raid.augmentation.Frame
	local unitGrowth, groupGrowth = (FrameDB.GrowthDirection or "RIGHT_DOWN"):match("^(%a+)_(%a+)$")
	unitGrowth = unitGrowth or "RIGHT"
	groupGrowth = groupGrowth or "DOWN"
	local spacing = FrameDB.Layout[5] or 0
	local frameCount = math.max(RUF.AUGMENTATION_RAID_FRAME_COUNT, 1)
	local unitsPerColumn = FrameDB.UnitsPerColumn or RUF.MAX_RAID_FRAMES_PER_GROUP
	local columns = math.ceil(frameCount / unitsPerColumn)
	local rows = math.min(frameCount, unitsPerColumn)
	local point = unitGrowth == "RIGHT" and "RIGHT" or unitGrowth == "UP" and "TOP" or unitGrowth == "DOWN" and "BOTTOM" or "LEFT"
	local xOffset = unitGrowth == "RIGHT" and -spacing or unitGrowth == "LEFT" and spacing or 0
	local yOffset = unitGrowth == "UP" and -spacing or unitGrowth == "DOWN" and spacing or 0
	local columnAnchorPoint = groupGrowth == "RIGHT" and "LEFT" or groupGrowth == "LEFT" and "RIGHT" or groupGrowth == "UP" and "BOTTOM" or "TOP"
	local columnWidth = (unitGrowth == "UP" or unitGrowth == "DOWN") and FrameDB.Width or (FrameDB.Width + spacing) * rows - spacing
	local columnHeight = (unitGrowth == "UP" or unitGrowth == "DOWN") and (FrameDB.Height + spacing) * rows - spacing or FrameDB.Height

	RUF.AUGMENTATION_RAID_CONTAINER:ClearAllPoints()
	RUF.AUGMENTATION_RAID_CONTAINER:SetPoint(FrameDB.Layout[1], UIParent, FrameDB.Layout[2], FrameDB.Layout[3], FrameDB.Layout[4])
	RUF.AUGMENTATION_RAID_CONTAINER:SetFrameStrata(FrameDB.FrameStrata)
	RUF.AUGMENTATION_RAID_CONTAINER:SetSize((groupGrowth == "LEFT" or groupGrowth == "RIGHT") and (columnWidth + spacing) * columns - spacing or columnWidth, (groupGrowth == "UP" or groupGrowth == "DOWN") and (columnHeight + spacing) * columns - spacing or columnHeight)

	local header = RUF.AUGMENTATION_RAID_HEADER
	for childIndex = 1, RUF.MAX_RAID_FRAMES do
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
	header:SetAttribute("maxColumns", math.ceil(RUF.MAX_RAID_FRAMES / unitsPerColumn))
	header:SetAttribute("columnSpacing", spacing)
	header:SetAttribute("columnAnchorPoint", columnAnchorPoint)
	header:SetFrameStrata(FrameDB.FrameStrata)
	header:SetSize(RUF.AUGMENTATION_RAID_CONTAINER:GetSize())
	header:ClearAllPoints()
	local horizontalAnchor = groupGrowth == "LEFT" and "RIGHT" or groupGrowth == "RIGHT" and "LEFT" or unitGrowth == "RIGHT" and "RIGHT" or "LEFT"
	local verticalAnchor = groupGrowth == "UP" and "BOTTOM" or groupGrowth == "DOWN" and "TOP" or unitGrowth == "DOWN" and "BOTTOM" or "TOP"
	header:SetPoint(verticalAnchor .. horizontalAnchor, RUF.AUGMENTATION_RAID_CONTAINER, verticalAnchor .. horizontalAnchor)
end

function RUF:UpdateAugmentationRaidFrames()
	local AugmentationDB = RUF.db.profile.Units.raid.augmentation
	local isAugmentation = AugmentationDB.Enabled and RUF:IsAugmentationEvoker()
	if not RUF.AUGMENTATION_RAID_HEADER then
		if isAugmentation then RUF:SpawnUnitFrame("raid") end
		return
	end
	if InCombatLockdown() then
		GroupRosterEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	if not isAugmentation then
		RUF.AUGMENTATION_RAID_FRAME_COUNT = 0
		if RUF.AUGMENTATION_RAID_HEADER:GetAttribute("nameList") ~= "" then
			RUF.AUGMENTATION_RAID_HEADER:SetAttribute("nameList", "")
			RUF:ForEachAugmentationRaidFrame(function(raidFrame)
				RUF:UnregisterRangeFrame(raidFrame)
				RUF:UnregisterTargetGlowIndicatorFrame(raidFrame)
				if raidFrame.DispelHighlightUnit then RUF:UnregisterDispelHighlightEvents(raidFrame) end
				raidFrame.RUFGroupUnit = nil
			end, true)
		end
		if RUF.AUGMENTATION_RAID_CONTAINER:IsShown() then RUF.AUGMENTATION_RAID_CONTAINER:Hide() end
		if RUF.MOVERS and RUF.MOVERS.augmentation and RUF.MOVERS.augmentation:IsShown() then RUF.MOVERS.augmentation:Hide() end
		return
	end

	local names = {}
	local seen, rosterByFullName, rosterByShortName = {}, {}, {}
	for raidIndex = 1, GetNumGroupMembers() do
		local rosterName = GetRaidRosterInfo(raidIndex)
		if rosterName then
			rosterByFullName[rosterName:lower()] = rosterName
			local shortName = Ambiguate(rosterName, "short"):lower()
			local shortNames = rosterByShortName[shortName]
			if not shortNames then
				rosterByShortName[shortName] = rosterName
			elseif type(shortNames) == "string" then
				rosterByShortName[shortName] = {shortNames, rosterName}
			else
				shortNames[#shortNames + 1] = rosterName
			end
		end
	end

	for configuredName in (AugmentationDB.Names or ""):gmatch("[^,;\n]+") do
		local configuredNameLower = strtrim(configuredName):lower()
		if configuredNameLower ~= "" then
			local rosterName = rosterByFullName[configuredNameLower]
			local shortNames = not rosterName and rosterByShortName[configuredNameLower]
			if type(shortNames) == "string" then
				rosterName = shortNames
			elseif shortNames then
				for _, shortName in ipairs(shortNames) do
					if not seen[shortName] then rosterName = shortName break end
				end
			end
			if rosterName and not seen[rosterName] then
				seen[rosterName] = true
				names[#names + 1] = rosterName
			end
		end
	end
	local active = #names > 0
	RUF.AUGMENTATION_RAID_FRAME_COUNT = #names
	local nameList = table.concat(names, ",")
	local activeNameList = active and nameList or ""
	local sortMethod = AugmentationDB.Frame.SortBy == "NAME" and "NAME" or "NAMELIST"
	if RUF.AUGMENTATION_RAID_HEADER:GetAttribute("sortMethod") ~= sortMethod then RUF.AUGMENTATION_RAID_HEADER:SetAttribute("sortMethod", sortMethod) end
	if RUF.AUGMENTATION_RAID_HEADER:GetAttribute("nameList") ~= activeNameList then RUF.AUGMENTATION_RAID_HEADER:SetAttribute("nameList", activeNameList) end
	RUF:ForEachAugmentationRaidFrame(function(raidFrame, unit, assignedUnit)
		if not assignedUnit then
			RUF:UnregisterRangeFrame(raidFrame)
			RUF:UnregisterTargetGlowIndicatorFrame(raidFrame)
			if raidFrame.DispelHighlightUnit then RUF:UnregisterDispelHighlightEvents(raidFrame) end
			raidFrame.RUFGroupUnit = nil
			return
		end
		raidFrame:SetSize(AugmentationDB.Frame.Width, AugmentationDB.Frame.Height)
		raidFrame:SetFrameStrata(AugmentationDB.Frame.FrameStrata)
		RUF:UpdateUnitFrame(raidFrame, unit)
		raidFrame.RUFGroupUnit = assignedUnit
	end, true)
	RUF:LayoutAugmentationRaidFrames()
	RUF.AUGMENTATION_RAID_CONTAINER:SetShown(active)
	if RUF.MOVERS and RUF.MOVERS.augmentation then RUF.MOVERS.augmentation:SetShown(isAugmentation and RUF.MOVERS_UNLOCKED) end
end

function RUF:SpawnAugmentationRaidFrames()
	local AugmentationDB = RUF.db.profile.Units.raid.augmentation
	if not AugmentationDB or not AugmentationDB.Enabled or not RUF:IsAugmentationEvoker() then return end
	if not RUF.AUGMENTATION_RAID_CONTAINER then
		RUF.AUGMENTATION_RAID_CONTAINER = CreateFrame("Frame", "RUF_AugmentationRaidContainer", UIParent, "BackdropTemplate")
		RUF.AUGMENTATION_RAID_CONTAINER:SetBackdrop(RUF.BACKDROP)
		RUF.AUGMENTATION_RAID_CONTAINER:SetBackdropColor(0, 0, 0, 0)
		RUF.AUGMENTATION_RAID_CONTAINER:SetBackdropBorderColor(0, 0, 0, 0)
	end
	if not RUF.AUGMENTATION_RAID_HEADER then
		local FrameDB = AugmentationDB.Frame
		RUF.AUGMENTATION_RAID_HEADER = oUF:SpawnHeader("RUF_AugmentationRaidHeader", nil,
			"showRaid", true,
			"showParty", false,
			"showPlayer", true,
			"showSolo", false,
			"nameList", "",
			"sortMethod", FrameDB.SortBy == "NAME" and "NAME" or "NAMELIST",
			"initial-width", FrameDB.Width,
			"initial-height", FrameDB.Height,
			"oUF-initialConfigFunction", ("self:SetWidth(%s); self:SetHeight(%s)"):format(FrameDB.Width, FrameDB.Height),
			"unitsPerColumn", FrameDB.UnitsPerColumn or RUF.MAX_RAID_FRAMES_PER_GROUP,
			"maxColumns", math.ceil(RUF.MAX_RAID_FRAMES / (FrameDB.UnitsPerColumn or RUF.MAX_RAID_FRAMES_PER_GROUP))
		)
		RUF.AUGMENTATION_RAID_HEADER:SetParent(RUF.AUGMENTATION_RAID_CONTAINER)
		RUF.AUGMENTATION_RAID_HEADER:SetVisibility("raid")
	end
	RUF:CreateMover("augmentation")
	RUF:UpdateAugmentationRaidFrames()
end

function RUF:SpawnGroupFrame(groupType)
	local FrameDB = RUF.db.profile.Units[groupType].Frame
	if groupType == "party" then
		if not RUF.PARTY_CONTAINER then
			RUF.PARTY_CONTAINER = CreateFrame("Frame", "RUF_PartyContainer", UIParent, "BackdropTemplate")
			RUF.PARTY_CONTAINER:SetBackdrop(RUF.BACKDROP)
			RUF.PARTY_CONTAINER:SetBackdropColor(0, 0, 0, 0)
			RUF.PARTY_CONTAINER:SetBackdropBorderColor(0, 0, 0, 0)
		end
		RUF.PARTY_CONTAINER:ClearAllPoints()
		RUF.PARTY_CONTAINER:SetPoint(FrameDB.Layout[1], UIParent, FrameDB.Layout[2], FrameDB.Layout[3], FrameDB.Layout[4])
		RUF.PARTY_CONTAINER:SetFrameStrata(FrameDB.FrameStrata)
		RegisterStateDriver(RUF.PARTY_CONTAINER, "visibility", "[group:party,nogroup:raid] show; hide")
		for i = 1, RUF.MAX_PARTY_FRAMES do
			local partyFrame = oUF:Spawn("party" .. i, RUF:FetchFrameName("party" .. i))
			partyFrame.partyIndex = i + 1
			partyFrame:SetParent(RUF.PARTY_CONTAINER)
			partyFrame:SetSize(FrameDB.Width, FrameDB.Height)
			partyFrame:SetFrameStrata(FrameDB.FrameStrata)
			RUF["PARTY" .. i] = partyFrame
			RUF.PARTY_FRAMES[i] = partyFrame
			RUF:RegisterTargetGlowIndicatorFrame(RUF:FetchFrameName("party" .. i), "party" .. i)
			RUF:RegisterRangeFrame(RUF:FetchFrameName("party" .. i), "party" .. i)
			RUF:RegisterDispelHighlightEvents(partyFrame, "party" .. i)
		end
		if FrameDB.ShowPlayer then
			local partyPlayerFrame = oUF:Spawn("player", RUF:FetchFrameName("partyplayer"))
			partyPlayerFrame.partyIndex = 1
			partyPlayerFrame:SetParent(RUF.PARTY_CONTAINER)
			partyPlayerFrame:SetSize(FrameDB.Width, FrameDB.Height)
			partyPlayerFrame:SetFrameStrata(FrameDB.FrameStrata)
			RUF.PARTYPLAYER = partyPlayerFrame
			RUF.PARTY_FRAMES[#RUF.PARTY_FRAMES + 1] = partyPlayerFrame
			RUF:RegisterTargetGlowIndicatorFrame(partyPlayerFrame, "partyplayer")
			RUF:RegisterRangeFrame(partyPlayerFrame, "player")
			RUF:RegisterDispelHighlightEvents(partyPlayerFrame, "player")
		end
		RUF:CreateMover(groupType)
		for i = 1, RUF.MAX_PARTY_FRAMES do RegisterUnitWatch(RUF["PARTY" .. i]) end
		RUF.PARTY_CONTAINER:Show()
	elseif groupType == "raid" then
		if not RUF.RAID_CONTAINER then
			RUF.RAID_CONTAINER = CreateFrame("Frame", "RUF_RaidContainer", UIParent, "BackdropTemplate")
			RUF.RAID_CONTAINER:SetBackdrop(RUF.BACKDROP)
			RUF.RAID_CONTAINER:SetBackdropColor(0, 0, 0, 0)
			RUF.RAID_CONTAINER:SetBackdropBorderColor(0, 0, 0, 0)
		end
		RUF.RAID_CONTAINER:ClearAllPoints()
		RUF.RAID_CONTAINER:SetPoint(FrameDB.Layout[1], UIParent, FrameDB.Layout[2], FrameDB.Layout[3], FrameDB.Layout[4])
		RUF.RAID_CONTAINER:SetFrameStrata(FrameDB.FrameStrata)
		RegisterStateDriver(RUF.RAID_CONTAINER, "visibility", "show")
		local unitGrowth = (FrameDB.GrowthDirection or "RIGHT_DOWN"):match("^(%a+)_")
		local spacing = FrameDB.Layout[5] or 0
		local point = unitGrowth == "RIGHT" and "RIGHT" or unitGrowth == "UP" and "TOP" or unitGrowth == "DOWN" and "BOTTOM" or "LEFT"
		local unitXOffset = unitGrowth == "RIGHT" and -spacing or unitGrowth == "LEFT" and spacing or 0
		local unitYOffset = unitGrowth == "UP" and -spacing or unitGrowth == "DOWN" and spacing or 0

		for groupIndex = 1, RUF.MAX_RAID_GROUPS do
			local headerName = "RUF_RaidHeader" .. groupIndex
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
				"unitsPerColumn", RUF.MAX_RAID_FRAMES_PER_GROUP,
				"maxColumns", 1,
				"sortMethod", FrameDB.SortBy == "INDEX" and "INDEX" or nil
			)
			header:SetSize(FrameDB.Width, FrameDB.Height)
			header:SetParent(RUF.RAID_CONTAINER)
			header:SetVisibility("raid")
			header:SetAttribute("startingIndex", -(RUF.MAX_RAID_FRAMES_PER_GROUP - 1))
			header:Show()
			header:SetAttribute("startingIndex", 1)
			RUF.RAID_HEADERS[groupIndex] = header
		end
		RUF:CreateMover(groupType)
		RUF.RAID_CONTAINER:Show()
		for _, header in ipairs(RUF.RAID_HEADERS) do header:Show() end
	end
	RUF:LayoutGroupFrames(groupType)
end

function RUF:UpdateGroupFrame(groupType)
	local UnitDB = RUF.db.profile.Units[groupType]
	if not UnitDB or not UnitDB.Enabled then
		local container = groupType == "party" and RUF.PARTY_CONTAINER or RUF.RAID_CONTAINER
		if container then if not InCombatLockdown() then UnregisterStateDriver(container, "visibility") end container:Hide() end
		if groupType == "party" then
			for _, partyFrame in ipairs(RUF.PARTY_FRAMES) do
				RUF:UnregisterRangeFrame(partyFrame)
				RUF:UnregisterTargetGlowIndicatorFrame(partyFrame)
				if partyFrame.DispelHighlightUnit then RUF:UnregisterDispelHighlightEvents(partyFrame) end
				partyFrame.RUFGroupUnit = nil
			end
		else
			RUF:ForEachRaidFrame(function(raidFrame)
				RUF:UnregisterRangeFrame(raidFrame)
				RUF:UnregisterTargetGlowIndicatorFrame(raidFrame)
				if raidFrame.DispelHighlightUnit then RUF:UnregisterDispelHighlightEvents(raidFrame) end
				raidFrame.RUFGroupUnit = nil
			end, true)
		end
		return
	end
	if groupType == "party" then
		if not RUF.PARTY_CONTAINER then RUF:SpawnGroupFrame("party") else
			RUF.PARTY_CONTAINER:ClearAllPoints()
			RUF.PARTY_CONTAINER:SetPoint(UnitDB.Frame.Layout[1], UIParent, UnitDB.Frame.Layout[2], UnitDB.Frame.Layout[3], UnitDB.Frame.Layout[4])
			RUF.PARTY_CONTAINER:SetFrameStrata(UnitDB.Frame.FrameStrata)
			RegisterStateDriver(RUF.PARTY_CONTAINER, "visibility", "[group:party,nogroup:raid] show; hide")
		end
		for i = 1, RUF.MAX_PARTY_FRAMES do if RUF["PARTY" .. i] then RUF:UpdateUnitFrame(RUF["PARTY" .. i], "party" .. i) end end
		if RUF.PARTYPLAYER then RUF:UpdateUnitFrame(RUF.PARTYPLAYER, "partyplayer") end
	elseif groupType == "raid" then
		if not RUF.RAID_CONTAINER then RUF:SpawnGroupFrame("raid") else
			RUF.RAID_CONTAINER:ClearAllPoints()
			RUF.RAID_CONTAINER:SetPoint(UnitDB.Frame.Layout[1], UIParent, UnitDB.Frame.Layout[2], UnitDB.Frame.Layout[3], UnitDB.Frame.Layout[4])
			RUF.RAID_CONTAINER:SetFrameStrata(UnitDB.Frame.FrameStrata)
			RegisterStateDriver(RUF.RAID_CONTAINER, "visibility", "show")
		end
		RUF:ForEachRaidFrame(function(raidFrame, unit, assignedUnit)
			if not unit or unit == "raid" then
				RUF:UnregisterRangeFrame(raidFrame)
				RUF:UnregisterTargetGlowIndicatorFrame(raidFrame)
				if raidFrame.DispelHighlightUnit then RUF:UnregisterDispelHighlightEvents(raidFrame) end
				raidFrame.RUFGroupUnit = nil
				return
			end
			raidFrame:SetSize(UnitDB.Frame.Width, UnitDB.Frame.Height)
			raidFrame:SetFrameStrata(UnitDB.Frame.FrameStrata)
			if raidFrame.DispelHighlightUnit and raidFrame.DispelHighlightUnit ~= unit then RUF:UnregisterDispelHighlightEvents(raidFrame) end
			RUF:UpdateUnitFrame(raidFrame, unit)
			if assignedUnit then
				raidFrame.RUFGroupUnit = assignedUnit
			else
				RUF:UnregisterRangeFrame(raidFrame)
				RUF:UnregisterTargetGlowIndicatorFrame(raidFrame)
				if raidFrame.DispelHighlightUnit then RUF:UnregisterDispelHighlightEvents(raidFrame) end
				raidFrame.RUFGroupUnit = nil
			end
		end, true)
	end
	RUF:LayoutGroupFrames(groupType)
end

function RUF:UpdateGroupIndicators(groupType, onlyUpdateRoles)
	local UnitDB = RUF.db.profile.Units[groupType]
	if not UnitDB or not UnitDB.Enabled then return end
	if groupType == "party" then
		for i = 1, RUF.MAX_PARTY_FRAMES do
			local partyFrame = RUF["PARTY" .. i]
			if partyFrame then
				if not onlyUpdateRoles then
					if partyFrame.DispelHighlightUnit and partyFrame.DispelHighlightUnit ~= "party" .. i then RUF:UnregisterDispelHighlightEvents(partyFrame) end
					RUF:RegisterRangeFrame(partyFrame, "party" .. i)
					RUF:RegisterTargetGlowIndicatorFrame(partyFrame, "party" .. i)
					if partyFrame.RUFGroupUnit ~= "party" .. i then
						partyFrame.RUFGroupUnit = "party" .. i
						if partyFrame.DispelHighlight then RUF:UpdateUnitDispelHighlight(partyFrame, "party" .. i) end
					end
				end
				if UnitDB.PowerBar.Enabled and UnitDB.PowerBar.OnlyShowHealers then RUF:UpdateUnitPowerBar(partyFrame, "party" .. i) end
				RUF:UpdateUnitRoleIndicator(partyFrame, "party" .. i)
			end
		end
		if RUF.PARTYPLAYER then
			if not onlyUpdateRoles then
				if RUF.PARTYPLAYER.DispelHighlightUnit and RUF.PARTYPLAYER.DispelHighlightUnit ~= "partyplayer" then RUF:UnregisterDispelHighlightEvents(RUF.PARTYPLAYER) end
				RUF:RegisterRangeFrame(RUF.PARTYPLAYER, "player")
				RUF:RegisterTargetGlowIndicatorFrame(RUF.PARTYPLAYER, "partyplayer")
				if RUF.PARTYPLAYER.RUFGroupUnit ~= "partyplayer" then
					RUF.PARTYPLAYER.RUFGroupUnit = "partyplayer"
					if RUF.PARTYPLAYER.DispelHighlight then RUF:UpdateUnitDispelHighlight(RUF.PARTYPLAYER, "partyplayer") end
				end
			end
			if UnitDB.PowerBar.Enabled and UnitDB.PowerBar.OnlyShowHealers then RUF:UpdateUnitPowerBar(RUF.PARTYPLAYER, "partyplayer") end
			RUF:UpdateUnitRoleIndicator(RUF.PARTYPLAYER, "partyplayer")
		end
	elseif groupType == "raid" then
		RUF:ForEachRaidFrame(function(raidFrame, unit)
			if unit and unit ~= "raid" then
				if not onlyUpdateRoles then
					if raidFrame.DispelHighlightUnit and raidFrame.DispelHighlightUnit ~= unit then RUF:UnregisterDispelHighlightEvents(raidFrame) end
					RUF:RegisterRangeFrame(raidFrame, unit)
					RUF:RegisterTargetGlowIndicatorFrame(raidFrame, unit)
					if raidFrame.RUFGroupUnit ~= unit then
						raidFrame.RUFGroupUnit = unit
						if raidFrame.DispelHighlight then RUF:UpdateUnitDispelHighlight(raidFrame, unit) end
					end
				end
				if UnitDB.PowerBar.Enabled and UnitDB.PowerBar.OnlyShowHealers then RUF:UpdateUnitPowerBar(raidFrame, unit) end
				RUF:UpdateUnitRoleIndicator(raidFrame, unit)
			elseif not onlyUpdateRoles then
				RUF:UnregisterRangeFrame(raidFrame)
				RUF:UnregisterTargetGlowIndicatorFrame(raidFrame)
				if raidFrame.DispelHighlightUnit then RUF:UnregisterDispelHighlightEvents(raidFrame) end
				raidFrame.RUFGroupUnit = nil
			end
		end, false)
	end
	if groupType == "party" then RUF:LayoutGroupFrames(groupType) end
end

function RUF:LayoutGroupFrames(groupType)
	local Frame = RUF.db.profile.Units[groupType].Frame
	if groupType == "party" then
		if not RUF.PARTY_CONTAINER or #RUF.PARTY_FRAMES == 0 then return end
		RUF.PARTY_CONTAINER:ClearAllPoints()
		RUF.PARTY_CONTAINER:SetPoint(Frame.Layout[1], UIParent, Frame.Layout[2], Frame.Layout[3], Frame.Layout[4])
		RUF.PARTY_CONTAINER:SetFrameStrata(Frame.FrameStrata)
		local partyFrames = {}
		for _, partyFrame in ipairs(RUF.PARTY_FRAMES) do partyFrames[#partyFrames + 1] = partyFrame end
		table.sort(partyFrames, function(firstFrame, secondFrame)
			if Frame.SortBy == "NAME" then
				return (UnitName(firstFrame.unit) or firstFrame.unit or "") < (UnitName(secondFrame.unit) or secondFrame.unit or "")
			elseif Frame.SortBy == "ROLE" then
				local firstRole = UnitGroupRolesAssigned(firstFrame.unit)
				local secondRole = UnitGroupRolesAssigned(secondFrame.unit)
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
		RUF.PARTY_CONTAINER:SetSize(math.max(horizontal and (Frame.Width + spacing) * #partyFrames - spacing or Frame.Width, Frame.Width), math.max(horizontal and Frame.Height or (Frame.Height + spacing) * #partyFrames - spacing, Frame.Height))
		for index, partyFrame in ipairs(partyFrames) do
			partyFrame:ClearAllPoints()
			partyFrame:SetSize(Frame.Width, Frame.Height)
			partyFrame:SetFrameStrata(Frame.FrameStrata)
			if Frame.GrowthDirection == "UP" then
				partyFrame:SetPoint("BOTTOMLEFT", RUF.PARTY_CONTAINER, "BOTTOMLEFT", 0, (index - 1) * (Frame.Height + spacing))
			elseif Frame.GrowthDirection == "LEFT" then
				partyFrame:SetPoint("TOPRIGHT", RUF.PARTY_CONTAINER, "TOPRIGHT", -((index - 1) * (Frame.Width + spacing)), 0)
			elseif Frame.GrowthDirection == "RIGHT" then
				partyFrame:SetPoint("TOPLEFT", RUF.PARTY_CONTAINER, "TOPLEFT", (index - 1) * (Frame.Width + spacing), 0)
			else
				partyFrame:SetPoint("TOPLEFT", RUF.PARTY_CONTAINER, "TOPLEFT", 0, -((index - 1) * (Frame.Height + spacing)))
			end
		end
	elseif groupType == "raid" then
		if not RUF.RAID_CONTAINER then return end
		local _, _, difficultyID = GetInstanceInfo()
		local autoGroupCount = Frame.AutoAdjustGroups and ((difficultyID == 14 or difficultyID == 15) and 6 or difficultyID == 16 and 4 or difficultyID == 233 and 5 or 8)
		local unitGrowth, groupGrowth = (Frame.GrowthDirection or "RIGHT_DOWN"):match("^(%a+)_(%a+)$")
		unitGrowth = unitGrowth or "RIGHT"
		groupGrowth = groupGrowth or "DOWN"
		local spacing = Frame.Layout[5] or 0
		local shownGroups = 0
		for groupIndex = 1, RUF.MAX_RAID_GROUPS do if autoGroupCount and groupIndex <= autoGroupCount or not autoGroupCount and (not Frame.Groups or Frame.Groups[groupIndex]) then shownGroups = shownGroups + 1 end end
		local headerWidth = (unitGrowth == "UP" or unitGrowth == "DOWN") and Frame.Width or (Frame.Width + spacing) * RUF.MAX_RAID_FRAMES_PER_GROUP - spacing
		local headerHeight = (unitGrowth == "UP" or unitGrowth == "DOWN") and (Frame.Height + spacing) * RUF.MAX_RAID_FRAMES_PER_GROUP - spacing or Frame.Height
		local point = unitGrowth == "RIGHT" and "RIGHT" or unitGrowth == "UP" and "TOP" or unitGrowth == "DOWN" and "BOTTOM" or "LEFT"
		local unitXOffset = unitGrowth == "RIGHT" and -spacing or unitGrowth == "LEFT" and spacing or 0
		local unitYOffset = unitGrowth == "UP" and -spacing or unitGrowth == "DOWN" and spacing or 0
		RUF.RAID_CONTAINER:ClearAllPoints()
		RUF.RAID_CONTAINER:SetPoint(Frame.Layout[1], UIParent, Frame.Layout[2], Frame.Layout[3], Frame.Layout[4])
		RUF.RAID_CONTAINER:SetFrameStrata(Frame.FrameStrata)
		RUF.RAID_CONTAINER:SetSize(math.max((groupGrowth == "LEFT" or groupGrowth == "RIGHT") and (headerWidth + spacing) * shownGroups - spacing or headerWidth, Frame.Width), math.max((groupGrowth == "UP" or groupGrowth == "DOWN") and (headerHeight + spacing) * shownGroups - spacing or headerHeight, Frame.Height))
		local shownGroupIndex = 0
		for groupIndex, header in ipairs(RUF.RAID_HEADERS) do
			local showGroup = autoGroupCount and groupIndex <= autoGroupCount or not autoGroupCount and (not Frame.Groups or Frame.Groups[groupIndex])
			if showGroup then shownGroupIndex = shownGroupIndex + 1 end
			for childIndex = 1, RUF.MAX_RAID_FRAMES_PER_GROUP do
				local child = header:GetAttribute("child" .. childIndex)
				if child then child:ClearAllPoints() end
			end
			header:SetAttribute("point", point)
			header:SetAttribute("xOffset", unitXOffset)
			header:SetAttribute("yOffset", unitYOffset)
			header:SetAttribute("initial-width", Frame.Width)
			header:SetAttribute("initial-height", Frame.Height)
			header:SetAttribute("oUF-initialConfigFunction", ("self:SetWidth(%s); self:SetHeight(%s)"):format(Frame.Width, Frame.Height))
			header:SetAttribute("unitsPerColumn", RUF.MAX_RAID_FRAMES_PER_GROUP)
			header:SetAttribute("maxColumns", 1)
			header:SetAttribute("sortMethod", Frame.SortBy == "INDEX" and "INDEX" or nil)
			header:SetAttribute("groupFilter", showGroup and tostring(groupIndex) or "0")
			if showGroup then header:Show() else header:Hide() end
			header:SetFrameStrata(Frame.FrameStrata)
			header:SetSize(headerWidth, headerHeight)
			header:ClearAllPoints()
			local horizontalAnchor = groupGrowth == "LEFT" and "RIGHT" or groupGrowth == "RIGHT" and "LEFT" or unitGrowth == "RIGHT" and "RIGHT" or "LEFT"
			local verticalAnchor = groupGrowth == "UP" and "BOTTOM" or groupGrowth == "DOWN" and "TOP" or unitGrowth == "DOWN" and "BOTTOM" or "TOP"
			header:SetPoint(verticalAnchor .. horizontalAnchor, RUF.RAID_CONTAINER, verticalAnchor .. horizontalAnchor, groupGrowth == "RIGHT" and (shownGroupIndex - 1) * (headerWidth + spacing) or groupGrowth == "LEFT" and -((shownGroupIndex - 1) * (headerWidth + spacing)) or 0, groupGrowth == "UP" and (shownGroupIndex - 1) * (headerHeight + spacing) or groupGrowth == "DOWN" and -((shownGroupIndex - 1) * (headerHeight + spacing)) or 0)
		end
	end
end

GroupRosterEventFrame:RegisterEvent("ADDON_LOADED")
GroupRosterEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
GroupRosterEventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
GroupRosterEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
GroupRosterEventFrame:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
GroupRosterEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
GroupRosterEventFrame:SetScript("OnEvent", function(_, event, addonName)
	if not RUF.db then return end
	local RaidDB = RUF.db.profile.Units.raid
	if event == "ADDON_LOADED" then
		if addonName == "Blizzard_CompactRaidFrames" and RaidDB and RaidDB.ForceHideBlizzard then RUF:HideBlizzardRaidFrames() end
		return
	end
	if InCombatLockdown() then GroupRosterEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED") return end
	if event == "PLAYER_REGEN_ENABLED" then GroupRosterEventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED") end
	if event == "GROUP_ROSTER_UPDATE" then
		if RaidDB and RaidDB.ForceHideBlizzard then RUF:HideBlizzardRaidFrames() end
		RUF:UpdateGroupIndicators("party")
		RUF:UpdateAugmentationRaidFrames()
		for _, partyFrame in ipairs(RUF.PARTY_FRAMES) do
			local unitGUID = UnitGUID(partyFrame.unit)
			if unitGUID ~= nil and not RUF:IsSecretValue(unitGUID) and unitGUID ~= partyFrame.unitGUID then 
				partyFrame.unitGUID = unitGUID
				partyFrame:UpdateAllElements("GROUP_ROSTER_UPDATE")
			end
		end
	elseif event == "PLAYER_ROLES_ASSIGNED" then
		RUF:UpdateGroupIndicators("party", true)
		RUF:UpdateGroupIndicators("raid", true)
		RUF:UpdateAugmentationRaidFrames()
	elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_DIFFICULTY_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
		if RaidDB and RaidDB.Frame.AutoAdjustGroups then RUF:LayoutGroupFrames("raid") end
		RUF:UpdateAugmentationRaidFrames()
		if event == "PLAYER_ENTERING_WORLD" then
			RUF:UpdateGroupIndicators("party", true)
			RUF:UpdateGroupIndicators("raid", true)
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if RaidDB and RaidDB.ForceHideBlizzard then RUF:HideBlizzardRaidFrames() end
		RUF:UpdateGroupIndicators("party")
		RUF:UpdateGroupIndicators("raid")
		RUF:UpdateAugmentationRaidFrames()
	end
end)
