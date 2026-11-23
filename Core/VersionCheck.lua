local _, ZF = ...

local PREFIX = "ZenFrames"
local LOGIN_DELAY = 15
local G_JOIN_DELAY = 3
local REPLY_COOLDOWN = 60

local myVersion
local notified = false
local wasInGroup = false
local lastReply = {}

local function ParseVersion(text)
    if type(text) ~= "string" then return end
    local major, minor, patch, rest = text:match("^[vV]?(%d+)%.(%d+)%.(%d+)(.*)$")
    if not major then return end
    local hotfix = 0
    if rest ~= "" then
        hotfix = tonumber(rest:match("^hf(%d+)$"))
        if not hotfix then return end
    end
    return { tonumber(major), tonumber(minor), tonumber(patch), hotfix }
end

local function IsNewer(a,b)
    for i = 1, 4 do
        if a[i] ~= b[i] then return a[i] > b[i] end
    end
    return false
end

local function GetGroupChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
end

local function Send(channel)
    if not channel or not myVersion then return end
    if C_ChatInfo.InChatMessagingLockdown() then return end
    C_ChatInfo.SendAddonMessage(PREFIX, ZF.ADDON_VERSION, channel)
end

local function Broadcast()
    if IsInGuild() then Send("GUILD") end
    Send(GetGroupChannel())
end

function ZF:OnVersionMessage(text, channel)
    if not myVersion or not ZF.db.global.VersionCheck then return end
    local theirs = ParseVersion(text)
    if not theirs or theirs[1] > myVersion[1]+1 then return end

    if IsNewer(theirs, myVersion) then
        if notified then return end
        notified = true
        ZF:StylizedPrint(string.format("A newer version (|cFF00FF00%s|r) is available.", text))
    elseif IsNewer(myVersion, theirs) then
        local now = GetTime()
        if now - (lastReply[channel] or 0) < REPLY_COOLDOWN then return end
        lastReply[channel] = now
        Send(channel)
    end
end

local function OnGroupRosterUpdate()
    local inGroup = IsInGroup()
    if inGroup and not wasInGroup then
        C_Timer.After(G_JOIN_DELAY, function() Send(GetGroupChannel()) end)
    end
    wasInGroup = inGroup
end

function ZF:InitVersionCheck()
    myVersion = ParseVersion(ZF.ADDON_VERSION)
    if not myVersion then return end

    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "CHAT_MSG_ADDON" then
            local prefix, text, channel = ...
            if prefix == PREFIX then ZF:OnVersionMessage(text, channel) end
        else
            OnGroupRosterUpdate()
        end
    end)

    wasInGroup = IsInGroup()
    if ZF.db.global.VersionCheck then C_Timer.After(LOGIN_DELAY, Broadcast) end
end
