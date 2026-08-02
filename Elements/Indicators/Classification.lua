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
	local ClassificationIndicator = RUF:CreateIndicatorTexture(unitFrame, unit, "_ClassificationIndicator", ClassificationIndicatorDB.Size, ClassificationIndicatorDB.Layout)
	ClassificationIndicator.PostUpdate = UpdateClassificationTexture

	if ClassificationIndicatorDB.Enabled then
		unitFrame.ClassificationIndicator = ClassificationIndicator
	else
		RUF:DisableIndicatorElement(unitFrame, "ClassificationIndicator", ClassificationIndicator)
	end

	return ClassificationIndicator
end

function RUF:UpdateUnitClassificationIndicator(unitFrame, unit)
	local ClassificationIndicatorDB = RUF.db.profile.Units.target.Indicators.Classification

	if ClassificationIndicatorDB.Enabled then
		unitFrame.ClassificationIndicator = unitFrame.ClassificationIndicator or RUF:CreateUnitClassificationIndicator(unitFrame, unit)
		if not unitFrame:IsElementEnabled("ClassificationIndicator") then unitFrame:EnableElement("ClassificationIndicator") end

		RUF:PositionIndicatorTexture(unitFrame.ClassificationIndicator, unitFrame.HighLevelContainer, ClassificationIndicatorDB.Size, ClassificationIndicatorDB.Layout)
		unitFrame.ClassificationIndicator:ForceUpdate()
	elseif unitFrame.ClassificationIndicator then
		RUF:DisableIndicatorElement(unitFrame, "ClassificationIndicator", unitFrame.ClassificationIndicator)
		unitFrame.ClassificationIndicator = nil
	end
end
