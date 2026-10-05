-- Native Wrath social-window skin. Retail files remain unloaded references.
local ADDON,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON]=ns; ns.IsWrath=true; ns.addon=E.Lite.NewAddon(ADDON)
ns.events=CreateFrame("Frame"); ns.rows={}; ns.saved={}; ns.owned={}
ns.defaults={profile={friends={enabled=true,useBlizzardStyle=false,useClassicStyle=false,scale=1,bgAlpha=.96,tileAlpha=.45,
 showBorder=true,useAccentTab=true,classColorNames=true,showClassIcons=true,nameFontSize=12,infoFontSize=10,fontOutline="OUTLINE"}}}
function ns.Config() return ns.addon.db and ns.addon.db.profile.friends end
function ns.FR_Style() local p=ns.Config(); return p and (p.useClassicStyle and "classic" or p.useBlizzardStyle and "blizzard") or "eui" end
local function Save(obj)
 if not obj or ns.saved[obj] then return end
 local s={alpha=obj:GetAlpha()}; ns.saved[obj]=s
 if obj.IsObjectType and obj:IsObjectType("FontString") then s.font={obj:GetFont()}; s.color={obj:GetTextColor()} end
end
function ns.Font(fs,size)
 if not fs then return end; Save(fs)
 local p=ns.Config(); local entry=E.GetModuleFontEntry and E.GetModuleFontEntry("friends")
 local flags=entry and entry.outline and entry.outline~="__global" and E.GetFontOutlineFlag and E.GetFontOutlineFlag("friends") or p.fontOutline or "OUTLINE"
 flags=flags:gsub(",?%s*SLUG","")
 if not fs:SetFont(E.GetFontPath("friends") or "Fonts\\FRIZQT__.TTF",size,flags) then fs:SetFont("Fonts\\FRIZQT__.TTF",size,"OUTLINE") end
end
local function ClassKey(class)
 for key in pairs(RAID_CLASS_COLORS) do
  if class==key or class==(LOCALIZED_CLASS_NAMES_MALE or {})[key] or class==(LOCALIZED_CLASS_NAMES_FEMALE or {})[key] then return key end
 end
 -- English clients/private servers may omit the localized lookup tables.
 local english={Warrior="WARRIOR",Paladin="PALADIN",Hunter="HUNTER",Rogue="ROGUE",Priest="PRIEST",["Death Knight"]="DEATHKNIGHT",Shaman="SHAMAN",Mage="MAGE",Warlock="WARLOCK",Druid="DRUID"}
 return english[class]
end
function ns.Restore()
 for obj,s in pairs(ns.saved) do
  obj:SetAlpha(s.alpha)
  if s.font and s.font[1] then obj:SetFont(unpack(s.font)); obj:SetTextColor(unpack(s.color)) end
 end
 for obj in pairs(ns.owned) do obj:Hide() end
 if ns.originalScale and FriendsFrame then FriendsFrame:SetScale(ns.originalScale) end
 ns.active=false
end
local function Own(obj) ns.owned[obj]=true; return obj end
function ns.StyleRow(button)
 if InCombatLockdown() then ns.pending=true; return end
 if not ns.active or not button or not button.name or not button.buttonType then return end
 local p=ns.Config(); local state=ns.rows[button]
 if not state then
  state={}; ns.rows[button]=state
  state.fill=Own(button:CreateTexture(nil,"BACKGROUND",nil,1)); state.fill:SetAllPoints(); state.fill:SetTexture("Interface\\Buttons\\WHITE8X8")
  state.icon=Own(button:CreateTexture(nil,"ARTWORK")); state.icon:SetWidth(16); state.icon:SetHeight(16)
  state.icon:SetPoint("TOPRIGHT",button,"TOPRIGHT",-4,-4)
 end
 ns.Font(button.name,p.nameFontSize); ns.Font(button.info,p.infoFontSize); ns.Font(button.broadcastMessage,p.infoFontSize)
 if button.background then Save(button.background); button.background:SetAlpha(0) end
 state.fill:SetVertexColor(.025,.04,.05,p.tileAlpha); state.fill:Show(); state.icon:Hide()
 if button.buttonType==(FRIENDS_BUTTON_TYPE_WOW or 3) and button.id then
  local _,_,class,_,online=GetFriendInfo(button.id)
  local key=class and ClassKey(class); local color=key and RAID_CLASS_COLORS[key]
  if not online then button.name:SetTextColor(.6,.6,.6)
  elseif p.classColorNames and color then button.name:SetTextColor(color.r,color.g,color.b)
  else button.name:SetTextColor(1,.91,.65) end
  local coords=key and ((CLASS_ICON_TCOORDS or {})[key] or E.CLASS_ICON_SPRITE_COORDS and E.CLASS_ICON_SPRITE_COORDS[key])
  if p.showClassIcons and online and coords then
   state.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"); state.icon:SetTexCoord(unpack(coords)); state.icon:Show()
  end
 elseif button.buttonType==(FRIENDS_BUTTON_TYPE_BNET or 2) then
  -- Keep native Battle.net text, identity, game icon and whisper handling.
  local online=BNGetFriendInfo and select(7,BNGetFriendInfo(button.id))
  if online then button.name:SetTextColor(.51,.773,1) else button.name:SetTextColor(.6,.6,.6) end
 else state.fill:Hide() end
 if button.info then button.info:SetTextColor(.85,.85,.85) end
