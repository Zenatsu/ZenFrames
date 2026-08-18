local _, ZF = ...

local function CreateIndicatorTexture(unitFrame, unit, nameSuffix, size, layout, layer, subLevel)
	local texture = unitFrame.HighLevelContainer:CreateTexture(ZF:FetchFrameName(unit) .. nameSuffix, layer or "OVERLAY", nil, subLevel)
	texture:SetSize(size, size)
	texture:SetPoint(layout[1], unitFrame.HighLevelContainer, layout[2], layout[3], layout[4])
	return texture
end

local function PositionIndicatorTexture(texture, parent, size, layout)
	texture:ClearAllPoints()
	texture:SetSize(size, size)
	texture:SetPoint(layout[1], parent, layout[2], layout[3], layout[4])
end

local function DisableIndicatorElement(unitFrame, elementName, texture)
	if unitFrame:IsElementEnabled(elementName) then unitFrame:DisableElement(elementName) end
	if texture then texture:Hide() end
end

local SIMPLE_INDICATORS = {
	Resurrect = {
		dbKey = "Resurrect",
		field = "ResurrectIndicator",
		staticTexture = "RaidFrame-Icon-Rez",
	},
	Summon = {
		dbKey = "Summon",
		field = "SummonIndicator",
	},
	RaidTargetMarker = {
		dbKey = "RaidTargetMarker",
		field = "RaidTargetIndicator",
		forceShow = true,
	},
	Combat = {
		dbKey = "Combat",
		field = "CombatIndicator",
		applyTexture = function(indicator, DB)
			if DB.Texture == "DEFAULT" then
				indicator:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
				indicator:SetTexCoord(0.5, 1, 0, 0.49)
			else
				indicator:SetTexture(ZF.StatusTextures["Combat"][DB.Texture])
				indicator:SetTexCoord(0, 1, 0, 1)
			end
		end,
		isVisible = function(unitFrame) return UnitAffectingCombat(unitFrame.__unit) end,
	},
	Resting = {
		dbKey = "Resting",
		field = "RestingIndicator",
		applyTexture = function(indicator, DB)
			if DB.Texture == "DEFAULT" then
				indicator:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
				indicator:SetTexCoord(0, 0.5, 0, 0.421875)
			else
				indicator:SetTexture(ZF.StatusTextures["Resting"][DB.Texture])
				indicator:SetTexCoord(0, 1, 0, 1)
			end
		end,
		isVisible = function() return IsResting() end,
	},
	Classification = {
		dbKey = "Classification",
		field = "ClassificationIndicator",
		getDB = function() return ZF.db.profile.Units.target.Indicators.Classification end,
		postUpdate = function(indicator, DB, _, classification)
			local texture = ZF.ClassificationTextures[DB.Texture][classification]
			if not texture then
				indicator:Hide()
				return
			end
			local usesAtlas = DB.Texture == "CLASSIFICATION0" or DB.Texture == "CLASSIFICATION1"
			if usesAtlas then indicator:SetAtlas(texture, false) else indicator:SetTexture(texture) end
			indicator:Show()
		end,
	},
	Quest = {
		dbKey = "Quest",
		field = "QuestUnitIndicator",
		immediatePostUpdate = true,
		postUpdate = function(indicator, DB)
			indicator:SetTexture(ZF.QuestTextures[DB.Texture] or ZF.QuestTextures.DEFAULT)
			if DB.Texture == "QUEST0" then
				indicator:SetHeight(DB.Size)
				indicator:SetWidth(DB.Size * 0.35)
			else
				indicator:SetSize(DB.Size, DB.Size)
			end
		end,
	},
	Role = {
		dbKey = "Role",
		field = "GroupRoleIndicator",
		postUpdate = function(indicator, DB, role)
			role = role == Enum.LFGRole.Tank and "TANK" or role == Enum.LFGRole.Healer and "HEALER" or role == Enum.LFGRole.Damage and "DAMAGER" or nil
			local showRole = (role == "TANK" and DB.ShowTank ~= false) or (role == "HEALER" and DB.ShowHealer ~= false) or (role == "DAMAGER" and DB.ShowDamager ~= false)
			if not showRole then
				indicator:Hide()
				return
			end
			local roleTextureSet = ZF.RoleTextures[DB.Texture]
			local roleTexture = roleTextureSet and roleTextureSet[role]
			if roleTexture then
				indicator:SetTexture(roleTexture)
				indicator:SetTexCoord(0, 1, 0, 1)
			end
			indicator:Show()
		end,
	},
	ReadyCheck = {
		dbKey = "ReadyCheck",
		field = "ReadyCheckIndicator",
		enableUnit = function(unitFrame, unit) return ZF:GetNormalizedUnit(unit) end,
		postUpdate = function(indicator, DB, status)
			local textureSet = ZF.ReadyCheckTextures[DB.Texture]
			local statusTexture = textureSet and (status == "ready" and textureSet["READY"] or status == "notready" and textureSet["NOTREADY"] or status == "waiting" and textureSet["WAITING"])
			if statusTexture then
				indicator:SetTexture(statusTexture)
				indicator:SetTexCoord(0, 1, 0, 1)
			end
		end,
	},
}

