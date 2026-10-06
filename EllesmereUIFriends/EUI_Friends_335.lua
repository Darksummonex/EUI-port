-- Native Wrath social-window skin. Retail files remain unloaded references.
local ADDON,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON]=ns; ns.IsWrath=true; ns.addon=E.Lite.NewAddon(ADDON)
ns.events=CreateFrame("Frame"); ns.rows={}; ns.saved={}; ns.owned={}; ns.tabLines={}
ns.defaults={profile={friends={enabled=true,useBlizzardStyle=false,useClassicStyle=false,scale=1,bgAlpha=.96,tileAlpha=.45,
 showBorder=true,useAccentTab=true,classColorNames=true,showClassIcons=true,nameFontSize=12,infoFontSize=10,fontOutline="OUTLINE",
 iconStyle="modern",borderSize=1,borderR=0,borderG=0,borderB=0,useClassColor=false,accentColors=true,factionBanners=false,
 autoAcceptFriendInvites=false,autoAcceptGuildInvites=false}}}
local MEDIA="Interface\\AddOns\\EllesmereUIFriends\\Media_335\\"
local SPRITES="Interface\\AddOns\\EllesmereUI\\media\\icons\\class-full\\"
-- 0.2 had a show/hide border and an accent toggle; Retail has a size and a Custom/Accent colour.
local function Migrate(p)
 if not p or p.borderMigrated then return end
 if p.showBorder==false then p.borderSize=0 end
 p.useClassColor=p.useAccentTab~=false; p.borderMigrated=true
end
function ns.Config() local p=ns.addon.db and ns.addon.db.profile.friends; Migrate(p); return p end
function ns.FR_Style() local p=ns.Config(); return p and (p.useClassicStyle and "classic" or p.useBlizzardStyle and "blizzard") or "eui" end
local function Save(obj)
 if not obj or ns.saved[obj] then return end
 local s={alpha=obj:GetAlpha()}; ns.saved[obj]=s
 if obj.IsObjectType and obj:IsObjectType("FontString") then s.font={obj:GetFont()}; s.color={obj:GetTextColor()}; s.object=obj.GetFontObject and obj:GetFontObject() or nil end
end
function ns.Font(fs,size)
 if not fs then return end; Save(fs)
 local p=ns.Config(); local entry=E.GetModuleFontEntry and E.GetModuleFontEntry("friends")
 local flags=entry and entry.outline and entry.outline~="__global" and E.GetFontOutlineFlag and E.GetFontOutlineFlag("friends") or p.fontOutline or "OUTLINE"
 flags=flags:gsub(",?%s*SLUG","")
 if E.PrimeFontShadow and E.GetFontUseShadow then E.PrimeFontShadow(fs,E.GetFontUseShadow("friends")) end
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
local function Note(note)
 if E.StripFriendNoteTag and issecretvalue then return E.StripFriendNoteTag(note) end
 return type(note)=="string" and note~="" and note or nil
end
-- Name shifted right of the class icon and details tucked under it, as Retail lays rows out.
local function Layout(button,state,on)
 local name,info=button.name,button.info
 if on and not state.points then
  state.points={name={name:GetPoint(1)},info={}}
  if info then for i=1,info:GetNumPoints() do state.points.info[i]={info:GetPoint(i)} end end
  local p1,rel,p2,x,y=unpack(state.points.name)
  if p1 then name:SetPoint(p1,rel,p2,(x or 0)+20,y or 0) end
  if info then info:ClearAllPoints(); info:SetPoint("TOPLEFT",name,"BOTTOMLEFT",0,-3) end
 elseif not on and state.points then
  if state.points.name[1] then name:SetPoint(unpack(state.points.name)) end
  if info and state.points.info[1] then info:ClearAllPoints(); for _,point in ipairs(state.points.info) do info:SetPoint(unpack(point)) end end
  state.points=nil
 end
