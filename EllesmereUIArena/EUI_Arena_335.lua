-- Wrath arena enemy frames: arena1-5 secure unit buttons, PvP trinket and crowd control tracking.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
local addon=E.Lite.NewAddon(ADDON_NAME)
E._ModuleNS[ADDON_NAME]=ns
ns.addon,ns.IsWrath=addon,true
local function RGB(r,g,b) return {r=r,g=g,b=b} end
local defaults={profile={enabled=true,hideBlizzard=true,previewCount=3,
    width=190,height=38,spacing=16,growth="DOWN",borderSize=1,
    texture="atrocity",classColored=true,healthColor=RGB(.2,.75,.25),bgDarkness=75,showPower=true,powerHeight=6,
    nameSize=12,classColoredNames=false,healthText="percent",healthTextSize=11,
    classIcon=true,iconSide="LEFT",iconStyle="modern",ccOnIcon=true,trinket=true,trinketSide="RIGHT",timers=true,timerSize=12,
    castBar=true,castBarHeight=14,castIcon=true,castTextSize=10,castColor=RGB(1,.7,0),uninterruptibleColor=RGB(.6,.6,.6),
    targetBorder=true,targetColor=RGB(.05,.82,.61),unseenAlpha=50}}
ns.defaults=defaults
ns.MAX=5
ns.TRINKET_COOLDOWN=120
-- PvP Trinket and Every Man for Himself share the two-minute cooldown.
ns.TRINKET_SPELLS={[42292]=true,[59752]=true}
ns.frames,ns.previews,ns.trinketUsed={},{},{}
-- Priority aura shown on the class icon. Auras match by name so every rank counts.
ns.AURA_PRIORITY_IDS={
    [6]={642,45438,10278,33786,19263,31224,46924,47585,48707,1022},
    [5]={853,408,1833,5211,22570,9005,12809,46968,7922,20253,44572,24394,47481,30283,20549,12355,2812},
    [4]={15487,47476,1330,28730,18469,24259,34490,18425,18498,31117,118,51514,6770,1776,2094,5782,5484,8122,5246,6789,6358,19503,3355,19386,2637,20066,64044,605,10326,49203,710},
    [3]={676,51722,53359,64058,33206},
    [2]={122,339,33395,12494,55080,23694,1044}}
function ns.BuildAuraPriority()
    local map={}
    for priority,ids in pairs(ns.AURA_PRIORITY_IDS) do
        for _,id in ipairs(ids) do
            local name=GetSpellInfo and GetSpellInfo(id)
            if name and (map[name] or 0)<priority then map[name]=priority end
        end
    end
    ns.AURA_PRIORITY=map
    return map
end
function ns.GetSettings() return addon.db and addon.db.profile end
function ns.Copy(value) if type(value)~="table" then return value end; local t={}; for k,v in pairs(value) do t[k]=ns.Copy(v) end; return t end
local function FillDefaults(p,d) for k,v in pairs(d) do if p[k]==nil then p[k]=ns.Copy(v) elseif type(v)=="table" and type(p[k])=="table" then FillDefaults(p[k],v) end end end
function ns.Font(fs,size)
    local path=(E.GetFontPath and E.GetFontPath("arena")) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local flags=((E.GetFontOutlineFlag and E.GetFontOutlineFlag("arena")) or "OUTLINE"):gsub(",?%s*SLUG","")
    if not fs:SetFont(path,math.max(8,tonumber(size) or 12),flags) then fs:SetFont("Fonts\\FRIZQT__.TTF",12,"OUTLINE") end
end
function ns.InArena()
    local inside,kind=IsInInstance()
    return inside and kind=="arena" or false
end
-- Bracket from the active battlefield queue (3.3.5: status, map, instance, min, max, teamSize).
function ns.TeamSize()
    for i=1,(MAX_BATTLEFIELD_QUEUES or 3) do
        local status,_,_,_,_,size=GetBattlefieldStatus(i)
        if status=="active" and tonumber(size) and size>0 then return math.min(size,ns.MAX) end
    end
    return ns.MAX
end
-- Unlock Mode "Element Options" target, rewritten after Core's deferred unlock body.
ns.ELEMENT_PANELS={ARENA_Frames={page="Arena Frames",sectionName="LAYOUT",highlightText="Frame Width"}}
local function WritePanels()
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    for key,panel in pairs(ns.ELEMENT_PANELS) do
        E._ELEMENT_SETTINGS_MAP[key]={module=ADDON_NAME,page=panel.page,sectionName=panel.sectionName,highlightText=panel.highlightText}
    end
