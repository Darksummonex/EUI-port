-------------------------------------------------------------------------------
--  EllesmereUI_Uninstall_335.lua
--  Wrath form of Retail's EllesmereUI_Uninstall.lua: the game settings
--  EllesmereUI changes that outlive it, and the Uninstall EUI action
--  (Global Settings > General) that puts them back.
--
--  Every such change goes through the setters here: CVars, chat window font
--  sizes and the keys EllesmereUI takes for its own commands (EUI_*). The
--  first change of a setting records the value it had before; every change
--  records the value EllesmereUI left. A setting goes back only while it still
--  holds EllesmereUI's value: one the player changed since is theirs.
--
--  Wrath has no Edit Mode, no CVar bitfields and no per-module login pass;
--  override bindings end with the session, so they need nothing. Records are
--  per character (Wrath keeps most interface CVars per character), and
--  DisableAddOn only turns the addons off for the character uninstalling.
--
--  Snapshots are kept only on an account that started on this build or later,
--  or since Uninstall EUI ran (fresh). Elsewhere EllesmereUI may have changed
--  a setting before its first record, so a CVar goes back to the game default.
--
--  Record: EllesmereUIDB.restoreOnUninstall
--    fresh    snapshots are kept
--    bind     [key] = the action it had before (false: none), account set
--    chars    [player GUID] = { cvar = { [lower name] = { n, b, a, o } },
--             chatFont = { [window] = { b, a } }, bind = character set }
-------------------------------------------------------------------------------
local E = EllesmereUI
if not E then return end

local KEY = "restoreOnUninstall"
local _fresh, _uninstalled
local _steps = {}

local function IsFreshAccount(db)
    if type(db) ~= "table" then return true end
    if type(db.profiles) == "table" then
        for _, prof in pairs(db.profiles) do
            if type(prof) == "table" and type(prof.addons) == "table" and next(prof.addons) then return false end
        end
    end
    return true
end

local function Record()
    if type(EllesmereUIDB) ~= "table" then EllesmereUIDB = {} end
    local r = EllesmereUIDB[KEY]
    if type(r) ~= "table" then
        r = { fresh = _fresh or nil }
        EllesmereUIDB[KEY] = r
    end
    return r
end

local function CharRecord(peek)
    local guid = UnitGUID and UnitGUID("player")
    if not guid then return nil end
    local r = Record()
    if not r.chars then
        if peek then return nil end
        r.chars = {}
    end
    local c = r.chars[guid]
    if not c and not peek then c = {}; r.chars[guid] = c end
    return c
end

local function Sub(t, k)
    local s = t[k]
    if not s then s = {}; t[k] = s end
    return s
end

if E.Lite and E.Lite.OnSavedVariablesLoaded then
    E.Lite.OnSavedVariablesLoaded(function()
        local r = type(EllesmereUIDB) == "table" and EllesmereUIDB[KEY]
        if type(r) == "table" then _fresh = r.fresh == true
        else _fresh = IsFreshAccount(EllesmereUIDB) end
    end)
end
local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    if _fresh == nil then _fresh = false end
    Record()
end)

local function GameDefault(name)
    if not GetCVarDefault then return nil end
    local ok, v = pcall(GetCVarDefault, name)
    return ok and v or nil
end

-------------------------------------------------------------------------------
--  CVars
-------------------------------------------------------------------------------
--- SetCVar for a value EllesmereUI applies on its own. owner: the module's
--- addon folder (nil for the core). Returns false once Uninstall ran.
function E.SetCVar(name, value, owner)
    if _uninstalled or not name then return false end
    local before = GetCVar(name)
    SetCVar(name, value)
    if before == nil then return true end
    local c = CharRecord()
    if not c then return true end
    local t = Sub(c, "cvar")
    local key = name:lower()
    local e = t[key]
    if not e then
        e = { n = name, o = owner }
        t[key] = e
        if Record().fresh then e.b = before else e.b = GameDefault(name) end
    end
    e.a = GetCVar(name)
    return true
end

local function RestoreCVars(t)
    if not t then return end
    for _, e in pairs(t) do
        local cur = e.n and GetCVar(e.n)
        if cur ~= nil and cur == e.a and e.b ~= nil and e.b ~= cur then SetCVar(e.n, e.b) end
    end
