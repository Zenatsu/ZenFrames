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

local function ApplyCastBarIconPosition(castBar, icon, container, iconPosition, height)
	icon:ClearAllPoints()
	castBar:ClearAllPoints()
	if iconPosition == "LEFT" then
		icon:SetPoint("TOPLEFT", container, "TOPLEFT", 1, -1)
		castBar:SetPoint("TOPLEFT", container, "TOPLEFT", height - 1, -1)
		castBar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -1, 1)
	elseif iconPosition == "RIGHT" then
		icon:SetPoint("TOPRIGHT", container, "TOPRIGHT", -1, -1)
		castBar:SetPoint("TOPLEFT", container, "TOPLEFT", 1, -1)
		castBar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -(height - 1), 1)
	end
end

local function ApplyCastBarNoIconPosition(castBar, container)
	castBar:ClearAllPoints()
	castBar:SetPoint("TOPLEFT", container, "TOPLEFT", 1, -1)
	castBar:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -1, 1)
end

function ZF:CreateUnitCastBar(unitFrame, unit)
    local GeneralDB = ZF.db.profile.General
    local FrameDB = ZF.db.profile.Units[ZF:GetNormalizedUnit(unit)].Frame
    local CastBarDB = ZF.db.profile.Units[ZF:GetNormalizedUnit(unit)].CastBar
    local SpellNameDB = ZF.db.profile.Units[ZF:GetNormalizedUnit(unit)].CastBar.Text.SpellName
    local DurationDB = ZF.db.profile.Units[ZF:GetNormalizedUnit(unit)].CastBar.Text.Duration

    local CastBarContainer = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_CastBarContainer", unitFrame, "BackdropTemplate")
    CastBarContainer:SetBackdrop(ZF.BACKDROP)
    CastBarContainer:SetBackdropColor(0, 0, 0, 0)
    CastBarContainer:SetBackdropBorderColor(0, 0, 0, 1)
    CastBarContainer:ClearAllPoints()
    CastBarContainer:SetPoint(CastBarDB.Layout[1], unitFrame, CastBarDB.Layout[2], CastBarDB.Layout[3], CastBarDB.Layout[4])
    if CastBarDB.MatchParentWidth then CastBarContainer:SetWidth(FrameDB.Width) else CastBarContainer:SetWidth(CastBarDB.Width) end
    CastBarContainer:SetHeight(CastBarDB.Height)
    CastBarContainer:SetFrameStrata(CastBarDB.FrameStrata)
    CastBarContainer:Hide()

    local CastBar = CreateFrame("StatusBar", ZF:FetchFrameName(unit) .. "_CastBar", CastBarContainer)
    CastBar:SetStatusBarTexture(ZF.Media.Foreground)
    CastBar:ClearAllPoints()
    CastBar:SetPoint("TOPLEFT", CastBarContainer, "TOPLEFT", 1, -1)
    CastBar:SetPoint("BOTTOMRIGHT", CastBarContainer, "BOTTOMRIGHT", -1, 1)
    CastBar:SetFrameLevel(CastBarContainer:GetFrameLevel() + 1)
    CastBar.timeToHold = CastBarDB.HoldTime
    SetCastBarColor(CastBar, unit, CastBarDB)

    CastBar.Background = CastBar:CreateTexture(nil, "BACKGROUND")
    CastBar.Background:SetAllPoints(CastBar)
    CastBar.Background:SetTexture(ZF.Media.Background)
    CastBar.Background:SetVertexColor(unpack(CastBarDB.Background))

    CastBar.NotInterruptibleOverlay = CastBar:CreateTexture(nil, "ARTWORK", nil, 1)
    CastBar.NotInterruptibleOverlay:SetPoint("TOPLEFT", CastBar:GetStatusBarTexture(), "TOPLEFT")
    CastBar.NotInterruptibleOverlay:SetPoint("BOTTOMRIGHT", CastBar:GetStatusBarTexture(), "BOTTOMRIGHT")
    CastBar.NotInterruptibleOverlay:SetTexture(ZF.Media.Foreground)
    CastBar.NotInterruptibleOverlay:SetVertexColor(unpack(CastBarDB.NotInterruptibleColor))
    CastBar.NotInterruptibleOverlay:SetAlpha(0)

    CastBar.Icon = CastBar:CreateTexture(ZF:FetchFrameName(unit) .. "_CastBarIcon", "ARTWORK")
    CastBar.Icon:SetSize(CastBarDB.Height - 2, CastBarDB.Height - 2)
    CastBar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if CastBarDB.Icon.Enabled then
        ApplyCastBarIconPosition(CastBar, CastBar.Icon, CastBarContainer, CastBarDB.Icon.Position, CastBarDB.Height)
    else
        CastBar.Icon:Hide()
        ApplyCastBarNoIconPosition(CastBar, CastBarContainer)
    end

    local SpellNameText = CastBar:CreateFontString(ZF:FetchFrameName(unit) .. "_CastBarSpellNameText", "OVERLAY", "GameFontNormal")
    SpellNameText:ClearAllPoints()
    SpellNameText:SetPoint(SpellNameDB.Layout[1], CastBar, SpellNameDB.Layout[2], SpellNameDB.Layout[3], SpellNameDB.Layout[4])
    ZF:ApplyFontStringStyle(SpellNameText, ZF.Media.Font, SpellNameDB.FontSize, GeneralDB.Fonts.FontFlag, SpellNameDB.Color, GeneralDB.Fonts.Shadow)
    SpellNameText:SetJustifyH(ZF:SetJustification(SpellNameDB.Layout[1]))

    local DurationText = CastBar:CreateFontString(ZF:FetchFrameName(unit) .. "_CastBarDurationText", "OVERLAY", "GameFontNormal")
    DurationText:ClearAllPoints()
    DurationText:SetPoint(DurationDB.Layout[1], CastBar, DurationDB.Layout[2], DurationDB.Layout[3], DurationDB.Layout[4])
    ZF:ApplyFontStringStyle(DurationText, ZF.Media.Font, DurationDB.FontSize, GeneralDB.Fonts.FontFlag, DurationDB.Color, GeneralDB.Fonts.Shadow)
    DurationText:SetJustifyH(ZF:SetJustification(DurationDB.Layout[1]))

    if CastBarDB.Inverse then
        CastBar:SetReverseFill(true)
    else
        CastBar:SetReverseFill(false)
    end

    if CastBarDB.Enabled then
        unitFrame.Castbar = CastBar
        unitFrame.Castbar.Text = SpellNameText
        unitFrame.Castbar.Time = DurationText
        if CastBarDB.Icon.Enabled then unitFrame.Castbar.Icon = CastBar.Icon else unitFrame.Castbar.Icon = nil end
        unitFrame.Castbar:HookScript("OnValueChanged", function(self, value) if self.Castbar then self.Castbar:SetValue(value) end end)
        unitFrame.Castbar:HookScript("OnHide", function() CastBarContainer:Hide() end)

        unitFrame.CastBarHookDB = ZF:GetUnitDB(unitFrame, unit).CastBar

        unitFrame.Castbar.PostCastStart = function(frameCastBar, _, spellID, notInterruptible, name, texture)
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
				local targetName = currentCastBarDB.ShowTarget and not UnitSpellTargetName and UnitName(unit .. "target")
				if currentCastBarDB.ShowTarget and UnitSpellTargetName and (isCasting or isChanneling and UnitShouldDisplaySpellTargetName(unit)) then targetName = UnitSpellTargetName(unit) end
                if ZF:IsSecretValue(targetName) or targetName then frameCastBar.Text:SetFormattedText("%s » %s", spellName, targetName) else frameCastBar.Text:SetText(spellName) end
            else
                frameCastBar.Text:SetText("")
            end

            if frameCastBar.NotInterruptibleOverlay then frameCastBar.NotInterruptibleOverlay:SetAlphaFromBoolean(notInterruptible, 1, 0) end
            CastBarContainer:Show()
        end

        unitFrame.Castbar.PostCastInterruptible = function(frameCastBar, _, _, notInterruptible)
			frameCastBar.zfNotInterruptible = notInterruptible
            if frameCastBar.NotInterruptibleOverlay then frameCastBar.NotInterruptibleOverlay:SetAlphaFromBoolean(notInterruptible, 1, 0) end
			SetCastBarColor(frameCastBar, unit, unitFrame.CastBarHookDB)
        end
        unitFrame.Castbar.PostCastFail = function(frameCastBar)
			frameCastBar.zfActive = nil
			frameCastBar:SetStatusBarColor(unpack(unitFrame.CastBarHookDB.InterruptedFailedColor))
            if frameCastBar.NotInterruptibleOverlay then frameCastBar.NotInterruptibleOverlay:SetAlpha(0) end
        end
        unitFrame.Castbar.PostCastInterrupted = unitFrame.Castbar.PostCastFail
        unitFrame.Castbar.PostCastStop = function(frameCastBar)
			frameCastBar.zfActive = nil
        end
        if SpellNameDB.Enabled then unitFrame.Castbar.Text:SetAlpha(1) else unitFrame.Castbar.Text:SetAlpha(0) end
        if DurationDB.Enabled then unitFrame.Castbar.Time:SetAlpha(1) else unitFrame.Castbar.Time:SetAlpha(0) end
    else
        CastBarContainer:Hide()
        if not unitFrame.Castbar then return end
        if unitFrame:IsElementEnabled("Castbar") then unitFrame:DisableElement("Castbar") end
        unitFrame.Castbar:Hide()
        unitFrame.Castbar = nil
    end

    return CastBar
