"""Real tooltip fade blocks under strict Wrath and modern animation APIs."""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'.codex-tools'))
from lupa.lua51 import LuaRuntime
s=(root/'EllesmereUI/EllesmereUI_UICore.lua').read_text()
fade='local function Show()\n'+s.split('    -- Cancel an in-progress fade-out',1)[1].split('local function HideWidgetTooltip',1)[0]
# The extraction starts after a complete comment line, at executable code.
fade=fade.replace(" so its OnFinished doesn't hide us\n",'',1)
hide='local function HideWidgetTooltip'+s.split('local function HideWidgetTooltip',1)[1].split('EllesmereUI.ShowWidgetTooltip',1)[0]
for modern in (False,True):
 lua=LuaRuntime()
 lua.globals().modern=modern
 lua.execute(r'''
 tt={alpha=0,shown=true,scale=1.5}
 function tt:SetAlpha(a) self.alpha=a end
 function tt:GetAlpha() return self.alpha end
 function tt:IsShown() return self.shown end
 function tt:Hide() self.shown=false end
 function tt:SetScale(s) self.scale=s end
 function tt:CreateAnimationGroup()
  local g={scripts={}}
  function g:CreateAnimation(kind)
   assert(kind=='Alpha'); local a={}
   function a:SetDuration(d) self.duration=d end
   function a:SetSmoothing(s) self.smoothing=s end
   if modern then
    function a:SetFromAlpha(v) self.from=v end
    function a:SetToAlpha(v) self.to=v end
   else
    function a:SetChange(v) self.change=v end
   end
   self.animation=a; return a
  end
  function g:SetScript(k,f) self.scripts[k]=f end
  function g:Stop() self.playing=false; self.stops=(self.stops or 0)+1 end
  function g:Play() self.playing=true end
  function g:Finish() if self.playing then self.playing=false; self.scripts.OnFinished() end end
  return g
 end
 local function GetTooltipFrame() return tt end
 ''')
 # GetTooltipFrame must share the same lexical scope as the real functions.
 lua.execute('function GetTooltipFrame() return tt end\n'+fade+hide+'\nShowFade=Show; HideFade=HideWidgetTooltip')
 lua.execute(r'''
 ShowFade(); assert(tt._fadeAG.playing and tt.alpha==0)
 if modern then assert(tt._fadeIn.from==0 and tt._fadeIn.to==1)
 else assert(tt._fadeIn.change==1) end
 tt._fadeAG:Finish(); assert(tt.alpha==1)
 tt.alpha=.4; HideFade(); assert(tt._fadeOutAG.playing)
 if modern then assert(tt._fadeOut.from==.4 and tt._fadeOut.to==0)
 else assert(tt._fadeOut.change==-.4) end
 -- Hovering again cancels the hide and keeps the tooltip visible.
 tt.alpha=0; ShowFade(); assert(not tt._fadeOutAG.playing)
 tt._fadeOutAG:Finish(); assert(tt.shown)
 tt._fadeAG:Finish(); assert(tt.alpha==1)
 HideFade(); tt._fadeOutAG:Finish(); assert(not tt.shown and tt.alpha==0 and tt.scale==1)
 tt.shown=true; tt.alpha=1; tt.scale=1.5; ShowFade(); HideFade(true)
 assert(not tt.shown and tt.alpha==0 and tt.scale==1 and not tt._fadeAG.playing)
 ''')
print('PASS: actual tooltip fade-in/out blocks with Wrath SetChange and native endpoints; interrupted hover, instant hide, opacity and scale cleanup')