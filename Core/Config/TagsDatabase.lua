local _, ZF = ...
local oUF = ZF.oUF
oUF.Tags = oUF.Tags or {}

function ZFG:AddTag(tagString, tagEvents, tagMethod, tagType, tagDescription)
    -- tagString: The string used to call the tag, e.g., "curhp:abbr"
    -- tagEvents: A space-separated string of events that will trigger an update of the tag
    -- tagMethod: A function that takes a unit as an argument and returns the tag's value
    -- tagType: "Health", "Power", "Name", "Misc"
    -- tagDescription: A short description of what the tag does.
    -- tagType, tagDescription are used for the configuration UI. Please provide them. Prefix of your AddOn Name is also advised.
    -- EG: ZFG:AddTag("BCDM: Health", "UNIT_HEALTH UNIT_MAXHEALTH", function(unit) return UnitHealth(unit) or 0 end, "Health", "Show Health")

    if not tagString or not tagEvents or not tagMethod or not tagType or not tagDescription then return end

    oUF.Tags.Methods[tagString] = tagMethod
    oUF.Tags.Events[tagString] = (oUF.Tags.Events[tagString] and (oUF.Tags.Events[tagString] .. " ") or "") .. tagEvents

    local tagDatabase = ZF:FetchTagData(tagType)
    if not tagDatabase then return end

    tagDatabase[1][tagString] = tagDescription

    for _, existing in ipairs(tagDatabase[2]) do
        if existing == tagString then return end
    end

    table.insert(tagDatabase[2], tagString)
end

