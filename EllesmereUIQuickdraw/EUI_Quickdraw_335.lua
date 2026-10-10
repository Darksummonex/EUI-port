local ADDON,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON]=ns; ns.IsWrath=true; ns.addon=E.Lite.NewAddon(ADDON); ns.EQD=ns.addon
ns.live={}; ns.selectedPalette=1; ns.events=CreateFrame("Frame")
local ICONS="Interface\\Icons\\"
ns.panelOrder={"character","spellbook","talents","achievements","quests","friends","guild","pvp","lfg","reputation","skills","currency","pet","calendar","macros","bags","worldmap","help","menu"}
ns.panels={character="CharacterMicroButton",spellbook="SpellbookMicroButton",talents="TalentMicroButton",achievements="AchievementMicroButton",quests="QuestLogMicroButton",friends="SocialsMicroButton",guild="SocialsMicroButton",pvp="PVPMicroButton",lfg="LFDMicroButton",calendar="GameTimeFrame",help="HelpMicroButton",menu="MainMenuMicroButton"}
ns.panelMacros={reputation='/run ToggleCharacter("ReputationFrame")',skills='/run ToggleCharacter("SkillFrame")',currency='/run ToggleCharacter("TokenFrame")',pet='/run ToggleCharacter("PetPaperDollFrame")',macros="/macro",bags="/run if ToggleAllBags then ToggleAllBags() else OpenAllBags() end",worldmap="/run ToggleFrame(WorldMapFrame)"}
ns.panelNames={character="Character",spellbook="Spellbook",talents="Talents",achievements="Achievements",quests="Quest Log",friends="Friends",guild="Guild",pvp="PvP",lfg="Dungeon Finder",reputation="Reputation",skills="Skills",currency="Currency",pet="Pets & Mounts",calendar="Calendar",macros="Macros",bags="Bags",worldmap="World Map",help="Help",menu="Game Menu"}
ns.panelIcons={character="INV_Chest_Cloth_17",spellbook="INV_Misc_Book_09",talents="Ability_Marksmanship",achievements="Achievement_Quests_Completed_08",quests="INV_Misc_Note_01",friends="INV_Misc_GroupNeedMore",guild="INV_Shirt_GuildTabard_01",pvp="INV_BannerPVP_02",lfg="INV_Misc_GroupLooking",reputation="Achievement_Reputation_01",skills="Trade_BlackSmithing",currency="INV_Misc_Coin_01",pet="Ability_Hunter_BeastTaming",calendar="INV_Misc_PocketWatch_01",macros="INV_Scroll_03",bags="INV_Misc_Bag_08",worldmap="INV_Misc_Map_01",help="INV_Misc_Note_05",menu="INV_Misc_Gear_01"}
-- Raid target icon order. The server's world marker spells are named by colour.
ns.markerNames={"Star","Circle","Diamond","Triangle","Moon","Square","Cross","Skull"}
ns.markerColors={"Yellow","Orange","Purple","Green","Silver","Blue","Red","White"}
ns.worldMarkerSpells={80952,80947,80948,80946,80950,80945,80949,80951}
ns.rezSpells={PRIEST={2006},PALADIN={7328},SHAMAN={2008},DRUID={50769,20484},DEATHKNIGHT={61999}}
ns.specSpells={63645,63644}
ns.professions={{key="alchemy",spell=2259},{key="blacksmithing",spell=2018},{key="enchanting",spell=7411},{key="engineering",spell=4036},{key="inscription",spell=45357},{key="jewelcrafting",spell=25229},{key="leatherworking",spell=2108},{key="tailoring",spell=3908},{key="mining",spell=2656},
 {key="cooking",spell=2550,secondary=true},{key="firstaid",spell=3273,secondary=true},{key="fishing",spell=7620,secondary=true},{key="runeforging",spell=53428,secondary=true},{key="disenchant",spell=13262,secondary=true},{key="prospecting",spell=31252,secondary=true},{key="milling",spell=51005,secondary=true}}
