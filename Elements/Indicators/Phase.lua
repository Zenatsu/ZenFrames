local _, ZF = ...

-- Sits a few levels above the container so it isn't hidden behind health
-- bar overlays, and takes mouse input for its (future) tooltip.
local PHASE_INDICATOR_FRAME_LEVEL_OFFSET = 5

function ZF:CreateUnitPhaseIndicator(unitFrame, unit)
    local PhaseDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Phase
    if not PhaseDB then return end

    local PhaseIndicator = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_PhaseIndicator", unitFrame.HighLevelContainer)
    PhaseIndicator:SetSize(PhaseDB.Size, PhaseDB.Size)
    PhaseIndicator:SetPoint(PhaseDB.Layout[1], unitFrame.HighLevelContainer, PhaseDB.Layout[2], PhaseDB.Layout[3], PhaseDB.Layout[4])
    PhaseIndicator:SetFrameLevel(unitFrame.HighLevelContainer:GetFrameLevel() + PHASE_INDICATOR_FRAME_LEVEL_OFFSET)
    PhaseIndicator:EnableMouse(true)

    PhaseIndicator.Icon = PhaseIndicator:CreateTexture(nil, "OVERLAY")
    PhaseIndicator.Icon:SetAllPoints()

    if PhaseDB.Enabled then
        unitFrame.PhaseIndicator = PhaseIndicator
    else
        ZF:DisableIndicatorElement(unitFrame, "PhaseIndicator", PhaseIndicator)
    end

    return PhaseIndicator
end

function ZF:UpdateUnitPhaseIndicator(unitFrame, unit)
    local PhaseDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Phase
    if not PhaseDB then return end

    if PhaseDB.Enabled then
        unitFrame.PhaseIndicator = unitFrame.PhaseIndicator or ZF:CreateUnitPhaseIndicator(unitFrame, unit)
        if not unitFrame:IsElementEnabled("PhaseIndicator") then unitFrame:EnableElement("PhaseIndicator") end

        ZF:PositionIndicatorTexture(unitFrame.PhaseIndicator, unitFrame.HighLevelContainer, PhaseDB.Size, PhaseDB.Layout)
        unitFrame.PhaseIndicator:ForceUpdate()
    elseif unitFrame.PhaseIndicator then
        ZF:DisableIndicatorElement(unitFrame, "PhaseIndicator", unitFrame.PhaseIndicator)
        unitFrame.PhaseIndicator = nil
    end
end
