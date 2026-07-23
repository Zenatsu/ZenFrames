local _, RUF = ...

local function UpdateClassificationTexture(ClassificationIndicator, _, classification)
	local ClassificationIndicatorDB = RUF.db.profile.Units.target.Indicators.Classification
	local ClassificationTextures = RUF.ClassificationTextures[ClassificationIndicatorDB.Texture]
	if ClassificationIndicatorDB.Texture == "CLASSIFICATION0" or ClassificationIndicatorDB.Texture == "CLASSIFICATION1" then
		if ClassificationTextures[classification] then
			ClassificationIndicator:SetAtlas(ClassificationTextures[classification], false)
		end
	else
		if ClassificationTextures[classification] then
			ClassificationIndicator:SetTexture(ClassificationTextures[classification])
		end
	end
end

function RUF:CreateUnitClassificationIndicator(unitFrame, unit)
	local ClassificationIndicatorDB = RUF.db.profile.Units.target.Indicators.Classification
	local ClassificationIndicator = unitFrame.HighLevelContainer:CreateTexture(RUF:FetchFrameName(unit) .. "_ClassificationIndicator", "OVERLAY")
	ClassificationIndicator:SetSize(ClassificationIndicatorDB.Size, ClassificationIndicatorDB.Size)
	ClassificationIndicator:SetPoint(ClassificationIndicatorDB.Layout[1], unitFrame.HighLevelContainer, ClassificationIndicatorDB.Layout[2], ClassificationIndicatorDB.Layout[3], ClassificationIndicatorDB.Layout[4])
	ClassificationIndicator.PostUpdate = UpdateClassificationTexture

	if ClassificationIndicatorDB.Enabled then
		unitFrame.ClassificationIndicator = ClassificationIndicator
	else
		ClassificationIndicator:Hide()
	end

	return ClassificationIndicator
end

function RUF:UpdateUnitClassificationIndicator(unitFrame, unit)
	local ClassificationIndicatorDB = RUF.db.profile.Units.target.Indicators.Classification

	if ClassificationIndicatorDB.Enabled then
		unitFrame.ClassificationIndicator = unitFrame.ClassificationIndicator or RUF:CreateUnitClassificationIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("ClassificationIndicator") then unitFrame:EnableElement("ClassificationIndicator") end

		unitFrame.ClassificationIndicator:ClearAllPoints()
		unitFrame.ClassificationIndicator:SetSize(ClassificationIndicatorDB.Size, ClassificationIndicatorDB.Size)
		unitFrame.ClassificationIndicator:SetPoint(ClassificationIndicatorDB.Layout[1], unitFrame.HighLevelContainer, ClassificationIndicatorDB.Layout[2], ClassificationIndicatorDB.Layout[3], ClassificationIndicatorDB.Layout[4])
		unitFrame.ClassificationIndicator:ForceUpdate()
	elseif unitFrame.ClassificationIndicator then
		if unitFrame:IsElementEnabled("ClassificationIndicator") then unitFrame:DisableElement("ClassificationIndicator") end
		unitFrame.ClassificationIndicator:Hide()
		unitFrame.ClassificationIndicator = nil
	end
end