local Tags = {
    ["perhp"] = "UNIT_HEALTH UNIT_MAXHEALTH",
    ["perhp-with-sign"] = "UNIT_HEALTH UNIT_MAXHEALTH",
    ["curhp:abbr"] = "UNIT_HEALTH UNIT_MAXHEALTH",
    ["curhpperhp"] = "UNIT_HEALTH UNIT_MAXHEALTH",
    ["curhpperhp:abbr"] = "UNIT_HEALTH UNIT_MAXHEALTH",
    ["absorbs"] = "UNIT_ABSORB_AMOUNT_CHANGED",
    ["absorbs:abbr"] = "UNIT_ABSORB_AMOUNT_CHANGED",
    ["absorbs:truncate"] = "UNIT_ABSORB_AMOUNT_CHANGED",
    ["maxhp:abbr"] = "UNIT_HEALTH UNIT_MAXHEALTH",

    ["curpp:color"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["curpp:abbr"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["curpp:abbr:color"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
	["curpp:manapercent"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
	["curpp:manapercent:healer"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER PLAYER_ROLES_ASSIGNED GROUP_ROSTER_UPDATE",
	["curpp:manapercent-with-sign:healer"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER PLAYER_ROLES_ASSIGNED GROUP_ROSTER_UPDATE",
	["curpp:manapercent-with-sign:healer:color"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER PLAYER_ROLES_ASSIGNED GROUP_ROSTER_UPDATE",
	["curpp:manapercent:abbr"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["curpp:manapercent-with-sign"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["curpp:manapercent-with-sign:abbr"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",

    ["maxpp:abbr"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["maxpp:color"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",
    ["maxpp:abbr:color"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER",

    ["name"] = "UNIT_CONNECTION GROUP_ROSTER_UPDATE",
    ["name:color"] = "UNIT_CLASSIFICATION_CHANGED UNIT_CONNECTION UNIT_FACTION UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE",
    ["name:target"] = "UNIT_CONNECTION UNIT_NAME_UPDATE UNIT_TARGET GROUP_ROSTER_UPDATE",
    ["name:target:color"] = "UNIT_CONNECTION UNIT_NAME_UPDATE UNIT_TARGET GROUP_ROSTER_UPDATE",

    ["reactioncolor"] = "UNIT_FACTION UNIT_NAME_UPDATE",
}

for i = 1, 25 do
    Tags["name:short:" .. i] = "UNIT_CONNECTION UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE"
end

for i = 1, 25 do
    Tags["name:short:" .. i .. ":color"] = "UNIT_CONNECTION UNIT_NAME_UPDATE GROUP_ROSTER_UPDATE"
end

for i = 1, 25 do
    Tags["name:target:short:" .. i] = "UNIT_CONNECTION UNIT_NAME_UPDATE UNIT_TARGET GROUP_ROSTER_UPDATE"
end

for i = 1, 25 do
    Tags["name:target:short:" .. i .. ":color"] = "UNIT_CONNECTION UNIT_NAME_UPDATE UNIT_TARGET GROUP_ROSTER_UPDATE"
end

for i = 1, 3 do
    Tags["perhp" .. ":" .. i] = "UNIT_HEALTH UNIT_MAXHEALTH"
    Tags["perhp-with-sign" .. ":" .. i] = "UNIT_HEALTH UNIT_MAXHEALTH"
    Tags["curhpperhp" .. ":" .. i] = "UNIT_HEALTH UNIT_MAXHEALTH"
    Tags["curhpperhp:abbr" .. ":" .. i] = "UNIT_HEALTH UNIT_MAXHEALTH"
    Tags["perpp" .. ":" .. i] = "UNIT_POWER_UPDATE UNIT_MAXPOWER"
    Tags["curpp:manapercent" .. ":" .. i] = "UNIT_POWER_UPDATE UNIT_MAXPOWER"
    Tags["curpp:manapercent:abbr" .. ":" .. i] = "UNIT_POWER_UPDATE UNIT_MAXPOWER"
    Tags["curpp:manapercent-with-sign" .. ":" .. i] = "UNIT_POWER_UPDATE UNIT_MAXPOWER"
    Tags["curpp:manapercent-with-sign:abbr" .. ":" .. i] = "UNIT_POWER_UPDATE UNIT_MAXPOWER"
end

ZF.SEPARATOR_TAGS = {
{
    ["||"] = "|",
    ["-"] = "-",
    ["/"] = "/",
    [" "] = "Space",
    ["[]"] = "[]",
    ["()"] = "()",
    ["•"] = "•",
},
{
    "||",
    "-",
    "/",
    "[]",
    "()",
    "•",
    " ",
}
}

ZF.TOT_SEPARATOR_TAGS = {
    {
        ["»"] = "»",
        ["-"] = "-",
        [">"] = ">",
        [">>"] = ">>",
        ["•"] = "•",
    },
    {
        "»",
        "-",
        ">",
        ">>",
        "•",
    }
}

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

for tagString, tagEvents in pairs(Tags) do
    oUF.Tags.Events[tagString] = (oUF.Tags.Events[tagString] and (oUF.Tags.Events[tagString] .. " ") or "") .. tagEvents
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

for i = 1, 3 do
    local precision = i
    oUF.Tags.Methods["perhp-with-sign" .. ":" .. precision] = function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitHealthPercent = UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)
        return string.format("%." .. precision .. "f", unitHealthPercent)
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
    local unitMaxHealth = UnitHealthMax(unit)
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
    local unitMaxHealth = UnitHealthMax(unit)
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


local HealthTags = {
    {
        ["curhp"] = "Current Health",
        ["curhp:abbr"] = "Current Health with Abbreviation",
        ["perhp"] = "Percentage Health",
        ["curhpperhp"] = "Current Health and Percentage",
        ["curhpperhp:abbr"] = "Current Health and Percentage with Abbreviation",
        ["maxhp:abbr"] = "Maximum Health with Abbreviation",
        ["absorbs"] = "Total Absorbs",
        ["absorbs:abbr"] = "Total Absorbs with Abbreviation",
        ["absorbs:truncate"] = "Total Absorbs but will hide when at zero.",
        ["missinghp"] = "Missing Health",
        ["perhp:2"] = "Percentage Health with Decimal Precision (1 - 3)",
        ["curhpperhp:2"] = "Current Health and Percentage with Decimal Precision (1 - 3)",
        ["curhpperhp:abbr:2"] = "Current Health and Percentage with Abbreviation and Decimal Precision (1 - 3)",
    },
    {
        "curhp",
        "curhp:abbr",
        "perhp",
        "curhpperhp",
        "curhpperhp:abbr",
        "maxhp:abbr",
        "absorbs",
        "absorbs:abbr",
        "absorbs:truncate",
        "missinghp",
        "perhp:2",
        "curhpperhp:2",
        "curhpperhp:abbr:2",
    }

}

local PowerTags = {
    {
        ["perpp"] = "Percentage Power",
        ["curpp"] = "Current Power",
        ["curpp:color"] = "Current Power with Color",
        ["curpp:abbr"] = "Current Power with Abbreviation",
        ["curpp:abbr:color"] = "Current Power with Abbreviation and Color",
        ["maxpp"] = "Maximum Power",
        ["maxpp:abbr"] = "Maximum Power with Abbreviation",
        ["maxpp:color"] = "Maximum Power with Color",
        ["maxpp:abbr:color"] = "Maximum Power with Abbreviation and Color",
        ["missingpp"] = "Missing Power",
		["curpp:manapercent"] = "Current Power but Mana as Percentage",
		["curpp:manapercent:healer"] = "Mana Percentage for Healers",
		["curpp:manapercent-with-sign:healer"] = "Mana Percentage for Healers with % Sign",
		["curpp:manapercent-with-sign:healer:color"] = "Mana Percentage for Healers with % Sign and Mana Color",
		["curpp:manapercent:abbr"] = "Current Power but Mana as Percentage with Abbreviation",
        ["curpp:manapercent-with-sign"] = "Current Power but Mana as Percentage with % Sign",
        ["curpp:manapercent-with-sign:abbr"] = "Current Power but Mana as Percentage with % Sign and Abbreviation",
        ["perpp:2"] = "Percentage Power with Decimal Precision (1 - 3)",
        ["curpp:manapercent:2"] = "Current Power but Mana as Percentage with Decimal Precision (1 - 3)",
        ["curpp:manapercent:abbr:2"] = "Current Power but Mana as Percentage with Abbreviation and Decimal Precision (1 - 3)",
        ["curpp:manapercent-with-sign:2"] = "Current Power but Mana as Percentage with % Sign and Decimal Precision (1 - 3)",
        ["curpp:manapercent-with-sign:abbr:2"] = "Current Power but Mana as Percentage with % Sign, Abbreviation and Decimal Precision (1 - 3)",
    },
    {
        "perpp",
        "curpp",
        "curpp:color",
        "curpp:abbr",
        "curpp:abbr:color",
		"curpp:manapercent",
		"curpp:manapercent:healer",
		"curpp:manapercent:healer:color",
		"curpp:manapercent:abbr",
        "curpp:manapercent-with-sign",
        "curpp:manapercent-with-sign:abbr",
        "perpp:2",
        "curpp:manapercent:2",
        "curpp:manapercent:abbr:2",
        "curpp:manapercent-with-sign:2",
        "curpp:manapercent-with-sign:abbr:2",
        "maxpp",
        "maxpp:abbr",
        "maxpp:color",
        "maxpp:abbr:color",
        "missingpp",
    }
}

local NameTags = {
    {
        ["name"] = "Unit Name",
        ["name:color"] = "Unit Name with Color",
        ["name:short:10"] = "Unit Name Shortened (1 - 25 Chars)",
        ["name:short:10:color"] = "Unit Name Shortened (1 - 25 Chars) with Color",
        ["name:target"] = "Target Unit Name",
        ["name:target:color"] = "Target Unit Name with Color",
        ["name:target:short:10"] = "Target Unit Name Shortened (1 - 25 Chars)",
        ["name:target:short:10:color"] = "Target Unit Name Shortened (1 - 25 Chars) with Color",
    },
    {
        "name",
        "name:color",
        "name:short:10",
        "name:short:10:color",
        "name:target",
        "name:target:color",
        "name:target:short:10",
        "name:target:short:10:color",
    }
}

local MiscTags = {
    {
        ["classification"] = "Unit Classification",
        ["shortclassification"] = "Unit Classification with Abbreviation",
        ["creature"] = "Creature Type",
        ["group"] = "Group Number",
        ["level"] = "Unit Level",
        ["powercolor"] = "Unit Power Color - Prefix",
        ["raidcolor"] = "Unit Class Color - Prefix",
        ["reactioncolor"] = "Unit Reaction Color - Prefix",
        ["class"] = "Unit Class",
        ["resetcolor"] = "Resets Color Prefix",
    },
    {
        "classification",
        "shortclassification",
        "creature",
        "group",
        "level",
        "powercolor",
        "raidcolor",
        "reactioncolor",
        "class",
        "resetcolor",
    }
}

function ZF:FetchTagData(queriedDB)
    if queriedDB == "Health" then
        return HealthTags
    elseif queriedDB == "Power" then
        return PowerTags
    elseif queriedDB == "Name" then
        return NameTags
    elseif queriedDB == "Misc" then
        return MiscTags
    end
end

function ZFG:GetTags()
    return oUF.Tags
end