local function GetIndicatorDB(spec, unitFrame, unit)
	if spec.getDB then return spec.getDB() end
	return ZF:GetUnitDB(unitFrame, unit).Indicators[spec.dbKey]
end

local function CreateSimpleIndicator(key, unitFrame, unit)
	local spec = SIMPLE_INDICATORS[key]
	local DB = GetIndicatorDB(spec, unitFrame, unit)
	if not DB then return end
	unitFrame[spec.field .. "DB"] = DB

	local indicator = CreateIndicatorTexture(unitFrame, unit, "_" .. spec.field, DB.Size, DB.Layout)
	if spec.staticTexture then indicator:SetAtlas(spec.staticTexture) end
	if spec.postUpdate then
		indicator.PostUpdate = function(ind, ...) spec.postUpdate(ind, unitFrame[spec.field .. "DB"], ...) end
		if spec.immediatePostUpdate then spec.postUpdate(indicator, DB) end
	end

	if DB.Enabled then
		unitFrame[spec.field] = indicator
		if spec.applyTexture then spec.applyTexture(indicator, DB) end
		if spec.forceShow then indicator:Show() end
		if spec.isVisible and spec.isVisible(unitFrame) then indicator:Show() end
	else
		DisableIndicatorElement(unitFrame, spec.field, indicator)
	end

	return indicator
end

local function UpdateSimpleIndicator(key, unitFrame, unit)
	local spec = SIMPLE_INDICATORS[key]
	local DB = GetIndicatorDB(spec, unitFrame, unit)
	if not DB then return end
	unitFrame[spec.field .. "DB"] = DB

	if DB.Enabled then
		unitFrame[spec.field] = unitFrame[spec.field] or CreateSimpleIndicator(key, unitFrame, unit)
		if not unitFrame[spec.field] then return end
		if not unitFrame:IsElementEnabled(spec.field) then
			if spec.enableUnit then
				unitFrame:EnableElement(spec.field, spec.enableUnit(unitFrame, unit))
			else
				unitFrame:EnableElement(spec.field)
			end
		end

		PositionIndicatorTexture(unitFrame[spec.field], unitFrame.HighLevelContainer, DB.Size, DB.Layout)
		if spec.applyTexture then spec.applyTexture(unitFrame[spec.field], DB) end

		if spec.forceShow then
			unitFrame[spec.field]:Show()
		elseif spec.isVisible then
			unitFrame[spec.field]:SetShown(spec.isVisible(unitFrame))
		end

		unitFrame[spec.field]:ForceUpdate()
	elseif unitFrame[spec.field] then
		DisableIndicatorElement(unitFrame, spec.field, unitFrame[spec.field])
		unitFrame[spec.field] = nil
	end
end

function ZF:CreateUnitResurrectIndicator(unitFrame, unit) return CreateSimpleIndicator("Resurrect", unitFrame, unit) end
function ZF:UpdateUnitResurrectIndicator(unitFrame, unit) return UpdateSimpleIndicator("Resurrect", unitFrame, unit) end

function ZF:CreateUnitSummonIndicator(unitFrame, unit) return CreateSimpleIndicator("Summon", unitFrame, unit) end
function ZF:UpdateUnitSummonIndicator(unitFrame, unit) return UpdateSimpleIndicator("Summon", unitFrame, unit) end

function ZF:CreateUnitRaidTargetMarker(unitFrame, unit) return CreateSimpleIndicator("RaidTargetMarker", unitFrame, unit) end
function ZF:UpdateUnitRaidTargetMarker(unitFrame, unit) return UpdateSimpleIndicator("RaidTargetMarker", unitFrame, unit) end

