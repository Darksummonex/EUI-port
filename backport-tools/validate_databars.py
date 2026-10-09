"""Exercise the Wrath DataBars port: engine, owned tooltip, block kit, every
block factory, secure travel/combat visibility, Unlock Mode movers + Element
Options links, 0.2 profile migration, options page, media and TOC contracts."""
from pathlib import Path
import re
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime  # noqa: E402
lua = LuaRuntime()
for file in ['backport-tools/wrath_mock.lua', 'backport-tools/inventory_resources_mock.lua', 'EllesmereUI/EllesmereUI_Lite.lua']:
    if file.endswith('EllesmereUI_Lite.lua'):
        lua.execute('lifecycleErrors={}; function geterrorhandler() return function(err) lifecycleErrors[#lifecycleErrors+1]=err end end')
        lua.execute((root / file).read_text(encoding='utf-8-sig'), 'EllesmereUI', lua.table())
    else:
        lua.execute((root / file).read_text(encoding='utf-8-sig'))
lua.execute('''
for _,frame in ipairs(allFrames) do
    if frame.events.ADDON_LOADED and frame.events.PLAYER_LOGIN then lifecycle=frame end
end
assert(lifecycle)
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUI')
''')
# Wrath widget surface used by the port (Retail-only methods stay absent).
lua.execute('''
local m=getmetatable(UIParent).__index
function m:IsEnabled() return true end
function m:GetNumRegions() local n=0; for _,c in ipairs(self.children) do if c.kind=='Texture' or c.kind=='FontString' then n=n+1 end end; return n end
function m:GetRegions() local out={}; for _,c in ipairs(self.children) do if c.kind=='Texture' or c.kind=='FontString' then out[#out+1]=c end end; return unpack(out) end
function m:GetChildren() local out={}; for _,c in ipairs(self.children) do if c.kind~='Texture' and c.kind~='FontString' then out[#out+1]=c end end; return unpack(out) end
function m:GetNumChildren() return select('#',self:GetChildren()) end
function m:GetStringHeight() return self.text and self.text~='' and 12 or 0 end
function m:SetWordWrap(v) self.wordWrap=v end
function m:SetNonSpaceWrap() end
function m:SetToplevel() end
function m:SetFrameLevel(v) self.level=v end
function m:GetFrameLevel() return self.level or 1 end
function m:SetFrameStrata(v) self.strata=v end
function m:GetFrameStrata() return self.strata or 'MEDIUM' end
function m:SetButtonState() end
function m:SetChecked(v) self.checked=v end
function m:GetChecked() return self.checked end
function m:SetShadowColor() end
function m:SetShadowOffset() end
function m:SetSpacing() end
function m:SetVertexColor(...) self.vertex={...} end
function m:GetVertexColor() if self.vertex then return unpack(self.vertex) end return 1,1,1,1 end
function m:SetTextColor(...) self.textColor={...} end
function m:GetTextColor() if self.textColor then return unpack(self.textColor) end return 1,1,1,1 end
function m:IsMouseEnabled() return self.mouse end
function m:EnableMouse(v) self.mouse=v end
function m:EnableKeyboard() end
function m:SetMinMaxValues(a,b) self.minimum,self.maximum=a,b end
function m:GetMinMaxValues() return self.minimum or 0,self.maximum or 1 end
function m:GetValue() return self.value or 0 end
function m:SetFontObject() end
function m:GetObjectType() return self.kind end
function m:GetRect() return 0,0,self.width,self.height end
function m:SetTexCoord(...) self.texcoords={...} end
function m:SetGradient() end
function m:SetMovable(v) self.movable=v end
function m:SetResizable() end
function m:SetUserPlaced() end
function m:IsForbidden() return false end
function m:IsProtected() return self.template and tostring(self.template):find('Secure')~=nil end
function m:SetMaxLetters() end
function m:SetJustifyH(v) self.justifyH=v end
function m:Disable() self.disabled=true end
function m:Enable() self.disabled=false end
function m:LockHighlight() end
function m:UnlockHighlight() end
function m:SetNormalFontObject() end
function m:SetHighlightFontObject() end
function m:SetFontString(fs) self.fontString=fs end
function m:GetFontString() return self.fontString end
function m:SetDisabledTexture() end
function m:SetStatusBarColor(...) self.color={...} end
function m:SetHitRectInsets() end
function m:SetClampRectInsets() end
function m:StopAnimating() end
function m:CreateAnimationGroup()
    local g={anims={}}
    function g:CreateAnimation() local a={}; setmetatable(a,{__index=function() return function() end end}); return a end
    function g:Play() self.playing=true end
    function g:Stop() self.playing=false end
    function g:IsPlaying() return self.playing end
    function g:SetLooping() end
    function g:SetScript() end
    return g
end
for _,k in ipairs({'SetSize','SetShown','SetColorTexture','EnableMouseMotion','SetIgnoreParentAlpha','SetClipsChildren','SetAtlas','SetRotatesTexture'}) do
    if k=='SetAtlas' or k=='SetRotatesTexture' then
        local orig=m[k]
        m[k]=function(self,...) retailCalls=(retailCalls or 0)+1; return orig(self,...) end
    else
        m[k]=nil
    end
end
UIParent:SetWidth(1920); UIParent:SetHeight(1080)
unlockElements={}
function EllesmereUI:RegisterUnlockElements(elements,folder) for _,e in ipairs(elements) do unlockElements[e.key]=e end end
drivers={}
function RegisterStateDriver(f,key,condition)
    assert(not combat,'Protected state driver changed during combat')
    drivers[f]=condition; f.driver=condition
    if condition=='hide' then f.shown=false
    elseif condition=='show' then f.shown=true
    elseif condition=='[combat] show; hide' then f.shown=combat
    elseif condition=='[combat] hide; show' then f.shown=not combat end
end
function Combat(value)
    combat=value
    for f,driver in pairs(drivers) do
        if driver=='[combat] show; hide' then f.shown=value
        elseif driver=='[combat] hide; show' then f.shown=not value end
    end
end
''')
# Wrath game API surface with deterministic data.
lua.execute('''
function GetFramerate() return 75.5 end
function GetNetStats() return 2.5,3.5,80 end
function GetGameTime() return 13,7 end
function GetZoneText() return 'Icecrown' end
function GetRealZoneText() return 'Icecrown' end
function GetSubZoneText() return 'Citadel' end
function GetMinimapZoneText() return 'Citadel' end
function GetZonePVPInfo() return zonePvp end
function SetMapToCurrentZone() mapSet=(mapSet or 0)+1 end
function GetCurrentMapZone() return 1 end
function GetCurrentMapContinent() return 4 end
function GetCurrentMapAreaID() return 492 end
function GetMapInfo() return 'IcecrownGlacier' end
function GetMapContinents() return 'Kalimdor','Eastern Kingdoms','Outland','Northrend' end
function GetPlayerMapPosition() if inInstance then return 0,0 end return .25,.625 end
function IsInInstance() if inInstance then return true,'raid' end return false,'none' end
function GetInstanceInfo() return 'Icecrown',inInstance and 'raid' or 'none',1,'10 Player' end
function UnitLevel() return level or 79 end
function UnitXP() return 250 end
function UnitXPMax() return 1000 end
function GetXPExhaustion() return 300 end
function GetRestState() return 1 end
function IsXPUserDisabled() return false end
function GetAccountExpansionLevel() return 2 end
MAX_PLAYER_LEVEL_TABLE={[0]=60,[1]=70,[2]=80}; MAX_PLAYER_LEVEL=80
function GetWatchedFactionInfo() if noRep then return end; return 'Argent Crusade',5,3000,9000,4500 end
function GetNumFactions() return 0 end
FACTION_BAR_COLORS={[1]={r=.8,g=.3,b=.22},[2]={r=.8,g=.3,b=.22},[3]={r=.75,g=.27,b=0},[4]={r=.9,g=.7,b=0},[5]={r=0,g=.6,b=.1},[6]={r=0,g=.6,b=.1},[7]={r=0,g=.6,b=.1},[8]={r=0,g=.6,b=.1}}
for i=1,8 do _G['FACTION_STANDING_LABEL'..i]=({'Hated','Hostile','Unfriendly','Neutral','Friendly','Honored','Revered','Exalted'})[i] end
function GetActiveTalentGroup() return activeSpec or 1 end
function GetNumTalentGroups() return 2 end
function GetNumTalentTabs() return 3 end
function GetTalentTabInfo(tab,inspect,pet,group) return ({'Arms','Fury','Protection'})[tab],'Interface\\\\Icons\\\\Ability_Warrior_Rampage',tab==2 and 51 or 10,'bg' end
function GetNumSkillLines() return 6 end
local skills={{'Professions',true},{'Alchemy',false,400,450},{'Mining',false,420,450},{'Secondary Skills',true},{'Cooking',false,300,450},{'First Aid',false,450,450}}
function GetSkillLineInfo(i) local s=skills[i]; if not s then return end; if s[2] then return s[1],true,true,0,0,0,0,false end; return s[1],false,false,s[3],0,0,s[4],true end
function ExpandSkillHeader() end
function CollapseSkillHeader() end
local spellNames={[2259]='Alchemy',[2018]='Blacksmithing',[7411]='Enchanting',[4036]='Engineering',[2366]='Herb Gathering',[45357]='Inscription',[25229]='Jewelcrafting',[2108]='Leatherworking',[2575]='Mining',[2656]='Smelting',[8613]='Skinning',[3908]='Tailoring',[2550]='Cooking',[3273]='First Aid',[7620]='Fishing',[818]='Basic Campfire',[63645]='Activate Primary Spec',[63644]='Activate Secondary Spec',[556]='Astral Recall',[53140]='Teleport: Dalaran'}
function GetSpellInfo(id) local n=spellNames[id] or (type(id)=='string' and id) or ('Spell'..tostring(id)); return n,nil,'Interface\\\\Icons\\\\Spell_Nature_AstralRecal' end
function IsSpellKnown(id) return id==53140 end
function GetSpellCooldown() return 0,0,1 end
function GetNumSpellTabs() return 0 end
function GetSpellTabInfo() return nil,nil,0,0 end
function GetInventoryItemDurability(i) if i==1 then return 50,100 end end
local equip={[1]='item:1',[5]='item:5',[16]='item:16'}
function GetInventoryItemLink(_,slot) return equip[slot] end
function GetInventoryItemID(_,slot) return equip[slot] and 1 or nil end
function GetInventoryItemTexture() return 'Interface\\\\Icons\\\\INV_Misc_QuestionMark' end
function GetInventorySlotInfo(name) return 1 end
local origItemInfo=GetItemInfo
function GetItemInfo(link)
    if link=='item:1' or link=='item:5' or link=='item:16' then return 'Gear','item:1',4,232,80,'Armor','Plate',1,link=='item:16' and 'INVTYPE_2HWEAPON' or 'INVTYPE_CHEST','icon' end
    if link==6948 or link=='item:6948' then return 'Hearthstone','item:6948',1,1,1,'Misc','Junk',1,'','Interface\\\\Icons\\\\INV_Misc_Rune_01' end
    if origItemInfo then return origItemInfo(link) end
end
function GetItemCount(id) if id==6948 or id=='item:6948' then return 1 end return 0 end
function GetItemCooldown(id) return 0,0,1 end
function IsEquippedItem() return false end
function GetItemIcon() return 'Interface\\\\Icons\\\\INV_Misc_Rune_01' end
function GetBindLocation() return 'Dalaran' end
function HasNewMail() return true end
function GetLatestThreeSenders() return 'Alice' end
function IsResting() return resting or false end
function GetCurrencyListSize() return 2 end
function GetCurrencyListInfo(i) if i==1 then return 'Dungeon and Raid',true,true,false,false,0 end; return 'Emblem of Frost',false,false,false,true,40,0,'Interface\\\\Icons\\\\INV_Misc_Frostemblem_01',49426 end
function ExpandCurrencyList() end
function GetHonorCurrency() return 1234 end
function GetArenaCurrency() return 56 end
function UnitFactionGroup() return 'Horde','Horde' end
cvars={Sound_EnableAllSound='1',Sound_MasterVolume='0.5',Sound_EnableSFX='1',Sound_SFXVolume='0.2',Sound_MusicVolume='0.4',Sound_AmbienceVolume='0.6',Sound_EnableMusic='1',Sound_EnableAmbience='1'}
function GetCVar(key) return cvars[key] or '1' end
function GetCVarBool(key) return GetCVar(key)=='1' end
function SetCVar(key,value) cvars[key]=tostring(value) end
function ToggleCharacter(tab) openedTab=tab end
function ToggleFrame(f) toggledFrame=f end
function ToggleTalentFrame() talents=true end
function ToggleSpellBook() spellbook=true end
function ToggleAchievementFrame() achievements=true end
function ToggleFriendsFrame(tab) friendsTab=tab or 1 end
function TogglePVPFrame() pvp=true end
function ToggleLFDParentFrame() lfd=true end
function ToggleHelpFrame() help=true end
function ToggleQuestLog() questlog=true end
function ShowUIPanel(f) if f then f:Show() end end
function HideUIPanel(f) if f then f:Hide() end end
function LoadAddOn() return true end
function Calendar_Toggle() calendar=true end
function TimeManager_Toggle() timeManager=true end
CalendarFrame=CreateFrame('Frame','CalendarFrame',UIParent); TimeManagerFrame=CreateFrame('Frame','TimeManagerFrame',UIParent)
WorldMapFrame=CreateFrame('Frame','WorldMapFrame',UIParent); WorldMapFrame:Hide()
QuestLogFrame=CreateFrame('Frame','QuestLogFrame',UIParent); GameMenuFrame=CreateFrame('Frame','GameMenuFrame',UIParent); GameMenuFrame:Hide()
CharacterMicroButton=CreateFrame('Button','CharacterMicroButton',UIParent)
function GetQuestResetTime() return 3600 end
function GetNumSavedInstances() return 1 end
function GetSavedInstanceInfo(i) return 'Icecrown Citadel',1,86400*3,3,true,false,0,true,25,'25 Player' end
function RequestRaidInfo() end
function CalendarGetDate() return 2,10,5,2026 end
function UpdateAddOnMemoryUsage() end
function GetNumAddOns() return 1 end
function GetAddOnInfo() return 'EllesmereUI','EllesmereUI' end
function GetAddOnMemoryUsage() return 2048 end
function IsAddOnLoaded() return true end
function GetNumFriends() return 1,1 end
function GetFriendInfo(i) return 'Bob',80,'Mage','Dalaran',true,'','' end
function BNGetNumFriends() return 0,0 end
function ShowFriends() end
function IsInGuild() return true end
function GetGuildInfo() return 'Guild','Member',1 end
function GuildRoster() end
function GetNumGuildMembers() return 2,1 end
function GetGuildRosterInfo(i) return 'Carl','Member',1,80,'Priest','Dalaran','','',i==1,0,'PRIEST' end
function UnitStat(_,i) return 100*i,100*i end
function GetCritChance() return 10 end
function GetRangedCritChance() return 5 end
function GetSpellCritChance() return 7 end
function GetCombatRatingBonus() return 3 end
function GetCombatRating() return 10 end
function GetArmorPenetration() return 0 end
function UnitAttackSpeed() return 2 end
function GetMoney() return money or 12345 end
function GetCoinTextureString(v) return v..' copper' end
function GetRealmName() return 'Test Realm' end
function UnitName(u) if u=='player' then return 'Tester' end return u end
function IsShiftKeyDown() return shiftDown or false end
function IsAltKeyDown() return altDown or false end
function IsModifiedClick() return false end
function PlaySound() end
function ReloadUI() reloaded=true end
function ChatFrame_SendTell(name) toldName=name end
function InviteUnit(name) invited=name end
function UIErrorsFrame_AddMessage() end
UIErrorsFrame={AddMessage=function() end}
DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) chatMsg=msg end}
function SecondsToTime(s) return tostring(math.floor(s))..' sec' end
function GetCVarDefault() return '1' end
BOOKTYPE_SPELL='spell'
RAID_CLASS_COLORS={WARRIOR={r=.78,g=.61,b=.43},MAGE={r=.41,g=.8,b=.94},PRIEST={r=1,g=1,b=1}}
LOCALIZED_CLASS_NAMES_MALE={WARRIOR='Warrior',MAGE='Mage',PRIEST='Priest'}
NUM_BAG_SLOTS=4
function GetContainerNumSlots(bag) if bag>=0 and bag<=4 then return bag==0 and 16 or 0 end return 0 end
function GetContainerNumFreeSlots(bag) if bag==0 then return 6,0 end return 0,0 end
function GetContainerItemLink() end
function ToggleAllBags() bagsToggled=true end
function OpenAllBags() bagsToggled=true end
function ToggleBackpack() bagsToggled=true end
function CloseAllBags() end
function GetBindingKey() return 'C' end
function GetBindingText(k) return k end
function MicroButtonTooltipText(t,b) return t end
function GetCursorPosition() return 100,100 end
function date(fmt,t) return os.date(fmt,t or 1790820000) end
function time() return 1790820000 end
''')
ns = lua.table()
toc = (root / 'EllesmereUIDataBars/EllesmereUIDataBars.toc').read_text(encoding='utf-8-sig')
files = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith('#')]
for file in files:
    lua.execute((root / 'EllesmereUIDataBars' / file.replace('\\', '/')).read_text(encoding='utf-8-sig'), 'EllesmereUIDataBars', ns)
