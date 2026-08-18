local _, ZF = ...

local function ShouldShowUnitPowerBar(unitFrame, unit, PowerBarDB)
	if not PowerBarDB.Enabled then return false end
	if not PowerBarDB.OnlyShowHealers then return true end
	local normalizedUnit = ZF:GetNormalizedUnit(unit)
	if normalizedUnit ~= "party" and normalizedUnit ~= "raid" then return true end
	local unitToken = unit == "partyplayer" and "player" or unit
	return UnitGroupRolesAssigned(unitToken) == "HEALER"
end

local function CreatePowerBarPostUpdateColor(unitFrame, unit)
    return function(element, _, color, altR, altG, altB)
        local PowerBarDB = unitFrame.PowerBarDB
        if not PowerBarDB.ColorBackgroundByType then return end
        if not element.Background then return end

        local mult = PowerBarDB.BackgroundMultiplier or 0.75
        local r, g, b

        if altR and altG and altB then
            r, g, b = altR, altG, altB
        elseif color then
            r, g, b = color:GetRGB()
        else
            r, g, b = element:GetStatusBarColor()
        end

        if r and g and b then
            element.Background:SetVertexColor(r * mult, g * mult, b * mult, PowerBarDB.Background[4] or 1)
        end
    end
end

local function ComputePowerBarAnchor(position, extraOffset)
    extraOffset = extraOffset or 0
    local isTopAnchored = position == "TOP"
    local anchorPoint = isTopAnchored and "TOPLEFT" or "BOTTOMLEFT"
    local anchorY = isTopAnchored and (-1 - extraOffset) or (1 + extraOffset)
    return anchorPoint, anchorY, isTopAnchored
end

local function LayoutUnitPowerBar(unitFrame, unit, width)
    local PowerBarDB = ZF:GetUnitDB(unitFrame, unit).PowerBar
    local powerBar = unitFrame.Power
    if not powerBar then return end

    width = width and width > 0 and width or ZF:GetUnitDB(unitFrame, unit).Frame.Width
	local position = ZF:GetConfiguredPowerBarPosition(unit, unitFrame)
    local anchorPoint, anchorY, isTopAnchored = ComputePowerBarAnchor(position)

    powerBar:ClearAllPoints()
    powerBar:SetPoint(anchorPoint, unitFrame.Container, anchorPoint, 1, anchorY)
    powerBar:SetSize(width - 2, PowerBarDB.Height)

    if powerBar.Background then
        powerBar.Background:ClearAllPoints()
        powerBar.Background:SetPoint(anchorPoint, unitFrame.Container, anchorPoint, 1, anchorY)
        powerBar.Background:SetSize(width - 2, PowerBarDB.Height)
    end

    if powerBar.PowerBarBorder then
        powerBar.PowerBarBorder:ClearAllPoints()
        if isTopAnchored then
            powerBar.PowerBarBorder:SetPoint("BOTTOMLEFT", powerBar, "BOTTOMLEFT", 0, -1)
            powerBar.PowerBarBorder:SetPoint("BOTTOMRIGHT", powerBar, "BOTTOMRIGHT", 0, -1)
        else
            powerBar.PowerBarBorder:SetPoint("TOPLEFT", powerBar, "TOPLEFT", 0, 1)
            powerBar.PowerBarBorder:SetPoint("TOPRIGHT", powerBar, "TOPRIGHT", 0, 1)
        end
    end
end

local function ApplyPowerBarSettings(powerBar, PowerBarDB)
    powerBar:SetStatusBarColor(PowerBarDB.Foreground[1], PowerBarDB.Foreground[2], PowerBarDB.Foreground[3], PowerBarDB.Foreground[4] or 1)
    powerBar:SetStatusBarTexture(ZF.Media.Foreground)
    powerBar.colorPower = PowerBarDB.ColorByType
    powerBar.colorClass = PowerBarDB.ColorByClass
    powerBar.frequentUpdates = PowerBarDB.Smooth

    if PowerBarDB.Inverse then
        powerBar:SetReverseFill(true)
    else
        powerBar:SetReverseFill(false)
    end

    if powerBar.Background then
        powerBar.Background:SetVertexColor(PowerBarDB.Background[1], PowerBarDB.Background[2], PowerBarDB.Background[3], PowerBarDB.Background[4] or 1)
        powerBar.Background:SetTexture(ZF.Media.Background)
    end
end