ns.defaults={profile={enabled=true,confirmKey="",cancelKey="",palettes={{name="Utilities",enabled=true,layout="ARC",fanOrientation="HORIZONTAL",arcSpan=360,arcRotation=0,centerMode="CURSOR",posX=0,posY=0,radius=100,iconSize=40,spacing=8,scale=1,columns=4,autoColumns=false,opacity=.95,
 showLabels=true,showCooldowns=true,showCounts=true,showUsability=true,hideUnusable=true,showActionText=false,showNeedle=true,openAnimation=true,toggleMode=false,worldMarkerCursor=true,textSize=11,fontOutline="OUTLINE",slots={}}}}}
-- Saved palette-1 entries were stored as diffs against these old sample defaults.
local LEGACY_SLOTS={{kind="item",id=6948},{kind="panel",id="character"},{kind="panel",id="spellbook"},{kind="panel",id="talents"},{kind="panel",id="quests"}}
function ns.Copy(value) if type(value)~="table" then return value end; local t={}; for k,v in pairs(value) do t[k]=ns.Copy(v) end; return t end
function ns.Clamp(value,min,max) return math.max(min,math.min(max,tonumber(value) or min)) end
function ns.MigrateProfile(p)
 if type(p)~="table" or p.slotsV2 then return end
 p.slotsV2=true
 local first=type(p.palettes)=="table" and p.palettes[1]
 if type(first)~="table" or type(first.slots)~="table" then return end
 for i,def in ipairs(LEGACY_SLOTS) do local slot=first.slots[i]
  if type(slot)=="table" and slot.kind==nil then for k,v in pairs(def) do if slot[k]==nil then slot[k]=v end end end
 end
 for i=#first.slots,1,-1 do if type(first.slots[i])~="table" or not first.slots[i].kind then table.remove(first.slots,i) end end
end
-- The first World Markers preset ended with a cycle entry that drew a second skull.
function ns.MigrateWorldMarkerPreset(p)
 if type(p)~="table" or p.worldMarkerPresetV2 then return end
 p.worldMarkerPresetV2=true
 for _,cfg in pairs(type(p.palettes)=="table" and p.palettes or {}) do
  local slots=type(cfg)=="table" and cfg.slots
  if cfg.name=="World Markers" and type(slots)=="table" and #slots==9 and slots[9].kind=="cycleworldmarker" then
   local markers=true; for i=1,8 do if slots[i].kind~="worldmarker" then markers=false end end
   if markers then slots[9]=nil end
  end
 end
end
local migrated=setmetatable({},{__mode="k"})
function ns.Profile()
 local p=ns.addon.db and ns.addon.db.profile
 if p and not migrated[p] then migrated[p]=true; ns.MigrateProfile(p); ns.MigrateWorldMarkerPreset(p) end
 return p
