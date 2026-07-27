local _, RUF = ...
local oUF = RUF.oUF
local overlays = {} 
local overLayer
local selectedEntry
local showingDropMessage = false
local designerUnit = "player"
local STYLE = RUF.DesignerStyle
local decorFrames = {} -- keyed decor frames: "Canvas" border, "OptionsPanel" backdrop

function RUF:CreateDesignerPreviewFrame() -- Set up the preview frame of the designer
    if RUF.DESIGNER_PREVIEW_FRAME then return RUF.DESIGNER_PREVIEW_FRAME end

    local activeStyle = oUF:GetActiveStyle()
    oUF:RegisterStyle("RUF_PlayerDesignerPreviewStyle", function(unitFrame)
        RUF.DESIGNER_PREVIEW_ACTIVE=true
        RUF:CreateUnitFrame(unitFrame, "player")
        RUF.DESIGNER_PREVIEW_ACTIVE=false
    end)
    oUF:SetActiveStyle("RUF_PlayerDesignerPreviewStyle")

    local previewFrame = oUF:Spawn("Player", "RUF_PlayerDesignerPreview_frame") -- spawn the preview frame of the player
    previewFrame.isDesignerPreview=true
    
    previewFrame:SetAttribute("unit",nil)
    UnregisterUnitWatch(previewFrame)
    if previewFrame:IsElementEnabled("Auras") then previewFrame:DisableElement("Auras") end
    if previewFrame:IsElementEnabled("CustomAuras") then previewFrame:DisableElement("CustomAuras") end
    previewFrame:EnableMouse(false)

    if activeStyle then oUF:SetActiveStyle(activeStyle) end
    
    previewFrame:Hide()
    RUF.DESIGNER_PREVIEW_FRAME = previewFrame
    return previewFrame
end

function RUF:UpdateDesignerPreviewFrame() -- Updates the preview frame
    local previewFrame = RUF:CreateDesignerPreviewFrame()
    local fDB = RUF.db.profile.Units.player.Frame

    RUF.DESIGNER_PREVIEW_ACTIVE = true
    RUF:UpdateUnitFrame(previewFrame, "player")
    RUF.DESIGNER_PREVIEW_ACTIVE = false
    
    if previewFrame:IsElementEnabled("Auras") then previewFrame:DisableElement("Auras") end
    if previewFrame:IsElementEnabled("CustomAuras") then previewFrame:DisableElement("CustomAuras") end
    if previewFrame:IsElementEnabled("PrivateAuras") then previewFrame:DisableElement("PrivateAuras") end

    previewFrame:SetSize(fDB.Width, fDB.Height)
    previewFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    previewFrame:SetFrameLevel(100)
    if previewFrame.HighLevelContainer then
            previewFrame.HighLevelContainer:SetFrameStrata("FULLSCREEN_DIALOG")
        end


    if previewFrame.Health then
        previewFrame.Health:SetMinMaxValues(0,100)
         previewFrame.Health:SetValue(STYLE.Preview.SampleHealth)
    end
    if previewFrame.Power then
        previewFrame.Power:SetMinMaxValues(0,100)
        previewFrame.Power:SetValue(STYLE.Preview.SamplePower)
        previewFrame.Power:Show()
    end

    RUF:ApplyDesignerSampleData()
end

function RUF:ShowDesignerPreview(parentFrame, unit, optionsContainer)
    if unit and unit ~= designerUnit then RUF:SetDesignerUnit(unit) end
    RUF.DESIGNER_CANVAS_FRAME = parentFrame
    RUF.DESIGNER_OPTIONS_CONTAINER = optionsContainer

    local previewFrame = RUF:CreateDesignerPreviewFrame()
    previewFrame:SetParent(parentFrame)
    previewFrame:Show()
    RUF:UpdateDesignerPreviewFrame()
    previewFrame:ClearAllPoints()
    previewFrame:SetPoint("CENTER", parentFrame, "CENTER",0,0)
    previewFrame:SetFrameLevel(parentFrame:GetFrameLevel()+10)
    RUF:AnchorDesignerOverlays()
    RUF:SetDesignerSelection(selectedEntry)
end