lua.globals().D = ns
lua.execute('''
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUIDataBars')
assert(#lifecycleErrors==0,lifecycleErrors[1])
assert(D.addon.db)
-- Legacy 0.2 profile shape migrates on first apply.
local p=D.addon.db.profile
p.nextBarId=1; p.initialized=true; p.schema=nil; p.enabled=true
p.bars={{id=1,name='Old Bar',enabled=true,theme='modern',bgAlpha=.5,spacing=4,fontSize=12,scale=1,width=800,
    visibility='combat',sizingMode='weighted',nextBlockId=2,orientation='H',thickness=30,length=800,
    blocks={{id=1,type='xprep',width=100,settings={mode='reputation'}},{id=2,type='currency',settings={currencyKey='49426'}}}}}
function IsLoggedIn() return true end
lifecycle:RunScript('OnEvent','PLAYER_LOGIN')
assert(#lifecycleErrors==0,lifecycleErrors[1])
local old=D.GetBar(1)
assert(p.schema==2 and type(old.theme)=='table' and old.theme.style=='modern' and old.visibility=='in_combat' and old.sizingMode=='auto')
assert(old.blocks[1].settings.mode=='rep' and old.blocks[2].settings.currencyId==49426 and old.blocks[1].width==nil and old.enabled==nil)
assert(D.live[1].bar.driver=='[combat] show; hide')
assert(D.ProgressUsed('reputation') and D.ProgressUsed('rep') and not D.ProgressUsed('xp'))
''')
print('PASS: ADDON_LOADED/PLAYER_LOGIN lifecycle and 0.2 profile migration (theme, visibility, sizing, xprep mode, currency key)')

