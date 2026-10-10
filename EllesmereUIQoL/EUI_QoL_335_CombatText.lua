-- Self Combat Text: damage taken, heals received, avoids and combat enter/leave
-- scrolling above the player frame in place of Blizzard's combat text.
-- Wrath has no C_CombatText and no Path animations: hits come from the combat
-- log (player or vehicle as the target) and an OnUpdate moves the live
-- messages, idle once the last one fades. Blizzard's CombatText frame is only
-- hidden, never written to: its OnEvent bails while hidden.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not ns.addon then return end

local POOL_SIZE,FADE_FRAC=12,.3
local UNLOCK_KEY="EUI_SelfCombatText"
local BOX_W,BOX_H=200,30
local LINE_H,LINE_GAP=1.15,2
local HALF_PI=math.pi/2

local DAMAGE={SWING_DAMAGE=9,RANGE_DAMAGE=12,SPELL_DAMAGE=12,SPELL_PERIODIC_DAMAGE=12,DAMAGE_SHIELD=12,DAMAGE_SPLIT=12,ENVIRONMENTAL_DAMAGE=10}
local HEAL={SPELL_HEAL=12,SPELL_PERIODIC_HEAL=12}
local MISSED={SWING_MISSED=9,RANGE_MISSED=12,SPELL_MISSED=12,SPELL_PERIODIC_MISSED=12,DAMAGE_SHIELD_MISSED=12}
local AVOID_FALLBACK={MISS="Miss",DODGE="Dodge",PARRY="Parry",EVADE="Evade",IMMUNE="Immune",DEFLECT="Deflect",REFLECT="Reflect",RESIST="Resist",BLOCK="Block",ABSORB="Absorb"}

local anchor,ev
local pool,nextIdx,live,xDir={},0,0,1
local enabled=false
local S={fontVer=0}
ns.sctPool=pool

local function Settings() local p=ns.GetSettings(); return p and p.selfCombatText end
local function Enabled() local p=ns.GetSettings(); local t=p and p.selfCombatText; return p and p.enabled and t and t.enabled and true or false end
local function Num(v,def,lo,hi) v=tonumber(v) or def; if lo and v<lo then v=lo end; if hi and v>hi then v=hi end; return v end
local function Col(c,r,g,b) c=type(c)=="table" and c or {}; return {r=c.r or r,g=c.g or g,b=c.b or b} end

local function ReadSettings()
    local t=Settings() or {}
    local key=t.font or "__combat"
    if key=="__global" then S.font=(E.GetFontPath and E.GetFontPath("extras")) or STANDARD_TEXT_FONT
    else local f=_G.CombatTextFont; S.font=f and f:GetFont() or STANDARD_TEXT_FONT end
    S.font=S.font or "Fonts\\FRIZQT__.TTF"
    S.flags=(t.outline=="NONE" and "") or (t.outline=="THICKOUTLINE" and "THICKOUTLINE") or "OUTLINE"
    S.shadow=t.shadow==true
    S.size=Num(t.size,16,8,64); S.critSize=S.size*Num(t.critScale,1.5,1,3)
    S.anim=(t.anim=="fountain" or t.anim=="static") and t.anim or "straight"
    S.rise=Num(t.rise,80,0,400); S.duration=Num(t.duration,1.9,.3,6)
    S.dy=t.direction=="down" and -S.rise or S.rise
    S.stagger=t.stagger~=false; S.abbreviate=t.abbreviate==true
    S.damage,S.heal,S.avoid,S.combat=t.damage~=false,t.heal~=false,t.avoid~=false,t.combat~=false
    S.damageColor=Col(t.damageColor,1,.1,.1); S.healColor=Col(t.healColor,.1,1,.1)
    S.avoidColor=Col(t.avoidColor,1,1,1); S.combatColor=Col(t.combatColor,1,.1,.1)
    S.fontVer=S.fontVer+1
end

local function Group(n)
    local s=tostring(math.floor(n+.5)); local out
    repeat s,out=s:gsub("^(%d+)(%d%d%d)","%1,%2") until out==0
    return s
end
function ns.SCT_FormatAmount(n,abbreviate)
    n=tonumber(n) or 0
    if abbreviate then
        if n>=1e6 then return (string.format("%.1fM",n/1e6):gsub("%.0M","M")) end
        if n>=1e4 then return string.format("%dK",math.floor(n/1e3+.5)) end
        if n>=1e3 then return (string.format("%.1fK",n/1e3):gsub("%.0K","K")) end
    end
    return Group(n)
