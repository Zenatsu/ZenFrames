local _, RUF = ...

local function SetCastBarColor(castBar, unit, CastBarDB)
	local r, g, b, a
	if CastBarDB.ColorByClass then
		local unitForClass = unit == "pet" and "player" or unit
		local unitClass = select(2, UnitClass(unitForClass))
		local unitColor = RAID_CLASS_COLORS[unitClass]
		if unitColor then r, g, b, a = unitColor.r, unitColor.g, unitColor.b, CastBarDB.ForegroundOpacity end
	end
	if not r then r, g, b, a = unpack(CastBarDB.Foreground) end
	if RUF.IsInterruptOnCooldown and C_CurveUtil.EvaluateColorValueFromBoolean and (castBar.casting or castBar.channeling or castBar.empowering) and castBar.notInterruptible ~= nil and UnitCanAttack("player", unit) and RUF:IsInterruptOnCooldown() then
		local CDR, CDG, CDB, CDA = unpack(CastBarDB.InterruptCooldownColor or CastBarDB.InterruptOnCooldownColor)
		r = C_CurveUtil.EvaluateColorValueFromBoolean(castBar.notInterruptible, r, CDR)
		g = C_CurveUtil.EvaluateColorValueFromBoolean(castBar.notInterruptible, g, CDG)
		b = C_CurveUtil.EvaluateColorValueFromBoolean(castBar.notInterruptible, b, CDB)
		a = C_CurveUtil.EvaluateColorValueFromBoolean(castBar.notInterruptible, a or 1, CDA or a or 1)
	end
	castBar:SetStatusBarColor(r, g, b, a)
end