lua.execute('''
local bar=D.CreateBar('empty'); testBar=bar
assert(D.GetProfile().selectedBarId==bar.id)
bar.length=1600; bar.thickness=32; bar.lengthMode='fixed'
allBlocks={}
for _,t in ipairs(D.BLOCK_TYPES) do allBlocks[t.key]=D.AddBlock(bar.id,t.key) end
assert(#bar.blocks==20 and #D.BLOCK_TYPES==20)
for _,k in ipairs({'crests','greatvault'}) do assert(not D.BlockFactories[k] and not D.BLOCK_DEFAULTS[k]) end
D.ApplyBar(bar.id); D.FlushLayouts(); D.HeartbeatTick()
assert(#lifecycleErrors==0,lifecycleErrors[1])
rec=D.live[bar.id]
function Inst(key) return rec.insts[allBlocks[key].id] end
function Slot(key) return rec.slots[allBlocks[key].id] end
for _,t in ipairs(D.BLOCK_TYPES) do
    local inst=Inst(t.key)
    assert(inst,'missing block instance: '..t.key)
    assert(inst.cfg==allBlocks[t.key] and inst.Refresh and inst.Enable and inst.Disable and inst.Destroy and inst.GetAutoLength,t.key)
    local ok,err=pcall(inst.Refresh,inst); assert(ok,t.key..': '..tostring(err))
    local len=inst:GetAutoLength(); assert(type(len)=='number' and len>=0,t.key)
end
assert(retailCalls==nil or retailCalls==0,'Retail-only texture API reached')
''')
print('PASS: all 20 Wrath block factories build, refresh and measure (no Crests/Great Vault, no SetAtlas/SetRotatesTexture)')

