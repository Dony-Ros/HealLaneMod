local GU = HealLaneMod

local GUILD_ICON = "|A:friends-icon-tab-guildmates:14:14|a"
local guildMembers = {}

local function NormalizeName(name)
    if type(name) ~= "string" or (issecretvalue and issecretvalue(name)) then
        return nil
    end
    name = name:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    return name
end

local function AddGuildMember(name)
    local normalized = NormalizeName(name)
    if not normalized then return end
    guildMembers[normalized] = true
    local shortName = normalized:match("^([^%-]+)")
    if shortName then guildMembers[shortName] = true end
end

local function IsGuildMember(name)
    local normalized = NormalizeName(name)
    if not normalized then return false end
    local shortName = normalized:match("^([^%-]+)")
    return guildMembers[normalized] or shortName and guildMembers[shortName] or false
end

local function IsPlayer(name)
    local normalized = NormalizeName(name)
    if not normalized then return false end

    local playerName = UnitName and UnitName("player")
    local fullPlayerName = GetUnitName and GetUnitName("player", true)
    return normalized == NormalizeName(playerName)
        or normalized == NormalizeName(fullPlayerName)
end

local function HasGuild()
    if IsInGuild then return IsInGuild() and true or false end
    local guildName = GetGuildInfo and GetGuildInfo("player")
    return type(guildName) == "string" and guildName ~= ""
end

local function RequestGuildRoster()
    if not HasGuild() then return end
    if C_GuildInfo and C_GuildInfo.GuildRoster then
        C_GuildInfo.GuildRoster()
    elseif GuildRoster then
        GuildRoster()
    end
end

local function GetGuildMemberCount()
    if C_GuildInfo and C_GuildInfo.GetNumGuildMembers then
        return C_GuildInfo.GetNumGuildMembers()
    end
    return GetNumGuildMembers and GetNumGuildMembers() or 0
end

local function GetGuildMemberName(index)
    if C_GuildInfo and C_GuildInfo.GetGuildRosterInfo then
        local info = C_GuildInfo.GetGuildRosterInfo(index)
        if type(info) == "table" then return info.name end
        return info
    end
    return GetGuildRosterInfo and GetGuildRosterInfo(index)
end

local function RefreshGuildMembers()
    wipe(guildMembers)
    if not HasGuild() then return end

    for index = 1, GetGuildMemberCount() do
        AddGuildMember(GetGuildMemberName(index))
    end
end

local function IsGuildChat(text)
    local channel = text:match("|Hchannel:([^:|]+)")
    if not channel then return false end
    channel = channel:upper()
    return channel == "GUILD" or channel == "OFFICER"
end

local function Decorate(text)
    local settings = GU.db and GU.db.modules.guildchaticon
    if not (settings and settings.enabled ~= false) then return text end
    if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) then return text end
    if IsGuildChat(text) then return text end

    local start, _, name = text:find("|Hplayer:([^:|]+)")
    if not start or IsPlayer(name) or not IsGuildMember(name) then return text end

    local prefix = text:sub(1, start - 1)
    if prefix:find(GUILD_ICON, 1, true) then return text end

    local beforeRole, roleIcon = prefix:match("^(.*)(|T.-|t)%s*$")
    if roleIcon then
        return beforeRole .. roleIcon .. " " .. GUILD_ICON .. " " .. text:sub(start)
    end
    return prefix .. GUILD_ICON .. " " .. text:sub(start)
end

local function HookFrame(frame)
    if not frame or frame.healLaneModGuildIconHooked or type(frame.AddMessage) ~= "function" then
        return
    end

    frame.healLaneModGuildIconHooked = true
    local original = frame.AddMessage
    frame.AddMessage = function(self, text, ...)
        return original(self, Decorate(text), ...)
    end
end

local function HookChatFrames()
    for index = 1, NUM_CHAT_WINDOWS or 10 do
        HookFrame(_G["ChatFrame" .. index])
    end
end

local function EnableFeature()
    HookChatFrames()
    RefreshGuildMembers()
    RequestGuildRoster()
end

GU:RegisterModule({
    key = "guildchaticon",
    name = "Guild icon in chat",
    tab = "Utilities",
    page = "Chat",
    description = "Show the guildmates icon before chat names of other guild members, after any role icon.",
    events = { "PLAYER_LOGIN", "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE" },
    defaults = { enabled = true },
    settings = {
        {
            key = "enabled",
            type = "checkbox",
            label = "Show guild icon in chat",
            description = "Adds the guildmates icon before chat names of other guild members. If role icons are present, the guild icon follows them.",
            searchTerms = "guild icon chat member role",
        },
    },
    onChange = function(option, value)
        if option ~= "enabled" then return end
        if value then
            EnableFeature()
        else
            wipe(guildMembers)
        end
    end,
    handler = function(event)
        if event == "PLAYER_LOGIN" then
            EnableFeature()
        elseif event == "PLAYER_GUILD_UPDATE" then
            RefreshGuildMembers()
            RequestGuildRoster()
        elseif event == "GUILD_ROSTER_UPDATE" then
            RefreshGuildMembers()
        end
    end,
})
