local _, ZF = ...

function ZF:CreateUnitSummonIndicator(unitFrame, unit)
    local SummonDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Summon
    if not SummonDB then return end

    local SummonIndicator = ZF:CreateIndicatorTexture(unitFrame, unit, "_SummonIndicator", SummonDB.Size, SummonDB.Layout)

    if SummonDB.Enabled then
        unitFrame.SummonIndicator = SummonIndicator
    else
        ZF:DisableIndicatorElement(unitFrame, "SummonIndicator", SummonIndicator)
    end

    return SummonIndicator
end

function ZF:UpdateUnitSummonIndicator(unitFrame, unit)
    local SummonDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Summon
    if not SummonDB then return end

    if SummonDB.Enabled then
        unitFrame.SummonIndicator = unitFrame.SummonIndicator or ZF:CreateUnitSummonIndicator(unitFrame, unit)
        if not unitFrame:IsElementEnabled("SummonIndicator") then unitFrame:EnableElement("SummonIndicator") end

        ZF:PositionIndicatorTexture(unitFrame.SummonIndicator, unitFrame.HighLevelContainer, SummonDB.Size, SummonDB.Layout)
        unitFrame.SummonIndicator:ForceUpdate()
    elseif unitFrame.SummonIndicator then
        ZF:DisableIndicatorElement(unitFrame, "SummonIndicator", unitFrame.SummonIndicator)
        unitFrame.SummonIndicator = nil
    end
end