end
function ns.RegisterElementPanels()
    WritePanels()
    local pending=E._unlockCoreInit
    if type(pending)=="function" and not ns._panelHook then
        ns._panelHook=true
        E._unlockCoreInit=function(...) pending(...); WritePanels() end
    end
end
-- Blizzard_ArenaUI loads on demand; park its frames under a hidden parent.
function ns.HideBlizzard()
    local frames=_G.ArenaEnemyFrames
    if not frames or InCombatLockdown() then return end
    local p=ns.GetSettings()
    if p and p.enabled and p.hideBlizzard then
        if not ns.hiddenParent then ns.hiddenParent=CreateFrame("Frame"); ns.hiddenParent:Hide() end
        if frames:GetParent()~=ns.hiddenParent then ns.blizzParent=ns.blizzParent or frames:GetParent(); frames:SetParent(ns.hiddenParent) end
    elseif ns.hiddenParent and frames:GetParent()==ns.hiddenParent then
        frames:SetParent(ns.blizzParent or UIParent)
    end
end
function ns.ResetMatch()
    wipe(ns.trinketUsed)
    for _,f in ipairs(ns.frames) do f.guid,f.class,f.unitName,f.lastHP,f.faction,f.everSeen=nil,nil,nil,nil,nil,nil end
end
function ns.FrameForGUID(guid)
    if not guid then return end
    for _,f in ipairs(ns.frames) do if f.guid==guid or UnitGUID(f.unit)==guid then return f end end
end
function ns.WantPreview()
    if ns.InArena() or InCombatLockdown() then return false end
    return ns.unlockPreview or ns.optionsPreview or ns.testMode or false
end
function ns.OptionsPreviewActive()
    return not InCombatLockdown() and E.IsShown and E:IsShown() and E.GetActiveModule and E:GetActiveModule()==ADDON_NAME or false
end
function ns.SyncOptionsPreview()
    local want=ns.OptionsPreviewActive()
    if want~=(ns.optionsPreview or false) then ns.optionsPreview=want; ns.Apply() end
end
function ns.SetPreview(on) ns.unlockPreview=on and not InCombatLockdown() or false; ns.Apply() end
function ns.Apply()
    local p=ns.GetSettings(); if not p then return end
    FillDefaults(p,defaults.profile)
    if InCombatLockdown() then ns.pending=true; if ns.RefreshAll then ns.RefreshAll() end; return end
    ns.pending=false
    ns.HideBlizzard()
    if ns.Layout then ns.Layout(p) end
end
_G._EARENA_Apply=function() ns.Apply() end
local function RegisterMovers()
    ns.RegisterElementPanels()
    if not E.RegisterUnlockElements or not E.MakeUnlockElement then return end
    E:RegisterUnlockElements({E.MakeUnlockElement({key="ARENA_Frames",label="Arena Frames",group="Arena Frames",order=850,noResize=true,noAnchorTo=true,
        getFrame=function() return ns.holder end,getSize=function() return ns.holder:GetWidth(),ns.holder:GetHeight() end,
        isHidden=function() local p=ns.GetSettings(); return not p or not p.enabled end,
        savePos=function(_,point,relPoint,x,y) local p=ns.GetSettings(); if p then p.position={point=point,relPoint=relPoint,x=x,y=y} end end,
        loadPos=function() local p=ns.GetSettings(); return p and p.position end,
        clearPos=function() local p=ns.GetSettings(); if p then p.position=nil; ns.Apply() end end,applyPos=ns.Apply})},ADDON_NAME)
end
function addon:OnInitialize()
    addon.db=E.Lite.NewDB("EllesmereUIArenaDB",defaults); ns.db=addon.db
    SLASH_EUI335ARENA1="/earena"; SLASH_EUI335ARENA2="/arenaframes"
    SlashCmdList.EUI335ARENA=function(msg)
        if InCombatLockdown() then return end
        if type(msg)=="string" and msg:lower():match("^%s*test") then ns.testMode=not ns.testMode; ns.Apply(); return end
        if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; E:ShowModule(ADDON_NAME)
    end