end

-------------------------------------------------------------------------------
--  Chat windows
-------------------------------------------------------------------------------
--- SetChatWindowSize for a font size EllesmereUI applies on its own.
function E.SetChatWindowSize(index, size)
    if _uninstalled or not SetChatWindowSize then return end
    local _, before = GetChatWindowInfo(index)
    SetChatWindowSize(index, size)
    if before == nil then return end
    local c = CharRecord()
    if not c then return end
    local t = Sub(c, "chatFont")
    local e = t[index]
    if not e then
        e = {}
        t[index] = e
        if Record().fresh then e.b = before end
    end
    local _, after = GetChatWindowInfo(index)
    e.a = after
end

local function RestoreChatFonts(t)
    if not t then return end
    for index, e in pairs(t) do
        local _, cur = GetChatWindowInfo(index)
        if cur ~= nil and cur == e.a and e.b ~= nil and e.b ~= cur then SetChatWindowSize(index, e.b) end
    end
end

-------------------------------------------------------------------------------
--  Key bindings
-------------------------------------------------------------------------------
--- Before EllesmereUI binds key to one of its own commands (EUI_*): records
--- the action the key had then. An empty key or one of EllesmereUI's own
--- commands never replaces an action already recorded.
function E.NoteBinding(key, before)
    if not key then return end
    local root
    if GetCurrentBindingSet and GetCurrentBindingSet() == 2 then root = CharRecord() else root = Record() end
    if not root then return end
    local t = Sub(root, "bind")
    local action = type(before) == "string" and before ~= "" and not before:find("^EUI_") and before or false
    if t[key] == nil or action then t[key] = action end
end

-- A key EllesmereUI took goes back to its earlier action while the key is
-- still on one of EllesmereUI's commands, or empty. Returns the binding set.
local function RestoreBindings(acct, mine)
    local set = GetCurrentBindingSet and GetCurrentBindingSet() or 1
    local rec
    if set == 2 then rec = mine.bind else rec = acct.bind end
    if rec then
        local changed = false
        for key, before in pairs(rec) do
            local action = GetBindingAction(key)
            if before and type(action) == "string" and (action == "" or action:find("^EUI_")) then
                SetBinding(key, before)
                changed = true
            end
        end
        if changed and SaveBindings then SaveBindings(set) end
    end
    return set
end

-------------------------------------------------------------------------------
--  Uninstall EUI
-------------------------------------------------------------------------------
--- Adds a step Uninstall runs before EllesmereUI turns off: for changes only
--- its module knows how to undo.
function E.OnUninstall(fn)
    _steps[#_steps + 1] = fn
end

--- True when the record holds the settings from before EllesmereUI (false:
--- CVars go back to the game's defaults instead).
function E.UninstallKnowsOriginals()
    local r = type(EllesmereUIDB) == "table" and EllesmereUIDB[KEY]
    return type(r) == "table" and r.fresh == true
end

function E.IsUninstalled() return _uninstalled == true end

local function OwnAddOns()
    local list = {}
    for i = 1, GetNumAddOns() do
        local name = GetAddOnInfo(i)
        if name and name:find("^EllesmereUI") then list[#list + 1] = name end
    end
    return list
end

--- Puts back the settings EllesmereUI changed and turns its addons off for
--- this character; the caller reloads. Refused in combat (bindings and some
--- CVars cannot change then). Returns true when it ran.
function E.Uninstall()
    if _uninstalled or InCombatLockdown() then return false end
    _uninstalled = true
    local r = Record()
    local mine = CharRecord(true) or {}
    if pcall(RestoreCVars, mine.cvar) then mine.cvar = nil end
    if pcall(RestoreChatFonts, mine.chatFont) then mine.chatFont = nil end
    local okBind, set = pcall(RestoreBindings, r, mine)
    if okBind then
        if set == 2 then mine.bind = nil else r.bind = nil end
    end
    for i = 1, #_steps do pcall(_steps[i]) end
    r.fresh = true
    for _, name in ipairs(OwnAddOns()) do DisableAddOn(name) end
    return true
end
