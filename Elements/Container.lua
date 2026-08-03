local _, ZF = ...

-- Sits above every other indicator/element so nothing else needs a
-- frame-level tug-of-war to render on top of the unit frame.
local HIGH_LEVEL_CONTAINER_FRAME_LEVEL = 999

function ZF:CreateUnitContainer(unitFrame, unit)
    if unitFrame.Container then return end

    unitFrame.Container = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_Container", unitFrame, "BackdropTemplate")
    unitFrame.Container:SetBackdrop(ZF.BACKDROP)
    unitFrame.Container:SetBackdropColor(0, 0, 0, 0)
    unitFrame.Container:SetBackdropBorderColor(0, 0, 0, 1)
    unitFrame.Container:SetAllPoints(unitFrame)

    if unitFrame.HighLevelContainer then return end

    unitFrame.HighLevelContainer = CreateFrame("Frame", ZF:FetchFrameName(unit) .. "_HighLevelContainer", unitFrame)
    unitFrame.HighLevelContainer:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 0, 0)
    unitFrame.HighLevelContainer:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", 0, 0)
    unitFrame.HighLevelContainer:SetFrameLevel(HIGH_LEVEL_CONTAINER_FRAME_LEVEL)
    unitFrame.HighLevelContainer:SetFrameStrata("MEDIUM")
end
