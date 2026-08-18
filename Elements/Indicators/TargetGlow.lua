local _, ZF = ...
ZF.TargetHighlightEvtFrames = {}

local unitIsTargetEvtFrame = CreateFrame("Frame")
unitIsTargetEvtFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
unitIsTargetEvtFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
unitIsTargetEvtFrame:RegisterEvent("UNIT_TARGET")
unitIsTargetEvtFrame:SetScript("OnEvent", function(_, event, eventUnit)
	local changedUnit = eventUnit and eventUnit .. "target"
	for frame, unit in pairs(ZF.TargetHighlightEvtFrames) do
		local unitChanged = event == "PLAYER_TARGET_CHANGED" or (event == "PLAYER_FOCUS_CHANGED" and (unit == "focus" or unit == "focustarget")) or unit == changedUnit
		if unitChanged and frame.TargetIndicatorDB.Enabled then ZF:UpdateTargetGlowIndicator(frame, unit) end
	end
end)

function ZF:CreateUnitTargetGlowIndicator(unitFrame, unit)
    local UnitDB = ZF:GetUnitDB(unitFrame, unit)
    local TargetIndicatorDB = UnitDB.Indicators.Target
    if TargetIndicatorDB then
        unitFrame.TargetIndicatorDB = TargetIndicatorDB
        unitFrame.TargetGlowFrameDB = UnitDB.Frame
        if TargetIndicatorDB.Style == "Border" then -- shown as "Outline" in UI until I can figure out a safe way to change the DB without breaking profiles
            unitFrame.TargetIndicator = unitFrame.ContainerBorder
        else
            local t = TargetIndicatorDB.BorderThickness
            unitFrame.TargetIndicatorFrame = CreateFrame("Frame", ZF:FetchFrameName(unit).."_TargetIndicator", unitFrame.Container, "BackdropTemplate")
            unitFrame.TargetIndicator = unitFrame.TargetIndicatorFrame
            unitFrame.TargetIndicatorFrame:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 3)
            unitFrame.TargetIndicatorFrame:SetBackdropColor(0, 0, 0, 0)
            unitFrame.TargetIndicator:SetBackdrop({ edgeFile = ZF.Media.Solid, edgeSize = t, insets = {left = -t, right = -t, top = -t, bottom = -t} })
            unitFrame.TargetIndicator:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", -t, t)
            unitFrame.TargetIndicator:SetPoint("BOTTOMRIGHT", unitFrame.Container, "BOTTOMRIGHT", t, -t)
            unitFrame.TargetIndicator:SetBackdropBorderColor(TargetIndicatorDB.Color[1], TargetIndicatorDB.Color[2], TargetIndicatorDB.Color[3], TargetIndicatorDB.Color[4])
            unitFrame.TargetIndicator:SetAlpha(0)
        end
    end
end

function ZF:UpdateUnitTargetGlowIndicator(unitFrame, unit)
    local TargetIndicatorDB = ZF:GetUnitDB(unitFrame, unit).Indicators.Target
    if unitFrame and TargetIndicatorDB then
        unitFrame.TargetIndicatorDB = TargetIndicatorDB
        unitFrame.TargetGlowFrameDB = ZF:GetUnitDB(unitFrame, unit).Frame
        if unitFrame.TargetIndicator and unitFrame.TargetIndicator ~= unitFrame.ContainerBorder then unitFrame.TargetIndicator:SetAlpha(0) end
        if TargetIndicatorDB.Style == "Border" then -- shown as "Outline" in UI until I can figure out a safe way to change the DB without breaking profiles
            unitFrame.TargetIndicator = unitFrame.ContainerBorder
            ZF:UpdateTargetGlowIndicator(unitFrame, unit)
            return
        end

        if not unitFrame.TargetIndicatorFrame then
            unitFrame.TargetIndicatorFrame = CreateFrame("Frame", ZF:FetchFrameName(unit).."_TargetIndicator", unitFrame.Container, "BackdropTemplate")
            unitFrame.TargetIndicatorFrame:SetFrameLevel(unitFrame.Container:GetFrameLevel() + 3)
        end
        unitFrame.TargetIndicator = unitFrame.TargetIndicatorFrame
        local t = TargetIndicatorDB.BorderThickness
        unitFrame.TargetIndicator:ClearAllPoints()
        unitFrame.TargetIndicator:SetBackdropColor(0, 0, 0, 0)
        unitFrame.TargetIndicator:SetBackdrop({ edgeFile = ZF.Media.Solid, edgeSize = t, insets = {left = -t, right = -t, top = -t, bottom = -t} })
        unitFrame.TargetIndicator:SetPoint("TOPLEFT", unitFrame.Container, "TOPLEFT", -t, t)
        unitFrame.TargetIndicator:SetPoint("BOTTOMRIGHT", unitFrame.Container, "BOTTOMRIGHT", t, -t)
        unitFrame.TargetIndicator:SetBackdropBorderColor(TargetIndicatorDB.Color[1], TargetIndicatorDB.Color[2], TargetIndicatorDB.Color[3], TargetIndicatorDB.Color[4])
        ZF:UpdateTargetGlowIndicator(unitFrame, unit)
    end
