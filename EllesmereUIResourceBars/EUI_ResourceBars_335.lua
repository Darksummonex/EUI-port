-- Native Wrath bars; Retail class/spec displays remain unloaded references.
local ADDON_NAME, ns = ...
local E = EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON_NAME] = ns
local addon = E.Lite.NewAddon(ADDON_NAME)
ns.addon, ns.ERB, ns.IsWrath = addon, addon, true
local white = "Interface\\Buttons\\WHITE8X8"
local defaults = {profile={enabled=true,font="__global",general={barTexture="none"},splitTex=false,
    health={enabled=false,width=214,height=16,textSize=11,showText=true,classColored=true},
    primary={enabled=true,width=214,height=14,textSize=11,showText=true},
    secondary={enabled=true,pipWidth=214,pipHeight=18,pipSpacing=3,textSize=11,showText=true},
    castBar={enabled=false,width=214,height=20,spellTextSize=11,timerSize=11,showText=true,showIcon=true,showChannelTicks=true,texture="none"},
    gcdBar={enabled=false,width=214,height=6,showText=false,texture="none"},
    totemBar={enabled=true,width=214,height=22,timerSize=11,showText=true},positions={},
}}
ns.defaults = defaults
local order={"health","primary","secondary","castBar","gcdBar","totemBar"}
local labels={health="Player Health",primary="Player Power",secondary="Class Resource",castBar="Player Cast Bar",gcdBar="Global Cooldown",totemBar="Totems"}
local keys={health="ERB_HealthBar",primary="ERB_PrimaryBar",secondary="ERB_SecondaryBar",castBar="ERB_CastBar",gcdBar="ERB_GCDBar",totemBar="ERB_TotemBar"}
ns.order,ns.labels,ns.keys=order,labels,keys
local frames,pending,preview={},false,false
ns.frames=frames
local cast,gcd,nativeCastAlpha
local ticks=E.WrathChannelTicks
local _,class=UnitClass("player")
local textures,names,texOrder={none=white,blizzard="Interface\\TargetingFrame\\UI-StatusBar"},{none="Solid",blizzard="Blizzard"},{"none","blizzard"}
for _,key in ipairs({"atrocity","beautiful","divide","fade","fade-right","glass","gradient-bt","gradient-lr","gradient-rl","gradient-tb","matte","plating","sheer","thin-line-bottom","thin-line-top"}) do
    textures[key]="Interface\\AddOns\\EllesmereUIResourceBars\\Media\\Textures_335\\"..key..".tga"
    names[key]=key:gsub("-"," "):gsub("^%l",string.upper); texOrder[#texOrder+1]=key
end
_G._ERB_BarTextures,_G._ERB_BarTextureNames,_G._ERB_BarTextureOrder=textures,names,texOrder
_G._ERB_CastBarTextures,_G._ERB_CastBarTextureNames,_G._ERB_CastBarTextureOrder=textures,names,texOrder
function ns.GetSettings() return addon.db and addon.db.profile end
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function Font(fs,size)
    local p=ns.GetSettings()
    local path=p and p.font~="__global" and E.ResolveFontName and E.ResolveFontName(p.font)
    path=path or (E.GetFontPath and E.GetFontPath(ADDON_NAME)) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local flag=((E.GetFontOutlineFlag and E.GetFontOutlineFlag(ADDON_NAME)) or "OUTLINE"):gsub(",?%s*SLUG","")
    if not fs:SetFont(path,math.max(8,tonumber(size) or 11),flag) then fs:SetFont("Fonts\\FRIZQT__.TTF",11,"OUTLINE") end
end
local function Texture(key)
    if textures[key] then return textures[key] end
    if type(key)=="string" and key:find("\\",1,true) then return key end
    return white
end
local function Color(b,r,g,blue) b:SetStatusBarColor(r or .1,g or .8,blue or .6) end
local function ClassColor(b) local c=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]; Color(b,c and c.r,c and c.g,c and c.b) end
local function NewBar(parent)
    local b=CreateFrame("StatusBar",nil,parent); b:SetStatusBarTexture(white); b:SetMinMaxValues(0,1); b:SetValue(0)
    b:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); b:SetBackdropColor(.035,.045,.05,.95); b:SetBackdropBorderColor(0,0,0,1)
    b.text=b:CreateFontString(nil,"OVERLAY"); Font(b.text,11); b.text:SetPoint("CENTER",b,"CENTER",0,0)
    return b
