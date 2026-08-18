local _, ZF = ...

local HIGH_LEVEL_CONTAINER_FRAME_LEVEL = 999
local CONTAINER_BORDER_FRAME_LEVEL_OFFSET = 3

local function ApplyContainerBorderStyle(border, ContainerDB)
    border:SetBackdrop({ edgeFile = ZF.BACKDROP.edgeFile, edgeSize = math.max(ContainerDB.BorderThickness, 1), insets = ZF.BACKDROP.insets })
    border:SetBackdropColor(0, 0, 0, 0)
    border:SetBackdropBorderColor(ContainerDB.BorderColor[1], ContainerDB.BorderColor[2], ContainerDB.BorderColor[3], ContainerDB.BorderThickness > 0 and ContainerDB.BorderOpacity or 0)
end

function ZF:CreateUnitContainer(unitFrame, unit)
    if unitFrame.Container then return end
    local ContainerDB = ZF:GetUnitDB(unitFrame, unit).Frame

    unitFrame.Container = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_Container", unitFrame, "BackdropTemplate")
    unitFrame.Container:SetAllPoints(unitFrame)
    unitFrame.Container:SetBackdrop(ZF.BACKDROP)
    unitFrame.Container:SetBackdropColor(0, 0, 0, 0)
    unitFrame.Container:SetBackdropBorderColor(0, 0, 0, 0)

    unitFrame.ContainerBorder = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_ContainerBorder", unitFrame.Container, "BackdropTemplate")
    unitFrame.ContainerBorder:SetAllPoints(unitFrame.Container)
    unitFrame.ContainerBorder:SetFrameLevel(unitFrame.Container:GetFrameLevel() + CONTAINER_BORDER_FRAME_LEVEL_OFFSET)
    ApplyContainerBorderStyle(unitFrame.ContainerBorder, ContainerDB)

    if unitFrame.HighLevelContainer then return end

    unitFrame.HighLevelContainer = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_HighLevelContainer", unitFrame)
    unitFrame.HighLevelContainer:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 0, 0)
    unitFrame.HighLevelContainer:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", 0, 0)
    unitFrame.HighLevelContainer:SetFrameLevel(HIGH_LEVEL_CONTAINER_FRAME_LEVEL)
    unitFrame.HighLevelContainer:SetFrameStrata("MEDIUM")
end

function ZF:UpdateUnitContainer(unitFrame, unit)
    if not unitFrame.ContainerBorder then return end
    local ContainerDB = ZF:GetUnitDB(unitFrame, unit).Frame
    ApplyContainerBorderStyle(unitFrame.ContainerBorder, ContainerDB)
end