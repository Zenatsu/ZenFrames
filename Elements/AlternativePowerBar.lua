local _, ZF = ...

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

local function LayoutAlternativePowerBar(AlternativePowerBar, unitContainer, AlternativePowerBarDB, ZFDB)
    AlternativePowerBar:ClearAllPoints()
    AlternativePowerBar:SetPoint(AlternativePowerBarDB.Layout[1], unitContainer, AlternativePowerBarDB.Layout[2], AlternativePowerBarDB.Layout[3], AlternativePowerBarDB.Layout[4])
    AlternativePowerBar:SetSize(AlternativePowerBarDB.Width, AlternativePowerBarDB.Height)
    AlternativePowerBar:SetBackdropColor(AlternativePowerBarDB.Background[1], AlternativePowerBarDB.Background[2], AlternativePowerBarDB.Background[3], AlternativePowerBarDB.Background[4])

    AlternativePowerBar.Status:ClearAllPoints()
    AlternativePowerBar.Status:SetPoint("TOPLEFT", AlternativePowerBar, "TOPLEFT", 1, -1)
    AlternativePowerBar.Status:SetPoint("BOTTOMRIGHT", AlternativePowerBar, "BOTTOMRIGHT", -1, 1)
    AlternativePowerBar.Status:SetSize(AlternativePowerBarDB.Width, AlternativePowerBarDB.Height)
    if AlternativePowerBarDB.ColorByType then
        local powerColor = ZFDB.General.Colors.Power[0]
        if powerColor then AlternativePowerBar.Status:SetStatusBarColor(powerColor[1], powerColor[2], powerColor[3], powerColor[4]) end
    else
        AlternativePowerBar.Status:SetStatusBarColor(AlternativePowerBarDB.Foreground[1], AlternativePowerBarDB.Foreground[2], AlternativePowerBarDB.Foreground[3], AlternativePowerBarDB.Foreground[4])
    end

    if AlternativePowerBarDB.Inverse then
        AlternativePowerBar.Status:SetReverseFill(true)
    else
        AlternativePowerBar.Status:SetReverseFill(false)
    end
end

local function ApplyAlternativePowerBarVisibility(AlternativePowerBar, unit, AlternativePowerBarDB)
    if AlternativePowerBarDB.Enabled and ZF:RequiresAlternativePowerBar() then
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

function ZF:CreateUnitAlternativePowerBar(unitFrame, unit)
    local ZFDB = ZF.db.profile
    local AlternativePowerBarDB = ZFDB.Units[ZF:GetNormalizedUnit(unit)].AlternativePowerBar
    local unitContainer = unitFrame.Container

    local AlternativePowerBar = CreateFrame("Frame", ZF:FetchFrameName(unit).."_AlternativePowerBar", unitContainer, "BackdropTemplate")
    AlternativePowerBar:SetBackdrop(ZF.BACKDROP)
    AlternativePowerBar:SetBackdropBorderColor(0, 0, 0, 1)
    AlternativePowerBar:SetFrameLevel(unitContainer:GetFrameLevel() + 5)

    AlternativePowerBar.Status = CreateFrame("StatusBar", ZF:FetchFrameName(unit).."_AlternativePowerBar", AlternativePowerBar)
    AlternativePowerBar.Status:SetStatusBarTexture(ZF.Media.Foreground)
    AlternativePowerBar.Status:SetFrameLevel(AlternativePowerBar:GetFrameLevel() + 1)
    AlternativePowerBar.unit = unit

    LayoutAlternativePowerBar(AlternativePowerBar, unitContainer, AlternativePowerBarDB, ZFDB)
    ApplyAlternativePowerBarVisibility(AlternativePowerBar, unit, AlternativePowerBarDB)

    unitFrame.AlternativePowerBar = AlternativePowerBar
    return AlternativePowerBar
end

function ZF:UpdateUnitAlternativePowerBar(unitFrame, unit)
    local ZFDB = ZF.db.profile
    local AlternativePowerBarDB = ZFDB.Units[ZF:GetNormalizedUnit(unit)].AlternativePowerBar
    local AlternativePowerBar = unitFrame.AlternativePowerBar
    if not AlternativePowerBar then return end

    LayoutAlternativePowerBar(AlternativePowerBar, unitFrame.Container, AlternativePowerBarDB, ZFDB)
    ApplyAlternativePowerBarVisibility(AlternativePowerBar, unit, AlternativePowerBarDB)
end
