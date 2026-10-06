local ADDON,ns=...
local E=EllesmereUI
local white="Interface\\Buttons\\WHITE8X8"
local nativeCreateFrame=CreateFrame
function ns.Font(fs,size,outline)
    local path=E.GetFontPath and E.GetFontPath("damageMeters") or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local flags=outline or "OUTLINE"
    if flags=="GLOBAL" then flags=(E.GetFontOutlineFlag and E.GetFontOutlineFlag("damageMeters") or "OUTLINE"):gsub(",?%s*SLUG","") end
    if flags~="" and flags~="OUTLINE" and flags~="THICKOUTLINE" then flags="OUTLINE" end
    if not fs:SetFont(path,size,flags) then fs:SetFont("Fonts\\FRIZQT__.TTF",size,"OUTLINE") end
    fs:SetShadowColor(0,0,0,1); fs:SetShadowOffset(1,-1)
end
function ns.Text(parent,size)
    local fs=parent:CreateFontString(nil,"OVERLAY"); ns.Font(fs,size or 11); fs:SetTextColor(1,1,1); fs:SetJustifyH("LEFT"); fs:SetJustifyV("MIDDLE"); return fs
end
local function Accent() if E.GetAccentColor then return E.GetAccentColor() end; return .047,.824,.616 end
ns.Accent=Accent
function ns.Skin(f,alpha)
    f:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); f:SetBackdropColor(.025,.035,.045,alpha or .96)
    f:SetBackdropBorderColor(Accent())
end
function ns.Button(parent,text,w,h,fn)
    local b=nativeCreateFrame("Button",nil,parent); ns.Size(b,w or 24,h or 22); ns.Skin(b,.85)
    b.text=ns.Text(b,10); b.text:SetAllPoints(b); b.text:SetJustifyH("CENTER"); b.text:SetText(text)
    b:SetScript("OnClick",fn); b:SetScript("OnEnter",function(self) self:SetBackdropColor(.08,.15,.16,math.min(1,(self.bgAlpha or .85)+.15)) end)
    b:SetScript("OnLeave",function(self) local c=self.bgColor; self:SetBackdropColor(c and c.r or .025,c and c.g or .035,c and c.b or .045,self.bgAlpha or .85) end); return b
end
ns.MEDIA="Interface\\AddOns\\EllesmereUIDamageMeters\\Media_335\\"
local ICON_ALPHA,ICON_HOVER_ALPHA,ICON_DISABLED_ALPHA=.4,.9,.2
local SNAP_THRESH=6
-- The padlock glyphs are centred on a 64px canvas.
local LOCK_COORDS={.28125,.71875,.203125,.796875}
ns.MAX_WINDOWS,ns.MIN_WIDTH,ns.MAX_WIDTH=5,150,1200
local function ShowTip(owner,text)
    if not text then return end
    GameTooltip:SetOwner(owner,"ANCHOR_TOP"); GameTooltip:SetText(text); GameTooltip:Show()
end
ns.ShowTip=ShowTip
local function PaintIcon(b) b.icon:SetAlpha(b.disabled and ICON_DISABLED_ALPHA or b.hover and ICON_HOVER_ALPHA or ICON_ALPHA) end
ns.PaintHeaderIcon=PaintIcon
-- Bare desaturated header glyph, brightened while hovered.
function ns.HeaderIcon(parent,file,tip,fn)
    local b=nativeCreateFrame("Button",nil,parent); ns.Size(b,22,22)
    b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetAllPoints(b); b.icon:SetTexture(ns.MEDIA..file); b.icon:SetDesaturated(true)
    b.tip=tip
    b:SetScript("OnEnter",function(self) self.hover=true; PaintIcon(self); if self.onEnter then self.onEnter() end; ShowTip(self,self.disabled and self.disabledTip or self.tip) end)
    b:SetScript("OnLeave",function(self) self.hover=false; PaintIcon(self); GameTooltip:Hide() end)
    b:SetScript("OnClick",function(self,button) if not self.disabled and fn then GameTooltip:Hide(); fn(self,button) end end)
    PaintIcon(b); return b
end
local resourceTextures={"atrocity","beautiful","divide","fade","fade-right","glass","gradient-bt","gradient-lr","gradient-rl","gradient-tb","matte","plating","sheer","thin-line-bottom","thin-line-top"}
local function SharedMedia()
    local ok,lsm=pcall(LibStub,"LibSharedMedia-3.0",true)
    return ok and type(lsm)=="table" and lsm.Fetch and lsm or nil
end
function ns.BarTexturePath(key)
    if not key or key=="none" then return white end
    if key=="blizzard" then return "Interface\\TargetingFrame\\UI-StatusBar" end
    local smName=key:match("^lsm:(.+)") or key:match("^sm:(.+)")
    if smName then
        local lsm=SharedMedia(); local ok,path=lsm and pcall(lsm.Fetch,lsm,"statusbar",smName,true)
        return ok and path or white
    end
    return "Interface\\AddOns\\EllesmereUIResourceBars\\Media\\Textures_335\\"..key..".tga"
