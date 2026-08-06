local _, ZF = ...

local function RenameKey(tbl, oldKey, newKey)
    if tbl[oldKey] == nil then return end
    tbl[newKey] = tbl[oldKey]
    tbl[oldKey] = nil
end

local function RewriteAnchorPrefix(value)
    if type(value) ~= "string" then return value end
    local suffix = value:match("^UUF_(.+)$") or value:match("^RUF_(.+)$")
    if suffix == "Target" or suffix == "Player" or suffix == "Focus" then
        return "ZF_" .. suffix
    end
    return value
end

local MigrationSteps = {
    {
        fromVersion = 0,
        migrate = function(_profile) end,
    },
    {
        fromVersion = 1,
        migrate = function(profile)
            local units = profile.Units
            if type(units) ~= "table" then return end

            if type(units.raid) == "table" and units.raid.augmentation ~= nil then
                units.augmentation = units.raid.augmentation
                units.raid.augmentation = nil
            end

            for _, unitDB in pairs(units) do
                local indicators = unitDB.Indicators
                if type(indicators) == "table" then
                    RenameKey(indicators, "LeaderAssistantIndicator", "LeaderAssistant")
                    RenameKey(indicators, "ReadyCheckIndicator", "ReadyCheck")
                    RenameKey(indicators, "ResurrectIndicator", "Resurrect")
                end

                if type(unitDB.Frame) == "table" then
                    RenameKey(unitDB.Frame, "AnchorParent", "AnchorToFrame")
                end

                local auras = unitDB.Auras
                if type(auras) == "table" then
                    for _, key in ipairs({"Buffs", "Debuffs", "Custom", "PrivateAuras"}) do
                        if type(auras[key]) == "table" then
                            RenameKey(auras[key], "AnchorParent", "AnchorRegion")
                        end
                    end
                end
            end
        end,
    },
    {
        fromVersion = 2,
        migrate = function(profile)
            local units = profile.Units
            if type(units) ~= "table" then return end

            for _, unitDB in pairs(units) do
                if type(unitDB.HealthBar) == "table" then
                    unitDB.HealthBar.AnchorToCooldownViewer = nil
                end
            end
        end,
    },
    {
        fromVersion = 3,
        migrate = function(profile)
            local units = profile.Units
            if type(units) ~= "table" then return end

            for _, unitDB in pairs(units) do
                if type(unitDB.Frame) == "table" then
                    unitDB.Frame.AnchorToFrame = RewriteAnchorPrefix(unitDB.Frame.AnchorToFrame)
                end
            end
        end,
    },
}

local CURRENT_DB_VERSION = #MigrationSteps

local function RestoreSnapshot(profile, snapshot)
    for key in pairs(profile) do
        profile[key] = nil
    end
    for key, value in pairs(snapshot) do
        profile[key] = value
    end
end

function ZF:MigrateProfile(profileName, profile)
    if type(profile) ~= "table" then return end

    local version = profile.DBVersion or 0
    while version < CURRENT_DB_VERSION do
        local step = MigrationSteps[version + 1]
        if not step then break end

        local snapshot = CopyTable(profile)
        local ok, err = pcall(step.migrate, profile)
        if not ok then
            RestoreSnapshot(profile, snapshot)
            print(string.format(
                "|cffff4040ZenFrames:|r migration step %d failed for profile '%s' (%s) - will retry next login.",
                version + 1, tostring(profileName), tostring(err)
            ))
            break
        end

        version = version + 1
        profile.DBVersion = version
    end
end

function ZF:MigrateAllProfiles(rawDB)
    if type(rawDB) ~= "table" or type(rawDB.profiles) ~= "table" then return end
    for profileName, profile in pairs(rawDB.profiles) do
        ZF:MigrateProfile(profileName, profile)
    end
end

function ZF:MigrateGlobalSettings(rawDB)
    if type(rawDB) ~= "table" or type(rawDB.global) ~= "table" then return end
    local global = rawDB.global
    if global.GlobalProfileName == nil then return end

    if not global.GlobalProfile or global.GlobalProfile == "" or global.GlobalProfile == "Default" then
        global.GlobalProfile = global.GlobalProfileName
    end
    global.GlobalProfileName = nil
end
