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
function ns.Skin(f,alpha)
    f:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); f:SetBackdropColor(.025,.035,.045,alpha or .96)
    f:SetBackdropBorderColor(Accent())
end
local function ButtonBackground(b,alpha,color)
    b.bgAlpha=alpha; b.bgColor=color
    b:SetBackdropColor(color and color.r or .025,color and color.g or .035,color and color.b or .045,alpha)
end
function ns.Button(parent,text,w,h,fn)
    local b=nativeCreateFrame("Button",nil,parent); ns.Size(b,w or 24,h or 22); ns.Skin(b,.85)
    b.text=ns.Text(b,10); b.text:SetAllPoints(b); b.text:SetJustifyH("CENTER"); b.text:SetText(text)
    b:SetScript("OnClick",fn); b:SetScript("OnEnter",function(self) self:SetBackdropColor(.08,.15,.16,math.min(1,(self.bgAlpha or .85)+.15)) end)
    b:SetScript("OnLeave",function(self) local c=self.bgColor; self:SetBackdropColor(c and c.r or .025,c and c.g or .035,c and c.b or .045,self.bgAlpha or .85) end); return b
end
ns.MEDIA="Interface\\AddOns\\EllesmereUIDamageMeters\\Media_335\\"
function ns.IconButton(parent,icon,w,h,fn,tip)
    local b=ns.Button(parent,"",w,h,fn)
    b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetTexture(ns.MEDIA..icon)
    b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",4,-4); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-4,4)
    local enter,leave=b:GetScript("OnEnter"),b:GetScript("OnLeave")
    b:SetScript("OnEnter",function(self) enter(self); if tip then GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(tip); GameTooltip:Show() end end)
    b:SetScript("OnLeave",function(self) leave(self); if tip then GameTooltip:Hide() end end)
    return b
end
local resourceTextures={"atrocity","beautiful","divide","fade","fade-right","glass","gradient-bt","gradient-lr","gradient-rl","gradient-tb","matte","plating","sheer","thin-line-bottom","thin-line-top"}
local function SharedMedia()
    local ok,lsm=pcall(LibStub,"LibSharedMedia-3.0",true)
    return ok and type(lsm)=="table" and lsm.Fetch and lsm or nil
