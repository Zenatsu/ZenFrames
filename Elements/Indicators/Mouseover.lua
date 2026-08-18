local _, ZF = ...

local function ApplyMouseoverStyle(highlight, healthBar, MouseoverDB)
    highlight:ClearAllPoints()

    if MouseoverDB.Style == "BORDER" then
        local t = MouseoverDB.BorderThickness
        highlight:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -t, t)
        highlight:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", t, -t)
        highlight:SetBackdrop({ bgFile = ZF.BACKDROP.bgFile, edgeFile = ZF.BACKDROP.edgeFile, edgeSize = t, insets = {left = -t, right = -t, top = -t, bottom = -t} })
        highlight:SetBackdropColor(0, 0, 0, 0)
        highlight:SetBackdropBorderColor(MouseoverDB.Color[1], MouseoverDB.Color[2], MouseoverDB.Color[3], MouseoverDB.HighlightOpacity)
    elseif MouseoverDB.Style == "GRADIENT" then
        highlight:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
        highlight:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
        highlight:SetBackdrop({
            bgFile = ZF.Media.Gradient,
            edgeFile = nil,
            tile = false, tileSize = 0, edgeSize = 0,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        highlight:SetBackdropColor(MouseoverDB.Color[1], MouseoverDB.Color[2], MouseoverDB.Color[3], MouseoverDB.HighlightOpacity)
        highlight:SetBackdropBorderColor(0, 0, 0, 0)
    else
        highlight:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
        highlight:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
        highlight:SetBackdrop(ZF.BACKDROP)
        highlight:SetBackdropColor(MouseoverDB.Color[1], MouseoverDB.Color[2], MouseoverDB.Color[3], MouseoverDB.HighlightOpacity)
        highlight:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

function ZF:CreateUnitMouseoverIndicator(unitFrame, unit)
    if unitFrame.MouseoverHighlight then return unitFrame.MouseoverHighlight end
    local MouseoverDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Mouseover
    unitFrame.MouseoverIndicatorDB = MouseoverDB

    local MouseoverHighlight = CreateFrame("Frame", nil, unitFrame.Health, "BackdropTemplate")
    ApplyMouseoverStyle(MouseoverHighlight, unitFrame.Health, MouseoverDB)
    MouseoverHighlight:Hide()
    MouseoverHighlight:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 3)
    unitFrame.MouseoverHighlight = MouseoverHighlight

    unitFrame:HookScript("OnEnter", function() if unitFrame.MouseoverIndicatorDB.Enabled then MouseoverHighlight:Show() end end)
    unitFrame:HookScript("OnLeave", function() if unitFrame.MouseoverIndicatorDB.Enabled then MouseoverHighlight:Hide() end end)

    return MouseoverHighlight
end

function ZF:UpdateUnitMouseoverIndicator(unitFrame, unit)
    local MouseoverDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Mouseover
    unitFrame.MouseoverIndicatorDB = MouseoverDB

    if MouseoverDB.Enabled then
        unitFrame.MouseoverHighlight = unitFrame.MouseoverHighlight or ZF:CreateUnitMouseoverIndicator(unitFrame, unit)
        ApplyMouseoverStyle(unitFrame.MouseoverHighlight, unitFrame.Health, MouseoverDB)

        if unitFrame:IsMouseOver() then unitFrame.MouseoverHighlight:Show() else unitFrame.MouseoverHighlight:Hide() end
    else
        if unitFrame.MouseoverHighlight then
            unitFrame.MouseoverHighlight:Hide()
        end
    end
end