end
local function NewFrame(key)
    local f=CreateFrame("Frame","EUI335Resource_"..key,UIParent); f:SetFrameStrata("MEDIUM"); f:Hide(); f.bars={}
    if key=="secondary" or key=="totemBar" then
        for i=1,(key=="secondary" and 6 or 4) do f.bars[i]=NewBar(f) end
    else
        f.bar=NewBar(f); f.bar:SetAllPoints(f)
        if key=="castBar" then
            f.bar.text:ClearAllPoints(); f.bar.text:SetPoint("LEFT",f.bar,"LEFT",4,0)
            f.timer=f.bar:CreateFontString(nil,"OVERLAY"); Font(f.timer,11); f.timer:SetPoint("RIGHT",f.bar,"RIGHT",-4,0)
            f.icon=f:CreateTexture(nil,"ARTWORK"); f.icon:SetTexCoord(.08,.92,.08,.92)
        end
    end
    f:EnableMouse(false); frames[key]=f; return f
end
local function Visible(key,show)
    local f,p=frames[key],ns.GetSettings()
    local supported=(key~="secondary" or class=="ROGUE" or class=="DRUID" or class=="DEATHKNIGHT") and (key~="totemBar" or class=="SHAMAN")
    if f then
        local visible=p.enabled and p[key].enabled and supported and (show or preview)
        if visible and not f:IsShown() then f:Show() elseif not visible and f:IsShown() then f:Hide() end
    end
end
local function Value(b,value,maxValue)
    maxValue=math.max(1,tonumber(maxValue) or 0); value=math.max(0,tonumber(value) or 0)
    if b._euiMaximum~=maxValue then b:SetMinMaxValues(0,maxValue); b._euiMaximum=maxValue end
    b:SetValue(math.min(value,maxValue))
end
function ns.UpdateVitals()
    local p=ns.GetSettings(); if not p or not frames.primary then return end
    local hp,maxHP=UnitHealth("player") or 0,UnitHealthMax("player") or 0
    local b=frames.health.bar; Value(b,hp,maxHP)
    if p.health.classColored then ClassColor(b) else Color(b,.12,.8,.25) end
    b.text:SetText(p.health.showText and (hp.." / "..maxHP) or ""); Visible("health",true)
    local powerType,token=UnitPowerType("player")
    local power,maxPower=UnitPower("player",powerType) or 0,UnitPowerMax("player",powerType) or 0
    b=frames.primary.bar; Value(b,power,maxPower)
    local c=PowerBarColor and (PowerBarColor[token] or PowerBarColor[powerType])
    Color(b,c and c.r or .15,c and c.g or .45,c and c.b or 1)
    b.text:SetText(p.primary.showText and (power.." / "..maxPower) or ""); Visible("primary",maxPower>0)
