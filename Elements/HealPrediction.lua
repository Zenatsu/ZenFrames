local _, RUF = ...

local function LayoutHealPredictionBar(bar, unitFrame, position, height, attachFn)
    bar:ClearAllPoints()
    bar:SetHeight(height)

    if position == "ATTACH" then
        unitFrame.Health:SetClipsChildren(true)
        attachFn(bar, unitFrame)
    elseif position == "TOPLEFT" then
        bar:SetPoint("TOPLEFT", unitFrame.Health, "TOPLEFT", 0, 0)
        bar:SetReverseFill(false)
    elseif position == "TOPRIGHT" then
        bar:SetPoint("TOPRIGHT", unitFrame.Health, "TOPRIGHT", 0, 0)
        bar:SetReverseFill(true)
    elseif position == "BOTTOMLEFT" then
        bar:SetPoint("BOTTOMLEFT", unitFrame.Health, "BOTTOMLEFT", 0, 0)
        bar:SetReverseFill(false)
    elseif position == "BOTTOMRIGHT" then
        bar:SetPoint("BOTTOMRIGHT", unitFrame.Health, "BOTTOMRIGHT", 0, 0)
        bar:SetReverseFill(true)
    elseif position == "LEFT" then
        bar:SetPoint("LEFT", unitFrame.Health, "LEFT", 0, 0)
        bar:SetReverseFill(false)
    elseif position == "RIGHT" then
        bar:SetPoint("RIGHT", unitFrame.Health, "RIGHT", 0, 0)
        bar:SetReverseFill(true)
    else
        bar:SetPoint("TOPLEFT", unitFrame.Health, "TOPLEFT", 0, 0)
        bar:SetReverseFill(false)
    end
end

local function AttachIncomingHeal(bar, unitFrame)
    if unitFrame.Health:GetReverseFill() then
        bar:SetPoint("TOPRIGHT", unitFrame.Health:GetStatusBarTexture(), "TOPLEFT", 0, 0)
        bar:SetReverseFill(true)
    else
        bar:SetPoint("TOPLEFT", unitFrame.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
        bar:SetReverseFill(false)
    end
end

local function AttachAbsorbs(bar, unitFrame)
    bar:SetPoint("TOP", unitFrame.Health, "TOP", 0, 0)
    bar:SetPoint("BOTTOM", unitFrame.Health, "BOTTOM", 0, 0)
    if unitFrame.Health:GetReverseFill() then
        bar:SetPoint("RIGHT", unitFrame.Health:GetStatusBarTexture(), "LEFT", 0, 0)
        bar:SetReverseFill(true)
    else
        bar:SetPoint("LEFT", unitFrame.Health:GetStatusBarTexture(), "RIGHT", 0, 0)
        bar:SetReverseFill(false)
    end
end

local function AttachHealAbsorbs(bar, unitFrame)
    bar:SetPoint("TOP", unitFrame.Health, "TOP", 0, 0)
    bar:SetPoint("BOTTOM", unitFrame.Health, "BOTTOM", 0, 0)
    if unitFrame.Health:GetReverseFill() then
        bar:SetPoint("LEFT", unitFrame.Health:GetStatusBarTexture(), "LEFT", 0, 0)
        bar:SetReverseFill(false)
    else
        bar:SetPoint("RIGHT", unitFrame.Health:GetStatusBarTexture(), "RIGHT", 0, 0)
        bar:SetReverseFill(true)
    end
end

local function CreateIncomingHeal(unitFrame, unit)
    local IncomingHealDB = RUF:GetUnitDB(unitFrame, unit).HealPrediction.IncomingHeal
    if not unitFrame.Health then return end

    local IncomingHealBar = CreateFrame("StatusBar", RUF:FetchFrameName(unit) .. "_IncomingHealBar", unitFrame.Health)
    if IncomingHealDB.UseStripedTexture then IncomingHealBar:SetStatusBarTexture("Interface\\AddOns\\RehaltedUnitFrames\\Media\\Textures\\ThinStripes.png") else IncomingHealBar:SetStatusBarTexture(RUF.Media.Foreground) end
    IncomingHealBar:SetStatusBarColor(IncomingHealDB.Color[1], IncomingHealDB.Color[2], IncomingHealDB.Color[3], IncomingHealDB.Color[4])
    local height = IncomingHealDB.MatchParentHeight and unitFrame.Health:GetHeight() or IncomingHealDB.Height
    LayoutHealPredictionBar(IncomingHealBar, unitFrame, IncomingHealDB.Position, height, AttachIncomingHeal)
    IncomingHealBar:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 1)
    IncomingHealBar:Show()

    return IncomingHealBar
end

