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

local function EnterFramePreview(unitFrame, frameUnit)
    if UnitExists(frameUnit == "partyplayer" and "player" or frameUnit) then return end
    unitFrame:SetAttribute("unit", nil)
    UnregisterUnitWatch(unitFrame)
    unitFrame:Show()
    ZF:ApplyUnitPreviewContent(unitFrame, frameUnit)
end

local function ExitFramePreview(unitFrame, frameUnit)
    if not unitFrame.isUnitPreview then return end
    unitFrame.isUnitPreview = nil
    unitFrame.previewClass = nil
    unitFrame:SetAttribute("unit", frameUnit == "partyplayer" and "player" or frameUnit)
    RegisterUnitWatch(unitFrame)
end

local SIMPLE_PREVIEW_UNITS = {
    target = "Target",
    focus = "Focus",
    focustarget = "FocusTarget",
    pet = "Pet",
    targettarget = "TargetTarget",
    boss = "Boss",
}

for unit, name in pairs(SIMPLE_PREVIEW_UNITS) do
    ZF["Enter" .. name .. "Preview"] = function()
        if InCombatLockdown() then return end
        ZF:ForEachFrameOfUnit(unit, EnterFramePreview)
    end
    ZF["Exit" .. name .. "Preview"] = function()
        if InCombatLockdown() then return end
        ZF:ForEachFrameOfUnit(unit, ExitFramePreview)
    end
end

function ZF:EnterPartyPreview()
    if InCombatLockdown() then return end
    if ZF.PARTY_CONTAINER then
        UnregisterStateDriver(ZF.PARTY_CONTAINER, "visibility")
        ZF.PARTY_CONTAINER:Show()
    end
    ZF:ForEachFrameOfUnit("party", EnterFramePreview)
end

function ZF:ExitPartyPreview()
    if InCombatLockdown() then return end
    ZF:ForEachFrameOfUnit("party", ExitFramePreview)
    if ZF.PARTY_CONTAINER then
        RegisterStateDriver(ZF.PARTY_CONTAINER, "visibility", "[group:party,nogroup:raid] show; hide")
    end
    ZF:UpdateGroupFrame("party")
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

function ZF:SpawnAuxiliaryPreviewFrames(groupKey)
    local entry = ZF.AUXILIARY_RAID_GROUPS[groupKey]
    local previewFrames = ZF.AUXILIARY_PREVIEW_FRAMES[groupKey]
    if #previewFrames > 0 then return end
    local container = ZF.AUXILIARY_RAID_CONTAINERS[groupKey]
    if not container then return end
    ZF:EnsureRaidStyleRegistered()
    local activeStyle = ZF.oUF:GetActiveStyle()
    ZF.oUF:SetActiveStyle(ZF:FetchFrameName("raid"))
    local prettyKey = groupKey:gsub("^%l", string.upper)
    for i = 1, entry.maxUnits do
        local previewFrame = ZF.oUF:Spawn("raid" .. i, "ZF_UnitPreview" .. prettyKey .. i)
        previewFrame:SetParent(container)
        previewFrames[i] = previewFrame
    end
    if activeStyle then ZF.oUF:SetActiveStyle(activeStyle) end
end

