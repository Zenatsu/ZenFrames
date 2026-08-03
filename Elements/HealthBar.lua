local _, ZF = ...
local StatusBarInterpolation = Enum.StatusBarInterpolation
local oUF = ZF.oUF

local function SetHealthBackgroundColor(unitFrame, unit, HealthBarDB, forceUpdate)
	local backgroundUnit = unitFrame.unit or unit
	local isDead = HealthBarDB.ColorBackdropWhenDead and UnitIsDeadOrGhost(backgroundUnit)
	local backgroundClass
	local backgroundReaction
	if HealthBarDB.ColorBackgroundByClass then
		local unitToColor = backgroundUnit ~= "pet" and backgroundUnit or "player"
		backgroundClass = select(2, UnitClass(unitToColor))
		if not backgroundClass then backgroundReaction = UnitReaction(unitToColor, "player") end
	end
	if not forceUpdate and unitFrame.HealthBackgroundClass == backgroundClass and unitFrame.HealthBackgroundReaction == backgroundReaction and unitFrame.HealthBackgroundIsDead == isDead then return end
	unitFrame.HealthBackgroundClass = backgroundClass
	unitFrame.HealthBackgroundReaction = backgroundReaction
	unitFrame.HealthBackgroundIsDead = isDead

    if isDead then
        local deadBackdropColor = oUF.colors.deadBackdrop
        local r, g, b = deadBackdropColor:GetRGB()
        unitFrame.HealthBackground:SetStatusBarColor(r, g, b, HealthBarDB.BackgroundOpacity)
    elseif HealthBarDB.ColorBackgroundByClass then
        local unitToColor = backgroundUnit ~= "pet" and backgroundUnit or "player"
        local r, g, b = ZF:GetUnitColor(unitToColor)
        unitFrame.HealthBackground:SetStatusBarColor(r, g, b, HealthBarDB.BackgroundOpacity)
    else
        unitFrame.HealthBackground:SetStatusBarColor(HealthBarDB.Background[1], HealthBarDB.Background[2], HealthBarDB.Background[3], HealthBarDB.BackgroundOpacity)
    end
end

function ZF:CreateUnitHealthBar(unitFrame, unit)
    local FrameDB = ZF:GetUnitDB(unitFrame, unit).Frame
    local HealthBarDB = ZF:GetUnitDB(unitFrame, unit).HealthBar
    local unitContainer = unitFrame.Container

    if not unitFrame.HealthBar then
        if not unitFrame.HealthBackground then
            unitFrame.HealthBackground = CreateFrame("StatusBar", ZF:FetchFrameName(unit) .. "_HealthBackground", unitContainer)
            unitFrame.HealthBackground:SetPoint("TOPLEFT", unitContainer, "TOPLEFT", 1, -1)
            unitFrame.HealthBackground:SetSize(FrameDB.Width - 2, FrameDB.Height - 2)
            unitFrame.HealthBackground:SetStatusBarTexture(ZF.Media.Background)
            unitFrame.HealthBackground:SetFrameLevel(unitContainer:GetFrameLevel() + 1)
            SetHealthBackgroundColor(unitFrame, unit, HealthBarDB, true)
        end

        local HealthBar = CreateFrame("StatusBar", ZF:FetchFrameName(unit) .. "_HealthBar", unitContainer)
        HealthBar:SetPoint("TOPLEFT", unitContainer, "TOPLEFT", 1, -1)
        HealthBar:SetSize(FrameDB.Width - 2, FrameDB.Height - 2)
        HealthBar:SetStatusBarTexture(ZF.Media.Foreground)
        HealthBar:SetFrameLevel(unitContainer:GetFrameLevel() + 2)
        HealthBar:SetStatusBarColor(HealthBarDB.Foreground[1], HealthBarDB.Foreground[2], HealthBarDB.Foreground[3], HealthBarDB.ForegroundOpacity)
        HealthBar.colorClass = HealthBarDB.ColorByClass
        HealthBar.colorReaction = HealthBarDB.ColorByClass
        HealthBar.colorHealth = not HealthBarDB.ColorByClass
        HealthBar.colorTapping = HealthBarDB.ColorWhenTapped
        HealthBar.colorDisconnected = HealthBarDB.ColorWhenDisconnected
        HealthBar.smoothing = HealthBarDB.Smooth ~= false and StatusBarInterpolation.ExponentialEaseOut or StatusBarInterpolation.Immediate
		HealthBar.PostUpdateColor = function(healthBar, unit, color)
			if color and color ~= oUF.colors.health then return end
			local currentHealthBarDB = ZF:GetUnitDB(unitFrame, unit).HealthBar
			if unit == "pet" and currentHealthBarDB.ColorByClass then
				local unitColor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
				if unitColor then healthBar:SetStatusBarColor(unitColor.r, unitColor.g, unitColor.b, currentHealthBarDB.ForegroundOpacity) return end
			end
			healthBar:SetStatusBarColor(currentHealthBarDB.Foreground[1], currentHealthBarDB.Foreground[2], currentHealthBarDB.Foreground[3], currentHealthBarDB.ForegroundOpacity)
		end

        if unit == "pet" and HealthBarDB.ColorByClass then
            HealthBar.colorClass = false
            HealthBar.colorReaction = false
            HealthBar.colorHealth = false
        end

        unitFrame.Health = HealthBar

        unitFrame.Health.PostUpdate = function(_, _, curHP, maxHP)
            local unitHP = unitFrame.HealthBackground
            maxHP = maxHP or 1
            curHP = curHP or 0
            unitHP:SetMinMaxValues(0, maxHP)
            unitHP:SetValue(UnitHealthMissing(unitFrame.unit, true), unitFrame.Health.smoothing)
			SetHealthBackgroundColor(unitFrame, unit, ZF:GetUnitDB(unitFrame, unit).HealthBar)
        end

        if HealthBarDB.Inverse then
            unitFrame.Health:SetReverseFill(true)
            unitFrame.HealthBackground:SetReverseFill(false)
        else
            unitFrame.Health:SetReverseFill(false)
            unitFrame.HealthBackground:SetReverseFill(true)
        end

    end
