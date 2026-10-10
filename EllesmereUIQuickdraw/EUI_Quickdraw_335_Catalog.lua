local _,ns=...
if not ns.IsWrath then return end
ns.catalogOrder={"spells","mounts","pets","items","macros","equipmentsets","targetmarkers","worldmarkers","teleports","hearthstones","potions","forms","specs","professions","questitems","panels","dynamic","menus"}
ns.catalogNames={menus="Action Menus",spells="Spells",mounts="Mounts",pets="Companions",items="Items",macros="Macros",equipmentsets="Equipment Sets",targetmarkers="Target Markers",worldmarkers="World Markers",teleports="Teleports",hearthstones="Hearthstones",potions="Potions",forms="Forms & Stances",specs="Specializations",professions="Professions",questitems="Quest Items",panels="Interface Panels",dynamic="Dynamic Actions"}
ns.presetOrder={"targetmarkers","worldmarkers","panels","hearthstones","teleports","potions","forms","specs","professions","questitems","equipmentsets","mounts"}
ns.teleportSpells={3561,3562,3565,32271,49359,33690,53140,3567,3563,3566,32272,49358,35715,10059,11416,11419,32266,49360,33691,53142,11417,11418,11420,32267,49361,35717,50977,18960,556}
ns.hearthstoneItems={6948,28585,37118,44314,44315,40585,40586,44934,44935,45688,45689,45690,45691,48954,48955,48956,48957,51557,51558,51559,51560,46874,32757,18984,18986,30542,30544,48933,50287,54452,52251,22589,22630,22631,22632}
local function Entry(list,slot) list[#list+1]={text=(ns.Display(slot)),slot=slot} end
local function BagItems(filter)
 local list,seen={},{}
 if not GetContainerNumSlots then return list end
 for bag=0,4 do for slotIndex=1,GetContainerNumSlots(bag) do
  local link=GetContainerItemLink and GetContainerItemLink(bag,slotIndex); local id=link and tonumber(link:match("item:(%d+)"))
  if id and not seen[id] then seen[id]=true; local name,_,_,_,_,itemType,subType=GetItemInfo(id)
   if name and filter(id,itemType,subType) then list[#list+1]={text=name,slot={kind="item",id=id}} end
  end
 end end
 table.sort(list,function(a,b) return a.text<b.text end)
 return list
end
local function Usable(id) return not GetItemSpell or GetItemSpell(id)~=nil end
local builders={}
function builders.spells()
 local list,seen={},{}
 if not GetNumSpellTabs then return list end
 for tab=1,GetNumSpellTabs() do local _,_,offset,count=GetSpellTabInfo(tab)
  for i=offset+1,offset+count do local name=GetSpellName(i,BOOKTYPE_SPELL or "spell")
   if name and not (IsPassiveSpell and IsPassiveSpell(i,BOOKTYPE_SPELL or "spell")) then
    local link=GetSpellLink and GetSpellLink(i,BOOKTYPE_SPELL or "spell"); local id=link and tonumber(link:match("spell:(%d+)"))
    if id then if seen[name] then list[seen[name]].slot.id=id else list[#list+1]={text=name,slot={kind="spell",id=id}}; seen[name]=#list end end
   end
  end
 end
 return list
end
local function Companions(kind)
 local list={}
 if not GetNumCompanions then return list end
 for i=1,GetNumCompanions(kind) do local _,name,spell=GetCompanionInfo(kind,i); if name then list[#list+1]={text=name,slot={kind="companion",companionType=kind,id=i,spell=spell}} end end
 return list
end
function builders.mounts()
 local list={{text="Random Mount",slot={kind="randommount"}},{text="Last Used Mount",slot={kind="lastmount"}}}
 for _,entry in ipairs(Companions("MOUNT")) do list[#list+1]=entry end
 return list
end
function builders.pets() return Companions("CRITTER") end
function builders.items() return BagItems(function(id) return Usable(id) end) end
function builders.macros()
 local list={}
 if not GetMacroInfo then return list end
 for i=1,54 do local name=GetMacroInfo(i); if name then list[#list+1]={text=name,slot={kind="macro",id=name}} end end
 return list
end
function builders.equipmentsets()
 local list={}
 if not GetNumEquipmentSets then return list end
 for i=1,GetNumEquipmentSets() do local name=GetEquipmentSetInfo(i); if name then list[#list+1]={text=name,slot={kind="equipmentset",id=name}} end end
 return list
end
function builders.targetmarkers()
 local list={}
 for i=1,8 do Entry(list,{kind="raidtarget",id=i}) end
 Entry(list,{kind="raidtarget",id=0}); Entry(list,{kind="cycleraidtarget"})
 return list
end
function builders.worldmarkers()
 local list={}
 for i=1,8 do Entry(list,{kind="worldmarker",id=i}) end
 return list
end
function builders.teleports()
 local list={}
 for _,id in ipairs(ns.teleportSpells) do local name=GetSpellInfo(id); if name and ns.KnownSpell(name) then Entry(list,{kind="spell",id=id}) end end
 return list
end
function builders.hearthstones()
 local list={}
 for _,id in ipairs(ns.hearthstoneItems) do if (GetItemCount(id) or 0)>0 or IsEquippedItem and IsEquippedItem(id) then Entry(list,{kind="item",id=id}) end end
 return list
end
function builders.potions() return BagItems(function(_,_,subType) return subType=="Potion" end) end
function builders.questitems() return BagItems(function(id,itemType) return itemType=="Quest" and Usable(id) end) end
function builders.forms()
 local list={}
 if GetNumShapeshiftForms then for i=1,GetNumShapeshiftForms() do local _,name=GetShapeshiftFormInfo(i); if name then Entry(list,{kind="spell",id=name}) end end end
 local _,class=UnitClass("player"); if class=="DRUID" or class=="PRIEST" or class=="SHAMAN" then Entry(list,{kind="cancelform"}) end
 return list
end
function builders.specs()
 local list={}
 for group=1,(GetNumTalentGroups and GetNumTalentGroups() or 1) do Entry(list,{kind="spec",id=group}) end
 return list
end
function builders.professions()
 local list={}
 Entry(list,{kind="profession",id="primary1"}); Entry(list,{kind="profession",id="primary2"})
 for _,prof in ipairs(ns.professions) do local name=GetSpellInfo(prof.spell); if name and ns.KnownSpell(name) then Entry(list,{kind="profession",id=prof.key}) end end
 return list
end
function builders.panels()
 local list={}
 for _,id in ipairs(ns.panelOrder) do Entry(list,{kind="panel",id=id}) end
 return list
end
function builders.dynamic()
 local list={}
 for _,slot in ipairs({{kind="rez"},{kind="randommount"},{kind="lastmount"},{kind="cycleraidtarget"},{kind="cycleworldmarker"},{kind="clearworldmarkers"},{kind="cancelform"}}) do Entry(list,slot) end
 return list
end
function builders.menus()
 local list={}
 local profile=ns.Profile()
 for i,cfg in ipairs(profile and profile.palettes or {}) do
  if i~=ns.selectedPalette and #(cfg.slots or {})>0 then list[#list+1]={text=i..". "..(cfg.name or "Action Menu"),slot={kind="palette",id=i}} end
 end
 return list
end
function ns.Catalog(category) local build=builders[category]; return build and build() or {} end
function ns.PresetSlots(category)
 local slots={}
 for _,entry in ipairs(ns.Catalog(category)) do if #slots<20 then slots[#slots+1]=entry.slot end end
 return slots
end
function ns.NewPresetPalette(category)
 local slots=category and ns.PresetSlots(category) or {}
 return ns.NewPalette(category and ns.catalogNames[category] or nil,slots)
end