function RUF:CreateUnitCastBar(unitFrame, unit)
    local GeneralDB = RUF.db.profile.General
    local FrameDB = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)].Frame
    local CastBarDB = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)].CastBar
    local SpellNameDB = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)].CastBar.Text.SpellName
    local DurationDB = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)].CastBar.Text.Duration

    local CastBarContainer = CreateFrame("Frame", RUF:FetchFrameName(unit) .. "_CastBarContainer", unitFrame, "BackdropTemplate")
    CastBarContainer:SetBackdrop(RUF.BACKDROP)
    CastBarContainer:SetBackdropColor(0, 0, 0, 0)
    CastBarContainer:SetBackdropBorderColor(0, 0, 0, 1)
    CastBarContainer:ClearAllPoints()
    CastBarContainer:SetPoint(CastBarDB.Layout[1], unitFrame, CastBarDB.Layout[2], CastBarDB.Layout[3], CastBarDB.Layout[4])
    if CastBarDB.MatchParentWidth then CastBarContainer:SetWidth(FrameDB.Width) else CastBarContainer:SetWidth(CastBarDB.Width) end
    CastBarContainer:SetHeight(CastBarDB.Height)
    CastBarContainer:SetFrameStrata(CastBarDB.FrameStrata)
    CastBarContainer:Hide()

    local CastBar = CreateFrame("StatusBar", RUF:FetchFrameName(unit) .. "_CastBar", CastBarContainer)
    CastBar:SetStatusBarTexture(RUF.Media.Foreground)
    CastBar:ClearAllPoints()
    CastBar:SetPoint("TOPLEFT", CastBarContainer, "TOPLEFT", 1, -1)
    CastBar:SetPoint("BOTTOMRIGHT", CastBarContainer, "BOTTOMRIGHT", -1, 1)
    CastBar:SetFrameLevel(CastBarContainer:GetFrameLevel() + 1)
    CastBar.timeToHold = CastBarDB.HoldTime
    SetCastBarColor(CastBar, unit, CastBarDB)

    CastBar.Background = CastBar:CreateTexture(nil, "BACKGROUND")
    CastBar.Background:SetAllPoints(CastBar)
    CastBar.Background:SetTexture(RUF.Media.Background)
    CastBar.Background:SetVertexColor(unpack(CastBarDB.Background))

    CastBar.NotInterruptibleOverlay = CastBar:CreateTexture(nil, "ARTWORK", nil, 1)
    CastBar.NotInterruptibleOverlay:SetPoint("TOPLEFT", CastBar:GetStatusBarTexture(), "TOPLEFT")
    CastBar.NotInterruptibleOverlay:SetPoint("BOTTOMRIGHT", CastBar:GetStatusBarTexture(), "BOTTOMRIGHT")
    CastBar.NotInterruptibleOverlay:SetTexture(RUF.Media.Foreground)
    CastBar.NotInterruptibleOverlay:SetVertexColor(unpack(CastBarDB.NotInterruptibleColor))
    CastBar.NotInterruptibleOverlay:SetAlpha(0)

    CastBar.Icon = CastBar:CreateTexture(RUF:FetchFrameName(unit) .. "_CastBarIcon", "ARTWORK")
    CastBar.Icon:SetSize(CastBarDB.Height - 2, CastBarDB.Height - 2)
    CastBar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    CastBar.Icon:ClearAllPoints()
    if CastBarDB.Icon.Enabled and CastBarDB.Icon.Position == "LEFT" then
        CastBar.Icon:SetPoint("TOPLEFT", CastBarContainer, "TOPLEFT", 1, -1)
        CastBar:ClearAllPoints()
        CastBar:SetPoint("TOPLEFT", CastBarContainer, "TOPLEFT", CastBarDB.Height - 1, -1)
        CastBar:SetPoint("BOTTOMRIGHT", CastBarContainer, "BOTTOMRIGHT", -1, 1)
    elseif CastBarDB.Icon.Enabled and CastBarDB.Icon.Position == "RIGHT" then
        CastBar.Icon:SetPoint("TOPRIGHT", CastBarContainer, "TOPRIGHT", -1, -1)
        CastBar:ClearAllPoints()
        CastBar:SetPoint("TOPLEFT", CastBarContainer, "TOPLEFT", 1, -1)
        CastBar:SetPoint("BOTTOMRIGHT", CastBarContainer, "BOTTOMRIGHT", -(CastBarDB.Height - 1), 1)
    elseif not CastBarDB.Icon.Enabled then
        CastBar.Icon:Hide()
        CastBar:ClearAllPoints()
        CastBar:SetPoint("TOPLEFT", CastBarContainer, "TOPLEFT", 1, -1)
        CastBar:SetPoint("BOTTOMRIGHT", CastBarContainer, "BOTTOMRIGHT", -1, 1)
    end

    local SpellNameText = CastBar:CreateFontString(RUF:FetchFrameName(unit) .. "_CastBarSpellNameText", "OVERLAY", "GameFontNormal")
    SpellNameText:ClearAllPoints()
    SpellNameText:SetPoint(SpellNameDB.Layout[1], CastBar, SpellNameDB.Layout[2], SpellNameDB.Layout[3], SpellNameDB.Layout[4])
    RUF:ApplyFontStringStyle(SpellNameText, RUF.Media.Font, SpellNameDB.FontSize, GeneralDB.Fonts.FontFlag, SpellNameDB.Color, GeneralDB.Fonts.Shadow)
    SpellNameText:SetJustifyH(RUF:SetJustification(SpellNameDB.Layout[1]))

    local DurationText = CastBar:CreateFontString(RUF:FetchFrameName(unit) .. "_CastBarDurationText", "OVERLAY", "GameFontNormal")
    DurationText:ClearAllPoints()
    DurationText:SetPoint(DurationDB.Layout[1], CastBar, DurationDB.Layout[2], DurationDB.Layout[3], DurationDB.Layout[4])
    RUF:ApplyFontStringStyle(DurationText, RUF.Media.Font, DurationDB.FontSize, GeneralDB.Fonts.FontFlag, DurationDB.Color, GeneralDB.Fonts.Shadow)
    DurationText:SetJustifyH(RUF:SetJustification(DurationDB.Layout[1]))

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

        unitFrame.Castbar.PostCastStart = function(frameCastBar)
			local currentCastBarDB = RUF:GetUnitDB(unitFrame, unit).CastBar
			local currentSpellNameDB = currentCastBarDB.Text.SpellName
			SetCastBarColor(frameCastBar, unit, currentCastBarDB)

            local spellInfo = C_Spell.GetSpellInfo(frameCastBar.spellID)
            local spellName = spellInfo and spellInfo.name
            if spellName then
                if not RUF:IsSecretValue(spellName) then
					if currentSpellNameDB.MaxChars and currentSpellNameDB.MaxChars > 0 then spellName = string.format("%." .. currentSpellNameDB.MaxChars .. "s", spellName) end
                    spellName = RUF:CleanTruncateUTF8String(spellName)
                end
				local targetName = currentCastBarDB.ShowTarget and not UnitSpellTargetName and UnitName(unit .. "target")
				if currentCastBarDB.ShowTarget and UnitSpellTargetName and (frameCastBar.casting or (frameCastBar.channeling or frameCastBar.empowering) and UnitShouldDisplaySpellTargetName(unit)) then targetName = UnitSpellTargetName(unit) end
                if RUF:IsSecretValue(targetName) or targetName then frameCastBar.Text:SetFormattedText("%s » %s", spellName, targetName) else frameCastBar.Text:SetText(spellName) end
            else
                frameCastBar.Text:SetText("")
            end

            if frameCastBar.NotInterruptibleOverlay and frameCastBar.notInterruptible ~= nil then frameCastBar.NotInterruptibleOverlay:SetAlphaFromBoolean(frameCastBar.notInterruptible, 1, 0) end
            CastBarContainer:Show()
        end

        unitFrame.Castbar.PostCastInterruptible = function(frameCastBar)
            if frameCastBar.NotInterruptibleOverlay and frameCastBar.notInterruptible ~= nil then frameCastBar.NotInterruptibleOverlay:SetAlphaFromBoolean(frameCastBar.notInterruptible, 1, 0) end
			SetCastBarColor(frameCastBar, unit, RUF:GetUnitDB(unitFrame, unit).CastBar)
        end
        unitFrame.Castbar.PostCastFail = function(frameCastBar)
			frameCastBar:SetStatusBarColor(unpack(RUF:GetUnitDB(unitFrame, unit).CastBar.InterruptedFailedColor))
            if frameCastBar.NotInterruptibleOverlay then frameCastBar.NotInterruptibleOverlay:SetAlpha(0) end
        end
        unitFrame.Castbar.PostCastInterrupted = unitFrame.Castbar.PostCastFail
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

