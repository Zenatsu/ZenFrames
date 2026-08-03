local _, ZF = ...

function ZF:CreateUnitRaidTargetMarker(unitFrame, unit)
    local RaidTargetMarkerDB = ZF:GetUnitDB(unitFrame, unit).Indicators.RaidTargetMarker

    local RaidTargetMarker = ZF:CreateIndicatorTexture(unitFrame, unit, "_RaidTargetMarkerIndicator", RaidTargetMarkerDB.Size, RaidTargetMarkerDB.Layout)

    if RaidTargetMarkerDB.Enabled then
        unitFrame.RaidTargetIndicator = RaidTargetMarker
        unitFrame.RaidTargetIndicator:Show()
    else
        ZF:DisableIndicatorElement(unitFrame, "RaidTargetIndicator", RaidTargetMarker)
    end

    return RaidTargetMarker
end

function ZF:UpdateUnitRaidTargetMarker(unitFrame, unit)
    local RaidTargetMarkerDB = ZF:GetUnitDB(unitFrame, unit).Indicators.RaidTargetMarker

    if RaidTargetMarkerDB.Enabled then
        unitFrame.RaidTargetIndicator = unitFrame.RaidTargetIndicator or ZF:CreateUnitRaidTargetMarker(unitFrame, unit)

        if not unitFrame:IsElementEnabled("RaidTargetIndicator") then unitFrame:EnableElement("RaidTargetIndicator") end

        if unitFrame.RaidTargetIndicator then
            ZF:PositionIndicatorTexture(unitFrame.RaidTargetIndicator, unitFrame.HighLevelContainer, RaidTargetMarkerDB.Size, RaidTargetMarkerDB.Layout)
            unitFrame.RaidTargetIndicator:Show()
            unitFrame.RaidTargetIndicator:ForceUpdate()
        end
    else
        if not unitFrame.RaidTargetIndicator then return end
        ZF:DisableIndicatorElement(unitFrame, "RaidTargetIndicator", unitFrame.RaidTargetIndicator)
        unitFrame.RaidTargetIndicator = nil
    end
end
