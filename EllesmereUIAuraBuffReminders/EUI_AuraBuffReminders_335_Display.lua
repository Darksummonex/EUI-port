local ADDON,ns=...
local E=EllesmereUI
local white="Interface\\Buttons\\WHITE8X8"
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function Font(fs,size,flags)
 local path=E.GetFontPath and E.GetFontPath("auraBuff") or "Fonts\\FRIZQT__.TTF"
 if not fs:SetFont(path,size,flags or "OUTLINE") then fs:SetFont("Fonts\\FRIZQT__.TTF",size,"OUTLINE") end
 fs:SetShadowColor(0,0,0,1); fs:SetShadowOffset(1,-1)
end
local function Tooltip(self)
 if not self.reminder or not ns.Profile().display.showTooltips then return end
 local r=self.reminder; GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine(r.name,1,1,1)
 GameTooltip:AddLine(r.reason or "",.8,.8,.8,true)
 if r.unit and UnitName(r.unit) then GameTooltip:AddLine("First missing: "..UnitName(r.unit),.8,.8,.8) end
 if r.spell or r.item then GameTooltip:AddLine("Left-click to apply outside combat.",.5,.8,.8,true) end
 GameTooltip:AddLine("Middle/right-click to dismiss until the next loading screen.",.5,.8,.8,true); GameTooltip:Show()
end
local function Leave(self) if GameTooltip.GetOwner and GameTooltip:GetOwner()==self then GameTooltip:Hide() end end
local function Dismiss(self,button)
 if self.reminder and (button=="MiddleButton" or button=="RightButton") then ns.dismissed[self.reminder.key]=true; ns.Refresh() end
end
function ns.CreateDisplay()
 local f=CreateFrame("Frame","EUI335AuraBuffReminders",UIParent); ns.frame=f; f.pool={}; ns.actions={}
 f:SetFrameStrata("MEDIUM"); f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
 f:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1})
 f.label=f:CreateFontString(nil,"OVERLAY"); Font(f.label,11); f.label:SetText("Aura Buff Reminders"); f.label:SetPoint("BOTTOMLEFT",f,"TOPLEFT",0,4)
 f:SetScript("OnDragStart",function() if ns.preview then f:StartMoving() end end)
 f:SetScript("OnDragStop",function() f:StopMovingOrSizing(); local x,y=f:GetCenter(); local ux,uy=UIParent:GetCenter(); local ratio=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
  ns.Profile().unlockPos={point="CENTER",relPoint="CENTER",x=x*ratio-ux,y=y*ratio-uy}; ns.Refresh() end)
 for i=1,40 do
  local b=CreateFrame("Button",nil,f); b:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); b:SetBackdropColor(.03,.04,.05,.9); b:SetBackdropBorderColor(0,0,0,1)
  b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1); b.icon:SetTexCoord(.08,.92,.08,.92)
  b.label=b:CreateFontString(nil,"OVERLAY"); Font(b.label,11); b.label:SetTextColor(1,1,1); b.label:SetPoint("TOP",b,"BOTTOM",0,-3)
  b.count=b:CreateFontString(nil,"OVERLAY"); Font(b.count,13); b.count:SetTextColor(1,1,1); b.count:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,2)
  b:SetScript("OnEnter",Tooltip); b:SetScript("OnLeave",Leave); b:SetScript("OnHide",Leave); b:RegisterForClicks("AnyUp"); b:SetScript("OnClick",Dismiss); b:Hide(); f.pool[i]=b
  -- No anchor/parent dependency on the dynamic, unprotected reminder display.
  local a=CreateFrame("Button","EUI335ReminderAction"..i,UIParent,"SecureActionButtonTemplate"); a:EnableMouse(true); a:SetFrameStrata("HIGH"); a:RegisterForClicks("AnyUp")
  a:SetScript("OnEnter",Tooltip); a:SetScript("OnLeave",Leave); a:SetScript("OnHide",Leave); a:SetScript("PostClick",Dismiss); a:Hide(); ns.actions[i]=a
 end
 if E.MakeUnlockElement and E.RegisterUnlockElements then E:RegisterUnlockElements({E.MakeUnlockElement({key="EABR_Reminders",label="Aura Buff Reminders",group="Aura Buff Reminders",order=360,noResize=true,noInitHook=true,
  getFrame=function() return ns.frame end,getSize=function() return f:GetWidth(),f:GetHeight() end,isHidden=function() return not ns.Profile().display.remindersEnabled end,
  savePos=function(_,point,relPoint,x,y) ns.Profile().unlockPos={point=point,relPoint=relPoint,x=x,y=y} end,loadPos=function() return ns.Profile().unlockPos end,clearPos=function() ns.Profile().unlockPos=nil end,
  applyPos=function() ns.Layout(); ns.Refresh() end})},ADDON) end
