-- Deliberately exposes legacy widget methods only.
now = 2
function GetTime() return now end
local methods = {}
allFrames={}
local function New(kind, parent)
    local f = setmetatable({kind=kind, parent=parent, scripts={},hooks={},events={},children={},shown=true,width=200,height=40,attributes={}}, {__index=methods})
    allFrames[#allFrames+1]=f
    if parent then parent.children[#parent.children+1] = f end
    return f
end
function CreateFrame(kind,name,parent,template)
    assert(not template or not template:find("Pingable") and not template:find("BackdropTemplate"))
    local f=New(kind,parent); if name then _G[name]=f end; return f
end
function methods:CreateTexture() return New("Texture",self) end
function methods:CreateFontString() return New("FontString",self) end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:UnregisterEvent(e) self.events[e]=nil end
function methods:UnregisterAllEvents() self.events={} end
function methods:SetScript(s,f) self.scripts[s]=f end
function methods:GetScript(s) return self.scripts[s] end
function methods:HookScript(s,f) self.hooks[s]=f end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:GetFrameLevel() return 1 end
function methods:GetFrameStrata() return "MEDIUM" end
function methods:GetEffectiveScale() return 1 end
function methods:GetScale() return 1 end
function methods:GetAlpha() return 1 end
function methods:GetOrientation() return self.orientation or "HORIZONTAL" end
function methods:SetOrientation(value) self.orientation=value end
-- The client crash report names this native call. Treat reaching it as fatal
-- so initialization/reload tests cover the Wrath fallback, even with a fill.
rotationCalls=0
function methods:SetRotatesTexture()
    rotationCalls=rotationCalls+1
    error("Wrath native SetRotatesTexture crash path reached")
end
function methods:GetStatusBarTexture() if not self.barTex then self.barTex=New("Texture",self) end return self.barTex end
function methods:CreateMaskTexture() return New("MaskTexture",self) end
function methods:IsProtected() return false end
function methods:GetFont() return "Fonts\\FRIZQT__.TTF",12,"OUTLINE" end
function methods:GetLeft() return 0 end
function methods:GetRight() return self.width end
function methods:GetTop() return self.height end
function methods:GetBottom() return 0 end
function methods:GetCenter() return 0,0 end
function methods:IsObjectType(k) return self.kind==k end
function methods:SetMinMaxValues(a,b) self.minimum,self.maximum=a,b end
function methods:SetValue(v) self.value=v end
function methods:SetAutoFocus(v) self.autoFocus=v end
function methods:ClearFocus() self.focus=false end
function methods:SetTexture(v) self.texture=v end
function methods:GetTexture() return self.texture end
function methods:SetTexCoord(...) self.texcoords={...} end
function methods:SetDesaturated(value) self.desaturated=value end
atlasInfoMock={}
nativeAtlasCalls=0
function methods:SetAtlas(atlas, useSize)
    assert(atlasInfoMock[atlas], "AtlasUtil:Unpack("..atlas..") Atlas does not exist")
    nativeAtlasCalls=nativeAtlasCalls+1
    self.atlas,self.atlasUseSize=atlas,useSize
end
function methods:SetText(v) self.text=v end
function methods:GetText() return self.text end
function methods:SetFormattedText(fmt,...) self:SetText(string.format(fmt,...)) end
function methods:SetParent(v) self.parent=v end
function methods:GetParent() return self.parent end
function methods:SetAttribute(k,v) self.attributes[k]=v end
function methods:GetAttribute(k) return self.attributes[k] end
function methods:SetCooldown(s,d) self.start,self.duration=s,d end
for _,k in ipairs({"SetPoint","ClearAllPoints","SetAllPoints","SetFont","SetAlpha","SetStatusBarTexture","SetGradientAlpha"}) do methods[k]=function() end end
for _,k in ipairs({"SetFrameLevel","SetFrameStrata","SetVertexColor","SetTextColor","SetStatusBarColor","SetScale","SetJustifyH","SetJustifyV","SetBlendMode","SetDrawLayer","SetCamera","SetUnit","SetModel","SetPosition","EnableMouse","RegisterForClicks","SetHitRectInsets","SetHorizTile","SetVertTile"}) do methods[k]=function() end end
UIParent=New("Frame")
function UnitHealthMax(u) return u=="missing" and 0 or 100 end
function UnitHealth() return 25 end
function UnitPower() return 50 end
function UnitPowerMax() return 100 end
function UnitPowerType() return 0,"MANA" end
function UnitCastingInfo() if castingMock==false then return end; return "Fireball","Rank 1","Fireball","fire-icon",1000,4000,false,19,false end
function UnitChannelInfo() return channelName or "Drain Life","Rank 1",channelName or "Drain Life","drain-icon",channelStart or 1000,channelEnd or 6000,false,true end
function GetSpellCooldown() return 1,10,1 end
function UnitClass() return "Warrior","WARRIOR" end
function UnitRace() return "Human","Human" end
function UnitExists() return true end
function UnitIsDead() return false end
function UnitIsDeadOrGhost() return false end
function UnitCanAttack() return false end
function UnitReaction() return 1 end
function UnitLevel() return 80 end
UnitEffectiveLevel=UnitLevel
function UnitClassification() return "normal" end
function UnitCreatureType() return "Humanoid" end
function UnitIsPVP() return false end
function UnitIsPVPFreeForAll() return false end
function UnitIsAFK() return false end
function UnitIsDND() return false end
function IsResting() return false end
function UnitAffectingCombat() return false end
function GetRaidTargetIndex() end
function GetQuestDifficultyColor() return {r=1,g=1,b=1} end
function UnitThreatSituation() end
function UnitIsTapped() return false end
function UnitIsTappedByPlayer() return false end
function UnitIsCorpse() return false end
function GetScreenWidth() return 1920 end
function GetScreenHeight() return 1080 end
function SetPortraitTexture() end
function UnitFrame_OnEnter() end
function UnitFrame_OnLeave() end
function UnitGUID(u) return u end
function UnitIsUnit(a,b) return a==b end
function UnitIsPlayer(u) return u=="player" end
function UnitIsConnected() return true end
function UnitIsVisible() return true end
function UnitPlayerControlled() return true end
function UnitFactionGroup() return "Alliance" end
function UnitName(u) return u end
function GetCVar() return "1" end
function GetNumPartyMembers() return 0 end
function GetNumRaidMembers() return 0 end
function UnitInRaid() end
function UnitIsPartyLeader() return false end
function GetThreatStatusColor() return 1,0,0 end
function InCombatLockdown() return false end
function IsLoggedIn() return false end
function IsAddOnLoaded() return false end
function hooksecurefunc() end
function geterrorhandler() return error end
function RegisterStateDriver(_,_,s) assert(not s:find("petbattle")) end
function RegisterUnitWatch() end
function SecureButton_GetUnit(f) return f:GetAttribute("unit") end
function SecureButton_GetModifiedUnit(f) return f:GetAttribute("unit") end
function GetLocale() return "enUS" end
function GetShapeshiftFormID() return 0 end
function IsPlayerSpell() return false end
function wipe(t) for k in pairs(t) do t[k]=nil end return t end
function UnitAura(unit,index,filter)
    if filter=="HELPFUL" and index==1 then return "Buff",nil,"buff-icon",2,nil,10,12,"player",false,false,100 end
    if filter=="HARMFUL" and index<=2 then return "Debuff",nil,index==1 and "other-icon" or "mine-icon",1,"Magic",10,12,index==1 and "other" or "player",false,false,100+index end
end
-- Stock Wrath exposes neither issecretvalue nor issecrettable.
EUI_WOW_335=true
RAID_CLASS_COLORS={WARRIOR={r=1,g=.5,b=.2}}
FACTION_BAR_COLORS={ [1]={r=1,g=0,b=0} }
PowerBarColor={MANA={r=0,g=0,b=1},[0]={r=0,g=0,b=1}}
C_Spell={GetSpellInfo=function(id) return {name=id,spellID=133} end}
C_CVar={}
C_Timer={After=function() end, NewTicker=function() return {Cancel=function() end} end}
C_SpecializationInfo={GetSpecialization=function() return 1 end, GetSpecializationInfo=function() return 33011,"Arms" end}
C_Texture={GetAtlasInfo=function(atlas) return atlasInfoMock[atlas] end}
EllesmereUI={_ModuleNS={},PP={},Lite={}, BORDER_DEFAULTS_FRAMES={}}
EllesmereUI.PP.perfect=1; EllesmereUI.PP.mult=1
EllesmereUI.CLASS_ICON_SPRITE_COORDS={ WARRIOR={0,.25,0,.25} }
EllesmereUI.FRAME_STRATA_ORDER_BASE={"MEDIUM"}; EllesmereUI.FRAME_STRATA_LABELS={MEDIUM="Medium"}
EllesmereUI.Tick={NewAnimTicker=function() return {Start=function() end,Stop=function() end} end}
EllesmereUI.GlowOptions={RegisterSite=function() end}
EllesmereUI.Glows={STEALABLE_BORDER=1,DEFAULT_COLOR={r=1,g=1,b=0}}
function EllesmereUI.NewCombatQueue() return {Defer=function() end} end
function EllesmereUI.RegisterBorderDefaults() end
function EllesmereUI.RegisterDarkModeToggle() end
function EllesmereUI.GetFontPath() return "Fonts\\FRIZQT__.TTF" end
function EllesmereUI.GetClassColor() return RAID_CLASS_COLORS.WARRIOR end
function EllesmereUI:RegisterOnShow() end
function EllesmereUI:RegisterOnHide() end
function EllesmereUI:RegisterModule(name,cfg) testModule=cfg end
SlashCmdList={}
function EllesmereUI.BuildBarTextureTables() return {default="Interface\\Buttons\\WHITE8X8"},{default="Default"},{"default"} end
function EllesmereUI.Lite.NewAddon() testAddon={}; return testAddon end
function EllesmereUI.Lite.NewDB(_, defaults) return {profile=defaults.profile} end
function EllesmereUI.AppendSharedMediaTextures() end
function EllesmereUI.ApplyColorsToOUF() end
function EllesmereUI.CaptureBlizzCastBarEvents() end
function EllesmereUI.RestoreBlizzCastBarEvents() end
function EllesmereUI.ApplyModuleFont(fs,font,size,_,flags) fs:SetFont(font,size,flags) end
function EllesmereUI.ResolveUnitPowerColor() return 0,0,1 end
function EllesmereUI.GetPowerColor() return {r=0,g=0,b=1} end
function EllesmereUI.GetResourceColor() return {r=0,g=0,b=1} end
function EllesmereUI.GetBorderCompanion() end
function EllesmereUI.CheckVisibilityOptions() return false end
function EllesmereUI.EvalVisibilityExtended() end
function EllesmereUI.VisOverrideValue() end
function EllesmereUI.GetActiveVisibilityModes() end
function EllesmereUI.VisHasAnyOption() return false end
function EllesmereUI.NumberAbbrevGlyphs() end
function EllesmereUI.ResolveTexturePath(t,key,fallback) return (t and key~=nil and t[key]) or fallback end
function EllesmereUI.BorderPx() return 1 end
function EllesmereUI.ApplyBorderStyle() end
function EllesmereUI.SetBorderStyleColor() end
function EllesmereUI.GetReactionColor() return {r=1,g=0,b=0} end
function EllesmereUI.WithSurname(name) return name end
function EllesmereUI.PP.HideBorder() end
function EllesmereUI.PP.ShowBorder() end
function EllesmereUI.PP.SetBorderSize() end
function EllesmereUI.PP.Scale(v) return v end
function EllesmereUI.PP.FromPixels(v) return v end
function EllesmereUI.PP.Snap(v) return v end
function EllesmereUI.PP.SnapForES(v) return v end
function EllesmereUI.PP.IsNum(v) return type(v)=="number" end
function EllesmereUI.PP.Size(f,w,h) f:SetSize(w,h) end
function EllesmereUI.PP.Width(f,w) f:SetWidth(w) end
function EllesmereUI.PP.Height(f,h) f:SetHeight(h) end
function EllesmereUI.PP.Point(f,...) f:SetPoint(...) end
function EllesmereUI.PP.DisablePixelSnap() end
function EllesmereUI.PP.CreateBorder() return {} end
function EllesmereUI.PP.GetBorders() end
function EllesmereUI.PP.SetInside(f,p) f:SetAllPoints(p) end
function EllesmereUI.PP.SetOutside(f,p) f:SetAllPoints(p) end
