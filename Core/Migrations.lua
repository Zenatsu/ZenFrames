local _, ZF = ...

local function RenameKey(tbl, oldKey, newKey)
    if tbl[oldKey] == nil then return end
    tbl[newKey] = tbl[oldKey]
    tbl[oldKey] = nil
end

-- Ordered migration steps for ZFDB profiles. Each step migrates a profile
-- from exactly `fromVersion` to `fromVersion + 1`. Add new steps here
-- (append only) whenever a Defaults.lua key gets renamed or restructured -
-- never edit or reorder a step once it has shipped, since a stale profile
-- sitting below that version may still need to run it exactly as written.
--
-- profile.DBVersion must NEVER be added to Core/Defaults.lua's default
-- table - AceDB's copyDefaults only backfills keys that are nil, so a
-- default value there would make every profile look "already current"
-- before this code ever gets a chance to run.
local MigrationSteps = {
    -- Placeholder no-op step: proves the pipeline (snapshot/pcall/version
    -- bump) end-to-end before any real Defaults.lua rename exists yet.
    -- Safe to leave in place once real steps are appended after it - it
    -- only ever runs once per profile, the first time that profile is seen
    -- post-upgrade.
    {
        fromVersion = 0,
        migrate = function(_profile) end,
    },
    -- Breakaway rewrite renames (Phase 3): augmentation promoted out of
    -- raid to a top-level unit, the LeaderAssistant/ReadyCheck/Resurrect
    -- indicator keys dropped their redundant "Indicator" suffix, and
    -- AnchorParent's two unrelated meanings split into AnchorToFrame
    -- (Frame - a real global frame name to anchor to) and AnchorRegion
    -- (Auras.* - "Frame" or "Health", which region of this same unit to
    -- anchor to).
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

local function MigrateProfile(profileName, profile)
    if type(profile) ~= "table" then return end

    local version = profile.DBVersion or 0
    while version < CURRENT_DB_VERSION do
        local step = MigrationSteps[version + 1]
        if not step then break end

        local snapshot = CopyTable(profile)
        local ok, err = pcall(step.migrate, profile)
        if not ok then
            -- Leave DBVersion untouched so this step is retried next login
            -- instead of being marked done, and roll back whatever partial
            -- changes it made before failing.
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

-- Runs over every stored profile (not just the active one) directly on the
-- raw SavedVariables table, before AceDB:New() ever touches it - an
-- unselected profile can still resurface later via /reload or a character
-- switch, so it needs to already be migrated by then.
function ZF:MigrateAllProfiles(rawDB)
    if type(rawDB) ~= "table" or type(rawDB.profiles) ~= "table" then return end
    for profileName, profile in pairs(rawDB.profiles) do
        MigrateProfile(profileName, profile)
    end
end

-- global.GlobalProfileName was a redundant duplicate of global.GlobalProfile
-- (Core.lua used to fall back from one to the other). Not a per-profile
-- concept, so it isn't versioned like MigrationSteps above - it's naturally
-- idempotent instead: once GlobalProfileName is cleared, later logins find
-- nothing left to migrate.
function ZF:MigrateGlobalSettings(rawDB)
    if type(rawDB) ~= "table" or type(rawDB.global) ~= "table" then return end
    local global = rawDB.global
    if global.GlobalProfileName == nil then return end

    if not global.GlobalProfile or global.GlobalProfile == "" or global.GlobalProfile == "Default" then
        global.GlobalProfile = global.GlobalProfileName
    end
    global.GlobalProfileName = nil
end
