local ADDON_NAME,ns=...
local E=EllesmereUI
if not ns.addon then return end
local white="Interface\\Buttons\\WHITE8X8"
local frames,dead,alerts={}, {}, {}
ns.frames=frames
local layout={
    {"fps","FPS and Latency",220,20,0,-260,"fpsTextSize","EUI_FPS"},
    {"stats","Secondary Stats",260,20,0,-285,"statsTextSize","EUI_SecondaryStats"},
    {"coordinates","Map Coordinates",180,20,0,-310,"mapCoordsTextSize","EUI_MapCoords"},
    {"crosshair","Character Crosshair",20,20,0,0,nil,"EUI_Crosshair"},
    {"durability","Durability Warning",300,30,0,150,"durWarnTextSize","EUI_DurabilityWarning"},
    {"combatAlert","Combat Alert",300,32,0,120,"combatAlertTextSize","EUI_CombatAlert"},
    {"deathAlert","Group Death Alert",420,36,0,190,"groupDeathTextSize","EUI_GroupDeathAlert"},
    {"bloodlust","Sated / Exhaustion",120,32,180,-150,"trackerTextSize","EUI_Bloodlust"},
    {"battleRes","Rebirth Cooldown",120,32,180,-190,"trackerTextSize","EUI_BattleRes"},
    {"movement","Movement Cooldown",120,32,180,-230,"trackerTextSize","EUI_MovementAlert"},
}
ns.displayLayout=layout
local _,class=UnitClass("player")
ns.classMovement={DRUID=1850,HUNTER=781,MAGE=1953,ROGUE=2983,WARRIOR=100}
local function Visible(key,show)
    local p=ns.GetSettings(); local f=frames[key]
    if f then if p.enabled and p[key] and (show or ns.preview) then f:Show() else f:Hide() end end
end
local function NewFrame(c)
    local key=c[1]; local f=CreateFrame("Frame","EUI335QoL_"..key,UIParent)
    ns.Size(f,c[3],c[4]); f:SetFrameStrata("MEDIUM"); f:EnableMouse(false)
    if key=="crosshair" then
        f.horizontal=f:CreateTexture(nil,"ARTWORK"); f.vertical=f:CreateTexture(nil,"ARTWORK")
        for _,t in ipairs({f.horizontal,f.vertical}) do t:SetTexture(white); t:SetVertexColor(.1,.85,.65,1); t:SetPoint("CENTER",f,"CENTER",0,0) end
    else
        f.text=f:CreateFontString(nil,"OVERLAY"); ns.Font(f.text,12); f.text:SetPoint("CENTER",f,"CENTER",0,0)
        if key=="bloodlust" or key=="battleRes" or key=="movement" then
            f.icon=f:CreateTexture(nil,"ARTWORK"); ns.Size(f.icon,30,30); f.icon:SetPoint("LEFT",f,"LEFT",0,0); f.icon:SetTexCoord(.08,.92,.08,.92)
            f.cooldown=CreateFrame("Cooldown",nil,f,"CooldownFrameTemplate"); f.cooldown:SetAllPoints(f.icon)
            f.text:ClearAllPoints(); f.text:SetPoint("LEFT",f,"LEFT",34,0)
        end
    end
    frames[key]=f; return f
end
function ns.Alert(key,text,r,g,b)
    local p=ns.GetSettings(); if not p or not p.enabled or not p[key] or not frames[key] then return end
    alerts[key]={text=text,expires=GetTime()+3,r=r,g=g,b=b}
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
local function Cooldown(key,id)
    local p,f=ns.GetSettings(),frames[key]
    local name,icon=KnownSpell(id)
    if not name then f:Hide(); return end
    local start,duration,enabled=GetSpellCooldown(name)
    local remain=math.max(0,(start or 0)+(duration or 0)-GetTime())
    local cooling=enabled~=0 and (duration or 0)>1.5 and remain>0
    f.icon:SetTexture(icon); f.cooldown:SetCooldown(cooling and start or 0,cooling and duration or 0)
    f.text:SetText(cooling and string.format("%.0fs",remain) or "Ready")
    Visible(key,cooling or p.showReady)
