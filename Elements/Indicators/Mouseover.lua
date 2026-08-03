local _, ZF = ...

function ZF:CreateUnitMouseoverIndicator(unitFrame, unit)
    local MouseoverDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Mouseover
	if unitFrame.MouseoverHighlight then return unitFrame.MouseoverHighlight end

    local MouseoverHighlight = CreateFrame("Frame", nil, unitFrame.Health, "BackdropTemplate")
    MouseoverHighlight:SetPoint("TOPLEFT", unitFrame.Health, "TOPLEFT", 0, 0)
    MouseoverHighlight:SetPoint("BOTTOMRIGHT", unitFrame.Health, "BOTTOMRIGHT", 0, 0)

    if MouseoverDB.Style == "BORDER" then
        MouseoverHighlight:SetBackdrop(ZF.BACKDROP)
        MouseoverHighlight:SetBackdropColor(0,0,0,0)
        MouseoverHighlight:SetBackdropBorderColor(MouseoverDB.Color[1], MouseoverDB.Color[2], MouseoverDB.Color[3], MouseoverDB.HighlightOpacity)
    elseif MouseoverDB.Style == "GRADIENT" then
        MouseoverHighlight:SetBackdrop({
            bgFile = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Gradient.png",
            edgeFile = nil,
            tile = false, tileSize = 0, edgeSize = 0,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        MouseoverHighlight:SetBackdropColor(MouseoverDB.Color[1], MouseoverDB.Color[2], MouseoverDB.Color[3], MouseoverDB.HighlightOpacity)
        MouseoverHighlight:SetBackdropBorderColor(0,0,0,0)
    else
        MouseoverHighlight:SetBackdrop(ZF.BACKDROP)
        MouseoverHighlight:SetBackdropColor(MouseoverDB.Color[1], MouseoverDB.Color[2], MouseoverDB.Color[3], MouseoverDB.HighlightOpacity)
        MouseoverHighlight:SetBackdropBorderColor(0,0,0,0)
    end

    MouseoverHighlight:Hide()
    MouseoverHighlight:SetFrameLevel(unitFrame.Health:GetFrameLevel() + 3)
	unitFrame.MouseoverHighlight = MouseoverHighlight
    unitFrame:HookScript("OnEnter", function() local DB = ZF:GetUnitDB(unitFrame, unit).Indicators.Mouseover if DB.Enabled then MouseoverHighlight:Show() end end)
    unitFrame:HookScript("OnLeave", function() local DB = ZF:GetUnitDB(unitFrame, unit).Indicators.Mouseover if DB.Enabled then MouseoverHighlight:Hide() end end)

    return MouseoverHighlight
end

function ZF:UpdateUnitMouseoverIndicator(unitFrame, unit)
    local MouseoverDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Mouseover

    if MouseoverDB.Enabled then
        unitFrame.MouseoverHighlight = unitFrame.MouseoverHighlight or ZF:CreateUnitMouseoverIndicator(unitFrame, unit)

        if MouseoverDB.Style == "BORDER" then
            unitFrame.MouseoverHighlight:SetBackdrop(ZF.BACKDROP)
            unitFrame.MouseoverHighlight:SetBackdropColor(0,0,0,0)
            unitFrame.MouseoverHighlight:SetBackdropBorderColor(MouseoverDB.Color[1], MouseoverDB.Color[2], MouseoverDB.Color[3], MouseoverDB.HighlightOpacity)
        elseif MouseoverDB.Style == "GRADIENT" then
            unitFrame.MouseoverHighlight:SetBackdrop({
                bgFile = "Interface\\AddOns\\ZenFrames\\Media\\Textures\\Gradient.png",
                edgeFile = nil,
                tile = false, tileSize = 0, edgeSize = 0,
                insets = { left = 0, right = 0, top = 0, bottom = 0 },
            })
            unitFrame.MouseoverHighlight:SetBackdropColor(MouseoverDB.Color[1], MouseoverDB.Color[2], MouseoverDB.Color[3], MouseoverDB.HighlightOpacity)
            unitFrame.MouseoverHighlight:SetBackdropBorderColor(0,0,0,0)
        else
            unitFrame.MouseoverHighlight:SetBackdrop(ZF.BACKDROP)
            unitFrame.MouseoverHighlight:SetBackdropColor(MouseoverDB.Color[1], MouseoverDB.Color[2], MouseoverDB.Color[3], MouseoverDB.HighlightOpacity)
            unitFrame.MouseoverHighlight:SetBackdropBorderColor(0,0,0,0)
        end

        if unitFrame:IsMouseOver() then unitFrame.MouseoverHighlight:Show() else unitFrame.MouseoverHighlight:Hide() end
    else
        if unitFrame.MouseoverHighlight then
            unitFrame.MouseoverHighlight:Hide()
        end
    end
end