end

function ZF:UpdateUnitCastBar(unitFrame, unit)
    local GeneralDB = ZF.db.profile.General
    local FrameDB = ZF.db.profile.Units[ZF:GetNormalizedUnit(unit)].Frame
    local CastBarDB = ZF.db.profile.Units[ZF:GetNormalizedUnit(unit)].CastBar
    local CastBarContainer = unitFrame.Castbar and unitFrame.Castbar:GetParent()

    if CastBarDB.Enabled then
        unitFrame.Castbar = unitFrame.Castbar or ZF:CreateUnitCastBar(unitFrame, unit)
        unitFrame.CastBarHookDB = ZF:GetUnitDB(unitFrame, unit).CastBar
        CastBarContainer = unitFrame.Castbar and unitFrame.Castbar:GetParent()

        if not unitFrame:IsElementEnabled("Castbar") then unitFrame:EnableElement("Castbar") end

        if unitFrame.Castbar then
            if CastBarContainer then CastBarContainer:ClearAllPoints() end
            if CastBarContainer then CastBarContainer:SetPoint(CastBarDB.Layout[1], unitFrame, CastBarDB.Layout[2], CastBarDB.Layout[3], CastBarDB.Layout[4]) end
            if CastBarContainer then CastBarContainer:SetFrameStrata(CastBarDB.FrameStrata) end
            unitFrame.Castbar:ClearAllPoints()
            unitFrame.Castbar:SetPoint("TOPLEFT", CastBarContainer, "TOPLEFT", 1, -1)
            unitFrame.Castbar:SetPoint("BOTTOMRIGHT", CastBarContainer, "BOTTOMRIGHT", -1, 1)
            if CastBarDB.MatchParentWidth then
                if CastBarContainer then
                    CastBarContainer:SetWidth(FrameDB.Width)
                end
            else
                if CastBarContainer then
                    CastBarContainer:SetWidth(CastBarDB.Width)
                end
            end
            if CastBarContainer then CastBarContainer:SetHeight(CastBarDB.Height) end
            unitFrame.Castbar:SetStatusBarTexture(ZF.Media.Foreground)
            unitFrame.Castbar.timeToHold = CastBarDB.HoldTime
            unitFrame.Castbar.Background:SetTexture(ZF.Media.Background)
            SetCastBarColor(unitFrame.Castbar, unit, CastBarDB)
            unitFrame.Castbar.Background:SetVertexColor(unpack(CastBarDB.Background))

            if unitFrame.Castbar.NotInterruptibleOverlay then
                unitFrame.Castbar.NotInterruptibleOverlay:SetTexture(ZF.Media.Foreground)
                unitFrame.Castbar.NotInterruptibleOverlay:SetVertexColor(unpack(CastBarDB.NotInterruptibleColor))
            end

            if CastBarDB.Inverse then
                unitFrame.Castbar:SetReverseFill(true)
            else
                unitFrame.Castbar:SetReverseFill(false)
            end

            if CastBarDB.Icon.Enabled then
                unitFrame.Castbar.Icon = unitFrame.Castbar.Icon or unitFrame.Castbar:CreateTexture(ZF:FetchFrameName(unit) .. "_CastBarIcon", "ARTWORK")
                unitFrame.Castbar.Icon:SetSize(CastBarDB.Height - 2, CastBarDB.Height - 2)
                unitFrame.Castbar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                ApplyCastBarIconPosition(unitFrame.Castbar, unitFrame.Castbar.Icon, CastBarContainer, CastBarDB.Icon.Position, CastBarDB.Height)
                unitFrame.Castbar.Icon:Show()
            else
                if unitFrame.Castbar.Icon then unitFrame.Castbar.Icon:Hide() end
                unitFrame.Castbar.Icon = nil
                ApplyCastBarNoIconPosition(unitFrame.Castbar, CastBarContainer)
            end

            if unitFrame.Castbar.Text then
                local SpellNameDB = ZF.db.profile.Units[ZF:GetNormalizedUnit(unit)].CastBar.Text.SpellName
                unitFrame.Castbar.Text:ClearAllPoints()
                unitFrame.Castbar.Text:SetPoint(SpellNameDB.Layout[1], unitFrame.Castbar, SpellNameDB.Layout[2], SpellNameDB.Layout[3], SpellNameDB.Layout[4])
                ZF:ApplyFontStringStyle(unitFrame.Castbar.Text, ZF.Media.Font, SpellNameDB.FontSize, GeneralDB.Fonts.FontFlag, SpellNameDB.Color, GeneralDB.Fonts.Shadow)
                unitFrame.Castbar.Text:SetJustifyH(ZF:SetJustification(SpellNameDB.Layout[1]))
                if SpellNameDB.Enabled then unitFrame.Castbar.Text:SetAlpha(1) else unitFrame.Castbar.Text:SetAlpha(0) end
            end

            if unitFrame.Castbar.Time then
                local DurationDB = ZF.db.profile.Units[ZF:GetNormalizedUnit(unit)].CastBar.Text.Duration
                unitFrame.Castbar.Time:ClearAllPoints()
                unitFrame.Castbar.Time:SetPoint(DurationDB.Layout[1], unitFrame.Castbar, DurationDB.Layout[2], DurationDB.Layout[3], DurationDB.Layout[4])
                ZF:ApplyFontStringStyle(unitFrame.Castbar.Time, ZF.Media.Font, DurationDB.FontSize, GeneralDB.Fonts.FontFlag, DurationDB.Color, GeneralDB.Fonts.Shadow)
                unitFrame.Castbar.Time:SetJustifyH(ZF:SetJustification(DurationDB.Layout[1]))
                if DurationDB.Enabled then unitFrame.Castbar.Time:SetAlpha(1) else unitFrame.Castbar.Time:SetAlpha(0) end
            end
        end
    else
        if not unitFrame.Castbar then return end
        if unitFrame:IsElementEnabled("Castbar") then unitFrame:DisableElement("Castbar") end
        unitFrame.Castbar:Hide()
        unitFrame.Castbar = nil
        if CastBarContainer then
            CastBarContainer:Hide()
        end
    end
    if unitFrame.isDesignerPreview and ZF.DESIGNER_PREVIEW_TOGGLES.CastBar then ZF:CreateTestCastBar(unitFrame, unit) end
