local _, RUF = ...

function RUF:CreateUnitLeaderAssistantIndicator(unitFrame, unit)
    local LeaderAssistantDB = RUF:GetUnitDB(unitFrame, unit).Indicators.LeaderAssistantIndicator
    if not LeaderAssistantDB then return end

    local Leader = RUF:CreateIndicatorTexture(unitFrame, unit, "_LeaderIndicator", LeaderAssistantDB.Size, LeaderAssistantDB.Layout)
    local Assistant = RUF:CreateIndicatorTexture(unitFrame, unit, "_AssistantIndicator", LeaderAssistantDB.Size, LeaderAssistantDB.Layout)

    if LeaderAssistantDB.Enabled then
        unitFrame.LeaderIndicator = Leader
        unitFrame.AssistantIndicator = Assistant
    else
        RUF:DisableIndicatorElement(unitFrame, "LeaderIndicator", Leader)
        RUF:DisableIndicatorElement(unitFrame, "AssistantIndicator", Assistant)
    end

    return Leader, Assistant
end

function RUF:UpdateUnitLeaderAssistantIndicator(unitFrame, unit)
    local LeaderAssistantDB = RUF:GetUnitDB(unitFrame, unit).Indicators.LeaderAssistantIndicator

    if LeaderAssistantDB.Enabled then
        if not unitFrame.LeaderIndicator or not unitFrame.AssistantIndicator then
            RUF:CreateUnitLeaderAssistantIndicator(unitFrame, unit)
        end

        if not unitFrame:IsElementEnabled("LeaderIndicator") then unitFrame:EnableElement("LeaderIndicator") end
        if not unitFrame:IsElementEnabled("AssistantIndicator") then unitFrame:EnableElement("AssistantIndicator") end

        if unitFrame.LeaderIndicator then
            RUF:PositionIndicatorTexture(unitFrame.LeaderIndicator, unitFrame.HighLevelContainer, LeaderAssistantDB.Size, LeaderAssistantDB.Layout)
            unitFrame.LeaderIndicator:Show()
            unitFrame.LeaderIndicator:ForceUpdate()
        end

        if unitFrame.AssistantIndicator then
            RUF:PositionIndicatorTexture(unitFrame.AssistantIndicator, unitFrame.HighLevelContainer, LeaderAssistantDB.Size, LeaderAssistantDB.Layout)
            unitFrame.AssistantIndicator:Show()
            unitFrame.AssistantIndicator:ForceUpdate()
        end
    else
        if not unitFrame.LeaderIndicator and not unitFrame.AssistantIndicator then return end
        RUF:DisableIndicatorElement(unitFrame, "LeaderIndicator", unitFrame.LeaderIndicator)
        RUF:DisableIndicatorElement(unitFrame, "AssistantIndicator", unitFrame.AssistantIndicator)
        unitFrame.LeaderIndicator = nil
        unitFrame.AssistantIndicator = nil
    end
end
