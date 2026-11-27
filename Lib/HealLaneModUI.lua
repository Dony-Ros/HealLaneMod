local UI = HealLaneModUI or GameUtilityUI or {}
HealLaneModUI = UI
GameUtilityUI = UI

function UI:WrapTextToWidth(fontString, width)
    if not fontString then return end
    fontString:SetWidth(width)
    if fontString.SetWordWrap then fontString:SetWordWrap(true) end
    if fontString.SetNonSpaceWrap then fontString:SetNonSpaceWrap(true) end
    return fontString
end

function UI:ApplyPixelPerfectFontString(fontString)
    if not fontString then
        return fontString
    end
    if fontString.SetSnapToPixelGrid then
        fontString:SetSnapToPixelGrid(true)
    end
    if fontString.SetTexelSnappingBias then
        fontString:SetTexelSnappingBias(0)
    end
    return fontString
end

function UI:CreatePixelPerfectFontString(parent, name, layer, template)
    return self:ApplyPixelPerfectFontString(parent:CreateFontString(name, layer, template))
end

local function ColorTexture(texture, color, alpha)
    if texture then
        texture:SetColorTexture(color[1], color[2], color[3], alpha or 1)
    end
end

local activeDropdownMenu
local function ToggleDropdownMenu(menu, refresh)
    if menu:IsShown() then
        menu:Hide()
        return
    end
    if activeDropdownMenu and activeDropdownMenu ~= menu then
        activeDropdownMenu:Hide()
    end
    refresh()
    activeDropdownMenu = menu
    menu:Show()
    menu:Raise()
end

function UI:StyleButton(button, colors, text)
    if text ~= nil then button:SetText(text) end
    button:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
    button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    button:SetPushedTexture("Interface\\Buttons\\WHITE8X8")
    ColorTexture(button:GetNormalTexture(), colors.control)
    ColorTexture(button:GetHighlightTexture(), colors.accent, 0.25)
    ColorTexture(button:GetPushedTexture(), colors.accentDim)

    local fontString = button:GetFontString()
    if fontString then
        self:ApplyPixelPerfectFontString(fontString)
        fontString:SetFontObject(GameFontNormal)
        fontString:SetTextColor(unpack(colors.text))
    end
    if not button.HealLaneModStyled then
        button.HealLaneModStyled = true
        button:HookScript("OnEnter", function(self) self:SetAlpha(0.82) end)
        button:HookScript("OnLeave", function(self) self:SetAlpha(1) end)
    end
    return button
end

function UI:CreateButton(parent, colors, text, width, height)
    local button = CreateFrame("Button", nil, parent, "HealLaneModUIButtonTemplate")
    button:SetSize(width, height)
    return self:StyleButton(button, colors, text)
end

function UI:CreateIconButton(parent, colors, width, height, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)

    button.background = button:CreateTexture(nil, "BACKGROUND")
    button.background:SetAllPoints()
    ColorTexture(button.background, colors.control)

    button.icon = button:CreateTexture(nil, "OVERLAY")
    local iconSize = math.max(1, math.min(height - 6, 20))
    button.icon:SetSize(iconSize, iconSize)
    button.icon:SetPoint("LEFT", 5, 0)
    button.icon:SetDrawLayer("OVERLAY")

    button.text = self:CreatePixelPerfectFontString(button, nil, "OVERLAY", "GameFontHighlight")
    button.text:SetPoint("LEFT", button.icon, "RIGHT", 8, 0)
    button.text:SetPoint("RIGHT", -6, 0)
    button.text:SetJustifyH("LEFT")
    button.text:SetTextColor(unpack(colors.text))

    button:SetScript("OnEnter", function(self)
        ColorTexture(self.background, colors.accentDim)
    end)
    button:SetScript("OnLeave", function(self)
        ColorTexture(self.background, colors.control)
        GameTooltip:Hide()
    end)
    button:SetScript("OnClick", onClick)
    return button
end

function UI:SetButtonSelected(button, colors, selected)
    ColorTexture(button:GetNormalTexture(), selected and colors.accentDim or colors.control)
    local fontString = button:GetFontString()
    if fontString then
        self:ApplyPixelPerfectFontString(fontString)
        fontString:SetTextColor(unpack(selected and colors.accent or colors.text))
    end
end

function UI:SetTabSelected(button, colors, selected)
    ColorTexture(button.tabBackground, selected and colors.accentDim or colors.control)
    if button.tabText then
        self:ApplyPixelPerfectFontString(button.tabText)
        button.tabText:SetTextColor(unpack(selected and colors.accent or colors.text))
    end
