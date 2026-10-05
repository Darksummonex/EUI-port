local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E._ModuleNS and E._ModuleNS.EllesmereUIAuraBuffReminders
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
 self:UnregisterEvent("PLAYER_LOGIN")
 local selectedCustom,selectedTalent,newID,newTalentID=1,1,"",""
 local function Refresh() E:InvalidatePageCache(); E:RefreshPage(true) end
 local function Label(t) return {type="label",text=t} end
 local function Store(key) return function() return ns.Profile()[key] end end
 local function Field(store,key,text,kind,min,max,step)
  return {type=kind,text=text,min=min,max=max,step=step or 1,getValue=function() local p=store(); return p and p[key] end,setValue=function(v) local p=store(); if p then p[key]=v; ns.Apply() end end}
 end
 local function DD(store,key,text,values,order) local c=Field(store,key,text,"dropdown"); c.values,c.order=values,order; return c end
 local where={always="Always",instances="In Instances",group="In Group",combat="In Combat",outofcombat="Out of Combat"}; local whereOrder={"always","instances","group","combat","outofcombat"}
 local sounds={"none","AirHorn","BananaPeelSlip","BikeHorn","BoxingArenaSound","WaterDrop"}
 E:RegisterModule("EllesmereUIAuraBuffReminders",{title="AuraBuff Reminders",description="Missing/expiring buffs, personal auras, consumables and manually assigned talent reminders.",pages={"Auras, Buffs & Consumables","Custom Reminders","Talent Reminders"},searchTerms="aura buff reminders raid missing expiry food flask weapon enchant poison imbue personal talent zone spell ID preview",
 buildPage=function(page,parent,y)
  local W=E.Widgets
  local function Row(a,b) local _,h=W:DualRow(parent,y,a,b or Label("")); y=y-h end
  local function Section(t) local _,h=W:SectionHeader(parent,t,y); y=y-h end
  local function Button(t,fn) local _,h=W:WideButton(parent,t,y,fn); y=y-h end
  if page=="Auras, Buffs & Consumables" then
   Section("DISPLAY")
   Row(Field(Store("display"),"remindersEnabled","Enable Reminders","toggle"),Field(Store("display"),"hideInCombat","Hide In Combat","toggle"))
   Row(Field(Store("display"),"iconSize","Icon Size","slider",20,80),Field(Store("display"),"iconSpacing","Spacing","slider",0,30))
   Row(Field(Store("display"),"scale","Scale","slider",.5,2,.05),Field(Store("display"),"opacity","Opacity","slider",.1,1,.05))
   Row(DD(Store("display"),"growDirection","Growth Direction",{CENTER="Centered",LEFT="Left",RIGHT="Right"},{"CENTER","LEFT","RIGHT"}),Field(Store("display"),"showUnder","Remind Below (Seconds)","slider",0,600,5))
   Row(Field(Store("display"),"showText","Show Labels","toggle"),Field(Store("display"),"showCount","Show Missing / Item Count","toggle"))
   Row(Field(Store("display"),"showTooltips","Tooltips","toggle"),Field(Store("display"),"hideMounted","Hide When Mounted","toggle"))
   Row(Field(Store("display"),"glow","Accent Border","toggle"),Field(Store("display"),"textSize","Text Size","slider",8,20))
   Row({type="toggle",text="Preview",getValue=function() return ns.optionsPreview end,setValue=function(v) ns.optionsPreview=v; ns.preview=v or ns.unlockPreview; ns.Apply() end},Label("Click-to-cast is available outside combat."))
   Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
   Button("Reset Position",function() ns.Profile().unlockPos=nil; ns.Apply() end)
   Section("RAID BUFFS")
   Row(DD(Store("raidBuffs"),"scope","Check Units",{player="Player Only",group="Party / Raid"},{"player","group"}),DD(Store("raidBuffs"),"where","Where To Show",where,whereOrder))
   Row(Field(Store("raidBuffs"),"othersMissing","Others Missing My Buffs","toggle"),Field(Store("raidBuffs"),"iAmMissing","I Am Missing Group Buffs","toggle"))
   Row(DD(Store("raidBuffs"),"sound","Raid Buff Sound",ns.sounds,sounds))
   for _,def in ipairs(ns.raidBuffs) do local name=GetSpellInfo(def.spell); Row(Field(function() return ns.Profile().raidBuffs.enabled end,def.key,name or def.key,"toggle")) end
   Section("PERSONAL AURAS")
   Row(DD(Store("auras"),"where","Aura Visibility",where,whereOrder),DD(Store("auras"),"sound","Aura Sound",ns.sounds,sounds))
   local _,class=UnitClass("player")
   for _,def in ipairs(ns.personal[class] or {}) do Row(Field(function() return ns.Profile().auras.enabled end,def.key,def.key=="pet" and "Pet Reminder" or GetSpellInfo(def.spell) or def.key,"toggle")) end
   Section("CONSUMABLES")
   Row(Field(Store("consumables"),"food","Food Reminder","toggle"),Field(Store("consumables"),"flask","Flask Reminder","toggle"))
   Row(Field(Store("consumables"),"mainhand","Main Hand Enchant","toggle"),Field(Store("consumables"),"offhand","Off Hand Enchant","toggle"))
   Row(DD(Store("consumables"),"where","Consumable Visibility",where,whereOrder),Field(Store("consumables"),"showWithoutItem","Show Restock Reminders","toggle"))
   Row(DD(Store("consumables"),"sound","Consumable Sound",ns.sounds,sounds))
   local foods,flasks={},{}; for _,id in ipairs(ns.foodItems) do foods[id]=GetItemInfo(id) or "Item "..id end; for _,id in ipairs(ns.flaskItems) do flasks[id]=GetItemInfo(id) or "Item "..id end
   Row(DD(Store("consumables"),"preferredFood","Preferred Food",foods,ns.foodItems),DD(Store("consumables"),"preferredFlask","Preferred Flask",flasks,ns.flaskItems))
  else
   local talent=page=="Talent Reminders"; local key=talent and "talentReminders" or "customReminders"
   local function List() return ns.Profile()[key] end
   local function Index() return talent and selectedTalent or selectedCustom end
   local function Entry() return List()[Index()] end
   Section(talent and "TALENT REMINDERS" or "CUSTOM MISSING AURAS")
   local values,order={},{}
   for i,e in ipairs(List()) do values[i]=e.label or GetSpellInfo(e.spellID) or "Spell "..e.spellID; order[#order+1]=i end
   if #order>0 then
    if talent then selectedTalent=math.min(selectedTalent,#order) else selectedCustom=math.min(selectedCustom,#order) end
    Row({type="dropdown",text="Select Reminder",values=values,order=order,getValue=Index,setValue=function(v) if talent then selectedTalent=v else selectedCustom=v end; Refresh() end},Field(Entry,"enabled","Enabled","toggle"))
    if talent then Row(Field(Entry,"zone","Exact Zone Name (Blank = Any)","input"),Label("Shows when the expected spell is not learned."))
    else
     Row(Field(Entry,"label","Label","input"),DD(Entry,"unit","Unit",{player="Player",target="Target",focus="Focus"},{"player","target","focus"}))
     Row(DD(Entry,"filter","Aura Type",{HELPFUL="Buff",HARMFUL="Debuff"},{"HELPFUL","HARMFUL"}),Field(Entry,"ownOnly","Own Only","toggle"))
     Row(DD(Entry,"where","Visibility",where,whereOrder),Field(Entry,"showUnder","Expiry Threshold (Seconds)","slider",0,600,5))
    end
    Button("Remove Reminder",function() table.remove(List(),Index()); if talent then selectedTalent=1 else selectedCustom=1 end; ns.Apply(); Refresh() end)
   end
   Row({type="input",text=talent and "Expected Talent Spell ID" or "Aura Spell ID",getValue=function() return talent and newTalentID or newID end,setValue=function(v) if talent then newTalentID=v else newID=v end end})
   Button("Add Reminder",function() local id=tonumber(talent and newTalentID or newID); if id and GetSpellInfo(id) and #List()<20 then
    List()[#List()+1]={spellID=id,enabled=true,unit="player",filter="HELPFUL",where="always",showUnder=60,zone=""}; if talent then selectedTalent=#List() else selectedCustom=#List() end; ns.Apply(); Refresh()
   end end)
  end
  Button("Restore Dismissed Reminders",function() ns.dismissed={}; ns.Refresh() end)
  return math.abs(y)
 end,onReset=function() ns.addon.db:ResetProfile(); ns.Apply(); Refresh() end})
 if E.RegisterOnHide then E:RegisterOnHide(function() ns.optionsPreview=false; ns.preview=ns.unlockPreview; ns.Refresh() end) end
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
