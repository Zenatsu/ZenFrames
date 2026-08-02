local _, RUF = ...

function RUF:CreateUnitRoleIndicator(unitFrame, unit)
	local RoleDB = RUF:GetUnitDB(unitFrame, unit).Indicators.Role
	if not RoleDB then return end

	local RoleIndicator = RUF:CreateIndicatorTexture(unitFrame, unit, "_RoleIndicator", RoleDB.Size, RoleDB.Layout)
	RoleIndicator.PostUpdate = function(textureElement, role)
		local showRole = (role == "TANK" and RoleDB.ShowTank ~= false) or (role == "HEALER" and RoleDB.ShowHealer ~= false) or (role == "DAMAGER" and RoleDB.ShowDamager ~= false)
		if not showRole then textureElement:Hide() return end
		local roleTexture = RUF.RoleTextures[RoleDB.Texture] and RUF.RoleTextures[RoleDB.Texture][role]
		if roleTexture then
			textureElement:SetTexture(roleTexture)
			textureElement:SetTexCoord(0, 1, 0, 1)
		end
		textureElement:Show()
	end

	if RoleDB.Enabled then
		unitFrame.GroupRoleIndicator = RoleIndicator
	else
		RUF:DisableIndicatorElement(unitFrame, "GroupRoleIndicator", RoleIndicator)
	end

	return RoleIndicator
end

function RUF:UpdateUnitRoleIndicator(unitFrame, unit)
	local RoleDB = RUF:GetUnitDB(unitFrame, unit).Indicators.Role
	if not RoleDB then return end

	if RoleDB.Enabled then
		unitFrame.GroupRoleIndicator = unitFrame.GroupRoleIndicator or RUF:CreateUnitRoleIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("GroupRoleIndicator") then unitFrame:EnableElement("GroupRoleIndicator") end

		RUF:PositionIndicatorTexture(unitFrame.GroupRoleIndicator, unitFrame.HighLevelContainer, RoleDB.Size, RoleDB.Layout)
		unitFrame.GroupRoleIndicator:ForceUpdate()
	elseif unitFrame.GroupRoleIndicator then
		RUF:DisableIndicatorElement(unitFrame, "GroupRoleIndicator", unitFrame.GroupRoleIndicator)
		unitFrame.GroupRoleIndicator = nil
	end
end
