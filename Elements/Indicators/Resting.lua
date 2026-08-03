local _, ZF = ...

function ZF:CreateUnitRestingIndicator(unitFrame, unit)
    local RestingDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Resting

    local Resting = ZF:CreateIndicatorTexture(unitFrame, unit, "_RestingIndicator", RestingDB.Size, RestingDB.Layout)

    if RestingDB.Enabled then
        unitFrame.RestingIndicator = Resting
        if RestingDB.Texture == "DEFAULT" then
            Resting:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
            Resting:SetTexCoord(0, 0.5, 0, 0.421875)
        else
            Resting:SetTexture(ZF.StatusTextures["Resting"][RestingDB.Texture])
            Resting:SetTexCoord(0, 1, 0, 1)
        end
        if IsResting() then Resting:Show() end
    else
        ZF:DisableIndicatorElement(unitFrame, "RestingIndicator", Resting)
    end

    return Resting
end

function ZF:UpdateUnitRestingIndicator(unitFrame, unit)
    local RestingDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Resting

    if RestingDB.Enabled then
        unitFrame.RestingIndicator = unitFrame.RestingIndicator or ZF:CreateUnitRestingIndicator(unitFrame, unit)

        if not unitFrame:IsElementEnabled("RestingIndicator") then unitFrame:EnableElement("RestingIndicator") end

        if unitFrame.RestingIndicator then
            ZF:PositionIndicatorTexture(unitFrame.RestingIndicator, unitFrame.HighLevelContainer, RestingDB.Size, RestingDB.Layout)
            if RestingDB.Texture == "DEFAULT" then
                unitFrame.RestingIndicator:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
                unitFrame.RestingIndicator:SetTexCoord(0, 0.5, 0, 0.421875)
            else
                unitFrame.RestingIndicator:SetTexture(ZF.StatusTextures["Resting"][RestingDB.Texture])
                unitFrame.RestingIndicator:SetTexCoord(0, 1, 0, 1)
            end
            if IsResting() then
                unitFrame.RestingIndicator:Show()
            else
                unitFrame.RestingIndicator:Hide()
            end
        end
    else
        if not unitFrame.RestingIndicator then return end
        ZF:DisableIndicatorElement(unitFrame, "RestingIndicator", unitFrame.RestingIndicator)
        unitFrame.RestingIndicator = nil
    end
end
