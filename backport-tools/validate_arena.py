"""Execute the native Arena module, its options page and the real Lite lifecycle in Lua 5.1."""
from pathlib import Path
import re
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
arena=root/'EllesmereUIArena'
toc=(arena/'EllesmereUIArena.toc').read_text(encoding='utf-8-sig')
assert '## Interface: 30300' in toc and '## SavedVariables: EllesmereUIArenaDB' in toc and '## X-Part-Of: EllesmereUI' in toc
files=[line.strip() for line in toc.splitlines() if line.strip().endswith('.lua') and not line.startswith('#')]
assert files==['EUI_Arena_335.lua','EUI_Arena_335_Display.lua'],files
for tga in (arena/'Media'/'Textures_335').glob('*.tga'):
    data=tga.read_bytes(); w=data[12]|data[13]<<8; h=data[14]|data[15]<<8
    assert w and h and w&(w-1)==0 and h&(h-1)==0,f'{tga.name} is {w}x{h}'
otoc=(root/'EllesmereUIOptions'/'EllesmereUIOptions.toc').read_text(encoding='utf-8-sig')
assert re.search(r'^EUI_Arena_335_Options\.lua$',otoc,re.M)
core=root/'EllesmereUI'
for name,needle in [('EllesmereUI.lua','{ folder = "EllesmereUIArena",'),('EllesmereUI.lua','"EllesmereUIArena",\n        },'),
                    ('EllesmereUI_Panel.lua','EllesmereUIArena = true,'),('EllesmereUI_Profiles.lua','svName = "EllesmereUIArenaDB"'),
                    ('EllesmereUI_Profiles.lua','_G._EARENA_Apply()'),('EllesmereUI_Fonts.lua','arena        = "EllesmereUIArena",'),
                    ('EllesmereUI_SpecOverrides_335.lua','EllesmereUIArena             = { "_EARENA_Apply" },'),('EllesmereUI_FirstInstall.lua','addon = "EllesmereUIArena"')]:
    assert needle in (core/name).read_text(encoding='utf-8-sig'),f'{name}: {needle}'
lua=LuaRuntime(unpack_returned_tuples=True)
for source in ['backport-tools/wrath_mock.lua','backport-tools/inventory_resources_mock.lua','backport-tools/arena_mock.lua','EllesmereUI/EllesmereUI_Lite.lua']:
    lua.execute((root/source).read_text(encoding='utf-8-sig'))
ns=lua.table()
for name in files:
    lua.execute((arena/name).read_text(encoding='utf-8-sig'),'EllesmereUIArena',ns)
