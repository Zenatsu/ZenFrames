local _, ZF = ...

local function SetCastBarColor(castBar, unit, CastBarDB)
	local r, g, b, a
	if CastBarDB.ColorByClass then
		local unitForClass = unit == "pet" and "player" or unit
		local unitClass = select(2, UnitClass(unitForClass))
		local unitColor = RAID_CLASS_COLORS[unitClass]
		if unitColor then r, g, b, a = unitColor.r, unitColor.g, unitColor.b, CastBarDB.ForegroundOpacity end
	end
	if not r then r, g, b, a = unpack(CastBarDB.Foreground) end
	if ZF.IsInterruptOnCooldown and C_CurveUtil.EvaluateColorValueFromBoolean and castBar.zfActive and UnitCanAttack("player", unit) and ZF:IsInterruptOnCooldown() then
		local CDR, CDG, CDB, CDA = unpack(CastBarDB.InterruptCooldownColor or CastBarDB.InterruptOnCooldownColor)
		r = C_CurveUtil.EvaluateColorValueFromBoolean(castBar.zfNotInterruptible, r, CDR)
		g = C_CurveUtil.EvaluateColorValueFromBoolean(castBar.zfNotInterruptible, g, CDG)
		b = C_CurveUtil.EvaluateColorValueFromBoolean(castBar.zfNotInterruptible, b, CDB)
		a = C_CurveUtil.EvaluateColorValueFromBoolean(castBar.zfNotInterruptible, a or 1, CDA or a or 1)
	end
	castBar:SetStatusBarColor(r, g, b, a)
end

local function ApplyCastBarBorderStyle(container, CastBarDB)
    return ZF:ApplyBorderStyle(container, CastBarDB, CastBarDB.Height, {0, 0, 0, 0})
end

local function ApplyCastBarIconPosition(castBar, icon, container, iconPosition, height, borderSize)
	icon:ClearAllPoints()
	castBar:ClearAllPoints()
	if iconPosition == "LEFT" then
		icon:SetPoint("TOPLEFT", container, "TOPLEFT", borderSize, -borderSize)
		castBar:SetPoint("TOPLEFT", container, "TOPLEFT", height - borderSize, -borderSize)
		castBar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -borderSize, borderSize)
	elseif iconPosition == "RIGHT" then
		icon:SetPoint("TOPRIGHT", container, "TOPRIGHT", -borderSize, -borderSize)
		castBar:SetPoint("TOPLEFT", container, "TOPLEFT", borderSize, -borderSize)
		castBar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -(height - borderSize), borderSize)
	end
end

local function ApplyCastBarNoIconPosition(castBar, container, borderSize)
	castBar:ClearAllPoints()
	castBar:SetPoint("TOPLEFT", container, "TOPLEFT", borderSize, -borderSize)
	castBar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -borderSize, borderSize)
end

local function SyncCastBarText(fontString, castBar, TextDB, GeneralDB)
    fontString:ClearAllPoints()
    fontString:SetPoint(TextDB.Layout[1], castBar, TextDB.Layout[2], TextDB.Layout[3], TextDB.Layout[4])
    ZF:ApplyFontStringStyle(fontString, ZF.Media.Font, TextDB.FontSize, GeneralDB.Fonts.FontFlag, TextDB.Color, GeneralDB.Fonts.Shadow)
    fontString:SetJustifyH(ZF:GetJustifyH(TextDB.Layout[1]))
    fontString:SetAlpha(TextDB.Enabled and 1 or 0)
end

local function SyncCastBar(unitFrame, unit, castBar)
    local GeneralDB = ZF.db.profile.General
    local UnitDB = ZF:GetUnitDB(nil, unit)
    local CastBarDB = UnitDB.CastBar
    local container = castBar:GetParent()

    container:ClearAllPoints()
    container:SetPoint(CastBarDB.Layout[1], unitFrame, CastBarDB.Layout[2], CastBarDB.Layout[3], CastBarDB.Layout[4])
    container:SetFrameStrata(CastBarDB.FrameStrata)
    castBar:ClearAllPoints()
    container:SetWidth(CastBarDB.MatchParentWidth and UnitDB.Frame.Width or CastBarDB.Width)
    container:SetHeight(CastBarDB.Height)
    local borderSize = ApplyCastBarBorderStyle(container, CastBarDB)

    castBar:SetStatusBarTexture(ZF.Media.Foreground)
    castBar.timeToHold = CastBarDB.HoldTime
    castBar.Background:SetTexture(ZF.Media.Background)
    SetCastBarColor(castBar, unit, CastBarDB)
    castBar.Background:SetVertexColor(unpack(CastBarDB.Background))
    castBar.NotInterruptibleOverlay:SetTexture(ZF.Media.Foreground)
    castBar.NotInterruptibleOverlay:SetVertexColor(unpack(CastBarDB.NotInterruptibleColor))
    castBar:SetReverseFill(CastBarDB.Inverse and true or false)

    local icon = castBar.IconTexture
    icon:SetSize(CastBarDB.Height - 2*borderSize, CastBarDB.Height - 2*borderSize)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if CastBarDB.Icon.Enabled then
        castBar.Icon = icon
        ApplyCastBarIconPosition(castBar, icon, container, CastBarDB.Icon.Position, CastBarDB.Height, borderSize)
        icon:Show()
    else
        castBar.Icon = nil
        icon:Hide()
        ApplyCastBarNoIconPosition(castBar, container, borderSize)
    end

    SyncCastBarText(castBar.Text, castBar, CastBarDB.Text.SpellName, GeneralDB)
    SyncCastBarText(castBar.Time, castBar, CastBarDB.Text.Duration, GeneralDB)
