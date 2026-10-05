-- Retail EllesmereUI nameplate look, painted over the native Wrath plate.
-- Data and identity come from EUI_Nameplates_335.lua.
local _,ns=...
local E=EllesmereUI
if not E or not ns or not ns.addon then return end
local MEDIA="Interface\\AddOns\\EllesmereUINameplates\\Media_335\\"
local FLAT="Interface\\Buttons\\WHITE8X8"
local SPARK="Interface\\AddOns\\EllesmereUI\\media\\cast_spark.tga"
local textures={flat=FLAT,blizzard="Interface\\TargetingFrame\\UI-StatusBar"}
ns.textureValues,ns.textureOrder={flat="Flat",blizzard="Blizzard"},{"flat","blizzard"}
ns.TARGET_TEXTURES={none="None",["striped-v2"]="Striped",["striped-wide-v2"]="Striped Wide",["striped-tiny"]="Striped Tiny",
    ["stripes-medium"]="Stripes Medium",["stripes-small-close"]="Stripes Small Close",["stripes-small-spread"]="Stripes Small Spread"}
ns.TARGET_TEXTURE_ORDER={"none","striped-v2","striped-wide-v2","striped-tiny","stripes-medium","stripes-small-close","stripes-small-spread"}
-- Drawn width at height 16 (scale 1), as in Retail.
ns.TARGET_ARROW_STYLES={
    simple={l="arrow_left",r="arrow_right",w=11,label="Simple Arrows"},
    double={l="arrow_leftx2",r="arrow_rightx2",w=22,label="Double Arrows"},
    barbed={l="barbed-left",r="barbed-right",w=28,label="Barbed"},
    bracket={l="bracket-left",r="bracket-right",w=22,label="Bracket"},
    celestial={l="celestial-left",r="celestial-right",w=28,label="Celestial"},
    classic={l="classic-left",r="classic-right",w=22,label="Classic"},
    crystal={l="crystal-left",r="crystal-right",w=22,label="Crystal"},
    curved={l="curved-left",r="curved-right",w=22,label="Curved"},
    demon={l="demon-left",r="demon-right",w=28,label="Demon"},
    diamond={l="diamond-left",r="diamond-right",w=28,label="Diamond"},
    feathered={l="feathered-left",r="feathered-right",w=22,label="Feathered"},
    halo={l="halo-left",r="halo-right",w=22,label="Halo"},
    holyspear={l="holy-spear-left",r="holy-spear-right",w=28,label="Holy Spear"},
    rune={l="rune-left",r="rune-right",w=22,label="Rune"},
    split={l="split-left",r="split-right",w=22,label="Split"},
    winged={l="winged-left",r="winged-right",w=28,label="Winged"},
}
ns.TARGET_ARROW_ORDER={"simple","double","winged","feathered","split","celestial","rune","demon",
    "halo","curved","barbed","holyspear","bracket","diamond","crystal","classic"}
local GLOW_MARGIN,GLOW_CORNER,GLOW_EXTEND=.48,12,6
local function PlayerClass() return select(2,UnitClass("player")) end

local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function RGB(c) return c.r,c.g,c.b end
local function Font(fs,size)
    local flags=E.GetFontOutlineFlag and E.GetFontOutlineFlag("nameplates") or ""
    fs:SetFont(E.GetFontPath("nameplates"),size,(flags:gsub(",?%s*SLUG","")))
end
local function Text(parent,size)
    local fs=parent:CreateFontString(nil,"OVERLAY"); Font(fs,size); fs:SetTextColor(1,1,1); fs:SetWordWrap(false)
    return fs
end
local function Frame(parent)
    local f=CreateFrame("Frame",nil,parent); f:EnableMouse(false); return f
end
local function Tex(parent,layer,path)
    local t=parent:CreateTexture(nil,layer or "ARTWORK"); t:SetTexture(path or FLAT); return t
end
local function Bar(parent)
    local f=CreateFrame("StatusBar",nil,parent); f:EnableMouse(false)
    f:SetStatusBarTexture(FLAT); f:SetMinMaxValues(0,1)
    return f
end
-- Inset pixel border made of four edges, so it never resizes the owner.
local function Edges(owner)
    local f=Frame(owner); f:SetAllPoints(owner); f:SetFrameLevel(owner:GetFrameLevel()+1)
    f.t,f.b,f.l,f.r=Tex(f,"OVERLAY"),Tex(f,"OVERLAY"),Tex(f,"OVERLAY"),Tex(f,"OVERLAY")
    f.t:SetPoint("TOPLEFT",owner,"TOPLEFT"); f.t:SetPoint("TOPRIGHT",owner,"TOPRIGHT")
    f.b:SetPoint("BOTTOMLEFT",owner,"BOTTOMLEFT"); f.b:SetPoint("BOTTOMRIGHT",owner,"BOTTOMRIGHT")
    f.l:SetPoint("TOPLEFT",owner,"TOPLEFT"); f.l:SetPoint("BOTTOMLEFT",owner,"BOTTOMLEFT")
    f.r:SetPoint("TOPRIGHT",owner,"TOPRIGHT"); f.r:SetPoint("BOTTOMRIGHT",owner,"BOTTOMRIGHT")
    return f
