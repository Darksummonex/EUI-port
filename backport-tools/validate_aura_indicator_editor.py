"""Real shared editor/preview, selected layouts, healer ranks and live UF pools."""
from pathlib import Path
import runpy
root=Path(__file__).resolve().parents[1]
fixture=runpy.run_path(str(root/'backport-tools/validate_raidframes.py'))
lua=fixture['lua']
lua.execute(r'''
combat=false; raidCount=0; partyCount=0
local methods=getmetatable(UIParent).__index
function methods:EnableKeyboard(value) self.keyboard=value end
R.selectedWrathAuraGroup='raid'; R.selectedRaidLayout='25'
local E=EllesmereUI; local A=E.WrathAuraIndicators
-- Blank layouts initialize only healing/defensive/external assignments.
local c=R.GetRaidLayout('25'); c.buffIndicators=nil
local list=A.List(c,'buff',true); assert(#list==3 and list[1].category=='healing' and list[2].category=='defensive' and list[3].category=='external')
assert(list[1].spells[139] and list[2].spells[48792] and list[3].spells[33206] and not list[1].spells[1459])
local legacy={maxBuffs=3,buffIndicators={{name='Buff Icons',position='TOPLEFT',size=19}}}
local converted=A.List(legacy,'buff',true)
assert(#converted==3 and converted[1].position=='TOPLEFT' and converted[1].size==19 and converted[1].filter=='tracked')
local manual={buffIndicators={{name='My Buffs',filter='tracked',spells={[1459]=true}}}}
assert(A.List(manual,'buff',true)==manual.buffIndicators and #manual.buffIndicators==1)
-- The client gives a different ID for higher ranks, but the same local name.
local spellInfo=GetSpellInfo
function GetSpellInfo(id)
    if id==48068 then return spellInfo(139) end
    return spellInfo(id)
end
assert(A.HasSpell(list[1].spells,48068))
c.buffFilterMode='own'; c.onlyPlayerBuffs=true
assert(A.Allows(c,'buff',33206,false,8,false),'External rejected by broad Own filter')
assert(not A.Select({{id=139,mine=false,index=1}},list[1])[1],'Healing Own Only ignored')
c.buffExclude={[33206]=true}; assert(not A.Allows(c,'buff',33206,false,8,false)); c.buffExclude={}
c.buffExclude={[139]=true}; assert(not A.Allows(c,'buff',48068,true,15,false),'Ranked buff bypassed exclusion'); c.buffExclude={}
local cfg=modules.EllesmereUIRaidFrames
assert(cfg.getHeaderBuilder('Buffs')(UIParent,720)==244)
local view=E.WrathAuraIndicatorViews.EllesmereUIRaidFramesbuff
assert(view.root:GetParent()==UIParent and view.icons[1].spellID==17 and view.icons[6].spellID==33206)
rows={}; cfg.buildPage('Buffs',UIParent,0)
FindRow('Position').setValue('TOPLEFT'); FindRow('Growth Direction').setValue('DOWN')
FindRow('Size').setValue(21); FindRow('X Offset').setValue(9)
local size,point,x,y=A.Geometry(c,'buff',list[1],2,c.frameWidth,c.frameHeight,true)
assert(view.icons[2]:GetWidth()==size and select(1,view.icons[2]:GetPoint())==point and select(4,view.icons[2]:GetPoint())==x and select(5,view.icons[2]:GetPoint())==y,'Preview/live geometry diverged')
local active=R.activeRaidLayout; R.activeRaidLayout='25'
local live=CreateFrame('Button',nil,UIParent); live._euiKind='raid'; live._euiPreview=1; R.InitButton(live)
for _,anchor in ipairs({'TOPLEFT','TOP','TOPRIGHT','LEFT','CENTER','RIGHT','BOTTOMLEFT','BOTTOM','BOTTOMRIGHT'}) do
    for _,growth in ipairs({'LEFT','RIGHT','UP','DOWN'}) do
        list[1].position=anchor; list[1].growth=growth; R.LayoutButton(live); E.UpdateWrathAuraIndicatorPreview('EllesmereUIRaidFrames','buff')
        for i=1,2 do
            local a,b=live.buffs[i],view.icons[i]
            assert(a:GetWidth()==b:GetWidth() and select(1,a:GetPoint())==select(1,b:GetPoint()) and select(4,a:GetPoint())==select(4,b:GetPoint()) and select(5,a:GetPoint())==select(5,b:GetPoint()),'Live/preview anchor mismatch '..anchor..'/'..growth)
        end
    end
end
R.activeRaidLayout=active
FindRow('Show Stacks').setValue(false); assert(view.icons[1].count:GetText()=='')
FindRow('Duration Text').setValue(false); assert(view.icons[1].time:GetText()=='')
FindRow('Hide Icons').setValue(true); assert(not view.icons[1].icon:IsShown())
view.items[3]:RunScript('OnClick'); assert(R.selectedbuffIndicator==3)
rows={}; cfg.buildPage('Buffs',UIParent,0); FindRow('Extra Spell IDs').setValue('33206, 47788')
assert(A.List(c,'buff')[3].spells[47788] and not A.List(c,'buff')[3].spells[6940])
assert(A.List(R.GetRaidLayout('10'),'buff',true)[3].spells[6940],'Editing 25-player spells changed 10-player layout')
assert(c~=R.GetRaidLayout('10') and c.buffIndicators~=R.GetRaidLayout('10').buffIndicators)
buttons['Add New Indicator'](); rows={}; cfg.buildPage('Buffs',UIParent,0)
local d=select(1,(function() local list=A.List(c,'buff'); return list[#list] end)())
assert(d.category=='manual' and next(d.spells)==nil and d.filter=='tracked')
FindRow('Extra Spell IDs').setValue('1459'); assert(d.spells[1459])
-- Header reconstruction/cache restoration reuses native frames and never
-- creates keyboard-capturing EditBoxes or secure/unit action buttons.
local count=#allFrames; cfg.getHeaderBuilder('Buffs')(UIParent,720); cfg.onPageCacheRestore('Buffs')
assert(count==#allFrames and not view.root.keyboard)
for _,a in ipairs(view.icons) do assert(not a.protected and not a:GetAttribute('type1')) end
-- Independent UF namespaces/records; default old aura rows remain available.
U={Wrath={CreateFrame=CreateFrame},frames={},IsWrath=true}
function U.Wrath.CreateFrame(...)
    local f=CreateFrame(...)
    function f:SetSize(w,h) self:SetWidth(w); self:SetHeight(h) end
    function f:SetShown(show) if show then self:Show() else self:Hide() end end
    return f
end
uc={frameWidth=181,healthHeight=46,powerHeight=6,showBuffs=true,maxBuffs=4,maxDebuffs=4,buffSize=22,debuffSize=22,buffAnchor='topleft',debuffAnchor='bottomleft',onlyPlayerBuffs=true}
function U.UF_GetSettings(unit) return unit=='player' and uc or tc end
tc={frameWidth=181,healthHeight=46,powerHeight=6,showBuffs=true,maxBuffs=4,maxDebuffs=4}
E._ModuleNS.EllesmereUIUnitFrames=U
''')
ns=lua.globals().U
lua.execute((root/'EllesmereUIUnitFrames/EUI_UnitFrames_335_Auras.lua').read_text(),'EllesmereUIUnitFrames',ns)
lua.execute(r'''
local E=EllesmereUI; local A=E.WrathAuraIndicators
uf=CreateFrame('Frame',nil,UIParent); uf._euiUnit='player'; uf:SetWidth(181); uf:SetHeight(52)
uf.Health=CreateFrame('StatusBar',nil,uf); U.frames.player=uf
units.player.buffs={{name='Higher Renew',id=48068,caster='player',duration=15,expires=GetTime()+15,stacks=2},
{name='External',id=33206,caster='party2',duration=8,expires=GetTime()+8},
{name='Personal Defensive',id=48792,caster='player',duration=12,expires=GetTime()+12},
{name='Other Ordinary Buff',id=1459,caster='player',duration=300,expires=GetTime()+300}}
U.UF_CreateAuraContainers(uf,'player')
local entry=U.WrathAuraEntries[uf]; assert(entry.buffs:IsShown() and not uc.buffIndicatorMode)
E.WrathAuraIndicatorHeader('EllesmereUIUnitFrames','buff')(UIParent,720)
rows={}; E.BuildWrathAuraIndicators('EllesmereUIUnitFrames','buff',UIParent,0)
FindRow('Use Indicator Layout').setValue(true)
assert(not entry.buffs:IsShown() and entry.indicators.buff[1].spellID==48068 and entry.indicators.buff[4].spellID==48792 and entry.indicators.buff[6].spellID==33206)
for _,a in ipairs(entry.indicators.buff) do assert(not a:IsShown() or a.spellID~=1459,'Non-healer buff appeared without manual assignment') end
local view=E.WrathAuraIndicatorViews.EllesmereUIUnitFramesbuff
FindRow('Position').setValue('TOPRIGHT'); FindRow('Growth Direction').setValue('LEFT'); FindRow('Size').setValue(24)
assert(select(1,entry.indicators.buff[1]:GetPoint())==select(1,view.icons[1]:GetPoint()) and entry.indicators.buff[1]:GetWidth()==view.icons[1]:GetWidth())
FindRow('Select Indicator').setValue(3); rows={}; E.BuildWrathAuraIndicators('EllesmereUIUnitFrames','buff',UIParent,0)
FindRow('Own Only').setValue(true); assert(not entry.indicators.buff[6]:IsShown()); FindRow('Own Only').setValue(false)
FindRow('Select Indicator').setValue(1); rows={}; E.BuildWrathAuraIndicators('EllesmereUIUnitFrames','buff',UIParent,0)
FindRow('Icons Per Indicator').setValue(2); buttons['Add New Indicator']()
rows={}; E.BuildWrathAuraIndicators('EllesmereUIUnitFrames','buff',UIParent,0); FindRow('Extra Spell IDs').setValue('1459')
assert(entry.indicators.buff[7]:IsShown() and entry.indicators.buff[7].spellID==1459,'Manual buff not applied to player')
local count=#allFrames; combat=true
units.player.buffs[1].expires=GetTime()+2; U.UF_ReloadAllAuraContainers(); assert(count==#allFrames,'Created indicator during combat')
now=now+3; entry.indicators.buff[1]:RunScript('OnUpdate',.3); assert(not entry.indicators.buff[1]:IsShown(),'Expired indicator persisted')
combat=false; FindRow('Use Indicator Layout').setValue(false); assert(entry.buffs:IsShown() and not entry.indicators.buff[7]:IsShown())
assert(not tc.buffIndicatorMode and not tc.buffIndicators,'Player edit changed target')
''')
print('PASS: shared raid/UF editor and live preview, nine anchors/growth geometry, selected 10/25/40 isolation, healer/defensive/external defaults, rank aliases, external any-caster vs Own/exclusions, manual-only other buffs, pooled live player indicators/expiration/combat/legacy lane restore and native factory/input safety.')