function RUF:HideDesignerPreview()
    RUF.DESIGNER_CANVAS_FRAME = nil
    RUF.DESIGNER_OPTIONS_CONTAINER = nil
    if RUF.DESIGNER_PREVIEW_FRAME then RUF.DESIGNER_PREVIEW_FRAME:Hide() end
    RUF:ResetDesignerInteractionState()
    for _, decor in pairs(decorFrames) do decor:Hide() end
end

-- Designer Widget registry. Inspired by Platynator's designer tool, this sets up to show and maintain the widgets within the designer preview frame

local function GetLiveFrame(unit) return RUF[unit:upper()] end

local function TagEntry(unit, tagKey, label)
    return {
        key = tagKey, label = label, kind = "tag", unit = unit,
        getDB = function() return RUF:GetUnitDB(nil, unit).Tags[tagKey] end,
        getRegion = function(previewFrame) return previewFrame.Tags and previewFrame.Tags[tagKey] end,
        refreshPreview = function(previewFrame)
            RUF.DESIGNER_PREVIEW_ACTIVE = true
            RUF:UpdateUnitTag(previewFrame, unit, tagKey)
            RUF.DESIGNER_PREVIEW_ACTIVE = false
        end,
        refreshLive = function()
            local liveFrame = GetLiveFrame(unit)
            if liveFrame then RUF:UpdateUnitTag(liveFrame, unit, tagKey) end
        end,
    }
end

local function IndicatorEntry(unit, entry)
   entry.kind = "indicator"
   entry.unit = unit
   entry.getDB = function() return RUF:GetUnitDB(nil, unit).Indicators[entry.dbKey] end
   entry.refreshPreview = function(previewFrame)
    RUF.DESIGNER_PREVIEW_ACTIVE = true
    entry.update(previewFrame)
    RUF.DESIGNER_PREVIEW_ACTIVE = false
   end
   entry.refreshLive = function()
        local liveFrame = GetLiveFrame(unit)
        if liveFrame then entry.update(liveFrame) end
   end
   return entry
end

local function BuildDesignerRegistry(unit)
    local registry = {
        TagEntry(unit, "TagOne", "Tag One"),
        TagEntry(unit, "TagTwo", "Tag Two"),
        TagEntry(unit, "TagThree", "Tag Three"),
        TagEntry(unit, "TagFour", "Tag Four"),
        TagEntry(unit, "TagFive", "Tag Five"),
        IndicatorEntry(unit, {
            key = "RaidTargetMarker", label = "Raid Target Marker", dbKey = "RaidTargetMarker",
            oUFElements = {"RaidTargetIndicator"},
            getRegion = function(previewFrame) return previewFrame.RaidTargetIndicator end,
            update = function(unitFrame) RUF:UpdateUnitRaidTargetMarker(unitFrame, unit) end,
            sample = function(previewFrame)
                local region = previewFrame.RaidTargetIndicator if not region then return end
                region:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
                SetRaidTargetIconTexture(region, 8) -- skull
                region:Show()
            end,
        }),
        IndicatorEntry(unit, {
            key = "LeaderAssistant", label = "Leader Indicator", dbKey = "LeaderAssistantIndicator", oUFElements = {"LeaderIndicator", "AssistantIndicator"},
            getRegion = function(previewFrame) return previewFrame.LeaderIndicator end,
            update = function(unitFrame) RUF:UpdateUnitLeaderAssistantIndicator(unitFrame, unit) end,
            sample = function(previewFrame)
                local region = previewFrame.LeaderIndicator if not region then return end
                region:SetTexture([[Interface\GroupFrame\UI-Group-LeaderIcon]])
                region:SetTexCoord(0,1,0,1)
                region:Show()
                if previewFrame.AssistantIndicator then previewFrame.AssistantIndicator:Hide() end -- Leader and Assistant share one DB Layout and Overlap.
            end,
        }),
        IndicatorEntry(unit, {
            key = "Resting", label = "Resting Indicator", dbKey = "Resting", oUFElements = {"RestingIndicator"},
            getRegion = function(previewFrame) return previewFrame.RestingIndicator end,
            update = function(unitFrame) RUF:UpdateUnitRestingIndicator(unitFrame, unit) end, -- Update sets the texture, visibility is state driven
            sample = function(previewFrame) if previewFrame.RestingIndicator then previewFrame.RestingIndicator:Show() end
        end,
        }),
        IndicatorEntry(unit, {
            key = "Combat", label = "Combat Indicator", dbKey = "Combat", oUFElements = {"CombatIndicator"},
            getRegion = function(previewFrame) return previewFrame.CombatIndicator end,
            update = function(unitFrame) RUF:UpdateUnitCombatIndicator(unitFrame, unit) end,
            sample = function(previewFrame) if previewFrame.CombatIndicator then previewFrame.CombatIndicator:Show() end
        end,
        }),
        IndicatorEntry(unit, {
            key = "PvP", label = "PvP Indicator", dbKey = "PvP", oUFElements = {"PvPIndicator"},
            getRegion = function(previewFrame) return previewFrame.PvPIndicator end,
            update = function(unitFrame) RUF:UpdateUnitPvPIndicator(unitFrame, unit) end,
            sample = function(previewFrame)
                local region = previewFrame.PvPIndicator if not region then return end
                local faction = UnitFactionGroup("player") == "Horde" and "Horde" or "Alliance"
                region:SetTexture("Interface\\TargetingFrame\\UI-PvP-" .. faction)
                region:SetTexCoord(0, 0.65625, 0, 0.65625)
                region:Show()
                if region.Badge then region.Badge:Hide() end
            end,
        }),
    }

    local entriesByKey = {}
    for _, entry in ipairs(registry) do entriesByKey[entry.key] = entry end
    for key, overlay in pairs(overlays) do
        overlay.entry = entriesByKey[key]
        if not overlay.entry then overlay:Hide() end
    end
    return registry
