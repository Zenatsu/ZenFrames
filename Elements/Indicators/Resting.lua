local _, RUF = ...

function RUF:CreateUnitRestingIndicator(unitFrame, unit)
    local RestingDB = RUF:GetUnitDB(unitFrame, unit).Indicators.Resting

    local Resting = RUF:CreateIndicatorTexture(unitFrame, unit, "_RestingIndicator", RestingDB.Size, RestingDB.Layout)

    if RestingDB.Enabled then
        unitFrame.RestingIndicator = Resting
        if RestingDB.Texture == "DEFAULT" then
            Resting:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
            Resting:SetTexCoord(0, 0.5, 0, 0.421875)
        else
            Resting:SetTexture(RUF.StatusTextures["Resting"][RestingDB.Texture])
            Resting:SetTexCoord(0, 1, 0, 1)
        end
        if IsResting() then Resting:Show() end
    else
        RUF:DisableIndicatorElement(unitFrame, "RestingIndicator", Resting)
    end

    return Resting
end

function RUF:UpdateUnitRestingIndicator(unitFrame, unit)
    local RestingDB = RUF:GetUnitDB(unitFrame, unit).Indicators.Resting

    if RestingDB.Enabled then
        unitFrame.RestingIndicator = unitFrame.RestingIndicator or RUF:CreateUnitRestingIndicator(unitFrame, unit)

        if not unitFrame:IsElementEnabled("RestingIndicator") then unitFrame:EnableElement("RestingIndicator") end

        if unitFrame.RestingIndicator then
            RUF:PositionIndicatorTexture(unitFrame.RestingIndicator, unitFrame.HighLevelContainer, RestingDB.Size, RestingDB.Layout)
            if RestingDB.Texture == "DEFAULT" then
                unitFrame.RestingIndicator:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
                unitFrame.RestingIndicator:SetTexCoord(0, 0.5, 0, 0.421875)
            else
                unitFrame.RestingIndicator:SetTexture(RUF.StatusTextures["Resting"][RestingDB.Texture])
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
        RUF:DisableIndicatorElement(unitFrame, "RestingIndicator", unitFrame.RestingIndicator)
        unitFrame.RestingIndicator = nil
    end
end
