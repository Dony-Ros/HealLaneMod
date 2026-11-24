local GU = HealLaneMod
local UI = HealLaneModUI

local config = {
    tabs = {},
    activeTab = nil,
    activePage = nil,
    pageFrames = {},
    searchRecords = {},
}

local function AddPage(tabName, pageName, data)
    local tab = config.tabs[tabName]
    if not tab then
        tab = { name = tabName, pages = {}, pageOrder = {} }
        config.tabs[tabName] = tab
    end
    local page = tab.pages[pageName]
    if not page then
        page = { name = pageName, groups = {}, settings = {} }
        tab.pages[pageName] = page
        tab.pageOrder[#tab.pageOrder + 1] = pageName
    end
    if data then page.groups[#page.groups + 1] = data end
    return page
end

local function BuildPages()
    for _, key in ipairs(GU.order) do
        local definition = GU.modules[key]
        local page = AddPage(definition.tab or "Utilities", definition.page or definition.name or key)
        page.groups[#page.groups + 1] = {
            moduleKey = key,
            title = definition.name or key,
            description = definition.description,
            settings = definition.settings or {},
        }
    end

    for _, definition in ipairs(GU.configPages) do
        local page = AddPage(definition.tab, definition.page)
        page.groups[#page.groups + 1] = {
            title = definition.title or definition.page,
            description = definition.description,
            settings = definition.settings or {},
        }
    end

    config.searchRecords = {}
    for tabName, tab in pairs(config.tabs) do
        for pageName, page in pairs(tab.pages) do
            for _, group in ipairs(page.groups) do
                local settings = group.settings or {}
                if group.moduleKey then
                    local hasEnabledSetting = false
                    for _, setting in ipairs(settings) do
                        if setting.key == "enabled" then hasEnabledSetting = true end
                    end
                    if not hasEnabledSetting then
                        table.insert(settings, 1, {
                            key = "enabled",
                            type = "checkbox",
                            label = "Enable " .. (group.title or group.moduleKey),
                            description = "Turn this feature on or off.",
                            searchTerms = "enable toggle on off",
                        })
                    end
                end
                for _, setting in ipairs(settings) do
                    config.searchRecords[#config.searchRecords + 1] = {
                        tab = tabName,
                        page = pageName,
                        group = group,
                        setting = setting,
                        text = table.concat({
                            tabName,
                            pageName,
                            group.title or "",
                            setting.label or "",
                            setting.description or "",
                            setting.searchTerms or "",
                        }, " "):lower(),
                    }
                end
            end
        end
    end
end

local function GetSettingValue(group, setting)
    if setting.get then return setting.get() end
    if group.moduleKey then return GU:Get(group.moduleKey, setting.key) end
    return nil
end

local function SetSettingValue(group, setting, value)
    if setting.set then
        setting.set(value)
    elseif group.moduleKey then
        GU:Set(group.moduleKey, setting.key, value)
    end
end

local function CreateSettingControl(parent, group, setting)
    local value = GetSettingValue(group, setting)
    if setting.type == "checkbox" then
        return UI:CreateCheckbox(parent, GU.colors, setting.label, value, function(checked)
            SetSettingValue(group, setting, checked)
        end)
    elseif setting.type == "dropdown" then
        local dropdown = UI:CreateDropdown(parent, GU.colors, setting.label, setting.options or {}, value, function(selected)
            SetSettingValue(group, setting, selected)
        end, setting.width or 210)
        if setting.onCreated then setting.onCreated(dropdown) end
        return dropdown
    elseif setting.create then
        return setting.create(parent, value, function(changed)
            SetSettingValue(group, setting, changed)
        end)
    end
end

local function CreatePageFrame(tabName, pageName, page)
    local frame = CreateFrame("Frame", nil, _G.HealLaneModConfigContentChild)
    frame:SetPoint("TOPLEFT")
    frame:SetWidth(_G.HealLaneModConfigContentChild:GetWidth())
    frame:Hide()
    local y = -20
    local padding = 22

    for _, group in ipairs(page.groups) do
        local titleButton = CreateFrame("Button", nil, frame)
        titleButton:SetPoint("TOPLEFT", padding, y)
        titleButton:SetSize(470, 22)
        local title = UI:CreateLabel(titleButton, GU.colors, group.title, "GameFontNormalLarge")
        title:SetPoint("LEFT")
        if group.description and group.description ~= "" then
            UI:SetTooltip(titleButton, group.description)
        end
        y = y - 35

        for _, setting in ipairs(group.settings or {}) do
            local row = CreateFrame("Frame", nil, frame)
            row:SetPoint("TOPLEFT", padding, y)
            row:SetPoint("TOPRIGHT", -padding, y)
            local hasDescription = setting.description and setting.description ~= ""
            local rowHeight = setting.type == "checkbox" and 52
                or setting.type == "dropdown" and 60
                or 64
            row:SetHeight(rowHeight)

            local control = CreateSettingControl(row, group, setting)
            if hasDescription and control then
                UI:SetTooltip(control, setting.description)
            end
            if control then
                if setting.type == "checkbox" then
                    control:SetPoint("TOPLEFT", 0, -2)
                elseif setting.type == "dropdown" then
                    control:SetPoint("TOPLEFT", 0, -2)
                    control:SetPoint("TOPRIGHT", 0, -2)
                else
                    control:SetPoint("TOPRIGHT", 0, -2)
                    local label = UI:CreateLabel(row, GU.colors, setting.label, "GameFontNormal")
                    label:SetPoint("TOPLEFT", 0, -7)
                end
            end

            for _, record in ipairs(config.searchRecords) do
                if record.tab == tabName and record.page == pageName
                    and record.group == group and record.setting == setting then
                    record.row = row
                    record.offset = -y
                    break
                end
            end
            y = y - row:GetHeight() - 4
        end
        y = y - 10
    end

    local height = math.max(1, -y + 20)
    frame:SetHeight(height)
    _G.HealLaneModConfigContentChild:SetHeight(height)
    return frame
end

local function RefreshPage(tabName, pageName)
    local key = tabName .. "\031" .. pageName
    local frame = config.pageFrames[key]
    if not frame then
        local page = config.tabs[tabName].pages[pageName]
        frame = CreatePageFrame(tabName, pageName, page)
        config.pageFrames[key] = frame
    end
    for _, pageFrame in pairs(config.pageFrames) do pageFrame:Hide() end
    frame:Show()
    _G.HealLaneModConfigContent:SetVerticalScroll(0)
    config.activePage = pageName
    for _, button in ipairs(config.pageButtons or {}) do
        local color = button.pageName == pageName and GU.colors.accent or GU.colors.text
        local text = button:GetFontString()
        if text then text:SetTextColor(unpack(color)) end
    end
end

local function CreatePageButtons()
    local sidebar = _G.HealLaneModConfigSidebar
    local tab = config.tabs[config.activeTab]
    config.pageButtons = config.pageButtons or {}
    local y = -8
    for index, pageName in ipairs(tab.pageOrder) do
        local button = config.pageButtons[index]
        if not button then
            button = UI:CreateButton(sidebar, GU.colors, "", 148, 30)
            config.pageButtons[index] = button
        end
        button:SetText(pageName)
        button.pageName = pageName
        button:SetPoint("TOPLEFT", 6, y)
        local selectedPage = pageName
        button:SetScript("OnClick", function() RefreshPage(config.activeTab, selectedPage) end)
        button:Show()
        y = y - 36
    end
    for index = #tab.pageOrder + 1, #config.pageButtons do
        config.pageButtons[index]:Hide()
    end
end

local function SelectTab(tabName)
    config.activeTab = tabName
    config.activePage = nil
    _G.HealLaneModConfigSearch:SetText("")
    CreatePageButtons()
    local tab = config.tabs[tabName]
    if tab and tab.pageOrder[1] then RefreshPage(tabName, tab.pageOrder[1]) end
    for name, button in pairs(config.tabButtons) do
        local color = name == tabName and GU.colors.accent or GU.colors.text
        local text = button:GetFontString()
        if text then text:SetTextColor(unpack(color)) end
    end
end

local function SearchCurrentTab(query)
    query = query:lower():match("^%s*(.-)%s*$")
    if query == "" then return end

    for _, record in ipairs(config.searchRecords) do
        if record.tab == config.activeTab and record.text:find(query, 1, true) then
            if config.activePage ~= record.page then
                CreatePageButtons()
                RefreshPage(record.tab, record.page)
            end
            if record.offset then
                _G.HealLaneModConfigContent:SetVerticalScroll(math.max(0, record.offset - 20))
            end
            return
        end
    end
end

local function InitializeConfig()
    BuildPages()
    local frame = _G.HealLaneModConfigFrame
    UI:StylePanel(frame, GU.colors)

    local title = UI:CreateLabel(frame, GU.colors, "HealLaneMod", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -16)
    local subtitle = UI:CreateLabel(frame, GU.colors, "Settings", "GameFontHighlightSmall", GU.colors.muted)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)

    local close = UI:CreateButton(frame, GU.colors, "X", 28, 26)
    close:SetPoint("TOPRIGHT", -14, -12)
    close:SetScript("OnClick", function() frame:Hide() end)

    local tabs = CreateFrame("Frame", nil, frame)
    tabs:SetPoint("TOPLEFT", 16, -58)
    tabs:SetPoint("TOPRIGHT", -250, -58)
    tabs:SetHeight(34)

    local search = CreateFrame("EditBox", "HealLaneModConfigSearch", frame, "InputBoxTemplate")
    search:SetSize(205, 24)
    search:SetPoint("TOPRIGHT", -24, -62)
    search:SetAutoFocus(false)
    search:SetTextInsets(6, 6, 0, 0)
    search:SetScript("OnTextChanged", function(self)
        SearchCurrentTab(self:GetText() or "")
    end)
    local placeholder = UI:CreateLabel(search, GU.colors, "Search this tab...", "GameFontDisableSmall", GU.colors.muted)
    placeholder:SetPoint("LEFT", 8, 0)
    local function UpdatePlaceholder()
        placeholder:SetShown(search:GetText() == "" and not search:HasFocus())
    end
    search:HookScript("OnTextChanged", UpdatePlaceholder)
    search:HookScript("OnEditFocusGained", UpdatePlaceholder)
    search:HookScript("OnEditFocusLost", UpdatePlaceholder)

    local sidebar = CreateFrame("Frame", "HealLaneModConfigSidebar", frame)
    sidebar:SetPoint("TOPLEFT", 14, -100)
    sidebar:SetPoint("BOTTOMLEFT", 14, 16)
    sidebar:SetWidth(166)

    local content = CreateFrame("ScrollFrame", "HealLaneModConfigContent", frame, "UIPanelScrollFrameTemplate")
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
    content:SetPoint("BOTTOMRIGHT", -28, 16)
    local contentChild = CreateFrame("Frame", nil, content)
    contentChild:SetWidth(550)
    contentChild:SetHeight(1)
    content:SetScrollChild(contentChild)
    _G.HealLaneModConfigContent = content
    _G.HealLaneModConfigContentChild = contentChild

    config.tabButtons = {}
    local tabNames = {}
    for name in pairs(config.tabs) do tabNames[#tabNames + 1] = name end
    table.sort(tabNames)
    local x = 0
    for _, tabName in ipairs(tabNames) do
        local button = UI:CreateButton(tabs, GU.colors, tabName, 120, 30)
        button:SetPoint("TOPLEFT", x, 0)
        local selectedTab = tabName
        button:SetScript("OnClick", function() SelectTab(selectedTab) end)
        config.tabButtons[tabName] = button
        x = x + 124
    end

    frame:HookScript("OnHide", function() search:ClearFocus() end)
    SelectTab(tabNames[1])
end

function GU:ToggleConfig()
    if not self.isReady then return end
    local frame = _G.HealLaneModConfigFrame
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

GU:RegisterConfigPage({
    tab = "General",
    page = "Minimap",
    title = "Minimap button",
    description = "Show and position the addon button. You can also drag it directly around the minimap.",
    settings = {
        {
            key = "hide",
            type = "checkbox",
            label = "Show minimap button",
            description = "Display a circular button beside the minimap.",
            searchTerms = "minimap icon button show hide visibility",
            get = function() return not GU.db.minimap.hide end,
            set = function(value)
                GU.db.minimap.hide = not value
                GU:UpdateMinimapButton()
            end,
        },
    },
})

GU:OnReady(InitializeConfig)
