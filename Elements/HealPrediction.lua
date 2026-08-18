local _, ZF = ...

local STRIPED_TEXTURE = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\ThinStripes.png"

local function ApplyHealPredictionTexture(bar, db)
    bar:SetStatusBarTexture(db.UseStripedTexture and STRIPED_TEXTURE or ZF.Media.Foreground)
end

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
    local IncomingHealDB = ZF:GetUnitDB(unitFrame, unit).HealPrediction.IncomingHeal
    if not unitFrame.Health then return end

    local IncomingHealBar = CreateFrame("StatusBar", ZF:FetchFrameName(unit) .. "_IncomingHealBar", unitFrame.Health)
    ApplyHealPredictionTexture(IncomingHealBar, IncomingHealDB)
    IncomingHealBar:SetStatusBarColor(IncomingHealDB.Color[1], IncomingHealDB.Color[2], IncomingHealDB.Color[3], IncomingHealDB.Color[4])
    local height = IncomingHealDB.MatchParentHeight and unitFrame.Health:GetHeight() or IncomingHealDB.Height
    LayoutHealPredictionBar(IncomingHealBar, unitFrame, IncomingHealDB.Position, height, AttachIncomingHeal)
    IncomingHealBar:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 1)
    IncomingHealBar:Show()

    return IncomingHealBar
end

local function CreateUnitAbsorbs(unitFrame, unit)
    local AbsorbDB = ZF:GetUnitDB(unitFrame, unit).HealPrediction.Absorbs
    if not unitFrame.Health then return end

    local AbsorbBar = CreateFrame("StatusBar", ZF:FetchFrameName(unit) .. "_AbsorbBar", unitFrame.Health)
    ApplyHealPredictionTexture(AbsorbBar, AbsorbDB)
    AbsorbBar:SetStatusBarColor(AbsorbDB.Color[1], AbsorbDB.Color[2], AbsorbDB.Color[3], AbsorbDB.Color[4])
    local height = AbsorbDB.MatchParentHeight and unitFrame.Health:GetHeight() or AbsorbDB.Height
    LayoutHealPredictionBar(AbsorbBar, unitFrame, AbsorbDB.Position, height, AttachAbsorbs)
    AbsorbBar:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 1)
    AbsorbBar:Show()

    return AbsorbBar
end

local function ConfigureUnitOverAbsorbs(OverAbsorbBar, unitFrame, AbsorbDB)
    local OverAbsorbClip = OverAbsorbBar.Clip
    ApplyHealPredictionTexture(OverAbsorbBar, AbsorbDB)
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

local function CreateUnitOverAbsorbs(unitFrame, unit, AbsorbDB)
    if not unitFrame.Health then return end

    local OverAbsorbClip = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_OverAbsorbClip", unitFrame.Health)
    OverAbsorbClip:SetClipsChildren(true)

    local OverAbsorbBar = CreateFrame("StatusBar", ZF:FetchFrameName(unit) .. "_OverAbsorbBar", OverAbsorbClip)
    OverAbsorbBar.Clip = OverAbsorbClip
    ConfigureUnitOverAbsorbs(OverAbsorbBar, unitFrame, AbsorbDB)
    OverAbsorbBar:Hide()
    OverAbsorbClip:Hide()

    return OverAbsorbBar
end

local function CreateUnitHealAbsorbs(unitFrame, unit)
    local HealAbsorbDB = ZF:GetUnitDB(unitFrame, unit).HealPrediction.HealAbsorbs
    if not unitFrame.Health then return end

    local HealAbsorbBar = CreateFrame("StatusBar", ZF:FetchFrameName(unit) .. "_HealAbsorbBar", unitFrame.Health)
    ApplyHealPredictionTexture(HealAbsorbBar, HealAbsorbDB)
    HealAbsorbBar:SetStatusBarColor(HealAbsorbDB.Color[1], HealAbsorbDB.Color[2], HealAbsorbDB.Color[3], HealAbsorbDB.Color[4])
    local height = HealAbsorbDB.MatchParentHeight and unitFrame.Health:GetHeight() or HealAbsorbDB.Height
    LayoutHealPredictionBar(HealAbsorbBar, unitFrame, HealAbsorbDB.Position, height, AttachHealAbsorbs)
    HealAbsorbBar:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 3)
    HealAbsorbBar:Show()

    return HealAbsorbBar
end

