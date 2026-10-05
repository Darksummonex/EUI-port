-- Wrath's anonymous WorldFrame plates remain the native data/click backend.
-- Retail engines and namespaces are not loaded or emulated.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not E or not E.Lite or not WorldFrame then return end
local addon=E.Lite.NewAddon(ADDON_NAME)
E._ModuleNS[ADDON_NAME]=ns
ns.addon,ns.ENP,ns.IsWrath=addon,addon,true
_G.EllesmereNameplates_NS=ns
local defaults={enabled=true,width=120,height=12,castHeight=8,yOffset=0,
    nameSize=11,healthTextSize=10,levelSize=10,castNameSize=10,castTimerSize=9,
    auraStackTextSize=10,auraDurationTextSize=9,
    showHealthText=true,showLevel=true,showCastBar=true,showCastName=true,showCastTimer=true,
    showRaidMarker=true,raidMarkerSize=20,showTargetBorder=true,targetScale=1.1,
    borderSize=1,healthBarTexture="flat",castBarTexture="flat",
    friendlyNameOnly=false,classColoredNames=false,threatColors=false,tankMode=false,
    friendlyHealthClassColored=false,
    opacity=100,nonTargetAlpha=100,showAuras=true,showDebuffs=true,showBuffs=false,
    onlyPlayerDebuffs=true,auraSize=20,maxAuras=6,
}
ns.defaults=defaults
local states,active,pending={},false,false
ns.plates=states
local elapsed,scanElapsed,layoutVersion=0,0,0
local castCVarOriginal,pendingCVars
local auraLib=LibStub and LibStub("LibAuraInfo-1.0-ElvUI",true)
local syncingAuraCache=false
ns.auraLib=auraLib
-- Class hints are cosmetic only; never use name/roster matches for auras or casts.
local rosterClasses,observedClasses={},{}
local marker="interface\\targetingframe\\ui-targetingframe-flash"
local textures={flat="Interface\\Buttons\\WHITE8X8",blizzard="Interface\\TargetingFrame\\UI-StatusBar"}
ns.textureValues,ns.textureOrder={flat="Flat",blizzard="Blizzard"},{"flat","blizzard"}
function ns.GetSettings() return addon.db and addon.db.profile end
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function Font(fs,size)
    local flags=E.GetFontOutlineFlag and E.GetFontOutlineFlag("nameplates") or ""
    fs:SetFont(E.GetFontPath("nameplates"),size,(flags:gsub(",?%s*SLUG","")))
end
local function Text(parent,size)
    local fs=parent:CreateFontString(nil,"OVERLAY"); Font(fs,size); fs:SetTextColor(1,1,1)
    return fs
end
local function Frame(parent)
    local f=CreateFrame("Frame",nil,parent); f:EnableMouse(false); return f
end
-- ElvUI-style look: translucent dark backdrop, thin dark border OUTSIDE the bar
-- (the old border sat behind the opaque bar and was never visible), soft palette.
local BACKDROP,BORDER={.06,.06,.06,.8},{.1,.1,.1}
local PALETTE={bad={.78,.25,.25},neutral={.85,.77,.36},good={.29,.69,.30},
    friendlyPlayer={.31,.45,.63},tapped={.6,.6,.6},transition={.92,.64,.16},
    cast={1,.81,0},castLocked={.78,.25,.25},glow={.3,.7,1}}
local function Soften(r,g,b)
    if r>.9 and g<.1 and b<.1 then return unpack(PALETTE.bad) end
    if r>.9 and g>.9 and b<.1 then return unpack(PALETTE.neutral) end
    if r<.1 and g>.9 and b<.1 then return unpack(PALETTE.good) end
    if r<.1 and g<.1 and b>.9 then return unpack(PALETTE.friendlyPlayer) end
    if math.abs(r-.5)<.05 and math.abs(g-.5)<.05 and math.abs(b-.5)<.05 then return unpack(PALETTE.tapped) end
    return r,g,b
