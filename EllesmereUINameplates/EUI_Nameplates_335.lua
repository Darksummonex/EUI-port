-- Wrath's anonymous WorldFrame plates remain the native data/click backend.
-- Retail engines and namespaces are not loaded or emulated; the Retail look
-- is painted by EUI_Nameplates_335_Display.lua.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not E or not E.Lite or not WorldFrame then return end
local addon=E.Lite.NewAddon(ADDON_NAME)
E._ModuleNS[ADDON_NAME]=ns
ns.addon,ns.ENP,ns.IsWrath=addon,addon,true
_G.EllesmereNameplates_NS=ns
local function C(r,g,b) return {r=r,g=g,b=b} end
local defaults={enabled=true,
    width=150,height=17,castHeight=17,yOffset=0,showBorder=true,borderSize=1,
    healthBarTexture="flat",castBarTexture="flat",
    bgColor=C(.12,.12,.12),bgAlpha=1,borderColor=C(.067,.067,.067),
    nameSize=11,healthTextSize=10,levelSize=10,totSize=10,castNameSize=10,castTimerSize=10,
    auraStackTextSize=10,auraDurationTextSize=10,nameYOffset=4,
    nameOutline="module",healthTextOutline="module",levelOutline="module",totOutline="module",castNameOutline="module",
    castTimerOutline="module",auraStackTextOutline="module",auraDurationTextOutline="module",friendlyNameOutline="module",
    textSlotTop="enemyName",textSlotLeft="level",textSlotRight="healthPercent",textSlotCenter="none",
    showHealthText=true,healthPctDecimal=false,showLevel=true,classColoredNames=false,
    enemyInCombat=C(.8,.137,.137),neutral=C(.81,.72,.19),tapped=C(.5,.5,.5),
    boss=C(.518,.243,.984),miniboss=C(.518,.243,.984),colorBosses=true,colorElitesInInstances=true,
    friendlyBarColor=C(.314,.8,.408),friendlyNPCColor=C(0,1,0),friendlyHealthClassColored=false,
    threatColorMode="instances",threatRole="auto",threatColorHealth=true,threatColorBorder=false,threatColorName=false,
    classicTankAggro=false,tankHasAggro=C(.05,.82,.62),tankLosingAggro=C(.81,.72,.19),tankNoAggro=C(1,.22,.17),
    dpsHasAggro=C(1,.5,0),dpsNearAggro=C(.81,.72,.19),
    showCastBar=true,showCastName=true,showCastTimer=true,castBarOffsetY=0,
    castBarColor=C(.7,.4,.9),castBarUninterruptible=C(.45,.45,.45),interruptReady=C(.92,.35,.2),
    castBarKickTint=true,castBarShieldEnabled=true,castBarSparkEnabled=true,
    castBgColor=C(.1,.1,.1),castBgAlpha=.9,castIconPosition="left",
    kickTickEnabled=true,kickTickColor=C(1,1,1),showInterruptedFlash=true,interruptedColor=C(.8,0,0),
    hideEnemyNameWhileCasting=false,
    targetEffect="glow",targetGlowColor=C(.41,.67,1),targetBorderColor=C(1,1,1),
    showTargetArrows=false,targetArrowStyle="simple",targetArrowScale=1,targetArrowClassColor=false,targetArrowColor=C(1,1,1),
    enableTargetColor=false,targetColor=C(.41,.67,1),targetTexture="none",targetScale=1,
    hoverEffect="highlight",opacity=100,nonTargetAlpha=100,
    hashLineEnabled=false,hashLinePercent=30,hashLineColor=C(1,1,1),
    executeGlow=true,showClassPower=true,classPowerScale=1.8,
    showAuras=true,showDebuffs=true,showBuffs=true,onlyPlayerDebuffs=true,buffHasDuration=true,
    debuffSlot="top",buffSlot="left",auraSize=26,buffSize=24,auraSpacing=2,maxAuras=5,maxBuffs=4,
    debuffYOffset=2,sideAuraXOffset=2,auraTimerPosition="topleft",
    ccSlot="right",ccSize=24,ccSpacing=2,debuffIncludeCC=false,
    showRaidMarker=true,raidMarkerSlot="topright",raidMarkerSize=24,
    showClassification=true,classificationSlot="topleft",classificationSize=20,
    classificationHideRare=false,classificationHideQuest=false,classificationShowInInstances=false,
    friendlyNameOnly=true,friendlyNameSize=15,hideEnemiesOutOfCombat=false,
}
ns.defaults=defaults
ns.MAX_DEBUFFS,ns.MAX_BUFFS,ns.MAX_CC=8,6,2
local states,active,pending={},false,false
ns.plates=states
local elapsed,scanElapsed=0,0
ns.layoutVersion=0
local castCVarOriginal,pendingCVars
local auraLib=LibStub and LibStub("LibAuraInfo-1.0-ElvUI",true)
local syncingAuraCache=false
ns.auraLib=auraLib
-- Class hints are cosmetic only; never use name/roster matches for auras or casts.
local rosterClasses,observedClasses={},{}
local marker="interface\\targetingframe\\ui-targetingframe-flash"
function ns.GetSettings() return addon.db and addon.db.profile end
function ns.IsActive() return active end
local function Kind(object,kind)
    return object and object.GetObjectType and object:GetObjectType()==kind
