local _, ZF = ...

local function PositionPvPBadge(badge, indicator, size)
    badge:ClearAllPoints()
    badge:SetSize(size * 5 / 3, size * 26 / 15)
    badge:SetPoint("CENTER", indicator, "CENTER", 0, 0)
end

function ZF:CreateUnitPvPIndicator(unitFrame, unit)
    local PvPIndicatorDB = ZF.db.profile.Units.player.Indicators.PvP

    local PvPIndicator = ZF:CreateIndicatorTexture(unitFrame, unit, "_PvPIndicator", PvPIndicatorDB.Size, PvPIndicatorDB.Layout, "OVERLAY", 1)

    PvPIndicator.Badge = unitFrame.HighLevelContainer:CreateTexture(ZF:FetchFrameName(unit) .. "_PvPIndicatorBadge", "OVERLAY")
    PositionPvPBadge(PvPIndicator.Badge, PvPIndicator, PvPIndicatorDB.Size)

    if PvPIndicatorDB.Enabled then
        unitFrame.PvPIndicator = PvPIndicator
    else
        ZF:DisableIndicatorElement(unitFrame, "PvPIndicator", PvPIndicator)
        PvPIndicator.Badge:Hide()
    end

    return PvPIndicator
end

function ZF:UpdateUnitPvPIndicator(unitFrame, unit)
    local PvPIndicatorDB = ZF.db.profile.Units.player.Indicators.PvP

    if PvPIndicatorDB.Enabled then
        unitFrame.PvPIndicator = unitFrame.PvPIndicator or ZF:CreateUnitPvPIndicator(unitFrame, unit)

        if not unitFrame:IsElementEnabled("PvPIndicator") then unitFrame:EnableElement("PvPIndicator") end

        if unitFrame.PvPIndicator then
            ZF:PositionIndicatorTexture(unitFrame.PvPIndicator, unitFrame.HighLevelContainer, PvPIndicatorDB.Size, PvPIndicatorDB.Layout)
            PositionPvPBadge(unitFrame.PvPIndicator.Badge, unitFrame.PvPIndicator, PvPIndicatorDB.Size)
            unitFrame.PvPIndicator:ForceUpdate()
        end
    else
        if not unitFrame.PvPIndicator then return end
        ZF:DisableIndicatorElement(unitFrame, "PvPIndicator", unitFrame.PvPIndicator)
        unitFrame.PvPIndicator.Badge:Hide()
        unitFrame.PvPIndicator = nil
    end
end
