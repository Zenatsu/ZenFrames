local _, RUF = ...

local PreviewClasses ={
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER",
}

function RUF:ApplyUnitPreviewContent(unitFrame, unit)
    unitFrame.isUnitPreview = true
    RUF:UpdateUnitFrame(unitFrame, unit)
    
    for tagName in pairs(RUF:GetUnitDB(unitFrame, unit).Tags) do
        RUF:UpdateUnitTag(unitFrame, unit, tagName)
        local tagFontString = unitFrame.Tags[tagName]
        if tagFontString and tagFontString:GetText() == "Offline" then tagFontString:SetText("")
        end
    end

    if unitFrame.Health then
        unitFrame.Health:SetMinMaxValues(0,100)
        unitFrame.Health:SetValue(100)
        if RUF:GetNormalizedUnit(unit) == "boss" then
            unitFrame.Health:SetStatusBarColor(1, 0.8, 0)
        elseif RUF:GetUnitDB(unitFrame, unit).HealthBar.ColorByClass then
            local classColor = RAID_CLASS_COLORS[PreviewClasses[math.random(#PreviewClasses)]]
            if classColor then unitFrame.Health:SetStatusBarColor(classColor.r, classColor.g, classColor.b) end
        end
    end
    if unitFrame.Power then
        unitFrame.Power:SetMinMaxValues(0,100)
        unitFrame.Power:SetValue(100)
    end
end

function RUF:EnterPartyPreview()
    if InCombatLockdown() then return end
    if RUF.PARTY_CONTAINER then
        UnregisterStateDriver(RUF.PARTY_CONTAINER, "visibility")
        RUF.PARTY_CONTAINER:Show()
    end
    for i = 1, RUF.MAX_PARTY_FRAMES do
        local partyFrame = RUF["PARTY" .. i]
        if partyFrame then
            partyFrame:SetAttribute("unit", nil)
            UnregisterUnitWatch(partyFrame)
            partyFrame:Show()
            RUF:ApplyUnitPreviewContent(partyFrame, "party" .. i)
        end
    end
    if RUF.PARTYPLAYER then
        RUF.PARTYPLAYER:SetAttribute("unit", nil)
        UnregisterUnitWatch(RUF.PARTYPLAYER)
        RUF.PARTYPLAYER:Show()
        RUF:ApplyUnitPreviewContent(RUF.PARTYPLAYER, "partyplayer")
    end
end

function RUF:ExitPartyPreview()
    if InCombatLockdown() then return end
    for i = 1, RUF.MAX_PARTY_FRAMES do
        local partyFrame = RUF["PARTY" .. i]
        if partyFrame then
            partyFrame.isUnitPreview = nil
            partyFrame:SetAttribute("unit", "party" .. i)
            RegisterUnitWatch(partyFrame)
        end
    end
    if RUF.PARTYPLAYER then
        RUF.PARTYPLAYER.isUnitPreview = nil
        RUF.PARTYPLAYER:SetAttribute("unit", "player")
        RegisterUnitWatch(RUF.PARTYPLAYER)
    end
    if RUF.PARTY_CONTAINER then
        RegisterStateDriver(RUF.PARTY_CONTAINER, "visibility", "[group:party,nogroup:raid] show; hide")
    end
    RUF:UpdateGroupFrame("party")
end

function RUF:EnterBossPreview()
    if InCombatLockdown() then return end
    for i = 1, RUF.MAX_BOSS_FRAMES do
        local bossFrame = RUF["BOSS" .. i]
        if bossFrame then
            bossFrame:SetAttribute("unit", nil)
            UnregisterUnitWatch(bossFrame)
            bossFrame:Show()
            RUF:ApplyUnitPreviewContent(bossFrame,"boss" .. i)
        end
    end
end

function RUF:ExitBossPreview()
    if InCombatLockdown() then return end
    for i = 1, RUF.MAX_BOSS_FRAMES do
        local bossFrame = RUF["BOSS" .. i]
        if bossFrame then
            bossFrame.isUnitPreview = nil
            bossFrame:SetAttribute("unit", "boss" .. i)
            RegisterUnitWatch(bossFrame)
        end
    end
end

function RUF:SpawnRaidPreviewFrames()
    if #RUF.RAID_PREVIEW_FRAMES > 0 then return end
    local activeStyle = RUF.oUF:GetActiveStyle()
    RUF.oUF:SetActiveStyle(RUF:FetchFrameName("raid"))
    for i = 1, RUF.MAX_RAID_FRAMES do
        local raidFrame = RUF.oUF:Spawn("raid" .. i, "RUF_UnitPreviewRaid" .. i)
        raidFrame:SetParent(RUF.RAID_CONTAINER)
        RUF.RAID_PREVIEW_FRAMES[i] = raidFrame
    end
    if activeStyle then RUF.oUF:SetActiveStyle(activeStyle) end
end

function RUF:RaidLayoutPreviewFrame()
    local Frame = RUF.db.profile.Units.raid.Frame
    if not RUF.RAID_CONTAINER or #RUF.RAID_PREVIEW_FRAMES == 0 then return end

    local unitGrowth, groupGrowth = (Frame.GrowthDirection or "RIGHT_DOWN"):match("^(%a+)_(%a+)$") 
    unitGrowth = unitGrowth or "RIGHT"
    groupGrowth = groupGrowth or "DOWN"
    local spacing = Frame.Layout[5] or 0
    local headerWidth = (unitGrowth == "UP" or unitGrowth == "DOWN") and Frame.Width or (Frame.Width + spacing) * RUF.MAX_RAID_FRAMES_PER_GROUP - spacing
    local headerHeight = (unitGrowth == "UP" or unitGrowth == "DOWN") and (Frame.Height + spacing) * RUF.MAX_RAID_FRAMES_PER_GROUP - spacing or Frame.Height
    local horizontalAnchor = groupGrowth == "LEFT" and "RIGHT" or groupGrowth == "RIGHT" and "LEFT" or unitGrowth == "RIGHT" and "RIGHT" or "LEFT"
    local verticalAnchor = groupGrowth == "UP" and "BOTTOM" or groupGrowth == "DOWN" and "TOP" or unitGrowth == "DOWN" and "BOTTOM" or "TOP"
    local anchor = verticalAnchor .. horizontalAnchor

    local RaidGroupIndex = 0
    for groupIndex = 1, RUF.MAX_RAID_GROUPS do
        local showGroup = not Frame.Groups or Frame.Groups[groupIndex]
        if showGroup then RaidGroupIndex = RaidGroupIndex +1 end
        local horizontalOffset = (RaidGroupIndex - 1) * (headerWidth + spacing)
        local verticalOffset = (RaidGroupIndex - 1 ) * (headerHeight + spacing)
        local headerXOffset = groupGrowth == "RIGHT" and horizontalOffset or groupGrowth == "LEFT" and -horizontalOffset or 0
        local headerYOffset = groupGrowth == "UP" and verticalOffset or groupGrowth == "DOWN" and -verticalOffset or 0

        for unitIndex = 1, RUF.MAX_RAID_FRAMES_PER_GROUP do
            local raidIndex = ((groupIndex -1) * RUF.MAX_RAID_FRAMES_PER_GROUP) + unitIndex
            local raidFrame = RUF.RAID_PREVIEW_FRAMES[raidIndex]
            if raidFrame then
                raidFrame:ClearAllPoints()
                raidFrame:SetSize(Frame.Width, Frame.Height)
                if showGroup then
                    local unitOffset = (unitIndex - 1) * (Frame[(unitGrowth == "UP" or unitGrowth == "DOWN") and "Height" or "Width"] + spacing)
                    local xOffset = headerXOffset + (unitGrowth == "RIGHT" and -unitOffset or unitGrowth == "LEFT" and unitOffset or 0)
                    local yOffset = headerYOffset + (unitGrowth == "UP" and -unitOffset or unitGrowth == "DOWN" and unitOffset or 0)
                    raidFrame:SetPoint(anchor, RUF.RAID_CONTAINER, anchor, xOffset, yOffset)
                    raidFrame:Show()
                else
                    raidFrame:Hide()
                end
            end
        end
    end
end

function RUF:EnterRaidPreview()
    if InCombatLockdown() then return end
    if RUF.RAID_CONTAINER then
        UnregisterStateDriver(RUF.RAID_CONTAINER, "visibility")
        RUF.RAID_CONTAINER:Show()
    end
    RUF:SpawnRaidPreviewFrames()
    for i = 1, RUF.MAX_RAID_FRAMES do
        local raidFrame = RUF.RAID_PREVIEW_FRAMES[i]
        if raidFrame then
            raidFrame:SetAttribute("unit", nil)
            UnregisterUnitWatch(raidFrame)
            raidFrame:Show()
            RUF:ApplyUnitPreviewContent(raidFrame, "raid" .. i)
        end
    end
    RUF:RaidLayoutPreviewFrame()
end

function RUF:ExitRaidPreview()
    if InCombatLockdown() then return end
    for i = 1, RUF.MAX_RAID_FRAMES do
        local raidFrame = RUF.RAID_PREVIEW_FRAMES[i]
        if raidFrame then
            raidFrame.isUnitPreview = nil
            raidFrame:SetAttribute("unit", "raid" .. i)
            RegisterUnitWatch(raidFrame)
        end
    end
    if RUF.RAID_CONTAINER then
        RegisterStateDriver(RUF.RAID_CONTAINER, "visibility", "[group:raid,nogroup:party] show; hide")
    end
    RUF:UpdateGroupFrame("raid")
end