end

function ZF:UpdateUnitHealthBar(unitFrame, unit)
    local FrameDB = ZF:GetUnitDB(unitFrame, unit).Frame
    local HealthBarDB = ZF:GetUnitDB(unitFrame, unit).HealthBar
    local DispelHighlightDB = ZF:GetUnitDB(unitFrame, unit).HealthBar.DispelHighlight

    if unitFrame then
        unitFrame:SetSize(FrameDB.Width, FrameDB.Height)
        ZF:PlaceUnitFrame(unitFrame, unit)
    end

    if unitFrame.Health then
        unitFrame.Health:SetSize(FrameDB.Width - 2, FrameDB.Height - 2)
        unitFrame.Health:SetStatusBarColor(HealthBarDB.Foreground[1], HealthBarDB.Foreground[2], HealthBarDB.Foreground[3], HealthBarDB.ForegroundOpacity)
        unitFrame.Health.colorClass = HealthBarDB.ColorByClass
        unitFrame.Health.colorReaction = HealthBarDB.ColorByClass
        unitFrame.Health.colorHealth = not HealthBarDB.ColorByClass
        unitFrame.Health.colorTapping = HealthBarDB.ColorWhenTapped
        unitFrame.Health.colorDisconnected = HealthBarDB.ColorWhenDisconnected
        unitFrame.Health.smoothing = HealthBarDB.Smooth ~= false and StatusBarInterpolation.ExponentialEaseOut or StatusBarInterpolation.Immediate
        unitFrame.Health:SetStatusBarTexture(ZF.Media.Foreground)
        if unit == "pet" and HealthBarDB.ColorByClass then
            unitFrame.Health.colorClass = false
            unitFrame.Health.colorReaction = false
            unitFrame.Health.colorHealth = false
        end
    end

    if unitFrame.HealthBackground then
        unitFrame.HealthBackground:SetSize(FrameDB.Width - 2, FrameDB.Height - 2)
        SetHealthBackgroundColor(unitFrame, unit, HealthBarDB, true)
        unitFrame.HealthBackground:SetStatusBarTexture(ZF.Media.Background)
    end

    if HealthBarDB.Inverse then
        unitFrame.Health:SetReverseFill(true)
        unitFrame.HealthBackground:SetReverseFill(false)
    else
        unitFrame.Health:SetReverseFill(false)
        unitFrame.HealthBackground:SetReverseFill(true)
    end

    if unitFrame.DispelHighlight then
        ZF:UpdateUnitDispelHighlight(unitFrame, unit)
    end

    unitFrame.Health:ForceUpdate()
end
