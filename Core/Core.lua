local ADDON = ...

local GU = {
    modules = {},
    order = {},
    configPages = {},
    readyCallbacks = {},
    isReady = false,
}
HealLaneMod = GU
GameUtility = GU

GU.colors = {
    bg        = { 0.09, 0.09, 0.10 },
    panel     = { 0.12, 0.12, 0.13 },
    control   = { 0.16, 0.16, 0.18 },
    panelAlpha = 0.8,
    border    = { 0.22, 0.22, 0.25 },
    accent    = { 0.36, 0.56, 0.96 },
    accentDim = { 0.17, 0.24, 0.38 },
    text      = { 0.86, 0.86, 0.88 },
    muted     = { 0.55, 0.55, 0.60 },
}

function GU.Lerp(a, b, t)
    return a + (b - a) * t
end

function GU.LerpColor(a, b, t)
    return a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")

function GU:OnReady(callback)
    if self.isReady then
        callback()
    else
        self.readyCallbacks[#self.readyCallbacks + 1] = callback
    end
end

function GU:RegisterModule(definition)
    assert(type(definition.key) == "string", "Module requires a string key")
    assert(not self.modules[definition.key], "Duplicate module key: " .. definition.key)

    definition.eventSet = {}
    for _, event in ipairs(definition.events or {}) do
        definition.eventSet[event] = true
        eventFrame:RegisterEvent(event)
    end
    self.modules[definition.key] = definition
    self.order[#self.order + 1] = definition.key
end

function GU:RegisterConfigPage(definition)
    assert(type(definition.tab) == "string" and type(definition.page) == "string",
        "Config page requires tab and page names")
    self.configPages[#self.configPages + 1] = definition
end

function GU:Get(key, option)
    local module = self.db.modules[key]
    return module and module[option]
end

function GU:Set(key, option, value)
    self.db.modules[key][option] = value
    local definition = self.modules[key]
    if definition and definition.onChange then
        definition.onChange(option, value)
    end
end

function GU:ResetModule(key)
    local definition = assert(self.modules[key], "Unknown module: " .. tostring(key))
    local settings = assert(self.db.modules[key], "Module settings are not initialized")
    wipe(settings)
    for option, value in pairs(definition.defaults or {}) do
        settings[option] = value
        if definition.onChange then definition.onChange(option, value) end
    end
end

local function Initialize()
    if type(HealLaneModDB) ~= "table" then
        HealLaneModDB = {}
    end
    local db = HealLaneModDB
    db.modules = type(db.modules) == "table" and db.modules or {}
    db.minimap = type(db.minimap) == "table" and db.minimap or {}
    db.minimap.angle = type(db.minimap.angle) == "number" and db.minimap.angle or 225
    if type(db.minimap.hide) ~= "boolean" then db.minimap.hide = false end

    for key, definition in pairs(GU.modules) do
        local settings = type(db.modules[key]) == "table" and db.modules[key] or {}
        db.modules[key] = settings
        for option, default in pairs(definition.defaults or {}) do
            if settings[option] == nil then
                if option == "enabled" and type(db[key]) == "boolean" then
                    settings[option] = db[key]
                else
                    settings[option] = default
                end
            end
        end
    end

    GU.db = db
    GU.isReady = true
    for _, callback in ipairs(GU.readyCallbacks) do callback() end
    wipe(GU.readyCallbacks)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if (...) == ADDON then Initialize() end
        return
    end
    if not GU.db then return end

    for key, definition in pairs(GU.modules) do
        if definition.handler
            and definition.eventSet[event]
            and GU.db.modules[key].enabled ~= false then
            definition.handler(event, ...)
        end
    end
end)

local function ToggleConfig()
    GU:ToggleConfig()
end
SLASH_HEALLANEMOD1 = "/hlm"
SlashCmdList["HEALLANEMOD"] = ToggleConfig
SLASH_GAMEUTILITY1 = "/gu"
SlashCmdList["GAMEUTILITY"] = ToggleConfig
