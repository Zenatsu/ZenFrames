local _, ZF = ...

function ZF:CreateUnitLeaderAssistantIndicator(unitFrame, unit)
    local LeaderAssistantDB = ZF:GetUnitDB(unitFrame, unit).Indicators.LeaderAssistant
    if not LeaderAssistantDB then return end

    local Leader = ZF:CreateIndicatorTexture(unitFrame, unit, "_LeaderIndicator", LeaderAssistantDB.Size, LeaderAssistantDB.Layout)
    local Assistant = ZF:CreateIndicatorTexture(unitFrame, unit, "_AssistantIndicator", LeaderAssistantDB.Size, LeaderAssistantDB.Layout)

    if LeaderAssistantDB.Enabled then
        unitFrame.LeaderIndicator = Leader
        unitFrame.AssistantIndicator = Assistant
    else
        ZF:DisableIndicatorElement(unitFrame, "LeaderIndicator", Leader)
        ZF:DisableIndicatorElement(unitFrame, "AssistantIndicator", Assistant)
    end

    return Leader, Assistant
end

function ZF:UpdateUnitLeaderAssistantIndicator(unitFrame, unit)
    local LeaderAssistantDB = ZF:GetUnitDB(unitFrame, unit).Indicators.LeaderAssistant

    if LeaderAssistantDB.Enabled then
        if not unitFrame.LeaderIndicator or not unitFrame.AssistantIndicator then
            ZF:CreateUnitLeaderAssistantIndicator(unitFrame, unit)
        end

        if not unitFrame:IsElementEnabled("LeaderIndicator") then unitFrame:EnableElement("LeaderIndicator") end
        if not unitFrame:IsElementEnabled("AssistantIndicator") then unitFrame:EnableElement("AssistantIndicator") end

        if unitFrame.LeaderIndicator then
            ZF:PositionIndicatorTexture(unitFrame.LeaderIndicator, unitFrame.HighLevelContainer, LeaderAssistantDB.Size, LeaderAssistantDB.Layout)
            unitFrame.LeaderIndicator:Show()
            unitFrame.LeaderIndicator:ForceUpdate()
        end

        if unitFrame.AssistantIndicator then
            ZF:PositionIndicatorTexture(unitFrame.AssistantIndicator, unitFrame.HighLevelContainer, LeaderAssistantDB.Size, LeaderAssistantDB.Layout)
            unitFrame.AssistantIndicator:Show()
            unitFrame.AssistantIndicator:ForceUpdate()
        end
    else
        if not unitFrame.LeaderIndicator and not unitFrame.AssistantIndicator then return end
        ZF:DisableIndicatorElement(unitFrame, "LeaderIndicator", unitFrame.LeaderIndicator)
        ZF:DisableIndicatorElement(unitFrame, "AssistantIndicator", unitFrame.AssistantIndicator)
        unitFrame.LeaderIndicator = nil
        unitFrame.AssistantIndicator = nil
    end
end
