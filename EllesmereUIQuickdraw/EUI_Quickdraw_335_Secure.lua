local _,ns=...
-- One selection rule shared by the drawing code and the restricted click path.
ns.selectionBody=[[
 local count=view:GetAttribute("count") or 0
 if count==0 then break end
 local wheel=view:GetAttribute("wheel")
 if wheel then
  local wheelX,wheelY=view:GetAttribute("wheelX"),view:GetAttribute("wheelY")
  if not px or not py or not wheelX or not wheelY or math.abs(px-wheelX)<.03 and math.abs(py-wheelY)<.03 then index=wheel; break end
 end
 if not px or not py then break end
 local initialX,initialY=view:GetAttribute("initialX"),view:GetAttribute("initialY")
 if initialX and initialY and math.abs(px-initialX)<.002 and math.abs(py-initialY)<.002 then break end
 local x,y=(px-.5)*view:GetWidth(),(py-.5)*view:GetHeight()
 local layout=view:GetAttribute("layout")
 if layout=="ARC" and x*x+y*y<24*24 then break end
 local best,score=nil,nil
 for i=1,count do
  local sx,sy=view:GetAttribute("x"..i),view:GetAttribute("y"..i)
  local value
  if layout=="ARC" then value=-(x*sx+y*sy)
  else value=(x-sx)*(x-sx)+(y-sy)*(y-sy) end
  if not score or value<score then best,score=i,value end
 end
 if layout=="ARC" then
  local nest=view:GetAttribute("nest"..best) or 0
  local edge=view:GetAttribute("nestEdge") or 0
  if nest>0 and edge>0 and x*x+y*y>edge*edge then
   local near,distance=nil,nil
   for k=1,nest do
    local cx,cy=view:GetAttribute("cx"..best.."_"..k),view:GetAttribute("cy"..best.."_"..k)
    local d=(x-cx)*(x-cx)+(y-cy)*(y-cy)
    if not distance or d<distance then near,distance=k,d end
   end
   index=best; child=near; break
  end
  local span=view:GetAttribute("arcSpan") or 360
  if span<360 then
   local angle=math.atan2(x,y)-(view:GetAttribute("arcRotation") or 0)*math.pi/180
   angle=(angle+math.pi)%(2*math.pi)-math.pi
   if math.abs(angle)>span*math.pi/360 then break end
  end
  index=best; break
 end
 local half=(view:GetAttribute("iconSize") or 40)/2
 if math.abs(x-view:GetAttribute("x"..best))<=half and math.abs(y-view:GetAttribute("y"..best))<=half then index=best; break end
 local reach=(view:GetAttribute("childSize") or 32)/2+2
 for i=1,count do
  local nest=view:GetAttribute("nest"..i) or 0
  for k=1,nest do
   local cx,cy=view:GetAttribute("cx"..i.."_"..k),view:GetAttribute("cy"..i.."_"..k)
   if not index and math.abs(x-cx)<=reach and math.abs(y-cy)<=reach then index=i; child=k end
  end
 end
]]
-- Wrath's restricted parser forbids the function keyword inside a snippet, so the body exits a repeat block with break.
ns.SelectByPoint=assert(loadstring("return function(view,px,py) local index,child repeat "..ns.selectionBody.." until true return index,child end"))()
ns.secureSelection=ns.selectionBody
local clearAction=[[
 self:SetAttribute("type",nil); self:SetAttribute("spell",nil); self:SetAttribute("item",nil)
 self:SetAttribute("macro",nil); self:SetAttribute("macrotext",nil); self:SetAttribute("unit",nil)
]]
local commitAction=[[
  if index then local kind,value,unit
   if child then local suffix=index.."_"..child
    kind=view:GetAttribute("ck"..suffix); value=view:GetAttribute("cv"..suffix); unit=view:GetAttribute("cu"..suffix)
   else local slot=actor:GetFrameRef("slot"..index)
    kind=slot:GetAttribute("actionKind"); value=slot:GetAttribute("actionValue"); unit=slot:GetAttribute("actionUnit")
   end
   if kind=="macrotext" then self:SetAttribute("type","macro"); self:SetAttribute("macrotext",value)
   elseif kind then self:SetAttribute("type",kind); self:SetAttribute(kind,value) end
   self:SetAttribute("unit",unit)
  end
]]
local closeAll=[[
 for i=1,16 do local view=owner:GetFrameRef("view"..i); if view then view:Hide(); view:ClearBindings() end end
]]
ns.preSnippet=[[
 local view=self:GetFrameRef("view")
]]..clearAction..[[
 if down then
  if self:GetAttribute("latched") then
   self:SetAttribute("latched",nil); self:SetAttribute("held",nil); owner:SetAttribute("active",nil)
   view:Hide(); view:ClearBindings(); return nil,true
  end
  if not self:GetAttribute("enabled") then return nil,true end
  for i=1,16 do local other=owner:GetFrameRef("driver"..i); local otherView=owner:GetFrameRef("view"..i)
   if other then other:SetAttribute("held",nil); other:SetAttribute("latched",nil) end
   if otherView then otherView:Hide(); otherView:ClearBindings() end
  end
  self:SetAttribute("held",true); owner:SetAttribute("active",self:GetAttribute("paletteIndex")); view:SetAttribute("wheel",nil)
  view:ClearAllPoints()
  if view:GetAttribute("centerMode")=="CURSOR" then view:SetPoint("CENTER","$cursor","CENTER",0,0)
  else view:SetPoint("CENTER","$screen","CENTER",view:GetAttribute("posX") or 0,view:GetAttribute("posY") or 0) end
  view:SetBindingClick(true,"ESCAPE",self:GetFrameRef("cancel"),"LeftButton")
  local cancelKey=self:GetAttribute("cancelKey"); if cancelKey then view:SetBindingClick(true,cancelKey,self:GetFrameRef("cancel"),"LeftButton") end
  if self:GetAttribute("toggle") then view:SetBindingClick(true,self:GetAttribute("confirmKey"),self:GetFrameRef("confirm"),"LeftButton") end
  view:Show()
  local ix,iy=view:GetMousePosition(); view:SetAttribute("initialX",ix); view:SetAttribute("initialY",iy)
 else
  local actor=self
  if not actor:GetAttribute("held") then local active=owner:GetAttribute("active"); actor=active and owner:GetFrameRef("driver"..active) end
  if not actor or not actor:GetAttribute("held") then return nil,true end
  if actor:GetAttribute("toggle") and not actor:GetAttribute("latched") then actor:SetAttribute("latched",true); return nil,true end
  if actor:GetAttribute("latched") then return nil,true end
  view=actor:GetFrameRef("view")
  local px,py=view:GetMousePosition()
  local index,child=nil,nil
  repeat
]]..ns.secureSelection..[[
  until true
]]..commitAction..[[
  actor:SetAttribute("held",nil); owner:SetAttribute("active",nil)
 end
 return nil,true
]]
ns.postSnippet=[[
 if not down then
  local active=owner:GetAttribute("active"); local actor=active and owner:GetFrameRef("driver"..active)
  if actor and actor:GetAttribute("latched") then return end
]]..closeAll..clearAction..[[
 end
]]
-- The Select key of a latched menu fires whatever the pointer is on.
ns.confirmSnippet=[[
]]..clearAction..[[
 local active=owner:GetAttribute("active"); local actor=active and owner:GetFrameRef("driver"..active)
 if not actor or not actor:GetAttribute("latched") then return false end
 local view=actor:GetFrameRef("view")
 local px,py=view:GetMousePosition()
 local index,child=nil,nil
 repeat
]]..ns.secureSelection..[[
 until true
]]..commitAction..[[
 actor:SetAttribute("held",nil); actor:SetAttribute("latched",nil); owner:SetAttribute("active",nil)
 return nil,true
]]
ns.confirmPostSnippet=closeAll..clearAction
ns.cancelSnippet=[[
 owner:SetAttribute("active",nil)
 for i=1,16 do local driver=owner:GetFrameRef("driver"..i); local view=owner:GetFrameRef("view"..i)
  if driver then driver:SetAttribute("held",nil); driver:SetAttribute("latched",nil); driver:SetAttribute("type",nil) end
  if view then view:Hide(); view:ClearBindings() end
 end
]]
ns.wheelSnippet=[[
 local n=self:GetAttribute("count") or 0
 if n>0 then local up=delta>0; if self:GetAttribute("invertScroll") then up=not up end
  local index=self:GetAttribute("wheel") or (up and 1 or 0)
  index=((index+(up and -1 or 1)-1)%n)+1; self:SetAttribute("wheel",index)
  local wheelX,wheelY=self:GetMousePosition(); self:SetAttribute("wheelX",wheelX); self:SetAttribute("wheelY",wheelY)
 end
]]
function ns.UpdateBindings()
 if InCombatLockdown() then ns.pending=true; return end
 ClearOverrideBindings(ns.header)
 local function Loads(i) local cfg=ns.Palette(i); return cfg and cfg.enabled~=false and ns.PaletteActive(i) end
 for i=1,16 do local live=ns.live[i]
  if ns.Profile().enabled and Loads(i) then
   local keys={GetBindingKey("EUI_RADIAL"..i)}
   local owner=ns.ShareOwner(i)
   if owner and not Loads(owner) then for _,key in ipairs({GetBindingKey("EUI_RADIAL"..owner)}) do keys[#keys+1]=key end end
   for _,key in ipairs(keys) do SetOverrideBindingClick(ns.header,false,key,live.driver:GetName(),"LeftButton")
    -- Preserve a held key's release when an unbound modifier is pressed.
    local base=key:gsub("ALT%-",""):gsub("CTRL%-",""):gsub("SHIFT%-","")
    for _,prefix in ipairs({"","ALT-","CTRL-","SHIFT-","ALT-CTRL-","ALT-SHIFT-","CTRL-SHIFT-","ALT-CTRL-SHIFT-"}) do
     local variant=prefix..base; local action=GetBindingAction(variant)
     if variant~=key and (not action or action=="") then SetOverrideBindingClick(ns.header,false,variant,live.driver:GetName(),"LeftButton") end
    end
   end
  end
 end
end
