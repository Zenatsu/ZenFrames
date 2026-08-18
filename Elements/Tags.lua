local _, ZF = ...

local function ApplyTagStyle(fontString, parent, TagDB, GeneralDB)
	ZF:ApplyFontStringStyle(fontString, ZF.Media.Font, TagDB.FontSize, GeneralDB.Fonts.FontFlag, TagDB.Color, GeneralDB.Fonts.Shadow)
	fontString:ClearAllPoints()
	fontString:SetPoint(TagDB.Layout[1], parent, TagDB.Layout[2], TagDB.Layout[3], TagDB.Layout[4])
	fontString:SetJustifyH(ZF:SetJustification(TagDB.Layout[1]))
	if TagDB.Layout[1] == "TOPLEFT" or TagDB.Layout[1] == "TOP" or TagDB.Layout[1] == "TOPRIGHT" then
		fontString:SetJustifyV("TOP")
	elseif TagDB.Layout[1] == "BOTTOMLEFT" or TagDB.Layout[1] == "BOTTOM" or TagDB.Layout[1] == "BOTTOMRIGHT" then
		fontString:SetJustifyV("BOTTOM")
	else
		fontString:SetJustifyV("MIDDLE")
	end
end

local function ApplyTagBinding(unitFrame, fontString, unit, TagDB)
	if TagDB.Tag and string.find(TagDB.Tag, ":target", 1, true) then
		unitFrame:Tag(fontString, TagDB.Tag, (unit == "partyplayer" and "player" or unit) .. "target")
	else
		unitFrame:Tag(fontString, TagDB.Tag)
	end
	fontString.ZFTagString = TagDB.Tag
	fontString.ZFTagUnit = unit
end

local function CreateUnitTag(unitFrame, unit, tagDB)
	local GeneralDB = ZF.db.profile.General
	local TagDB = ZF:GetUnitDB(unitFrame, unit).Tags[tagDB]

	if not unitFrame.Tags[tagDB] then
		unitFrame.Tags[tagDB] = unitFrame.HighLevelContainer:CreateFontString(ZF:FetchFrameName(unit) .. "_" .. tagDB, "ARTWORK", "GameFontNormal")
		ApplyTagStyle(unitFrame.Tags[tagDB], unitFrame.HighLevelContainer, TagDB, GeneralDB)
		ApplyTagBinding(unitFrame, unitFrame.Tags[tagDB], unit, TagDB)
	end
end

function ZF:UpdateUnitTag(unitFrame, unit, tagDB)
	local GeneralDB = ZF.db.profile.General
	local TagDB = ZF:GetUnitDB(unitFrame, unit).Tags[tagDB]

	if not unitFrame.Tags[tagDB] then CreateUnitTag(unitFrame, unit, tagDB) end
	if not unitFrame.Tags[tagDB] then return end

	ApplyTagStyle(unitFrame.Tags[tagDB], unitFrame.HighLevelContainer, TagDB, GeneralDB)
	if unitFrame.Tags[tagDB].ZFTagString ~= TagDB.Tag or unitFrame.Tags[tagDB].ZFTagUnit ~= unit then
		unitFrame.Tags[tagDB].extraUnits = nil
		ApplyTagBinding(unitFrame, unitFrame.Tags[tagDB], unit, TagDB)
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