end

RUF.DESIGNER_WIDGETS = BuildDesignerRegistry(designerUnit)

function RUF:GetDesignerUnit() return designerUnit end

function RUF:SetDesignerUnit(unit)
    if unit == designerUnit then return end
    RUF:SetDesignerSelection(nil)
    designerUnit = unit
    RUF.DESIGNER_WIDGETS = BuildDesignerRegistry(unit)
end

function RUF:ApplyDesignerSampleData()
    local previewFrame = RUF.DESIGNER_PREVIEW_FRAME 
    if not previewFrame then return end

    for _, entry in ipairs(RUF.DESIGNER_WIDGETS) do
        local db = entry.getDB()
        if entry.kind == "indicator" then 
            if db and db.Enabled then
                for _, elementName in ipairs(entry.oUFElements) do
                    if previewFrame:IsElementEnabled(elementName) then previewFrame:DisableElement(elementName) end
                end
                if entry.sample then entry.sample(previewFrame) end
            end
        else
            local region = entry.getRegion(previewFrame)
            if region and (not db.Tag or db.Tag == "") then region:SetText(entry.label) end
        end
    end
    if previewFrame.Totems then
        for _, totem in ipairs(previewFrame.Totems) do totem:EnableMouse(false) end
    end
end

function RUF:RefreshDesignerWidget(entry)
    local previewFrame = RUF.DESIGNER_PREVIEW_FRAME
    if not previewFrame or not previewFrame:IsShown() then return end
    entry.refreshPreview(previewFrame)
    entry.refreshLive()
    RUF:ApplyDesignerSampleData()
    RUF:AnchorDesignerOverlays()
    RUF:UpdateDesignerStatusText()
end

-- Overlay region with overlay visuals
local function UpdateOverlayVisual(overlay)
    if overlay.entry == selectedEntry then
        overlay:SetBackdropBorderColor(unpack(STYLE.Palette.Selected))  -- Gold: Selected
    elseif overlay.hovered then
        overlay:SetBackdropBorderColor(unpack(STYLE.Palette.Hovered))   -- White: Hovered
    else
        overlay:SetBackdropBorderColor(unpack(STYLE.Palette.Idle))     -- Invisible: not hovered, not selected
    end
end

local function IsInsideCanvas(overlay, x, y)
    local canvas = RUF.DESIGNER_CANVAS_FRAME
    if not (canvas and x and y) then return true end
    local scale = overlay:GetEffectiveScale() / canvas:GetEffectiveScale()
    local left, bottom, width, height = canvas:GetRect()
    if not left then return true end
    local scale = overlay:GetEffectiveScale()/canvas:GetEffectiveScale()
    x,y = x*scale, y*scale
    return x >= left and x <= left + width and y >= bottom and y <= bottom + height
end