end

function ZF:UpdateTargetGlowIndicator(unitFrame, unit)
    if unitFrame and unitFrame.TargetIndicator then
        local TargetIndicatorDB = unitFrame.TargetIndicatorDB
        local FrameDB = unitFrame.TargetGlowFrameDB
        local baseAlpha = FrameDB.BorderThickness > 0 and FrameDB.BorderOpacity or 0
        if TargetIndicatorDB.Style == "Border" then
            local isTarget = TargetIndicatorDB.Enabled and UnitIsUnit("target", unit == "partyplayer" and "player" or unit)
            unitFrame.ContainerBorder:SetBackdropBorderColor(isTarget and TargetIndicatorDB.Color[1] or FrameDB.BorderColor[1], isTarget and TargetIndicatorDB.Color[2] or FrameDB.BorderColor[2], isTarget and TargetIndicatorDB.Color[3] or FrameDB.BorderColor[3], isTarget and (TargetIndicatorDB.Color[4] or 1) or baseAlpha)
        else
            unitFrame.ContainerBorder:SetBackdropBorderColor(FrameDB.BorderColor[1], FrameDB.BorderColor[2], FrameDB.BorderColor[3], baseAlpha)
            if TargetIndicatorDB.Enabled then
                unitFrame.TargetIndicator:SetAlphaFromBoolean(UnitIsUnit("target", unit == "partyplayer" and "player" or unit), 1, 0)
            else
                unitFrame.TargetIndicator:SetAlpha(0)
            end
        end
    end
end

function ZF:RegisterTargetGlowIndicatorFrame(frameName, unit)
	if not unit or not frameName then return end
	local unitFrame = type(frameName) == "table" and frameName or _G[frameName]
	local DB = ZF:GetUnitDB(unitFrame, unit)
	if not unitFrame or not DB or not DB.Indicators.Target then return end
	if DB.Indicators.Target.Enabled then
		ZF.TargetHighlightEvtFrames[unitFrame] = unit
		ZF:UpdateTargetGlowIndicator(unitFrame, unit)
	else
		ZF.TargetHighlightEvtFrames[unitFrame] = nil
		if unitFrame.TargetIndicator == unitFrame.ContainerBorder then
			local FrameDB = DB.Frame
			unitFrame.ContainerBorder:SetBackdropBorderColor(FrameDB.BorderColor[1], FrameDB.BorderColor[2], FrameDB.BorderColor[3], FrameDB.BorderThickness > 0 and FrameDB.BorderOpacity or 0)
		elseif unitFrame.TargetIndicator then
			unitFrame.TargetIndicator:SetAlpha(0)
		end
	end
end

function ZF:UnregisterTargetGlowIndicatorFrame(unitFrame)
	if unitFrame then ZF.TargetHighlightEvtFrames[unitFrame] = nil end
end
