local ADDON,ns=...
local E=EllesmereUI
local white="Interface\\Buttons\\WHITE8X8"
local LOGO="Interface\\AddOns\\EllesmereUI\\media\\eg-logo.tga"
local NEEDLE_DOTS=7
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function Font(fs,cfg)
 local path=E.GetFontPath and E.GetFontPath("quickdraw") or "Fonts\\FRIZQT__.TTF"
 if not fs:SetFont(path,cfg.textSize or 11,cfg.fontOutline or "OUTLINE") then fs:SetFont("Fonts\\FRIZQT__.TTF",11,"OUTLINE") end
 fs:SetShadowColor(0,0,0,1); fs:SetShadowOffset(1,-1)
end
local function Tooltip(self)
 if not self.slot then return end
 GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); local kind,id=self.slot.kind,self.slot.id
 if kind=="spell" and tonumber(id) then GameTooltip:SetHyperlink("spell:"..id) elseif kind=="item" then GameTooltip:SetHyperlink("item:"..id)
 elseif kind=="worldmarker" and ns.worldMarkerItems[tonumber(id) or 0] then GameTooltip:SetHyperlink("item:"..ns.worldMarkerItems[tonumber(id)])
 else GameTooltip:AddLine(ns.Display(self.slot),1,1,1) end
 GameTooltip:Show()
