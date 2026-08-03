local _, ZF = ...

local totemPriorities = STANDARD_TOTEM_PRIORITIES
if UnitClassBase("player") == "SHAMAN" then totemPriorities = SHAMAN_TOTEM_PRIORITIES end

-- Shared by both the initial layout (CreateUnitTotems) and every later
-- reposition (UpdateUnitTotems) - growth direction just mirrors the offset.
local function PositionTotem(totem, TotemsDB, index, parent)
    local xOffset = (index - 1) * (TotemsDB.Size + TotemsDB.Layout[5])
    if TotemsDB.GrowthDirection == "LEFT" then xOffset = -xOffset end
    totem:ClearAllPoints()
    totem:SetSize(TotemsDB.Size, TotemsDB.Size)
    totem:SetPoint(TotemsDB.Layout[1], parent, TotemsDB.Layout[2], TotemsDB.Layout[3] + xOffset, TotemsDB.Layout[4])
end

local function CreateTotemButton(unitFrame, unit, index)
    local totem = CreateFrame("Button", ZF:FetchFrameName(unit) .. "_Totem" .. index, unitFrame, "SecureActionButtonTemplate")
    totem:RegisterForClicks("RightButtonUp", "RightButtonDown")
    totem:SetAttribute("type2", "destroytotem")
    totem:SetAttribute("typerelease2", "destroytotem")
    totem:SetAlpha(0)

    totem.Border = totem:CreateTexture(nil, "BACKGROUND")
    totem.Border:SetAllPoints()
    totem.Border:SetColorTexture(0, 0, 0, 1)

    totem.Icon = totem:CreateTexture(nil, "OVERLAY")
    totem.Icon:SetPoint("TOPLEFT", totem, "TOPLEFT", 1, -1)
    totem.Icon:SetPoint("BOTTOMRIGHT", totem, "BOTTOMRIGHT", -1, 1)
    totem.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    totem.Cooldown = CreateFrame("Cooldown", nil, totem, "CooldownFrameTemplate")
    totem.Cooldown:SetPoint("TOPLEFT", totem, "TOPLEFT", 1, -1)
    totem.Cooldown:SetPoint("BOTTOMRIGHT", totem, "BOTTOMRIGHT", -1, 1)
    totem.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    totem.Cooldown:SetDrawEdge(false)
    totem.Cooldown:SetDrawSwipe(true)
    totem.Cooldown:SetHideCountdownNumbers(false)
    totem.Cooldown:SetReverse(true)
    ZF:ApplyCooldownText(totem.Cooldown)

    return totem
end

function ZF:CreateUnitTotems(unitFrame, unit)
    if unit ~= "player" then return end
    local TotemsDB = ZF.db.profile.Units.player.Indicators.Totems
    if not TotemsDB.Enabled then return end

    local totems = {}
    for index = 1, #totemPriorities do
        local totem = CreateTotemButton(unitFrame, unit, index)
        PositionTotem(totem, TotemsDB, index, unitFrame.HighLevelContainer)
        totems[index] = totem
    end

    for slot = 1, #totemPriorities do
        totems[totemPriorities[slot]]:SetAttribute("totem-slot2", slot)
        totems[totemPriorities[slot]]:SetAttribute("totem-slot", slot)
    end

    totems.PostUpdate = function(self, slot)
        ZF:ApplyCooldownText(self[totemPriorities[slot]].Cooldown)
    end

    unitFrame.Totems = totems
    return totems
end

function ZF:UpdateUnitTotems(unitFrame, unit)
    if unit ~= "player" then return end
    local TotemsDB = ZF.db.profile.Units.player.Indicators.Totems

    if TotemsDB.Enabled then
        unitFrame.Totems = unitFrame.Totems or ZF:CreateUnitTotems(unitFrame, unit)
        if not unitFrame.Totems then return end

        for index = 1, #unitFrame.Totems do
            local totem = unitFrame.Totems[index]
            PositionTotem(totem, TotemsDB, index, unitFrame.HighLevelContainer)
            ZF:ApplyCooldownText(totem.Cooldown)
            totem:Show()
        end

        if not unitFrame:IsElementEnabled("Totems") then unitFrame:EnableElement("Totems") end
        if unitFrame.Totems.ForceUpdate then unitFrame.Totems:ForceUpdate() end
    else
        if not unitFrame.Totems then return end
        if unitFrame:IsElementEnabled("Totems") then unitFrame:DisableElement("Totems") end
        for index = 1, #unitFrame.Totems do
            unitFrame.Totems[index]:Hide()
        end
    end
end
