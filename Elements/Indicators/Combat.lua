local _, ZF = ...

function ZF:CreateUnitCombatIndicator(unitFrame, unit)
    local CombatDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Combat

    local Combat = ZF:CreateIndicatorTexture(unitFrame, unit, "_CombatIndicator", CombatDB.Size, CombatDB.Layout)

    if CombatDB.Enabled then
        unitFrame.CombatIndicator = Combat
        if CombatDB.Texture == "DEFAULT" then
            Combat:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
            Combat:SetTexCoord(0.5, 1, 0, 0.49)
        else
            Combat:SetTexture(ZF.StatusTextures["Combat"][CombatDB.Texture])
            Combat:SetTexCoord(0, 1, 0, 1)
        end
        if UnitAffectingCombat(unitFrame.__unit) then Combat:Show() end
    else
        ZF:DisableIndicatorElement(unitFrame, "CombatIndicator", Combat)
    end

    return Combat
end

function ZF:UpdateUnitCombatIndicator(unitFrame, unit)
    local CombatDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Combat

    if CombatDB.Enabled then
        unitFrame.CombatIndicator = unitFrame.CombatIndicator or ZF:CreateUnitCombatIndicator(unitFrame, unit)

        if not unitFrame:IsElementEnabled("CombatIndicator") then unitFrame:EnableElement("CombatIndicator") end

        if unitFrame.CombatIndicator then
            ZF:PositionIndicatorTexture(unitFrame.CombatIndicator, unitFrame.HighLevelContainer, CombatDB.Size, CombatDB.Layout)
            if CombatDB.Texture == "DEFAULT" then
                unitFrame.CombatIndicator:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
                unitFrame.CombatIndicator:SetTexCoord(0.5, 1, 0, 0.49)
            else
                unitFrame.CombatIndicator:SetTexture(ZF.StatusTextures["Combat"][CombatDB.Texture])
                unitFrame.CombatIndicator:SetTexCoord(0, 1, 0, 1)
            end
            if UnitAffectingCombat(unitFrame.__unit) then
                unitFrame.CombatIndicator:Show()
            else
                unitFrame.CombatIndicator:Hide()
            end
        end
    else
        if not unitFrame.CombatIndicator then return end
        ZF:DisableIndicatorElement(unitFrame, "CombatIndicator", unitFrame.CombatIndicator)
        unitFrame.CombatIndicator = nil
    end
end
