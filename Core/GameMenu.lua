local _, ZF = ...

local LOGOUT_BUTTON_TEXTS = {
    [LOGOUT] = true,
    [LOG_OUT] = true,
    [EXIT_GAME] = true,
    [RETURN_TO_GAME] = true,
}

local function ShiftButtonPoint(button, yOffset)
    local point, relativeTo, relativePoint, offsetX, offsetY = button:GetPoint()
    if not point then return end
    button:ClearAllPoints()
    button:SetPoint(point, relativeTo, relativePoint, offsetX, (offsetY or 0) + yOffset)
end

local function RepositionGameMenu()
    if not GameMenuFrame or not GameMenuFrame.ZF then return end
    local menuHeight = GameMenuFrame:GetHeight()
    if GameMenuFrame.ZFAdjustedHeight == menuHeight then
        menuHeight = menuHeight - (GameMenuFrame.ZFAddedHeight or 0)
    end

    local anchorButton
    for button in GameMenuFrame.buttonPool:EnumerateActive() do
        local text = button:GetText()
        if LOGOUT_BUTTON_TEXTS[text] then
            ShiftButtonPoint(button, -25)
        else
            if text == MACROS then anchorButton = button end
            ShiftButtonPoint(button, 10)
        end
    end

    if not anchorButton then
        GameMenuFrame.ZFAddedHeight = 0
        GameMenuFrame.ZFAdjustedHeight = nil
        GameMenuFrame.ZF:Hide()
        return
    end

    GameMenuFrame.ZF:ClearAllPoints()
    GameMenuFrame.ZF:SetPoint("TOPLEFT", anchorButton, "BOTTOMLEFT", 0, 0)
    GameMenuFrame.ZF:SetText(ZF.ADDON_NAME)
    GameMenuFrame.ZF:Show()
    GameMenuFrame.ZFAddedHeight = GameMenuFrame.ZF:GetHeight() + 10
    GameMenuFrame.ZFAdjustedHeight = menuHeight + GameMenuFrame.ZFAddedHeight
    GameMenuFrame:SetHeight(GameMenuFrame.ZFAdjustedHeight)
end

local function OpenZFConfig()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
    if not InCombatLockdown() then HideUIPanel(GameMenuFrame) end
    ZF:CreateGUI()
end

-- Returns true once GameMenuFrame.ZF exists, whether that happened just
-- now or on a previous call - lets the caller below decide whether it still
-- needs to wait for Blizzard_GameMenu to load.
local function InstallGameMenuButton()
    if not GameMenuFrame then return false end
    if GameMenuFrame.ZF then return true end

    local button = CreateFrame("Button", "ZF_GameMenuButton", GameMenuFrame, "MainMenuFrameButtonTemplate")
    button:SetSize(200, 35)
    button:SetScript("OnClick", OpenZFConfig)
    GameMenuFrame.ZF = button
    hooksecurefunc(GameMenuFrame, "Layout", RepositionGameMenu)
    return true
end

if not InstallGameMenuButton() then
    local loadWatcher = CreateFrame("Frame")
    loadWatcher:RegisterEvent("ADDON_LOADED")
    loadWatcher:SetScript("OnEvent", function(self, _, addonName)
        if addonName ~= "Blizzard_GameMenu" then return end
        if InstallGameMenuButton() then self:UnregisterAllEvents() end
    end)
end
