-- Raid Tools, Retail layout on 3.3.5: Show mode, Show as (Compact Band, One/Two
-- Windows, Only Group & Pull, Only Markers), collapsed icon, toggle keybind and
-- three pull timers. Wrath has no world markers, role poll or Blizzard countdown,
-- so the markers row is target markers only and pulls use EUI_QoL_335_Panels.
--
-- Visibility is the Retail secure state machine: shells and the icon carry
-- enabled / visible / override / expanded / startexpanded attributes and the
-- "apply" snippet is the only place they are shown or hidden, so the state
-- driver, keybind, collapse and expand all work in combat. Lua changes defer
-- to PLAYER_REGEN_ENABLED.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not ns.addon then return end

local MEDIA="Interface\\AddOns\\EllesmereUIQoL\\Media\\Textures_335\\"
local PANEL_W,PAD,TOPBAR_H,ROW_H,ROW_GAP=236,10,25,22,4
local CONTENT_TOP=TOPBAR_H+6
local MARKER_SZ,MARKER_LBL_H,ICON_SZ=23,10,30
local COMPACT_W,COMPACT_H,COMPACT_MIN_W,COMPACT_MIN_H=400,40,365,28
local COMPACT_PAD,COMPACT_ICON,COMPACT_GAP,COMPACT_DIV=6,28,4,5
local PULL_DEFAULTS={3,5,10}
ns.PULL_DEFAULTS=PULL_DEFAULTS
local BG_ASPECT=561/433
local BASE_L,BASE_R,BASE_T,BASE_B=.25,1,0,.75
local SECTION_KEYS={"Group","Markers"}
local SECTION_LABEL={Group="Group & Pull",Markers="Markers"}
local MARKER_NAME={"Star","Circle","Diamond","Triangle","Moon","Square","Cross","Skull"}
local MODES={never=true,raid=true,group=true,always=true}
local SHOW_AS={compact=true,one=true,two=true,group=true,markers=true}
local MODE_DRIVERS={raid="[group:raid] show; hide",group="[group] show; hide"}
local ICON_CORNER={downright="TOPLEFT",upright="BOTTOMLEFT",downleft="TOPRIGHT",upleft="BOTTOMRIGHT"}
-- Unlock keys and saved position slots. EUI_RaidTools/raidTools predate the
-- split and keep existing positions.
local UNLOCK={Group="EUI_RaidTools",Markers="EUI_RaidTools_Markers",Compact="EUI_RaidTools_Compact"}
local POS={Group="raidTools",Markers="raidToolsMarkers",Compact="raidToolsCompact"}

local sections,titles,fonts={},{},{}
local groupHolder,markersHolder,compactHolder,iconBtn,toggleButton,events
local groupButtons,markerButtons,pullButtons,compactMarkers={},{},{},{}
local readyButton,convertButton,disbandButton,reinviteButton,stopButton,compactReady,compactPull,compactDivider
local groupH,markersH=0,0
local applyPending,settingsPreview,lastSuppressed,lastVisSig,lastPerm,lastWorldSig,resetHooked

local APPLY=[[
    if not self:GetAttribute("enabled") then self:Hide() return end
    local ov=self:GetAttribute("override")
    local vis
    if ov=="show" then vis=true elseif ov=="hide" then vis=false else vis=self:GetAttribute("visible") end
    local want=self:GetAttribute("expanded")
    if self:GetAttribute("isicon") then want=not want end
    if vis and want then self:Show() else self:Hide() end
]]
local ONSTATE=[[
    local vis=(newstate=="show")
    local seed=self:GetAttribute("startexpanded")
    self:SetAttribute("visible",vis)
    self:SetAttribute("override","")
    self:SetAttribute("expanded",seed)
    control:RunAttribute("apply")
    local icon=self:GetFrameRef("icon")
    if icon then
        icon:SetAttribute("visible",vis)
        icon:SetAttribute("override","")
        icon:SetAttribute("expanded",seed)
        control:RunFor(icon,icon:GetAttribute("apply"))
    end
]]
-- Default to Collapsed on: the key rocks between icon and windows. Off: plain show/hide.
local TOGGLE=[[
    local n=self:GetAttribute("count") or 0
    local icon=self:GetFrameRef("icon")
    local anyWin,iconShown=false,false
    for i=1,n do local f=self:GetFrameRef("s"..i); if f and f:IsShown() then anyWin=true end end
    if icon and icon:IsShown() then iconShown=true end
    if icon and not icon:GetAttribute("startexpanded") then
        local expand=not anyWin
        for i=1,n do
            local f=self:GetFrameRef("s"..i)
            if f then
                if expand then f:SetAttribute("override","show") end
                f:SetAttribute("expanded",expand); control:RunFor(f,f:GetAttribute("apply"))
            end
        end
        if expand then icon:SetAttribute("override","show") end
        icon:SetAttribute("expanded",expand); control:RunFor(icon,icon:GetAttribute("apply"))
        return
    end
    local ov="show"
    if anyWin or iconShown then ov="hide" end
    for i=1,n do
        local f=self:GetFrameRef("s"..i)
        if f then
            f:SetAttribute("override",ov)
            if ov=="show" then f:SetAttribute("expanded",f:GetAttribute("startexpanded")) end
            control:RunFor(f,f:GetAttribute("apply"))
        end
    end
    if icon then
        icon:SetAttribute("override",ov)
        if ov=="show" then icon:SetAttribute("expanded",icon:GetAttribute("startexpanded")) end
        control:RunFor(icon,icon:GetAttribute("apply"))
    end
]]
local function FlipSnippet(expanded)
    return [[
    local n=self:GetAttribute("count") or 0
    for i=1,n do local f=self:GetFrameRef("s"..i); if f then f:SetAttribute("expanded",]]..expanded..[[); control:RunFor(f,f:GetAttribute("apply")) end end
    local icon=self:GetFrameRef("icon") or self
    icon:SetAttribute("expanded",]]..expanded..[[); control:RunFor(icon,icon:GetAttribute("apply"))
]]
end
local EXPAND,COLLAPSE=FlipSnippet("true"),FlipSnippet("false")
local RUN_APPLY=[[ control:RunAttribute("apply") ]]
local function Exec(f,body)
    if SecureHandlerExecute then SecureHandlerExecute(f,body) elseif f.Execute then f:Execute(body) end