end
local function SetInfoNote(button,state,note)
 local info=button.info; if not info then return end
 local text=info:GetText() or ""
 if text==state.noteText then text=state.origInfo or "" end
 state.origInfo=text
 local final=note and (text~="" and text.."  |cff888888|  "..note.."|r" or "|cff888888"..note.."|r") or text
 if final~=(info:GetText() or "") then info:SetText(final) end
 state.noteText=final
end
function ns.Restore()
 for obj,s in pairs(ns.saved) do
  obj:SetAlpha(s.alpha)
  if s.object and obj.SetFontObject then obj:SetFontObject(s.object) end
  if s.font and s.font[1] then obj:SetFont(unpack(s.font)); obj:SetTextColor(unpack(s.color)) end
 end
 for button,state in pairs(ns.rows) do
  Layout(button,state,false)
  if state.noteText and button.info and button.info:GetText()==state.noteText then button.info:SetText(state.origInfo or "") end
  state.noteText=nil
 end
 for obj in pairs(ns.owned) do obj:Hide() end
 if ns.originalScale and FriendsFrame then FriendsFrame:SetScale(ns.originalScale) end
 ns.active=false; ns.decorate=false
end
local function Own(obj) ns.owned[obj]=true; return obj end
local function ClassIcon(icon,key,style)
 local coords
 if style=="blizzard" or not (E.CLASS_ICON_SPRITE_COORDS and E.CLASS_ICON_SPRITE_COORDS[key]) then
  icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"); coords=(CLASS_ICON_TCOORDS or {})[key]
 else
  icon:SetTexture(SPRITES..style..".tga"); coords=E.CLASS_ICON_SPRITE_COORDS[key]
 end
 if not coords then return false end
 icon:SetTexCoord(coords[1],coords[2],coords[3],coords[4]); return true
end
local function StatusTexture(status)
 status=type(status)=="string" and status or ""
 if status:find("DND",1,true) or CHAT_FLAG_DND and status==CHAT_FLAG_DND then return FRIENDS_TEXTURE_DND or "Interface\\FriendsFrame\\StatusIcon-DnD" end
 if status:find("AFK",1,true) or CHAT_FLAG_AFK and status==CHAT_FLAG_AFK then return FRIENDS_TEXTURE_AFK or "Interface\\FriendsFrame\\StatusIcon-Away" end
 return FRIENDS_TEXTURE_ONLINE or "Interface\\FriendsFrame\\StatusIcon-Online"