end
local runeColors={{.8,.15,.15},{.2,.75,.2},{.25,.6,1},{.65,.3,.9}}
function ns.UpdateClass()
    local p=ns.GetSettings(); if not p or not frames.secondary then return end
    local f=frames.secondary; local now=GetTime()
    local combo=class=="ROGUE" or (class=="DRUID" and UnitPowerType("player")==3)
    local count=class=="DEATHKNIGHT" and 6 or 5
    local points=combo and (GetComboPoints("player","target") or 0) or 0
    local valid=combo or (class=="DEATHKNIGHT" and type(GetRuneCooldown)=="function")
    local c=p.secondary; local w=(f:GetWidth()-(count-1)*c.pipSpacing)/count
    for i,b in ipairs(f.bars) do
        b:ClearAllPoints(); b:SetPoint("LEFT",f,"LEFT",(i-1)*(w+c.pipSpacing),0); Size(b,w,f:GetHeight())
        if i<=count then b:Show() else b:Hide() end
        local text=""
        if class=="DEATHKNIGHT" and GetRuneCooldown then
            local start,duration,ready=GetRuneCooldown(i); local remaining=math.max(0,(start or 0)+(duration or 0)-now)
            Value(b,ready and 1 or ((duration or 0)>0 and 1-remaining/duration or 0),1)
            local rc=runeColors[GetRuneType and GetRuneType(i) or 1] or runeColors[1]; Color(b,unpack(rc))
            if not ready and remaining>0 then text=string.format("%.1f",remaining) end
        else Value(b,i<=points and 1 or 0,1); ClassColor(b); text=i<=points and tostring(i) or "" end
        if preview and not valid then Value(b,1,1); ClassColor(b); text=tostring(i) end
        b.text:SetText(c.showText and text or "")
    end
    Visible("secondary",valid)
end
function ns.UpdateTotems()
    local p=ns.GetSettings(); if not p or not frames.totemBar then return end
    local f=frames.totemBar; local any=false
    for i,b in ipairs(f.bars) do
        local have,name,start,duration
        if class=="SHAMAN" and GetTotemInfo then have,name,start,duration=GetTotemInfo(i) end
        local remaining=math.max(0,(start or 0)+(duration or 0)-GetTime()); if have and remaining>0 then any=true end
        Value(b,remaining,duration); local c=({{.95,.3,.15},{.6,.4,.2},{.2,.5,1},{.7,.8,.9}})[i]; Color(b,unpack(c))
        b.text:SetText(p.totemBar.showText and ((have and remaining>0) and tostring(math.ceil(remaining)) or (preview and tostring(i) or "")) or "")
        b.totemName=name
    end
    Visible("totemBar",class=="SHAMAN" and any)
end
-- Query the current cast on each event: an older STOP must not erase a newer cast.
function ns.ReadCast(updating)
    local name,rank,display,icon,start,finish,trade,id=UnitCastingInfo("player")
    local channel=false
    if not name then name,rank,display,icon,start,finish=UnitChannelInfo("player"); channel=true end
    local previous=cast
    if name and start and finish and finish>start and finish/1000>GetTime() then
        cast={name=name,icon=icon,start=start/1000,finish=finish/1000,channel=channel,id=id}
        if channel and ticks then cast.ticks=ticks.Schedule(name,cast.start,cast.finish,previous and previous.channel and previous.ticks,nil,updating) end
    else cast=nil end
    if frames.castBar then
        local f,p=frames.castBar,ns.GetSettings()
        f.bar.text:SetText(cast and p.castBar.showText and cast.name or "")
        f.icon:SetTexture(cast and cast.icon or nil)
        if ticks then ticks.Draw(f.bar,cast and cast.ticks,cast and cast.start,cast and cast.finish,p.castBar.showChannelTicks~=false) end
    end
    ns.cast=cast; ns.UpdateTimers()
end
function ns.ReadGCD()
    if not GetSpellCooldown then return end
    local start,duration,enabled=GetSpellCooldown(61304)
    if enabled~=0 and duration and duration>0 and duration<=1.7 and start then gcd={start=start,duration=duration} else gcd=nil end
    ns.UpdateTimers()
