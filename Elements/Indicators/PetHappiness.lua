local _, ZF = ...
local oUF = ZF.oUF

local HAPPINESS_EVENTS = { "UNIT_POWER_UPDATE", "UNIT_PET" }

function ZF:SetPetHappinessTexture(region, level)
	local textureName = ZF.PetHappinessTextures[level]
	if not textureName then
		region:Hide()
		return
	end
	if C_Texture.GetAtlasInfo(textureName) then
		region:SetAtlas(textureName, false)
	else
		region:SetTexture(ZF.PetHappinessTexturePath .. textureName)
		region:SetTexCoord(0, 1, 0, 1)
	end
end

local POLL_INTERVAL = 0.5

local function ReadHappiness()
	if C_PetInfo and C_PetInfo.GetPetHappiness then return C_PetInfo.GetPetHappiness() end
	if PetFrameHappiness and PetFrameHappiness.GetHappinessStats then return PetFrameHappiness:GetHappinessStats() end
end

local function GetHappinessStats()
	local level, damagePercentage, loyaltyRate = ReadHappiness()
	if ZF:IsSecretValue(level) or not ZF.PetHappinessTextures[level] then return end
	return level, damagePercentage, loyaltyRate
end

local function GetLoyaltyLevel()
	if not C_PetInfo or not C_PetInfo.GetPetLoyalty then return end
	local loyaltyLevel = C_PetInfo.GetPetLoyalty()
	if type(loyaltyLevel) ~= "string" or ZF:IsSecretValue(loyaltyLevel) or loyaltyLevel == "" then return end
	return loyaltyLevel
end

