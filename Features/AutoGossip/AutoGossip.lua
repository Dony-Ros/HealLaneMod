local GU = HealLaneMod

local lastSelect = 0

local function GetGossipState()
    if C_GossipInfo and C_GossipInfo.GetOptions then
        local options = C_GossipInfo.GetOptions() or {}
        local quests = 0
        if C_GossipInfo.GetAvailableQuests then
            quests = quests + #(C_GossipInfo.GetAvailableQuests() or {})
        end
        if C_GossipInfo.GetActiveQuests then
            quests = quests + #(C_GossipInfo.GetActiveQuests() or {})
        end
        return #options, quests, options[1]
    end

    local quests = (GetNumGossipAvailableQuests and GetNumGossipAvailableQuests() or 0)
        + (GetNumGossipActiveQuests and GetNumGossipActiveQuests() or 0)
    return GetNumGossipOptions and GetNumGossipOptions() or 0, quests
end

local function SelectFirst(option)
    if C_GossipInfo and C_GossipInfo.SelectOption and option then
        C_GossipInfo.SelectOption(option.gossipOptionID)
    elseif SelectGossipOption then
        SelectGossipOption(1)
    end
end

GU:RegisterModule({
    key = "autogossip",
    name = "Auto gossip",
    tab = "Utilities",
    page = "Gossip",
    description = "Automatically select a single gossip option when no quests are available.",
    events = { "GOSSIP_SHOW" },
    defaults = { enabled = true },
    settings = {
        {
            key = "enabled",
            type = "checkbox",
            label = "Enable automatic gossip",
            description = "Automatically select the only gossip option when no quests are available. Hold Shift to skip.",
            searchTerms = "toggle enable disable skip shift",
        },
    },
    handler = function()
        if IsShiftKeyDown() then return end
        local optionCount, questCount, firstOption = GetGossipState()
        if optionCount ~= 1 or questCount > 0 then return end

        local now = GetTime()
        if now - lastSelect < 0.5 then return end
        lastSelect = now
        SelectFirst(firstOption)
    end,
})
