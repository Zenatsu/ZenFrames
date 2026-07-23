local _, RUF = ...

function RUF:CreateUnitContainer(unitFrame, unit)
    if not unitFrame.Container then
        unitFrame.Container = CreateFrame("Frame", RUF:FetchFrameName(unit) .. "_Container", unitFrame, "BackdropTemplate")
        unitFrame.Container:SetBackdrop(RUF.BACKDROP)
        unitFrame.Container:SetBackdropColor(0, 0, 0, 0)
        unitFrame.Container:SetBackdropBorderColor(0, 0, 0, 1)
        unitFrame.Container:SetAllPoints(unitFrame)

        if not unitFrame.HighLevelContainer then
            unitFrame.HighLevelContainer = CreateFrame("Frame", RUF:FetchFrameName(unit) .. "_HighLevelContainer", unitFrame)
            unitFrame.HighLevelContainer:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", 0, 0)
            unitFrame.HighLevelContainer:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", 0, 0)
            unitFrame.HighLevelContainer:SetFrameLevel(999)
            unitFrame.HighLevelContainer:SetFrameStrata("MEDIUM")
        end
    end
end