end
function ns.BarTexturePath(key)
    if not key or key=="none" then return white end
    if key=="blizzard" then return "Interface\\TargetingFrame\\UI-StatusBar" end
    if key:sub(1,4)=="lsm:" then
        local lsm=SharedMedia(); local ok,path=lsm and pcall(lsm.Fetch,lsm,"statusbar",key:sub(5),true)
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
function ns.WindowHeight(cfg) return cfg.headerHeight+8+cfg.rows*(cfg.rowHeight+cfg.barSpacing) end
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
    ns.OpenMenu(anchor,{
        Toggle("Hide in Dungeons","hideInDungeon"),
        Toggle("Hide in Raids","hideInRaid"),
        Toggle("Hide in PvP","hideInPvP","Battlegrounds and arenas"),
        Toggle("Hide out of Instances","hideOutOfInstance"),
        "---",
        {text="Width",isInput=true,getValue=function() return Cfg().width end,
         setValue=function(v) Cfg().width=ns.Clamp(v,220,650); ns.Apply() end},
        {text="Height",isInput=true,getValue=function() return math.floor(ns.WindowHeight(Cfg())+.5) end,
         setValue=function(v) local c=Cfg(); c.rows=ns.Clamp(math.floor((v-c.headerHeight-8)/(c.rowHeight+c.barSpacing)),1,40); ns.Apply() end},
        Toggle("Lock Position","locked","Prevents dragging this window by its header"),
        Toggle("Hide Timer","hideTimer"),
        Toggle("Auto Swap Current/Overall","autoSwapInstance","Switch this window to Overall when you leave a dungeon or raid, and to Current when you enter one"),
        {text="Auto Current on Combat",tooltip="Entering combat switches this window back to Current if viewing a past segment",keepOpen=true,
         isActive=AutoCurrent,fn=function() Cfg().autoCurrentOnCombat=not AutoCurrent() end},
        Toggle("Sync Segment Selection","syncSegments","Selecting a segment switches all synced windows to it"),
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
local function NewRow(parent,index)
    local r=nativeCreateFrame("Button",nil,parent)
    r.windowIndex=index
    r.bg=r:CreateTexture(nil,"BACKGROUND"); r.bg:SetTexture(white); r.bg:SetAllPoints(r); r.bg:SetVertexColor(0,0,0,0)
    r.bar=nativeCreateFrame("StatusBar",nil,r); r.bar:SetAllPoints(r); r.bar:SetStatusBarTexture(white)
    r.bar:SetFrameLevel(r:GetFrameLevel()); r.textHost=nativeCreateFrame("Frame",nil,r); r.textHost:SetAllPoints(r); r.textHost:SetFrameLevel(r.bar:GetFrameLevel()+1)
    r.border=nativeCreateFrame("Frame",nil,r); r.border:SetAllPoints(r); r.border:SetFrameLevel(r.textHost:GetFrameLevel()+1); r.border:Hide()
    r.icon=r.textHost:CreateTexture(nil,"ARTWORK"); r.icon:SetPoint("LEFT",r.textHost,"LEFT",4,0); r.icon:Hide()
    r.label=ns.Text(r.textHost); r.label:SetPoint("LEFT",r.textHost,"LEFT",5,0)
    r.value=ns.Text(r.textHost); r.value:SetPoint("RIGHT",r.textHost,"RIGHT",-5,0); r.value:SetJustifyH("RIGHT")
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
        if not self.data then return end
        local cfg=ns.Profile().windows[self.windowIndex]
        local entry=self.data.breakdown and self.data.entry
        if cfg and cfg.spellTooltips and entry and entry.id and entry.id>0 and self.focusMode~="targets" then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetHyperlink("spell:"..entry.id); GameTooltip:Show(); self.spellTip=true
        elseif not cfg or cfg.hoverBreakdown~=false then ns.ShowBreakdownTooltip(self) end
    end)
    r:SetScript("OnLeave",function(self) ns.HideBreakdownTooltip(self); if self.spellTip then self.spellTip=nil; GameTooltip:Hide() end end)
    r:SetScript("OnHide",function(self) ns.HideBreakdownTooltip(self) end); return r
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
function ns.CreateWindow(index)
    local r={rows={},offset=0}; local f=nativeCreateFrame("Frame","EUI335DamageMeter_"..index,UIParent)
    r.frame=f; f:SetFrameStrata("LOW"); f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true)
    r.title=ns.Button(f,"",220,22,function(self,button)
        if button=="RightButton" then ns.RightClick(index)
        elseif r.focusGUID then ns.FocusModeMenu(index,self)
        else MetricMenu(index,self) end
    end); r.title:SetPoint("TOPLEFT",f,"TOPLEFT",3,-3)
    r.title.text:ClearAllPoints(); r.title.text:SetPoint("LEFT",r.title,"LEFT",7,0); r.title.text:SetPoint("RIGHT",r.title,"RIGHT",-4,0); r.title.text:SetJustifyH("LEFT")
    r.title:RegisterForClicks("LeftButtonUp","RightButtonUp")
    r.title:RegisterForDrag("LeftButton")
    r.title:SetScript("OnDragStart",function() local c=ns.Profile().windows[index]; if c and not c.locked then f:StartMoving() end end)
    r.title:SetScript("OnDragStop",function() f:StopMovingOrSizing(); local c=ns.Profile().windows[index]; if c then SavePosition(c,f) end end)
    r.close=ns.IconButton(f,"dm_close.tga",22,22,function() ns.Profile().windows[index].enabled=false; ns.Apply() end,"Hide window")
    r.settings=ns.IconButton(f,"dm_settings.tga",22,22,function(self) SettingsMenu(index,self) end,"Settings")
    r.segment=ns.IconButton(f,"dm_sheet.tga",22,22,function(self) SegmentMenu(index,self) end,"Select Segment")
    r.reset=ns.IconButton(f,"dm_reset.tga",22,22,function() ns.ShowReset() end,"Clear combat history")
    r.report=ns.IconButton(f,"dm_report.tga",22,22,function() ns.ShowReport(index) end,"Report")
    r.headerButtons={r.close,r.settings,r.segment,r.reset,r.report}
    r.headerLine=f:CreateTexture(nil,"OVERLAY"); r.headerLine:SetTexture(white); r.headerLine:Hide()
    r.back=ns.IconButton(f,"dm_undo.tga",22,22,function() ns.BackToGroup(index) end,"Back to group (right click)")
    r.back:SetPoint("TOPLEFT",f,"TOPLEFT",3,-3); r.back:Hide()
    r.empty=ns.Text(f); r.empty:SetPoint("CENTER",f,"CENTER",0,0); r.empty:SetText("Waiting for combat data")
    f:EnableMouseWheel(true); f:SetScript("OnMouseWheel",function(_,delta) r.offset=math.max(0,r.offset-delta); ns.RefreshWindow(index) end)
    f:SetScript("OnMouseUp",function(_,button) if button=="RightButton" then ns.RightClick(index) end end)
    f:SetScript("OnHide",function() ns.HideWindowBreakdown(index); if ns.HideHome then ns.HideHome(index) end end)
    -- Preallocate all rows; live combat updates never construct a row frame.
    for i=1,40 do r.rows[i]=NewRow(f,index); r.rows[i]:Hide() end
    ns.CreateBreakdownTooltip()
    ns.windows[index]=r; return r