end

-------------------------------------------------------------------------------
-- Position (Unlock Mode owns it once saved)
-------------------------------------------------------------------------------
local function ApplyPos()
    if not anchor then return end
    local p=ns.GetSettings(); local pos=p and p.positions and p.positions.selfCombatText
    anchor:ClearAllPoints()
    if pos then anchor:SetPoint(pos.point,UIParent,pos.relPoint or pos.point,pos.x,pos.y); return end
    local pf=_G.EllesmereUIUnitFrames_Player
    if pf and pf:IsShown() then anchor:SetPoint("BOTTOM",pf,"TOP",0,10)
    else anchor:SetPoint("BOTTOM",UIParent,"CENTER",0,-140) end
end
ns.SCT_ApplyPos=ApplyPos

function ns.SCT_UnlockElement()
    return E.MakeUnlockElement({key=UNLOCK_KEY,label="Self Combat Text",group="Quality of Life",order=930,noResize=true,noAnchorTo=true,
        isHidden=function() return not Enabled() end,
        getFrame=function() return enabled and anchor or nil end,
        getSize=function() return BOX_W,BOX_H end,
        savePos=function(_,point,relPoint,x,y)
            local p=ns.GetSettings(); if not (p and point) then return end
            p.positions.selfCombatText={point=point,relPoint=relPoint or point,x=x,y=y}
            if not E._unlockActive then ApplyPos() end
        end,
        loadPos=function() local p=ns.GetSettings(); return p and p.positions.selfCombatText end,
        clearPos=function() local p=ns.GetSettings(); if p then p.positions.selfCombatText=nil end; ApplyPos() end,
        applyPos=ApplyPos})
end

-------------------------------------------------------------------------------
-- Messages
-------------------------------------------------------------------------------
-- Fraction of the scroll distance covered: linear for Straight, the height of
-- a quarter circle for Fountain, none for Static.
local function Travel(m,now)
    if S.anim=="static" then return 0 end
    local f=(now-m.t0)/S.duration; if f>1 then f=1 end
    if S.anim=="fountain" then return math.sin(f*HALF_PI) end
    return f
end

local function Place(m,now)
    local f=(now-m.t0)/S.duration
    local x=0
    if S.anim=="fountain" then x=m.lane*S.rise*(1-math.cos(math.min(f,1)*HALF_PI)) end
    m:ClearAllPoints(); m:SetPoint("BOTTOM",anchor,"BOTTOM",x,m.y0+S.dy*Travel(m,now))
    m:SetAlpha(f>1-FADE_FRAC and math.max(0,(1-f)/FADE_FRAC) or 1)
end

local function OnUpdate()
    local now=GetTime()
    for i=1,POOL_SIZE do
        local m=pool[i]
        if m.live then
            if now-m.t0>=S.duration then m.live=nil; m:Hide(); live=live-1 else Place(m,now) end
        end
    end
    if live<=0 then live=0; anchor:SetScript("OnUpdate",nil) end
end

-- Stagger: before a message of height h starts at the anchor, push its lane's
-- live messages on along the scroll until the nearest one clears it.
local function ClearLane(lane,h)
    local now,dur,dy=GetTime(),S.duration,S.dy
    local s=dy<0 and -1 or 1
    local near,nearD
    for i=1,POOL_SIZE do
        local m=pool[i]
        if m.live and m.lane==lane and now-m.t0<dur then
            local d=s*(m.y0+dy*Travel(m,now))
            if not nearD or d<nearD then near,nearD=m,d end
        end
    end
    if not near then return end
    local need=(s>0 and h or near.h)+LINE_GAP-nearD
    if need<=0 then return end
    for i=1,POOL_SIZE do
        local m=pool[i]
        if m.live and m.lane==lane and now-m.t0<dur then m.y0=m.y0+s*need; Place(m,now) end
    end
end

