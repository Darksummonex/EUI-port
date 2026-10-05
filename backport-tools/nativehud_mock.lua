-- Native HUD contracts, state changes and protected-frame layout guards.
local m=getmetatable(UIParent).__index
function m:GetObjectType() return self.kind end
function m:GetRegions() return unpack(self.regions or {}) end
function m:GetTexCoord() return unpack(self.texcoords or {0,1,0,1}) end
function m:GetNormalTexture() return self.normalTexture end
function m:GetPushedTexture() return self.pushedTexture end
function m:GetHighlightTexture() return self.highlightTexture end
function m:GetDisabledTexture() return self.disabledTexture end
function m:GetButtonState() return self.buttonState or 'NORMAL' end
function m:SetHitRectInsets(...) self.hitRect={...} end
function m:GetHitRectInsets() return unpack(self.hitRect or {0,0,20,0}) end
function m:IsEnabled() return self.enabled~=false end
function m:IsProtected() return self.protected or false end
function m:GetFont() return unpack(self.font or {'Fonts\\FRIZQT__.TTF',12,''}) end
function m:SetStatusBarColor(...) self.barColor={...} end
function m:GetStatusBarColor() return unpack(self.barColor or {1,1,1,1}) end
function m:SetStatusBarTexture(path) self:GetStatusBarTexture():SetTexture(path) end
function m:SetFrameLevel(v) self.level=v end
function m:GetFrameLevel() return self.level or 1 end
function m:SetFrameStrata(v) self.strata=v end
function m:GetFrameStrata() return self.strata or 'MEDIUM' end
function m:SetFont(...) self.font={...} end
local oldCreateFontString=m.CreateFontString
function m:CreateFontString(...)
    local fs=oldCreateFontString(self,...)
    -- The data bars create untemplated FontStrings; Wrath rejects text until
    -- SetFont succeeds. Other controls retain their existing template fixture.
    if self.kind=='StatusBar' then fs.requireFont=true end
    return fs
end
local oldSetText=m.SetText
function m:SetText(value)
    assert(not self.requireFont or self.font and self.font[1],'SetText(): Font not set')
    return oldSetText(self,value)
