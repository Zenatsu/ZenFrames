local _, ZF = ...

function ZF:CreateUnitRoleIndicator(unitFrame, unit)
    local RoleDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Role
    if not RoleDB then return end

    local RoleIndicator = ZF:CreateIndicatorTexture(unitFrame, unit, "_RoleIndicator", RoleDB.Size, RoleDB.Layout)
    RoleIndicator.PostUpdate = function(textureElement, role)
        local showRole = (role == "TANK" and RoleDB.ShowTank ~= false) or (role == "HEALER" and RoleDB.ShowHealer ~= false) or (role == "DAMAGER" and RoleDB.ShowDamager ~= false)
        if not showRole then
            textureElement:Hide()
            return
        end

        local roleTextureSet = ZF.RoleTextures[RoleDB.Texture]
        local roleTexture = roleTextureSet and roleTextureSet[role]
        if roleTexture then
            textureElement:SetTexture(roleTexture)
            textureElement:SetTexCoord(0, 1, 0, 1)
        end
        textureElement:Show()
    end

    if RoleDB.Enabled then
        unitFrame.GroupRoleIndicator = RoleIndicator
    else
        ZF:DisableIndicatorElement(unitFrame, "GroupRoleIndicator", RoleIndicator)
    end

    return RoleIndicator
end

function ZF:UpdateUnitRoleIndicator(unitFrame, unit)
    local RoleDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Role
    if not RoleDB then return end

    if RoleDB.Enabled then
        unitFrame.GroupRoleIndicator = unitFrame.GroupRoleIndicator or ZF:CreateUnitRoleIndicator(unitFrame, unit)
        if not unitFrame:IsElementEnabled("GroupRoleIndicator") then unitFrame:EnableElement("GroupRoleIndicator") end

        ZF:PositionIndicatorTexture(unitFrame.GroupRoleIndicator, unitFrame.HighLevelContainer, RoleDB.Size, RoleDB.Layout)
        unitFrame.GroupRoleIndicator:ForceUpdate()
    elseif unitFrame.GroupRoleIndicator then
        ZF:DisableIndicatorElement(unitFrame, "GroupRoleIndicator", unitFrame.GroupRoleIndicator)
        unitFrame.GroupRoleIndicator = nil
    end
end