end
local function WithBorder(f)
    local border=Frame(f); border:SetFrameLevel(math.max(0,f:GetFrameLevel()-1))
    border:SetPoint("TOPLEFT",f,"TOPLEFT",-1,1); border:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",1,-1)
    f.border=border
    local bg=f:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(f); bg:SetTexture(textures.flat)
    bg:SetVertexColor(BACKDROP[1],BACKDROP[2],BACKDROP[3],BACKDROP[4])
    return f
end
local function Bar(parent)
    local f=CreateFrame("StatusBar",nil,parent); f:EnableMouse(false)
    f:SetStatusBarTexture(textures.flat); f:SetMinMaxValues(0,1)
    return WithBorder(f)
end
local function Box(parent)
    local f=WithBorder(Frame(parent))
    f.tex=f:CreateTexture(nil,"ARTWORK"); f.tex:SetAllPoints(f); f.tex:SetTexCoord(.08,.92,.08,.92)
    return f
end
local function Border(f,p,r,g,b)
    local n=math.max(0,math.min(4,p.borderSize or 1))
    local owner=f:GetParent()
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT",owner,"TOPLEFT",-n,n); f:SetPoint("BOTTOMRIGHT",owner,"BOTTOMRIGHT",n,-n)
    f:SetBackdrop(n>0 and {edgeFile=textures.flat,edgeSize=n} or nil)
    f:SetBackdropBorderColor(r or BORDER[1],g or BORDER[2],b or BORDER[3],1)
end
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
local function HideNative(s)
    for region in pairs(s.originalAlpha) do region:SetAlpha(0) end
    -- The client's flash animation can overwrite alpha. Keep its threat state
    -- and vertex colors, but render the warning on the owned health bar.
    s.native.threat:SetTexture("")
end
local function ClearUnit(s)
    s.unit,s.guid,s.isTarget=nil,nil,false
    s.friendlyClass=nil
    s.auraGUID,s.auraName,s.auraVerified=nil,nil,nil
    if s.aggro then s.aggro:Hide() end
    if s.auras then for _,a in ipairs(s.auras) do a:Hide() end end
