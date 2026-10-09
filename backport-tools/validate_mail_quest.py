"""Mail counts remain above icons; dark quest/gossip text stays legible."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
for file in ['backport-tools/wrath_mock.lua','backport-tools/blizzardskin_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/file).read_text(encoding='utf-8-sig'))
lua.execute('''
EllesmereUIDB={}; MailFrame=NativeWindow('MailFrame'); OpenMailFrame=NativeWindow('OpenMailFrame')
SendMailFrame=CreateFrame('Frame','SendMailFrame',MailFrame)
mailButtons={}
for i,name in ipairs({'MailItem1Button','SendMailAttachment1','OpenMailAttachmentButton1'}) do
 local parent=i==3 and OpenMailFrame or i==2 and SendMailFrame or MailFrame
 local b=NativeButton(name,parent); local icon=b:CreateTexture(); icon:SetTexture('Interface\\\\Icons\\\\INV_Potion_01'); icon:SetDrawLayer('BORDER')
 _G[name..'IconTexture']=icon; b.icon=icon
 local count=b:CreateFontString(); _G[name..'Count']=count; b.count=count; count:SetText('20'); count:SetDrawLayer(i==3 and 'BORDER' or i==2 and 'ARTWORK' or 'OVERLAY'); count:SetTextColor(.2,.2,.2,1)
 b:SetScript('OnReceiveDrag',function() mailDragged=true end); mailButtons[i]=b
end
SendMailFrame:SetFrameLevel(5)
SendMailNameEditBox=CreateFrame('EditBox','SendMailNameEditBox',SendMailFrame); SendMailNameEditBox:SetFrameLevel(6)
SendMailScrollFrame=CreateFrame('ScrollFrame','SendMailScrollFrame',SendMailFrame); SendMailScrollFrame:SetFrameLevel(6)
SendMailBodyEditBox=CreateFrame('EditBox','SendMailBodyEditBox',SendMailScrollFrame); SendMailBodyEditBox:SetFrameLevel(7)
function OpenMail_UpdateAttachments() mailButtons[3].count:SetText('7'); return 'native-mail' end
GossipFrame=NativeWindow('GossipFrame'); QuestFrame=NativeWindow('QuestFrame')
gossip=NativeButton('GossipTitleButton1',GossipFrame); gossip.label:SetText('|cff6e5900Dark Quest|r'); gossip.label:SetTextColor(.43,.35,0,1)
quest=NativeButton('QuestTitleButton1',QuestFrame); quest.label:SetText('Quest title'); quest.label:SetTextColor(.4,.3,0,1)
function GossipFrameUpdate() gossip.label:SetText('|cff000000New Quest|r'); gossip.label:SetTextColor(0,0,0,1); return 'native-gossip' end
''')
ns=lua.table(); lua.globals().BS=ns
lua.execute((root/'EllesmereUIBlizzardSkin/EUI_BlizzardSkin_335.lua').read_text(encoding='utf-8-sig'),'EllesmereUIBlizzardSkin',ns)
lua.execute('''
BS.addon:OnInitialize(); BS.addon:OnEnable()
local insets=BS.states[MailFrame].insets
local to,scroll=insets[SendMailNameEditBox],insets[SendMailScrollFrame]
assert(to and to.panel:IsShown() and to.panel:GetFrameLevel()==6,'Send Mail To box border must not sit under the sheet fill')
assert(scroll and scroll.panel:IsShown() and scroll.panel:GetFrameLevel()==6,'Send Mail body box')
assert(not insets[SendMailBodyEditBox],'Scrolled mail body is framed by its scroll frame, not a one-line box')
for _,b in ipairs(mailButtons) do assert(b.count:GetDrawLayer()=='OVERLAY' and b.icon:GetDrawLayer()=='ARTWORK' and b.count:GetText()=='20' and b.count.textColor[1]==1) end
assert(OpenMail_UpdateAttachments()=='native-mail'); BS.events:RunScript('OnUpdate',.3); assert(mailButtons[3].count:GetText()=='7' and mailButtons[3].count:GetDrawLayer()=='OVERLAY')
mailButtons[2]:RunScript('OnReceiveDrag'); mailButtons[3]:RunScript('OnClick'); assert(mailDragged and mailButtons[3].nativeClicks==1)
mailButtons[2].count:SetText(''); mailButtons[2].count:Hide(); BS.Apply(); assert(mailButtons[2].count:GetText()=='' and not mailButtons[2].count:IsShown())
assert(gossip.label.textColor[1]>.75 and not gossip.label:GetText():find('|cff6e5900',1,true) and quest.label.textColor[1]>.75)
assert(GossipFrameUpdate()=='native-gossip'); BS.events:RunScript('OnUpdate',.3)
assert(not gossip.label:GetText():find('|cff000000',1,true) and gossip.label.textColor[1]>=.75)
gossip:RunScript('OnClick'); assert(gossip.nativeClicks==1)
local before=#allFrames; BS.Apply(); BS.Apply(); assert(before==#allFrames)
combat=true; BS.SetValue('reskinMail',false); assert(mailButtons[3].count:GetDrawLayer()=='OVERLAY')
combat=false; BS.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(mailButtons[3].count:GetDrawLayer()=='BORDER' and mailButtons[3].count.textColor[1]==.2)
BS.SetValue('reskinGossip',false); BS.SetValue('reskinQuest',false)
assert(gossip.label:GetText()=='|cff000000New Quest|r' and gossip.label.textColor[1]==.43 and quest.label.textColor[1]==.4)
''')
print('PASS: inbox/send/open native mail counts, icon layering, update hooks/returns, actions, empty counts, dark quest/gossip colors including inline codes, refresh, reuse and combat-safe restoration.')
