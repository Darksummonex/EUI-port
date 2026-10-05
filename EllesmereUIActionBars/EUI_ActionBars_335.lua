-- Native Wrath action bars. The Retail implementation remains an unloaded reference.
local ADDON_NAME, ns = ...
local E = EllesmereUI
if not E or not E.Lite then return end
local LAB = LibStub("LibActionButton-1.0-Ellesmere335")
local addon = E.Lite.NewAddon(ADDON_NAME)
ns.EAB, ns.addon, ns.IsWrath = addon, addon, true
E._ModuleNS[ADDON_NAME] = ns
local definitions = {
    {key="bar1",label="Action Bar 1",page=1,binding="ACTIONBUTTON",x=0,y=70},
    {key="bar2",label="Action Bar 2",page=6,binding="MULTIACTIONBAR1BUTTON",x=0,y=112},
    {key="bar3",label="Action Bar 3",page=5,binding="MULTIACTIONBAR2BUTTON",x=0,y=154},
    {key="bar4",label="Action Bar 4",page=3,binding="MULTIACTIONBAR3BUTTON",x=510,y=70},
    {key="bar5",label="Action Bar 5",page=4,binding="MULTIACTIONBAR4BUTTON",x=-510,y=70},
    {key="bar6",label="Action Bar 6",page=2,binding="EUI335_BAR6_BUTTON",x=0,y=196},
    {key="petBar",label="Pet Bar",native="PetActionButton",count=10,x=0,y=244},
    {key="stanceBar",label="Stance Bar",native="ShapeshiftButton",count=10,x=-320,y=244},
}
ns.definitions, ns.bars = definitions, {}
local FLAT="Interface\\Buttons\\WHITE8X8"
local MEDIA="Interface\\AddOns\\EllesmereUIActionBars\\Media\\Textures_335\\"
-- Retail Media/highlight-2/3/4.png as power-of-two TGA (backport-tools/prepare_actionbar_media.py).
local HIGHLIGHT_TEXTURES={MEDIA.."highlight-2.tga",MEDIA.."highlight-3.tga",MEDIA.."highlight-4.tga"}
ns.HIGHLIGHT_TEXTURES=HIGHLIGHT_TEXTURES
ns.TEXT_ANCHOR_ORDER={"TOPLEFT","TOP","TOPRIGHT","BOTTOMLEFT","BOTTOM","BOTTOMRIGHT"}
local ANCHORS={TOPLEFT=true,TOP=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOM=true,BOTTOMRIGHT=true}
local INTERACTION,WHITE={r=.973,g=.839,b=.604,a=1},{r=1,g=1,b=1}
local function RGB(r,g,b,a) return {r=r,g=g,b=b,a=a} end
local defaults = {profile={enabled=true,lockActions=true,clickOnDown=false,fontSize=11,hideArtwork=true,
    iconZoom=5.5,desaturateOnCooldown=false,alphaWhenOnCD=100,cdSwipeAlpha=80,
    slotBgColor=RGB(.15,.15,.15),slotBgOpacity=50,mouseoverShowAll=false,
    pushedTextureType=2,pushedUseClassColor=false,pushedCustomColor=RGB(.973,.839,.604,1),pushedBorderSize=4,
    highlightTextureType=2,highlightUseClassColor=false,highlightCustomColor=RGB(.973,.839,.604,1),highlightBorderSize=4,
    showCastHighlight=true,bars={},barPositions={},
    nativeHUD={micro=true,bags=true,bagsConsolidate=false,xp=true,reputation=true,
        buffs=true,debuffs=true,buttonSize=28,spacing=4,barWidth=400,barHeight=14,auraColumns=8}}}
for i,d in ipairs(definitions) do
    defaults.profile.bars[d.key]={enabled=i~=6,buttons=d.count or 12,
        buttonsPerRow=d.count or 12,size=d.native and 30 or 36,spacing=4,
        opacity=100,barVisibility="always",showEmpty=true,clickThrough=false,
        orientation="horizontal",iconOrder="default",
        bgEnabled=false,bgPadding=2,bgColor=RGB(0,0,0,.5),bgBorderSize=0,bgBorderColor=RGB(0,0,0,1),
        borderSize=1,borderColor=RGB(0,0,0,1),borderClassColor=false,
        hideKeybind=false,keybindFontSize=12,keybindFontColor=RGB(1,1,1),keybindAnchor="TOPRIGHT",keybindOffsetX=0,keybindOffsetY=0,
        hideMacroText=false,macroFontSize=12,macroFontColor=RGB(1,1,1),macroAnchor="BOTTOM",macroOffsetX=0,macroOffsetY=0,
        countFontSize=12,countFontColor=RGB(1,1,1),countAnchor="BOTTOMRIGHT",countOffsetX=0,countOffsetY=0,
        showCooldownText=true,cooldownFontSize=12,cooldownTextColor=RGB(1,1,1),cooldownTextXOffset=0,cooldownTextYOffset=0,
        disableTooltips=false,outOfRangeColoring=true,outOfRangeColor=RGB(.8,.1,.1),
        disableFormPaging=false,pagingShift=0,pagingCtrl=0,pagingAlt=0,pagingFriendly=0,pagingHostile=0,
        pagingArrows=false,pagingArrowsRight=false}
end
ns.defaults=defaults
local original, decorations, active, pending = {}, {}, false, false
local artwork={}
local hidden = CreateFrame("Frame",nil,UIParent); hidden:Hide()
local events = CreateFrame("Frame",nil,UIParent)
local toggleOwner = CreateFrame("Frame",nil,UIParent)
local cdButtons, nativeSkins = {}, {}
ns.events, ns.visToggle = events, {}
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function Clamp(v,a,b) return math.max(a,math.min(b,tonumber(v) or a)) end
function ns.GetSettings(key)
    local p=addon.db and addon.db.profile
    return key and p and p.bars[key] or p
end
local function ClassRGB()
    local c=E.GetClassColor and E.GetClassColor(select(2,UnitClass("player")))
    if c then return c.r,c.g,c.b end