function ZF:CreateUnitCombatIndicator(unitFrame, unit) return CreateSimpleIndicator("Combat", unitFrame, unit) end
function ZF:UpdateUnitCombatIndicator(unitFrame, unit) return UpdateSimpleIndicator("Combat", unitFrame, unit) end

function ZF:CreateUnitRestingIndicator(unitFrame, unit) return CreateSimpleIndicator("Resting", unitFrame, unit) end
function ZF:UpdateUnitRestingIndicator(unitFrame, unit) return UpdateSimpleIndicator("Resting", unitFrame, unit) end

function ZF:CreateUnitClassificationIndicator(unitFrame, unit) return CreateSimpleIndicator("Classification", unitFrame, unit) end
function ZF:UpdateUnitClassificationIndicator(unitFrame, unit) return UpdateSimpleIndicator("Classification", unitFrame, unit) end

function ZF:CreateUnitQuestIndicator(unitFrame, unit) return CreateSimpleIndicator("Quest", unitFrame, unit) end
function ZF:UpdateUnitQuestIndicator(unitFrame, unit) return UpdateSimpleIndicator("Quest", unitFrame, unit) end

function ZF:CreateUnitRoleIndicator(unitFrame, unit) return CreateSimpleIndicator("Role", unitFrame, unit) end
function ZF:UpdateUnitRoleIndicator(unitFrame, unit) return UpdateSimpleIndicator("Role", unitFrame, unit) end

function ZF:CreateUnitReadyCheckIndicator(unitFrame, unit) return CreateSimpleIndicator("ReadyCheck", unitFrame, unit) end
function ZF:UpdateUnitReadyCheckIndicator(unitFrame, unit) return UpdateSimpleIndicator("ReadyCheck", unitFrame, unit) end

local PHASE_INDICATOR_FRAME_LEVEL_OFFSET = 5

function ZF:CreateUnitPhaseIndicator(unitFrame, unit)
	local PhaseDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Phase
	if not PhaseDB then return end

	local PhaseIndicator = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_PhaseIndicator", unitFrame.HighLevelContainer)
	PositionIndicatorTexture(PhaseIndicator, unitFrame.HighLevelContainer, PhaseDB.Size, PhaseDB.Layout)
	PhaseIndicator:SetFrameLevel(unitFrame.HighLevelContainer:GetFrameLevel() + PHASE_INDICATOR_FRAME_LEVEL_OFFSET)
	PhaseIndicator:EnableMouse(true)

	PhaseIndicator.Icon = PhaseIndicator:CreateTexture(nil, "OVERLAY")
	PhaseIndicator.Icon:SetAllPoints()

	if PhaseDB.Enabled then
		unitFrame.PhaseIndicator = PhaseIndicator
	else
		DisableIndicatorElement(unitFrame, "PhaseIndicator", PhaseIndicator)
	end

	return PhaseIndicator
end

function ZF:UpdateUnitPhaseIndicator(unitFrame, unit)
	local PhaseDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Phase
	if not PhaseDB then return end

	if PhaseDB.Enabled then
		unitFrame.PhaseIndicator = unitFrame.PhaseIndicator or ZF:CreateUnitPhaseIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("PhaseIndicator") then unitFrame:EnableElement("PhaseIndicator") end

		PositionIndicatorTexture(unitFrame.PhaseIndicator, unitFrame.HighLevelContainer, PhaseDB.Size, PhaseDB.Layout)
		unitFrame.PhaseIndicator:ForceUpdate()
	elseif unitFrame.PhaseIndicator then
		DisableIndicatorElement(unitFrame, "PhaseIndicator", unitFrame.PhaseIndicator)
		unitFrame.PhaseIndicator = nil
	end
end

local function PositionPvPBadge(badge, indicator, size)
	badge:ClearAllPoints()
	badge:SetSize(size * 5 / 3, size * 26 / 15)
	badge:SetPoint("CENTER", indicator, "CENTER", 0, 0)
end

function ZF:CreateUnitPvPIndicator(unitFrame, unit)
	local PvPIndicatorDB = ZF:GetUnitDB(unitFrame, unit).Indicators.PvP

	local PvPIndicator = CreateIndicatorTexture(unitFrame, unit, "_PvPIndicator", PvPIndicatorDB.Size, PvPIndicatorDB.Layout, "OVERLAY", 1)

	PvPIndicator.Badge = unitFrame.HighLevelContainer:CreateTexture(ZF:FetchFrameName(unit) .. "_PvPIndicatorBadge", "OVERLAY")
	PositionPvPBadge(PvPIndicator.Badge, PvPIndicator, PvPIndicatorDB.Size)

	if PvPIndicatorDB.Enabled then
		unitFrame.PvPIndicator = PvPIndicator
	else
		DisableIndicatorElement(unitFrame, "PvPIndicator", PvPIndicator)
		PvPIndicator.Badge:Hide()
	end

	return PvPIndicator
