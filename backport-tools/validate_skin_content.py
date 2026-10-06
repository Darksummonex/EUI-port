"""Reported currency/LFD/talent content and native overlapping tab margins."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
for name in ['backport-tools/wrath_mock.lua','backport-tools/blizzardskin_mock.lua','backport-tools/character_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/name).read_text(encoding='utf-8-sig'))
lua.execute('''
CreateCharacterFixture(); EllesmereUIDB={}
TokenFrame=CreateFrame('Frame','TokenFrame',CharacterFrame); TokenFrame:Hide()
TokenFrameContainer=CreateFrame('ScrollFrame','TokenFrameContainer',TokenFrame)
TokenFrameContainer.buttons={}
for i=1,3 do
    local b=NativeButton('TokenFrameContainerButton'..i,TokenFrameContainer); TokenFrameContainer.buttons[i]=b
    b.icon=b:CreateTexture(); b.icon:SetTexture('Interface\\\\Icons\\\\INV_Misc_Coin_02'); b.icon:SetDrawLayer('BACKGROUND')
    b.label:SetText('Currency '..i); b.label:SetTextColor(.1,.1,.1,1)
end
LFDParentFrame=NativeWindow('LFDParentFrame')
LFDQueueFrameRandomScrollFrame=CreateFrame('ScrollFrame','LFDQueueFrameRandomScrollFrame',LFDParentFrame)
LFDQueueFrameRandomScrollFrameChildFrame=CreateFrame('Frame','LFDQueueFrameRandomScrollFrameChildFrame',LFDQueueFrameRandomScrollFrame)
local reward=CreateFrame('Button','LFDQueueFrameRandomScrollFrameChildFrameItem1',LFDQueueFrameRandomScrollFrameChildFrame)
LFDTestReward=reward; reward.iconTexture=reward:CreateTexture(); reward.iconTexture:SetTexture('Interface\\\\Icons\\\\INV_Misc_Coin_02'); reward.iconTexture:SetDrawLayer('BACKGROUND')
reward.label=reward:CreateFontString(); reward.label:SetText('Valor'); reward.label:SetTextColor(.1,.1,.1,1)
reward.normal=reward:CreateTexture(); reward.normal:SetTexture('Interface\\\\Buttons\\\\UI-Quickslot2')
reward:SetScript('OnEnter',function() nativeRewardTooltip=true end)
PlayerTalentFramePointsBar=CreateFrame('Frame','PlayerTalentFramePointsBar',PlayerTalentFrame)
PlayerTalentFramePointsBar:SetPoint('BOTTOMLEFT',PlayerTalentFrame,'BOTTOMLEFT',0,50)
for i,label in ipairs({'Affliction','Demonology','Destruction','Glyphs'}) do
    local b=NativeButton('PlayerTalentFrameTab'..i,PlayerTalentFrame); b.id=i; b.label:SetText(label)
    b.normal:SetTexture('Interface\\\\CharacterFrame\\\\UI-Character-Tab-Left')
    b:SetWidth(100); b:ClearAllPoints(); b:SetPoint('BOTTOMLEFT',PlayerTalentFrame,'BOTTOMLEFT',(i-1)*85,4)
end
PlayerTalentFrameTalent1=CreateFrame('Button','PlayerTalentFrameTalent1',PlayerTalentFrame)
PlayerTalentFrameTalent1IconTexture=PlayerTalentFrameTalent1:CreateTexture(); PlayerTalentFrameTalent1IconTexture:SetTexture('Interface\\\\Icons\\\\Spell_Shadow_CurseOfSargeras'); PlayerTalentFrameTalent1IconTexture:SetDrawLayer('BORDER')
PlayerTalentFrameTalent1.normal=PlayerTalentFrameTalent1:CreateTexture(); PlayerTalentFrameTalent1.normal:SetTexture('Interface\\\\Buttons\\\\UI-Quickslot2')
PlayerTalentFrameTalent1:SetScript('OnClick',function() talentLearned=true end)
-- Native footer tabs commonly place adjacent logical buttons 15px apart
-- inside their transparent margins (also used by installed Wrath ElvUI).
otherTabs={}
for _,name in ipairs({'MerchantFrame','FriendsFrame','GuildBankFrame','AuctionFrame','InspectFrame','AchievementFrame','InterfaceOptionsFrame'}) do
    local frame=_G[name] or NativeWindow(name); _G[name]=frame
    local tabs={}
    for i=1,2 do local b=NativeButton(name..'Tab'..i,frame); b.id=i; b.label:SetText('Tab '..i); b.normal:SetTexture('Interface\\\\CharacterFrame\\\\UI-Character-Tab-Left'); b:ClearAllPoints(); b:SetPoint('BOTTOMLEFT',frame,'BOTTOMLEFT',(i-1)*85,4); tabs[i]=b end
    frame.selectedTab=2; otherTabs[#otherTabs+1]={frame=frame,tabs=tabs}
end
FriendsTabHeaderTab1=NativeButton('FriendsTabHeaderTab1',FriendsFrame)
FriendsTabHeaderTab1.normal:SetTexture('Interface\\\\CharacterFrame\\\\UI-Character-Tab-Left')
''')
ns=lua.table()
for name in ['EUI_BlizzardSkin_335.lua','EUI_CharacterSheet_335.lua']:
    lua.execute((root/'EllesmereUIBlizzardSkin'/name).read_text(encoding='utf-8-sig'),'EllesmereUIBlizzardSkin',ns)
lua.globals().BS=ns
lua.execute('''
BS.addon:OnInitialize(); BS.addon:OnEnable()
local function Uncovered(s,button,icon)
    local panel=s.buttons[button].panel
    assert(not panel:GetBackdrop().bgFile,'Filled child panel can obscure content')
    assert(panel.background:GetParent()==button and panel.background:GetDrawLayer()=='BACKGROUND')
    assert(icon:GetDrawLayer()=='ARTWORK' and icon:GetTexture(),'Content icon lost')
end
local l=BS.states[LFDParentFrame]; Uncovered(l,LFDTestReward,LFDTestReward.iconTexture)
assert(LFDTestReward.label.textColor[1]==.9); LFDTestReward:RunScript('OnEnter'); assert(nativeRewardTooltip)
local t=BS.states[PlayerTalentFrame]; Uncovered(t,PlayerTalentFrameTalent1,PlayerTalentFrameTalent1IconTexture)
PlayerTalentFrameTalent1:RunScript('OnClick'); assert(talentLearned)
local right=0
for i=1,4 do local tab=_G['PlayerTalentFrameTab'..i]; assert(tab:GetID()==i and select(4,tab:GetPoint())>=right,'Talent tabs overlap'); right=select(4,tab:GetPoint())+tab:GetWidth()+6 end
assert(select(5,PlayerTalentFramePointsBar:GetPoint())>select(5,PlayerTalentFrameTab1:GetPoint())+PlayerTalentFrameTab1:GetHeight())
-- Close button and points footer stop at the scroll bar limit, inside the fill.
local close,barPoint,fill=PlayerTalentFrameCloseButton.point,PlayerTalentFramePointsBar.point,t.panel.point
assert(close[1]=='TOPRIGHT' and close[2]==PlayerTalentFrame and barPoint[1]=='BOTTOMRIGHT','Close/footer anchors')
assert(close[4]==barPoint[4] and close[4]<fill[4],'Close button and footer must end at the scroll bar, inside the fill')
-- Tab fills live on the button's BACKGROUND layer; the native tab art fade must not clear them.
for i=1,4 do local bg=t.buttons[_G['PlayerTalentFrameTab'..i]].panel.background
    assert(bg:GetTexture() and bg:GetAlpha()>0 and bg:IsShown(),'Talent tab background cleared') end
for _,entry in ipairs(otherTabs) do local bg=BS.states[entry.frame].buttons[entry.tabs[1]].panel.background
    assert(bg:GetTexture() and bg:GetAlpha()>0,'Tab background cleared') end
for _,entry in ipairs(otherTabs) do
    local s=BS.states[entry.frame]
    local a,b=entry.tabs[1],entry.tabs[2]
    assert(s.buttons[a].panel.point[4]==-10 and s.buttons[b].panel.point[4]==-10)
    assert(select(4,a:GetPoint())+a:GetWidth()-10 < select(4,b:GetPoint())+10,'Native tab borders overlap')
    assert(s.buttons[b].panel.borderColor[2]>.5 and s.buttons[a].panel.borderColor[2]==.25,'Selection indicator wrong')
    assert(a:GetWidth()==100 and a:GetID()==1 and select(4,b:GetPoint())==85,'Skin changed native tab geometry')
end
assert(BS.states[FriendsFrame].buttons[FriendsTabHeaderTab1])
-- Currency uses native sheet size/header, expanded paper doll only its tab.
PaperDollFrame:Hide(); TokenFrame:Show(); BS.RequestRefresh(); BS.events:RunScript('OnUpdate',.3)
local c=BS.states[CharacterFrame]
assert(CharacterFrame:GetWidth()==384 and not c.character.enhanced and not c.character.header:IsShown())
for _,b in ipairs(TokenFrameContainer.buttons) do Uncovered(c,b,b.icon); assert(b.label.textColor[1]==.9) end
-- Updates loaded after module initialization get hooks, preserve native
-- return values, and reapply currency text/LFD icons after native refresh.
function TokenFrame_Update() for _,b in ipairs(TokenFrameContainer.buttons) do b.label:SetTextColor(.1,.1,.1,1) end; return 'currency-result' end
function TokenFrameContainer.update() return TokenFrame_Update() end
function LFDQueueFrameRandom_UpdateFrame() LFDTestReward.label:SetTextColor(.1,.1,.1,1); return 'reward-result' end
BS.events:RunScript('OnEvent','ADDON_LOADED'); BS.events:RunScript('OnUpdate',.3)
assert(TokenFrameContainer.update()=='currency-result' and LFDQueueFrameRandom_UpdateFrame()=='reward-result')
BS.events:RunScript('OnUpdate',.3); assert(TokenFrameContainer.buttons[1].label.textColor[1]==.9 and LFDTestReward.label.textColor[1]==.9)
local count=#allFrames; BS.Apply(); BS.Apply(); assert(#allFrames==count)
local nativeTalentX=0
combat=true; BS.SetValue('reskinPlayerSpells',false); assert(t.active)
combat=false; BS.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(not t.active and PlayerTalentFrameTalent1IconTexture:GetDrawLayer()=='BORDER' and select(4,PlayerTalentFrameTab2:GetPoint())==85 and PlayerTalentFrameTab2:GetWidth()==100)
assert(PlayerTalentFrameCloseButton:GetPoint()=='CENTER','Close button geometry not restored')
BS.SetValue('reskinLFGMenu',false); assert(LFDTestReward.iconTexture:GetDrawLayer()=='BACKGROUND' and not l.buttons[LFDTestReward].panel.background:IsShown())
BS.SetValue('themedCharacterSheet',false); assert(TokenFrameContainer.buttons[1].icon:GetDrawLayer()=='BACKGROUND' and TokenFrameContainer.buttons[1].label.textColor[1]==.1)
BS.SetValue('themedCharacterSheet',true); TokenFrame:Hide(); PaperDollFrame:Show(); BS.Apply(); assert(c.character.enhanced and CharacterFrame:GetWidth()==660)
''')
print('PASS: currency native sizing/text/icons, dungeon reward icons/tooltips/LOD refresh, talent icons/clicks/tab spacing, close button and footer at the scroll bar limit, tab backgrounds kept, native tab padding/selection across seven windows, combat deferral, layer/geometry restoration and frame reuse.')
