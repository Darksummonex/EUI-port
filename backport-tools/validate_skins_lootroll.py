"""ElvUI-parity skins (barber, PvP/arena registrar, battleground score/minimap, help/GM,
mirror timers/stopwatch, debug tools, raid pullouts, capture bar, GM chat status, Ace3) and group loot roll choices."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
skin=root/'EllesmereUIBlizzardSkin'
toc=(skin/'EllesmereUIBlizzardSkin.toc').read_text(encoding='utf-8-sig')
assert '## Version: 9.3.4-335-0.30' in toc and 'EUI_SkinExtras_335.lua' in toc and 'EUI_LootRolls_335.lua' in toc
lua=LuaRuntime()
for name in ['backport-tools/wrath_mock.lua','backport-tools/blizzardskin_mock.lua','backport-tools/character_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/name).read_text(encoding='utf-8-sig'))
lua.execute(r'''
CreateCharacterFixture(); EllesmereUIDB={}
local m=getmetatable(UIParent).__index
function m:SetStatusBarTexture(v) self.barTexture=v end
function m:GetStatusBarTexture() self.barTex=self.barTex or {GetTexture=function() return self.barTexture end}; return self.barTex end
local function Named(parent,name,path,layer)
    local t=parent:CreateTexture(); t.name=name; _G[name]=t; t:SetTexture(path); if layer then t:SetDrawLayer(layer) end; return t
end
-- Window specs from the client FrameXML names.
for _,name in ipairs({'BarberShopFrame','PVPParentFrame','BattlefieldFrame','ArenaFrame','ArenaRegistrarFrame','PVPBannerFrame',
    'WorldStateScoreFrame','RebuffedHelpFrame','StopwatchFrame','TimeManagerFrame','ScriptErrorsFrame','EventTraceFrame','TicketStatusFrame',
    'RaidInfoFrame'}) do
    _G[name]=NativeWindow(name)
end
PVPFrame=CreateFrame('Frame','PVPFrame',PVPParentFrame); PVPFrame:SetBackdrop(nil)
Named(PVPFrame,'PVPFrameBackground','Interface\\PVPFrame\\UI-Character-PVP')
Named(PVPFrame,'PVPFramePortrait','Interface\\BattlefieldFrame\\UI-Battlefield-Icon')
Named(PVPBannerFrame,'PVPBannerFrameEmblemTopLeft','Interface\\PVPFrame\\Icons\\PVP-Banner-Emblem-1')
Named(BattlefieldFrame,'BattlefieldFrameHonorSymbol','Interface\\PVPFrame\\PVP-Currency-Horde')
StopwatchTabFrame=CreateFrame('Frame','StopwatchTabFrame',StopwatchFrame)
Named(StopwatchTabFrame,'StopwatchTabFrameMiddle','Interface\\ChatFrame\\ChatFrameTab')
BattlefieldMinimap=NativeWindow('BattlefieldMinimap'); BattlefieldMinimapTab=NativeWindow('BattlefieldMinimapTab')
for i=1,12 do Named(BattlefieldMinimap,'BattlefieldMinimap'..i,'Interface\\WorldMap\\WarsongGulch\\WarsongGulch'..i,'BACKGROUND') end
Named(BattlefieldMinimap,'BattlefieldMinimapBackground','Interface\\BattlefieldFrame\\UI-BattlefieldMinimap-Border','BORDER')
BattlefieldMinimapOptions={opacity=.5}
for i=1,3 do
    local f=NativeWindow('MirrorTimer'..i); _G['MirrorTimer'..i]=f
    Named(f,'MirrorTimer'..i..'Border','Interface\\CastingBar\\UI-CastingBar-Border','OVERLAY')
    local bar=CreateFrame('StatusBar','MirrorTimer'..i..'StatusBar',f); _G['MirrorTimer'..i..'StatusBar']=bar
    bar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
end
''')
ns=lua.table()
files=[line.strip() for line in toc.splitlines() if line.strip().endswith('.lua') and not line.startswith('#')]
for name in ['EUI_BlizzardSkin_335.lua','EUI_SkinExtras_335.lua','EUI_LootRolls_335.lua']:
    assert name in files
    lua.execute((skin/name).read_text(encoding='utf-8-sig'),'EllesmereUIBlizzardSkin',ns)
lua.globals().BS=ns
lua.execute(r'''
-- Loot roll environment.
LOOT_ROLL_NEED='%s has selected Need for: %s'; LOOT_ROLL_GREED='%s has selected Greed for: %s'
LOOT_ROLL_DISENCHANT='%s has selected Disenchant for: %s'; LOOT_ROLL_PASSED='%s passed on: %s'
LOOT_ROLL_PASSED_AUTO='%s automatically passed on: %s because he cannot loot that item.'
LOOT_ROLL_NEED_SELF='You have selected Need for: %s'; LOOT_ROLL_PASSED_SELF='You passed on: %s'
NEED='Need'; GREED='Greed'; PASS='Pass'; ROLL_DISENCHANT='Disenchant'
RAID_CLASS_COLORS={MAGE={r=.4,g=.8,b=.9},PRIEST={r=1,g=1,b=1},WARRIOR={r=.8,g=.6,b=.4}}
function UnitName(u) if u=='player' then return 'Me' end; return u=='party1' and 'Alice' or nil end
function UnitClass(u) if u=='player' then return 'Mage','MAGE' end; return 'Priest','PRIEST' end
function GetNumRaidMembers() return 0 end
function GetNumPartyMembers() return 1 end
local links={[7]='|cffa335ee|Hitem:40395:0:0:0:0:0:0:0:80|h[Torch of Holy Fire]|h|r',[8]='|cffa335ee|Hitem:40395:0:0:0:0:0:0:0:80|h[Torch of Holy Fire]|h|r',
    [9]='|cff0070dd|Hitem:12345:0:0:0:0:0:0:0:80|h[Blue Thing]|h|r'}
function GetLootRollItemLink(id) return links[id] end
NUM_GROUP_LOOT_FRAMES=4
for i=1,4 do
    local f=CreateFrame('Frame','GroupLootFrame'..i,UIParent); _G['GroupLootFrame'..i]=f
    for _,s in ipairs({'RollButton','GreedButton','DisenchantButton','PassButton'}) do
        local b=CreateFrame('Button','GroupLootFrame'..i..s,f); _G['GroupLootFrame'..i..s]=b
        b:SetScript('OnEnter',function(self) GameTooltip:SetOwner(self); GameTooltip:SetText('native') end)
    end
end
function GameTooltip:SetOwner(o) self.owner=o; self.lines={} end
function GameTooltip:IsOwned(o) return self.owner==o end
function GameTooltip:SetText(t) self.lines={{t}} end
function GameTooltip:AddLine(t,r,g,b) table.insert(self.lines,{t,r,g,b}) end
-- Ace3 environment.
local ace={}
function ace:Create(kind)
    local w={type=kind,frame=CreateFrame('Button',nil,UIParent)}
    w.frame.normal=w.frame:CreateTexture(); w.frame.normal:SetTexture('Interface\\Buttons\\UI-Panel-Button-Up')
    w.frame.left=w.frame:CreateTexture(); w.frame.left:SetTexture('Interface\\Buttons\\UI-Panel-Button-Up')
    if kind=='CheckBox' then w.checkbg=w.frame:CreateTexture(); w.checkbg:SetTexture('Interface\\Buttons\\UI-CheckBox-Up'); w.highlight=w.frame:CreateTexture() end
    if kind=='Heading' then w.left=w.frame:CreateTexture(); w.right=w.frame:CreateTexture() end
    if kind=='Broken' then w.frame=nil end
    return w
end
function LibStub(name,silent) if name=='AceGUI-3.0' then return ace end end
AceLib=ace
''')
lua.execute(r'''
BS.addon:OnInitialize(); BS.addon:OnEnable()
local function Has(label) for _,spec in ipairs(BS.windows) do if spec.label==label then return spec end end end
for _,label in ipairs({'Barber Shop','PvP, Battlemasters & Arena Registrar','Battleground Score & Minimap','Help & GM Requests',
    'Breath/Fatigue Timers & Stopwatch','Debug Tools','Raid Pullouts','Battleground Capture Bar','GM Chat Status','Ace3 Config Windows'}) do assert(Has(label),label) end
for _,name in ipairs({'BarberShopFrame','PVPParentFrame','ArenaRegistrarFrame','PVPBannerFrame','WorldStateScoreFrame','RebuffedHelpFrame',
    'StopwatchFrame','TimeManagerFrame','ScriptErrorsFrame','EventTraceFrame','BattlefieldMinimap','MirrorTimer1'}) do
    local s=BS.states[_G[name]]; assert(s and s.active and s.panel:IsShown(),name..' not skinned')
end
-- Insets measured from FrameXML; classic PvP panels; compact bars without accent.
local score=BS.states[WorldStateScoreFrame].panel.point
assert(score[1]=='BOTTOMRIGHT' and score[4]==-114 and score[5]==70,'score inset')
assert(BS.states[PVPParentFrame].panel.point[4]==-32 and BS.states[PVPParentFrame].panel.point[5]==76,'PvP classic inset')
assert(BS.states[TimeManagerFrame].panel.point[4]==-48 and BS.states[TimeManagerFrame].panel.point[5]==4)
-- Raid Info is a small dialog inside the social spec: not the Friends window's classic inset.
local raidInfo=BS.states[RaidInfoFrame]; assert(raidInfo and raidInfo.active,'Raid Info not skinned')
assert(raidInfo.panel.point[1]=='BOTTOMRIGHT' and raidInfo.panel.point[4]==-2 and raidInfo.panel.point[5]==4,'Raid Info inset')
for _,name in ipairs({'MirrorTimer1','StopwatchFrame','BattlefieldMinimap','TicketStatusFrame'}) do assert(not BS.states[_G[name]].accent:IsShown(),name..' accent') end
assert(BS.states[BarberShopFrame].accent:IsShown())
-- PvP sheet art faded; portrait, banner emblems and currency symbols kept.
assert(PVPFrameBackground:GetAlpha()==0 and PVPFramePortrait:GetAlpha()==1)
assert(PVPBannerFrameEmblemTopLeft:GetAlpha()==1 and PVPBannerFrameEmblemTopLeft.texture,'emblem wiped')
assert(BattlefieldFrameHonorSymbol:GetAlpha()==1 and BattlefieldFrameHonorSymbol.texture,'honor symbol wiped')
assert(StopwatchTabFrameMiddle:GetAlpha()==0,'stopwatch tab art kept')
-- Minimap tiles above the fill, fill follows the native opacity.
local mm=BS.states[BattlefieldMinimap]
for i=1,12 do local t=_G['BattlefieldMinimap'..i]; assert(t:GetDrawLayer()=='BORDER' and t:GetAlpha()==1 and t.texture,'tile '..i) end
assert(BattlefieldMinimapBackground:GetAlpha()==0)
assert(math.abs(mm.panel.background.color[4]-.475)<1e-9,'minimap opacity')
-- Mirror timers: flat bar, fill on the bar itself, panel hugs the bar.
local mt=BS.states[MirrorTimer1]
assert(MirrorTimer1StatusBar.barTexture=='Interface\\Buttons\\WHITE8X8' and MirrorTimer1Border:GetAlpha()==0)
assert(mt.panel.background:GetAlpha()==0 and mt.barBg:IsShown() and mt.panel.point[2]==MirrorTimer1StatusBar)
-- Restore.
BS.SetValue('reskinTimers',false)
assert(MirrorTimer1StatusBar.barTexture=='Interface\\TargetingFrame\\UI-StatusBar' and not mt.barBg:IsShown() and MirrorTimer1Border:GetAlpha()==1)
BS.SetValue('reskinBattleground',false)
assert(BattlefieldMinimap1:GetDrawLayer()=='BACKGROUND' and BattlefieldMinimapBackground:GetAlpha()==1)
BS.SetValue('reskinTimers',true); BS.SetValue('reskinBattleground',true); assert(mt.active and mm.active)
''')
lua.execute(r'''
-- Raid pullouts (Blizzard_RaidUI loads on demand).
local pullout=CreateFrame('Button','RaidPullout1',UIParent)
RaidPullout1MenuBackdrop=CreateFrame('Frame','RaidPullout1MenuBackdrop',pullout)
RaidPullout1MenuBackdrop:SetBackdrop({bgFile='Interface\\Tooltips\\UI-Tooltip-Background'}); RaidPullout1MenuBackdrop:SetAlpha(.7)
local button=CreateFrame('Frame','RaidPullout1Button1',pullout)
button.healthbar=CreateFrame('StatusBar','RaidPullout1Button1HealthBar',button); button.healthbar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
RaidPullout1Button1HealthBarFrame=button.healthbar:CreateTexture(); RaidPullout1Button1HealthBarFrame:SetTexture('Interface\\RaidFrame\\UI-RaidFrame-HealthBar')
button.manabar=CreateFrame('StatusBar','RaidPullout1Button1ManaBar',button); button.manabar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
pullout.buttons={button}
NUM_RAID_PULLOUT_FRAMES=1
local updates=0
function RaidPullout_Update(frame) updates=updates+1; return 'native-update' end
BS.Apply()
assert(RaidPullout_Update(pullout)=='native-update' and updates==1,'pullout hook lost native return')
assert(RaidPullout1MenuBackdrop:GetBackdrop().bgFile=='Interface\\Buttons\\WHITE8X8' and RaidPullout1MenuBackdrop:GetAlpha()==1)
assert(button.healthbar.barTexture=='Interface\\Buttons\\WHITE8X8' and RaidPullout1Button1HealthBarFrame:GetAlpha()==0)
BS.SetValue('reskinRaidPullouts',false)
assert(RaidPullout1MenuBackdrop:GetBackdrop().bgFile=='Interface\\Tooltips\\UI-Tooltip-Background' and math.abs(RaidPullout1MenuBackdrop:GetAlpha()-.7)<1e-9)
assert(button.healthbar.barTexture=='Interface\\TargetingFrame\\UI-StatusBar' and RaidPullout1Button1HealthBarFrame:GetAlpha()==1)
BS.SetValue('reskinRaidPullouts',true); assert(button.manabar.barTexture=='Interface\\Buttons\\WHITE8X8')
-- Ace3: Create stays functional, widgets are styled once, errors stay contained.
local b=AceLib:Create('Button'); assert(b.type=='Button' and b.frame:GetBackdrop().bgFile=='Interface\\Buttons\\WHITE8X8')
assert(b.frame.normal:GetAlpha()==0 and b.frame.left:GetAlpha()==0)
local c=AceLib:Create('CheckBox'); assert(c.checkbg:GetAlpha()==0)
local h=AceLib:Create('Heading'); assert(h.left.texture=='Interface\\Buttons\\WHITE8X8')
assert(AceLib:Create('Broken').type=='Broken','skin error escaped')
-- A newer AceGUI replacing Create is wrapped again on the next refresh.
function AceLib:Create(kind) return {type=kind,frame=CreateFrame('Button',nil,UIParent),newer=true} end
BS.Apply(); local n=AceLib:Create('Button'); assert(n.newer and n.frame:GetBackdrop(),'newer AceGUI not wrapped')
BS.SetValue('reskinAce3',false); local off=AceLib:Create('Button'); assert(not off.frame:GetBackdrop(),'Ace3 skinned while off')
-- Battleground capture bar (created lazily by WorldStateAlwaysUpFrame_Update).
local art='Interface\\WorldStateFrame\\WorldState-CaptureBar'
NUM_EXTENDED_UI_FRAMES=0
function WorldStateAlwaysUpFrame_Update()
    local bar=CreateFrame('Frame','WorldStateCaptureBar1',UIParent); _G.WorldStateCaptureBar1=bar
    for _,s in ipairs({'LeftBar','RightBar','MiddleBar','LeftLine','RightLine','LeftIconHighlight','RightIconHighlight'}) do
        local t=bar:CreateTexture(); t.name='WorldStateCaptureBar1'..s; _G[t.name]=t; t:SetTexture(art); t:SetTexCoord(.82,1,0,.14)
    end
    WorldStateCaptureBar1LeftLine:SetWidth(3); WorldStateCaptureBar1RightLine:SetWidth(3)
    bar.frameArt=bar:CreateTexture(); bar.frameArt:SetTexture(art)
    local ind=CreateFrame('Frame','WorldStateCaptureBar1Indicator',bar); _G.WorldStateCaptureBar1Indicator=ind; ind:SetWidth(5); ind:SetHeight(18)
    ind.art=ind:CreateTexture(); ind.art:SetTexture(art)
    NUM_EXTENDED_UI_FRAMES=1
    return 'native-ws'
end
BS.Apply(); assert(WorldStateAlwaysUpFrame_Update()=='native-ws','capture hook lost native return')
local cap=WorldStateCaptureBar1
assert(WorldStateCaptureBar1LeftBar.texture=='Interface\\Buttons\\WHITE8X8' and select(3,WorldStateCaptureBar1LeftBar:GetVertexColor())==.95,'alliance zone')
assert(select(1,WorldStateCaptureBar1RightBar:GetVertexColor())==.9 and WorldStateCaptureBar1LeftLine:GetWidth()==1)
assert(cap.frameArt:GetAlpha()==0 and WorldStateCaptureBar1LeftIconHighlight:GetAlpha()==0,'capture art kept')
assert(WorldStateCaptureBar1Indicator.art.texture=='Interface\\Buttons\\WHITE8X8' and WorldStateCaptureBar1Indicator:GetWidth()==3)
BS.SetValue('reskinCaptureBar',false)
assert(WorldStateCaptureBar1LeftBar.texture==art and select(1,WorldStateCaptureBar1LeftBar:GetTexCoord())==.82 and cap.frameArt:GetAlpha()==1)
assert(WorldStateCaptureBar1Indicator:GetWidth()==5 and WorldStateCaptureBar1LeftLine:GetWidth()==3,'capture restore')
BS.SetValue('reskinCaptureBar',true); assert(WorldStateCaptureBar1MiddleBar.texture=='Interface\\Buttons\\WHITE8X8')
-- GM chat status (Blizzard_GMChatUI loads on demand): backdrop lives on the unnamed button.
GMChatStatusFrame=CreateFrame('Frame','GMChatStatusFrame',UIParent)
local textHost=CreateFrame('Frame',nil,GMChatStatusFrame)
local box=CreateFrame('Button',nil,GMChatStatusFrame); box:SetBackdrop({bgFile='Interface\\Tooltips\\UI-Tooltip-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border'})
local status=CreateFrame('Button','GMChatStatusFrameButton',GMChatStatusFrame)
TOOLTIP_DEFAULT_COLOR={r=1,g=1,b=1}; TOOLTIP_DEFAULT_BACKGROUND_COLOR={r=.09,g=.09,b=.19}
BS.Apply(); assert(box:GetBackdrop().bgFile=='Interface\\Buttons\\WHITE8X8' and not status:GetBackdrop() and not textHost:GetBackdrop())
BS.SetValue('reskinGMStatus',false); assert(box:GetBackdrop().edgeFile=='Interface\\Tooltips\\UI-Tooltip-Border')
BS.SetValue('reskinGMStatus',true); assert(box:GetBackdrop().bgFile=='Interface\\Buttons\\WHITE8X8')
-- Profile kill switch covers the extras too.
BS.SetValue('reskinAce3',true); BS.SetWindowsEnabled(false); assert(not BS.WindowSkinEnabled('reskinRaidPullouts') and not BS.WindowSkinEnabled('reskinAce3'))
assert(WorldStateCaptureBar1LeftBar.texture==art and box:GetBackdrop().edgeFile=='Interface\\Tooltips\\UI-Tooltip-Border','kill switch restores capture bar and GM status')
BS.SetWindowsEnabled(true)
''')
lua.execute(r'''
local R=BS.LootRolls
-- Pattern conversion handles positional tokens and magic characters.
local p,order=R.ToPattern('Para %2$s, %1$s escolheu (Necessidade).')
assert(p=='^Para (.+), (.+) escolheu %(Necessidade%)%.$' and order[1]==2 and order[2]==1)
-- Two frames with the same item, one different item.
R.Start(7); R.Start(8); R.Start(9)
GroupLootFrame1.rollID=7; GroupLootFrame1:Show(); GroupLootFrame2.rollID=8; GroupLootFrame2:Show(); GroupLootFrame3.rollID=9; GroupLootFrame3:Show()
local torch='|cffa335ee|Hitem:40395:0:0:0:0:0:0:0:80|h[Torch of Holy Fire]|h|r'
local blue='|cff0070dd|Hitem:12345:0:0:0:0:0:0:0:80|h[Blue Thing]|h|r'
local function Event(msg) BS.LootRolls.events:RunScript('OnEvent','CHAT_MSG_LOOT',msg) end
Event('Alice has selected Need for: '..torch)
Event('Alice has selected Greed for: '..torch)
Event('You have selected Need for: '..torch)
Event('Bob passed on: '..blue)
Event('Carl automatically passed on: '..blue..' because he cannot loot that item.')
Event('You passed on: '..blue)
Event('Somebody won: '..blue)
local function Text(frame,suffix) local fs=nil; for _,r in ipairs({_G[frame..suffix]:GetRegions()}) do if r.text~=nil or r.shown~=nil then fs=r end end; return fs end
local need1=Text('GroupLootFrame1','RollButton'); assert(need1 and need1.text==2 and need1:IsShown(),'need count')
local greed2=Text('GroupLootFrame2','GreedButton'); assert(greed2 and greed2.text==1,'second roll of the same item')
local pass3=Text('GroupLootFrame3','PassButton'); assert(pass3.text==3,'pass count incl. auto and self')
assert(BS.LootRolls.rolls[9].chosen['Me']=='pass' and BS.LootRolls.rolls[9].chosen['Carl']=='pass')
-- Tooltip lists names after the native text, in class colours.
GroupLootFrame1RollButton:RunScript('OnEnter')
local lines=GameTooltip.lines
assert(lines[1][1]=='native' and lines[2][1]=='Alice' and lines[3][1]=='Me','tooltip names')
assert(lines[2][2]==1 and lines[3][2]==.4,'class colours')
-- Toggle off hides counts; cancel clears the roll.
BS.SetValue('lootRollShowChoices',false); assert(not need1:IsShown())
BS.SetValue('lootRollShowChoices',true); assert(need1:IsShown())
BS.LootRolls.events:RunScript('OnEvent','CANCEL_LOOT_ROLL',7); assert(BS.LootRolls.rolls[7]==nil and not need1:IsShown())
''')
print('PASS: barber/PvP/arena registrar/battleground score/help/stopwatch/time manager/debug windows skinned with FrameXML insets; '
      'PvP portraits, emblems and currency symbols kept; minimap tiles above the fill with native opacity; mirror timer flat bars; '
      'raid pullouts and Ace3 widgets styled and restored, newer AceGUI rewrapped; loot roll choices parsed (self, auto-pass, positional), '
      'counted per roll, listed in class-coloured tooltips, hidden when off and cleared on cancel.')
