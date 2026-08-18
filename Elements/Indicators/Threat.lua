local _, ZF = ...

local GLOW_INSET = 3

function ZF:CreateThreatIndicatorOverlay(unitFrame, unit)
    local overlay = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_ThreatIndicator", unitFrame.Container, "BackdropTemplate")
    overlay:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 4)
    overlay:SetBackdrop({ edgeFile = ZF.Media.Solid, edgeSize = GLOW_INSET, insets = {left = -GLOW_INSET, right = -GLOW_INSET, top = -GLOW_INSET, bottom = -GLOW_INSET} })
    overlay:SetBackdropColor(0, 0, 0, 0)
    overlay:SetBackdropBorderColor(1, 1, 1, 1)
    overlay:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", -GLOW_INSET, GLOW_INSET)
    overlay:SetPoint("BOTTOMRIGHT", unitFrame.Container, "BOTTOMRIGHT", GLOW_INSET, -GLOW_INSET)
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

    local overlay = ZF:CreateThreatIndicatorOverlay(unitFrame, unit)
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
