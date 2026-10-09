"""Real native tooltip hooks: spell/action/macro/aura/link IDs and deduplication."""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / '.codex-tools'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime()
lua.execute((root / 'backport-tools/wrath_mock.lua').read_text(encoding='utf-8-sig'))
lua.execute('''
EUI_WOW_335=true
EllesmereUI.GetAccentColor=function() return .2,.6,.9 end
EllesmereUIDB={}
shift,control,alt=false,false,false
IsShiftKeyDown=function() return shift end
IsControlKeyDown=function() return control end
IsAltKeyDown=function() return alt end
UnitBuff=function() return "Buff","Rank 1","icon",1,nil,10,20,"player",false,false,111 end
UnitDebuff=function() return "Debuff","Rank 2","icon",1,nil,10,20,"target",false,false,222 end
UnitAura=function() return "Aura","Rank 3","icon",1,nil,10,20,"player",false,false,333 end
GetActionInfo=function(slot)
 if slot==1 then return "spell",7,"spell",444 elseif slot==2 then return "macro",5 elseif slot==4 then return "spell",9,"spell" else return "item",999 end
end
GetMacroSpell=function() return "Fireball","Rank 2" end
GetSpellLink=function(name,rank)
 if name==9 then assert(rank=="spell"); return "|Hspell:666|h[Frostbolt]|h" end
 assert(name=="Fireball" and rank=="Rank 2"); return "|Hspell:555|h[Fireball]|h"
end
hooksecurefunc=function(obj,key,fn)
 local old=obj[key]
 obj[key]=function(self,...) old(self,...); fn(self,...) end
end
local m=getmetatable(UIParent).__index
function m:GetName() return self.name end
function m:HookScript(event,fn)
 self.hooks[event]=self.hooks[event] or {}; table.insert(self.hooks[event],fn)
end
function m:Run(event,...)
 for _,fn in ipairs(self.hooks[event] or {}) do fn(self,...) end
end
function m:NumLines() return #(self.lines or {}) end
function m:ClearLines()
 self.lines={}; self.spell=nil
 self:Run("OnTooltipCleared")
end
function m:AddDoubleLine(left,right,...)
 self.lines=self.lines or {}
 local i=#self.lines+1; self.lines[i]={left,right}
 _G[self.name.."TextLeft"..i]={GetText=function() return left end}
 _G[self.name.."TextRight"..i]={GetText=function() return right end}
end
function m:GetSpell() return "Fireball","Rank 1",self.spell end
function m:SetSpellByID(id) self:ClearLines(); self.spell=id; self:Run("OnTooltipSetSpell") end
function m:SetHyperlink(link) self:ClearLines() end
function m:SetUnitBuff(...) self:ClearLines() end
function m:SetUnitDebuff(...) self:ClearLines() end
function m:SetUnitAura(...) self:ClearLines() end
function m:SetAction(slot) self:ClearLines(); if slot==1 then self.spell=444; self:Run("OnTooltipSetSpell") end end
GameTooltip=CreateFrame("GameTooltip"); GameTooltip.name="GameTooltip"
ItemRefTooltip=CreateFrame("GameTooltip"); ItemRefTooltip.name="ItemRefTooltip"
''')
source = (root / 'EllesmereUI/EUI_TooltipIDs_335.lua').read_text(encoding='utf-8-sig')
lua.execute(source)
lua.execute('''
local t=GameTooltip
t:SetSpellByID(123); assert(t:NumLines()==0)
EllesmereUIDB.showSpellID=true
t:SetSpellByID(123); assert(t:NumLines()==1 and t.lines[1][2]=="123")
t:Run("OnTooltipSetSpell"); assert(t:NumLines()==1)
t:SetSpellByID(456); assert(t:NumLines()==1 and t.lines[1][2]=="456")
t:SetUnitBuff("player",1); assert(t.lines[1][2]=="111" and t:NumLines()==1)
t:SetUnitDebuff("target",1); assert(t.lines[1][2]=="222")
t:SetUnitAura("player",1,"HELPFUL"); assert(t.lines[1][2]=="333")
t:SetHyperlink("spell:777"); assert(t.lines[1][2]=="777")
ItemRefTooltip:SetHyperlink("|Hspell:888|h[Spell]|h"); assert(ItemRefTooltip.lines[1][2]=="888")
t:SetHyperlink("item:777"); assert(t:NumLines()==0)
t:SetAction(1); assert(t.lines[1][2]=="444" and t:NumLines()==1)
t:SetAction(2); assert(t.lines[1][2]=="555")
t:SetAction(3); assert(t:NumLines()==0)
t:SetAction(4); assert(t.lines[1][2]=="666","Spellbook slot falls back to the spell link ID")
EllesmereUIDB.spellIDModifier="shift"; t:SetSpellByID(123); assert(t:NumLines()==0)
shift=true; t:SetSpellByID(123); assert(t:NumLines()==1)
EllesmereUIDB.spellIDModifier="control"; t:SetSpellByID(123); assert(t:NumLines()==0)
control=true; t:SetSpellByID(123); assert(t:NumLines()==1)
EllesmereUIDB.spellIDModifier="alt"; t:SetSpellByID(123); assert(t:NumLines()==0)
alt=true; t:SetSpellByID(123); assert(t:NumLines()==1)
EllesmereUIDB.spellIDModifier="none"
t:ClearLines(); t:AddDoubleLine("SpellID","123"); EllesmereUI._wrathTooltipIDs.Add(t,123); assert(t:NumLines()==1)
t:ClearLines(); t:AddDoubleLine("|cFFCA3C3CID|r 123",""); EllesmereUI._wrathTooltipIDs.Add(t,123); assert(t:NumLines()==1)
t:ClearLines(); EllesmereUI._wrathTooltipIDs.Add(t,nil); EllesmereUI._wrathTooltipIDs.Add(t,0); assert(t:NumLines()==0)
EllesmereUIDB.showSpellID=false; t:SetUnitBuff("player",1); assert(t:NumLines()==0)
''')
lua.execute(source)  # idempotent file/event initialization
lua.execute('''
EllesmereUIDB.showSpellID=true
for _,f in ipairs(allFrames) do
 if f.events.ADDON_LOADED and f:GetScript("OnEvent") then
  for i=1,5 do f:GetScript("OnEvent")(f,"ADDON_LOADED","AnotherAddon") end
 end
end
assert(#GameTooltip.hooks.OnTooltipSetSpell==1)
GameTooltip:SetSpellByID(321); assert(GameTooltip:NumLines()==1)
''')
print('PASS: spell/action/macro/aura/chat-link tooltip IDs; default/toggle/modifiers, refresh/dedup, other-addon coexistence, invalid IDs and idempotent registration')