end
function ns.StyleRow(button)
 if InCombatLockdown() then ns.pending=true; return end
 if not (ns.active or ns.decorate) or not button or not button.name or not button.buttonType then return end
 local p=ns.Config(); local state=ns.rows[button]; local full=ns.active
 if not state then
  state={}; ns.rows[button]=state
  state.fill=Own(button:CreateTexture(nil,"BACKGROUND",nil,1)); state.fill:SetAllPoints(); state.fill:SetTexture("Interface\\Buttons\\WHITE8X8")
  state.banner=Own(button:CreateTexture(nil,"BACKGROUND",nil,3)); state.banner:SetAllPoints()
  state.icon=Own(button:CreateTexture(nil,"ARTWORK",nil,2))
  state.orb=Own(button:CreateTexture(nil,"OVERLAY",nil,3)); state.orb:SetWidth(12); state.orb:SetHeight(12)
  state.hover=Own(button:CreateTexture(nil,"ARTWORK",nil,-7)); state.hover:SetAllPoints(); state.hover:SetTexture("Interface\\Buttons\\WHITE8X8")
  if state.hover.SetGradientAlpha then state.hover:SetGradientAlpha("HORIZONTAL",.4,.7,1,.22,.4,.7,1,0) else state.hover:SetVertexColor(.4,.7,1,.12) end
  state.hover:Hide()
  button:HookScript("OnEnter",function() if ns.active then state.hover:Show() end end)
  button:HookScript("OnLeave",function() state.hover:Hide() end)
 end
 local wow=button.buttonType==(FRIENDS_BUTTON_TYPE_WOW or 3) and button.id
 local icon=state.icon; icon:ClearAllPoints(); icon:Hide(); icon:SetAlpha(1); state.orb:Hide(); state.banner:Hide()
 if full then
  ns.Font(button.name,p.nameFontSize); ns.Font(button.info,p.infoFontSize); ns.Font(button.broadcastMessage,p.infoFontSize)
  if button.background then Save(button.background); button.background:SetAlpha(0) end
  state.fill:SetVertexColor(.025,.04,.05,p.tileAlpha); state.fill:Show()
 else state.fill:Hide() end
 -- The orb replaces the native status icon on WoW rows only; recycled rows get it back.
 if button.status and button.status.SetTexture then Save(button.status); button.status:SetAlpha(full and wow and 0 or ns.saved[button.status].alpha) end
 Layout(button,state,full and wow and true or false)
 if wow then
  local _,_,class,_,online,status,note=GetFriendInfo(button.id)
  local key=class and ClassKey(class); local color=key and RAID_CLASS_COLORS[key]
  if not online then button.name:SetTextColor(.6,.6,.6)
  elseif p.classColorNames and color then button.name:SetTextColor(color.r,color.g,color.b)
  elseif full then button.name:SetTextColor(1,.91,.65) end
  local h=(button:GetHeight() or 34)-4
  if not full then
   icon:SetWidth(16); icon:SetHeight(16); icon:SetPoint("TOPRIGHT",button,"TOPRIGHT",-4,-4)
   if p.showClassIcons and online and key and ClassIcon(icon,key,p.iconStyle or "modern") then icon:Show() end
  elseif p.showClassIcons and h>0 then
   if online then
    local inset=math.floor(h*.025+.5); local size=h-inset*2
    icon:SetWidth(size); icon:SetHeight(size); icon:SetPoint("LEFT",button,"LEFT",4,0)
    if key and ClassIcon(icon,key,p.iconStyle or "modern") then icon:Show() end
   else
    local size=math.floor(h*.75); icon:SetWidth(size); icon:SetHeight(size); icon:SetPoint("LEFT",button,"LEFT",4+math.floor((h-size)/2),0)
    icon:SetTexture(MEDIA.."offline.tga"); icon:SetTexCoord(0,1,0,1); icon:SetAlpha(.5); icon:Show()
   end
  end
  if full then
   -- Wrath friends always share the player's faction.
   local faction=p.factionBanners and UnitFactionGroup("player")
   state.banner:SetTexture(MEDIA..((faction=="Alliance" and "alliance") or (faction=="Horde" and "horde") or "neutral")..".tga"); state.banner:SetAlpha(.2); state.banner:Show()
   state.orb:SetTexture(online and StatusTexture(status) or FRIENDS_TEXTURE_OFFLINE or "Interface\\FriendsFrame\\StatusIcon-Offline")
   state.orb:SetAlpha(online and 1 or .6); state.orb:ClearAllPoints(); state.orb:SetPoint("LEFT",button.name,"LEFT",(button.name:GetStringWidth() or 0)+3,0); state.orb:Show()
   SetInfoNote(button,state,Note(note))
  end
 elseif button.buttonType==(FRIENDS_BUTTON_TYPE_BNET or 2) then
  -- Keep native Battle.net text, identity, game icon and whisper handling.
  local online=BNGetFriendInfo and select(7,BNGetFriendInfo(button.id))
  if online then button.name:SetTextColor(.51,.773,1) else button.name:SetTextColor(.6,.6,.6) end
 else state.fill:Hide() end
 if full and button.info then button.info:SetTextColor(.85,.85,.85) end