end

function UI:CreateTabButton(parent, colors, text, width, height, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)

    button.tabBackground = button:CreateTexture(nil, "BACKGROUND")
    button.tabBackground:SetAllPoints()

    button.tabText = self:CreatePixelPerfectFontString(button, nil, "OVERLAY", "GameFontNormal")
    button.tabText:SetPoint("CENTER")
    button.tabText:SetText(text or "")

    button:SetScript("OnClick", onClick)
    self:SetTabSelected(button, colors, false)
    return button
end

function UI:CreateCheckbox(parent, colors, label, checked, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "HealLaneModUICheckButtonTemplate")
    checkbox:SetSize(26, 26)
    checkbox:SetChecked(checked and true or false)

    local text = self:CreatePixelPerfectFontString(checkbox, nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    text:SetText(label or "")
    text:SetTextColor(unpack(colors.text))
    checkbox:SetHitRectInsets(0, -text:GetStringWidth() - 4, 0, 0)
    checkbox.label = text
    checkbox:SetScript("OnClick", function(self)
        onClick(self:GetChecked() and true or false)
    end)
    return checkbox
end

function UI:StyleCheckbox(checkbox, colors)
    local label = checkbox.label
    if not label and checkbox.GetName then
        local name = checkbox:GetName()
        if name then label = _G[name .. "Text"] end
    end
    if label then
        self:ApplyPixelPerfectFontString(label)
        label:SetTextColor(unpack(colors.text))
    end
    local checked = checkbox:GetCheckedTexture()
    if checked then checked:SetVertexColor(unpack(colors.accent)) end
end

function UI:CreateLabel(parent, colors, text, font, color)
    local label = self:CreatePixelPerfectFontString(parent, nil, "ARTWORK", font or "GameFontNormal")
    label:SetText(text or "")
    label:SetTextColor(unpack(color or colors.text))
    return label
end

function UI:SetTooltip(element, text)
    if not text or text == "" then return end
    local target = element.slider or element.button or element
    local onEnter = target:GetScript("OnEnter")
    local onLeave = target:GetScript("OnLeave")
    target:SetScript("OnEnter", function(self, ...)
        if onEnter then onEnter(self, ...) end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(text)
        GameTooltip:Show()
    end)
    target:SetScript("OnLeave", function(self, ...)
        if onLeave then onLeave(self, ...) end
        GameTooltip:Hide()
    end)
end

function UI:StylePanel(panel, colors, background)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    local color = background or colors.bg
    local alpha = tonumber(colors.panelAlpha) or 0.8
    alpha = math.max(0, math.min(1, alpha))
    panel:SetBackdropColor(color[1], color[2], color[3], alpha)
    panel:SetBackdropBorderColor(unpack(colors.border))
end

function UI:StyleText(fontString, colors, color)
    if fontString then
        self:ApplyPixelPerfectFontString(fontString)
        fontString:SetTextColor(unpack(color or colors.text))
    end
end

function UI:StyleEditBox(editBox, colors)
    editBox:SetTextColor(unpack(colors.text))
    if editBox.SetBackdrop then
        self:StylePanel(editBox, colors, colors.control)
    end
end

function UI:StyleSlider(slider, colors)
    local thumb = slider:GetThumbTexture()
    if thumb then thumb:SetVertexColor(unpack(colors.accent)) end
    local name = slider:GetName()
    if name then
        self:StyleText(_G[name .. "Text"], colors)
        self:StyleText(_G[name .. "Low"], colors, colors.muted)
        self:StyleText(_G[name .. "High"], colors, colors.muted)
    end
end

function UI:StyleDropdown(dropdown, colors)
    local name = dropdown:GetName()
    if not name then return end
    for _, suffix in ipairs({ "Left", "Middle", "Right" }) do
        local texture = _G[name .. suffix]
        if texture then texture:SetVertexColor(unpack(colors.control)) end
    end
    self:StyleText(_G[name .. "Text"], colors)
end

function UI:CreateDropdown(parent, colors, label, options, selectedValue, onSelect, width)
    local dropdown = CreateFrame("Frame", nil, parent)
    local hasLabel = type(label) == "string" and label ~= ""
    local buttonTop = hasLabel and -21 or 0
    dropdown:SetSize(width or 180, hasLabel and 50 or 28)
    dropdown.options = options
    dropdown.selectedValue = selectedValue
    dropdown.onSelect = onSelect

    local button = self:CreateButton(dropdown, colors, "", dropdown:GetWidth(), dropdown:GetHeight())
    button:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, buttonTop)
    button:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT")
    dropdown.button = button

    if hasLabel then
        local marker = dropdown:CreateTexture(nil, "ARTWORK")
        marker:SetSize(4, 4)
        marker:SetPoint("TOPLEFT", 0, -7)
        ColorTexture(marker, colors.accent)

        local title = self:CreateLabel(dropdown, colors, label, "GameFontHighlightSmall")
        title:SetPoint("LEFT", marker, "RIGHT", 4, 0)
    end

    local valueText = button:GetFontString()
    if valueText then
        self:ApplyPixelPerfectFontString(valueText)
        valueText:ClearAllPoints()
        valueText:SetPoint("LEFT", button, "LEFT", 10, 0)
        valueText:SetPoint("RIGHT", button, "RIGHT", -28, 0)
        valueText:SetJustifyH("LEFT")
        valueText:SetFontObject(GameFontHighlightSmall)
        valueText:SetTextColor(unpack(colors.text))
    end

    local arrow = self:CreatePixelPerfectFontString(button, nil, "OVERLAY", "GameFontHighlightSmall")
    arrow:SetPoint("RIGHT", button, "RIGHT", -10, 0)
    arrow:SetText("v")
    arrow:SetTextColor(unpack(colors.muted or colors.text))

    local menu = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    menu:SetFrameStrata("TOOLTIP")
    menu:SetWidth(dropdown:GetWidth())
    menu:SetHeight(math.max(34, #options * 28 + 8))
    self:StylePanel(menu, colors, colors.panel)
    menu:SetBackdropColor(colors.panel[1], colors.panel[2], colors.panel[3], 1)
    menu:Hide()
    menu:SetScript("OnHide", function()
        if activeDropdownMenu == menu then activeDropdownMenu = nil end
    end)
    dropdown.menu = menu
    local itemButtons = {}

    local function GetOptions()
        if type(dropdown.options) == "function" then
            return dropdown.options() or {}
        end
        return dropdown.options or {}
    end

    local function UpdateLabel()
        local selectedLabel
        for _, option in ipairs(GetOptions()) do
            if option.value == dropdown.selectedValue then
                selectedLabel = option.label
                break
            end
        end
        local fallback = dropdown.selectedValue == nil and "Select" or "Custom"
        button:SetText(selectedLabel or fallback)
    end
    function dropdown:SetValue(value)
        self.selectedValue = value
        UpdateLabel()
    end
    function dropdown:SetOptions(newOptions)
        self.options = newOptions
        UpdateLabel()
    end

    local function RefreshMenu()
        local currentOptions = GetOptions()
        menu:SetHeight(math.max(34, #currentOptions * 28 + 8))
        for index, option in ipairs(currentOptions) do
            local item = option
            local itemButton = itemButtons[index]
            if not itemButton then
                itemButton = self:CreateButton(menu, colors, "", menu:GetWidth() - 8, 28)
                itemButton:SetPoint("TOPLEFT", 4, -4 - ((index - 1) * 28))
                itemButtons[index] = itemButton
            end
            itemButton:SetText(item.label)
            local fontString = itemButton:GetFontString()
            if fontString then
                self:ApplyPixelPerfectFontString(fontString)
                local color = item.value == dropdown.selectedValue and colors.accent or colors.text
                fontString:SetTextColor(unpack(color))
            end
            itemButton:SetScript("OnClick", function()
                dropdown.selectedValue = item.value
                UpdateLabel()
                menu:Hide()
                if onSelect then onSelect(item.value) end
            end)
            itemButton:Show()
        end
        for index = #currentOptions + 1, #itemButtons do
            itemButtons[index]:Hide()
        end
    end

    menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, 0)
    button:SetScript("OnClick", function()
        ToggleDropdownMenu(menu, RefreshMenu)
    end)
    UpdateLabel()
    return dropdown
end

function UI:CreateMultiDropdown(parent, colors, options, isSelected, onToggle, getSummary, width)
    local dropdown = CreateFrame("Frame", nil, parent)
    dropdown:SetSize(width or 180, 28)
    dropdown.options = options

    local button = self:CreateButton(dropdown, colors, "", dropdown:GetWidth(), dropdown:GetHeight())
    button:SetAllPoints()
    dropdown.button = button

    local menu = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    menu:SetFrameStrata("TOOLTIP")
    menu:SetWidth(dropdown:GetWidth())
    self:StylePanel(menu, colors, colors.panel)
    menu:SetBackdropColor(colors.panel[1], colors.panel[2], colors.panel[3], 1)
    menu:Hide()
    menu:SetScript("OnHide", function()
        if activeDropdownMenu == menu then activeDropdownMenu = nil end
    end)
    dropdown.menu = menu
    local itemButtons = {}

    local function UpdateLabel()
        button:SetText(getSummary())
    end

    function dropdown:Refresh()
        UpdateLabel()
        if menu:IsShown() then self:RefreshOptions() end
    end

    function dropdown:SetOptions(newOptions)
        self.options = newOptions
        self:Refresh()
    end

    function dropdown:RefreshOptions()
        menu:SetHeight(math.max(34, #self.options * 28 + 8))
        for index, option in ipairs(self.options) do
            local value = type(option) == "table" and option.value or option
            local text = type(option) == "table" and option.label or option
            local itemButton = itemButtons[index]
            if not itemButton then
                itemButton = UI:CreateButton(menu, colors, "", menu:GetWidth() - 8, 28)
                itemButton:SetPoint("TOPLEFT", 4, -4 - ((index - 1) * 28))
                itemButtons[index] = itemButton
            end
            itemButton:SetText((isSelected(value) and "[x] " or "[ ] ") .. text)
            itemButton:SetScript("OnClick", function()
                onToggle(value)
                dropdown:Refresh()
            end)
            itemButton:Show()
        end
        for index = #self.options + 1, #itemButtons do itemButtons[index]:Hide() end
    end

    menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, 0)
    button:SetScript("OnClick", function()
        ToggleDropdownMenu(menu, function() dropdown:RefreshOptions() end)
    end)
    UpdateLabel()
    return dropdown
end

function UI:CreateSlider(parent, colors, label, minimum, maximum, step, value, onValueChanged, width)
    local control = CreateFrame("Frame", nil, parent)
    control:SetSize(width or 180, 40)

    local valueText = self:CreateLabel(control, colors, "", "GameFontHighlightSmall", colors.accent)
    valueText:SetPoint("TOPRIGHT", 0, -1)
    valueText:SetJustifyH("RIGHT")
    valueText:SetWidth(42)
    local labelText = self:CreateLabel(control, colors, label, "GameFontHighlightSmall")
    labelText:SetPoint("TOPLEFT", 0, -1)
    labelText:SetPoint("RIGHT", valueText, "LEFT", -6, 0)
    labelText:SetJustifyH("LEFT")

    local slider = CreateFrame("Slider", nil, control)
    slider:SetOrientation("HORIZONTAL")
    slider:SetPoint("BOTTOMLEFT", 1, 3)
    slider:SetPoint("BOTTOMRIGHT", -1, 3)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(colors.control[1], colors.control[2], colors.control[3], 1)
    track:SetPoint("LEFT", slider, "LEFT")
    track:SetPoint("RIGHT", slider, "RIGHT")
    track:SetPoint("CENTER", slider, "CENTER")
    track:SetHeight(4)

    slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:SetSize(12, 12)
        thumb:SetColorTexture(colors.accent[1], colors.accent[2], colors.accent[3], 1)
        thumb:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    end

    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetColorTexture(colors.accent[1], colors.accent[2], colors.accent[3], 1)
    fill:SetPoint("LEFT", track, "LEFT")
    fill:SetPoint("RIGHT", thumb or slider, "CENTER")
    fill:SetPoint("CENTER", track, "CENTER")
    fill:SetHeight(4)

    local function UpdateValueText(currentValue)
        valueText:SetText(string.format("%g", currentValue))
    end

    slider:SetValue(value or minimum)
    UpdateValueText(slider:GetValue())
    slider:SetScript("OnValueChanged", function(_, currentValue)
        UpdateValueText(currentValue)
        if onValueChanged then onValueChanged(currentValue) end
    end)
    control.slider = slider
    control.valueText = valueText
    control.SetValue = function(_, currentValue) slider:SetValue(currentValue) end
    control.GetValue = function() return slider:GetValue() end
    slider:SetScript("OnEnter", function()
        if thumb then thumb:SetColorTexture(1, 1, 1, 1) end
    end)
    slider:SetScript("OnLeave", function()
        if thumb then thumb:SetColorTexture(colors.accent[1], colors.accent[2], colors.accent[3], 1) end
    end)
    return control
end
