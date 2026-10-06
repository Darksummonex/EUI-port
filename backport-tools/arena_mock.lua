-- Native 3.3.5 arena contracts: arenaN units, battlefield status, combat log and secure lockdown.
local m=getmetatable(UIParent).__index
function m:SetVertexColor(...) self.vertexColor={...} end
function m:SetTextColor(...) self.textColor={...} end
function m:SetStatusBarColor(...) self.color={...} end
function m:GetMinMaxValues() return self.minimum or 0,self.maximum or 1 end
function m:GetValue() return self.value end
function m:SetFrameStrata(v) self.strata=v end
function m:RegisterForClicks(...) self.clicks={...} end
local function Locked(self) return combat and (self.template=="SecureUnitButtonTemplate" or self.name=="EllesmereUIArenaHolder" or self.name=="ArenaEnemyFrames") end
for _,key in ipairs({"Show","Hide","SetPoint","ClearAllPoints","SetWidth","SetHeight","SetParent","SetAttribute"}) do
    local before=m[key]
    m[key]=function(self,...) assert(not Locked(self),"Protected "..key.." in combat on "..tostring(self.name)); return before(self,...) end
end
inside,instanceKind=false,"none"
function IsInInstance() return inside,instanceKind end
bracket=nil
function GetBattlefieldStatus(i) if i==1 and bracket then return "active","Nagrand Arena",1,80,80,bracket,1 end; return "none" end
SPELL_NAMES={[642]="Divine Shield",[408]="Kidney Shot",[118]="Polymorph",[42292]="PvP Trinket"}
function GetSpellInfo(id) return SPELL_NAMES[id] or ("Spell"..id),nil,"icon"..id end
units={}; auras={}; casts={}; channels={}; targetUnit=nil
function UnitExists(u) return u=="player" or units[u]~=nil end
function UnitName(u) local d=units[u]; if d then return d.name end; return u end
function UnitClass(u) local d=units[u]; if d then return d.class,d.class end; return playerClass,playerClass end
function UnitGUID(u) local d=units[u]; return d and d.guid or u end
function UnitHealth(u) local d=units[u]; return d and d.hp or 25 end
function UnitHealthMax(u) local d=units[u]; return d and d.max or 100 end
function UnitIsDeadOrGhost(u) local d=units[u]; return d and d.dead or false end
function UnitFactionGroup(u) local d=units[u]; if d then return d.faction end; return "Alliance" end
function UnitIsUnit(a,b) if a=="target" then return b==targetUnit end; return a==b end
function UnitAura(u,i,filter) local list=auras[u] and auras[u][filter]; local a=list and list[i]; if a then return a.name,nil,a.icon,0,nil,a.duration,a.expires,"x",false,false,a.id end end
function UnitCastingInfo(u) local c=casts[u]; if c then return c.name,"",c.name,c.icon,c.s,c.e,false,1,c.ni end end
function UnitChannelInfo(u) local c=channels[u]; if c then return c.name,"",c.name,c.icon,c.s,c.e,false,c.ni end end
RAID_CLASS_COLORS.MAGE={r=.25,g=.78,b=.92}
EllesmereUI.CLASS_ICON_SPRITE_COORDS.MAGE={.125,.25,0,.125}
panelShown,activeModule=false,nil
function EllesmereUI:IsShown() return panelShown end
function EllesmereUI:GetActiveModule() return activeModule end
