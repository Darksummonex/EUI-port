-- Blocks_335\MicroMenu.lua
-- Micro menu block factory (3.3.5 port of Retail Blocks\MicroMenu.lua).
-- Every button is our own plain Button calling the client's insecure toggle
-- functions out of combat. The Blizzard micro buttons belong to the EllesmereUI
-- ActionBars HUD: this block never touches, hides, re-parents or clicks them.
local _, ns = ...
if not ns.IsWrath then return end
local L = ns.L
local K = ns.BlockKit
local E = EllesmereUI

-- Upvalues
local _G               = _G
local CreateFrame      = CreateFrame
local InCombatLockdown = InCombatLockdown
local GetTime          = GetTime
local pairs            = pairs
local ipairs           = ipairs
local type             = type
local pcall            = pcall
local format           = string.format
local tconcat          = table.concat
local floor            = math.floor
local max              = math.max

local CONTENT_BASE         = K.CONTENT_BASE
local InstKey              = K.InstKey
local MakeEventFrame       = K.MakeEventFrame
local RegisterInstEvents   = K.RegisterInstEvents
local UnregisterInstEvents = K.UnregisterInstEvents
local MaybeRelayout        = K.MaybeRelayout
local AttachTextOffset     = K.AttachTextOffset
local BlockColorOf         = K.BlockColorOf
local Size                 = ns.Size

-------------------------------------------------------------------------------
--  MICROMENU (insecure: plain buttons, toggles refused in combat)
-------------------------------------------------------------------------------
local MM_SPACING = 2
local MM_MEDIA = ns.MICROMENU_MEDIA

-- Button key -> icon file in Media_335\micromenu\ (TGA, no extension).
-- No talent glyph ships with the set; the professions glyph stands in so the
-- Talents button does not repeat the Spellbook glyph right beside it.
local MM_ICON_FILE = {
    menu   = "menu-options",
    guild  = "menu-guild",
    social = "menu-friends",
    char   = "menu-character",
    spell  = "menu-spellbook",
    talent = "menu-professions",
    ach    = "menu-achievements",
    quest  = "menu-quests",
    lfg    = "menu-group",
    pvp    = "menu-pvp",
    help   = "menu-cs",
}

-- Wrath splits the spellbook and the talents into two micro buttons (as WoW
-- Forever does on Retail), so Talents follows Spellbook and reads a missing
-- setting as on.
local mmButtonDefs = {
    { key = 'menu',   binding = 'TOGGLEGAMEMENU',    label = MAINMENU_BUTTON or 'Game Menu' },
    { key = 'guild',  binding = 'TOGGLEGUILDTAB',    label = GUILD or 'Guild',                       info = true },
    { key = 'social', binding = 'TOGGLESOCIAL',      label = SOCIAL_LABEL or SOCIAL_BUTTON or 'Social', info = true },
    { key = 'char',   binding = 'TOGGLECHARACTER0',  label = CHARACTER_BUTTON or 'Character Info' },
    { key = 'spell',  binding = 'TOGGLESPELLBOOK',   label = SPELLBOOK_ABILITIES_BUTTON or SPELLBOOK or 'Spellbook' },
    { key = 'talent', binding = 'TOGGLETALENTS',     label = TALENTS_BUTTON or TALENTS or 'Talents', onWhenUnset = true },
    { key = 'ach',    binding = 'TOGGLEACHIEVEMENT', label = ACHIEVEMENT_BUTTON or ACHIEVEMENTS or 'Achievements' },
    { key = 'quest',  binding = 'TOGGLEQUESTLOG',    label = QUESTLOG_BUTTON or QUEST_LOG or 'Quest Log' },
    { key = 'lfg',    binding = 'TOGGLELFGPARENT',   label = DUNGEONS_BUTTON or LOOKING_FOR_DUNGEON or 'Dungeon Finder' },
    { key = 'pvp',    binding = 'TOGGLECHARACTER4',  label = PLAYER_V_PLAYER or PVP_OPTIONS or 'PvP' },
    { key = 'help',   binding = false,               label = HELP_BUTTON or 'Help Request' },
}
local mmButtonOrder = {}
local mmButtonDefsByKey = {}
for _, def in ipairs(mmButtonDefs) do
    mmButtonOrder[#mmButtonOrder + 1] = def.key
    mmButtonDefsByKey[def.key] = def
end

-- Whether a block shows one button. A button added after blocks were saved
-- (onWhenUnset) reads a missing setting as on, as the options checklist does.
local function MMButtonOn(mm, key)
    local v = mm[key]
    if v == nil then
        local def = mmButtonDefsByKey[key]
        return def and def.onWhenUnset or false
    end
    return v
end

local function MMError(msg)
    if msg and UIErrorsFrame then UIErrorsFrame:AddMessage(msg, 1.0, 0.1, 0.1, 1.0) end
end

-- Level-gated panels: refuse with Blizzard's own wording when it exists.
local function MMLevelGate(minLevel)
    if (UnitLevel("player") or 0) >= minLevel then return true end
    if FEATURE_BECOMES_AVAILABLE_AT_LEVEL then MMError(format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, minLevel)) end
    return false