local function UpdateUnitOverAbsorbs(unitFrame, unit, AbsorbDB)
    if not unitFrame.Health.DamageAbsorb then return end

    if not AbsorbDB.Enabled or not AbsorbDB.ShowOverAbsorb or AbsorbDB.Position ~= "ATTACH" then
        if unitFrame.HealthPrediction.overDamageAbsorb then
            unitFrame.HealthPrediction.overDamageAbsorb:Hide()
            unitFrame.HealthPrediction.overDamageAbsorb.Clip:Hide()
        end
        return
    end

    unitFrame.HealthPrediction.overDamageAbsorb = unitFrame.HealthPrediction.overDamageAbsorb or CreateUnitOverAbsorbs(unitFrame, unit, AbsorbDB)
    local OverAbsorbBar = unitFrame.HealthPrediction.overDamageAbsorb
    if not OverAbsorbBar then return end

    ConfigureUnitOverAbsorbs(OverAbsorbBar, unitFrame, AbsorbDB)
    OverAbsorbBar:SetMinMaxValues(unitFrame.Health.DamageAbsorb:GetMinMaxValues())
    OverAbsorbBar:SetValue(unitFrame.Health.DamageAbsorb:GetValue())
    OverAbsorbBar:SetWidth(unitFrame.Health:GetWidth())
    OverAbsorbBar.Clip:Show()
    OverAbsorbBar:Show()
end

local function RefreshHealthPredictionAliases(unitFrame)
    unitFrame.HealthPrediction = unitFrame.HealthPrediction or {}
    unitFrame.HealthPrediction.healingPlayer = unitFrame.Health.HealingPlayer
    unitFrame.HealthPrediction.damageAbsorb = unitFrame.Health.DamageAbsorb
    unitFrame.HealthPrediction.healAbsorb = unitFrame.Health.HealAbsorb
end

local function EnsureHealthPostUpdateChain(unitFrame, AbsorbDB)
    unitFrame.HealPredictionAbsorbDB = AbsorbDB
    if unitFrame.Health.zfHealPredictionChained then return end
    unitFrame.Health.zfHealPredictionChained = true
    local existingPostUpdate = unitFrame.Health.PostUpdate
    unitFrame.Health.PostUpdate = function(healthElement, event, curHP, maxHP, ...)
        if existingPostUpdate then existingPostUpdate(healthElement, event, curHP, maxHP, ...) end
        UpdateUnitOverAbsorbs(unitFrame, unitFrame.__unit, unitFrame.HealPredictionAbsorbDB)
    end
end

function ZF:CreateUnitHealPrediction(unitFrame, unit)
    local IncomingHealDB = ZF:GetUnitDB(unitFrame, unit).HealPrediction.IncomingHeal
    local AbsorbDB = ZF:GetUnitDB(unitFrame, unit).HealPrediction.Absorbs
    local HealAbsorbDB = ZF:GetUnitDB(unitFrame, unit).HealPrediction.HealAbsorbs

    unitFrame.Health.HealingPlayer = IncomingHealDB.Enabled and CreateIncomingHeal(unitFrame, unit) or nil
    unitFrame.Health.DamageAbsorb = AbsorbDB.Enabled and CreateUnitAbsorbs(unitFrame, unit) or nil
    unitFrame.Health.damageAbsorbClampMode = 2
    unitFrame.Health.HealAbsorb = HealAbsorbDB.Enabled and CreateUnitHealAbsorbs(unitFrame, unit) or nil
    unitFrame.Health.healAbsorbClampMode = 1
    unitFrame.Health.healAbsorbMode = 1

    unitFrame.HealthPrediction = unitFrame.HealthPrediction or {}
    unitFrame.HealthPrediction.overDamageAbsorb = AbsorbDB.Enabled and AbsorbDB.ShowOverAbsorb and AbsorbDB.Position == "ATTACH" and CreateUnitOverAbsorbs(unitFrame, unit, AbsorbDB) or nil

    RefreshHealthPredictionAliases(unitFrame)
    EnsureHealthPostUpdateChain(unitFrame, AbsorbDB)
end

