local ADDON,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON]=ns
ns.IsWrath=true; ns.addon=E.Lite.NewAddon(ADDON); ns.ECME=ns.addon
ns.frames,ns.compiled,ns.auras,ns.spells,ns.petSpells,ns.actionGlows={},{},{},{},{},{}
ns.order={"cooldowns","utility","buffs","tracking"}
ns.defaults={profile={wrathVersion=1,enabled=true,glowsOnlyInCombat=false,readySound=false,actionBarGlows=false,positions={},wrathSpecLists={},
 cdmBars={enabled=true,bars={
 {key="cooldowns",name="Cooldowns",enabled=true,iconSize=42,columns=8,spacing=3,scale=1,alpha=1,show="always",visibility="always",growDirection="RIGHT",showGCD=false,showText=true,showStacks=true,showKeybind=true,tooltip=true,glow="none",showRange=false,bgAlpha=.6},
 {key="utility",name="Utility",enabled=true,iconSize=34,columns=10,spacing=3,scale=1,alpha=1,show="always",visibility="always",growDirection="RIGHT",showGCD=false,showText=true,showStacks=true,showKeybind=true,tooltip=true,glow="none",showRange=false,bgAlpha=.6},
 {key="buffs",name="Buffs",enabled=true,iconSize=36,columns=8,spacing=3,scale=1,alpha=1,show="active",visibility="always",growDirection="RIGHT",showGCD=false,showText=true,showStacks=true,showKeybind=false,tooltip=true,glow="active",showRange=false,bgAlpha=.6},
 {key="tracking",name="Tracking Bars",enabled=true,iconSize=24,columns=1,spacing=3,scale=1,alpha=1,show="active",visibility="always",growDirection="DOWN",showGCD=false,showText=true,showStacks=true,showKeybind=false,tooltip=true,glow="none",showRange=false,bgAlpha=.6,width=240,height=24},
 }}}}
