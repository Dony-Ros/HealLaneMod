HealLaneMod UI library

To reuse the widgets in another addon, copy this Lib folder into that addon and
load HealLaneModUI.lua followed by HealLaneModUI.xml from its XML load file.
The library is exposed as the global HealLaneModUI table (with GameUtilityUI
kept as a compatibility alias) and does not depend on the HealLaneMod core or
the HealLane addon.

Available helpers: CreateButton, CreateIconButton, CreateTabButton,
CreateCheckbox, CreateLabel, CreateDropdown, CreateMultiDropdown, CreateSlider,
SetButtonSelected, SetTabSelected, SetTooltip, StyleButton, and StylePanel.
Widget helpers accept a colors table so the consuming addon can supply its own
theme. The table uses bg, panel, control, border, accent, accentDim, text, and
muted RGB arrays. It can also include panelAlpha (0-1) to set StylePanel
background opacity.

Examples:

local button = HealLaneModUI:CreateButton(parent, colors, "Apply", 120, 28)
button:SetPoint("TOPLEFT", 12, -12)

local iconButton = HealLaneModUI:CreateIconButton(parent, colors, 220, 24)
iconButton.icon:SetTexture(spellIcon)
iconButton.text:SetText(spellName)
iconButton:SetPoint("TOPLEFT", 12, -48)