end
-- One-time move from the old global button options to the Retail per-bar keys.
local function Migrate(p)
    if p._abRetail==1 then return end
    p._abRetail=1
    for _,s in pairs(p.bars) do
        if s.visibility~=nil then
            if s.visibility~="always" then s.barVisibility=s.visibility end
            s.visibility=nil
        end
        if p.showHotkeys==false then s.hideKeybind=true end
        if p.showMacroNames==false then s.hideMacroText=true end
        if p.fontSize and p.fontSize~=11 then s.keybindFontSize,s.macroFontSize,s.countFontSize=p.fontSize,p.fontSize,p.fontSize end
        if p.rangeColor==false then s.outOfRangeColoring=false end
        if p.tooltip==false then s.disableTooltips=true end
        if p.borderSize~=nil then s.borderSize=p.borderSize end
        if (p.borderR or 0)+(p.borderG or 0)+(p.borderB or 0)>0 then s.borderColor=RGB(p.borderR or 0,p.borderG or 0,p.borderB or 0,1) end
        if p.classBorder then s.borderClassColor=true end
    end
    if p.iconCrop==false then p.iconZoom=0 end
    for _,k in ipairs({"showHotkeys","showMacroNames","rangeColor","tooltip","borderSize","borderR","borderG","borderB","classBorder","iconCrop"}) do p[k]=nil end
end
ns.Migrate=Migrate
local function Snapshot(f)
    if not f or original[f] then return end
    local points={}
    for i=1,f:GetNumPoints() do points[i]={f:GetPoint(i)} end
    original[f]={parent=f:GetParent(),points=points,width=f:GetWidth(),height=f:GetHeight(),
        scale=f:GetScale(),alpha=f:GetAlpha(),shown=f:IsShown()}
end
local function RestoreArt()
    for texture,saved in pairs(artwork) do texture:SetTexture(saved.path); texture:SetAlpha(saved.alpha) end
end
function ns.UpdateArt()
    local p=ns.GetSettings()
    if not p or InCombatLockdown() then return end
    if not p.enabled or p.hideArtwork==false then RestoreArt(); return end
    local function StripTexture(texture)
        if not texture or not texture.GetObjectType or texture:GetObjectType()~="Texture" then return end
        if not artwork[texture] then artwork[texture]={path=texture:GetTexture(),alpha=texture:GetAlpha()} end
        texture:SetTexture(nil); texture:SetAlpha(0)
    end
    -- Art containers stay alive: their scripts and functional children continue
    -- to run, including bags/micro buttons when those skins are switched off.
    for _,name in ipairs({"MainMenuBar","MainMenuBarArtFrame","MainMenuBarArt","MainMenuBarArtFrameBackground",
        "MainMenuBarTexture0","MainMenuBarTexture1","MainMenuBarTexture2","MainMenuBarTexture3",
        "MainMenuBarLeftEndCap","MainMenuBarRightEndCap","MainMenuBarTextureExtender"}) do
        local f=_G[name]
        if f then
            if f.GetObjectType and f:GetObjectType()=="Texture" then StripTexture(f)
            elseif f.GetRegions then for _,region in ipairs({f:GetRegions()}) do StripTexture(region) end end
        end
    end
    for texture in pairs(artwork) do texture:SetTexture(nil); texture:SetAlpha(0) end
end
local function RestoreNativeSkins()
    for button,saved in pairs(nativeSkins) do
        if button._euiBorder then button._euiBorder:Hide() end
        if saved.icon then saved.icon:SetTexCoord(0,1,0,1) end
        for t,alpha in pairs(saved.alpha) do t:SetAlpha(alpha) end
        for fs,font in pairs(saved.fonts) do fs:SetFont(unpack(font)) end
        button:EnableMouse(true)
    end
end
local function RestoreNative()
    RestoreNativeSkins()
    for f,s in pairs(original) do
        f:SetParent(s.parent); f:ClearAllPoints()
        for _,point in ipairs(s.points) do f:SetPoint(unpack(point)) end
        Size(f,s.width,s.height); f:SetScale(s.scale); f:SetAlpha(s.alpha)
        if s.shown then f:Show() else f:Hide() end
    end
    for f,s in pairs(decorations) do
        f:SetAlpha(s.alpha)
        if s.mouse~=nil then f:EnableMouse(s.mouse) end
    end
    RestoreArt()
    if PetActionBar_Update and PetActionBarFrame then PetActionBar_Update(PetActionBarFrame) end
    if ShapeshiftBar_Update then ShapeshiftBar_Update() end
end
local function HideNativeActions()
    for _,prefix in ipairs({"ActionButton","BonusActionButton","MultiBarBottomLeftButton",
        "MultiBarBottomRightButton","MultiBarRightButton","MultiBarLeftButton"}) do
        for i=1,12 do
            local f=_G[prefix..i]
            if f then Snapshot(f); f:SetParent(hidden) end
        end
    end
    -- The bonus shell is also shown when entering a stance, independently of
    -- its buttons. EUI handles those action pages through its secure header.
    if BonusActionBarFrame then Snapshot(BonusActionBarFrame); BonusActionBarFrame:SetParent(hidden) end
    -- The original bar shells remain alive for micro/bag/data-bar children.
    -- Their invisible mouse surfaces can cover Bar 1 and swallow spell drops.
    for _,name in ipairs({"MainMenuBar","MainMenuBarArtFrame","MainMenuBarArt"}) do
        local f=_G[name]
        if f and f.EnableMouse and f.IsMouseEnabled then
            if not decorations[f] then decorations[f]={alpha=f:GetAlpha(),mouse=f:IsMouseEnabled()} end
            f:EnableMouse(false)
        end
    end
    -- Unused native paging controls stay hidden independently of the art toggle.
    for _,name in ipairs({"ActionBarUpButton","ActionBarDownButton","MainMenuBarPageNumber"}) do
        local f=_G[name]
        if f then
            if not decorations[f] then decorations[f]={alpha=f:GetAlpha(),mouse=f.IsMouseEnabled and f:IsMouseEnabled()} end
            f:SetAlpha(0); if f.EnableMouse then f:EnableMouse(false) end
        end
    end
    ns.UpdateArt()