local function CreateUnitAbsorbs(unitFrame, unit)
    local AbsorbDB = RUF:GetUnitDB(unitFrame, unit).HealPrediction.Absorbs
    if not unitFrame.Health then return end

    local AbsorbBar = CreateFrame("StatusBar", RUF:FetchFrameName(unit) .. "_AbsorbBar", unitFrame.Health)
    if AbsorbDB.UseStripedTexture then AbsorbBar:SetStatusBarTexture("Interface\\AddOns\\RehaltedUnitFrames\\Media\\Textures\\ThinStripes.png") else AbsorbBar:SetStatusBarTexture(RUF.Media.Foreground) end
    AbsorbBar:SetStatusBarColor(AbsorbDB.Color[1], AbsorbDB.Color[2], AbsorbDB.Color[3], AbsorbDB.Color[4])
    local height = AbsorbDB.MatchParentHeight and unitFrame.Health:GetHeight() or AbsorbDB.Height
    LayoutHealPredictionBar(AbsorbBar, unitFrame, AbsorbDB.Position, height, AttachAbsorbs)
    AbsorbBar:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 1)
    AbsorbBar:Show()

    return AbsorbBar
end

local function ConfigureUnitOverAbsorbs(OverAbsorbBar, unitFrame, unit)
    local AbsorbDB = RUF:GetUnitDB(unitFrame, unit).HealPrediction.Absorbs
    local OverAbsorbClip = OverAbsorbBar.Clip
    if AbsorbDB.UseStripedTexture then OverAbsorbBar:SetStatusBarTexture("Interface\\AddOns\\RehaltedUnitFrames\\Media\\Textures\\ThinStripes.png") else OverAbsorbBar:SetStatusBarTexture(RUF.Media.Foreground) end
    OverAbsorbBar:SetStatusBarColor(AbsorbDB.Color[1], AbsorbDB.Color[2], AbsorbDB.Color[3], AbsorbDB.Color[4])
    OverAbsorbClip:ClearAllPoints()
    OverAbsorbBar:ClearAllPoints()
    local height = AbsorbDB.MatchParentHeight and unitFrame.Health:GetHeight() or AbsorbDB.Height
    OverAbsorbClip:SetHeight(height)
    OverAbsorbBar:SetHeight(height)

    if unitFrame.Health:GetReverseFill() then
        OverAbsorbClip:SetPoint("TOPRIGHT", unitFrame.Health, "TOPRIGHT", 0, 0)
        OverAbsorbClip:SetPoint("BOTTOMLEFT", unitFrame.Health:GetStatusBarTexture(), "BOTTOMLEFT", 0, 0)
        OverAbsorbBar:SetPoint("TOPLEFT", unitFrame.Health, "TOPLEFT", 0, 0)
        OverAbsorbBar:SetPoint("BOTTOMLEFT", unitFrame.Health, "BOTTOMLEFT", 0, 0)
        OverAbsorbBar:SetReverseFill(false)
    else
        OverAbsorbClip:SetPoint("TOPLEFT", unitFrame.Health, "TOPLEFT", 0, 0)
        OverAbsorbClip:SetPoint("BOTTOMRIGHT", unitFrame.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
        OverAbsorbBar:SetPoint("TOPRIGHT", unitFrame.Health, "TOPRIGHT", 0, 0)
        OverAbsorbBar:SetPoint("BOTTOMRIGHT", unitFrame.Health, "BOTTOMRIGHT", 0, 0)
        OverAbsorbBar:SetReverseFill(true)
    end
    OverAbsorbClip:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 2)
    OverAbsorbBar:SetFrameLevel(OverAbsorbClip:GetFrameLevel() + 1)
end

local function CreateUnitOverAbsorbs(unitFrame, unit)
    if not unitFrame.Health then return end

    local OverAbsorbClip = CreateFrame("Frame", RUF:FetchFrameName(unit) .. "_OverAbsorbClip", unitFrame.Health)
    OverAbsorbClip:SetClipsChildren(true)

    local OverAbsorbBar = CreateFrame("StatusBar", RUF:FetchFrameName(unit) .. "_OverAbsorbBar", OverAbsorbClip)
    OverAbsorbBar.Clip = OverAbsorbClip
    ConfigureUnitOverAbsorbs(OverAbsorbBar, unitFrame, unit)
    OverAbsorbBar:Hide()
    OverAbsorbClip:Hide()

    return OverAbsorbBar
end

