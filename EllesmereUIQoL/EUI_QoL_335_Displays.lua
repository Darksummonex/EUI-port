local ADDON_NAME,ns=...
local E=EllesmereUI
if not ns.addon then return end
local white="Interface\\Buttons\\WHITE8X8"
local frames,dead,alerts={}, {}, {}
ns.frames=frames
-- key, mover label, width, height, x, y, text size key, unlock key, options section, options row,
-- x/y given in physical pixels (the Unlock Mode readout) instead of UI units.
-- Rows without an unlock key are fixed anchors: no mover and no saved position.
local layout={
    {"fps","FPS Counter",220,20,0,-260,"fpsTextSize","EUI_FPS","FPS COUNTER","FPS and Latency"},
    {"stats","Secondary Stats",130,34,0,-285,"statsTextSize","EUI_SecondaryStats","SECONDARY STATS","Secondary Stats"},
    {"coordinates","Map Coordinates",180,20,0,-330,"mapCoordsTextSize","EUI_MapCoords","CROSSHAIR AND COORDINATES","Screen Coordinates"},
    {"crosshair","Character Crosshair",40,40,0,0,nil,"EUI_Crosshair","CROSSHAIR AND COORDINATES","Character Crosshair"},
    {"durability","Durability Warning",400,40,0,250,"durWarnTextSize","EUI_DurabilityWarning","ALERTS","Low Durability Warning"},
    {"combatAlert","Combat Alert",300,36,0,120,"combatAlertTextSize","EUI_CombatAlert","ALERTS","Combat Alert"},
    {"deathAlert","Group Death Alert",420,40,0,190,"groupDeathTextSize","EUI_GroupDeathAlert","ALERTS","Group Death Alert"},
    {"bloodlust","Sated / Exhaustion",120,32,180,-150,"trackerTextSize","EUI_Bloodlust","TRACKERS","Sated / Exhaustion Timer"},
    {"battleRes","Rebirth Cooldown",120,32,180,-190,"trackerTextSize","EUI_BattleRes","TRACKERS","Rebirth Cooldown (Druid)"},
    {"movement","Movement Cooldown",120,32,180,-230,"trackerTextSize","EUI_MovementAlert","TRACKERS","Movement Cooldown"},
    {"targetDistance","Target Distance",90,28,0,-120,"targetDistanceTextSize","EUI_TargetDistance","TARGET DISTANCE","Target Distance Text"},
    {"zoneText","Zone Text",512,64,9,322,nil,nil,"ZONE TEXT","Move Zone Text",true},
}
ns.displayLayout=layout
local _,class=UnitClass("player")
ns.classMovement={DRUID=1850,HUNTER=781,MAGE=1953,ROGUE=2983,WARRIOR=100}
local function Visible(key,show)
    local p=ns.GetSettings(); local f=frames[key]
    if f then if p.enabled and p[key] and (show or ns.preview) then f:Show() else f:Hide() end end
end
local function Color(c,r,g,b,a) c=c or {}; return c.r or r,c.g or g,c.b or b,c.a or a end
local function ClassColor() local c=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]; if c then return c.r,c.g,c.b end end
local function Hex(r,g,b) return string.format("%02x%02x%02x",math.floor((r or 1)*255+.5),math.floor((g or 1)*255+.5),math.floor((b or 1)*255+.5)) end

function ns.Sounds()
    if not ns.soundPaths then
        if E.BuildAlertSoundTables then ns.soundPaths,ns.soundNames,ns.soundOrder=E.BuildAlertSoundTables()
        else ns.soundPaths,ns.soundNames,ns.soundOrder={},{none="None"},{"none"} end
        if E.AppendSharedMediaSounds then E.AppendSharedMediaSounds(ns.soundPaths,ns.soundNames,ns.soundOrder) end
    end
    return ns.soundPaths,ns.soundNames,ns.soundOrder
end
function ns.PlaySound(key)
    local path=key and key~="none" and ns.Sounds()[key]
    if path and PlaySoundFile then PlaySoundFile(path,"Master") end
end

-- Alerts fade in, hold, then fade out like Retail's animation groups.
local function AlertOnUpdate(self)
    local a=alerts[self.key]; local now=GetTime()
    if not a or now>=a.expires then if not ns.preview then self:Hide() end; self:SetAlpha(1); return end
    local t,left=now-a.start,a.expires-now
    self:SetAlpha(t<.15 and t/.15 or left<.5 and left/.5 or 1)
