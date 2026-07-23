local _, RUF = ...

local ALTERNATIVE_POWER_BAR_EVENTS = {
    "UNIT_POWER_UPDATE",
    "UNIT_MAXPOWER",
    "UNIT_DISPLAYPOWER",
}

local function UpdateUnitPowerBarValues(unitFrame, event, unit)
    if unit and unit ~= unitFrame.unit then return end
    if not UnitExists(unitFrame.unit) then return end

    local value = UnitPower(unitFrame.unit, Enum.PowerType.Mana)
    unitFrame.Status:SetMinMaxValues(0, UnitPowerMax(unitFrame.unit, Enum.PowerType.Mana))
    unitFrame.Status:SetValue(value)
end


function RUF:CreateUnitAlternativePowerBar(unitFrame, unit)
    local RUFDB = RUF.db.profile
    local AlternativePowerBarDB = RUFDB.Units["player"].AlternativePowerBar
    local unitContainer = unitFrame.Container

    local AlternativePowerBar = CreateFrame("Frame", RUF:FetchFrameName(unit).."_AlternativePowerBar", unitContainer, "BackdropTemplate")
    AlternativePowerBar:SetPoint(AlternativePowerBarDB.Layout[1], unitContainer, AlternativePowerBarDB.Layout[2], AlternativePowerBarDB.Layout[3], AlternativePowerBarDB.Layout[4])
    AlternativePowerBar:SetSize(AlternativePowerBarDB.Width, AlternativePowerBarDB.Height)
    AlternativePowerBar:SetBackdrop(RUF.BACKDROP)
    AlternativePowerBar:SetBackdropColor(AlternativePowerBarDB.Background[1], AlternativePowerBarDB.Background[2], AlternativePowerBarDB.Background[3], AlternativePowerBarDB.Background[4])
    AlternativePowerBar:SetBackdropBorderColor(0, 0, 0, 1)
    AlternativePowerBar:SetFrameLevel(unitContainer:GetFrameLevel() + 5)

    AlternativePowerBar.Status = CreateFrame("StatusBar", RUF:FetchFrameName(unit).."_AlternativePowerBar", AlternativePowerBar)
    AlternativePowerBar.Status:SetPoint("TOPLEFT", AlternativePowerBar, "TOPLEFT", 1, -1)
    AlternativePowerBar.Status:SetPoint("BOTTOMRIGHT", AlternativePowerBar, "BOTTOMRIGHT", -1, 1)
    AlternativePowerBar.Status:SetSize(AlternativePowerBarDB.Width, AlternativePowerBarDB.Height)
    AlternativePowerBar.Status:SetStatusBarTexture(RUF.Media.Foreground)
    AlternativePowerBar.Status:SetFrameLevel(AlternativePowerBar:GetFrameLevel() + 1)
    if AlternativePowerBarDB.ColourByType then
        local powerColour = RUFDB.General.Colours.Power[0]
        if powerColour then AlternativePowerBar.Status:SetStatusBarColor(powerColour[1], powerColour[2], powerColour[3], powerColour[4]) end
    else
        AlternativePowerBar.Status:SetStatusBarColor(AlternativePowerBarDB.Foreground[1], AlternativePowerBarDB.Foreground[2], AlternativePowerBarDB.Foreground[3], AlternativePowerBarDB.Foreground[4])
    end
    AlternativePowerBar.unit = unit

    if AlternativePowerBarDB.Inverse then
        AlternativePowerBar.Status:SetReverseFill(true)
    else
        AlternativePowerBar.Status:SetReverseFill(false)
    end

    if AlternativePowerBarDB.Enabled and RUF:RequiresAlternativePowerBar() then
        AlternativePowerBar:Show()
        AlternativePowerBar:RegisterEvent("PLAYER_ENTERING_WORLD")
        for _, event in ipairs(ALTERNATIVE_POWER_BAR_EVENTS) do
            AlternativePowerBar:RegisterUnitEvent(event, unit)
        end
        AlternativePowerBar:SetScript("OnEvent", UpdateUnitPowerBarValues)
    else
        AlternativePowerBar:Hide()
        AlternativePowerBar:UnregisterAllEvents()
        AlternativePowerBar:SetScript("OnEvent", nil)
    end

    unitFrame.AlternativePowerBar = AlternativePowerBar
    return AlternativePowerBar
end

function RUF:UpdateUnitAlternativePowerBar(unitFrame, unit)
    local RUFDB = RUF.db.profile
    local AlternativePowerBarDB = RUFDB.Units[RUF:GetNormalizedUnit(unit)].AlternativePowerBar
    local AlternativePowerBar = unitFrame.AlternativePowerBar
    if not AlternativePowerBar then return end

    AlternativePowerBar:ClearAllPoints()
    AlternativePowerBar:SetPoint(AlternativePowerBarDB.Layout[1], unitFrame.Container, AlternativePowerBarDB.Layout[2], AlternativePowerBarDB.Layout[3], AlternativePowerBarDB.Layout[4])
    AlternativePowerBar:SetSize(AlternativePowerBarDB.Width, AlternativePowerBarDB.Height)
    AlternativePowerBar:SetBackdropColor(AlternativePowerBarDB.Background[1], AlternativePowerBarDB.Background[2], AlternativePowerBarDB.Background[3], AlternativePowerBarDB.Background[4])

    AlternativePowerBar.Status:ClearAllPoints()
    AlternativePowerBar.Status:SetPoint("TOPLEFT", AlternativePowerBar, "TOPLEFT", 1, -1)
    AlternativePowerBar.Status:SetPoint("BOTTOMRIGHT", AlternativePowerBar, "BOTTOMRIGHT", -1, 1)
    AlternativePowerBar.Status:SetSize(AlternativePowerBarDB.Width, AlternativePowerBarDB.Height)
    if AlternativePowerBarDB.ColourByType then
        local powerColour = RUFDB.General.Colours.Power[0]
        if powerColour then AlternativePowerBar.Status:SetStatusBarColor(powerColour[1], powerColour[2], powerColour[3], powerColour[4]) end
    else
        AlternativePowerBar.Status:SetStatusBarColor(AlternativePowerBarDB.Foreground[1], AlternativePowerBarDB.Foreground[2], AlternativePowerBarDB.Foreground[3], AlternativePowerBarDB.Foreground[4])
    end

    if AlternativePowerBarDB.Inverse then
        AlternativePowerBar.Status:SetReverseFill(true)
    else
        AlternativePowerBar.Status:SetReverseFill(false)
    end

    if AlternativePowerBarDB.Enabled and RUF:RequiresAlternativePowerBar() then
        AlternativePowerBar:Show()
        AlternativePowerBar:Show()
        AlternativePowerBar:RegisterEvent("PLAYER_ENTERING_WORLD")
        for _, event in ipairs(ALTERNATIVE_POWER_BAR_EVENTS) do
            AlternativePowerBar:RegisterUnitEvent(event, unit)
        end
        AlternativePowerBar:SetScript("OnEvent", UpdateUnitPowerBarValues)
    else
        AlternativePowerBar:Hide()
        AlternativePowerBar:UnregisterAllEvents()
        AlternativePowerBar:SetScript("OnEvent", nil)
    end
end