end
local function Leave(self) if GameTooltip.GetOwner and GameTooltip:GetOwner()==self then GameTooltip:Hide() end end
-- Geometry shared by the live palettes and the options preview.
function ns.Layout(cfg,count,nests)
 local size=ns.Clamp(cfg.iconSize,24,80); local gap=ns.Clamp(cfg.spacing,0,30)
 local layout=cfg.layout=="GRID" and "GRID" or cfg.layout=="FAN" and "FAN" or "ARC"
 local columns
 if layout=="FAN" then columns=cfg.fanOrientation=="VERTICAL" and 1 or math.max(1,count)
 elseif cfg.autoColumns then columns=math.max(1,math.ceil(math.sqrt(count)))
 else columns=math.floor(ns.Clamp(cfg.columns,1,10)) end
 local rows=math.max(1,math.ceil(count/columns))
 -- Labels hang under each icon, so a labelled ring needs room between neighbours.
 local labelRoom=cfg.showLabels~=false and math.floor(size*.6) or 0
 local radius=math.max(ns.Clamp(cfg.radius,50,250)+labelRoom,(size+gap+labelRoom)*count/(2*math.pi))
 local width=layout=="ARC" and radius*2+size+gap or columns*(size+gap)+gap
 local height=layout=="ARC" and width or rows*(size+gap+20)+gap
 local span=ns.Clamp(cfg.arcSpan or 360,30,360)
 local pos,angles={},{}
 local spanRad=span*math.pi/180
 for j=1,count do local x,y
  if layout=="ARC" then local angle=math.pi/2-(cfg.arcRotation or 0)*math.pi/180
   if spanRad>=2*math.pi then angle=angle-(j-1)*spanRad/count else angle=angle+spanRad/2-(j-1)*spanRad/math.max(1,count-1) end
   angles[j]=angle; x,y=math.cos(angle)*radius,math.sin(angle)*radius
  else x=((j-1)%columns-(columns-1)/2)*(size+gap); y=(rows-1)/2*(size+gap+20)-math.floor((j-1)/columns)*(size+gap+20) end
  pos[j]={x,y}
 end
 local csize=math.floor(size*ns.Clamp(cfg.nestScale or .8,.4,1))
 local band=ns.Clamp(cfg.nestBand or 40,0,160)
 local geo={layout=layout,size=size,gap=gap,width=width,height=height,span=span,pos=pos,labelWidth=size+gap+(layout=="ARC" and labelRoom or 0),childSize=csize,childPos={},nestEdge=0}
 if not nests then return geo end
 local labelH=cfg.showLabels~=false and 14 or 0
 local extentX,extentY=width/2,height/2
 local function Place(list,x,y) list[#list+1]={x,y}; extentX=math.max(extentX,math.abs(x)+csize/2+gap); extentY=math.max(extentY,math.abs(y)+csize/2+labelH+gap) end
 if layout=="ARC" then
  -- Children ring outward from their parent, kept inside the parent's own sector.
  local sector=count<=1 and math.min(spanRad,2*math.pi) or (spanRad>=2*math.pi and 2*math.pi/count or spanRad/(count-1))
  local maxSpan=math.min(sector*.92,math.pi/2)
  local first=radius+size/2+band+csize/2
  geo.nestEdge=(radius+size/2+first-csize/2)/2
  for j=1,count do local n=nests[j] or 0
   if n>0 then local list,left,ring={},n,0
    while left>0 do local r=first+ring*(csize+gap+labelH)
     local m=ring>=3 and left or math.min(left,math.max(1,math.floor(maxSpan*r/(csize+gap))+1))
     local step=(csize+gap)/r; if m>1 and (m-1)*step>maxSpan then step=maxSpan/(m-1) end
     for t=1,m do local a=angles[j]+((m-1)/2-(t-1))*step; Place(list,math.cos(a)*r,math.sin(a)*r) end
     left,ring=left-m,ring+1
    end
    geo.childPos[j]=list
   end
  end
 else
  -- A lane outside the block on the edge nearest its parent; lanes that would overlap stack outward.
  local maxX,maxY=(columns-1)/2*(size+gap),(rows-1)/2*(size+gap+20)
  local top,bottom,right=maxY+size/2,-maxY-size/2-20,maxX+size/2
  local used={top={},bottom={},right={},left={}}
  for j=1,count do local n=nests[j] or 0
   if n>0 then local x,y=pos[j][1],pos[j][2]
    local edge,best="top",top-(y+size/2)
    for _,option in ipairs({{"right",right-(x+size/2)},{"bottom",(y-size/2-20)-bottom},{"left",(x-size/2)+right}}) do if option[2]<best then edge,best=option[1],option[2] end end
    local horizontal=edge=="top" or edge=="bottom"
    local pitch=horizontal and csize+gap or csize+gap+labelH
    local center=horizontal and x or y
    local low,high=center-n*pitch/2,center+n*pitch/2
    local level=0
    while true do local clash=false
     for _,span2 in ipairs(used[edge][level] or {}) do if low<span2[2] and high>span2[1] then clash=true end end
     if not clash then break end
     level=level+1
    end
    used[edge][level]=used[edge][level] or {}; table.insert(used[edge][level],{low,high})
    local list={}
    for t=1,n do local along=center+((t-1)-(n-1)/2)*pitch
     if edge=="top" then Place(list,along,top+band+csize/2+level*(csize+gap+labelH))
     elseif edge=="bottom" then Place(list,along,bottom-band-csize/2-level*(csize+gap+labelH))
     elseif edge=="right" then Place(list,right+band+csize/2+level*(csize+gap),y-((t-1)-(n-1)/2)*pitch)
     else Place(list,-right-band-csize/2-level*(csize+gap),y-((t-1)-(n-1)/2)*pitch) end
    end
    geo.childPos[j]=list
   end
  end
 end
 geo.width=math.max(width,2*extentX); geo.height=math.max(height,2*extentY)
 return geo
end
-- Entries a nested menu contributes: one level, so its own nested menus are left out.
function ns.NestChildren(target)
 local list={}
 for _,slot in ipairs(target and target.slots or {}) do
  if #list<8 and slot.kind~="palette" and not (target.hideUnusable~=false and ns.Unavailable(slot)) then list[#list+1]=slot end
 end
 return list
end
function ns.VisibleSlots(cfg)
 local list={}
 for _,slot in ipairs(cfg.slots or {}) do
  if #list<20 and not (cfg.hideUnusable~=false and ns.Unavailable(slot)) then list[#list+1]=slot end
 end
 return list
end
function ns.CreatePalettes()
 ns.header=CreateFrame("Frame","EUI335QuickdrawHeader",UIParent,"SecureHandlerBaseTemplate")
 ns.cancel=CreateFrame("Button","EUI335QuickdrawCancel",UIParent,"SecureHandlerBaseTemplate"); Size(ns.cancel,1,1); ns.cancel:SetAlpha(0); ns.cancel:EnableMouse(false); ns.cancel:RegisterForClicks("AnyUp"); ns.cancel:SetScript("OnClick",function() end)
 SecureHandlerWrapScript(ns.cancel,"OnClick",ns.header,ns.cancelSnippet)
 ns.cancel:SetScript("PostClick",function() if ns.pending and not InCombatLockdown() then C_Timer.After(0,ns.Apply) end end)
 ns.confirm=CreateFrame("Button","EUI335QuickdrawConfirm",UIParent,"SecureActionButtonTemplate"); Size(ns.confirm,1,1); ns.confirm:SetAlpha(0); ns.confirm:EnableMouse(false); ns.confirm:RegisterForClicks("AnyDown")
 ns.confirm:SetPoint("TOPLEFT",UIParent,"TOPLEFT",-100,100)
 SecureHandlerWrapScript(ns.confirm,"OnClick",ns.header,ns.confirmSnippet,ns.confirmPostSnippet)
 ns.confirm:SetScript("PostClick",function() if ns.pending and not InCombatLockdown() then C_Timer.After(0,ns.Apply) end end)
 for i=1,16 do
  local view=CreateFrame("Frame","EUI335QuickdrawView"..i,UIParent,"SecureHandlerBaseTemplate"); view:SetFrameStrata("DIALOG"); view:SetClampedToScreen(true); view:EnableMouse(true); view:EnableMouseWheel(true)
  view:SetScript("OnMouseWheel",function() end); SecureHandlerWrapScript(view,"OnMouseWheel",ns.header,ns.wheelSnippet)
  local driver=CreateFrame("Button","EUI335QuickdrawDriver"..i,UIParent,"SecureActionButtonTemplate"); Size(driver,1,1); driver:SetAlpha(0); driver:EnableMouse(false); driver:SetPoint("TOPLEFT",UIParent,"TOPLEFT",-100-i*2,100)
  driver:RegisterForClicks("AnyDown","AnyUp"); driver:SetAttribute("useOnKeyDown",false)
  driver:SetAttribute("paletteIndex",i)
  SecureHandlerSetFrameRef(driver,"view",view); SecureHandlerSetFrameRef(driver,"cancel",ns.cancel); SecureHandlerSetFrameRef(driver,"confirm",ns.confirm)
  SecureHandlerSetFrameRef(ns.header,"driver"..i,driver); SecureHandlerSetFrameRef(ns.header,"view"..i,view)
  SecureHandlerWrapScript(driver,"OnClick",ns.header,ns.preSnippet,ns.postSnippet)
  driver:SetScript("PostClick",function(_,_,down) if not down and ns.pending and not InCombatLockdown() then C_Timer.After(0,ns.Apply) end end)
  local live={view=view,driver=driver,pool={},needle={}}; ns.live[i]=live
  live.hub=view:CreateTexture(nil,"ARTWORK"); live.hub:SetTexture(LOGO); Size(live.hub,40,40); live.hub:SetPoint("CENTER",view,"CENTER",0,0); live.hub:Hide()
  for k=1,NEEDLE_DOTS do local dot=view:CreateTexture(nil,"ARTWORK"); dot:SetTexture(white); Size(dot,4,4); dot:Hide(); live.needle[k]=dot end
  for slot=1,20 do
   local b=CreateFrame("Button",nil,view,"SecureActionButtonTemplate"); b:RegisterForClicks("AnyUp"); b:SetBackdrop({edgeFile=white,edgeSize=1}); b:SetBackdropBorderColor(0,0,0,0)
   b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1); b.icon:SetTexCoord(.08,.92,.08,.92)
   b.cooldown=CreateFrame("Cooldown",nil,b); b.cooldown:SetAllPoints(b); b.cooldown.noCooldownCount=true
   b.textHost=CreateFrame("Frame",nil,b); b.textHost:SetAllPoints(b); b.textHost:SetFrameLevel(b.cooldown:GetFrameLevel()+2)
   b.label=b.textHost:CreateFontString(nil,"OVERLAY"); Font(b.label,ns.defaults.profile.palettes[1]); b.label:SetPoint("TOP",b,"BOTTOM",0,-3); b.label:SetTextColor(1,1,1)
   b.count=b.textHost:CreateFontString(nil,"OVERLAY"); Font(b.count,ns.defaults.profile.palettes[1]); b.count:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,2); b.count:SetTextColor(1,1,1)
   b:SetScript("OnEnter",Tooltip); b:SetScript("OnLeave",Leave); b:SetScript("OnHide",Leave)
   SecureHandlerWrapScript(b,"OnClick",ns.header,"return nil,true",ns.cancelSnippet)
   b:SetScript("PostClick",function() if ns.pending and not InCombatLockdown() then C_Timer.After(0,ns.Apply) end end)
   SecureHandlerSetFrameRef(driver,"slot"..slot,b); live.pool[slot]=b
  end
  local textHost=CreateFrame("Frame",nil,view); textHost:SetAllPoints(view); textHost:SetFrameLevel(view:GetFrameLevel()+30)
  live.caption=textHost:CreateFontString(nil,"OVERLAY"); Font(live.caption,ns.defaults.profile.palettes[1]); live.caption:SetTextColor(1,1,1); live.caption:Hide()
  -- Nested entries are drawn only; the secure release picks them by position.
  live.textHost=textHost; live.childPool={}; live.children={}
  for _=1,8 do ns.ChildVisual(live) end
  view:SetScript("OnUpdate",function() ns.UpdateVisuals(i) end)
  view:HookScript("OnShow",function() live.openedAt=GetTime(); live.animP=nil; live.nextState=nil; live.focus=nil; ns.ShowChildren(live,nil) end)
  view:Hide()
 end
