local _, ZF = ...
local AceGUI = LibStub("AceGUI-3.0")

local routes = {}
local WidgetRouter = {}

function ZF:IsNativeGUIEnabled()
    return not (ZF.db and ZF.db.global.NativeGUI == false)
end

function WidgetRouter:Create(widgetType)
    local route = ZF:IsNativeGUIEnabled() and routes[widgetType]
    return AceGUI:Create(route or widgetType)
end

function WidgetRouter:Release(widget)
    AceGUI:Release(widget)
end

function WidgetRouter:RegisterNative(stockType, nativeType, constructor, version)
    AceGUI:RegisterWidgetType(nativeType, constructor, version)
    routes[stockType] = nativeType
end

setmetatable(WidgetRouter, {
    __index = function(_, key)
        local value = AceGUI[key]
        if type(value) == "function" then
            return function(_, ...) return value(AceGUI, ...) end
        end
        return value
    end,
})

ZF.AG = WidgetRouter