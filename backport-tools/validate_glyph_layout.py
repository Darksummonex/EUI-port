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
GlyphFrameBackground:SetWidth(352); GlyphFrameBackground:SetHeight(441); GlyphFrameBackground:SetPoint('TOPLEFT',GlyphFrame,'TOPLEFT',0,0)
GlyphFrameBackground:SetTexCoord(0,0.6875,0,0.861328125)
GlyphFrameGlow=GlyphFrame:CreateTexture(); GlyphFrameGlow:SetTexture('Interface\Spellbook\UI-GlyphFrame-Glow'); GlyphFrameGlow:SetAlpha(0.4)
GlyphFrame.glow=GlyphFrameGlow
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
    -- Box = the native parchment body (x 22-342, y 58-432 of the 384x512 sheet).
    assert(parent==GlyphFrame and parent2==GlyphFrame and left==22 and top==-58 and right==-42 and bottom==80,'Glyph box is not the parchment body')
    -- Native glyph art stays visible, cropped to the body at its native 1:1 offset inside the 1px border.
    local bg=GlyphFrameBackground
    assert(bg:GetTexture()=='Interface\Spellbook\UI-GlyphFrame' and bg:GetAlpha()==1 and not g.regions[bg] and not g.cleared[bg],'Glyph background stripped')
    local p,rel,rp,x,y=bg:GetPoint(1)
    assert(bg:GetNumPoints()==1 and p=='TOPLEFT' and rel==GlyphFrame and rp=='TOPLEFT' and x==23 and y==-59,'Glyph art moved off its native offset')
    assert(bg:GetWidth()==318 and bg:GetHeight()==372,'Glyph art spills outside the box')
    local cl,cr,ct,cb=bg:GetTexCoord()
    assert(math.abs(cl*512-23)<1e-9 and math.abs(cr*512-341)<1e-9 and math.abs(ct*512-59)<1e-9 and math.abs(cb*512-431)<1e-9,'Glyph art crop not 1:1')
    assert((cr-cl)*512==bg:GetWidth() and (cb-ct)*512==bg:GetHeight(),'Glyph art stretched')
    assert(GlyphFrameGlow:GetTexture()=='Interface\Spellbook\UI-GlyphFrame-Glow' and GlyphFrameGlow:GetAlpha()==0.4,'Learn glow stripped')
    -- Every socket sits inside the box (native GlyphTemplate anchors on a 384x512 frame).
    -- Centres from the top-left: 1 CENTER(-15,140), 2 CENTER(-14,-103), 3 TOPLEFT(28,-133),
    -- 4 BOTTOMRIGHT(-56,168), 5 TOPRIGHT(-56,-133), 6 BOTTOMLEFT(26,168); all 90x90.
    for _,sock in ipairs({{177,116},{178,359},{73,178},{283,299},{283,178},{71,299}}) do
        assert(sock[1]-45>=left and sock[1]+45<=384+right and sock[2]-45>=-top and sock[2]+45<=512-bottom,'Socket outside glyph box')
    end
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
    assert(select(4,GlyphFrameBackground:GetPoint(1))==0 and GlyphFrameBackground:GetWidth()==352 and select(2,GlyphFrameBackground:GetTexCoord())==0.6875,'Hidden glyph art not restored')
    assert(not PlayerTalentFrameActivateButton:IsShown() and not PlayerTalentFramePreviewBar:IsShown(),'Inactive native controls resurrected')
end
assert(nativeGlyphUpdates==5 and nativeGlyphCloses==6,'Native glyph handlers replaced')
-- The talent window fill stops above the tab row and left of the dual-spec tabs.
GlyphFrame:Show(); BS.Apply()
local function TalentFill() local _,_,_,l,tp=t.panel:GetPoint(1); local _,_,_,r,b=t.panel:GetPoint(2); return l,tp,r,b end
local tabTop=0
for j=1,4 do local tab=_G['PlayerTalentFrameTab'..j]; tabTop=math.max(tabTop,select(5,tab:GetPoint())+tab:GetHeight()) end
local l,tp,r,b=TalentFill()
assert(l==4 and tp==-4 and r==-32 and b>tabTop and b<tabTop+6,'Talent fill covers the tabs or the dual-spec column: '..tostring(r)..' '..tostring(b))
PlayerSpecTab1=CreateFrame('CheckButton','PlayerSpecTab1',PlayerTalentFrame)
function PlayerSpecTab1:GetLeft() return PlayerTalentFrame:GetRight()-40 end
BS.Apply(); l,tp,r,b=TalentFill(); assert(r==-42,'Fill not stopped at the dual-spec tabs: '..tostring(r))
PlayerSpecTab1:Hide(); BS.Apply(); l,tp,r,b=TalentFill(); assert(r==-32)
BS.SetValue('reskinPlayerSpells',false)
assert(PlayerTalentFrameTitleText:IsShown() and PlayerTalentFrameScrollFrame:IsShown() and PlayerTalentFramePointsBar:IsShown())
assert(GlyphFrameBackground:GetTexture()=='Interface\Spellbook\UI-GlyphFrame' and not BS.states[GlyphFrame].panel:IsShown())
assert(GlyphFrameBackground:GetNumPoints()==1 and select(4,GlyphFrameBackground:GetPoint(1))==0 and GlyphFrameBackground:GetHeight()==441)
assert(select(4,GlyphFrameBackground:GetTexCoord())==0.861328125 and GlyphFrameGlow:GetAlpha()==0.4,'Disable did not restore native glyph art')
BS.SetValue('reskinPlayerSpells',true)
local count=#allFrames; BS.Apply(); BS.Apply(); assert(count==#allFrames,'Duplicate glyph skin frames')
combat=true; GlyphFrame:Hide(); assert(not PlayerTalentFrameScrollFrame:IsShown())
combat=false; BS.events:RunScript('OnEvent','PLAYER_REGEN_ENABLED'); assert(PlayerTalentFrameScrollFrame:IsShown())
''')
print('PASS: glyph box fitted to the native parchment body; native UI-GlyphFrame art kept and cropped 1:1 inside it, learn glow kept, sockets inside, art restored on hide/disable.')
print('PASS: glyph content bounds, shared header/tabs, six native sockets/clicks/tooltips, repeated tab switching, native hide handlers, inactive control restoration, skin disable/combat deferral and frame reuse.')