function ZF:CreateUnitPowerBar(unitFrame, unit)
    local FrameDB = ZF:GetUnitDB(unitFrame, unit).Frame
    local PowerBarDB = ZF:GetUnitDB(unitFrame, unit).PowerBar
    unitFrame.PowerBarDB = PowerBarDB
    local unitContainer = unitFrame.Container

    local PowerBar = CreateFrame("StatusBar", ZF:FetchFrameName(unit) .. "_PowerBar", unitContainer)
    PowerBar:SetPoint("BOTTOMLEFT", unitContainer, "BOTTOMLEFT", 1, 1)
    PowerBar:SetSize(FrameDB.Width - 2, PowerBarDB.Height)
    PowerBar:SetFrameLevel(unitContainer:GetFrameLevel() + 2)
    PowerBar.PostUpdateColor = CreatePowerBarPostUpdateColor(unitFrame, unit)
	unitFrame.PowerBar = PowerBar

    PowerBar.Background = PowerBar:CreateTexture(ZF:FetchFrameName(unit) .. "_PowerBackground", "BACKGROUND")
    PowerBar.Background:SetPoint("BOTTOMLEFT", unitContainer, "BOTTOMLEFT", 1, 1)
    PowerBar.Background:SetSize(FrameDB.Width - 2, PowerBarDB.Height)

    if not PowerBar.PowerBarBorder then
        PowerBar.PowerBarBorder = PowerBar:CreateTexture(nil, "OVERLAY")
        PowerBar.PowerBarBorder:SetHeight(1)
        PowerBar.PowerBarBorder:SetTexture(ZF.Media.Solid)
        PowerBar.PowerBarBorder:SetVertexColor(0, 0, 0, 1)
        PowerBar.PowerBarBorder:SetPoint("TOPLEFT", PowerBar, "TOPLEFT", 0, 1)
        PowerBar.PowerBarBorder:SetPoint("TOPRIGHT", PowerBar, "TOPRIGHT", 0, 1)
    end

    ApplyPowerBarSettings(PowerBar, PowerBarDB)

    if ShouldShowUnitPowerBar(unitFrame, unit, PowerBarDB) then
        unitFrame.Power = PowerBar
        PowerBar:Show()
        if unitFrame.PowerBackground then unitFrame.PowerBackground:Show() end
    else
        if unitFrame:IsElementEnabled("Power") then unitFrame:DisableElement("Power") end
        PowerBar:Hide()
        if unitFrame.PowerBackground then unitFrame.PowerBackground:Hide() end
    end

    if unitFrame.Power then
        LayoutUnitPowerBar(unitFrame, unit, FrameDB.Width)
    end
    ZF:UpdateHealthBarLayout(unitFrame, unit)

    return PowerBar
end

function ZF:UpdateUnitPowerBar(unitFrame, unit)
    local PowerBarDB = ZF:GetUnitDB(unitFrame, unit).PowerBar
    unitFrame.PowerBarDB = PowerBarDB

    if ShouldShowUnitPowerBar(unitFrame, unit, PowerBarDB) then
		unitFrame.Power = unitFrame.Power or unitFrame.PowerBar or ZF:CreateUnitPowerBar(unitFrame, unit)

        if not unitFrame:IsElementEnabled("Power") then unitFrame:EnableElement("Power") end

        if unitFrame.Power then
            LayoutUnitPowerBar(unitFrame, unit, unitFrame:GetWidth())
            ApplyPowerBarSettings(unitFrame.Power, PowerBarDB)
        end

        unitFrame.Power:Show()
        unitFrame.Power:ForceUpdate()
    else
        if unitFrame.Power then
            if unitFrame:IsElementEnabled("Power") then unitFrame:DisableElement("Power") end
            unitFrame.Power:Hide()
            unitFrame.Power = nil
        end
        ZF:UpdateHealthBarLayout(unitFrame, unit)
        return
    end

    ZF:UpdateHealthBarLayout(unitFrame, unit)
end

local playerClass = UnitClassBase("player")
local isDeathKnight = playerClass == "DEATHKNIGHT"

local secondaryPowerEvents = CreateFrame("Frame")
secondaryPowerEvents:RegisterEvent("TRAIT_CONFIG_UPDATED")
secondaryPowerEvents:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
secondaryPowerEvents:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
secondaryPowerEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
secondaryPowerEvents:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end

    C_Timer.After(0.1, function()
        if ZF.PLAYER then
            ZF:UpdateUnitSecondaryPowerBar(ZF.PLAYER, "player")
        end
    end)