# Find text in a block's widget tree.
lua.execute('''
function Texts(frame,out)
    out=out or {}
    if frame.kind=='FontString' and frame.text then out[#out+1]=tostring(frame.text) end
    for _,c in ipairs(frame.children or {}) do Texts(c,out) end
    return out
end
function HasText(key,pattern)
    for _,t in ipairs(Texts(Slot(key))) do if t:find(pattern) then return true end end
    return false, table.concat(Texts(Slot(key)),' | ')
end
function Find(frame,pred)
    if pred(frame) then return frame end
    for _,c in ipairs(frame.children or {}) do local hit=Find(c,pred); if hit then return hit end end
end
local checks={{'fps','75'},{'ms','80'},{'location','Citadel'},{'coords','25'},{'durability','50'},{'spec','Fury'},
    {'profession','Alchemy'},{'currency','40'},{'clock','%d'},{'gold','1'},{'bags','6'},{'ilvl','%d'}}
allBlocks.currency.settings.currencyId=49426; Inst('currency'):Refresh()
local vol=Find(Slot('audio'),function(f) return f.kind=='StatusBar' end); assert(vol and vol.value==.5,'audio volume bar')
local bad={}
for _,c in ipairs(checks) do local ok,all=HasText(c[1],c[2]); if not ok then bad[#bad+1]=c[1]..' text: '..tostring(all) end end
assert(#bad==0,table.concat(bad,'\\n'))
assert(D.BlockKit.lastDurabilityPct==50)
assert(D.BlockKit.lastAvgIlvl and D.BlockKit.lastAvgIlvl>0)
-- Secure hearthstone lives inside the travel block.
travelBtn=Find(Slot('travel'),function(f) return f.template and tostring(f.template):find('SecureActionButtonTemplate') end)
assert(travelBtn,'travel secure button')
local item=travelBtn:GetAttribute('*item1') or travelBtn:GetAttribute('item') or travelBtn:GetAttribute('macrotext')
local kind=travelBtn:GetAttribute('*type1') or travelBtn:GetAttribute('type')
assert(kind=='item' or kind=='macro','travel action type '..tostring(kind))
assert(item and (tostring(item):find('6948') or tostring(item):find('Hearthstone')),'hearthstone attribute '..tostring(item))
-- XP block feeds the ActionBars handoff.
assert(D.ProgressUsed('xp'))
''')
print('PASS: block values (fps, latency, zone, coords, durability, talents, professions, currency, audio, clock, item level) and secure hearthstone')

