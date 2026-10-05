-- Wrath's WatchFrame retains all native quests, achievements and item actions.
local ADDON,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON]=ns; ns.IsWrath=true; ns.addon=E.Lite.NewAddon(ADDON)
ns.events=CreateFrame("Frame"); ns.suppressors={}; ns.lines={}; ns.savedFonts={}
ns.defaults={profile={questTracker={enabled=true,useBlizzardStyle=false,useClassicStyle=false,scale=1,maxHeight=500,wide=true,
 forceOnScreen=true,bgAlpha=.75,showTopLine=true,titleFontSize=12,objectiveFontSize=11,headerFontSize=14,fontOutline="OUTLINE",
 titleR=1,titleG=.91,titleB=.47,completedR=.25,completedG=1,completedB=.35,objectiveR=.92,objectiveG=.92,objectiveB=.92,
 focusR=.871,focusG=.251,focusB=1,headerUseAccent=true,headerShowClassColor=false,headerR=1,headerG=1,headerB=1,
 lineUseAccent=true,lineShowClassColor=false,lineR=1,lineG=1,lineB=1,bgR=.035,bgG=.045,bgB=.05,hideAllObjectivesHeader=false,
 visibility="always",hideInRaidMode="never",
 visOnlyInstances=false,visHideMounted=false,visHideNoTarget=false,autoAccept=false,autoAcceptShiftSkip=true,
 autoTurnIn=false,autoTurnInShiftSkip=true,questItemHotkey="",unlockPos=nil}}}
ns.EQT={}; EllesmereUIQuestTracker=ns.EQT
local legacyModes={combat="in_combat",outofcombat="out_of_combat"}
function ns.Config()
 local p=ns.addon.db and ns.addon.db.profile.questTracker
 if p and legacyModes[p.visibility] then p.visibility=legacyModes[p.visibility] end
 return p
end
function ns.EQT.DB() return ns.Config() end
function ns.QT_Style() local p=ns.Config(); return p and (p.useClassicStyle and "classic" or p.useBlizzardStyle and "blizzard") or "eui" end
function ns.Font(fs,size)
 if not fs then return end
 if not ns.savedFonts[fs] then ns.savedFonts[fs]={font={fs:GetFont()},color={fs:GetTextColor()}} end
 local p=ns.Config()
 local path=p.font and p.font~="__global" and E.ResolveFontName and E.ResolveFontName(p.font) or E.GetFontPath("questTracker")
 local entry=E.GetModuleFontEntry and E.GetModuleFontEntry("questTracker")
 local flags=entry and entry.outline and entry.outline~="__global" and E.GetFontOutlineFlag and E.GetFontOutlineFlag("questTracker") or p.fontOutline
 flags=(flags or "OUTLINE"):gsub(",?%s*SLUG","")
 if not fs:SetFont(path or "Fonts\\FRIZQT__.TTF",size,flags) then fs:SetFont("Fonts\\FRIZQT__.TTF",size,"OUTLINE") end
end
function ns.StyleLine(line,header,complete)
 if not line or not line.text then return end
 ns.lines[line]={header=header,complete=complete}
 if not ns.Config() or not ns.Config().enabled or ns.QT_Style()~="eui" then return end
 local p=ns.Config(); ns.Font(line.text,header and p.titleFontSize or p.objectiveFontSize); ns.Font(line.dash,p.objectiveFontSize)
 if complete then line.text:SetTextColor(p.completedR,p.completedG,p.completedB)
 elseif header then line.text:SetTextColor(p.titleR,p.titleG,p.titleB)
 else line.text:SetTextColor(p.objectiveR,p.objectiveG,p.objectiveB) end
 if line.dash then line.dash:SetTextColor(p.objectiveR,p.objectiveG,p.objectiveB) end
end
local function ClassRGB()
 local c=RAID_CLASS_COLORS and RAID_CLASS_COLORS[select(2,UnitClass("player"))]
 if c then return c.r,c.g,c.b end
 return 1,1,1
end
-- Header and line colours: class colour, accent colour (default) or a custom swatch.
function ns.ModeColor(prefix)
 local p=ns.Config()
 if p[prefix.."ShowClassColor"] then return ClassRGB() end
 if p[prefix.."UseAccent"]~=false then return E.GetAccentColor() end
 return p[prefix.."R"] or 1,p[prefix.."G"] or 1,p[prefix.."B"] or 1
