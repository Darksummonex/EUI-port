local ADDON_NAME,ns=...
local E=EllesmereUI
if not ns.addon then return end
local white="Interface\\Buttons\\WHITE8X8"
local MEDIA="Interface\\AddOns\\EllesmereUIArena\\Media\\Textures_335\\"
local textures,names,order={flat=white,blizzard="Interface\\TargetingFrame\\UI-StatusBar"},{flat="Flat",blizzard="Blizzard"},{"flat","blizzard"}
for _,key in ipairs({"atrocity","beautiful","divide","fade","fade-right","glass","gradient-bt","gradient-lr","gradient-rl","gradient-tb","matte","plating","sheer","thin-line-bottom","thin-line-top"}) do
    textures[key]=MEDIA..key..".tga"; names[key]=key:gsub("-"," "):gsub("^%l",string.upper); order[#order+1]=key
end
ns.textures,ns.textureNames,ns.textureOrder=textures,names,order
local MODERN_CLASSES="Interface\\AddOns\\EllesmereUI\\media\\icons_335\\class-modern.tga"
local BLIZZ_CLASSES="Interface\\WorldStateFrame\\Icons-Classes"
local TRINKET_ICONS={Alliance="Interface\\Icons\\INV_Jewelry_TrinketPVP_01",Horde="Interface\\Icons\\INV_Jewelry_TrinketPVP_02"}
local GAP,CAST_GAP=2,3
ns.PREVIEW={
    {name="Frostbite",class="MAGE",hp=82,power=64,powerType="MANA",cast={name="Polymorph",icon="Interface\\Icons\\Spell_Nature_Polymorph"}},
    {name="Shadowstep",class="ROGUE",hp=55,power=90,powerType="ENERGY",trinket=35,cc={icon="Interface\\Icons\\Ability_Rogue_KidneyShot",duration=6}},
    {name="Lightwell",class="PRIEST",hp=100,power=40,powerType="MANA"},
    {name="Bloodfang",class="DEATHKNIGHT",hp=33,power=80,powerType="RUNIC_POWER",cast={name="Death Coil",icon="Interface\\Icons\\Spell_Shadow_DeathCoil",notInterruptible=true}},
    {name="Barkskin",class="DRUID",hp=67,power=70,powerType="MANA",trinket=90}}
local function Texture(key) return textures[key] or white end
local function Short(v)
    v=tonumber(v) or 0
    if v>=1e6 then return string.format("%.1fm",v/1e6) elseif v>=1e3 then return string.format("%.1fk",v/1e3) end
    return tostring(math.floor(v+.5))
end
function ns.HealthText(mode,hp,max)
    local pct=math.floor(hp/math.max(max,1)*100+.5)
    if mode=="percent" then return pct.."%" elseif mode=="current" then return Short(hp)
    elseif mode=="both" then return Short(hp).." | "..pct.."%" end
    return ""
end
function ns.Timer(remaining)
    if not remaining or remaining<=0 then return "" end
    if remaining>=60 then return math.ceil(remaining/60).."m" end
    if remaining<10 then return string.format("%.1f",remaining) end
    return tostring(math.floor(remaining))
end
local function NewIcon(parent)
    local f=CreateFrame("Frame",nil,parent)
    f.bg=f:CreateTexture(nil,"BACKGROUND"); f.bg:SetTexture(white); f.bg:SetVertexColor(0,0,0,1); f.bg:SetAllPoints(f)
    f.icon=f:CreateTexture(nil,"ARTWORK")
    f.cd=CreateFrame("Cooldown",nil,f); f.cd:SetAllPoints(f.icon); f.cd:Hide()
    f.textLayer=CreateFrame("Frame",nil,f); f.textLayer:SetAllPoints(f)
    f.timer=f.textLayer:CreateFontString(nil,"OVERLAY"); ns.Font(f.timer,12); f.timer:SetPoint("CENTER",f,"CENTER",0,0)
    return f
end
local function NewBar(parent)
    local bar=CreateFrame("StatusBar",nil,parent)
    bar.bg=bar:CreateTexture(nil,"BACKGROUND"); bar.bg:SetAllPoints(bar)
    return bar
end
function ns.Build(f)
    f.border=f:CreateTexture(nil,"BACKGROUND"); f.border:SetTexture(white)
    f.health=NewBar(f); f.power=NewBar(f)
    f.textLayer=CreateFrame("Frame",nil,f.health); f.textLayer:SetAllPoints(f.health)
    f.name=f.textLayer:CreateFontString(nil,"OVERLAY"); ns.Font(f.name,12); f.name:SetJustifyH("LEFT")
    f.hp=f.textLayer:CreateFontString(nil,"OVERLAY"); ns.Font(f.hp,11); f.hp:SetJustifyH("RIGHT")
    f.classIcon=NewIcon(f); f.trinket=NewIcon(f)
    local c=NewBar(f); f.cast=c
    c.border=c:CreateTexture(nil,"BACKGROUND",nil,-1); c.border:SetTexture(white); c.border:SetVertexColor(0,0,0,1)
    c.icon=c:CreateTexture(nil,"ARTWORK"); c.icon:SetTexCoord(.08,.92,.08,.92)
    c.text=c:CreateFontString(nil,"OVERLAY"); ns.Font(c.text,10); c.text:SetJustifyH("LEFT")
    c.time=c:CreateFontString(nil,"OVERLAY"); ns.Font(c.time,10); c.time:SetJustifyH("RIGHT")
    c:Hide()
    return f
end
local function CreateHolder()
    local h=CreateFrame("Frame","EllesmereUIArenaHolder",UIParent)
    h:SetFrameStrata("LOW"); ns.holder=h
    for i=1,ns.MAX do
        local b=CreateFrame("Button","EllesmereUIArenaFrame"..i,h,"SecureUnitButtonTemplate")
        b.unit,b.index="arena"..i,i
        b:SetAttribute("unit",b.unit); b:SetAttribute("type1","target"); b:SetAttribute("type2","focus")
        b:RegisterForClicks("AnyUp")
        b:SetScript("OnEnter",function(self) if UnitFrame_OnEnter and UnitExists(self.unit) then UnitFrame_OnEnter(self) end end)
        b:SetScript("OnLeave",function(self) if UnitFrame_OnLeave then UnitFrame_OnLeave(self) end end)
        ns.Build(b); b:Hide(); ns.frames[i]=b
        local pv=CreateFrame("Frame",nil,h); pv.unit,pv.index="arena"..i,i
        ns.Build(pv); pv:Hide(); ns.previews[i]=pv
    end
end
-- Icons sit outside the bars; when both share a side the trinket is outermost.
local function Geometry(p)
    local left,right={},{}
    if p.classIcon then local t=p.iconSide=="RIGHT" and right or left; t[#t+1]="classIcon" end
    if p.trinket then local t=p.trinketSide=="LEFT" and left or right; t[#t+1]="trinket" end
    local size=p.height
    local barsX=#left*(size+GAP)
    return left,right,barsX,p.width+(#left+#right)*(size+GAP)
end
local function ApplyLayout(f,p)
    local left,right,barsX,blockW=Geometry(p)
    local w,h,b=p.width,p.height,p.borderSize or 1
    local powerH=p.showPower and math.min(p.powerHeight,h-4) or 0
    local healthH=h-(powerH>0 and powerH+1 or 0)
    f:SetWidth(blockW); f:SetHeight(h)
    f.border:ClearAllPoints()
    f.border:SetPoint("TOPLEFT",f,"TOPLEFT",barsX-b,b); f.border:SetPoint("BOTTOMRIGHT",f,"TOPLEFT",barsX+w+b,-h-b)
    if b<=0 then f.border:Hide() else f.border:Show() end
    local tex=Texture(p.texture)
    f.health:ClearAllPoints(); f.health:SetPoint("TOPLEFT",f,"TOPLEFT",barsX,0); f.health:SetWidth(w); f.health:SetHeight(healthH)
    f.health:SetStatusBarTexture(tex); f.health.bg:SetTexture(tex)
    f.power:ClearAllPoints(); f.power:SetPoint("TOPLEFT",f.health,"BOTTOMLEFT",0,-1); f.power:SetWidth(w); f.power:SetHeight(math.max(powerH,1))
    f.power:SetStatusBarTexture(tex); f.power.bg:SetTexture(tex)
    if powerH>0 then f.power:Show() else f.power:Hide() end
    ns.Font(f.name,p.nameSize); ns.Font(f.hp,p.healthTextSize)
    f.name:ClearAllPoints(); f.name:SetPoint("LEFT",f.health,"LEFT",4,0); f.name:SetPoint("RIGHT",f.hp,"LEFT",-4,0)
    f.hp:ClearAllPoints(); f.hp:SetPoint("RIGHT",f.health,"RIGHT",-4,0)
    f.classIcon:Hide(); f.trinket:Hide()
    for i,key in ipairs(left) do local icon=f[key]; icon:ClearAllPoints(); icon:SetPoint("TOPLEFT",f,"TOPLEFT",barsX-i*(h+GAP),0); icon:SetWidth(h); icon:SetHeight(h); icon:Show() end
    for i,key in ipairs(right) do local icon=f[key]; icon:ClearAllPoints(); icon:SetPoint("TOPLEFT",f,"TOPLEFT",barsX+w+GAP+(i-1)*(h+GAP),0); icon:SetWidth(h); icon:SetHeight(h); icon:Show() end
    for _,icon in ipairs({f.classIcon,f.trinket}) do
        icon.icon:ClearAllPoints(); icon.icon:SetPoint("TOPLEFT",icon,"TOPLEFT",b,-b); icon.icon:SetPoint("BOTTOMRIGHT",icon,"BOTTOMRIGHT",-b,b)
        ns.Font(icon.timer,p.timerSize)
        if p.timers then icon.timer:Show() else icon.timer:Hide() end
    end
    local c,ch=f.cast,p.castBarHeight
    local iconW=p.castIcon and ch+GAP or 0
    c:ClearAllPoints(); c:SetPoint("TOPLEFT",f,"TOPLEFT",barsX+iconW,-h-CAST_GAP-b); c:SetWidth(math.max(w-iconW,10)); c:SetHeight(ch)
    c:SetStatusBarTexture(tex); c.bg:SetTexture(tex); c.bg:SetVertexColor(.1,.1,.1,.8)
    c.border:ClearAllPoints(); c.border:SetPoint("TOPLEFT",c,"TOPLEFT",-iconW-b,b); c.border:SetPoint("BOTTOMRIGHT",c,"BOTTOMRIGHT",b,-b)
    c.icon:ClearAllPoints(); c.icon:SetPoint("TOPRIGHT",c,"TOPLEFT",-GAP,0); c.icon:SetWidth(ch); c.icon:SetHeight(ch)
    if p.castIcon then c.icon:Show() else c.icon:Hide() end
    ns.Font(c.text,p.castTextSize); ns.Font(c.time,p.castTextSize)
    c.text:ClearAllPoints(); c.text:SetPoint("LEFT",c,"LEFT",3,0); c.text:SetPoint("RIGHT",c.time,"LEFT",-3,0)
    c.time:ClearAllPoints(); c.time:SetPoint("RIGHT",c,"RIGHT",-3,0)
    return blockW
end
local function Stride(p) return p.height+(p.castBar and p.castBarHeight+CAST_GAP+2*(p.borderSize or 1) or 0)+p.spacing end
local function Place(f,i,p)
    local y=(i-1)*Stride(p)
    f:ClearAllPoints()
    if p.growth=="UP" then f:SetPoint("BOTTOMLEFT",ns.holder,"BOTTOMLEFT",0,y) else f:SetPoint("TOPLEFT",ns.holder,"TOPLEFT",0,-y) end
end
function ns.Layout(p)
    if not ns.holder then CreateHolder() end
    local h=ns.holder
    local pos=p.position
    h:ClearAllPoints()
    if pos and pos.point then h:SetPoint(pos.point,UIParent,pos.relPoint or pos.point,pos.x or 0,pos.y or 0)
    else h:SetPoint("RIGHT",UIParent,"RIGHT",-260,60) end
    local blockW
    for i=1,ns.MAX do blockW=ApplyLayout(ns.frames[i],p); ApplyLayout(ns.previews[i],p); Place(ns.frames[i],i,p); Place(ns.previews[i],i,p) end
    h:SetWidth(blockW); h:SetHeight(math.max(ns.MAX*Stride(p)-p.spacing,1))
    local arena,preview=p.enabled and ns.InArena(),p.enabled and ns.WantPreview()
    local size=arena and ns.TeamSize() or 0
    if arena or preview then h:Show() else h:Hide() end
    for i,f in ipairs(ns.frames) do
        if arena and (i<=size or f.everSeen) then f:Show(); ns.RefreshFrame(f) else f:Hide(); f.cast:Hide(); f.cast.active=nil end
    end
    if preview then ns.ShowPreviews(p) else ns.HidePreviews() end
end
function ns.ShowPreviews(p)
    local now=GetTime()
    for i,pv in ipairs(ns.previews) do
        if i<=(p.previewCount or 3) then
            local d=ns.PREVIEW[i]; pv.fake=d
            pv.class,pv.unitName=d.class,d.name
            if d.trinket then pv.fakeTrinket=now-d.trinket end
            if d.cc then pv.fakeCC=now end
            pv:Show(); ns.RefreshFrame(pv)
        else pv:Hide() end
    end
end
function ns.HidePreviews()
    for _,pv in ipairs(ns.previews) do pv:Hide(); pv.cast:Hide(); pv.cast.active=nil end
    if ns.holder and not ns.InArena() and not InCombatLockdown() then ns.holder:Hide() end
end
local function Values(f)
    local d=f.fake
    if d then return true,d.name,d.class,d.hp,100,d.power,100,0,d.powerType,false end
    local unit=f.unit
    if not UnitExists(unit) then return false,f.unitName,f.class,f.lastHP or 0,100,0,1,0,nil,false end
    local _,class=UnitClass(unit)
    f.class=class or f.class; f.unitName=UnitName(unit) or f.unitName; f.guid=UnitGUID(unit) or f.guid
    f.faction=UnitFactionGroup(unit) or f.faction
    local hp,max=UnitHealth(unit) or 0,UnitHealthMax(unit) or 1; if max<=0 then max=1 end
    local pt,token=UnitPowerType(unit)
    return true,f.unitName,f.class,hp,max,UnitPower(unit) or 0,UnitPowerMax(unit) or 1,pt,token,UnitIsDeadOrGhost(unit)
end
function ns.UpdateUnit(f)
    local p=ns.GetSettings(); if not p then return end
    local seen,name,class,hp,max,pw,pwMax,pt,token,dead=Values(f)
    if seen and not f.fake then f.lastHP=hp/max*100 end
    local cc=class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    local r,g,b
    if not seen then r,g,b=.45,.45,.45 elseif p.classColored and cc then r,g,b=cc.r,cc.g,cc.b else r,g,b=p.healthColor.r,p.healthColor.g,p.healthColor.b end
    local dark=1-(p.bgDarkness or 75)/100
    f.health:SetMinMaxValues(0,max); f.health:SetValue(dead and 0 or hp)
    f.health:SetStatusBarColor(r,g,b); f.health.bg:SetVertexColor(r*dark,g*dark,b*dark,1)
    if p.showPower then
        local c=PowerBarColor and (PowerBarColor[token] or PowerBarColor[pt]) or {r=0,g=0,b=1}
        f.power:SetMinMaxValues(0,math.max(pwMax,1)); f.power:SetValue(seen and pw or 0)
        f.power:SetStatusBarColor(c.r,c.g,c.b); f.power.bg:SetVertexColor(c.r*dark,c.g*dark,c.b*dark,1)
    end
    f.name:SetText(name or ("Arena "..f.index))
    if p.classColoredNames and cc then f.name:SetTextColor(cc.r,cc.g,cc.b) else f.name:SetTextColor(1,1,1) end
    local text
    if dead then text="Dead" elseif not seen then text=f.unitName and "Unseen" or "" else text=ns.HealthText(p.healthText,hp,max) end
    f.hp:SetText(text)
    f:SetAlpha(seen and 1 or math.max(.1,(p.unseenAlpha or 50)/100))
    local target=p.targetBorder and not f.fake and UnitIsUnit("target",f.unit)
    if target then f.border:SetVertexColor(p.targetColor.r,p.targetColor.g,p.targetColor.b,1) else f.border:SetVertexColor(0,0,0,1) end
end
-- Highest priority crowd control or immunity aura; ties keep the longest remaining.
function ns.PriorityAura(f)
    if f.fake then
        local d=f.fake.cc; if not d then return end
        local start=f.fakeCC or GetTime(); if GetTime()-start>=d.duration then start=GetTime(); f.fakeCC=start end
        return d.icon,start,d.duration
    end
    local map=ns.AURA_PRIORITY or ns.BuildAuraPriority()
    local best,bestIcon,bestStart,bestDur,bestLeft=0
    for _,filter in ipairs({"HARMFUL","HELPFUL"}) do
        for i=1,40 do
            local name,_,icon,_,_,duration,expires=UnitAura(f.unit,i,filter)
            if not name then break end
            local priority=map[name]
            if priority then
                local left=(expires and expires>0) and expires-GetTime() or math.huge
                if priority>best or (priority==best and left>bestLeft) then
                    best,bestIcon,bestLeft=priority,icon,left
                    bestDur=duration or 0; bestStart=(expires or 0)-bestDur
                end
            end
        end
    end
    if bestIcon then return bestIcon,bestStart,bestDur end
end
function ns.SetClassTexture(t,class,style)
    if style=="blizzard" and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class] then
        t:SetTexture(BLIZZ_CLASSES); t:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
    elseif E.CLASS_ICON_SPRITE_COORDS and E.CLASS_ICON_SPRITE_COORDS[class] then
        t:SetTexture(MODERN_CLASSES); t:SetTexCoord(unpack(E.CLASS_ICON_SPRITE_COORDS[class]))
    else t:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); t:SetTexCoord(.08,.92,.08,.92) end
end
function ns.UpdateIcon(f)
    local p=ns.GetSettings(); if not p or not p.classIcon then return end
    local icon=f.classIcon
    local tex,start,dur
    if p.ccOnIcon then tex,start,dur=ns.PriorityAura(f) end
    if tex then
        icon.icon:SetTexture(tex); icon.icon:SetTexCoord(.08,.92,.08,.92)
        if dur and dur>0 then icon.cd:Show(); icon.cd:SetCooldown(start,dur); icon.expires=start+dur else icon.cd:Hide(); icon.expires=nil end
    else
        ns.SetClassTexture(icon.icon,f.class,p.iconStyle); icon.cd:Hide(); icon.expires=nil
    end
end
function ns.TrinketStart(f)
    if f.fake then return f.fakeTrinket end
    return f.guid and ns.trinketUsed[f.guid]
end
function ns.UpdateTrinket(f)
    local p=ns.GetSettings(); if not p or not p.trinket then return end
    local t=f.trinket
    local faction=f.faction or (UnitFactionGroup("player")=="Horde" and "Alliance" or "Horde")
    t.icon:SetTexture(TRINKET_ICONS[faction] or TRINKET_ICONS.Horde); t.icon:SetTexCoord(.08,.92,.08,.92)
    local start=ns.TrinketStart(f)
    if start and start+ns.TRINKET_COOLDOWN>GetTime() then
        t.cd:Show(); t.cd:SetCooldown(start,ns.TRINKET_COOLDOWN); t.expires=start+ns.TRINKET_COOLDOWN
    else t.cd:Hide(); t.expires=nil end
end
function ns.UpdateCast(f,event)
    local p=ns.GetSettings(); local c=f.cast
    if not p or not p.castBar then c:Hide(); c.active=nil; return end
    local now=GetTime()
    if event=="UNIT_SPELLCAST_INTERRUPTED" and c.active then
        c.active=nil; c.holdUntil=now+.6; c:SetStatusBarColor(1,.15,.15); c:SetValue(select(2,c:GetMinMaxValues()) or 1)
        c.text:SetText(INTERRUPTED or "Interrupted"); c.time:SetText(""); return
    end
    if c.holdUntil and c.holdUntil>now then return end
    c.holdUntil=nil
    local name,texture,startTime,endTime,notInterruptible,channel
    if f.fake then
        local d=f.fake.cast
        if d then name,texture,notInterruptible=d.name,d.icon,d.notInterruptible; startTime=math.floor(now/3)*3; endTime=startTime+3 end
    else
        local n,_,_,tex,s,e,_,_,ni=UnitCastingInfo(f.unit)
        if n then name,texture,startTime,endTime,notInterruptible=n,tex,s/1000,e/1000,ni
        else
            n,_,_,tex,s,e,_,ni=UnitChannelInfo(f.unit)
            if n then name,texture,startTime,endTime,notInterruptible,channel=n,tex,s/1000,e/1000,ni,true end
        end
    end
    if not name or not startTime or endTime<=startTime then c:Hide(); c.active=nil; return end
    c.startTime,c.endTime,c.channel,c.active=startTime,endTime,channel,true
    c:SetMinMaxValues(0,endTime-startTime)
    local color=notInterruptible and p.uninterruptibleColor or p.castColor
    c:SetStatusBarColor(color.r,color.g,color.b)
    c.icon:SetTexture(texture); c.text:SetText(name)
    c:Show(); ns.TickCast(f)
end
function ns.TickCast(f)
    local c=f.cast
    if not c.active then
        if c.holdUntil and c.holdUntil<=GetTime() then c.holdUntil=nil; c:Hide() end
        return
    end
    local now=GetTime()
    if now>c.endTime+.2 then
        if f.fake then ns.UpdateCast(f) else c.active=nil; c:Hide() end
        return
    end
    local total=c.endTime-c.startTime
    local value=c.channel and (c.endTime-now) or (now-c.startTime)
    c:SetValue(math.max(0,math.min(total,value)))
    c.time:SetText(string.format("%.1f",math.max(0,c.endTime-now)))
end
local function TickTimers(f)
    for _,icon in ipairs({f.classIcon,f.trinket}) do
        local left=icon.expires and icon.expires-GetTime()
        if left and left<=0 then icon.expires=nil; icon.cd:Hide(); left=nil
            if icon==f.trinket then ns.UpdateTrinket(f) else ns.UpdateIcon(f) end
        end
        icon.timer:SetText(ns.Timer(left))
    end
end
function ns.RefreshFrame(f)
    ns.UpdateUnit(f); ns.UpdateIcon(f); ns.UpdateTrinket(f); ns.UpdateCast(f); TickTimers(f)
end
function ns.RefreshAll()
    for _,f in ipairs(ns.frames) do if f:IsShown() then ns.RefreshFrame(f) end end
    for _,f in ipairs(ns.previews) do if f:IsShown() then ns.RefreshFrame(f) end end
end
function ns.TickCasts()
    for _,f in ipairs(ns.frames) do if f:IsShown() then ns.TickCast(f) end end
    for _,f in ipairs(ns.previews) do if f:IsShown() then ns.TickCast(f) end end
end
-- 0.1s: health, power, casts and timers; 0.5s: auras as a fallback for missed UNIT_AURA.
function ns.Poll(slow)
    for _,list in ipairs({ns.frames,ns.previews}) do
        for _,f in ipairs(list) do
            if f:IsShown() then
                ns.UpdateUnit(f)
                if not f.cast.active then ns.UpdateCast(f) end
                if slow then ns.UpdateIcon(f) end
                TickTimers(f)
            end
        end
    end
end