local function Emit(text,c,crit)
    if not anchor then return end
    nextIdx=nextIdx%POOL_SIZE+1
    local m=pool[nextIdx]
    if m.live then live=live-1 end
    m.live=nil
    local lane=0
    if S.anim=="fountain" then xDir=-xDir; lane=xDir end
    local h=(crit and S.critSize or S.size)*LINE_H
    if S.stagger then ClearLane(lane,h) end
    local kind=crit and 2 or 1
    if m.fontVer~=S.fontVer or m.fontKind~=kind then
        m.fontVer,m.fontKind=S.fontVer,kind
        if not m:SetFont(S.font,crit and S.critSize or S.size,S.flags) then m:SetFont("Fonts\\FRIZQT__.TTF",crit and S.critSize or S.size,S.flags) end
        if S.shadow then m:SetShadowColor(0,0,0,1); m:SetShadowOffset(1,-1) else m:SetShadowOffset(0,0) end
    end
    m.t0,m.y0,m.h,m.lane,m.live=GetTime(),0,h,lane,true
    m:SetTextColor(c.r,c.g,c.b); m:SetText(text)
    live=live+1; Place(m,m.t0); m:Show()
    anchor:SetScript("OnUpdate",OnUpdate)
end
ns.SCT_Emit=Emit

local function IsMe(guid)
    if not guid then return false end
    if guid==UnitGUID("player") then return true end
    return UnitHasVehicleUI and UnitHasVehicleUI("player") and guid==UnitGUID("vehicle") or false
end

local function OnCombatLog(...)
    local sub,dst=select(2,...),select(6,...)
    if not IsMe(dst) then return end
    local at=DAMAGE[sub]
    if at then
        if not S.damage then return end
        local amount=select(at,...); if not amount or amount<=0 then return end
        Emit("-"..ns.SCT_FormatAmount(amount,S.abbreviate),S.damageColor,select(at+6,...) and true or false); return
    end
    at=HEAL[sub]
    if at then
        if not S.heal then return end
        local amount=select(at,...); if not amount or amount<=0 then return end
        Emit("+"..ns.SCT_FormatAmount(amount,S.abbreviate),S.healColor,select(at+3,...) and true or false); return
    end
    at=MISSED[sub]
    if at and S.avoid then
        local miss=select(at,...)
        local label=miss and (_G["COMBAT_TEXT_"..miss] or AVOID_FALLBACK[miss])
        if label then Emit(label,S.avoidColor,false) end
    end
end

local function HideBlizzard() if _G.CombatText then _G.CombatText:Hide() end end
local function OnEvent(_,event,...)
    if event=="COMBAT_LOG_EVENT_UNFILTERED" then OnCombatLog(...)
    elseif event=="PLAYER_REGEN_DISABLED" then Emit(_G.ENTERING_COMBAT or "+Combat",S.combatColor,false)
    elseif event=="PLAYER_REGEN_ENABLED" then Emit(_G.LEAVING_COMBAT or "-Combat",S.combatColor,false)
    elseif event=="ADDON_LOADED" and ...=="Blizzard_CombatText" then HideBlizzard(); ev:UnregisterEvent("ADDON_LOADED") end
end

local function UpdateEvents()
    if S.damage or S.heal or S.avoid then ev:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") else ev:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED") end
    if S.combat then ev:RegisterEvent("PLAYER_REGEN_DISABLED"); ev:RegisterEvent("PLAYER_REGEN_ENABLED")
    else ev:UnregisterEvent("PLAYER_REGEN_DISABLED"); ev:UnregisterEvent("PLAYER_REGEN_ENABLED") end
end

local function Build()
    anchor=CreateFrame("Frame","EUI335QoL_SelfCombatText",UIParent)
    ns.Size(anchor,BOX_W,BOX_H); anchor:SetFrameStrata("HIGH"); anchor:EnableMouse(false)
    for i=1,POOL_SIZE do local fs=anchor:CreateFontString(nil,"OVERLAY"); fs:Hide(); pool[i]=fs end
    ev=CreateFrame("Frame"); ev:SetScript("OnEvent",OnEvent)
    ns.sctAnchor,ns.sctEvents=anchor,ev
end

function ns.ApplySelfCombatText()
    local want=Enabled()
    if want then
        if not anchor then Build() end
        ReadSettings(); ApplyPos(); anchor:Show(); UpdateEvents()
        if not enabled then
            if _G.CombatText then HideBlizzard() else ev:RegisterEvent("ADDON_LOADED") end
        end
    elseif enabled then
        ev:UnregisterAllEvents(); anchor:SetScript("OnUpdate",nil); anchor:Hide()
        for i=1,POOL_SIZE do pool[i].live=nil; pool[i]:Hide() end; live=0
        if _G.CombatText then _G.CombatText:Show() end
    end
    enabled=want
end