end
function ns.UpdateTimers()
    local p=ns.GetSettings(); if not p or not frames.castBar then return end
    local now=GetTime(); local f=frames.castBar; local b=f.bar
    if cast and now>=cast.finish then cast=nil; ns.cast=nil end
    if cast then
        Value(b,cast.channel and cast.finish-now or now-cast.start,cast.finish-cast.start); Color(b,.12,.72,.58)
        local text=p.castBar.showText and string.format("%.1f",math.max(0,cast.finish-now)) or ""
        if f._timerText~=text then f.timer:SetText(text); f._timerText=text end
    elseif preview then Value(b,.6,1); Color(b,.12,.72,.58); b.text:SetText("Cast Bar"); f.timer:SetText("1.2"); f._timerText="1.2" end
    Visible("castBar",cast~=nil)
    if not cast and ticks then ticks.Hide(b) end
    if gcd and now>=gcd.start+gcd.duration then gcd=nil end
    b=frames.gcdBar.bar; if gcd then Value(b,gcd.start+gcd.duration-now,gcd.duration) elseif preview then Value(b,.6,1) end
    Color(b,.65,.65,.75); Visible("gcdBar",gcd~=nil)
    if nativeCastAlpha~=nil and CastingBarFrame then CastingBarFrame:SetAlpha(0) end
end
local function Position(key,index)
    local p,f=ns.GetSettings(),frames[key]; local pos=p.positions[key]; f:ClearAllPoints()
    if pos then f:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y) else f:SetPoint("CENTER",UIParent,"CENTER",0,-150-(index-1)*27) end
end
function ns.Apply()
    local p=ns.GetSettings(); if not p then return end
    if InCombatLockdown() then pending=true; return end; pending=false
    for i,key in ipairs(order) do
        local f=frames[key] or NewFrame(key); local c=p[key]
        local w=math.max(60,math.min(1000,tonumber(c.pipWidth or c.width) or 214)); local h=math.max(3,math.min(100,tonumber(c.pipHeight or c.height) or 18))
        Size(f,w,h); Position(key,i)
        local tex=Texture((key=="castBar" or key=="gcdBar") and c.texture or (p.splitTex and c.barTexture or p.general.barTexture))
        for _,b in ipairs(f.bars) do b:SetStatusBarTexture(tex); Font(b.text,c.textSize or c.timerSize) end
        if f.bar then f.bar:SetStatusBarTexture(tex); Font(f.bar.text,c.textSize or c.spellTextSize) end
        if key=="totemBar" then for n,b in ipairs(f.bars) do Size(b,(w-9)/4,h); b:ClearAllPoints(); b:SetPoint("LEFT",f,"LEFT",(n-1)*((w-9)/4+3),0) end
        elseif key=="castBar" then
            Font(f.timer,c.timerSize); f.icon:ClearAllPoints(); Size(f.icon,h,h); f.icon:SetPoint("RIGHT",f,"LEFT",-3,0)
            if c.showIcon then f.icon:Show() else f.icon:Hide() end
            f.bar.text:SetWidth(math.max(20,w-48)); f.bar.text:SetJustifyH("LEFT")
        end
    end
    if CastingBarFrame then
        if p.enabled and p.castBar.enabled then if nativeCastAlpha==nil then nativeCastAlpha=CastingBarFrame:GetAlpha() end; CastingBarFrame:SetAlpha(0)
        elseif nativeCastAlpha~=nil then local alpha=nativeCastAlpha; nativeCastAlpha=nil; CastingBarFrame:SetAlpha(alpha) end
    end
    ns.UpdateVitals(); ns.UpdateClass(); ns.UpdateTotems(); ns.ReadCast(); ns.ReadGCD()
end
function ns.SetPreview(value) preview=value and true or false; ns.Apply() end
function ns.ResetPositions() local p=ns.GetSettings(); if p then p.positions={}; ns.Apply() end end
function addon:OnInitialize()
    addon.db=E.Lite.NewDB("EllesmereUIResourceBarsDB",defaults); ns.db=addon.db; _G._ERB_AceDB=addon.db
    _G._ERB_Apply=ns.Apply; _G._ERB_RefreshAll=ns.Apply
    SLASH_EUI335RESOURCE1="/erb"
    SlashCmdList.EUI335RESOURCE=function() if InCombatLockdown() then return end; if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; E:ShowModule(ADDON_NAME) end