end

local function BuildCastBar(unitFrame, unit)
    local CastBarContainer = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_CastBarContainer", unitFrame, "BackdropTemplate")
    CastBarContainer:Hide()

    local CastBar = CreateFrame("StatusBar", ZF:FetchFrameName(unit) .. "_CastBar", CastBarContainer)
    CastBar:SetFrameLevel(CastBarContainer:GetFrameLevel() + 1)

    CastBar.Background = CastBar:CreateTexture(nil, "BACKGROUND")
    CastBar.Background:SetAllPoints(CastBar)

    CastBar.NotInterruptibleOverlay = CastBar:CreateTexture(nil, "ARTWORK", nil, 1)
    CastBar.NotInterruptibleOverlay:SetPoint("TOPLEFT", CastBar:GetStatusBarTexture(), "TOPLEFT")
    CastBar.NotInterruptibleOverlay:SetPoint("BOTTOMRIGHT", CastBar:GetStatusBarTexture(), "BOTTOMRIGHT")
    CastBar.NotInterruptibleOverlay:SetAlpha(0)

    CastBar.IconTexture = CastBar:CreateTexture(ZF:FetchFrameName(unit) .. "_CastBarIcon", "ARTWORK")
    CastBar.Text = CastBar:CreateFontString(ZF:FetchFrameName(unit) .. "_CastBarSpellNameText", "OVERLAY", "GameFontNormal")
    CastBar.Time = CastBar:CreateFontString(ZF:FetchFrameName(unit) .. "_CastBarDurationText", "OVERLAY", "GameFontNormal")

    CastBar:HookScript("OnHide", function() CastBarContainer:Hide() end)

    CastBar.PostCastStart = function(frameCastBar, _, spellID, notInterruptible, name, texture)
        local currentCastBarDB = unitFrame.CastBarHookDB
        local currentSpellNameDB = currentCastBarDB.Text.SpellName
        frameCastBar.zfActive = true
        frameCastBar.zfNotInterruptible = notInterruptible
        SetCastBarColor(frameCastBar, unit, currentCastBarDB)

        if frameCastBar.Icon and texture then frameCastBar.Icon:SetTexture(texture) end

        local spellName = name
        if spellName then
            if not ZF:IsSecretValue(spellName) then
                if currentSpellNameDB.MaxChars and currentSpellNameDB.MaxChars > 0 then spellName = string.format("%." .. currentSpellNameDB.MaxChars .. "s", spellName) end
                spellName = ZF:CleanTruncateUTF8String(spellName)
            end
            local isCasting = UnitCastingInfo(unit) ~= nil
            local isChanneling = not isCasting and UnitChannelInfo(unit) ~= nil
            local targetName
            if currentCastBarDB.ShowTarget then
                if not UnitSpellTargetName then
                    targetName = UnitName(unit .. "target")
                elseif isCasting or (isChanneling and UnitShouldDisplaySpellTargetName(unit)) then
                    targetName = UnitSpellTargetName(unit)
                end
            end
            if ZF:IsSecretValue(targetName) or targetName then frameCastBar.Text:SetFormattedText("%s » %s", spellName, targetName) else frameCastBar.Text:SetText(spellName) end
        else
            frameCastBar.Text:SetText("")
        end

        if frameCastBar.NotInterruptibleOverlay then frameCastBar.NotInterruptibleOverlay:SetAlphaFromBoolean(notInterruptible, 1, 0) end
        CastBarContainer:Show()
    end

    CastBar.PostCastInterruptible = function(frameCastBar, _, _, notInterruptible)
        frameCastBar.zfNotInterruptible = notInterruptible
        if frameCastBar.NotInterruptibleOverlay then frameCastBar.NotInterruptibleOverlay:SetAlphaFromBoolean(notInterruptible, 1, 0) end
        SetCastBarColor(frameCastBar, unit, unitFrame.CastBarHookDB)
    end
    CastBar.PostCastFail = function(frameCastBar)
        frameCastBar.zfActive = nil
        frameCastBar:SetStatusBarColor(unpack(unitFrame.CastBarHookDB.InterruptedFailedColor))
        if frameCastBar.NotInterruptibleOverlay then frameCastBar.NotInterruptibleOverlay:SetAlpha(0) end
    end
    CastBar.PostCastInterrupted = CastBar.PostCastFail
    CastBar.PostCastStop = function(frameCastBar)
        frameCastBar.zfActive = nil
    end

    unitFrame.CastBarWidget = CastBar
    return CastBar
