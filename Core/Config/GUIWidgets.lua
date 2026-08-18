local _, ZF = ...
local AG = ZF.AG
local STYLE = ZF.DesignerStyle
ZF.GUIWidgets = {}
local Widgets = ZF.GUIWidgets

function Widgets.DeepDisable(widget, disabled, exemptWidget)
    if widget == exemptWidget then return end
    if widget.SetDisabled then widget:SetDisabled(disabled) end
    if not widget.children then return end
    for _, child in ipairs(widget.children) do
        Widgets.DeepDisable(child, disabled, exemptWidget)
    end
end

local function Finalize(parent, widget)
    widget:SetFullWidth(true)
    parent:AddChild(widget)
    return widget
end

function Widgets.CreateInformationTag(parent, description, justification)
    local label = AG:Create("Label")
    label:SetText(ZF.INFOBUTTON .. description)
    label:SetFont("Fonts\\FRIZQT__.TTF", STYLE.Layout.InfoLabelFontSize, "OUTLINE")
    label:SetJustifyH(justification or "CENTER")
    label:SetHeight(STYLE.Layout.InfoLabelHeight)
    label:SetJustifyV("MIDDLE")
    return Finalize(parent, label)
end

function Widgets.CreateScrollFrame(parent)
    local scrollFrame = AG:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    return Finalize(parent, scrollFrame)
end

function Widgets.CreateInlineGroup(parent, title)
    local group = AG:Create("InlineGroup")
    group:SetTitle("|cFFFFFFFF" .. title .. "|r")
    group:SetLayout("Flow")
    return Finalize(parent, group)
end

function Widgets.CreateHeader(parent, title)
    local header = AG:Create("Heading")
    header:SetText("|cFFFFD100" .. title .. "|r")
    return Finalize(parent, header)
end

function Widgets.TextureMarkup(path, width, height)
    height = height or width
    return "|T" .. path .. ":" .. width .. ":" .. height .. "|t"
end

function Widgets.AtlasMarkup(atlas, width, height)
    height = height or width
    return "|A:" .. atlas .. ":" .. width .. ":" .. height .. "|a"
end