end

function ZF:CreateTestCastBar(unitFrame, unit)
    if not unit then return end
    if not unitFrame then return end
    local CastBarDB = ZF.db.profile.Units[ZF:GetNormalizedUnit(unit)].CastBar
    local CastBarContainer = unitFrame.Castbar and unitFrame.Castbar:GetParent()
    if unitFrame.isDesignerPreview and ZF.DESIGNER_PREVIEW_TOGGLES.CastBar then
        if unitFrame.Castbar and CastBarDB.Enabled then
            unitFrame:DisableElement("Castbar")
            CastBarContainer:Show()
            CastBarContainer:SetFrameStrata(CastBarDB.FrameStrata)
            unitFrame.Castbar:Show()
            unitFrame.Castbar.Background:Show()
            local spellName = "Ethereal Portal"
            local maxChars = ZF.db.profile.Units[ZF:GetNormalizedUnit(unit)].CastBar.Text.SpellName.MaxChars
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
	if not ZF.db or not ZF.GetNormalizedUnit then return end
	for i = 1, 9 do
		local unitFrame = i == 1 and ZF.PLAYER or i == 2 and ZF.TARGET or i == 3 and ZF.FOCUS or i == 4 and ZF.PET or ZF["BOSS" .. (i - 4)]
		local castBar = unitFrame and unitFrame.Castbar
		local unit = unitFrame and unitFrame.__unit
		local UnitDB = unit and ZF.db.profile.Units[ZF:GetNormalizedUnit(unit)]
		if castBar and castBar:IsShown() and castBar.zfActive and UnitDB and UnitDB.CastBar then SetCastBarColor(castBar, unit, UnitDB.CastBar) end
	end
end)
