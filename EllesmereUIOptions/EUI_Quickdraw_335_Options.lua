local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E._ModuleNS and E._ModuleNS.EllesmereUIQuickdraw
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
 self:UnregisterEvent("PLAYER_LOGIN")
 local kind,id,selectedSlot,status="spell","",1,""
 local category,pick="spells",nil
 local white="Interface\\Buttons\\WHITE8X8"
 local function Refresh() E:InvalidatePageCache(); E:RefreshPage(true) end
 local function PaletteName(index) local cfg=ns.Palette(index); return cfg and cfg.name or "Palette "..index end
 local function KeyConflict(index,key,action)
  local label=_G["BINDING_NAME_"..action] or action
  local function Rebind() local ok,message=ns.Bind(index,key,true); status=ok and "Key assigned: "..key or message; Refresh() end
  status=key.." is bound to "..label
  if E.ShowConfirmPopup then
   E:ShowConfirmPopup({title="Key Already Bound",message=key.." is bound to "..label..".\nRebind it to "..PaletteName(index).."?",confirmText="Rebind",cancelText="Keep",onConfirm=Rebind,onCancel=function() status="Kept "..key.." on "..label; Refresh() end})
  end
 end
 -- Wrath has no keyboard propagation API. Capture only in this temporary
 -- dialog, and always turn keyboard input off before hiding or rebuilding it.
 local capture=CreateFrame("Frame","EUI335QuickdrawKeyCapture",UIParent)
 capture:SetWidth(420); capture:SetHeight(140); capture:SetFrameStrata("DIALOG")
 capture:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1})
 capture:SetBackdropColor(.04,.06,.07,.98)
 local r,g,b=E.GetAccentColor(); capture:SetBackdropBorderColor(r,g,b,1)
 capture:EnableMouse(true); capture:EnableKeyboard(false); capture:Hide()
 local prompt=capture:CreateFontString(nil,"OVERLAY")
 prompt:SetFont(E.GetFontPath(),14,"OUTLINE"); prompt:SetPoint("TOP",capture,"TOP",0,-20); prompt:SetWidth(390)
 local cancel=CreateFrame("Button",nil,capture,"UIPanelButtonTemplate")
 cancel:SetWidth(120); cancel:SetHeight(24); cancel:SetPoint("BOTTOM",capture,"BOTTOM",0,12); cancel:SetText("Cancel")
 -- target is a palette index for its keybind, or "confirmKey"/"cancelKey".
 local target,pressed,chord,elapsed
 local ignored={LSHIFT=true,RSHIFT=true,LCTRL=true,RCTRL=true,LALT=true,RALT=true,UNKNOWN=true}
 local mouseKeys={MiddleButton="BUTTON3",Button4="BUTTON4",Button5="BUTTON5"}
 local function Modifiers() return (IsAltKeyDown() and "ALT-" or "")..(IsControlKeyDown() and "CTRL-" or "")..(IsShiftKeyDown() and "SHIFT-" or "") end
 local function StopCapture(message)
  local active=target~=nil
  target,pressed,chord=nil,nil,nil
  capture:EnableKeyboard(false); capture:UnregisterAllEvents(); capture:Hide()
  if active then status=message or "Key assignment cancelled" end
 end
 local function CancelCapture(message) StopCapture(message); Refresh() end
 local function Assign(where,binding)
  if type(where)=="number" then
   local ok,message,action=ns.Bind(where,binding)
   if message=="conflict" then KeyConflict(where,binding,action); Refresh(); return end
   status=ok and "Key assigned: "..binding or message
  else ns.Profile()[where]=binding; ns.Apply(); status=(where=="confirmKey" and "Select key: " or "Cancel key: ")..binding end
  Refresh()
 end
 capture:SetScript("OnHide",function() StopCapture() end)
 capture:SetScript("OnKeyDown",function(_,key)
  if not target then return end
  if key=="ESCAPE" then CancelCapture(); return end
  if pressed or ignored[key] or not key then return end
  pressed=key; chord=Modifiers()..key
  prompt:SetText("Selected: "..chord.."\nRelease the key to assign. Esc cancels.")
 end)
 capture:SetScript("OnKeyUp",function(_,key)
  if not target or key~=pressed then return end
  local where,binding=target,chord
  StopCapture(); Assign(where,binding)
 end)
 capture:SetScript("OnEvent",function() CancelCapture("Change bindings outside combat") end)
 capture:SetScript("OnUpdate",function(_,dt)
  if not target then return end
  elapsed=elapsed+dt
  if elapsed>=20 then CancelCapture("Key assignment timed out")
  elseif GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() then CancelCapture() end
 end)
 capture:SetScript("OnMouseDown",function(_,button)
  if type(target)=="string" and mouseKeys[button] then local where,binding=target,Modifiers()..mouseKeys[button]; StopCapture(); Assign(where,binding); return end
  if button=="RightButton" then CancelCapture() end
 end)
 cancel:SetScript("OnClick",function() CancelCapture() end)
 E:RegisterOnHide(function() StopCapture() end)
 local function StartCapture(parent,where)
  StopCapture()
  if InCombatLockdown() then status="Change bindings outside combat"; Refresh(); return end
  local focus=GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
  if focus then focus:ClearFocus() end
  target=where or ns.selectedPalette; elapsed=0
  capture:SetParent(parent); capture:ClearAllPoints(); capture:SetPoint("CENTER",UIParent,"CENTER",0,0)
  capture:SetFrameLevel(parent:GetFrameLevel()+50)
  if type(target)=="number" then prompt:SetText("Press a hotkey for "..ns.Selected().name.."\nCtrl, Alt and Shift supported. Esc cancels.")
  else prompt:SetText("Press the "..(target=="confirmKey" and "Select" or "Cancel").." key for open menus\nKeys, middle mouse and mouse buttons 4/5. Esc cancels.") end
  capture:RegisterEvent("PLAYER_REGEN_DISABLED"); capture:Show(); capture:EnableKeyboard(true)
 end
 local function Label(t) return {type="label",text=t} end
 local function Field(store,k,text,type,min,max,step)
  return {type=type,text=text,min=min,max=max,step=step or 1,getValue=function() local cfg=store(); return cfg and cfg[k] end,setValue=function(v) local cfg=store(); if cfg then cfg[k]=v; ns.Apply() end end}
 end
 -- Toggles whose default is on read nil as on: palettes made before a setting existed lack it.
 local function OnField(store,k,text) local c=Field(store,k,text,"toggle"); c.getValue=function() local cfg=store(); return cfg and cfg[k]~=false end; return c end
 local function DD(store,k,text,values,order) local c=Field(store,k,text,"dropdown"); c.values,c.order=values,order; return c end
 local function Entry() local cfg=ns.Selected(); return cfg and cfg.slots[selectedSlot] end
 local function DropCursor(position)
  if not GetCursorInfo() then return end
  local ok,message=ns.AddCursor(); status=ok and "Cursor action added" or message
  if ok then local list=ns.Selected().slots; selectedSlot=#list
   if position and position<#list then ns.MoveSlot(#list,position); selectedSlot=position end
  end
  Refresh()
 end
 local function BuildPreview(parent,y)
  local cfg=ns.Selected(); local height=240; local slots=cfg.slots
  local box=CreateFrame("Frame",nil,parent); box:SetPoint("TOPLEFT",parent,"TOPLEFT",20,y); box:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-20,y); box:SetHeight(height)
  box:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); box:SetBackdropColor(.02,.03,.04,.6); box:SetBackdropBorderColor(1,1,1,.08)
  box:EnableMouse(true); box:SetScript("OnReceiveDrag",function() DropCursor() end); box:SetScript("OnMouseUp",function() DropCursor() end)
  local hint=box:CreateFontString(nil,"OVERLAY"); hint:SetFont(E.GetFontPath(),11,"OUTLINE"); hint:SetPoint("BOTTOM",box,"BOTTOM",0,6); hint:SetTextColor(.7,.7,.7)
  hint:SetText(#slots==0 and "Drop spells, items, macros or mounts here, or use Add Action below." or "Click edits - Drag reorders - Right click removes - Drop to add")
  local nests,childLists={},{}
  for j,slot in ipairs(slots) do nests[j]=0
   local target=slot.kind=="palette" and tonumber(slot.id)~=ns.selectedPalette and ns.Palette(tonumber(slot.id))
   if target then childLists[j]=ns.NestChildren(target); nests[j]=#childLists[j] end
  end
  local geo=ns.Layout(cfg,#slots,nests); local width=math.max(100,(parent:GetWidth() or 600)-40)
  local scale=math.min(1,(height-34)/geo.height,width/geo.width)
  for j,list in pairs(childLists) do
   for k,child in ipairs(list) do local p=geo.childPos[j][k]; local size=geo.childSize*scale
    local icon=box:CreateTexture(nil,"ARTWORK"); icon:SetWidth(size); icon:SetHeight(size); icon:SetTexCoord(.08,.92,.08,.92)
    icon:SetPoint("CENTER",box,"CENTER",p[1]*scale,p[2]*scale+10); icon:SetTexture(select(2,ns.Display(child)) or "Interface\\Icons\\INV_Misc_QuestionMark"); icon:SetAlpha(.45)
   end
  end
  local buttons,dragFrom,hovered={},nil,nil
  local ghost=box:CreateTexture(nil,"OVERLAY"); ghost:SetTexCoord(.08,.92,.08,.92); ghost:SetAlpha(.7); ghost:Hide()
  local function Hovered()
   for j,button in ipairs(buttons) do if button.IsMouseOver and button:IsMouseOver() or MouseIsOver and MouseIsOver(button) then return j end end
   return hovered
  end
  for j,slot in ipairs(slots) do
   local button=CreateFrame("Button",nil,box); local size=geo.size*scale
   button:SetWidth(size); button:SetHeight(size); button:SetPoint("CENTER",box,"CENTER",geo.pos[j][1]*scale,geo.pos[j][2]*scale+10)
   button:SetBackdrop({edgeFile=white,edgeSize=1})
   if j==selectedSlot then button:SetBackdropBorderColor(r,g,b,1) else button:SetBackdropBorderColor(0,0,0,0) end
   local name,iconPath=ns.Display(slot)
   local icon=button:CreateTexture(nil,"ARTWORK"); icon:SetPoint("TOPLEFT",button,"TOPLEFT",1,-1); icon:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-1,1); icon:SetTexCoord(.08,.92,.08,.92)
   icon:SetTexture(iconPath or "Interface\\Icons\\INV_Misc_QuestionMark")
   if cfg.hideUnusable~=false and ns.Unavailable(slot) then icon:SetDesaturated(true); icon:SetVertexColor(.5,.5,.5) end
   button.icon=icon; buttons[j]=button
   button:RegisterForClicks("LeftButtonUp","RightButtonUp"); button:RegisterForDrag("LeftButton")
   button:SetScript("OnClick",function(_,mouse)
    if GetCursorInfo() then DropCursor(j)
    elseif mouse=="RightButton" then table.remove(ns.Selected().slots,j); selectedSlot=math.max(1,math.min(selectedSlot,#ns.Selected().slots)); status="Removed "..name; ns.Apply(); Refresh()
    else selectedSlot=j; Refresh() end
   end)
   button:SetScript("OnReceiveDrag",function() DropCursor(j) end)
   button:SetScript("OnEnter",function(self) hovered=j; GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine(name,1,1,1); GameTooltip:Show() end)
   button:SetScript("OnLeave",function() if hovered==j then hovered=nil end; GameTooltip:Hide() end)
   button:SetScript("OnDragStart",function(self)
    dragFrom=j; self:SetAlpha(.35); ghost:SetTexture(iconPath); ghost:SetWidth(size); ghost:SetHeight(size); ghost:Show()
    box:SetScript("OnUpdate",function()
     local x,yy=GetCursorPosition(); local s=box:GetEffectiveScale(); ghost:ClearAllPoints(); ghost:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/s,yy/s)
    end)
   end)
   button:SetScript("OnDragStop",function(self)
    self:SetAlpha(1); ghost:Hide(); box:SetScript("OnUpdate",nil)
    local from,to=dragFrom,Hovered(); dragFrom=nil
    if from and to and to~=from and ns.MoveSlot(from,to) then selectedSlot=to; status="Moved "..name end
    Refresh()
   end)
  end
  return height
 end
 E:RegisterModule("EllesmereUIQuickdraw",{title="Quickdraw",description="Hold a bound key, point or scroll to choose, then release to fire. Escape cancels.",pages={"Palettes"},searchTerms="quickdraw radial ring arc fan grid wheel palette spell item macro mount companion raid marker world marker equipment set keybind preset toggle",
 buildPage=function(page,parent,y)
  StopCapture()
  local W=E.Widgets
  local function Row(a,b) local _,h=W:DualRow(parent,y,a,b or Label("")); y=y-h end
  local function Section(t) local _,h=W:SectionHeader(parent,t,y); y=y-h end
  local function Button(t,fn) local _,h=W:WideButton(parent,t,y,fn); y=y-h end
  local profile=ns.Profile()
  Section("GENERAL")
  local presetValues,presetOrder={none="Choose...",empty="Empty Action Menu"},{"none","empty"}
  for _,key in ipairs(ns.presetOrder) do presetValues[key]=ns.catalogNames[key].." Preset"; presetOrder[#presetOrder+1]=key end
  Row(Field(ns.Profile,"enabled","Enable Quickdraw","toggle"),{type="dropdown",text="Add Action Menu",values=presetValues,order=presetOrder,getValue=function() return "none" end,setValue=function(v)
   if v=="none" then return end
   local cfg=ns.NewPresetPalette(v~="empty" and v or nil)
   status=cfg and ("Created "..cfg.name..(#cfg.slots>0 and " with "..#cfg.slots.." actions" or "")) or "Maximum 16 palettes"; selectedSlot=1; Refresh()
  end})
  Section("ACTION MENU SETUP")
  local values,order={},{}
  for i,cfg in ipairs(profile.palettes) do values[i]=i..". "..cfg.name; order[#order+1]=i end
  if not ns.Selected() then ns.selectedPalette=1 end
  Row({type="dropdown",text="Select Palette",values=values,order=order,getValue=function() return ns.selectedPalette end,setValue=function(v) ns.selectedPalette=v; selectedSlot=1; Refresh() end},Field(ns.Selected,"enabled","Enable This Palette","toggle"))
  local cfg=ns.Selected(); if not cfg then return math.abs(y) end
  local copyValues,copyOrder={none="Choose..."},{"none"}
  for i,other in ipairs(profile.palettes) do if i~=ns.selectedPalette then copyValues[i]=i..". "..other.name; copyOrder[#copyOrder+1]=i end end
  Row(Field(ns.Selected,"name","Palette Name","input"),{type="dropdown",text="Copy Settings From",values=copyValues,order=copyOrder,getValue=function() return "none" end,setValue=function(v)
   if v~="none" and ns.CopySettings(v,ns.selectedPalette) then status="Copied settings from "..PaletteName(v) end; Refresh()
  end})
  local keys={GetBindingKey("EUI_RADIAL"..ns.selectedPalette)}
  Row(Label("Keybind: "..(#keys>0 and table.concat(keys,", ") or "Unbound")),Label("Click Assign Key, then press your hotkey."))
  Button("Assign Key",function() StartCapture(parent) end)
  Button("Clear Palette Keybinds",function() if InCombatLockdown() then status="Change bindings outside combat"; Refresh(); return end
   for _,bound in ipairs({GetBindingKey("EUI_RADIAL"..ns.selectedPalette)}) do SetBinding(bound) end
   if SaveBindings then SaveBindings(GetCurrentBindingSet()) end; ns.Apply(); Refresh()
  end)
  local confirmKey=profile.confirmKey~="" and profile.confirmKey or "None"; local cancelKey=profile.cancelKey~="" and profile.cancelKey or "None"
  Row(Field(ns.Selected,"toggleMode","Toggle Menu Open","toggle"),Label("Select key: "..confirmKey.."   Cancel key: "..cancelKey))
  if cfg.toggleMode and profile.confirmKey=="" then Row(Label("Toggle mode needs a Select key; until one is set the menu fires on release.")) end
  Button("Set Select Key",function() StartCapture(parent,"confirmKey") end)
  Button("Set Cancel Key",function() StartCapture(parent,"cancelKey") end)
  Button("Clear Select And Cancel Keys",function() profile.confirmKey=""; profile.cancelKey=""; ns.Apply(); Refresh() end)
  Row(Label("Hold the key to open, release to fire. Toggle mode keeps the menu open: the Select key fires, the menu key or Escape closes."))
  Section("PREVIEW")
  y=y-BuildPreview(parent,y)-10
  Section("ACTIONS")
  local slots,slotOrder={},{}
  for i,s in ipairs(cfg.slots) do slots[i]=i..". "..ns.Display(s); slotOrder[#slotOrder+1]=i end
  if #slotOrder>0 then
   selectedSlot=math.max(1,math.min(selectedSlot,#slotOrder))
   Row({type="dropdown",text="Edit Action",values=slots,order=slotOrder,getValue=function() return selectedSlot end,setValue=function(v) selectedSlot=v; Refresh() end},Field(Entry,"label","Custom Label","input"))
   Row(DD(Entry,"unit","Spell Target",{none="Automatic",player="Player",target="Target",focus="Focus",mouseover="Mouseover"},{"none","player","target","focus","mouseover"}))
   Button("Move Action Up",function() if ns.MoveSlot(selectedSlot,selectedSlot-1) then selectedSlot=selectedSlot-1 end; Refresh() end)
   Button("Move Action Down",function() if ns.MoveSlot(selectedSlot,selectedSlot+1) then selectedSlot=selectedSlot+1 end; Refresh() end)
   Button("Remove Action",function() table.remove(ns.Selected().slots,selectedSlot); selectedSlot=1; ns.Apply(); Refresh() end)
  end
  Section("ADD ACTION")
  local entries=ns.Catalog(category); local pickValues,pickOrder={_noLoc=true,_menuOpts={searchable=true}},{}
  for i,entry in ipairs(entries) do pickValues[i]=entry.text; pickOrder[i]=i end
  if not entries[pick or 0] then pick=entries[1] and 1 or nil end
  if not pick then pickValues[0]="Nothing available"; pickOrder[1]=0 end
  Row({type="dropdown",text="Category",values=ns.catalogNames,order=ns.catalogOrder,getValue=function() return category end,setValue=function(v) category=v; pick=nil; Refresh() end},
   {type="dropdown",text="Action",values=pickValues,order=pickOrder,getValue=function() return pick or 0 end,setValue=function(v) pick=v end})
  Button("Add Selected Action",function()
   local entry=entries[pick or 0]; if not entry then status="Nothing to add in this category"; Refresh(); return end
   local slot=ns.Copy(entry.slot); local slotKind,slotID=slot.kind,slot.id; slot.kind,slot.id=nil,nil
   local ok,message=ns.AddSlot(slotKind,slotID,slot); status=ok and "Added "..entry.text or message; if ok then selectedSlot=#ns.Selected().slots end; Refresh()
  end)
  Row({type="dropdown",text="Action Type",values={spell="Spell ID",item="Item ID",macro="Macro Name / Index",macrotext="Macro Text",panel="Micro Menu",raidtarget="Raid Marker 0-8",worldmarker="World Marker 1-8",equipmentset="Equipment Set",companion="Mount Index",palette="Action Menu Number"},order={"spell","item","macro","macrotext","panel","raidtarget","worldmarker","equipmentset","companion","palette"},getValue=function() return kind end,setValue=function(v) kind=v; Refresh() end},
   kind=="panel" and {type="dropdown",text="Panel",values=ns.panelNames,order=ns.panelOrder,getValue=function() return id end,setValue=function(v) id=v end}
   or {type="input",text="Action ID / Name / Text",getValue=function() return tostring(id) end,setValue=function(v) id=v end})
  Button("Add Action",function()
   local value=id
   if kind=="spell" or kind=="item" or kind=="raidtarget" or kind=="worldmarker" or kind=="companion" or kind=="palette" then value=tonumber(id) or id end
   local ok,message=ns.AddSlot(kind,value); status=ok and "Action added" or message; if ok then selectedSlot=#ns.Selected().slots end; Refresh()
  end)
  Button("Add Action From Cursor",function() local ok,message=ns.AddCursor(); status=ok and "Cursor action added" or message; if ok then selectedSlot=#ns.Selected().slots end; Refresh() end)
  Row(Label(status))
  Section("LAYOUT")
  Row(DD(ns.Selected,"layout","Layout",{ARC="Ring / Arc",FAN="Fan",GRID="Grid"},{"ARC","FAN","GRID"}),DD(ns.Selected,"centerMode","Open At",{CURSOR="Cursor",SCREEN="Screen Position"},{"CURSOR","SCREEN"}))
  Row(DD(ns.Selected,"fanOrientation","Fan Direction",{HORIZONTAL="Horizontal",VERTICAL="Vertical"},{"HORIZONTAL","VERTICAL"}),Field(ns.Selected,"autoColumns","Auto Grid Columns","toggle"))
  Row(Field(ns.Selected,"columns","Grid Columns","slider",1,10),Field(ns.Selected,"radius","Ring Radius","slider",50,250))
  Row(Field(ns.Selected,"arcSpan","Arc Span (Degrees)","slider",30,360,5),Field(ns.Selected,"arcRotation","Arc Rotation (Degrees)","slider",0,355,5))
  Row(Field(ns.Selected,"iconSize","Icon Size","slider",24,80),Field(ns.Selected,"spacing","Spacing","slider",0,30))
  Row(Field(ns.Selected,"scale","Scale","slider",.5,2,.05),Field(ns.Selected,"opacity","Opacity","slider",.1,1,.05))
  Row(Field(ns.Selected,"posX","Screen X Offset","slider",-800,800,5),Field(ns.Selected,"posY","Screen Y Offset","slider",-500,500,5))
  Section("APPEARANCE")
  Row(OnField(ns.Selected,"showLabels","Show Labels"),OnField(ns.Selected,"showCounts","Item Counts"))
  Row(OnField(ns.Selected,"showCooldowns","Cooldown Swipes"),OnField(ns.Selected,"showUsability","Dim Unusable Entries"))
  Row(OnField(ns.Selected,"hideUnusable","Hide Unusable Entries"),Field(ns.Selected,"showActionText","Show Action Text Label","toggle"))
  Row(OnField(ns.Selected,"showNeedle","Selection Needle"),OnField(ns.Selected,"openAnimation","Open Animation"))
  Row(OnField(ns.Selected,"worldMarkerCursor","World Markers at Cursor"),Label("Off: world markers ask for a ground click."))
  Row(Field(ns.Selected,"textSize","Text Size","slider",8,20),DD(ns.Selected,"fontOutline","Font Outline",{OUTLINE="Outline",THICKOUTLINE="Thick Outline"},{"OUTLINE","THICKOUTLINE"}))
  Button("Clear And Disable This Palette",function() ns.RemovePalette(ns.selectedPalette); selectedSlot=1; Refresh() end)
  return math.abs(y)
 end,onReset=function() ns.addon.db:ResetProfile(); ns.Apply(); Refresh() end})
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
