-- Restricted snippets execute their real source with only Wrath-safe globals.
local m=getmetatable(UIParent).__index
local factory=CreateFrame
secureDepth=0; secureActions={}; secureDrivers={}; overrides={}; bindingKeys={}
local function Guard(f) assert(not combat or not f.protected or secureDepth>0,'Insecure protected mutation in combat') end
local function GuardGlobal() assert(not combat or secureDepth>0,'Insecure protected API in combat') end
function m:IsProtected() return self.protected or false end
for _,method in ipairs({'SetAttribute','SetPoint','ClearAllPoints','SetWidth','SetHeight','SetScale','Show','Hide'}) do
 local original=m[method]
 m[method]=function(self,...) Guard(self); return original(self,...) end
end
function m:SetShadowColor(...) self.shadowColor={...} end
function m:SetShadowOffset(...) self.shadowOffset={...} end
function m:EnableMouseWheel(value) self.wheelEnabled=value end
function m:GetFrameRef(name) return self.refs and self.refs[name] end
function m:GetMousePosition() return self.mouseX,self.mouseY end
function m:ClearBindings() ClearOverrideBindings(self) end
function m:SetBindingClick(priority,key,name,button) SetOverrideBindingClick(self,priority,key,type(name)=='table' and name:GetName() or name,button) end
local setPoint=m.SetPoint
function m:SetPoint(point,relative,...)
 if relative=='$cursor' then self.mouseX,self.mouseY=.5,.5 end
 return setPoint(self,point,relative,...)
end
function CreateFrame(kind,name,parent,template)
 assert(not combat,'Combat frame allocation')
 local f=factory(kind,name,parent,template); f.protected=template and template:find('Secure')~=nil or false
 if f.protected then local p=parent; while p and p~=UIParent do p.protected=true; p=p:GetParent() end end
 if template and template:find('SecureActionButtonTemplate') then
  f:SetScript('OnClick',function(self,button,down)
   local suffix=button=='LeftButton' and '1' or button=='RightButton' and '2' or button=='MiddleButton' and '3' or ''
   local kind=self:GetAttribute('type'..suffix) or self:GetAttribute('type')
   if kind then secureActions[#secureActions+1]={kind=kind,value=self:GetAttribute(kind..suffix) or self:GetAttribute(kind),macrotext=self:GetAttribute('macrotext'..suffix) or self:GetAttribute('macrotext'),unit=self:GetAttribute('unit'),down=down} end
  end)
 end
 return f
end
function SecureHandlerSetFrameRef(f,name,ref) GuardGlobal(); f.refs=f.refs or {}; f.refs[name]=ref end
local function Snippet(body)
 if not body then return end
 assert(not body:match('function'),'Wrath restricted parser forbids nested functions')
 assert(not body:match('[{}]'),'Wrath restricted parser forbids direct table creation')
 local f=assert(loadstring('return function(self,button,down,delta,owner) '..body..' end'))
 setfenv(f,{math=math,string=string,tonumber=tonumber,tostring=tostring})
 return f()
end
function SecureHandlerWrapScript(f,script,header,pre,post)
 GuardGlobal(); local old=f:GetScript(script); local before,after=Snippet(pre),Snippet(post)
 f:SetScript(script,function(self,button,down)
  secureDepth=secureDepth+1
  local delta=script=='OnMouseWheel' and button or nil
  local replacement,message=before(self,button,down,delta,header)
  if replacement~=false then
   if old then old(self,replacement or button,down) end
   if after and message~=nil then after(self,button,down,delta,header) end
  end
  secureDepth=secureDepth-1
 end)
end
function ClearOverrideBindings(owner) GuardGlobal(); overrides[owner]={} end
function SetOverrideBindingClick(owner,priority,key,name,button) GuardGlobal(); overrides[owner]=overrides[owner] or {}; overrides[owner][key]={name=name,button=button,priority=priority} end
function GetBindingKey(action) local keys={}; for key,value in pairs(bindingKeys) do if value==action then keys[#keys+1]=key end end; table.sort(keys); return unpack(keys) end
function GetBindingAction(key) return bindingKeys[key] or '' end
function SetBinding(key,action) GuardGlobal(); if key=='INVALID' then return false end; bindingKeys[key]=action; return true end
function SaveBindings(set) GuardGlobal(); assert(set==1); bindingSaved=true end
function GetCurrentBindingSet() return 1 end
function RegisterStateDriver(f,key,condition)
 GuardGlobal(); secureDrivers[f]=condition; secureDepth=secureDepth+1
 if condition=='hide' or condition=='[combat] hide; show' and combat then f:Hide() else f:Show() end
 secureDepth=secureDepth-1
end
function Combat(value)
 combat=value; secureDepth=secureDepth+1
 for f,condition in pairs(secureDrivers) do if condition=='hide' or condition=='[combat] hide; show' and combat then f:Hide() else f:Show() end end
 secureDepth=secureDepth-1
end
function Click(f,button,down) f:RunScript('PreClick',button,down); f:RunScript('OnClick',button,down); f:RunScript('PostClick',button,down) end
function GameTooltip:SetOwner(owner) self.owner=owner end
function GameTooltip:GetOwner() return self.owner end
function GameTooltip:AddLine(text) self.tooltipText=text end
function GameTooltip:SetHyperlink(link) self.link=link end
function GetCursorPosition() return 100,100 end
function EllesmereUI.GetAccentColor() return .1,.8,.7 end
function EllesmereUI.MakeUnlockElement(opts) return {key=opts.key,getFrame=opts.getFrame,savePosition=opts.savePos,loadPosition=opts.loadPos,clearPosition=opts.clearPos,applyPosition=opts.applyPos,isHidden=opts.isHidden} end
unlock={}; function EllesmereUI:RegisterUnlockElements(list) for _,entry in ipairs(list) do unlock[entry.key]=entry end end
function EllesmereUI:RegisterUnlockModeListener(_,fn) unlockListener=fn end
function EllesmereUI:RegisterOnHide(fn) hideOptions=fn end
function EllesmereUI.EnsureOptionsLoaded() end
function EllesmereUI.GetFontPath() return 'Fonts\\FRIZQT__.TTF' end
