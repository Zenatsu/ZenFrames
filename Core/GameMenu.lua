local _, RUF = ...

local function PositionGameMenuButton()
	if not GameMenuFrame or not GameMenuFrame.RUF then return end
	local height = GameMenuFrame:GetHeight()
	if GameMenuFrame.RUFAdjustedHeight == height then height = height - (GameMenuFrame.RUFAddedHeight or 0) end

	local anchorButton
	for button in GameMenuFrame.buttonPool:EnumerateActive() do
		local text = button:GetText()
		local point, relativeTo, relativePoint, offsetX, offsetY = button:GetPoint()
		if text and (text == LOGOUT or text == LOG_OUT or text == EXIT_GAME or text == RETURN_TO_GAME) then
			if point then
				button:ClearAllPoints()
				button:SetPoint(point, relativeTo, relativePoint, offsetX, (offsetY or 0) - 25)
			end
		else
			if text == MACROS then anchorButton = button end
			if point then
				button:ClearAllPoints()
				button:SetPoint(point, relativeTo, relativePoint, offsetX, (offsetY or 0) + 10)
			end
		end
	end
	if anchorButton then
		GameMenuFrame.RUF:ClearAllPoints()
		GameMenuFrame.RUF:SetPoint("TOPLEFT", anchorButton, "BOTTOMLEFT", 0, 0)
		GameMenuFrame.RUF:SetText(RUF.ADDON_NAME)
		GameMenuFrame.RUF:Show()
		GameMenuFrame.RUFAddedHeight = GameMenuFrame.RUF:GetHeight() + 10
		GameMenuFrame.RUFAdjustedHeight = height + GameMenuFrame.RUFAddedHeight
		GameMenuFrame:SetHeight(GameMenuFrame.RUFAdjustedHeight)
	else
		GameMenuFrame.RUFAddedHeight = 0
		GameMenuFrame.RUFAdjustedHeight = nil
		GameMenuFrame.RUF:Hide()
	end
end

local function OpenRUFConfig()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
	if not InCombatLockdown() then HideUIPanel(GameMenuFrame) end
	RUF:CreateGUI()
end

local function SetupGameMenu()
	if not GameMenuFrame or GameMenuFrame.RUF then return end
	local button = CreateFrame("Button", "RUF_GameMenuButton", GameMenuFrame, "MainMenuFrameButtonTemplate")
	button:SetSize(200, 35)
	button:SetScript("OnClick", OpenRUFConfig)
	GameMenuFrame.RUF = button
	hooksecurefunc(GameMenuFrame, "Layout", PositionGameMenuButton)
end

SetupGameMenu()

if not GameMenuFrame or not GameMenuFrame.RUF then
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("ADDON_LOADED")
	eventFrame:SetScript("OnEvent", function(self, _, addonName)
		if addonName ~= "Blizzard_GameMenu" then return end
		SetupGameMenu()
		if GameMenuFrame and GameMenuFrame.RUF then self:UnregisterAllEvents() end
	end)
end
