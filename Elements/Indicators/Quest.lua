local _, ZF = ...

local function UpdateQuestTexture(QuestIndicator, unitFrame, unit)
    local QuestIndicatorDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Quest
    QuestIndicator:SetTexture(ZF.QuestTextures[QuestIndicatorDB.Texture] or ZF.QuestTextures.DEFAULT)
    if QuestIndicatorDB.Texture == "QUEST0" then
        QuestIndicator:SetHeight(QuestIndicatorDB.Size)
        QuestIndicator:SetWidth(QuestIndicatorDB.Size * 0.35)
    else
        QuestIndicator:SetSize(QuestIndicatorDB.Size, QuestIndicatorDB.Size)
    end
end

function ZF:CreateUnitQuestIndicator(unitFrame, unit)
    local QuestIndicatorDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Quest

    local QuestIndicator = unitFrame.HighLevelContainer:CreateTexture(ZF:FetchFrameName(unit) .. "_QuestIndicator", "OVERLAY")
    QuestIndicator:SetPoint(QuestIndicatorDB.Layout[1], unitFrame.HighLevelContainer, QuestIndicatorDB.Layout[2], QuestIndicatorDB.Layout[3], QuestIndicatorDB.Layout[4])
    QuestIndicator.PostUpdate = function(indicator) UpdateQuestTexture(indicator, unitFrame, unit) end
    UpdateQuestTexture(QuestIndicator, unitFrame, unit)

    if QuestIndicatorDB.Enabled then
        unitFrame.QuestUnitIndicator = QuestIndicator
        unitFrame.QuestUnitIndicator:Show()
    else
        ZF:DisableIndicatorElement(unitFrame, "QuestUnitIndicator", QuestIndicator)
    end

    return QuestIndicator
end

function ZF:UpdateUnitQuestIndicator(unitFrame, unit)
    local QuestIndicatorDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Quest

    if QuestIndicatorDB.Enabled then
        unitFrame.QuestUnitIndicator = unitFrame.QuestUnitIndicator or ZF:CreateUnitQuestIndicator(unitFrame, unit)

        if not unitFrame:IsElementEnabled("QuestUnitIndicator") then unitFrame:EnableElement("QuestUnitIndicator") end

        if unitFrame.QuestUnitIndicator then
            unitFrame.QuestUnitIndicator:ClearAllPoints()
            unitFrame.QuestUnitIndicator:SetPoint(QuestIndicatorDB.Layout[1], unitFrame.HighLevelContainer, QuestIndicatorDB.Layout[2], QuestIndicatorDB.Layout[3], QuestIndicatorDB.Layout[4])
            unitFrame.QuestUnitIndicator:ForceUpdate()
        end
    else
        if not unitFrame.QuestUnitIndicator then return end
        ZF:DisableIndicatorElement(unitFrame, "QuestUnitIndicator", unitFrame.QuestUnitIndicator)
        unitFrame.QuestUnitIndicator = nil
    end
end
