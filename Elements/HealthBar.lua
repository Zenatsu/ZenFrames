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

local function ApplyHealthBarSettings(unitFrame, unit, HealthBarDB)
    local HealthBar = unitFrame.Health
    HealthBar:SetStatusBarColor(HealthBarDB.Foreground[1], HealthBarDB.Foreground[2], HealthBarDB.Foreground[3], HealthBarDB.ForegroundOpacity)
    HealthBar:SetStatusBarTexture(ZF.Media.Foreground)
    HealthBar.colorClass = HealthBarDB.ColorByClass
    HealthBar.colorReaction = HealthBarDB.ColorByClass
    HealthBar.colorHealth = not HealthBarDB.ColorByClass
    HealthBar.colorTapping = HealthBarDB.ColorWhenTapped
    HealthBar.colorDisconnected = HealthBarDB.ColorWhenDisconnected
    HealthBar.smoothing = HealthBarDB.Smooth ~= false and StatusBarInterpolation.ExponentialEaseOut or StatusBarInterpolation.Immediate

    if unit == "pet" and HealthBarDB.ColorByClass then
        HealthBar.colorClass = false
        HealthBar.colorReaction = false
        HealthBar.colorHealth = false
    end
end

function ZF:CreateUnitHealthBar(unitFrame, unit)
    local FrameDB = ZF:GetUnitDB(unitFrame, unit).Frame
    local HealthBarDB = ZF:GetUnitDB(unitFrame, unit).HealthBar
    unitFrame.HealthBarDB = HealthBarDB
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
        HealthBar:SetFrameLevel(unitContainer:GetFrameLevel() + 2)
		HealthBar.PostUpdateColor = function(healthBar, _, color)
			local currentHealthBarDB = unitFrame.HealthBarDB
			if color and color ~= oUF.colors.health then return end
			if unit == "pet" and currentHealthBarDB.ColorByClass then
				local unitColor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
				if unitColor then healthBar:SetStatusBarColor(unitColor.r, unitColor.g, unitColor.b, currentHealthBarDB.ForegroundOpacity) return end
			end
			healthBar:SetStatusBarColor(currentHealthBarDB.Foreground[1], currentHealthBarDB.Foreground[2], currentHealthBarDB.Foreground[3], currentHealthBarDB.ForegroundOpacity)
		end

        unitFrame.Health = HealthBar
        ApplyHealthBarSettings(unitFrame, unit, HealthBarDB)

        unitFrame.Health.PostUpdate = function(_, _, curHP, maxHP)
            local unitHP = unitFrame.HealthBackground
            maxHP = maxHP or 1
            unitHP:SetMinMaxValues(0, maxHP)
            unitHP:SetValue(UnitHealthMissing(unit, true), unitFrame.Health.smoothing)
			SetHealthBackgroundColor(unitFrame, unit, unitFrame.HealthBarDB)
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
    if InCombatLockdown() then return end
    local FrameDB = ZF:GetUnitDB(unitFrame, unit).Frame
    local HealthBarDB = ZF:GetUnitDB(unitFrame, unit).HealthBar
    unitFrame.HealthBarDB = HealthBarDB

    if unitFrame then
        unitFrame:SetSize(FrameDB.Width, FrameDB.Height)
        ZF:PlaceUnitFrame(unitFrame, unit)
    end

    if unitFrame.Health then
        unitFrame.Health:SetSize(FrameDB.Width - 2, FrameDB.Height - 2)
        ApplyHealthBarSettings(unitFrame, unit, HealthBarDB)
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