local function ShowDropRejectedMessage()
    if not overLayer then return end
    showingDropMessage = true
    overLayer.Status:SetText(STYLE.Palette.ErrorText .. "Dropped outside the canvas|r")
    C_Timer.After(STYLE.StatusText.DropMessageSeconds, function()
        showingDropMessage = false
        RUF:UpdateDesignerStatusText()
    end)
end

function RUF:UpdateDesignerStatusText()
    if not overLayer then return end
    if selectedEntry then
        local db = selectedEntry.getDB()
        overLayer.Status:SetFormattedText(STYLE.Palette.SelectedText .. "%s|r    Anchor: %s -> %s    X: %d Y: %d", selectedEntry.label, db.Layout[1], db.Layout[2], db.Layout[3], db.Layout[4])
    else
        overLayer.Status:SetText("Hover over a widget to highlight it. Click to select. Drag to move.")
    end    
end

local function GetOverLayer()
    if overLayer then return overLayer end
    local previewFrame = RUF.DESIGNER_PREVIEW_FRAME
    overLayer = CreateFrame("Frame", "RUF_DesignerOverLayer", previewFrame)
    overLayer:SetAllPoints(previewFrame)
    overLayer:SetFrameStrata("FULLSCREEN_DIALOG")
    overLayer:SetFrameLevel(1000)
    overLayer:EnableMouse(true)
    overLayer:SetScript("OnMouseDown", function() RUF:SetDesignerSelection(nil) end)
    overLayer.Status = overLayer:CreateFontString(nil, "OVERLAY")
    overLayer.Status:SetFont(RUF.Media.Font, STYLE.StatusText.Size, STYLE.StatusText.Outline)
    overLayer.Status:SetPoint("TOP", previewFrame, "BOTTOM", 0, STYLE.StatusText.FallbackOffsetY)
    overLayer.Status:SetText("Hover over a widget to highlight it")
    return overLayer
end

local function CreateOverlay(entry, index)
    local layer = GetOverLayer()
    local overlay = CreateFrame("Button", "RUF_DesignerOverlay_" .. entry.key, layer, "BackdropTemplate")
    overlay.entry = entry
    overlay:SetFrameLevel(layer:GetFrameLevel() +10+ index) -- Always sit above the parent frame level
    overlay:SetBackdrop(STYLE.Overlays.Backdrop)  
     overlay:SetBackdropColor(unpack(STYLE.Overlays.Fill))
    overlay:SetMovable(true)
    overlay:SetClampedToScreen(true)
    overlay:RegisterForDrag("LeftButton")
    overlay:SetScript("OnEnter", function(self) 
        self.hovered = true 
        UpdateOverlayVisual(self)
        if not selectedEntry then overLayer.Status:SetText("Hovering: " .. self.entry.label) end
    end)
    overlay:SetScript("OnLeave", function(self)
        self.hovered = false
        UpdateOverlayVisual(self)
        if not showingDropMessage then RUF:UpdateDesignerStatusText() end
    end)
    overlay:SetScript("OnClick", function(self) RUF:SetDesignerSelection(self.entry) end)
    UpdateOverlayVisual(overlay)
    overlays[entry.key] = overlay
    overlay:SetScript("OnDragStart", function(self)
        RUF:SetDesignerSelection(self.entry)
        self.startX, self.startY = self:GetCenter()
        self:StartMoving() 
        local region = self.entry.getRegion(RUF.DESIGNER_PREVIEW_FRAME)
        if region then region:ClearAllPoints() region:SetPoint("CENTER", self, "CENTER", 0, 0) end
    end)
    overlay:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local endX, endY = self:GetCenter()
        local startX, startY = self.startX, self.startY
        self.startX, self.startY = nil, nil
        if not (startX and endX) then RUF:AnchorDesignerOverlays() return end
        
        if not IsInsideCanvas(self, endX, endY) then
            RUF:RefreshDesignerWidget(self.entry)
            ShowDropRejectedMessage()
            return
        end

        local db = self.entry.getDB()
        db.Layout[3] = math.floor(db.Layout[3] + (endX - startX) + 0.5)
        db.Layout[4] = math.floor(db.Layout[4] + (endY - startY) + 0.5)

        RUF:RefreshDesignerWidget(self.entry)
        RUF:BuildDesignerWidgetOptions(RUF.DESIGNER_OPTIONS_CONTAINER, designerUnit, self.entry)
    end)
    return overlay
end

