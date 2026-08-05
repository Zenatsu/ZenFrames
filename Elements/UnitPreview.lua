local _, ZF = ...

local PreviewClasses ={
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK", "DRUID", "DEMONHUNTER", "EVOKER",
}

function ZF:ApplyUnitPreviewContent(unitFrame, unit)
    unitFrame.isUnitPreview = true
    ZF:UpdateUnitFrame(unitFrame, unit)
    
    for tagName in pairs(ZF:GetUnitDB(unitFrame, unit).Tags) do
        ZF:UpdateUnitTag(unitFrame, unit, tagName)
        local tagFontString = unitFrame.Tags[tagName]
        if tagFontString then
            local text = tagFontString:GetText()
            if not ZF:IsSecretValue(text) and text == "Offline" then tagFontString:SetText("") end
        end
    end

    if unitFrame.Health then
        unitFrame.Health:SetMinMaxValues(0,100)
        unitFrame.Health:SetValue(100)
        if ZF:GetNormalizedUnit(unit) == "boss" then
            unitFrame.Health:SetStatusBarColor(1, 0.8, 0)
        elseif ZF:GetUnitDB(unitFrame, unit).HealthBar.ColorByClass then
            unitFrame.previewClass = unitFrame.previewClass or PreviewClasses[math.random(#PreviewClasses)]
            local classColor = RAID_CLASS_COLORS[unitFrame.previewClass]
            if classColor then unitFrame.Health:SetStatusBarColor(classColor.r, classColor.g, classColor.b) end
        end
    end
    if unitFrame.Power then
        unitFrame.Power:SetMinMaxValues(0,100)
        unitFrame.Power:SetValue(100)
    end
end

function ZF:EnterPartyPreview()
    if InCombatLockdown() then return end
    if ZF.PARTY_CONTAINER then
        UnregisterStateDriver(ZF.PARTY_CONTAINER, "visibility")
        ZF.PARTY_CONTAINER:Show()
    end
    for i = 1, ZF.MAX_PARTY_FRAMES do
        local partyFrame = ZF["PARTY" .. i]
        if partyFrame and not UnitExists("party" .. i) then
            partyFrame:SetAttribute("unit", nil)
            UnregisterUnitWatch(partyFrame)
            partyFrame:Show()
            ZF:ApplyUnitPreviewContent(partyFrame, "party" .. i)
        end
    end
    if ZF.PARTYPLAYER and not UnitExists("player") then
        ZF.PARTYPLAYER:SetAttribute("unit", nil)
        UnregisterUnitWatch(ZF.PARTYPLAYER)
        ZF.PARTYPLAYER:Show()
        ZF:ApplyUnitPreviewContent(ZF.PARTYPLAYER, "partyplayer")
    end
end

function ZF:ExitPartyPreview()
    if InCombatLockdown() then return end
    for i = 1, ZF.MAX_PARTY_FRAMES do
        local partyFrame = ZF["PARTY" .. i]
        if partyFrame and partyFrame.isUnitPreview then
            partyFrame.isUnitPreview = nil
            partyFrame.previewClass = nil
            partyFrame:SetAttribute("unit", "party" .. i)
            RegisterUnitWatch(partyFrame)
        end
    end
    if ZF.PARTYPLAYER and ZF.PARTYPLAYER.isUnitPreview then
        ZF.PARTYPLAYER.isUnitPreview = nil
        ZF.PARTYPLAYER.previewClass = nil
        ZF.PARTYPLAYER:SetAttribute("unit", "player")
        RegisterUnitWatch(ZF.PARTYPLAYER)
    end
    if ZF.PARTY_CONTAINER then
        RegisterStateDriver(ZF.PARTY_CONTAINER, "visibility", "[group:party,nogroup:raid] show; hide")
    end
    ZF:UpdateGroupFrame("party")
end

function ZF:EnterBossPreview()
    if InCombatLockdown() then return end
    for i = 1, ZF.MAX_BOSS_FRAMES do
        local bossFrame = ZF["BOSS" .. i]
        if bossFrame and not UnitExists("boss" .. i) then
            bossFrame:SetAttribute("unit", nil)
            UnregisterUnitWatch(bossFrame)
            bossFrame:Show()
            ZF:ApplyUnitPreviewContent(bossFrame,"boss" .. i)
        end
    end
end

function ZF:ExitBossPreview()
    if InCombatLockdown() then return end
    for i = 1, ZF.MAX_BOSS_FRAMES do
        local bossFrame = ZF["BOSS" .. i]
        if bossFrame and bossFrame.isUnitPreview then
            bossFrame.isUnitPreview = nil
            bossFrame.previewClass = nil
            bossFrame:SetAttribute("unit", "boss" .. i)
            RegisterUnitWatch(bossFrame)
        end
    end
end

function ZF:EnterTargetPreview()
    if InCombatLockdown() then return end
    if ZF.TARGET and not UnitExists("target") then
        ZF.TARGET:SetAttribute("unit", nil)
        UnregisterUnitWatch(ZF.TARGET)
        ZF.TARGET:Show()
        ZF:ApplyUnitPreviewContent(ZF.TARGET, "target")
    end
end

function ZF:ExitTargetPreview()
    if InCombatLockdown() then return end
    if ZF.TARGET and ZF.TARGET.isUnitPreview then
        ZF.TARGET.isUnitPreview = nil
        ZF.TARGET.previewClass = nil
        ZF.TARGET:SetAttribute("unit", "target")
        RegisterUnitWatch(ZF.TARGET)
    end
end

function ZF:SpawnRaidPreviewFrames()
    if #ZF.RAID_PREVIEW_FRAMES > 0 then return end
    ZF:EnsureRaidStyleRegistered()
    local activeStyle = ZF.oUF:GetActiveStyle()
    ZF.oUF:SetActiveStyle(ZF:FetchFrameName("raid"))
    for i = 1, ZF.MAX_RAID_FRAMES do
        local raidFrame = ZF.oUF:Spawn("raid" .. i, "ZF_UnitPreviewRaid" .. i)
        raidFrame:SetParent(ZF.RAID_CONTAINER)
        ZF.RAID_PREVIEW_FRAMES[i] = raidFrame
    end
    if activeStyle then ZF.oUF:SetActiveStyle(activeStyle) end
end

function ZF:RaidLayoutPreviewFrame()
    local Frame = ZF.db.profile.Units.raid.Frame
    if not ZF.RAID_CONTAINER or #ZF.RAID_PREVIEW_FRAMES == 0 then return end

    local unitGrowth, groupGrowth = (Frame.GrowthDirection or "RIGHT_DOWN"):match("^(%a+)_(%a+)$") 
    unitGrowth = unitGrowth or "RIGHT"
    groupGrowth = groupGrowth or "DOWN"
    local spacing = Frame.Layout[5] or 0
    local headerWidth = (unitGrowth == "UP" or unitGrowth == "DOWN") and Frame.Width or (Frame.Width + spacing) * ZF.MAX_RAID_FRAMES_PER_GROUP - spacing
    local headerHeight = (unitGrowth == "UP" or unitGrowth == "DOWN") and (Frame.Height + spacing) * ZF.MAX_RAID_FRAMES_PER_GROUP - spacing or Frame.Height
    local horizontalAnchor = groupGrowth == "LEFT" and "RIGHT" or groupGrowth == "RIGHT" and "LEFT" or unitGrowth == "RIGHT" and "RIGHT" or "LEFT"
    local verticalAnchor = groupGrowth == "UP" and "BOTTOM" or groupGrowth == "DOWN" and "TOP" or unitGrowth == "DOWN" and "BOTTOM" or "TOP"
    local anchor = verticalAnchor .. horizontalAnchor

    local RaidGroupIndex = 0
    for groupIndex = 1, ZF.MAX_RAID_GROUPS do
        local showGroup = ZF:IsRaidGroupShown(Frame, groupIndex)
        if showGroup then RaidGroupIndex = RaidGroupIndex +1 end
        local horizontalOffset = (RaidGroupIndex - 1) * (headerWidth + spacing)
        local verticalOffset = (RaidGroupIndex - 1 ) * (headerHeight + spacing)
        local headerXOffset = groupGrowth == "RIGHT" and horizontalOffset or groupGrowth == "LEFT" and -horizontalOffset or 0
        local headerYOffset = groupGrowth == "UP" and verticalOffset or groupGrowth == "DOWN" and -verticalOffset or 0

        for unitIndex = 1, ZF.MAX_RAID_FRAMES_PER_GROUP do
            local raidIndex = ((groupIndex -1) * ZF.MAX_RAID_FRAMES_PER_GROUP) + unitIndex
            local raidFrame = ZF.RAID_PREVIEW_FRAMES[raidIndex]
            if raidFrame then
                raidFrame:ClearAllPoints()
                raidFrame:SetSize(Frame.Width, Frame.Height)
                if showGroup then
                    local unitOffset = (unitIndex - 1) * (Frame[(unitGrowth == "UP" or unitGrowth == "DOWN") and "Height" or "Width"] + spacing)
                    local xOffset = headerXOffset + (unitGrowth == "RIGHT" and -unitOffset or unitGrowth == "LEFT" and unitOffset or 0)
                    local yOffset = headerYOffset + (unitGrowth == "UP" and -unitOffset or unitGrowth == "DOWN" and unitOffset or 0)
                    raidFrame:SetPoint(anchor, ZF.RAID_CONTAINER, anchor, xOffset, yOffset)
                    raidFrame:Show()
                else
                    raidFrame:Hide()
                end
            end
        end
    end
end

function ZF:EnterRaidPreview()
    if InCombatLockdown() then return end
    if ZF.RAID_CONTAINER then
        UnregisterStateDriver(ZF.RAID_CONTAINER, "visibility")
        ZF.RAID_CONTAINER:Show()
    end
    ZF:SpawnRaidPreviewFrames()
    for i = 1, ZF.MAX_RAID_FRAMES do
        local raidFrame = ZF.RAID_PREVIEW_FRAMES[i]
        if raidFrame then
            raidFrame:SetAttribute("unit", nil)
            UnregisterUnitWatch(raidFrame)
            raidFrame:Show()
            ZF:ApplyUnitPreviewContent(raidFrame, "raid" .. i)
        end
    end
    ZF:RaidLayoutPreviewFrame()
end

function ZF:ExitRaidPreview()
    if InCombatLockdown() then return end
    for i = 1, ZF.MAX_RAID_FRAMES do
        local raidFrame = ZF.RAID_PREVIEW_FRAMES[i]
        if raidFrame then
            raidFrame.isUnitPreview = nil
            raidFrame.previewClass = nil
            raidFrame:SetAttribute("unit", "raid" .. i)
            RegisterUnitWatch(raidFrame)
        end
    end
    if ZF.RAID_CONTAINER then
        RegisterStateDriver(ZF.RAID_CONTAINER, "visibility", "[group:raid,nogroup:party] show; hide")
    end
    ZF:UpdateGroupFrame("raid")
end