end
-- Hovering a quest or achievement paints its title with the Focused colour.
function ns.Highlight(button,onEnter)
 for line,state in pairs(ns.lines) do ns.StyleLine(line,state.header,state.complete) end
 local p=ns.Config()
 if not onEnter or not p or not p.enabled or ns.QT_Style()~="eui" or type(button)~="table" or type(button.lines)~="table" then return end
 local line=tonumber(button.startLine) and button.lines[tonumber(button.startLine)]
 if line and line.text then line.text:SetTextColor(p.focusR,p.focusG,p.focusB) end
end
function ns.HeaderParts() return WatchFrameTitle,WatchFrameCollapseExpandButton end
function ns.ShowHeader(show)
 local title,toggle=ns.HeaderParts()
 if title then title:SetAlpha(show and 1 or 0) end
 if toggle then toggle:SetAlpha(show and 1 or 0); toggle:EnableMouse(show) end
end
function ns.Schedule() if not ns.applying then ns.dirty=true end end
function ns.ItemBinding()
 if InCombatLockdown() or not ns.itemButton then ns.pending=true; return end
 ClearOverrideBindings(ns.itemButton); ns.itemButton:SetAttribute("type",nil); ns.itemButton:SetAttribute("clickbutton",nil)
 local p=ns.Config(); local key=(p.questItemHotkey or ""):upper():gsub("%s","")
 local ignored={LSHIFT=true,RSHIFT=true,LCTRL=true,RCTRL=true,LALT=true,RALT=true}
 if not p.enabled or key=="" or key=="ESCAPE" or key:find("MOUSEWHEEL") or ignored[key] then return end
 local item
 for i=1,(WATCHFRAME_NUM_ITEMS or 25) do local button=_G["WatchFrameItem"..i]; if button and button:IsShown() then item=button; break end end
 if item then ns.itemButton:SetAttribute("type","click"); ns.itemButton:SetAttribute("clickbutton",item); pcall(SetOverrideBindingClick,ns.itemButton,true,key,ns.itemButton:GetName(),"LeftButton") end
end
-- The shared Visibility checklist (modes, Match All/Any, Show/Hide lanes) decides; the
-- secure driver carries the combat edge and alpha covers what can change mid-fight.
local function GroupState(inCombat)
 local raid=GetNumRaidMembers()>0
 return {inCombat=inCombat and true or false,inRaid=raid,inParty=not raid and GetNumPartyMembers()>0}
end
local function LegacyOptionHide(p)
 return p.visOnlyInstances and not IsInInstance() or p.visHideMounted and IsMounted() or p.visHideNoTarget and not UnitExists("target")
end
function ns.Verdict(p,inCombat)
 local state=GroupState(inCombat)
 local v=E.EvalVisibilityExtended and E.EvalVisibilityExtended(p,"visibility",state)
 if v==nil then
  local mode=p.visibility or "always"
  if mode=="mouseover" then v="mouseover"
  elseif E.CheckVisibilityMode then v=E.CheckVisibilityMode(mode,state) and true or false
  else v=mode~="never" and not (mode=="in_combat" and not state.inCombat) and not (mode=="out_of_combat" and state.inCombat) end
 end
 if v then
  local hide
  if E.CheckVisibilityOptions then hide=E.CheckVisibilityOptions(p) else hide=LegacyOptionHide(p) end
  if hide then v=false end
 end
 return v
end
local dynamicModes={mouseover=true,in_raid=true,in_party=true,solo=true,hide_in_raid=true,hide_in_party=true,hide_solo=true}
local dynamicOptions={"visHideNoTarget","visHideWithTarget","visHideNoEnemy","visHideWithEnemy","visOnlyMounted","visHideMounted","visOnlyVehicle","visHideVehicle"}
-- True when the verdict may change inside combat, where the secure driver is frozen.
function ns.CanFlipInCombat(p)
 if p.visibilityMatch=="any" or dynamicModes[p.visibility] then return true end
 if type(p.visibilityModes)=="table" then for key in pairs(p.visibilityModes) do if dynamicModes[key] then return true end end end
 for _,key in ipairs(dynamicOptions) do if p[key] then return true end end
 return false