end
local SPELLCAST={UNIT_SPELLCAST_START=true,UNIT_SPELLCAST_STOP=true,UNIT_SPELLCAST_FAILED=true,UNIT_SPELLCAST_INTERRUPTED=true,UNIT_SPELLCAST_DELAYED=true,
    UNIT_SPELLCAST_CHANNEL_START=true,UNIT_SPELLCAST_CHANNEL_STOP=true,UNIT_SPELLCAST_CHANNEL_UPDATE=true}
local function FrameForUnit(unit)
    local i=type(unit)=="string" and tonumber(unit:match("^arena(%d)$"))
    return i and ns.frames[i]
end
local function OnEvent(_,event,...)
    local arg1,arg2=...
    if event=="COMBAT_LOG_EVENT_UNFILTERED" then
        local _,sub,srcGUID,_,_,_,_,_,spellId=...
        if sub=="SPELL_CAST_SUCCESS" and ns.TRINKET_SPELLS[spellId] and srcGUID then
            ns.trinketUsed[srcGUID]=GetTime()
            local f=ns.FrameForGUID(srcGUID); if f and ns.UpdateTrinket then ns.UpdateTrinket(f) end
        end
    elseif SPELLCAST[event] then
        local f=FrameForUnit(arg1); if f and ns.UpdateCast then ns.UpdateCast(f,event) end
    elseif event=="UNIT_AURA" then
        local f=FrameForUnit(arg1); if f and ns.UpdateIcon then ns.UpdateIcon(f) end
    elseif event=="UNIT_NAME_UPDATE" then
        local f=FrameForUnit(arg1); if f and ns.UpdateUnit then ns.UpdateUnit(f) end
    elseif event=="ARENA_OPPONENT_UPDATE" then
        local f=FrameForUnit(arg1)
        if f and (arg2=="destroyed" or arg2=="cleared") then f.guid,f.class,f.unitName,f.lastHP,f.faction=nil,nil,nil,nil,nil end
        if f and arg2=="seen" then f.everSeen=true end
        if f and arg2=="seen" and not f:IsShown() then ns.Apply() elseif f and ns.RefreshFrame then ns.RefreshFrame(f) end
    elseif event=="PLAYER_TARGET_CHANGED" then if ns.RefreshAll then ns.RefreshAll() end
    elseif event=="ADDON_LOADED" then if arg1=="Blizzard_ArenaUI" then ns.Apply() end
    elseif event=="PLAYER_REGEN_DISABLED" then
        ns.unlockPreview,ns.optionsPreview,ns.testMode=false,false,false
        if ns.HidePreviews then ns.HidePreviews() end
    elseif event=="PLAYER_REGEN_ENABLED" then if ns.pending then ns.Apply() end
    elseif event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA" then
        local arena=ns.InArena()
        if arena and not ns.wasArena then ns.ResetMatch() end
        ns.wasArena=arena; ns.Apply()
    end
end
function addon:OnEnable()
    ns.BuildAuraPriority()
    ns.Apply(); RegisterMovers()
    if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener(ADDON_NAME,ns.SetPreview) end
    if E.RegisterOnShow then E:RegisterOnShow(function() ns.SyncOptionsPreview() end) end
    if E.RegisterOnHide then E:RegisterOnHide(function() ns.SyncOptionsPreview() end) end
    local events=CreateFrame("Frame"); ns.events=events
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","ARENA_OPPONENT_UPDATE","PLAYER_TARGET_CHANGED",
        "UNIT_AURA","UNIT_NAME_UPDATE","COMBAT_LOG_EVENT_UNFILTERED","ADDON_LOADED"}) do pcall(events.RegisterEvent,events,event) end
    for event in pairs(SPELLCAST) do pcall(events.RegisterEvent,events,event) end
    events:SetScript("OnEvent",OnEvent)
    local elapsed,slow=0,0
    events:SetScript("OnUpdate",function(_,dt)
        if ns.TickCasts then ns.TickCasts() end
        elapsed=elapsed+dt; if elapsed<.1 then return end
        slow=slow+elapsed; elapsed=0
        if ns.OptionsPreviewActive()~=(ns.optionsPreview or false) then ns.SyncOptionsPreview() end
        if ns.Poll then ns.Poll(slow>=.5) end
        if slow>=.5 then slow=0 end
    end)
end
