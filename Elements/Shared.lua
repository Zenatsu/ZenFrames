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