end
local function NewFrame(c)
    local key=c[1]; local f=CreateFrame("Frame","EUI335QoL_"..key,UIParent)
    ns.Size(f,c[3],c[4]); f:SetFrameStrata("MEDIUM"); f:EnableMouse(false); f.key=key
    if key=="crosshair" then
        f.hBorder=f:CreateTexture(nil,"ARTWORK"); f.vBorder=f:CreateTexture(nil,"ARTWORK")
        f.horizontal=f:CreateTexture(nil,"OVERLAY"); f.vertical=f:CreateTexture(nil,"OVERLAY")
        for _,t in ipairs({f.hBorder,f.vBorder,f.horizontal,f.vertical}) do t:SetTexture(white); t:SetPoint("CENTER",f,"CENTER",0,0) end
    else
        f.text=f:CreateFontString(nil,"OVERLAY"); ns.Font(f.text,12); f.text:SetPoint("CENTER",f,"CENTER",0,0)
        if key=="fps" then
            f.text:ClearAllPoints(); f.text:SetPoint("LEFT",f,"LEFT",0,0)
            f.div1=f:CreateTexture(nil,"OVERLAY"); f.div2=f:CreateTexture(nil,"OVERLAY")
            for _,t in ipairs({f.div1,f.div2}) do t:SetTexture(white); ns.Size(t,1,10) end
            f.world=f:CreateFontString(nil,"OVERLAY"); f.worldLabel=f:CreateFontString(nil,"OVERLAY")
            f.localMs=f:CreateFontString(nil,"OVERLAY"); f.localLabel=f:CreateFontString(nil,"OVERLAY")
        elseif key=="stats" then
            f.text:ClearAllPoints(); f.text:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); if f.text.SetJustifyH then f.text:SetJustifyH("LEFT") end
        elseif key=="bloodlust" or key=="battleRes" or key=="movement" then
            f.icon=f:CreateTexture(nil,"ARTWORK"); ns.Size(f.icon,30,30); f.icon:SetPoint("LEFT",f,"LEFT",0,0); f.icon:SetTexCoord(.08,.92,.08,.92)
            f.cooldown=CreateFrame("Cooldown",nil,f,"CooldownFrameTemplate"); f.cooldown:SetAllPoints(f.icon)
            f.text:ClearAllPoints(); f.text:SetPoint("LEFT",f,"LEFT",34,0)
        elseif key=="durability" then
            f:SetFrameStrata("HIGH"); f.clock=0
            f:SetScript("OnUpdate",function(self,dt) self.clock=self.clock+(dt or 0); self.text:SetAlpha(.65+.35*math.cos(self.clock*math.pi*2/.8)) end)
        elseif key=="combatAlert" or key=="deathAlert" then
            f:SetFrameStrata("HIGH"); f:SetScript("OnUpdate",AlertOnUpdate)
        end
    end
    frames[key]=f; return f
end
function ns.Alert(key,text,r,g,b,duration)
    local p=ns.GetSettings(); if not p or not p.enabled or not p[key] or not frames[key] then return end
    local now=GetTime(); alerts[key]={text=text,start=now,expires=now+(duration or 3),r=r,g=g,b=b}
end
function ns.CombatAlert(which)
    local p=ns.GetSettings(); if not p or not p.combatAlert or ns.preview then return end
    local mode=p.combatAlertMode or "both"
    if (which=="enter" and mode=="leave") or (which=="leave" and mode=="enter") then return end
    local text=which=="leave" and (p.combatLeaveText~="" and p.combatLeaveText or "-Combat") or (p.combatEnterText~="" and p.combatEnterText or "+Combat")
    local r,g,b
    if p.combatClassColor then r,g,b=ClassColor() end
    if not r then r,g,b=Color(which=="leave" and p.combatLeaveColor or p.combatEnterColor,1,1,1) end
    ns.Alert("combatAlert",text,r,g,b,1.85)
end
local function KnownSpell(id)
    local name,_,icon=GetSpellInfo(id); if not name then return end
    if IsSpellKnown then if not IsSpellKnown(id) then return end
    else
        local known=false
        for tab=1,GetNumSpellTabs() do
            local _,_,offset,count=GetSpellTabInfo(tab)
            for i=offset+1,offset+count do if GetSpellName(i,BOOKTYPE_SPELL or "spell")==name then known=true; break end end
        end
        if not known then return end
    end
    return name,icon