end
function ns.RefreshWindow(index)
    local cfg=ns.Profile().windows[index]; local r=ns.windows[index]; if not cfg or not r then return end
    local visible=ns.Profile().enabled and cfg.enabled and (ns.preview or not InstanceHidden(cfg) and (cfg.visibility=="always"
        or cfg.visibility=="combat" and ns.current~=nil or cfg.visibility=="group" and (GetNumPartyMembers()>0 or GetNumRaidMembers()>0)))
    if not visible then ns.HideWindowBreakdown(index); r.frame:Hide(); return end
    r.frame:Show()
    local rows,s=ns.Rows(cfg.segment,cfg.metric); local m=ns.metricMap[cfg.metric] or ns.metricMap.damage
    if r.focusGUID and (r.focusConfig~=cfg or r.focusMetric~=cfg.metric or r.focusSegment~=cfg.segment) then
        r.focusGUID=nil; r.offset=0; ns.HideWindowBreakdown(index)
    end
    local actorRow
    if r.focusGUID then rows,actorRow=ns.FocusRows(index,cfg,rows,s) end
    local step=cfg.headerHeight+2; local titleX=r.focusGUID and step+3 or 3
    if r.focusGUID then r.back:Show() else r.back:Hide() end
    r.title:ClearAllPoints(); r.title:SetPoint("TOPLEFT",r.frame,"TOPLEFT",titleX,-3)
    r.title:SetWidth(math.max(40,cfg.width-titleX-3-#r.headerButtons*step))
    if cfg.metric=="threat" then r.segment:Hide() else r.segment:Show() end
    local count=ns.Clamp(cfg.rows,1,40); r.offset=ns.Clamp(r.offset,0,math.max(0,#rows-count))
    local title
    if r.focusGUID then
        title=r.focusName.." - "..(cfg.metric=="deaths" and ("Death "..(r.focusDeath or 1)) or r.focusMode=="targets" and "Targets" or m.label)
    elseif cfg.metric=="threat" then title=m.label.."  "..(UnitName("target") or "Target")
    else
        local values=ns.SegmentChoices(); local seg=cfg.segment=="current" and "Current" or cfg.segment=="overall" and "Overall" or (s and s.label) or values[cfg.segment] or "Expired"
        title=m.label.." - "..seg
        if s and not cfg.hideTimer then local d=math.floor(ns.Duration(s)); title=title..string.format("  %d:%02d",math.floor(d/60),d%60) end
    end
    r.title.text:SetText(title)
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
    local top=cfg.headerHeight+6; local step=cfg.rowHeight+cfg.barSpacing
    local alpha=ns.Clamp(cfg.barAlpha==nil and 1 or cfg.barAlpha,0,1)
    local texture=ns.BarTexturePath(cfg.barTexture); local bgc=cfg.barBgColor
    local style=cfg.showSpecIcons==false and "none" or cfg.iconStyle or "spec"
    local borderSize=ns.Clamp(cfg.barBorderSize,0,3); local bc=cfg.barBorderColor
    for i,row in ipairs(r.rows) do
        local rank=i<=count and ranks[i]; local data=rank and rows[rank]
        if data then
            row.data,row.metric,row.segment,row.actorRow,row.focusMode=data,cfg.metric,s,actorRow,r.focusMode
            row:ClearAllPoints(); row:SetPoint("TOPLEFT",r.frame,"TOPLEFT",3,-top-(i-1)*step); ns.Size(row,cfg.width-6,cfg.rowHeight)
            row.bar:SetStatusBarTexture(texture)
            row.bar:SetMinMaxValues(0,max); row.bar:SetValue(data.value)
            local cr,cg,cb
            if cfg.barColorMode=="custom" then cr,cg,cb=cfg.barColor.r,cfg.barColor.g,cfg.barColor.b
            elseif cfg.barColorMode=="accent" then cr,cg,cb=Accent()
            else cr,cg,cb=Color(data.class) end
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
            local iconSize=cfg.rowHeight-2; local textX=5
            row.specName=nil
            if icon then
                ns.Size(row.icon,iconSize,iconSize); row.icon:SetTexture(icon)
                if coords then row.icon:SetTexCoord(unpack(coords)) else row.icon:SetTexCoord(.08,.92,.08,.92) end
                row.icon:Show(); textX=iconSize+8; row.specName=specName
            else row.icon:Hide() end
            row.label:ClearAllPoints(); row.label:SetPoint("LEFT",row.textHost,"LEFT",textX,0)
            local fmt=cfg.numberFormat
            local value=ns.Format(data.value,fmt)
            if cfg.showRate and not m.rate and (cfg.metric=="damage" or cfg.metric=="healing") then value=value.." ("..ns.Format(data.rate,fmt).."/s)" end
            if cfg.showPercent and not data.recap then value=value..string.format(" %.1f%%",data.percent or 0) end
            row.value:SetText(value); local reserved=math.min(cfg.width*.62,row.value:GetStringWidth()+10)
            row.value:SetWidth(reserved); row.value:SetHeight(cfg.rowHeight); row.label:SetHeight(cfg.rowHeight)
            local name=data.breakdown and data.name or (cfg.hideRank and data.name or rank..". "..data.name)
            row.label:SetWidth(math.max(20,cfg.width-reserved-textX-10)); row.label:SetText(name); row:Show()
        else row.data=nil; row.icon:Hide(); row:Hide() end
    end
    ns.UpdateWindowBreakdown(index)
    if r.home and r.home:IsShown() and ns.PaintHome then ns.PaintHome(index) end
end
function ns.Refresh()
    if not ns.Profile() then return end
    for i in ipairs(ns.Profile().windows) do ns.RefreshWindow(i) end
end
function ns.Apply()
    local p=ns.Profile(); if not p then return end
    ns.TrimHistory()
    if ns.events then
        if p.enabled then ns.events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") else ns.events:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED"); ns.Finish() end
    end
    for index,cfg in ipairs(p.windows) do
        -- Existing third/fourth windows are outside the default array entries.
        -- Fill their new fields as well, preserving explicit zero/false values.
        for _,key in ipairs({"fontOutline","barAlpha","chromeAlpha","showSpecIcons"}) do
            if cfg[key]==nil then cfg[key]=ns.defaults.profile.windows[1][key] end
        end
        for key,value in pairs(ns.windowExtras) do if cfg[key]==nil then cfg[key]=ns.Copy(value) end end
        cfg.width=ns.Clamp(cfg.width,220,650); cfg.rows=ns.Clamp(cfg.rows,1,40); cfg.rowHeight=ns.Clamp(cfg.rowHeight,14,36)
        cfg.fontSize=ns.Clamp(cfg.fontSize,8,20); cfg.valueFontSize=ns.Clamp(cfg.valueFontSize,8,20)
        cfg.headerHeight=ns.Clamp(cfg.headerHeight,16,34); cfg.barSpacing=ns.Clamp(cfg.barSpacing,0,10)
        cfg.titleFontSize=ns.Clamp(cfg.titleFontSize,8,20)
        local hh=cfg.headerHeight
        local r=ns.windows[index] or ns.CreateWindow(index)
        ns.Size(r.frame,cfg.width,ns.WindowHeight(cfg))
        r.frame:SetScale(ns.Clamp(cfg.scale,.5,2)); Position(cfg,r.frame)
        local border=ns.Clamp(cfg.borderSize,0,4); local bg=cfg.bgColor
        r.frame:SetBackdrop(border>0 and {bgFile=white,edgeFile=white,edgeSize=border} or {bgFile=white})
        r.frame:SetBackdropColor(bg.r or .025,bg.g or .035,bg.b or .045,ns.Clamp(cfg.alpha,0,1))
        if border>0 then
            if cfg.borderUseAccent~=false then r.frame:SetBackdropBorderColor(Accent())
            else r.frame:SetBackdropBorderColor(cfg.borderColor.r,cfg.borderColor.g,cfg.borderColor.b,1) end
        end
        local chrome=ns.Clamp(cfg.chromeAlpha==nil and .85 or cfg.chromeAlpha,0,1)
        for _,b in ipairs({r.title,r.settings,r.close,r.segment,r.report,r.reset,r.back}) do
            ButtonBackground(b,chrome,cfg.headerColor)
            ns.Font(b.text,10,cfg.fontOutline)
        end
        ns.Font(r.title.text,cfg.titleFontSize,cfg.fontOutline)
        r.title.text:SetTextColor(cfg.titleColor.r,cfg.titleColor.g,cfg.titleColor.b)
        r.title:SetHeight(hh); ns.Size(r.back,hh,hh)
        for i,b in ipairs(r.headerButtons) do
            ns.Size(b,hh,hh); b:ClearAllPoints(); b:SetPoint("TOPRIGHT",r.frame,"TOPRIGHT",-3-(i-1)*(hh+2),-3)
        end
        local lineSize=ns.Clamp(cfg.headerBorderSize,0,4)
        r.headerLine:ClearAllPoints()
        r.headerLine:SetPoint("TOPLEFT",r.frame,"TOPLEFT",3,-(hh+3)); r.headerLine:SetPoint("TOPRIGHT",r.frame,"TOPRIGHT",-3,-(hh+3))
        r.headerLine:SetHeight(math.max(1,lineSize))
        r.headerLine:SetVertexColor(cfg.headerBorderColor.r,cfg.headerBorderColor.g,cfg.headerBorderColor.b,1)
        if lineSize>0 then r.headerLine:Show() else r.headerLine:Hide() end
        ns.Font(r.empty,cfg.fontSize,cfg.fontOutline)
        Register(index,cfg)
    end
    for index,r in pairs(ns.windows) do if not p.windows[index] then r.focusGUID=nil; r.frame:Hide() end end
    if not p.enabled then ns.reportQueue=nil; ns.CloseMenu(); if ns.detail then ns.detail:Hide() end; if ns.report then ns.report:Hide() end; if ns.resetDialog then ns.resetDialog:Hide() end end
    for index,r in pairs(ns.windows) do if r.home and r.home:IsShown() and ns.PaintHome then ns.PaintHome(index) end end
    ns.Refresh()
end
function ns.NewWindow()
    if #ns.Profile().windows>=4 then return end
    local cfg=ns.Copy(ns.defaults.profile.windows[1]); cfg.name="Meter "..(#ns.Profile().windows+1); cfg.enabled=true
    cfg.savedPos={point="CENTER",relPoint="CENTER",x=0,y=0}; table.insert(ns.Profile().windows,cfg); ns.selectedWindow=#ns.Profile().windows; ns.Apply()
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
    if message=="show" then for _,c in ipairs(ns.Profile().windows) do c.enabled=true end; ns.Apply()
    elseif message=="hide" then for _,c in ipairs(ns.Profile().windows) do c.enabled=false end; ns.Apply()
    elseif message=="reset" then ns.ShowReset()
    elseif message=="report" then ns.ShowReport(ns.selectedWindow or 1)
    else Settings(ns.selectedWindow or 1) end
end
