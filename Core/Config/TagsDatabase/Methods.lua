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

local Methods = oUF.Tags.Methods
local MANA = Enum.PowerType.Mana

local function UnitStatusText(unit)
    return UnitIsDead(unit) and DEAD or UnitIsGhost(unit) and "Ghost" or not UnitIsConnected(unit) and "Offline"
end

local function UnitHealthPercentValue(unit)
    return UnitHealthPercent(unit, false, CurveConstants.ScaleTo100)
end

local function RawValue(value)
    return value
end

local function TruncateWhenZero(value)
    return C_StringUtil.TruncateWhenZero(value)
end

local function SeparatorFormats(percentFormat)
    local builtIn = {
        ["[]"] = "%s [" .. percentFormat .. "]",
        ["()"] = "%s (" .. percentFormat .. ")",
        [" "] = "%s " .. percentFormat,
    }
    return builtIn, "%s %s " .. percentFormat
end

local function FormatWithSeparator(builtIn, customFormat, value, percent)
    local separator = ZF.SEPARATOR
    local format = builtIn[separator]
    if format then return string.format(format, value, percent) end
    return string.format(customFormat, value, separator, percent)
end

local function ColorWrap(r, g, b, format, value)
    return string.format("|cff%02x%02x%02x" .. format .. "|r", r * 255, g * 255, b * 255, value)
end

local function HealthPercentTag(percentFormat, checkStatus)
    return function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitHealthPercent = UnitHealthPercentValue(unit)
        local unitStatus = checkStatus and UnitStatusText(unit)
        if unitStatus then return unitStatus end
        return string.format(percentFormat, unitHealthPercent)
    end
end

local function HealthAndPercentTag(percentFormat, valueFormatter, checkStatus)
    local builtInFormats, customFormat = SeparatorFormats(percentFormat)
    return function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitHealth = UnitHealth(unit)
        local unitHealthPercent = UnitHealthPercentValue(unit)
        local unitStatus = checkStatus and UnitStatusText(unit)
        if unitStatus then return unitStatus end
        return FormatWithSeparator(builtInFormats, customFormat, valueFormatter(unitHealth), unitHealthPercent)
    end
end

local function ManaPercentTag(percentFormat, valueFormatter)
    return function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitPower = UnitPower(unit)
        local unitPowerType = UnitPowerType(unit)
        if unitPowerType == MANA and unitPower then
            local powerPercent = UnitPowerPercent(unit, MANA, true, CurveConstants.ScaleTo100)
            return string.format(percentFormat, powerPercent)
        else
            return string.format("%s", valueFormatter(unitPower))
        end
    end
end

local function HealerManaTag(percentFormat)
    return function(unit)
        if not unit or not UnitExists(unit) then return "" end
        if UnitGroupRolesAssigned(unit) ~= "HEALER" then return "" end
        local unitPower = UnitPower(unit, MANA)
        if unitPower then
            local powerPercent = UnitPowerPercent(unit, MANA, true, CurveConstants.ScaleTo100)
            return string.format(percentFormat, powerPercent)
        end
    end
end

local function HealerManaColorTag(percentFormat)
    return function(unit)
        if not unit then return end
        if UnitGroupRolesAssigned(unit) ~= "HEALER" then return end
        local unitPower = UnitPower(unit, MANA)
        if unitPower then
            local powerPercent = UnitPowerPercent(unit, MANA, true, CurveConstants.ScaleTo100)
            local manaColor = ZF.db.profile.General.Colors.Power[0]
            if manaColor then
                local manaColorR, manaColorG, manaColorB = unpack(manaColor)
                return ColorWrap(manaColorR, manaColorG, manaColorB, percentFormat, powerPercent)
            end
        end
    end
end

local function ValueTag(getValue, valueFormatter, getColor)
    return function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local colorR, colorG, colorB
        if getColor then colorR, colorG, colorB = getColor(unit) end
        local value = getValue(unit)
        if value then
            if getColor then return ColorWrap(colorR, colorG, colorB, "%s", valueFormatter(value)) end
            return string.format("%s", valueFormatter(value))
        end
    end
end

local function UnitClassColor(unit)
    return ZF:GetUnitColor(unit)
end

local function AbsorbTag(valueFormatter)
    return function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local absorbAmount = UnitGetTotalAbsorbs(unit) or 0
        if absorbAmount then
            return string.format("%s", valueFormatter(absorbAmount))
        end
    end
end

Methods["perhp"] = HealthPercentTag("%.0f", true)
Methods["perhp-with-sign"] = HealthPercentTag("%.0f%%", true)

Methods["curhp:abbr"] = function(unit)
    if not unit or not UnitExists(unit) then return "" end
    local unitHealth = UnitHealth(unit)
    local unitStatus = UnitStatusText(unit)
    if unitStatus then return unitStatus end
    return string.format("%s", AbbreviateValue(unitHealth))
end

Methods["curhpperhp"] = HealthAndPercentTag("%.0f%%", RawValue, true)
Methods["curhpperhp:abbr"] = HealthAndPercentTag("%.0f%%", AbbreviateValue, true)

Methods["absorbs"] = AbsorbTag(RawValue)
Methods["absorbs:abbr"] = AbsorbTag(AbbreviateValue)
Methods["absorbs:truncate"] = AbsorbTag(TruncateWhenZero)

