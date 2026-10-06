local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E._ModuleNS and E._ModuleNS.EllesmereUIQuestTracker
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
 self:UnregisterEvent("PLAYER_LOGIN")
 local function Refresh() ns.Apply() end
 local function Cfg(key) return ns.Config()[key] end
 local function Set(key,v) ns.Config()[key]=v end
 local function Field(key,text,kind,min,max,step)
  return {type=kind,text=text,min=min,max=max,step=step or 1,getValue=function() return ns.Config()[key] end,setValue=function(v) ns.Config()[key]=v; Refresh() end}
 end
 local function DD(key,text,values,order) local cfg=Field(key,text,"dropdown"); cfg.values,cfg.order=values,order; return cfg end
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
 E:RegisterModule("EllesmereUIQuestTracker",{title="Quest Tracker",description="Wrath's native quest and achievement tracker with EUI styling, visibility rules, auto-accept/turn-in and a quest-item hotkey.",pages={"Quest Tracker"},searchTerms="quest tracker objectives achievements item hotkey accept turn in visibility move color font",
 buildPage=function(_,parent,y)
  local W=E.Widgets
  local live=not E._prebuilding
  local function Row(a,b) local row,h=W:DualRow(parent,y,a,b or {type="label",text=""}); y=y-h; return row end
  local function Section(text) local _,h=W:SectionHeader(parent,text,y); y=y-h end
  local function Swatch(region,level,prefix,refresh)
   if not live or not region or not E.BuildColorSwatch then return end
   local sw,swRefresh=E.BuildColorSwatch(region,level,
    function() local p=ns.Config(); return p[prefix.."R"],p[prefix.."G"],p[prefix.."B"] end,
    function(r,g,b) local p=ns.Config(); p[prefix.."R"],p[prefix.."G"],p[prefix.."B"]=r,g,b; Refresh() end,false,20)
   sw:ClearAllPoints(); sw:SetPoint("RIGHT",refresh or region,refresh and "LEFT" or "RIGHT",refresh and -8 or -20,0)
   if E.RegisterWidgetRefresh then E.RegisterWidgetRefresh(swRefresh) end
   return sw
  end
  local function Cog(region,title,rows)
   if live and region and E.BuildInlineCog then E.BuildInlineCog(region,{title=title,rows=rows}) end
  end
  local function CogToggle(label,key) return {type="toggle",label=label,get=function() return Cfg(key)~=false end,set=function(v) Set(key,v) end} end

  if E.ClearContentHeader then E:ClearContentHeader() end
  parent._showRowDivider=true
  -- Retail points at Edit Mode here; Wrath positions the tracker through Unlock Mode.
  if live then
   local fontPath=E.GetFontPath and E.GetFontPath() or STANDARD_TEXT_FONT
   local info=CreateFrame("Frame",nil,parent); info:SetWidth(parent:GetWidth() or 400); info:SetHeight(20)
   info:SetPoint("TOP",parent,"TOP",0,y-20); info._isSpacer=true
   local label=info:CreateFontString(nil,"OVERLAY"); label:SetFont(fontPath,15,""); label:SetTextColor(1,1,1,.75)
   label:SetPoint("CENTER"); label:SetJustifyH("CENTER"); label:SetText(E.L and E.L("Reposition this element within Unlock Mode") or "Reposition this element within Unlock Mode")
   local EG=E.ELLESMERE_GREEN or {r=.047,g=.824,b=.624}
   local link=CreateFrame("Button",nil,parent); local text=link:CreateFontString(nil,"OVERLAY")
   text:SetFont(fontPath,15,""); text:SetTextColor(EG.r,EG.g,EG.b,.75); text:SetPoint("CENTER")
   local function Label()
    local s=Cfg("forceOnScreen") and "Allow Quest Tracker to be Moved Offscreen" or "Force Quest Tracker on Screen"
    text:SetText(E.L and E.L(s) or s); link:SetWidth(text:GetStringWidth()+12); link:SetHeight(18)
   end
   Label(); link:SetPoint("TOP",label,"BOTTOM",0,-10)
   link:SetScript("OnEnter",function() text:SetTextColor(EG.r,EG.g,EG.b,1) end)
   link:SetScript("OnLeave",function() text:SetTextColor(EG.r,EG.g,EG.b,.75) end)
   link:SetScript("OnClick",function()
    if InCombatLockdown() then return end
    Set("forceOnScreen",not Cfg("forceOnScreen")); Refresh(); Label()
    if E.ToggleUnlockMode then E:ToggleUnlockMode() end
   end)
   ns.optionsLink=link
  end
  y=y-68

  -- Blizzard Style / Classic WoW UI keep the native tracker look: the background,
  -- font and colour rows only apply to the EllesmereUI look.
  local BS=E.BlizzStyle
  local STOCK=BS and BS.Get and BS.Get("questtracker")

  Section("DISPLAY")
  if BS and BS.Note then y=BS.Note(parent,y,"questtracker") end
  local raidCfg=DD("hideInRaidMode","Hide When In Raid",{never="Never",always="Always",combat="Raid Combat",boss="Boss Combat"},{"never","always","combat","boss"})
  raidCfg.tooltip="Always: hide the tracker the whole time you are in a raid.\nRaid Combat: hide during any raid combat.\nBoss Combat: hide only during boss encounters.\nArenas always hide the tracker."
  if E.BuildVisibilityRow then
   local _,h=E.BuildVisibilityRow(W,parent,y,{getStore=ns.Config,legacyKey="visibility",caps={partyIncludesRaid=false},
    onChanged=Refresh,onOptionChanged=Refresh},raidCfg)
   y=y-h
  else
   Row(DD("visibility","Visibility",{always="Always",never="Never",mouseover="Mouseover",in_combat="In Combat",out_of_combat="Out of Combat"},{"always","never","mouseover","in_combat","out_of_combat"}),raidCfg)
  end
  if not STOCK then
   local topLine=Field("showTopLine","Show Top Line","toggle"); topLine.tooltip="Draws a thin accent line at the top of the tracker background."
   local bgRow=Row(Field("bgAlpha","Background Opacity","slider",0,1,.05),topLine)
   local region=bgRow and bgRow._leftRegion
   if region then Swatch(region,bgRow:GetFrameLevel()+3,"bg",region._control or region) end
   Row(Field("headerFontSize","Header Font Size","slider",8,24),Field("titleFontSize","Title Font Size","slider",8,24))
   local fontValues,fontOrder
   if E.BuildFontDropdownData then fontValues,fontOrder=E.BuildFontDropdownData() end
   local fontCfg=fontValues and {type="dropdown",text="Font",values=fontValues,order=fontOrder,getValue=function() return Cfg("font") or "__global" end,setValue=function(v) Set("font",v); Refresh() end}
    or DD("fontOutline","Font Outline",{OUTLINE="Outline",THICKOUTLINE="Thick Outline"},{"OUTLINE","THICKOUTLINE"})
   local fontRow=Row(Field("objectiveFontSize","Objective Font Size","slider",8,24),fontCfg)
   if fontValues then
    Cog(fontRow and fontRow._rightRegion,"Font Settings",{{type="dropdown",label="Font Outline",values={OUTLINE="Outline",THICKOUTLINE="Thick Outline"},order={"OUTLINE","THICKOUTLINE"},
     get=function() return Cfg("fontOutline") or "OUTLINE" end,set=function(v) Set("fontOutline",v); Refresh() end}})
   end
  end
  local headerCfg=Field("hideAllObjectivesHeader","Hide All Objectives","toggle")
  headerCfg.tooltip=STOCK and "Hides the Objectives header and its minimize button at the top of the tracker."
   or "Hides the Objectives header and its minimize button at the top of the tracker. When shown, it uses the Header Color with a divider in the Line Color."
  Row(Field("enabled","Enable Quest Tracker","toggle"),headerCfg)
  local wideCfg=Field("wide","Wide Tracker","toggle"); wideCfg.tooltip="Uses Wrath's wide objectives tracker width."
  Row(wideCfg,Field("scale","Tracker Scale","slider",.7,1.5,.05))
  Row(Field("maxHeight","Maximum Height","slider",150,850,10),{type="spacer"})

  if not STOCK then
   Section("COLORS")
   local colorRow=Row({type="label",text="Title Color"},{type="label",text="Completed Color"})
   if colorRow then Swatch(colorRow._leftRegion,colorRow:GetFrameLevel()+3,"title"); Swatch(colorRow._rightRegion,colorRow:GetFrameLevel()+3,"completed") end
   local focusRow=Row({type="label",text="Focused Color",tooltip="Quest or achievement title under the mouse."},{type="multiSwatch",text="Header Color",swatches=ModeSwatches("header")})
   if focusRow then Swatch(focusRow._leftRegion,focusRow:GetFrameLevel()+3,"focus") end
   local lineRow=Row({type="multiSwatch",text="Line Color",swatches=ModeSwatches("line")},{type="label",text="Objective Color"})
   if lineRow then Swatch(lineRow._rightRegion,lineRow:GetFrameLevel()+3,"objective") end
   y=y-10
  end

  Section("EXTRAS")
  local turnIn=Field("autoTurnIn","Auto Turn In Quests","toggle")
  turnIn.tooltip="Quests with more than one reward choice, and turn-ins that cost money or items, stay manual."
  local helpers=Row(Field("autoAccept","Auto Accept Quests","toggle"),turnIn)
  Cog(helpers and helpers._leftRegion,"Auto Accept Settings",{CogToggle("Prevent Multi Quest Accept","autoAcceptPreventMulti"),CogToggle("Hold Shift to Skip","autoAcceptShiftSkip")})
  Cog(helpers and helpers._rightRegion,"Auto Turn In Settings",{CogToggle("Hold Shift to Skip","autoTurnInShiftSkip")})
  local hotkey=Field("questItemHotkey","Quest Item Hotkey","input")
  hotkey.tooltip="Type a key such as ALT-X. It uses your watched quest's item (or the first quest item) and binds only while one exists. Updates outside combat; leave empty to disable."
  Row(hotkey,{type="label",text=""})
  return math.abs(y)
 end,onReset=function() ns.addon.db:ResetProfile(); Refresh(); E:RefreshPage(true) end})
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
