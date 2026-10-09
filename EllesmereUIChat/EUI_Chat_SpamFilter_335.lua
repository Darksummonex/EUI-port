-- Player-chat spam filtering through Wrath's native event filters.
local _, ns = ...
local scopes = {
    CHAT_MSG_SAY="public", CHAT_MSG_YELL="public", CHAT_MSG_CHANNEL="public",
    CHAT_MSG_PARTY="group", CHAT_MSG_PARTY_LEADER="group", CHAT_MSG_RAID="group",
    CHAT_MSG_RAID_LEADER="group", CHAT_MSG_RAID_WARNING="group",
    CHAT_MSG_GUILD="group", CHAT_MSG_OFFICER="group",
    CHAT_MSG_BATTLEGROUND="group", CHAT_MSG_BATTLEGROUND_LEADER="group",
    CHAT_MSG_WHISPER="whispers",
}
local histories, decisions = {}, {entries={}, count=0}
local signature, registered
local keywordSource, keywords = nil, {}
local LIMIT = 500
function ns.ResetSpamFilter()
    histories, decisions = {}, {entries={}, count=0}
end
function ns.SyncSpamFilter()
    local p = ns.GetSettings()
    if not p then return end
    local current = table.concat({tostring(p.enabled), tostring(p.spamFilterEnabled),
        tostring(p.spamFilterWindow), tostring(p.spamFilterAnySender),
        tostring(p.spamFilterPublic), tostring(p.spamFilterGroup), tostring(p.spamFilterWhispers),
        tostring(p.spamFilterGoldSellers), tostring(p.spamFilterAchievements), tostring(p.spamFilterTrade), tostring(p.spamFilterRecruitment),
        tostring(p.spamFilterKeywordsEnabled), tostring(p.spamFilterKeywords)}, ":")
    if current ~= signature then signature=current; ns.ResetSpamFilter() end
end
local function Put(cache, key, entry, now)
    -- Bound memory even in very busy channels; expired/oldest records go first.
    if not cache.entries[key] then
        if cache.count >= LIMIT then
            local oldestKey, oldestTime
            for k, value in pairs(cache.entries) do
                if value.expires <= now then cache.entries[k]=nil; cache.count=cache.count-1
                elseif not oldestTime or value.expires < oldestTime then oldestKey,oldestTime=k,value.expires end
            end
            if cache.count >= LIMIT and oldestKey then cache.entries[oldestKey]=nil; cache.count=cache.count-1 end
        end
        cache.count=cache.count+1
    end
    cache.entries[key]=entry
end
-- Byte ranges instead of string.lower/%s, whose results depend on the C locale and can
-- rewrite UTF-8 bytes. Accented capitals (UTF-8 C3 80-9E, e.g. Ç Ã É) sit 0x20 below
-- their lowercase forms; C3 97 is the multiplication sign.
local function LowerASCII(c) return string.char(c:byte() + 32) end
local function LowerAccent(c)
    local b = c:byte()
    if b ~= 0x97 then return "\195"..string.char(b + 32) end
end
local function Normalize(text)
    text = text:gsub("[A-Z]", LowerASCII):gsub("\195([\128-\158])", LowerAccent):gsub("[ \t\r\n]+", " ")
    return text:match("^ ?(.-) ?$")
end
local function Word(text, word)
    return text:find("%f[%w]"..word.."%f[%W]") ~= nil
end
local function Trade(text)
    return Word(text,"wts") or Word(text,"wtb") or Word(text,"wtt") or Word(text,"lfw") or
        Word(text,"selling") or Word(text,"buying") or Word(text,"vendo") or Word(text,"compro")
end
local function GoldSeller(text)
    -- Require a sale, gold quantity/name and a commercial signal together.
    local sale = Word(text,"sell") or Word(text,"selling") or Word(text,"wts") or
        Word(text,"buy") or Word(text,"buying") or Word(text,"vendo") or Word(text,"compro")
    local gold = Word(text,"gold") or Word(text,"ouro") or text:find("%d[%d,. ]*%s*g%f[%W]") ~= nil
    if not gold then return false end
    local compact = text:gsub("[^a-z0-9]", "")
    local website = compact:find("www",1,true) or Word(text,"web") or text:find("www.",1,true) or text:find("https?://") or
        text:find("[%w%-]+%.com%f[%W]") or text:find("[%w%-]+%.net%f[%W]")
    local cash = text:find("%$%s*%d") or text:find("%d%s*%$") or Word(text,"usd") or Word(text,"eur")
    local bucks = text:find("%d[%d,.]*%s*bucks?%f[%W]") ~= nil
    local goldPrice = text:find("%d[%d,. ]*%s*g%f[%W]%s*=%s*%d[%d,.]*%s*bucks?%f[%W]") ~= nil
    return ((sale and (website or cash)) or goldPrice or (bucks and website)) and true or false