end
local function Capture(plate,native)
    local p=ns.GetSettings()
    local s={native=native,plate=plate,originalAlpha={},auras={},originalThreatTexture=native.threat:GetTexture()}
    states[plate]=s
    for _,region in pairs(native) do
        if region.GetAlpha and region.SetAlpha then s.originalAlpha[region]=region:GetAlpha() end
    end
    local root=Frame(plate); root:SetPoint("CENTER",plate,"CENTER",0,0)
    Size(root,p.width,p.height); root:SetFrameLevel(plate:GetFrameLevel()+4); s.root=root
    s.health=Bar(root); s.health:SetAllPoints(root)
    s.aggro=Frame(s.health); s.aggro:SetAllPoints(s.health)
    s.aggro:SetFrameLevel(s.health:GetFrameLevel()+2)
    s.aggro:SetBackdrop({edgeFile=textures.flat,edgeSize=2}); s.aggro:Hide()
    -- Target glow: two thin rings just outside the dark border (ElvUI "border" glow).
    s.glowInner,s.glowOuter=Frame(root),Frame(root)
    s.glowInner:SetFrameLevel(math.max(0,s.health:GetFrameLevel()-2)); s.glowInner:Hide()
    s.glowOuter:SetFrameLevel(math.max(0,s.health:GetFrameLevel()-3)); s.glowOuter:Hide()
    -- Name above-left, level above-right, health text centred on the bar.
    s.name=Text(root,p.nameSize); s.name:SetPoint("BOTTOMLEFT",s.health,"TOPLEFT",0,3)
    s.name:SetJustifyH("LEFT"); s.name:SetWordWrap(false)
    s.level=Text(root,p.levelSize); s.level:SetPoint("BOTTOMRIGHT",s.health,"TOPRIGHT",0,3); s.level:SetJustifyH("RIGHT")
    s.healthText=Text(s.health,p.healthTextSize); s.healthText:SetPoint("CENTER",s.health,"CENTER",0,0)
    -- Cast bar under the health bar; bordered icon on the left spanning both bars; spark.
    s.cast=Bar(root); s.cast:SetPoint("TOPLEFT",s.health,"BOTTOMLEFT",0,-4)
    s.castText=Text(s.cast,p.castNameSize); s.castText:SetPoint("LEFT",s.cast,"LEFT",4,0); s.castText:SetJustifyH("LEFT")
    s.castTimer=Text(s.cast,p.castTimerSize); s.castTimer:SetPoint("RIGHT",s.cast,"RIGHT",-4,0)
    s.castSpark=s.cast:CreateTexture(nil,"OVERLAY"); s.castSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    s.castSpark:SetBlendMode("ADD"); s.castSpark:SetWidth(14)
    s.castSpark:SetPoint("CENTER",s.cast:GetStatusBarTexture(),"RIGHT",0,0)
    s.castIcon=Box(root); s.castIcon:SetPoint("BOTTOMRIGHT",s.cast,"BOTTOMLEFT",-4,0)
    s.raid=root:CreateTexture(nil,"OVERLAY"); s.raid:SetPoint("LEFT",s.health,"RIGHT",5,0)
    s.hover=s.health:CreateTexture(nil,"OVERLAY")
    s.hover:SetPoint("TOPLEFT",s.health,"TOPLEFT"); s.hover:SetPoint("BOTTOMRIGHT",s.health:GetStatusBarTexture(),"BOTTOMRIGHT")
    s.hover:SetTexture(textures.flat); s.hover:SetVertexColor(1,1,1,.3)
    for i=1,8 do
        local a=Frame(root); a.icon=a:CreateTexture(nil,"ARTWORK"); a.icon:SetAllPoints(a); a.icon:SetTexCoord(.08,.92,.08,.92)
        a.border=Frame(a); a.border:SetFrameLevel(math.max(0,a:GetFrameLevel()-1))
        a.border:SetPoint("TOPLEFT",a,"TOPLEFT",-1,1); a.border:SetPoint("BOTTOMRIGHT",a,"BOTTOMRIGHT",1,-1)
        a.border:SetBackdrop({edgeFile=textures.flat,edgeSize=1}); a.border:SetBackdropBorderColor(BORDER[1],BORDER[2],BORDER[3],1)
        a.count=Text(a,p.auraStackTextSize); a.count:SetPoint("BOTTOMRIGHT",a,"BOTTOMRIGHT",1,0)
        a.time=Text(a,p.auraDurationTextSize); a.time:SetPoint("CENTER",a,"CENTER",0,0)
        a:Hide(); s.auras[i]=a
    end
    plate:HookScript("OnHide",function() ClearUnit(s); s.root:Hide() end)
    plate:HookScript("OnShow",function() ClearUnit(s); if active then ns.Update() end end)
    native.health:HookScript("OnValueChanged",function() if active and plate:IsShown() then ns.UpdateHealth(s) end end)
    return s
end
local function Ratio(bar)
    local low,high=bar:GetMinMaxValues(); local value=bar:GetValue()
    if type(low)~="number" or type(high)~="number" or type(value)~="number" or high<=low then return 0 end
    return math.max(0,math.min(1,(value-low)/(high-low)))
end
local function Friendly(s)
    if s.unit and UnitReaction then local r=UnitReaction("player",s.unit); if r then return r>=5 end end
    local r,g,b=s.native.health:GetStatusBarColor()
    return r<.01 and ((g>.99 and b<.01) or (b>.99 and g<.01))
end
local function NativeFriendlyPlayer(s)
    local r,g,b=s.native.health:GetStatusBarColor()
    return r<.01 and g<.01 and b>.99
end
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
local function Threat(s)
    local n=s.native.threat
    if not n or not n:IsShown() then return end
    local r,g,b=n:GetVertexColor()
    if r and r>0 then if g and g>0 then return b and b>0 and 1 or 2 end; return 3 end