end
local function Deaths()
    local observed={}
    local raid,party=GetNumRaidMembers(),GetNumPartyMembers()
    for i=1,(raid>0 and raid or party) do
        local unit=(raid>0 and "raid" or "party")..i
        local guid=UnitGUID(unit)
        if guid and not UnitIsUnit(unit,"player") then
            local isDead=UnitIsDeadOrGhost(unit) and not (UnitIsFeignDeath and UnitIsFeignDeath(unit))
            if isDead and dead[guid]==false then ns.Alert("deathAlert",(UnitName(unit) or "Group member").." died",1,.3,.3) end
            observed[guid]=isDead and true or false
        end
    end
    dead=observed
end
function ns.UpdateDisplays()
    local p=ns.GetSettings(); if not p or not frames.fps then return end
    if not p.enabled then for _,f in pairs(frames) do f:Hide() end; dead={}; return end
    if p.fps then local _,_,home,world=GetNetStats(); frames.fps.text:SetText(string.format("%.0f FPS  |  %d ms",GetFramerate(),math.max(home or 0,world or 0))) end
    Visible("fps",true)
    if p.stats then
        local crit=math.max(GetCritChance() or 0,GetRangedCritChance() or 0)
        for school=2,7 do crit=math.max(crit,GetSpellCritChance(school) or 0) end
        local haste=0
        if GetCombatRatingBonus then for _,rating in ipairs({CR_HASTE_MELEE,CR_HASTE_RANGED,CR_HASTE_SPELL}) do haste=math.max(haste,GetCombatRatingBonus(rating) or 0) end end
        frames.stats.text:SetText(string.format("Crit %.1f%%  |  Haste %.1f%%",crit,haste))
    end
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
    Visible("crosshair",true)
    local lowest=100
    if p.durability then for slot=1,18 do local current,max=GetInventoryItemDurability(slot); if max and max>0 then lowest=math.min(lowest,current/max*100) end end end
    frames.durability.text:SetText(string.format("Durability: %.0f%%",lowest)); frames.durability.text:SetTextColor(1,.3,.2)
    Visible("durability",lowest<=p.durabilityThreshold)
    for _,key in ipairs({"combatAlert","deathAlert"}) do
        local a=alerts[key]; local live=a and GetTime()<a.expires
        frames[key].text:SetText(live and a.text or (ns.preview and (key=="combatAlert" and "Combat" or "Group death alert") or ""))
        if live then frames[key].text:SetTextColor(a.r or 1,a.g or 1,a.b or 1) end
        Visible(key,live)
    end
    if p.deathAlert then Deaths() else dead={} end
    local lockout
    if p.bloodlust then for i=1,40 do
        local name,_,icon,_,_,duration,expiry,_,_,_,id=UnitAura("player",i,"HARMFUL")
        if not name then break end
        if id==57723 or id==57724 then lockout={icon=icon,duration=duration or 0,expiry=expiry or 0}; break end
    end end
    local f=frames.bloodlust
    if lockout then
        f.icon:SetTexture(lockout.icon); f.cooldown:SetCooldown(lockout.expiry-lockout.duration,lockout.duration)
        f.text:SetText(string.format("%.0fs",math.max(0,lockout.expiry-GetTime())))
    else f.icon:SetTexture("Interface\\Icons\\Spell_Nature_BloodLust"); f.cooldown:SetCooldown(0,0); f.text:SetText("Ready") end
    Visible("bloodlust",lockout or p.showReady)
    if p.battleRes and class=="DRUID" then Cooldown("battleRes",20484) else f=frames.battleRes; f:Hide() end
    local moveID=p.movementSpellID>0 and p.movementSpellID or ns.classMovement[class]
    if p.movement and moveID then Cooldown("movement",moveID) else frames.movement:Hide() end
end
local cursor,trail={},{}
local trailClock,trailIndex=0,0
function ns.UpdateCursor(dt)
    local p=ns.GetSettings(); if not p or not cursor.frame then return end
    local c=p.cursor
    local visible=p.enabled and c.enabled and (not c.combatOnly or UnitAffectingCombat("player")) and not (IsMouselooking and IsMouselooking())
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
    for _,f in ipairs(trail) do
        if c.trail and f.expires and f.expires>GetTime() then f:SetAlpha((f.expires-GetTime())/.25*.45); f:Show() else f:Hide() end
    end
