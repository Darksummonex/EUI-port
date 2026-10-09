local ADDON,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON]=ns
ns.IsWrath=true; ns.addon=E.Lite.NewAddon(ADDON); ns.ECME=ns.addon
ns.frames,ns.compiled,ns.auras,ns.spells,ns.petSpells,ns.actionGlows,ns.keybinds,ns.pressed={},{},{},{},{},{},{},{}
ns.icdStart,ns.icdWatch,ns.collapsed={},{},setmetatable({},{__mode="k"})
ns.DEFAULT_BARS={"cooldowns","utility","buffs"}
-- Retail per-bar keys (EllesmereUICooldownManager.lua DEFAULTS and the CDM Bars page).
ns.BAR_DEFAULTS={enabled=true,barType="cooldowns",iconSize=36,numRows=1,spacing=2,growDirection="RIGHT",rowGrowDirection="DOWN",verticalOrientation=false,
 pandemicR=1,pandemicG=.8,pandemicB=.2,
 borderSize=1,borderR=0,borderG=0,borderB=0,borderA=1,borderClassColor=false,borderTexture="solid",
 bgR=.08,bgG=.08,bgB=.08,bgA=.6,iconZoom=.08,iconShape="none",iconCropPercent=10,
 barBgEnabled=false,barBgR=0,barBgG=0,barBgB=0,barBgA=.5,anchorTo="none",anchorPosition="left",anchorOffsetX=0,anchorOffsetY=0,
 addOffsetX=0,addOffsetY=0,barVisibility="always",visOnlyInstances=false,visHideMounted=false,visHideNoTarget=false,visHideNoEnemy=false,
 showCooldownText=true,cooldownTextPosition="center",cooldownFontSize=12,cooldownTextR=1,cooldownTextG=1,cooldownTextB=1,cooldownTextX=0,cooldownTextY=0,
 showItemCount=true,stackCountSize=11,stackCountR=1,stackCountG=1,stackCountB=1,stackCountPosition="bottomright",stackCountX=0,stackCountY=0,
 showTooltip=false,showKeybind=false,keybindSize=10,keybindAnchor="TOPLEFT",keybindOffsetX=2,keybindOffsetY=-2,keybindR=1,keybindG=1,keybindB=1,keybindA=.9,
 barOpacity=1,oocFadeEnabled=false,oocFadeAlpha=.5,maxIcons=0,barStrata="MEDIUM",showCooldownEdge=false,suppressGCD=false,
 pixelGlowThickness=2,pixelGlowLines=8,pixelGlowSpeed=4,onlyShowNumbers=false,chargesOnly=false,hideZeroChargeText=false,hideItemsIfMissing=false,
 showPassiveTrinkets=false,pressMirror=false,desaturateOnCD=true,showRange=true,rangeR=.85,rangeG=.15,rangeB=.15,showNoMana=true,manaR=.35,manaG=.45,manaB=1,
 showInactiveBuffIcons=false,desaturateInactiveBuffs=true,hidePlaceholderIcon=false,buffGlow=0,pandemicGlow=false,pandemicGlowStyle=1,
 procGlowStyle=1,activeState=true,swipeAlpha=.7,sort="assigned"}
ns.TYPE_DEFAULTS={cooldowns={iconSize=42},utility={iconSize=36},buffs={iconSize=32,showKeybind=false},focuskick={iconSize=40,showKeybind=true,
 focusReminderEnabled=true,focusReminderUseAccent=true,focusReminderR=1,focusReminderG=.2,focusReminderB=.2,focusReminderSize=14,focusReminderOffsetX=0,focusReminderOffsetY=4,
 focusKickUseTarget=false,focusCastSoundKey="RaidWarning",focusKickInterruptSpellID=0}}
-- Retail TBB_DEFAULT_BAR (EllesmereUICdmBuffBars.lua); unit/filter/ownOnly are Wrath aura scopes.
ns.TBB_DEFAULTS={spellID=0,name="New Bar",enabled=true,trackType="aura",unit="player",filter="HELPFUL",ownOnly=false,hideWhenInactive=true,onlyInCombat=false,
 barVisibility="always",visOnlyInstances=false,visHideMounted=false,visHideNoTarget=false,visHideNoEnemy=false,groupID=0,
 height=24,width=270,verticalOrientation=false,reverseFill=false,fillUp=false,texture="none",fillR=.05,fillG=.82,fillB=.62,fillA=1,bgR=0,bgG=0,bgB=0,bgA=.4,
 useClassColor=true,gradientEnabled=false,gradientR=.2,gradientG=.2,gradientB=.8,gradientA=1,gradientDir="HORIZONTAL",opacity=1,
 showTimer=true,timerPosition="right",timerSize=11,timerX=0,timerY=0,timerTextR=1,timerTextG=1,timerTextB=1,timerTextA=.9,decimals=false,decimalThreshold=5,
 showName=true,namePosition="left",nameSize=11,nameX=0,nameY=0,nameTextR=1,nameTextG=1,nameTextB=1,nameTextA=.9,showSpark=true,
 iconDisplay="left",iconSize=24,iconX=0,iconY=0,iconBorderSize=0,stacksPosition="center",stacksSize=11,stacksX=0,stacksY=0,
 stacksTextR=1,stacksTextG=1,stacksTextB=1,stacksTextA=.9,stackThresholdEnabled=false,stackThreshold=5,stackThresholdR=.8,stackThresholdG=.1,stackThresholdB=.1,stackThresholdA=1,
 stackThresholdMaxEnabled=false,stackThresholdMax=10,stackThresholdTicks="",stackThresholdTickR=1,stackThresholdTickG=1,stackThresholdTickB=1,stackThresholdTickA=1,
 stackBasedBar=false,pandemicGlow=true,pandemicGlowStyle=1,pandemicGlowR=1,pandemicGlowG=.8,pandemicGlowB=.2,pandemicGlowLines=8,pandemicGlowThickness=2,pandemicGlowSpeed=4,
 borderSize=1,borderR=0,borderG=0,borderB=0,borderA=1,borderTexture="solid",barStrata="MEDIUM"}