end

local function MMTogglePanel(frame)
    if not frame then return end
    if frame:IsShown() then HideUIPanel(frame) else ShowUIPanel(frame) end
end

-- Click handlers. Shared table: they close over no instance state. Panels are
-- protected in combat on this client, so every action is refused in lockdown
-- (Retail's secure buttons drop their click action there the same way).
local mmClickFunctions = {}
mmClickFunctions.menu = function(_, button)
    if InCombatLockdown() then MMError(L["CANNOT_USE_COMBAT"]); return end
    if button == "LeftButton" then
        if GameMenuFrame then MMTogglePanel(GameMenuFrame) end
    elseif button == "RightButton" then
        if IsShiftKeyDown() then
            if E and E.RequestReload then
                local Loc = E.L or function(s) return s end
                E.RequestReload(Loc("Reload UI"), Loc("Reload the UI now?"))
            else
                ReloadUI()
            end
        elseif _G.AddonList then
            ToggleFrame(_G.AddonList)
        end
    end
end
mmClickFunctions.guild = function()
    if not IsInGuild() then MMError(ERR_GUILD_PLAYER_NOT_IN_GUILD or L["NOT_IN_GUILD"]); return end
    if ToggleFriendsFrame then ToggleFriendsFrame(3) end
end
mmClickFunctions.social = function()
    if ToggleFriendsFrame then ToggleFriendsFrame(1) end
end
mmClickFunctions.char = function()
    if ToggleCharacter then ToggleCharacter("PaperDollFrame") end
end
mmClickFunctions.spell = function()
    if ToggleSpellBook then ToggleSpellBook(BOOKTYPE_SPELL or "spell") end
end
mmClickFunctions.talent = function()
    if not MMLevelGate(SHOW_TALENT_LEVEL or 10) then return end
    if ToggleTalentFrame then ToggleTalentFrame() end
end
mmClickFunctions.ach = function()
    if ToggleAchievementFrame then ToggleAchievementFrame() end
end
mmClickFunctions.quest = function()
    if ToggleQuestLog then ToggleQuestLog()
    elseif QuestLogFrame then ToggleFrame(QuestLogFrame) end
end
mmClickFunctions.lfg = function()
    if not MMLevelGate(SHOW_LFD_LEVEL or 15) then return end
    if ToggleLFDParentFrame then ToggleLFDParentFrame() end
end
mmClickFunctions.pvp = function()
    if not MMLevelGate(SHOW_PVP_LEVEL or 10) then return end
    if TogglePVPFrame then TogglePVPFrame() end
end
mmClickFunctions.help = function()
    if ToggleHelpFrame then ToggleHelpFrame() end
end

-- Every non-menu button acts on left click only (Retail's *clickbutton1).
local function MMDispatchClick(key, frame, button)
    local fn = mmClickFunctions[key]
    if not fn then return end
    if key == "menu" then fn(frame, button); return end
    if button ~= "LeftButton" then return end
    if InCombatLockdown() then MMError(L["CANNOT_USE_COMBAT"]); return end
    fn(frame, button)
end

-- Character stats tooltip (always on). Fixed set: equipped item level, primary
-- stat, and the secondary percentages with raw combat rating in parentheses.
-- Wrath has no Mastery or Versatility (same set as Retail's WoW Forever path).
local CS_DIM = "|cffaaaaaa"

-- Equipped average item level: 17 gear slots (shirt and tabard excluded), a
-- two-hander fills the off-hand slot, empty slots count as zero.
local MM_ILVL_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }
local function MMAverageItemLevel()
    local total, missing = 0, false
    local mhLevel, mhTwoHand = 0, false
    for _, slot in ipairs(MM_ILVL_SLOTS) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local _, _, _, level, _, _, _, _, equipLoc = GetItemInfo(link)
            if level then
                total = total + level
                if slot == 16 then mhLevel, mhTwoHand = level, equipLoc == "INVTYPE_2HWEAPON" end
            else
                missing = true
            end
        elseif slot == 17 and mhTwoHand then
            total = total + mhLevel
        end
    end
    if missing then return nil end
    return total / #MM_ILVL_SLOTS
end

-- No specialization primary stat on this client: the highest effective of
-- Strength / Agility / Intellect stands in for it.
local MM_PRIMARY = {
    { 1, SPELL_STAT1_NAME or "Strength" },
    { 2, SPELL_STAT2_NAME or "Agility" },
    { 4, SPELL_STAT4_NAME or "Intellect" },
}
local function MMPrimaryStat()
    local bestLabel, bestVal
    for _, p in ipairs(MM_PRIMARY) do
        local _, eff = UnitStat("player", p[1])
        if eff and (not bestVal or eff > bestVal) then bestLabel, bestVal = p[2], eff end
    end
    return bestLabel, bestVal
end

-- Crit: the highest of melee / ranged / spell (spell = lowest school, as
-- Retail's PlayerCritChance reads it). Haste follows the same pick.
local function MMCritAndHaste()
    local melee = GetCritChance and GetCritChance() or 0
    local ranged = GetRangedCritChance and GetRangedCritChance() or 0
    local spell = 0
    if GetSpellCritChance then
        spell = GetSpellCritChance(2) or 0
        for i = 3, MAX_SPELL_SCHOOLS or 7 do
            local s = GetSpellCritChance(i)
            if s and s < spell then spell = s end
        end
    end
    local crit, critCR, hasteCR = melee, CR_CRIT_MELEE or 9, CR_HASTE_MELEE or 18
    if ranged > crit then crit, critCR, hasteCR = ranged, CR_CRIT_RANGED or 10, CR_HASTE_RANGED or 19 end
    if spell > crit then crit, critCR, hasteCR = spell, CR_CRIT_SPELL or 11, CR_HASTE_SPELL or 20 end
    return crit, critCR, (GetCombatRatingBonus and GetCombatRatingBonus(hasteCR)) or 0, hasteCR
end

local function MMAddCharStats()
    local ar, ag, ab = ns.GetAccent()
    local function pctRating(label, pct, rating)
        if not (pct and rating) then return end
        ns.Tip_AddDouble(label,
            format("%.2f%%", pct) .. " " .. CS_DIM .. "(" .. floor(rating + 0.5) .. ")|r",
            ar, ag, ab, 1, 1, 1)
    end

    ns.Tip_AddLine(" ")

    local eq = MMAverageItemLevel()
    if eq then
        ns.Tip_AddDouble(STAT_AVERAGE_ITEM_LEVEL or "Item Level", format("%.1f", eq), ar, ag, ab, 1, 1, 1)
    end

    local pLabel, pVal = MMPrimaryStat()
    if pLabel and pVal then
        ns.Tip_AddDouble(pLabel, format("%.0f", pVal), ar, ag, ab, 1, 1, 1)
    end

    local crit, critCR, haste, hasteCR = MMCritAndHaste()
    pctRating(STAT_CRITICAL_STRIKE or "Critical Strike", crit, GetCombatRating(critCR))
    pctRating(STAT_HASTE or "Haste", haste, GetCombatRating(hasteCR))
end

-- Interactive Social / Guild tooltips (always on): online member lists built on
-- the owned Tip system's insecure clickable-row primitive (Tip_AddClickable).
-- Every action (whisper/invite) is unprotected, so rows stay clickable in and
-- out of combat. Shift is the fixed invite modifier.

-- Whisper: a Real ID friend by presence name when the client can route it
-- (ChatFrame_SendSmartTell), everyone else by character name.
local function MMOpenWhisper(charName, bnetName)
    if bnetName and bnetName ~= "" and ChatFrame_SendSmartTell then
        ChatFrame_SendSmartTell(bnetName, DEFAULT_CHAT_FRAME)
        return
    end
    if charName and charName ~= "" and ChatFrame_SendTell then
        ChatFrame_SendTell(charName, DEFAULT_CHAT_FRAME)
    end
end

local function MMInvite(name)
    if name and name ~= "" and InviteUnit then InviteUnit(name) end
end

local FRIEND_TEX_ONLINE = FRIENDS_TEXTURE_ONLINE or "Interface\\FriendsFrame\\StatusIcon-Online"
local FRIEND_TEX_AFK    = FRIENDS_TEXTURE_AFK or "Interface\\FriendsFrame\\StatusIcon-Away"
local FRIEND_TEX_DND    = FRIENDS_TEXTURE_DND or "Interface\\FriendsFrame\\StatusIcon-DnD"

local function MMClassRGB(token)
    if token and E and E.GetClassColor then
        local cc = E.GetClassColor(token)
        if cc then return cc.r, cc.g, cc.b end
    end
    local cc = token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    if cc then return cc.r, cc.g, cc.b end
end

local function MMClassToken(localized)
    if not localized then return nil end
    if E and E.ClassTokenFromLocalized then return E.ClassTokenFromLocalized(localized) end
    for token, n in pairs(LOCALIZED_CLASS_NAMES_MALE or {}) do if n == localized then return token end end
    for token, n in pairs(LOCALIZED_CLASS_NAMES_FEMALE or {}) do if n == localized then return token end end
end

-- BNGetToonInfo's faction arrives as a token string or as 0 (Horde) / 1 (Alliance).
local function MMSameFaction(faction)
    if faction == nil then return true end
    local mine = UnitFactionGroup("player")
    if type(faction) == "number" then faction = (faction == 0 and "Horde") or (faction == 1 and "Alliance") or nil end
    return faction == nil or faction == mine
end

-- GuildRoster() fires GUILD_ROSTER_UPDATE and the server rate-limits it (~10s);
-- throttle so hovering the guild button does not spam requests.
local mmLastTipRoster = 0

-- Member rows per tooltip: a big friend list or guild otherwise grows it past
-- the screen. The rest become one "...and N more" line.
local MM_TIP_MAX_ROWS = 30

local function MMOnlineFriendCount()
    local total, online = 0, 0
    if GetNumFriends then total, online = GetNumFriends() end
    if online == nil then
        online = 0
        for i = 1, total or 0 do
            local _, _, _, _, connected = GetFriendInfo(i)
            if connected then online = online + 1 end
        end
    end
    return online or 0
end

local function MMBuildSocialTip()
    local ar, ag, ab = ns.GetAccent()
    local totalBN = (BNGetNumFriends and BNGetNumFriends()) or 0
    local myRealm = GetRealmName()

    ns.Tip_AddLine(" ")

    -- Only people actually in WoW: Real ID friends on another program add nothing here.
    local shown, hidden = 0, 0

    if BNGetFriendInfo then
        for i = 1, totalBN do
            local _, givenName, surname, toonName, toonID, client, isOnline, _, isAFK, isDND = BNGetFriendInfo(i)
            local inWoW = isOnline and client == (BNET_CLIENT_WOW or "WoW")
            if inWoW and shown >= MM_TIP_MAX_ROWS then
                hidden = hidden + 1
            elseif inWoW then
                local realmName, faction, className, area
                if toonID and BNGetToonInfo then
                    local ok, _, tName, _, rName, fac, _, cls, _, zone = pcall(BNGetToonInfo, toonID)
                    if ok then
                        toonName = tName or toonName
                        realmName, faction, className, area = rName, fac, cls, zone
                    end
                end
                local icon = FRIEND_TEX_ONLINE
                if isAFK then icon = FRIEND_TEX_AFK end
                if isDND then icon = FRIEND_TEX_DND end
                local accountName = givenName or "?"
                if surname and surname ~= "" then accountName = accountName .. " " .. surname end
                -- Left text carries NO |c codes so hover recolor (Tip_Show) shows; its blue rides the left-color args.
                local left = format("|T%s:16|t %s", icon, accountName)
                local nameText
                local cr, cg, cb = MMClassRGB(MMClassToken(className))
                if cr and toonName then
                    nameText = format("|cff%02x%02x%02x%s|r", floor(cr * 255), floor(cg * 255), floor(cb * 255), toonName)
                else
                    nameText = format("|cffecd672%s|r", toonName or "?")
                end
                local right = format("%s %s", nameText, area or "")
                local bnetName = accountName
                -- Invites only reach the same realm and faction on this client.
                local canInvite = toonName and MMSameFaction(faction)
                    and (realmName == nil or realmName == "" or realmName == myRealm)
                local inviteName = toonName
                ns.Tip_AddClickable(left, right, function(mouseButton)
                    if mouseButton == "LeftButton" then
                        if IsShiftKeyDown() and canInvite then
                            MMInvite(inviteName)
                        else
                            MMOpenWhisper(inviteName, bnetName)
                        end
                    elseif mouseButton == "RightButton" and canInvite then
                        MMOpenWhisper(inviteName, nil)
                    end
                end, 0.51, 0.77, 1, 1, 1, 1)
                shown = shown + 1
            end
        end
    end

    -- WoW (non-Real ID) friends.
    local numFriends = (GetNumFriends and GetNumFriends()) or 0
    for i = 1, numFriends do
        local name, level, className, area, connected, status = GetFriendInfo(i)
        if connected and shown >= MM_TIP_MAX_ROWS then
            hidden = hidden + 1
        elseif connected then
            local icon = FRIEND_TEX_ONLINE
            if type(status) == "string" and status ~= "" then
                local up = status:upper()
                if up:find("DND") or (CHAT_FLAG_DND and status == CHAT_FLAG_DND) then icon = FRIEND_TEX_DND
                else icon = FRIEND_TEX_AFK end
            end
            -- No |c codes on the left (hover recolor needs a plain string); the class
            -- colour rides the left-color args (white when the class is unknown).
            local left = format("|T%s:16|t %s  %s", icon, name or "?", level or "")
            local cr, cg, cb = MMClassRGB(MMClassToken(className))
            if not cr then cr, cg, cb = 1, 1, 1 end
            local fname = name
            ns.Tip_AddClickable(left, area or "", function(mouseButton)
                if not fname then return end
                if mouseButton == "RightButton" then
                    MMOpenWhisper(fname, nil)
                elseif mouseButton == "LeftButton" and IsShiftKeyDown() then
                    MMInvite(fname)
                end
            end, cr, cg, cb, 0.8, 0.8, 0.8)
            shown = shown + 1
        end
    end

    if shown == 0 then
        ns.Tip_AddLine(L["NO_FRIENDS_ONLINE"], 0.6, 0.6, 0.6)
        return
    end
    if hidden > 0 then ns.Tip_AddLine(format("...and %d more", hidden), 0.53, 0.53, 0.53) end

    -- Left click whispers the Real ID friend (or does nothing for a plain friend),
    -- right click whispers the character directly.
    ns.Tip_AddLine(" ")
    if totalBN > 0 then
        ns.Tip_AddDouble(L["LEFT_CLICK"], L["WHISPER_BNET"] or "Whisper (Real ID)", 1, 1, 1, ar, ag, ab)
    end
    ns.Tip_AddDouble(L["SHIFT_LEFT_CLICK"], L["INVITE"],  1, 1, 1, ar, ag, ab)
    ns.Tip_AddDouble(L["RIGHT_CLICK"],      L["WHISPER"], 1, 1, 1, ar, ag, ab)
end

local function MMGuildStatus(status)
    if type(status) == "string" then return status end
    if status == 1 then return DEFAULT_AFK_MESSAGE or CHAT_FLAG_AFK or "" end
    if status == 2 then return DEFAULT_DND_MESSAGE or CHAT_FLAG_DND or "" end
    return ""
end

local function MMBuildGuildTip()
    local ar, ag, ab = ns.GetAccent()
    ns.Tip_AddLine(" ")
    if not IsInGuild() then
        ns.Tip_AddLine(L["NOT_IN_GUILD"], 0.6, 0.6, 0.6)
        return
    end

    local now = GetTime()
    if not InCombatLockdown() and (now - mmLastTipRoster) >= 10 then
        mmLastTipRoster = now
        GuildRoster()
    end

    local gName = GetGuildInfo("player")
    if gName then ns.Tip_AddLine("|cff00ff00" .. gName .. "|r") end

    local shown, hidden = 0, 0
    for i = 1, (GetNumGuildMembers(true) or 0) do
        local name, _, _, level, className, zone, _, _, isOnline, status, classFile = GetGuildRosterInfo(i)
        if isOnline and shown >= MM_TIP_MAX_ROWS then
            hidden = hidden + 1
        elseif isOnline then
            shown = shown + 1
            local clr, clg, clb = MMClassRGB(classFile or MMClassToken(className))
            if not clr then clr, clg, clb = 1, 1, 1 end
            local st = MMGuildStatus(status)
            local cn = name and name:match("[^-]+") or "?"
            -- Left plain (no |c): the class color rides the left-color args so the hover recolor to accent shows.
            local left  = format("%s  %s %s", level or "", cn, st)
            local fname = name
            ns.Tip_AddClickable(left, zone or "", function(mouseButton)
                if not fname then return end
                if mouseButton == "LeftButton" then
                    if IsShiftKeyDown() then MMInvite(fname)
                    else MMOpenWhisper(fname, nil) end
                end
            end, clr, clg, clb, 1, 1, 1)
        end
    end
    if hidden > 0 then ns.Tip_AddLine(format("...and %d more", hidden), 0.53, 0.53, 0.53) end

    ns.Tip_AddLine(" ")
    ns.Tip_AddDouble(L["LEFT_CLICK"],       L["WHISPER"], 1, 1, 1, ar, ag, ab)
    ns.Tip_AddDouble(L["SHIFT_LEFT_CLICK"], L["INVITE"],  1, 1, 1, ar, ag, ab)
end

local function MMOnlineGuildCount()
    local online = 0
    for i = 1, (GetNumGuildMembers(true) or 0) do
        local _, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
        if isOnline then online = online + 1 end
    end
    return online
end

ns.BlockFactories.micromenu = function(blockCfg, slot, content, barCtx)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)
    inst.events = {
        "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE",
        "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE",
        "FRIENDLIST_UPDATE",
        "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PLAYER_ENTERING_WORLD",
    }

    -- Per-instance button sets.
    local frames = {}
    local icons = {}
    local textFS = {}
    local bgTexture = {}
    local lastRosterRequest = 0

    local function D() return blockCfg.settings or {} end
    local function BC() return barCtx.cfg end

    local function GetIconSize()
        -- Fixed content size: bar Height never scales icons (Content Scale does).
        return max(16, floor(CONTENT_BASE * 0.82 + 0.5))
    end

    local function SocialFontSize()
        -- 0.3667 ratio = 11px at the 30px base.
        return max(7, floor(CONTENT_BASE * 0.3667 + 0.5))
    end

    local function ShowButtonTooltip(name)
        local frame = frames[name]; if not frame then return end
        local def = mmButtonDefsByKey[name]; if not def then return end
        local r, g, b = 1, 1, 1
        ns.Tip_Begin(frame)
        local title = '|cFFFFFFFF' .. (def.label or name) .. '|r'
        if def.binding then
            local k1, k2 = GetBindingKey(def.binding)
            local keys = {}
            if k1 and k1 ~= '' then keys[#keys + 1] = GetBindingText(k1, "KEY_") end
            if k2 and k2 ~= '' then keys[#keys + 1] = GetBindingText(k2, "KEY_") end
            if #keys > 0 then
                title = title .. ' |cFFFFD200(' .. tconcat(keys, ' / ') .. ')|r'
            end
        end
        ns.Tip_AddLine(title, r, g, b)

        if name == 'ach' then
            local pts = 0
            if GetTotalAchievementPoints then pts = GetTotalAchievementPoints() or 0 end
            local hexAccent = format('%02x%02x%02x', floor(r * 255), floor(g * 255), floor(b * 255))
            ns.Tip_AddLine(" ")
            ns.Tip_AddDouble('|cFFFFFFFF' .. L["ACH_POINTS"] .. '|r', '|cFF' .. hexAccent .. pts .. '|r', 1, 1, 1, r, g, b)
        end

        -- pcall is a last resort so an API surprise never kills the rest of the tooltip.
        if name == 'char' then pcall(MMAddCharStats) end
        if name == 'social' then pcall(MMBuildSocialTip) end
        if name == 'guild'  then pcall(MMBuildGuildTip)  end

        ns.Tip_Show()
    end

    -- Per-button hover/click wiring. Runs once per frame, at creation time.
    local function SetupButtonScripts(name, frame)
        frame:EnableMouse(true)
        frame:RegisterForClicks("AnyUp")
        frame:SetScript("OnClick", function(self, button) MMDispatchClick(name, self, button) end)

        frame:SetScript("OnEnter", function()
            -- Hover tint stays alive in combat (our textures/fonts only).
            local r, g, b = ns.GetAccent()
            if icons[name] then
                icons[name]:SetVertexColor(r, g, b, 1)
            end
            -- The counter text (guild/social) follows its button's hover.
            if textFS[name] then
                textFS[name]:SetTextColor(r, g, b, 1)
            end
            if InCombatLockdown() then
                -- Clicks are refused in lockdown; say so instead of the full tooltip.
                local def = mmButtonDefsByKey[name]
                ns.Tip_Begin(frame)
                ns.Tip_AddLine('|cFFFFFFFF' .. ((def and def.label) or name) .. '|r', 1, 1, 1)
                ns.Tip_AddLine(L["CANNOT_USE_COMBAT"], 0.65, 0.65, 0.65)
                ns.Tip_Show()
                return
            end
            ShowButtonTooltip(name)
        end)
        frame:SetScript("OnLeave", function()
            local br, bgr, bb = BlockColorOf(blockCfg)
            if icons[name] then icons[name]:SetVertexColor(br, bgr, bb, 1) end
            if textFS[name] then textFS[name]:SetTextColor(br, bgr, bb, 1) end
            ns.Tip_HideUnlessInteractive(frame)
        end)
    end

    -- Create one button frame (idempotent). Plain frames: safe at any time.
    local function EnsureButtonFrame(def)
        local key = def.key
        if frames[key] then return frames[key] end
        local frame = CreateFrame("Button", "EWB_MM_" .. inst.key .. "_" .. key, content)
        frames[key] = frame
        if def.info then
            textFS[key]    = frame:CreateFontString(nil, "OVERLAY")
            bgTexture[key] = frame:CreateTexture(nil, "OVERLAY")
            AttachTextOffset(inst, textFS[key])
        end
        icons[key] = frame:CreateTexture(nil, "OVERLAY")
        icons[key]:SetTexture(MM_MEDIA .. (MM_ICON_FILE[key] or key))
        SetupButtonScripts(key, frame)
        return frame
    end

    -- Materialise buttons for every enabled key.
    local function CreateFramesInner()
        local mm = D()
        for _, def in ipairs(mmButtonDefs) do
            if MMButtonOn(mm, def.key) then EnsureButtonFrame(def) end
        end
    end

    local function CounterColor(key, fs)
        -- Keep the hover tint if a roster event repaints mid-hover.
        if frames[key] and ns.MouseOver(frames[key]) then
            local ar, ag, ab = ns.GetAccent()
            fs:SetTextColor(ar, ag, ab, 1)
        else
            fs:SetTextColor(BlockColorOf(blockCfg))
        end
    end

    local function UpdateGuildText()
        local mm = D()
        if not textFS.guild or not MMButtonOn(mm, "guild") or mm.hideSocialText then return end
        if not IsInGuild() then
            textFS.guild:Hide()
            if bgTexture.guild then bgTexture.guild:Hide() end
            return
        end
        -- Throttled: GuildRoster() itself fires GUILD_ROSTER_UPDATE, which re-enters this function; unthrottled that is a request loop.
        local now = GetTime()
        if not InCombatLockdown() and (now - lastRosterRequest) >= 15 then
            lastRosterRequest = now
            GuildRoster()
        end
        ns.SetFont(textFS.guild, SocialFontSize(), BC())
        CounterColor("guild", textFS.guild)
        textFS.guild:SetText(MMOnlineGuildCount())
        -- Plain button-center anchor: the block's Text Position offsets are the ONE positioning input (the wrapper injects them here).
        textFS.guild:ClearAllPoints()
        textFS.guild:SetPoint('CENTER', frames.guild, 'CENTER', 0, 0)
        if bgTexture.guild then
            bgTexture.guild:ClearAllPoints()
            bgTexture.guild:SetPoint('CENTER', textFS.guild)
            ns.Solid(bgTexture.guild, 0.04, 0.04, 0.04, 0.85)
            bgTexture.guild:Show()
        end
        textFS.guild:Show()
    end

    local function UpdateFriendText()
        local mm = D()
        if mm.hideSocialText or not MMButtonOn(mm, "social") or not textFS.social then return end
        local bnOnline = 0
        if BNGetNumFriends then
            local _, on = BNGetNumFriends()
            bnOnline = on or 0
        end
        local total = bnOnline + MMOnlineFriendCount()
        ns.SetFont(textFS.social, SocialFontSize(), BC())
        CounterColor("social", textFS.social)
        textFS.social:SetText(total)
        -- Plain button-center anchor (see the guild counter note).
        textFS.social:ClearAllPoints()
        textFS.social:SetPoint('CENTER', frames.social, 'CENTER', 0, 0)
        if bgTexture.social then
            bgTexture.social:ClearAllPoints()
            bgTexture.social:SetPoint('CENTER', textFS.social)
            ns.Solid(bgTexture.social, 0.04, 0.04, 0.04, 0.85)
        end
        textFS.social:Show()
    end

    function inst:Refresh()
        if self._dead then return end
        content:Show()

        local mm = D()
        -- Materialise any buttons enabled after creation (options toggle).
        CreateFramesInner()
        if not next(frames) then return end
        local ICON_SIZE = GetIconSize()
        local isVertical = barCtx.IsVertical()
        local totalWidth, totalHeight, prev = 0, 0, nil
        for _, key in ipairs(mmButtonOrder) do
            local frame = frames[key]
            -- Hide buttons toggled off after creation; lay out enabled ones.
            if frame and not MMButtonOn(mm, key) then
                frame:Hide()
                frame = nil
            end
            if frame then
                frame:Show()
                Size(frame, ICON_SIZE, ICON_SIZE)
                if icons[key] then
                    icons[key]:ClearAllPoints()
                    icons[key]:SetPoint("CENTER")
                    -- The drawn image sits 6px smaller than the button (click target and
                    -- layout keep ICON_SIZE). Uniform for the whole set, no per-button special cases.
                    local iconSize = max(8, ICON_SIZE - 6)
                    Size(icons[key], iconSize, iconSize)
                    if ns.MouseOver(frame) then
                        icons[key]:SetVertexColor(ns.GetAccent())
                    else
                        icons[key]:SetVertexColor(BlockColorOf(blockCfg))
                    end
                end
                frame:ClearAllPoints()
                local spacing = mm.iconSpacing or MM_SPACING
                if prev and prev == frames.menu then spacing = mm.mainMenuSpacing or 4 end
                if not prev then
                    if isVertical then frame:SetPoint("TOP", content, "TOP", 0, 0)
                    else               frame:SetPoint("LEFT", content, "LEFT", 0, 0) end
                else
                    if isVertical then frame:SetPoint("TOP", prev, "BOTTOM", 0, -spacing)
                    else               frame:SetPoint("LEFT", prev, "RIGHT", spacing, 0) end
                end
                local prevSpacing = 0
                if prev then prevSpacing = spacing end
                if isVertical then
                    totalHeight = totalHeight + ICON_SIZE + prevSpacing
                    totalWidth  = max(totalWidth, ICON_SIZE)
                else
                    totalWidth  = totalWidth + ICON_SIZE + prevSpacing
                    totalHeight = max(totalHeight, ICON_SIZE)
                end
                prev = frame
            end
        end

        Size(content, max(totalWidth, 1), max(totalHeight, 1))

        if mm.hideSocialText then
            for _, fs in pairs(textFS) do fs:Hide() end
            for _, tex in pairs(bgTexture) do tex:Hide() end
        else
            UpdateFriendText(); UpdateGuildText()
        end
        MaybeRelayout(inst)
    end

    inst.eventFrame = MakeEventFrame(inst, function(self, event)
        if self._dead then return end
        if event == 'GUILD_ROSTER_UPDATE' or event == 'PLAYER_GUILD_UPDATE' then
            UpdateGuildText()
        elseif event == 'BN_FRIEND_ACCOUNT_ONLINE'
            or event == 'BN_FRIEND_ACCOUNT_OFFLINE'
            or event == 'FRIENDLIST_UPDATE' then
            UpdateFriendText()
        else
            -- REGEN x2 / PLAYER_ENTERING_WORLD: re-assert the strip and its counters.
            self:Refresh()
        end
    end)

    CreateFramesInner()

    function inst:Enable()
        content:Show()
        RegisterInstEvents(self)
    end

    function inst:Disable()
        UnregisterInstEvents(self)
        for _, frame in pairs(frames) do ns.Tip_Hide(frame) end
        content:Hide()
    end

    function inst:GetAutoLength()
        local mm = D()
        local ICON_SIZE = GetIconSize()
        local count = 0
        for _, key in ipairs(mmButtonOrder) do
            if frames[key] and MMButtonOn(mm, key) then count = count + 1 end
        end
        if count == 0 then return 50 end
        local spacing = mm.iconSpacing or 2
        return max(count * ICON_SIZE + (count - 1) * spacing, 50)
    end

    function inst:Destroy()
        self._dead = true
        UnregisterInstEvents(self)
        for _, frame in pairs(frames) do
            ns.Tip_Hide(frame)
            frame:Hide()
            frame:SetParent(ns._park)
        end
        content:Hide()
    end

    return inst
end