end
function addon:OnEnable()
    ns.Apply()
    if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener(ADDON_NAME,function(active) ns.SetPreview(active) end) end
    if E.RegisterUnlockElements and E.MakeUnlockElement then
        local elements={}
        for i,key in ipairs(order) do
            local barKey=key
            elements[#elements+1]=E.MakeUnlockElement({key=keys[key],label=labels[key],group="Resource Bars",order=700+i,noResize=true,noAnchorTo=true,
                getFrame=function() return frames[barKey] end,
                getSize=function() local f=frames[barKey]; return f and f:GetWidth() or 214,f and f:GetHeight() or 18 end,
                isHidden=function() local p=ns.GetSettings(); return not p or not p.enabled or not p[barKey].enabled or not frames[barKey] or not frames[barKey]:IsShown() end,
                savePos=function(_,point,relPoint,x,y) local p=ns.GetSettings(); if p then p.positions[barKey]={point=point,relPoint=relPoint,x=x,y=y} end end,
                loadPos=function() local p=ns.GetSettings(); return p and p.positions[barKey] end,
                clearPos=function() local p=ns.GetSettings(); if p then p.positions[barKey]=nil; ns.Apply() end end,applyPos=ns.Apply,
            })
        end
        E:RegisterUnlockElements(elements,ADDON_NAME)
    end
    local events=CreateFrame("Frame"); ns.events=events
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_TARGET_CHANGED","UNIT_COMBO_POINTS","RUNE_POWER_UPDATE","RUNE_TYPE_UPDATE","PLAYER_TOTEM_UPDATE","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_MANA","UNIT_MAXMANA","UNIT_RAGE","UNIT_MAXRAGE","UNIT_ENERGY","UNIT_MAXENERGY","UNIT_RUNIC_POWER","UNIT_MAXRUNIC_POWER","UNIT_DISPLAYPOWER","UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_DELAYED","UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_UPDATE","UNIT_SPELLCAST_CHANNEL_STOP","SPELL_UPDATE_COOLDOWN"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent",function(_,event,unit)
        if event=="PLAYER_ENTERING_WORLD" or (event=="PLAYER_REGEN_ENABLED" and pending) then ns.Apply()
        elseif event:find("UNIT_SPELLCAST",1,true) then if unit=="player" then ns.ReadCast(event=="UNIT_SPELLCAST_CHANNEL_UPDATE") end
        elseif event=="SPELL_UPDATE_COOLDOWN" then ns.ReadGCD()
        elseif event=="PLAYER_TOTEM_UPDATE" then ns.UpdateTotems()
        elseif not unit or unit=="player" or event=="PLAYER_TARGET_CHANGED" or event:find("RUNE_",1,true)==1 then ns.UpdateVitals(); ns.UpdateClass() end
    end)
    local elapsed=0
    events:SetScript("OnUpdate",function(_,dt)
        local p=ns.GetSettings(); if not p or not p.enabled then return end
        -- Timed fills must follow the render clock; only class-resource work
        -- is throttled. Never interpolate toward a moving cast endpoint.
        if cast or gcd then ns.UpdateTimers() end
        elapsed=elapsed+dt; if elapsed<.05 then return end; elapsed=0
        if class=="DEATHKNIGHT" and p.secondary.enabled then ns.UpdateClass() end
        if class=="SHAMAN" and p.totemBar.enabled then ns.UpdateTotems() end
    end)
    if CastingBarFrame and type(hooksecurefunc)=="function" then
        hooksecurefunc(CastingBarFrame,"SetAlpha",function(self,alpha)
            if nativeCastAlpha~=nil and alpha~=0 then self:SetAlpha(0) end
        end)
    end
end