local function CreateUnitHealAbsorbs(unitFrame, unit)
    local HealAbsorbDB = RUF:GetUnitDB(unitFrame, unit).HealPrediction.HealAbsorbs
    if not unitFrame.Health then return end

    local HealAbsorbBar = CreateFrame("StatusBar", RUF:FetchFrameName(unit) .. "_HealAbsorbBar", unitFrame.Health)
    if HealAbsorbDB.UseStripedTexture then HealAbsorbBar:SetStatusBarTexture("Interface\\AddOns\\RehaltedUnitFrames\\Media\\Textures\\ThinStripes.png") else HealAbsorbBar:SetStatusBarTexture(RUF.Media.Foreground) end
    HealAbsorbBar:SetStatusBarColor(HealAbsorbDB.Color[1], HealAbsorbDB.Color[2], HealAbsorbDB.Color[3], HealAbsorbDB.Color[4])
    local height = HealAbsorbDB.MatchParentHeight and unitFrame.Health:GetHeight() or HealAbsorbDB.Height
    LayoutHealPredictionBar(HealAbsorbBar, unitFrame, HealAbsorbDB.Position, height, AttachHealAbsorbs)
    HealAbsorbBar:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 3)
    HealAbsorbBar:Show()

    return HealAbsorbBar
end

local function UpdateUnitOverAbsorbs(unitFrame, unit)
    local AbsorbDB = RUF:GetUnitDB(unitFrame, unit).HealPrediction.Absorbs
    if not unitFrame.HealthPrediction or not unitFrame.HealthPrediction.damageAbsorb then return end

    if not AbsorbDB.Enabled or not AbsorbDB.ShowOverAbsorb or AbsorbDB.Position ~= "ATTACH" then
        if unitFrame.HealthPrediction.overDamageAbsorb then
            unitFrame.HealthPrediction.overDamageAbsorb:Hide()
            unitFrame.HealthPrediction.overDamageAbsorb.Clip:Hide()
        end
        return
    end

    unitFrame.HealthPrediction.overDamageAbsorb = unitFrame.HealthPrediction.overDamageAbsorb or CreateUnitOverAbsorbs(unitFrame, unit)
    local OverAbsorbBar = unitFrame.HealthPrediction.overDamageAbsorb
    if not OverAbsorbBar then return end

    ConfigureUnitOverAbsorbs(OverAbsorbBar, unitFrame, unit)
    OverAbsorbBar:SetMinMaxValues(unitFrame.HealthPrediction.damageAbsorb:GetMinMaxValues())
    OverAbsorbBar:SetValue(unitFrame.HealthPrediction.damageAbsorb:GetValue())
    OverAbsorbBar:SetWidth(unitFrame.Health:GetWidth())
    OverAbsorbBar.Clip:Show()
    OverAbsorbBar:Show()
end

function RUF:CreateUnitHealPrediction(unitFrame, unit)
    local IncomingHealDB = RUF:GetUnitDB(unitFrame, unit).HealPrediction.IncomingHeal
    local AbsorbDB = RUF:GetUnitDB(unitFrame, unit).HealPrediction.Absorbs
    local HealAbsorbDB = RUF:GetUnitDB(unitFrame, unit).HealPrediction.HealAbsorbs

    unitFrame.HealthPrediction = {
        healingPlayer = IncomingHealDB.Enabled and CreateIncomingHeal(unitFrame, unit),
        damageAbsorb = AbsorbDB.Enabled and CreateUnitAbsorbs(unitFrame, unit),
        damageAbsorbClampMode = 2,
        overDamageAbsorb = AbsorbDB.Enabled and AbsorbDB.ShowOverAbsorb and AbsorbDB.Position == "ATTACH" and CreateUnitOverAbsorbs(unitFrame, unit),
        healAbsorb = HealAbsorbDB.Enabled and CreateUnitHealAbsorbs(unitFrame, unit),
        healAbsorbClampMode = 1,
        healAbsorbMode = 1,
        PostUpdate = function(_, updateUnit) UpdateUnitOverAbsorbs(unitFrame, updateUnit) end,
    }
end