end
function ns.FindNativeParts(plate)
    if not plate.GetRegions or not plate.GetChildren then return end
    local threat,border,castBorder,shield,icon,highlight,name,level,boss,raid,elite=plate:GetRegions()
    if not Kind(threat,"Texture") then return end
    local path=threat:GetTexture()
    if type(path)~="string" or path:lower():gsub("%.blp$","")~=marker then return end
    local health,cast=plate:GetChildren()
    if not Kind(health,"StatusBar") or not Kind(cast,"StatusBar") or not Kind(name,"FontString") or not Kind(level,"FontString") then return end
    -- Another renderer has already taken ownership of this native plate.
    if plate.UnitFrame then
        if not ns.otherRendererDetected then
            ns.otherRendererDetected=true
            if E.PrintError then E.PrintError("Another nameplate skin is active. Disable its nameplate module to show EllesmereUI Nameplates.") end
        end
        return
    end
    return {health=health,cast=cast,threat=threat,border=border,castBorder=castBorder,
        shield=shield,icon=icon,highlight=highlight,name=name,level=level,boss=boss,raid=raid,elite=elite}
end
function ns.HideNative(s)
    for region in pairs(s.originalAlpha) do region:SetAlpha(0) end
    -- The client's flash animation can overwrite alpha. Keep its threat state
    -- and vertex colors, but never let the old-size texture render.
    s.native.threat:SetTexture("")
end
function ns.ClearUnit(s)
    if s.isPreview then return end
    s.unit,s.guid,s.isTarget=nil,nil,false
    s.friendlyClass=nil
    s.auraGUID,s.auraName,s.auraVerified=nil,nil,nil
    s.flashUntil=nil
    s.debuffList,s.buffList,s.ccList,s.auraDirty={},{},{},true
    if s.auras then for _,a in ipairs(s.auras) do a:Hide() end end
    if s.buffs then for _,a in ipairs(s.buffs) do a:Hide() end end
    if s.ccs then for _,a in ipairs(s.ccs) do a:Hide() end end
end
function ns.Ratio(bar)
    local low,high=bar:GetMinMaxValues(); local value=bar:GetValue()
    if type(low)~="number" or type(high)~="number" or type(value)~="number" or high<=low then return 0 end
    return math.max(0,math.min(1,(value-low)/(high-low)))
end
-- Native bar colors: red hostile, yellow neutral, green friendly NPC,
-- blue friendly player, grey tapped; anything else is a native class color.
function ns.NativeKind(s)
    local r,g,b=s.native.health:GetStatusBarColor()
    if math.abs(r-.5)<.05 and math.abs(g-.5)<.05 and math.abs(b-.5)<.05 then return "tapped" end
    if r>.9 and g<.1 and b<.1 then return "hostile" end
    if r>.9 and g>.9 and b<.1 then return "neutral" end
    if r<.1 and g>.9 and b<.1 then return "friendlyNPC" end
    if r<.1 and g<.1 and b>.9 then return "friendlyPlayer" end
    return "class"
