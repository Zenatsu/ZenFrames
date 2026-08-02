local _, RUF = ...

function RUF:CreateUnitRaidTargetMarker(unitFrame, unit)
    local RaidTargetMarkerDB = RUF:GetUnitDB(unitFrame, unit).Indicators.RaidTargetMarker

    local RaidTargetMarker = RUF:CreateIndicatorTexture(unitFrame, unit, "_RaidTargetMarkerIndicator", RaidTargetMarkerDB.Size, RaidTargetMarkerDB.Layout)

    if RaidTargetMarkerDB.Enabled then
        unitFrame.RaidTargetIndicator = RaidTargetMarker
        unitFrame.RaidTargetIndicator:Show()
    else
        RUF:DisableIndicatorElement(unitFrame, "RaidTargetIndicator", RaidTargetMarker)
    end

    return RaidTargetMarker
end

function RUF:UpdateUnitRaidTargetMarker(unitFrame, unit)
    local RaidTargetMarkerDB = RUF:GetUnitDB(unitFrame, unit).Indicators.RaidTargetMarker

    if RaidTargetMarkerDB.Enabled then
        unitFrame.RaidTargetIndicator = unitFrame.RaidTargetIndicator or RUF:CreateUnitRaidTargetMarker(unitFrame, unit)

        if not unitFrame:IsElementEnabled("RaidTargetIndicator") then unitFrame:EnableElement("RaidTargetIndicator") end

        if unitFrame.RaidTargetIndicator then
            RUF:PositionIndicatorTexture(unitFrame.RaidTargetIndicator, unitFrame.HighLevelContainer, RaidTargetMarkerDB.Size, RaidTargetMarkerDB.Layout)
            unitFrame.RaidTargetIndicator:Show()
            unitFrame.RaidTargetIndicator:ForceUpdate()
        end
    else
        if not unitFrame.RaidTargetIndicator then return end
        RUF:DisableIndicatorElement(unitFrame, "RaidTargetIndicator", unitFrame.RaidTargetIndicator)
        unitFrame.RaidTargetIndicator = nil
    end
end