end

function ZF:UpdateUnitPvPIndicator(unitFrame, unit)
	local PvPIndicatorDB = ZF:GetUnitDB(unitFrame, unit).Indicators.PvP

	if PvPIndicatorDB.Enabled then
		unitFrame.PvPIndicator = unitFrame.PvPIndicator or ZF:CreateUnitPvPIndicator(unitFrame, unit)

		if not unitFrame:IsElementEnabled("PvPIndicator") then unitFrame:EnableElement("PvPIndicator") end

		if unitFrame.PvPIndicator then
			PositionIndicatorTexture(unitFrame.PvPIndicator, unitFrame.HighLevelContainer, PvPIndicatorDB.Size, PvPIndicatorDB.Layout)
			PositionPvPBadge(unitFrame.PvPIndicator.Badge, unitFrame.PvPIndicator, PvPIndicatorDB.Size)
			unitFrame.PvPIndicator:ForceUpdate()
		end
	else
		if not unitFrame.PvPIndicator then return end
		DisableIndicatorElement(unitFrame, "PvPIndicator", unitFrame.PvPIndicator)
		unitFrame.PvPIndicator.Badge:Hide()
		unitFrame.PvPIndicator = nil
	end
end

function ZF:CreateUnitLeaderAssistantIndicator(unitFrame, unit)
	local LeaderAssistantDB = ZF:GetUnitDB(unitFrame, unit).Indicators.LeaderAssistant
	if not LeaderAssistantDB then return end

	local Leader = CreateIndicatorTexture(unitFrame, unit, "_LeaderIndicator", LeaderAssistantDB.Size, LeaderAssistantDB.Layout)
	local Assistant = CreateIndicatorTexture(unitFrame, unit, "_AssistantIndicator", LeaderAssistantDB.Size, LeaderAssistantDB.Layout)

	if LeaderAssistantDB.Enabled then
		unitFrame.LeaderIndicator = Leader
		unitFrame.AssistantIndicator = Assistant
	else
		DisableIndicatorElement(unitFrame, "LeaderIndicator", Leader)
		DisableIndicatorElement(unitFrame, "AssistantIndicator", Assistant)
	end

	return Leader, Assistant
end

function ZF:UpdateUnitLeaderAssistantIndicator(unitFrame, unit)
	local LeaderAssistantDB = ZF:GetUnitDB(unitFrame, unit).Indicators.LeaderAssistant

	if LeaderAssistantDB.Enabled then
		if not unitFrame.LeaderIndicator or not unitFrame.AssistantIndicator then
			ZF:CreateUnitLeaderAssistantIndicator(unitFrame, unit)
		end

		if not unitFrame:IsElementEnabled("LeaderIndicator") then unitFrame:EnableElement("LeaderIndicator") end
		if not unitFrame:IsElementEnabled("AssistantIndicator") then unitFrame:EnableElement("AssistantIndicator") end

		if unitFrame.LeaderIndicator then
			PositionIndicatorTexture(unitFrame.LeaderIndicator, unitFrame.HighLevelContainer, LeaderAssistantDB.Size, LeaderAssistantDB.Layout)
			unitFrame.LeaderIndicator:Show()
			unitFrame.LeaderIndicator:ForceUpdate()
		end

		if unitFrame.AssistantIndicator then
			PositionIndicatorTexture(unitFrame.AssistantIndicator, unitFrame.HighLevelContainer, LeaderAssistantDB.Size, LeaderAssistantDB.Layout)
			unitFrame.AssistantIndicator:Show()
			unitFrame.AssistantIndicator:ForceUpdate()
		end
	else
		if not unitFrame.LeaderIndicator and not unitFrame.AssistantIndicator then return end
		DisableIndicatorElement(unitFrame, "LeaderIndicator", unitFrame.LeaderIndicator)
		DisableIndicatorElement(unitFrame, "AssistantIndicator", unitFrame.AssistantIndicator)
		unitFrame.LeaderIndicator = nil
		unitFrame.AssistantIndicator = nil
	end
end
