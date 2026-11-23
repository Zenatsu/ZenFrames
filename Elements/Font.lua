local _, ZF = ...

function ZF:ApplyFontStringStyle(fontString, font, fontSize, fontFlag, color, shadowDB)
    fontString:SetFont(font, fontSize, fontFlag)
    fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    if shadowDB.Enabled then
        fontString:SetShadowColor(shadowDB.Color[1], shadowDB.Color[2], shadowDB.Color[3], shadowDB.Color[4])
        fontString:SetShadowOffset(shadowDB.XPos, shadowDB.YPos)
    else
        fontString:SetShadowColor(0, 0, 0, 0)
        fontString:SetShadowOffset(0, 0)
    end
end

function ZF:ApplyBackdropStyle(frame, backdropColor, borderColor)
    frame:SetBackdrop(ZF.BACKDROP)
    frame:SetBackdropColor(unpack(backdropColor))
    frame:SetBackdropBorderColor(unpack(borderColor))
end

function ZF:GetBorderColor(borderDB)
    return borderDB.BorderColor[1], borderDB.BorderColor[2], borderDB.BorderColor[3], borderDB.BorderThickness > 0 and borderDB.BorderOpacity or 0
end

function ZF:ApplyOutsetBorder(frame, anchorTo, thickness, edgeFile, bgFile)
    frame:SetBackdrop({ bgFile = bgFile, edgeFile = edgeFile, edgeSize = thickness, insets = { left = -thickness, right = -thickness, top = -thickness, bottom = -thickness } })
    frame:SetPoint("TOPLEFT", anchorTo, "TOPLEFT", -thickness, thickness)
    frame:SetPoint("BOTTOMRIGHT", anchorTo, "BOTTOMRIGHT", thickness, -thickness)
end

function ZF:ApplyBorderStyle(frame, borderDB, maxDimension, backdropColor)
    local borderSize = math.max(math.min(borderDB.BorderThickness, math.floor(maxDimension / 2)), 1)
    frame:SetBackdrop({ edgeFile = ZF.BACKDROP.edgeFile, edgeSize = borderSize, insets = ZF.BACKDROP.insets })
    frame:SetBackdropColor(unpack(backdropColor))
    frame:SetBackdropBorderColor(ZF:GetBorderColor(borderDB))
    return borderSize
end
