local _, ZF = ...

function ZF:CreateIndicatorTexture(unitFrame, unit, nameSuffix, size, layout, layer, subLevel)
    local texture = unitFrame.HighLevelContainer:CreateTexture(ZF:FetchFrameName(unit) .. nameSuffix, layer or "OVERLAY", nil, subLevel)
    texture:SetSize(size, size)
    texture:SetPoint(layout[1], unitFrame.HighLevelContainer, layout[2], layout[3], layout[4])
    return texture
end

function ZF:PositionIndicatorTexture(texture, parent, size, layout)
    texture:ClearAllPoints()
    texture:SetSize(size, size)
    texture:SetPoint(layout[1], parent, layout[2], layout[3], layout[4])
end

function ZF:DisableIndicatorElement(unitFrame, elementName, texture)
    if unitFrame:IsElementEnabled(elementName) then unitFrame:DisableElement(elementName) end
    if texture then texture:Hide() end
end