function RUF:UpdateUnitCastBar(unitFrame, unit)
    local GeneralDB = RUF.db.profile.General
    local FrameDB = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)].Frame
    local CastBarDB = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)].CastBar
    local CastBarContainer = unitFrame.Castbar and unitFrame.Castbar:GetParent()

    if CastBarDB.Enabled then
        unitFrame.Castbar = unitFrame.Castbar or RUF:CreateUnitCastBar(unitFrame, unit)
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
            unitFrame.Castbar:SetStatusBarTexture(RUF.Media.Foreground)
            unitFrame.Castbar.timeToHold = CastBarDB.HoldTime
            unitFrame.Castbar.Background:SetTexture(RUF.Media.Background)
            SetCastBarColor(unitFrame.Castbar, unit, CastBarDB)
            unitFrame.Castbar.Background:SetVertexColor(unpack(CastBarDB.Background))

            if unitFrame.Castbar.NotInterruptibleOverlay then
                unitFrame.Castbar.NotInterruptibleOverlay:SetTexture(RUF.Media.Foreground)
                unitFrame.Castbar.NotInterruptibleOverlay:SetVertexColor(unpack(CastBarDB.NotInterruptibleColor))
            end

            if CastBarDB.Inverse then
                unitFrame.Castbar:SetReverseFill(true)
            else
                unitFrame.Castbar:SetReverseFill(false)
            end

            if CastBarDB.Icon.Enabled then
                unitFrame.Castbar.Icon = unitFrame.Castbar.Icon or unitFrame.Castbar:CreateTexture(RUF:FetchFrameName(unit) .. "_CastBarIcon", "ARTWORK")
                unitFrame.Castbar.Icon:SetSize(CastBarDB.Height - 2, CastBarDB.Height - 2)
                unitFrame.Castbar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                unitFrame.Castbar.Icon:ClearAllPoints()
                if CastBarDB.Icon.Enabled and CastBarDB.Icon.Position == "LEFT" then
                    unitFrame.Castbar.Icon:SetPoint("TOPLEFT", CastBarContainer, "TOPLEFT", 1, -1)
                    unitFrame.Castbar:ClearAllPoints()
                    unitFrame.Castbar:SetPoint("TOPLEFT", CastBarContainer, "TOPLEFT", CastBarDB.Height - 1, -1)
                    unitFrame.Castbar:SetPoint("BOTTOMRIGHT", CastBarContainer, "BOTTOMRIGHT", -1, 1)
                elseif CastBarDB.Icon.Enabled and CastBarDB.Icon.Position == "RIGHT" then
                    unitFrame.Castbar.Icon:SetPoint("TOPRIGHT", CastBarContainer, "TOPRIGHT", -1, -1)
                    unitFrame.Castbar:ClearAllPoints()
                    unitFrame.Castbar:SetPoint("TOPLEFT", CastBarContainer, "TOPLEFT", 1, -1)
                    unitFrame.Castbar:SetPoint("BOTTOMRIGHT", CastBarContainer, "BOTTOMRIGHT", -(CastBarDB.Height - 1), 1)
                elseif not CastBarDB.Icon.Enabled then
                    unitFrame.Castbar.Icon:Hide()
                    unitFrame.Castbar:ClearAllPoints()
                    unitFrame.Castbar:SetPoint("TOPLEFT", CastBarContainer, "TOPLEFT", 1, -1)
                    unitFrame.Castbar:SetPoint("BOTTOMRIGHT", CastBarContainer, "BOTTOMRIGHT", -1, 1)
                end
                unitFrame.Castbar.Icon:Show()
            else
                if unitFrame.Castbar.Icon then unitFrame.Castbar.Icon:Hide() end
                unitFrame.Castbar.Icon = nil
                unitFrame.Castbar:ClearAllPoints()
                unitFrame.Castbar:SetPoint("TOPLEFT", CastBarContainer, "TOPLEFT", 1, -1)
                unitFrame.Castbar:SetPoint("BOTTOMRIGHT", CastBarContainer, "BOTTOMRIGHT", -1, 1)
            end

            if unitFrame.Castbar.Text then
                local SpellNameDB = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)].CastBar.Text.SpellName
                unitFrame.Castbar.Text:ClearAllPoints()
                unitFrame.Castbar.Text:SetPoint(SpellNameDB.Layout[1], unitFrame.Castbar, SpellNameDB.Layout[2], SpellNameDB.Layout[3], SpellNameDB.Layout[4])
                RUF:ApplyFontStringStyle(unitFrame.Castbar.Text, RUF.Media.Font, SpellNameDB.FontSize, GeneralDB.Fonts.FontFlag, SpellNameDB.Color, GeneralDB.Fonts.Shadow)
                unitFrame.Castbar.Text:SetJustifyH(RUF:SetJustification(SpellNameDB.Layout[1]))
                if SpellNameDB.Enabled then unitFrame.Castbar.Text:SetAlpha(1) else unitFrame.Castbar.Text:SetAlpha(0) end
            end

            if unitFrame.Castbar.Time then
                local DurationDB = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)].CastBar.Text.Duration
                unitFrame.Castbar.Time:ClearAllPoints()
                unitFrame.Castbar.Time:SetPoint(DurationDB.Layout[1], unitFrame.Castbar, DurationDB.Layout[2], DurationDB.Layout[3], DurationDB.Layout[4])
                RUF:ApplyFontStringStyle(unitFrame.Castbar.Time, RUF.Media.Font, DurationDB.FontSize, GeneralDB.Fonts.FontFlag, DurationDB.Color, GeneralDB.Fonts.Shadow)
                unitFrame.Castbar.Time:SetJustifyH(RUF:SetJustification(DurationDB.Layout[1]))
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
    if RUF.CASTBAR_TEST_MODE or (unitFrame.isDesignerPreview and RUF.DESIGNER_PREVIEW_TOGGLES.CastBar) then RUF:CreateTestCastBar(unitFrame, unit) end
