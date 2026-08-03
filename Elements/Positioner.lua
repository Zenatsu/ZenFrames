local _, ZF = ...

local COOLDOWN_VIEWER_ANCHORS = {
    { addon = "SkironCooldownManager", frameName = "SCM_GroupAnchor_1" },
    { addon = "Coolinator", frameName = "CoolinatorPrimaryGroupAnchor" },
}
local DEFAULT_COOLDOWN_VIEWER_FRAME_NAME = "EssentialCooldownViewer"

local function FindCooldownViewerFrame()
    for _, candidate in ipairs(COOLDOWN_VIEWER_ANCHORS) do
        if C_AddOns.IsAddOnLoaded(candidate.addon) then
            return _G[candidate.frameName]
        end
    end
    return _G[DEFAULT_COOLDOWN_VIEWER_FRAME_NAME]
end

function ZF:CreatePositionController()
    local cooldownViewer = FindCooldownViewerFrame()
    if not cooldownViewer or not cooldownViewer:IsShown() then
        ZF:PrettyPrint("|cFFFFD100Anchor Point|r was not found.")
        return
    end

    local anchor = CreateFrame("Frame", "ZF_CDMAnchor", UIParent)
    anchor:SetAllPoints(cooldownViewer)
    anchor:SetSize(cooldownViewer:GetWidth() or 300, cooldownViewer:GetHeight() or 48)
end