end
function ns.BarTextureChoices()
    local names,order={none="Solid",blizzard="Blizzard"},{"none","blizzard"}
    for _,key in ipairs(resourceTextures) do names[key]=key:gsub("-"," "):gsub("^%l",string.upper); order[#order+1]=key end
    local lsm=SharedMedia()
    if lsm and lsm.List then
        for _,name in ipairs(lsm:List("statusbar") or {}) do local key="lsm:"..name; names[key]=name; order[#order+1]=key end
    end
    return names,order
end
local function Commas(n)
    local s=tostring(math.floor(n+.5)); local k
    repeat s,k=s:gsub("^(-?%d+)(%d%d%d)","%1,%2") until k==0
    return s
end
function ns.Format(n,style)
    n=tonumber(n) or 0
    if (style=="full" or style=="comma") and n>=100 then return style=="comma" and Commas(n) or tostring(math.floor(n+.5)) end
    if style=="full" or style=="comma" then return n%1~=0 and string.format("%.1f",n) or tostring(n) end
    if n>=1000000 then return string.format("%.2fm",n/1000000)
    elseif n>=1000 then return string.format("%.1fk",n/1000)
    elseif n%1~=0 then return string.format("%.1f",n) end
    return tostring(math.floor(n))
end
local function Color(class)
    local c=class and RAID_CLASS_COLORS[class]; if c then return c.r,c.g,c.b end
    return Accent()
end
-- Items: {text,fn,isActive (value or function),keepOpen,tooltip} or an input
-- {text,isInput,getValue,setValue}; the string "---" draws a divider.
local MENU_ROWS,MENU_LINES=16,4
function ns.CloseMenu() if ns.menu then ns.menu:Hide(); ns.menu.cover:Hide() end end
local function MenuClick(self)
    local m=ns.menu; local item=self.itemIndex and m.items[self.itemIndex]
    if not item or item.isInput then return end
    GameTooltip:Hide()
    if item.keepOpen then if item.fn then item.fn() end; if m:IsShown() then ns.PaintMenu() end
    else ns.CloseMenu(); if item.fn then item.fn() end end
end
local function MenuInput(m,b)
    local e=nativeCreateFrame("EditBox",nil,b); ns.Size(e,52,18); e:SetPoint("RIGHT",b,"RIGHT",-4,0); ns.Skin(e,.9)
    e:SetBackdropBorderColor(.25,.27,.3,1); e:SetAutoFocus(false); e:SetNumeric(true); e:SetMaxLetters(4)
    e:SetTextInsets(4,4,0,0); e:SetJustifyH("RIGHT"); ns.Font(e,10,"")
    e:SetScript("OnEnterPressed",function(self)
        local item=b.itemIndex and m.items[b.itemIndex]; local v=tonumber(self:GetText())
        self:ClearFocus(); if item and item.setValue and v then item.setValue(v) end
        if m:IsShown() then ns.PaintMenu() end
    end)
    e:SetScript("OnEscapePressed",function(self) self:ClearFocus(); if m:IsShown() then ns.PaintMenu() end end)
    e:SetScript("OnHide",function(self) self:ClearFocus() end)
    e:Hide(); return e
end
function ns.OpenMenu(anchor,items,width)
    ns.CloseMenu()
    local m=ns.menu
    if not m then
        m=nativeCreateFrame("Frame",nil,UIParent); m:SetFrameStrata("TOOLTIP"); m:SetClampedToScreen(true); ns.Skin(m)
        m.cover=nativeCreateFrame("Button",nil,UIParent); m.cover:SetAllPoints(UIParent); m.cover:SetFrameStrata("FULLSCREEN_DIALOG")
        m.cover:SetScript("OnClick",ns.CloseMenu); m.buttons={}; m.lines={}; m:EnableMouseWheel(true)
        m:SetScript("OnMouseWheel",function(_,delta) m.offset=ns.Clamp(m.offset-delta,0,math.max(0,#m.items-MENU_ROWS)); ns.PaintMenu() end)
        m:SetScript("OnHide",function() GameTooltip:Hide() end)
        for i=1,MENU_ROWS do
            local b=ns.Button(m,"",245,22,MenuClick)
            b.text:ClearAllPoints(); b.text:SetPoint("LEFT",b,"LEFT",8,0); b.text:SetPoint("RIGHT",b,"RIGHT",-8,0); b.text:SetJustifyH("LEFT")
            local enter,leave=b:GetScript("OnEnter"),b:GetScript("OnLeave")
            b:SetScript("OnEnter",function(self) enter(self); local item=self.itemIndex and m.items[self.itemIndex]
                if item and item.tooltip then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(item.tooltip,1,1,1,1,true); GameTooltip:Show() end
            end)
            b:SetScript("OnLeave",function(self) leave(self); GameTooltip:Hide() end)
            b.input=MenuInput(m,b); m.buttons[i]=b
        end
        for i=1,MENU_LINES do
            local line=m:CreateTexture(nil,"ARTWORK"); line:SetTexture(white); line:SetVertexColor(.3,.32,.35,1); line:SetHeight(1); line:Hide(); m.lines[i]=line
        end
        m.hint=ns.Text(m,10); m.hint:SetPoint("BOTTOM",m,"BOTTOM",0,5)
        ns.menu=m
    end
    m.items,m.offset,m.width=items,0,width or 245; m:ClearAllPoints(); m:SetPoint("TOPRIGHT",anchor,"BOTTOMRIGHT",0,-2)
    ns.PaintMenu(); m.cover:Show(); m:Show()
end
function ns.PaintMenu()
    local m=ns.menu; local w=m.width or 245; local y=-3; local shown,lines,i=0,0,m.offset
    local ar,ag,ab=Accent()
    for _,b in ipairs(m.buttons) do b.itemIndex=nil; b:Hide() end
    for _,line in ipairs(m.lines) do line:Hide() end
    while shown<MENU_ROWS and i<#m.items do
        i=i+1; local item=m.items[i]
        if item=="---" then
            if lines<MENU_LINES and shown>0 then
                lines=lines+1; local line=m.lines[lines]; line:ClearAllPoints()
                line:SetPoint("TOPLEFT",m,"TOPLEFT",8,y-3); line:SetWidth(w-16); line:Show(); y=y-7
            end
        else
            shown=shown+1; local b=m.buttons[shown]; b.itemIndex=i
            ns.Size(b,w-6,22); b:ClearAllPoints(); b:SetPoint("TOPLEFT",m,"TOPLEFT",3,y)
            local active=item.isActive; if type(active)=="function" then active=active() end
            b.text:SetText(item.text)
            if active then b.text:SetTextColor(ar,ag,ab) else b.text:SetTextColor(1,1,1) end
            if item.isInput then b.input:SetText(tostring(item.getValue and item.getValue() or "")); b.input:Show() else b.input:Hide() end
            b:Show(); y=y-24
        end
    end
    local more=m.offset>0 or i<#m.items
    if more then m.hint:SetText("Mouse wheel: more options"); m.hint:Show(); y=y-19 else m.hint:Hide() end
    ns.Size(m,w,-y+3)
end
local function SavePosition(cfg,f)
    local x,y=f:GetCenter(); local ux,uy=UIParent:GetCenter(); local factor=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
    cfg.savedPos={point="CENTER",relPoint="CENTER",x=x*factor-ux,y=y*factor-uy}
end
local function Position(cfg,f)
    local p=cfg.savedPos or {point="BOTTOMRIGHT",relPoint="BOTTOMRIGHT",x=-10,y=180}
    f:ClearAllPoints(); f:SetPoint(p.point or "CENTER",UIParent,p.relPoint or p.point or "CENTER",p.x or 0,p.y or 0)
end
local function Settings(index)
    ns.selectedWindow=index
    if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end
    if E.ShowModule then E:ShowModule(ADDON) end
end
ns.OpenSettings=Settings
local function MetricMenu(index,anchor)
    local items={}
    for _,m in ipairs(ns.metrics) do local key=m.key
        items[#items+1]={text=m.label,fn=function() ns.Profile().windows[index].metric=key; ns.windows[index].offset=0; ns.Refresh() end}
    end
    ns.OpenMenu(anchor,items)
end
function ns.SegmentChoices()
    local values,order={current="Current / Last",overall="Overall"},{"current","overall"}
    for _,s in ipairs(ns.history.segments) do
        values[s.id]="#"..s.id.." "..s.label.." ("..math.floor(s.duration).."s)"; order[#order+1]=s.id
    end
    return values,order
end
local function Border(cfg) return ns.Clamp(cfg.borderSize,0,4) end
function ns.WindowHeight(cfg) return Border(cfg)*2+cfg.headerHeight+cfg.rows*(cfg.rowHeight+cfg.barSpacing) end
function ns.RowsForHeight(cfg,h) return ns.Clamp(math.floor((h-Border(cfg)*2-cfg.headerHeight)/(cfg.rowHeight+cfg.barSpacing)+.5),1,40) end
function ns.SelectSegment(index,key)
    local windows=ns.Profile().windows; local cfg=windows[index]; if not cfg then return end
    cfg.segment=key
    if cfg.syncSegments then
        for _,other in ipairs(windows) do if other.syncSegments and other.metric~="threat" then other.segment=key end end
    end
    for i in ipairs(windows) do local r=ns.windows[i]; if r and windows[i].segment==key then r.offset=0 end end
    ns.Refresh()
end
local function SegmentMenu(index,anchor)
    local cfg=ns.Profile().windows[index]; if not cfg or cfg.metric=="threat" then return end
    local items={}; local values,order=ns.SegmentChoices()
    for i,key in ipairs(order) do local choice=key
        if i==3 then items[#items+1]="---" end
        items[#items+1]={text=values[key],isActive=tostring(cfg.segment)==tostring(key),fn=function() ns.SelectSegment(index,choice) end}
    end
    ns.OpenMenu(anchor,items,230)
end
local function InstanceHidden(cfg)
    local inside,kind
    if IsInInstance then inside,kind=IsInInstance() end
    if not inside then return cfg.hideOutOfInstance end
    return kind=="party" and cfg.hideInDungeon or kind=="raid" and cfg.hideInRaid or (kind=="pvp" or kind=="arena") and cfg.hideInPvP
end
ns.InstanceHidden=InstanceHidden
-- Instance entry/exit flips windows with Auto Swap between Current and Overall.
function ns.InstanceChanged()
    local inside=IsInInstance and IsInInstance() and true or false
    if ns.wasInInstance~=nil and inside~=ns.wasInInstance and ns.Profile() then
        for _,cfg in ipairs(ns.Profile().windows) do
            if cfg.autoSwapInstance and cfg.metric~="threat" then cfg.segment=inside and "current" or "overall" end
        end
    end
    ns.wasInInstance=inside
end
local function SettingsMenu(index,anchor)
    local function Cfg() return ns.Profile().windows[index] end
    local function Toggle(text,key,tooltip)
        return {text=text,tooltip=tooltip,keepOpen=true,isActive=function() local c=Cfg(); return c and c[key] end,
            fn=function() local c=Cfg(); if c then c[key]=not c[key]; ns.Refresh() end end}
    end
    local function AutoCurrent()
        local c=Cfg(); if c.autoCurrentOnCombat==nil then return ns.Profile().autoCurrent end
        return c.autoCurrentOnCombat
    end
    local cfg=Cfg()
    ns.OpenMenu(anchor,{
        Toggle("Hide in Dungeons","hideInDungeon"),
        Toggle("Hide in Raids","hideInRaid"),
        Toggle("Hide in PvP","hideInPvP","Battlegrounds and arenas"),
        Toggle("Hide out of Instances","hideOutOfInstance"),
        "---",
        {text="Width",isInput=true,getValue=function() return Cfg().width end,
         setValue=function(v) Cfg().width=ns.Clamp(v,ns.MIN_WIDTH,ns.MAX_WIDTH); ns.Apply() end},
        {text="Height",isInput=true,getValue=function() return math.floor(ns.WindowHeight(Cfg())+.5) end,
         setValue=function(v) local c=Cfg(); c.rows=ns.Clamp(math.floor((v-Border(c)*2-c.headerHeight)/(c.rowHeight+c.barSpacing)),1,40); ns.Apply() end},
        {text=cfg.snapDisabled and "Enable Snapping" or "Disable Snapping",tooltip="Snap this window to nearby meter windows while dragging or resizing",
         fn=function() local c=Cfg(); c.snapDisabled=not c.snapDisabled end},
        Toggle("Hide Timer","hideTimer"),
        Toggle("Auto Swap Current/Overall","autoSwapInstance","Switch this window to Overall when you leave a dungeon or raid, and to Current when you enter one"),
        {text="Auto Current on Combat",tooltip="Entering combat switches this window back to Current if viewing a past segment",keepOpen=true,
         isActive=AutoCurrent,fn=function() Cfg().autoCurrentOnCombat=not AutoCurrent() end},
        Toggle("Sync Segment Selection","syncSegments","Selecting a segment switches all synced windows to it"),
        {text="Report",fn=function() ns.ShowReport(index) end},
        {text="Settings",fn=function() Settings(index) end},
    },190)
end
-- Right click is navigation: details go back, the group view opens the
-- bookmark/segment home, and the home closes again.
function ns.RightClick(index)
    local r=ns.windows[index]; if not r then return end
    ns.CloseMenu(); ns.HideBreakdownTooltip()
    if r.home and r.home:IsShown() then ns.HideHome(index)
    elseif r.focusGUID then ns.BackToGroup(index)
    elseif ns.ShowHome then ns.ShowHome(index) end
end
-- Hover state drives the mouseover header icons and the grip/padlock fade.
local hoverDriver=nativeCreateFrame("Frame"); hoverDriver:Hide(); ns.hoverDriver=hoverDriver
local function Over(f)
    if f.IsMouseOver then return f:IsMouseOver() and true or false end
    return MouseIsOver~=nil and MouseIsOver(f) and true or false
end
function ns.PaintGrip(index)
    local r,cfg=ns.windows[index],ns.Profile().windows[index]; if not r or not cfg then return end
    local base=(r.fade or 0)*.3
    r.grip:SetAlpha(cfg.locked and 0 or r.grip.hover and .7 or base)
    r.lock:SetAlpha(r.lock.hover and .7 or base)
end
function ns.StartHover(index,header)
    local r=ns.windows[index]; if not r then return end
    r.hoverActive=true; r.fadeTarget=1
    if header and not r.headerHover then
        r.headerHover=true
        local cfg=ns.Profile().windows[index]; if cfg and cfg.mouseoverIcons then ns.RefreshWindow(index) end
    end
    hoverDriver:Show()
end
hoverDriver:SetScript("OnUpdate",function(self,dt)
    self.poll=(self.poll or 0)+dt
    local poll=self.poll>=.1; if poll then self.poll=0 end
    local busy=false; local p=ns.Profile()
    for index,r in pairs(ns.windows) do
        local cfg=p and p.windows[index]
        if r.hoverActive and poll then
            local shown=cfg and r.frame:IsShown()
            local header=shown and (r.drag or Over(r.header)) and true or false
            if header~=(r.headerHover or false) then r.headerHover=header; if cfg.mouseoverIcons then ns.RefreshWindow(index) end end
            if not (shown and (r.drag or r.resizing or Over(r.frame))) then r.hoverActive=false; r.fadeTarget=0 end
        end
        local target,fade=r.fadeTarget or 0,r.fade or 0
        if fade~=target then
            local s=dt/.12
            fade=target>fade and math.min(target,fade+s) or math.max(target,fade-s)
            r.fade=fade; ns.PaintGrip(index)
        end
        if r.hoverActive or fade~=target then busy=true end
    end
    if not busy then self:Hide() end
end)
local function NewRow(parent,index)
    local r=nativeCreateFrame("Button",nil,parent)
    r.windowIndex=index
    r.bg=r:CreateTexture(nil,"BACKGROUND"); r.bg:SetTexture(white); r.bg:SetAllPoints(r); r.bg:SetVertexColor(0,0,0,0)
    r.bar=nativeCreateFrame("StatusBar",nil,r); r.bar:SetAllPoints(r); r.bar:SetStatusBarTexture(white); r.barInset=0
    r.bar:SetFrameLevel(r:GetFrameLevel()); r.textHost=nativeCreateFrame("Frame",nil,r); r.textHost:SetAllPoints(r); r.textHost:SetFrameLevel(r.bar:GetFrameLevel()+1)
    r.border=nativeCreateFrame("Frame",nil,r); r.border:SetAllPoints(r); r.border:SetFrameLevel(r.textHost:GetFrameLevel()+1); r.border:Hide()
    r.icon=r.textHost:CreateTexture(nil,"ARTWORK"); r.icon:SetPoint("LEFT",r,"LEFT",0,0); r.icon:Hide()
    r.label=ns.Text(r.textHost); r.label:SetPoint("LEFT",r.bar,"LEFT",3,0)
    r.value=ns.Text(r.textHost); r.value:SetPoint("RIGHT",r.bar,"RIGHT",-3,0); r.value:SetJustifyH("RIGHT")
    r.hl=r.textHost:CreateTexture(nil,"BACKGROUND"); r.hl:SetTexture(white); r.hl:SetAllPoints(r); r.hl:SetVertexColor(1,1,1,.08); r.hl:Hide()
    r:SetScript("OnClick",function(self,button)
        if button=="RightButton" then ns.RightClick(self.windowIndex); return end
        if not self.data then return end
        ns.HideBreakdownTooltip()
        if not self.data.breakdown and IsShiftKeyDown and IsShiftKeyDown() then ns.ShowDetail(self.data,self.metric,self.segment,"spells")
        elseif not self.data.breakdown then ns.FocusWindow(self.windowIndex,self.data)
        elseif self.data.entry and self.data.entry.id and self.data.entry.id>0 then ns.ShowBreakdownTooltip(self) end
    end)
    r:RegisterForClicks("LeftButtonUp","RightButtonUp")
    r:SetScript("OnEnter",function(self)
        ns.StartHover(self.windowIndex)
        if not self.data then return end
        self.hl:Show()
        local cfg=ns.Profile().windows[self.windowIndex]
        local entry=self.data.breakdown and self.data.entry
        if cfg and cfg.spellTooltips and entry and entry.id and entry.id>0 and self.focusMode~="targets" then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetHyperlink("spell:"..entry.id); GameTooltip:Show(); self.spellTip=true
        elseif not cfg or cfg.hoverBreakdown~=false then ns.ShowBreakdownTooltip(self) end
    end)
    r:SetScript("OnLeave",function(self) self.hl:Hide(); ns.HideBreakdownTooltip(self); if self.spellTip then self.spellTip=nil; GameTooltip:Hide() end end)
    r:SetScript("OnHide",function(self) self.hl:Hide(); ns.HideBreakdownTooltip(self) end); return r
end
local function Register(index,cfg)
    if ns.registered[index] then ns.registered[index].label=cfg.name; return end
    if not E.RegisterUnlockElements or not E.MakeUnlockElement then return end
    local elem=E.MakeUnlockElement({key="EDM_"..index,label=cfg.name,group="Damage Meters",order=950+index,noResize=true,noAnchorTo=true,
        getFrame=function() return ns.windows[index] and ns.windows[index].frame end,
        getSize=function() local f=ns.windows[index] and ns.windows[index].frame; return f and f:GetWidth() or 310,f and f:GetHeight() or 210 end,
        isHidden=function() local c=ns.Profile() and ns.Profile().windows[index]; return not c or not ns.Profile().enabled or not c.enabled end,
        savePos=function(_,point,relPoint,x,y) local c=ns.Profile().windows[index]; if c then c.savedPos={point=point,relPoint=relPoint,x=x,y=y} end end,
        loadPos=function() local c=ns.Profile().windows[index]; return c and c.savedPos end,
        clearPos=function() local c=ns.Profile().windows[index]; if c then c.savedPos=nil end end,
        applyPos=function() local c=ns.Profile().windows[index]; local r=ns.windows[index]; if c and r then Position(c,r.frame) end end})
    ns.registered[index]=elem; E:RegisterUnlockElements({elem},ADDON)
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}; E._ELEMENT_SETTINGS_MAP["EDM_"..index]={module=ADDON,page="Windows",sectionName="WINDOW SETTINGS",highlightText="Select Window"}
end
local function Cursor(f) local x,y=GetCursorPosition(); local s=f:GetEffectiveScale(); return x/s,y/s end
local function Screen(f)
    local s=f and f:GetScale() or 1
    return (UIParent:GetWidth() or 1920)/s,(UIParent:GetHeight() or 1080)/s
end
-- Dragging and growing need a fixed top-left corner.
local function AnchorTopLeft(f)
    local l,t=f:GetLeft(),f:GetTop(); if not l or not t then return end
    f:ClearAllPoints(); f:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",l,t)
end
local function Snap(value,candidates)
    local best,dist=value,math.huge
    for i=1,#candidates,2 do
        local d=math.abs(candidates[i]-value)
        if d<=SNAP_THRESH and d<dist then best,dist=candidates[i+1],d end
    end
    return best,dist
end
-- Edge snapping against the nearest shown meter window.
function ns.SnapPosition(index,left,top)
    local cfg,r=ns.Profile().windows[index],ns.windows[index]
    if not cfg or cfg.snapDisabled or not r then return left,top end
    local w,h=r.frame:GetWidth(),r.frame:GetHeight()
    local bestX,bestY,dx,dy=left,top,math.huge,math.huge
    for i,o in pairs(ns.windows) do
        local of=o.frame
        if i~=index and ns.Profile().windows[i] and of:IsShown() then
            local ol,orr,ot,ob=of:GetLeft(),of:GetRight(),of:GetTop(),of:GetBottom()
            if ol and orr and ot and ob then
                local x,d=Snap(left,{ol,ol,orr,orr,ol-w,ol-w,orr-w,orr-w})
                if d<dx then bestX,dx=x,d end
                local y,e=Snap(top,{ot,ot,ob,ob,ot+h,ot+h,ob+h,ob+h})
                if e<dy then bestY,dy=y,e end
            end
        end
    end
    return bestX,bestY
end
function ns.StartDrag(index)
    local r,cfg=ns.windows[index],ns.Profile().windows[index]
    if not r or not cfg or cfg.locked or r.resizing then return end
    AnchorTopLeft(r.frame)
    local x,y=Cursor(r.frame)
    r.drag={x=x,y=y,left=r.frame:GetLeft() or 0,top=r.frame:GetTop() or 0}; r.dragMoved=nil
    r.title:SetScript("OnUpdate",r.dragStep)
end
function ns.DragStep(index)
    local r=ns.windows[index]; local d=r and r.drag; if not d then return end
    if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then ns.StopDrag(index); return end
    local x,y=Cursor(r.frame); local dx,dy=x-d.x,y-d.y
    if not d.moved and math.abs(dx)+math.abs(dy)>2 then d.moved=true; ns.CloseMenu(); ns.HideBreakdownTooltip() end
    if not d.moved then return end
    local left,top=ns.SnapPosition(index,d.left+dx,d.top+dy)
    r.frame:ClearAllPoints(); r.frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left,top)
end
function ns.StopDrag(index)
    local r=ns.windows[index]; local d=r and r.drag; if not d then return end
    r.drag=nil; r.title:SetScript("OnUpdate",nil); r.dragMoved=d.moved
    local cfg=ns.Profile().windows[index]
    if d.moved and cfg then SavePosition(cfg,r.frame) end
end
local function SnapSize(index,w,h)
    local cfg=ns.Profile().windows[index]; if cfg.snapDisabled then return w,h end
    local bw,bh,dw,dh=w,h,math.huge,math.huge
    for i,o in pairs(ns.windows) do
        if i~=index and ns.Profile().windows[i] and o.frame:IsShown() then
            local ow,oh=o.frame:GetWidth(),o.frame:GetHeight()
            local d=math.abs(w-ow); if d<=SNAP_THRESH and d<dw then bw,dw=ow,d end
            d=math.abs(h-oh); if d<=SNAP_THRESH and d<dh then bh,dh=oh,d end
        end
    end
    return bw,bh
end
-- Corner grip: Shift locks the first axis moved; height converts to rows.
function ns.StartResize(index)
    local r,cfg=ns.windows[index],ns.Profile().windows[index]
    if not r or not cfg or cfg.locked or r.resizing or r.drag then return end
    AnchorTopLeft(r.frame)
    local x,y=Cursor(r.frame)
    r.resizing={x=x,y=y,w=r.frame:GetWidth(),h=r.frame:GetHeight()}
    ns.CloseMenu(); ns.HideBreakdownTooltip(); GameTooltip:Hide()
    r.grip:SetScript("OnUpdate",r.resizeStep)
end
function ns.ResizeStep(index)
    local r,cfg=ns.windows[index],ns.Profile().windows[index]; local s=r and r.resizing
    if not s or not cfg then return end
    if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then ns.StopResize(index); return end
    local x,y=Cursor(r.frame); local dx,dy=x-s.x,s.y-y
    if IsShiftKeyDown and IsShiftKeyDown() then
        if not s.axis and math.abs(dx)+math.abs(dy)>3 then s.axis=math.abs(dx)>=math.abs(dy) and "x" or "y" end
        if s.axis=="x" then dy=0 elseif s.axis=="y" then dx=0 end
    else s.axis=nil end
    local sw,sh=Screen(r.frame); local left,top=r.frame:GetLeft() or 0,r.frame:GetTop() or sh
    local minH=Border(cfg)*2+cfg.headerHeight+cfg.rowHeight+cfg.barSpacing
    local w=ns.Clamp(s.w+dx,ns.MIN_WIDTH,math.max(ns.MIN_WIDTH,math.min(ns.MAX_WIDTH,sw-left)))
    local h=ns.Clamp(s.h+dy,minH,math.max(minH,math.min(ns.MAX_WIDTH,top)))
    w,h=SnapSize(index,w,h)
    w=math.floor(w+.5); local rows=ns.RowsForHeight(cfg,h)
    if w~=cfg.width or rows~=cfg.rows then
        cfg.width,cfg.rows=w,rows; ns.Size(r.frame,w,ns.WindowHeight(cfg)); ns.RefreshWindow(index)
        if r.home and r.home:IsShown() and ns.PaintHome then ns.PaintHome(index) end
    end
end
function ns.StopResize(index)
    local r=ns.windows[index]; if not r or not r.resizing then return end
    r.resizing=nil; r.grip:SetScript("OnUpdate",nil)
    local cfg=ns.Profile().windows[index]
    if cfg then SavePosition(cfg,r.frame) end
    ns.Apply()
end
function ns.UpdateLock(index)
    local r,cfg=ns.windows[index],ns.Profile().windows[index]; if not r or not cfg then return end
    r.lock.tex:SetTexture(ns.MEDIA..(cfg.locked and "dm_locked.tga" or "dm_unlocked.tga"))
    r.lock:ClearAllPoints()
    if cfg.locked then r.lock:SetPoint("BOTTOMRIGHT",r.frame,"BOTTOMRIGHT",-4,4) else r.lock:SetPoint("RIGHT",r.grip,"LEFT",-2,0) end
    r.grip:EnableMouse(not cfg.locked)
    if index~=1 then r.action.disabled=cfg.locked and true or false; PaintIcon(r.action) end
end
local function CreateGrip(r,index)
    local f=r.frame
    local g=nativeCreateFrame("Button",nil,f); ns.Size(g,18,18); g:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-2,2)
    g:SetFrameLevel(f:GetFrameLevel()+15); g:SetAlpha(0)
    g.tex=g:CreateTexture(nil,"ARTWORK"); g.tex:SetAllPoints(g); g.tex:SetTexture(ns.MEDIA.."resize_element.tga"); g.tex:SetDesaturated(true)
    g:SetScript("OnEnter",function(self) self.hover=true; ns.StartHover(index); ns.PaintGrip(index) end)
    g:SetScript("OnLeave",function(self) self.hover=false; ns.PaintGrip(index) end)
    g:SetScript("OnMouseDown",function(_,button) if button=="LeftButton" then ns.StartResize(index) end end)
    g:SetScript("OnMouseUp",function() ns.StopResize(index) end)
    g:SetScript("OnHide",function() if r.resizing then ns.StopResize(index) end end)
    r.grip=g
    local l=nativeCreateFrame("Button",nil,f); ns.Size(l,13,17); l:SetFrameLevel(f:GetFrameLevel()+16); l:SetAlpha(0)
    l.tex=l:CreateTexture(nil,"ARTWORK"); l.tex:SetAllPoints(l); l.tex:SetDesaturated(true); l.tex:SetTexCoord(unpack(LOCK_COORDS))
    local function Tip(self) local c=ns.Profile().windows[index]; ShowTip(self,c and c.locked and "Locked" or "Unlocked") end
    l:SetScript("OnEnter",function(self) self.hover=true; ns.StartHover(index); ns.PaintGrip(index); Tip(self) end)
    l:SetScript("OnLeave",function(self) self.hover=false; ns.PaintGrip(index); GameTooltip:Hide() end)
    l:SetScript("OnClick",function(self)
        local c=ns.Profile().windows[index]; if not c then return end
        c.locked=not c.locked; ns.UpdateLock(index); ns.PaintGrip(index); Tip(self)
    end)
    r.lock=l
end
function ns.CreateWindow(index)
    local r={rows={},offset=0,fade=0,fadeTarget=0}; local f=nativeCreateFrame("Frame","EUI335DamageMeter_"..index,UIParent)
    r.frame=f; f:SetFrameStrata("LOW"); f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true)
    r.dragStep=function() ns.DragStep(index) end
    r.resizeStep=function() ns.ResizeStep(index) end
    f:SetScript("OnEnter",function() ns.StartHover(index) end)
    local header=nativeCreateFrame("Frame",nil,f); r.header=header; header:SetFrameLevel(f:GetFrameLevel()+5)
    header.bg=header:CreateTexture(nil,"BACKGROUND"); header.bg:SetTexture(white); header.bg:SetAllPoints(header)
    r.headerLine=header:CreateTexture(nil,"OVERLAY"); r.headerLine:SetTexture(white); r.headerLine:Hide()
    r.title=nativeCreateFrame("Button",nil,header); r.title:SetAllPoints(header); r.title:SetFrameLevel(header:GetFrameLevel()+1)
    r.title:RegisterForClicks("LeftButtonUp","RightButtonUp")
    r.title.text=ns.Text(r.title,11); r.title.text:SetPoint("LEFT",r.title,"LEFT",6,0)
    r.timer=ns.Text(r.title,11); r.timer:SetPoint("LEFT",r.title.text,"RIGHT",4,0); r.timer:SetTextColor(1,1,1,.7); r.timer:Hide()
    r.title:SetScript("OnMouseDown",function(_,button) if button=="LeftButton" then ns.StartDrag(index) end end)
    r.title:SetScript("OnMouseUp",function(_,button) if button=="LeftButton" then ns.StopDrag(index) end end)
    r.title:SetScript("OnClick",function(self,button)
        local moved=r.dragMoved; r.dragMoved=nil
        if button=="RightButton" then ns.RightClick(index)
        elseif moved then return
        elseif r.focusGUID then ns.FocusModeMenu(index,self)
        else MetricMenu(index,self) end
    end)
    r.title:SetScript("OnEnter",function() ns.StartHover(index,true) end)
    r.title:SetScript("OnHide",function() ns.StopDrag(index) end)
    local function Icon(file,tip,fn)
        local b=ns.HeaderIcon(header,file,tip,fn); b:SetFrameLevel(header:GetFrameLevel()+2)
        b.onEnter=function() ns.StartHover(index,true) end; return b
    end
    r.settings=Icon("dm_settings.tga","Settings",function(self) SettingsMenu(index,self) end)
    r.segment=Icon("dm_sheet.tga","Select Segment",function(self) SegmentMenu(index,self) end)
    r.mode=Icon("dm_home_damage.tga","Switch Meter Type",function(self) if r.focusGUID then ns.FocusModeMenu(index,self) else MetricMenu(index,self) end end)
    r.reset=Icon("dm_reset.tga","Reset Data",function() ns.ShowReset() end)
    if index==1 then
        r.action=Icon("dm_open.tga","New Window",function() ns.NewWindow() end)
        r.action.disabledTip="You may only have "..ns.MAX_WINDOWS.." windows active"
    else
        r.action=Icon("dm_close.tga","Close Window",function() ns.DeleteWindow(index) end)
        r.action.disabledTip="Unlock Window to Close"
        r.action.icon:ClearAllPoints(); r.action.icon:SetPoint("TOPLEFT",r.action,"TOPLEFT",-1,1); r.action.icon:SetPoint("BOTTOMRIGHT",r.action,"BOTTOMRIGHT",1,-1)
    end
    r.headerButtons={r.settings,r.segment,r.mode,r.reset,r.action}
    r.back=Icon("dm_undo.tga","Back to group (right click)",function() ns.BackToGroup(index) end); r.back:Hide()
    r.empty=ns.Text(f); r.empty:SetPoint("CENTER",f,"CENTER",0,0); r.empty:SetText("Waiting for combat data")
    f:EnableMouseWheel(true); f:SetScript("OnMouseWheel",function(_,delta) r.offset=math.max(0,r.offset-delta); ns.RefreshWindow(index) end)
    f:SetScript("OnMouseUp",function(_,button) if button=="RightButton" then ns.RightClick(index) end end)
    f:SetScript("OnHide",function() ns.HideWindowBreakdown(index); if ns.HideHome then ns.HideHome(index) end end)
    -- Preallocate all rows; live combat updates never construct a row frame.
    for i=1,40 do r.rows[i]=NewRow(f,index); r.rows[i]:Hide() end
    CreateGrip(r,index)
    ns.CreateBreakdownTooltip()
    ns.windows[index]=r; return r
end
-- Right to left: Settings, Segment, Meter Type, Reset, then + / x.
function ns.LayoutHeader(index,cfg)
    local r=ns.windows[index]; local hh=cfg.headerHeight
    local shown=not cfg.mouseoverIcons or r.headerHover or ns.preview
    local n=0
    for _,b in ipairs(r.headerButtons) do
        if b==r.reset and cfg.hideResetButton or b==r.segment and cfg.metric=="threat" then b:Hide()
        else
            n=n+1; ns.Size(b,hh,hh); b:ClearAllPoints(); b:SetPoint("RIGHT",r.header,"RIGHT",-(hh*(n-1)-2*n+2),0)
            b:SetAlpha(shown and 1 or 0); b:EnableMouse(shown and true or false); b:Show()
        end
    end
    r.iconCount=shown and n or 0
end
function ns.RefreshWindow(index)
    local p=ns.Profile(); local cfg=p.windows[index]; local r=ns.windows[index]; if not cfg or not r then return end
    local visible=p.enabled and cfg.enabled and (ns.preview or not ns.toggleHidden and not InstanceHidden(cfg) and (cfg.visibility=="always"
        or cfg.visibility=="combat" and ns.current~=nil or cfg.visibility=="group" and (GetNumPartyMembers()>0 or GetNumRaidMembers()>0)))
    if not visible then ns.HideWindowBreakdown(index); r.frame:Hide(); return end
    r.frame:Show()
    local rows,s=ns.Rows(cfg.segment,cfg.metric); local m=ns.metricMap[cfg.metric] or ns.metricMap.damage
    if r.focusGUID and (r.focusConfig~=cfg or r.focusMetric~=cfg.metric or r.focusSegment~=cfg.segment) then
        r.focusGUID=nil; r.offset=0; ns.HideWindowBreakdown(index)
    end
    local actorRow
    if r.focusGUID then rows,actorRow=ns.FocusRows(index,cfg,rows,s) end
    local b,hh=Border(cfg),cfg.headerHeight
    r.mode.icon:SetTexture(ns.MetricIcon and ns.MetricIcon(cfg.metric) or ns.MEDIA.."dm_home_damage.tga")
    if index==1 then r.action.disabled=#p.windows>=ns.MAX_WINDOWS; PaintIcon(r.action) end
    ns.LayoutHeader(index,cfg)
    local titleX=6
    if r.focusGUID then
        ns.Size(r.back,hh,hh); r.back:ClearAllPoints(); r.back:SetPoint("LEFT",r.header,"LEFT",2,0); r.back:Show(); titleX=hh+4
    else r.back:Hide() end
    r.title.text:ClearAllPoints(); r.title.text:SetPoint("LEFT",r.title,"LEFT",titleX,0)
    local count=ns.Clamp(cfg.rows,1,40); r.offset=ns.Clamp(r.offset,0,math.max(0,#rows-count))
    local title,timer
    if r.focusGUID then
        title=r.focusName.." - "..(cfg.metric=="deaths" and ("Death "..(r.focusDeath or 1)) or r.focusMode=="targets" and "Targets" or m.label)
    elseif cfg.metric=="threat" then title=m.label.."  "..(UnitName("target") or "Target")
    else
        local values=ns.SegmentChoices(); local seg=cfg.segment=="current" and "Current" or cfg.segment=="overall" and "Overall" or (s and s.label) or values[cfg.segment] or "Expired"
        title=m.label.." - "..seg
    end
    if s and not cfg.hideTimer and cfg.metric~="threat" then local d=math.floor(ns.Duration(s)); timer=string.format("(%d:%02d)",math.floor(d/60),d%60) end
    r.title.text:SetWidth(0); r.title.text:SetText(title)
    if timer then r.timer:SetText(timer); r.timer:Show() else r.timer:Hide() end
    local room=cfg.width-b*2-titleX-4-(r.iconCount or 0)*(hh-2)-(timer and r.timer:GetStringWidth()+4 or 0)
    r.title.text:SetWidth(math.max(20,math.min(room,r.title.text:GetStringWidth()+2)))
    r.empty:SetText(r.focusGUID and "No data for this player in this view" or "Waiting for combat data")
    if #rows==0 then r.empty:Show() else r.empty:Hide() end
    local max=.0001; for _,data in ipairs(rows) do max=math.max(max,data.value) end
    -- Visible slots: rank numbers stay true when the player is pinned last.
    local ranks={}
    for i=1,count do ranks[i]=i+r.offset end
    if cfg.alwaysShowPlayer and not r.focusGUID then
        local me=UnitGUID("player")
        for i,data in ipairs(rows) do
            if data.guid==me then if i>r.offset+count then ranks[count]=i end; break end
        end
    end
    local top=b+hh; local step=cfg.rowHeight+cfg.barSpacing; local rowW=cfg.width-b*2
    local alpha=ns.Clamp(cfg.barAlpha==nil and 1 or cfg.barAlpha,0,1)
    local texture=ns.BarTexturePath(cfg.barTexture); local bgc=cfg.barBgColor
    local style=cfg.showSpecIcons==false and "none" or cfg.iconStyle or "spec"
    local borderSize=ns.Clamp(cfg.barBorderSize,0,3); local bc=cfg.barBorderColor
    for i,row in ipairs(r.rows) do
        local rank=i<=count and ranks[i]; local data=rank and rows[rank]
        if data then
            row.data,row.metric,row.segment,row.actorRow,row.focusMode=data,cfg.metric,s,actorRow,r.focusMode
            row:ClearAllPoints(); row:SetPoint("TOPLEFT",r.frame,"TOPLEFT",b,-top-(i-1)*step); ns.Size(row,rowW,cfg.rowHeight)
            row.bar:SetStatusBarTexture(texture)
            local cr,cg,cb
            if cfg.barColorMode=="custom" then cr,cg,cb=cfg.barColor.r,cfg.barColor.g,cfg.barColor.b
            elseif cfg.barColorMode=="accent" then cr,cg,cb=Accent()
            else cr,cg,cb=Color(data.class) end
            if data.recap then
                -- Death recap rows show the victim's health when the hit landed.
                row.bar:SetMinMaxValues(0,1); row.bar:SetValue(data.hp or 0)
                if data.heal then cr,cg,cb=.1,.5,.1 else cr,cg,cb=.6,.08,.08 end
            else row.bar:SetMinMaxValues(0,max); row.bar:SetValue(data.value) end
            row.bar:SetStatusBarColor(cr,cg,cb,alpha)
            row.bg:SetVertexColor(bgc.r or .1,bgc.g or .1,bgc.b or .1,bgc.a or 0)
            if borderSize>0 then
                if row.borderSize~=borderSize then row.border:SetBackdrop({edgeFile=white,edgeSize=borderSize}); row.borderSize=borderSize end
                row.border:SetBackdropBorderColor(bc.r or 0,bc.g or 0,bc.b or 0,1); row.border:Show()
            else row.border:Hide() end
            ns.Font(row.label,cfg.fontSize,cfg.fontOutline); ns.Font(row.value,cfg.valueFontSize or cfg.fontSize,cfg.fontOutline)
            local icon,coords,specName
            if data.breakdown then icon=data.icon
            elseif style=="class" then icon,coords=ns.RowIcon({guid="",class=data.class})
            elseif style=="spec" then icon,coords,specName=ns.RowIcon(data) end
            local inset=0
            row.specName=nil
            if icon then
                inset=cfg.rowHeight
                ns.Size(row.icon,inset,inset); row.icon:SetTexture(icon)
                if coords then row.icon:SetTexCoord(unpack(coords)) else row.icon:SetTexCoord(.08,.92,.08,.92) end
                row.icon:Show(); row.specName=specName
            else row.icon:Hide() end
            if row.barInset~=inset then
                row.barInset=inset; row.bar:ClearAllPoints()
                row.bar:SetPoint("TOPLEFT",row,"TOPLEFT",inset,0); row.bar:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",0,0)
            end
            local fmt=cfg.numberFormat
            local value
            if data.recap then value=ns.RecapAmount(data.entry,data.fatal)
            else
                value=ns.Format(data.value,fmt)
                if cfg.showRate and not m.rate and (cfg.metric=="damage" or cfg.metric=="healing") then value=value.." ("..ns.Format(data.rate,fmt).."/s)" end
                if cfg.showPercent then value=value..string.format(" %.1f%%",data.percent or 0) end
            end
            row.value:SetText(value); local reserved=math.min(rowW*.62,row.value:GetStringWidth()+6)
            row.value:SetWidth(reserved); row.value:SetHeight(cfg.rowHeight); row.label:SetHeight(cfg.rowHeight)
            local name=data.breakdown and data.name or (cfg.hideRank and data.name or rank..". "..data.name)
            row.label:SetWidth(math.max(20,rowW-inset-reserved-9)); row.label:SetText(name); row:Show()
        else row.data=nil; row.icon:Hide(); row:Hide() end
    end
    ns.UpdateWindowBreakdown(index)
    if r.home and r.home:IsShown() and ns.PaintHome then ns.PaintHome(index) end
end
function ns.Refresh()
    if not ns.Profile() then return end
    for i in ipairs(ns.Profile().windows) do ns.RefreshWindow(i) end
    if ns.UpdateTimer then ns.UpdateTimer() end
end
local function SameValue(a,b)
    if type(a)=="table" and type(b)=="table" then
        return math.abs((a.r or 0)-(b.r or 0))<.002 and math.abs((a.g or 0)-(b.g or 0))<.002 and math.abs((a.b or 0)-(b.b or 0))<.002
    end
    return a==b
end
-- One-time switch to the Retail look for windows still on the old defaults.
function ns.MigrateStyle(p)
    for _,cfg in ipairs(p.windows) do
        if cfg.titleUseAccent==nil then cfg.titleUseAccent=cfg.titleColor==nil or SameValue(cfg.titleColor,{r=1,g=1,b=1}) end
        for _,change in ipairs(ns.styleMigration) do
            if cfg[change[1]]==nil or SameValue(cfg[change[1]],change[2]) then cfg[change[1]]=ns.Copy(change[3]) end
        end
    end
    p.styleVersion=2
end
function ns.Apply()
    local p=ns.Profile(); if not p then return end
    ns.TrimHistory()
    if ns.events then
        if p.enabled then ns.events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") else ns.events:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED"); ns.Finish() end
    end
    -- The DB re-adds removed default windows on login; the count keeps them deleted.
    if not p.windowCount then p.windowCount=#p.windows end
    while #p.windows>math.max(1,math.min(p.windowCount,ns.MAX_WINDOWS)) do table.remove(p.windows) end
    p.windowCount=#p.windows
    if (p.styleVersion or 1)<2 then ns.MigrateStyle(p) end
    for index,cfg in ipairs(p.windows) do
        -- Added windows are outside the default array entries.
        -- Fill their new fields as well, preserving explicit zero/false values.
        for _,key in ipairs({"fontOutline","barAlpha","chromeAlpha","showSpecIcons"}) do
            if cfg[key]==nil then cfg[key]=ns.defaults.profile.windows[1][key] end
        end
        for key,value in pairs(ns.windowExtras) do if cfg[key]==nil then cfg[key]=ns.Copy(value) end end
        cfg.width=ns.Clamp(cfg.width,ns.MIN_WIDTH,ns.MAX_WIDTH); cfg.rows=ns.Clamp(cfg.rows,1,40); cfg.rowHeight=ns.Clamp(cfg.rowHeight,14,36)
        cfg.fontSize=ns.Clamp(cfg.fontSize,8,20); cfg.valueFontSize=ns.Clamp(cfg.valueFontSize,8,20)
        cfg.headerHeight=ns.Clamp(cfg.headerHeight,16,34); cfg.barSpacing=ns.Clamp(cfg.barSpacing,0,10)
        cfg.titleFontSize=ns.Clamp(cfg.titleFontSize,8,20)
        local hh=cfg.headerHeight
        local r=ns.windows[index] or ns.CreateWindow(index)
        ns.Size(r.frame,cfg.width,ns.WindowHeight(cfg))
        r.frame:SetScale(ns.Clamp(cfg.scale,.5,2)); Position(cfg,r.frame)
        local border=Border(cfg); local bg=cfg.bgColor
        r.frame:SetBackdrop(border>0 and {bgFile=white,edgeFile=white,edgeSize=border} or {bgFile=white})
        r.frame:SetBackdropColor(bg.r or 0,bg.g or 0,bg.b or 0,ns.Clamp(cfg.alpha,0,1))
        if border>0 then
            if cfg.borderUseAccent~=false then r.frame:SetBackdropBorderColor(Accent())
            else r.frame:SetBackdropBorderColor(cfg.borderColor.r,cfg.borderColor.g,cfg.borderColor.b,1) end
        end
        r.header:ClearAllPoints(); r.header:SetPoint("TOPLEFT",r.frame,"TOPLEFT",border,-border); r.header:SetPoint("TOPRIGHT",r.frame,"TOPRIGHT",-border,-border)
        r.header:SetHeight(hh)
        local chrome=ns.Clamp(cfg.chromeAlpha==nil and 1 or cfg.chromeAlpha,0,1); local hc=cfg.headerColor
        r.header.bg:SetVertexColor(hc.r or .106,hc.g or .106,hc.b or .106,chrome)
        ns.Font(r.title.text,cfg.titleFontSize,cfg.fontOutline); ns.Font(r.timer,cfg.titleFontSize,cfg.fontOutline)
        r.title.text:SetHeight(hh); r.timer:SetHeight(hh)
        if cfg.titleUseAccent~=false then r.title.text:SetTextColor(Accent())
        else r.title.text:SetTextColor(cfg.titleColor.r,cfg.titleColor.g,cfg.titleColor.b) end
        local lineSize=ns.Clamp(cfg.headerBorderSize,0,4)
        r.headerLine:ClearAllPoints()
        r.headerLine:SetPoint("TOPLEFT",r.header,"BOTTOMLEFT",0,0); r.headerLine:SetPoint("TOPRIGHT",r.header,"BOTTOMRIGHT",0,0)
        r.headerLine:SetHeight(math.max(1,lineSize))
        r.headerLine:SetVertexColor(cfg.headerBorderColor.r,cfg.headerBorderColor.g,cfg.headerBorderColor.b,1)
        if lineSize>0 then r.headerLine:Show() else r.headerLine:Hide() end
        ns.Font(r.empty,cfg.fontSize,cfg.fontOutline)
        ns.UpdateLock(index); ns.PaintGrip(index)
        Register(index,cfg)
    end
    for index,r in pairs(ns.windows) do if not p.windows[index] then r.focusGUID=nil; r.frame:Hide() end end
    if not p.enabled then ns.reportQueue=nil; ns.CloseMenu(); if ns.detail then ns.detail:Hide() end; if ns.report then ns.report:Hide() end; if ns.resetDialog then ns.resetDialog:Hide() end end
    for index,r in pairs(ns.windows) do if r.home and r.home:IsShown() and ns.PaintHome then ns.PaintHome(index) end end
    ns.Refresh()
    if ns.ApplyExtras then ns.ApplyExtras() end
end
-- New windows copy window 1 and open above the highest window, or below
-- the lowest one when the screen top has no room.
function ns.NewWindow()
    local p=ns.Profile(); local windows=p.windows
    if #windows>=ns.MAX_WINDOWS then return end
    local src=windows[1]
    local cfg=ns.Copy(src); cfg.name="Meter "..(#windows+1); cfg.enabled=true; cfg.locked=false; cfg.segment="current"
    cfg.metric=src.metric=="damage" and "healing" or "damage"
    local scale=ns.Clamp(cfg.scale,.5,2); local w,h=cfg.width*scale,ns.WindowHeight(cfg)*scale
    local _,sh=Screen(); local high,low
    for i in ipairs(windows) do
        local r=ns.windows[i]
        if r and r.frame:IsShown() then
            local f=r.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
            local t,bt,l=(r.frame:GetTop() or 0)*f,(r.frame:GetBottom() or 0)*f,(r.frame:GetLeft() or 0)*f
            if not high or t>high.t then high={t=t,l=l} end
            if not low or bt<low.b then low={b=bt,l=l} end
        end
    end
    local ux,uy=UIParent:GetCenter(); local cx,cy
    if high and high.t+4+h<=sh then cx,cy=high.l+w/2,high.t+4+h/2
    elseif low and low.b-4-h>=0 then cx,cy=low.l+w/2,low.b-4-h/2 end
    cfg.savedPos=cx and {point="CENTER",relPoint="CENTER",x=cx-ux,y=cy-uy} or {point="CENTER",relPoint="CENTER",x=0,y=0}
    windows[#windows+1]=cfg; p.windowCount=#windows; ns.selectedWindow=#windows
    ns.Apply()
    if ns.ShowHome then ns.ShowHome(#windows) end
end
function ns.DeleteWindow(index)
    local p=ns.Profile(); local cfg=p and p.windows[index]
    if not cfg or index==1 or cfg.locked then return end
    table.remove(p.windows,index); p.windowCount=#p.windows
    ns.HideBreakdownTooltip(); ns.CloseMenu()
    for _,r in pairs(ns.windows) do r.focusGUID=nil; r.offset=0; if r.home then r.home:Hide() end end
    if (ns.selectedWindow or 1)>#p.windows then ns.selectedWindow=#p.windows end
    ns.Apply()
end
function ns.ShowDetail(row,metric,segment,mode)
    if metric=="threat" then return end
    local f=ns.detail
    if not f then
        f=nativeCreateFrame("Frame",nil,UIParent); ns.Size(f,510,480); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:SetClampedToScreen(true); ns.Skin(f)
        f.title=ns.Text(f,13); f.title:SetPoint("TOPLEFT",f,"TOPLEFT",12,-12); f.title:SetWidth(455)
        f.close=ns.Button(f,"X",22,22,function() f:Hide(); GameTooltip:Hide() end); f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-5,-5)
        f.spells=ns.Button(f,"Spells",120,24,function() f.mode="spells"; f.offset=0; ns.PaintDetail() end); f.spells:SetPoint("TOPLEFT",f,"TOPLEFT",8,-36)
        f.targets=ns.Button(f,"Targets",120,24,function() f.mode="targets"; f.offset=0; ns.PaintDetail() end); f.targets:SetPoint("LEFT",f.spells,"RIGHT",4,0)
        f.previous=ns.Button(f,"Previous Death",135,24,function() f.deathIndex=math.max(1,f.deathIndex-1); f.offset=0; ns.PaintDetail() end); f.previous:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",8,8)
        f.next=ns.Button(f,"Next Death",135,24,function() f.deathIndex=math.min(#f.deathList,f.deathIndex+1); f.offset=0; ns.PaintDetail() end); f.next:SetPoint("LEFT",f.previous,"RIGHT",4,0)
        f.note=ns.Text(f,10); f.note:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-8,12)
        f.rows={}; f:EnableMouseWheel(true); f:SetScript("OnMouseWheel",function(_,delta) f.offset=ns.Clamp(f.offset-delta,0,math.max(0,#(f.entries or {})-18)); ns.PaintDetail() end)
        for i=1,18 do
            local b=ns.Button(f,"",494,20,function(self) if self.entry and self.entry.id and self.entry.id>0 then
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetHyperlink("spell:"..self.entry.id); GameTooltip:Show()
            end end)
            b.text:SetJustifyH("LEFT"); b:SetPoint("TOPLEFT",f,"TOPLEFT",8,-66-(i-1)*21); f.rows[i]=b
        end
        ns.detail=f
    end
    f.row,f.metric,f.segment,f.mode,f.offset,f.deathIndex=row,metric,segment,mode or "spells",0,1
    f.deathList={}; for _,d in ipairs(segment and segment.deaths or {}) do if d.guid==row.guid then f.deathList[#f.deathList+1]=d end end
    f:Show(); ns.PaintDetail()
end
function ns.PaintDetail()
    local f=ns.detail; if not f or not f:IsShown() then return end
    local deaths=f.metric=="deaths"; local m=ns.metricMap[f.metric]; local entries={}
    f.spells:Hide(); f.targets:Hide(); f.previous:Hide(); f.next:Hide()
    if deaths then
        local d=f.deathList[f.deathIndex]; entries=d and d.logs or {}
        f.previous:Show(); f.next:Show(); f.note:SetText("Death "..f.deathIndex.." / "..#f.deathList)
    else
        entries=ns.Breakdown(f.row,f.metric,f.mode); f.spells:Show(); f.targets:Show(); f.note:SetText("Scroll for more; click a spell for tooltip")
    end
    f.entries=entries; f.title:SetText(f.row.name.." - "..(m and m.label or f.metric))
    for i,b in ipairs(f.rows) do local entry=entries[i+f.offset]; b.entry=entry
        if entry then
            local text
            if deaths then local death=f.deathList[f.deathIndex]
                text=string.format("%+.1fs  %s%s  %s (%s)",entry.at-death.at,entry.kind=="heal" and "+" or "-",ns.Format(entry.amount),entry.name,entry.source)
            else
                text=entry.name.."  "..ns.Format(entry.total)
                if entry.hits and f.metric~="buffUptime" and f.metric~="debuffUptime" then
                    text=text.."  "..entry.hits.." hits / "..entry.crit.." crits  ["..ns.Format(entry.min).."-"..ns.Format(entry.max).."]"
                elseif f.metric=="buffUptime" or f.metric=="debuffUptime" then text=text.." seconds" end
            end
            b.text:SetText(text); b:Show()
        else b:Hide() end
    end
end
function ns.ReportLines(index,limit)
    local cfg=ns.Profile().windows[index]; local rows,s=ns.Rows(cfg.segment,cfg.metric)
    local m=ns.metricMap[cfg.metric] or ns.metricMap.damage
    local window=ns.windows[index]
    if window and window.focusGUID then rows=ns.FocusRows(index,cfg,rows,s) end
    local lines={"EllesmereUI - "..(window and window.focusGUID and window.focusName.." - " or "")..m.label.." - "..(s and s.label or UnitName("target") or "Target")}
    for i=1,math.min(#rows,ns.Clamp(limit or 5,1,10)) do
        local r=rows[i]; lines[#lines+1]=i..". "..r.name..": "..ns.Format(r.value)..(r.recap and "" or string.format(" (%.1f%%)",r.percent or 0))
    end
    return lines
end
function ns.SendReport(lines,channel)
    if channel=="PARTY" and GetNumPartyMembers()==0 or channel=="RAID" and GetNumRaidMembers()==0
        or channel=="GUILD" and not IsInGuild() then return false end
    -- Only called by the user's Send button. A local copy/preview sends nothing.
    ns.reportQueue={lines=ns.Copy(lines),channel=channel,index=1,elapsed=.5}
    return true
end
function ns.ShowReport(index)
    local f=ns.report
    if not f then
        f=nativeCreateFrame("Frame",nil,UIParent); ns.Size(f,480,290); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); ns.Skin(f)
        local title=ns.Text(f,13); title:SetPoint("TOPLEFT",f,"TOPLEFT",10,-10); title:SetText("Combat Report")
        f.close=ns.Button(f,"X",22,22,function() f:Hide() end); f.close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-5,-5)
        f.box=nativeCreateFrame("EditBox",nil,f); ns.Size(f.box,456,185); f.box:SetPoint("TOPLEFT",f,"TOPLEFT",12,-38)
        f.box:SetMultiLine(true); f.box:SetAutoFocus(false); ns.Font(f.box,11)
        f.box:SetScript("OnEscapePressed",function(self) self:ClearFocus(); f:Hide() end)
        f.box:SetScript("OnHide",function(self) self:ClearFocus() end)
        f.channel="PARTY"
        f.choose=ns.Button(f,"Channel: Party",160,24,function(self)
            local items={}; for _,c in ipairs({"PARTY","RAID","GUILD","SAY"}) do local channel=c
                items[#items+1]={text=c,fn=function() f.channel=channel; f.choose.text:SetText("Channel: "..channel) end}
            end; ns.OpenMenu(self,items)
        end); f.choose:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",10,10)
        f.send=ns.Button(f,"Send",120,24,function() if not ns.SendReport(f.lines,f.channel) then
            f.choose.text:SetText("Channel unavailable")
        else f:Hide() end end); f.send:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-10,10)
        ns.report=f
    end
    f.lines=ns.ReportLines(index); f.box:SetText(table.concat(f.lines,"\n")); f.box:ClearFocus(); f:Show()
end
function ns.ShowReset()
    if ns.resetDialog then ns.resetDialog:Show(); return end
    local f=nativeCreateFrame("Frame",nil,UIParent); ns.Size(f,350,95); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); ns.Skin(f)
    local text=ns.Text(f,12); text:SetPoint("TOPLEFT",f,"TOPLEFT",10,-12); text:SetText("Clear all combat history and overall totals?")
    ns.Button(f,"Clear",145,24,function() if ns.Reset() then f:Hide() else text:SetText("Finish combat before clearing history.") end end):SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",10,10)
    ns.Button(f,"Cancel",145,24,function() f:Hide() end):SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-10,10)
    ns.resetDialog=f
end
local reportDriver=nativeCreateFrame("Frame")
reportDriver:SetScript("OnUpdate",function(_,dt)
    local q=ns.reportQueue; if not q then return end
    q.elapsed=q.elapsed+dt; if q.elapsed<.5 then return end; q.elapsed=0
    if q.channel=="PARTY" and GetNumPartyMembers()==0 or q.channel=="RAID" and GetNumRaidMembers()==0 then ns.reportQueue=nil; return end
    SendChatMessage(q.lines[q.index]:sub(1,240),q.channel); q.index=q.index+1
    if q.index>#q.lines then ns.reportQueue=nil end
end)
SLASH_EUI335DM1="/edm"
SlashCmdList.EUI335DM=function(message)
    if message=="show" then for _,c in ipairs(ns.Profile().windows) do c.enabled=true end; ns.toggleHidden=nil; ns.Apply()
    elseif message=="hide" then for _,c in ipairs(ns.Profile().windows) do c.enabled=false end; ns.Apply()
    elseif message=="toggle" and ns.ToggleWindows then ns.ToggleWindows()
    elseif message=="reset" then ns.ShowReset()
    elseif message=="report" then ns.ShowReport(ns.selectedWindow or 1)
    elseif message=="spells" and ns.OpenSpellHistorySettings then ns.OpenSpellHistorySettings()
    else Settings(ns.selectedWindow or 1) end
end
