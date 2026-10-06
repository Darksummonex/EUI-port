local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E._ModuleNS and E._ModuleNS.EllesmereUIFriends
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
 self:UnregisterEvent("PLAYER_LOGIN")
 local function Cfg(key) return ns.Config()[key] end
 local function Set(key,v) ns.Config()[key]=v end
 local function Field(key,text,kind,min,max,step)
  return {type=kind,text=text,min=min,max=max,step=step or 1,getValue=function() return ns.Config()[key] end,setValue=function(v) ns.Config()[key]=v; ns.Apply() end}
 end
 local ICON_VALUES={blizzard="Blizzard",modern="Modern",pixel="Pixel",pixelsComic="Pixels Comic",glyph="Glyph",arcade="Arcade",legend="Legend",midnight="Midnight",runic="Runic"}
 local ICON_ORDER={"blizzard","modern","pixel","pixelsComic","glyph","arcade","legend","midnight","runic"}
 E:RegisterModule("EllesmereUIFriends",{title="Friends List",description="The native social window with class icons, class-coloured names, faction banners and invite auto-accept; friend actions and every social tab stay native.",pages={"Friends"},searchTerms="friends social guild raid class icon theme name font opacity border accent faction banner invite auto accept",
 buildPage=function(_,parent,y)
  local W=E.Widgets
  local live=not E._prebuilding
  local function Row(a,b) local row,h=W:DualRow(parent,y,a,b or {type="label",text=""}); y=y-h; return row end
  -- Blizzard Style / Classic WoW UI keep Blizzard's window; rows still gain class icons and names.
  local BS=E.BlizzStyle
  local function Gate(cfg) if BS and BS.Gate then BS.Gate("friends",cfg) end; return cfg end
  if E.ClearContentHeader then E:ClearContentHeader() end
  local _,h=W:SectionHeader(parent,"DISPLAY",y); y=y-h
  if BS and BS.Note then y=BS.Note(parent,y,"friends") end
  Row({type="dropdown",text="Class Icon Theme",values=ICON_VALUES,order=ICON_ORDER,getValue=function() return Cfg("iconStyle") or "modern" end,setValue=function(v) Set("iconStyle",v); ns.Apply() end},
   Field("classColorNames","Class Color Names","toggle"))
  Row(Gate({type="slider",text="Border Size",min=0,max=4,step=1,getValue=function() return Cfg("borderSize") or 1 end,
    setValue=function(v) Set("borderSize",v); ns.Apply(); if E.RefreshPage then E:RefreshPage() end end}),
   Gate({type="multiSwatch",text="Border Color",disabled=function() return (Cfg("borderSize") or 0)==0 end,disabledTooltip="Set Border Size above 0",rawTooltip=true,swatches={
    {tooltip="Custom Color",hasAlpha=false,
     getValue=function() return Cfg("borderR") or 0,Cfg("borderG") or 0,Cfg("borderB") or 0 end,
     setValue=function(r,g,b) local p=ns.Config(); p.borderR,p.borderG,p.borderB=r,g,b; ns.Apply() end,
     onClick=function(button)
      if Cfg("useClassColor") then Set("useClassColor",false); ns.Apply(); if E.RefreshPage then E:RefreshPage() end; return end
      if button._eabOrigClick then button._eabOrigClick(button) end
     end,
     refreshAlpha=function() if not Cfg("enabled") then return .15 end; return Cfg("useClassColor") and .3 or 1 end},
    {tooltip="Accent Colored",hasAlpha=false,getValue=function() return E.GetAccentColor() end,setValue=function() end,
     onClick=function() Set("useClassColor",true); ns.Apply(); if E.RefreshPage then E:RefreshPage() end end,
     refreshAlpha=function() if not Cfg("enabled") then return .15 end; return Cfg("useClassColor") and 1 or .3 end}}}))
  local accent=Field("accentColors","Enable Accent Colors","toggle"); accent.tooltip="Underlines the selected social tab in the accent colour."
  local banners=Field("factionBanners","Enable Faction Banners","toggle"); banners.tooltip="Draws your faction's banner behind each friend row (Wrath friends share your faction)."
  Row(Gate(accent),Gate(banners))
  local invites=Field("autoAcceptFriendInvites","Auto-Accept Friend Invites","toggle")
  invites.tooltip="Auto-accepts all group invites from people on your friends list"
  invites.setValue=function(v) Set("autoAcceptFriendInvites",v); ns.SyncAutoAccept(); if E.RefreshPage then E:RefreshPage() end end
  local icons=Field("showClassIcons","Show Class Icons","toggle"); icons.tooltip="Class icon for online friends; offline friends show a dimmed offline icon."
  local inviteRow=Row(icons,invites)
  if live and inviteRow and inviteRow._rightRegion and E.BuildInlineCog then
   E.BuildInlineCog(inviteRow._rightRegion,{title="Auto Accept Settings",rows={{type="toggle",label="Accept Invites from Guildmates",
    get=function() return Cfg("autoAcceptGuildInvites") end,set=function(v) Set("autoAcceptGuildInvites",v) end}},
    disabled=function() return not Cfg("autoAcceptFriendInvites") end,disabledTooltip="Auto-Accept Friend Invites"})
  end
  -- Wrath-only: Retail sizes the window through Edit Mode and the Window Skins card.
  Row(Field("enabled","Enable Friends Skin","toggle"),Gate(Field("scale","Window Scale","slider",.7,1.5,.05)))
  Row(Gate(Field("bgAlpha","Background Opacity","slider",0,1,.05)),Gate(Field("tileAlpha","Friend Row Opacity","slider",0,1,.05)))
  local fontRow=Row(Gate(Field("nameFontSize","Name Font Size","slider",9,16)),Gate(Field("infoFontSize","Details Font Size","slider",8,14)))
  if live and fontRow and fontRow._leftRegion and E.BuildInlineCog then
   E.BuildInlineCog(fontRow._leftRegion,{title="Font Settings",rows={{type="dropdown",label="Font Outline",values={OUTLINE="Outline",THICKOUTLINE="Thick Outline"},order={"OUTLINE","THICKOUTLINE"},
    get=function() return Cfg("fontOutline") or "OUTLINE" end,set=function(v) Set("fontOutline",v); ns.Apply() end}}})
  end
  return math.abs(y)
 end,onReset=function() ns.addon.db:ResetProfile(); ns.Apply(); E:RefreshPage(true) end})
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