end
local function RaidHidden(p,inCombat)
 if GetNumRaidMembers()==0 then return false end
 local mode=p.hideInRaidMode
 return mode=="always" or inCombat and (mode=="combat" or mode=="boss" and (UnitExists("boss1") or UnitClassification("target")=="worldboss"))
end
function ns.DriverString(p)
 if next(ns.suppressors) or p.hideInRaidMode=="always" and GetNumRaidMembers()>0 then return "hide" end
 local inState=(ns.Verdict(p,true) or ns.CanFlipInCombat(p)) and "show" or "hide"
 local outState=ns.Verdict(p,false) and "show" or "hide"
 local body=inState==outState and inState or "[combat] "..inState.."; "..outState
 if body=="hide" then return body end
 if p.hideInRaidMode=="combat" then body="[group:raid,combat] hide; "..body
 elseif p.hideInRaidMode=="boss" then body="[group:raid,combat,@boss1,exists] hide; "..body end
 return body
end
function ns.WantsHover(p)
 local modes=p and p.visibilityModes
 return p and p.enabled and (p.visibility=="mouseover" or type(modes)=="table" and modes.mouseover) and true or false
end
local function Hovered()
 local f=ns.background and ns.background:IsShown() and ns.background or WatchFrame
 if MouseIsOver then return MouseIsOver(f) and true or false end
 return f.IsMouseOver and f:IsMouseOver() and true or false
end
local function SetLinksEnabled(enabled)
 if ns.linksEnabled==enabled then return end
 ns.linksEnabled=enabled
 for i=1,100 do local button=_G["WatchFrameLinkButton"..i]; if not button then break end; button:EnableMouse(enabled) end
end
-- Unprotected, so it runs in combat too: fades the tracker for conditions the frozen driver cannot see.
function ns.UpdateAlpha()
 local f,p=WatchFrame,ns.Config(); if not f or not p or not p.enabled then return end
 local alpha=1
 if not ns.preview then
  local inCombat=InCombatLockdown() or UnitAffectingCombat("player")
  local v=ns.Verdict(p,inCombat)
  if next(ns.suppressors) or RaidHidden(p,inCombat) then v=false end
  if v=="mouseover" then v=Hovered() end
  alpha=v and 1 or 0
 end
 if f:GetAlpha()~=alpha then f:SetAlpha(alpha) end
 SetLinksEnabled(alpha>0)
end
function ns.Visibility()
 local f,p=WatchFrame,ns.Config(); if not f or not p then return end
 if InCombatLockdown() then ns.pending=true; ns.UpdateAlpha(); return end
 if not p.enabled then
  if ns.driver then UnregisterStateDriver(f,"visibility"); ns.driver=nil end
  if ns.original and ns.original.shown then f:Show() else f:Hide() end
  if ns.background then ns.background:Hide() end
  f:SetAlpha(1); SetLinksEnabled(true)
  return
 end
 local condition=ns.preview and "show" or ns.DriverString(p)
 if condition~=ns.driver then RegisterStateDriver(f,"visibility",condition); ns.driver=condition end
 ns.UpdateAlpha()
 if ns.background then
  local top,bottom=f:GetTop(),nil
  for line in pairs(ns.lines) do if line:IsShown() and line:GetBottom() then bottom=bottom and math.min(bottom,line:GetBottom()) or line:GetBottom() end end
  local hasContent=bottom~=nil or ns.preview
  ns.background:SetWidth(f:GetWidth()+16); ns.background:SetHeight(top and bottom and math.max(36,math.min(p.maxHeight+10,top-bottom+14)) or 40)
  if p.enabled and ns.QT_Style()=="eui" and f:IsShown() and hasContent then ns.background:Show() else ns.background:Hide() end
 end
end
function ns.Restore()
 local f,o=WatchFrame,ns.original
 if not f or not o then return end
 for fs,s in pairs(ns.savedFonts) do if s.font[1] then fs:SetFont(unpack(s.font)); fs:SetTextColor(unpack(s.color)) end end
 f:ClearAllPoints(); for _,point in ipairs(o.points) do f:SetPoint(unpack(point)) end
 f:SetScale(o.scale); f:SetHeight(o.height); f:SetClampedToScreen(o.clamped)
 if WatchFrame_SetWidth then WatchFrame_SetWidth(o.width>250 and "1" or "0") else f:SetWidth(o.width) end
 ns.width=nil
 ns.ShowHeader(true); f:SetAlpha(1)
 if ns.background then ns.background:Hide() end