end

local function True(v) return v~=nil and v~=false and v~=0 end
local function R() local p=ns.GetSettings(); return p and p.raidTools end
local function InRaid() return (GetNumRaidMembers() or 0)>0 end
local function InGroup() return InRaid() or (GetNumPartyMembers() or 0)>0 end
local function IsLeader() if not InGroup() then return true end; return True(UnitIsPartyLeader("player")) end
local function HasAssist()
    if not InGroup() then return true end
    return IsLeader() or (InRaid() and UnitIsRaidOfficer and True(UnitIsRaidOfficer("player")))
end
-- Older profiles had enabled + groupOnly; an unset mode keeps their behaviour.
function ns.RaidToolsMode(p)
    local r=p and p.raidTools
    if not (p and p.enabled and r) then return "never" end
    if MODES[r.mode] then return r.mode end
    if not r.enabled then return "never" end
    return r.groupOnly==false and "always" or "group"
end
local function Mode() return ns.RaidToolsMode(ns.GetSettings()) end
function ns.RaidToolsShowAs()
    local r=R(); local v=r and r.showAs
    return SHOW_AS[v] and v or "one"
end
local ShowAs=ns.RaidToolsShowAs
-- The settings page shows the tools even on Never; Unlock Mode only an active mode.
local function Forced() return settingsPreview or (ns.preview and Mode()~="never") end
-- In a raid every button needs leader or assist, so the feature leaves the screen.
local function Suppressed() return not Forced() and InRaid() and not HasAssist() end
local function Scale()
    local v=tonumber(R() and R().scale) or 100
    if v<=5 then v=v*100 end
    return math.max(.5,math.min(2,v/100))
end
function ns.RaidToolsPullTime(i)
    local t=R() and R().pullTimes; local v=t and t[i]
    if v==nil then v=PULL_DEFAULTS[i] end
    v=tonumber(v) or 0
    if v<=0 then return nil end
    return math.min(60,math.floor(v))
end
local PullTime=ns.RaidToolsPullTime
local function CompactW() local r=R(); return math.max(COMPACT_MIN_W,tonumber(r and r.compactWidth) or COMPACT_W) end
local function CompactH() local r=R(); return math.max(COMPACT_MIN_H,tonumber(r and r.compactHeight) or COMPACT_H) end