end
local oldCreateTexture=m.CreateTexture
function m:CreateTexture()
    local t=oldCreateTexture(self); table.remove(self.children); self.regions=self.regions or {}; self.regions[#self.regions+1]=t; return t
end
local create=CreateFrame
function CreateFrame(kind,name,parent,template) assert(not combat,'HUD created a frame in combat'); return create(kind,name,parent,template) end
for _,name in ipairs({'SetParent','SetPoint','ClearAllPoints','SetWidth','SetHeight','SetScale'}) do
    local original=m[name]
    m[name]=function(self,...) assert(not combat or restricted or not self:IsProtected(),'Insecure HUD layout in combat: '..name); return original(self,...) end
end
function m:HookScript(event,fn)
    local before=self.hooks[event]
    self.hooks[event]=function(...) if before then before(...) end; fn(...) end
end
function m:RunScript(event,...) if self.scripts[event] then self.scripts[event](self,...) end; if self.hooks[event] then self.hooks[event](self,...) end end
function hooksecurefunc(target,name,fn)
    if type(target)=='string' then fn,name,target=name,target,_G end
    local original=target[name]; assert(type(original)=='function')
    target[name]=function(...) local a,b=original(...); fn(...); return a,b end
end
MainMenuBarTexture0.kind='Texture'; MainMenuBarTexture0:SetTexture('Interface\\MainMenuBar\\UI-MainMenuBar-Left')
MainMenuBar=CreateFrame('Frame','MainMenuBar',UIParent)
MainMenuBarArtFrame=CreateFrame('Frame','MainMenuBarArtFrame',MainMenuBar)
MainMenuBarArtFrame.art=MainMenuBarArtFrame:CreateTexture(); MainMenuBarArtFrame.art:SetTexture('Interface\\MainMenuBar\\UI-MainMenuBar-Right')
MainMenuBarArtFrame.art:SetAlpha(.7)
MainMenuBarArtFrame.functionalChild=CreateFrame('Button',nil,MainMenuBarArtFrame)
function NativeHUDButton(name)
    local b=_G[name] or CreateFrame('Button',name,nativeParent); b.kind='Button'; b.protected=true
    b:SetWidth(28); b:SetHeight(58); b:SetPoint('BOTTOMRIGHT',nativeParent,'BOTTOMRIGHT',-5,5)
    b.normalTexture=b:CreateTexture(); b.normalTexture:SetTexture('native-normal-'..name)
    b.pushedTexture=b:CreateTexture(); b.pushedTexture:SetTexture('native-pushed-'..name)
    b.highlightTexture=b:CreateTexture(); b.highlightTexture:SetTexture('native-highlight-'..name)
    b:SetScript('OnClick',function(self) self.nativeClicks=(self.nativeClicks or 0)+1 end)
    b:SetScript('OnReceiveDrag',function(self) self.nativeDrags=(self.nativeDrags or 0)+1 end)
    b:SetScript('OnEnter',function(self) nativeHover=self end)
    return b
end
for _,name in ipairs({'CharacterMicroButton','SpellbookMicroButton','TalentMicroButton','MainMenuMicroButton','HelpMicroButton','ParagonMicroButton','CollectionsMicroButton','StoreMicroButton'}) do NativeHUDButton(name) end
StoreMicroButtonIcon=StoreMicroButton:CreateTexture(); StoreMicroButtonIcon:SetTexture('Interface\\Store\\StoreButton')
for _,name in ipairs({'MainMenuBarBackpackButton','CharacterBag0Slot','CharacterBag1Slot','CharacterBag2Slot','CharacterBag3Slot'}) do
    local b=NativeHUDButton(name); _G[name..'IconTexture']=b:CreateTexture(); _G[name..'IconTexture']:SetTexture('bag-icon-'..name)
end
NativeHUDButton('KeyRingButton')
function SetPortraitTexture(t,unit) t:SetTexture('portrait-'..unit) end
MainMenuExpBar.protected=false; MainMenuExpBar:SetScript('OnMouseDown',function(self,button) xpRightClick={self,button} end)
-- These XP decorations are Texture regions in Wrath, not Frames. Expose the
-- actual missing Frame-only methods instead of inheriting the permissive mock.
local textureAbsent={GetScale=true,SetScale=true,GetRegions=true,GetStatusBarTexture=true,
    IsMouseEnabled=true,EnableMouse=true,GetHitRectInsets=true,SetHitRectInsets=true,GetScript=true,SetScript=true}
for _,name in ipairs({'ExhaustionLevelFillBar','ExhaustionTick'}) do
    local t=MainMenuExpBar:CreateTexture(); _G[name]=t
    t:SetTexture('native-'..name); t:SetAlpha(.65); t:SetTexCoord(.1,.9,.2,.8)
    setmetatable(t,{__index=function(_,key) if not textureAbsent[key] then return m[key] end end})
end
ReputationWatchBar=CreateFrame('Frame','ReputationWatchBar',nativeParent); ReputationWatchBar:SetAlpha(.75)
BuffFrame=CreateFrame('Frame','BuffFrame',UIParent); BuffFrame:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-10,-10); BuffFrame:SetWidth(200); BuffFrame:SetHeight(60)
TemporaryEnchantFrame=CreateFrame('Frame','TemporaryEnchantFrame',BuffFrame)
TempEnchant1=CreateFrame('Button','TempEnchant1',TemporaryEnchantFrame); TempEnchant1:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-20,-15)
ConsolidatedBuffs=CreateFrame('Button','ConsolidatedBuffs',BuffFrame); ConsolidatedBuffs:Hide()
for _,prefix in ipairs({'BuffButton','DebuffButton'}) do
    for i=1,12 do
        local b=CreateFrame('Button',prefix..i,BuffFrame); b:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-10,-10); b:SetWidth(30); b:SetHeight(30)
        b:SetScript('OnMouseUp',function(self,key) auraAction={self,key} end)
        b:SetScript('OnUpdate',function(self) self.timerTicks=(self.timerTicks or 0)+1 end)
    end
end
level,xp,xpmax,rested=70,250,1000,200
faction={'Test Faction',5,3000,9000,4500}
MAX_PLAYER_LEVEL=80
function UnitXP() return xp end
function UnitXPMax() return xpmax end
function UnitLevel() return level end
function GetXPExhaustion() return rested end
function GetWatchedFactionInfo() return unpack(faction) end
FACTION_BAR_COLORS={[5]={r=.2,g=.8,b=.3}}
function BuffFrame_UpdateAllBuffAnchors() BuffButton1:ClearAllPoints(); BuffButton1:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-10,-10); return 'native-buff-result' end
function DebuffButton_UpdateAnchors() DebuffButton1:ClearAllPoints(); DebuffButton1:SetPoint('TOPRIGHT',BuffButton1,'BOTTOMRIGHT',0,-12) end
function UIParent_ManageFramePositions() return 'native-layout-result' end
function UpdateMicroButtons() return 'native-micro-result' end
function ReputationWatchBar_Update() return 'native-rep-result' end
function GameTooltip:AddLine(...) self.lines=self.lines or {}; self.lines[#self.lines+1]={...} end
function GameTooltip:SetOwner(f) self.owner=f; self.lines={} end
-- IsUnlockModeActive is supplied by the real Core method in the validator.
