local _, ZF = ...

-- The "CLASSIFICATION0"/"CLASSIFICATION1" texture sets are Blizzard atlases;
-- every other set is a plain file-path texture, so the two need different
-- setter calls even though they're keyed the same way.
local function UpdateClassificationTexture(ClassificationIndicator, _, classification)
    local ClassificationIndicatorDB = ZF.db.profile.Units.target.Indicators.Classification
    local texture = ZF.ClassificationTextures[ClassificationIndicatorDB.Texture][classification]
    if not texture then return end

    local usesAtlas = ClassificationIndicatorDB.Texture == "CLASSIFICATION0" or ClassificationIndicatorDB.Texture == "CLASSIFICATION1"
    if usesAtlas then
        ClassificationIndicator:SetAtlas(texture, false)
    else
        ClassificationIndicator:SetTexture(texture)
    end
end

function ZF:CreateUnitClassificationIndicator(unitFrame, unit)
    local ClassificationIndicatorDB = ZF.db.profile.Units.target.Indicators.Classification
    local ClassificationIndicator = ZF:CreateIndicatorTexture(unitFrame, unit, "_ClassificationIndicator", ClassificationIndicatorDB.Size, ClassificationIndicatorDB.Layout)
    ClassificationIndicator.PostUpdate = UpdateClassificationTexture

    if ClassificationIndicatorDB.Enabled then
        unitFrame.ClassificationIndicator = ClassificationIndicator
    else
        ZF:DisableIndicatorElement(unitFrame, "ClassificationIndicator", ClassificationIndicator)
    end

    return ClassificationIndicator
end

function ZF:UpdateUnitClassificationIndicator(unitFrame, unit)
    local ClassificationIndicatorDB = ZF.db.profile.Units.target.Indicators.Classification

    if ClassificationIndicatorDB.Enabled then
        unitFrame.ClassificationIndicator = unitFrame.ClassificationIndicator or ZF:CreateUnitClassificationIndicator(unitFrame, unit)
        if not unitFrame:IsElementEnabled("ClassificationIndicator") then unitFrame:EnableElement("ClassificationIndicator") end

        ZF:PositionIndicatorTexture(unitFrame.ClassificationIndicator, unitFrame.HighLevelContainer, ClassificationIndicatorDB.Size, ClassificationIndicatorDB.Layout)
        unitFrame.ClassificationIndicator:ForceUpdate()
    elseif unitFrame.ClassificationIndicator then
        ZF:DisableIndicatorElement(unitFrame, "ClassificationIndicator", unitFrame.ClassificationIndicator)
        unitFrame.ClassificationIndicator = nil
    end
end
