local _, ZF = ...
local oUF = ZF.oUF

local abbrevData = {
   breakpointData = {
      {
         breakpoint = 1e12,
         abbreviation = "B",
         significandDivisor = 1e10,
         fractionDivisor = 100,
         abbreviationIsGlobal = false,
      },
      {
         breakpoint = 1e11,
         abbreviation = "B",
         significandDivisor = 1e9,
         fractionDivisor = 1,
         abbreviationIsGlobal = false,
      },
      {
         breakpoint = 1e10,
         abbreviation = "B",
         significandDivisor = 1e8,
         fractionDivisor = 10,
         abbreviationIsGlobal = false,
      },
      {
         breakpoint = 1e9,
         abbreviation = "B",
         significandDivisor = 1e7,
         fractionDivisor = 100,
         abbreviationIsGlobal = false,
      },
      {
         breakpoint = 1e8,
         abbreviation = "M",
         significandDivisor = 1e6,
         fractionDivisor = 1,
         abbreviationIsGlobal = false,
      },
      {
         breakpoint = 1e7,
         abbreviation = "M",
         significandDivisor = 1e5,
         fractionDivisor = 10,
        abbreviationIsGlobal = false,
      },
      {
         breakpoint = 1e6,
         abbreviation = "M",
         significandDivisor = 1e4,
         fractionDivisor = 100,
         abbreviationIsGlobal = false,
      },
      {
         breakpoint = 1e5,
         abbreviation = "K",
         significandDivisor = 1000,
         fractionDivisor = 1,
         abbreviationIsGlobal = false,
      },
      {
         breakpoint = 1e4,
         abbreviation = "K",
         significandDivisor = 100,
         fractionDivisor = 10,
         abbreviationIsGlobal = false,
      },
   },
}

local function AbbreviateValue(value)
    local useCustomAbbreviations = ZF.db.profile.General.UseCustomAbbreviations
    if useCustomAbbreviations then
        return AbbreviateNumbers(value, abbrevData)
    else
        return AbbreviateLargeNumbers(value)
    end
end

local function FetchUnitPowerColor(unit)
    local powerType = UnitPowerType(unit)
    local powerColor = powerType and ZF.db.profile.General.Colors.Power[powerType]
    if powerColor then
        local powerColorR, powerColorG, powerColorB = unpack(powerColor)
        return powerColorR, powerColorG, powerColorB
    end
    return 1, 1, 1
end

oUF.Tags.Methods["perhp"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitHealthPercent = UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)
    local unitStatus = UnitIsDead(unit) and DEAD or UnitIsGhost(unit) and "Ghost" or not UnitIsConnected(unit) and "Offline"
    if unitStatus then
        return unitStatus
    else
        return string.format("%.0f", unitHealthPercent)
    end
end

oUF.Tags.Methods["perhp-with-sign"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitHealthPercent = UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)
    local unitStatus = UnitIsDead(unit) and DEAD or UnitIsGhost(unit) and "Ghost" or not UnitIsConnected(unit) and "Offline"
    if unitStatus then
        return unitStatus
    else
        return string.format("%.0f%%", unitHealthPercent)
    end
end

