"""Real Chat module/Core lifecycle and native FrameXML entry points on Lua 5.1."""
from pathlib import Path
import sys,re
root=Path(__file__).resolve().parents[1]
retail=Path('D:/World of Warcraft/_retail_/Interface/AddOns/EllesmereUIChat')
for original in retail.rglob('*'):
    if original.is_file() and original.suffix.lower()!='.toc':
        assert original.read_bytes()==(root/'EllesmereUIChat'/original.relative_to(retail)).read_bytes(),original
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
def native_function(file,name):
    source=(root/'backport-tools/framexml-chat'/file).read_text(encoding='utf-8-sig')
    match=re.search(r'^function '+name+r'\(.*?(?=^function |\Z)',source,re.M|re.S)
    assert match,name
    # Keep just the complete top-level body, not later file-scope statements.
    return match[0].split('\nend',1)[0]+'\nend'
for file,name in [('ChatFrame.lua','ChatFrame_OnHyperlinkShow'),('FloatingChatFrame.lua','FloatingChatFrame_OnMouseScroll'),('FloatingChatFrame.lua','FCF_SetChatWindowFontSize'),('FloatingChatFrame.lua','FCF_SetWindowAlpha'),('FloatingChatFrame.lua','FCF_SetWindowColor'),('FloatingChatFrame.lua','FCFTab_UpdateColors'),('FloatingChatFrame.lua','FCF_Tab_OnClick')]:
    lua.execute(native_function(file,name))
