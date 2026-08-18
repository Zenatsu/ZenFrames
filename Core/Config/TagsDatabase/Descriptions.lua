local _, ZF = ...
local oUF = ZF.oUF

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
