local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E._ModuleNS and E._ModuleNS.EllesmereUICooldownManager
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
 self:UnregisterEvent("PLAYER_LOGIN")
 local index,addKind,addID,status=1,"spell","",""
 local function Refresh() E:InvalidatePageCache(); E:RefreshPage(true) end
 local function Label(t) return {type="label",text=t} end
 local function Group() return ns.selectedBar or "cooldowns" end
 local function Config() return ns.Config(Group()) end
 local function List() local lists=ns.Lists(); lists[Group()]=lists[Group()] or {}; return lists[Group()] end
 local function Entry() return List()[index] end
 local function Field(store,key,text,kind,min,max,step)
  return {type=kind,text=text,min=min,max=max,step=step or 1,getValue=function() local p=store(); return p and p[key] end,
   setValue=function(v) local p=store(); if p then p[key]=v; ns.Apply() end end}
 end
 local function DD(store,key,text,values,order) local c=Field(store,key,text,"dropdown"); c.values,c.order=values,order; return c end
 local function Add(kind,id)
  id=tonumber(id)
  if not id or id<1 or id~=math.floor(id) or kind=="slot" and id>19 then status="Enter a valid ID or equipment slot 1-19"; Refresh(); return end
  if (kind=="spell" or kind=="aura") and not GetSpellInfo(id) then status="Spell ID unavailable in this client"; Refresh(); return end
  local l=List(); if #l>=40 then status="Maximum 40 entries per group"; Refresh(); return end
  l[#l+1]={kind=kind,id=id,enabled=true,unit="player",filter="HELPFUL"}; index=#l
  status="Added. Unlearned spells and empty equipment slots stay hidden."; ns.Apply(); Refresh()
 end
 E:RegisterModule("EllesmereUICooldownManager",{title="Cooldown Manager",description="Wrath spells, items and auras. Assignments are saved for each dual talent group.",
 pages={"CDM Bars","Tracking Bars","Bar Glows"},searchTerms="cooldown manager CDM tracking bars buffs debuffs spell aura item equipment trinket glow keybind duration stacks range preview",
 buildPage=function(page,parent,y)
  local W=E.Widgets
  local function Row(a,b) local _,h=W:DualRow(parent,y,a,b or Label("")); y=y-h end
  local function Section(t) local _,h=W:SectionHeader(parent,t,y); y=y-h end
  local function Button(t,fn) local _,h=W:WideButton(parent,t,y,fn); y=y-h end
  if page=="Tracking Bars" then ns.selectedBar="tracking" elseif Group()=="tracking" then ns.selectedBar="cooldowns" end
  if ns.selectedEntry then for i,e in ipairs(List()) do if e==ns.selectedEntry then index=i end end; ns.selectedEntry=nil end
  Section("COOLDOWN MANAGER")
  Row(Field(ns.Profile,"enabled","Enable Cooldown Manager","toggle"),Label("Assignments: "..ns.SpecKey()))
  if page~="Tracking Bars" then Row({type="dropdown",text="Select Bar",values={cooldowns="Cooldowns",utility="Utility",buffs="Buffs"},order={"cooldowns","utility","buffs"},getValue=Group,
   setValue=function(v) ns.selectedBar=v; index=1; Refresh() end}) end
  if page=="Bar Glows" then
   Section("GLOWS")
   Row(DD(Config,"glow","Icon Glow",{none="None",active="Active Aura",ready="Ready Cooldown",cooldown="On Cooldown"},{"none","active","ready","cooldown"}),Field(ns.Profile,"glowsOnlyInCombat","Glows Only In Combat","toggle"))
   Row(Field(ns.Profile,"actionBarGlows","Highlight EUI Action Buttons","toggle"),Field(ns.Profile,"readySound","Cooldown Ready Sound","toggle"))
   Row(Label("Assign an aura's Highlight Spell ID below to light its action button."))
  else
   Section("BAR SETTINGS")
   Row(Field(Config,"enabled","Show This Bar","toggle"),DD(Config,"visibility","Visibility",{always="Always",combat="In Combat",target="With Target"},{"always","combat","target"}))
   Row(DD(Config,"show","Show Entries",{always="Always",active="Active Aura / Cooldown",cooldown="On Cooldown",ready="Ready"},{"always","active","cooldown","ready"}),DD(Config,"growDirection","Growth Direction",{RIGHT="Right / Down",LEFT="Left / Down",UP="Up",DOWN="Down"},{"RIGHT","LEFT","UP","DOWN"}))
   if page=="Tracking Bars" then Row(Field(Config,"width","Bar Width","slider",120,600),Field(Config,"height","Bar Height","slider",16,40))
   else Row(Field(Config,"iconSize","Icon Size","slider",16,80),Field(Config,"columns","Icons Per Row","slider",1,40)) end
   Row(Field(Config,"spacing","Spacing","slider",0,20),Field(Config,"scale","Scale","slider",.5,2,.05))
   Row(Field(Config,"alpha","Opacity","slider",.1,1,.05),Field(Config,"bgAlpha","Background Opacity","slider",0,1,.05))
   Row(Field(Config,"showText","Duration Text","toggle"),Field(Config,"showStacks","Show Stacks","toggle"))
   Row(Field(Config,"showKeybind","Show Keybinds","toggle"),Field(Config,"showGCD","Show Global Cooldown","toggle"))
   Row(Field(Config,"showRange","Range Color","toggle"),Field(Config,"tooltip","Mouseover Tooltip","toggle"))
   Row(Field(Config,"textSize","Text Size","slider",8,24),DD(Config,"fontOutline","Text Outline",{OUTLINE="Outline",THICKOUTLINE="Thick Outline",GLOBAL="Global"},{"OUTLINE","THICKOUTLINE","GLOBAL"}))
   Row(DD(Config,"sort","Entry Order",{assigned="Assigned Order",remaining="Remaining Duration"},{"assigned","remaining"}),{type="toggle",text="Preview",getValue=function() return ns.optionsPreview end,
    setValue=function(v) ns.optionsPreview=v; ns.preview=v or ns.unlockPreview; ns.Apply() end})
   Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
   Button("Reset Bar Position",function() ns.Profile().positions[Group()]=nil; ns.Apply() end)
  end
  Section("ASSIGNED SPELLS AND ITEMS")
  local values,order={},{}
  for i,e in ipairs(List()) do local m=ns.Resolve(e); values[i]=i..". "..(m and m.name or e.kind.." "..e.id); order[#order+1]=i end
  if #order>0 then
   index=math.max(1,math.min(index,#order))
   Row({type="dropdown",text="Edit Entry",values=values,order=order,getValue=function() return index end,setValue=function(v) index=v; Refresh() end},Field(Entry,"enabled","Enable Entry","toggle"))
   if Entry().kind=="aura" then
    Row(DD(Entry,"unit","Aura Unit",{player="Player",target="Target",focus="Focus"},{"player","target","focus"}),DD(Entry,"filter","Aura Type",{HELPFUL="Buff",HARMFUL="Debuff"},{"HELPFUL","HARMFUL"}))
    Row(Field(Entry,"ownOnly","Own Auras Only","toggle"),{type="input",text="Highlight Spell ID",getValue=function() return tostring(Entry().highlightSpellID or "") end,
     setValue=function(v) Entry().highlightSpellID=tonumber(v); ns.Apply() end})
   end
   Button("Move Entry Up",function() local l=List(); if index>1 then l[index],l[index-1]=l[index-1],l[index]; index=index-1; ns.Apply(); Refresh() end end)
   Button("Move Entry Down",function() local l=List(); if index<#l then l[index],l[index+1]=l[index+1],l[index]; index=index+1; ns.Apply(); Refresh() end end)
   Button("Remove Entry",function() table.remove(List(),index); ns.Apply(); Refresh() end)
  end
  Section("ADD ENTRY")
  Row({type="dropdown",text="Entry Type",values={spell="Spell Cooldown",aura="Buff / Debuff",item="Item Cooldown",slot="Equipment Slot"},order={"spell","aura","item","slot"},getValue=function() return addKind end,setValue=function(v) addKind=v end},
   {type="input",text="Spell / Item ID",getValue=function() return addID end,setValue=function(v) addID=v end})
  Button("Add Entry",function() Add(addKind,addID) end)
  local learned,learnedOrder={},{}
  for key,m in pairs(ns.spells) do if type(key)=="string" and m.id and not m.passive then learned[m.id]=m.name; learnedOrder[#learnedOrder+1]=m.id end end
  table.sort(learnedOrder,function(a,b) return learned[a]<learned[b] end)
  Row({type="dropdown",text="Add Learned Spell",values=learned,order=learnedOrder,getValue=function() return nil end,setValue=function(v) Add("spell",v) end},Label(status))
  Button("Restore Default Assignments For This Bar",function() local _,class=UnitClass("player"); ns.Lists()[Group()]=ns.SeedLists(class)[Group()]; index=1; ns.Apply(); Refresh() end)
  return math.abs(y)
 end,onReset=function() ns.addon.db:ResetProfile(); ns.Apply(); Refresh() end})
 if E.RegisterOnHide then E:RegisterOnHide(function() ns.optionsPreview=false; ns.preview=ns.unlockPreview; ns.Update() end) end
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