end
local function Cooldown(key,id,allowed)
    local p,f=ns.GetSettings(),frames[key]
    local name,icon=KnownSpell(id)
    if not name then f:Hide(); return end
    local start,duration,enabled=GetSpellCooldown(name)
    local remain=math.max(0,(start or 0)+(duration or 0)-GetTime())
    local cooling=enabled~=0 and (duration or 0)>1.5 and remain>0
    f.icon:SetTexture(icon); f.cooldown:SetCooldown(cooling and start or 0,cooling and duration or 0)
    f.text:SetText(cooling and string.format("%.0fs",remain) or "Ready")
    Visible(key,allowed~=false and (cooling or p.showReady))
    return cooling
end
local lastDeathSound=0
local function Deaths(p)
    local observed={}
    local raid,party=GetNumRaidMembers(),GetNumPartyMembers()
    local name,token,count
    for i=1,(raid>0 and raid or party) do
        local unit=(raid>0 and "raid" or "party")..i
        local guid=UnitGUID(unit)
        if guid and not UnitIsUnit(unit,"player") then
            local isDead=UnitIsDeadOrGhost(unit) and not (UnitIsFeignDeath and UnitIsFeignDeath(unit))
            if isDead and dead[guid]==false then name=UnitName(unit) or "Group member"; token=select(2,UnitClass(unit)); count=(count or 0)+1 end
            observed[guid]=isDead and true or false
        end
    end
    dead=observed
    if not count then return end
    local c=token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
    local colored=c and ("|cff"..Hex(c.r,c.g,c.b)..name.."|r") or name
    ns.Alert("deathAlert","|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t "..colored.." |cffff2020DIED!|r",1,1,1,3.15)
    local now=GetTime()
    if raid<=5 or now-lastDeathSound>=3 then lastDeathSound=now; ns.PlaySound(p.deathSound) end
end