lua.execute((root/'backport-tools/chat_mock.lua').read_text())
lua.execute('''
-- Confirm the fixture reproduces the native 50px bottom limit before styling.
ChatFrame1:ClearAllPoints(); ChatFrame1:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',40,0)
assert(ChatFrame1:GetBottom()==50)
ChatFrame1:ClearAllPoints(); ChatFrame1:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',40,60)
''')
# Load the actual Core library; its dispatcher exposes the Lua 5.1 self issue.
core=(root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
lua.execute(core)
lua.execute('lifecycleErrors={}; function geterrorhandler() return function(err) lifecycleErrors[#lifecycleErrors+1]=err end end')
safe_source='local function errorhandler('+core.split('local function errorhandler(',1)[1].split('\n-------------------------------------------------------------------------------',1)[0]
safe=lua.execute(safe_source+'\nreturn safecall')
ns=lua.table()
loader=lua.eval('function(s,n) return assert(loadstring(s,n)) end')
loader((root/'EllesmereUIChat/EUI_Chat_335.lua').read_text(),'EUI_Chat_335.lua')('EllesmereUIChat',ns)
lua.globals().CHAT=ns
safe(ns.addon.OnInitialize,ns.addon); safe(ns.addon.OnEnable,ns.addon)
lua.execute('assert(#lifecycleErrors==0,lifecycleErrors[1])')
lua.execute('''
local p=CHAT.GetSettings()
assert(p.enabled and _ECHAT_DB==CHAT.addon.db and unlockFolder=="EllesmereUIChat")
assert(ChatFrame1:GetWidth()==420 and ChatFrame1:GetHeight()==180)
assert(ChatFrame1:IsClampedToScreen() and select(4,ChatFrame1:GetClampRectInsets())==0)
assert(select(1,ChatFrame1:GetClampRectInsets())==-35 and select(2,ChatFrame1:GetClampRectInsets())==35 and select(3,ChatFrame1:GetClampRectInsets())==38)
assert(CHAT.states[ChatFrame1].clampInsets[4]==-50)
assert(ChatFrame1Background:GetAlpha()==0 and not ChatFrame1:GetFading())
assert(select(2,ChatFrame1:GetFont())==12 and select(3,ChatFrame1:GetFont())=="OUTLINE")
assert(not ChatFrame1EditBox:HasFocus() and not ChatFrame1EditBox:IsAutoFocus())
ChatFrame1EditBox:RunScript("OnEnterPressed"); assert(nativeSent==1)
ChatFrame1:RunScript("OnEvent"); assert(nativeEvents==1)
ChatFrame1.buttonFrame:RunScript("OnMouseDown"); assert(nativeButtonClicks==1)
local originalLink="|cff00ff00|Hitem:123:0:0|h[www.item-name.com]|h|r"
assert(CHAT.LinkURLs(originalLink)==originalLink)
assert(CHAT.LinkURLs("|Twww.icon:16|t")=="|Twww.icon:16|t")
local url=CHAT.LinkURLs("visit https://example.com/a?b=2, and www.site.org!")
assert(url=="visit |Heuiurl:https://example.com/a?b=2|h[https://example.com/a?b=2]|h, and |Heuiurl:www.site.org|h[www.site.org]|h!")
assert(CHAT.LinkURLs(url)==url)
assert(CHAT.PlainText(originalLink)=="[www.item-name.com]")
assert(ChatFrame1:AddMessage("hello https://example.com",.2,.3,.4,17)=="native-result")
local message=ChatFrame1.messages[1]
assert(message[1]:find("[13:07]",1,true) and message[1]:find("|Heuiurl:",1,true))
assert(message[2]==.2 and message[3]==.3 and message[4]==.4 and message[5]==17)
ChatFrame2:AddMessage("combat https://example.com"); assert(ChatFrame2.messages[1][1]=="combat https://example.com")
ChatFrame1:RunScript("OnHyperlinkClick","item:123",originalLink,"LeftButton")
assert(itemRef[1]=="item:123" and itemRef[4]==ChatFrame1)
ChatFrame1:RunScript("OnHyperlinkClick","euiurl:https://example.com","url","LeftButton")
assert(CHAT.copyWindow.box:GetText()=="https://example.com" and CHAT.copyWindow.box:HasFocus())
CHAT.copyWindow.box:RunScript("OnEscapePressed")
assert(not CHAT.copyWindow:IsShown() and not CHAT.copyWindow.box:HasFocus())
CHAT.CopyChat(ChatFrame1)
assert(CHAT.copyWindow.box:GetText()=="[13:07] hello [https://example.com]")
CHAT.copyWindow:Hide(); assert(not CHAT.copyWindow.box:HasFocus())
ChatFrame1:RunScript("OnMouseWheel",1); assert(ChatFrame1.scroll=="up")
shift=true; ChatFrame1:RunScript("OnMouseWheel",-1); assert(ChatFrame1.scroll=="bottom"); shift=false
FCF_SetChatWindowFontSize(nil,ChatFrame1,20)
assert(select(2,ChatFrame1:GetFont())==12 and savedFontSize[2]==20)
FCF_SetWindowAlpha(ChatFrame1,.9); assert(ChatFrame1Background:GetAlpha()==0 and savedAlpha[2]==.9)
FCF_SetWindowColor(ChatFrame1,.5,.6,.7); assert(ChatFrame1Background:GetAlpha()==0)
local temp=FCF_OpenTemporaryWindow(); assert(CHAT.states[temp])
assert(select(4,temp:GetClampRectInsets())==0 and select(3,temp:GetClampRectInsets())==26)
temp:AddMessage("private"); assert(temp.messages[1][1]:find("private",1,true))
p.hideButtons=true; CHAT.Apply(); assert(not ChatFrame1.buttonFrame:IsShown())
ChatFrame1.buttonFrame:Show(); assert(not ChatFrame1.buttonFrame:IsShown())
p.hideButtons=false; CHAT.Apply(); assert(ChatFrame1.buttonFrame:IsShown())
p.inputOnTop=true; CHAT.Apply(); assert(ChatFrame1EditBox:GetPoint(1)=="BOTTOMLEFT")
unlockElements[1].savePos(nil,"CENTER","BOTTOMLEFT",500,250); CHAT.Apply(); assert(ChatFrame1:GetPoint(1)=="CENTER")
-- Live drag can reach Y=0 and its saved anchor survives profile/world reapply.
ChatFrame1:ClearAllPoints(); ChatFrame1:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',40,0)
assert(ChatFrame1:GetBottom()==0)
unlockElements[1].savePos(nil,'BOTTOMLEFT','BOTTOMLEFT',40,0); CHAT.Apply()
CHAT.events:RunScript('OnEvent','PLAYER_ENTERING_WORLD')
assert(unlockElements[1].loadPos().y==0 and ChatFrame1:GetBottom()==0)
-- A native reset is corrected on show without modifying the other margins.
ChatFrame1:SetClampRectInsets(-35,35,38,-50); ChatFrame1:Hide(); ChatFrame1:Show()
assert(ChatFrame1:GetBottom()==0 and select(4,ChatFrame1:GetClampRectInsets())==0)
ChatFrame1:SetClampRectInsets(-35,35,38,-50); combat=true; ChatFrame1:Hide(); ChatFrame1:Show()
assert(select(4,ChatFrame1:GetClampRectInsets())==-50)
combat=false; CHAT.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED')
assert(ChatFrame1:GetBottom()==0 and select(4,ChatFrame1:GetClampRectInsets())==0)
unlockElements[1].savePos(nil,'CENTER','BOTTOMLEFT',500,250); CHAT.Apply()
combat=true; p.width=550; CHAT.Apply(); assert(ChatFrame1:GetWidth()==420)
CHAT.ResetPosition(); assert(ChatFrame1:GetPoint(1)=="CENTER")
combat=false; CHAT.events:RunScript("OnEvent","PLAYER_REGEN_ENABLED")
assert(ChatFrame1:GetWidth()==550 and ChatFrame1:GetPoint(1)=="BOTTOMLEFT")
local db=CHAT.addon.db; CHAT.addon.db=nil
assert(unlockElements[1].loadPos()==nil and unlockElements[1].isHidden())
unlockElements[1].savePos(nil,"CENTER","CENTER",1,1); unlockElements[1].clearPos(); unlockElements[1].applyPos()
CHAT.addon.db=db
-- A later addon wraps our AddMessage bridge. Re-apply must not recurse.
local previous=ChatFrame1.AddMessage
local later=function(self,...) return previous(self,...) end
ChatFrame1.AddMessage=later; CHAT.Apply(); ChatFrame1:AddMessage("later wrapper")
p.enabled=false; CHAT.Apply()
assert(ChatFrame1.AddMessage==later and ChatFrame1:GetWidth()==380 and ChatFrame1:GetHeight()==160)
assert(select(4,ChatFrame1:GetClampRectInsets())==-50 and select(3,ChatFrame1:GetClampRectInsets())==38 and ChatFrame1:IsClampedToScreen())
assert(select(4,temp:GetClampRectInsets())==-50 and select(3,temp:GetClampRectInsets())==26)
assert(ChatFrame1:GetFading() and ChatFrame1:GetTimeVisible()==75 and ChatFrame1Background:GetAlpha()==.7)
assert(ChatFrame1:GetScript("OnHyperlinkClick")==ChatFrame_OnHyperlinkShow)
assert(ChatFrame1:GetScript("OnMouseWheel")==FloatingChatFrame_OnMouseScroll)
ChatFrame1:AddMessage("disabled https://example.com"); assert(ChatFrame1.messages[#ChatFrame1.messages][1]=="disabled https://example.com")
p.enabled=true; CHAT.Apply(); ChatFrame1:AddMessage("re-enabled")
assert(select(4,ChatFrame1:GetClampRectInsets())==0 and select(4,temp:GetClampRectInsets())==0)
assert(ChatFrame1.messages[#ChatFrame1.messages][1]:find("[13:07]",1,true))
-- The copy buffer can exceed the native scrollback limit and follows Clear.
p.copyLines=50
for i=1,65 do ChatFrame1:AddMessage("buffer "..i) end
assert(#CHAT.states[ChatFrame1].lines==50)
ChatFrame1:Clear(); assert(#CHAT.states[ChatFrame1].lines==0)
ChatFrame1:AddMessage("after clear")
CHAT.CopyChat(ChatFrame1); assert(CHAT.copyWindow.box:GetText()=="[13:07] after clear"); CHAT.copyWindow:Hide()
SlashCmdList.EUI335CHAT(); assert(optionsLoaded and shownModule=="EllesmereUIChat")
assert(not ChatFrame1.scripts.OnKeyDown and not ChatFrame1EditBox.scripts.OnKeyDown)
assert(_ECHAT_RefreshAll==CHAT.Apply)
-- Native left/right tab actions still select windows and open their menu.
local mainSkin=CHAT.states[ChatFrame1]
local secondSkin=CHAT.states[ChatFrame2]
FCF_SelectDockFrame(ChatFrame1)
assert(mainSkin.tabLine:IsShown() and not secondSkin.tabLine:IsShown())
ChatFrame2Tab:RunScript("OnClick","LeftButton")
assert(SELECTED_DOCK_FRAME==ChatFrame2 and secondSkin.tabLine:IsShown() and not mainSkin.tabLine:IsShown())
assert(ChatFrame2Tab.leftSelectedTexture:IsShown() and ChatFrame2Tab.leftSelectedTexture:GetAlpha()==0)
ChatFrame2Tab:RunScript("OnClick","RightButton")
assert(CURRENT_CHAT_FRAME_ID==2 and dropDownArgs[4]=="ChatFrame2Tab")
local scrollButton=ChatFrame1ButtonFrameUpButton
local scrollSkin=mainSkin.squareButtons[scrollButton]
assert(scrollSkin and scrollSkin.panel:IsShown() and scrollButton:GetNormalTexture():GetAlpha()==0)
scrollButton:RunScript("OnClick"); assert(nativeButtonClicks==2)
p.squareSkin=false; CHAT.Apply()
assert(not mainSkin.tabPanel:IsShown() and ChatFrame1Tab.leftTexture:GetAlpha()==.7)
assert(not scrollSkin.panel:IsShown() and scrollButton:GetNormalTexture():GetAlpha()==.7)
p.squareSkin=true; CHAT.Apply()
assert(mainSkin.tabPanel:IsShown() and scrollSkin.panel:IsShown())
p.enabled=false; CHAT.Apply(); assert(not mainSkin.tabPanel:IsShown() and scrollButton:GetNormalTexture():GetAlpha()==.7)
p.enabled=true; CHAT.Apply()
''')
# Build module pages and mutate real options controls.
lua.execute('''
IsLoggedIn=function() return true end
rows={}; buttons={}
function EllesmereUI:ToggleUnlockMode() unlockOpened=true end
EllesmereUI.Widgets={
    DualRow=function(_,parent,y,left,right) rows[#rows+1]={left,right}; return {},50 end,
    SectionHeader=function() return {},30 end,
    WideButton=function(_,parent,text,y,fn) buttons[text]=fn; return {},40 end,
}
''')
lua.execute((root/'EllesmereUIOptions/EUI_Chat_335_Options.lua').read_text())
lua.execute('''
assert(testModule and #testModule.pages==2)
for _,page in ipairs(testModule.pages) do assert(testModule.buildPage(page,UIParent,0)>0) end
rows={}; testModule.buildPage("Fonts",UIParent,0)
rows[1][1].setValue("native"); rows[1][2].setValue(16)
assert(select(1,ChatFrame1:GetFont())=="native.ttf" and select(2,ChatFrame1:GetFont())==16)
rows={}; testModule.buildPage("Chat",UIParent,0)
rows[3][1].setValue(.4); assert(CHAT.states[ChatFrame1].panel.bgColor[4]==.4)
buttons["Copy Current Chat Window"](); assert(CHAT.copyWindow:IsShown()); CHAT.copyWindow:Hide()
buttons["Unlock Mode"](); assert(unlockOpened)
rows[1][1].setValue(false); assert(not CHAT.states[ChatFrame1].panel:IsShown())
rows[1][1].setValue(true)
''')
for file,next_card in [('EUI_Fonts_Options.lua','TileMythicTimer'),('EUI_Textures_Options.lua','TileQoL')]:
    source=(root/'EllesmereUIOptions'/file).read_text(encoding='utf-8-sig')
    body=source.split('local function TileChat(',1)[1].split('local function '+next_card+'(',1)[0]
    card=lua.execute('''local NS=function(folder) return EllesmereUI._ModuleNS[folder] end
local ModuleOutlineCfg=function() return {type="dropdown"} end
local BLANK=function() return {type="label"} end
local NoteRow=function(_,y) return y-30 end
local LinkRow=function(_,y,_,_,page) assert(page=="Chat"); return y-30 end
local function TileChat('''+body+'\nreturn TileChat')
    lua.globals().cardBuilder=card
    lua.execute('rows={}; assert(cardBuilder(UIParent,0,EllesmereUI.Widgets,{folder="EllesmereUIChat",display="Chat"})<0)')
    if file=='EUI_Fonts_Options.lua':
        lua.execute('rows[1][2].setValue("native"); rows[2][1].setValue("thick"); assert(select(3,ChatFrame1:GetFont())=="THICKOUTLINE")')
print('PASS: real Core Lite/Chat and native Wrath entry points; native input/messages/links/copy/focus/wheel; chat Y=0 drag/saved reapply/native refresh, preserved side/top clamps and restored bottom margin; temporary windows, combat deferral, unlock, restore/re-enable/external wrappers and module/shared options. Native rendering and taint require in-game confirmation.')