oUF.Tags.Methods["curhp:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitHealth = UnitHealth(unit)
    local unitStatus = UnitIsDead(unit) and DEAD or UnitIsGhost(unit) and "Ghost" or not UnitIsConnected(unit) and "Offline"
    if unitStatus then
        return unitStatus
    else
        return string.format("%s", AbbreviateValue(unitHealth))
    end
end

oUF.Tags.Methods["curhpperhp"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitHealth = UnitHealth(unit)
    local unitHealthPercent = UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)
    local unitStatus = UnitIsDead(unit) and DEAD or UnitIsGhost(unit) and "Ghost" or not UnitIsConnected(unit) and "Offline"
    if unitStatus then
        return unitStatus
    else
        if ZF.SEPARATOR == "[]" then
            return string.format("%s [%.0f%%]", unitHealth, unitHealthPercent)
        elseif ZF.SEPARATOR == "()" then
            return string.format("%s (%.0f%%)", unitHealth, unitHealthPercent)
        elseif ZF.SEPARATOR == " " then
            return string.format("%s %.0f%%", unitHealth, unitHealthPercent)
        else
            return string.format("%s %s %.0f%%", unitHealth, ZF.SEPARATOR, unitHealthPercent)
        end
    end
end

oUF.Tags.Methods["curhpperhp:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitHealth = UnitHealth(unit)
    local unitHealthPercent = UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)
    local unitStatus = UnitIsDead(unit) and DEAD or UnitIsGhost(unit) and "Ghost" or not UnitIsConnected(unit) and "Offline"
    if unitStatus then
        return unitStatus
    else
        if ZF.SEPARATOR == "[]" then
            return string.format("%s [%.0f%%]", AbbreviateValue(unitHealth), unitHealthPercent)
        elseif ZF.SEPARATOR == "()" then
            return string.format("%s (%.0f%%)", AbbreviateValue(unitHealth), unitHealthPercent)
        elseif ZF.SEPARATOR == " " then
            return string.format("%s %.0f%%", AbbreviateValue(unitHealth), unitHealthPercent)
        else
            return string.format("%s %s %.0f%%", AbbreviateValue(unitHealth), ZF.SEPARATOR, unitHealthPercent)
        end
    end
end

oUF.Tags.Methods["absorbs"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
    if absorbAmount then
        return string.format("%s", absorbAmount)
    end
end

oUF.Tags.Methods["absorbs:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
    if absorbAmount then
        return string.format("%s", AbbreviateValue(absorbAmount))
    end
end

oUF.Tags.Methods["absorbs:truncate"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
    if absorbAmount then
        return string.format("%s", C_StringUtil.TruncateWhenZero(absorbAmount))
    end
end

oUF.Tags.Methods["curpp:color"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local powerColorR, powerColorG, powerColorB = FetchUnitPowerColor(unit)
    local unitPower = UnitPower(unit)
    if unitPower then
        return string.format("|cff%02x%02x%02x%s|r", powerColorR * 255, powerColorG * 255, powerColorB * 255, unitPower)
    end
end

oUF.Tags.Methods["maxpp:color"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local powerColorR, powerColorG, powerColorB = FetchUnitPowerColor(unit)
    local unitPowerMax = UnitPowerMax(unit)
    if unitPowerMax then
        return string.format("|cff%02x%02x%02x%s|r", powerColorR * 255, powerColorG * 255, powerColorB * 255, unitPowerMax)
    end
end

oUF.Tags.Methods["curpp:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitPower = UnitPower(unit)
    if unitPower then
        return string.format("%s", AbbreviateValue(unitPower))
    end
end

oUF.Tags.Methods["curpp:manapercent"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitPower = UnitPower(unit)
    local unitPowerType = UnitPowerType(unit)
    if unitPowerType == Enum.PowerType.Mana and unitPower then
        local powerPercent = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
        return string.format("%.f", powerPercent)
    else
        return string.format("%s", unitPower)
    end
end

oUF.Tags.Methods["curpp:manapercent:healer"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    if UnitGroupRolesAssigned(unit) ~= "HEALER" then return "" end
    local unitPower = UnitPower(unit, Enum.PowerType.Mana)
    if unitPower then
        local powerPercent = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
        return string.format("%.f", powerPercent)
    end
end

oUF.Tags.Methods["curpp:manapercent:healer:color"] = function(unit)
    if not unit then return end
    if UnitGroupRolesAssigned(unit) ~= "HEALER" then return end
    local unitPower = UnitPower(unit, Enum.PowerType.Mana)
    if unitPower then
        local powerPercent = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
        local manaColor = ZF.db.profile.General.Colors.Power[0]
        if manaColor then
            local manaColorR, manaColorG, manaColorB = unpack(manaColor)
            return string.format("|cff%02x%02x%02x%.f|r", manaColorR * 255, manaColorG * 255, manaColorB * 255, powerPercent)
        end
    end
end

oUF.Tags.Methods["curpp:manapercent-with-sign:healer"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    if UnitGroupRolesAssigned(unit) ~= "HEALER" then return "" end
    local unitPower = UnitPower(unit, Enum.PowerType.Mana)
    if unitPower then
        local powerPercent = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
        return string.format("%.f%%", powerPercent)
    end
end

oUF.Tags.Methods["curpp:manapercent-with-sign:healer:color"] = function(unit)
    if not unit then return end
    if UnitGroupRolesAssigned(unit) ~= "HEALER" then return end
    local unitPower = UnitPower(unit, Enum.PowerType.Mana)
    if unitPower then
        local powerPercent = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
        local manaColor = ZF.db.profile.General.Colors.Power[0]
        if manaColor then
            local manaColorR, manaColorG, manaColorB = unpack(manaColor)
            return string.format("|cff%02x%02x%02x%.f%%|r", manaColorR * 255, manaColorG * 255, manaColorB * 255, powerPercent)
        end
    end
end

oUF.Tags.Methods["curpp:manapercent-with-sign"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitPower = UnitPower(unit)
    local unitPowerType = UnitPowerType(unit)
    if unitPowerType == Enum.PowerType.Mana and unitPower then
        local powerPercent = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
        return string.format("%.f%%", powerPercent)
    else
        return string.format("%s", unitPower)
    end
end

oUF.Tags.Methods["curpp:manapercent:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitPower = UnitPower(unit)
    local unitPowerType = UnitPowerType(unit)
    if unitPowerType == Enum.PowerType.Mana and unitPower then
        local powerPercent = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
        return string.format("%.f", powerPercent)
    else
        return string.format("%s", AbbreviateValue(unitPower))
    end
end

oUF.Tags.Methods["curpp:manapercent-with-sign:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitPower = UnitPower(unit)
    local unitPowerType = UnitPowerType(unit)
    if unitPowerType == Enum.PowerType.Mana and unitPower then
        local powerPercent = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
        return string.format("%.f%%", powerPercent)
    else
        return string.format("%s", AbbreviateValue(unitPower))
    end
end

oUF.Tags.Methods["maxpp:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitPowerMax = UnitPowerMax(unit)
    if unitPowerMax then
        return string.format("%s", AbbreviateValue(unitPowerMax))
    end
end

oUF.Tags.Methods["curpp:abbr:color"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local powerColorR, powerColorG, powerColorB = FetchUnitPowerColor(unit)
    local unitPower = UnitPower(unit)
    if unitPower then
        return string.format("|cff%02x%02x%02x%s|r", powerColorR * 255, powerColorG * 255, powerColorB * 255, AbbreviateValue(unitPower))
    end
end

oUF.Tags.Methods["maxpp:abbr:color"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local powerColorR, powerColorG, powerColorB = FetchUnitPowerColor(unit)
    local unitPowerMax = UnitPowerMax(unit)
    if unitPowerMax then
        return string.format("|cff%02x%02x%02x%s|r", powerColorR * 255, powerColorG * 255, powerColorB * 255, AbbreviateValue(unitPowerMax))
    end
end

oUF.Tags.Methods["maxhp:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitMaxHealth = UnitHealthMax(unit)
    if unitMaxHealth then
        return string.format("%s", AbbreviateValue(unitMaxHealth))
    end
end

oUF.Tags.Methods["maxhp:abbr:color"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local classColorR, classColorG, classColorB = ZF:GetUnitColor(unit)
    local unitMaxHealth = UnitHealthMax(unit)
    if unitMaxHealth then
        return string.format("|cff%02x%02x%02x%s|r", classColorR * 255, classColorG * 255, classColorB * 255, AbbreviateValue(unitMaxHealth))
    end
end

oUF.Tags.Methods["name:color"] = function(unit)
    local classColorR, classColorG, classColorB = ZF:GetUnitColor(unit)
    local unitName = UnitName(unit) or ""
    return string.format("|cff%02x%02x%02x%s|r", classColorR * 255, classColorG * 255, classColorB * 255, unitName)
end

oUF.Tags.Methods["name:target"] = function(unit)
    local targetUnit = unit and (unit .. "target")
    local arrowSeperator = ZF.TOT_SEPARATOR
    if not targetUnit or not UnitExists(targetUnit) then return "" end
    return string.format(" %s %s", arrowSeperator, UnitName(targetUnit) or "")
end

oUF.Tags.Methods["name:target:color"] = function(unit)
    local targetUnit = unit and (unit .. "target")
    local arrowSeperator = ZF.TOT_SEPARATOR
    if not targetUnit or not UnitExists(targetUnit) then return "" end
    local classColorR, classColorG, classColorB = ZF:GetUnitColor(targetUnit)
    local unitName = UnitName(targetUnit) or ""
    return string.format(" %s |cff%02x%02x%02x%s|r", arrowSeperator, classColorR * 255, classColorG * 255, classColorB * 255, unitName)
end

oUF.Tags.Methods["resetcolor"] = function(unit)
    return "|r"
end

oUF.Tags.Methods["reactioncolor"] = function(unit)
    local unitReaction = UnitReaction(unit, "player")
    local reactionColor = unitReaction and ZF.db.profile.General.Colors.Reaction[unitReaction]
    if reactionColor then
        local reactionColorR, reactionColorG, reactionColorB = unpack(reactionColor)
        return string.format("|cff%02x%02x%02x", reactionColorR * 255, reactionColorG * 255, reactionColorB * 255)
    end
    return "|cFFFFFFFF"
end

local function ShortenUnitName(unit, maxChars)
    if not unit or not UnitExists(unit) then return "" end
    local unitName = UnitName(unit) or ""
    if ZF:IsSecretValue(unitName) then return unitName end
    if maxChars and maxChars > 0 then
        unitName = string.format("%." .. maxChars .. "s", unitName)
    end
    return ZF:CleanTruncateUTF8String(unitName)
end

for i = 1, 25 do
    oUF.Tags.Methods["name:short:" .. i] = function(unit) return ShortenUnitName(unit, i) end
end

for i = 1, 25 do
    oUF.Tags.Methods["name:short:" .. i .. ":color"] = function(unit)
        local classColorR, classColorG, classColorB = ZF:GetUnitColor(unit)
        local shortenedName = ShortenUnitName(unit, i)
        return string.format("|cff%02x%02x%02x%s|r", classColorR * 255, classColorG * 255, classColorB * 255, shortenedName)
    end
end

for i = 1, 25 do
    oUF.Tags.Methods["name:target:short:" .. i] = function(unit)
        local targetUnit = unit and (unit .. "target")
        if not targetUnit or not UnitExists(targetUnit) then return "" end
        local shortenedName = ShortenUnitName(targetUnit, i)
        local arrowSeperator = ZF.TOT_SEPARATOR
        return string.format(" %s %s", arrowSeperator, shortenedName)
    end
end

for i = 1, 25 do
    oUF.Tags.Methods["name:target:short:" .. i .. ":color"] = function(unit)
        local targetUnit = unit and (unit .. "target")
        if not targetUnit or not UnitExists(targetUnit) then return "" end
        local classColorR, classColorG, classColorB = ZF:GetUnitColor(targetUnit)
        local shortenedName = ShortenUnitName(targetUnit, i)
        local arrowSeperator = ZF.TOT_SEPARATOR
        return string.format(" %s |cff%02x%02x%02x%s|r", arrowSeperator, classColorR * 255, classColorG * 255, classColorB * 255, shortenedName)
    end
end

for i = 1, 3 do
    local precision = i

    oUF.Tags.Methods["perhp" .. ":" .. precision] = function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitHealthPercent = UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)
        return string.format("%." .. precision .. "f", unitHealthPercent)
    end

    oUF.Tags.Methods["perhp-with-sign" .. ":" .. precision] = function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitHealthPercent = UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)
        return string.format("%." .. precision .. "f", unitHealthPercent)
    end

    oUF.Tags.Methods["curhpperhp" .. ":" .. precision] = function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitHealth = UnitHealth(unit)
        local unitHealthPercent = UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)
        if ZF.SEPARATOR == "[]" then
            return string.format("%s [%." .. precision .. "f%%]", unitHealth, unitHealthPercent)
        elseif ZF.SEPARATOR == "()" then
            return string.format("%s (%." .. precision .. "f%%)", unitHealth, unitHealthPercent)
        elseif ZF.SEPARATOR == " " then
            return string.format("%s %." .. precision .. "f%%", unitHealth, unitHealthPercent)
        else
            return string.format("%s %s %." .. precision .. "f%%", unitHealth, ZF.SEPARATOR, unitHealthPercent)
        end
    end

    oUF.Tags.Methods["curhpperhp:abbr" .. ":" .. precision] = function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitHealth = UnitHealth(unit)
        local unitHealthPercent = UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)
        if ZF.SEPARATOR == "[]" then
            return string.format("%s [%." .. precision .. "f%%]", AbbreviateValue(unitHealth), unitHealthPercent)
        elseif ZF.SEPARATOR == "()" then
            return string.format("%s (%." .. precision .. "f%%)", AbbreviateValue(unitHealth), unitHealthPercent)
        elseif ZF.SEPARATOR == " " then
            return string.format("%s %." .. precision .. "f%%", AbbreviateValue(unitHealth), unitHealthPercent)
        else
            return string.format("%s %s %." .. precision .. "f%%", AbbreviateValue(unitHealth), ZF.SEPARATOR, unitHealthPercent)
        end
    end

    oUF.Tags.Methods["perpp" .. ":" .. precision] = function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitPowerPercent = UnitPowerPercent(unit, nil, true, CurveConstants.ScaleTo100)
        return string.format("%." .. precision .. "f", unitPowerPercent)
    end

    oUF.Tags.Methods["curpp:manapercent" .. ":" .. precision] = function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitPower = UnitPower(unit)
        local unitPowerType = UnitPowerType(unit)
        if unitPowerType == Enum.PowerType.Mana and unitPower then
            local powerPercent = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
            return string.format("%." .. precision .. "f", powerPercent)
        else
            return string.format("%s", unitPower)
        end
    end

    oUF.Tags.Methods["curpp:manapercent:abbr" .. ":" .. precision] = function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitPower = UnitPower(unit)
        local unitPowerType = UnitPowerType(unit)
        if unitPowerType == Enum.PowerType.Mana and unitPower then
            local powerPercent = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
            return string.format("%." .. precision .. "f", powerPercent)
        else
            return string.format("%s", AbbreviateValue(unitPower))
        end
    end

    oUF.Tags.Methods["curpp:manapercent-with-sign" .. ":" .. precision] = function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitPower = UnitPower(unit)
        local unitPowerType = UnitPowerType(unit)
        if unitPowerType == Enum.PowerType.Mana and unitPower then
            local powerPercent = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
            return string.format("%." .. precision .. "f%%", powerPercent)
        else
            return string.format("%s", unitPower)
        end
    end

    oUF.Tags.Methods["curpp:manapercent-with-sign:abbr" .. ":" .. precision] = function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitPower = UnitPower(unit)
        local unitPowerType = UnitPowerType(unit)
        if unitPowerType == Enum.PowerType.Mana and unitPower then
            local powerPercent = UnitPowerPercent(unit, Enum.PowerType.Mana, true, CurveConstants.ScaleTo100)
            return string.format("%." .. precision .. "f%%", powerPercent)
        else
            return string.format("%s", AbbreviateValue(unitPower))
        end
    end
end