local function Font(owner,size,r,g,b)
    local fs=owner:CreateFontString(nil,"OVERLAY"); ns.Font(fs,size); fs:SetTextColor(r or 1,g or 1,b or 1)
    fonts[#fonts+1]={fs,size}; return fs
end
local function Border(f,r,g,b,a)
    local edges={}
    local function Edge(p1,p2,w,h)
        local t=f:CreateTexture(nil,"BORDER"); t:SetTexture(r,g,b,a); t:SetPoint(p1,f,p1); t:SetPoint(p2,f,p2)
        if w then t:SetWidth(w) else t:SetHeight(h) end
        edges[#edges+1]=t
    end
    Edge("TOPLEFT","TOPRIGHT",nil,1); Edge("BOTTOMLEFT","BOTTOMRIGHT",nil,1); Edge("TOPLEFT","BOTTOMLEFT",1); Edge("TOPRIGHT","BOTTOMRIGHT",1)
    return edges
end
local function ShowAll(list,on) for _,t in ipairs(list) do if on then t:Show() else t:Hide() end end end
local function SkinButton(b)
    local fill=b:CreateTexture(nil,"BACKGROUND"); fill:SetTexture(.08,.08,.08,.92); fill:SetAllPoints(b)
    Border(b,.2,.2,.2,1)
    local hover=b:CreateTexture(nil,"HIGHLIGHT"); hover:SetTexture(1,1,1,.1); hover:SetAllPoints(b)
end
local function FitArt(f)
    local w,h=f:GetWidth(),f:GetHeight()
    if not f._art or not w or w<=0 or not h or h<=0 then return end
    local a=w/h
    if a>BG_ASPECT then
        local trim=((BASE_B-BASE_T)-(BASE_B-BASE_T)*(BG_ASPECT/a))/2
        f._art:SetTexCoord(BASE_L,BASE_R,BASE_T+trim,BASE_B-trim)
    else
        local trim=((BASE_R-BASE_L)-(BASE_R-BASE_L)*(a/BG_ASPECT))/2
        f._art:SetTexCoord(BASE_L+trim,BASE_R-trim,BASE_T,BASE_B)
    end
end
local function Tip(owner,title,rows)
    if not GameTooltip then return end
    GameTooltip:SetOwner(owner,"ANCHOR_TOP"); GameTooltip:SetText(title,1,1,1)
    for _,row in ipairs(rows) do GameTooltip:AddDoubleLine(row[1],row[2],1,1,1,1,1,1) end
    GameTooltip:Show()
end
local function HideTip() if GameTooltip then GameTooltip:Hide() end end

local function GroupButton(parent,text,onClick,needsLeader)
    local b=CreateFrame("Button",nil,parent); ns.Size(b,PANEL_W-PAD*2,ROW_H)
    SkinButton(b)
    b.label=Font(b,11); b.label:SetPoint("CENTER",b,"CENTER",0,0); b.label:SetText(text)
    b:SetScript("OnClick",onClick); b.needsLeader=needsLeader
    groupButtons[#groupButtons+1]=b
    return b
end
local function MarkTarget(index,button)
    if not UnitExists("target") then return end
    if index==0 or button=="RightButton" or IsShiftKeyDown() then SetRaidTarget("target",0)
    elseif GetRaidTargetIndex("target")==index then SetRaidTarget("target",0)
    else SetRaidTarget("target",index) end
end
-- The server's world marker items, in raid target order (same as Quickdraw).
local WORLD_ITEMS={131084,131079,131080,131078,131082,131077,131081,131083}
ns.RAID_WORLD_ITEMS=WORLD_ITEMS
function ns.RaidToolsWorldMarker(index)
    local r=R(); if r and r.worldMarkers==false then return nil end
    local item=WORLD_ITEMS[index or 0]
    if not item or (GetItemCount(item) or 0)==0 then return nil end
    return "item:"..item
end
-- The server's "Reset Markers" button on the Raid tab clears world markers.
local RESET_BUTTON="rmarkbtn"
function ns.RaidToolsWorldReset()
    local r=R(); if r and r.worldMarkers==false then return nil end
    return _G[RESET_BUTTON] and "/click "..RESET_BUTTON or nil
end
-- SetRaidTarget is not protected on 3.3.5, so it runs from PostClick; the
-- secure template is only there for Shift + Left Click world marker items.
local function MarkerButton(parent,index,size,compact)
    local b=CreateFrame("Button",nil,parent,"SecureActionButtonTemplate"); ns.Size(b,size,size)
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    local icon=b:CreateTexture(nil,"ARTWORK"); icon:SetAllPoints(b)
    if index==0 then icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    else icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons"); SetRaidTargetIconTexture(icon,index) end
    icon:SetAlpha(.8); b.icon,b.index,b._baseAlpha=icon,index,.8
    b:SetScript("PostClick",function(self,button)
        if self.world and button=="LeftButton" and IsShiftKeyDown() then return end
        MarkTarget(index,button)
    end)
    if compact and index>0 then
        local line=b:CreateTexture(nil,"OVERLAY"); line:SetHeight(2)
        line:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",2,-2); line:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,-2)
        local r,g,bl=.05,.82,.62
        if E.GetAccentColor then r,g,bl=E.GetAccentColor() end
        line:SetTexture(r,g,bl,.95); line:Hide(); b.active=line
    end
    b:SetScript("OnEnter",function(self)
        if self._baseAlpha>=.8 then self.icon:SetAlpha(1) end
        if not compact and not self.world then return end
        if index==0 then
            local rows={{"Click","Clear target marker"}}
            if self.world then rows[2]={"Shift + Left Click","Reset world markers"} end
            Tip(self,"Clear Markers",rows); return
        end
        local rows={{"Left Click","Toggle target marker"},{"Right Click","Clear target marker"}}
        if self.world then rows[#rows+1]={"Shift + Left Click","Place world marker"} end
        Tip(self,MARKER_NAME[index],rows)
    end)
    b:SetScript("OnLeave",function(self) self.icon:SetAlpha(self._baseAlpha); HideTip() end)
    markerButtons[#markerButtons+1]=b
    return b
end

local function MakeShell(key)
    local f=CreateFrame("Frame","EUI335QoLRaidTools"..(key=="Group" and "" or key),UIParent,"SecureHandlerStateTemplate")
    f:SetWidth(PANEL_W); f:SetHeight(60); f:SetFrameStrata("MEDIUM"); f:SetClampedToScreen(true); f:Hide()
    local art=f:CreateTexture(nil,"BACKGROUND"); art:SetTexture(MEDIA.."modern_blizz"); art:SetAllPoints(f)
    local wash=f:CreateTexture(nil,"BACKGROUND"); wash:SetTexture(0,0,0,.62); wash:SetAllPoints(f)
    local bar=f:CreateTexture(nil,"BORDER"); bar:SetTexture(0,0,0,.5); bar:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); bar:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0); bar:SetHeight(TOPBAR_H)
    f._art,f._bar,f._edges=art,bar,Border(f,.2,.2,.2,1)
    f:HookScript("OnSizeChanged",FitArt)
    f:SetAttribute("enabled",true); f:SetAttribute("visible",false); f:SetAttribute("override","")
    f:SetAttribute("expanded",true); f:SetAttribute("startexpanded",true)
    f:SetAttribute("apply",APPLY); f:SetAttribute("_onstate-euirt_vis",ONSTATE)
    local title=Font(f,12); title:SetPoint("LEFT",f,"TOPLEFT",PAD,-TOPBAR_H/2); title:SetText(SECTION_LABEL[key]); titles[key]=title
    local col=CreateFrame("Button",nil,f,"SecureHandlerClickTemplate"); ns.Size(col,14,14)
    col:SetPoint("RIGHT",f,"TOPRIGHT",-6,-TOPBAR_H/2); col:RegisterForClicks("AnyUp"); SkinButton(col)
    local dash=Font(col,14); dash:SetPoint("CENTER",col,"CENTER",0,1); dash:SetText("-"); dash:SetAlpha(.7)
    col:SetScript("OnEnter",function() dash:SetAlpha(1) end); col:SetScript("OnLeave",function() dash:SetAlpha(.7) end)
    col:SetAttribute("_onclick",COLLAPSE); f.collapse=col
    sections[key]=f
    return f
end

local function LayoutGroup()
    if not groupHolder then return end
    local r=R(); local rows,pair={},{}
    local function Add(b) pair[#pair+1]=b; if #pair==2 then rows[#rows+1]=pair; pair={} end end
    Add(readyButton)
    if not r or r.showConvert~=false then Add(convertButton) end
    if not r or r.showDisband~=false then Add(disbandButton) end
    if not r or r.showReinvite~=false then Add(reinviteButton) end
    if #pair>0 then rows[#rows+1]=pair end
    local pull={}
    for i=1,3 do
        local secs=PullTime(i)
        if secs then local b=pullButtons[#pull+1]; b.secs=secs; b.label:SetText(tostring(secs)); pull[#pull+1]=b end
    end
    if #pull>0 then pull[#pull+1]=stopButton; rows[#rows+1]=pull end
    for _,b in ipairs(groupButtons) do if b:GetParent()==groupHolder then b:Hide() end end
    local y=0
    for _,row in ipairs(rows) do
        local w=(PANEL_W-PAD*2-ROW_GAP*(#row-1))/#row
        for i,b in ipairs(row) do b:SetWidth(w); b:ClearAllPoints(); b:SetPoint("TOPLEFT",groupHolder,"TOPLEFT",PAD+(w+ROW_GAP)*(i-1),y); b:Show() end
        y=y-ROW_H-ROW_GAP
    end
    groupH=math.max(0,-(y+ROW_GAP)); groupHolder:SetHeight(math.max(1,groupH))
end
local function BuildGroup()
    groupHolder=CreateFrame("Frame",nil,sections.Group); groupHolder:SetWidth(PANEL_W)
    readyButton=GroupButton(groupHolder,"Ready Check",function() DoReadyCheck() end)
    convertButton=GroupButton(groupHolder,"Convert to Raid",function()
        if not InRaid() then ConvertToRaid()
        elseif ConvertToParty then ConvertToParty()
        elseif ns.ConfirmRebuildParty then ns.ConfirmRebuildParty() end
    end,true)
    convertButton.allowed=function()
        return not InRaid() or ConvertToParty~=nil or (ns.CanRebuildParty~=nil and ns.CanRebuildParty())
    end
    disbandButton=GroupButton(groupHolder,"Disband",function() if ns.ConfirmDisband then ns.ConfirmDisband() end end,true)
    reinviteButton=GroupButton(groupHolder,"Reinvite",function() if ns.ConfirmReinvite then ns.ConfirmReinvite() end end,true)
    reinviteButton.allowed=function() return InGroup() end
    for i=1,3 do local b; b=GroupButton(groupHolder,"",function() ns.StartPull(b.secs) end); pullButtons[i]=b end
    stopButton=GroupButton(groupHolder,"Stop",function() ns.StopPull() end)
    LayoutGroup()
end
local function BuildMarkers()
    markersHolder=CreateFrame("Frame",nil,sections.Markers); markersHolder:SetWidth(PANEL_W)
    local label=Font(markersHolder,9); label:SetAlpha(.55); label:SetPoint("TOPLEFT",markersHolder,"TOPLEFT",PAD,0); label:SetText("Target Markers")
    markersHolder.label=label
    local y=-MARKER_LBL_H-2
    local step=(PANEL_W-PAD*2-MARKER_SZ)/8
    for i=0,8 do
        local b=MarkerButton(markersHolder,i==8 and 0 or i+1,MARKER_SZ)
        b:SetPoint("TOPLEFT",markersHolder,"TOPLEFT",PAD+step*i,y)
    end
    markersH=MARKER_LBL_H+2+MARKER_SZ; markersHolder:SetHeight(markersH)
end
local function CompactAction(label,tip,onClick)
    local b=CreateFrame("Button",nil,compactHolder); ns.Size(b,COMPACT_ICON,COMPACT_ICON)
    b:RegisterForClicks("LeftButtonUp","RightButtonUp"); b:SetScript("OnClick",onClick)
    b.label=Font(b,11); b.label:SetPoint("CENTER",b,"CENTER",0,0); b.label:SetText(label); b.label:SetAlpha(.8)
    b:SetScript("OnEnter",function(self) self.label:SetAlpha(1); Tip(self,tip())end)
    b:SetScript("OnLeave",function(self) self.label:SetAlpha(.8); HideTip() end)
    groupButtons[#groupButtons+1]=b
    return b
end
local function LayoutCompact()
    if not compactHolder then return end
    local secs=PullTime(3) or PullTime(2) or PullTime(1)
    if secs then compactPull:Show() else compactPull:Hide() end
    compactReady:ClearAllPoints(); compactReady:SetPoint("RIGHT",compactHolder,"RIGHT",-COMPACT_PAD,0)
    compactPull:ClearAllPoints(); compactPull:SetPoint("RIGHT",compactReady,"LEFT",-COMPACT_GAP,0)
    local first=secs and compactPull or compactReady
    compactDivider:ClearAllPoints()
    compactDivider:SetPoint("TOP",first,"TOPLEFT",-COMPACT_DIV,-2); compactDivider:SetPoint("BOTTOM",first,"BOTTOMLEFT",-COMPACT_DIV,2)
    local width=CompactW(); local utilities=secs and 2 or 1
    local lastLeft=width-COMPACT_PAD-(utilities*COMPACT_ICON+(utilities-1)*COMPACT_GAP)-COMPACT_DIV-COMPACT_GAP-COMPACT_ICON
    local stride=(lastLeft-COMPACT_PAD)/(#compactMarkers-1)
    for i,b in ipairs(compactMarkers) do b:ClearAllPoints(); b:SetPoint("LEFT",compactHolder,"LEFT",math.floor(COMPACT_PAD+(i-1)*stride+.5),0) end
end
local function BuildCompact()
    compactHolder=CreateFrame("Frame",nil,sections.Group); compactHolder:SetHeight(COMPACT_H)
    for i=1,8 do compactMarkers[i]=MarkerButton(compactHolder,i,COMPACT_ICON,true) end
    compactMarkers[9]=MarkerButton(compactHolder,0,COMPACT_ICON,true)
    compactReady=CompactAction("RC",function() return "Ready Check",{{"Left Click","Ready Check"}} end,function() DoReadyCheck() end)
    compactPull=CompactAction("PT",function()
        local function S(i) local v=PullTime(i); return v and ("Pull "..v) or "off" end
        return "Pull Timer",{{"Left Click",S(3)},{"Shift + Left Click",S(2)},{"Ctrl + Left Click",S(1)},{"Right Click","Stop pull timer"}}
    end,function(_,button)
        if button=="RightButton" then ns.StopPull(); return end
        local secs
        if IsControlKeyDown() then secs=PullTime(1) elseif IsShiftKeyDown() then secs=PullTime(2)
        else secs=PullTime(3) or PullTime(2) or PullTime(1) end
        if secs then ns.StartPull(secs) end
    end)
    compactDivider=compactHolder:CreateTexture(nil,"ARTWORK"); compactDivider:SetTexture(1,1,1,.1); compactDivider:SetWidth(1)
    ns.raidButtons.compactReady,ns.raidButtons.compactPull=compactReady,compactPull
    LayoutCompact()
end
-- Compact marks the symbol your target wears (Wrath has no ground markers).
local function RefreshMarkerState()
    if not compactHolder then return end
    local current=UnitExists("target") and GetRaidTargetIndex("target")
    for _,b in ipairs(compactMarkers) do
        if b.active then if current==b.index then b.active:Show() else b.active:Hide() end end
    end
end
local function BuildIcon()
    iconBtn=CreateFrame("Button","EUI335QoLRaidToolsIcon",UIParent,"SecureHandlerClickTemplate")
    ns.Size(iconBtn,ICON_SZ,ICON_SZ); iconBtn:SetFrameStrata("MEDIUM"); iconBtn:SetClampedToScreen(true)
    iconBtn:RegisterForClicks("AnyUp"); iconBtn:Hide()
    local tex=iconBtn:CreateTexture(nil,"ARTWORK"); tex:SetAllPoints(iconBtn); tex:SetTexture(MEDIA.."raid-tools")
    local hl=iconBtn:CreateTexture(nil,"HIGHLIGHT"); hl:SetAllPoints(iconBtn); hl:SetTexture(MEDIA.."raid-tools"); hl:SetBlendMode("ADD"); hl:SetAlpha(.5)
    iconBtn:SetAttribute("isicon",true); iconBtn:SetAttribute("enabled",true); iconBtn:SetAttribute("visible",false)
    iconBtn:SetAttribute("override",""); iconBtn:SetAttribute("expanded",true); iconBtn:SetAttribute("startexpanded",true)
    iconBtn:SetAttribute("apply",APPLY); iconBtn:SetAttribute("_onclick",EXPAND)
end
local function BuildAll()
    if sections.Group then return end
    MakeShell("Group"); MakeShell("Markers"); ns.raidFrame=sections.Group
    BuildGroup(); BuildMarkers(); BuildIcon()
    toggleButton=CreateFrame("Button","EUI335QoLRaidToolsToggle",UIParent,"SecureHandlerClickTemplate")
    ns.Size(toggleButton,1,1); toggleButton:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",-100,-100); toggleButton:SetAlpha(0)
    toggleButton:RegisterForClicks("AnyUp"); toggleButton:SetAttribute("count",#SECTION_KEYS); toggleButton:SetAttribute("_onclick",TOGGLE)
    ns.raidToggle,ns.raidIcon,ns.raidSections=toggleButton,iconBtn,sections
    ns.raidButtons={ready=readyButton,convert=convertButton,disband=disbandButton,reinvite=reinviteButton,pull=pullButtons,stop=stopButton,markers=markerButtons,compact=compactMarkers}
    for i,key in ipairs(SECTION_KEYS) do
        local shell=sections[key]
        SecureHandlerSetFrameRef(toggleButton,"s"..i,shell); SecureHandlerSetFrameRef(shell,"icon",iconBtn)
        SecureHandlerSetFrameRef(iconBtn,"s"..i,shell)
        shell.collapse:SetAttribute("count",#SECTION_KEYS)
        for j,other in ipairs(SECTION_KEYS) do SecureHandlerSetFrameRef(shell.collapse,"s"..j,sections[other]) end
        SecureHandlerSetFrameRef(shell.collapse,"icon",iconBtn)
    end
    SecureHandlerSetFrameRef(toggleButton,"icon",iconBtn); iconBtn:SetAttribute("count",#SECTION_KEYS)
end

local function ApplyLayout()
    local r=R(); local showAs=ShowAs(); local g,m=sections.Group,sections.Markers
    local compact=showAs=="compact"
    local collapseUI=not compact and r and r.collapsedIcon~=false
    if collapseUI then g.collapse:Show() else g.collapse:Hide() end
    if collapseUI and showAs~="two" then m.collapse:Show() else m.collapse:Hide() end
    for _,t in ipairs({g._art,g._bar,titles.Group}) do if compact then t:Hide() else t:Show() end end
    ShowAll(g._edges,not compact)
    if compact and not compactHolder then BuildCompact() end
    if compactHolder then if compact then compactHolder:Show() else compactHolder:Hide() end end
    if compact then
        g:SetWidth(CompactW()); g:SetHeight(CompactH())
        compactHolder:SetParent(g); compactHolder:ClearAllPoints(); compactHolder:SetAllPoints(g)
        groupHolder:Hide(); markersHolder:Hide()
        LayoutCompact()
    elseif showAs=="one" then
        g:SetWidth(PANEL_W); titles.Group:SetText("Raid Tools")
        groupHolder:SetParent(g); groupHolder:Show(); groupHolder:ClearAllPoints(); groupHolder:SetPoint("TOPLEFT",g,"TOPLEFT",0,-CONTENT_TOP)
        markersHolder:SetParent(g); markersHolder:Show(); markersHolder:ClearAllPoints()
        markersHolder:SetPoint("TOPLEFT",g,"TOPLEFT",0,-CONTENT_TOP-groupH-ROW_GAP*2)
        g:SetHeight(CONTENT_TOP+groupH+ROW_GAP*2+markersH+PAD)
    else
        g:SetWidth(PANEL_W); m:SetWidth(PANEL_W); titles.Group:SetText(SECTION_LABEL.Group)
        groupHolder:SetParent(g); groupHolder:Show(); groupHolder:ClearAllPoints(); groupHolder:SetPoint("TOPLEFT",g,"TOPLEFT",0,-CONTENT_TOP)
        g:SetHeight(CONTENT_TOP+groupH+PAD)
        markersHolder:SetParent(m); markersHolder:Show(); markersHolder:ClearAllPoints(); markersHolder:SetPoint("TOPLEFT",m,"TOPLEFT",0,-CONTENT_TOP)
        m:SetHeight(CONTENT_TOP+markersH+PAD)
    end
    local corner=ICON_CORNER[r and r.growDir] or "TOPLEFT"
    iconBtn:ClearAllPoints(); iconBtn:SetPoint(corner,showAs=="markers" and m or g,corner,0,0)
    FitArt(g); FitArt(m); RefreshMarkerState()
end
local function DefaultPos(key)
    local s=Scale(); local top=-20
    if key=="Markers" then top=top-(sections.Group:GetHeight()*s+ROW_GAP) end
    return {point="TOPLEFT",relPoint="TOPLEFT",x=20/s,y=top/s}
end
local function ApplyPosition(key,slot)
    local f=sections[key]; local p=ns.GetSettings()
    local pos=p and p.positions and p.positions[POS[slot]] or DefaultPos(key)
    if E.ApplyCenterPosition and pos.point=="CENTER" and pos.relPoint=="CENTER" and E.ApplyCenterPosition(UNLOCK[slot],pos) then return end
    if E.IsUnlockAnchored and E.IsUnlockAnchored(UNLOCK[slot]) then return end
    f:ClearAllPoints(); f:SetPoint(pos.point,UIParent,pos.relPoint or pos.point,pos.x or 0,pos.y or 0)
end
local function ApplyPositions()
    if E._unlockActive then return end
    local showAs=ShowAs()
    if showAs=="compact" then ApplyPosition("Group","Compact") elseif showAs~="markers" then ApplyPosition("Group","Group") end
    if showAs=="two" or showAs=="markers" then ApplyPosition("Markers","Markers") end
end
local function ApplyVisibility()
    local r=R(); local mode=Mode(); local driver=MODE_DRIVERS[mode]
    local visNow=(mode=="raid" and InRaid()) or (mode=="group" and InGroup()) or mode=="always"
    local showAs=ShowAs(); local compact=showAs=="compact"; local suppressed=Suppressed()
    local on={Group=showAs~="markers" and not suppressed,Markers=(showAs=="two" or showAs=="markers") and not suppressed}
    local startExpanded=compact or not (r and r.collapsedIcon~=false)
    local expandedNow,forced=startExpanded,Forced()
    if forced then driver=nil; visNow=true; expandedNow=true end
    lastSuppressed=suppressed
    -- QoL re-applies on every addon load; only a real change may reset the
    -- player's current collapse/override state.
    local sig=table.concat({mode,showAs,tostring(suppressed),tostring(startExpanded),tostring(forced)},":")
    if sig==lastVisSig then return end
    lastVisSig=sig
    for _,key in ipairs(SECTION_KEYS) do
        local f=sections[key]
        f:SetAttribute("enabled",on[key] and true or false); f:SetAttribute("visible",visNow and true or false)
        f:SetAttribute("override",""); f:SetAttribute("startexpanded",startExpanded); f:SetAttribute("expanded",expandedNow)
        UnregisterStateDriver(f,"euirt_vis")
        if on[key] and driver then RegisterStateDriver(f,"euirt_vis",driver) end
    end
    iconBtn:SetAttribute("enabled",not compact and not suppressed); iconBtn:SetAttribute("visible",visNow and true or false)
    iconBtn:SetAttribute("override",""); iconBtn:SetAttribute("startexpanded",startExpanded); iconBtn:SetAttribute("expanded",expandedNow)
    for _,key in ipairs(SECTION_KEYS) do Exec(sections[key],RUN_APPLY) end
    Exec(iconBtn,RUN_APPLY)
end
local function ApplyKeybind()
    ClearOverrideBindings(toggleButton)
    local k=R() and R().toggleKey
    if k and k~="" and Mode()~="never" and not Suppressed() then SetOverrideBindingClick(toggleButton,false,k,toggleButton:GetName()) end
end
local function SetEnabled(b,on) b:SetAlpha(on and 1 or .35); b:EnableMouse(on and true or false) end
local function RefreshPermissions(force)
    if not sections.Group then return end
    local assist,leader,raid=HasAssist(),IsLeader(),InRaid()
    local key=tostring(assist)..tostring(leader)..tostring(raid)..tostring(raid and GetNumRaidMembers()<=5)
    if not force and key==lastPerm then return end
    lastPerm=key
    convertButton.label:SetText(raid and "Convert to Party" or "Convert to Raid")
    for _,b in ipairs(groupButtons) do
        local ok
        if b.needsLeader then ok=leader else ok=assist end
        SetEnabled(b,ok and (not b.allowed or b.allowed()))
    end
    local mark=not raid or assist
    -- Marker buttons are protected: their mouse state waits for combat to end.
    local locked=InCombatLockdown()
    if locked then applyPending=true end
    for _,b in ipairs(markerButtons) do b._baseAlpha=mark and .8 or .4; b.icon:SetAlpha(b._baseAlpha); if not locked then b:EnableMouse(mark) end end
end
local function ApplyWorldMarkers()
    local any=false
    for _,b in ipairs(markerButtons) do
        if b.index==0 then
            local macro=ns.RaidToolsWorldReset()
            b.world=macro; b:SetAttribute("shift-type1",macro and "macro" or nil); b:SetAttribute("shift-macrotext1",macro)
        else
            local item=ns.RaidToolsWorldMarker(b.index)
            b.world=item; b:SetAttribute("shift-type1",item and "item" or nil); b:SetAttribute("shift-item1",item)
            if item then any=true end
        end
    end
    -- The server may build its button when the Raid tab first opens.
    if not _G[RESET_BUTTON] and RaidFrame and not resetHooked then
        resetHooked=true
        RaidFrame:HookScript("OnShow",function()
            if not _G[RESET_BUTTON] or not markersHolder then return end
            if InCombatLockdown() then applyPending=true else ApplyWorldMarkers() end
        end)
    end
    if markersHolder then markersHolder.label:SetText(any and "Target Markers  |cff888888(Shift: World)|r" or "Target Markers") end
end
local function OnEvent(_,event)
    if event=="PLAYER_REGEN_ENABLED" then if applyPending then ns.ApplyRaidTools() end; return end
    if event=="BAG_UPDATE" then
        local sig=""
        for i=1,#WORLD_ITEMS do sig=sig..(ns.RaidToolsWorldMarker(i) and "1" or "0") end
        if sig==lastWorldSig then return end
        lastWorldSig=sig
        if InCombatLockdown() then applyPending=true elseif sections.Group then ApplyWorldMarkers() end
        return
    end
    if event=="RAID_TARGET_UPDATE" or event=="PLAYER_TARGET_CHANGED" then RefreshMarkerState(); return end
    RefreshPermissions()
    if Suppressed()~=lastSuppressed then ns.ApplyRaidTools() end
end
local function EnsureEvents()
    if not events then events=CreateFrame("Frame"); events:SetScript("OnEvent",OnEvent); ns.raidEvents=events end
    for _,e in ipairs({"RAID_ROSTER_UPDATE","PARTY_MEMBERS_CHANGED","PARTY_LEADER_CHANGED","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","RAID_TARGET_UPDATE","PLAYER_TARGET_CHANGED","BAG_UPDATE"}) do events:RegisterEvent(e) end
end

function ns.ApplyRaidTools()
    if InCombatLockdown() then applyPending=true; EnsureEvents(); return end
    applyPending=false
    if Mode()=="never" and not settingsPreview then
        if sections.Group then
            for _,key in ipairs(SECTION_KEYS) do
                local f=sections[key]; UnregisterStateDriver(f,"euirt_vis"); f:SetAttribute("enabled",false); f:SetAttribute("override",""); f:Hide()
            end
            iconBtn:SetAttribute("enabled",false); iconBtn:Hide(); ClearOverrideBindings(toggleButton)
        end
        lastVisSig=nil
        if events then events:UnregisterAllEvents() end
        return
    end
    EnsureEvents(); BuildAll(); LayoutGroup(); ApplyLayout()
    local s=Scale(); sections.Group:SetScale(s); sections.Markers:SetScale(s); iconBtn:SetScale(s)
    ApplyPositions(); ApplyVisibility(); ApplyKeybind()
    for _,f in ipairs(fonts) do ns.Font(f[1],f[2]) end
    RefreshPermissions(true); RefreshMarkerState(); ApplyWorldMarkers()
end
function ns.RaidToolsPreview(on)
    on=on and true or false
    if settingsPreview==on then return end
    settingsPreview=on; ns.ApplyRaidTools()
end
function ns.ToggleRaidTools()
    if Mode()=="never" then ns.Print("Raid Tools is disabled in the EllesmereUI options."); return end
    if InCombatLockdown() then ns.Print("Raid Tools cannot be toggled by slash command in combat; use the keybind."); return end
    if Suppressed() then ns.Print("Raid Tools is hidden in a raid without leader or assist; none of its buttons work there."); return end
    BuildAll(); Exec(toggleButton,TOGGLE)
end
SLASH_EUIRAIDTOOLS1="/euiraid"
SlashCmdList.EUIRAIDTOOLS=ns.ToggleRaidTools

function ns.RaidToolsUnlockElements()
    local function SavePos(slot,key)
        return function(_,point,relPoint,x,y)
            local p=ns.GetSettings(); if not (point and p) then return end
            if E.ConvertToCenterPos then point,relPoint,x,y=E.ConvertToCenterPos(UNLOCK[slot],point,relPoint,x,y) end
            p.positions[POS[slot]]={point=point,relPoint=relPoint,x=x,y=y}
            if not E._unlockActive and sections[key] then ApplyPosition(key,slot) end
        end
    end
    local function Element(slot,key,label,order,visible)
        local def={key=UNLOCK[slot],label=label,group="Quality of Life",order=order,noResize=slot~="Compact",noAnchorTo=true,
            getFrame=function()
                if Mode()=="never" or Suppressed() or not visible(ShowAs()) then return nil end
                BuildAll(); return sections[key]
            end,
            getSize=function()
                local f=sections[key]; local s=Scale()
                if slot=="Compact" then return CompactW(),CompactH() end
                if f then return f:GetWidth()*s,f:GetHeight()*s end
                return PANEL_W*s,60*s
            end,
            isHidden=function() local f=sections[key]; return not (f and f:IsShown()) end,
            savePos=SavePos(slot,key),
            loadPos=function() local p=ns.GetSettings(); return p and p.positions[POS[slot]] end,
            clearPos=function() local p=ns.GetSettings(); if p then p.positions[POS[slot]]=nil end end,
            applyPos=function() if sections[key] and visible(ShowAs()) and not E._unlockActive then ApplyPosition(key,slot) end end}
        if slot=="Compact" then
            local function Resize(field,minimum)
                return function(_,v)
                    local r=R(); if not (r and v) then return end
                    r[field]=math.max(minimum,math.floor(v+.5))
                    if sections.Group and not InCombatLockdown() then ApplyLayout() end
                end
            end
            def.setWidth,def.setHeight=Resize("compactWidth",COMPACT_MIN_W),Resize("compactHeight",COMPACT_MIN_H)
        end
        return E.MakeUnlockElement(def)
    end
    return {
        Element("Group","Group","Raid Tools",920,function(v) return v~="compact" and v~="markers" end),
        Element("Markers","Markers","Raid Markers",921,function(v) return v=="two" or v=="markers" end),
        Element("Compact","Group","Raid Tools Compact Band",922,function(v) return v=="compact" end),
    }
end