end
-- Accent underline beneath the selected social tab (Retail's Enable Accent Colors).
function ns.TabAccent()
 local f,p=FriendsFrame,ns.Config(); if not f or not p then return end
 local selected=PanelTemplates_GetSelectedTab and PanelTemplates_GetSelectedTab(f) or f.selectedTab
 local r,g,b=E.GetAccentColor()
 for i=1,(f.numTabs or 4) do
  local tab=_G["FriendsFrameTab"..i]
  if tab then
   local line=ns.tabLines[tab]
   if not line then
    line=Own(tab:CreateTexture(nil,"OVERLAY")); ns.tabLines[tab]=line; line:SetTexture("Interface\\Buttons\\WHITE8X8"); line:SetHeight(2)
    local text=_G["FriendsFrameTab"..i.."Text"] or tab.GetFontString and tab:GetFontString()
    if text then line:SetPoint("TOPLEFT",text,"BOTTOMLEFT",0,-2); line:SetPoint("TOPRIGHT",text,"BOTTOMRIGHT",0,-2) else line:SetPoint("BOTTOMLEFT",tab,"BOTTOMLEFT",12,8); line:SetPoint("BOTTOMRIGHT",tab,"BOTTOMRIGHT",-12,8) end
   end
   line:SetVertexColor(r,g,b,1)
   if ns.active and p.accentColors~=false and selected==i then line:Show() else line:Hide() end
  end
 end
end
function ns.BorderColor(p)
 if p.useClassColor then local r,g,b=E.GetAccentColor(); return r,g,b end
 return p.borderR or 0,p.borderG or 0,p.borderB or 0
end
function ns.Apply()
 if InCombatLockdown() then ns.pending=true; return end
 local p=ns.Config(); if not p then return end
 ns.pending=false; ns.SyncAutoAccept()
 local skin=E._ModuleNS and E._ModuleNS.EllesmereUIBlizzardSkin
 if skin and skin.ReleaseWindow and p.enabled then skin.ReleaseWindow(FriendsFrame) end
 if ns.claimed~=p.enabled then ns.claimed=p.enabled; if skin and skin.RequestRefresh then skin.RequestRefresh() end end
 local f=FriendsFrame
 if not p.enabled or not f then ns.Restore(); return end
 local scroll=FriendsFrameFriendsScrollFrame
 if ns.FR_Style()~="eui" then
  -- Stock styles keep Blizzard's window; rows still gain class icons and class-coloured names.
  if ns.active then ns.Restore() end
  ns.decorate=true
 else
  if not ns.panel then
   ns.originalScale=f:GetScale()
   for _,region in ipairs({f:GetRegions()}) do if region:IsObjectType("Texture") and not ns.owned[region] then Save(region) end end
   local panel=Own(CreateFrame("Frame",nil,f)); ns.panel=panel
   panel:SetFrameLevel(math.max(0,f:GetFrameLevel()-1)); panel:SetPoint("TOPLEFT",f,"TOPLEFT",10,-10); panel:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-34,68)
   ns.fill=Own(f:CreateTexture(nil,"BACKGROUND")); ns.fill:SetTexture("Interface\\Buttons\\WHITE8X8"); ns.fill:SetAllPoints(panel)
   f:HookScript("OnShow",ns.Schedule)
  end
  ns.active=true; ns.decorate=false
  for _,region in ipairs({f:GetRegions()}) do if region:IsObjectType("Texture") and not ns.owned[region] then Save(region); region:SetAlpha(0) end end
  f:SetScale(p.scale)
  ns.fill:SetVertexColor(.035,.045,.05,p.bgAlpha); ns.fill:Show()
  local size=math.max(0,math.floor(p.borderSize or 1))
  if ns.borderSize~=size then ns.borderSize=size; ns.panel:SetBackdrop(size>0 and {edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=size} or nil) end
  if size>0 then local r,g,b=ns.BorderColor(p); ns.panel:SetBackdropBorderColor(r,g,b,1) end
  ns.panel:Show()
  ns.Font(FriendsFrameTitleText,14); if FriendsFrameTitleText then FriendsFrameTitleText:SetTextColor(1,1,1) end
  local offline=FriendsFrameOfflineHeader
  if offline and offline.GetFontString then offline=offline:GetFontString() elseif offline and not offline.SetFont then offline=nil end
  ns.Font(offline,p.nameFontSize)
 end
 for _,button in ipairs(scroll and scroll.buttons or {}) do ns.StyleRow(button) end
 for i=1,40 do local button=_G["FriendsFrameFriendsScrollFrameButton"..i] or _G["FriendsFrameFriendButton"..i]; if button then ns.StyleRow(button) end end
 for button in pairs(ns.rows) do if button:IsShown() then ns.StyleRow(button) end end
 ns.TabAccent()