end)

local function DisableSecondaryPowerElement(unitFrame, elementName, secondaryPower)
    if unitFrame:IsElementEnabled(elementName) then
        unitFrame:DisableElement(elementName)
    end

    for index = 1, #secondaryPower do
        secondaryPower[index]:Hide()
    end

    for index = 1, #secondaryPower.Ticks do
        secondaryPower.Ticks[index]:Hide()
    end

    secondaryPower.ContainerBackground:Hide()
    secondaryPower.PowerBarBorder:Hide()
    secondaryPower.OverlayFrame:Hide()
    unitFrame[elementName] = nil
end

local function UnpackColor(color)
    return color[1], color[2], color[3], color[4] or 1
end

local function GetSecondaryPowerMaxCount(powerType)
    if isDeathKnight then return 6 end
    return UnitPowerMax("player", powerType)
end

function ZF:CreateUnitSecondaryPowerBar(unitFrame, unit)
    local unitDB = ZF:GetUnitDB(unitFrame, unit)
    local secondaryPowerDB = unitDB.SecondaryPowerBar
    unitFrame.SecondaryPowerBarDB = secondaryPowerDB
    if not secondaryPowerDB.Enabled then return end

    local powerType = ZF:GetSecondaryPowerType()
    if not isDeathKnight and not powerType then return end

    local maxPower = GetSecondaryPowerMaxCount(powerType)
    if not maxPower or maxPower < 1 then return end

    local secondaryPower = {Ticks = {}}

    secondaryPower.ContainerBackground = unitFrame.Container:CreateTexture(nil, "BACKGROUND")
    secondaryPower.ContainerBackground:SetTexture(ZF.Media.Background)

    for index = 1, maxPower do
        local bar = CreateFrame("StatusBar", nil, unitFrame.Container)
        bar:SetStatusBarTexture(ZF.Media.Foreground)
        bar:SetMinMaxValues(0, 1)
        bar:Hide()

        bar.Background = bar:CreateTexture(nil, "BACKGROUND")
        bar.Background:SetAllPoints(bar)
        bar.Background:SetTexture(ZF.Media.Background)

        secondaryPower[index] = bar
    end

    secondaryPower.OverlayFrame = CreateFrame("Frame", nil, unitFrame.Container)
    secondaryPower.OverlayFrame:SetAllPoints(unitFrame.Container)
    secondaryPower.OverlayFrame:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 10)

    for index = 1, maxPower - 1 do
        local tick = secondaryPower.OverlayFrame:CreateTexture(nil, "OVERLAY")
        tick:SetTexture(ZF.Media.Solid)
        tick:SetDrawLayer("OVERLAY", 7)
        tick:SetVertexColor(0, 0, 0, 1)
        secondaryPower.Ticks[index] = tick
    end

    secondaryPower.PowerBarBorder = secondaryPower.OverlayFrame:CreateTexture(nil, "OVERLAY")
    secondaryPower.PowerBarBorder:SetTexture(ZF.Media.Solid)
    secondaryPower.PowerBarBorder:SetDrawLayer("OVERLAY", 6)
    secondaryPower.PowerBarBorder:SetVertexColor(0, 0, 0, 1)
    secondaryPower.PowerBarBorder:SetHeight(1)

    secondaryPower.PostUpdateColor = function(element)
        local currentSecondaryPowerDB = unitFrame.SecondaryPowerBarDB
        if currentSecondaryPowerDB.ColorByType then return end

        for index = 1, #element do
            element[index]:SetStatusBarColor(UnpackColor(currentSecondaryPowerDB.Foreground))
        end
    end

    if isDeathKnight then
        secondaryPower.sortOrder = "asc"
        secondaryPower.colorSpec = secondaryPowerDB.ColorByType
        unitFrame.Runes = secondaryPower
    else
        unitFrame.ClassPower = secondaryPower
    end

    return secondaryPower
end

