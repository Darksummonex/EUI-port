_G.EUI_WOW_335 = true
-- EllesmereUI core compatibility layer for WoW 3.3.5.
EUI_CLIENT_BLOCKED=false
EUI_CLIENT_FOREVER=false
-- Retail exposes securecallfunction(); the 3.3.5 client does not.
-- CallbackHandler-1.0 v8 localizes this global while loading, so this
-- compatibility function must exist before the library is loaded.
if not securecallfunction then
 function securecallfunction(func, ...)
  if type(func) ~= "function" then
   error("securecallfunction: function expected", 2)
  end
  return func(...)
 end
end
C_Timer=C_Timer or {}
do
 local frame,timers
 local function ensure()
  if frame then return end
  frame=CreateFrame('Frame','EUI335TimerFrame'); frame:Hide()
  frame:SetScript('OnUpdate',function(_,e)
   for i=#timers,1,-1 do local t=timers[i]
    if t.cancelled then table.remove(timers,i)
    else t.delay=t.delay-e; if t.delay<=0 then
     if t.repeating then t.delay=t.interval else table.remove(timers,i) end
     local ok,err=pcall(t.callback,t); if not ok and geterrorhandler then geterrorhandler()(err) end
    end end
   end
   if #timers==0 then frame:Hide() end
  end)
 end
 local function add(delay,cb,repeatable,iterations)
  ensure(); timers=timers or {}; local n=0
  local t={delay=math.max(0,delay or 0),interval=math.max(.001,delay or .001),callback=function(self)
   n=n+1; cb(self); if iterations and n>=iterations then self:Cancel() end
  end,repeating=repeatable}; function t:Cancel() self.cancelled=true end
  timers[#timers+1]=t; frame:Show(); return t
 end
 function C_Timer.After(d,cb) add(d,cb,false) end
 function C_Timer.NewTimer(d,cb) return add(d,cb,false) end
 function C_Timer.NewTicker(d,cb,n) return add(d,cb,true,n) end
end
C_AddOns=C_AddOns or {}
C_AddOns.IsAddOnLoaded=C_AddOns.IsAddOnLoaded or IsAddOnLoaded
C_AddOns.GetAddOnInfo=C_AddOns.GetAddOnInfo or GetAddOnInfo
C_AddOns.GetAddOnEnableState=C_AddOns.GetAddOnEnableState or GetAddOnEnableState
C_AddOns.EnableAddOn=C_AddOns.EnableAddOn or EnableAddOn
C_AddOns.DisableAddOn=C_AddOns.DisableAddOn or DisableAddOn
C_AddOns.LoadAddOn=C_AddOns.LoadAddOn or LoadAddOn
C_AddOns.GetNumAddOns=C_AddOns.GetNumAddOns or GetNumAddOns
C_Spell=C_Spell or {}
C_Spell.GetSpellInfo=C_Spell.GetSpellInfo or function(id)
 -- 3.3.5 order: name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange.
 local name, rank, icon, _, _, _, castTime, minRange, maxRange = GetSpellInfo(id)
 if not name then return nil end
 return {name=name, subName=rank, iconID=icon, castTime=castTime, minRange=minRange, maxRange=maxRange, spellID=tonumber(id) or tonumber((GetSpellLink and GetSpellLink(id) or ""):match("spell:(%d+)"))}
end
C_Spell.GetSpellTexture=C_Spell.GetSpellTexture or function(id) return GetSpellTexture(id) end
C_Spell.GetSpellCooldown=C_Spell.GetSpellCooldown or function(id)
 local startTime, duration, isEnabled = GetSpellCooldown(id)
 return {startTime=startTime or 0, duration=duration or 0, isEnabled=isEnabled ~= 0, modRate=1}
end
C_Spell.GetSpellCharges=C_Spell.GetSpellCharges or function(id)
 if not GetSpellCharges then return nil end
 local currentCharges, maxCharges, cooldownStartTime, cooldownDuration = GetSpellCharges(id)
 if currentCharges == nil then return nil end
 return {currentCharges=currentCharges, maxCharges=maxCharges, cooldownStartTime=cooldownStartTime or 0, cooldownDuration=cooldownDuration or 0, chargeModRate=1}
end
C_Spell.IsSpellUsable=C_Spell.IsSpellUsable or function(id) return IsUsableSpell(id) end
C_Spell.IsSpellInRange=C_Spell.IsSpellInRange or function(id,u) return IsSpellInRange(id,u) end
C_Spell.RequestLoadSpellData=C_Spell.RequestLoadSpellData or function() end
C_Item=C_Item or {}
C_Item.GetItemInfo=C_Item.GetItemInfo or function(i) return GetItemInfo(i) end
C_Item.GetItemInfoInstant=C_Item.GetItemInfoInstant or function(i) return GetItemInfoInstant(i) end
C_Item.GetItemIconByID=C_Item.GetItemIconByID or function(i) return GetItemIcon(i) end
C_Item.GetItemQualityColor=C_Item.GetItemQualityColor or function(q) return GetItemQualityColor(q) end
C_Container=C_Container or {}
C_Container.GetContainerNumSlots=C_Container.GetContainerNumSlots or GetContainerNumSlots
C_Container.GetContainerItemLink=C_Container.GetContainerItemLink or GetContainerItemLink
C_Container.GetContainerItemInfo=C_Container.GetContainerItemInfo or function(b,s)local a,b2,c,d,e,f,g=GetContainerItemInfo(b,s);return{iconFileID=a,stackCount=b2,isLocked=c,quality=d,hyperlink=g}end
C_Container.UseContainerItem=C_Container.UseContainerItem or UseContainerItem
C_Container.PickupContainerItem=C_Container.PickupContainerItem or PickupContainerItem
C_UnitAuras=C_UnitAuras or {}
C_UnitAuras.GetAuraDataByIndex=C_UnitAuras.GetAuraDataByIndex or function(u,i,f)local n,ic,c,d,du,ex,src,st,_,sid=UnitAura(u,i,f);if not n then return end;return{name=n,icon=ic,applications=c,dispelName=d,duration=du,expirationTime=ex,sourceUnit=src,isStealable=st,spellId=sid}end
C_SpecializationInfo=C_SpecializationInfo or {}
-- Wrath has talent trees rather than Retail specializations.  Expose the dominant
-- talent tab through the modern API shape so core/profile code can query it safely.
local function EUI335_GetDominantTalentTab()
    if not GetNumTalentTabs or not GetTalentTabInfo then return nil end
    local best, bestPoints = nil, -1
    for i = 1, (GetNumTalentTabs() or 0) do
        local _, _, points = GetTalentTabInfo(i)
        points = tonumber(points) or 0
        if points > bestPoints then best, bestPoints = i, points end
    end
    return best
end
C_SpecializationInfo.GetSpecialization=C_SpecializationInfo.GetSpecialization or EUI335_GetDominantTalentTab
C_SpecializationInfo.GetSpecializationInfo=C_SpecializationInfo.GetSpecializationInfo or function(index)
    index = tonumber(index) or EUI335_GetDominantTalentTab()
    if not index or not GetTalentTabInfo then return nil end
    local name, icon, points = GetTalentTabInfo(index)
    if not name then return nil end
    local _, class = UnitClass('player')
    -- Stable Wrath-only synthetic ID; Retail spec IDs do not exist on 3.3.5.
    local classIDs = {WARRIOR=1,PALADIN=2,HUNTER=3,ROGUE=4,PRIEST=5,DEATHKNIGHT=6,SHAMAN=7,MAGE=8,WARLOCK=9,DRUID=11}
    local id = 33000 + ((classIDs[class] or 0) * 10) + index
    return id, name, nil, icon, nil, nil, points
end
if not GetNumSpecializations then
    GetNumSpecializations=function() return GetNumTalentTabs and GetNumTalentTabs() or 0 end
end
C_ChallengeMode=C_ChallengeMode or {IsChallengeModeActive=function()return false end}
C_EditMode=C_EditMode or {}; C_AddOnProfiler=C_AddOnProfiler or {}; C_GamePad=C_GamePad or {}; C_InputInterfaceStyle=C_InputInterfaceStyle or {}; C_PlayerInfo=C_PlayerInfo or {}; C_ToyBox=C_ToyBox or {}; C_Garrison=C_Garrison or {}; C_Housing=C_Housing or {}; C_PvP=C_PvP or {}
if not IsUsingGamepad then IsUsingGamepad=function() return false end end
C_GamePad.IsEnabled=C_GamePad.IsEnabled or function() return false end
C_GamePad.GetAllDeviceIDs=C_GamePad.GetAllDeviceIDs or function() return {} end
C_GamePad.GetDeviceRawState=C_GamePad.GetDeviceRawState or function() return nil end
C_CVar=C_CVar or {}; C_CVar.GetCVar=C_CVar.GetCVar or GetCVar; C_CVar.SetCVar=C_CVar.SetCVar or SetCVar
-- Some custom 3.3.5 clients ship an addon-level C_Texture whose GetAtlasInfo
-- raises an error for unknown atlases; Retail returns nil, and EUI probes
-- Retail atlas names at file load. Wrap such a version so a miss is nil.
C_Texture=C_Texture or {}
function EUI335_SafeAtlasInfo()
 local current=C_Texture.GetAtlasInfo
 if not current then C_Texture.GetAtlasInfo=function() return nil end
 elseif current~=C_Texture._euiSafeAtlasInfo then
  local safe=function(atlas,...)
   local ok,info=pcall(current,atlas,...)
   if ok then return info end
  end
  C_Texture.GetAtlasInfo=safe; C_Texture._euiSafeAtlasInfo=safe
 end
end
EUI335_SafeAtlasInfo()
-- Modern LibSharedMedia checks media paths through C_UIFileAsset.IsKnownFile.
-- Wrath 3.3.5 has no equivalent path validator; returning true preserves the
-- classic behavior where SetFont/SetTexture performs the actual file lookup.
C_UIFileAsset=C_UIFileAsset or {}
C_UIFileAsset.IsKnownFile=C_UIFileAsset.IsKnownFile or function(path) return type(path) == 'string' and path ~= '' end
C_Secrets=C_Secrets or {}; C_CurveUtil=C_CurveUtil or {}; C_ClassColor=C_ClassColor or {}
Enum=Enum or {}; Enum.PowerType=Enum.PowerType or {Mana=0,Rage=1,Focus=2,Energy=3,RunicPower=6}; Enum.SpellBookSpellBank=Enum.SpellBookSpellBank or {Player=0,Pet=1}
if not CreateColor then function CreateColor(r,g,b,a)local c={r=r or 0,g=g or 0,b=b or 0,a=a==nil and 1 or a};function c:GetRGBA()return self.r,self.g,self.b,self.a end;function c:GetRGB()return self.r,self.g,self.b end;function c:SetRGBA(x,y,z,w)self.r,self.g,self.b,self.a=x,y,z,w end;return c end end

-- Wrath has no colour-texture API, and solid SetTexture(r,g,b,a) textures ignore
-- gradients. Other addons' polyfills (AruiQOL) push alpha through SetAlpha, which
-- then sticks on later calls, so the Retail contract is always installed here.
if (GetBuildInfo and select(4, GetBuildInfo()) or 0) < 70000 then
 local idx = getmetatable(CreateFrame("Frame"):CreateTexture()).__index
 local setTexture, gradientAlpha = idx.SetTexture, idx.SetGradientAlpha
 idx.SetColorTexture = function(self, r, g, b, a)
  self._euiSolid = true
  r, g, b, a = r or 0, g or 0, b or 0, a == nil and 1 or a
  self._euiR, self._euiG, self._euiB, self._euiA = r, g, b, a
  setTexture(self, r, g, b, a)
 end
 if gradientAlpha then
  local nativeGradient = idx.SetGradient
  local function RGBA(c)
   if c.GetRGBA then return c:GetRGBA() end
   return c.r or 0, c.g or 0, c.b or 0, c.a == nil and 1 or c.a
  end
  idx.SetGradient = function(self, orient, c1, c2, ...)
   if type(c1) ~= "table" or type(c2) ~= "table" then return nativeGradient(self, orient, c1, c2, ...) end
   if self._euiSolid then self._euiSolid = nil; setTexture(self, "Interface\\Buttons\\WHITE8X8") end
   local r1, g1, b1, a1 = RGBA(c1)
   local r2, g2, b2, a2 = RGBA(c2)
   return gradientAlpha(self, orient, r1, g1, b1, a1, r2, g2, b2, a2)
  end
  idx._euiGradient = true
 end
end

-- FontString:SetMaxLines came after Wrath, and Core (Unlock Mode movers, the panel)
-- calls it before the Options addon's own no-op exists. One line is Wrath's
-- single-line truncation (word wrap off, restored if a later call lifts the limit).
-- Larger limits are only recorded: a forced height would move JustifyV/anchored
-- text that Retail leaves alone.
do
 local probe = CreateFrame("Frame")
 probe:Hide()
 local fsIdx = getmetatable(probe:CreateFontString()).__index
 if type(fsIdx) == "table" and not fsIdx.SetMaxLines then
  fsIdx.SetMaxLines = function(self, n)
   n = tonumber(n) or 0
   if n < 0 then n = 0 end
   self._euiMaxLines = n
   if n == 1 then
    if not self._euiMaxLinesWrap and self.CanWordWrap and self:CanWordWrap() then
     self._euiMaxLinesWrap = true
    end
    if self.SetWordWrap then self:SetWordWrap(false) end
   elseif self._euiMaxLinesWrap then
    self._euiMaxLinesWrap = nil
    if self.SetWordWrap then self:SetWordWrap(true) end
   end
  end
 end
 if type(fsIdx) == "table" and not fsIdx.GetMaxLines then
  fsIdx.GetMaxLines = function(self) return self._euiMaxLines or 0 end
 end
 -- Unlock Mode's cog offset boxes ask HasFocus while syncing after a nudge.
 local box = CreateFrame("EditBox", nil, probe)
 if box.SetAutoFocus then box:SetAutoFocus(false) end
 if box.ClearFocus then box:ClearFocus() end
 if box.EnableKeyboard then box:EnableKeyboard(false) end
 box:Hide()
 local ebIdx = getmetatable(box).__index
 if type(ebIdx) == "table" and not ebIdx.HasFocus then
  ebIdx.HasFocus = function(self)
   return GetCurrentKeyBoardFocus ~= nil and GetCurrentKeyBoardFocus() == self
  end
 end
end

-- Physical screen dimensions were added after Wrath. Keep the modern global
-- available because several original core files call it directly.
if not GetPhysicalScreenSize then
 function GetPhysicalScreenSize()
  local w = (GetScreenWidth and GetScreenWidth()) or (UIParent and UIParent:GetWidth()) or 1920
  local h = (GetScreenHeight and GetScreenHeight()) or (UIParent and UIParent:GetHeight()) or 1080
  if not w or w <= 0 then w = 1920 end
  if not h or h <= 0 then h = 1080 end
  return w, h
 end
end
if not UnitEffectiveLevel then UnitEffectiveLevel = UnitLevel end
if not IsPlayerSpell then IsPlayerSpell = IsSpellKnown or function() return false end end
if not PlayerHasToy then PlayerHasToy = function() return false end end
if not GetRelativeDifficultyColor then
 GetRelativeDifficultyColor = function(_, level) return GetQuestDifficultyColor and GetQuestDifficultyColor(level) end
end
C_QuestLog=C_QuestLog or {}
C_QuestLog.GetTrivialRange=C_QuestLog.GetTrivialRange or function() return 5 end
C_ClassColor=C_ClassColor or {}
C_ClassColor.GetClassColor=C_ClassColor.GetClassColor or function(token)
 local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
 if not c then return nil end
 return CreateColor(c.r, c.g, c.b, 1)
end
-- Retail Settings API -> legacy Interface Options registration.
Settings=Settings or {}
Settings.RegisterCanvasLayoutCategory=Settings.RegisterCanvasLayoutCategory or function(panel, name)
 if panel then panel.name = panel.name or name end
 return panel
end
-- A top-level entry with the same name is already listed (EUI_OptionsAccess_335
-- registers the Wrath "EllesmereUI" entry), so the list keeps a single one.
Settings.RegisterAddOnCategory=Settings.RegisterAddOnCategory or function(category)
 if not category then return category end
 for _,panel in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES or {}) do
  if panel.name==category.name and type(panel.parent)~="string" then return panel end
 end
 if InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(category) end
 return category
end

-- 3.3.5 widget/event compatibility discovered by full core audit.
-- Visual-only Retail methods become safe no-ops; callers can keep their base texture/frame.
local function EUI335_NoOp() end
local function EUI335_PatchObjectMethods(obj)
    if not obj then return obj end
    -- We cannot modify userdata metatables safely here; individual call sites are guarded below.
    return obj
end

-- Retail roster event name maps to Wrath's party/raid roster events at registration sites.
EUI335 = EUI335 or {}
EUI335.IsWrath = true
EUI335.RegisterRosterEvents = EUI335.RegisterRosterEvents or function(frame)
    if not frame or not frame.RegisterEvent then return end
    pcall(frame.RegisterEvent, frame, "PARTY_MEMBERS_CHANGED")
    pcall(frame.RegisterEvent, frame, "RAID_ROSTER_UPDATE")
end
EUI335.RegisterEventSafe = EUI335.RegisterEventSafe or function(frame, event)
    if not frame or not frame.RegisterEvent or not event then return false end
    return pcall(frame.RegisterEvent, frame, event)
end