end
-- Action pages offered by the paging dropdowns, labelled by the bar that shows them.
ns.PAGE_LABELS={[1]="Action Bar 1",[6]="Action Bar 2",[5]="Action Bar 3",[3]="Action Bar 4",[4]="Action Bar 5",[2]="Action Bar 6"}
local PAGING_MODS={{"pagingShift","shift"},{"pagingCtrl","ctrl"},{"pagingAlt","alt"},{"pagingFriendly","help"},{"pagingHostile","harm"}}
function ns.GetPageDriver()
    local s=ns.GetSettings("bar1") or {}
    local class=select(2,UnitClass("player"))
    local forms="[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; "
    if class=="DRUID" then forms="[bonusbar:1,stealth] 8; "..forms
    elseif class=="ROGUE" then forms="[form:3] 7; "..forms end
    if s.disableFormPaging then forms="" end
    local mods=""
    for _,m in ipairs(PAGING_MODS) do
        local v=tonumber(s[m[1]]) or 0
        if ns.PAGE_LABELS[v] then
            mods=mods.."["..((m[2]=="help" or m[2]=="harm") and m[2] or "mod:"..m[2]).."] "..v.."; "
        end
    end
    return "[bonusbar:5] 11; "..mods.."[bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; "..forms.."1"
end
-- Legacy single-mode values; the Retail checklist writes the same keys.
local LEGACY_VIS = {
    always="show",never="hide",mouseover="show",in_combat="[combat] show; hide",
    out_of_combat="[nocombat] show; hide",in_party="[group:party,nogroup:raid] show; hide",
    in_raid="[group:raid] show; hide",solo="[nogroup] show; hide",
}
-- Wrath has no skyriding: imported dragonriding lanes are inert instead of
-- reaching a 3.3.5 driver as the unknown [advflyable] conditional.
local DRAGON={show_dragonriding=true,show_not_dragonriding=true,hide_dragonriding=true,hide_not_dragonriding=true}
local WRATH_EDGES={softTarget=true}
local function WrathModes(p)
    local vm=E.GetActiveVisibilityModes and E.GetActiveVisibilityModes(p,"barVisibility")
    if not vm then return nil end
    local copy,any={},false
    for k,v in pairs(vm) do if v and not DRAGON[k] then copy[k]=true; any=true end end
    return any and copy or nil
end
function ns.WantsMouseover(p)
    if (p.barVisibility or "always")=="mouseover" then return true end
    local vm=E.GetActiveVisibilityModes and E.GetActiveVisibilityModes(p,"barVisibility")
    return vm and vm.mouseover and true or false
end
function ns.GetVisibilityDriver(d,p)
    if not ns.GetSettings().enabled then return "hide" end
    if d.key=="stanceBar" and GetNumShapeshiftForms()==0 then return "hide" end
    local prefix="[vehicleui] hide; "
    if d.native then prefix=prefix.."[bonusbar:5] hide; " end
    if d.key=="petBar" then prefix=prefix.."[nopet] hide; " end
    local toggled=ns.visToggle[d.key]
    if toggled~=nil then return prefix..(toggled and "show" or "hide") end
    if not p.enabled or (p.barVisibility or "always")=="never" then return "hide" end
    if ns.quickKeybind then return prefix.."show" end
    local ov=E.VisOverrideValue and E.VisOverrideValue(p)
    if ov then return prefix..(ov=="never" and "hide" or "show") end
    local vm=WrathModes(p)
    if p.visibilityMatch=="any" and E.BuildAnyMatchTail then
        return prefix..E.BuildAnyMatchTail(p,"barVisibility",vm,nil,WRATH_EDGES)
    end
    -- Instances, resting, vehicle and Party Mode have no macro token: they are
    -- resolved now and rebuilt on their events, out of combat.
    local veto=E.CheckVisibilityOptionsNonMacro and E.CheckVisibilityOptionsNonMacro(p,true)
    if veto=="mountaxis" then prefix="[nocombat] hide; "..prefix
    elseif veto then return prefix.."hide" end
    if p.visHideMounted then prefix=prefix.."[mounted] hide; " end
    if p.visOnlyMounted then prefix=prefix.."[nomounted] hide; " end
    if p.visHideNoTarget then prefix=prefix.."[noexists] hide; " end
    if p.visHideWithTarget then prefix=prefix.."[exists] hide; " end
    if p.visHideNoEnemy then prefix=prefix.."[noharm] hide; " end
    if p.visHideWithEnemy then prefix=prefix.."[harm] hide; " end
    if vm and E.BuildVisibilityDriverString then return E.BuildVisibilityDriverString(prefix,vm) end
    return prefix..(LEGACY_VIS[p.barVisibility or "always"] or "show")
end
local applyBindings = [[
    self:ClearBindings()
    if self:GetAttribute("state-eui-visible") ~= "show" then return end
    local count = self:GetAttribute("binding-count") or 0
    for i=1,count do
        self:SetBindingClick(true, self:GetAttribute("binding-key-"..i),
            self:GetAttribute("binding-button-"..i), "LeftButton")
    end
]]
local showState = [[
    if newstate == "show" then self:Show() else self:Hide() end
    control:RunAttribute("ApplyBindings")
]]
local pageState = [[
    if not newstate then return end
    self:SetAttribute("state",newstate)
    control:ChildUpdate("state",newstate)
]]
ns.secure={bindings=applyBindings,visibility=showState,page=pageState}
local function AnchorText(fs,button,anchor,ox,oy,scale,limit)
    if not fs then return end
    anchor=ANCHORS[anchor] and anchor or "TOPRIGHT"
    local x=anchor:find("LEFT") and 2 or anchor:find("RIGHT") and -2 or 0
    local y=anchor:find("TOP") and -2 or 2
    fs:ClearAllPoints(); fs:SetPoint(anchor,button,anchor,(x+(tonumber(ox) or 0))/scale,(y+(tonumber(oy) or 0))/scale)
    fs:SetJustifyH(anchor:find("LEFT") and "LEFT" or anchor:find("RIGHT") and "RIGHT" or "CENTER")
    if limit then fs:SetWidth(math.max(1,button:GetWidth()-4)) end
