local ADDON,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON]=ns; ns.IsWrath=true; ns.addon=E.Lite.NewAddon(ADDON); ns.EABR=ns.addon
ns.dismissed,ns.previous,ns.spells,ns.cache,ns.missing={},{},{},{},{}
ns.events=CreateFrame("Frame")
ns.defaults={profile={display={remindersEnabled=true,iconSize=40,iconSpacing=8,scale=1,opacity=1,growDirection="CENTER",showText=true,showCount=true,showTooltips=true,textSize=11,fontOutline="OUTLINE",showUnder=60,hideInCombat=false,hideMounted=true,glow=true},
 raidBuffs={enabled={motw=true,fort=true,spirit=true,shadow=true,intellect=true,shout=true,horn=true},scope="group",othersMissing=true,iAmMissing=false,where="instances",sound="none"},
 auras={enabled={innerfire=true,shadowform=true,armor=true,pet=true,aspect=true,aura=true,seal=true,shield=true},where="always",sound="none"},consumables={food=true,flask=true,mainhand=true,offhand=true,where="instances",showWithoutItem=true,preferredFood=43015,preferredFlask=46376,sound="none"},customReminders={},talentReminders={},unlockPos=nil}}
function ns.Profile() return ns.addon.db and ns.addon.db.profile end
function ns.Known(id) if not tonumber(id) then return end; local name=GetSpellInfo(tonumber(id)); return name and ns.spells[name] end
function ns.ScanSpells()
 ns.spells={}
 for slot=1,1024 do local name=GetSpellName(slot,BOOKTYPE_SPELL or "spell"); if not name then break end
  local link=GetSpellLink and GetSpellLink(slot,BOOKTYPE_SPELL or "spell"); local id=link and tonumber(link:match("spell:(%d+)"))
  ns.spells[name]={name=name,slot=slot,id=id,icon=GetSpellTexture(slot,BOOKTYPE_SPELL or "spell")}
 end