function ns.Clamp(v,a,b) return math.max(a,math.min(b,tonumber(v) or a)) end
function ns.Copy(v) if type(v)~="table" then return v end; local n={}; for k,x in pairs(v) do n[k]=ns.Copy(x) end; return n end
function ns.Profile() return ns.addon.db and ns.addon.db.profile end
function ns.Config(key)
    local p=ns.Profile(); if not p then return end
    p.cdmBars=p.cdmBars or {enabled=true}; p.cdmBars.bars=p.cdmBars.bars or {}
    for _,default in ipairs(ns.defaults.profile.cdmBars.bars) do if default.key==key then
        for _,cfg in ipairs(p.cdmBars.bars) do if cfg.key==key then
            for k,v in pairs(default) do if cfg[k]==nil then cfg[k]=ns.Copy(v) end end
            cfg.textSize=cfg.textSize or 12; cfg.fontOutline=cfg.fontOutline or "OUTLINE"; cfg.sort=cfg.sort or "assigned"
            return cfg
        end end
        local cfg=ns.Copy(default); cfg.textSize=12; cfg.fontOutline="OUTLINE"; cfg.sort="assigned"; p.cdmBars.bars[#p.cdmBars.bars+1]=cfg; return cfg
    end end
end
function ns.SpecKey()
    local _,class=UnitClass("player"); return (class or "UNKNOWN")..":"..tostring(GetActiveTalentGroup and GetActiveTalentGroup() or 1)
end
function ns.Lists()
    local p=ns.Profile(); if not p then return end
    p.wrathSpecLists=p.wrathSpecLists or {}; p.positions=p.positions or {}
    local key=ns.SpecKey()
    if not p.wrathSpecLists[key] then local _,class=UnitClass("player"); p.wrathSpecLists[key]=ns.SeedLists(class) end
    return p.wrathSpecLists[key]
end
function ns.ScanSpells()
    ns.spells,ns.petSpells={},{}
    local function Scan(book,dst,limit)
        for slot=1,limit do
            local name,rank=GetSpellName(slot,book); if not name then break end
            local link=GetSpellLink and GetSpellLink(slot,book)
            local id=link and tonumber(link:match("spell:(%d+)"))
            local icon=GetSpellTexture and GetSpellTexture(slot,book)
            local passive=IsPassiveSpell and IsPassiveSpell(slot,book)
            local meta={name=name,rank=rank,id=id,icon=icon,slot=slot,book=book,passive=passive}
            dst[name]=meta; if id then dst[id]=meta end
        end
    end
    Scan(BOOKTYPE_SPELL or "spell",ns.spells,1024)
    Scan(BOOKTYPE_PET or "pet",ns.petSpells,HasPetSpells and HasPetSpells() or 0)
end
function ns.Resolve(entry)
    local kind=entry.kind or "spell"; local id=tonumber(entry.id); if not id or id<1 then return end
    if kind=="spell" or kind=="aura" then
        local name,_,icon=GetSpellInfo(id); if not name then return end
        if kind=="spell" then
            local meta=ns.spells[name] or ns.spells[id] or ns.petSpells[name] or ns.petSpells[id]
            if not meta or meta.passive then return end
            return {name=meta.name,id=meta.id or id,icon=meta.icon or icon,slot=meta.slot,book=meta.book,kind=kind}
        end
        return {name=name,id=id,icon=icon,kind=kind}
    elseif kind=="item" or kind=="slot" then
        local itemID=kind=="slot" and GetInventoryItemID("player",id) or id
        if not itemID then return end
        local name,_,_,_,_,_,_,_,_,icon=GetItemInfo(itemID)
        icon=icon or GetItemIcon and GetItemIcon(itemID)
        if not name and not icon then return end
        return {name=name or ("Item "..itemID),id=itemID,icon=icon,kind=kind,slot=kind=="slot" and id or nil}
    end
end
function ns.Compile()
    local lists=ns.Lists(); if not lists then return end
    ns.compiled={}
    for _,key in ipairs(ns.order) do
        local entries={}; ns.compiled[key]=entries
        for _,entry in ipairs(lists[key] or {}) do
            if entry.enabled~=false then
                local meta=ns.Resolve(entry)
                if meta and #entries<40 then entries[#entries+1]={entry=entry,meta=meta,remaining=0,active=false} end
            end
        end
    end
end
function ns.ScanAuras()
    local cache={}
    for _,unit in ipairs({"player","target","focus"}) do
        cache[unit]={}
        for _,filter in ipairs({"HELPFUL","HARMFUL"}) do
            local list={}; cache[unit][filter]=list
            for i=1,40 do
                local name,_,icon,count,_,duration,expires,caster,_,_,id=UnitAura(unit,i,filter)
                if not name then break end
                list[#list+1]={name=name,id=id,icon=icon,count=count or 0,duration=duration or 0,expires=expires or 0,caster=caster,index=i}
            end
        end
    end
    ns.auras=cache
end
local function Aura(state,now)
    local e,m=state.entry,state.meta; local unit=e.unit or "player"; local filter=e.filter=="HARMFUL" and "HARMFUL" or "HELPFUL"
    local chosen
    for _,a in ipairs(ns.auras[unit] and ns.auras[unit][filter] or {}) do
        if (a.id==m.id or a.name==m.name) and (not e.ownOnly or a.caster=="player" or a.caster and UnitIsUnit and UnitIsUnit(a.caster,"player"))
            and (a.duration==0 or a.expires>now) and (not chosen or a.expires>chosen.expires) then chosen=a end
    end
    state.aura=chosen; state.active=chosen~=nil; state.usable=state.active; state.count=chosen and chosen.count or 0
    state.duration=chosen and chosen.duration or 0; state.start=chosen and chosen.expires-state.duration or 0
    state.remaining=chosen and state.duration>0 and math.max(0,chosen.expires-now) or 0
end
function ns.UpdateState(state,showGCD,now)
    local m=state.meta
    if m.kind=="aura" then Aura(state,now); return end
    local start,duration,enabled
    if m.kind=="spell" then start,duration,enabled=GetSpellCooldown(m.slot,m.book)
    elseif m.kind=="slot" then start,duration,enabled=GetInventoryItemCooldown("player",m.slot)
    else start,duration,enabled=GetItemCooldown(m.id) end
    start,duration=tonumber(start) or 0,tonumber(duration) or 0
    -- Ignore only the observed shared GCD, not every genuinely short cooldown.
    if not showGCD and ns.gcdDuration>0 and math.abs(start-ns.gcdStart)<.03 and math.abs(duration-ns.gcdDuration)<.03 then start,duration=0,0 end
    state.start,state.duration=start,duration; state.remaining=math.max(0,start+duration-now)
    state.active=state.remaining>0; state.usable=enabled~=0
    if m.kind=="spell" and IsUsableSpell and m.book~=(BOOKTYPE_PET or "pet") then
        local usable=IsUsableSpell(m.name); if usable~=nil then state.usable=state.usable and not not usable end
    end
    state.count=m.kind=="item" and (GetItemCount(m.id) or 0) or 0
    if m.kind=="item" and state.count==0 then state.usable=false end
    if state.wasCooldown and not state.active and enabled~=0 and ns.Profile().readySound and now-(ns.lastReadySound or -1)>1 then
        if PlaySound then PlaySound("RaidWarning") end; ns.lastReadySound=now
    end
    state.wasCooldown=state.active
end
function ns.Update()
    local p=ns.Profile(); if not p or not ns.frames.cooldowns then return end
    local now=GetTime(); ns.gcdStart,ns.gcdDuration=0,0
    if GetSpellCooldown then local ok,s,d=pcall(GetSpellCooldown,61304); if ok and d and d<=1.7 then ns.gcdStart,ns.gcdDuration=s or 0,d end end
    for _,key in ipairs(ns.order) do
        local cfg=ns.Config(key)
        for _,state in ipairs(ns.compiled[key] or {}) do ns.UpdateState(state,cfg.showGCD,now) end
        ns.PaintGroup(key,now)
    end
    if ns.UpdateActionGlows then ns.UpdateActionGlows(now) end
end
function ns.Apply()
    if not ns.Profile() then return end
    ns.ScanSpells(); ns.Compile(); ns.ScanAuras()
    if ns.Layout then ns.Layout() end
    if ns.PrepareActionGlows and not InCombatLockdown() then ns.PrepareActionGlows() end
    ns.Update()
    if E._specProfileSwitching and E.OnSpecSwitchComplete then E.OnSpecSwitchComplete() end
end
function ns.addon:OnInitialize()
    ns.addon.db=E.Lite.NewDB("EllesmereUICooldownManagerDB",ns.defaults); ns.db=ns.addon.db; _ECME_DB=ns.db
end
function ns.addon:OnEnable()
    ns.CreateGroups()
    ns.events=CreateFrame("Frame")
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","SPELLS_CHANGED","ACTIVE_TALENT_GROUP_CHANGED","PLAYER_TALENT_UPDATE","UNIT_PET","UNIT_AURA","PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","SPELL_UPDATE_COOLDOWN","BAG_UPDATE_COOLDOWN","BAG_UPDATE","UNIT_INVENTORY_CHANGED","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","ACTIONBAR_SLOT_CHANGED","ACTIONBAR_PAGE_CHANGED","UPDATE_BINDINGS","ADDON_LOADED","GET_ITEM_INFO_RECEIVED"}) do ns.events:RegisterEvent(event) end
    ns.events:SetScript("OnEvent",function(_,event,unit)
        if event=="UNIT_AURA" or event=="PLAYER_TARGET_CHANGED" or event=="PLAYER_FOCUS_CHANGED" then
            if event~="UNIT_AURA" or unit=="player" or unit=="target" or unit=="focus" then ns.ScanAuras(); ns.Update() end
        elseif event=="SPELL_UPDATE_COOLDOWN" or event=="BAG_UPDATE_COOLDOWN" or event=="PLAYER_REGEN_DISABLED" or event=="ACTIONBAR_SLOT_CHANGED" or event=="ACTIONBAR_PAGE_CHANGED" or event=="UPDATE_BINDINGS" then ns.Update()
        elseif event=="BAG_UPDATE" or event=="GET_ITEM_INFO_RECEIVED" or event=="UNIT_INVENTORY_CHANGED" then
            if event~="UNIT_INVENTORY_CHANGED" or unit=="player" then ns.Compile(); ns.Update() end
        elseif event=="ADDON_LOADED" then
            if unit=="EllesmereUIActionBars" and not InCombatLockdown() then ns.PrepareActionGlows(); ns.Update() end
        else ns.Apply() end
    end)
    local elapsed,auraElapsed=0,0
    ns.events:SetScript("OnUpdate",function(_,dt)
        local p=ns.Profile(); if not p or not p.enabled or not p.cdmBars.enabled then return end
        elapsed=elapsed+dt; auraElapsed=auraElapsed+dt; if elapsed<.1 then return end; elapsed=0
        if auraElapsed>=.5 then auraElapsed=0; ns.ScanAuras() end
        ns.Update()
    end)
    if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener(ADDON,function(active) ns.unlockPreview=active; ns.preview=active or ns.optionsPreview; ns.Update() end) end
    ns.Apply()
end
_ECME_Apply=ns.Apply
E.CdmIconStyle=E.CdmIconStyle or function() return "eui" end
E.CdmBarStyle=E.CdmBarStyle or function() return "eui" end
