local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E._ModuleNS and E._ModuleNS.EllesmereUIFriends
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
 self:UnregisterEvent("PLAYER_LOGIN")
 local function Field(key,text,kind,min,max,step)
  return {type=kind,text=text,min=min,max=max,step=step or 1,getValue=function() return ns.Config()[key] end,setValue=function(v) ns.Config()[key]=v; ns.Apply() end}
 end
 E:RegisterModule("EllesmereUIFriends",{title="Friends List",description="Style the native social window, preserving friend actions and all social tabs.",pages={"Friends"},searchTerms="friends social guild raid class icon name font opacity style",
 buildPage=function(_,parent,y)
  local W=E.Widgets
  local function Row(a,b) local _,h=W:DualRow(parent,y,a,b or {type="label",text=""}); y=y-h end
  local _,h=W:SectionHeader(parent,"FRIENDS LIST",y); y=y-h
  Row(Field("enabled","Enable Friends Skin","toggle"),{type="dropdown",text="Style",values={eui="EllesmereUI",blizzard="Blizzard"},order={"eui","blizzard"},
   getValue=function() return ns.FR_Style()=="eui" and "eui" or "blizzard" end,setValue=function(v) ns.Config().useBlizzardStyle=v=="blizzard"; ns.Config().useClassicStyle=false; ns.Apply() end})
  Row(Field("scale","Window Scale","slider",.7,1.5,.05),Field("bgAlpha","Background Opacity","slider",0,1,.05))
  Row(Field("tileAlpha","Friend Row Opacity","slider",0,1,.05),Field("showBorder","Show Border","toggle"))
  Row(Field("classColorNames","Class Color Names","toggle"),Field("showClassIcons","Class Icons","toggle"))
  Row(Field("useAccentTab","Accent Border","toggle"),{type="dropdown",text="Font Outline",values={OUTLINE="Outline",THICKOUTLINE="Thick Outline"},order={"OUTLINE","THICKOUTLINE"},getValue=function() return ns.Config().fontOutline end,setValue=function(v) ns.Config().fontOutline=v; ns.Apply() end})
  Row(Field("nameFontSize","Name Font Size","slider",9,16),Field("infoFontSize","Details Font Size","slider",8,14))
  Row({type="label",text="Open the social window normally. Native whisper, invite, notes, ignore, guild and raid controls remain available."})
  return math.abs(y)
 end,onReset=function() ns.addon.db:ResetProfile(); ns.Apply(); E:RefreshPage(true) end})
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