end
local function StyleText(fs,size,color,scale)
    if not fs then return end
    local flags=E.GetIconTextOutlineFlag and E.GetIconTextOutlineFlag("actionBars") or "OUTLINE"
    E.ApplyModuleFont(fs,E.GetFontPath("actionBars"),Clamp(size,6,32)/scale,"actionBars",flags)
    color=color or WHITE
    -- Wrath FontStrings keep a separate vertex tint (LAB sets .75 on hotkeys).
    if fs.SetVertexColor then fs:SetVertexColor(1,1,1) end
    fs:SetTextColor(color.r or 1,color.g or 1,color.b or 1)
end
ns.AnchorText,ns.StyleText=AnchorText,StyleText
local function Border(button,s,scale)
    local p=ns.GetSettings()
    local border=button._euiBorder
    if not border then border=CreateFrame("Frame",nil,button); button._euiBorder=border end
    border:SetFrameLevel(math.max(0,button:GetFrameLevel()-1))
    local edge=Clamp(s.borderSize,0,5)/scale
    border:ClearAllPoints(); border:SetPoint("TOPLEFT",button,"TOPLEFT",-edge,edge)
    border:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",edge,-edge)
    border:SetBackdrop({bgFile=FLAT,edgeFile=FLAT,edgeSize=math.max(1/scale,edge)})
    local bg=p.slotBgColor or RGB(.15,.15,.15)
    border:SetBackdropColor(bg.r,bg.g,bg.b,Clamp(p.slotBgOpacity,0,100)/100)
    local c=s.borderColor or RGB(0,0,0,1)
    local r,g,b=c.r,c.g,c.b
    if s.borderClassColor then local cr,cg,cb=ClassRGB(); if cr then r,g,b=cr,cg,cb end end
    border:SetBackdropBorderColor(r,g,b,edge>0 and (c.a or 1) or 0)
    border:Show()
end
local function Edges(button,key)
    local e=button[key]
    if not e then
        e={}; for i=1,4 do local t=button:CreateTexture(nil,"OVERLAY"); t:SetTexture(FLAT); t:Hide(); e[i]=t end
        button[key]=e
    end
    return e
end
local function ShowEdges(e,show) if e then for i=1,4 do if show then e[i]:Show() else e[i]:Hide() end end end end
local function PaintEdges(e,button,size,r,g,b)
    for i=1,4 do e[i]:ClearAllPoints(); e[i]:SetVertexColor(r,g,b,1) end
    e[1]:SetPoint("TOPLEFT",button,"TOPLEFT"); e[1]:SetPoint("TOPRIGHT",button,"TOPRIGHT"); e[1]:SetHeight(size)
    e[2]:SetPoint("BOTTOMLEFT",button,"BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT"); e[2]:SetHeight(size)
    e[3]:SetPoint("TOPLEFT",button,"TOPLEFT"); e[3]:SetPoint("BOTTOMLEFT",button,"BOTTOMLEFT"); e[3]:SetWidth(size)
    e[4]:SetPoint("TOPRIGHT",button,"TOPRIGHT"); e[4]:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT"); e[4]:SetWidth(size)
end
-- Interaction types: 1-3 textures, 4 flat colour, 5 border edges, 6 none.
local function StyleState(button,getter,edgeKey,typ,r,g,b,size)
    ShowEdges(button[edgeKey],false)
    button[edgeKey.."On"]=typ==5
    if typ==5 then PaintEdges(Edges(button,edgeKey),button,size,r,g,b) end
    local t=button[getter] and button[getter](button)
    if not t then return end
    t:ClearAllPoints(); t:SetAllPoints(button); t:SetTexCoord(0,1,0,1)
    if typ==5 or typ==6 then t:SetAlpha(0)
    elseif typ==4 then t:SetTexture(FLAT); t:SetVertexColor(r,g,b,.35); t:SetAlpha(1)
    else t:SetTexture(HIGHLIGHT_TEXTURES[typ] or HIGHLIGHT_TEXTURES[1]); t:SetVertexColor(r,g,b,1); t:SetAlpha(1) end
end
function ns.InteractionColor(prefix)
    local p=ns.GetSettings()
    if p[prefix.."UseClassColor"] then local r,g,b=ClassRGB(); if r then return r,g,b end end
    local c=p[prefix.."CustomColor"] or INTERACTION
    return c.r,c.g,c.b
end
local function StyleInteractions(button)
    local p=ns.GetSettings()
    local pr,pg,pb=ns.InteractionColor("pushed")
    local hr,hg,hb=ns.InteractionColor("highlight")
    local hType=Clamp(p.highlightTextureType or 2,1,6)
    StyleState(button,"GetPushedTexture","_euiPush",Clamp(p.pushedTextureType or 2,1,6),pr,pg,pb,Clamp(p.pushedBorderSize,1,8))
    StyleState(button,"GetHighlightTexture","_euiHL",hType,hr,hg,hb,Clamp(p.highlightBorderSize,1,8))
    -- Spell-cast highlight reuses the hover look; edges have no checked state, so they paint flat.
    StyleState(button,"GetCheckedTexture","_euiChk",p.showCastHighlight==false and 6 or (hType==5 and 4 or hType),hr,hg,hb,1)
    if not button._euiHooked then
        button._euiHooked=true
        button:HookScript("OnEnter",function(self) if self._euiHLOn then ShowEdges(self._euiHL,true) end end)
        button:HookScript("OnLeave",function(self) ShowEdges(self._euiHL,false) end)
        button:HookScript("OnMouseDown",function(self) if self._euiPushOn then ShowEdges(self._euiPush,true) end end)
        button:HookScript("OnMouseUp",function(self) ShowEdges(self._euiPush,false) end)
    end
end
local function FormatCD(remain)
    if remain>=3600 then return string.format("%dh",math.ceil(remain/3600)) end
    if remain>=60 then return string.format("%dm",math.ceil(remain/60)) end
    if remain>=3 then return string.format("%d",math.ceil(remain)) end
    return string.format("%.1f",remain)