lua.globals().A=ns
lite=(root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig')
safe=lua.execute('local function errorhandler('+lite.split('local function errorhandler(',1)[1].split('\n-------------------------------------------------------------------------------',1)[0]+'\nreturn safecall')
safe(ns.addon.OnInitialize,ns.addon)
safe(ns.addon.OnEnable,ns.addon)
lua.execute(r'''
local p=A.GetSettings(); local e=A.events; local F,P=A.frames,A.previews
assert(p.enabled and p.hideBlizzard and p.width==190 and A.holder and not A.holder:IsShown())
local mover=unlockByFolder.EllesmereUIArena[1]
assert(#unlockByFolder.EllesmereUIArena==1 and mover.key=='ARENA_Frames' and mover.getFrame()==A.holder)
local panel=EllesmereUI._ELEMENT_SETTINGS_MAP.ARENA_Frames
assert(panel.module=='EllesmereUIArena' and panel.page=='Arena Frames' and panel.sectionName=='LAYOUT' and panel.highlightText=='Frame Width')
for i,f in ipairs(F) do
    assert(f.template=='SecureUnitButtonTemplate' and f:GetAttribute('unit')=='arena'..i and f:GetAttribute('type1')=='target' and f:GetAttribute('type2')=='focus')
    assert(not f:IsShown() and f.name:GetFont()=='Fonts\\FRIZQT__.TTF' and select(3,f.name:GetFont())=='OUTLINE','SLUG flag must be stripped')
end
assert(A.AURA_PRIORITY['Divine Shield']==6 and A.AURA_PRIORITY['Kidney Shot']==5 and A.AURA_PRIORITY['Polymorph']==4)
-- Unlock Mode preview: fake frames only, secure buttons stay hidden.
EllesmereUI.listeners.EllesmereUIArena(true)
assert(A.holder:IsShown() and P[1]:IsShown() and P[3]:IsShown() and not P[4]:IsShown() and not F[1]:IsShown())
assert(P[1].name:GetText()=='Frostbite' and P[1].cast:IsShown() and P[1].cast.text:GetText()=='Polymorph')
assert(P[2].trinket.cd:IsShown() and P[2].trinket.cd.duration==120 and P[2].classIcon.icon:GetTexture()=='Interface\\Icons\\Ability_Rogue_KidneyShot')
assert(P[1].classIcon.icon:GetTexture():find('class%-modern') and P[1].health.color[1]==.25,'Preview class color/icon')
e:RunScript('OnUpdate',.2); assert(P[2].trinket.timer:GetText()=='2m','Trinket timer '..tostring(P[2].trinket.timer:GetText()))
EllesmereUI.listeners.EllesmereUIArena(false); assert(not P[1]:IsShown() and not A.holder:IsShown())
-- Options page preview follows the open module.
panelShown,activeModule=true,'EllesmereUIArena'; e:RunScript('OnUpdate',.2); assert(P[1]:IsShown())
activeModule='EllesmereUIQoL'; e:RunScript('OnUpdate',.2); assert(not P[1]:IsShown()); panelShown,activeModule=false,nil
-- Arena entry: bracket-sized frames, stealthed slots stay visible.
ArenaEnemyFrames=CreateFrame('Frame','ArenaEnemyFrames',UIParent)
inside,instanceKind,bracket=true,'arena',3
units.arena1={name='Enemy',class='MAGE',guid='G1',hp=50,max=100,faction='Horde'}
e:RunScript('OnEvent','PLAYER_ENTERING_WORLD')
assert(A.holder:IsShown() and F[1]:IsShown() and F[3]:IsShown() and not F[4]:IsShown())
e:RunScript('OnEvent','ADDON_LOADED','Blizzard_ArenaUI'); assert(ArenaEnemyFrames:GetParent()==A.hiddenParent and not A.hiddenParent:IsShown())
assert(F[1].name:GetText()=='Enemy' and F[1].hp:GetText()=='50%' and F[1].health.color[1]==.25)
assert(F[2].name:GetText()=='Arena 2' and F[2].hp:GetText()=='' and F[2].alpha==.5)
assert(F[1].trinket.icon:GetTexture()=='Interface\\Icons\\INV_Jewelry_TrinketPVP_02' and not F[1].trinket.cd:IsShown())
-- Trinket from the combat log (3.3.5 argument order, no hideCaster).
e:RunScript('OnEvent','COMBAT_LOG_EVENT_UNFILTERED',now,'SPELL_CAST_SUCCESS','G1','Enemy',0,'','',0,42292,'PvP Trinket',1)
assert(F[1].trinket.cd:IsShown() and F[1].trinket.cd.start==now and F[1].trinket.cd.duration==120)
e:RunScript('OnUpdate',.2); assert(F[1].trinket.timer:GetText()=='2m')
e:RunScript('OnEvent','COMBAT_LOG_EVENT_UNFILTERED',now,'SPELL_CAST_SUCCESS','G9','X',0,'','',0,59752,'Every Man for Himself',1)
assert(A.trinketUsed.G9==now,'Unseen trinket use must be remembered')
-- Priority aura: immunity beats a stun; falls back to the class icon.
auras.arena1={HARMFUL={{name='Kidney Shot',icon='ks',duration=6,expires=now+5,id=408}},HELPFUL={{name='Divine Shield',icon='ds',duration=12,expires=now+10,id=642}}}
e:RunScript('OnEvent','UNIT_AURA','arena1'); assert(F[1].classIcon.icon:GetTexture()=='ds' and F[1].classIcon.cd.duration==12)
auras.arena1.HELPFUL={}; e:RunScript('OnEvent','UNIT_AURA','arena1'); assert(F[1].classIcon.icon:GetTexture()=='ks')
auras.arena1=nil; e:RunScript('OnEvent','UNIT_AURA','arena1'); assert(F[1].classIcon.icon:GetTexture():find('class%-modern') and not F[1].classIcon.cd:IsShown())
-- Cast bar, uninterruptible colour and the interrupt flash.
casts.arena1={name='Fireball',icon='fb',s=now*1000-500,e=now*1000+2500,ni=true}
e:RunScript('OnEvent','UNIT_SPELLCAST_START','arena1')
assert(F[1].cast:IsShown() and F[1].cast.text:GetText()=='Fireball' and F[1].cast.color[1]==.6 and F[1].cast.time:GetText()=='2.5')
casts.arena1=nil; e:RunScript('OnEvent','UNIT_SPELLCAST_INTERRUPTED','arena1'); assert(F[1].cast.text:GetText()=='Interrupted' and F[1].cast:IsShown())
now=now+.7; e:RunScript('OnUpdate',.01); assert(not F[1].cast:IsShown())
channels.arena1={name='Arcane Missiles',icon='am',s=now*1000,e=now*1000+5000,ni=false}
e:RunScript('OnEvent','UNIT_SPELLCAST_CHANNEL_START','arena1'); assert(F[1].cast.channel and F[1].cast.value==5 and F[1].cast.color[1]==1)
channels.arena1=nil; e:RunScript('OnEvent','UNIT_SPELLCAST_CHANNEL_STOP','arena1'); assert(not F[1].cast:IsShown())
-- Target highlight.
targetUnit='arena1'; e:RunScript('OnEvent','PLAYER_TARGET_CHANGED'); assert(F[1].border.vertexColor[2]==.82)
targetUnit=nil; e:RunScript('OnEvent','PLAYER_TARGET_CHANGED'); assert(F[1].border.vertexColor[2]==0)
-- Stealth keeps the frame and last known data.
units.arena1=nil; e:RunScript('OnEvent','ARENA_OPPONENT_UPDATE','arena1','unseen')
assert(F[1]:IsShown() and F[1].name:GetText()=='Enemy' and F[1].hp:GetText()=='Unseen' and F[1].alpha==.5)
-- A late opponent beyond the bracket gets its frame out of combat.
units.arena4={name='Late',class='WARRIOR',guid='G4',hp=100,max=100,faction='Alliance'}
e:RunScript('OnEvent','ARENA_OPPONENT_UPDATE','arena4','seen'); assert(F[4]:IsShown() and F[4].name:GetText()=='Late')
-- Combat: secure changes wait for PLAYER_REGEN_ENABLED (the mock asserts on protected calls).
e:RunScript('OnEvent','PLAYER_REGEN_DISABLED'); combat=true
p.width=250; A.Apply(); assert(A.pending and F[1].width~=250+2*(p.height+2))
e:RunScript('OnUpdate',.6)
combat=false; e:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(not A.pending and F[1].width==250+2*(p.height+2),F[1].width)
-- Unlock position persists through the holder.
mover.savePos(nil,'TOPRIGHT','TOPRIGHT',-40,-200); A.Apply(); assert(select(1,A.holder:GetPoint(1))=='TOPRIGHT' and select(5,A.holder:GetPoint(1))==-200)
mover.clearPos(); assert(p.position==nil and select(1,A.holder:GetPoint(1))=='RIGHT')
p.hideBlizzard=false; A.Apply(); assert(ArenaEnemyFrames:GetParent()==UIParent)
-- Leaving and re-entering resets the match state.
inside,instanceKind,bracket=false,'none',nil; e:RunScript('OnEvent','PLAYER_ENTERING_WORLD'); assert(not F[1]:IsShown() and not A.holder:IsShown())
inside,instanceKind,bracket=true,'arena',2; e:RunScript('OnEvent','PLAYER_ENTERING_WORLD')
assert(next(A.trinketUsed)==nil and F[2]:IsShown() and not F[3]:IsShown() and not F[4]:IsShown() and F[1].name:GetText()=='Arena 1')
inside,instanceKind,bracket=false,'none',nil; e:RunScript('OnEvent','PLAYER_ENTERING_WORLD')
-- Growth up anchors from the bottom; disabled module hides everything.
p.growth='UP'; A.SetPreview(true); assert(select(1,P[2]:GetPoint(1))=='BOTTOMLEFT' and select(5,P[2]:GetPoint(1))>0)
p.enabled=false; A.Apply(); assert(not P[1]:IsShown() and not A.holder:IsShown()); p.enabled=true; p.growth='DOWN'; A.SetPreview(false)
SlashCmdList.EUI335ARENA('test'); assert(A.testMode and P[1]:IsShown())
SlashCmdList.EUI335ARENA('test'); assert(not A.testMode and not P[1]:IsShown())
SlashCmdList.EUI335ARENA(''); assert(optionsLoaded and shownModule=='EllesmereUIArena')
assert(type(_EARENA_Apply)=='function' and rotationCalls==0)
''')
lua.execute('function IsLoggedIn() return true end')
lua.execute((root/'EllesmereUIOptions'/'EUI_Arena_335_Options.lua').read_text(encoding='utf-8-sig'))
lua.execute(r'''
local m=modules.EllesmereUIArena
assert(m and m.title=='Arena Frames' and m.pages[1]=='Arena Frames')
rows={}; local h=m.buildPage('Arena Frames',UIParent,0); assert(h>0)
local width=FindRow('Frame Width'); width.setValue(260); assert(A.GetSettings().width==260 and width.getValue()==260)
FindRow('Bar Texture').setValue('glass'); assert(A.frames[1].health.statusTexture:find('EllesmereUIArena\\Media\\Textures_335\\glass.tga',1,true))
assert(FindRow('Bar Texture').values.atrocity=='Atrocity')
local color=FindRow('Cast Color'); color.setValue(.1,.2,.3); assert(A.GetSettings().castColor.g==.2)
for _,label in ipairs({'Enable Arena Frames','Hide Blizzard Arena Frames','Show PvP Trinket','Crowd Control on Class Icon','Show Cast Bar','Highlight Target','Unseen Opacity','Growth Direction'}) do FindRow(label) end
assert(buttons['Unlock Arena Frames'])
''')
print('Arena validation passed')
