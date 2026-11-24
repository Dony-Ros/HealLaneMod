local GU = HealLaneMod

local function GetCursorAngle()
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cursorX, cursorY = cursorX / scale, cursorY / scale
    local centerX, centerY = Minimap:GetCenter()
    return math.deg(math.atan2(cursorY - centerY, cursorX - centerX)) % 360
end

local function SetButtonPosition()
    local button = _G.HealLaneModMinimapButton
    local angle = math.rad(GU.db.minimap.angle)
    local radius = (Minimap:GetWidth() or 140) / 2 + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function UpdateDragPosition(button)
    button = button or _G.HealLaneModMinimapButton
    local cursorX, cursorY = GetCursorPosition()
    local dx = cursorX - (button.pressX or cursorX)
    local dy = cursorY - (button.pressY or cursorY)
    if dx * dx + dy * dy <= 36 then return end

    button.dragMoved = true
    GU.db.minimap.angle = GetCursorAngle()
    SetButtonPosition()
end

local function InitializeMinimapButton()
    local button = _G.HealLaneModMinimapButton
    local icon = _G.HealLaneModMinimapButtonIcon
    local ring = _G.HealLaneModMinimapButtonRing
    local face = _G.HealLaneModMinimapButtonFace

    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    face:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    local colors = GU.colors
    ring:SetVertexColor(unpack(colors.accent))
    face:SetVertexColor(unpack(colors.control))
    button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnMouseDown", function(self)
        local x, y = GetCursorPosition()
        self.pressX, self.pressY = x, y
        self.dragMoved = false
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function() UpdateDragPosition(self) end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        UpdateDragPosition(self)
    end)
    button:SetScript("OnClick", function(self)
        local x, y = GetCursorPosition()
        local dx, dy = x - (self.pressX or x), y - (self.pressY or y)
        if dx * dx + dy * dy > 36 then return end
        GU:ToggleConfig()
    end)
    button:SetScript("OnEnter", function(self)
        icon:SetAlpha(0.8)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("HealLaneMod")
        GameTooltip:AddLine("Click to open settings", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag to move around the minimap", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        icon:SetAlpha(1)
        GameTooltip:Hide()
    end)
    GU:UpdateMinimapButton()
    SetButtonPosition()
end

function GU:UpdateMinimapButton()
    local button = _G.HealLaneModMinimapButton
    if button then button:SetShown(not self.db.minimap.hide) end
end

function GU:UpdateMinimapButtonPosition()
    if self.db and _G.HealLaneModMinimapButton and Minimap then
        SetButtonPosition()
        self:UpdateMinimapButton()
    end
end

GU:OnReady(InitializeMinimapButton)