end
function ns.UpdateHealth(s)
    local p=ns.GetSettings(); if not p then return end
    local ratio=Ratio(s.native.health); s.health:SetValue(ratio)
    local r,g,b=Soften(s.native.health:GetStatusBarColor())
    local classColor=p.friendlyHealthClassColored and s.friendlyClass and RAID_CLASS_COLORS[s.friendlyClass]
    if classColor then r,g,b=classColor.r,classColor.g,classColor.b end
    local status=not Friendly(s) and Threat(s)
    if status and s.health:IsShown() then
        local ar,ag,ab=s.native.threat:GetVertexColor()
        s.aggro:SetBackdropBorderColor(ar,ag,ab,1); s.aggro:Show()
    else s.aggro:Hide() end
    local threat=p.threatColors and status
    if threat==3 then if p.tankMode then r,g,b=unpack(PALETTE.good) else r,g,b=unpack(PALETTE.bad) end
    elseif threat then r,g,b=unpack(PALETTE.transition) end
    s.health:SetStatusBarColor(r,g,b)
    s.healthText:SetText(p.showHealthText and string.format("%d%%",math.floor(ratio*100+.5)) or "")
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
local function CastInfo(s)
    if not s.unit or UnitGUID(s.unit)~=s.guid then return end
    local name,_,_,icon,startTime,endTime,_,_,locked=UnitCastingInfo(s.unit)
    local channel=false
    if not name then name,_,_,icon,startTime,endTime,_,locked=UnitChannelInfo(s.unit); channel=true end
    if not name or not startTime or not endTime or endTime<=startTime then return end
    local duration=(endTime-startTime)/1000; local left=math.max(0,endTime/1000-GetTime())
    if left<=0 then return end
    return name,icon,left,channel and left/duration or 1-left/duration,locked
end
local function UpdateCast(s,p)
    local name,icon,left,value,locked=CastInfo(s)
    local visible=p.showCastBar and (name or s.native.cast:IsShown()) and not (p.friendlyNameOnly and Friendly(s))
    if not visible then s.cast:Hide(); s.castIcon:Hide(); return end
    s.cast:Show(); s.cast:SetValue(value or Ratio(s.native.cast))
    local shield=s.native.shield and s.native.shield:IsShown()
    if locked or shield then s.cast:SetStatusBarColor(unpack(PALETTE.castLocked)) else s.cast:SetStatusBarColor(unpack(PALETTE.cast)) end
    s.castText:SetText(p.showCastName and name or "")
    s.castTimer:SetText(p.showCastTimer and left and string.format("%.1f",left) or "")
    icon=icon or (s.native.icon and s.native.icon:GetTexture())
    if icon then s.castIcon.tex:SetTexture(icon); s.castIcon:Show() else s.castIcon:Hide() end