local function GetFoodTypes()
	local foodTypes = {}
	if not C_PetInfo or not C_PetInfo.GetPetFoodTypes then return foodTypes end
	local result = C_PetInfo.GetPetFoodTypes()
	if type(result) ~= "table" then return foodTypes end
	for key, value in pairs(result) do
		if type(value) == "string" and not ZF:IsSecretValue(value) then
			foodTypes[#foodTypes + 1] = value
		elseif value == true and type(key) == "string" then
			foodTypes[#foodTypes + 1] = key
		end
	end
	table.sort(foodTypes)
	return foodTypes
end

ZF.GetPetHappinessStats = GetHappinessStats
ZF.GetPetLoyaltyLevel = GetLoyaltyLevel
ZF.GetPetFoodTypes = GetFoodTypes

local function ShowHappinessTooltip(hover)
	local level, damagePercentage, loyaltyRate = GetHappinessStats()
	if not level then return end
	GameTooltip:SetOwner(hover, "ANCHOR_RIGHT")
	GameTooltip:SetText(_G["PET_HAPPINESS" .. level], NORMAL_FONT_COLOR:GetRGB())
	if damagePercentage and not ZF:IsSecretValue(damagePercentage) then
		GameTooltip:AddLine(string.format(PET_DAMAGE_PERCENTAGE, damagePercentage), 1, 1, 1)
	end
	local loyaltyLevel = GetLoyaltyLevel()
	if loyaltyLevel then GameTooltip:AddLine("Loyalty: " .. loyaltyLevel, 0.8, 0.8, 1) end
	local foodTypes = GetFoodTypes()
	if #foodTypes > 0 then GameTooltip:AddLine("Diet: " .. table.concat(foodTypes, ", "), 0.8, 0.8, 1) end
	if loyaltyRate and not ZF:IsSecretValue(loyaltyRate) then
		if loyaltyRate < 0 then
			GameTooltip:AddLine(LOSING_LOYALTY, 1, 0.3, 0.3)
		elseif loyaltyRate > 0 then
			GameTooltip:AddLine(GAINING_LOYALTY, 0.3, 1, 0.3)
		end
	end
	GameTooltip:Show()
end

local function Update(self, event, unit)
	if event ~= "UNIT_PET" and unit and unit ~= self.__unit then return end

	local element = self.PetHappinessIndicator
	if element.PreUpdate then element:PreUpdate() end

	local level = GetHappinessStats()
	if level then
		ZF:SetPetHappinessTexture(element, level)
		element:Show()
	else
		element:Hide()
	end
	if element.Hover then element.Hover:SetShown(level ~= nil) end

	if element.PostUpdate then return element:PostUpdate(level) end
end

local function Path(self, ...)
	return (self.PetHappinessIndicator.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.__unit)
end

local function Enable(self)
	local element = self.PetHappinessIndicator
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		for _, event in ipairs(HAPPINESS_EVENTS) do
			if C_EventUtils.IsEventValid(event) then self:RegisterEvent(event, Path) end
		end

		local poller = self.PetHappinessPoller or CreateFrame("Frame", nil, self)
		self.PetHappinessPoller = poller
		poller.elapsed = 0
		poller.lastLevel = nil
		poller:SetScript("OnUpdate", function(frame, elapsed)
			frame.elapsed = frame.elapsed + elapsed
			if frame.elapsed < POLL_INTERVAL then return end
			frame.elapsed = 0
			local level = GetHappinessStats()
			if level ~= frame.lastLevel then
				frame.lastLevel = level
				Path(self, "Poll", self.__unit)
			end
		end)
		return true
	end
end

local function Disable(self)
	local element = self.PetHappinessIndicator
	if element then
		element:Hide()
		if element.Hover then element.Hover:Hide() end
		if self.PetHappinessPoller then self.PetHappinessPoller:SetScript("OnUpdate", nil) end
		for _, event in ipairs(HAPPINESS_EVENTS) do
			if C_EventUtils.IsEventValid(event) then self:UnregisterEvent(event, Path) end
		end
	end
end

oUF:AddElement("PetHappinessIndicator", Path, Enable, Disable)

local function PlaceCluster(indicator, DB, container)
	local cluster = indicator.Cluster
	cluster:ClearAllPoints()
	cluster:SetPoint(DB.Layout[1], container, DB.Layout[2], DB.Layout[3], DB.Layout[4])
	cluster:SetSize(DB.Size, DB.Size)
	indicator:ClearAllPoints()
	indicator:SetAllPoints(cluster)
end

local function CreatePetHappinessTexture(unitFrame, unit, DB)
	local cluster = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_PetHappinessCluster", unitFrame.HighLevelContainer)
	local texture = cluster:CreateTexture(ZF:FetchFrameName(unit) .. "_PetHappinessIndicator", "OVERLAY")
	texture.Cluster = cluster

	local hover = CreateFrame("Frame", nil, cluster)
	hover:SetAllPoints(cluster)
	hover:SetFrameLevel(cluster:GetFrameLevel() + 1)
	hover:EnableMouse(true)
	hover:Hide()
	hover:SetScript("OnEnter", ShowHappinessTooltip)
	hover:SetScript("OnLeave", GameTooltip_Hide)
	texture.Hover = hover

	PlaceCluster(texture, DB, unitFrame.HighLevelContainer)
	return texture
end

function ZF:CreateUnitPetHappinessIndicator(unitFrame, unit)
	if not ZF.IS_FOREVER then return end
	local DB = ZF:GetUnitDB(unitFrame, unit).Indicators.PetHappiness
	if not DB then return end

	local indicator = CreatePetHappinessTexture(unitFrame, unit, DB)
	if DB.Enabled then
		unitFrame.PetHappinessIndicator = indicator
	else
		indicator.Cluster:Hide()
		indicator:Hide()
		indicator.Hover:Hide()
	end
	return indicator
end

function ZF:UpdateUnitPetHappinessIndicator(unitFrame, unit)
	if not ZF.IS_FOREVER then return end
	local DB = ZF:GetUnitDB(unitFrame, unit).Indicators.PetHappiness
	if not DB then return end

	if DB.Enabled then
		unitFrame.PetHappinessIndicator = unitFrame.PetHappinessIndicator or ZF:CreateUnitPetHappinessIndicator(unitFrame, unit)
		local indicator = unitFrame.PetHappinessIndicator
		if not indicator then return end
		if not unitFrame:IsElementEnabled("PetHappinessIndicator") then unitFrame:EnableElement("PetHappinessIndicator") end

		PlaceCluster(indicator, DB, unitFrame.HighLevelContainer)
		indicator.Cluster:Show()
		ForceUpdate(indicator)
	elseif unitFrame.PetHappinessIndicator then
		if unitFrame:IsElementEnabled("PetHappinessIndicator") then unitFrame:DisableElement("PetHappinessIndicator") end
		unitFrame.PetHappinessIndicator.Cluster:Hide()
		unitFrame.PetHappinessIndicator:Hide()
		unitFrame.PetHappinessIndicator.Hover:Hide()
		unitFrame.PetHappinessIndicator = nil
	end
end