function ZF:UpdateUnitHealPrediction(unitFrame, unit)
    local IncomingHealDB = ZF:GetUnitDB(unitFrame, unit).HealPrediction.IncomingHeal
    local AbsorbDB = ZF:GetUnitDB(unitFrame, unit).HealPrediction.Absorbs
    local HealAbsorbDB = ZF:GetUnitDB(unitFrame, unit).HealPrediction.HealAbsorbs

    if not unitFrame.Health then return end

    if IncomingHealDB.Enabled then
        unitFrame.Health.HealingPlayer = unitFrame.Health.HealingPlayer or CreateIncomingHeal(unitFrame, unit)
        unitFrame.Health.HealingPlayer:Show()
        ApplyHealPredictionTexture(unitFrame.Health.HealingPlayer, IncomingHealDB)
        unitFrame.Health.HealingPlayer:SetStatusBarColor(IncomingHealDB.Color[1], IncomingHealDB.Color[2], IncomingHealDB.Color[3], IncomingHealDB.Color[4])
        local height = IncomingHealDB.MatchParentHeight and unitFrame.Health:GetHeight() or IncomingHealDB.Height
        LayoutHealPredictionBar(unitFrame.Health.HealingPlayer, unitFrame, IncomingHealDB.Position, height, AttachIncomingHeal)
    elseif unitFrame.Health.HealingPlayer then
        unitFrame.Health.HealingPlayer:Hide()
    end

    if AbsorbDB.Enabled then
        unitFrame.Health.DamageAbsorb = unitFrame.Health.DamageAbsorb or CreateUnitAbsorbs(unitFrame, unit)
        unitFrame.Health.damageAbsorbClampMode = 2
        unitFrame.Health.DamageAbsorb:Show()
        ApplyHealPredictionTexture(unitFrame.Health.DamageAbsorb, AbsorbDB)
        unitFrame.Health.DamageAbsorb:SetStatusBarColor(AbsorbDB.Color[1], AbsorbDB.Color[2], AbsorbDB.Color[3], AbsorbDB.Color[4])
        local height = AbsorbDB.MatchParentHeight and unitFrame.Health:GetHeight() or AbsorbDB.Height
        local position = AbsorbDB.Position
        LayoutHealPredictionBar(unitFrame.Health.DamageAbsorb, unitFrame, position, height, AttachAbsorbs)

        if AbsorbDB.ShowOverAbsorb and position == "ATTACH" then
            unitFrame.HealthPrediction.overDamageAbsorb = unitFrame.HealthPrediction.overDamageAbsorb or CreateUnitOverAbsorbs(unitFrame, unit, AbsorbDB)
            if unitFrame.HealthPrediction.overDamageAbsorb then ConfigureUnitOverAbsorbs(unitFrame.HealthPrediction.overDamageAbsorb, unitFrame, AbsorbDB) end
        elseif unitFrame.HealthPrediction.overDamageAbsorb then
            unitFrame.HealthPrediction.overDamageAbsorb:Hide()
            unitFrame.HealthPrediction.overDamageAbsorb.Clip:Hide()
        end
    else
        if unitFrame.Health.DamageAbsorb then
            unitFrame.Health.DamageAbsorb:Hide()
        end
        if unitFrame.HealthPrediction.overDamageAbsorb then
            unitFrame.HealthPrediction.overDamageAbsorb:Hide()
            unitFrame.HealthPrediction.overDamageAbsorb.Clip:Hide()
        end
    end

    if HealAbsorbDB.Enabled then
        unitFrame.Health.HealAbsorb = unitFrame.Health.HealAbsorb or CreateUnitHealAbsorbs(unitFrame, unit)
        unitFrame.Health.healAbsorbClampMode = 1
        unitFrame.Health.HealAbsorb:Show()
        ApplyHealPredictionTexture(unitFrame.Health.HealAbsorb, HealAbsorbDB)
        unitFrame.Health.HealAbsorb:SetStatusBarColor(HealAbsorbDB.Color[1], HealAbsorbDB.Color[2], HealAbsorbDB.Color[3], HealAbsorbDB.Color[4])
        local height = HealAbsorbDB.MatchParentHeight and unitFrame.Health:GetHeight() or HealAbsorbDB.Height
        LayoutHealPredictionBar(unitFrame.Health.HealAbsorb, unitFrame, HealAbsorbDB.Position, height, AttachHealAbsorbs)
        unitFrame.Health.HealAbsorb:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 3)
    elseif unitFrame.Health.HealAbsorb then
        unitFrame.Health.HealAbsorb:Hide()
    end

    RefreshHealthPredictionAliases(unitFrame)
    EnsureHealthPostUpdateChain(unitFrame, AbsorbDB)

    if unitFrame:IsElementEnabled("Health") then unitFrame:DisableElement("Health") end
    unitFrame:EnableElement("Health")
    unitFrame.Health:ForceUpdate()

    if unitFrame.Health.HealingPlayer then unitFrame.Health.HealingPlayer:SetShown(IncomingHealDB.Enabled) end
    if unitFrame.Health.DamageAbsorb then unitFrame.Health.DamageAbsorb:SetShown(AbsorbDB.Enabled) end
    if unitFrame.Health.HealAbsorb then unitFrame.Health.HealAbsorb:SetShown(HealAbsorbDB.Enabled) end
end