end
function ns.Roster(scope)
 local units={}
 if scope~="player" and GetNumRaidMembers()>0 then for i=1,GetNumRaidMembers() do units[#units+1]="raid"..i end
 else units[1]="player"; if scope~="player" then for i=1,GetNumPartyMembers() do units[#units+1]="party"..i end end end
 return units
end
function ns.ScanUnit(unit)
 if ns.cache[unit] then return ns.cache[unit] end
 local list={}; ns.cache[unit]=list
 for _,filter in ipairs({"HELPFUL","HARMFUL"}) do list[filter]={}
  for i=1,40 do local name,_,icon,count,_,duration,expires,caster,_,_,id=UnitAura(unit,i,filter); if not name then break end
   list[filter][#list[filter]+1]={name=name,id=id,icon=icon,count=count or 0,duration=duration or 0,expires=expires or 0,caster=caster,index=i}
  end
 end
 return list
end
function ns.Present(unit,ids,filter,ownOnly,threshold)
 local names={}; local set={}; for _,id in ipairs(ids) do set[id]=true; local name=GetSpellInfo(id); if name then names[name]=true end end
 local now=GetTime()
 for _,a in ipairs(ns.ScanUnit(unit)[filter or "HELPFUL"]) do
  if (set[a.id] or names[a.name]) and (not ownOnly or a.caster=="player" or a.caster and UnitIsUnit(a.caster,"player")) then
   if a.duration==0 or a.expires>now+(InCombatLockdown() and 0 or threshold or 0) then return true,a end
  end
 end
 return false
end
function ns.Where(where)
 if where=="combat" then return InCombatLockdown() elseif where=="outofcombat" then return not InCombatLockdown() elseif where=="group" then return GetNumPartyMembers()>0 or GetNumRaidMembers()>0
 elseif where=="instances" then local inside,kind=IsInInstance(); return inside and (kind=="party" or kind=="raid" or kind=="arena" or kind=="pvp") end
 return true
end
local function Reachable(unit)
 if not UnitExists(unit) or not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then return false end
 if UnitInRange then local inRange=UnitInRange(unit); if inRange==false then return false end end
 return not UnitIsVisible or UnitIsVisible(unit)
end
local function BestSpell(def)
 for _,id in ipairs(def.prefer or {}) do local s=ns.Known(id); if s then return s end end
 return ns.Known(def.groupSpell) or ns.Known(def.spell)
end
local function Add(key,label,icon,count,unit,spell,item,section,reason)
 if ns.dismissed[key] then return end
 ns.missing[#ns.missing+1]={key=key,name=label,icon=icon,count=count or 1,unit=unit or "player",spell=spell,item=item,section=section,reason=reason}
end
function ns.Collect()
 local p=ns.Profile(); ns.cache={}; ns.missing={}
 if not p or not p.display.remindersEnabled or UnitIsDeadOrGhost("player") or p.display.hideMounted and IsMounted and IsMounted() then return end
 local _,class=UnitClass("player"); local threshold=tonumber(p.display.showUnder) or 60
 local group=ns.Roster(p.raidBuffs.scope)
 if ns.Where(p.raidBuffs.where) then for _,def in ipairs(ns.raidBuffs) do if p.raidBuffs.enabled[def.key]~=false then
  local spell=class==def.class and BestSpell(def)
  if spell and p.raidBuffs.othersMissing then
   local count,first=0,nil
   for _,unit in ipairs(group) do if Reachable(unit) and not ns.Present(unit,def.buffs,"HELPFUL",false,threshold) then count=count+1; first=first or unit end end
   if count>0 then Add("raid:"..def.key,spell.name,spell.icon,count,first,spell,nil,"raidBuffs","Missing or expiring on "..count.." reachable group member(s)") end
  elseif p.raidBuffs.iAmMissing and not ns.Present("player",def.buffs,"HELPFUL",false,threshold) then
   local provider=false; for _,unit in ipairs(group) do local _,c=UnitClass(unit); if c==def.class and Reachable(unit) then provider=true end end
   if provider then local name,_,icon=GetSpellInfo(def.spell); if name then Add("raid:"..def.key,name,icon,1,"player",nil,nil,"raidBuffs","Ask a "..def.class.." for this buff") end end
  end
 end end end
 if ns.Where(p.auras.where) then for _,def in ipairs(ns.personal[class] or {}) do if p.auras.enabled[def.key]~=false then
  local spell=BestSpell(def); local allowed=true
  if def.tree and GetTalentTabInfo then local best,points=1,-1; for tab=1,3 do local _,_,spent=GetTalentTabInfo(tab); if (spent or 0)>points then best,points=tab,spent or 0 end end; allowed=best==def.tree end
  if spell and allowed then
   if def.kind=="pet" then
    if not UnitExists("pet") or UnitIsDeadOrGhost("pet") then local revive=class=="HUNTER" and UnitIsDeadOrGhost("pet") and ns.Known(982); Add("aura:pet",revive and revive.name or spell.name,spell.icon,1,"player",revive or spell,nil,"auras","Your permanent pet is missing or dead") end
   elseif not ns.Present("player",def.buffs,"HELPFUL",false,threshold) then Add("aura:"..def.key,spell.name,spell.icon,1,"player",spell,nil,"auras","Missing or expiring personal aura") end
  end
 end end end
 local co=p.consumables
 if ns.Where(co.where) then
  for _,kind in ipairs({"flask","food"}) do if co[kind] and not ns.Present("player",ns[kind=="food" and "food" or "flasks"],"HELPFUL",false,threshold) then
   local id=tonumber(co[kind=="food" and "preferredFood" or "preferredFlask"]); local count=id and GetItemCount(id) or 0
   if count==0 then for _,candidate in ipairs(ns[kind=="food" and "foodItems" or "flaskItems"]) do if GetItemCount(candidate)>0 then id=candidate; count=GetItemCount(id); break end end end
   if co.showWithoutItem or count>0 then local name,icon; if id then local n,_,_,_,_,_,_,_,_,t=GetItemInfo(id); name,icon=n,t end; Add("consume:"..kind,name or (kind=="food" and "Food" or "Flask"),icon or "Interface\\Icons\\INV_Misc_QuestionMark",count,"player",nil,count>0 and id or nil,"consumables",count>0 and "Missing or expiring "..kind or "Restock "..kind) end
  end end
  local mh,mt,_,oh,ot=GetWeaponEnchantInfo()
  for _,hand in ipairs({{key="mainhand",slot=16,has=mh,time=mt},{key="offhand",slot=17,has=oh,time=ot}}) do
   local link=GetInventoryItemLink("player",hand.slot)
   -- An equipped offhand shield/frill is not a weapon to poison or imbue.
   local weapon=false; if link then local _,_,_,_,_,_,_,_,equipLoc=GetItemInfo(link); weapon=equipLoc=="INVTYPE_WEAPON" or equipLoc=="INVTYPE_WEAPONMAINHAND" or equipLoc=="INVTYPE_WEAPONOFFHAND" or equipLoc=="INVTYPE_2HWEAPON" end
   if co[hand.key] and weapon and (not hand.has or not InCombatLockdown() and (hand.time or 0)<=threshold*1000) then
    local spell=class=="SHAMAN" and (ns.Known(51730) or ns.Known(8024) or ns.Known(8232))
    Add("consume:"..hand.key,hand.key=="mainhand" and "Main Hand Enchant" or "Off Hand Enchant",GetInventoryItemTexture("player",hand.slot),1,"player",spell,nil,"consumables","Weapon enchant missing or expiring")
   end
  end
 end
 for i,entry in ipairs(p.customReminders) do if entry.enabled~=false and UnitExists(entry.unit or "player") and ns.Where(entry.where or "always") then
  local id=tonumber(entry.spellID); local name,_,icon=id and GetSpellInfo(id)
  if id then name,_,icon=GetSpellInfo(id) end
  if name and not ns.Present(entry.unit or "player",{id},entry.filter or "HELPFUL",entry.ownOnly,tonumber(entry.showUnder) or threshold) then
   Add("custom:"..i,entry.label or name,icon,1,entry.unit,ns.Known(tonumber(entry.castSpellID) or id),nil,"auras","Custom missing aura reminder")
  end
 end end
 for i,entry in ipairs(p.talentReminders) do if entry.enabled~=false then
  local zone=GetRealZoneText and GetRealZoneText() or ""; local location=entry.zone or ""
  local id=tonumber(entry.spellID); local name,_,icon
  if id then name,_,icon=GetSpellInfo(id) end
  if name and (location=="" or location==zone) and not ns.Known(id) then Add("talent:"..i,"Talent: "..name,icon,1,"player",nil,nil,"auras","Expected spell is not learned in this talent group") end
 end end
end
function ns.Refresh()
 if not ns.Profile() or not ns.frame then return end
 ns.Collect(); ns.Draw()
 if not InCombatLockdown() then ns.UpdateActions() else ns.pending=true end
 local current={}; local played={}
 if ns.preview then return end
 for _,reminder in ipairs(ns.missing) do current[reminder.key]=true; local sound=ns.Profile()[reminder.section].sound
  if ns.frame:IsShown() and ns.primed and not ns.previous[reminder.key] and sound and sound~="none" and ns.sounds[sound] and not played[sound] then
   PlaySoundFile("Interface\\AddOns\\"..ADDON.."\\Sounds\\"..sound..".ogg"); played[sound]=true
  end
 end
 ns.previous=current; ns.primed=true
end
function ns.Apply() ns.ScanSpells(); if ns.frame then ns.Layout(); ns.Refresh() end end
function ns.addon:OnInitialize() ns.addon.db=E.Lite.NewDB("EllesmereUIAuraBuffRemindersDB",ns.defaults); ns.db=ns.addon.db end
function ns.addon:OnEnable()
 if not InCombatLockdown() then ns.CreateDisplay() else ns.pending=true end
 ns.ScanSpells()
 for _,event in ipairs({"PLAYER_ENTERING_WORLD","UNIT_AURA","RAID_ROSTER_UPDATE","PARTY_MEMBERS_CHANGED","SPELLS_CHANGED","ACTIVE_TALENT_GROUP_CHANGED","PLAYER_TALENT_UPDATE","UNIT_PET","UNIT_INVENTORY_CHANGED","BAG_UPDATE","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","ZONE_CHANGED_NEW_AREA","PLAYER_ALIVE","PLAYER_UNGHOST"}) do ns.events:RegisterEvent(event) end
 ns.events:SetScript("OnEvent",function(_,event)
  if not ns.frame and not InCombatLockdown() then ns.CreateDisplay(); ns.Layout() end
  if event=="PLAYER_ENTERING_WORLD" then ns.dismissed={}; ns.primed=false end
  if event=="SPELLS_CHANGED" or event=="ACTIVE_TALENT_GROUP_CHANGED" or event=="PLAYER_TALENT_UPDATE" then ns.ScanSpells() end
  ns.Refresh()
 end)
 local elapsed=0; ns.events:SetScript("OnUpdate",function(_,dt) elapsed=elapsed+dt; if elapsed>=.5 then elapsed=0; ns.Refresh() end end)
 if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener(ADDON,function(active) ns.unlockPreview=active; ns.preview=active or ns.optionsPreview; ns.Refresh() end) end
 ns.Apply()
end
_EABR_RequestRefresh=ns.Apply; _EABR_ApplyAllIconBorders=ns.Apply; _EABR_ApplyUnlockPos=ns.Apply
E.GetAuraBuffGrowDir=function() return ns.Profile().display.growDirection end
E.SetAuraBuffGrowDir=function(v) ns.Profile().display.growDirection=v; ns.Apply() end
SLASH_EABR1="/eabr"; SLASH_EABR2="/ebr"
SlashCmdList.EABR=function() if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; if E.ShowModule then E:ShowModule(ADDON) end end