end
function ns.ApplyDisplays()
    local p=ns.GetSettings()
    for _,c in ipairs(layout) do
        local f=frames[c[1]] or NewFrame(c); local pos=p.positions[c[1]]
        f:ClearAllPoints(); if pos then f:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y) else f:SetPoint("CENTER",UIParent,"CENTER",c[5],c[6]) end
        if f.text then ns.Font(f.text,p[c[7]]) else ns.Size(f.horizontal,p.crosshairSize,2); ns.Size(f.vertical,2,p.crosshairSize); ns.Size(f,p.crosshairSize,p.crosshairSize) end
    end
    if not cursor.frame then
        cursor.frame=CreateFrame("Frame",nil,UIParent); cursor.frame:SetFrameStrata("TOOLTIP"); cursor.frame:EnableMouse(false)
        cursor.ring=cursor.frame:CreateTexture(nil,"ARTWORK"); cursor.ring:SetAllPoints(cursor.frame); cursor.pips={}
        for i=1,32 do local t=cursor.frame:CreateTexture(nil,"OVERLAY"); t:SetTexture(white); ns.Size(t,2,2); cursor.pips[i]=t end
        for i=1,6 do local f=CreateFrame("Frame",nil,UIParent); f:SetFrameStrata("TOOLTIP"); f:EnableMouse(false)
            f.texture=f:CreateTexture(nil,"ARTWORK"); f.texture:SetAllPoints(f); f.texture:SetTexture("Interface\\AddOns\\EllesmereUIQoL\\Media\\Textures_335\\circle_cursor.tga"); f:Hide(); trail[i]=f
        end
    end
    ns.cursor=cursor; ns.trail=trail
    local c=p.cursor; local size=math.max(12,math.min(100,tonumber(c.size) or 36)); ns.Size(cursor.frame,size,size)
    local textures={ring_thin=true,ring_light=true,ring_normal=true,ring_heavy=true,ring_thick=true}
    cursor.ring:SetTexture("Interface\\AddOns\\EllesmereUIQoL\\Media\\Textures_335\\"..(textures[c.texture] and c.texture or "ring_normal")..".tga")
    local color=c.classColor and RAID_CLASS_COLORS[class] or {r=.05,g=.82,b=.62}
    cursor.ring:SetVertexColor(color.r,color.g,color.b,1)
    for i,t in ipairs(cursor.pips) do local angle=(i-1)*math.pi/16; t:ClearAllPoints(); t:SetPoint("CENTER",cursor.frame,"CENTER",math.sin(angle)*size/2,math.cos(angle)*size/2); t:SetVertexColor(1,.8,.2,1) end
    for _,f in ipairs(trail) do ns.Size(f,size*.35,size*.35); f.texture:SetVertexColor(color.r,color.g,color.b,1) end
    ns.mapDirty=true; ns.UpdateDisplays(); ns.UpdateCursor(0)
end
function ns.RegisterMovers()
    if not E.RegisterUnlockElements or not E.MakeUnlockElement then return end
    local elements={}
    for i,c in ipairs(layout) do local key=c[1]
        elements[#elements+1]=E.MakeUnlockElement({key=c[8],label=c[2],group="Quality of Life",order=900+i,noResize=true,noAnchorTo=true,
            getFrame=function() return frames[key] end,getSize=function() local f=frames[key]; return f:GetWidth(),f:GetHeight() end,
            isHidden=function() local f=frames[key]; return not f or not f:IsShown() end,
            savePos=function(_,point,relPoint,x,y) local p=ns.GetSettings(); if p then p.positions[key]={point=point,relPoint=relPoint,x=x,y=y} end end,
            loadPos=function() local p=ns.GetSettings(); return p and p.positions[key] end,
            clearPos=function() local p=ns.GetSettings(); if p then p.positions[key]=nil; ns.Apply() end end,applyPos=ns.Apply})
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
