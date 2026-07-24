local _, RUF = ...
local oUF = RUF.oUF

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
    
    RUF.DESIGNER_PREVIEW_FRAME = previewFrame
    return previewFrame
end

function RUF:UpdateDesignerPreviewFrame() -- Updates the preview frame
    local previewFrame = RUF:CreateDesignerPreviewFrame()
    local fDB = RUF.db.profile.Units.player.Frame

    RUF.DESIGNER_PREVIEW_ACTIVE = true
    RUF:UpdateUnitFrame(previewFrame, "player")
    RUF.DESIGNER_PREVIEW_ACTIVE = false
    
    previewFrame:SetSize(fDB.Width, fDB.Height)
    previewFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    previewFrame:SetFrameLevel(100)

    if previewFrame.Health then
        previewFrame.Health:SetMinMaxValues(0,100)
        previewFrame.Health:SetValue(70)
    end
    if previewFrame.Power then
        previewFrame.Power:SetMinMaxValues(0,100)
        previewFrame.Power:SetValue(45)
        previewFrame.Power:Show()
    end
end

function RUF:ShowDesignerPreview(parentFrame) -- Show the preview
    local previewFrame = RUF:CreateDesignerPreviewFrame()
    previewFrame:SetParent(parentFrame)
    RUF:UpdateDesignerPreviewFrame()
    previewFrame:ClearAllPoints()
    previewFrame:SetPoint("CENTER", parentFrame, "CENTER", 0,0)
    previewFrame:SetFrameLevel(parentFrame:GetFrameLevel()+10)
    previewFrame:Show()
end

function RUF:HideDesignerPreview() -- hide the preview
    if RUF.DESIGNER_PREVIEW_FRAME then RUF.DESIGNER_PREVIEW_FRAME:Hide() end
end