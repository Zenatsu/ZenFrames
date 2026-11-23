local _, ZF = ...

local GLOW_INSET = 3

function ZF:CreateThreatIndicatorOverlay(unitFrame, unit)
    local overlay = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_ThreatIndicator", unitFrame.Container, "BackdropTemplate")
    overlay:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 4)
    ZF:ApplyOutsetBorder(overlay, unitFrame.Container, GLOW_INSET, ZF.Media.Solid)
    overlay:SetBackdropColor(0, 0, 0, 0)
    overlay:SetBackdropBorderColor(1, 1, 1, 1)
    overlay:SetAlpha(0)
    overlay:Hide()

    overlay.PostUpdate = function(element, _, status, color)
        if status and status > 0 and color then
            element:SetBackdropBorderColor(color:GetRGB())
            element:SetAlpha(1)
        else
            element:SetAlpha(0)
        end
    end

    return overlay
end

function ZF:CreateUnitThreatIndicator(unitFrame, unit)
    local ThreatDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Threat
    if not ThreatDB then return end

    unitFrame.ThreatOverlay = unitFrame.ThreatOverlay or ZF:CreateThreatIndicatorOverlay(unitFrame, unit)
    local overlay = unitFrame.ThreatOverlay
    if ThreatDB.Enabled then
        unitFrame.ThreatIndicator = overlay
    else
        overlay:Hide()
    end

    return overlay
end

function ZF:UpdateUnitThreatIndicator(unitFrame, unit)
    local ThreatDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Threat
    if not ThreatDB then return end

    if ThreatDB.Enabled then
        unitFrame.ThreatIndicator = unitFrame.ThreatIndicator or ZF:CreateUnitThreatIndicator(unitFrame, unit)
        if not unitFrame:IsElementEnabled("ThreatIndicator") then unitFrame:EnableElement("ThreatIndicator") end
        if unitFrame.ThreatIndicator then unitFrame.ThreatIndicator:ForceUpdate() end
    elseif unitFrame.ThreatIndicator then
        if unitFrame:IsElementEnabled("ThreatIndicator") then unitFrame:DisableElement("ThreatIndicator") end
        unitFrame.ThreatIndicator:SetAlpha(0)
        unitFrame.ThreatIndicator:Hide()
        unitFrame.ThreatIndicator = nil
    end
end

local ThreatTargetEventFrame = CreateFrame("Frame")
ThreatTargetEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
ThreatTargetEventFrame:SetScript("OnEvent", function()
    if ZF.TARGET then ZF:UpdateUnitThreatIndicator(ZF.TARGET, "target") end
end)