ns.defaults={profile={wrathVersion=2,enabled=true,glowsOnlyInCombat=false,readySound=false,swapPotions=false,useClassicStyle=false,useClassicStyleBars=false,
 tbbSmooth=true,stableKeybinds=true,positions={},wrathSpecLists={},tbbGroups={},cdmBars={enabled=true}}}
function ns.Clamp(v,a,b) return math.max(a,math.min(b,tonumber(v) or a)) end
function ns.Copy(v) if type(v)~="table" then return v end; local n={}; for k,x in pairs(v) do n[k]=ns.Copy(x) end; return n end
function ns.Profile() return ns.addon.db and ns.addon.db.profile end
function ns.Fill(t,defaults) for k,v in pairs(defaults) do if t[k]==nil then t[k]=ns.Copy(v) end end; return t end
function ns.NewBar(key,barType,name)
    local b={key=key,barType=barType,name=name}
    ns.Fill(b,ns.TYPE_DEFAULTS[barType] or {}); return ns.Fill(b,ns.BAR_DEFAULTS)
end
-- 0.1 saved bars (indexed, defaults stripped at logout) become Retail-keyed bars.
local V1={{key="cooldowns",name="Cooldowns",iconSize=42,show="always",showKeybind=true},{key="utility",name="Utility",iconSize=34,show="always",showKeybind=true},
 {key="buffs",name="Buffs",iconSize=36,show="active",glow="active",showKeybind=false},{key="tracking",name="Tracking Bars",show="active",width=240,height=24}}