function ZF:UpdateUnitSecondaryPowerBar(unitFrame, unit)
    if not unitFrame then return end

    local unitDB = ZF:GetUnitDB(unitFrame, unit)
    local frameDB = unitDB.Frame
    local secondaryPowerDB = unitDB.SecondaryPowerBar
    unitFrame.SecondaryPowerBarDB = secondaryPowerDB
    local powerType = ZF:GetSecondaryPowerType()
    local elementName = isDeathKnight and "Runes" or "ClassPower"

    if not secondaryPowerDB.Enabled or (not isDeathKnight and not powerType) then
        local secondaryPower = unitFrame[elementName]
        if secondaryPower then
            DisableSecondaryPowerElement(unitFrame, elementName, secondaryPower)
        end

        if unitFrame.Power then
            ZF:UpdateUnitPowerBar(unitFrame, unit)
        else
            ZF:UpdateHealthBarLayout(unitFrame, unit)
        end
        return
    end

    local maxPower = GetSecondaryPowerMaxCount(powerType)
    if not maxPower or maxPower < 1 then return end

    local secondaryPower = unitFrame[elementName]
    if secondaryPower and #secondaryPower ~= maxPower then
        DisableSecondaryPowerElement(unitFrame, elementName, secondaryPower)
        secondaryPower = nil
    end

    if not secondaryPower then
        secondaryPower = ZF:CreateUnitSecondaryPowerBar(unitFrame, unit)
        if not secondaryPower then return end

        if not unitFrame:IsElementEnabled(elementName) then
            unitFrame:EnableElement(elementName)
        end
    end

    local totalWidth = frameDB.Width - 2
    local segmentWidth = totalWidth / maxPower
	local position = ZF:GetConfiguredSecondaryPowerBarPosition(unit, unitFrame)
    local stackOffset = ZF:GetSecondaryPowerBarStackOffset(unitFrame, unit)
    local anchorPoint, anchorY, isTopAnchored = ComputePowerBarAnchor(position, stackOffset)

    secondaryPower.ContainerBackground:ClearAllPoints()
    secondaryPower.ContainerBackground:SetPoint(anchorPoint, unitFrame.Container, anchorPoint, 1, anchorY)
    secondaryPower.ContainerBackground:SetSize(totalWidth, secondaryPowerDB.Height)
    secondaryPower.ContainerBackground:SetTexture(ZF.Media.Background)
    secondaryPower.ContainerBackground:SetVertexColor(UnpackColor(secondaryPowerDB.Background))
    secondaryPower.ContainerBackground:Show()

    secondaryPower.OverlayFrame:SetAllPoints(unitFrame.Container)
    secondaryPower.OverlayFrame:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 10)
    secondaryPower.OverlayFrame:Show()

    secondaryPower.PowerBarBorder:ClearAllPoints()
    if isTopAnchored then
        secondaryPower.PowerBarBorder:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", 1, anchorY - secondaryPowerDB.Height)
        secondaryPower.PowerBarBorder:SetPoint("TOPRIGHT", unitFrame.Container, "TOPLEFT", 1 + totalWidth, anchorY - secondaryPowerDB.Height)
    else
        secondaryPower.PowerBarBorder:SetPoint("BOTTOMLEFT", unitFrame.Container, "BOTTOMLEFT", 1, anchorY + secondaryPowerDB.Height)
        secondaryPower.PowerBarBorder:SetPoint("BOTTOMRIGHT", unitFrame.Container, "BOTTOMLEFT", 1 + totalWidth, anchorY + secondaryPowerDB.Height)
    end
    secondaryPower.PowerBarBorder:Show()

    for index = 1, maxPower do
        local bar = secondaryPower[index]
        bar:ClearAllPoints()
        bar:SetPoint(anchorPoint, unitFrame.Container, anchorPoint, 1 + ((index - 1) * segmentWidth), anchorY)
        bar:SetSize(segmentWidth, secondaryPowerDB.Height)
        bar:SetStatusBarTexture(ZF.Media.Foreground)
        bar.Background:SetTexture(ZF.Media.Background)
        bar.Background:SetVertexColor(UnpackColor(secondaryPowerDB.Background))
        bar:Show()
    end

    for index = 1, maxPower - 1 do
        local tick = secondaryPower.Ticks[index]
        tick:ClearAllPoints()
        tick:SetPoint(anchorPoint, unitFrame.Container, anchorPoint, 1 + (index * segmentWidth) - 0.5, anchorY)
        tick:SetSize(1, secondaryPowerDB.Height)
        tick:Show()
    end

    if isDeathKnight then
        secondaryPower.colorSpec = secondaryPowerDB.ColorByType
    end

    secondaryPower:PostUpdateColor()
    if secondaryPower.ForceUpdate then
        secondaryPower:ForceUpdate()
    end

    if unitFrame.Power then
        ZF:UpdateUnitPowerBar(unitFrame, unit)
    else
        ZF:UpdateHealthBarLayout(unitFrame, unit)
    end
end

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
