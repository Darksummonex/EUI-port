"""Glyphs share talent chrome; the elevated glyph sheet must not cover tabs."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime()
for name in ['wrath_mock.lua','blizzardskin_mock.lua']:
    lua.execute((root/'backport-tools'/name).read_text())
lua.execute((root/'EllesmereUI/EllesmereUI_Lite.lua').read_text(encoding='utf-8-sig'))
lua.execute(r'''
local m=getmetatable(UIParent).__index
function m:SetPoint(...) assert(not combat); self.points=self.points or {}; self.points[#self.points+1]={...}; self.point={...} end
function m:ClearAllPoints() assert(not combat); self.points={}; self.point=nil end
function m:GetNumPoints() return #(self.points or {}) end
function m:GetPoint(i) return unpack((self.points or {})[i or 1] or {}) end
PlayerTalentFrame:SetFrameLevel(10)
PlayerTalentFrameTitleText=PlayerTalentFrame:CreateFontString(); PlayerTalentFrameTitleText:SetText('Primary Talents')
for _,name in ipairs({'ScrollFrame','PointsBar','StatusFrame','PreviewBar','ActivateButton'}) do
    local f=CreateFrame('Frame','PlayerTalentFrame'..name,PlayerTalentFrame); f:SetWidth(330); f:SetHeight(26)
end
PlayerTalentFrameActivateButton:Hide()
PlayerTalentFramePreviewBar:Hide()
for i,label in ipairs({'Discipline','Holy','Shadow','Glyphs'}) do
    local b=NativeButton('PlayerTalentFrameTab'..i,PlayerTalentFrame); b.id=i; b.label:SetText(label)
    b.normal:SetTexture('Interface\CharacterFrame\UI-Character-Tab-Left')
end
GlyphFrame=CreateFrame('Frame','GlyphFrame',PlayerTalentFrame)
GlyphFrame:SetWidth(384); GlyphFrame:SetHeight(512); GlyphFrame:SetFrameLevel(14); GlyphFrame:SetAllPoints(PlayerTalentFrame)
GlyphFrameBackground=GlyphFrame:CreateTexture(); GlyphFrameBackground:SetTexture('Interface\Spellbook\UI-GlyphFrame')
GlyphFrameTitleText=GlyphFrame:CreateFontString(); GlyphFrameTitleText:SetText('Primary Glyphs')
GlyphFrame:SetScript('OnShow',function() nativeGlyphUpdates=(nativeGlyphUpdates or 0)+1 end)
GlyphFrame:SetScript('OnHide',function() nativeGlyphCloses=(nativeGlyphCloses or 0)+1 end)
for i=1,6 do
    local b=CreateFrame('Button','GlyphFrameGlyph'..i,GlyphFrame); b.id=i; b:SetFrameLevel(15)
    b.glyph=b:CreateTexture(); b.glyph:SetTexture('Interface\Spellbook\UI-Glyph-Rune1')
    b.setting=b:CreateTexture(); b.setting:SetTexture('Interface\Spellbook\UI-GlyphFrame')
    b:SetScript('OnClick',function(self) clickedGlyph=self.id end)
    b:SetScript('OnEnter',function(self) tooltipGlyph=self.id end)
end
GlyphFrame:Hide()
EllesmereUIDB={}
''')
ns=lua.table()
lua.execute((root/'EllesmereUIBlizzardSkin/EUI_BlizzardSkin_335.lua').read_text(),'EllesmereUIBlizzardSkin',ns)
lua.globals().BS=ns
lua.execute(r'''
BS.addon:OnInitialize(); BS.addon:OnEnable()
local t=BS.states[PlayerTalentFrame]
for i=1,5 do
    GlyphFrame:Show(); BS.Apply()
    local g=BS.states[GlyphFrame]
    assert(g.active and g.panel:IsShown() and not g.accent:IsShown())
    local _,parent,_,left,top=g.panel:GetPoint(1)
    local _,parent2,_,right,bottom=g.panel:GetPoint(2)
    assert(parent==GlyphFrame and parent2==GlyphFrame and left==16 and top==-58 and right==-45 and bottom==72,'Glyph fill covers header/footer')
    assert(not PlayerTalentFrameTitleText:IsShown() and GlyphFrameTitleText:IsShown())
    assert(not PlayerTalentFrameScrollFrame:IsShown() and not PlayerTalentFramePointsBar:IsShown())
    assert(not PlayerTalentFrameStatusFrame:IsShown() and not PlayerTalentFrameActivateButton:IsShown())
    local tabTop=0
    for j=1,4 do
        local tab=_G['PlayerTalentFrameTab'..j]
        local y=select(5,tab:GetPoint()); tabTop=math.max(tabTop,y+tab:GetHeight())
        assert(tab:IsShown() and t.buttons[tab].panel:IsShown(),'Shared tabs disappeared')
    end
    assert(bottom>tabTop,'Glyph background overlaps tab rectangles')
    for j=1,6 do
        local slot=_G['GlyphFrameGlyph'..j]
        assert(slot.glyph:GetTexture()=='Interface\Spellbook\UI-Glyph-Rune1')
        assert(slot.setting:GetTexture()=='Interface\Spellbook\UI-GlyphFrame')
        slot:RunScript('OnClick'); slot:RunScript('OnEnter'); assert(clickedGlyph==j and tooltipGlyph==j)
    end
    GlyphFrame:Hide(); BS.Apply()
    assert(PlayerTalentFrameTitleText:IsShown() and PlayerTalentFrameScrollFrame:IsShown() and PlayerTalentFramePointsBar:IsShown())
    assert(not PlayerTalentFrameActivateButton:IsShown() and not PlayerTalentFramePreviewBar:IsShown(),'Inactive native controls resurrected')
end
assert(nativeGlyphUpdates==5 and nativeGlyphCloses==6,'Native glyph handlers replaced')
GlyphFrame:Show(); BS.Apply()
BS.SetValue('reskinPlayerSpells',false)
assert(PlayerTalentFrameTitleText:IsShown() and PlayerTalentFrameScrollFrame:IsShown() and PlayerTalentFramePointsBar:IsShown())
assert(GlyphFrameBackground:GetTexture()=='Interface\Spellbook\UI-GlyphFrame' and not BS.states[GlyphFrame].panel:IsShown())
BS.SetValue('reskinPlayerSpells',true)
local count=#allFrames; BS.Apply(); BS.Apply(); assert(count==#allFrames,'Duplicate glyph skin frames')
combat=true; GlyphFrame:Hide(); assert(not PlayerTalentFrameScrollFrame:IsShown())
combat=false; BS.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(PlayerTalentFrameScrollFrame:IsShown())
''')
print('PASS: glyph content bounds, shared header/tabs, six native sockets/clicks/tooltips, repeated tab switching, native hide handlers, inactive control restoration, skin disable/combat deferral and frame reuse.')