end
local function Recruitment(text)
    local guild = Word(text,"guild") or Word(text,"guilda") or text:find("<[^>]+>") ~= nil
    return text:find("guild recruitment",1,true) ~= nil or
        (guild and (Word(text,"recruiting") or Word(text,"recruitment") or
        Word(text,"recrutando") or Word(text,"recrutamento") or Word(text,"recruta") or
        text:find("looking for members",1,true) ~= nil or text:find("looking for players",1,true) ~= nil)) or
        text:find("%f[%w]lf%s*guilda?%f[%W]") ~= nil or text:find("looking for a guild",1,true) ~= nil
end
local function KeywordMatch(p, text)
    local source = type(p.spamFilterKeywords)=="string" and p.spamFilterKeywords or ""
    if source ~= keywordSource then
        keywordSource, keywords = source, {}
        -- Literal phrases, not Lua patterns. Empty entries never match everything.
        for entry in source:gmatch("[^,;\r\n]+") do
            local word = Normalize(entry)
            if word~="" then keywords[#keywords+1]=word end
        end
    end
    for _,word in ipairs(keywords) do if text:find(word,1,true) then return true end end
    return false
end
-- Hardcore realm death announcements reach chat as server messages:
-- "Name the level 11 Gnome Warrior has been slain by X in Westfall".
local hardcoreEvents = {CHAT_MSG_SYSTEM=true, CHAT_MSG_CHANNEL=true, CHAT_MSG_RAID_BOSS_EMOTE=true,
    CHAT_MSG_MONSTER_EMOTE=true, CHAT_MSG_BG_SYSTEM_NEUTRAL=true}
local deathPhrases = {" has been slain", " has been killed", " has died", " has drowned", " has fallen",
    " has burned", " was slain", " was killed"}
local function HardcoreDeathLevel(text)
    local level, rest = text:match("%S the level (%d+) (.+)$")
    if not level then return nil end
    for _,phrase in ipairs(deathPhrases) do
        if rest:find(phrase,1,true) then return tonumber(level) end
    end
end
ns.HardcoreDeathLevel = HardcoreDeathLevel
local function Decide(self, event, msg, author, ...)
    local p = ns.GetSettings()
    if not p or not p.enabled then return false end
    if not (p.spamFilterEnabled or p.spamFilterKeywordsEnabled or p.spamFilterAchievements or
        p.spamFilterGoldSellers or p.spamFilterTrade or p.spamFilterRecruitment or p.spamFilterHardcoreDeaths) then return false end
    local player, realm = UnitName("player")
    if player and (author==player or (realm and author==player.."-"..realm)) then return false end
    -- arg6 is the sender flag: GM messages are always shown.
    if select(4, ...)=="GM" then return false end
    if p.spamFilterHardcoreDeaths and hardcoreEvents[event] and type(msg)=="string" then
        local level = HardcoreDeathLevel(Normalize(ns.PlainText(msg)))
        -- Deaths at or above the keep level stay visible; 81 hides every death.
        if level then return level < (tonumber(p.spamFilterHardcoreKeepLevel) or 81), "Hardcore" end
    end
    if event=="CHAT_MSG_ACHIEVEMENT" or event=="CHAT_MSG_GUILD_ACHIEVEMENT" then
        return p.spamFilterAchievements and true or false, "Achievement"
    end
    local scope = scopes[event]
    if not scope or type(msg)~="string" or type(author)~="string" or author=="" then return false end
    -- Match visible labels, never hyperlink IDs or invisible colour/texture codes.
    if (scope=="public" and not p.spamFilterPublic) or
       (scope=="group" and not p.spamFilterGroup) or
       (scope=="whispers" and not p.spamFilterWhispers) then return false end
    local visible = Normalize(ns.PlainText(msg))
    if p.spamFilterGoldSellers and GoldSeller(visible) then return true, "Gold Seller" end
    if scope=="public" and p.spamFilterTrade and Trade(visible) then return true, "Trade" end
    if scope=="public" and p.spamFilterRecruitment and Recruitment(visible) then return true, "Recruitment" end
    if p.spamFilterKeywordsEnabled and KeywordMatch(p,visible) then return true, "Keyword" end
    if not p.spamFilterEnabled then return false end
    local text = Normalize(msg)
    if text=="" then return false end
    local now = GetTime()
    local window = math.max(1, math.min(120, tonumber(p.spamFilterWindow) or 15))
    -- arg8 is the channel index; arg11 is Wrath's message line ID.
    local channel, lineID = select(6, ...), select(9, ...)
    local key = event.."\031"..tostring(channel or "").."\031"..
        (p.spamFilterAnySender and "" or author:lower()).."\031"..text
    local decisionKey
    if type(lineID)=="number" and lineID>0 then
        decisionKey=event.."\031"..author.."\031"..tostring(channel or "").."\031"..lineID.."\031"..text
        local prior=decisions.entries[decisionKey]
        -- Each chat window must receive the same decision for one server message.
        if prior and prior.expires>now then return prior.blocked, "Repeat" end
    end
    -- Clients without usable line IDs keep independent window histories.
    local owner=decisionKey and "server" or (self or "fallback")
    local cache=histories[owner]
    if not cache then cache={entries={},count=0}; histories[owner]=cache end
    local previous=cache.entries[key]
    local blocked=previous and previous.expires>now or false
    -- Hidden repeats do not extend the window indefinitely.
    if not blocked then Put(cache,key,{expires=now+window},now) end
    if decisionKey then Put(decisions,decisionKey,{expires=now+window,blocked=blocked},now) end
    return blocked, "Repeat"
end
-- Session log of hidden lines, newest last; one entry per server message even though
-- every chat window showing that chat type runs the filter.
local hiddenLog, logged, loggedCount = {}, {}, 0
local LOG_LIMIT = 200
local function LogHidden(event, msg, author, reason, ...)
    local lineID = select(9, ...)
    local key = event.."\031"..tostring(author).."\031"..
        ((type(lineID)=="number" and lineID>0) and lineID or tostring(msg).."\031"..GetTime())
    if logged[key] then return end
    if loggedCount>=LOG_LIMIT*2 then logged, loggedCount = {}, 0 end
    logged[key]=true; loggedCount=loggedCount+1
    local text = type(msg)=="string" and ns.PlainText(msg) or ""
    if event=="CHAT_MSG_ACHIEVEMENT" or event=="CHAT_MSG_GUILD_ACHIEVEMENT" then
        text = text:gsub("%%s", (tostring(author or ""):gsub("%%","%%%%")))
    end
    local where = event=="CHAT_MSG_CHANNEL" and select(2, ...)
    if type(where)~="string" or where=="" then where = event:gsub("^CHAT_MSG_",""):gsub("_"," ") end
    hiddenLog[#hiddenLog+1] = {time=date("%H:%M:%S"), reason=reason or "?", where=where,
        author=type(author)=="string" and author or "", text=text}
    if #hiddenLog>LOG_LIMIT then table.remove(hiddenLog,1) end
end
function ns.SpamFilter(self, event, msg, author, ...)
    local blocked, reason = Decide(self, event, msg, author, ...)
    if blocked then
        LogHidden(event, msg, author, reason, ...)
        return true
    end
    return false
end
function ns.GetHiddenLog() return hiddenLog end
function ns.ShowHiddenLog()
    local lines = {}
    for i=#hiddenLog,1,-1 do
        local e = hiddenLog[i]
        lines[#lines+1] = e.time.." ["..e.reason.."] ["..e.where.."] "..
            (e.author~="" and e.author..": " or "")..e.text
    end
    if ns.ShowCopy then
        ns.ShowCopy(#lines>0 and table.concat(lines,"\n") or "(No hidden messages this session)",
            "Hidden Messages ("..#hiddenLog..")")
    end
end
function ns.RegisterSpamFilters()
    if registered or not ChatFrame_AddMessageEventFilter then return end
    registered=true
    ChatFrame_AddMessageEventFilter("CHAT_MSG_ACHIEVEMENT",ns.SpamFilter)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD_ACHIEVEMENT",ns.SpamFilter)
    for event in pairs(scopes) do ChatFrame_AddMessageEventFilter(event,ns.SpamFilter) end
    for event in pairs(hardcoreEvents) do
        if not scopes[event] then ChatFrame_AddMessageEventFilter(event,ns.SpamFilter) end
    end
end