end
function ns.Schedule()
 ns.dirty=true
end
local function InGroup() return (GetNumRaidMembers and GetNumRaidMembers() or 0)>0 or (GetNumPartyMembers and GetNumPartyMembers() or 0)>0 end
-- Friends (and optionally guildmates) are matched by the inviter's character name.
function ns.IsTrustedInviter(name,p)
 if type(name)~="string" or name=="" then return false end
 name=name:match("^[^%-]+") or name
 for i=1,(GetNumFriends and GetNumFriends() or 0) do if GetFriendInfo(i)==name then return true end end
 if BNGetNumFriends and BNGetFriendInfo then
  for i=1,(BNGetNumFriends() or 0) do if select(4,BNGetFriendInfo(i))==name then return true end end
 end
 if p.autoAcceptGuildInvites and IsInGuild and IsInGuild() and GetGuildRosterInfo then
  for i=1,(GetNumGuildMembers and GetNumGuildMembers(true) or 0) do if GetGuildRosterInfo(i)==name then return true end end
 end
 return false
end
ns.inviteFrame=CreateFrame("Frame")
ns.inviteFrame:SetScript("OnEvent",function(self,event,name)
 if event=="PARTY_INVITE_REQUEST" then
  local p=ns.Config()
  if not p or not p.enabled or not p.autoAcceptFriendInvites or InGroup() or not ns.IsTrustedInviter(name,p) then return end
  AcceptGroup(); ns.hidePopup=true; self:RegisterEvent("PARTY_MEMBERS_CHANGED")
 elseif event=="PARTY_MEMBERS_CHANGED" and ns.hidePopup then
  ns.hidePopup=false; self:UnregisterEvent("PARTY_MEMBERS_CHANGED")
  if StaticPopup_Hide then StaticPopup_Hide("PARTY_INVITE") end
 end
end)
function ns.SyncAutoAccept()
 local p=ns.Config()
 if p and p.enabled and p.autoAcceptFriendInvites then ns.inviteFrame:RegisterEvent("PARTY_INVITE_REQUEST") else ns.inviteFrame:UnregisterEvent("PARTY_INVITE_REQUEST") end
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
 if FriendsFrame_SetButton then hooksecurefunc("FriendsFrame_SetButton",function(button) if ns.active or ns.decorate then ns.StyleRow(button) end end) end
 if FriendsList_Update then hooksecurefunc("FriendsList_Update",ns.Schedule) end
 if PanelTemplates_SetTab then hooksecurefunc("PanelTemplates_SetTab",function(frame) if frame==FriendsFrame then ns.TabAccent() end end) end
 if E.RegAccent then E.RegAccent({type="callback",fn=function() ns.Schedule() end}) end
 ns.Apply()
end
_EFR_ApplyFriends=ns.Apply; _EFR_ProcessFriendButtons=ns.Apply; _EFR_SyncAutoAccept=function() ns.SyncAutoAccept() end
SLASH_EFRIENDS1="/efriends"; SLASH_EFRIENDS2="/efr"
SlashCmdList.EFRIENDS=function() if InCombatLockdown() then return end; if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; if E.ShowModule then E:ShowModule(ADDON) end end