# Latency text follows the good/fair/poor color by default; a chosen text color still wins.
lua.execute('''
local K, msb = D.BlockKit, allBlocks.ms
local function shown()
    local fs=Find(Slot('ms'),function(f) return f.kind=='FontString' and f.text and tostring(f.text):find('%d') end)
    return fs.textColor
end
local function at(lat) GetNetStats=function() return 2.5,3.5,lat end; Inst('ms'):Refresh(); return shown() end
msb.color,msb.useClassColor,msb.useAccentColor,msb.useDynamicColor=nil,nil,nil,nil
local good,fair,poor=at(80),at(180),at(400)
assert(good[2]>good[1] and good[2]>good[3],'good latency is green')
assert(fair[1]>.5 and fair[2]>.5 and fair[3]<.5,'fair latency is yellow')
assert(poor[1]>poor[2] and poor[1]>poor[3],'poor latency is red')
msb.useDynamicColor=true; assert(at(400)[1]==poor[1])
msb.useDynamicColor=nil; msb.color={r=.2,g=.3,b=.4}; local c=at(400); assert(c[1]==.2 and c[2]==.3 and c[3]==.4,'custom color wins')
msb.color=nil; msb.useAccentColor=true; local ar=D.GetAccent(); assert(at(400)[1]==ar,'accent wins'); msb.useAccentColor=nil
local fps=allBlocks.fps; fps.color,fps.useDynamicColor=nil,nil
local r,g,b=K.BlockColorOf(fps); assert(r==1 and g==1 and b==1,'other blocks keep white')
GetNetStats=function() return 2.5,3.5,80 end; Inst('ms'):Refresh()
''')
print('PASS: latency text colored good/fair/poor by default and with the Latency swatch; custom/accent colors win; other blocks stay white')

# Owned tooltip: every interactive block opens rows on hover.
lua.execute('''
local opened=0
for _,t in ipairs(D.BLOCK_TYPES) do
    local slot=Slot(t.key)
    local target=Find(slot,function(f) return f.scripts and f.scripts.OnEnter end)
    if target then
        local ok,err=pcall(target.RunScript,target,'OnEnter'); assert(ok,t.key..' OnEnter: '..tostring(err))
        if D.Tip_Lines and #D.Tip_Lines()>0 then opened=opened+1 end
        local ok2,err2=pcall(target.RunScript,target,'OnLeave'); assert(ok2,t.key..' OnLeave: '..tostring(err2))
        D.Tip_Hide()
    end
end
assert(opened>=10,'owned tooltip rows opened by '..opened..' blocks')
assert(#lifecycleErrors==0,lifecycleErrors[1])
''')
print('PASS: owned tooltip opens for the interactive blocks without errors')

# Clicks and wheel on the main blocks.
lua.execute('''
local function Click(key,button)
    local target=Find(Slot(key),function(f) return f.scripts and (f.scripts.OnClick or f.scripts.OnMouseUp) and not (f.template and tostring(f.template):find('Secure')) end)
    assert(target,'clickable '..key)
    if target.scripts.OnClick then target:RunScript('OnClick',button or 'LeftButton') else target:RunScript('OnMouseUp',button or 'LeftButton') end
end
Click('clock','LeftButton'); assert(calendar,'calendar')
Click('clock','RightButton'); assert(timeManager,'time manager')
Click('ilvl','LeftButton'); assert(openedTab=='PaperDollFrame')
Click('location','LeftButton'); assert(toggledFrame==WorldMapFrame)
local before=tonumber(cvars.Sound_MasterVolume)
local wheel=Find(Slot('audio'),function(f) return f.scripts and f.scripts.OnMouseWheel end)
assert(wheel); wheel:RunScript('OnMouseWheel',1); assert(tonumber(cvars.Sound_MasterVolume)>before)
local micro=Find(Slot('micromenu'),function(f) return f.kind=='Button' and f.scripts and f.scripts.OnClick end)
assert(micro); assert(CharacterMicroButton:GetParent()==UIParent)
assert(#lifecycleErrors==0,lifecycleErrors[1])
''')
print('PASS: clock/item level/location clicks, audio wheel, micro menu never touches Blizzard micro buttons')