end
function ns.BuildPalettes()
 if InCombatLockdown() then ns.pending=true; return end
 local profile=ns.Profile()
 local confirmKey=profile.confirmKey~="" and profile.confirmKey or nil
 local cancelKey=profile.cancelKey~="" and profile.cancelKey or nil
 for i,live in ipairs(ns.live) do local cfg=ns.Palette(i); local view,driver=live.view,live.driver; view:Hide(); ClearOverrideBindings(view)
  driver:SetAttribute("held",nil); driver:SetAttribute("latched",nil)
  local visible=cfg and ns.VisibleSlots(cfg) or {}
  driver:SetAttribute("enabled",profile.enabled and cfg and cfg.enabled~=false and ns.PaletteActive(i) and #visible>0 or false)
  driver:SetAttribute("toggle",cfg and cfg.toggleMode==true and confirmKey~=nil or nil); driver:SetAttribute("confirmKey",confirmKey); driver:SetAttribute("cancelKey",cancelKey)
  if cfg then
   cfg.slots=cfg.slots or {}; local count=#visible
   live.config=ns.Copy(cfg)
   local nests,childLists={},{}
   for j,slot in ipairs(visible) do nests[j]=0
    local target=slot.kind=="palette" and tonumber(slot.id)~=i and ns.PaletteActive(tonumber(slot.id)) and ns.Palette(tonumber(slot.id))
    if target then childLists[j]=ns.NestChildren(target); nests[j]=#childLists[j] end
   end
   local geo=ns.Layout(cfg,count,nests); local layout,size,gap=geo.layout,geo.size,geo.gap
   live.size=size; live.layout=layout; live.childSize=geo.childSize; live.children={}
   view:SetAttribute("nestEdge",geo.nestEdge); view:SetAttribute("childSize",geo.childSize)
   for j=1,20 do view:SetAttribute("nest"..j,nil) end
   for j,list in pairs(childLists) do local drawn={}
    view:SetAttribute("nest"..j,#list)
    for k,child in ipairs(list) do local p=geo.childPos[j][k]; local suffix=j.."_"..k
     local ck,cv=ns.Action(child,cfg); if ck=="nest" then ck,cv=nil,nil end
     local unit=(child.unit=="player" or child.unit=="target" or child.unit=="focus" or child.unit=="mouseover") and child.unit or nil
     view:SetAttribute("cx"..suffix,p[1]); view:SetAttribute("cy"..suffix,p[2])
     view:SetAttribute("ck"..suffix,ck); view:SetAttribute("cv"..suffix,cv); view:SetAttribute("cu"..suffix,unit)
     local name,icon=ns.Display(child); drawn[k]={name=name,icon=icon,x=p[1],y=p[2]}
    end
    live.children[j]=drawn
    for _=#live.childPool+1,(layout=="ARC" and #drawn or 0) do ns.ChildVisual(live) end
   end
   if layout~="ARC" then local total=0
    for _,drawn in pairs(live.children) do total=total+#drawn end
    for _=#live.childPool+1,total do ns.ChildVisual(live) end
   end
   Size(view,geo.width,geo.height); view:SetScale(ns.Clamp(cfg.scale,.5,2)); view:SetAlpha(ns.Clamp(cfg.opacity,.1,1))
   view:SetAttribute("count",count); view:SetAttribute("layout",layout); view:SetAttribute("iconSize",size); view:SetAttribute("centerMode",cfg.centerMode or "CURSOR")
   view:SetAttribute("arcSpan",geo.span); view:SetAttribute("arcRotation",cfg.arcRotation or 0); view:SetAttribute("initialX",nil); view:SetAttribute("initialY",nil)
   view:SetAttribute("posX",(cfg.posX or 0)/view:GetScale()); view:SetAttribute("posY",(cfg.posY or 0)/view:GetScale()); view:SetAttribute("wheel",nil); view:SetAttribute("wheelX",nil); view:SetAttribute("wheelY",nil)
   view:SetAttribute("invertScroll",cfg.invertScroll==true or nil)
   if layout=="ARC" then live.hub:Show() else live.hub:Hide() end
   Font(live.caption,cfg); live.caption:ClearAllPoints()
   if layout=="ARC" then live.caption:SetPoint("TOP",view,"CENTER",0,-24) else live.caption:SetPoint("TOP",view,"BOTTOM",0,-6) end
   for j,b in ipairs(live.pool) do local slot=visible[j]; b.slot=slot and ns.Copy(slot); b.spellName,b.itemID,b.name,b.unit=nil,nil,nil,nil
    b:SetAttribute("type",nil); b:SetAttribute("spell",nil); b:SetAttribute("item",nil); b:SetAttribute("macro",nil); b:SetAttribute("macrotext",nil); b:SetAttribute("unit",nil)
    b:SetAttribute("actionKind",nil); b:SetAttribute("actionValue",nil); b:SetAttribute("actionUnit",nil)
    if slot then
     local x,y=geo.pos[j][1],geo.pos[j][2]
     view:SetAttribute("x"..j,x); view:SetAttribute("y"..j,y); b:ClearAllPoints(); b:SetPoint("CENTER",view,"CENTER",x,y); Size(b,size,size)
     local name,icon=ns.Display(slot); b.name=name; b.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark"); b.icon:SetVertexColor(1,1,1); b.icon:SetDesaturated(false)
     Font(b.label,cfg); Font(b.count,cfg); b.label:SetWidth(geo.labelWidth); b.label:SetText(cfg.showLabels~=false and name or "")
     local kind,value=ns.Action(slot,cfg); if kind=="nest" then kind,value=nil,nil end
     b:SetAttribute("actionKind",kind); b:SetAttribute("actionValue",value)
     if slot.kind=="worldmarker" then b.itemID=ns.worldMarkerItems[tonumber(slot.id)]
     elseif kind=="spell" then b.spellName=value elseif kind=="item" then b.itemID=tonumber(value:match("item:(%d+)")) end
     local unit=(slot.unit=="player" or slot.unit=="target" or slot.unit=="focus" or slot.unit=="mouseover") and slot.unit or nil
     b.unit=unit; b:SetAttribute("actionUnit",unit); b:SetAttribute("unit",unit)
     if kind=="macrotext" then b:SetAttribute("type","macro"); b:SetAttribute("macrotext",value) elseif kind then b:SetAttribute("type",kind); b:SetAttribute(kind,value) end
     b:Show()
    else b:Hide() end
   end
  end
 end
end
function ns.ChildVisual(live)
 local c={}; local host=live.textHost
 c.border=host:CreateTexture(nil,"BORDER"); c.border:SetTexture(white); c.border:Hide()
 c.icon=host:CreateTexture(nil,"ARTWORK"); c.icon:SetTexCoord(.08,.92,.08,.92); c.icon:Hide()
 c.label=host:CreateFontString(nil,"OVERLAY"); Font(c.label,ns.defaults.profile.palettes[1]); c.label:SetPoint("TOP",c.icon,"BOTTOM",0,-2); c.label:SetTextColor(1,1,1); c.label:Hide()
 live.childPool[#live.childPool+1]=c
 return c
end
-- The ring shows the nest under the pointer; grid and fan lanes stay visible because they are picked by position alone.
function ns.ShowChildren(live,focus)
 local size=live.childSize or 32
 local cfg=live.config or ns.defaults.profile.palettes[1]
 local used=0
 for j,list in pairs(live.children or {}) do
  if live.layout~="ARC" or j==focus then
   for k,data in ipairs(list) do used=used+1; local c=live.childPool[used]
    if c then c.parent,c.index=j,k
     c.icon:SetTexture(data.icon or "Interface\\Icons\\INV_Misc_QuestionMark"); Size(c.icon,size,size); c.icon:ClearAllPoints(); c.icon:SetPoint("CENTER",live.view,"CENTER",data.x,data.y)
     Size(c.border,size+2,size+2); c.border:ClearAllPoints(); c.border:SetPoint("CENTER",c.icon,"CENTER",0,0); c.border:SetAlpha(0)
     Font(c.label,cfg); c.label:SetWidth(size+(cfg.spacing or 8)+12); c.label:SetText(cfg.showLabels~=false and data.name or "")
     c.icon:Show(); c.border:Show(); c.label:Show()
    end
   end
  end
 end
 for k=used+1,#live.childPool do local c=live.childPool[k]; c.parent,c.index=nil,nil; c.icon:Hide(); c.border:Hide(); c.label:Hide() end
end
-- Same three cues an action button gives: out of range, short of power, unusable.
local function Usability(b)
 local usable,noPower,range=true,false,nil
 local unit=b.unit or "target"
 if b.spellName then
  if IsUsableSpell then usable,noPower=IsUsableSpell(b.spellName) end
  if IsSpellInRange and UnitExists(unit) then range=IsSpellInRange(b.spellName,unit) end
 elseif b.itemID then
  if IsUsableItem then usable,noPower=IsUsableItem(b.itemID) end
  if (GetItemCount(b.itemID) or 0)==0 and not (IsEquippedItem and IsEquippedItem(b.itemID)) then usable=false end
  if IsItemInRange and UnitExists(unit) then range=IsItemInRange(b.itemID,unit) end
 end
 if range==0 then return 1,.3,.3,false end
 if noPower then return .35,.45,1,false end
 if not usable then return .55,.55,.55,true end
 return 1,1,1,false
end
function ns.UpdateVisuals(index)
 local live=ns.live[index]; local cfg=live.config; if not cfg then return end
 local view=live.view; local now=GetTime()
 local progress=1
 if cfg.openAnimation~=false and live.openedAt then progress=math.min(1,(now-live.openedAt)/.12) end
 if progress~=live.animP then live.animP=progress
  view:SetAlpha(ns.Clamp(cfg.opacity,.1,1)*(.3+.7*progress))
  for _,b in ipairs(live.pool) do local inset=1+(1-progress)*(live.size or 40)*.22
   b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",inset,-inset); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-inset,inset)
  end
 end
 local cx,cy=GetCursorPosition(); local scale=view:GetEffectiveScale(); local x,y=view:GetLeft(),view:GetBottom()
 local px,py
 if x and y then px,py=(cx/scale-x)/view:GetWidth(),(cy/scale-y)/view:GetHeight(); if px<0 or px>1 or py<0 or py>1 then px,py=nil,nil end end
 local selected,child=ns.SelectByPoint(view,px,py)
 -- Empty space keeps the last nest open so the pointer can travel out to it.
 local focus=live.focus
 if selected and live.children[selected] then focus=selected elseif selected then focus=nil end
 if focus~=live.focus then live.focus=focus; ns.ShowChildren(live,focus) end
 local refresh=not live.nextState or now>=live.nextState; if refresh then live.nextState=now+.1 end
 local r,g,blue=ns.SelectColor(cfg)
 for j,b in ipairs(live.pool) do if b.slot then
  if j==selected then b:SetBackdropBorderColor(r,g,blue,1) else b:SetBackdropBorderColor(0,0,0,0) end
  local start,duration=0,0; local count=0
  if b.spellName then start,duration=GetSpellCooldown(b.spellName)
  elseif b.itemID then start,duration=GetItemCooldown(b.itemID); count=GetItemCount(b.itemID) or 0 end
  if cfg.showCooldowns~=false and duration and duration>0 then
   if start~=b.lastStart or duration~=b.lastDuration then b.cooldown:SetCooldown(start,duration); b.lastStart,b.lastDuration=start,duration end
   b.cooldown:Show()
  else b.cooldown:Hide(); b.lastStart,b.lastDuration=nil,nil end
  local text=cfg.showCounts~=false and count>1 and tostring(count) or ""; if b.count:GetText()~=text then b.count:SetText(text) end
  if refresh then
   local tr,tg,tb,desaturate=1,1,1,false
   if cfg.showUsability~=false then tr,tg,tb,desaturate=Usability(b) end
   b.icon:SetVertexColor(tr,tg,tb); b.icon:SetDesaturated(desaturate)
  end
 end end
 for _,c in ipairs(live.childPool) do if c.parent then
  if c.parent==selected and c.index==child then c.border:SetVertexColor(r,g,blue); c.border:SetAlpha(1) else c.border:SetAlpha(0) end
 end end
 local sx,sy=selected and view:GetAttribute("x"..selected),selected and view:GetAttribute("y"..selected)
 local reach=live.size or 40
 local picked=child and live.children[selected] and live.children[selected][child]
 if picked then sx,sy,reach=picked.x,picked.y,live.childSize or 32 end
 local distance=sx and math.sqrt(sx*sx+sy*sy) or 0
 local first,last=26,distance-reach/2-4
 if live.layout=="ARC" and cfg.showNeedle~=false and sx and last>first then
  for k,dot in ipairs(live.needle) do local t=first+(last-first)*(k-1)/(NEEDLE_DOTS-1)
   dot:ClearAllPoints(); dot:SetPoint("CENTER",view,"CENTER",sx/distance*t,sy/distance*t); dot:SetVertexColor(r,g,blue); dot:SetAlpha(.35+.65*k/NEEDLE_DOTS); dot:Show()
  end
 else for _,dot in ipairs(live.needle) do dot:Hide() end end
 local name=picked and picked.name or selected and live.pool[selected].name
 if cfg.showActionText==true and name then if live.caption:GetText()~=name then live.caption:SetText(name) end; live.caption:Show() else live.caption:Hide() end
end