function RUF:UpdateUnitHealPrediction(unitFrame, unit)
    local IncomingHealDB = RUF:GetUnitDB(unitFrame, unit).HealPrediction.IncomingHeal
    local AbsorbDB = RUF:GetUnitDB(unitFrame, unit).HealPrediction.Absorbs
    local HealAbsorbDB = RUF:GetUnitDB(unitFrame, unit).HealPrediction.HealAbsorbs

    if unitFrame.HealthPrediction then
        if IncomingHealDB.Enabled then
            unitFrame.HealthPrediction.healingPlayer = unitFrame.HealthPrediction.healingPlayer or CreateIncomingHeal(unitFrame, unit)
            unitFrame.HealthPrediction.healingPlayerClampMode = 2
            unitFrame.HealthPrediction.healingPlayer:Show()
            if IncomingHealDB.UseStripedTexture then unitFrame.HealthPrediction.healingPlayer:SetStatusBarTexture("Interface\\AddOns\\RehaltedUnitFrames\\Media\\Textures\\ThinStripes.png") else unitFrame.HealthPrediction.healingPlayer:SetStatusBarTexture(RUF.Media.Foreground) end
            unitFrame.HealthPrediction.healingPlayer:SetStatusBarColor(IncomingHealDB.Color[1], IncomingHealDB.Color[2], IncomingHealDB.Color[3], IncomingHealDB.Color[4])
            local height = IncomingHealDB.MatchParentHeight and unitFrame.Health:GetHeight() or IncomingHealDB.Height
            LayoutHealPredictionBar(unitFrame.HealthPrediction.healingPlayer, unitFrame, IncomingHealDB.Position, height, AttachIncomingHeal)
            unitFrame.HealthPrediction:ForceUpdate()
        else
            if unitFrame.HealthPrediction.healingPlayer then
                unitFrame.HealthPrediction.healingPlayer:Hide()
            end
        end
        if AbsorbDB.Enabled then
            unitFrame.HealthPrediction.damageAbsorb = unitFrame.HealthPrediction.damageAbsorb or CreateUnitAbsorbs(unitFrame, unit)
            unitFrame.HealthPrediction.damageAbsorbClampMode = 2
            unitFrame.HealthPrediction.PostUpdate = function(_, updateUnit) UpdateUnitOverAbsorbs(unitFrame, updateUnit) end
            unitFrame.HealthPrediction.damageAbsorb:Show()
            if AbsorbDB.UseStripedTexture then unitFrame.HealthPrediction.damageAbsorb:SetStatusBarTexture("Interface\\AddOns\\RehaltedUnitFrames\\Media\\Textures\\ThinStripes.png") else unitFrame.HealthPrediction.damageAbsorb:SetStatusBarTexture(RUF.Media.Foreground) end
            unitFrame.HealthPrediction.damageAbsorb:SetStatusBarColor(AbsorbDB.Color[1], AbsorbDB.Color[2], AbsorbDB.Color[3], AbsorbDB.Color[4])
            local height = AbsorbDB.MatchParentHeight and unitFrame.Health:GetHeight() or AbsorbDB.Height
            local position = AbsorbDB.Position
            LayoutHealPredictionBar(unitFrame.HealthPrediction.damageAbsorb, unitFrame, position, height, AttachAbsorbs)

            if AbsorbDB.ShowOverAbsorb and position == "ATTACH" then
                unitFrame.HealthPrediction.overDamageAbsorb = unitFrame.HealthPrediction.overDamageAbsorb or CreateUnitOverAbsorbs(unitFrame, unit)
                if unitFrame.HealthPrediction.overDamageAbsorb then ConfigureUnitOverAbsorbs(unitFrame.HealthPrediction.overDamageAbsorb, unitFrame, unit) end
            elseif unitFrame.HealthPrediction.overDamageAbsorb then
                unitFrame.HealthPrediction.overDamageAbsorb:Hide()
                unitFrame.HealthPrediction.overDamageAbsorb.Clip:Hide()
            end
            unitFrame.HealthPrediction:ForceUpdate()
        else
            if unitFrame.HealthPrediction.damageAbsorb then
                unitFrame.HealthPrediction.damageAbsorb:Hide()
            end
            if unitFrame.HealthPrediction.overDamageAbsorb then
                unitFrame.HealthPrediction.overDamageAbsorb:Hide()
                unitFrame.HealthPrediction.overDamageAbsorb.Clip:Hide()
            end
        end
        if HealAbsorbDB.Enabled then
            unitFrame.HealthPrediction.healAbsorb = unitFrame.HealthPrediction.healAbsorb or CreateUnitHealAbsorbs(unitFrame, unit)
            unitFrame.HealthPrediction.healAbsorbClampMode = 1
            unitFrame.HealthPrediction.healAbsorb:Show()
            if HealAbsorbDB.UseStripedTexture then unitFrame.HealthPrediction.healAbsorb:SetStatusBarTexture("Interface\\AddOns\\RehaltedUnitFrames\\Media\\Textures\\ThinStripes.png") else unitFrame.HealthPrediction.healAbsorb:SetStatusBarTexture(RUF.Media.Foreground) end
            unitFrame.HealthPrediction.healAbsorb:SetStatusBarColor(HealAbsorbDB.Color[1], HealAbsorbDB.Color[2], HealAbsorbDB.Color[3], HealAbsorbDB.Color[4])
            local height = HealAbsorbDB.MatchParentHeight and unitFrame.Health:GetHeight() or HealAbsorbDB.Height
            LayoutHealPredictionBar(unitFrame.HealthPrediction.healAbsorb, unitFrame, HealAbsorbDB.Position, height, AttachHealAbsorbs)
            unitFrame.HealthPrediction.healAbsorb:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 3)
            unitFrame.HealthPrediction:ForceUpdate()
        else
            if unitFrame.HealthPrediction.healAbsorb then
                unitFrame.HealthPrediction.healAbsorb:Hide()
            end
        end
    else
        RUF:CreateUnitHealPrediction(unitFrame, unit)
    end
end