end
function ns.Apply()
 if InCombatLockdown() then ns.pending=true; return end
 local p=ns.Config(); if not p then return end
 ns.pending=false
 local skin=E._ModuleNS and E._ModuleNS.EllesmereUIBlizzardSkin
 if skin and skin.ReleaseWindow and p.enabled then skin.ReleaseWindow(FriendsFrame) end
 if ns.claimed~=p.enabled then ns.claimed=p.enabled; if skin and skin.RequestRefresh then skin.RequestRefresh() end end
 if not p.enabled or ns.FR_Style()~="eui" then ns.Restore(); return end
 local f=FriendsFrame; if not f then return end
 if not ns.panel then
  ns.originalScale=f:GetScale()
  for _,region in ipairs({f:GetRegions()}) do if region:IsObjectType("Texture") and not ns.owned[region] then Save(region) end end
  local panel=Own(CreateFrame("Frame",nil,f)); ns.panel=panel
  panel:SetFrameLevel(math.max(0,f:GetFrameLevel()-1)); panel:SetPoint("TOPLEFT",f,"TOPLEFT",10,-10); panel:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-34,68)
  panel:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  ns.fill=Own(f:CreateTexture(nil,"BACKGROUND")); ns.fill:SetTexture("Interface\\Buttons\\WHITE8X8"); ns.fill:SetAllPoints(panel)
  f:HookScript("OnShow",ns.Schedule)
 end
 ns.active=true
 for _,region in ipairs({f:GetRegions()}) do if region:IsObjectType("Texture") and not ns.owned[region] then Save(region); region:SetAlpha(0) end end
 f:SetScale(p.scale)
 local r,g,b=E.GetAccentColor(); ns.fill:SetVertexColor(.035,.045,.05,p.bgAlpha); ns.fill:Show()
 ns.panel:SetBackdropBorderColor(p.useAccentTab and r or .15,p.useAccentTab and g or .15,p.useAccentTab and b or .15,p.showBorder and 1 or 0); ns.panel:Show()
 ns.Font(FriendsFrameTitleText,14); if FriendsFrameTitleText then FriendsFrameTitleText:SetTextColor(1,1,1) end
 local offline=FriendsFrameOfflineHeader
 if offline and offline.GetFontString then offline=offline:GetFontString() elseif offline and not offline.SetFont then offline=nil end
 ns.Font(offline,p.nameFontSize)
 local scroll=FriendsFrameFriendsScrollFrame
 for _,button in ipairs(scroll and scroll.buttons or {}) do ns.StyleRow(button) end
 for i=1,40 do local button=_G["FriendsFrameFriendsScrollFrameButton"..i] or _G["FriendsFrameFriendButton"..i]; if button then ns.StyleRow(button) end end
 for button in pairs(ns.rows) do if button:IsShown() then ns.StyleRow(button) end end
end
function ns.Schedule()
 ns.dirty=true
end
function ns.addon:OnInitialize()
 ns.addon.db=E.Lite.NewDB("EllesmereUIFriendsDB",ns.defaults); _EFR_DB=ns.addon.db
end
function ns.addon:OnEnable()
 for _,event in ipairs({"FRIENDLIST_UPDATE","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","ADDON_LOADED"}) do ns.events:RegisterEvent(event) end
 ns.events:SetScript("OnEvent",ns.Schedule)
 ns.events:SetScript("OnUpdate",function(_,dt)
  ns.elapsed=(ns.elapsed or 0)+dt
  if ns.dirty or ns.elapsed>=.5 then ns.elapsed=0; ns.dirty=false; if ns.pending or FriendsFrame and FriendsFrame:IsShown() or not ns.panel then ns.Apply() end end
 end)
 if FriendsFrame_SetButton then hooksecurefunc("FriendsFrame_SetButton",function(button) if ns.active then ns.StyleRow(button) end end) end
 ns.Apply()
end
_EFR_ApplyFriends=ns.Apply; _EFR_ProcessFriendButtons=ns.Apply
SLASH_EFRIENDS1="/efriends"
SlashCmdList.EFRIENDS=function() if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; if E.ShowModule then E:ShowModule(ADDON) end end
