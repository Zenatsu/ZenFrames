local _, ZF = ...
ZF.TargetHighlightEvtFrames = {}
local trackedUnits
local function IsTrackedUnit(unit)
	if not trackedUnits then
		trackedUnits = {}
		for _, frameUnit in pairs(ZF.TargetHighlightEvtFrames) do trackedUnits[frameUnit] = true end
	end
	return trackedUnits[unit]
end

local function SetTrackedFrame(unitFrame, unit)
	if ZF.TargetHighlightEvtFrames[unitFrame] == unit then return end
	ZF.TargetHighlightEvtFrames[unitFrame] = unit
	trackedUnits = nil
end

local unitIsTargetEvtFrame = CreateFrame("Frame")
unitIsTargetEvtFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
unitIsTargetEvtFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
unitIsTargetEvtFrame:RegisterEvent("UNIT_TARGET")
unitIsTargetEvtFrame:SetScript("OnEvent", function(_, event, eventUnit)
	local changedUnit = eventUnit and eventUnit .. "target"
	if event == "UNIT_TARGET" and not IsTrackedUnit(changedUnit) then return end
	for frame, unit in pairs(ZF.TargetHighlightEvtFrames) do
		local unitChanged = event == "PLAYER_TARGET_CHANGED" or (event == "PLAYER_FOCUS_CHANGED" and (unit == "focus" or unit == "focustarget")) or unit == changedUnit
		if unitChanged and frame.TargetIndicatorDB.Enabled then ZF:UpdateTargetGlowIndicator(frame, unit) end
	end
end)

function ZF:CreateUnitTargetGlowIndicator(unitFrame, unit)
    ZF:UpdateUnitTargetGlowIndicator(unitFrame, unit)
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
        unitFrame.TargetIndicator:ClearAllPoints()
        unitFrame.TargetIndicator:SetBackdropColor(0, 0, 0, 0)
        ZF:ApplyOutsetBorder(unitFrame.TargetIndicator, unitFrame.Container, TargetIndicatorDB.BorderThickness, ZF.Media.Solid)
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
		SetTrackedFrame(unitFrame, unit)
		ZF:UpdateTargetGlowIndicator(unitFrame, unit)
	else
		SetTrackedFrame(unitFrame, nil)
		if unitFrame.TargetIndicator == unitFrame.ContainerBorder then
			local FrameDB = DB.Frame
			unitFrame.ContainerBorder:SetBackdropBorderColor(ZF:GetBorderColor(FrameDB))
		elseif unitFrame.TargetIndicator then
			unitFrame.TargetIndicator:SetAlpha(0)
		end
	end
end

function ZF:UnregisterTargetGlowIndicatorFrame(unitFrame)
	if unitFrame then SetTrackedFrame(unitFrame, nil) end
end