end
function ns.Layout()
 local p=ns.Profile(); if not p or not ns.frame then return end
 local d,f=p.display,ns.frame; local scale=math.max(.5,math.min(2,tonumber(d.scale) or 1)); f:SetScale(scale); f:SetAlpha(d.opacity or 1)
 f:ClearAllPoints(); local pos=p.unlockPos
 if pos then f:SetPoint(pos.point or "CENTER",UIParent,pos.relPoint or pos.point or "CENTER",(pos.x or 0)/scale,(pos.y or 0)/scale)
 else f:SetPoint("CENTER",UIParent,"CENTER",0,200/scale) end
 for _,b in ipairs(f.pool) do Font(b.label,d.textSize or 11,d.fontOutline); Font(b.count,(d.textSize or 11)+2,d.fontOutline) end
end
function ns.Draw()
 local d,f=ns.Profile().display,ns.frame
 local count=math.min(40,#ns.missing); local size=math.max(20,math.min(80,tonumber(d.iconSize) or 40)); local spacing=math.max(0,math.min(30,tonumber(d.iconSpacing) or 8))
 local perRow=math.max(1,math.min(12,math.floor((UIParent:GetWidth()/f:GetScale()-30)/(size+spacing))))
 if ns.preview and count==0 then count=3 end
 local cols=math.min(perRow,math.max(1,count)); local rows=math.max(1,math.ceil(count/perRow)); local pitchY=size+(d.showText and (d.textSize or 11)+7 or 0)+spacing
 Size(f,cols*(size+spacing)-spacing,rows*pitchY-spacing)
 local visible=ns.preview or d.remindersEnabled and count>0 and (not d.hideInCombat or not InCombatLockdown())
 if visible then f:Show() else f:Hide() end
 f:SetBackdropColor(.03,.04,.05,ns.preview and .5 or 0); f:SetBackdropBorderColor(.1,.8,.7,ns.preview and 1 or 0)
 if ns.preview then f.label:Show() else f.label:Hide() end
 for i,b in ipairs(f.pool) do local r=ns.missing[i]; b.reminder=r
  if i<=count then
   local col,row=(i-1)%perRow,math.floor((i-1)/perRow); local rowCount=math.min(perRow,count-row*perRow); local x=col*(size+spacing)
   if d.growDirection=="LEFT" then x=f:GetWidth()-size-x elseif d.growDirection=="CENTER" then x=x+(f:GetWidth()-(rowCount*(size+spacing)-spacing))/2 end
   b:ClearAllPoints(); b:SetPoint("TOPLEFT",f,"TOPLEFT",x,-row*pitchY); Size(b,size,size); b.offsetX,b.offsetY=x+size/2,-row*pitchY-size/2
   b.icon:SetTexture(r and r.icon or "Interface\\Icons\\INV_Misc_QuestionMark"); b.icon:SetDesaturated(r and r.item==nil and r.spell==nil or false)
   b.label:SetWidth(size+spacing); b.label:SetText(d.showText and (r and r.name or "Reminder") or ""); b.count:SetText(d.showCount and r and r.count>1 and r.count or "")
   if d.glow and r then local red,green,blue=.047,.824,.616; if E.GetAccentColor then red,green,blue=E.GetAccentColor() end; b:SetBackdropBorderColor(red,green,blue,1) else b:SetBackdropBorderColor(0,0,0,1) end
   b:Show()
  else b:Hide() end
 end
end
function ns.UpdateActions()
 if InCombatLockdown() then ns.pending=true; return end
 local f=ns.frame; local cx,cy=f:GetCenter(); if not cx or not cy then return end
 local scale=f:GetEffectiveScale()/UIParent:GetEffectiveScale(); local ux,uy=UIParent:GetCenter()
 for i,a in ipairs(ns.actions) do local b=f.pool[i]; local r=ns.missing[i]
  local active=r and f:IsShown() and b:IsShown() and not ns.preview and (r.spell or r.item)
  a.reminder=r; a:ClearAllPoints(); a:SetPoint("CENTER",UIParent,"CENTER",(cx+(b.offsetX or 0)-f:GetWidth()/2)*scale-ux,(cy+(b.offsetY or 0)+f:GetHeight()/2)*scale-uy)
  Size(a,b:GetWidth()*scale,b:GetHeight()*scale)
  a:SetAttribute("type1",nil); a:SetAttribute("spell1",nil); a:SetAttribute("item1",nil); a:SetAttribute("unit",nil)
  if active and r.spell then a:SetAttribute("type1","spell"); a:SetAttribute("spell1",r.spell.name); a:SetAttribute("unit",r.unit)
  elseif active and r.item then a:SetAttribute("type1","item"); a:SetAttribute("item1","item:"..r.item) end
  local driver=active and "[combat] hide; show" or "hide"
  if a.driver~=driver then RegisterStateDriver(a,"visibility",driver); a.driver=driver end
 end
 ns.pending=false
end
