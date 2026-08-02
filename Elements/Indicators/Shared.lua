local _, RUF = ...

function RUF:CreateIndicatorTexture(unitFrame, unit, nameSuffix, size, layout, layer, subLevel)
    local texture = unitFrame.HighLevelContainer:CreateTexture(RUF:FetchFrameName(unit) .. nameSuffix, layer or "OVERLAY", nil, subLevel)
    texture:SetSize(size, size)
    texture:SetPoint(layout[1], unitFrame.HighLevelContainer, layout[2], layout[3], layout[4])
    return texture
end

function RUF:PositionIndicatorTexture(texture, parent, size, layout)
    texture:ClearAllPoints()
    texture:SetSize(size, size)
    texture:SetPoint(layout[1], parent, layout[2], layout[3], layout[4])
end

function RUF:DisableIndicatorElement(unitFrame, elementName, texture)
    if unitFrame:IsElementEnabled(elementName) then unitFrame:DisableElement(elementName) end
    if texture then texture:Hide() end
end
