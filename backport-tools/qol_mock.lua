-- Native contracts used by QoL: no C_* namespaces, C_Timer, atlas or masks.
local m=getmetatable(UIParent).__index
function m:EnableMouse(v) self.mouse=v end
function m:IsMouseEnabled() return self.mouse or false end
function m:IsMovable() return self.movable or false end
function m:HookScript(event,fn) local old=self.hooks[event]; self.hooks[event]=function(...) if old then old(...) end; fn(...) end end
function m:GetCenter() return self.centerX or 450,self.centerY or 350 end
function m:SetFrameStrata(v) self.strata=v end
function m:SetVertexColor(...) self.vertexColor={...} end
function m:SetTextColor(...) self.textColor={...} end
function m:IsProtected() return self.protected or false end
function m:Enable() self.enabled=true end
function m:Disable() self.enabled=false end
function m:IsEnabled() return self.enabled and 1 or nil end
function m:SetScale(v) self.scale=v end
function m:SetJustifyH(v) self.justifyH=v end
function m:RegisterForClicks(...) self.clicks={...} end
function m:SetFrameLevel(v) self.level=v end
-- Native 3.3.5 globals used by the QoL extras (bindings, sounds, chat, auras).
overrideBindings={}
function SetOverrideBindingClick(owner,_,key,button) overrideBindings[#overrideBindings+1]={owner,key,button} end
function ClearOverrideBindings(owner) for i=#overrideBindings,1,-1 do if overrideBindings[i][1]==owner then table.remove(overrideBindings,i) end end end
function UnregisterStateDriver(f,attribute) if f.drivers then f.drivers[attribute]=nil end end
SecureStateDriverManager={events={},RegisterEvent=function(self,e) self.events[e]=true end}
mouselook=false
function MouselookStart() mouselook=true end
function MouselookStop() mouselook=false end
sounds={}; function PlaySoundFile(path,channel) sounds[#sounds+1]={path,channel} end
chatSent={}; function SendChatMessage(text,channel) chatSent[#chatSent+1]={text,channel} end
cancelled={}; function CancelUnitBuff(unit,index,filter) cancelled[#cancelled+1]={unit,index,filter} end
local originalCreate=CreateFrame
function CreateFrame(kind,name,parent,template) assert(not combat,'QoL created frames in combat'); return originalCreate(kind,name,parent,template) end
for _,key in ipairs({'SetPoint','ClearAllPoints','SetMovable','EnableMouse','StartMoving','StopMovingOrSizing'}) do
    local before=m[key]; m[key]=function(self,...) assert(not combat or not self:IsProtected(),'Protected frame changed in combat'); return before(self,...) end
end
function RegisterStateDriver(f,attribute,driver)
    assert(not combat); f.drivers=f.drivers or {}; f.drivers[attribute]=driver
    if attribute=='visibility' then if driver=='hide' then f:Hide() else f:Show() end end
end
cvars={autoLootDefault='1',showTutorials='1'}
function GetCVar(key) return cvars[key] end
function SetCVar(key,value) cvars[key]=tostring(value) end
playerClass='DRUID'
inside,instanceKind=false,'none'
function IsInInstance() return inside,instanceKind end
logging,logCalls=false,{}
function LoggingCombat(value) if value~=nil then logging=value; logCalls[#logCalls+1]=value end; return logging end
function GetMoney() return 10000 end
guildLimit,guildFunds=1000,5000
function GetRepairAllCost() return 1500,true end
function CanMerchantRepair() return true end
function CanGuildBankRepair() return true end
function GetGuildBankWithdrawMoney() return guildLimit end
function GetGuildBankMoney() return guildFunds end
repairs={}
function RepairAllItems(guild) repairs[#repairs+1]=guild end
bagSlots={[0]=7}; items={
    ['0:1']={link='junk',quality=0,price=25,count=2},['0:2']={link='epic',quality=4,price=100},
    ['0:3']={link='locked',quality=0,price=50,locked=true},['0:4']={link='quest',quality=0,price=25,quest=true},
    ['0:5']={link='free',quality=0,price=0},['0:6']={link='uncached',quality=0,price=25,uncached=true},
    ['0:7']={link='lootable',quality=0,price=25,lootable=true}}
function GetItemInfo(link) for _,i in pairs(items) do if i.link==link then if i.uncached then return end; return link,link,i.quality,1,1,'Misc','Junk',20,'','icon',i.price end end end
function GetContainerItemInfo(bag,slot) local i=items[bag..':'..slot]; if i then return 'icon',i.count or 1,i.locked,i.quality,false,i.lootable,i.link end end
function GetContainerItemQuestInfo(bag,slot) local i=items[bag..':'..slot]; return i and i.quest,nil end
sales={}; cursorHeld=false
function GetCursorInfo() if cursorHeld then return 'spell',42 end end
function UseContainerItem(bag,slot) sales[#sales+1]={bag,slot} end
autoLootToggle=false
function IsModifiedClick() return autoLootToggle end
loot={}
function GetNumLootItems() return 3 end
function LootSlot(index) loot[#loot+1]=index end
ClassTrainerFrame=CreateFrame('Frame','ClassTrainerFrame',UIParent); ClassTrainerFrame:Hide()
CharacterFrame=CreateFrame('Frame','CharacterFrame',UIParent); CharacterFrame:SetPoint('TOPLEFT',UIParent,'TOPLEFT',25,-25); CharacterFrame.protected=true
TrainerServices={{name='Spell A',rank='Rank 1',kind='available',cost=100},{name='Spell B',rank='Rank 1',kind='unavailable',cost=100}}
function GetNumTrainerServices() return #TrainerServices end
function GetTrainerServiceInfo(i) local s=TrainerServices[i]; return s.name,s.rank,s.kind end
function GetTrainerServiceCost(i) return TrainerServices[i].cost end
trained={}; function BuyTrainerService(i) trained[#trained+1]=i end
UIErrorsFrame=CreateFrame('Frame',nil,UIParent); errorEvents={}
UIErrorsFrame:SetScript('OnEvent',function(_,event,message) errorEvents[#errorEvents+1]={event,message} end)
TutorialFrame=CreateFrame('Frame',nil,UIParent)
StaticPopup1=CreateFrame('Frame','StaticPopup1',UIParent); StaticPopup1:Hide(); StaticPopup1.editBox=CreateFrame('EditBox',nil,StaticPopup1); StaticPopup1.editBox:SetFont('native',12,'')
DELETE_ITEM_CONFIRM_STRING='DELETE'
function CinematicFrame_CancelCinematic() cinematicSkipped=true end
function GetFramerate() return 144 end
function GetNetStats() return 0,0,45,80 end
function GetCritChance() return 12 end
function GetRangedCritChance() return 13 end
function GetSpellCritChance(i) return i==3 and 14 or 10 end
CR_HASTE_MELEE,CR_HASTE_RANGED,CR_HASTE_SPELL=1,2,3
function GetCombatRatingBonus(i) return i==3 and 15 or 9 end
WorldMapFrame=CreateFrame('Frame',nil,UIParent); WorldMapFrame:Hide()
mapReads,mapSets=0,0
function SetMapToCurrentZone() mapSets=mapSets+1 end
function GetPlayerMapPosition() mapReads=mapReads+1; return .25,.75 end
durability=30
function GetInventoryItemDurability(i) if i==1 then return durability,100 end end
groupDead=false
function GetNumPartyMembers() return 1 end
function UnitGUID(unit) return 'guid-'..unit end
function UnitIsDeadOrGhost(unit) return unit=='party1' and groupDead end
function UnitIsUnit(a,b) return a==b end
playerAuras={}
function UnitAura(unit,index) local a=playerAuras[index]; if a then return a.name,nil,'aura-icon',1,nil,a.duration,a.expires,'player',false,false,a.id end end
known={[20484]=true,[1850]=true,[1953]=false}
function GetSpellInfo(id) return 'Spell '..id,'Rank 1','spell-icon-'..id end
function IsSpellKnown(id) return known[id] end
spellCooldowns={['Spell 20484']={1,600,1},['Spell 1850']={0,0,1},[61304]={0,0,1}}
function GetSpellCooldown(id) local c=spellCooldowns[id]; if c then return unpack(c) end; return 0,0,1 end
cursorX,cursorY=200,300
function GetCursorPosition() return cursorX,cursorY end
mouselook=false
function IsMouselooking() return mouselook end
function UnitAffectingCombat() return combat end
shift,ctrl,mouseDown=false,false,false
function IsShiftKeyDown() return shift end
function IsControlKeyDown() return ctrl end
function IsMouseButtonDown() return mouseDown end
function SetRaidTargetIconTexture(texture,index) texture.marker=index end
leader=false
function UnitIsPartyLeader() return leader end
function UnitIsRaidOfficer() return false end
function DoReadyCheck() readyChecks=(readyChecks or 0)+1 end
