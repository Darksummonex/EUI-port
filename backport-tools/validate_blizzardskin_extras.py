"""Ported Retail BlizzardSkin extras on Wrath 3.3.5a: tooltip info/placement/visibility,
paper doll enchants/gems/durability/eye/model/stats/better items, socket strip, inspect,
merchant list mode, resurrect glow, queue countdown and the server's Collections windows.
Rendering still needs in-game review."""
from pathlib import Path
import re
import struct
import sys
root=Path(__file__).resolve().parents[1]
skin=root/'EllesmereUIBlizzardSkin'
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime

toc=(skin/'EllesmereUIBlizzardSkin.toc').read_text(encoding='utf-8-sig')
files=[line.strip() for line in toc.splitlines() if line.strip().endswith('.lua') and not line.startswith('#')]
order=['EUI_BlizzardSkin_335.lua','EUI_Items_335.lua','EUI_CharacterSheet_335.lua','EUI_SocketPanel_335.lua',
       'EUI_Tooltips_335.lua','EUI_Inspect_335.lua','EUI_Merchant_335.lua','EUI_Popups_335.lua']
assert files[:len(order)]==order,files
for name in order:
    source=re.sub(r'--[^\n]*','',(skin/name).read_text(encoding='utf-8-sig'))
    for banned in ['C_Timer','C_Item','GET_ITEM_INFO_RECEIVED','SetRotatesTexture','INSPECT_READY"','.png"']:
        assert banned not in source,(name,banned)
tga=(skin/'Media'/'character-bg.tga').read_bytes()
width,height=struct.unpack('<HH',tga[12:16])
assert tga[2] in (2,10) and (width,height)==(512,1024),(tga[2],width,height)
assert 'character-bg.tga' in (skin/'EUI_CharacterSheet_335.lua').read_text(encoding='utf-8-sig')