Methods["curpp:color"] = ValueTag(UnitPower, RawValue, FetchUnitPowerColor)
Methods["maxpp:color"] = ValueTag(UnitPowerMax, RawValue, FetchUnitPowerColor)
Methods["curpp:abbr"] = ValueTag(UnitPower, AbbreviateValue)
Methods["maxpp:abbr"] = ValueTag(UnitPowerMax, AbbreviateValue)
Methods["curpp:abbr:color"] = ValueTag(UnitPower, AbbreviateValue, FetchUnitPowerColor)
Methods["maxpp:abbr:color"] = ValueTag(UnitPowerMax, AbbreviateValue, FetchUnitPowerColor)
Methods["maxhp:abbr"] = ValueTag(UnitHealthMax, AbbreviateValue)
Methods["maxhp:abbr:color"] = ValueTag(UnitHealthMax, AbbreviateValue, UnitClassColor)

Methods["curpp:manapercent"] = ManaPercentTag("%.f", RawValue)
Methods["curpp:manapercent-with-sign"] = ManaPercentTag("%.f%%", RawValue)
Methods["curpp:manapercent:abbr"] = ManaPercentTag("%.f", AbbreviateValue)
Methods["curpp:manapercent-with-sign:abbr"] = ManaPercentTag("%.f%%", AbbreviateValue)

Methods["curpp:manapercent:healer"] = HealerManaTag("%.f")
Methods["curpp:manapercent-with-sign:healer"] = HealerManaTag("%.f%%")
Methods["curpp:manapercent:healer:color"] = HealerManaColorTag("%.f")
Methods["curpp:manapercent-with-sign:healer:color"] = HealerManaColorTag("%.f%%")

for precision = 1, 3 do
    local percentFormat = "%." .. precision .. "f"
    local suffix = ":" .. precision

    Methods["perhp" .. suffix] = HealthPercentTag(percentFormat, false)
    Methods["perhp-with-sign" .. suffix] = HealthPercentTag(percentFormat, false)
    Methods["curhpperhp" .. suffix] = HealthAndPercentTag(percentFormat .. "%%", RawValue, false)
    Methods["curhpperhp:abbr" .. suffix] = HealthAndPercentTag(percentFormat .. "%%", AbbreviateValue, false)

    Methods["perpp" .. suffix] = function(unit)
        if not unit or not UnitExists(unit) then return "" end
        local unitPowerPercent = UnitPowerPercent(unit, nil, true, CurveConstants.ScaleTo100)
        return string.format(percentFormat, unitPowerPercent)
    end

    Methods["curpp:manapercent" .. suffix] = ManaPercentTag(percentFormat, RawValue)
    Methods["curpp:manapercent:abbr" .. suffix] = ManaPercentTag(percentFormat, AbbreviateValue)
    Methods["curpp:manapercent-with-sign" .. suffix] = ManaPercentTag(percentFormat .. "%%", RawValue)
    Methods["curpp:manapercent-with-sign:abbr" .. suffix] = ManaPercentTag(percentFormat .. "%%", AbbreviateValue)
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

local function FirstCharacter(word)
    return word:match("^[%z\1-\127\194-\244][\128-\191]*") or ""
end

function ZF.AbbreviateFamily(family)
    local words = {}
    for word in family:gmatch("%S+") do words[#words + 1] = word end
    if #words > 1 then
        local result = ""
        for _, word in ipairs(words) do
            local first = FirstCharacter(word)
            local isConnector = word == word:lower()
            result = result .. (isConnector and first:lower() or first:upper())
        end
        return result
    end
    if #family > 4 then return family:sub(1, 4) end
    return family
end

if ZF.IS_FOREVER then
    oUF.Tags.Methods["pethappiness"] = function(unit)
        if unit ~= "pet" then return "" end
        local level = ZF.GetPetHappinessStats()
        return level and _G["PET_HAPPINESS" .. level] or ""
    end

    oUF.Tags.Methods["petloyaltylevel"] = function(unit)
        if unit ~= "pet" then return "" end
        return ZF.GetPetLoyaltyLevel() or ""
    end

    oUF.Tags.Methods["petdiet"] = function(unit)
        if unit ~= "pet" then return "" end
        return table.concat(ZF.GetPetFoodTypes(), ", ")
    end

    oUF.Tags.Methods["petcurxp"] = function(unit)
        if unit ~= "pet" then return "" end
        local current = ZF.GetPetExperienceValues()
        return current and tostring(current) or ""
    end

    oUF.Tags.Methods["petneedxp"] = function(unit)
        if unit ~= "pet" then return "" end
        local _, needed = ZF.GetPetExperienceValues()
        return needed and tostring(needed) or ""
    end

    oUF.Tags.Methods["petlvl"] = function(unit)
        if unit ~= "pet" or not UnitExists(unit) then return "" end
        local level = UnitLevel(unit)
        if type(level) ~= "number" or ZF:IsSecretValue(level) then return "" end
        return tostring(level)
    end

    oUF.Tags.Methods["petfam"] = function(unit)
        if unit ~= "pet" or not UnitExists(unit) then return "" end
        local family = UnitCreatureFamily(unit)
        if type(family) ~= "string" or ZF:IsSecretValue(family) then return "" end
        return family
    end

    oUF.Tags.Methods["petshortfam"] = function(unit)
        if unit ~= "pet" or not UnitExists(unit) then return "" end
        local family = UnitCreatureFamily(unit)
        if type(family) ~= "string" or ZF:IsSecretValue(family) then return "" end
        return ZF.AbbreviateFamily(family)
    end
end