-- Approximate target range from native interact distances, range-check items and
-- learned spells without a minimum range, the same buckets LibRangeCheck uses.
local RANGE_ITEMS={
    harm={{5,37727},{8,34368},{10,32321},{15,33069},{20,10645},{25,24268},{30,835},{35,24269},{40,28767},{45,23836},{60,32825},{80,35278}},
    help={{5,37727},{8,34368},{10,32321},{15,1251},{20,21519},{25,31463},{30,1180},{35,18904},{40,34471},{45,32698},{60,32825},{80,35278}},
}
local INTERACT={{3,10},{2,11},{4,28}}
local function RangeSpells()
    if ns.rangeSpells then return ns.rangeSpells end
    local list,seen={}, {}
    if GetSpellName then
        local i=1
        while true do
            local name=GetSpellName(i,BOOKTYPE_SPELL or "spell"); if not name then break end
            local _,_,_,_,_,_,_,minRange,maxRange=GetSpellInfo(name)
            maxRange=tonumber(maxRange)
            if maxRange and maxRange>0 and (tonumber(minRange) or 0)==0 and not seen[maxRange] then seen[maxRange]=true; list[#list+1]={maxRange,name} end
            i=i+1
        end
    end
    ns.rangeSpells=list; return list
end
function ns.TargetRange(unit)
    unit=unit or "target"; if not UnitExists(unit) then return end
    if UnitIsUnit(unit,"player") then return 0,0 end
    local lo,hi=0,nil
    local function Check(range,result)
        if result==nil then return end
        if result==1 or result==true then if not hi or range<hi then hi=range end elseif range>lo then lo=range end
    end
    if CheckInteractDistance then for _,c in ipairs(INTERACT) do Check(c[2],CheckInteractDistance(unit,c[1]) and 1 or 0) end end
    if IsItemInRange then for _,c in ipairs(UnitCanAttack("player",unit) and RANGE_ITEMS.harm or RANGE_ITEMS.help) do Check(c[1],IsItemInRange(c[2],unit)) end end
    if IsSpellInRange then for _,s in ipairs(RangeSpells()) do Check(s[1],IsSpellInRange(s[2],unit)) end end
    if hi and lo>hi then lo=hi end
    return lo,hi
end
local MELEE={WARRIOR=true,ROGUE=true,DEATHKNIGHT=true,PALADIN=true}
local function AttackCutoff()
    if MELEE[class] then return 5 end
    if class=="DRUID" and GetShapeshiftFormID then local form=GetShapeshiftFormID(); if form==1 or form==5 or form==8 then return 5 end end
    return class=="HUNTER" and 35 or 30
end
function ns.TargetOutOfRange()
    if not (UnitExists("target") and UnitCanAttack("player","target") and not UnitIsDead("target")) then return false end
    local lo,hi=ns.TargetRange("target"); if not lo then return false end
    local cutoff=AttackCutoff()
    if hi and hi<=cutoff then return false end
    return lo>=cutoff
end
function ns.FormatRange(lo,hi,format)
    if not lo then return "" end
    if format=="min" then return tostring(lo) end
    if format=="plus" or not hi then return lo.."+" end
    return lo.."-"..hi
end

local function FPS(f,p)
    local r,g,b
    if p.fpsColorMode=="class" then r,g,b=ClassColor() end
    if not r then r,g,b=Color(p.fpsColor,1,1,1) end
    local _,_,home,world=GetNetStats()
    f.text:SetText(math.floor(GetFramerate()+.5).." fps"); f.text:SetTextColor(r,g,b,1)
    local anchor,width=f.text,f.text:GetStringWidth()
    local function Part(show,div,value,label,ms,suffix)
        if not show then div:Hide(); value:Hide(); label:Hide(); return end
        div:ClearAllPoints(); div:SetPoint("LEFT",anchor,"RIGHT",6,0); div:SetVertexColor(r,g,b,.35); div:Show()
        value:ClearAllPoints(); value:SetPoint("LEFT",div,"RIGHT",6,0); value:SetText((ms or 0).." ms"); value:SetTextColor(r,g,b,1); value:Show()
        anchor,width=value,width+13+value:GetStringWidth()
        if p.fpsLabels then
            label:ClearAllPoints(); label:SetPoint("LEFT",value,"RIGHT",3,0); label:SetText(suffix); label:SetTextColor(r,g,b,.6); label:Show()
            anchor,width=label,width+3+label:GetStringWidth()
        else label:Hide() end
    end
    Part(p.fpsWorld,f.div1,f.world,f.worldLabel,world,"(world)")
    Part(p.fpsLocal,f.div2,f.localMs,f.localLabel,home,"(local)")
    ns.Size(f,width+4,20)
end
local function Stats(f,p)
    local crit=math.max(GetCritChance() or 0,GetRangedCritChance() or 0)
    for school=2,7 do crit=math.max(crit,GetSpellCritChance(school) or 0) end
    local function Rating(list) local v=0; if GetCombatRatingBonus then for _,id in ipairs(list) do if id then v=math.max(v,GetCombatRatingBonus(id) or 0) end end end; return v end
    local lines={string.format("|cffffd100Crit|r  %.1f%%",crit),string.format("|cff2ecc71Haste|r  %.1f%%",Rating({CR_HASTE_MELEE,CR_HASTE_RANGED,CR_HASTE_SPELL}))}
    if p.statsExtra then
        local hex=Hex(ClassColor())
        lines[#lines+1]=string.format("|cff%sHit|r  %.1f%%",hex,Rating({CR_HIT_MELEE,CR_HIT_RANGED,CR_HIT_SPELL}))
        lines[#lines+1]=string.format("|cff%sExpertise|r  %d",hex,GetExpertise and (GetExpertise()) or 0)
        lines[#lines+1]=string.format("|cff%sArmor Pen|r  %.1f%%",hex,GetArmorPenetration and GetArmorPenetration() or Rating({CR_ARMOR_PENETRATION}))
    end
    f.text:SetText(table.concat(lines,"\n"))
    local size=tonumber(p.statsTextSize) or 12
    ns.Size(f,size*11,#lines*(size+3))
end
function ns.UpdateDisplays()
    local p=ns.GetSettings(); if not p or not frames.fps then return end
    if not p.enabled then for _,f in pairs(frames) do f:Hide() end; dead={}; return end
    local now,combat=GetTime(),UnitAffectingCombat("player") or InCombatLockdown()
    if p.fps and now>=(ns.fpsNext or 0) then ns.fpsNext=now+math.max(.25,tonumber(p.fpsInterval) or 1); FPS(frames.fps,p) end
    Visible("fps",true)
    if p.stats then Stats(frames.stats,p) end
    Visible("stats",true)
    local mapShown=WorldMapFrame and WorldMapFrame:IsShown()
    if mapShown then ns.mapDirty=true end
    local validCoords=false
    if p.coordinates and not mapShown then
        if ns.mapDirty then SetMapToCurrentZone(); ns.mapDirty=false end
        local x,y=GetPlayerMapPosition("player")
        validCoords=x and y and (x~=0 or y~=0)
        frames.coordinates.text:SetText(validCoords and string.format("%.1f, %.1f",x*100,y*100) or "")
    end
    Visible("coordinates",validCoords)
    local ch=frames.crosshair; local vis=p.crosshairVisibility; local inside=IsInInstance()
    local showCross=vis=="combat" and combat or vis=="instances" and inside or vis=="instances_combat" and inside and combat or vis~="combat" and vis~="instances" and vis~="instances_combat"
    Visible("crosshair",showCross)
    if p.crosshair and ch:IsShown() then
        local r,g,b,a=Color(p.crosshairColor,1,1,1,.75)
        if p.crosshairRange and ns.TargetOutOfRange() then r,g,b,a=Color(p.crosshairRangeColor,1,0,0,1) end
        ch.horizontal:SetVertexColor(r,g,b,a); ch.vertical:SetVertexColor(r,g,b,a)
    end
    local lowest=100
    if p.durability then for slot=1,18 do local current,max=GetInventoryItemDurability(slot); if max and max>0 then lowest=math.min(lowest,current/max*100) end end end
    local dur=frames.durability; dur.text:SetTextColor(Color(p.durabilityColor,1,.27,.27))
    dur.text:SetText(ns.preview and lowest>=p.durabilityThreshold and "Low Durability (Preview)" or string.format("Low Durability (%d%%)",math.floor(lowest)))
    Visible("durability",lowest<p.durabilityThreshold and not combat)
    for _,key in ipairs({"combatAlert","deathAlert"}) do
        local a=alerts[key]; local live=a and now<a.expires
        frames[key].text:SetText(live and a.text or (ns.preview and (key=="combatAlert" and (p.combatEnterText or "+Combat") or "Group death alert") or ""))
        if live then frames[key].text:SetTextColor(a.r or 1,a.g or 1,a.b or 1) end
        Visible(key,live)
    end
    if p.deathAlert then Deaths(p) else dead={} end
    local lockout
    if p.bloodlust then for i=1,40 do
        local name,_,icon,_,_,duration,expiry,_,_,_,id=UnitAura("player",i,"HARMFUL")
        if not name then break end
        if id==57723 or id==57724 then lockout={icon=icon,duration=duration or 0,expiry=expiry or 0}; break end
    end end
    local f=frames.bloodlust
    if lockout then
        f.icon:SetTexture(lockout.icon); f.cooldown:SetCooldown(lockout.expiry-lockout.duration,lockout.duration)
        f.text:SetText(string.format("%.0fs",math.max(0,lockout.expiry-now)))
    else f.icon:SetTexture("Interface\\Icons\\Spell_Nature_BloodLust"); f.cooldown:SetCooldown(0,0); f.text:SetText("Ready") end
    Visible("bloodlust",lockout or p.showReady)
    if p.battleRes and class=="DRUID" then Cooldown("battleRes",20484) else f=frames.battleRes; f:Hide() end
    local moveID=p.movementSpellID>0 and p.movementSpellID or ns.classMovement[class]
    if p.movement and moveID then
        local cooling=Cooldown("movement",moveID,combat or not p.movementCombatOnly)
        if ns.moveCooling and cooling==false then ns.PlaySound(p.movementSound) end
        ns.moveCooling=cooling
    else frames.movement:Hide(); ns.moveCooling=nil end
    local td=frames.targetDistance
    if p.targetDistance then
        local lo,hi=ns.TargetRange("target")
        td.text:SetText(lo and ns.FormatRange(lo,hi,p.targetDistanceFormat) or (ns.preview and ns.FormatRange(30,35,p.targetDistanceFormat) or ""))
        Visible("targetDistance",lo~=nil)
    else td:Hide() end
    frames.zoneText:Hide()
end
local cursor,trail={},{}
local trailClock,trailIndex=0,0
function ns.UpdateCursor(dt)
    local p=ns.GetSettings(); if not p or not cursor.frame then return end
    local c=p.cursor
    local visible=p.enabled and c.enabled and (not c.combatOnly or UnitAffectingCombat("player")) and (not c.instancesOnly or IsInInstance()) and not (IsMouselooking and IsMouselooking())
    if not visible then cursor.frame:Hide(); for _,f in ipairs(trail) do f:Hide(); f.expires=nil end; return end
    local x,y=GetCursorPosition(); local scale=UIParent:GetEffectiveScale(); x,y=x/scale,y/scale
    cursor.frame:ClearAllPoints(); cursor.frame:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y); cursor.frame:Show()
    local ratio
    if c.cast then
        local name,_,_,_,start,finish=UnitCastingInfo("player")
        local channel=false
        if not name then name,_,_,_,start,finish=UnitChannelInfo("player"); channel=true end
        if name and finish and start and finish>start then ratio=(GetTime()*1000-start)/(finish-start); if channel then ratio=1-ratio end end
    end
    if not ratio and c.gcd then local start,duration=GetSpellCooldown(61304); if duration and duration>0 and duration<=1.7 then ratio=(GetTime()-start)/duration end end
    for i,t in ipairs(cursor.pips) do if ratio and i<=math.floor(math.max(0,math.min(1,ratio))*32) then t:Show() else t:Hide() end end
    trailClock=trailClock+dt
    if c.trail and trailClock>=.045 then
        trailClock=0; trailIndex=trailIndex%#trail+1; local f=trail[trailIndex]
        f:ClearAllPoints(); f:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y); f.expires=GetTime()+.25
    end
    local opacity=math.max(.1,math.min(1,(tonumber(c.opacity) or 100)/100))
    for _,f in ipairs(trail) do
        if c.trail and f.expires and f.expires>GetTime() then f:SetAlpha((f.expires-GetTime())/.25*.45*opacity); f:Show() else f:Hide() end
    end
end
-- Wrath anchors ZoneTextFrame and SubZoneTextFrame at UIParent BOTTOM +512, which
-- lands mid-screen once the UI scale makes UIParent taller than ~1024. Both are
-- pinned to the Zone Text mover; the sub-zone strings hang off ZoneTextString.
local ZONE_FRAMES={"ZoneTextFrame","SubZoneTextFrame"}
local zoneSaved,zoneHooked,zoneBusy={},false,false
local function ZoneAnchor() local p=ns.GetSettings(); return p and p.enabled and p.zoneText and frames.zoneText end
local function ZoneDrifted(anchor)
    for _,name in ipairs(ZONE_FRAMES) do local z=_G[name]
        if z then
            local point,rel,relPoint,x,y=z:GetPoint(1)
            if z:GetNumPoints()~=1 or point~="CENTER" or rel~=anchor or relPoint~="CENTER" or x~=0 or y~=0 then return true end
        end
    end
end
local function ZoneReassert()
    if zoneBusy then return end
    local anchor=ZoneAnchor(); if anchor and ZoneDrifted(anchor) then ns.ApplyZoneText() end
end
function ns.ApplyZoneText()
    local anchor=ZoneAnchor(); zoneBusy=true
    for _,name in ipairs(ZONE_FRAMES) do local z=_G[name]
        if z and anchor then
            if not zoneSaved[z] then local pts={}; for i=1,z:GetNumPoints() do pts[i]={z:GetPoint(i)} end; zoneSaved[z]=pts end
            z:ClearAllPoints(); z:SetPoint("CENTER",anchor,"CENTER",0,0)
        elseif z and zoneSaved[z] then
            local pts=zoneSaved[z]; zoneSaved[z]=nil; z:ClearAllPoints()
            if #pts==0 then pts={{"BOTTOM",UIParent,"BOTTOM",0,512}} end
            for _,pt in ipairs(pts) do z:SetPoint(unpack(pt)) end
        end
    end
    zoneBusy=false
    if zoneHooked or not hooksecurefunc then return end
    zoneHooked=true
    for _,name in ipairs(ZONE_FRAMES) do local z=_G[name]; if z then hooksecurefunc(z,"SetPoint",ZoneReassert); hooksecurefunc(z,"SetAllPoints",ZoneReassert) end end
    for _,fn in ipairs({"SetZoneText","UIParent_ManageFramePositions"}) do if type(_G[fn])=="function" then hooksecurefunc(fn,ZoneReassert) end end
end
-- Zone Text outline: "module" keeps Blizzard's own zone fonts; restoring re-applies the
-- original font object so its native outline and shadow come back.
local ZONE_STRINGS={"ZoneTextString","SubZoneTextString","PVPInfoTextString","PVPArenaTextString"}
local zoneFonts={}
function ns.ApplyZoneOutline()
    local p=ns.GetSettings(); local mode=p and p.enabled and p.zoneTextOutline
    if mode=="module" or not E.ApplyTextOutline then mode=nil end
    for _,name in ipairs(ZONE_STRINGS) do local fs=_G[name]
        if fs and fs.GetFont then
            if mode then
                if not zoneFonts[fs] then local path,size,flags=fs:GetFont(); zoneFonts[fs]={obj=fs.GetFontObject and fs:GetFontObject(),path=path,size=size,flags=flags} end
                local n=zoneFonts[fs]; E.ApplyTextOutline(fs,n.path,n.size,mode,"extras")
            elseif zoneFonts[fs] then
                local n,r,g,b,a=zoneFonts[fs],fs:GetTextColor(); zoneFonts[fs]=nil; fs._euiTextOutline=nil
                if n.obj then fs:SetFontObject(n.obj) end
                fs:SetFont(n.path,n.size,n.flags or "")
                if r then fs:SetTextColor(r,g,b,a) end
            end
        end
    end
end
local function Px(v) local PP=E.PP; return PP and PP.FromPixels and PP.FromPixels(v) or v end
function ns.ApplyDisplays()
    local p=ns.GetSettings()
    p.positions.zoneText=nil; p.zoneTextPosV1=nil
    for _,c in ipairs(layout) do
        local f=frames[c[1]] or NewFrame(c); local pos=c[8] and p.positions[c[1]]
        local x,y=c[5],c[6]; if c[11] then x,y=Px(x),Px(y) end
        f:ClearAllPoints(); if pos then f:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y) else f:SetPoint("CENTER",UIParent,"CENTER",x,y) end
        if f.text then
            local size=c[7] and p[c[7]] or (c[1]=="zoneText" and 24 or nil); ns.Font(f.text,size)
            if c[1]=="fps" then for _,fs in ipairs({f.world,f.localMs}) do ns.Font(fs,size) end; for _,fs in ipairs({f.worldLabel,f.localLabel}) do ns.Font(fs,(tonumber(size) or 12)-2) end end
            if c[1]=="combatAlert" or c[1]=="deathAlert" or c[1]=="durability" or c[1]=="targetDistance" then local s=tonumber(size) or 22; ns.Size(f,math.max(c[3],s*7),s+14) end
        end
    end
    ns.ApplyZoneText(); ns.ApplyZoneOutline()
    local ch,len,thick=frames.crosshair,math.max(4,tonumber(p.crosshairSize) or 40),math.max(1,tonumber(p.crosshairThickness) or 2)
    ns.Size(ch.horizontal,len,thick); ns.Size(ch.vertical,thick,len); ns.Size(ch,len,len)
    local border=math.max(0,tonumber(p.crosshairBorder) or 0)
    for _,t in ipairs({ch.hBorder,ch.vBorder}) do if border>0 then t:SetVertexColor(Color(p.crosshairBorderColor,0,0,0,1)); t:Show() else t:Hide() end end
    ns.Size(ch.hBorder,len+border*2,thick+border*2); ns.Size(ch.vBorder,thick+border*2,len+border*2)
    local icon=math.max(16,math.min(64,tonumber(p.trackerIconSize) or 30))
    for _,key in ipairs({"bloodlust","battleRes","movement"}) do
        local f=frames[key]; ns.Size(f.icon,icon,icon); ns.Size(f,icon+70,icon+2); f.text:ClearAllPoints(); f.text:SetPoint("LEFT",f,"LEFT",icon+4,0)
    end
    ns.fpsNext=0
    if not cursor.frame then
        cursor.frame=CreateFrame("Frame",nil,UIParent); cursor.frame:SetFrameStrata("TOOLTIP"); cursor.frame:EnableMouse(false)
        cursor.ring=cursor.frame:CreateTexture(nil,"ARTWORK"); cursor.ring:SetAllPoints(cursor.frame); cursor.pips={}
        cursor.reticle=cursor.frame:CreateTexture(nil,"OVERLAY"); cursor.reticle:SetTexture(white); ns.Size(cursor.reticle,4,4); cursor.reticle:SetPoint("CENTER",cursor.frame,"CENTER",0,0)
        for i=1,32 do local t=cursor.frame:CreateTexture(nil,"OVERLAY"); t:SetTexture(white); ns.Size(t,2,2); cursor.pips[i]=t end
        for i=1,6 do local f=CreateFrame("Frame",nil,UIParent); f:SetFrameStrata("TOOLTIP"); f:EnableMouse(false)
            f.texture=f:CreateTexture(nil,"ARTWORK"); f.texture:SetAllPoints(f); f.texture:SetTexture("Interface\\AddOns\\EllesmereUIQoL\\Media\\Textures_335\\circle_cursor.tga"); f:Hide(); trail[i]=f
        end
    end
    ns.cursor=cursor; ns.trail=trail
    local c=p.cursor; local size=math.max(12,math.min(100,tonumber(c.size) or 36)); ns.Size(cursor.frame,size,size)
    local textures={ring_thin=true,ring_light=true,ring_normal=true,ring_heavy=true,ring_thick=true}
    cursor.ring:SetTexture("Interface\\AddOns\\EllesmereUIQoL\\Media\\Textures_335\\"..(textures[c.texture] and c.texture or "ring_normal")..".tga")
    local r,g,b
    if c.classColor then r,g,b=ClassColor() end
    if not r then r,g,b=Color(c.color,.05,.82,.62) end
    local opacity=math.max(.1,math.min(1,(tonumber(c.opacity) or 100)/100))
    cursor.ring:SetVertexColor(r,g,b,opacity); cursor.reticle:SetVertexColor(r,g,b,opacity)
    if c.reticle then cursor.reticle:Show() else cursor.reticle:Hide() end
    for i,t in ipairs(cursor.pips) do local angle=(i-1)*math.pi/16; t:ClearAllPoints(); t:SetPoint("CENTER",cursor.frame,"CENTER",math.sin(angle)*size/2,math.cos(angle)*size/2); t:SetVertexColor(1,.8,.2,1) end
    for _,f in ipairs(trail) do ns.Size(f,size*.35,size*.35); f.texture:SetVertexColor(r,g,b,1) end
    ns.mapDirty=true; ns.UpdateDisplays(); ns.UpdateCursor(0)
end
function ns.RegisterElementSettings()
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    for _,c in ipairs(layout) do if c[8] then E._ELEMENT_SETTINGS_MAP[c[8]]={module=ADDON_NAME,page="Displays",sectionName=c[9],highlightText=c[10]} end end
    E._ELEMENT_SETTINGS_MAP.EUI_RaidTools={module=ADDON_NAME,page="Raid Tools",sectionName="RAID TOOLS",highlightText="Show Raid Tools"}
end
function ns.RegisterMovers()
    ns.RegisterElementSettings()
    if not E.RegisterUnlockElements or not E.MakeUnlockElement then return end
    local elements={}
    for i,c in ipairs(layout) do local key=c[1]
        if c[8] then elements[#elements+1]=E.MakeUnlockElement({key=c[8],label=c[2],group="Quality of Life",order=900+i,noResize=true,noAnchorTo=true,
            getFrame=function() return frames[key] end,getSize=function() local f=frames[key]; return f:GetWidth(),f:GetHeight() end,
            isHidden=function() local f=frames[key]; return not f or not f:IsShown() end,
            savePos=function(_,point,relPoint,x,y) local p=ns.GetSettings(); if p then p.positions[key]={point=point,relPoint=relPoint,x=x,y=y} end end,
            loadPos=function() local p=ns.GetSettings(); return p and p.positions[key] end,
            clearPos=function() local p=ns.GetSettings(); if p then p.positions[key]=nil; ns.Apply() end end,applyPos=ns.Apply}) end
    end
    if ns.raidFrame then
        elements[#elements+1]=E.MakeUnlockElement({key="EUI_RaidTools",label="Raid Tools",group="Quality of Life",order=920,noResize=true,noAnchorTo=true,
            getFrame=function() return ns.raidFrame end,getSize=function() return ns.raidFrame:GetWidth(),ns.raidFrame:GetHeight() end,
            isHidden=function() return not ns.raidFrame:IsShown() end,
            savePos=function(_,point,relPoint,x,y) local p=ns.GetSettings(); if p then p.positions.raidTools={point=point,relPoint=relPoint,x=x,y=y} end end,
            loadPos=function() local p=ns.GetSettings(); return p and p.positions.raidTools end,
            clearPos=function() local p=ns.GetSettings(); if p then p.positions.raidTools=nil; ns.Apply() end end,applyPos=ns.Apply})
    end
    E:RegisterUnlockElements(elements,ADDON_NAME)
end