# Layout solver, vertical bars, combat deferral, unlock elements.
lua.execute('''
local bar=testBar
local segs=D.SolveLayout(bar,1600,function(b) local i=rec.insts[b.id]; return i and i:GetAutoLength() or 0 end)
local last=segs[#segs]; assert(last.at+last.px<=1600.01,'layout overflow')
bar.sizingMode='even'; segs=D.SolveLayout(bar,1600,function() return 50 end)
assert(math.abs(segs[1].px-segs[2].px)<.01)
bar.sizingMode='auto'
bar.orientation='V'; D.ApplyBar(bar.id); D.FlushLayouts(); assert(rec.bar:GetWidth()==32 and rec.bar:GetHeight()==1600 and rotationCalls==0)
bar.orientation='H'; D.ApplyBar(bar.id); D.FlushLayouts()
local elem=unlockElements['EDB_'..bar.id]
assert(elem and elem.getFrame()==rec.bar and elem.group=='DataBars')
elem.savePos(nil,'TOPLEFT','TOPLEFT',20,-60); elem.applyPos()
assert(elem.loadPos().y==-60 and bar.savedPos.point=='TOPLEFT')
local map=EllesmereUI._ELEMENT_SETTINGS_MAP['EDB_'..bar.id]
assert(map and map.module=='EllesmereUIDataBars' and map.page=='DataBars' and map.sectionName=='BAR SETTINGS' and map.highlightText=='Visibility')
D.GetProfile().selectedBarId=1; map.preSelectFn(); assert(D.GetProfile().selectedBarId==bar.id)
assert(unlockElements.EDB_1 and EllesmereUI._ELEMENT_SETTINGS_MAP.EDB_1)
D.RenameBar(bar.id,'Test Bar'); assert(bar.name=='Test Bar')
-- Combat: secure driver keeps working, structural edits defer.
bar.visibility='out_of_combat'; D.ApplyBar(bar.id); assert(rec.bar.driver=='[combat] hide; show')
Combat(true); assert(not rec.bar:IsShown())
local oldLen=bar.length; bar.length=1000; D.ApplyBar(bar.id); assert(rec.bar:GetWidth()==oldLen,'resized in combat')
assert(not D.CreateBar('empty') and not D.AddBlock(bar.id,'fps'))
D.DeleteBar(bar.id); assert(D.GetBar(bar.id),'deleted in combat')
Combat(false); D.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); D.FlushDeferred(); D.FlushLayouts()
assert(rec.bar:GetWidth()==1000 and rec.bar:IsShown())
EllesmereUI.listeners.EllesmereUIDataBars(true); assert(rec.bar.driver=='show' and D.preview)
EllesmereUI.listeners.EllesmereUIDataBars(false); assert(rec.bar.driver=='[combat] hide; show' and not D.preview)
bar.visibility='never'; D.ApplyBar(bar.id); assert(rec.bar.driver=='hide')
bar.visibility='always'; D.ApplyBar(bar.id); assert(rec.bar.driver=='show')
-- Removing XP hands progress back to ActionBars.
D.RemoveBlock(bar.id,allBlocks.xprep.id); D.RemoveBlock(1,D.GetBar(1).blocks[1].id); assert(not D.ProgressUsed('xp') and not D.ProgressUsed('reputation'))
local count=#allFrames; D.Update(); D.Apply(); D.Apply(); assert(#allFrames==count,'reapply leaked frames')
D.DeleteBar(bar.id); assert(not D.GetBar(bar.id) and rec.bar.driver=='hide')
local mc=D.CreateBar('minimapc'); assert(mc and #mc.blocks>0); local ms=D.CreateBar('microstrip'); assert(ms)
assert(unlockElements['EDB_'..mc.id] and EllesmereUI._ELEMENT_SETTINGS_MAP['EDB_'..ms.id])
-- Profile replacement rebuilds instances against the new block tables.
local copied=D.Copy(D.GetProfile()); D.addon.db.profile=copied; D.Apply()
for id,inst in pairs(D.live[mc.id].insts) do assert(inst.cfg==D.GetBlock(mc.id,id),'stale block cfg') end
assert(#lifecycleErrors==0,lifecycleErrors[1])
''')
print('PASS: solver bounds/even split, vertical bars without rotation, Unlock Mode movers + Element Options links (preSelectFn), combat-safe drivers/deferral, preview, CRUD, profile rebinding')