end
local function UpdateAuras(s,p)
    for _,a in ipairs(s.auras) do a:Hide() end
    if not p.showAuras or (p.friendlyNameOnly and Friendly(s)) then return end
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
    local count=0
    local limit=math.max(1,math.min(#s.auras,tonumber(p.maxAuras) or 6))
    local function Add(filter)
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
            local prefix=filter=="HARMFUL" and "debuff" or "buff"
            local include=filter~="HARMFUL" or not p.onlyPlayerDebuffs or mine
            if E.WrathAuraFilters then include=E.WrathAuraFilters.Allow(p,prefix,spellID,mine,duration,stealable) end
            if include then
                count=count+1; if count>limit then return end
                local a=s.auras[count]; a.icon:SetTexture(icon)
                a.count:SetText(stacks and stacks>1 and stacks or "")
                local left=expires and expires>0 and expires-GetTime()
                a.time:SetText(left and left>0 and tostring(math.ceil(left)) or "")
                a:Show()
            end
        end
    end
    if p.showDebuffs then Add("HARMFUL") end
    if p.showBuffs and count<limit then Add("HELPFUL") end
end
local function Layout(s,p)
    local root=s.root
    if s.layoutVersion~=layoutVersion then
    s.layoutVersion=layoutVersion; s.auraDirty=true
    root:ClearAllPoints(); root:SetPoint("CENTER",s.plate,"CENTER",0,p.yOffset)
    Size(root,p.width,p.height)
    Size(s.cast,p.width,p.castHeight)
    local iconSize=p.height+p.castHeight+4; Size(s.castIcon,iconSize,iconSize)
    s.castSpark:SetHeight(p.castHeight*2)
    s.name:SetHeight(p.nameSize+3); s.nameKey=nil
    s.castText:SetWidth(math.max(20,p.width-35))
    s.health:SetStatusBarTexture(textures[p.healthBarTexture] or textures.flat)
    s.cast:SetStatusBarTexture(textures[p.castBarTexture] or textures.flat)
    Border(s.health.border,p); Border(s.cast.border,p); Border(s.castIcon.border,p)
    do
        local n=math.max(0,math.min(4,p.borderSize or 1))
        s.glowInner:ClearAllPoints(); s.glowOuter:ClearAllPoints()
        s.glowInner:SetPoint("TOPLEFT",s.health,"TOPLEFT",-(n+1),n+1); s.glowInner:SetPoint("BOTTOMRIGHT",s.health,"BOTTOMRIGHT",n+1,-(n+1))
        s.glowOuter:SetPoint("TOPLEFT",s.health,"TOPLEFT",-(n+3),n+3); s.glowOuter:SetPoint("BOTTOMRIGHT",s.health,"BOTTOMRIGHT",n+3,-(n+3))
        s.glowInner:SetBackdrop({edgeFile=textures.flat,edgeSize=1}); s.glowOuter:SetBackdrop({edgeFile=textures.flat,edgeSize=2})
    end
    Font(s.name,p.nameSize); Font(s.healthText,p.healthTextSize); Font(s.level,p.levelSize)
    Font(s.castText,p.castNameSize); Font(s.castTimer,p.castTimerSize)
    for i,a in ipairs(s.auras) do
        Size(a,p.auraSize,p.auraSize); a:ClearAllPoints()
        a:SetPoint("BOTTOMLEFT",s.name,"TOPLEFT",(i-1)*(p.auraSize+4)+1,4)
        Font(a.count,p.auraStackTextSize); Font(a.time,p.auraDurationTextSize)
    end
    end
    root:SetScale(s.isTarget and p.targetScale or 1)
    root:SetAlpha(p.opacity/100*(UnitExists("target") and not s.isTarget and p.nonTargetAlpha/100 or 1))
    s.name:SetText(s.native.name:GetText() or "")
    local r,g,b=s.native.name:GetTextColor()
    if p.classColoredNames and s.friendlyClass then
        local color=RAID_CLASS_COLORS[s.friendlyClass]; if color then r,g,b=color.r,color.g,color.b end
    elseif p.classColoredNames and s.unit and UnitIsPlayer(s.unit) then
        local color=RAID_CLASS_COLORS[select(2,UnitClass(s.unit))]; if color then r,g,b=color.r,color.g,color.b end
    end
    s.name:SetTextColor(r,g,b)
    local level=s.native.level:GetText() or "??"
    s.level:SetTextColor(s.native.level:GetTextColor())
    if s.native.boss and s.native.boss:IsShown() then level="??"
    elseif s.native.elite and s.native.elite:IsShown() then level=level.."+" end
    s.level:SetText(p.showLevel and level or "")
    local nameOnly=p.friendlyNameOnly and Friendly(s)
    if nameOnly then s.health:Hide(); s.level:Hide() else s.health:Show(); s.level:Show() end
    local nameKey=nameOnly and "N" or (p.showLevel and math.floor((s.level:GetStringWidth() or 0)+.5) or 0)
    if s.nameKey~=nameKey then
        s.nameKey=nameKey
        s.name:ClearAllPoints()
        if nameOnly then
            s.name:SetPoint("BOTTOM",s.health,"TOP",0,3); s.name:SetJustifyH("CENTER"); s.name:SetWidth(p.width)
        else
            s.name:SetPoint("BOTTOMLEFT",s.health,"TOPLEFT",0,3); s.name:SetJustifyH("LEFT")
            s.name:SetWidth(math.max(20,p.width-(nameKey>0 and nameKey+6 or 0)))
        end
    end
    if s.isTarget and p.showTargetBorder and not nameOnly then
        s.glowInner:SetBackdropBorderColor(PALETTE.glow[1],PALETTE.glow[2],PALETTE.glow[3],.95)
        s.glowOuter:SetBackdropBorderColor(PALETTE.glow[1],PALETTE.glow[2],PALETTE.glow[3],.35)
        s.glowInner:Show(); s.glowOuter:Show()
    else s.glowInner:Hide(); s.glowOuter:Hide() end
    if p.showRaidMarker and s.native.raid and s.native.raid:IsShown() then
        Size(s.raid,p.raidMarkerSize,p.raidMarkerSize); s.raid:SetTexture(s.native.raid:GetTexture())
        s.raid:SetTexCoord(s.native.raid:GetTexCoord()); s.raid:Show()
    else s.raid:Hide() end
    if not nameOnly and s.native.highlight and s.native.highlight:IsShown() then s.hover:Show() else s.hover:Hide() end
    HideNative(s); root:Show()
end
function ns.Scan()
    if not active then return end
    for _,plate in ipairs({WorldFrame:GetChildren()}) do
        if not states[plate] then local native=ns.FindNativeParts(plate); if native then Capture(plate,native) end end
    end
end
function ns.Update()
    local p=ns.GetSettings(); if not active or not p then return end
    BindUnits()
    ResolveFriendlyClasses()
    for plate,s in pairs(states) do
        if plate:IsShown() then
            Layout(s,p); ns.UpdateHealth(s); UpdateCast(s,p)
            if s.auraDirty or not s.auraTime or GetTime()-s.auraTime>=.15 then
                s.auraDirty=false; s.auraTime=GetTime(); UpdateAuras(s,p)
            end
        else s.root:Hide() end
    end
end
function ns.Restore()
    active=false
    for _,s in pairs(states) do
        ClearUnit(s); s.root:Hide()
        for region,alpha in pairs(s.originalAlpha) do region:SetAlpha(alpha) end
        s.native.threat:SetTexture(s.originalThreatTexture)
    end
    if castCVarOriginal~=nil then SetCVar("showVKeyCastbar",castCVarOriginal); castCVarOriginal=nil end
end
function ns.SetNativeCVar(key,value)
    if key~="nameplateShowEnemies" and key~="nameplateShowFriends" and key~="nameplateAllowOverlap" and key~="ShowClassColorInNameplate" then return end
    if InCombatLockdown() then pendingCVars=pendingCVars or {}; pendingCVars[key]=value and "1" or "0"; return end
    SetCVar(key,value and "1" or "0")
end
function ns.Apply()
    local p=ns.GetSettings(); if not p then return end
    if InCombatLockdown() then pending=true; return end
    pending=false
    if not p.enabled then ns.Restore(); return end
    if castCVarOriginal==nil then castCVarOriginal=GetCVar("showVKeyCastbar") end
    SetCVar("showVKeyCastbar","1")
    active=true; layoutVersion=layoutVersion+1; ns.Scan(); ns.Update()
end
ns.RefreshAllSettings=ns.Apply
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
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","UNIT_AURA","PARTY_MEMBERS_CHANGED","RAID_ROSTER_UPDATE"}) do f:RegisterEvent(event) end
    f:SetScript("OnEvent",function(_,event)
        if event=="PLAYER_REGEN_ENABLED" then
            for key,value in pairs(pendingCVars or {}) do SetCVar(key,value) end; pendingCVars=nil
            if pending then ns.Apply() end
        elseif event=="PLAYER_ENTERING_WORLD" then observedClasses={}; ns.RefreshFriendlyRoster(); ns.Apply()
        elseif event=="PARTY_MEMBERS_CHANGED" or event=="RAID_ROSTER_UPDATE" then ns.RefreshFriendlyRoster(); ns.Update()
        else ns.Update() end
    end)
    f:SetScript("OnUpdate",function(_,dt)
        if not active then return end
        elapsed,scanElapsed=elapsed+dt,scanElapsed+dt
        if scanElapsed>=.25 then scanElapsed=0; ns.Scan() end
        if elapsed>=.05 then elapsed=0; ns.Update() end
    end)
end