end
function ns.UpdateCooldownLook(button)
    local p,s=ns.GetSettings(),button._euiBarKey and ns.GetSettings(button._euiBarKey)
    if not p or not s then return end
    local finish=button._euiCDEnd
    local now=GetTime()
    local on=finish and finish>now
    if not on then button._euiCDEnd=nil; cdButtons[button]=nil end
    button.icon:SetDesaturated(on and p.desaturateOnCooldown and true or false)
    button.icon:SetAlpha(on and Clamp(p.alphaWhenOnCD,0,100)/100 or 1)
    local text=button._euiCDText
    if text then
        if on and s.showCooldownText~=false then text:SetText(FormatCD(finish-now)); text:Show()
        else text:Hide() end
    end
end
LAB.RegisterCallback(ns,"OnCooldownUpdate",function(_,button,start,duration,enable)
    if not button._euiBarKey then return end
    local on=enable==1 and (duration or 0)>1.5 and (start or 0)>0
    button._euiCDEnd=on and start+duration or nil
    cdButtons[button]=on or nil
    ns.UpdateCooldownLook(button)
end)
local function CooldownText(button,s)
    local text=button._euiCDText
    if not text then
        local holder=CreateFrame("Frame",nil,button); holder:SetAllPoints(button)
        holder:SetFrameLevel(button.cooldown:GetFrameLevel()+2)
        text=holder:CreateFontString(nil,"OVERLAY"); button._euiCDText=text
    end
    text:ClearAllPoints(); text:SetPoint("CENTER",button,"CENTER",tonumber(s.cooldownTextXOffset) or 0,tonumber(s.cooldownTextYOffset) or 0)
    StyleText(text,s.cooldownFontSize,s.cooldownTextColor,1)
end
-- Raw binding tokens (LAB) and Blizzard's abbreviated text (pet/stance: "s-1",
-- "Num Pad 1", "Middle Mouse") both condense to Retail's form: S1, C1, A1, N1, M3.
function ns.ShortKey(text)
    if type(text)~="string" or text=="" then return text end
    text=text:gsub("CTRL%-","C"):gsub("ALT%-","A"):gsub("SHIFT%-","S"):gsub("%f[%a]([sca])%-",string.upper)
    text=text:gsub("Mouse Button ","M"):gsub("Middle Mouse","M3"):gsub("MOUSEWHEELUP","MwU"):gsub("MOUSEWHEELDOWN","MwD")
    text=text:gsub("Mouse Wheel Up","MwU"):gsub("Mouse Wheel Down","MwD"):gsub("CAPSLOCK","Caps")
    text=text:gsub("NUMPADDECIMAL","N."):gsub("NUMPADPLUS","N+"):gsub("NUMPADMINUS","N-")
    text=text:gsub("NUMPADMULTIPLY","N*"):gsub("NUMPADDIVIDE","N/"):gsub("NUMPAD","N"):gsub("Num Pad ","N"):gsub("BUTTON","M")
    return text
end
local function ShortHotkey(fs,nativeOnly)
    if not fs or not fs.SetText or fs._euiShortKey then return end
    fs._euiShortKey=true
    local busy
    hooksecurefunc(fs,"SetText",function(self,text)
        if busy or (nativeOnly and not active) then return end
        local short=ns.ShortKey(text)
        if short~=text then busy=true; self:SetText(short); busy=false end
    end)
    local text=fs:GetText(); if text then fs:SetText(text) end
end
local function Skin(button,d)
    local p,s=ns.GetSettings(),ns.GetSettings(d.key)
    button._euiBarKey=d.key
    Border(button,s,1)
    button.normalTexture:SetAlpha(0)
    button.icon:ClearAllPoints(); button.icon:SetAllPoints(button)
    button.cooldown:ClearAllPoints(); button.cooldown:SetAllPoints(button)
    button.cooldown:SetAlpha(Clamp(p.cdSwipeAlpha,0,100)/100)
    button.flash:SetAllPoints(button)
    local z=Clamp(p.iconZoom,0,15)/100
    button.icon:SetTexCoord(z,1-z,z,1-z)
    ShortHotkey(button.hotkey)
    StyleText(button.hotkey,s.keybindFontSize,s.keybindFontColor,1)
    AnchorText(button.hotkey,button,s.keybindAnchor,s.keybindOffsetX,s.keybindOffsetY,1,true)
    StyleText(button.actionName,s.macroFontSize,s.macroFontColor,1)
    AnchorText(button.actionName,button,s.macroAnchor or "BOTTOM",s.macroOffsetX,s.macroOffsetY,1,true)
    StyleText(button.count,s.countFontSize,s.countFontColor,1)
    AnchorText(button.count,button,s.countAnchor or "BOTTOMRIGHT",s.countOffsetX,s.countOffsetY,1,false)
    CooldownText(button,s)
    StyleInteractions(button)
    ns.UpdateCooldownLook(button)
end
-- Pet/stance buttons stay Blizzard's (their events own the slots); only the
-- EUI look is layered on, and every change is undone when the module turns off.
local function SkinNative(button,d,scale)
    local s,p=ns.GetSettings(d.key),ns.GetSettings()
    local name=button:GetName() or ""
    local saved=nativeSkins[button]
    if not saved then saved={alpha={},fonts={}}; nativeSkins[button]=saved end
    Border(button,s,scale)
    local icon=_G[name.."Icon"]
    if icon then
        saved.icon=icon
        local z=Clamp(p.iconZoom,0,15)/100; icon:SetTexCoord(z,1-z,z,1-z)
    end
    for _,suffix in ipairs({"NormalTexture","NormalTexture2"}) do
        local t=_G[name..suffix]
        if t and t.SetAlpha then if saved.alpha[t]==nil then saved.alpha[t]=t:GetAlpha() end; t:SetAlpha(0) end
    end
    local hotkey,count=_G[name.."HotKey"],_G[name.."Count"]
    for _,fs in ipairs({hotkey,count}) do if fs and fs.GetFont and not saved.fonts[fs] then saved.fonts[fs]={fs:GetFont()} end end
    if hotkey then
        ShortHotkey(hotkey,true)
        StyleText(hotkey,s.keybindFontSize,s.keybindFontColor,scale)
        if s.hideKeybind then hotkey:SetAlpha(0) else hotkey:SetAlpha(1) end
    end
    StyleText(count,s.countFontSize,s.countFontColor,scale)