end
local function SizeEdges(f,n)
    n=math.max(0,math.min(4,n or 1))
    f.size=n
    -- The frame also hosts cast text, timer, shield and kick tick; only the edges hide.
    for _,t in ipairs({f.t,f.b,f.l,f.r}) do if n==0 then t:Hide() else t:Show() end end
    if n==0 then return end
    f.t:SetHeight(n); f.b:SetHeight(n); f.l:SetWidth(n); f.r:SetWidth(n)
end
local function ColorEdges(f,r,g,b,a)
    if f.cr==r and f.cg==g and f.cb==b and f.ca==a then return end
    f.cr,f.cg,f.cb,f.ca=r,g,b,a
    for _,t in ipairs({f.t,f.b,f.l,f.r}) do t:SetVertexColor(r,g,b,a or 1) end
end
local function NineSlice(parent,path)
    local f=Frame(parent); f.pieces={}
    local m,c=GLOW_MARGIN,GLOW_CORNER
    local function Piece(l,r,t,b)
        local tx=Tex(f,"BACKGROUND",path); tx:SetBlendMode("ADD"); tx:SetTexCoord(l,r,t,b)
        f.pieces[#f.pieces+1]=tx; return tx
    end
    local tl=Piece(0,m,0,m); Size(tl,c,c); tl:SetPoint("TOPLEFT")
    local tr=Piece(1-m,1,0,m); Size(tr,c,c); tr:SetPoint("TOPRIGHT")
    local bl=Piece(0,m,1-m,1); Size(bl,c,c); bl:SetPoint("BOTTOMLEFT")
    local br=Piece(1-m,1,1-m,1); Size(br,c,c); br:SetPoint("BOTTOMRIGHT")
    local top=Piece(m,1-m,0,m); top:SetHeight(c); top:SetPoint("TOPLEFT",tl,"TOPRIGHT"); top:SetPoint("TOPRIGHT",tr,"TOPLEFT")
    local bot=Piece(m,1-m,1-m,1); bot:SetHeight(c); bot:SetPoint("BOTTOMLEFT",bl,"BOTTOMRIGHT"); bot:SetPoint("BOTTOMRIGHT",br,"BOTTOMLEFT")
    local lft=Piece(0,m,m,1-m); lft:SetWidth(c); lft:SetPoint("TOPLEFT",tl,"BOTTOMLEFT"); lft:SetPoint("BOTTOMLEFT",bl,"TOPLEFT")
    local rgt=Piece(1-m,1,m,1-m); rgt:SetWidth(c); rgt:SetPoint("TOPRIGHT",tr,"BOTTOMRIGHT"); rgt:SetPoint("BOTTOMRIGHT",br,"TOPRIGHT")
    local ctr=Piece(m,1-m,m,1-m); ctr:SetPoint("TOPLEFT",lft,"TOPRIGHT"); ctr:SetPoint("BOTTOMRIGHT",rgt,"BOTTOMLEFT")
    f:Hide()
    return f
end
local function TintSlice(f,r,g,b,a)
    for _,t in ipairs(f.pieces) do t:SetVertexColor(r,g,b,a or 1) end
    f.r,f.g,f.b,f.a=r,g,b,a
end
local function Aura(parent)
    local a=Frame(parent)
    a.icon=Tex(a,"ARTWORK"); a.icon:SetAllPoints(a); a.icon:SetTexCoord(.08,.92,.08,.92)
    a.border=Edges(a); SizeEdges(a.border,1); ColorEdges(a.border,0,0,0,1)
    a.count=Text(a.border,10); a.count:SetPoint("BOTTOMRIGHT",a,"BOTTOMRIGHT",1,0)
    a.time=Text(a.border,10)
    a:Hide()
    return a
end

function ns.Capture(plate,native)
    local p=ns.GetSettings()
    local s={native=native,plate=plate,originalAlpha={},auras={},buffs={},pips={},debuffList={},buffList={},
        originalThreatTexture=native.threat:GetTexture()}
    for _,region in pairs(native) do
        if region.GetAlpha and region.SetAlpha then s.originalAlpha[region]=region:GetAlpha() end
    end
    local root=Frame(plate); root:SetPoint("CENTER",plate,"CENTER",0,0)
    Size(root,p.width,p.height); root:SetFrameLevel(plate:GetFrameLevel()+4); s.root=root
    local base=root:GetFrameLevel()
    s.glow=NineSlice(root,MEDIA.."background.tga"); s.glow:SetFrameLevel(base)
    s.exec=NineSlice(root,MEDIA.."execute-glow.tga"); s.exec:SetFrameLevel(base)
    s.health=Bar(root); s.health:SetAllPoints(root); s.health:SetFrameLevel(base+2)
    s.healthBg=Tex(s.health,"BACKGROUND"); s.healthBg:SetAllPoints(s.health)
    s.targetTex=Tex(s.health,"OVERLAY")
    s.targetTex:SetPoint("TOPLEFT",s.health,"TOPLEFT"); s.targetTex:SetPoint("BOTTOMRIGHT",s.health:GetStatusBarTexture(),"BOTTOMRIGHT")
    s.highlight=Tex(s.health,"OVERLAY"); s.highlight:SetAllPoints(s.health); s.highlight:SetVertexColor(1,1,1,.2)
    s.hover=Tex(s.health,"OVERLAY"); s.hover:SetAllPoints(s.health); s.hover:SetVertexColor(1,1,1,.3)
    s.hash=Tex(s.health,"OVERLAY"); s.hash:SetWidth(2)
    s.border=Edges(s.health)
    s.textHost=Frame(root); s.textHost:SetAllPoints(root); s.textHost:SetFrameLevel(base+6)
    s.name=Text(s.textHost,p.nameSize); s.level=Text(s.textHost,p.levelSize); s.healthText=Text(s.textHost,p.healthTextSize)
    s.arrowL,s.arrowR=Tex(s.textHost,"OVERLAY"),Tex(s.textHost,"OVERLAY")
    s.raid,s.class=Tex(s.textHost,"OVERLAY"),Tex(s.textHost,"OVERLAY")
    s.cast=Bar(root); s.cast:SetFrameLevel(base+2)
    s.castBg=Tex(s.cast,"BACKGROUND"); s.castBg:SetAllPoints(s.cast)
    s.castBorder=Edges(s.cast)
    s.castSpark=Tex(s.cast,"OVERLAY",SPARK); s.castSpark:SetBlendMode("ADD")
    s.castSpark:SetPoint("CENTER",s.cast:GetStatusBarTexture(),"RIGHT",0,0)
    s.castShield=Tex(s.castBorder,"OVERLAY",MEDIA.."shield.tga")
    s.kickTick=Tex(s.castBorder,"OVERLAY")
    s.castText=Text(s.castBorder,p.castNameSize); s.castText:SetJustifyH("LEFT")
    s.castTimer=Text(s.castBorder,p.castTimerSize); s.castTimer:SetPoint("RIGHT",s.cast,"RIGHT",-4,0)
    s.castIcon=Frame(root); s.castIcon:SetFrameLevel(base+2)
    s.castIcon.tex=Tex(s.castIcon,"ARTWORK"); s.castIcon.tex:SetAllPoints(s.castIcon); s.castIcon.tex:SetTexCoord(.08,.92,.08,.92)
    s.castIconBorder=Edges(s.castIcon); SizeEdges(s.castIconBorder,1); ColorEdges(s.castIconBorder,0,0,0,1)
    for i=1,5 do s.pips[i]=Tex(s.textHost,"OVERLAY") end
    for i=1,ns.MAX_DEBUFFS do s.auras[i]=Aura(root) end
    for i=1,ns.MAX_BUFFS do s.buffs[i]=Aura(root) end
    -- The options header caches the preview by hiding it; it must repaint, not reset, on return.
    plate:HookScript("OnHide",function() if s.isPreview then return end; ns.ClearUnit(s); s.root:Hide() end)
    plate:HookScript("OnShow",function()
        if s.isPreview then if ns.onPreviewShown then ns.onPreviewShown() else ns.PaintPreview() end; return end
        ns.ClearUnit(s); if ns.IsActive() then ns.Update() end
    end)
    native.health:HookScript("OnValueChanged",function() if plate:IsShown() then ns.UpdateHealth(s) end end)
    return s
end

local function InInstance()
    if not IsInInstance then return false end
    local inside,kind=IsInInstance()
    return inside and (kind=="party" or kind=="raid") or false
end
-- Retail priority: tapped > threat > target color > neutral > enemy player
-- class > boss > elite (instances) > enemy. Friendly bars use their palette.
function ns.HealthColor(s,p)
    s.threatBorder,s.threatName=nil,nil
    local kind=ns.NativeKind(s)
    if kind=="tapped" then return RGB(p.tapped) end
    if ns.Friendly(s) then
        local cc=p.friendlyHealthClassColored and s.friendlyClass and RAID_CLASS_COLORS[s.friendlyClass]
        if cc then return cc.r,cc.g,cc.b end
        if kind=="friendlyPlayer" then return RGB(p.friendlyBarColor) end
        if kind=="friendlyNPC" then return RGB(p.friendlyNPCColor) end
        return s.native.health:GetStatusBarColor()
    end
    local threat=ns.ThreatColor(s,p)
    if threat then
        if p.threatColorBorder then s.threatBorder=threat end
        if p.threatColorName then s.threatName=threat end
        if p.threatColorHealth then return RGB(threat) end
    end
    if s.isTarget and p.enableTargetColor then return RGB(p.targetColor) end
    if kind=="neutral" then return RGB(p.neutral) end
    if kind=="class" then return s.native.health:GetStatusBarColor() end
    if p.colorBosses and s.native.boss and s.native.boss:IsShown() then return RGB(p.boss) end
    if p.colorElitesInInstances and s.native.elite and s.native.elite:IsShown() and InInstance() then return RGB(p.miniboss) end
    return RGB(p.enemyInCombat)
end
function ns.PaintHealth(s,p)
    local ratio=ns.Ratio(s.native.health); s.health:SetValue(ratio)
    s.health:SetStatusBarColor(ns.HealthColor(s,p))
    local bc=s.threatBorder or (s.isTarget and p.targetEffect=="border" and p.targetBorderColor) or p.borderColor
    ColorEdges(s.border,bc.r,bc.g,bc.b,1)
    s.healthText:SetText(s.healthText.slot and p.showHealthText and string.format("%d%%",math.floor(ratio*100+.5)) or "")
    if s.isTarget and p.targetTexture and p.targetTexture~="none" and ns.TARGET_TEXTURES[p.targetTexture] and ratio>0 then
        s.targetTex:SetTexture(MEDIA..p.targetTexture..".tga")
        -- Source art is 512 px wide; keep the stripe density constant.
        s.targetTex:SetTexCoord(0,math.min(1,p.width*ratio/512),0,1); s.targetTex:Show()
    else s.targetTex:Hide() end
    local threshold=ns.executeThreshold
    s.execActive=p.executeGlow and threshold and not s.nameOnly and not ns.Friendly(s) and ratio>0 and ratio<=threshold or false
    if s.execActive then
        local pulse=.35+.65*(.5+.5*math.cos(GetTime()*math.pi*2/1.1))
        TintSlice(s.exec,1,0,0,pulse); s.exec:Show()
    else s.exec:Hide() end
    if p.hashLineEnabled and s.isTarget and not s.nameOnly then
        local x=math.floor(p.width*(p.hashLinePercent or 30)/100+.5)
        s.hash:ClearAllPoints()
        s.hash:SetPoint("TOPLEFT",s.health,"TOPLEFT",x-1,0); s.hash:SetPoint("BOTTOMLEFT",s.health,"BOTTOMLEFT",x-1,0)
        s.hash:SetVertexColor(RGB(p.hashLineColor)); s.hash:Show()
    else s.hash:Hide() end
end

local TEXT_SLOTS={"Top","Left","Right","Center"}
local function PlaceText(s,p,nameOnly)
    local strings={name=s.name,healthPercent=s.healthText,level=s.level}
    for _,fs in pairs(strings) do fs:ClearAllPoints(); fs.slot=nil end
    s.topText=nil
    if nameOnly then
        s.name:SetPoint("BOTTOM",s.health,"TOP",0,p.nameYOffset); s.name:SetJustifyH("CENTER"); s.name:SetWidth(p.width+40)
        s.name.slot,s.topText="top",s.name
        return
    end
    for _,slot in ipairs(TEXT_SLOTS) do
        local fs=strings[p["textSlot"..slot]]
        if fs and not fs.slot then
            fs.slot=slot:lower()
            if slot=="Top" then
                fs:SetPoint("BOTTOM",s.health,"TOP",0,p.nameYOffset); fs:SetJustifyH("CENTER"); fs:SetWidth(p.width); s.topText=fs
            elseif slot=="Left" then
                fs:SetPoint("LEFT",s.health,"LEFT",4,0); fs:SetJustifyH("LEFT"); fs:SetWidth(math.floor(p.width*.6))
            elseif slot=="Right" then
                fs:SetPoint("RIGHT",s.health,"RIGHT",-2,0); fs:SetJustifyH("RIGHT"); fs:SetWidth(math.floor(p.width*.6))
            else
                fs:SetPoint("CENTER",s.health,"CENTER",0,0); fs:SetJustifyH("CENTER"); fs:SetWidth(p.width)
            end
        end
    end
end
local function PlaceSlot(tex,s,slot,size)
    tex:ClearAllPoints(); Size(tex,size,size)
    if slot=="top" then tex:SetPoint("BOTTOM",s.topText or s.health,"TOP",0,2)
    elseif slot=="left" then tex:SetPoint("RIGHT",s.health,"LEFT",-2,0)
    elseif slot=="right" then tex:SetPoint("LEFT",s.health,"RIGHT",2,0)
    elseif slot=="topleft" then tex:SetPoint("BOTTOMLEFT",s.health,"TOPLEFT",0,2)
    elseif slot=="topright" then tex:SetPoint("BOTTOMRIGHT",s.health,"TOPRIGHT",0,2)
    elseif slot=="bottom" then tex:SetPoint("TOP",s.cast,"BOTTOM",0,-2)
    else return false end
    return true
end
local function Layout(s,p,nameOnly)
    local key=ns.layoutVersion..(nameOnly and "N" or "")
    if s.layoutKey==key then return end
    s.layoutKey,s.auraKey,s.pipKey=key,nil,nil
    local root=s.root
    root:ClearAllPoints(); root:SetPoint("CENTER",s.plate,"CENTER",0,p.yOffset)
    Size(root,p.width,p.height)
    s.health:SetStatusBarTexture(textures[p.healthBarTexture] or FLAT)
    s.healthBg:SetVertexColor(p.bgColor.r,p.bgColor.g,p.bgColor.b,p.bgAlpha)
    SizeEdges(s.border,p.showBorder~=false and p.borderSize or 0); s.border.cr=nil
    for _,glow in ipairs({s.glow,s.exec}) do
        glow:ClearAllPoints()
        glow:SetPoint("TOPLEFT",s.health,"TOPLEFT",-GLOW_EXTEND,GLOW_EXTEND)
        glow:SetPoint("BOTTOMRIGHT",s.health,"BOTTOMRIGHT",GLOW_EXTEND,-GLOW_EXTEND)
    end
    Font(s.name,nameOnly and p.friendlyNameSize or p.nameSize); Font(s.healthText,p.healthTextSize); Font(s.level,p.levelSize)
    PlaceText(s,p,nameOnly)
    s.cast:ClearAllPoints(); s.cast:SetPoint("TOPLEFT",s.health,"BOTTOMLEFT",0,p.castBarOffsetY or 0)
    Size(s.cast,p.width,p.castHeight)
    s.cast:SetStatusBarTexture(textures[p.castBarTexture] or FLAT)
    s.castBg:SetVertexColor(p.castBgColor.r,p.castBgColor.g,p.castBgColor.b,p.castBgAlpha)
    SizeEdges(s.castBorder,p.showBorder~=false and p.borderSize or 0); ColorEdges(s.castBorder,p.borderColor.r,p.borderColor.g,p.borderColor.b,1)
    Size(s.castSpark,8,p.castHeight)
    local shield=math.floor(p.castHeight*.75+.5)
    Size(s.castShield,shield,shield); s.castShield:ClearAllPoints(); s.castShield:SetPoint("LEFT",s.cast,"LEFT",2,0)
    s.castText:ClearAllPoints(); s.castText:SetPoint("LEFT",s.cast,"LEFT",4,0); s.castText:SetWidth(math.max(20,p.width-40))
    Font(s.castText,p.castNameSize); Font(s.castTimer,p.castTimerSize)
    Size(s.kickTick,2,p.castHeight); s.kickTick:SetVertexColor(RGB(p.kickTickColor))
    Size(s.castIcon,p.castHeight,p.castHeight); s.castIcon:ClearAllPoints()
    if p.castIconPosition=="right" then s.castIcon:SetPoint("TOPLEFT",s.cast,"TOPRIGHT",0,0)
    else s.castIcon:SetPoint("TOPRIGHT",s.cast,"TOPLEFT",0,0) end
    local style=ns.TARGET_ARROW_STYLES[p.targetArrowStyle] or ns.TARGET_ARROW_STYLES.simple
    local scale=p.targetArrowScale or 1
    s.arrowW=math.floor(style.w*scale+.5)
    Size(s.arrowL,s.arrowW,math.floor(16*scale+.5)); Size(s.arrowR,s.arrowW,math.floor(16*scale+.5))
    s.arrowL:SetTexture(MEDIA.."Arrows\\"..style.l..".tga"); s.arrowR:SetTexture(MEDIA.."Arrows\\"..style.r..".tga")
    s.raidPlaced=PlaceSlot(s.raid,s,p.raidMarkerSlot,p.raidMarkerSize)
    s.classPlaced=PlaceSlot(s.class,s,p.classificationSlot,p.classificationSize)
    for _,a in ipairs(s.auras) do
        Size(a,p.auraSize,p.auraSize); Font(a.count,p.auraStackTextSize); Font(a.time,p.auraDurationTextSize)
    end
    for _,a in ipairs(s.buffs) do
        Size(a,p.buffSize,p.buffSize); Font(a.count,p.auraStackTextSize); Font(a.time,p.auraDurationTextSize)
    end
    for _,pool in ipairs({s.auras,s.buffs}) do
        for _,a in ipairs(pool) do
            a.time:ClearAllPoints()
            if p.auraTimerPosition=="center" then a.time:SetPoint("CENTER",a,"CENTER",0,0)
            else a.time:SetPoint("TOPLEFT",a,"TOPLEFT",-1,1) end
        end
    end
end

local function PaintCast(s,p)
    local name,icon,left,value,locked,duration,channel=ns.CastInfo(s)
    local flashing=s.flashUntil and s.flashUntil>GetTime() and not name
    local visible=p.showCastBar and not s.nameOnly and (name or s.native.cast:IsShown() or flashing)
    s.castVisible=visible and not flashing and true or false
    if not visible then s.cast:Hide(); s.castIcon:Hide(); return end
    s.cast:Show()
    icon=icon or (s.native.icon and s.native.icon:GetTexture()) or s.lastCastIcon
    s.lastCastIcon=icon
    if icon and p.castIconPosition~="none" then s.castIcon.tex:SetTexture(icon); s.castIcon:Show() else s.castIcon:Hide() end
    if flashing then
        s.cast:SetValue(1); s.cast:SetStatusBarColor(RGB(p.interruptedColor))
        s.castText:SetText(p.showCastName and (INTERRUPTED or "Interrupted") or ""); s.castTimer:SetText("")
        s.castSpark:Hide(); s.castShield:Hide(); s.kickTick:Hide()
        return
    end
    value=value or ns.Ratio(s.native.cast)
    s.cast:SetValue(value)
    local uninterruptible=locked or (s.native.shield and s.native.shield:IsShown()) or false
    s.uninterruptible=uninterruptible
    if uninterruptible then s.cast:SetStatusBarColor(RGB(p.castBarUninterruptible))
    elseif p.castBarKickTint and E.ComputeCastBarTint then s.cast:SetStatusBarColor(E.ComputeCastBarTint(p.interruptReady,p.castBarColor))
    else s.cast:SetStatusBarColor(RGB(p.castBarColor)) end
    if uninterruptible and p.castBarShieldEnabled then s.castShield:Show() else s.castShield:Hide() end
    if p.castBarSparkEnabled and value>0 and value<1 then s.castSpark:Show() else s.castSpark:Hide() end
    -- Kick tick: where the bar will be when the interrupt comes off cooldown.
    local remaining=p.kickTickEnabled and name and not uninterruptible and E.GetKickCooldownRemaining and E.GetKickCooldownRemaining()
    if remaining and remaining>0 and remaining<left and duration and duration>0 then
        local at=(left-remaining)/duration
        if not channel then at=1-at end
        s.kickTick:ClearAllPoints(); s.kickTick:SetPoint("CENTER",s.cast,"LEFT",math.floor(at*p.width+.5),0); s.kickTick:Show()
    else s.kickTick:Hide() end
    s.castText:ClearAllPoints()
    s.castText:SetPoint("LEFT",s.cast,"LEFT",s.castShield:IsShown() and math.floor(p.castHeight*.75+.5)+4 or 4,0)
    s.castText:SetText(p.showCastName and name or "")
    s.castTimer:SetText(p.showCastTimer and left and string.format("%.1f",left) or "")
end

local function PaintText(s,p,friendly)
    local r,g,b=s.native.name:GetTextColor()
    local class=s.friendlyClass or (s.unit and UnitIsPlayer(s.unit) and select(2,UnitClass(s.unit)))
    local color=(p.classColoredNames or (s.nameOnly and s.friendlyClass)) and class and RAID_CLASS_COLORS[class]
    if color then r,g,b=color.r,color.g,color.b end
    if s.threatName then r,g,b=RGB(s.threatName) end
    s.name:SetTextColor(r,g,b)
    local hideName=p.hideEnemyNameWhileCasting and s.castVisible and not friendly
    s.name:SetText(s.name.slot and not hideName and (s.native.name:GetText() or "") or "")
    local level=s.native.level:GetText() or "??"
    s.level:SetTextColor(s.native.level:GetTextColor())
    if s.native.boss and s.native.boss:IsShown() then level="??"
    elseif s.native.elite and s.native.elite:IsShown() then level=level.."+" end
    s.level:SetText(s.level.slot and p.showLevel and level or "")
    if s.nameOnly then s.health:Hide() else s.health:Show() end
end

local function ArrowColor(p)
    local cc=p.targetArrowClassColor and RAID_CLASS_COLORS[PlayerClass()]
    if cc then return cc.r,cc.g,cc.b end
    return RGB(p.targetArrowColor)
end
local function PaintTarget(s,p,leftExtent,rightExtent)
    local target=s.isTarget and not s.nameOnly
    if target and p.targetEffect=="glow" then
        local c=p.targetGlowColor
        if s.glow.r~=c.r or s.glow.g~=c.g or s.glow.b~=c.b then TintSlice(s.glow,c.r,c.g,c.b,1) end
        s.glow:Show()
    else s.glow:Hide() end
    if target and p.targetEffect=="highlight" then s.highlight:Show() else s.highlight:Hide() end
    if target and p.showTargetArrows then
        s.arrowL:ClearAllPoints(); s.arrowR:ClearAllPoints()
        s.arrowL:SetPoint("RIGHT",s.health,"LEFT",-(leftExtent+8),0)
        s.arrowR:SetPoint("LEFT",s.health,"RIGHT",rightExtent+8,0)
        local r,g,b=ArrowColor(p)
        s.arrowL:SetVertexColor(r,g,b); s.arrowR:SetVertexColor(r,g,b)
        s.arrowL:Show(); s.arrowR:Show()
    else s.arrowL:Hide(); s.arrowR:Hide() end
    local hovered=s.native.highlight and s.native.highlight:IsShown()
    if not s.nameOnly and hovered and p.hoverEffect=="highlight" then s.hover:Show() else s.hover:Hide() end
    s.root:SetScale(s.isTarget and p.targetScale or 1)
    s.root:SetAlpha(p.opacity/100*(UnitExists("target") and not s.isTarget and p.nonTargetAlpha/100 or 1))
end

local function PaintIcons(s,p)
    if p.showRaidMarker and s.raidPlaced and s.native.raid and s.native.raid:IsShown() then
        s.raid:SetTexture(s.native.raid:GetTexture()); s.raid:SetTexCoord(s.native.raid:GetTexCoord()); s.raid:Show()
    else s.raid:Hide() end
    local boss=s.native.boss and s.native.boss:IsShown()
    if p.showClassification and s.classPlaced and boss and not s.nameOnly then
        s.class:SetTexture(s.native.boss:GetTexture()); s.class:SetTexCoord(s.native.boss:GetTexCoord()); s.class:Show()
    else s.class:Hide() end
end

local function FillAuras(pool,list,now)
    local shown=0
    for i,a in ipairs(pool) do
        local data=list[i]
        if data then
            shown=i
            a.icon:SetTexture(data.icon)
            a.count:SetText(data.stacks and data.stacks>1 and data.stacks or "")
            local left=data.expires and data.expires>0 and data.expires-now
            a.time:SetText(left and left>0 and (left>=60 and math.ceil(left/60).."m" or tostring(math.ceil(left))) or "")
            a:Show()
        else a:Hide() end
    end
    return shown
end
local function PlaceAuras(pool,n,s,p,slot,size,yOffset)
    local spacing,side=p.auraSpacing or 2,p.sideAuraXOffset or 2
    for i=1,n do
        local a,step=pool[i],(i-1)*(size+spacing)
        a:ClearAllPoints()
        if slot=="top" then
            local total=n*size+(n-1)*spacing
            a:SetPoint("BOTTOMLEFT",s.topText or s.health,"TOP",-total/2+step,yOffset)
        elseif slot=="left" then a:SetPoint("BOTTOMRIGHT",s.health,"BOTTOMLEFT",-(side+step),0)
        elseif slot=="right" then a:SetPoint("BOTTOMLEFT",s.health,"BOTTOMRIGHT",side+step,0)
        elseif slot=="topleft" then a:SetPoint("BOTTOMLEFT",s.health,"TOPLEFT",step,yOffset)
        elseif slot=="bottom" then
            local total=n*size+(n-1)*spacing
            a:SetPoint("TOPLEFT",s.cast,"BOTTOM",-total/2+step,-2)
        else a:SetPoint("BOTTOMRIGHT",s.health,"TOPRIGHT",-step,yOffset) end
    end
    if n==0 then return 0,0 end
    local extent=side+n*size+(n-1)*spacing
    return slot=="left" and extent or 0,slot=="right" and extent or 0
end
local function PaintAuras(s,p)
    local now=GetTime()
    local debuffs=FillAuras(s.auras,s.debuffList or {},now)
    local buffs=FillAuras(s.buffs,s.buffList or {},now)
    local key=debuffs..":"..buffs..":"..(s.topText and s.topText:GetText() and "t" or "")
    if s.auraKey~=key then
        s.auraKey=key
        local l1,r1=PlaceAuras(s.auras,debuffs,s,p,p.debuffSlot,p.auraSize,p.debuffYOffset or 2)
        local l2,r2=PlaceAuras(s.buffs,buffs,s,p,p.buffSlot,p.buffSize,p.debuffYOffset or 2)
        s.leftExtent,s.rightExtent=math.max(l1,l2),math.max(r1,r2)
    end
    return s.leftExtent or 0,s.rightExtent or 0
end

local function PaintClassPower(s,p)
    local class=PlayerClass()
    local show=p.showClassPower and s.isTarget and not s.nameOnly and (s.previewPoints or class=="ROGUE" or class=="DRUID")
    local points=show and (s.previewPoints or GetComboPoints and GetComboPoints("player","target")) or 0
    if not show or points==0 then for _,pip in ipairs(s.pips) do pip:Hide() end; return end
    local scale=p.classPowerScale or 1.8
    local w,h,gap=math.floor(8*scale+.5),math.floor(3*scale+.5),2
    local anchor=s.castVisible and s.cast or s.health
    local key=w..":"..h..":"..tostring(anchor)
    if s.pipKey~=key then
        s.pipKey=key
        local total=5*w+4*gap
        for i,pip in ipairs(s.pips) do
            Size(pip,w,h); pip:ClearAllPoints()
            pip:SetPoint("TOPLEFT",anchor,"BOTTOM",-total/2+(i-1)*(w+gap),-3)
        end
    end
    local cc=RAID_CLASS_COLORS[class] or {r=1,g=.96,b=.41}
    for i,pip in ipairs(s.pips) do
        if i<=points then pip:SetVertexColor(cc.r,cc.g,cc.b,1) else pip:SetVertexColor(.2,.2,.2,.6) end
        pip:Show()
    end
end

function ns.Paint(s,p)
    local friendly=ns.Friendly(s)
    s.nameOnly=p.friendlyNameOnly and friendly or false
    Layout(s,p,s.nameOnly)
    ns.PaintHealth(s,p)
    PaintCast(s,p)
    PaintText(s,p,friendly)
    PaintIcons(s,p)
    local leftExtent,rightExtent=PaintAuras(s,p)
    PaintTarget(s,p,leftExtent,rightExtent)
    PaintClassPower(s,p)
    ns.HideNative(s); s.root:Show()
end

-- Options preview: a hidden stand-in for the native plate, painted by the same
-- renderer. It is never added to ns.plates, so the live update loop ignores it.
local PREVIEW_DEBUFFS={"Interface\\Icons\\Spell_Shadow_ShadowWordPain","Interface\\Icons\\Spell_Shadow_AbominationExplosion",
    "Interface\\Icons\\Spell_Shadow_CurseOfSargeras","Interface\\Icons\\Spell_Nature_Slow"}
local PREVIEW_BUFFS={"Interface\\Icons\\Spell_Holy_PowerWordShield","Interface\\Icons\\Spell_Nature_Bloodlust"}
ns.previewHidden={}
function ns.CreatePreview(parent)
    local s=ns.preview
    if s then s.plate:SetParent(parent); s.plate:Show(); return s end
    local plate=CreateFrame("Frame",nil,parent); Size(plate,200,40)
    local function Region(kind)
        local r=kind=="font" and plate:CreateFontString(nil,"OVERLAY","GameFontNormalSmall") or plate:CreateTexture(nil,"ARTWORK")
        return r
    end
    local native={threat=Region(),border=Region(),castBorder=Region(),shield=Region(),icon=Region(),highlight=Region(),
        name=Region("font"),level=Region("font"),boss=Region(),raid=Region(),elite=Region()}
    native.threat:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash"); native.threat:Hide()
    native.shield:Hide(); native.highlight:Hide(); native.elite:Hide()
    native.icon:SetTexture("Interface\\Icons\\Spell_Fire_FlameBolt")
    native.name:SetText("Enemy Name Text"); native.name:SetTextColor(1,1,1)
    native.level:SetText("80"); native.level:SetTextColor(1,.82,0)
    native.boss:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    native.raid:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons"); native.raid:SetTexCoord(0,.25,0,.25)
    native.health=CreateFrame("StatusBar",nil,plate); native.health:SetMinMaxValues(0,100); native.health:SetValue(72)
    native.health:SetStatusBarColor(1,0,0)
    native.cast=CreateFrame("StatusBar",nil,plate); native.cast:SetMinMaxValues(0,1); native.cast:SetValue(.6)
    s=ns.Capture(plate,native); s.isPreview,s.previewPoints=true,3; ns.preview=s
    return s
end
local function Samples(paths,count,start)
    local list,now={},GetTime()
    for i=1,count do list[i]={icon=paths[(i-1)%#paths+1],stacks=i==1 and 3 or nil,expires=now+start+i*4} end
    return list
end
-- Returns the header height the preview needs.
function ns.PaintPreview()
    local s,p=ns.preview,ns.GetSettings()
    if not s or not p then return 0 end
    local hidden=ns.previewHidden
    s.isTarget,s.unit,s.guid,s.friendlyClass=true,nil,nil,nil
    s.layoutKey=nil
    s.debuffList=(p.showAuras and p.showDebuffs and p.debuffSlot~="none") and Samples(PREVIEW_DEBUFFS,math.min(2,p.maxAuras or 2),4) or {}
    s.buffList=(p.showAuras and p.showBuffs and p.buffSlot~="none") and Samples(PREVIEW_BUFFS,1,8) or {}
    s.previewCast=p.showCastBar and {"Spell Name","Interface\\Icons\\Spell_Fire_FlameBolt",2.3,.6,false,5,false} or nil
    if p.showCastBar then s.native.cast:Show() else s.native.cast:Hide() end
    if hidden.raidmarker then s.native.raid:Hide() else s.native.raid:Show() end
    if hidden.classification then s.native.boss:Hide() else s.native.boss:Show() end
    ns.Paint(s,p)
    -- The sample skull only demonstrates the icon slot; keep the bar and level of a normal enemy.
    if not hidden.classification then
        s.native.boss:Hide(); s.health:SetStatusBarColor(ns.HealthColor(s,p)); s.native.boss:Show()
        s.level:SetText(s.level.slot and p.showLevel and "80" or "")
    end
    local top=p.height/2+(p.nameYOffset or 4)+p.nameSize+((#s.debuffList>0 and p.debuffSlot=="top") and p.auraSize+(p.debuffYOffset or 2) or 0)
    local bottom=p.height/2+(p.showCastBar and p.castHeight-(p.castBarOffsetY or 0) or 0)
        +(p.showClassPower and math.floor(3*(p.classPowerScale or 1.8)+.5)+4 or 0)
    s.plate:ClearAllPoints(); s.plate:SetPoint("CENTER",s.plate:GetParent(),"TOP",0,-(top+12))
    return math.floor(top+bottom+26+.5)
end