end
function ns.Apply()
 if InCombatLockdown() then ns.pending=true; return end
 local p,f=ns.Config(),WatchFrame; if not p or not f then return end
 ns.pending=false; ns.applying=true
 if not ns.original then
  ns.original={scale=f:GetScale(),width=f:GetWidth(),height=f:GetHeight(),clamped=f:IsClampedToScreen(),shown=f:IsShown(),points={}}
  for i=1,f:GetNumPoints() do ns.original.points[i]={f:GetPoint(i)} end
  ns.background=CreateFrame("Frame",nil,f); ns.background:SetFrameLevel(math.max(0,f:GetFrameLevel()-1)); ns.background:SetPoint("TOPLEFT",f,"TOPLEFT",-8,5)
  ns.background:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  ns.fill=f:CreateTexture(nil,"BACKGROUND"); ns.fill:SetTexture("Interface\\Buttons\\WHITE8X8"); ns.fill:SetAllPoints(ns.background)
  ns.background:HookScript("OnShow",function() ns.fill:Show() end); ns.background:HookScript("OnHide",function() ns.fill:Hide() end)
  ns.line=ns.background:CreateTexture(nil,"OVERLAY"); ns.line:SetTexture("Interface\\Buttons\\WHITE8X8"); ns.line:SetHeight(2); ns.line:SetPoint("TOPLEFT",ns.background,"TOPLEFT",1,-1); ns.line:SetPoint("TOPRIGHT",ns.background,"TOPRIGHT",-1,-1)
  ns.itemButton=CreateFrame("Button","EUI335QuestItemHotkey",UIParent,"SecureActionButtonTemplate")
  ns.itemButton:SetWidth(1); ns.itemButton:SetHeight(1); ns.itemButton:SetPoint("TOPLEFT",UIParent,"TOPLEFT",0,0); ns.itemButton:EnableMouse(false); ns.itemButton:RegisterForClicks("AnyUp")
  f:HookScript("OnShow",ns.Schedule); f:HookScript("OnHide",function() ns.background:Hide() end)
  if E.MakeUnlockElement and E.RegisterUnlockElements then
   E:RegisterUnlockElements({E.MakeUnlockElement({key="EQT_Tracker",label="Quest Tracker",group="Quest Tracker",order=370,noResize=true,noInitHook=true,
    getFrame=function() return WatchFrame end,getSize=function() return f:GetWidth(),f:GetHeight() end,isHidden=function() return not ns.Config().enabled end,
    savePos=function(_,point,relPoint,x,y) ns.Config().unlockPos={point=point,relPoint=relPoint,x=x,y=y} end,
    loadPos=function() return ns.Config().unlockPos end,clearPos=function() ns.Config().unlockPos=nil end,applyPos=ns.Apply})},ADDON)
  end
 end
 if not p.enabled then ns.Restore(); ns.Visibility(); ns.ItemBinding(); ns.applying=false; return end
 f:SetScale(p.scale); f:SetClampedToScreen(p.forceOnScreen); f:ClearAllPoints()
 local pos=p.unlockPos
 if pos then f:SetPoint(pos.point or "TOPRIGHT",UIParent,pos.relPoint or pos.point or "TOPRIGHT",(pos.x or 0)/p.scale,(pos.y or 0)/p.scale)
 else f:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-55/p.scale,-230/p.scale) end
 f:SetHeight(math.min(p.maxHeight,math.max(150,UIParent:GetHeight()/p.scale-80)))
 if WatchFrame_SetWidth and ns.width~=p.wide then ns.width=p.wide; WatchFrame_SetWidth(p.wide and "1" or "0") end
 if WatchFrame_Update then WatchFrame_Update(f) end
 if ns.QT_Style()=="eui" then
  ns.fill:SetVertexColor(p.bgR,p.bgG,p.bgB,p.bgAlpha); ns.background:SetBackdropBorderColor(.15,.2,.22,.9)
  local r,g,b=ns.ModeColor("line"); ns.line:SetVertexColor(r,g,b,1); if p.showTopLine then ns.line:Show() else ns.line:Hide() end
  ns.Font(WatchFrameTitle,p.headerFontSize); if WatchFrameTitle then WatchFrameTitle:SetTextColor(ns.ModeColor("header")) end
  for line,state in pairs(ns.lines) do ns.StyleLine(line,state.header,state.complete) end
 else
  for fs,s in pairs(ns.savedFonts) do if s.font[1] then fs:SetFont(unpack(s.font)); fs:SetTextColor(unpack(s.color)) end end
  ns.background:Hide()
 end
 ns.ShowHeader(not p.hideAllObjectivesHeader)
 ns.Visibility(); ns.ItemBinding(); ns.applying=false