end
local function Config(d)
    local p,s=ns.GetSettings(),ns.GetSettings(d.key)
    local c=s.outOfRangeColor or RGB(.8,.1,.1)
    return {showGrid=s.showEmpty,clickOnDown=p.clickOnDown,tooltip=s.disableTooltips and "disabled" or "enabled",
        outOfRangeColoring=s.outOfRangeColoring==false and "none" or "button",useColoring=true,keyBoundTarget=false,
        colors={range={c.r,c.g,c.b},mana={.5,.5,1},usable={1,1,1},notUsable={.4,.4,.4}},
        hideElements={macro=s.hideMacroText==true,hotkey=s.hideKeybind==true,equipped=false}}
end
local function CreateBar(d)
    local bar=CreateFrame("Frame","EllesmereUIActionBars_"..d.key,UIParent,"SecureHandlerStateTemplate")
    bar:SetFrameStrata("LOW"); bar.buttons={}; ns.bars[d.key]=bar
    bar:SetAttribute("ApplyBindings",applyBindings)
    bar:SetAttribute("_onstate-eui-visible",showState)
    if d.native then
        for i=1,d.count do
            local button=_G[d.native..i]
            if button then Snapshot(button); bar.buttons[i]=button end
        end
    else
        bar:SetAttribute("_onstate-page",pageState)
        for i=1,12 do
            local button=LAB:CreateButton(i,"EllesmereUIActionBars_"..d.key.."Button"..i,bar,Config(d))
            bar.buttons[i]=button
            button:SetState(0,"action",(d.page-1)*12+i)
            for page=1,11 do button:SetState(page,"action",(page-1)*12+i) end
            button:SetAttribute("checkselfcast",true); button:SetAttribute("checkfocuscast",true)
        end
    end
    return bar
end
local function UpdateBindings(d,bar)
    local count=0
    if not d.native then
        local p=ns.GetSettings(d.key)
        for i=1,Clamp(p.buttons,1,12) do
            local command=d.binding..i
            local button=bar.buttons[i]
            local keys={GetBindingKey(command)}
            for _,key in ipairs({GetBindingKey("CLICK "..button:GetName()..":LeftButton")}) do keys[#keys+1]=key end
            for _,key in ipairs(keys) do
                count=count+1; bar:SetAttribute("binding-key-"..count,key)
                bar:SetAttribute("binding-button-"..count,button:GetName())
            end
            local config=Config(d); config.keyBoundTarget=command
            button:UpdateConfig(config); button:SetAttribute("buttonlock",ns.GetSettings().lockActions)
            Skin(button,d)
        end
    end
    bar:SetAttribute("binding-count",count)
    bar:Execute([[control:RunAttribute("ApplyBindings")]])
end
-- Grid cell of the idx-th (0-based) button. Grow direction aligns a partial
-- last row (left/right/center, or up/down/center when vertical); corner orders
-- put the first button in that corner.
local function GridPos(idx,count,stride,vertical,order,grow)
    if order=="reversed" then idx=count-1-idx end
    local lines=math.ceil(count/stride)
    local line,pos=math.floor(idx/stride),idx%stride
    local inLine=line==lines-1 and count-line*stride or stride
    if grow=="center" then pos=pos+(stride-inLine)/2
    elseif grow=="right" or grow=="down" then pos=pos+stride-inLine end
    local col,row
    if vertical then col,row=line,pos else col,row=pos,line end
    local cols,rows=vertical and lines or stride,vertical and stride or lines
    if order=="TOPRIGHT" or order=="BOTTOMRIGHT" then col=cols-1-col end
    if order=="BOTTOMLEFT" or order=="BOTTOMRIGHT" then row=rows-1-row end
    return col,row
end
ns.GridPos=GridPos
local function Background(bar,s)
    local bg=bar._euiBG
    if not s.bgEnabled then if bg then bg:Hide() end; return end
    if not bg then bg=CreateFrame("Frame",nil,bar); bar._euiBG=bg; bg:EnableMouse(false) end
    bg:SetFrameLevel(bar:GetFrameLevel())
    local pad=Clamp(s.bgPadding,0,30)
    bg:ClearAllPoints(); bg:SetPoint("TOPLEFT",bar,"TOPLEFT",-pad,pad); bg:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",pad,-pad)
    local edge=Clamp(s.bgBorderSize,0,8)
    bg:SetBackdrop({bgFile=FLAT,edgeFile=FLAT,edgeSize=math.max(1,edge)})
    local c,bc=s.bgColor or RGB(0,0,0,.5),s.bgBorderColor or RGB(0,0,0,1)
    bg:SetBackdropColor(c.r,c.g,c.b,c.a or .5)
    bg:SetBackdropBorderColor(bc.r,bc.g,bc.b,edge>0 and (bc.a or 1) or 0)
    bg:Show()
end
function ns.UpdatePageText()
    local a=ns.bars.bar1 and ns.bars.bar1._euiArrows
    if a and a.text then a.text:SetText(GetActionBarPage and GetActionBarPage() or 1) end
end
local function PagingArrows(bar,s,size)
    local a=bar._euiArrows
    if not s.pagingArrows then if a then a:Hide() end; return end
    if not a then
        a=CreateFrame("Frame",nil,bar); bar._euiArrows=a
        local function Arrow(dir,step)
            local b=CreateFrame("Button",nil,a)
            local t=b:CreateTexture(nil,"ARTWORK"); t:SetAllPoints(b)
            local up,down="Interface\\MainMenuBar\\UI-MainMenu-Scroll"..dir.."Button-Up","Interface\\MainMenuBar\\UI-MainMenu-Scroll"..dir.."Button-Down"
            t:SetTexture(up)
            b:SetScript("OnMouseDown",function() t:SetTexture(down) end)
            b:SetScript("OnMouseUp",function() t:SetTexture(up) end)
            b:SetScript("OnClick",function()
                local n=(GetActionBarPage and GetActionBarPage() or 1)+step
                if n>6 then n=1 elseif n<1 then n=6 end
                if ChangeActionBarPage then ChangeActionBarPage(n) end
            end)
            return b
        end
        a.up,a.down=Arrow("Up",1),Arrow("Down",-1)
        a.text=a:CreateFontString(nil,"OVERLAY")
    end
    local w=math.max(14,math.floor(size/2))
    Size(a,w,bar:GetHeight())
    a:ClearAllPoints()
    if s.pagingArrowsRight then a:SetPoint("LEFT",bar,"RIGHT",4,0) else a:SetPoint("RIGHT",bar,"LEFT",-4,0) end
    Size(a.up,w,w); Size(a.down,w,w)
    a.up:ClearAllPoints(); a.up:SetPoint("TOP",a,"TOP",0,0)
    a.down:ClearAllPoints(); a.down:SetPoint("BOTTOM",a,"BOTTOM",0,0)
    a.text:ClearAllPoints(); a.text:SetPoint("CENTER",a,"CENTER",0,0)
    E.ApplyModuleFont(a.text,E.GetFontPath("actionBars"),12,"actionBars","OUTLINE")
    ns.UpdatePageText(); a:Show()
end
local function Layout(d,bar)
    local p=ns.GetSettings(d.key)
    local count=d.native and d.count or Clamp(p.buttons,1,12)
    if d.key=="stanceBar" then count=math.max(1,math.min(count,GetNumShapeshiftForms())) end
    local stride=math.min(count,Clamp(p.buttonsPerRow,1,d.count or 12))
    local vertical=p.orientation=="vertical"
    local lines=math.ceil(count/stride)
    local cols,rows=vertical and lines or stride,vertical and stride or lines
    local size,spacing=Clamp(p.size,16,120),Clamp(p.spacing,-10,20)
    Size(bar,cols*(size+spacing)-spacing,rows*(size+spacing)-spacing)
    local pos=ns.GetSettings().barPositions[d.key]
    bar:ClearAllPoints()
    if pos then bar:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y)
    else bar:SetPoint("BOTTOM",UIParent,"BOTTOM",d.x,d.y) end
    for i,button in ipairs(bar.buttons) do
        button:SetParent(bar); button:ClearAllPoints()
        local scale=1
        if d.native then scale=size/original[button].width; button:SetScale(scale)
        else Size(button,size,size); button:SetScale(1) end
        local col,row
        if i<=count then col,row=GridPos(i-1,count,stride,vertical,p.iconOrder,p.growDirection)
        else col,row=(i-1)%stride,math.floor((i-1)/stride) end
        button:SetPoint("TOPLEFT",bar,"TOPLEFT",col*(size+spacing)/scale,-row*(size+spacing)/scale)
        button:EnableMouse(not p.clickThrough)
        -- Native pet/stance events still own the availability of individual slots.
        if d.native then SkinNative(button,d,scale)
        elseif i<=count then button:Show() else button:Hide() end
    end
    if d.native then
        local nativeFrame=_G[d.key=="petBar" and "PetActionBarFrame" or "ShapeshiftBarFrame"]
        -- Blizzard's slide/show animations restore alpha on stance changes.
        -- Keep its event controller running under a hidden parent; the native
        -- buttons have already been moved to our independently visible header.
        if nativeFrame then Snapshot(nativeFrame); nativeFrame:SetParent(hidden); nativeFrame:SetAlpha(0) end
    end
    Background(bar,p)
    if not d.native then
        RegisterStateDriver(bar,"page",d.key=="bar1" and ns.GetPageDriver() or tostring(d.page))
        if d.key=="bar1" then PagingArrows(bar,p,size) end
    end
    UpdateBindings(d,bar)
    RegisterStateDriver(bar,"eui-visible",ns.GetVisibilityDriver(d,p))