end
function ns.Friendly(s)
    if s.unit and UnitReaction then local r=UnitReaction("player",s.unit); if r then return r>=5 end end
    local kind=ns.NativeKind(s)
    return kind=="friendlyNPC" or kind=="friendlyPlayer"
end
local function NativeFriendlyPlayer(s) return ns.NativeKind(s)=="friendlyPlayer" end
local function FriendlyUnitClass(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    local reaction=UnitReaction("player",unit)
    if not reaction or reaction<5 then return end
    local class=select(2,UnitClass(unit))
    if class and RAID_CLASS_COLORS[class] then return class end
end
local function RememberClass(store,unit)
    local class=FriendlyUnitClass(unit)
    if not class then return end
    local name,guid=UnitName(unit),UnitGUID(unit)
    if not name or not guid then return end
    store[name]=store[name] or {}; store[name][guid]=class
end
function ns.RefreshFriendlyRoster()
    rosterClasses={}
    RememberClass(rosterClasses,"player")
    for i=1,4 do RememberClass(rosterClasses,"party"..i) end
    for i=1,40 do RememberClass(rosterClasses,"raid"..i) end
end
local function KnownClass(name)
    local foundGUID,foundClass
    for _,store in ipairs({rosterClasses,observedClasses}) do
        for guid,class in pairs(store[name] or {}) do
            if foundGUID and foundGUID~=guid then return end
            foundGUID,foundClass=guid,class
        end
    end
    return foundClass
end
local function ResolveFriendlyClasses()
    for _,unit in ipairs({"target","mouseover","focus"}) do RememberClass(observedClasses,unit) end
    local visibleNames={}
    for plate,s in pairs(states) do
        if plate:IsShown() and NativeFriendlyPlayer(s) then
            local name=s.native.name:GetText()
            if name then visibleNames[name]=(visibleNames[name] or 0)+1 end
        end
    end
    for plate,s in pairs(states) do
        s.friendlyClass=nil
        if plate:IsShown() then
            if s.unit then s.friendlyClass=FriendlyUnitClass(s.unit)
            elseif NativeFriendlyPlayer(s) then
                local name=s.native.name:GetText()
                if name and visibleNames[name]==1 then s.friendlyClass=KnownClass(name) end
            end
        end
    end
end
-- Native glow: 3 red (securely tanking), 2 orange (tanking, not highest),
-- 1 yellow (high threat). Identified units use the unit API instead.
function ns.NativeThreat(s)
    local n=s.native.threat
    if not n or not n:IsShown() then return end
    local r,g,b=n:GetVertexColor()
    if r and r>0 then if g and g>0 then return b and b>0 and 1 or 2 end; return 3 end
end
function ns.ThreatStatus(s)
    if s.unit and UnitThreatSituation and UnitGUID(s.unit)==s.guid then
        local status=UnitThreatSituation("player",s.unit)
        if status then return status,UnitAffectingCombat and UnitAffectingCombat(s.unit) end
    end
    local status=ns.NativeThreat(s)
    return status,status~=nil
end
local TANK_AURAS={71,5487,9634,25780,48263} -- Defensive Stance, Bear, Dire Bear, Righteous Fury, Frost Presence
local tankNames
-- Runs per plate on every health change; the result is cached until the player's auras change.
function ns.IsTank(p)
    if p.threatRole=="tank" then return true elseif p.threatRole=="dps" then return false end
    if ns.tankState==nil then
        if not tankNames then
            tankNames={}
            for _,id in ipairs(TANK_AURAS) do
                local name=GetSpellInfo and GetSpellInfo(id)
                if name then tankNames[#tankNames+1]=name end
            end
        end
        local tank=false
        for _,name in ipairs(tankNames) do if UnitAura("player",name) then tank=true; break end end
        ns.tankState=tank
    end
    return ns.tankState
end
function ns.InGroup()
    return (GetNumRaidMembers and GetNumRaidMembers() or 0)>0 or (GetNumPartyMembers and GetNumPartyMembers() or 0)>0
end
function ns.ThreatAllowed(p)
    local mode=p.threatColorMode
    if mode=="never" then return false end
    if mode=="always" then return true end
    local inside,kind=false,nil
    if IsInInstance then inside,kind=IsInInstance() end
    return inside and (kind=="party" or kind=="raid") or false
end
-- Retail threat palette, resolved for an enemy plate. Returns a color table or nil.
function ns.ThreatColor(s,p)
    if not ns.ThreatAllowed(p) then return end
    local status,inCombat=ns.ThreatStatus(s)
    if not status then return end
    if ns.IsTank(p) then
        if status>=3 then return p.classicTankAggro and p.tankHasAggro or nil end
        if status==2 then return p.tankLosingAggro end
        if inCombat then return p.tankNoAggro end
        return
    end
    if not ns.InGroup() then return end
    if status>=3 then return p.dpsHasAggro end
    if status==2 then return p.dpsNearAggro end
end
local function MatchName(s,unit)
    local name=UnitName(unit); return name and name==s.native.name:GetText()
end
local function BindUnits()
    local target,hover,targetCount,hoverCount=nil,nil,0,0
    local hasTarget=UnitExists("target")
    local hasHover=UnitExists("mouseover")
    for plate,s in pairs(states) do
        s.oldUnit,s.oldGUID,s.oldAuraGUID=s.unit,s.guid,s.auraGUID
        s.unit,s.guid,s.isTarget=nil,nil,false
        if plate:IsShown() then
            if hasTarget and plate:GetAlpha()>=.99 and MatchName(s,"target") then target=s; targetCount=targetCount+1 end
            if hasHover and s.native.highlight and s.native.highlight:IsShown() and MatchName(s,"mouseover") then hover=s; hoverCount=hoverCount+1 end
        end
    end
    -- Names are not identities. Require native selection/highlight and a
    -- unique candidate, never bind multiple same-name plates to one unit.
    if targetCount==1 then target.unit,target.guid,target.isTarget="target",UnitGUID("target"),true end
    if hoverCount==1 and not hover.isTarget then
        local guid=UnitGUID("mouseover")
        -- A native mouseover highlight is stronger evidence than selection
        -- alpha during a target transition. One unit cannot own two plates.
        if targetCount==1 and target~=hover and target.guid==guid then
            target.unit,target.guid,target.isTarget=nil,nil,false
        end
        hover.unit,hover.guid="mouseover",guid
    end
    local owners={}
    for _,s in pairs(states) do if s.unit and s.guid then owners[s.guid]=s end end
    for _,s in pairs(states) do
        if s.unit~=s.oldUnit or s.guid~=s.oldGUID then s.auraDirty=true end
        if s.guid~=s.oldGUID then s.flashUntil=nil end
        if s.unit then s.auraGUID,s.auraName,s.auraVerified=s.guid,s.native.name:GetText(),true
        elseif not s.auraVerified or s.auraName~=s.native.name:GetText()
            or (s.auraGUID and owners[s.auraGUID] and owners[s.auraGUID]~=s) then
            s.auraGUID,s.auraName,s.auraVerified=nil,nil,nil
        end
    end
    -- Name-only combat-log matches cannot identify anonymous Wrath NPCs.
    -- Keep a GUID only on the plate observed through selection/mouseover,
    -- for that visible lifetime. Never populate nearby same-name plates.
    local counts={}
    for plate,s in pairs(states) do if plate:IsShown() and s.auraGUID then counts[s.auraGUID]=(counts[s.auraGUID] or 0)+1 end end
    for _,s in pairs(states) do
        if s.auraGUID and counts[s.auraGUID] and counts[s.auraGUID]>1 then s.auraGUID,s.auraName,s.auraVerified=nil,nil,nil end
        if s.auraGUID~=s.oldAuraGUID then s.auraDirty=true end
    end
end
-- Returns name, icon, seconds left, bar value, uninterruptible, duration, channel, end time (seconds).
function ns.CastInfo(s)
    if s.previewCast then return unpack(s.previewCast) end
    if not s.unit or UnitGUID(s.unit)~=s.guid then return end
    local name,_,_,icon,startTime,endTime,_,_,locked=UnitCastingInfo(s.unit)
    local channel=false
    if not name then name,_,_,icon,startTime,endTime,_,locked=UnitChannelInfo(s.unit); channel=true end
    if not name or not startTime or not endTime or endTime<=startTime then return end
    local duration=(endTime-startTime)/1000; local left=math.max(0,endTime/1000-GetTime())
    if left<=0 then return end
    return name,icon,left,channel and left/duration or 1-left/duration,locked,duration,channel,endTime/1000
end
-- Crowd Control: Wrath auras carry no CC flag, so the CC set is LibAuraInfo's DR table
-- (DRData, every category but taunt), matched by spell ID, then by name for other ranks.
local ccNames
function ns.IsCrowdControl(spellID,name)
    local dr=ns.auraLib and ns.auraLib.drSpells
    if not dr then return false end
    local category=spellID and dr[spellID]
    if category then return category~="taunt" end
    if not ccNames then
        ccNames={}
        for id,kind in pairs(dr) do
            local spell=kind~="taunt" and GetSpellInfo and GetSpellInfo(id)
            if spell then ccNames[spell]=true end
        end
    end
    return name~=nil and ccNames[name]==true
end
local function CollectAuras(s,p)
    local debuffs,buffs,ccs={},{},{}
    s.debuffList,s.buffList,s.ccList=debuffs,buffs,ccs
    if not p.showAuras or (p.friendlyNameOnly and ns.Friendly(s)) then return end
    local direct=s.guid and s.unit and UnitGUID(s.unit)==s.guid
    local cached=auraLib and s.auraVerified and s.auraGUID
    if not direct and not cached then return end
    -- Events may predate library registration, or arrive before the native
    -- aura list is ready. Preserve every live observation before the token
    -- changes, rather than relying on target-change callback ordering.
    if direct and auraLib and auraLib.frame and auraLib.frame.UNIT_AURA then
        syncingAuraCache=true
        auraLib.frame:UNIT_AURA("UNIT_AURA",s.unit)
        syncingAuraCache=false
    end
    if cached then auraLib:GetNumGUIDAuras(s.auraGUID) end -- expires cached entries
    local function Scan(filter,visit)
        for i=1,40 do
            local name,icon,stacks,duration,expires,caster,stealable,spellID,mine
            if direct then
                local rank,dtype
                name,rank,icon,stacks,dtype,duration,expires,caster,stealable,rank,spellID=UnitAura(s.unit,i,filter)
                mine=caster=="player" or caster=="pet" or caster=="vehicle"
            else
                local valid,dtype,sourceGUID
                valid,name,icon,stacks,dtype,duration,expires,sourceGUID,spellID=auraLib:GUIDAura(s.auraGUID,i,filter)
                if not valid then break end
                mine=sourceGUID and (sourceGUID==UnitGUID("player") or sourceGUID==UnitGUID("pet") or sourceGUID==UnitGUID("vehicle"))
            end
            if not name then break end
            if visit(name,icon,stacks,duration,expires,stealable,spellID,mine) then return end
        end
    end
    local function Allowed(prefix,name,duration,stealable,spellID,mine)
        local include=prefix~="debuff" or not p.onlyPlayerDebuffs or mine
        if E.WrathAuraFilters then include=E.WrathAuraFilters.Allow(p,prefix,spellID,mine,duration,stealable,name) end
        return include
    end
    local maxDebuffs=math.max(1,math.min(ns.MAX_DEBUFFS,tonumber(p.maxAuras) or 5))
    local maxBuffs=math.max(1,math.min(ns.MAX_BUFFS,tonumber(p.maxBuffs) or 4))
    local debuffsOn=p.showDebuffs and p.debuffSlot~="none"
    local ccOwn=p.ccSlot~=nil and p.ccSlot~="none"
    local ccMerged=not ccOwn and debuffsOn and p.debuffIncludeCC
    -- With a CC element placed, CC (any caster) leaves the debuff row as on Retail; Debuffs + CC
    -- lists it first in the debuff row.
    if debuffsOn or ccOwn then
        local merged={}
        Scan("HARMFUL",function(name,icon,stacks,duration,expires,stealable,spellID,mine)
            local entry={icon=icon,stacks=stacks,expires=expires}
            if (ccOwn or ccMerged) and ns.IsCrowdControl(spellID,name) then
                if ccOwn then if #ccs<ns.MAX_CC then ccs[#ccs+1]=entry end
                elseif #merged<maxDebuffs then merged[#merged+1]=entry end
            elseif debuffsOn and #debuffs<maxDebuffs and Allowed("debuff",name,duration,stealable,spellID,mine) then
                debuffs[#debuffs+1]=entry
            end
            if ccMerged then return #merged>=maxDebuffs end
            return (not debuffsOn or #debuffs>=maxDebuffs) and (not ccOwn or #ccs>=ns.MAX_CC)
        end)
        for i=#merged,1,-1 do table.insert(debuffs,1,merged[i]) end
        for i=#debuffs,maxDebuffs+1,-1 do debuffs[i]=nil end
    end
    -- Buffs are only interesting on enemies.
    if p.showBuffs and p.buffSlot~="none" and not ns.Friendly(s) then
        Scan("HELPFUL",function(name,icon,stacks,duration,expires,stealable,spellID,mine)
            if Allowed("buff",name,duration,stealable,spellID,mine) then buffs[#buffs+1]={icon=icon,stacks=stacks,expires=expires} end
            return #buffs>=maxBuffs
        end)
    end
end
-- Execute-range spells known by the player (rank-independent name lookup).
local EXECUTE={WARRIOR={5308,.2},PALADIN={24275,.2},HUNTER={53351,.2},WARLOCK={1120,.25}}
function ns.RefreshExecute()
    ns.executeThreshold=nil
    local class=select(2,UnitClass("player")); local entry=EXECUTE[class]
    if not entry or not GetSpellInfo then return end
    local name=GetSpellInfo(entry[1])
    if name and GetSpellInfo(name) then ns.executeThreshold=entry[2] end
end
function ns.Scan()
    if not active then return end
    for _,plate in ipairs({WorldFrame:GetChildren()}) do
        if not states[plate] then
            local native=ns.FindNativeParts(plate)
            if native then states[plate]=ns.Capture(plate,native) end
        end
    end
end
function ns.Update()
    local p=ns.GetSettings(); if not active or not p then return end
    BindUnits()
    ResolveFriendlyClasses()
    for plate,s in pairs(states) do
        if plate:IsShown() then
            if s.auraDirty or not s.auraTime or GetTime()-s.auraTime>=.15 then
                s.auraDirty=false; s.auraTime=GetTime(); CollectAuras(s,p)
            end
            ns.Paint(s,p)
        else s.root:Hide() end
    end
end
-- A newly shown plate binds and paints only itself now; the other plates follow on the next frame.
function ns.UpdatePlate(s)
    local p=ns.GetSettings(); if not active or not p then return end
    BindUnits()
    ResolveFriendlyClasses()
    s.auraDirty=false; s.auraTime=GetTime(); CollectAuras(s,p)
    ns.Paint(s,p); ns.updatePending=true
end
-- Quest Indicator: Wrath plates carry no unit and unit tooltips list no objectives, so a quest
-- mob is a plate whose name matches an unfinished kill objective in the quest log.
local function QuestKillPattern()
    local fmt=(QUEST_MONSTERS_KILLED or "%s slain: %d/%d"):gsub("%%%d%$","%%")
    fmt=fmt:gsub("([%(%)%.%+%-%*%?%[%]%^%$])","%%%1")
    fmt=fmt:gsub("%%s","(.-)"):gsub("%%d","%%d+")
    return "^"..fmt.."$"
end
function ns.RefreshQuestMobs()
    local mobs,pattern={},QuestKillPattern()
    for i=1,(GetNumQuestLogEntries and GetNumQuestLogEntries() or 0) do
        local _,_,_,_,header,_,complete=GetQuestLogTitle(i)
        if not header and complete~=1 then
            for j=1,(GetNumQuestLeaderBoards(i) or 0) do
                local text,kind,done=GetQuestLogLeaderBoard(j,i)
                if text and kind=="monster" and not done then
                    local mob=text:match(pattern) or text:match("^(.-):%s*%d+/%d+$")
                    if mob and mob~="" then mobs[mob]=true end
                end
            end
        end
    end
    ns.questMobs=mobs
end
function ns.UpdateHealth(s)
    local p=ns.GetSettings(); if p and active then ns.PaintHealth(s,p) end
end
function ns.Restore()
    active=false
    for _,s in pairs(states) do
        ns.ClearUnit(s); s.root:Hide()
        for region,alpha in pairs(s.originalAlpha) do region:SetAlpha(alpha) end
        s.native.threat:SetTexture(s.originalThreatTexture)
    end
    if castCVarOriginal~=nil then ns.SetCVar("showVKeyCastbar",castCVarOriginal); castCVarOriginal=nil end
end
function ns.SetCVar(key,value)
    if E.SetCVar then E.SetCVar(key,value,ADDON_NAME) else SetCVar(key,value) end
end
local NATIVE_CVARS={nameplateShowEnemies=true,nameplateShowFriends=true,nameplateAllowOverlap=true,
    ShowClassColorInNameplate=true,nameplateShowEnemyPets=true}
function ns.SetNativeCVar(key,value)
    if not NATIVE_CVARS[key] then return end
    if InCombatLockdown() then pendingCVars=pendingCVars or {}; pendingCVars[key]=value and "1" or "0"; return end
    ns.SetCVar(key,value and "1" or "0")
end
-- "Hide Enemy Nameplates out of Combat": the CVar is only writable out of
-- combat, so plates are revealed on REGEN_DISABLED before lockdown applies.
local function ApplyCombatVisibility(inCombat)
    local p=ns.GetSettings()
    if not p or not p.enabled or not p.hideEnemiesOutOfCombat or InCombatLockdown() then return end
    ns.SetCVar("nameplateShowEnemies",inCombat and "1" or "0")
end
ns.ApplyCombatVisibility=ApplyCombatVisibility
local function Migrate(p)
    if p.threatColors==true then p.threatColorMode="always" end
    if p.tankMode==true then p.threatRole="tank" end
    if p.showTargetBorder==false then p.targetEffect="none" end
    if p.borderSize==0 then p.showBorder,p.borderSize=false,1 end
    p.threatColors,p.tankMode,p.showTargetBorder=nil,nil,nil
    -- Crowd Control arrived with a Retail default slot; an older profile may already use it.
    for _,key in ipairs({"debuffSlot","buffSlot","raidMarkerSlot","classificationSlot"}) do
        if p.ccSlot~="none" and p[key]==p.ccSlot then p.ccSlot="none" end
    end
    if p.debuffIncludeCC and p.ccSlot~="none" then p.debuffIncludeCC=false end
    for _,slot in ipairs({"Top","Left","Right","Center"}) do
        if p["textSlot"..slot]=="name" then p["textSlot"..slot]="enemyName" end
    end
end
ns.Migrate=Migrate
function ns.Apply()
    local p=ns.GetSettings(); if not p then return end
    if InCombatLockdown() then pending=true; return end
    pending=false
    Migrate(p)
    if not p.enabled then ns.Restore(); return end
    if castCVarOriginal==nil then castCVarOriginal=GetCVar("showVKeyCastbar") end
    ns.SetCVar("showVKeyCastbar","1")
    ApplyCombatVisibility(false)
    for _,s in pairs(states) do s.auraDirty=true end
    active=true; ns.layoutVersion=ns.layoutVersion+1; ns.Scan(); ns.Update()
end
ns.RefreshAllSettings=ns.Apply
local function FlashInterrupted(unit)
    local p=ns.GetSettings(); if not p or not p.showInterruptedFlash then return end
    local guid=UnitGUID(unit); if not guid then return end
    for _,s in pairs(states) do
        if s.guid==guid then s.flashUntil=GetTime()+.6 end
    end
end
function addon:OnInitialize()
    addon.db=E.Lite.NewDB("EllesmereUINameplatesDB",{profile=defaults}); ns.db=addon.db
    _G._ENP_RefreshAllSettings=ns.Apply
    SLASH_ELLESMERENAMEPLATES1="/enp"
    SlashCmdList.ELLESMERENAMEPLATES=function()
        if InCombatLockdown() then return end
        if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; E:ShowModule(ADDON_NAME)
    end
end
function addon:OnEnable()
    if not addon.db then return end
    ns.RefreshFriendlyRoster()
    ns.RefreshExecute()
    ns.Apply()
    if auraLib then
        for _,event in ipairs({"AURA_APPLIED","AURA_REMOVED","AURA_REFRESH","AURA_APPLIED_DOSE","AURA_CLEAR","UNIT_AURA"}) do
            auraLib.RegisterCallback(ns,"LibAuraInfo_"..event,function(_,guid)
                if syncingAuraCache then return end
                for _,s in pairs(states) do if not guid or s.auraGUID==guid then s.auraDirty=true end end
            end)
        end
    end
    local f=CreateFrame("Frame"); ns.events=f
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","PLAYER_TARGET_CHANGED",
        "UPDATE_MOUSEOVER_UNIT","UNIT_AURA","PARTY_MEMBERS_CHANGED","RAID_ROSTER_UPDATE","UNIT_SPELLCAST_INTERRUPTED",
        "SPELLS_CHANGED","LEARNED_SPELL_IN_TAB","QUEST_LOG_UPDATE"}) do f:RegisterEvent(event) end
    f:SetScript("OnEvent",function(_,event,unit)
        if event=="PLAYER_REGEN_ENABLED" then
            for key,value in pairs(pendingCVars or {}) do ns.SetCVar(key,value) end; pendingCVars=nil
            if pending then ns.Apply() end
            ApplyCombatVisibility(false)
        elseif event=="PLAYER_REGEN_DISABLED" then ApplyCombatVisibility(true)
        elseif event=="PLAYER_ENTERING_WORLD" then ns.tankState=nil; observedClasses={}; ns.RefreshFriendlyRoster(); ns.RefreshExecute(); ns.RefreshQuestMobs(); ns.Apply()
        elseif event=="QUEST_LOG_UPDATE" then ns.RefreshQuestMobs()
        elseif event=="PARTY_MEMBERS_CHANGED" or event=="RAID_ROSTER_UPDATE" then ns.RefreshFriendlyRoster(); ns.Update()
        elseif event=="SPELLS_CHANGED" or event=="LEARNED_SPELL_IN_TAB" then ns.RefreshExecute()
        elseif event=="UNIT_SPELLCAST_INTERRUPTED" then if unit then FlashInterrupted(unit) end; ns.Update()
        elseif event=="UNIT_AURA" then
            -- 3.3.5 sends UNIT_AURA for every unit; only plate-bound tokens and the player's tank state matter.
            if unit=="player" then ns.tankState=nil
            elseif unit=="target" or unit=="mouseover" or unit=="focus" then
                for _,s in pairs(states) do if s.unit==unit then s.auraDirty=true end end
                ns.updatePending=true
            end
        else ns.updatePending=true end
    end)
    -- Events only flag an update; one pass per frame at most, plus the 20 Hz refresh.
    f:SetScript("OnUpdate",function(_,dt)
        if not active then return end
        elapsed,scanElapsed=elapsed+dt,scanElapsed+dt
        if scanElapsed>=.25 then scanElapsed=0; ns.Scan() end
        if elapsed>=.05 or ns.updatePending then elapsed=0; ns.updatePending=false; ns.Update() end
    end)
end