function ns.Migrate(p)
    p.cdmBars=p.cdmBars or {enabled=true}
    local old,new=p.cdmBars.bars,{}
    if type(old)~="table" or old[1]==nil then p.cdmBars.bars=type(old)=="table" and old or {}; return end
    if old[1].barType then return end
    for i,v in ipairs(V1) do
        local o=old[i] or {}; for k,x in pairs(v) do if o[k]==nil then o[k]=x end end
        if o.key=="tracking" then
            p.tbbLegacy={width=o.width,height=o.height}
            if p.positions and p.positions.tracking then p.positions.TBB_1=p.positions.tracking; p.positions.tracking=nil end
        else
            local b=ns.NewBar(o.key,o.key,o.name)
            b.enabled=o.enabled~=false; b.iconSize=math.floor(ns.Clamp((o.iconSize or 36)*(o.scale or 1),16,80)+.5); b.spacing=o.spacing or 3
            b.barOpacity=o.alpha or 1; b.bgA=o.bgAlpha or .6; b.showCooldownText=o.showText~=false; b.showItemCount=o.showStacks~=false
            b.showKeybind=o.showKeybind and true or false; b.showTooltip=o.tooltip~=false; b.suppressGCD=not o.showGCD; b.cooldownFontSize=o.textSize or 12
            b.growDirection=o.growDirection or "RIGHT"; b.showRange=o.showRange and true or false; b.sort=o.sort or "assigned"
            if b.growDirection=="UP" or b.growDirection=="DOWN" then b.rowGrowDirection=b.growDirection; b.growDirection="RIGHT" end
            if o.visibility=="combat" then b.barVisibility="in_combat" elseif o.visibility=="target" then b.visHideNoTarget=true end
            b.spellDefaults={}
            if o.key=="buffs" then b.showInactiveBuffIcons=o.show=="always"
            elseif o.show=="cooldown" or o.show=="active" then b.spellDefaults.cdStateEffect="hiddenReadyShift"
            elseif o.show=="ready" then b.spellDefaults.cdStateEffect="hiddenOnCDShift" end
            if o.glow=="ready" and not b.spellDefaults.cdStateEffect then b.spellDefaults.cdStateEffect="pixelGlowReady" end
            if o.glow=="active" then b.buffGlow=1 end
            new[#new+1]=b
        end
    end
    p.cdmBars.bars=new; p.wrathVersion=2
end
ns.BUILTIN_NAMES={cooldowns="Cooldowns",utility="Utility",buffs="Buffs"}
-- Older options could save a built-in bar twice or with another built-in's type/name
-- (one bar missing, two "Buffs"): give each built-in key back to exactly one bar.
function ns.RepairBuiltins(bars)
    local names,order,count,missing=ns.BUILTIN_NAMES,{},{},{}
    for i,k in ipairs(ns.DEFAULT_BARS) do order[k]=i end
    for _,b in ipairs(bars) do if names[b.key] then count[b.key]=(count[b.key] or 0)+1 end end
    for _,k in ipairs(ns.DEFAULT_BARS) do if not count[k] then missing[#missing+1]=k end end
    for _,b in ipairs(bars) do
        local k=b.key
        if names[k] and count[k]>1 then
            local to
            for i,m in ipairs(missing) do if order[m]<order[k] then to=table.remove(missing,i); break end end
            if not to and b~=ns.FirstBarByKey(bars,k) then to=table.remove(missing,1) end
            if to then count[k]=count[k]-1; b.key=to; b.name=names[to]
            elseif b~=ns.FirstBarByKey(bars,k) then
                local n=1; while ns.FirstBarByKey(bars,"custom_"..n) do n=n+1 end
                count[k]=count[k]-1; b.key="custom_"..n
            end
        end
        if names[b.key] then
            if b.barType~=b.key then b.barType=b.key end
            for other,n in pairs(names) do if other~=b.key and b.name==n then b.name=names[b.key] end end
            if not b.name then b.name=names[b.key] end
        end
    end
end
function ns.FirstBarByKey(bars,key) for _,b in ipairs(bars) do if b.key==key then return b end end end
function ns.Bars()
    local p=ns.Profile(); if not p then return {} end
    ns.Migrate(p)
    local bars=p.cdmBars.bars
    -- Spec Overrides traces getters through read proxies: # and ipairs see them empty in
    -- Lua 5.1, so read through __index into a plain list and never seed or repair there.
    if rawget(bars,1)==nil and bars[1]~=nil then
        local list,i={},1
        while bars[i]~=nil do list[i]=bars[i]; i=i+1 end
        return list
    end
    if bars[1]==nil then for i,k in ipairs(ns.DEFAULT_BARS) do bars[i]=ns.NewBar(k,k,ns.BUILTIN_NAMES[k]) end end
    ns.RepairBuiltins(bars)
    for _,b in ipairs(bars) do b.spellDefaults=b.spellDefaults or {}; ns.Fill(b,ns.TYPE_DEFAULTS[b.barType] or {}); ns.Fill(b,ns.BAR_DEFAULTS) end
    return bars
end
function ns.BarByKey(key) for _,b in ipairs(ns.Bars()) do if b.key==key then return b end end end
ns.Config=ns.BarByKey
function ns.IsBuffBar(b) return b and b.barType=="buffs" end
function ns.AddBar(barType,name)
    local bars=ns.Bars(); local n=1
    while ns.BarByKey("custom_"..n) do n=n+1 end
    if barType=="focuskick" then for _,b in ipairs(bars) do if b.barType=="focuskick" then return b end end end
    local b=ns.NewBar(barType=="focuskick" and "focuskick" or "custom_"..n,barType,name or (barType=="focuskick" and "FocusKick" or "Custom Bar "..n))
    b.spellDefaults={}; bars[#bars+1]=b; return b
end
function ns.RemoveBar(key)
    local bars=ns.Bars()
    for i,b in ipairs(bars) do if b.key==key and not (key=="cooldowns" or key=="utility" or key=="buffs") then
        table.remove(bars,i); ns.Profile().positions[key]=nil
        for _,lists in pairs(ns.Profile().wrathSpecLists) do lists[key]=nil end
        for _,o in ipairs(bars) do if o.anchorTo==key then o.anchorTo="none" end; if o.overflowTarget==key then o.overflowTarget=nil; o.maxIcons=0 end end
        return true
    end end
end
function ns.SpecKey()
    local _,class=UnitClass("player"); return (class or "UNKNOWN")..":"..tostring(GetActiveTalentGroup and GetActiveTalentGroup() or 1)
end
function ns.OtherSpecKey()
    local _,class=UnitClass("player"); local g=GetActiveTalentGroup and GetActiveTalentGroup() or 1; return (class or "UNKNOWN")..":"..(g==1 and 2 or 1)
end
function ns.ListsFor(key)
    local p=ns.Profile(); if not p then return end
    p.wrathSpecLists=p.wrathSpecLists or {}; p.positions=p.positions or {}
    local lists=p.wrathSpecLists[key]
    if not lists then local _,class=UnitClass("player"); lists=ns.SeedLists(class); p.wrathSpecLists[key]=lists end
    if not lists.tbb then
        lists.tbb={}
        for _,e in ipairs(lists.tracking or {}) do
            if e.kind=="aura" then lists.tbb[#lists.tbb+1]={spellID=e.id,unit=e.unit,filter=e.filter,ownOnly=e.ownOnly,enabled=e.enabled~=false,
                width=p.tbbLegacy and p.tbbLegacy.width,height=p.tbbLegacy and p.tbbLegacy.height} end
        end
        lists.tracking=nil
    end
    if not lists.barGlows then
        lists.barGlows={enabled=p.actionBarGlows and true or false,list={}}
        for _,e in ipairs(lists.buffs or {}) do if e.highlightSpellID then
            lists.barGlows.list[#lists.barGlows.list+1]={auraID=e.id,unit=e.unit or "player",filter=e.filter or "HELPFUL",ownOnly=e.ownOnly,spellID=e.highlightSpellID,mode="active",glowType=1}
            e.highlightSpellID=nil
        end end
    end
    for _,t in ipairs(lists.tbb) do ns.Fill(t,ns.TBB_DEFAULTS) end
    if not ns.collapsed[lists] then ns.collapsed[lists]=true; ns.CollapseRacials(lists) end
    return lists
end
function ns.Lists() return ns.ListsFor(ns.SpecKey()) end
function ns.EntriesFor(barKey) local l=ns.Lists(); if not l then return {} end; l[barKey]=l[barKey] or {}; return l[barKey] end
function ns.Eff(st,k)
    local v=st.entry[k]; if v~=nil then return v end
    local d=st.bar.spellDefaults; return d and d[k]
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
    ns.procByName,ns.reactiveByName={},{}
    for id,v in pairs(ns.PROC_AURAS) do local n=GetSpellInfo(id); if n then ns.procByName[n]=v end end
    for id in pairs(ns.REACTIVE) do local n=GetSpellInfo(id); if n then ns.reactiveByName[n]=true end end
end
-- Talent Conditions (Retail EllesmereUICdmTalentConditions.lua): talent by name in the active group.
function ns.ScanTalents()
    ns.talents={}
    local group=GetActiveTalentGroup and GetActiveTalentGroup() or 1
    for tab=1,(GetNumTalentTabs and GetNumTalentTabs() or 0) do
        for i=1,(GetNumTalents and GetNumTalents(tab) or 0) do
            local name,_,_,_,rank=GetTalentInfo(tab,i,false,false,group)
            if name then ns.talents[name]=(rank or 0)>0 end
        end
    end
end
function ns.TalentOK(e)
    local n=e.talentName; if not n or n=="" then return true end
    local known=ns.talents and ns.talents[n] or false
    if e.talentTaken==false then return not known end
    return known
end
function ns.PresetItems(e)
    local p=ns.ITEM_PRESET_BY_KEY[e.id]; if not p then return end
    return p
end
-- Passive proc items (TrinketData): proc spell IDs and the internal cooldown they share.
function ns.TrinketProcs(itemID)
    local v=ns.TRINKET_PROCS and ns.TRINKET_PROCS[itemID]; if not v then return end
    local ids=type(v)=="table" and v or {v}; local icd,nocd=0,true
    for _,p in ipairs(ids) do if not ns.TRINKET_NOCD[p] then nocd=false; icd=math.max(icd,ns.TRINKET_ICD[p] or 45) end end
    return {ids=ids,icd=icd,nocd=nocd}
end
function ns.ProcCooldown(procs)
    if procs.nocd then return 0,0 end
    local start=0
    for _,p in ipairs(procs.ids) do local s=ns.icdStart[p]; if s and s>start then start=s end end
    return start,start>0 and procs.icd or 0
end
function ns.Resolve(entry,bar)
    local kind=entry.kind or "spell"
    if kind=="preset" then
        local p=ns.ITEM_PRESET_BY_KEY[entry.id]; if not p then return end
        local icon=GetItemIcon and GetItemIcon(p.items[1])
        return {name=p.name,id=p.items[1],icon=icon or "Interface\\Icons\\INV_Misc_QuestionMark",kind="preset",preset=p}
    end
    local id=tonumber(entry.id); if not id or id<1 then return end
    local custom=entry.customIcon and entry.customIcon~="" and (tonumber(entry.customIcon) and select(3,GetSpellInfo(tonumber(entry.customIcon))) or entry.customIcon)
    if kind=="spell" or kind=="aura" then
        local name,_,icon=GetSpellInfo(id); if not name then return end
        if kind=="spell" then
            local meta=ns.spells[name] or ns.spells[id] or ns.petSpells[name] or ns.petSpells[id]
            if not meta or meta.passive then return end
            return {name=meta.name,id=meta.id or id,icon=custom or meta.icon or icon,slot=meta.slot,book=meta.book,kind=kind}
        end
        local ids
        local preset=entry.preset and ns.BUFF_PRESET_BY_KEY[entry.preset]
        if preset then ids={}; for _,x in ipairs(preset.ids) do local n=GetSpellInfo(x); if n then ids[n]=true end end; icon=preset.icon or icon end
        return {name=preset and preset.name or name,auraName=name,id=id,icon=custom or icon,kind=kind,names=ids}
    elseif kind=="item" or kind=="slot" then
        local itemID=kind=="slot" and GetInventoryItemID("player",id) or id
        if not itemID then return end
        local useSpell=GetItemSpell and GetItemSpell(itemID); local onUse=useSpell
        if kind=="slot" and not onUse then onUse=select(3,GetInventoryItemCooldown("player",id))==1 end
        local procs=not onUse and ns.TrinketProcs(itemID) or nil
        if kind=="slot" and (id==13 or id==14) and bar and not bar.showPassiveTrinkets and not onUse and not procs then return end
        local name,_,_,_,_,_,_,_,_,icon=GetItemInfo(itemID)
        icon=icon or GetItemIcon and GetItemIcon(itemID) or kind=="slot" and GetInventoryItemTexture and GetInventoryItemTexture("player",id)
        if not name and not icon then return end
        return {name=name or ("Item "..itemID),id=itemID,icon=custom or icon,kind=kind,slot=kind=="slot" and id or nil,useSpell=useSpell,procs=procs}
    end
end
function ns.KickEntry(bar)
    local id=tonumber(bar.focusKickInterruptSpellID) or 0
    if id<=0 and E.GetActiveKickSpell then id=E.GetActiveKickSpell() or 0 end
    return id>0 and {kind="spell",id=id,enabled=true} or nil
end
function ns.Compile()
    local lists=ns.Lists(); if not lists then return end
    ns.compiled={}
    local watch={}
    for _,bar in ipairs(ns.Bars()) do
        local entries,seen={},{}; ns.compiled[bar.key]=entries
        local source=lists[bar.key] or {}
        if bar.barType=="focuskick" then local k=ns.KickEntry(bar); source=k and {k} or {} end
        for _,entry in ipairs(source) do
            if entry.enabled~=false and ns.TalentOK(entry) then
                local meta=ns.Resolve(entry,bar)
                if meta and meta.kind=="spell" then
                    local k=tostring(meta.book)..":"..tostring(meta.slot)
                    if seen[k] then meta=nil else seen[k]=true end
                end
                if meta and meta.procs and not meta.procs.nocd then for _,p in ipairs(meta.procs.ids) do watch[p]=true end end
                if meta and #entries<40 then entries[#entries+1]={entry=entry,meta=meta,bar=bar,remaining=0,active=false,count=0} end
            end
        end
    end
    ns.icdWatch=watch
    if ns.events then
        if next(watch) then ns.events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") else ns.events:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED") end
    end
    if ns.EnsurePools then ns.EnsurePools() end
end
function ns.ScanAuras()
    local cache={}
    for _,unit in ipairs({"player","target","focus","pet"}) do
        cache[unit]={}
        for _,filter in ipairs({"HELPFUL","HARMFUL"}) do
            local list={}; cache[unit][filter]=list
            for i=1,40 do
                local name,_,icon,count,_,duration,expires,caster,_,_,id=UnitAura(unit,i,filter)
                if not name then break end
                list[#list+1]={name=name,id=id,icon=icon,count=count or 0,duration=duration or 0,expires=expires or 0,caster=caster,index=i,unit=unit,filter=filter}
                if id and ns.icdWatch[id] and unit=="player" and (duration or 0)>0 then
                    local s=expires-duration; if s>(ns.icdStart[id] or 0)+.5 then ns.icdStart[id]=s end
                end
            end
        end
    end
    ns.auras=cache
end
local function Mine(a) return a.caster=="player" or a.caster=="pet" or a.caster=="vehicle" or a.caster and UnitIsUnit and UnitIsUnit(a.caster,"player") end
function ns.FindAura(unit,filter,id,name,names,own,now)
    local chosen
    for _,a in ipairs(ns.auras[unit] and ns.auras[unit][filter] or {}) do
        if (id and a.id==id or name and a.name==name or names and names[a.name]) and (not own or Mine(a)) and (a.duration==0 or a.expires>now)
            and (not chosen or a.expires>chosen.expires) then chosen=a end
    end
    return chosen
end
local function AuraState(st,now)
    local e,m=st.entry,st.meta
    local a=ns.FindAura(e.unit or "player",e.filter=="HARMFUL" and "HARMFUL" or "HELPFUL",m.id,m.auraName or m.name,m.names,e.ownOnly,now)
    st.aura=a; st.active=a~=nil; st.usable=st.active; st.count=a and a.count or 0
    st.duration=a and a.duration or 0; st.start=a and a.expires-st.duration or 0
    st.remaining=a and st.duration>0 and math.max(0,a.expires-now) or 0
    st.onCD=false; st.activeAura=nil
end
function ns.IsGCD(start,duration)
    if duration<=0 then return false end
    if ns.gcdDuration>0 and math.abs(start-ns.gcdStart)<.03 and math.abs(duration-ns.gcdDuration)<.03 then return true end
    return duration<=1.5
end
function ns.PresetChoice(st)
    local p=st.meta.preset
    local function First(list) for _,id in ipairs(list) do if (GetItemCount(id) or 0)>0 then return id end end end
    local id=First(p.items)
    if not id and p.swapWith and ns.Profile().swapPotions then
        for _,k in ipairs(p.swapWith) do local q=ns.ITEM_PRESET_BY_KEY[k]; id=q and First(q.items); if id then break end end
    end
    id=id or p.items[1]
    st.itemID=id; st.icon=GetItemIcon and GetItemIcon(id) or st.meta.icon
    return id
end
function ns.UpdateState(st,now)
    local m,e,bar=st.meta,st.entry,st.bar
    st.icon=m.icon; st.proc=false; st.outOfRange,st.noMana,st.missing=false,false,false
    if m.kind=="aura" then AuraState(st,now); return end
    local start,duration,enabled,itemID
    if m.kind=="spell" then start,duration,enabled=GetSpellCooldown(m.slot,m.book)
    elseif m.procs then start,duration=ns.ProcCooldown(m.procs); enabled=1; itemID=m.id
    elseif m.kind=="slot" then start,duration,enabled=GetInventoryItemCooldown("player",m.slot); itemID=m.id
    else itemID=m.kind=="preset" and ns.PresetChoice(st) or m.id; start,duration,enabled=GetItemCooldown(itemID) end
    start,duration=tonumber(start) or 0,tonumber(duration) or 0
    local gcd=ns.IsGCD(start,duration)
    if gcd and (bar.suppressGCD or ns.Eff(st,"suppressGCD")) then start,duration=0,0 end
    st.start,st.duration=start,duration; st.remaining=math.max(0,start+duration-now)
    st.onCD=st.remaining>0 and not gcd; st.active=st.remaining>0; st.usable=enabled~=0
    if m.kind=="spell" and IsUsableSpell and m.book~=(BOOKTYPE_PET or "pet") then
        local usable,noMana=IsUsableSpell(m.name)
        if usable~=nil then st.usable=st.usable and not not usable end
        st.noMana=noMana and true or false
    end
    st.count=0
    if m.kind=="item" or m.kind=="preset" then
        st.count=GetItemCount(itemID,nil,true) or 0
        if st.count==0 then st.usable=false; st.missing=true end
    end
    if bar.showRange and UnitExists("target") then
        if m.kind=="spell" and IsSpellInRange and SpellHasRange and SpellHasRange(m.name) then st.outOfRange=IsSpellInRange(m.name,"target")==0
        elseif itemID and IsItemInRange and ItemHasRange and ItemHasRange(itemID) then st.outOfRange=IsItemInRange(itemID,"target")==0 end
    end
    st.activeAura=nil
    if m.kind=="spell" and bar.activeState and ns.Eff(st,"activeState")~="none" then
        local custom=tonumber(ns.Eff(st,"activeAuraID"))
        local cname=custom and GetSpellInfo(custom)
        local a=ns.FindAura("player","HELPFUL",custom,cname or m.name,nil,true,now)
        if a and a.duration>0 and (custom or a.duration<=60) then st.activeAura=a end
    elseif m.procs and bar.activeState and ns.Eff(st,"activeState")~="none" then
        for _,p in ipairs(m.procs.ids) do
            local a=ns.FindAura("player","HELPFUL",p,nil,nil,false,now)
            if a and a.duration>0 then st.activeAura=a; break end
        end
    end
    if st.fakeUntil and st.fakeUntil>now then st.activeAura={expires=st.fakeUntil,duration=st.fakeDuration or 0,count=0}
    else st.fakeUntil=nil end
    if m.kind=="spell" and ns.Eff(st,"procGlow")~=0 then
        local pa=tonumber(e.procAuraID) and {tonumber(e.procAuraID),tonumber(e.procStacks)} or ns.procByName and ns.procByName[m.name]
        if pa then
            local a=ns.FindAura("player","HELPFUL",pa[1],GetSpellInfo(pa[1]),nil,false,now)
            st.proc=a~=nil and (a.count or 0)>=(pa[2] or 0)
        elseif ns.reactiveByName and ns.reactiveByName[m.name] then st.proc=st.usable and not st.onCD end
    end
    if st.wasCooldown and not st.onCD and enabled~=0 and ns.Profile().readySound and now-(ns.lastReadySound or -1)>1 then
        if PlaySound then PlaySound("RaidWarning") end; ns.lastReadySound=now
    end
    st.wasCooldown=st.onCD
end
-- Which glow an icon shows (Retail priority: active, proc, max stacks/pandemic/buff, CD ready).
function ns.GlowFor(st,now)
    local p,bar,e=ns.Profile(),st.bar,st.entry
    if p.glowsOnlyInCombat and not ns.inCombat then return end
    local style,r,g,b=nil,tonumber(ns.Eff(st,"glowColorR")),tonumber(ns.Eff(st,"glowColorG")),tonumber(ns.Eff(st,"glowColorB"))
    if st.activeAura and (tonumber(ns.Eff(st,"activeGlow")) or 0)>0 then style=tonumber(ns.Eff(st,"activeGlow"))
    elseif st.proc then style=tonumber(ns.Eff(st,"procGlow")) or bar.procGlowStyle
    elseif st.meta.kind=="aura" and st.active then
        local maxStacks=tonumber(e.maxStacks)
        if maxStacks and maxStacks>0 and st.count>=maxStacks and (tonumber(e.maxStacksGlow) or 0)>0 then style=tonumber(e.maxStacksGlow)
        elseif bar.pandemicGlow and st.duration>0 and st.remaining>0 and st.remaining<=st.duration*.3 then style=bar.pandemicGlowStyle; r,g,b=r or bar.pandemicR,g or bar.pandemicG,b or bar.pandemicB
        elseif (tonumber(e.buffGlow) or bar.buffGlow or 0)>0 then style=tonumber(e.buffGlow) or bar.buffGlow end
    else
        local cse=ns.Eff(st,"cdStateEffect")
        if (cse=="pixelGlowReady" or cse=="buttonGlowReady") and not st.onCD and not st.missing or (cse=="pixelGlowReadyUsable" or cse=="buttonGlowReadyUsable") and not st.onCD and st.usable then
            style=tonumber(ns.Eff(st,"cdStateGlowStyle")) or (cse:find("button") and 3 or 1)
        end
    end
    if not style or style<=0 then return end
    return style,r,g,b
end
-- Retail cdStateEffect / Always Show Buffs / Keep Buffs in Same Place: "show", "keep" (slot reserved, invisible) or nil (removed).
function ns.Placement(st)
    local bar,e=st.bar,st.entry
    if st.meta.kind=="aura" then
        if st.active then return "show" end
        if bar.showInactiveBuffIcons or e.alwaysShow then return "show","inactive" end
        if bar.hidePlaceholderIcon then return "keep" end
        return
    end
    if st.missing and bar.hideItemsIfMissing then return end
    local cse=ns.Eff(st,"cdStateEffect")
    if cse=="hiddenOnCDShift" and st.onCD or cse=="hiddenReadyShift" and not st.onCD and not st.activeAura then return end
    if cse=="hiddenOnCD" and st.onCD or cse=="hiddenReady" and not st.onCD and not st.activeAura then return "keep" end
    return "show"
end
function ns.Update()
    local p=ns.Profile(); if not p or not ns.ready then return end
    local now=GetTime(); ns.gcdStart,ns.gcdDuration=0,0
    if GetSpellCooldown then local ok,s,d=pcall(GetSpellCooldown,61304); if ok and d and d>0 and d<=1.7 then ns.gcdStart,ns.gcdDuration=s or 0,d end end
    for _,bar in ipairs(ns.Bars()) do
        for _,st in ipairs(ns.compiled[bar.key] or {}) do ns.UpdateState(st,now) end
    end
    if ns.PaintAll then ns.PaintAll(now) end
    if ns.UpdateTrackingBars then ns.UpdateTrackingBars(now) end
    if ns.UpdateActionGlows then ns.UpdateActionGlows(now) end
end
function ns.Apply()
    if not ns.Profile() or not ns.ready then return end
    ns.ScanSpells(); ns.ScanTalents(); ns.Compile(); ns.ScanAuras()
    if ns.Layout then ns.Layout() end
    if ns.LayoutTrackingBars then ns.LayoutTrackingBars() end
    if ns.RegisterUnlock then ns.RegisterUnlock() end
    if ns.BuildKeybinds then ns.BuildKeybinds() end
    if ns.PrepareActionGlows and not InCombatLockdown() then ns.PrepareActionGlows() end
    ns.Update()
    if E._specProfileSwitching and E.OnSpecSwitchComplete then E.OnSpecSwitchComplete() end
end
function ns.addon:OnInitialize()
    ns.addon.db=E.Lite.NewDB("EllesmereUICooldownManagerDB",ns.defaults); ns.db=ns.addon.db; _ECME_DB=ns.db
end
function ns.OnSpellCast(unit,spellName)
    if unit~="player" or not spellName then return end
    local now=GetTime()
    for _,entries in pairs(ns.compiled) do for _,st in ipairs(entries) do
        local d=tonumber(ns.Eff(st,"activeDuration"))
        if d and d>0 and (st.meta.name==spellName or st.meta.useSpell==spellName) then st.fakeUntil=now+d; st.fakeDuration=d end
    end end
end
-- A watched trinket proc starts its internal cooldown (registered only while one is tracked).
function ns.OnCombatLog(_,sub,src,_,_,dst,_,_,spellID)
    if not ns.icdWatch[spellID] or sub=="SPELL_AURA_REMOVED" or sub=="SPELL_AURA_REMOVED_DOSE" or sub=="SPELL_MISSED" then return end
    local me=UnitGUID("player")
    if src~=me and not (dst==me and (not src or src=="0x0000000000000000" or src==dst)) then return end
    ns.icdStart[spellID]=GetTime(); ns.Update()
end
local EVENTS={"PLAYER_ENTERING_WORLD","SPELLS_CHANGED","ACTIVE_TALENT_GROUP_CHANGED","PLAYER_TALENT_UPDATE","CHARACTER_POINTS_CHANGED","UNIT_PET","UNIT_AURA",
 "PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","SPELL_UPDATE_COOLDOWN","SPELL_UPDATE_USABLE","BAG_UPDATE_COOLDOWN","BAG_UPDATE","UNIT_INVENTORY_CHANGED",
 "PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","ACTIONBAR_SLOT_CHANGED","ACTIONBAR_PAGE_CHANGED","UPDATE_BINDINGS","ADDON_LOADED","GET_ITEM_INFO_RECEIVED",
 "UNIT_SPELLCAST_SUCCEEDED","UPDATE_MACROS"}
function ns.OnEvent(_,event,unit,arg2,...)
    if event=="COMBAT_LOG_EVENT_UNFILTERED" then ns.OnCombatLog(unit,arg2,...)
    elseif event=="UNIT_AURA" or event=="PLAYER_TARGET_CHANGED" or event=="PLAYER_FOCUS_CHANGED" then
        if event~="UNIT_AURA" or unit=="player" or unit=="target" or unit=="focus" or unit=="pet" then ns.ScanAuras(); ns.Update() end
    elseif event=="PLAYER_REGEN_DISABLED" or event=="PLAYER_REGEN_ENABLED" then
        ns.inCombat=event=="PLAYER_REGEN_DISABLED"
        if not ns.inCombat and ns.PrepareActionGlows then ns.PrepareActionGlows() end
        ns.Update()
    elseif event=="ACTIONBAR_SLOT_CHANGED" or event=="ACTIONBAR_PAGE_CHANGED" or event=="UPDATE_BINDINGS" or event=="UPDATE_MACROS" then
        if ns.BuildKeybinds then ns.BuildKeybinds() end; ns.Update()
    elseif event=="SPELL_UPDATE_COOLDOWN" or event=="SPELL_UPDATE_USABLE" or event=="BAG_UPDATE_COOLDOWN" then ns.Update()
    elseif event=="UNIT_SPELLCAST_SUCCEEDED" then ns.OnSpellCast(unit,arg2)
    elseif event=="BAG_UPDATE" or event=="GET_ITEM_INFO_RECEIVED" or event=="UNIT_INVENTORY_CHANGED" then
        if event~="UNIT_INVENTORY_CHANGED" or unit=="player" then ns.Compile(); if ns.Layout then ns.Layout() end; ns.Update() end
    elseif event=="ADDON_LOADED" then
        if unit=="EllesmereUIActionBars" and not InCombatLockdown() then ns.PrepareActionGlows(); ns.Update() end
    else ns.Apply() end
end
function ns.addon:OnEnable()
    ns.ready=true; ns.inCombat=InCombatLockdown() and true or false
    if ns.CreateGroups then ns.CreateGroups() end
    ns.events=CreateFrame("Frame")
    for _,event in ipairs(EVENTS) do ns.events:RegisterEvent(event) end
    ns.events:SetScript("OnEvent",ns.OnEvent)
    local elapsed,auraElapsed=0,0
    ns.events:SetScript("OnUpdate",function(_,dt)
        local p=ns.Profile(); if not p or not p.enabled or not p.cdmBars.enabled then return end
        elapsed=elapsed+dt; auraElapsed=auraElapsed+dt; if elapsed<.1 then return end; elapsed=0
        if auraElapsed>=.5 then auraElapsed=0; ns.ScanAuras() end
        ns.Update()
    end)
    if hooksecurefunc then hooksecurefunc("UseAction",function(slot) if ns.ActionSpellName then local n=ns.ActionSpellName(slot); if n then ns.pressed[n]=GetTime() end end end) end
    if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener(ADDON,function(active)
        ns.unlockPreview=active; ns.preview=active or ns.optionsPreview
        if ns.Layout then ns.Layout() end; if ns.LayoutTrackingBars then ns.LayoutTrackingBars() end; ns.Update()
    end) end
    ns.Apply()
end
_ECME_Apply=function() ns.Apply() end
E.CdmIconStyle=E.CdmIconStyle or function() local p=ns.Profile(); return p and p.useClassicStyle and "classic" or "eui" end
E.CdmBarStyle=E.CdmBarStyle or function() local p=ns.Profile(); return p and p.useClassicStyleBars and "classic" or "eui" end