end
local function ToggleButton(key)
    local name="EUI335_ABToggle_"..key
    local b=_G[name] or CreateFrame("Button",name,UIParent)
    b:SetScript("OnClick",function() ns.ToggleBar(key) end)
    return b
end
-- Runtime show/hide that never writes the saved Visibility; out of combat only.
function ns.ToggleBar(key)
    if InCombatLockdown() then return end
    local bar=ns.bars[key]; if not bar then return end
    ns.visToggle[key]=not bar:IsShown()
    ns.RefreshVisibility()
end
function ns.RebuildToggleBindings()
    if InCombatLockdown() or not ClearOverrideBindings then return end
    ClearOverrideBindings(toggleOwner)
    if not active then return end
    for _,d in ipairs(definitions) do
        local key=ns.GetSettings(d.key).toggleVisKey
        if key and key~="" then SetOverrideBindingClick(toggleOwner,false,key,ToggleButton(d.key):GetName()) end
    end
end
function ns.RefreshVisibility()
    if not active then return end
    if InCombatLockdown() then pending=true; return end
    for _,d in ipairs(definitions) do
        local bar=ns.bars[d.key]
        if bar then RegisterStateDriver(bar,"eui-visible",ns.GetVisibilityDriver(d,ns.GetSettings(d.key))) end
    end
end
function ns.UpdateAlpha()
    if not active then return end
    ns.UpdateArt()
    local unlock=E.IsUnlockModeActive and E:IsUnlockModeActive()
    local root=ns.GetSettings()
    local anyHover=false
    if root.mouseoverShowAll then
        for _,d in ipairs(definitions) do
            local bar=ns.bars[d.key]
            if bar and bar:IsShown() and ns.WantsMouseover(ns.GetSettings(d.key)) and MouseIsOver(bar) then anyHover=true end
        end
    end
    for _,d in ipairs(definitions) do
        local bar=ns.bars[d.key]
        if bar then
            local p=ns.GetSettings(d.key)
            local alpha=Clamp(p.opacity,0,100)/100
            if ns.WantsMouseover(p) and not anyHover and not MouseIsOver(bar) and not unlock then alpha=0 end
            if ns.quickKeybind then alpha=1 end
            bar:SetAlpha(alpha)
        end
    end
    for button in pairs(cdButtons) do ns.UpdateCooldownLook(button) end
