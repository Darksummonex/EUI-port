"""Uninstall EUI (Wrath): tracked CVars, chat font sizes and Quickdraw keys go back only while
they still hold EllesmereUI's values; fresh vs pre-record accounts; addons turned off; module wiring."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime

toc=(root/'EllesmereUI/EllesmereUI.toc').read_text(encoding='utf-8-sig')
assert 'EllesmereUI_Popups.lua\r\nEllesmereUI_Uninstall_335.lua' in toc or 'EllesmereUI_Popups.lua\nEllesmereUI_Uninstall_335.lua' in toc

SETUP=r'''
cv={rotateMinimap='0',showTutorials='1',UberTooltips='1',chatBubbles='1'}
defaults={rotateMinimap='0',showTutorials='1',UberTooltips='1',chatBubbles='1'}
function GetCVar(n) return cv[n] end
function SetCVar(n,v) cv[n]=tostring(v) end
function GetCVarDefault(n) return defaults[n] end
chat={[1]=14,[2]=14}
function GetChatWindowInfo(i) return 'Window'..i,chat[i] end
function SetChatWindowSize(i,s) chat[i]=s end
binds={F='TARGETNEARESTENEMY'}; bindSet=1; saved={}
function GetBindingAction(k) return binds[k] or '' end
function SetBinding(k,a) binds[k]=a; return true end
function SaveBindings(s) saved[#saved+1]=s end
function GetCurrentBindingSet() return bindSet end
addons={'EllesmereUI','EllesmereUIBags','DBM-Core','EllesmereUIQoL'}; disabled={}
function GetNumAddOns() return #addons end
function GetAddOnInfo(i) return addons[i] end
function DisableAddOn(n) disabled[#disabled+1]=n end
function UnitGUID(u) return 'Player-1' end
combat=false; function InCombatLockdown() return combat end
'''

def runtime(db_lua):
    lua=LuaRuntime()
    lua.execute((root/'backport-tools/wrath_mock.lua').read_text(encoding='utf-8-sig'))
    lua.execute((root/'backport-tools/inventory_resources_mock.lua').read_text(encoding='utf-8-sig'))
    lua.execute('lifecycleErrors={}; function geterrorhandler() return function(e) lifecycleErrors[#lifecycleErrors+1]=e end end')
    lua.execute((root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig'),'EllesmereUI',lua.table())
    lua.execute(SETUP)
    lua.execute((root/'EllesmereUI/EllesmereUI_Uninstall_335.lua').read_text(encoding='utf-8-sig'),'EllesmereUI',lua.table())
    lua.execute(db_lua)
    lua.execute(r'''
for _,f in ipairs(allFrames) do if f.events.ADDON_LOADED and f.events.PLAYER_LOGIN then lifecycle=f end end
lifecycle:RunScript('OnEvent','ADDON_LOADED','EllesmereUI')
for _,f in ipairs(allFrames) do if f.events.PLAYER_LOGIN and not f.events.ADDON_LOADED then f:RunScript('OnEvent','PLAYER_LOGIN') end end
''')
    return lua

# Fresh account: the values from before EllesmereUI go back.
lua=runtime('EllesmereUIDB=nil')
lua.execute(r'''
local E=EllesmereUI
assert(EllesmereUIDB.restoreOnUninstall.fresh==true and E.UninstallKnowsOriginals(),'fresh account')
E.SetCVar('rotateMinimap','1','EllesmereUIMinimap'); E.SetCVar('rotateMinimap','1','EllesmereUIMinimap')
E.SetCVar('showTutorials','0','EllesmereUIQoL')
E.SetCVar('UberTooltips','0','EllesmereUIBlizzardSkin')
local rec=EllesmereUIDB.restoreOnUninstall.chars['Player-1'].cvar
assert(rec.rotateminimap.b=='0' and rec.rotateminimap.a=='1' and rec.rotateminimap.o=='EllesmereUIMinimap','first write keeps the earlier value')
cv.showTutorials='1'  -- the player turned tutorials back on: theirs now
E.SetChatWindowSize(1,12); E.SetChatWindowSize(2,12); chat[2]=16
E.NoteBinding('F',GetBindingAction('F')); SetBinding('F','EUI_RADIAL1')
E.NoteBinding('G',''); SetBinding('G','EUI_RADIAL2')
local stepRan=false; E.OnUninstall(function() stepRan=true end); E.OnUninstall(function() error('boom') end)
combat=true; assert(E.Uninstall()==false and cv.rotateMinimap=='1','refused in combat'); combat=false
assert(E.Uninstall()==true)
assert(cv.rotateMinimap=='0' and cv.UberTooltips=='1','EllesmereUI CVars put back')
assert(cv.showTutorials=='1','a value the player changed stays')
assert(chat[1]==14 and chat[2]==16,'chat font: ours back, player change kept')
assert(binds.F=='TARGETNEARESTENEMY' and binds.G=='EUI_RADIAL2' and saved[1]==1,'taken key handed back, empty key left')
assert(stepRan,'module steps run (a failing one does not stop it)')
assert(#disabled==3 and disabled[1]=='EllesmereUI' and disabled[2]=='EllesmereUIBags' and disabled[3]=='EllesmereUIQoL','only EllesmereUI addons turned off')
local r=EllesmereUIDB.restoreOnUninstall; local c=r.chars['Player-1']
assert(not c.cvar and not c.chatFont and not r.bind and r.fresh==true,'records dropped')
assert(E.SetCVar('rotateMinimap','1')==false and cv.rotateMinimap=='0' and E.IsUninstalled(),'nothing re-applies before the reload')
assert(E.Uninstall()==false,'runs once')
''')

# Account from before the record: CVars go back to the game defaults.
lua=runtime("EllesmereUIDB={profiles={Default={addons={EllesmereUIMinimap={}}}}}; cv.rotateMinimap='1'")
lua.execute(r'''
local E=EllesmereUI
assert(not E.UninstallKnowsOriginals(),'pre-record account')
E.SetCVar('rotateMinimap','1','EllesmereUIMinimap')
assert(EllesmereUIDB.restoreOnUninstall.chars['Player-1'].cvar.rotateminimap.b=='0','game default used')
E.SetChatWindowSize(1,12); assert(EllesmereUIDB.restoreOnUninstall.chars['Player-1'].chatFont[1].b==nil,'chat size: no original known')
E.Uninstall(); assert(cv.rotateMinimap=='0' and chat[1]==12)
''')

# Existing record keeps its fresh mark across sessions.
lua=runtime("EllesmereUIDB={profiles={Default={addons={X={}}}},restoreOnUninstall={fresh=true}}")
assert lua.eval('EllesmereUI.UninstallKnowsOriginals()')

def read(rel): return (root/rel).read_text(encoding='utf-8-sig')
wiring={
    'EllesmereUIMinimap/EUI_Minimap_335.lua':['E.SetCVar("rotateMinimap", v, ADDON_NAME)'],
    'EllesmereUINameplates/EUI_Nameplates_335.lua':['E.SetCVar(key,value,ADDON_NAME)','ns.SetCVar("showVKeyCastbar","1")','ns.SetCVar("nameplateShowEnemies"'],
    'EllesmereUIChat/EUI_Chat_335.lua':['E.SetCVar(name,value,ADDON_NAME)','E.SetChatWindowSize(i,size)','ns.SetChatFontSize(i,p.chatFontSize)'],
    'EllesmereUIQoL/EUI_QoL_335.lua':['ns.SetCVar("showTutorials","0")'],
    'EllesmereUIBlizzardSkin/EUI_Tooltips_335.lua':['E.SetCVar("UberTooltips",v,"EllesmereUIBlizzardSkin")'],
    'EllesmereUIQuickdraw/EUI_Quickdraw_335.lua':['E.NoteBinding(key,current)'],
    'EllesmereUIOptions/EUI__General_Options.lua':['EllesmereUI.L("Uninstall EUI")','EllesmereUI.UninstallKnowsOriginals()','EllesmereUI.RequestReload(EllesmereUI.L("Uninstall EUI")','EllesmereUIDB.restoreOnUninstall = oldRestore','EllesmereUI.BuildActionCardRow(parent, y, {','typeToConfirm = "Confirm"'],
}
for rel,needles in wiring.items():
    text=read(rel)
    for n in needles: assert n in text,(rel,n)
import re
for rel in ['EllesmereUIMinimap/EUI_Minimap_335.lua','EllesmereUINameplates/EUI_Nameplates_335.lua','EllesmereUIQoL/EUI_QoL_335.lua']:
    bare=[l for l in read(rel).splitlines() if re.search(r'(?<![.\w])SetCVar\(',l) and 'else SetCVar(' not in l]
    assert not bare,(rel,bare)
# The General page's action cards must come from a file the Options TOC loads.
toc=[l.strip().replace('\\','/') for l in read('EllesmereUIOptions/EllesmereUIOptions.toc').splitlines() if l.strip().endswith('.lua')]
assert any('function EllesmereUI.BuildActionCardRow(' in read('EllesmereUIOptions/'+f) for f in toc),'BuildActionCardRow not in a loaded Options file'
print('PASS: Uninstall EUI puts back tracked CVars, chat font sizes and taken keys only while they hold EllesmereUI values, runs module steps, refuses in combat, turns off EllesmereUI addons only, drops records; pre-record accounts use game defaults; Minimap, Nameplates, Chat, QoL, Tooltips and Quickdraw wired; Reset ALL keeps the record; General button.')