local function ApplyDecorStyle(key, decor)
    local group = STYLE[key]
    decor:SetBackdrop(group.Backdrop) -- NOTE: SetBackdrop wipes colors, so tint after
    decor:SetBackdropColor(unpack(group.Fill))
    decor:SetBackdropBorderColor(unpack(group.Border))
end

local function GetDecorFrame(key, parent)
    local decor = decorFrames[key]
    if not decor then
        decor = CreateFrame("Frame", "RUF_DesignerDecor_" .. key, parent, "BackdropTemplate")
        decorFrames[key] = decor
    end
    ApplyDecorStyle(key, decor)
    decor:SetParent(parent)
    decor:SetFrameLevel(parent:GetFrameLevel())
    decor:ClearAllPoints()
    local pad = STYLE[key].Padding or {}
    decor:SetPoint("TOPLEFT", parent, "TOPLEFT", -(pad.left or 0), (pad.top or 0))
    decor:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", (pad.right or 0), -(pad.bottom or 0))
    decor:Show()
    return decor
end

function RUF:AnchorDesignerOverlays()
    local previewFrame = RUF.DESIGNER_PREVIEW_FRAME
    if not previewFrame then return end
    GetOverLayer()

    local canvas = RUF.DESIGNER_CANVAS_FRAME
    if canvas then
        overLayer.Status:ClearAllPoints()
        overLayer.Status:SetPoint("BOTTOM", canvas, "BOTTOM", 0, STYLE.StatusText.CanvasBottomInset)
        canvas:EnableMouse(true)
        canvas:SetScript("OnMouseDown", function() RUF:SetDesignerSelection(nil) end)
        GetDecorFrame("Canvas", canvas)
    end

    for index, entry in ipairs(RUF.DESIGNER_WIDGETS) do
        local region = entry.getRegion(previewFrame)
        local db = entry.getDB()
        local isActive = region and db and (entry.kind == "tag" or db.Enabled)
        local overlay = overlays[entry.key]
        if isActive then
            overlay = overlay or CreateOverlay(entry, index)
            local w, h = region:GetWidth(), region:GetHeight()
            if RUF:IsSecretValue(w) or RUF:IsSecretValue(h) then
                local fontSize = (entry.kind == "tag" and db.FontSize) or STYLE.Preview.FallbackFontSize
                w, h = fontSize * 5, fontSize
            end
            overlay:SetSize(
                math.max((w or 0) + STYLE.Layout.OverlayBleed * 2, STYLE.Layout.OverlayMinHit),
                math.max((h or 0) + STYLE.Layout.OverlayBleed * 2, STYLE.Layout.OverlayMinHit))
            overlay:ClearAllPoints()
            overlay:SetPoint(db.Layout[1], overLayer, db.Layout[2], db.Layout[3], db.Layout[4])
            overlay:Show()
        elseif overlay then
            overlay:Hide()
        end
    end
end

function RUF:ResetDesignerInteractionState()
    for _, overlay in pairs(overlays) do
        overlay:StopMovingOrSizing()
        overlay.startX, overlay.startY = nil, nil
        overlay.hovered = false
    end
    if overLayer and overLayer.Status then overLayer.Status:ClearAllPoints() end
    RUF:SetDesignerSelection(nil)
end

function RUF:SetDesignerSelection(entry)
    selectedEntry = entry
    for _, overlay in pairs(overlays) do UpdateOverlayVisual(overlay) end
    RUF:UpdateDesignerStatusText()
    if entry then
        RUF:BuildDesignerWidgetOptions(RUF.DESIGNER_OPTIONS_CONTAINER, designerUnit, entry)
    else
        RUF:BuildDesignerSectionOptions(RUF.DESIGNER_OPTIONS_CONTAINER, designerUnit, nil)
    end
end

function RUF:RefreshDesignerStyle()
    for _, overlay in pairs(overlays) do
        overlay:SetBackdrop(STYLE.Overlays.Backdrop)
        overlay:SetBackdropColor(unpack(STYLE.Overlays.Fill))
        UpdateOverlayVisual(overlay)
    end
    if overLayer and overLayer.Status then
        overLayer.Status:SetFont(RUF.Media.Font, STYLE.StatusText.Size, STYLE.StatusText.Outline)
    end
    for key, decor in pairs(decorFrames) do ApplyDecorStyle(key, decor) end
end

_G.RUFDebug = RUF -- For /run debugging commands