end

function RUF:CreateTestCastBar(unitFrame, unit)
    if not unit then return end
    if not unitFrame then return end
    local GeneralDB = RUF.db.profile.General
    local CastBarDB = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)].CastBar
    local CastBarContainer = unitFrame.Castbar and unitFrame.Castbar:GetParent()
    if RUF.CASTBAR_TEST_MODE or (unitFrame.isDesignerPreview and RUF.DESIGNER_PREVIEW_TOGGLES.CastBar) then
        if unitFrame.Castbar and CastBarDB.Enabled then
            unitFrame:DisableElement("Castbar")
            CastBarContainer:Show()
            CastBarContainer:SetFrameStrata(CastBarDB.FrameStrata)
            unitFrame.Castbar:Show()
            unitFrame.Castbar.Background:Show()
            local spellName = "Ethereal Portal"
            local maxChars = RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)].CastBar.Text.SpellName.MaxChars
            if maxChars and maxChars > 0 then spellName = string.format("%." .. maxChars .. "s", spellName) end
            spellName = RUF:CleanTruncateUTF8String(spellName)
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
	if not RUF.db or not RUF.GetNormalizedUnit then return end
	for i = 1, 9 do
		local unitFrame = i == 1 and RUF.PLAYER or i == 2 and RUF.TARGET or i == 3 and RUF.FOCUS or i == 4 and RUF.PET or RUF["BOSS" .. (i - 4)]
		local castBar = unitFrame and unitFrame.Castbar
		local unit = unitFrame and unitFrame.unit
		local UnitDB = unit and RUF.db.profile.Units[RUF:GetNormalizedUnit(unit)]
		if castBar and castBar:IsShown() and (castBar.casting or castBar.channeling or castBar.empowering) and UnitDB and UnitDB.CastBar then SetCastBarColor(castBar, unit, UnitDB.CastBar) end
	end
end)
