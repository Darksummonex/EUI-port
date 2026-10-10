-- Explicit anonymous Wrath plate shape; no Retail namespaces or unit tokens.
C_NamePlate=nil; C_UnitAuras=nil; C_Spell=nil; C_Timer=nil; C_CVar=nil; C_Texture=nil
local m=getmetatable(UIParent).__index
function m:GetObjectType() return self.kind end
function m:GetChildren() return unpack(self.children) end
function m:GetRegions() return unpack(self.regions or {}) end
local oldTexture,oldFont=m.CreateTexture,m.CreateFontString
local function Region(self,ctor)
    local r=ctor(self); table.remove(self.children); self.regions=self.regions or {}; table.insert(self.regions,r); return r
end
function m:CreateTexture() return Region(self,oldTexture) end
function m:CreateFontString() return Region(self,oldFont) end
function m:GetMinMaxValues() return self.minimum or 0,self.maximum or 100 end
function m:GetValue() return self.value or 0 end
function m:SetValue(v) self.value=v; self:RunScript('OnValueChanged',v) end
function m:SetAlpha(v) self.alpha=v end
function m:GetAlpha() return self.alpha or 1 end
function m:SetScale(v) self.scale=v end
function m:GetScale() return self.scale or 1 end
function m:SetPoint(...) self.point={...} end
function m:ClearAllPoints() self.point=nil end
function m:SetAllPoints(f) self.allPoints=f end
function m:EnableMouse(v) self.mouse=v end
function m:SetBackdrop(v) self.backdrop=v end
function m:SetBackdropBorderColor(...) self.borderColor={...} end
function m:SetVertexColor(...) self.color={...} end
function m:GetVertexColor() return unpack(self.color or {1,1,1,1}) end
function m:SetTextColor(...) self.textColor={...} end
function m:GetTextColor() return unpack(self.textColor or {1,1,1,1}) end
function m:SetStatusBarColor(...) self.barColor={...} end
function m:GetStatusBarColor() return unpack(self.barColor or {1,0,0,1}) end
function m:SetStatusBarTexture(v) self.barTexture=v end
function m:GetTexCoord() return unpack(self.texcoords or {0,1,0,1}) end
function m:SetWordWrap(v) self.wordWrap=v end
function m:SetNonSpaceWrap(v) self.nonSpaceWrap=v end
fontWrites=0
function m:SetFont(...) self.font={...}; fontWrites=fontWrites+1 end
function m:RunScript(k,...) if self.scripts[k] then self.scripts[k](self,...) end; if self.hooks[k] then self.hooks[k](self,...) end end
function m:Show() local changed=not self.shown; self.shown=true; if changed then self:RunScript('OnShow') end end
function m:Hide() local changed=self.shown; self.shown=false; if changed then self:RunScript('OnHide') end end
WorldFrame=CreateFrame('Frame')
function NativePlate(name,alpha)
    local f=CreateFrame('Frame',nil,WorldFrame); f:SetWidth(110); f:SetHeight(45); f:SetAlpha(alpha or 1)
    f:EnableMouse(true); f:SetPoint('CENTER',WorldFrame,'CENTER',10,20)
    for i=1,11 do
        local r=i==7 or i==8; local obj=r and f:CreateFontString() or f:CreateTexture()
        if i~=1 and i~=2 and i~=3 and i~=7 and i~=8 then obj:Hide() end
    end
    f.regions[1]:SetTexture('Interface\\TargetingFrame\\UI-TargetingFrame-Flash.blp'); f.regions[1]:Hide()
    f.regions[7]:SetText(name); f.regions[8]:SetText('80')
    local h=CreateFrame('StatusBar',nil,f); h:SetMinMaxValues(0,100); h:SetValue(60); h:SetStatusBarColor(1,0,0)
    local c=CreateFrame('StatusBar',nil,f); c:SetMinMaxValues(0,3); c:SetValue(1); c:Hide()
    f.clicks=0; f:SetScript('OnMouseDown',function(self) self.clicks=self.clicks+1 end)
    return f
end
plateA=NativePlate('Mob',1); plateB=NativePlate('Other',.5)
irrelevant=CreateFrame('Frame',nil,WorldFrame)
foreign=NativePlate('Foreign',.5); foreign.UnitFrame={}
units={}
function UnitExists(u) return units[u]~=nil end
function UnitName(u) return units[u] and units[u].name end
function UnitGUID(u) return units[u] and units[u].guid end
function UnitReaction(_,u) return units[u] and units[u].reaction or 1 end
function UnitIsPlayer(u) return units[u] and units[u].player or false end
function UnitClass(u) local class=units[u] and units[u].class or 'WARRIOR'; return class,class end
RAID_CLASS_COLORS.MAGE={r=.25,g=.78,b=.92}
RAID_CLASS_COLORS.PRIEST={r=1,g=1,b=1}
function UnitCastingInfo(u) local t=units[u]; if t and t.cast then return 'Fireball','Rank 1','Fireball','fire-icon',1000,6000,false,42,t.locked end end
function UnitChannelInfo(u) local t=units[u]; if t and t.channel then return 'Drain Life','Rank 1','Drain Life','drain-icon',1000,6000,false,t.locked end end
function UnitAura(u,i,filter)
    local t=units[u]; local a=t and t.auras and t.auras[filter]; a=a and a[i]
    if a then return a.name,'Rank 1',a.icon or 'debuff-icon',a.stacks or 1,nil,10,a.expires or 12,a.caster,nil,nil,a.spellID end
end
combat=false
function InCombatLockdown() return combat end
function UnitThreatSituation(_,u) local t=units[u]; return t and t.threat end
function UnitAffectingCombat(u) local t=units[u]; return t and t.combat or false end
groupSize=0
function GetNumPartyMembers() return groupSize end
instanceType='none'
function IsInInstance() return instanceType~='none',instanceType end
comboPoints=0
function GetComboPoints() return comboPoints end
spellNames={[5308]='Execute',[24275]='Hammer of Wrath',[53351]='Kill Shot',[1120]='Drain Soul',[71]='Defensive Stance'}
knownSpells={}
function GetSpellInfo(id)
    if type(id)=='number' then return spellNames[id] end
    if knownSpells[id] then return id end
end
cvars={showVKeyCastbar='0',nameplateShowEnemies='1',nameplateShowFriends='0',nameplateAllowOverlap='0',ShowClassColorInNameplate='0',nameplateShowEnemyPets='0'}
function GetCVar(k) assert(cvars[k]~=nil,k); return cvars[k] end
function SetCVar(k,v) assert(not combat,'CVar write in combat'); assert(cvars[k]~=nil,k); cvars[k]=v end
function IsLoggedIn() return true end
function EllesmereUI.GetFontOutlineFlag() return 'OUTLINE,SLUG' end
function EllesmereUI.PrintError(v) rendererWarning=v end
function EllesmereUI.EnsureOptionsLoaded() optionsLoaded=true end
function EllesmereUI:ShowModule(v) shownModule=v end
function EllesmereUI:InvalidatePageCache() end
rows={}
EllesmereUI.Widgets={}
function EllesmereUI.Widgets:DualRow(_,_,left,right) rows[#rows+1]={left,right}; return CreateFrame('Frame'),50 end
function EllesmereUI.Widgets:SectionHeader() return CreateFrame('Frame'),30 end
