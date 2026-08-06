local _, ZF = ...
local Serialize = LibStub:GetLibrary("AceSerializer-3.0")
local Compress = LibStub:GetLibrary("LibDeflate")
local ZF_IMPORT_PREFIX = "!ZF_"
local UUF_IMPORT_PREFIX = "!UUF_"

local function MergeInto(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key]={}
            end
            MergeInto(target[key], value)
        else
            target[key]=value
        end
    end
end

local function SerializeLuaValue(value, indentation, serializedTables)
    local valueType = type(value)
    if valueType == "string" then return string.format("%q", value) end
    if valueType == "number" or valueType == "boolean" then return tostring(value) end
    if valueType ~= "table" then return "nil" end
    if serializedTables[value] then return "nil" end

    serializedTables[value] = true
    local keys = {}
    local arrayLength = 0
    local isArray = true
    local hasNestedTables = false
    for key, tableValue in pairs(value) do
        keys[#keys + 1] = key
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            isArray = false
        elseif key > arrayLength then
            arrayLength = key
        end
        if type(tableValue) == "table" then hasNestedTables = true end
    end

    if #keys == 0 then
        serializedTables[value] = nil
        return "{}"
    end
    if isArray and arrayLength ~= #keys then isArray = false end

    if isArray and not hasNestedTables then
        local values = {}
        for index = 1, arrayLength do values[index] = SerializeLuaValue(value[index], indentation + 1, serializedTables) end
        serializedTables[value] = nil
        return "{" .. table.concat(values, ", ") .. "}"
    end

    table.sort(keys, function(firstKey, secondKey)
        local firstType = type(firstKey)
        local secondType = type(secondKey)
        if firstType == secondType then return firstKey < secondKey end
        if firstType == "number" then return true end
        if secondType == "number" then return false end
        return tostring(firstKey) < tostring(secondKey)
    end)

    local lines = {"{"}
    local indentationText = string.rep("    ", indentation + 1)
    for _, key in ipairs(keys) do
        local keyText = ""
        if not isArray then
            keyText = type(key) == "string" and key:match("^[%a_][%w_]*$") and key .. " = " or "[" .. SerializeLuaValue(key, indentation + 1, serializedTables) .. "] = "
        end
        lines[#lines + 1] = indentationText .. keyText .. SerializeLuaValue(value[key], indentation + 1, serializedTables) .. ","
    end
    lines[#lines + 1] = string.rep("    ", indentation) .. "}"
    serializedTables[value] = nil
    return table.concat(lines, "\n")
end

local function BuildEncodedProfile(profileData)
    local serializedInfo = Serialize:Serialize(profileData)
    local compressedInfo = Compress:CompressDeflate(serializedInfo)
    local encodedInfo = Compress:EncodeForPrint(compressedInfo)
    return ZF_IMPORT_PREFIX .. encodedInfo
end

local function ParseEncodedProfile(encodedInfo)
    if type(encodedInfo) ~= "string" then
        return nil
    end

    local prefix = (encodedInfo:sub(1, #ZF_IMPORT_PREFIX) == ZF_IMPORT_PREFIX) and ZF_IMPORT_PREFIX 
        or (encodedInfo:sub(1, #UUF_IMPORT_PREFIX) == UUF_IMPORT_PREFIX) and UUF_IMPORT_PREFIX
        or nil
        
    if not prefix then
        return nil
    end

    local decodedInfo = Compress:DecodeForPrint(encodedInfo:sub(#prefix + 1))
    if not decodedInfo then
        return nil
    end

    local decompressedInfo = Compress:DecompressDeflate(decodedInfo)
    if not decompressedInfo then
        return nil
    end

    local success, data = Serialize:Deserialize(decompressedInfo)
    if not success or type(data) ~= "table" then
        return nil
    end

    return data
end

local function ApplyImportedProfileToCurrent(profile)
    if type(profile) ~= "table" then
        return
    end

    MergeInto(ZF.db.profile, profile)
    ZF:MigrateProfile("current", ZF.db.profile)

    ZFG.RefreshProfiles()
    ZF:UpdateAllUnitFrames()
end

function ZF:ExportSavedVariables()
    local profileData = { profile = ZF.db.profile, }
    return BuildEncodedProfile(profileData)
end

function ZF:ExportDefaultsTable()
    return "local Defaults = " .. SerializeLuaValue({
        global = ZF.db.global,
        profile = ZF.db.profile,
    }, 0, {})
end

function ZF:ImportSavedVariables(encodedInfo, profileName)
    local data = ParseEncodedProfile(encodedInfo)
    if not data then
        ZF:PrettyPrint("Invalid Import String.")
        return
    end

    if profileName then
        ZF.db:SetProfile(profileName)
        ApplyImportedProfileToCurrent(data.profile)
    else
        StaticPopupDialogs["ZF_IMPORT_NEW_PROFILE"] = {
            text = ZF.ADDON_NAME.." - ".."Profile Name?",
            button1 = "Import",
            button2 = "Cancel",
            hasEditBox = true,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            OnAccept = function(self)
                local editBox = self.EditBox
                local newProfileName = editBox:GetText() or string.format("Imported_%s-%s-%s", date("%d"), date("%m"), date("%Y"))
                if not newProfileName or newProfileName == "" then
                    ZF:PrettyPrint("Please enter a valid profile name.")
                    return
                end

                ZF.db:SetProfile(newProfileName)
                ApplyImportedProfileToCurrent(data.profile)
            end,
        }
        StaticPopup_Show("ZF_IMPORT_NEW_PROFILE")
    end
    local popup = StaticPopup_Show("ZF_IMPORT_NEW_PROFILE")
    if popup then popup:SetFrameStrata("TOOLTIP") end

end

function ZFG:ExportZF(profileKey)
    local profile = ZF.db.profiles[profileKey]
    if not profile then return nil end

    local profileData = { profile = profile, }
    return BuildEncodedProfile(profileData)
end

function ZFG:ImportZF(importString, profileKey)
    local profileData = ParseEncodedProfile(importString)
    if not profileData then
        ZF:PrettyPrint("Invalid Import String.")
        return
    end

    if type(profileData.profile) == "table" then
        ZF.db.profiles[profileKey] = profileData.profile
        ZF:MigrateProfile(profileKey, ZF.db.profiles[profileKey])
        ZF.db:SetProfile(profileKey)
    end
end
