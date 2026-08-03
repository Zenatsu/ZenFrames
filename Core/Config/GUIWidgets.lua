local _, ZF = ...
local AG = ZF.AG
ZF.GUIWidgets = {}
local Widgets = ZF.GUIWidgets

-- Recursively disables/re-enables an AceGUI widget and every descendant in
-- its `.children` tree, except `exemptWidget` (typically the toggle that
-- triggered the disable, which must stay clickable to re-enable the rest).
function Widgets.DeepDisable(widget, disabled, exemptWidget)
    if widget == exemptWidget then return end
    if widget.SetDisabled then widget:SetDisabled(disabled) end
    if not widget.children then return end
    for _, child in ipairs(widget.children) do
        Widgets.DeepDisable(child, disabled, exemptWidget)
    end
end

-- A full-width info label prefixed with ZF.INFOBUTTON, used throughout the
-- Designer to explain a section before its controls.
function Widgets.CreateInformationTag(parent, description, justification)
    local label = AG:Create("Label")
    label:SetText(ZF.INFOBUTTON .. description)
    label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    label:SetFullWidth(true)
    label:SetJustifyH(justification or "CENTER")
    label:SetHeight(24)
    label:SetJustifyV("MIDDLE")
    parent:AddChild(label)
    return label
end

function Widgets.CreateScrollFrame(parent)
    local scrollFrame = AG:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:SetFullWidth(true)
    parent:AddChild(scrollFrame)
    return scrollFrame
end

function Widgets.CreateInlineGroup(parent, title)
    local group = AG:Create("InlineGroup")
    group:SetTitle("|cFFFFFFFF" .. title .. "|r")
    group:SetFullWidth(true)
    group:SetLayout("Flow")
    parent:AddChild(group)
    return group
end

function Widgets.CreateHeader(parent, title)
    local header = AG:Create("Heading")
    header:SetText("|cFFFFD100" .. title .. "|r")
    header:SetFullWidth(true)
    parent:AddChild(header)
    return header
end
