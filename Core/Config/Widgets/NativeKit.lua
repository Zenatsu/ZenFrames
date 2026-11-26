local _, ZF = ...
local NATIVE = ZF.DesignerStyle.Native

local Kit = {}
ZF.NativeKit = Kit

local templateExists = {}

function Kit.TemplateExists(name)
    if templateExists[name] == nil then
        local ok, info = pcall(C_XMLUtil.GetTemplateInfo, name)
        templateExists[name] = ok and info ~= nil
    end
    return templateExists[name]
end

function Kit.FirstTemplate(...)
    for index = 1, select("#", ...) do
        local name = select(index, ...)
        if Kit.TemplateExists(name) then return name end
    end
end

function Kit.SetAtlasOrColor(texture, atlas, fallback)
    if atlas and C_Texture.GetAtlasExists(atlas) then
        texture:SetAtlas(atlas, false)
    else
        texture:SetColorTexture(fallback[1], fallback[2], fallback[3], fallback[4])
    end
end

function Kit.CreateLabel(parent, fontObject)
    local label = parent:CreateFontString(nil, "OVERLAY", fontObject or NATIVE.LabelFont)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    return label
end

function Kit.SetLabelText(label, text)
    label:SetText(text or "")
    local hasText = text ~= nil and text ~= ""
    label:SetShown(hasText)
    return hasText
end

function Kit.SetTextEnabled(region, enabled, enabledColor)
    local color = enabled and (enabledColor or NORMAL_FONT_COLOR) or GRAY_FONT_COLOR
    region:SetTextColor(color:GetRGB())
end

function Kit.StepDecimals(step)
    local text = string.format("%.6f", step or 1):gsub("0+$", "")
    local decimals = text:match("%.(%d+)$")
    return decimals and #decimals or 0
end

function Kit.RoundToStep(value, step)
    if not step or step <= 0 then return value end
    local snapped = math.floor(value / step + 0.5) * step
    return tonumber(string.format("%." .. Kit.StepDecimals(step) .. "f", snapped))
end

function Kit.FireOnEnter(region)
    region.obj:Fire("OnEnter")
end

function Kit.FireOnLeave(region)
    region.obj:Fire("OnLeave")
end