end
function ns.Apply()
    if not addon.db then return end
    if InCombatLockdown() then pending=true; return end
    pending=false
    local p=ns.GetSettings()
    Migrate(p)
    if ns.NativeHUD then ns.NativeHUD.Apply() end
    if not p.enabled then
        active=false
        for _,bar in pairs(ns.bars) do
            UnregisterStateDriver(bar,"eui-visible"); UnregisterStateDriver(bar,"page")
            bar:Execute([[self:ClearBindings()]])
            bar:SetAttribute("state-eui-visible",nil); bar:SetAttribute("state-page",nil); bar:Hide()
        end
        RestoreNative(); ns.RebuildToggleBindings(); return
    end
    active=true; HideNativeActions()
    for _,d in ipairs(definitions) do Layout(d,ns.bars[d.key] or CreateBar(d)) end
    ns.RebuildToggleBindings()
    ns.UpdateAlpha()
end
function addon:ApplyAll() ns.Apply() end
function addon:ApplyBorders() if not InCombatLockdown() then for _,d in ipairs(definitions) do if not d.native and ns.bars[d.key] then for _,b in ipairs(ns.bars[d.key].buttons) do Skin(b,d) end end end end end
function ns.AB_Style() return "eui" end
-- Unlock mover "Element Options" targets, shared with the options page.
local HUD_TARGETS={
    micro={"MICRO MENU & BAGS","Micro Menu Skin"},bags={"MICRO MENU & BAGS","Bag Bar Skin"},
    xp={"EXPERIENCE BAR","Enable Experience Bar"},reputation={"REPUTATION BAR","Enable Reputation Bar"},
    buffs={"PLAYER AURAS","Buff Mover"},debuffs={"PLAYER AURAS","Debuff Mover"},
}
function ns.RegisterSettingsTargets()
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    for _,d in ipairs(definitions) do
        local selected=d.key
        E._ELEMENT_SETTINGS_MAP["EUI335_AB_"..selected]={module=ADDON_NAME,page="Bar Display",sectionName="LAYOUT",highlightText="Icon Size",
            preSelectFn=function()
                ns.selectedWrathBar=selected
                if ns.SelectWrathBar then ns.SelectWrathBar(selected,false) end
            end}
    end
    for key,target in pairs(HUD_TARGETS) do
        E._ELEMENT_SETTINGS_MAP["EUI335_HUD_"..key]={module=ADDON_NAME,page="Menu, Bags & XP Bars",sectionName=target[1],highlightText=target[2]}
    end
end
function addon:OnInitialize()
    -- Lua 5.1 xpcall does not forward the Core dispatcher's extra arguments.
    -- Capture the instance, as the Wrath Minimap does, instead of relying on self.
    addon.db=E.Lite.NewDB("EllesmereUIActionBarsDB",defaults)
    _G._EAB_Apply=ns.Apply
    BINDING_HEADER_EUI335_ACTIONBARS="EllesmereUI Action Bars"
    for i=1,12 do _G["BINDING_NAME_EUI335_BAR6_BUTTON"..i]="Action Bar 6 - Button "..i end
    SLASH_EUI335ACTIONBARS1="/eab"
    SlashCmdList.EUI335ACTIONBARS=function()
        if InCombatLockdown() then return end
        if E.EnsureOptionsLoaded and E.EnsureOptionsLoaded() then E:ShowModule(ADDON_NAME) end
    end
end
function addon:OnEnable()
    if not addon.db then return end
    ns.Apply()
    if ns.NativeHUD then ns.NativeHUD.Enable() end
    if E.RegisterUnlockElements and E.MakeUnlockElement then
        local elements={}
        for i,d in ipairs(definitions) do
            local key=d.key
            elements[#elements+1]=E.MakeUnlockElement({key="EUI335_AB_"..key,label=d.label,group="Action Bars",order=100+i,
                noResize=true,noAnchorTo=true,getFrame=function() return ns.bars[key] end,
                getSize=function() local f=ns.bars[key]; return f and f:GetWidth() or 1,f and f:GetHeight() or 1 end,
                isHidden=function()
                    local root,p=ns.GetSettings(),ns.GetSettings(key)
                    return not root or not root.enabled or not p or not p.enabled or p.barVisibility=="never"
                end,
                savePos=function(_,point,relPoint,x,y)
                    local p=ns.GetSettings(); if p then p.barPositions[key]={point=point,relPoint=relPoint,x=x,y=y} end
                end,
                loadPos=function() local p=ns.GetSettings(); return p and p.barPositions[key] end,
                clearPos=function() local p=ns.GetSettings(); if p then p.barPositions[key]=nil end end,applyPos=ns.Apply,
            })
        end
        if ns.NativeHUD then for _,element in ipairs(ns.NativeHUD.Elements()) do elements[#elements+1]=element end end
        -- Register shortcuts before Options loads so the first mover cog can
        -- select its bar while opening the lazy settings panel.
        ns.RegisterSettingsTargets()
        E:RegisterUnlockElements(elements,ADDON_NAME)
    end
    for _,event in ipairs({"PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD","UPDATE_BINDINGS","UPDATE_SHAPESHIFT_FORMS",
        "ZONE_CHANGED_NEW_AREA","PLAYER_UPDATE_RESTING","UNIT_ENTERED_VEHICLE","UNIT_EXITED_VEHICLE","ACTIONBAR_PAGE_CHANGED"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent",function(_,event,unit)
        if event=="PLAYER_REGEN_ENABLED" then if pending then ns.Apply() end
        elseif event=="ACTIONBAR_PAGE_CHANGED" then ns.UpdatePageText()
        elseif event=="ZONE_CHANGED_NEW_AREA" or event=="PLAYER_UPDATE_RESTING" then ns.RefreshVisibility()
        elseif event=="UNIT_ENTERED_VEHICLE" or event=="UNIT_EXITED_VEHICLE" then if unit=="player" then ns.RefreshVisibility() end
        else ns.Apply() end
    end)
    if E.RegisterVisEdge then E.RegisterVisEdge(ns.RefreshVisibility) end
    local elapsed=0
    events:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        if elapsed>=.1 then elapsed=0; ns.UpdateAlpha() end
    end)
end