# Options page.
lua.execute('''
local W=EllesmereUI.Widgets; swatches={}; cogs={}
local function Half(row,cfg) local r=CreateFrame('Frame',nil,row); r._control=CreateFrame('Frame',nil,r); r.cfg=cfg; return r end
function W:DualRow(parent,y,a,b) local row=CreateFrame('Frame',nil,parent); row._leftRegion,row._rightRegion=Half(row,a),Half(row,b); rows[#rows+1]=a; rows[#rows+1]=b; return row,50 end
function W:SectionHeader(parent,label,y) sections=sections or {}; sections[#sections+1]=label; return CreateFrame('Frame',nil,parent),30 end
function W:WideButton(parent,label,y,fn) buttons[label]=fn; return CreateFrame('Button',nil,parent),40 end
function W:Spacer(parent,y,h) return CreateFrame('Frame',nil,parent),h or 10 end
function EllesmereUI.BuildColorSwatch(rgn,level,get,set) local sw=CreateFrame('Button',nil,rgn); sw.get,sw.set=get,set; return sw,function() end end
function EllesmereUI.BuildInlineCog(rgn,opts) cogs[opts.title or '?']=opts; return CreateFrame('Button',nil,rgn) end
function EllesmereUI.BuildVisibilityRow(W,parent,y,opts,right)
    visOpts=opts; local row,h=W:DualRow(parent,y,{type='dropdown',text='Visibility',getValue=function() return opts.getStore().visibility end,setValue=function(v) opts.getStore().visibility=v; if opts.onChanged then opts.onChanged() end end},right)
    return row,h
end
function EllesmereUI.RegisterWidgetRefresh() end
function EllesmereUI:SetContentHeader() end
function EllesmereUI:ClearContentHeader() end
function EllesmereUI:ShowConfirmPopup(opts) confirmPopup=opts end
function EllesmereUI.GetAccentColor() return 0,.8,.6 end
function EllesmereUI.GetFontsDir() return 'Fonts\\\\' end
function EllesmereUI:ToggleUnlockMode() unlockOpened=true end
''')
lua.execute((root / 'EllesmereUIOptions/EUI_DataBars_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
for i=#allFrames,1,-1 do local f=allFrames[i]; if f.events.PLAYER_LOGIN and f~=lifecycle then f:RunScript('OnEvent','PLAYER_LOGIN') end end
local cfg=modules.EllesmereUIDataBars; assert(cfg and cfg.pages[1]=='DataBars' and cfg.buildPage and cfg.onReset)
rows={}; sections={}
local h=cfg.buildPage('DataBars',UIParent,0); assert(type(h)=='number' and h>0)
assert(#lifecycleErrors==0,lifecycleErrors[1])
local hasBar=false; for _,s in ipairs(sections) do if s=='BAR SETTINGS' then hasBar=true end end; assert(hasBar,'BAR SETTINGS section')
assert(FindRow('Visibility') and FindRow('Select Bar') and FindRow('Text Scale') and FindRow('Block To Add'))
local target=D.BarsInOrder()[#D.BarsInOrder()]
FindRow('Select Bar').setValue(target.id); rows={}; sections={}; cfg.buildPage('DataBars',UIParent,0)
FindRow('Text Scale').setValue(120); assert(D.GetBar(target.id).fontScale==120)
local n=#target.blocks
FindRow('Block To Add').setValue('currency')
local addHalf=nil; for _,r in ipairs(rows) do if r and r.type=='button' and r.text=='Add Block' then addHalf=r end end
assert(addHalf and addHalf.onClick,'Add Block button'); addHalf.onClick()
assert(#D.GetBar(target.id).blocks==n+1 and D.GetBar(target.id).blocks[n+1].type=='currency')
rows={}; sections={}; cfg.buildPage('DataBars',UIParent,0)
FindRow('Currency').setValue(49426); assert(D.GetBar(target.id).blocks[n+1].settings.currencyId==49426)
FindRow('Visibility').setValue('in_raid'); assert(D.GetBar(target.id).visibility=='in_raid' and D.live[target.id].bar.driver=='[group:raid] show; hide')
for _,r in ipairs(rows) do if r and r.type=='input' then assert(not r.autoFocus,'options EditBox autofocus') end end
-- Latency Text Color: a Latency swatch, selected while no color is stored; Custom seeds white on first click.
local msBar, msBlock
for _,bar in ipairs(D.BarsInOrder()) do for _,b in ipairs(bar.blocks) do if b.type=='ms' and not msBlock then msBar,msBlock=bar,b end end end
assert(msBlock,'a bar with a latency block')
msBlock.color,msBlock.useClassColor,msBlock.useAccentColor,msBlock.useDynamicColor=nil,nil,nil,nil
FindRow('Select Bar').setValue(msBar.id); rows={}; sections={}; cfg.buildPage('DataBars',UIParent,0)
local lat, custom
for _,r in ipairs(rows) do
    if r and r.type=='multiSwatch' then
        for _,sw in ipairs(r.swatches) do if sw.tooltip=='Latency' then lat,custom=sw,r.swatches[1] end end
    end
end
assert(lat and custom,'Latency text color swatch')
assert(lat.refreshAlpha()==1 and custom.refreshAlpha()==.3,'Latency selected by default')
custom.onClick({}); assert(msBlock.color and msBlock.color.r==1 and custom.refreshAlpha()==1 and lat.refreshAlpha()==.3)
lat.onClick(); assert(msBlock.useDynamicColor and lat.refreshAlpha()==1 and custom.refreshAlpha()==.3)
msBlock.color,msBlock.useDynamicColor=nil,nil
assert(#lifecycleErrors==0,lifecycleErrors[1])
SlashCmdList.EUI335DATABARS(); assert(shownModule=='EllesmereUIDataBars')
''')
print('PASS: options page (BAR SETTINGS/Visibility, Select Bar, Text Scale, Add Block, Currency, visibility driver, no EditBox autofocus) and /edb')

# Preserved Retail source, native TOC, Wrath-only media and API surface.
original = Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIDataBars')
if original.exists():
    for p in original.rglob('*'):
        if p.is_file() and p.suffix != '.toc':
            assert p.read_bytes() == (root / 'EllesmereUIDataBars' / p.relative_to(original)).read_bytes(), p
    retail_opts = Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIOptions/EllesmereUIDataBars_Options.lua')
    if retail_opts.exists():
        assert retail_opts.read_bytes() == (root / 'EllesmereUIOptions/EllesmereUIDataBars_Options.lua').read_bytes()
expected = ['EUI_DataBars_335.lua', 'EUI_DataBars_335_Tip.lua', 'EUI_DataBars_335_Kit.lua'] + ['Blocks_335\\' + n + '.lua' for n in
    ['Clock', 'Stats', 'Location', 'Gold', 'Bags', 'XPRep', 'Travel', 'Spec', 'Profession', 'MicroMenu', 'Currency', 'ItemLevel', 'Audio', 'LDB', 'Spacer']]
assert files == expected, files
assert re.search(r'^## Interface: 30300$', toc, re.M) and re.search(r'^## Version: 9\.3\.4-335-0\.5$', toc, re.M)
wrath_sources = [root / 'EllesmereUIDataBars' / f.replace('\\', '/') for f in files] + [root / 'EllesmereUIOptions/EUI_DataBars_335_Options.lua']
banned = re.compile(r'\.png["\']|:SetAtlas\(|:SetRotatesTexture\(|:SetSize\(|:SetShown\(|:SetColorTexture\(|C_Timer\.After|\bC_(Map|CurrencyInfo|Container|PvP|Item|Spell|DateAndTime|ClassTalents|SpecializationInfo|ToyBox|FriendList|BattleNet|Club|TradeSkillUI|WeeklyRewards|AddOns|CVar)\.')
for src in wrath_sources:
    for i, line in enumerate(src.read_text(encoding='utf-8-sig').splitlines(), 1):
        code = line.split('--', 1)[0]
        hit = banned.search(code)
        if hit and hit.group(0).startswith(':'):
            method = hit.group(0)[1:-1]
            if re.search(r'if\s+[\w.]+\.' + method + r'\s+then', code):
                continue  # feature-guarded call (compat shim installed by the core)
        assert not hit, f'{src.name}:{i}: {hit.group(0)}'
media = root / 'EllesmereUIDataBars/Media_335'
for src in wrath_sources:
    text = src.read_text(encoding='utf-8-sig')
    for base, ref in re.findall(r'\b(MICROMENU_MEDIA|MM_MEDIA|MEDIA)\s*\.\.\s*"([^"]+)"', text):
        if ref.endswith('\\'):
            continue
        sub = 'micromenu/' if base in ('MICROMENU_MEDIA', 'MM_MEDIA') else ''
        path = media / (sub + ref.replace('\\\\', '/').replace('\\', '/') + '.tga')
        assert path.exists(), f'{src.name}: missing media {base} {ref}'
    for ref in re.findall(r'"(prof-[a-z]+)"', text):
        assert (media / 'profession' / (ref + '.tga')).exists(), f'{src.name}: missing profession icon {ref}'
    for ref in re.findall(r'"((?:dk|druid|hunter|mage|paladin|priest|rogue|shaman|warlock|warrior)-[a-z]+)"', text):
        assert (media / 'spec' / (ref + '.tga')).exists(), f'{src.name}: missing spec icon {ref}'
    for ref in re.findall(r'"(menu-[a-z]+)"', text):
        assert (media / 'micromenu' / (ref + '.tga')).exists(), f'{src.name}: missing micro menu icon {ref}'
from PIL import Image  # noqa: E402
for tga in media.rglob('*.tga'):
    w, h = Image.open(tga).size
    assert w & (w - 1) == 0 and h & (h - 1) == 0, tga
print('PASS: unchanged Retail references, native TOC 9.3.4-335-0.5 load order, no Retail-only APIs/PNG, power-of-two TGA media present')

# Snapped and full-length bars anchor to UIParent's edges, never to offsets computed
# from its size: Core re-applies the UI scale after OnEnable, which stranded the bar.
lua.execute('''
local m=getmetatable(UIParent).__index
local oldSet,oldClear,oldCombat=m.SetPoint,m.ClearAllPoints,InCombatLockdown
function InCombatLockdown() return false end
function m:ClearAllPoints() self.pts={} end
function m:SetPoint(...) self.pts=self.pts or {}; self.pts[#self.pts+1]={...} end
local cfg=D.CreateBar('empty'); local id=cfg.id; D.ApplyBar(id); local frame=D.live[id].bar
local function Is(i,p,rp,x,y) local q=frame.pts[i]; return q and q[1]==p and q[2]==UIParent and q[3]==rp and q[4]==x and q[5]==y end
local function Apply() D.ApplyBarPosition(id); return #frame.pts end
-- The reported Bottom Info Bar: custom length, snapped to top, saved BOTTOM/BOTTOM.
cfg.orientation='H'; cfg.lengthMode='custom'; cfg.snapEdge='top'; cfg.savedPos={point='BOTTOM',relPoint='BOTTOM',x=0,y=0}
assert(Apply()==1 and Is(1,'TOP','TOP',0,0),'top snap')
cfg.savedPos={point='TOPRIGHT',relPoint='TOPRIGHT',x=-40,y=-200}; Apply(); assert(Is(1,'TOPRIGHT','TOPRIGHT',-40,0))
cfg.snapEdge='bottom'; cfg.savedPos={point='LEFT',relPoint='CENTER',x=25,y=99}; Apply(); assert(Is(1,'BOTTOMLEFT','BOTTOM',25,0))
cfg.lengthMode='full'; cfg.snapEdge='top'; assert(Apply()==2 and Is(1,'TOPLEFT','TOPLEFT',0,0) and Is(2,'TOPRIGHT','TOPRIGHT',0,0))
cfg.snapEdge='none'; cfg.savedPos={point='CENTER',relPoint='CENTER',x=10,y=-300}; Apply(); assert(Is(1,'LEFT','LEFT',0,-300) and Is(2,'RIGHT','RIGHT',0,-300))
cfg.orientation='V'; cfg.lengthMode='custom'; cfg.snapEdge='left'; cfg.savedPos={point='TOP',relPoint='CENTER',x=5,y=60}
assert(Apply()==1 and Is(1,'TOPLEFT','LEFT',0,60))
cfg.lengthMode='full'; cfg.snapEdge='right'; Apply(); assert(Is(1,'TOPRIGHT','TOPRIGHT',0,0) and Is(2,'BOTTOMRIGHT','BOTTOMRIGHT',0,0))
cfg.snapEdge='none'; cfg.savedPos={point='CENTER',relPoint='CENTER',x=-70,y=3}; Apply(); assert(Is(1,'TOP','TOP',-70,0) and Is(2,'BOTTOM','BOTTOM',-70,0))
-- Free bars keep their saved anchor as-is.
cfg.orientation='H'; cfg.lengthMode='custom'; cfg.snapEdge='none'; cfg.savedPos={point='TOPRIGHT',relPoint='TOPRIGHT',x=-4,y=-240}
Apply(); assert(Is(1,'TOPRIGHT','TOPRIGHT',-4,-240))
-- Positioning never reads UIParent's size.
local gw,gh=UIParent.GetWidth,UIParent.GetHeight
UIParent.GetWidth=function() error('size-dependent bar anchor') end; UIParent.GetHeight=UIParent.GetWidth
for _,c in ipairs({{'H','custom','top'},{'H','full','bottom'},{'H','full','none'},{'V','custom','right'},{'V','full','left'},{'V','full','none'}}) do
    cfg.orientation,cfg.lengthMode,cfg.snapEdge=c[1],c[2],c[3]; Apply()
end
UIParent.GetWidth,UIParent.GetHeight=gw,gh
m.SetPoint,m.ClearAllPoints,InCombatLockdown=oldSet,oldClear,oldCombat
''')
print('PASS: snapped and full-length bars anchor to UIParent edges (scale-independent); free bars keep their saved anchor')
