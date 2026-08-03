local _, ZF = ...

local function CreateUnitTag(unitFrame, unit, tagDB)
	local GeneralDB = ZF.db.profile.General
	local TagDB = ZF:GetUnitDB(unitFrame, unit).Tags[tagDB]

	if not unitFrame.Tags[tagDB] then
		unitFrame.Tags[tagDB] = unitFrame.HighLevelContainer:CreateFontString(ZF:FetchFrameName(unit) .. "_" .. tagDB, "ARTWORK", "GameFontNormal")
		ZF:ApplyFontStringStyle(unitFrame.Tags[tagDB], ZF.Media.Font, TagDB.FontSize, GeneralDB.Fonts.FontFlag, TagDB.Color, GeneralDB.Fonts.Shadow)
		unitFrame.Tags[tagDB]:SetPoint(TagDB.Layout[1], unitFrame.HighLevelContainer, TagDB.Layout[2], TagDB.Layout[3], TagDB.Layout[4])
		unitFrame.Tags[tagDB]:SetJustifyH(ZF:SetJustification(TagDB.Layout[1]))
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
		unitFrame.Tags[tagDB].ZFTagString = TagDB.Tag
		unitFrame.Tags[tagDB].ZFTagUnit = unit
	end
end

function ZF:UpdateUnitTag(unitFrame, unit, tagDB)
	local GeneralDB = ZF.db.profile.General
	local TagDB = ZF:GetUnitDB(unitFrame, unit).Tags[tagDB]

	if not unitFrame.Tags[tagDB] then CreateUnitTag(unitFrame, unit, tagDB) end
	if not unitFrame.Tags[tagDB] then return end

	ZF:ApplyFontStringStyle(unitFrame.Tags[tagDB], ZF.Media.Font, TagDB.FontSize, GeneralDB.Fonts.FontFlag, TagDB.Color, GeneralDB.Fonts.Shadow)
	unitFrame.Tags[tagDB]:ClearAllPoints()
	unitFrame.Tags[tagDB]:SetPoint(TagDB.Layout[1], unitFrame.HighLevelContainer, TagDB.Layout[2], TagDB.Layout[3], TagDB.Layout[4])
	unitFrame.Tags[tagDB]:SetJustifyH(ZF:SetJustification(TagDB.Layout[1]))
	if TagDB.Layout[1] == "TOPLEFT" or TagDB.Layout[1] == "TOP" or TagDB.Layout[1] == "TOPRIGHT" then
		unitFrame.Tags[tagDB]:SetJustifyV("TOP")
	elseif TagDB.Layout[1] == "BOTTOMLEFT" or TagDB.Layout[1] == "BOTTOM" or TagDB.Layout[1] == "BOTTOMRIGHT" then
		unitFrame.Tags[tagDB]:SetJustifyV("BOTTOM")
	else
		unitFrame.Tags[tagDB]:SetJustifyV("MIDDLE")
	end
	if unitFrame.Tags[tagDB].ZFTagString ~= TagDB.Tag or unitFrame.Tags[tagDB].ZFTagUnit ~= unit then
		unitFrame.Tags[tagDB].extraUnits = nil
		if TagDB.Tag and string.find(TagDB.Tag, ":target", 1, true) then
			unitFrame:Tag(unitFrame.Tags[tagDB], TagDB.Tag, (unit == "partyplayer" and "player" or unit) .. "target")
		else
			unitFrame:Tag(unitFrame.Tags[tagDB], TagDB.Tag)
		end
		unitFrame.Tags[tagDB].ZFTagString = TagDB.Tag
		unitFrame.Tags[tagDB].ZFTagUnit = unit
	end
	unitFrame.Tags[tagDB]:UpdateTag()
end

function ZF:CreateUnitTags(unitFrame, unit)
    unitFrame.Tags = unitFrame.Tags or {}
    for tagName, _ in pairs(ZF:GetUnitDB(unitFrame, unit).Tags) do
        CreateUnitTag(unitFrame, unit, tagName)
    end
end

function ZF:UpdateUnitTags(unit, tagName)
	if not unit then return end
	local UnitDB = ZF:GetUnitDB(nil, unit)
	if not UnitDB or not UnitDB.Tags then return end
	ZF.SEPARATOR = ZF.db.profile.General.Separator or "||"
	ZF.TOT_SEPARATOR = ZF.db.profile.General.ToTSeparator or "»"

	local function UpdateFrameTags(unitFrame, frameUnit)
		if not unitFrame then return end
		if tagName then
			ZF:UpdateUnitTag(unitFrame, frameUnit, tagName)
		else
			for configuredTag in pairs(UnitDB.Tags) do ZF:UpdateUnitTag(unitFrame, frameUnit, configuredTag) end
		end
	end

	if unit == "boss" then
		for i = 1, ZF.MAX_BOSS_FRAMES do UpdateFrameTags(ZF["BOSS" .. i], "boss" .. i) end
	elseif unit == "party" then
		for i = 1, ZF.MAX_PARTY_FRAMES do UpdateFrameTags(ZF["PARTY" .. i], "party" .. i) end
		UpdateFrameTags(ZF.PARTYPLAYER, "partyplayer")
	elseif unit == "raid" then
		ZF:ForEachRaidFrame(UpdateFrameTags, true)
	elseif unit == "augmentation" then
		ZF:ForEachAugmentationRaidFrame(UpdateFrameTags, false)
	else
		UpdateFrameTags(ZF[unit:upper()], unit)
	end
end
