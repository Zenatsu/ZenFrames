local _, RUF = ...

local function CreateUnitTag(unitFrame, unit, tagDB)
	local GeneralDB = RUF.db.profile.General
	local TagDB = RUF:GetUnitDB(unitFrame, unit).Tags[tagDB]

	if not unitFrame.Tags[tagDB] then
		unitFrame.Tags[tagDB] = unitFrame.HighLevelContainer:CreateFontString(RUF:FetchFrameName(unit) .. "_" .. tagDB, "ARTWORK", "GameFontNormal")
		RUF:ApplyFontStringStyle(unitFrame.Tags[tagDB], RUF.Media.Font, TagDB.FontSize, GeneralDB.Fonts.FontFlag, TagDB.Color, GeneralDB.Fonts.Shadow)
		unitFrame.Tags[tagDB]:SetPoint(TagDB.Layout[1], unitFrame.HighLevelContainer, TagDB.Layout[2], TagDB.Layout[3], TagDB.Layout[4])
		unitFrame.Tags[tagDB]:SetJustifyH(RUF:SetJustification(TagDB.Layout[1]))
		if TagDB.Layout[1] == "TOPLEFT" or TagDB.Layout[1] == "TOP" or TagDB.Layout[1] == "TOPRIGHT" then
			unitFrame.Tags[tagDB]:SetJustifyV("TOP")
		elseif TagDB.Layout[1] == "BOTTOMLEFT" or TagDB.Layout[1] == "BOTTOM" or TagDB.Layout[1] == "BOTTOMRIGHT" then
			unitFrame.Tags[tagDB]:SetJustifyV("BOTTOM")
		else
			unitFrame.Tags[tagDB]:SetJustifyV("MIDDLE")
		end
		if TagDB.Tag and string.find(TagDB.Tag, ":target", 1, true) then
			unitFrame:Tag(unitFrame.Tags[tagDB], TagDB.Tag, (unit == "partyplayer" and "player" or unit) .. "target")
		else
			unitFrame:Tag(unitFrame.Tags[tagDB], TagDB.Tag)
		end
		unitFrame.Tags[tagDB].RUFTagString = TagDB.Tag
		unitFrame.Tags[tagDB].RUFTagUnit = unit
	end
end

function RUF:UpdateUnitTag(unitFrame, unit, tagDB)
	local GeneralDB = RUF.db.profile.General
	local TagDB = RUF:GetUnitDB(unitFrame, unit).Tags[tagDB]

	if not unitFrame.Tags[tagDB] then CreateUnitTag(unitFrame, unit, tagDB) end
	if not unitFrame.Tags[tagDB] then return end

	RUF:ApplyFontStringStyle(unitFrame.Tags[tagDB], RUF.Media.Font, TagDB.FontSize, GeneralDB.Fonts.FontFlag, TagDB.Color, GeneralDB.Fonts.Shadow)
	unitFrame.Tags[tagDB]:ClearAllPoints()
	unitFrame.Tags[tagDB]:SetPoint(TagDB.Layout[1], unitFrame.HighLevelContainer, TagDB.Layout[2], TagDB.Layout[3], TagDB.Layout[4])
	unitFrame.Tags[tagDB]:SetJustifyH(RUF:SetJustification(TagDB.Layout[1]))
	if TagDB.Layout[1] == "TOPLEFT" or TagDB.Layout[1] == "TOP" or TagDB.Layout[1] == "TOPRIGHT" then
		unitFrame.Tags[tagDB]:SetJustifyV("TOP")
	elseif TagDB.Layout[1] == "BOTTOMLEFT" or TagDB.Layout[1] == "BOTTOM" or TagDB.Layout[1] == "BOTTOMRIGHT" then
		unitFrame.Tags[tagDB]:SetJustifyV("BOTTOM")
	else
		unitFrame.Tags[tagDB]:SetJustifyV("MIDDLE")
	end
	if unitFrame.Tags[tagDB].RUFTagString ~= TagDB.Tag or unitFrame.Tags[tagDB].RUFTagUnit ~= unit then
		unitFrame.Tags[tagDB].extraUnits = nil
		if TagDB.Tag and string.find(TagDB.Tag, ":target", 1, true) then
			unitFrame:Tag(unitFrame.Tags[tagDB], TagDB.Tag, (unit == "partyplayer" and "player" or unit) .. "target")
		else
			unitFrame:Tag(unitFrame.Tags[tagDB], TagDB.Tag)
		end
		unitFrame.Tags[tagDB].RUFTagString = TagDB.Tag
		unitFrame.Tags[tagDB].RUFTagUnit = unit
	end
	unitFrame.Tags[tagDB]:UpdateTag()
end

function RUF:CreateUnitTags(unitFrame, unit)
    unitFrame.Tags = unitFrame.Tags or {}
    for tagName, _ in pairs(RUF:GetUnitDB(unitFrame, unit).Tags) do
        CreateUnitTag(unitFrame, unit, tagName)
    end
end

function RUF:UpdateUnitTags(unit, tagName)
	if not unit then return end
	local UnitDB = RUF:GetUnitDB(nil, unit)
	if not UnitDB or not UnitDB.Tags then return end
	RUF.SEPARATOR = RUF.db.profile.General.Separator or "||"
	RUF.TOT_SEPARATOR = RUF.db.profile.General.ToTSeparator or "»"

	local function UpdateFrameTags(unitFrame, frameUnit)
		if not unitFrame then return end
		if tagName then
			RUF:UpdateUnitTag(unitFrame, frameUnit, tagName)
		else
			for configuredTag in pairs(UnitDB.Tags) do RUF:UpdateUnitTag(unitFrame, frameUnit, configuredTag) end
		end
	end

	if unit == "boss" then
		for i = 1, RUF.MAX_BOSS_FRAMES do UpdateFrameTags(RUF["BOSS" .. i], "boss" .. i) end
	elseif unit == "party" then
		for i = 1, RUF.MAX_PARTY_FRAMES do UpdateFrameTags(RUF["PARTY" .. i], "party" .. i) end
		UpdateFrameTags(RUF.PARTYPLAYER, "partyplayer")
	elseif unit == "raid" then
		RUF:ForEachRaidFrame(UpdateFrameTags, true)
	elseif unit == "augmentation" then
		RUF:ForEachAugmentationRaidFrame(UpdateFrameTags, false)
	else
		UpdateFrameTags(RUF[unit:upper()], unit)
	end
end
