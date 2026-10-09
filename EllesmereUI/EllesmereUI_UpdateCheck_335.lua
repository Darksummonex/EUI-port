-------------------------------------------------------------------------------
--  Update notices. The 3.3.5 client has no internet access, so EUI clients
--  trade their release stamp (Core TOC "X-EUI-Release", YYYYMMDDNN) over addon
--  messages in guild and group, and the older side is told a newer release
--  exists. /euiupdate shows the download link.
-------------------------------------------------------------------------------
local E = EllesmereUI
local PREFIX = "EUIVER"
local URL = "https://github.com/Darksummonex/EUI-port/releases"
local THROTTLE = 60

local mine = tonumber(GetAddOnMetadata("EllesmereUI", "X-EUI-Release") or "") or 0
local newest, notified = mine, false
local lastSent = {}

local function Label(stamp)
    local s = tostring(stamp)
    if #s < 8 then return s end
    return s:sub(1, 4) .. "-" .. s:sub(5, 6) .. "-" .. s:sub(7, 8)
end

local function Send(channel, target)
    if mine == 0 then return end
    local key = target or channel
    local now = GetTime()
    if lastSent[key] and now - lastSent[key] < THROTTLE then return end
    lastSent[key] = now
    SendAddonMessage(PREFIX, tostring(mine), channel, target)
end

local function Broadcast()
    if IsInGuild() then Send("GUILD") end
    local _, kind = IsInInstance()
    if kind == "pvp" then
        Send("BATTLEGROUND")
    elseif GetNumRaidMembers() > 0 then
        Send("RAID")
    elseif GetNumPartyMembers() > 0 then
        Send("PARTY")
    end
end

local function Notify()
    if notified or (EllesmereUIDB and EllesmereUIDB.updateCheckDisabled) then return end
    notified = true
    print("|cff0cd29fEllesmereUI:|r a newer release (" .. Label(newest) .. ") is available. Type |cff0cd29f/euiupdate|r for the download link.")
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:SetScript("OnEvent", function(_, event, prefix, msg, channel, sender)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(15, Broadcast)
    elseif event == "CHAT_MSG_ADDON" then
        if prefix ~= PREFIX or sender == UnitName("player") then return end
        local remote = tonumber(msg)
        if not remote then return end
        if remote > newest then
            newest = remote
            Notify()
        elseif remote < mine then
            if channel == "WHISPER" then Send("WHISPER", sender) else Send(channel) end
        end
    else
        Broadcast()
    end
end)

E.UpdateCheck = {
    URL = URL,
    Release = function() return mine end,
    Newest = function() return newest end,
}

SLASH_EUIUPDATE1 = "/euiupdate"
SlashCmdList.EUIUPDATE = function()
    local status = "Installed release: " .. (mine > 0 and Label(mine) or "unknown")
    if newest > mine then status = status .. "  |  Newer release seen: " .. Label(newest) end
    if E.ShowCopyPopup then
        E:ShowCopyPopup("EllesmereUI Updates", status, URL)
    else
        print("|cff0cd29fEllesmereUI:|r " .. status .. " - " .. URL)
    end
end