end

local function DetachCastBar(unitFrame)
    if not unitFrame.Castbar then return end
    if unitFrame:IsElementEnabled("Castbar") then unitFrame:DisableElement("Castbar") end
    unitFrame.Castbar:Hide()
    unitFrame.Castbar:GetParent():Hide()
    unitFrame.Castbar = nil
end

function ZF:CreateUnitCastBar(unitFrame, unit)
    local CastBarDB = ZF:GetUnitDB(nil, unit).CastBar
    local CastBar = unitFrame.CastBarWidget or BuildCastBar(unitFrame, unit)
    unitFrame.CastBarHookDB = ZF:GetUnitDB(unitFrame, unit).CastBar
    SyncCastBar(unitFrame, unit, CastBar)
    CastBar:GetParent():Hide()

    if CastBarDB.Enabled then
        unitFrame.Castbar = CastBar
    else
        DetachCastBar(unitFrame)
    end

    return CastBar
end

function ZF:UpdateUnitCastBar(unitFrame, unit)
    local CastBarDB = ZF:GetUnitDB(nil, unit).CastBar

    if CastBarDB.Enabled then
        if not unitFrame.Castbar then ZF:CreateUnitCastBar(unitFrame, unit) end
        unitFrame.CastBarHookDB = ZF:GetUnitDB(unitFrame, unit).CastBar
        if not unitFrame:IsElementEnabled("Castbar") then unitFrame:EnableElement("Castbar") end
        SyncCastBar(unitFrame, unit, unitFrame.Castbar)
    else
        if not unitFrame.Castbar then return end
        DetachCastBar(unitFrame)
    end
    if unitFrame.isDesignerPreview and ZF.DESIGNER_PREVIEW_TOGGLES.CastBar then ZF:CreateTestCastBar(unitFrame, unit) end
end

function ZF:CreateTestCastBar(unitFrame, unit)
    if not unit then return end
    if not unitFrame then return end
    local CastBarDB = ZF:GetUnitDB(nil, unit).CastBar
    local CastBarContainer = unitFrame.Castbar and unitFrame.Castbar:GetParent()
    if unitFrame.isDesignerPreview and ZF.DESIGNER_PREVIEW_TOGGLES.CastBar then
        if unitFrame.Castbar and CastBarDB.Enabled then
            unitFrame:DisableElement("Castbar")
            CastBarContainer:Show()
            CastBarContainer:SetFrameStrata(CastBarDB.FrameStrata)
            unitFrame.Castbar:Show()
            unitFrame.Castbar.Background:Show()
            local spellName = "Ethereal Portal"
            local maxChars = CastBarDB.Text.SpellName.MaxChars
            if maxChars and maxChars > 0 then spellName = string.format("%." .. maxChars .. "s", spellName) end
            spellName = ZF:CleanTruncateUTF8String(spellName)
            if CastBarDB.ShowTarget then unitFrame.Castbar.Text:SetFormattedText("%s » %s", spellName, "Target") else unitFrame.Castbar.Text:SetText(spellName) end
            unitFrame.Castbar.Time:SetText("2.5")
            unitFrame.Castbar:SetMinMaxValues(0, 1000)
            unitFrame.Castbar:SetValue(500)
            SetCastBarColor(unitFrame.Castbar, unit, CastBarDB)
            if unitFrame.Castbar.NotInterruptibleOverlay then
                unitFrame.Castbar.NotInterruptibleOverlay:SetAlpha(0)
            end
            if CastBarDB.Icon.Enabled and unitFrame.Castbar.Icon then unitFrame.Castbar.Icon:SetTexture("Interface\\Icons\\ability_mage_netherwindpresence") unitFrame.Castbar.Icon:Show() end
        else
            if CastBarContainer then CastBarContainer:Hide() end
            if unitFrame.Castbar and unitFrame.Castbar.Icon then unitFrame.Castbar.Icon:Hide() end
        end
    else
        if unitFrame.Castbar then
            unitFrame.Castbar:Hide()
            if CastBarContainer then CastBarContainer:Hide() end
            if CastBarDB.Enabled then
                if unitFrame:IsElementEnabled("Castbar") then unitFrame:DisableElement("Castbar") end
                unitFrame:EnableElement("Castbar")
            end
        end
    end
end

local InterruptCooldownFrame = CreateFrame("Frame")
InterruptCooldownFrame:RegisterEvent("SPELLS_CHANGED")
InterruptCooldownFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
InterruptCooldownFrame:SetScript("OnEvent", function()
	for i = 1, 9 do
		local unitFrame = i == 1 and ZF.PLAYER or i == 2 and ZF.TARGET or i == 3 and ZF.FOCUS or i == 4 and ZF.PET or ZF["BOSS" .. (i - 4)]
		local castBar = unitFrame and unitFrame.Castbar
		local unit = unitFrame and unitFrame.__unit
		local CastBarDB = unitFrame and unitFrame.CastBarHookDB
		if castBar and castBar:IsShown() and castBar.zfActive and CastBarDB then SetCastBarColor(castBar, unit, CastBarDB) end
	end
end)
