"""Custom Button Shape on the Wrath action bars: round icons, outlines, cooldown inset, restore, options and preview."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime

media=root/'EllesmereUI/media/portraits'
for shape in ['square','circle','csquare','diamond','hexagon','portrait','shield']:
    for kind in ['border','mask']:
        assert (media/f'{shape}_{kind}.tga').is_file(),f'missing {shape}_{kind}.tga'

lua=LuaRuntime()
lua.execute((root/'backport-tools/wrath_mock.lua').read_text())
lua.execute((root/'backport-tools/actionbars_mock.lua').read_text())
lua.execute((root/'backport-tools/nativehud_mock.lua').read_text())
unlock_source=(root/'EllesmereUI/EUI_UnlockMode.lua').read_text(encoding='utf-8-sig')
active_method='function EllesmereUI:IsUnlockModeActive()'+unlock_source.split('function EllesmereUI:IsUnlockModeActive()',1)[1].split('\n    end',1)[0]+'\nend'
lua.execute(active_method)
lua.execute('''
local function Copy(value)
    if type(value)~='table' then return value end
    local result={}; for k,v in pairs(value) do result[k]=Copy(v) end; return result
end
function EllesmereUI.Lite.NewDB(_,defaults) return {profile=Copy(defaults.profile)} end
local m=getmetatable(UIParent).__index
function m:SetVertexColor(...) self.vertex={...} end
function m:GetVertexColor() return unpack(self.vertex or {1,1,1,1}) end
function m:SetDrawLayer(layer) self.layer=layer end
function m:EnableKeyboard(v) self.keyboard=v end
function m:EnableMouseWheel(v) self.wheel=v end
function m:SetCheckedTexture(t) self.checkedTexture=t end
function m:GetChecked() return self.checked end
for _,k in ipairs({"SetMovable","SetClampedToScreen","StartMoving","StopMovingOrSizing"}) do m[k]=function() end end
for _,k in ipairs({"Highlight","Pushed","Checked"}) do
    m["Get"..k.."Texture"]=function(self)
        local key="_mock"..k
        if not self[key] then self[key]=self:CreateTexture(); self[key]:SetTexture("native-"..k) end
        return self[key]
    end
end
portraitCalls=0
function SetPortraitToTexture(t,path) portraitCalls=portraitCalls+1; t.portrait=path end
StaticPopupDialogs,UISpecialFrames,tinsert={}, {}, table.insert
DEFAULT_CHAT_FRAME={AddMessage=function() end}
''')
for file in ['EllesmereUI/Libs/LibStub/LibStub.lua','EllesmereUI/Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua']:
    lua.execute((root/file).read_text(encoding='utf-8-sig'))
lua.execute('local k=LibStub:NewLibrary("LibKeyBound-1.0",999); function k:Set() error("key capture reached") end')
lua.execute((root/'EllesmereUIActionBars/Libs/LibActionButton-1.0-335.lua').read_text())
ns=lua.table()
lua.execute((root/'EllesmereUIActionBars/EUI_ActionBars_335.lua').read_text(),'EllesmereUIActionBars',ns)
lua.execute((root/'EllesmereUIActionBars/EUI_ActionBars_335_EndCaps.lua').read_text(),'EllesmereUIActionBars',ns)
lua.execute((root/'EllesmereUIActionBars/EUI_NativeHUD_335.lua').read_text(),'EllesmereUIActionBars',ns)
lua.globals().AB=ns
lua.execute('''
PetActionButton1Icon=PetActionButton1:CreateTexture(); PetActionButton1Icon:SetTexture("pet-icon")
PetActionButton1Cooldown=CreateFrame("Cooldown",nil,PetActionButton1)
AB.addon:OnInitialize(); AB.addon:OnEnable()
''')
lua.execute('''
local function Ends(path,tail) return type(path)=="string" and path:sub(-#tail)==tail end
local function Offset(t,i) return select(4,t:GetPoint(i)),select(5,t:GetPoint(i)) end
local function Near(a,b) return math.abs(a-b)<1e-6 end
local s=AB.GetSettings("bar1"); local p=AB.GetSettings()
local button=AB.bars.bar1.buttons[1]
local icon,width=button.icon,button:GetWidth()
assert(s.buttonShape=="none" and AB.ShapeOf(s)=="none" and AB.ShapeOf({buttonShape="bogus"})=="none")
assert(button._euiShapeOutline==nil and not icon._euiRoundHook,"Shapes off must not touch the icon")
assert(button._euiBorder.borderColor[4]>0,"Square border expected with shapes off")
assert(#AB.SHAPE_ORDER==8 and AB.SHAPE_LABELS.csquare=="Curved Square")

-- Circle: round icon, round slot, outline fitted to the opening, inset swipe.
s.buttonShape="circle"; AB.Apply()
local outline,bg=button._euiShapeOutline,button._euiShapeBg
assert(outline and outline:IsShown() and Ends(outline:GetTexture(),"circle_border.tga"))
local pad=(width*128/104-width)/2
local x,y=Offset(outline,1); assert(Near(x,-pad) and Near(y,pad),"Outline not fitted: "..tostring(x))
assert(outline.vertex[1]==0 and outline.vertex[4]==1,"Outline uses the black border colour")
assert(bg and bg:IsShown() and Ends(bg:GetTexture(),"circle_mask.tga") and bg.parent==button._euiBorder)
assert(Near(bg.vertex[4],p.slotBgOpacity/100))
assert(button._euiBorder.borderColor[4]==0 and button._euiBorder.bgColor[4]==0,"Square edge and slot must hide")
assert(icon._euiRound and icon.portrait=="icon-1" and icon.texcoords[1]==0 and icon.texcoords[2]==1 and icon.layer=="BACKGROUND")
local inset=width*(1-.7071)/2
x,y=Offset(button.cooldown,1); assert(Near(x,inset) and Near(y,-inset),"Swipe not inset")
local hl=button:GetHighlightTexture()
assert(Ends(hl:GetTexture(),"circle_border.tga") and Near(select(4,hl:GetPoint(1)),-pad),"Hover not shaped")
assert(Ends(button:GetCheckedTexture():GetTexture(),"circle_border.tga") and Ends(button:GetPushedTexture():GetTexture(),"circle_border.tga"))
assert(not button._euiHLOn,"Square hover edges must stay off")

-- LAB swapping the action redraws the round icon and remembers the real path.
icon:SetTexture("icon-9"); assert(icon.portrait=="icon-9" and icon._euiPath=="icon-9")
local calls=portraitCalls; AB.Apply(); AB.Apply()
assert(portraitCalls>calls and icon._euiRound and icon.portrait==icon._euiPath,"Reapplying must keep the round icon")

-- Border size 0 hides the outline; class colour tints it.
s.borderSize=0; AB.Apply(); assert(not outline:IsShown())
s.borderSize=1; s.borderClassColor=true; AB.Apply(); assert(outline:IsShown() and outline.vertex[1]~=0)
s.borderClassColor=false

-- Diamond, hexagon and shield crop the icon into strips as wide as the mask row.
s.buttonShape="hexagon"; AB.Apply()
assert(Ends(outline:GetTexture(),"hexagon_border.tga") and outline:IsShown())
assert(bg:IsShown() and Ends(bg:GetTexture(),"hexagon_mask.tga") and button._euiBorder.bgColor[4]==0)
assert(not icon._euiRound and icon.texture==icon._euiPath and icon.texture~=nil,"Round icon not undone")
x=Offset(outline,1); assert(Near(x,-(width*128/126-width)/2))
local strips=icon._euiStrips
assert(strips and strips.on and strips.count>20,"Hexagon not cropped")
local rows=AB.STRIP_SHAPES.hexagon
local n=math.floor(button:GetHeight()+.5)
local covered=0
for k=0,n-1 do local row=math.floor((k+.5)/n*64); if rows[row*2+2]>rows[row*2+1] then covered=covered+1 end end
assert(strips.count==covered-1,"One strip per covered row, the icon is the first")
local ix,iy=Offset(icon,1); local rx=Offset(icon,2)
assert(ix>0 and rx<width and iy<0,"Icon must become the narrow top strip")
local mid=strips[math.floor(strips.count/2)]
local mx=Offset(mid,1); local mr=Offset(mid,2)
assert(Near(mx,0) and Near(mr,width),"Middle row spans the whole button")
local z=p.iconZoom/100
assert(Near(mid.texcoords[1],z) and Near(mid.texcoords[2],1-z) and mid.texcoords[3]>z,"Strip texcoords follow the zoom")
for i=1,strips.count do assert(strips[i].texture==icon.texture and strips[i]:IsShown()) end
icon:SetVertexColor(.4,.4,.4); assert(mid.vertex[1]==.4,"Usable colour not mirrored")
icon:SetDesaturated(true); assert(mid.desaturated==true)
icon:SetAlpha(.5); assert(mid.alpha==.5)
icon:Hide(); assert(not mid:IsShown()); icon:Show(); assert(mid:IsShown())
icon:SetTexture("icon-77"); assert(mid.texture=="icon-77")
x,y=Offset(button.cooldown,1); assert(Near(x,.238*width) and Near(y,-.078*button:GetHeight()),"Swipe not fitted inside the hexagon")
local extra=#strips
s.buttonShape="diamond"; AB.Apply(); assert(strips.on and #strips>=extra and Ends(bg:GetTexture(),"diamond_mask.tga"))
for i=strips.count+1,#strips do assert(not strips[i]:IsShown(),"Unused strip left visible") end
s.buttonShape="shield"; AB.Apply(); assert(strips.on and strips.count>20)

-- Outline-only shapes keep the square icon, slot and swipe.
s.buttonShape="csquare"; AB.Apply()
assert(Ends(outline:GetTexture(),"csquare_border.tga") and outline:IsShown() and not bg:IsShown())
assert(not strips.on and icon:GetNumPoints()==0,"Strips not undone")
for i=1,#strips do assert(not strips[i]:IsShown()) end
icon:SetVertexColor(.123,0,0); assert(strips[1].vertex[1]~=.123,"Hidden strips must stop mirroring")
assert(button._euiBorder.bgColor[4]>0 and button._euiBorder.borderColor[4]==0)
x=Offset(button.cooldown,1); assert(x==0,"Outline shapes keep the full swipe")

-- None restores everything Retail-style.
s.buttonShape="none"; AB.Apply()
assert(not outline:IsShown() and not bg:IsShown() and not icon._euiRound and button._euiShapeCD==nil)
assert(button._euiBorder.borderColor[4]>0 and hl:GetTexture()~=AB.ShapeTexture("csquare","border"))
assert(Near(icon.texcoords[1],z),"Zoom not restored")
assert(AB.bars.bar2.buttons[1]._euiShapeOutline==nil,"Shape is per bar")

-- Pet and stance buttons stay Blizzard's but take the shape, and it is undone on disable.
local ps=AB.GetSettings("petBar"); ps.buttonShape="portrait"; AB.Apply()
assert(PetActionButton1._euiShapeOutline:IsShown() and PetActionButton1Icon._euiRound and PetActionButton1Icon.portrait=="pet-icon")
PetActionButton1Icon:SetTexture("pet-icon-2"); assert(PetActionButton1Icon.portrait=="pet-icon-2")
p.enabled=false; AB.Apply()
assert(not PetActionButton1._euiShapeOutline:IsShown() and not PetActionButton1Icon._euiRound and PetActionButton1Icon.texture=="pet-icon-2")
p.enabled=true; AB.Apply(); assert(PetActionButton1Icon._euiRound)
ps.buttonShape="none"; AB.Apply(); assert(not PetActionButton1Icon._euiRound)
''')
# Options: dropdown, sync scope and the live preview.
lua.execute('IsLoggedIn=function() return true end; function EllesmereUI:RefreshPage() end')
lua.execute((root/'EllesmereUIOptions/EUI_ActionBars_335_Options.lua').read_text())
lua.execute('''
EllesmereUI.Widgets={
    DualRow=function(_,parent,y,left,right) rows[#rows+1]={left,right}; return {},50 end,
    SectionHeader=function(_,parent,label,y) local h={GetPoint=function() return 'TOPLEFT',parent,'TOPLEFT',0,y end}; return h,30 end,
    WideButton=function() return {},40 end,
}
function EllesmereUI:SetContentHeader(fn) headerBuilder=fn end
function EllesmereUI:InvalidateContentHeaderCache() end
EllesmereUI.CreatePreviewHitOverlay=function(el,nav,key) hits[#hits+1]={el=el,key=key}; return CreateFrame('Button',nil,UIParent) end
local function Find(label) for _,r in ipairs(rows) do for i=1,2 do if r[i] and r[i].text==label then return r[i] end end end end
AB.SelectWrathBar('bar1',false); rows={}
assert(testModule.buildPage('Bar Display',UIParent,0)>0)
local dd=Find('Custom Button Shape')
assert(dd and dd.type=='dropdown' and dd.values==AB.SHAPE_LABELS and dd.order==AB.SHAPE_ORDER and dd.getValue()=='none')
dd.setValue('circle'); assert(AB.GetSettings('bar1').buttonShape=='circle' and AB.bars.bar1.buttons[1].icon._euiRound)
assert(AB.GetSettings('bar2').buttonShape=='none')
local function PreviewButton()
    hits={}; local hdr=CreateFrame('Frame',nil,UIParent); hdr:SetWidth(900); hdr:Show()
    assert(headerBuilder(hdr,900)>0)
    for _,hit in ipairs(hits) do if hit.key=='keybind' then return hit.el:GetParent():GetParent() end end
end
local b=PreviewButton()
assert(b and b.icon.portrait=='icon-1' and b.outline:IsShown() and b.slot:IsShown(),'Preview not round')
assert(b.border.borderColor[4]==0 and b.border.bgColor[4]==0)
dd.setValue('diamond'); b=PreviewButton()
assert(b.outline:IsShown() and b.slot:IsShown() and b.icon:GetTexture()=='icon-1' and b.border.bgColor[4]==0)
assert(b.icon._euiStrips.on and b.icon._euiStrips[1].texture=='icon-1','Preview not cropped')
dd.setValue('csquare'); b=PreviewButton()
assert(b.outline:IsShown() and not b.slot:IsShown() and b.border.bgColor[4]>0 and not (b.icon._euiStrips and b.icon._euiStrips.on))
dd.setValue('none'); b=PreviewButton()
assert(not b.outline:IsShown() and b.border.borderColor[4]>0,'Preview border '..tostring(b.border.borderColor[4]))
''')
print('PASS: custom button shapes (round icons via SetPortraitToTexture with LAB texture swaps, diamond/hexagon/shield cropped into mirrored strips with fitted swipe, fitted outlines, round slot, inset swipe, shaped hover/pushed/checked, border size/class colour, per-bar, pet/stance restore), options dropdown and live preview. Rendering requires in-game testing.')
