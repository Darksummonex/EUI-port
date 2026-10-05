local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E._ModuleNS and E._ModuleNS.EllesmereUIQuestTracker
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
 self:UnregisterEvent("PLAYER_LOGIN")
 local function Refresh() ns.Apply() end
 local function Field(key,text,kind,min,max,step)
  return {type=kind,text=text,min=min,max=max,step=step or 1,getValue=function() return ns.Config()[key] end,setValue=function(v) ns.Config()[key]=v; Refresh() end}
 end
 local function DD(key,text,values,order) local cfg=Field(key,text,"dropdown"); cfg.values,cfg.order=values,order; return cfg end
 local function Color(prefix,text)
  return {type="colorpicker",text=text,hasAlpha=false,
   getValue=function() local p=ns.Config(); return p[prefix.."R"],p[prefix.."G"],p[prefix.."B"] end,
   setValue=function(r,g,b) local p=ns.Config(); p[prefix.."R"],p[prefix.."G"],p[prefix.."B"]=r,g,b; Refresh() end}
 end
 -- Class / Custom / Accent swatches; the active one is drawn at full alpha.
 local function ModeSwatches(prefix)
  local classKey,accentKey=prefix.."ShowClassColor",prefix.."UseAccent"
  local function IsClass() return ns.Config()[classKey]==true end
  local function IsAccent() return not IsClass() and ns.Config()[accentKey]~=false end
  local function Pick(class,accent) local p=ns.Config(); p[classKey],p[accentKey]=class,accent; Refresh(); if E.RefreshPage then E:RefreshPage() end end
  return {
   {tooltip="Class Color",hasAlpha=false,
    getValue=function() local c=RAID_CLASS_COLORS and RAID_CLASS_COLORS[select(2,UnitClass("player"))]; if c then return c.r,c.g,c.b end; return 1,1,1 end,
    setValue=function() end,onClick=function() Pick(true,false) end,refreshAlpha=function() return IsClass() and 1 or .3 end},
   {tooltip="Custom Color",hasAlpha=false,
    getValue=function() local p=ns.Config(); return p[prefix.."R"],p[prefix.."G"],p[prefix.."B"] end,
    setValue=function(r,g,b) local p=ns.Config(); p[prefix.."R"],p[prefix.."G"],p[prefix.."B"]=r,g,b; Pick(false,false) end,
    onClick=function(button)
     if IsClass() or IsAccent() then Pick(false,false); return end
     if button._eabOrigClick then button._eabOrigClick(button) end
    end,
    refreshAlpha=function() if IsClass() then return .15 end; return IsAccent() and .3 or 1 end},
   {tooltip="Accent Color",hasAlpha=false,
    getValue=function() return E.GetAccentColor() end,
    setValue=function() end,onClick=function() Pick(false,true) end,refreshAlpha=function() return IsAccent() and 1 or .3 end},
  }
 end
 E:RegisterModule("EllesmereUIQuestTracker",{title="Quest Tracker",description="Wrath's native quest and achievement tracker with EUI styling, visibility rules and optional quest helpers.",pages={"Quest Tracker"},searchTerms="quest tracker objectives achievements item hotkey accept turn in visibility move color font",
 buildPage=function(_,parent,y)
  local W=E.Widgets
  local live=not E._prebuilding
  local function Row(a,b) local row,h=W:DualRow(parent,y,a,b or {type="label",text=""}); y=y-h; return row end
  local function Section(text) local _,h=W:SectionHeader(parent,text,y); y=y-h end
  local function Button(text,fn) local _,h=W:WideButton(parent,text,y,fn); y=y-h end
  local function Cog(region,title,key)
   if live and E.BuildInlineCog and region then
    E.BuildInlineCog(region,{title=title,rows={{type="toggle",label="Hold Shift to Skip",
     get=function() return ns.Config()[key]~=false end,set=function(v) ns.Config()[key]=v end}}})
   end
  end

  Section("DISPLAY")
  Row(Field("enabled","Enable Quest Tracker","toggle"),{type="dropdown",text="Style",values={eui="EllesmereUI",blizzard="Blizzard"},order={"eui","blizzard"},getValue=function() return ns.QT_Style()=="eui" and "eui" or "blizzard" end,setValue=function(v) ns.Config().useBlizzardStyle=v=="blizzard"; ns.Config().useClassicStyle=false; Refresh() end})
  local raidCfg=DD("hideInRaidMode","Hide When In Raid",{never="Never",always="Always",combat="Raid Combat",boss="Boss Combat"},{"never","always","combat","boss"})
  raidCfg.tooltip="Always: hide the tracker the whole time you are in a raid.\nRaid Combat: hide during any raid combat.\nBoss Combat: hide only during boss encounters."
  if E.BuildVisibilityRow then
   local _,h=E.BuildVisibilityRow(W,parent,y,{getStore=ns.Config,legacyKey="visibility",caps={partyIncludesRaid=false},
    onChanged=Refresh,onOptionChanged=Refresh},raidCfg)
   y=y-h
  else
   Row(DD("visibility","Visibility",{always="Always",never="Never",mouseover="Mouseover",in_combat="In Combat",out_of_combat="Out of Combat"},{"always","never","mouseover","in_combat","out_of_combat"}),raidCfg)
  end
  local bgRow=Row(Field("bgAlpha","Background Opacity","slider",0,1,.05),Field("showTopLine","Show Top Line","toggle"))
  if live and E.BuildColorSwatch and bgRow and bgRow._leftRegion then
   local region=bgRow._leftRegion
   local swatch,refresh=E.BuildColorSwatch(region,bgRow:GetFrameLevel()+3,
    function() local p=ns.Config(); return p.bgR,p.bgG,p.bgB end,
    function(r,g,b) local p=ns.Config(); p.bgR,p.bgG,p.bgB=r,g,b; Refresh() end,false,20)
   swatch:ClearAllPoints(); swatch:SetPoint("RIGHT",region._control or region,"LEFT",-8,0)
   if E.RegisterWidgetRefresh then E.RegisterWidgetRefresh(refresh) end
  end
  Row(Field("headerFontSize","Header Font Size","slider",8,24),Field("titleFontSize","Title Font Size","slider",8,24))
  local fontValues,fontOrder
  if E.BuildFontDropdownData then fontValues,fontOrder=E.BuildFontDropdownData() end
  Row(Field("objectiveFontSize","Objective Font Size","slider",8,24),
   fontValues and {type="dropdown",text="Font",values=fontValues,order=fontOrder,getValue=function() return ns.Config().font or "__global" end,setValue=function(v) ns.Config().font=v; Refresh() end}
   or DD("fontOutline","Font Outline",{OUTLINE="Outline",THICKOUTLINE="Thick Outline"},{"OUTLINE","THICKOUTLINE"}))
  local headerCfg=Field("hideAllObjectivesHeader","Hide Objectives Header","toggle")
  headerCfg.tooltip="Hides the Objectives title and its collapse button at the top of the tracker."
  Row(fontValues and DD("fontOutline","Font Outline",{OUTLINE="Outline",THICKOUTLINE="Thick Outline"},{"OUTLINE","THICKOUTLINE"}) or {type="label",text=""},headerCfg)
  Row(Field("scale","Tracker Scale","slider",.7,1.5,.05),Field("maxHeight","Maximum Height","slider",150,850,10))
  Row(Field("wide","Wide Tracker","toggle"),Field("forceOnScreen","Keep On Screen","toggle"))

  Section("COLORS")
  Row(Color("title","Title Color"),Color("completed","Completed Color"))
  local focusCfg=Color("focus","Focused Color"); focusCfg.tooltip="Quest or achievement title under the mouse."
  Row(Color("objective","Objective Color"),focusCfg)
  Row({type="multiSwatch",text="Header Color",swatches=ModeSwatches("header")},{type="multiSwatch",text="Line Color",swatches=ModeSwatches("line")})

  Section("EXTRAS")
  local helpers=Row(Field("autoAccept","Auto Accept Quests","toggle"),Field("autoTurnIn","Auto Turn In Quests","toggle"))
  Cog(helpers and helpers._leftRegion,"Auto Accept Settings","autoAcceptShiftSkip")
  Cog(helpers and helpers._rightRegion,"Auto Turn In Settings","autoTurnInShiftSkip")
  Row(Field("questItemHotkey","Quest Item Hotkey (Example: ALT-X)","input"),{type="label",text="Uses the first visible native quest-item button. Updates outside combat; leave empty to disable."})
  Row({type="label",text="Quests with a choice of rewards require manual selection. Gossip choices, shared quests and paid/material turn-ins remain manual."})
  Button("Move In Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
  Button("Reset Tracker Position",function() ns.Config().unlockPos=nil; Refresh() end)
  return math.abs(y)
 end,onReset=function() ns.addon.db:ResetProfile(); Refresh(); E:RefreshPage(true) end})
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
