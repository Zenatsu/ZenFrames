local _, ZF = ...
local oUF = ZF.oUF
oUF.Tags = oUF.Tags or {}

function ZFG:AddTag(tagString, tagEvents, tagMethod, tagType, tagDescription)

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

for tagString, tagEvents in pairs(Tags) do
    oUF.Tags.Events[tagString] = (oUF.Tags.Events[tagString] and (oUF.Tags.Events[tagString] .. " ") or "") .. tagEvents
end