lua=LuaRuntime()
for name in ['backport-tools/wrath_mock.lua','backport-tools/blizzardskin_mock.lua','backport-tools/character_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/name).read_text(encoding='utf-8-sig'))
lua.execute(r'''
CreateCharacterFixture(); EllesmereUIDB={}; lifecycleErrors={}
function geterrorhandler() return function(e) lifecycleErrors[#lifecycleErrors+1]=e end end
UIParent:SetWidth(1920); UIParent:SetHeight(1080)
local m=getmetatable(UIParent).__index
function m:SetStatusBarTexture(v) self.barTexture=v end
function m:SetStatusBarColor(...) self.barColor={...} end
function m:SetFrameStrata(v) self.strata=v end
function m:SetScale(v) self.scale=v end
function m:GetScale() return self.scale or 1 end
-- Tooltip scanners: lines per hyperlink, inventory slot or bag slot.
scanLines={}
local baseCreate=CreateFrame
function CreateFrame(kind,name,parent,template)
    local f=baseCreate(kind,name,parent,template)
    if kind=='GameTooltip' and name then
        f.kind='GameTooltip'
        for i=1,30 do _G[name..'TextLeft'..i]=f:CreateFontString() end
        local function Fill(lines)
            for i=1,30 do local fs=_G[name..'TextLeft'..i]; fs.text=nil; fs.textColor=nil end
            f.count=#lines
            for i,l in ipairs(lines) do local fs=_G[name..'TextLeft'..i]; fs:SetText(l[1]); fs:SetTextColor(l[2] or 1,l[3] or 1,l[4] or 1) end
        end
        f.SetOwner=function() end; f.ClearLines=function() Fill({}) end; f.NumLines=function() return f.count or 0 end
        f.SetHyperlink=function(_,link) Fill(scanLines[link] or {{'Item'}}) end
        f.SetInventoryItem=function(_,unit,slot) Fill(scanLines[unit..slot] or {{'Item'}}) end
        f.SetBagItem=function(_,bag,slot) Fill(scanLines['bag'..bag..':'..slot] or {{'Item'}}) end
    end
    return f
end
-- Server GameTooltip with lines, unit, status bar and default anchor.
for i=1,12 do _G['GameTooltipTextLeft'..i]=GameTooltip:CreateFontString() end
tipUnit=nil
function GameTooltip:GetUnit() if tipUnit then return UnitName(tipUnit),tipUnit end end
function GameTooltip:NumLines() local n=0; for i=1,12 do local t=_G['GameTooltipTextLeft'..i].text; if t and t~='' then n=i end end; return n end
function GameTooltip:AddLine(text,r,g,b) local fs=_G['GameTooltipTextLeft'..(self:NumLines()+1)]; fs:SetText(text); fs:SetTextColor(r or 1,g or 1,b or 1) end
function GameTooltip:AddDoubleLine(l,_,r,g,b) self:AddLine(l,r,g,b) end
function GameTooltip:ClearLines() for i=1,12 do _G['GameTooltipTextLeft'..i].text=nil end end
function GameTooltip:SetText(text,r,g,b) self:ClearLines(); self:AddLine(text,r,g,b) end
function GameTooltip:SetOwner(owner) self.owner=owner end
function GameTooltip:SetHyperlink(link) self:ClearLines(); self:AddLine(link) end
GameTooltipStatusBar=CreateFrame('StatusBar','GameTooltipStatusBar',GameTooltip)
ShoppingTooltip1=NativeWindow('ShoppingTooltip1'); ShoppingTooltip1.kind='GameTooltip'
function GameTooltip_SetDefaultAnchor(tip,parent)
    tip:SetOwner(parent,'ANCHOR_NONE'); tip:ClearAllPoints(); tip:SetPoint('BOTTOMRIGHT',UIParent,'BOTTOMRIGHT',-13,70); tip.default=1
end
inspects={}; function NotifyInspect(unit) inspects[#inspects+1]=unit end
function CanInspect() return true end
function CheckInteractDistance() return true end
cursorX,cursorY=300,200; function GetCursorPosition() return cursorX,cursorY end
shift=false; function IsShiftKeyDown() return shift end
function IsControlKeyDown() return false end; function IsAltKeyDown() return false end
fighting=false; function UnitAffectingCombat() return fighting end
cvars={}; function SetCVar(k,v) cvars[k]=v end
RAID_CLASS_COLORS={DEATHKNIGHT={r=.77,g=.12,b=.23},WARRIOR={r=.78,g=.61,b=.43},MAGE={r=.41,g=.8,b=.94}}
-- Units: a hovered death knight, an inspect target and the player.
units={mouseover={name='Arthas',class='DEATHKNIGHT',guid='G-Arthas',guild='Knights of the Ebon Blade',rank='Officer',title='Kingslayer Arthas'},
    target={name='Jaina',class='MAGE',guid='G-Jaina'}}
local realName,realClass,realGUID,realPlayer,realUnit=UnitName,UnitClass,UnitGUID,UnitIsPlayer,UnitIsUnit
function UnitName(u) local d=units[u]; if d then return d.name end; return realName(u) end
function UnitClass(u) local d=units[u]; if d then return d.class,d.class end; return realClass(u) end
function UnitGUID(u) local d=units[u]; if d then return d.guid end; return u=='player' and 'G-Player' or nil end
function UnitIsPlayer(u) return units[u]~=nil or realPlayer(u) end
function UnitExists(u)
    if u=='mouseovertarget' then return mouseoverTarget~=nil end
    if u=='boss1' then return bossUp and true or false end
    return units[u]~=nil or u=='player'
end
function UnitIsUnit(a,b) if a=='mouseovertarget' and b=='player' then return mouseoverTarget=='player' end; return realUnit(a,b) end
function UnitPVPName(u) local d=units[u]; return d and d.title end
function GetGuildInfo(u) local d=units[u]; if d and d.guild then return d.guild,d.rank,1 end end
function UnitAura(u,i,filter) if u=='mouseover' and filter=='HELPFUL' and i==1 then return 'Invincible',nil,'aura-icon',0,nil,0,0,'mouseover',false,false,72286 end end
mountCollected=true
C_MountJournal={GetMountIDs=function() return {363} end,
    GetMountInfoByID=function() return 'Invincible',72286,'mount-icon',false,true,0,false,false,nil,false,mountCollected end}
-- Gear: an enchanted head with one socketed gem and one empty red socket.
EMPTY_SOCKET_RED='Red Socket'; EMPTY_SOCKET_META='Meta Socket'; ITEM_MOD_STRENGTH_SHORT='Strength'; DURABILITY='Durability'
headLink='item:1:3817:3520:0:0:0:0:0'
enchantText='+50 Attack Power and +20 Critical Strike Rating'
scanLines[headLink]={{'Helm'},{enchantText,0,1,0}}
scanLines['item:1:0:3520:0:0:0:0:0']={{'Helm'}}
scanLines['item:1:3817:0:0:0:0:0:0']={{'Helm'},{enchantText,0,1,0}}
scanLines['item:1:0:0:0:0:0:0:0']={{'Helm'}}
scanLines['player1']={{'Helm'},{'Red Socket'}}
local baseLink=GetInventoryItemLink
function GetInventoryItemLink(unit,id)
    if id==1 and unit=='player' then return headLink end
    if id==1 and unit=='target' then return 'item:1:3817:0:0:0:0:0:0' end
    return baseLink(unit,id)
end
function GetItemGem(link,i) if link==headLink and i==1 then return 'Bold Ruby','item:40111' end end
local baseInfo=GetItemInfo
function GetItemInfo(link)
    local id=tonumber(tostring(link):match('item:(%d+)'))
    if id==40111 or id==40112 then return id==40111 and 'Bold Ruby' or 'Bold Cardinal Ruby',link,id==40111 and 3 or 4,80,0,'Gem','Red',20,'','gem-icon' end
    if id==40113 then return 'Relentless Earthsiege Diamond',link,3,80,0,'Gem','Meta',20,'','meta-icon' end
    if id==50 then return 'Better Helm',link,4,264,80,'Armor','Plate',1,'INVTYPE_HEAD','helm-icon' end
    return baseInfo(link)
end
function GetInventoryItemDurability(slot) if slot==1 then return 30,100 elseif slot==5 then return 90,100 end end
NUM_BAG_SLOTS=0
bagItems={'item:50','item:40112','item:40113'}
function GetContainerNumSlots(bag) return bag==0 and #bagItems or 0 end
function GetContainerItemLink(bag,i) return bag==0 and bagItems[i] or nil end
function GetContainerItemInfo(_,i) return 'icon',i==2 and 3 or 1 end
function GetItemStats(link) if link:find('40112',1,true) then return {ITEM_MOD_STRENGTH_SHORT=20} end; return {} end
scanLines['bag0:1']={{'Better Helm'},{'Plate'}}
socketLog={}
function SocketInventoryItem(slot) socketLog[#socketLog+1]='open'..slot end
function PickupContainerItem(bag,i) socketLog[#socketLog+1]='pick'..bag..':'..i end
function ClickSocketButton(i) socketLog[#socketLog+1]='socket'..i end
function AcceptSockets() socketLog[#socketLog+1]='accept' end
function CloseSocketInfo() socketLog[#socketLog+1]='close' end
cursorItem=false; function CursorHasItem() return cursorItem end; function ClearCursor() cursorItem=false end
StaticPopupDialogs={}
UIErrorsFrame={AddMessage=function(_,msg) uiError=msg end}
StaticPopup1.button1=NativeButton('StaticPopup1Button1',StaticPopup1); StaticPopup1:Hide()
function StaticPopup_Show(which)
    if which=='EUI335_REPLACE_GEM' then lastDialog={}; return lastDialog end
    StaticPopup1:Hide(); StaticPopup1.which=which; StaticPopup1:Show(); return StaticPopup1
end
-- Server windows: Collections/Wardrobe and the Dungeon Finder popups.
CollectionsJournal=NativeWindow('CollectionsJournal'); WardrobeFrame=NativeWindow('WardrobeFrame')
LFDRoleCheckPopup=NativeWindow('LFDRoleCheckPopup'); LFDDungeonReadyStatus=NativeWindow('LFDDungeonReadyStatus')
-- Wrath merchant: 2x5 grid, buyback-only rows 11-12 and the buyback button.
for i=1,12 do
    local row=CreateFrame('Frame','MerchantItem'..i,MerchantFrame); row:SetSize(153,44)
    if i==1 then row:SetPoint('TOPLEFT',MerchantFrame,'TOPLEFT',24,-80)
    elseif i%2==0 then row:SetPoint('TOPLEFT','MerchantItem'..(i-1),'TOPRIGHT',12,0)
    else row:SetPoint('TOPLEFT','MerchantItem'..(i-2),'BOTTOMLEFT',0,-8) end
    local b=CreateFrame('Button','MerchantItem'..i..'ItemButton',row); b:SetSize(37,37); b:SetPoint('TOPLEFT',row,'TOPLEFT',0,0)
    local name=row:CreateFontString('MerchantItem'..i..'Name'); name:SetPoint('LEFT',b,'RIGHT',5,0); name:SetSize(100,30)
    _G['MerchantItem'..i..'SlotTexture']=row:CreateTexture(); _G['MerchantItem'..i..'NameFrame']=row:CreateTexture()
    local money=CreateFrame('Frame','MerchantItem'..i..'MoneyFrame',row); money:SetPoint('BOTTOMLEFT',b,'BOTTOMRIGHT',3,0)
end
MerchantBuyBackItem=CreateFrame('Frame','MerchantBuyBackItem',MerchantFrame); MerchantBuyBackItem:SetPoint('TOPLEFT',MerchantItem10,'BOTTOMLEFT',0,-53)
merchantMode='merchant'
function MerchantFrame_UpdateMerchantInfo()
    merchantMode='merchant'
    for i=1,10 do local b=_G['MerchantItem'..i..'ItemButton']; b.hasItem=true; b.link='item:'..i end
    for i=3,9,2 do _G['MerchantItem'..i]:SetPoint('TOPLEFT','MerchantItem'..(i-2),'BOTTOMLEFT',0,-8) end
end
function MerchantFrame_UpdateBuybackInfo()
    merchantMode='buyback'
    for i=3,9,2 do _G['MerchantItem'..i]:SetPoint('TOPLEFT','MerchantItem'..(i-2),'BOTTOMLEFT',0,-15) end
end
function MerchantFrame_Update() if merchantMode=='buyback' then MerchantFrame_UpdateBuybackInfo() else MerchantFrame_UpdateMerchantInfo() end end
function UpdateUIPanelPositions() end
function EllesmereUI.MakeUnlockElement(t) return t end
function EllesmereUI:RegisterUnlockElements(list) unlockElements=list end
''')
loader=lua.eval('function(s,n) return assert(loadstring(s,n)) end')
ns=lua.table()
for name in order:
    loader((skin/name).read_text(encoding='utf-8-sig'),name)('EllesmereUIBlizzardSkin',ns)
lua.globals().BS=ns
lua.execute(r'''
BS.addon:OnInitialize(); BS.addon:OnEnable()
assert(not next(lifecycleErrors),lifecycleErrors[1])
assert(#BS.extras==4,'extras registry')
-- Server Collections/Wardrobe and Dungeon Finder popups use the window skin.
assert(BS.states[CollectionsJournal] and BS.states[CollectionsJournal].active,'Collections not skinned')
assert(BS.states[WardrobeFrame].active and BS.states[LFDRoleCheckPopup].active and BS.states[LFDDungeonReadyStatus].active)
BS.SetValue('reskinCollections',false); assert(not BS.states[CollectionsJournal].active and CollectionsJournal.art:GetAlpha()==.8)
BS.SetValue('reskinCollections',true); assert(BS.states[CollectionsJournal].active)

-- Tooltip information.
local function L(i) return _G['GameTooltipTextLeft'..i] end
local function Find(prefix) for i=1,GameTooltip:NumLines() do local t=L(i):GetText(); if t and t:find(prefix,1,true)==1 then return t end end end
local function Hover(unit,lines) GameTooltip:ClearLines(); for _,t in ipairs(lines) do GameTooltip:AddLine(t) end; tipUnit=unit; GameTooltip:RunScript('OnTooltipSetUnit') end
local arthas={'Kingslayer Arthas','Knights of the Ebon Blade','Level 80 Human Death Knight'}
Hover('mouseover',arthas)
assert(L(1):GetText()=='Arthas' and L(1).textColor[1]==.77,'title not stripped / not class coloured')
assert(L(2):GetText()=='Knights of the Ebon Blade' and not Find('Mount:') and not Find('Targeting:'),'Retail-off info shown by default')
BS.SetValue('tooltipShowGuildRank',true); BS.SetValue('tooltipShowTarget',true); BS.SetValue('tooltipShowMount',true)
mouseoverTarget='player'
Hover('mouseover',arthas)
assert(L(2):GetText():find('Officer',1,true),'guild rank')
assert(Find('Mount:'):find('Invincible',1,true) and Find('Mount:'):find('(Collected)',1,true),'mount line')
assert(Find('Targeting:'):find('YOU',1,true),'target line')
assert(not Find('Item Level:') and #inspects==0,'remote item level before inspect')
now=now+.1; BS.Tooltips.events:RunScript('OnUpdate'); assert(#inspects==0,'inspect before hover rest')
now=now+2; BS.Tooltips.events:RunScript('OnUpdate'); assert(inspects[1]=='mouseover','paced inspect not sent')
BS.Tooltips.events:RunScript('OnUpdate'); assert(#inspects==1,'inspect repeated')
BS.Tooltips.events:RunScript('OnEvent','INSPECT_TALENT_READY')
assert(Find('Item Level:') and Find('Item Level:'):find('209.8',1,true),'inspect item level')
local gs=Find('GearScore:'); assert(gs and tonumber(gs:match('|c%x%x%x%x%x%x%x%x(%d+)|r'))==BS.GearScore('mouseover') and BS.GearScore('mouseover')>0,'inspect GearScore')
Hover('mouseover',arthas); assert(Find('Item Level:'):find('209.8',1,true) and Find('GearScore:')==gs and #inspects==1,'cached item level/GearScore')
GearScore_HookSetUnit=function() end; GS_Settings={Player=1}
Hover('mouseover',arthas); assert(not Find('GearScore:') and Find('Item Level:'),'duplicated GearScoreLite line')
GS_Settings.Player=-1; Hover('mouseover',arthas); assert(Find('GearScore:'),'GearScoreLite line off but ours hidden')
GearScore_HookSetUnit,GS_Settings=nil,nil
BS.SetValue('tooltipShowGearScore',false); Hover('mouseover',arthas); assert(not Find('GearScore:')); BS.SetValue('tooltipShowGearScore',true)
mountCollected=false; Hover('mouseover',arthas); assert(Find('Mount:'):find('Not collected',1,true)); mountCollected=true
BS.SetValue('tooltipPlayerTitles',true); Hover('mouseover',arthas); assert(L(1):GetText()=='Kingslayer Arthas'); BS.SetValue('tooltipPlayerTitles',false)
Hover('player',{'Me'}); assert(Find('Item Level:') and Find('GearScore:'),'own item level/GearScore'); assert(not Find('Targeting:'))
tipUnit='mouseover'; GameTooltipStatusBar:RunScript('OnValueChanged',50); assert(GameTooltipStatusBar.barColor[1]==.77,'class health bar')
assert(GameTooltipStatusBar:GetAlpha()==0); BS.SetValue('tooltipHideHealthStrip',false); assert(GameTooltipStatusBar:GetAlpha()==1)
BS.SetValue('tooltipHideHealthStrip',true)
-- Visibility modes keep the tooltip shown inside a hidden host.
BS.SetValue('tooltipShowMode','outOfCombat'); assert(GameTooltip:GetParent()==UIParent)
fighting=true; BS.Tooltips.events:RunScript('OnEvent','PLAYER_REGEN_DISABLED')
assert(GameTooltip:GetParent()~=UIParent and not GameTooltip:GetParent():IsShown() and ShoppingTooltip1:GetParent()==GameTooltip:GetParent())
BS.SetValue('tooltipShowModifier','shift'); shift=true; BS.Tooltips.events:RunScript('OnEvent','MODIFIER_STATE_CHANGED')
assert(GameTooltip:GetParent()==UIParent and GameTooltip.strata=='TOOLTIP','peek modifier')
shift=false; BS.Tooltips.events:RunScript('OnEvent','MODIFIER_STATE_CHANGED'); assert(GameTooltip:GetParent()~=UIParent)
BS.SetValue('tooltipShowMode','outOfBossCombat'); assert(GameTooltip:GetParent()==UIParent,'boss mode hid trash fights')
bossUp=true; BS.Tooltips.events:RunScript('OnEvent','INSTANCE_ENCOUNTER_ENGAGE_UNIT'); assert(GameTooltip:GetParent()~=UIParent)
fighting,bossUp=false,false; BS.Tooltips.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(GameTooltip:GetParent()==UIParent and ShoppingTooltip1:GetParent()==UIParent)
BS.SetValue('tooltipShowMode','never'); assert(GameTooltip:GetParent()~=UIParent)
BS.SetValue('tooltipShowMode','always'); BS.SetValue('tooltipShowModifier','none'); assert(GameTooltip:GetParent()==UIParent)
-- Placement: cursor anchor follows and drops stale unit tooltips; fixed anchor only once moved.
GameTooltip_SetDefaultAnchor(GameTooltip,UIParent); assert(GameTooltip.point[1]=='BOTTOMRIGHT' and GameTooltip.point[2]==UIParent,'native anchor replaced')
BS.SetValue('tooltipAnchorCursor',true); BS.SetValue('tooltipCursorOffsetX',10)
GameTooltip_SetDefaultAnchor(GameTooltip,UIParent)
assert(GameTooltip.point[1]=='BOTTOM' and GameTooltip.point[3]=='BOTTOMLEFT' and GameTooltip.point[4]==310 and GameTooltip.point[5]==200)
cursorX=400; GameTooltip:RunScript('OnUpdate'); assert(GameTooltip.point[4]==410,'cursor tooltip did not follow')
BS.SetValue('tooltipCursorPosition','right'); GameTooltip:RunScript('OnUpdate'); assert(GameTooltip.point[1]=='LEFT')
local saved=units.mouseover; units.mouseover=nil; tipUnit='mouseover'; GameTooltip:RunScript('OnUpdate')
assert(not GameTooltip:IsShown(),'stale cursor unit tooltip stayed'); units.mouseover=saved; GameTooltip:Show()
BS.SetValue('tooltipAnchorCursor',false); BS.SetValue('tooltipGrowthDirection','down')
assert(unlockElements and unlockElements[1].key=='EBS_TooltipAnchor','tooltip unlock element')
unlockElements[1].savePos(nil,'TOPLEFT','TOPLEFT',50,-60); unlockElements[1].applyPos()
assert(EUI335TooltipFixedAnchor.point[1]=='TOPLEFT' and EUI335TooltipFixedAnchor.point[4]==50)
GameTooltip_SetDefaultAnchor(GameTooltip,UIParent)
assert(GameTooltip.point[2]==EUI335TooltipFixedAnchor and GameTooltip.point[1]=='TOPLEFT','fixed anchor/growth')
BS.SetValue('tooltipGrowthDirection','up'); GameTooltip_SetDefaultAnchor(GameTooltip,UIParent); assert(GameTooltip.point[1]=='BOTTOMLEFT')
unlockElements[1].clearPos(); GameTooltip_SetDefaultAnchor(GameTooltip,UIParent); assert(GameTooltip.point[2]==UIParent)
assert(cvars.UberTooltips==nil,'UberTooltips touched while unmanaged')
BS.SetValue('uberTooltipsManual',true); BS.SetValue('uberTooltips',false); assert(cvars.UberTooltips=='0')
BS.SetValue('uberTooltipsManual',false)

-- Character slots: enchant badge or name, gems, missing socket, durability, eye, model, backdrop.
local c=BS.states[CharacterFrame].character
assert(c.enhanced)
local function Badge(slot,fn) for _,b in ipairs(c.flags[slot] or {}) do if b:IsShown() and fn(b) then return b end end end
assert(Badge('Head',function(b) return b.tip==enchantText and b.tipColor[2]==1 end),'enchant badge')
assert(Badge('Head',function(b) return b.link=='item:40111' end),'gem badge')
assert(Badge('Head',function(b) return b.tip=='Empty socket' end),'empty socket flag')
assert(not Badge('Head',function(b) return b.tip=='Missing enchant' end),'enchanted head flagged')
assert(c.itemLabels.Head.point[5]==7 and not c.enchantLabels.Head:IsShown())
BS.SetValue('charSheetEnchantNames',true)
assert(c.enchantLabels.Head:IsShown() and c.enchantLabels.Head:GetText()==enchantText,'enchant name')
assert(c.itemLabels.Head.point[5]==12 and c.enchantLabels.Head.point[2]==c.itemLabels.Head)
assert(not Badge('Head',function(b) return b.tip==enchantText end),'enchant shown twice')
BS.SetValue('charSheetEnchantSize',30); assert(c.enchantLabels.Head.font[2]==16)
BS.SetValue('showEnchants',false); assert(not c.enchantLabels.Head:IsShown()); BS.SetValue('showEnchants',true)
BS.SetValue('showGems',false); assert(not Badge('Head',function(b) return b.link end)); BS.SetValue('showGems',true)
assert(not c.durability:IsShown())
BS.SetValue('showCharSheetDurability',true)
assert(c.durability:IsShown() and c.durability:GetText():find('30%',1,true) and c.durability.point[2]==CharacterModelFrame,'durability')
BS.SetValue('charSheetDurabilityLocation','header'); assert(c.durability.point[2]==c.health)
BS.SetValue('charSheetDurabilityLocation','footer'); assert(c.durability.point[2]==c.sidebar)
BS.SetValue('charSheetDurabilityShowLabel',false); assert(not c.durability:GetText():find('Durability',1,true))
c.eye:RunScript('OnClick')
assert(not c.itemLabels.Head:IsShown() and not c.enchantLabels.Head:IsShown() and not Badge('Head',function() return true end),'eye')
assert(c.eye.tex.desaturated==true)
c.eye:RunScript('OnClick'); assert(c.itemLabels.Head:IsShown() and c.enchantLabels.Head:IsShown() and c.eye.tex.desaturated==false)
local model=CharacterModelFrame
function model:SetRotation(r) self.rot=r end
function model:GetPosition() return unpack(self.pos or {0,0,0}) end
function model:SetPosition(x,y,z) self.pos={x,y,z} end
cursorX,cursorY=100,100; model:RunScript('OnMouseDown','LeftButton'); cursorX=150; model:RunScript('OnUpdate')
assert(math.abs(model.rot-1)<1e-9,'drag rotate'); model:RunScript('OnMouseUp')
model:RunScript('OnMouseDown','RightButton'); cursorX=300; model:RunScript('OnUpdate'); assert(model.pos[2]==1,'drag pan')
model:RunScript('OnMouseUp'); model:RunScript('OnMouseWheel',1); assert(math.abs(model.pos[1]-.15)<1e-9,'wheel zoom')
assert(c.backdrop:IsShown() and c.backdrop:GetTexture():find('character%-bg%.tga$'),'character backdrop')

-- Stats sidebar: hide, reorder past hidden sections, colours, better items.
BS.SetValue('showStatCategory_Melee',false); assert(not c.sections[2].header:IsShown())
c.sections[3].up:RunScript('OnClick')
assert(c.sections[1].key=='Base' and c.sections[3].key=='Ranged','reorder changed the base section list')
assert(BS.GetSettings().statSectionsOrder[1]=='Ranged' and c.sections[3].header.point[5]==0 and c.sections[1].header.point[5]<0,'reorder')
assert(c.sections[3].up:GetAlpha()==.25)
BS.SetValue('showStatCategory_Melee',true); assert(c.sections[2].header:IsShown())
local db=BS.GetSettings(); db.statCategoryColors={Attributes={r=1,g=0,b=0}}; db.statCategoryUseColor={Attributes=true}; BS.Apply()
assert(c.sections[1].label.textColor[1]==1 and c.sections[1].label.textColor[2]==0,'stat colour')
db.statCategoryUseColor=nil; BS.Apply(); assert(c.sections[1].label.textColor[1]==.05)
assert(c.betterArrow:IsShown(),'better bag item not found')
GameTooltip:ClearLines(); c.better:RunScript('OnEnter'); assert(Find('Head: item:50'),'better items tooltip')
scanLines['bag0:1'][2]={'Requires Level 85',1,.1,.1}; c.betterAt=nil; BS.Apply(); assert(not c.betterArrow:IsShown(),'unusable item offered')
scanLines['bag0:1'][2]={'Plate'}; c.betterAt=nil; BS.Apply()

-- Socket strip, gem flyout and one-click socketing.
local strip=c.socketStrip
assert(strip and strip:IsShown() and c.scroll:GetHeight()==300,'socket strip')
local b1,b2=strip.buttons[1],strip.buttons[2]
assert(b1.entry.slot==1 and b1.entry.gemLink=='item:40111' and b2.entry.kind=='Red' and not strip.buttons[3]:IsShown(),
    'socket entries '..tostring(b1.entry and b1.entry.slot)..' '..tostring(b1.entry and b1.entry.gemLink)..' '..tostring(b2.entry and b2.entry.kind)..' '..tostring(strip.buttons[3].entry and strip.buttons[3].entry.slot))
b2:RunScript('OnClick'); local fly=BS.SocketPanel.flyout
assert(fly:IsShown() and fly.rows[1].gem.link=='item:40112' and fly.rows[1].stats:GetText()=='+20 Strength' and not fly.rows[2]:IsShown(),'gem flyout')
assert(fly.rows[1].name:GetText()=='3x Bold Cardinal Ruby')
fly.rows[1]:RunScript('OnClick'); BS.SocketPanel.OnSocketInfo(); now=now+.5; BS.SocketPanel.Tick()
assert(table.concat(socketLog,',')=='open1,pick0:2,socket2,accept,close',table.concat(socketLog,','))
socketLog={}; b1:RunScript('OnClick'); fly.rows[1]:RunScript('OnClick')
assert(#socketLog==0 and lastDialog and lastDialog.data,'replacing a gem skipped the confirmation')
StaticPopupDialogs.EUI335_REPLACE_GEM.OnAccept(lastDialog); assert(socketLog[1]=='open1')
now=now+6; BS.SocketPanel.Tick(); assert(uiError and socketLog[#socketLog]=='close','stuck socketing job')
BS.SetValue('charSheetSocketPanel',false); assert(not strip:IsShown() and c.scroll:GetHeight()==340)
BS.SetValue('charSheetSocketPanel',true); assert(strip:IsShown())
c.tabs.equipment:RunScript('OnClick'); assert(not strip:IsShown()); c.tabs.stats:RunScript('OnClick'); assert(strip:IsShown())

-- Inspect sheet: loads on demand, labels, average and docking.
InspectFrame=NativeWindow('InspectFrame'); InspectFrame:Hide(); InspectFrame.unit='target'
InspectPaperDollFrame=CreateFrame('Frame','InspectPaperDollFrame',InspectFrame)
InspectModelFrame=CreateFrame('PlayerModel','InspectModelFrame',InspectPaperDollFrame)
for _,slot in ipairs({'Head','Neck','Shoulder','Back','Chest','Shirt','Tabard','Wrist','Hands','Waist','Legs','Feet','Finger0','Finger1','Trinket0','Trinket1','MainHand','SecondaryHand','Ranged'}) do
    NativeButton('Inspect'..slot..'Slot',InspectPaperDollFrame)
end
BS.Inspect.events:RunScript('OnEvent','ADDON_LOADED','Blizzard_InspectUI')
InspectFrame:Show(); BS.Inspect.events:RunScript('OnUpdate')
local I=BS.Inspect
assert(tostring(I.labels.Head.level:GetText())=='201' and I.labels.Head.level:IsShown(),'inspect item level')
assert(not I.labels.Shirt.level:IsShown() and I.labels.Head.enchant:GetText()==enchantText and not I.labels.Neck.enchant:IsShown())
assert(I.average:GetText():find('209.8',1,true),'inspect average')
UpdateUIPanelPositions(); assert(InspectFrame.point[2]==CharacterFrame and InspectFrame.point[4]==-19,'inspect dock')
BS.SetValue('inspectShowEnchants',false); assert(not I.labels.Head.enchant:IsShown() and I.labels.Head.level:IsShown())
BS.SetValue('inspectShowItemLevel',false); assert(not I.labels.Head.level:IsShown() and not I.average:IsShown())
BS.SetValue('inspectShowItemLevel',true); BS.SetValue('inspectShowEnchants',true)

-- Merchant: list layout over the native rows, buyback restore, item levels.
MerchantFrame:Show(); MerchantFrame_UpdateMerchantInfo()
assert(MerchantItem2.point[2]=='MerchantItem1' and MerchantFrame:GetHeight()==512,'grid changed by default')
BS.SetValue('merchantShowAsList',true)
assert(MerchantItem2.point[2]==MerchantFrame and MerchantItem2.point[5]==-110 and MerchantItem2:GetWidth()==318,'list layout')
assert(MerchantFrame:GetHeight()==596 and MerchantBuyBackItem.point[1]=='TOPRIGHT' and MerchantItem1SlotTexture:GetAlpha()==0)
BS.SetValue('merchantShowItemLevel',true)
local mx=BS.Merchant.extras
assert(mx[2].listLevel:IsShown() and tostring(mx[2].listLevel:GetText())=='202' and not mx[2].level:IsShown(),'list item level')
MerchantFrame_UpdateBuybackInfo()
assert(MerchantFrame:GetHeight()==512 and MerchantItem2.point[2]=='MerchantItem1' and MerchantItem3.point[5]==-15,'buyback restore')
assert(MerchantBuyBackItem.point[1]=='TOPLEFT' and not mx[2].listLevel:IsShown() and not mx[2].level:IsShown())
MerchantFrame_UpdateMerchantInfo(); assert(MerchantItem2.point[2]==MerchantFrame)
BS.SetValue('merchantListRowHeight',40); assert(MerchantItem2.point[5]==-118 and MerchantItem2:GetHeight()==40)
BS.SetValue('merchantShowAsList',false)
assert(MerchantItem2.point[2]=='MerchantItem1' and MerchantItem3.point[5]==-8 and MerchantFrame:GetHeight()==512 and MerchantItem1SlotTexture:GetAlpha()==1,'grid restore')
assert(mx[2].level:IsShown() and tostring(mx[2].level:GetText())=='202' and not mx[2].bg:IsShown(),'grid item level')

-- Resurrect glow and Dungeon Finder countdown.
local function Glow() for _,ch in ipairs(StaticPopup1.button1.children) do if ch.backdrop and ch.backdrop.edgeSize==2 then return ch end end end
StaticPopup_Show('RESURRECT'); assert(not Glow() or not Glow():IsShown(),'glow on by default')
BS.SetValue('resurrectAcceptGlow',true); StaticPopup_Show('RESURRECT'); assert(Glow() and Glow():IsShown(),'resurrect glow')
StaticPopup_Show('PARTY_INVITE'); assert(not Glow():IsShown())
StaticPopup_Show('RESURRECT_NO_SICKNESS'); assert(Glow():IsShown()); StaticPopup1:Hide(); assert(not Glow():IsShown())
BS.Popups.events:RunScript('OnEvent','LFG_PROPOSAL_SHOW')
local bar; for _,ch in ipairs(LFDDungeonReadyDialog.children) do if ch.kind=='StatusBar' then bar=ch end end
assert(bar and bar:IsShown() and bar.maximum==40 and bar.point[3]:find('^BOTTOM'),'queue countdown')
now=now+10; bar:RunScript('OnUpdate'); assert(bar.text:GetText()=='30' and bar.value==30)
BS.SetValue('queueTimerBarHeight',20); assert(bar:GetHeight()==20)
BS.GetSettings().queueTimerTextColor={r=0,g=1,b=0}; BS.Apply(); assert(bar.text.textColor[1]==0 and bar.text.textColor[2]==1)
BS.Popups.events:RunScript('OnEvent','LFG_PROPOSAL_SUCCEEDED'); assert(not bar:IsShown())
BS.SetValue('showQueueTimer',false); BS.Popups.events:RunScript('OnEvent','LFG_PROPOSAL_SHOW'); assert(not bar:IsShown())
BS.SetValue('showQueueTimer',true)
now=now+50; BS.Popups.events:RunScript('OnEvent','LFG_PROPOSAL_SHOW'); now=now+41; bar:RunScript('OnUpdate'); assert(not bar:IsShown())

-- Combat: socketing and flyouts abort, no skin writes happen.
b2:RunScript('OnClick'); assert(fly:IsShown())
combat=true; for _,f in ipairs(allFrames) do if f.events and f.events.PLAYER_REGEN_DISABLED and f.scripts.OnEvent then f:RunScript('OnEvent','PLAYER_REGEN_DISABLED') end end
assert(not fly:IsShown()); combat=false
assert(not next(lifecycleErrors),lifecycleErrors[1])
''')
lua.execute((root/'EllesmereUIOptions/EUI_BlizzardSkin_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute(r'''
local seen={}
for _,page in ipairs(testModule.pages) do
    rows={}; assert(testModule.buildPage(page,UIParent,0)>0)
    for _,row in ipairs(rows) do
        for side=1,2 do
            local cfg=row[side]
            if cfg and cfg.text then seen[cfg.text]=cfg end
            if cfg and cfg.type=='toggle' then
                local v=cfg.getValue(); cfg.setValue(not v); assert(cfg.getValue()==(not v),'toggle not saved: '..cfg.text); cfg.setValue(v)
            elseif cfg and cfg.type=='dropdown' then
                local v=cfg.getValue()
                for _,key in ipairs(cfg.order) do assert(cfg.values[key]); cfg.setValue(key); assert(cfg.getValue()==key,'dropdown not saved: '..cfg.text) end
                cfg.setValue(v)
            elseif cfg and cfg.type=='slider' then
                local v=cfg.getValue(); cfg.setValue(cfg.max); assert(cfg.getValue()==cfg.max,'slider not saved: '..cfg.text); cfg.setValue(v)
            end
        end
    end
end
for _,text in ipairs({'Enchants on Equipment Slots','Show Enchant Names Instead of Icons','Enchant Name Size','Socketed Gem Icons',
    'Show Durability','Durability Location','Durability Label','Socket Panel & One-Click Gems','Reset Stat Colors & Order',
    'Inspect Item Levels','Inspect Enchants','Dock Inspect Beside Character','Show Merchant as List','List Row Height','Merchant Item Levels',
    'Show Player Titles','Inspect Item Level','Show GearScore','Guild Rank','Show Target','Show Mount & Collected Status','Hide Health Bar',
    'Anchor to Cursor','Cursor Position','Cursor Offset X','Cursor Offset Y','Growth Direction','Show Tooltips','Peek Modifier',
    'Manage Enhanced Tooltips','Enhanced Tooltips','Resurrect Accept Glow','Dungeon Ready Countdown','Countdown Bar Height',
    'Countdown Text Size','Countdown Text Color','Countdown Text Offset','Collections','Wardrobe & Transmog'}) do
    assert(seen[text],'missing option row: '..text)
end
for _,group in ipairs(BS.statGroups) do assert(seen[group.text..' Color'],'missing stat colour row: '..group.text) end
BS.SetValue('charSheetEnchantNames',true); assert(not seen['Enchant Name Size'].disabled())
BS.SetValue('charSheetEnchantNames',false); assert(seen['Enchant Name Size'].disabled(),'dependent row not disabled')
local db=BS.GetSettings(); db.statSectionsOrder={'Ranged'}; db.statCategoryColors={Attributes={r=1,g=0,b=0}}; db.queueTimerTextColor={r=0,g=1,b=0}
seen['Reset Stat Colors & Order'].onClick(); assert(db.statSectionsOrder==nil and db.statCategoryColors==nil)
db.statSectionsOrder={'Ranged'}; testModule.onReset(); db=BS.GetSettings()
assert(db.statSectionsOrder==nil and db.queueTimerTextColor==nil,'reset kept extras')
assert(not next(lifecycleErrors),lifecycleErrors[1])
assert(not C_Item and not C_Timer and not C_Spell and rotationCalls==0)
''')
print('PASS: tooltip info/inspect pacing/cursor+fixed anchors/visibility modes; enchant/gem/socket badges, durability, eye, model controls, TGA backdrop; stat hide/reorder/colours, better items; socket strip/flyout/socketing/confirm/timeout; inspect labels/average/dock; merchant list/buyback/grid restore/item levels; resurrect glow; queue countdown; Collections/Wardrobe/LFD skins; every option row persists.')