function ZF:LayoutAuxiliaryPreviewFrame(groupKey)
    local Frame = ZF.db.profile.Units[groupKey].Frame
    local container = ZF.AUXILIARY_RAID_CONTAINERS[groupKey]
    local previewFrames = ZF.AUXILIARY_PREVIEW_FRAMES[groupKey]
    if not container or #previewFrames == 0 then return end

    local unitGrowth, groupGrowth = (Frame.GrowthDirection or "RIGHT_DOWN"):match("^(%a+)_(%a+)$")
    unitGrowth = unitGrowth or "RIGHT"
    groupGrowth = groupGrowth or "DOWN"
    local spacing = Frame.Layout[5] or 0
    local unitsPerColumn = Frame.UnitsPerColumn or ZF.MAX_RAID_FRAMES_PER_GROUP
    local columnWidth = (unitGrowth == "UP" or unitGrowth == "DOWN") and Frame.Width or (Frame.Width + spacing) * unitsPerColumn - spacing
    local columnHeight = (unitGrowth == "UP" or unitGrowth == "DOWN") and (Frame.Height + spacing) * unitsPerColumn - spacing or Frame.Height
    local horizontalAnchor = groupGrowth == "LEFT" and "RIGHT" or groupGrowth == "RIGHT" and "LEFT" or unitGrowth == "RIGHT" and "RIGHT" or "LEFT"
    local verticalAnchor = groupGrowth == "UP" and "BOTTOM" or groupGrowth == "DOWN" and "TOP" or unitGrowth == "DOWN" and "BOTTOM" or "TOP"
    local anchor = verticalAnchor .. horizontalAnchor

    for slotIndex, previewFrame in ipairs(previewFrames) do
        local columnIndex = math.floor((slotIndex - 1) / unitsPerColumn)
        local rowIndex = (slotIndex - 1) % unitsPerColumn
        local horizontalOffset = columnIndex * (columnWidth + spacing)
        local verticalOffset = columnIndex * (columnHeight + spacing)
        local columnXOffset = groupGrowth == "RIGHT" and horizontalOffset or groupGrowth == "LEFT" and -horizontalOffset or 0
        local columnYOffset = groupGrowth == "UP" and verticalOffset or groupGrowth == "DOWN" and -verticalOffset or 0
        local unitOffset = rowIndex * (Frame[(unitGrowth == "UP" or unitGrowth == "DOWN") and "Height" or "Width"] + spacing)
        local xOffset = columnXOffset + (unitGrowth == "RIGHT" and -unitOffset or unitGrowth == "LEFT" and unitOffset or 0)
        local yOffset = columnYOffset + (unitGrowth == "UP" and -unitOffset or unitGrowth == "DOWN" and unitOffset or 0)
        previewFrame:ClearAllPoints()
        previewFrame:SetSize(Frame.Width, Frame.Height)
        previewFrame:SetPoint(anchor, container, anchor, xOffset, yOffset)
        previewFrame:Show()
    end
end

function ZF:EnterAuxiliaryPreview(groupKey)
    if InCombatLockdown() then return end
    local container = ZF.AUXILIARY_RAID_CONTAINERS[groupKey]
    if not container then return end
    container:Show()
    ZF:SpawnAuxiliaryPreviewFrames(groupKey)
    for i, previewFrame in ipairs(ZF.AUXILIARY_PREVIEW_FRAMES[groupKey]) do
        previewFrame:SetAttribute("unit", nil)
        UnregisterUnitWatch(previewFrame)
        previewFrame:Show()
        ZF:ApplyUnitPreviewContent(previewFrame, "raid" .. i)
    end
    ZF:LayoutAuxiliaryPreviewFrame(groupKey)
end

function ZF:ExitAuxiliaryPreview(groupKey)
    if InCombatLockdown() then return end
    for _, previewFrame in ipairs(ZF.AUXILIARY_PREVIEW_FRAMES[groupKey]) do
        previewFrame.isUnitPreview = nil
        previewFrame.previewClass = nil
        previewFrame:SetAttribute("unit", nil)
        previewFrame:Hide()
    end
    ZF:UpdateAuxiliaryRaidGroup(groupKey)
end

function ZF:EnterMainTankPreview() ZF:EnterAuxiliaryPreview("maintank") end
function ZF:ExitMainTankPreview() ZF:ExitAuxiliaryPreview("maintank") end
function ZF:EnterMainAssistPreview() ZF:EnterAuxiliaryPreview("mainassist") end
function ZF:ExitMainAssistPreview() ZF:ExitAuxiliaryPreview("mainassist") end