end
function ns.QuestEvent(event)
 local p=ns.Config(); if not p or not p.enabled or InCombatLockdown() then return end
 local costs=(GetRequiredMoney and GetRequiredMoney() or 0)>0 or (GetNumQuestItems and GetNumQuestItems() or 0)>0
 if event=="QUEST_DETAIL" and p.autoAccept and not (p.autoAcceptShiftSkip and IsShiftKeyDown()) then
  -- Confirm quest acceptance only; shared/gossip choices remain explicit.
  if not QuestGetAutoAccept or not QuestGetAutoAccept() then AcceptQuest() end
 elseif event=="QUEST_PROGRESS" and p.autoTurnIn and not costs and not (p.autoTurnInShiftSkip and IsShiftKeyDown()) and IsQuestCompletable() then CompleteQuest()
 elseif event=="QUEST_COMPLETE" and p.autoTurnIn and not (p.autoTurnInShiftSkip and IsShiftKeyDown()) then
  if not costs and GetNumQuestChoices()==0 then GetQuestReward(0) end
 end
end
function ns.addon:OnInitialize() ns.addon.db=E.Lite.NewDB("EllesmereUIQuestTrackerDB",ns.defaults); _EQT_DB=ns.addon.db end
function ns.addon:OnEnable()
 for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","PLAYER_TARGET_CHANGED","PARTY_MEMBERS_CHANGED","RAID_ROSTER_UPDATE",
  "ZONE_CHANGED_NEW_AREA","PLAYER_UPDATE_RESTING","UNIT_ENTERED_VEHICLE","UNIT_EXITED_VEHICLE","UPDATE_SHAPESHIFT_FORM","COMPANION_UPDATE",
  "QUEST_LOG_UPDATE","QUEST_WATCH_UPDATE","QUEST_DETAIL","QUEST_PROGRESS","QUEST_COMPLETE"}) do ns.events:RegisterEvent(event) end
 ns.events:SetScript("OnEvent",function(_,event) ns.QuestEvent(event); if InCombatLockdown() then ns.UpdateAlpha() end; ns.Schedule() end)
 ns.events:SetScript("OnUpdate",function(_,dt)
  ns.elapsed=(ns.elapsed or 0)+dt; ns.hoverElapsed=(ns.hoverElapsed or 0)+dt
  if ns.dirty or ns.elapsed>=1 then local dirty=ns.dirty; ns.dirty=false; ns.elapsed=0; ns.hoverElapsed=0; if dirty or ns.pending or not ns.original then ns.Apply() else ns.Visibility() end
  elseif ns.hoverElapsed>=.1 then ns.hoverElapsed=0; if ns.WantsHover(ns.Config()) then ns.UpdateAlpha() end end
 end)
 if E.RegisterVisibilityUpdater then E.RegisterVisibilityUpdater(function() if InCombatLockdown() then ns.UpdateAlpha() end; ns.Schedule() end) end
 if WatchFrame_SetLine then hooksecurefunc("WatchFrame_SetLine",function(line,_,_,header,_,_,_,complete) ns.StyleLine(line,header,complete) end) end
 if WatchFrame_Update then hooksecurefunc("WatchFrame_Update",ns.Schedule) end
 if WatchFrameLinkButtonTemplate_Highlight then hooksecurefunc("WatchFrameLinkButtonTemplate_Highlight",ns.Highlight) end
 if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener("EQT335",function(on) ns.preview=on; ns.Visibility() end) end
 ns.Apply()
end
_EQT_RefreshAll=ns.Apply
ns.EQT.RestyleAll=ns.Apply
_EQT_SetSuppressed=function(key,on) if key then ns.suppressors[key]=on and true or nil; ns.Visibility() end end
SLASH_EQT1="/eqt"; SlashCmdList.EQT=function() if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; if E.ShowModule then E:ShowModule(ADDON) end end
