"""Core 3.3.5 texture cooldown swipe (EllesmereUI_TextureSwipe_335.lua) and its
Cooldown Manager use (Swipe Style "texture")."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

core = root / 'EllesmereUI'
toc = [l.strip() for l in (core / 'EllesmereUI.toc').read_text(encoding='utf-8-sig').splitlines()]
assert toc.index('EllesmereUI_Glows.lua') < toc.index('EllesmereUI_TextureSwipe_335.lua')
src = (core / 'EllesmereUI_TextureSwipe_335.lua').read_text(encoding='utf-8')
for bad in ('SetRotation(', 'SetClipsChildren', 'CreateMaskTexture', 'SetRotatesTexture'):
    assert bad not in src, bad

lua = LuaRuntime()
lua.execute(r'''
now = 0
function GetTime() return now end
local function Region()
    local r = { shown = true, points = {} }
    function r:Show() self.shown = true end
    function r:Hide() self.shown = false end
    function r:IsShown() return self.shown end
    function r:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function r:SetAllPoints(t) self.all = t end
    function r:SetWidth(w) self.w = w end
    function r:SetHeight(h) self.h = h end
    function r:GetWidth() return self.w end
    function r:GetHeight() return self.h end
    return r
end
function NewTexture()
    local t = Region()
    function t:SetTexture(p) self.path = p end
    function t:SetTexCoord(...) self.coords = { ... } end
    function t:SetVertexColor(...) self.color = { ... } end
    function t:CreateAnimationGroup()
        local g = { anims = {} }
        function g:SetLooping(v) self.looping = v end
        function g:Play() self.playing = true end
        function g:CreateAnimation(kind)
            assert(kind == "Rotation")
            local a = {}
            function a:SetOrigin(p, x, y) self.origin = p end
            function a:SetDuration(d) self.duration = d end
            function a:SetEndDelay(d) self.delay = d end
            function a:SetDegrees(d) self.degrees = d end
            t.turn = a
            return a
        end
        t.group = g
        return g
    end
    return t
end
scrolls = 0
function CreateFrame(kind, name, parent)
    local f = Region()
    f.kind = kind
    function f:CreateTexture() return NewTexture() end
    function f:SetScrollChild(c) self.scrollChild = c end
    function f:SetScript(s, fn) self.scripts = self.scripts or {}; self.scripts[s] = fn end
    function f:GetScript(s) return self.scripts and self.scripts[s] end
    function f:SetFrameLevel(l) self.level = l end
    if kind == "ScrollFrame" then scrolls = scrolls + 1 end
    return f
end
EllesmereUI = {}
''')
lua.execute(src)
lua.execute(r'''
local sw = EllesmereUI.CreateTextureSwipe(CreateFrame("Frame"))
assert(scrolls == 4 and not sw.shown, "four clipping quarters, hidden")
for _, q in ipairs(sw.quarters) do
    assert(q.frame.scrollChild == q.child)
    assert(q.wedge.group.playing and q.wedge.group.looping == "REPEAT")
    assert(q.turn.duration == 0 and q.turn.origin == "BOTTOMLEFT" and q.turn.delay > 0)
end
sw.w, sw.h = 20, 20
sw.scripts.OnSizeChanged(sw)
assert(sw.wedgeSize == 40 and sw.quarters[1].child.w == 10 and sw.quarters[1].wedge.w == 40)

local function state()
    local out = {}
    for k, q in ipairs(sw.quarters) do out[k] = q.wedge.shown and "w" or (q.full.shown and "F" or "-") end
    return table.concat(out)
end
sw:Start(100, 8, false)
now = 100
sw.scripts.OnUpdate(sw)
assert(state() == "FFFF", "start: all dark " .. state())
now = 101          -- 45 degrees
sw.scripts.OnUpdate(sw)
assert(state() == "wFFF", state())
local q1 = sw.quarters[1]
assert(q1.turn.degrees == -45, "clockwise turn")
local c = q1.wedge.coords
assert(#c == 8)
-- Lower left corner (the centre) stays at the icon centre.
assert(math.abs(c[3] - .5) < 1e-9 and math.abs(c[4] - .5) < 1e-9)
-- Upper left corner lands 45 degrees clockwise from 12 o'clock, 40px out.
local d = 40 * math.sqrt(.5)
assert(math.abs(c[1] - (.5 + d / 20)) < 1e-9 and math.abs(c[2] - (.5 - d / 20)) < 1e-9)
now = 104          -- 180 degrees
sw.scripts.OnUpdate(sw)
assert(state() == "--FF", state())
now = 107          -- 315 degrees
sw.scripts.OnUpdate(sw)
assert(state() == "---w" and sw.quarters[4].turn.degrees == -315, state())
now = 108
sw.scripts.OnUpdate(sw)
assert(not sw.shown and sw.scripts.OnUpdate == nil, "stops at the end")

sw:Start(200, 8, true)
now = 201
sw.scripts.OnUpdate(sw)
assert(state() == "w---" and sw.quarters[1].turn.degrees == 45, "reverse " .. state())
now = 205          -- 225 degrees
sw.scripts.OnUpdate(sw)
assert(state() == "FFw-" and sw.quarters[3].turn.degrees == -135, state())
sw:Stop()
assert(not sw.shown)

sw:SetArt("circle.tga"); sw:SetTint(1, 0, 0, .5)
for _, q in ipairs(sw.quarters) do
    assert(q.full.path == "circle.tga" and q.wedge.path == "circle.tga" and q.wedge.color[1] == 1 and q.full.color[4] == .5)
end
''')

disp = (root / 'EllesmereUICooldownManager' / 'EUI_CooldownManager_335_Display.lua').read_text(encoding='utf-8')
for need in ('bar.swipeStyle=="texture" and E.CreateTextureSwipe', 'b.swipe:Start(cs,cd,rev)',
             'b.swipe:SetArt(b.circle and CIRCLE or white)', 'if b.swipe then b.swipe:Stop() end'):
    assert need in disp, need
base = (root / 'EllesmereUICooldownManager' / 'EUI_CooldownManager_335.lua').read_text(encoding='utf-8')
assert 'swipeStyle="native",swipeR=0,swipeG=0,swipeB=0' in base
opts = (root / 'EllesmereUIOptions' / 'EUI_CooldownManager_335_Options.lua').read_text(encoding='utf-8')
assert 'O.D(s,"swipeStyle","Swipe Style",{native="Native",texture="Shaped"}' in opts
assert 'O.C(s,"swipe","Swipe Color",false' in opts
assert (core / 'media' / 'portraits' / 'circle_mask.tga').exists()
print('Texture swipe validation passed')