end
function ns.Palette(index) local p=ns.Profile(); return p and p.palettes[index] end
function ns.Selected() return ns.Palette(ns.selectedPalette) end
function ns.NewPalette(name,slots)
 local p=ns.Profile(); if #p.palettes>=16 then return end
 local cfg=ns.Copy(ns.defaults.profile.palettes[1]); cfg.name=name or "Palette "..(#p.palettes+1); cfg.slots={}
 for i,slot in ipairs(slots or {}) do if i<=20 then cfg.slots[i]=ns.Copy(slot) end end
 p.palettes[#p.palettes+1]=cfg; ns.selectedPalette=#p.palettes; ns.Apply(); return cfg
end
function ns.RemovePalette(index)
 -- Stable palette numbers preserve existing keybinding assignments.
 local cfg=ns.Palette(index); if cfg then cfg.enabled=false; cfg.slots={}; cfg.name="Empty Palette "..index; ns.Apply() end
end
local SKIP_COPY={name=true,enabled=true,slots=true}
function ns.CopySettings(from,to)
 local src,dst=ns.Palette(from),ns.Palette(to); if not src or not dst or src==dst then return false end
 for k,v in pairs(ns.defaults.profile.palettes[1]) do if not SKIP_COPY[k] then local value=src[k]; if value==nil then value=v end; dst[k]=ns.Copy(value) end end
 ns.Apply(); return true
end
local function Icon(path) if path and not path:find("\\") then return ICONS..path end; return path end
function ns.KnownSpell(name)
 if not name then return false end
 if not GetNumSpellTabs or not GetSpellTabInfo or not GetSpellName then return true end
 if not ns.spellCache then local cache={}
  for tab=1,GetNumSpellTabs() do local _,_,offset,count=GetSpellTabInfo(tab)
   for i=(offset or 0)+1,(offset or 0)+(count or 0) do local spell=GetSpellName(i,BOOKTYPE_SPELL or "spell"); if spell then cache[spell]=true end end
  end
  ns.spellCache=cache
 end
 return ns.spellCache[name]==true
end
local function SpellName(id) return GetSpellInfo(tonumber(id) or id) end
function ns.CompanionIndex(slot)
 local kind=slot.companionType or "MOUNT"
 if slot.spell and GetNumCompanions then for i=1,GetNumCompanions(kind) do local _,_,spell=GetCompanionInfo(kind,i); if spell==slot.spell then return i end end; return nil end
 return tonumber(slot.id)
end
function ns.RezSpells()
 local _,class=UnitClass("player"); local list=ns.rezSpells[class]; if not list then return end
 local known={}; for _,id in ipairs(list) do local name=SpellName(id); if name and ns.KnownSpell(name) then known[#known+1]=id end end
 return known[1] and known or nil
end
function ns.ProfessionSpell(slot)
 local id=slot.id
 if id=="primary1" or id=="primary2" then local want,n=id=="primary1" and 1 or 2,0
  for _,prof in ipairs(ns.professions) do if not prof.secondary and ns.KnownSpell(SpellName(prof.spell)) then n=n+1; if n==want then return prof.spell end end end
  return nil
 end
 for _,prof in ipairs(ns.professions) do if prof.key==id then return prof.spell end end
end
function ns.SpecInfo(group)
 local best,name,icon=-1,nil,nil
 if GetTalentTabInfo and GetNumTalentTabs then for tab=1,GetNumTalentTabs() do local tabName,tabIcon,points=GetTalentTabInfo(tab,false,false,group); if (points or 0)>best then best,name,icon=points or 0,tabName,tabIcon end end end
 return name,icon
end
local function MarkerIcon(id) return tonumber(id)==0 and "Interface\\Buttons\\UI-GroupLoot-Pass-Up" or "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"..tostring(id) end
local function WorldMarkerName(index) return SpellName(ns.worldMarkerSpells[index]) or "Raid Marker: "..ns.markerColors[index] end
ns.WorldMarkerName=WorldMarkerName
local RANDOM_MOUNT='/dismount [mounted]\n/run if not IsMounted() then local n=GetNumCompanions("MOUNT") if n>0 then CallCompanion("MOUNT",random(n)) end end'
function ns.Display(slot)
 local kind,id=slot.kind,slot.id
 if kind=="spell" then local name,_,icon=SpellName(id); return slot.label or name or "Unknown Spell",icon
 elseif kind=="item" then local name,_,_,_,_,_,_,_,_,icon=GetItemInfo(tonumber(id)); return slot.label or name or "Item "..tostring(id),icon
 elseif kind=="macro" then local name,icon=GetMacroInfo(tonumber(id) or id); return slot.label or name or "Unknown Macro",icon
 elseif kind=="companion" then local index=ns.CompanionIndex(slot); local _,name,_,icon; if index then _,name,_,icon=GetCompanionInfo(slot.companionType or "MOUNT",index) end; return slot.label or name or "Companion",icon
 elseif kind=="panel" then return slot.label or ns.panelNames[id] or "Panel",Icon(ns.panelIcons[id] or "INV_Misc_Book_09")
 elseif kind=="raidtarget" then return slot.label or (tonumber(id)==0 and "Clear Marker" or ns.markerNames[tonumber(id)] or "Raid Marker "..tostring(id)),MarkerIcon(id)
 elseif kind=="worldmarker" then local index=tonumber(id); return slot.label or (index and WorldMarkerName(index).." ("..ns.markerNames[index]..")" or "World Marker"),MarkerIcon(index or 0)
 elseif kind=="cycleraidtarget" then return slot.label or "Cycle Target Markers",MarkerIcon(1)
 elseif kind=="cycleworldmarker" then return slot.label or "Cycle World Markers",MarkerIcon(8)
 elseif kind=="equipmentset" then local icon=GetEquipmentSetInfoByName and GetEquipmentSetInfoByName(id); return slot.label or tostring(id),Icon(icon) or ICONS.."INV_Chest_Cloth_17"
 elseif kind=="rez" then local list=ns.RezSpells(); local name,_,icon; if list then name,_,icon=SpellName(list[1]) end; return slot.label or name or "Resurrect",icon or ICONS.."Spell_Holy_Resurrection"
 elseif kind=="randommount" then return slot.label or "Random Mount",ICONS.."Ability_Mount_RidingHorse"
 elseif kind=="lastmount" then local p=ns.Profile(); local name,_,icon=p and p.lastMount and SpellName(p.lastMount); return slot.label or (name and "Last Mount: "..name or "Last Mount"),icon or ICONS.."Ability_Mount_WhiteTiger"
 elseif kind=="spec" then local tree,icon=ns.SpecInfo(tonumber(id)); local which=tonumber(id)==2 and "Secondary" or "Primary"; return slot.label or (tree and tree.." ("..which..")" or which.." Spec"),icon or ICONS.."Achievement_General"
 elseif kind=="profession" then local spell=ns.ProfessionSpell(slot); local name,_,icon; if spell then name,_,icon=SpellName(spell) end
  local fallback=slot.id=="primary1" and "Profession 1" or slot.id=="primary2" and "Profession 2" or "Profession"; return slot.label or name or fallback,icon or ICONS.."Trade_Engineering"
 elseif kind=="cancelform" then return slot.label or "Cancel Form",ICONS.."Spell_Nature_WispSplode"
 elseif kind=="palette" then local target=ns.Palette(tonumber(id)); if not target then return slot.label or "Missing Menu",ICONS.."INV_Misc_QuestionMark" end
  local first=ns.NestChildren and ns.NestChildren(target)[1]; local icon=first and select(2,ns.Display(first))
  return slot.label or target.name or "Action Menu "..tostring(id),icon or ICONS.."INV_Misc_Bag_08"
 end
 return slot.label or "Custom Macro",ICONS.."INV_Misc_QuestionMark"
end
-- World markers are ground-targeted; [@cursor] places them without a ground click.
function ns.Action(slot,cfg)
 local kind,id=slot.kind,slot.id
 local atCursor=not cfg or cfg.worldMarkerCursor~=false
 if kind=="spell" then local name=SpellName(id); if name then return "spell",name end
 elseif kind=="item" and tonumber(id) then return "item","item:"..tonumber(id)
 elseif kind=="macro" then local name=GetMacroInfo(tonumber(id) or id); if name then return "macro",name end
 elseif kind=="macrotext" and type(id)=="string" and #id<=1023 then return "macrotext",id
 elseif kind=="panel" and ns.panels[id] then return "macrotext","/click "..ns.panels[id]..(id=="guild" and "\n/click FriendsFrameTab3" or "")
 elseif kind=="panel" and ns.panelMacros[id] then return "macrotext",ns.panelMacros[id]
 elseif kind=="raidtarget" and tonumber(id) and tonumber(id)>=0 and tonumber(id)<=8 and tonumber(id)%1==0 then return "macrotext",'/run SetRaidTarget("target",'..tonumber(id)..')'
 elseif kind=="worldmarker" and ns.worldMarkerSpells[tonumber(id) or 0] then
  if atCursor then return "macrotext","/cast [@cursor] "..WorldMarkerName(tonumber(id)) end
  return "spell",WorldMarkerName(tonumber(id))
 elseif kind=="cycleraidtarget" then return "macrotext",'/run local i=(EUIQuickdrawMarker or 0)%8+1 EUIQuickdrawMarker=i SetRaidTarget("target",i)'
 elseif kind=="cycleworldmarker" then local names={}; for i=1,8 do names[i]=WorldMarkerName(i) end; return "macrotext","/castsequence "..(atCursor and "[@cursor] " or "").."reset=60 "..table.concat(names,", ")
 elseif kind=="equipmentset" and type(id)=="string" and not id:find("[\r\n]") then return "macrotext","/equipset "..id
 elseif kind=="companion" then local index=ns.CompanionIndex(slot); if index then local _,_,spell=GetCompanionInfo(slot.companionType or "MOUNT",index); local name=spell and GetSpellInfo(spell); if name then return "spell",name end end
 elseif kind=="rez" then local list=ns.RezSpells(); if list then
  if list[2] then return "macrotext","/cast [combat] "..SpellName(list[2]).."; "..SpellName(list[1]) end
  return "spell",SpellName(list[1]) end
 elseif kind=="randommount" then return "macrotext",RANDOM_MOUNT
 elseif kind=="lastmount" then local p=ns.Profile(); local name=p and p.lastMount and SpellName(p.lastMount); if name then return "spell",name end; return "macrotext",RANDOM_MOUNT
 elseif kind=="spec" and ns.specSpells[tonumber(id) or 0] then local name=SpellName(ns.specSpells[tonumber(id)]); if name then return "spell",name end
 elseif kind=="profession" then local spell=ns.ProfessionSpell(slot); local name=spell and SpellName(spell); if name then return "spell",name end
 elseif kind=="cancelform" then return "macrotext","/cancelform"
 elseif kind=="palette" then local index=tonumber(id); if index and ns.Palette(index) then return "nest",index end
 end
end
-- Entries this character can never use are dropped when hideUnusable is on.
function ns.Unavailable(slot)
 local kind,id=slot.kind,slot.id
 if kind=="spell" then return not ns.KnownSpell(SpellName(id))
 elseif kind=="macro" then return not GetMacroInfo(tonumber(id) or id)
 elseif kind=="companion" then return ns.CompanionIndex(slot)==nil
 elseif kind=="equipmentset" then return GetEquipmentSetInfoByName and not GetEquipmentSetInfoByName(id) or false
 elseif kind=="rez" then return ns.RezSpells()==nil
 elseif kind=="spec" then return GetNumTalentGroups and GetNumTalentGroups()<(tonumber(id) or 1) or false
 elseif kind=="profession" then local spell=ns.ProfessionSpell(slot); return not spell or not ns.KnownSpell(SpellName(spell))
 elseif kind=="palette" then local target=ns.Palette(tonumber(id)); return not target or not ns.NestChildren or #ns.NestChildren(target)==0
 end
 return false
end
function ns.AddSlot(kind,id,extra)
 local cfg=ns.Selected(); if not cfg or #cfg.slots>=20 then return false,"Maximum 20 entries" end
 if kind=="palette" and tonumber(id)==ns.selectedPalette then return false,"A menu cannot open itself" end
 local slot={kind=kind,id=id}; if extra then for k,v in pairs(extra) do slot[k]=v end end
 if not ns.Action(slot) then return false,"Invalid action or unavailable spell/macro" end
 cfg.slots[#cfg.slots+1]=slot; ns.Apply(); return true
end
function ns.MoveSlot(from,to)
 local cfg=ns.Selected(); local list=cfg and cfg.slots; if not list then return false end
 if from==to or not list[from] or to<1 or to>#list then return false end
 table.insert(list,to,table.remove(list,from)); ns.Apply(); return true
end
function ns.AddCursor()
 if InCombatLockdown() then return false,"Edit actions outside combat" end
 local kind,id,book,spellID=GetCursorInfo()
 if kind=="spell" then
  local link=GetSpellLink and GetSpellLink(id,book or BOOKTYPE_SPELL or "spell"); id=spellID or link and tonumber(link:match("spell:(%d+)"))
 elseif kind=="companion" then local companionType=id; id=book; local _,_,spell=GetCompanionInfo(companionType,id)
  local ok,message=ns.AddSlot("companion",id,{companionType=companionType,spell=spell}); if ok then ClearCursor() end; return ok,message
 elseif kind=="equipmentset" then local ok,message=ns.AddSlot("equipmentset",id); if ok then ClearCursor() end; return ok,message
 elseif kind~="item" and kind~="macro" then return false,"Drag a spell, item, macro, companion or equipment set onto the cursor first" end
 local ok,message=ns.AddSlot(kind,id); if ok then ClearCursor() end; return ok,message
end
function ns.Bind(index,key,force)
 if InCombatLockdown() then return false,"Change bindings outside combat" end
 key=(key or ""):upper():gsub("%s","")
 if key=="" or key=="ESCAPE" or key:find("MOUSEWHEEL") then return false,"Choose a holdable key other than Escape or mouse wheel" end
 local current=GetBindingAction(key)
 if not force and current and current~="" and current~="EUI_RADIAL"..index then return false,"conflict",current end
 if E.NoteBinding then E.NoteBinding(key,current) end
 if SetBinding(key,"EUI_RADIAL"..index) then if SaveBindings then SaveBindings(GetCurrentBindingSet()) end; ns.Apply(); return true end
 return false,"Invalid binding key"
end
function ns.Apply()
 if not ns.Profile() or not ns.header then return end
 if InCombatLockdown() then ns.pending=true; return end
 if ns.Profile().enabled then for _,live in ipairs(ns.live) do if live.driver:GetAttribute("held") then ns.pending=true; return end end end
 ns.BuildPalettes(); ns.UpdateBindings(); ns.pending=false
end
-- Spell, macro and companion events arrive in bursts; one rebuild per frame.
function ns.RequestApply()
 if ns.applyQueued then return end
 ns.applyQueued=true
 C_Timer.After(0,function() ns.applyQueued=false; ns.Apply() end)
end
function ns.TrackMount()
 if not GetNumCompanions then return false end
 for i=1,GetNumCompanions("MOUNT") do local _,_,spell,_,active=GetCompanionInfo("MOUNT",i)
  if active and spell then local p=ns.Profile(); if p and p.lastMount~=spell then p.lastMount=spell; return true end; return false end
 end
 return false
end
function ns.addon:OnInitialize() ns.addon.db=E.Lite.NewDB("EllesmereUIQuickdrawDB",ns.defaults); ns.db=ns.addon.db end
function ns.addon:OnEnable()
 for _,event in ipairs({"UPDATE_BINDINGS","PLAYER_REGEN_ENABLED","SPELLS_CHANGED","LEARNED_SPELL_IN_TAB","PLAYER_ENTERING_WORLD","COMPANION_UPDATE","COMPANION_LEARNED","UPDATE_MACROS","EQUIPMENT_SETS_CHANGED","ACTIVE_TALENT_GROUP_CHANGED","UPDATE_SHAPESHIFT_FORMS"}) do ns.events:RegisterEvent(event) end
 ns.events:SetScript("OnEvent",function(_,event,arg1)
  if event=="SPELLS_CHANGED" or event=="LEARNED_SPELL_IN_TAB" then ns.spellCache=nil end
  if event=="COMPANION_UPDATE" and not ns.TrackMount() and arg1==nil then return end
  if not ns.header and not InCombatLockdown() then ns.CreatePalettes() end
  if event=="PLAYER_REGEN_ENABLED" then ns.Apply() else ns.RequestApply() end
 end)
 if InCombatLockdown() then ns.pending=true else ns.CreatePalettes(); ns.Apply() end
end
_EQD_Apply=ns.Apply
BINDING_HEADER_EUI_RADIAL="EllesmereUI Quickdraw"
for i=1,16 do _G["BINDING_NAME_EUI_RADIAL"..i]="Quickdraw Palette "..i end
SLASH_EQD1="/eqd"
SlashCmdList.EQD=function() if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; if E.ShowModule then E:ShowModule(ADDON) end end
