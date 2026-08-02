local _, RUF = ...

function RUF:CreateUnitPvPIndicator(unitFrame, unit)
    local PvPIndicatorDB = RUF.db.profile.Units.player.Indicators.PvP

    local PvPIndicator = RUF:CreateIndicatorTexture(unitFrame, unit, "_PvPIndicator", PvPIndicatorDB.Size, PvPIndicatorDB.Layout, "OVERLAY", 1)

    PvPIndicator.Badge = unitFrame.HighLevelContainer:CreateTexture(RUF:FetchFrameName(unit) .. "_PvPIndicatorBadge", "OVERLAY")
    PvPIndicator.Badge:SetSize(PvPIndicatorDB.Size * 5 / 3, PvPIndicatorDB.Size * 26 / 15)
    PvPIndicator.Badge:SetPoint("CENTER", PvPIndicator, "CENTER", 0, 0)

    if PvPIndicatorDB.Enabled then
        unitFrame.PvPIndicator = PvPIndicator
    else
        RUF:DisableIndicatorElement(unitFrame, "PvPIndicator", PvPIndicator)
        PvPIndicator.Badge:Hide()
    end

    return PvPIndicator
end

function RUF:UpdateUnitPvPIndicator(unitFrame, unit)
    local PvPIndicatorDB = RUF.db.profile.Units.player.Indicators.PvP

    if PvPIndicatorDB.Enabled then
        unitFrame.PvPIndicator = unitFrame.PvPIndicator or RUF:CreateUnitPvPIndicator(unitFrame, unit)

        if not unitFrame:IsElementEnabled("PvPIndicator") then unitFrame:EnableElement("PvPIndicator") end

        if unitFrame.PvPIndicator then
            RUF:PositionIndicatorTexture(unitFrame.PvPIndicator, unitFrame.HighLevelContainer, PvPIndicatorDB.Size, PvPIndicatorDB.Layout)
            unitFrame.PvPIndicator.Badge:ClearAllPoints()
            unitFrame.PvPIndicator.Badge:SetSize(PvPIndicatorDB.Size * 5 / 3, PvPIndicatorDB.Size * 26 / 15)
            unitFrame.PvPIndicator.Badge:SetPoint("CENTER", unitFrame.PvPIndicator, "CENTER", 0, 0)
            unitFrame.PvPIndicator:ForceUpdate()
        end
    else
        if not unitFrame.PvPIndicator then return end
        RUF:DisableIndicatorElement(unitFrame, "PvPIndicator", unitFrame.PvPIndicator)
        unitFrame.PvPIndicator.Badge:Hide()
        unitFrame.PvPIndicator = nil
    end
end
