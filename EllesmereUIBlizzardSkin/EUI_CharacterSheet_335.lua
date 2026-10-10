-- Expanded Wrath paper doll. Native equipment buttons/model/stat setters remain
-- authoritative; every native geometry change is restored when disabled.
local _,ns=...
local E=EllesmereUI
local flat="Interface\\Buttons\\WHITE8X8"
local left={"Head","Neck","Shoulder","Back","Chest","Shirt","Tabard","Wrist"}
local right={"Hands","Waist","Legs","Feet","Finger0","Finger1","Trinket0","Trinket1"}
local weapons={"MainHand","SecondaryHand","Ranged"}
local ids={Head=1,Neck=2,Shoulder=3,Shirt=4,Chest=5,Waist=6,Legs=7,Feet=8,Wrist=9,
    Hands=10,Finger0=11,Finger1=12,Trinket0=13,Trinket1=14,Back=15,MainHand=16,SecondaryHand=17,Ranged=18,Tabard=19}
local groups={
    {key="Base",token="PLAYERSTAT_BASE_STATS",text="Attributes",color={.05,.82,.62}},
    {key="Melee",token="PLAYERSTAT_MELEE_COMBAT",text="Melee",color={.7,.36,.95}},
    {key="Ranged",token="PLAYERSTAT_RANGED_COMBAT",text="Ranged",color={.7,.36,.95}},
    {key="Spell",token="PLAYERSTAT_SPELL_COMBAT",text="Spell",color={.7,.36,.95}},
    {key="Defense",token="PLAYERSTAT_DEFENSES",text="Defense",color={.88,.4,.76}},
}
ns.statGroups=groups
for key,value in pairs({showEnchants=true,showGems=true,charSheetEnchantNames=false,charSheetEnchantSize=9,
    showCharSheetDurability=false,charSheetDurabilityLocation="model",charSheetDurabilityShowLabel=true,
    charSheetSocketPanel=true,highlightStatItems=false}) do ns.defaults[key]=value end
for _,spec in ipairs(groups) do ns.defaults["showStatCategory_"..spec.key]=true end
-- Stat hover highlight (Retail highlightSecondaryItems): hovering a stat row
-- glows the equipped slots whose item stats grant it. Rows are labelled by
-- Blizzard's UpdatePaperdollStats, so labels map to the ITEM_MOD_* keys
-- GetItemStats returns through the client's own strings, English as fallback.
local statMods
local function StatMods()
    if statMods then return statMods end
    statMods={}
    local function Add(mods,...)
        for i=1,select("#",...) do local name=select(i,...); if type(name)=="string" and name~="" then statMods[name]=mods end end
    end
    Add({"ITEM_MOD_STRENGTH_SHORT"},_G.SPELL_STAT1_NAME,"Strength")
    Add({"ITEM_MOD_AGILITY_SHORT"},_G.SPELL_STAT2_NAME,"Agility")
    Add({"ITEM_MOD_STAMINA_SHORT"},_G.SPELL_STAT3_NAME,"Stamina")
    Add({"ITEM_MOD_INTELLECT_SHORT"},_G.SPELL_STAT4_NAME,"Intellect")
    Add({"ITEM_MOD_SPIRIT_SHORT"},_G.SPELL_STAT5_NAME,"Spirit")
    Add({"RESISTANCE0_NAME","ITEM_MOD_EXTRA_ARMOR_SHORT"},_G.ARMOR,"Armor")
    Add({"ITEM_MOD_HIT_RATING_SHORT","ITEM_MOD_HIT_MELEE_RATING_SHORT","ITEM_MOD_HIT_RANGED_RATING_SHORT","ITEM_MOD_HIT_SPELL_RATING_SHORT"},_G.COMBAT_RATING_NAME6,"Hit Rating")
    Add({"ITEM_MOD_CRIT_RATING_SHORT","ITEM_MOD_CRIT_MELEE_RATING_SHORT","ITEM_MOD_CRIT_RANGED_RATING_SHORT","ITEM_MOD_CRIT_SPELL_RATING_SHORT"},_G.MELEE_CRIT_CHANCE,_G.SPELL_CRIT_CHANCE,_G.RANGED_CRIT_CHANCE,"Crit Chance")
    Add({"ITEM_MOD_HASTE_RATING_SHORT","ITEM_MOD_HASTE_SPELL_RATING_SHORT"},_G.SPELL_HASTE,"Haste Rating","Haste")
    Add({"ITEM_MOD_EXPERTISE_RATING_SHORT"},_G.COMBAT_RATING_NAME24,"Expertise")
    Add({"ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"},_G.DEFENSE,"Defense")
    Add({"ITEM_MOD_DODGE_RATING_SHORT"},_G.STAT_DODGE,"Dodge")
    Add({"ITEM_MOD_PARRY_RATING_SHORT"},_G.STAT_PARRY,"Parry")
    Add({"ITEM_MOD_BLOCK_RATING_SHORT","ITEM_MOD_BLOCK_VALUE_SHORT"},_G.STAT_BLOCK,"Block")
    Add({"ITEM_MOD_RESILIENCE_RATING_SHORT"},_G.STAT_RESILIENCE,"Resilience")
    Add({"ITEM_MOD_ATTACK_POWER_SHORT","ITEM_MOD_RANGED_ATTACK_POWER_SHORT"},_G.ATTACK_POWER_TOOLTIP,"Attack Power","Power")
    Add({"ITEM_MOD_SPELL_POWER_SHORT"},_G.BONUS_DAMAGE,_G.BONUS_HEALING,"Bonus Damage","Bonus Healing","Spell Power")
    Add({"ITEM_MOD_MANA_REGENERATION_SHORT","ITEM_MOD_POWER_REGEN0_SHORT","ITEM_MOD_SPIRIT_SHORT"},_G.MANA_REGEN,"Mana Regen")
    return statMods
end
function ns.StatModsFor(label)
    if type(label)~="string" then return nil end
    label=label:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("[:%s]+$","")
    return StatMods()[label]
end
local statGlows,statGlowsLit={},false
ns.statGlows=statGlows
function ns.StopStatHighlights()
    if not statGlowsLit then return end
    statGlowsLit=false
    for _,f in pairs(statGlows) do
        if f:IsShown() then if E.Glows and E.Glows.StopGlow then E.Glows.StopGlow(f) end; f:Hide() end
    end
end
function ns.StartStatHighlights(row)
    ns.StopStatHighlights()
    if not ns.GetValue("highlightStatItems") or not GetItemStats then return end
    local mods=ns.StatModsFor(row and row.label and row.label:GetText())
    if not mods then return end
    for slot,id in pairs(ids) do
        local button=_G["Character"..slot.."Slot"]
        local link=button and button:IsVisible() and GetInventoryItemLink("player",id)
        local stats=link and GetItemStats(link)
        local has=false
        if stats then for _,key in ipairs(mods) do local v=stats[key]; if type(v)=="number" and v>0 then has=true; break end end end
        if has then
            local f=statGlows[slot]
            if not f then f=CreateFrame("Frame",nil,button); f:SetAllPoints(button); statGlows[slot]=f end
            f:SetFrameLevel(button:GetFrameLevel()+5); f:Show()
            local w,h=button:GetWidth(),button:GetHeight()
            if not w or w<1 then w=37 end
            if not h or h<1 then h=w end
            if E.Glows and E.Glows.StartGlow then E.Glows.StartGlow(f,6,w,1,1,1,nil,h) end
            statGlowsLit=true
        end
    end
end
local backdrop="Interface\\AddOns\\EllesmereUIBlizzardSkin\\Media\\character-bg.tga"
-- GearScoreLite formula; GearScoreLite itself is preferred when loaded.
local gsSlotMod={INVTYPE_RELIC=.3164,INVTYPE_TRINKET=.5625,INVTYPE_2HWEAPON=2,INVTYPE_WEAPONMAINHAND=1,
    INVTYPE_WEAPONOFFHAND=1,INVTYPE_RANGED=.3164,INVTYPE_THROWN=.3164,INVTYPE_RANGEDRIGHT=.3164,INVTYPE_SHIELD=1,
    INVTYPE_WEAPON=1,INVTYPE_HOLDABLE=1,INVTYPE_HEAD=1,INVTYPE_NECK=.5625,INVTYPE_SHOULDER=.75,INVTYPE_CHEST=1,
    INVTYPE_ROBE=1,INVTYPE_WAIST=.75,INVTYPE_LEGS=1,INVTYPE_FEET=.75,INVTYPE_WRIST=.5625,INVTYPE_HAND=.75,
    INVTYPE_FINGER=.5625,INVTYPE_CLOAK=.5625,INVTYPE_BODY=0}
local gsEnchantable={INVTYPE_2HWEAPON=true,INVTYPE_WEAPONMAINHAND=true,INVTYPE_WEAPONOFFHAND=true,INVTYPE_RANGED=true,
    INVTYPE_SHIELD=true,INVTYPE_WEAPON=true,INVTYPE_HEAD=true,INVTYPE_SHOULDER=true,INVTYPE_CHEST=true,INVTYPE_ROBE=true,
    INVTYPE_LEGS=true,INVTYPE_FEET=true,INVTYPE_WRIST=true,INVTYPE_HAND=true,INVTYPE_CLOAK=true}
local gsFormula={A={[4]={91.45,.65},[3]={81.375,.8125},[2]={73,1}},B={[4]={26,1.2},[3]={.75,1.8},[2]={8,2},[1]={0,2.25}}}
local gsBands={{1000,.55,.55,.55},{2000,1,1,1},{3000,.12,1,0},{4000,0,.5,1},{5000,.69,.28,.97},{math.huge,.94,.47,0}}
local enchantSlots={[1]=true,[3]=true,[5]=true,[7]=true,[8]=true,[9]=true,[10]=true,[15]=true,[16]=true}
local offhandEnchant={INVTYPE_WEAPON=true,INVTYPE_WEAPONOFFHAND=true,INVTYPE_SHIELD=true,INVTYPE_2HWEAPON=true}
local scopeEnchant={INVTYPE_RANGED=true,INVTYPE_RANGEDRIGHT=true}
local flagArt={
    enchant={"Interface\\Icons\\Trade_Engraving",true},
    sockets={"Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic",false},
    buckle={(GetItemIcon and GetItemIcon(41611)) or "Interface\\Icons\\INV_Misc_Gear_01",true},
    socket={"Interface\\Icons\\Trade_BlackSmithing",true},
}
local function LinkFields(link)
    local fields={}
    local body=link and link:match("item:([%-%d:]+)")
    if body then for v in (body..":"):gmatch("([^:]*):") do fields[#fields+1]=tonumber(v) or 0 end end
    for i=1,6 do fields[i]=fields[i] or 0 end
    return fields
end
local function ItemScore(link)
    local _,_,rarity,level,_,_,_,_,equip=GetItemInfo(link)
    local mod=gsSlotMod[equip]; if not (rarity and level and mod) then return 0 end
    local scale=1
    if rarity==5 then scale,rarity=1.3,4 elseif rarity<=1 then scale,rarity=.005,2 end
    if rarity==7 then rarity,level=3,187.05 end
    if rarity<2 or rarity>4 then return 0 end
    local t=gsFormula[level>120 and "A" or "B"][rarity]
    local score=math.max(0,math.floor((level-t[1])/t[2]*mod*1.8618*scale))
    if gsEnchantable[equip] and LinkFields(link)[2]==0 then score=math.floor(score*(1+math.floor(-2*mod*100)/10000)) end
    return score
end
function ns.GearScore(unit)
    if GearScore_GetScore and GS_Formula and GS_ItemTypes and GS_Settings then
        local ok,score=pcall(GearScore_GetScore,UnitName(unit),unit)
        if ok and type(score)=="number" then return score end
    end
    local _,class=UnitClass(unit); local hunter=class=="HUNTER"
    local total,titan=0,1
    local main,off=GetInventoryItemLink(unit,16),GetInventoryItemLink(unit,17)
    if main and off and select(9,GetItemInfo(main))=="INVTYPE_2HWEAPON" then titan=.5 end
    if off then
        if select(9,GetItemInfo(off))=="INVTYPE_2HWEAPON" then titan=.5 end
        total=total+ItemScore(off)*(hunter and .3164 or 1)*titan
    end
    for i=1,18 do
        local link=i~=4 and i~=17 and GetInventoryItemLink(unit,i)
        if link then
            local score=ItemScore(link)
            if hunter and i==16 then score=score*.3164 elseif hunter and i==18 then score=score*5.3224 end
            if i==16 then score=score*titan end
            total=total+score
        end
    end
    return math.floor(total)
end
function ns.GearScoreColor(score)
    if GearScore_GetQuality and GS_Quality then
        local ok,r,g,b=pcall(GearScore_GetQuality,score)
        if ok and type(r)=="number" and g and b then return r,g,b end
    end
    for _,band in ipairs(gsBands) do if score<=band[1] then return band[2],band[3],band[4] end end
end
local socketText
local function SocketText()
    if not socketText then
        socketText={}
        for _,key in ipairs({"EMPTY_SOCKET_RED","EMPTY_SOCKET_YELLOW","EMPTY_SOCKET_BLUE","EMPTY_SOCKET_META","EMPTY_SOCKET_NO_COLOR","EMPTY_SOCKET_PRISMATIC"}) do
            if type(_G[key])=="string" then socketText[_G[key]]=true end
        end
    end
    return socketText
end
local scanner
local function CountEmptySockets(method,...)
    if scanner==nil then
        local ok,tip=pcall(CreateFrame,"GameTooltip","EUI335CharacterScanTooltip",nil,"GameTooltipTemplate")
        scanner=ok and tip or false
    end
    if not (scanner and scanner.SetOwner and scanner[method] and scanner.NumLines) then return 0 end
    scanner:SetOwner(WorldFrame,"ANCHOR_NONE"); scanner:ClearLines()
    if not pcall(scanner[method],scanner,...) then scanner:Hide(); return 0 end
    local count,known=0,SocketText()
    for i=2,scanner:NumLines() do
        local line=_G["EUI335CharacterScanTooltipTextLeft"..i]
        local text=line and line:GetText()
        if text and known[text] then count=count+1 end
    end
    scanner:Hide()
    return count
end
local function ProfessionRank(spellId)
    local name=GetSpellInfo and GetSpellInfo(spellId)
    if not name or not GetNumSkillLines or not GetSkillLineInfo then return 0 end
    for i=1,GetNumSkillLines() do
        local skill,header,_,rank=GetSkillLineInfo(i)
        if not header and skill==name then return rank or 0 end
    end
    return 0
end
local function MissingFor(id,link,equip,ctx)
    local fields=LinkFields(link)
    local miss={}
    local needsEnchant=enchantSlots[id] or id==17 and offhandEnchant[equip] or id==18 and ctx.hunter and scopeEnchant[equip]
        or (id==11 or id==12) and ctx.enchanter
    if needsEnchant and fields[2]==0 then miss[#miss+1]="enchant" end
    local filled=0
    for i=3,6 do if fields[i]~=0 then filled=filled+1 end end
    local empty=CountEmptySockets("SetInventoryItem",ctx.unit or "player",id)
    if empty>0 then miss[#miss+1]="sockets"; miss.sockets=empty end
    if (id==6 or ctx.blacksmith and (id==9 or id==10)) and fields[1]>0 then
        if empty+filled<=CountEmptySockets("SetHyperlink","item:"..fields[1]) then miss[#miss+1]=id==6 and "buckle" or "socket" end
    end
    return miss
end
-- Shared with the inspect sheet (ctx.unit; other players' professions are unknown).
ns.MissingFor=MissingFor
local function Own(obj) ns.owned[obj]=true; return obj end
local function Font(fs,size)
    local flags=E.GetFontOutlineFlag and E.GetFontOutlineFlag("blizzardSkin") or ""
    flags=flags:gsub(",?%s*SLUG","")
    if not fs:SetFont(E.GetFontPath("blizzardSkin"),size,flags) then
        fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",size,"")
    end
end
local function Text(parent,size,name)
    local fs=Own(parent:CreateFontString(name,"OVERLAY")); Font(fs,size)
    if fs.SetWordWrap then fs:SetWordWrap(false) end
    fs:SetTextColor(.9,.9,.9,1); return fs
end
local flagTips={enchant="Missing enchant",sockets="Empty socket",buckle="Missing belt buckle",socket="Missing Blacksmithing socket"}
ns.missingArt,ns.missingTips=flagArt,flagTips
local MAX_BADGES=7
local function FlagIcons(c,slot)
    local icons=c.flags[slot]; if icons then return icons end
    icons={}
    for i=1,MAX_BADGES do
        local b=Own(CreateFrame("Frame",nil,c.host)); b:SetSize(14,14)
        b:SetBackdrop({bgFile=flat,edgeFile=flat,edgeSize=1})
        b:SetBackdropColor(0,0,0,.85); b:SetBackdropBorderColor(1,.2,.2,1)
        b.tex=Own(b:CreateTexture(nil,"ARTWORK"))
        b.tex:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.tex:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1)
        b:EnableMouse(true)
        b:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            if self.link then GameTooltip:SetHyperlink(self.link) else GameTooltip:SetText(self.tip or "",unpack(self.tipColor or {1,.3,.3})) end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end)
        b:Hide(); icons[i]=b
    end
    c.flags[slot]=icons; return icons
end
local function AnchorItemLabel(c,slot,raised,enchanted)
    local fs,button,side=c.itemLabels[slot],c.slotButtons[slot],c.slotSides[slot]
    if not (fs and button) then return end
    fs:ClearAllPoints()
    local y=enchanted and 12 or raised and 7 or 0
    if side=="left" then fs:SetPoint("LEFT",button,"RIGHT",6,y)
    elseif side=="right" then fs:SetPoint("RIGHT",button,"LEFT",-6,y)
    else fs:SetPoint("TOP",button,"BOTTOM",0,-4) end
    local ench=c.enchantLabels and c.enchantLabels[slot]
    if ench then
        ench:ClearAllPoints()
        if side=="left" then ench:SetPoint("TOPLEFT",fs,"BOTTOMLEFT",0,-1); ench:SetJustifyH("LEFT")
        elseif side=="right" then ench:SetPoint("TOPRIGHT",fs,"BOTTOMRIGHT",0,-1); ench:SetJustifyH("RIGHT")
        else ench:SetPoint("TOP",fs,"BOTTOM",0,-1); ench:SetJustifyH("CENTER") end
    end
end
-- Badges share one row beside the slot: missing enhancements first, then the
-- enchant icon and socketed gems.
local function ShowFlags(c,slot,miss,extras,enchanted)
    local list={}
    for i=1,(miss and #miss or 0) do
        local kind=miss[i]; local art=flagArt[kind]
        local tip=E.L(flagTips[kind])
        if kind=="sockets" and miss.sockets>1 then tip=tip.." x"..miss.sockets end
        list[#list+1]={texture=art[1],crop=art[2],tip=tip,border={1,.2,.2}}
    end
    for _,entry in ipairs(extras or {}) do list[#list+1]=entry end
    local count=math.min(#list,MAX_BADGES)
    local icons=(count>0 or c.flags[slot]) and FlagIcons(c,slot)
    AnchorItemLabel(c,slot,count>0,enchanted)
    if not icons then return end
    local button,side=c.slotButtons[slot],c.slotSides[slot]
    for i,b in ipairs(icons) do
        local entry=i<=count and list[i]
        if entry then
            b.tex:SetTexture(entry.texture)
            if entry.crop then b.tex:SetTexCoord(.08,.92,.08,.92) else b.tex:SetTexCoord(0,1,0,1) end
            b.tip,b.link,b.tipColor=entry.tip,entry.link,entry.tipColor
            b:SetBackdropBorderColor(unpack(entry.border))
            b:ClearAllPoints()
            local step=(i-1)*16
            if side=="left" then b:SetPoint("BOTTOMLEFT",button,"BOTTOMRIGHT",6+step,2)
            elseif side=="right" then b:SetPoint("BOTTOMRIGHT",button,"BOTTOMLEFT",-6-step,2)
            else b:SetPoint("BOTTOMLEFT",button,"TOPLEFT",(40-(count*16-2))/2+step,3) end
            if c.textHidden then b:Hide() else b:Show() end
        else b:Hide() end
    end
end
local function SlotExtras(c,slot,link,quality)
    local extras,enchantName={},nil
    local Items=ns.Items
    if not (link and Items) then return extras end
    if ns.GetValue("showEnchants")~=false then
        local text=Items.EnchantText(link)
        if text then
            if ns.GetValue("charSheetEnchantNames") then enchantName=text
            else extras[#extras+1]={texture="Interface\\Icons\\Trade_Engraving",crop=true,tip=text,tipColor={.1,1,.1},border={.1,.8,.1}} end
        end
    end
    if ns.GetValue("showGems")~=false then
        for _,gem in ipairs(Items.Gems(link)) do
            local r,g,b=Items.QualityColor(gem.quality)
            extras[#extras+1]={texture=gem.icon or "Interface\\Icons\\INV_Misc_QuestionMark",crop=true,link=gem.link,border={r,g,b}}
        end
    end
    local ench=c.enchantLabels[slot]
    if enchantName and not c.textHidden then
        local size=math.max(6,math.min(16,tonumber(ns.GetValue("charSheetEnchantSize")) or 9))
        ns.ApplyFont(ench,size,"OUTLINE")
        local r,g,b=Items.QualityColor(quality)
        ench:SetTextColor(r+(1-r)*.5,g+(1-g)*.5,b+(1-b)*.5,.9)
        -- Long names stop short of the model centre and the opposite column.
        ench:SetWidth(c.slotSides[slot]=="bottom" and 120 or 130)
        ench:SetText(enchantName); ench:Show()
    else ench:SetText(""); ench:Hide() end
    return extras,enchantName~=nil
end
local function DurabilityText()
    local Items=ns.Items
    local pct=Items and GetInventoryItemDurability and Items.LowestDurability()
    if not pct then return nil end
    local r,g,b=Items.DurabilityColor(pct)
    local value=string.format("|cff%02x%02x%02x%d%%|r",math.floor(r*255),math.floor(g*255),math.floor(b*255),math.floor(pct+.5))
    if ns.GetValue("charSheetDurabilityShowLabel")~=false then return (DURABILITY or "Durability")..": "..value end
    return value
end
local function Save(c,obj)
    if not obj or c.geometry[obj] then return end
    local d={points={},width=obj:GetWidth(),height=obj:GetHeight(),alpha=obj:GetAlpha()}
    for i=1,obj:GetNumPoints() do d.points[i]={obj:GetPoint(i)} end
    c.geometry[obj]=d
end
local function Place(c,obj,point,relative,relPoint,x,y,w,h)
    if not obj then return end
    Save(c,obj); obj:ClearAllPoints(); obj:SetPoint(point,relative,relPoint,x,y)
    if w then obj:SetSize(w,h) end
end
local function HideNative(c,obj)
    if not obj then return end
    if c.hidden[obj]==nil then c.hidden[obj]=obj:IsShown() end
    obj:Hide()
end
local function LayoutTabs(s,c)
    local x,row=0,0
    local available=s.frame:GetWidth()-48
    for i=1,10 do
        local tab=_G["CharacterFrameTab"..i]
        if tab and tab:IsShown() then
            local label=tab.GetFontString and tab:GetFontString()
            local width=math.max(62,(label and label:GetStringWidth() or 50)+28)
            if x>0 and x+width>available then x,row=0,row+1 end
            Place(c,tab,"TOPLEFT",s.panel,"BOTTOMLEFT",x,-5-row*31,width,28)
            x=x+width+6
        end
    end
    if c.enhanced then
        -- Reserve another footer row rather than drawing wrapped tabs below
        -- the window's click/clamp bounds. The content keeps its same height.
        s.frame:SetHeight(580+row*31)
        s.panel:SetPoint("BOTTOMRIGHT",s.frame,"BOTTOMRIGHT",-12,40+row*31)
    end
end
local function RestoreGeometry(c)
    for obj,d in pairs(c.geometry) do
        obj:ClearAllPoints()
        for _,point in ipairs(d.points) do obj:SetPoint(unpack(point)) end
        obj:SetSize(d.width,d.height); obj:SetAlpha(d.alpha)
    end
    for obj,shown in pairs(c.hidden) do if shown then obj:Show() else obj:Hide() end end
    c.geometry,c.hidden={},{}
end
function ns.RestoreCharacter(s)
    local c=s.character; if not c then return end
    if c.host then c.host:Hide(); c.header:Hide() end
    RestoreGeometry(c)
    if c.widthSaved then s.frame:SetAttribute("UIPanelLayout-width",c.nativePanelWidth); c.widthSaved=nil end
    if c.titleParent then PlayerTitlePickerFrame:SetParent(c.titleParent); c.titleParent=nil end
    if c.popupParent then
        local popup=GearManagerDialogPopup
        popup:Hide(); popup:SetParent(c.popupParent); popup:SetFrameLevel(c.popupLevel)
        c.popupParent,c.popupLevel=nil,nil
    end
    if c.popupBg then c.popupBg:Hide() end
    if c.backdrop then c.backdrop:Hide() end
    local model=_G.CharacterModelFrame
    if c.modelHooked and model then
        c.drag=nil
        if model.EnableMouseWheel then model:EnableMouseWheel(c.nativeWheel and true or false) end
        if model.SetPosition then model:SetPosition(0,0,0) end
    end
    if ns.SocketPanel then ns.SocketPanel.Hide(c) end
    c.enhanced=false
end
local equipSlots={INVTYPE_HEAD={1},INVTYPE_NECK={2},INVTYPE_SHOULDER={3},INVTYPE_CHEST={5},INVTYPE_ROBE={5},
    INVTYPE_WAIST={6},INVTYPE_LEGS={7},INVTYPE_FEET={8},INVTYPE_WRIST={9},INVTYPE_HAND={10},INVTYPE_FINGER={11,12},
    INVTYPE_TRINKET={13,14},INVTYPE_CLOAK={15},INVTYPE_WEAPON={16},INVTYPE_2HWEAPON={16},INVTYPE_WEAPONMAINHAND={16},
    INVTYPE_WEAPONOFFHAND={17},INVTYPE_SHIELD={17},INVTYPE_HOLDABLE={17},INVTYPE_RANGED={18},INVTYPE_RANGEDRIGHT={18},
    INVTYPE_THROWN={18},INVTYPE_RELIC={18}}
-- Bag gear with a higher item level than the weakest matching equipped slot
-- and no red (unmet) requirement on its tooltip.
function ns.BetterBagItems()
    local Items=ns.Items
    if not (Items and GetContainerNumSlots and GetContainerItemLink) then return {} end
    local equipped={}
    local function Equipped(slot)
        if equipped[slot]==nil then
            local link=GetInventoryItemLink("player",slot)
            equipped[slot]=link and select(4,GetItemInfo(link)) or 0
        end
        return equipped[slot]
    end
    local found={}
    for bag=0,(NUM_BAG_SLOTS or 4) do
        for index=1,GetContainerNumSlots(bag) or 0 do
            local link=GetContainerItemLink(bag,index)
            if link then
                local _,_,quality,level,_,_,_,_,equip=GetItemInfo(link)
                local targets=level and equipSlots[equip]
                if targets then
                    local slot,current=targets[1],Equipped(targets[1])
                    for i=2,#targets do if Equipped(targets[i])<current then slot,current=targets[i],Equipped(targets[i]) end end
                    if level>current and Items.Usable("SetBagItem",bag,index) then
                        found[#found+1]={link=link,level=level,current=current,slot=slot,quality=quality}
                    end
                end
            end
        end
    end
    table.sort(found,function(a,b) if a.slot~=b.slot then return a.slot<b.slot end return a.level>b.level end)
    return found
end
local slotNames={}
for name,id in pairs(ids) do slotNames[id]=name end
local function BetterItemsTooltip(owner)
    local list=ns.BetterBagItems()
    GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
    GameTooltip:AddLine(E.L("Better Items in Bags"),1,.82,0)
    if #list==0 then GameTooltip:AddLine(E.L("No better items in your bags"),.7,.7,.7) end
    for _,entry in ipairs(list) do
        local label=_G[(slotNames[entry.slot] or ""):upper().."SLOT"] or slotNames[entry.slot] or ""
        GameTooltip:AddDoubleLine(label..": "..entry.link,string.format("%d > |cff33ff33%d|r",entry.current,entry.level),.9,.9,.9,.9,.9,.9)
    end
    GameTooltip:Show()
end
local function OrderedSections(c)
    local order=ns.GetSettings().statSectionsOrder
    local list,used={},{}
    for _,title in ipairs(type(order)=="table" and order or {}) do
        for _,section in ipairs(c.sections) do
            if section.title==title and not used[section] then list[#list+1]=section; used[section]=true end
        end
    end
    for _,section in ipairs(c.sections) do if not used[section] then list[#list+1]=section end end
    return list
end
local function MoveSection(c,section,delta)
    local list=OrderedSections(c)
    for i,entry in ipairs(list) do
        if entry==section then
            local j=i+delta
            while list[j] and ns.GetValue("showStatCategory_"..list[j].key)==false do j=j+delta end
            if list[j] then list[i],list[j]=list[j],list[i] end
            break
        end
    end
    local order={}
    for i,entry in ipairs(list) do order[i]=entry.title end
    ns.GetSettings().statSectionsOrder=order
end
function ns.SectionColor(title,r,g,b)
    local db=ns.GetSettings()
    local use=type(db.statCategoryUseColor)=="table" and db.statCategoryUseColor[title]
    local color=type(db.statCategoryColors)=="table" and db.statCategoryColors[title]
    if use and type(color)=="table" then return color.r or r,color.g or g,color.b or b end
    return r,g,b
end
local function Flow(c)
    local y=0
    local list=OrderedSections(c)
    local shown={}
    for _,section in ipairs(list) do
        if ns.GetValue("showStatCategory_"..section.key)~=false then shown[#shown+1]=section
        else section.header:Hide(); for _,row in ipairs(section.rows) do row:Hide() end end
    end
    for index,section in ipairs(shown) do
        section.header:ClearAllPoints(); section.header:SetPoint("TOPLEFT",c.child,"TOPLEFT",0,-y); section.header:Show()
        section.up:SetAlpha(index>1 and 1 or .25); section.down:SetAlpha(index<#shown and 1 or .25)
        y=y+28
        for _,row in ipairs(section.rows) do
            if not section.collapsed and row.available then
                row:ClearAllPoints(); row:SetPoint("TOPLEFT",c.child,"TOPLEFT",4,-y)
                row:Show(); y=y+21
            else row:Hide() end
        end
        y=y+9
    end
    local height=c.scrollHeight or 340
    c.scroll:SetHeight(height); c.scrollbar:SetHeight(height)
    c.child:SetHeight(math.max(1,y))
    c.maxScroll=math.max(0,y-height)
    c.scroll:SetVerticalScroll(math.min(c.scroll:GetVerticalScroll() or 0,c.maxScroll))
    c.scrollbar:SetMinMaxValues(0,c.maxScroll)
    c.scrollbar:SetValue(c.scroll:GetVerticalScroll() or 0)
end
local function AccentRGB()
    if E.GetAccentColor then local r,g,b=E.GetAccentColor(); if r then return r,g,b end end
    return 1,.8,.2
end
local function FlatButton(parent,w,h,label)
    local b=Own(CreateFrame("Button",nil,parent)); b:SetSize(w,h)
    b:SetBackdrop({bgFile=flat,edgeFile=flat,edgeSize=1})
    b:SetBackdropColor(.08,.08,.08,1); b:SetBackdropBorderColor(.25,.25,.25,1)
    b.label=Text(b,11); b.label:SetPoint("CENTER",b,"CENTER",0,0); b.label:SetText(label)
    b:SetScript("OnEnter",function(self) if self.enabled~=false then self:SetBackdropBorderColor(AccentRGB()) end end)
    b:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(.25,.25,.25,1) end)
    return b
end
local function SetButtonEnabled(b,on)
    b.enabled=on
    if on then b.label:SetTextColor(.9,.9,.9,1) else b.label:SetTextColor(.4,.4,.4,1) end
    if on and b.Enable then b:Enable() elseif not on and b.Disable then b:Disable() end
end
local function HideSetPrompts()
    if StaticPopup_Hide then StaticPopup_Hide("CONFIRM_SAVE_EQUIPMENT_SET"); StaticPopup_Hide("CONFIRM_OVERWRITE_EQUIPMENT_SET") end
end
local function ClearIgnoredSlots() if PaperDollFrame_ClearIgnoredSlots then PaperDollFrame_ClearIgnoredSlots() end end
local function SetIsEquipped(name)
    local items=GetEquipmentSetItemIDs and GetEquipmentSetItemIDs(name)
    if type(items)~="table" then return false end
    local any=false
    for slot=1,19 do
        local want=items[slot]
        if want and want>1 then
            any=true
            local have=GetInventoryItemID and GetInventoryItemID("player",slot)
                or tonumber((GetInventoryItemLink("player",slot) or ""):match("item:(%d+)"))
            if have~=want then return false end
        end
    end
    return any
end
local function SkinSetPopup(c,popup)
    for _,region in ipairs({popup:GetRegions()}) do
        if region:IsObjectType("Texture") and not ns.owned[region] then Save(c,region); region:SetAlpha(0) end
    end
    if not c.popupBg then
        local bg=Own(CreateFrame("Frame",nil,popup)); c.popupBg=bg
        bg:SetPoint("TOPLEFT",popup,"TOPLEFT",5,-10); bg:SetPoint("BOTTOMRIGHT",popup,"BOTTOMRIGHT",-39,8)
        bg:SetBackdrop({bgFile=flat,edgeFile=flat,edgeSize=1})
        bg:SetBackdropColor(.04,.04,.04,.96)
    end
    c.popupBg:SetFrameLevel(popup:GetFrameLevel())
    c.popupBg:SetBackdropBorderColor(AccentRGB())
    c.popupBg:Show()
end
local function OpenSetPopup(c,editName,editTexture)
    local popup=_G.GearManagerDialogPopup
    if not popup or InCombatLockdown() then return end
    if not c.popupParent then c.popupParent,c.popupLevel=popup:GetParent(),popup:GetFrameLevel() end
    popup:SetParent(c.frame)
    Place(c,popup,"TOPLEFT",c.frame,"TOPRIGHT",-6,-40)
    popup:SetFrameLevel(c.frame:GetFrameLevel()+20)
    SkinSetPopup(c,popup)
    -- Native recalculation reads GearManagerDialog.selectedSet, not arguments.
    -- Set it before Show (OnShow may run), and rebuild even if already visible.
    if _G.GearManagerDialog then
        GearManagerDialog.selectedSet=nil
        GearManagerDialog.selectedSetName=editName
        for _,row in ipairs(c.equipment and c.equipment.rows or {}) do
            if editName and row.name==editName then GearManagerDialog.selectedSet=row; break end
        end
    end
    popup.selectedSetName=nil
    popup.isEdit,popup.origName=editName~=nil,editName
    if not editName and popup.SetSelection then popup:SetSelection(true,nil) end
    popup:Show()
    if RecalculateGearManagerDialogPopup then RecalculateGearManagerDialogPopup() end
end
local function UpdateEquipment(c)
    local eq=c.equipment; if not eq then return end
    local num=GetNumEquipmentSets and GetNumEquipmentSets() or 0
    local maxSets=MAX_EQUIPMENT_SETS_PER_PLAYER or 10
    if c.selectedSet and not (GetEquipmentSetInfoByName and GetEquipmentSetInfoByName(c.selectedSet)) then
        c.selectedSet=nil; ClearIgnoredSlots()
    end
    local r,g,b=AccentRGB()
    for i,row in ipairs(eq.rows) do
        if i<=num then
            local name,texture=GetEquipmentSetInfo(i)
            row.name=name
            row.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.text:SetText(name or ""); row.text:SetTextColor(.95,.95,.95,1)
            row.selected=name~=nil and name==c.selectedSet
            if name and SetIsEquipped(name) then row.check:Show() else row.check:Hide() end
            row:Show()
        elseif i==num+1 and num<maxSets then
            row.name,row.selected=nil,false
            row.icon:SetTexture("Interface\\Icons\\Spell_ChargePositive")
            row.text:SetText(E.L("New Set")); row.text:SetTextColor(.3,1,.3,1)
            row.check:Hide(); row:Show()
        else row:Hide() end
        if row.selected then row.bg:SetVertexColor(r,g,b,.25)
        elseif i%2==0 then row.bg:SetVertexColor(1,1,1,.04)
        else row.bg:SetVertexColor(1,1,1,0) end
        Font(row.text,11)
    end
    SetButtonEnabled(eq.equip,c.selectedSet~=nil); SetButtonEnabled(eq.save,c.selectedSet~=nil)
end
local function SetRowHover(row,hover)
    local show=hover and row.name~=nil
    if show then row.delete:Show(); row.edit:Show() else row.delete:Hide(); row.edit:Hide() end
    if hover then row.hover:Show() else row.hover:Hide() end
end
local function BuildEquipment(c)
    local eq=Own(CreateFrame("Frame",nil,c.sidebar)); c.equipment=eq
    eq:SetPoint("TOPLEFT",c.sidebar,"TOPLEFT",7,-32); eq:SetPoint("BOTTOMRIGHT",c.sidebar,"BOTTOMRIGHT",-7,8)
    eq:Hide()
    eq.equip=FlatButton(eq,102,22,EQUIPSET_EQUIP or "Equip"); eq.equip:SetPoint("TOPLEFT",eq,"TOPLEFT",0,0)
    eq.save=FlatButton(eq,102,22,SAVE or "Save"); eq.save:SetPoint("TOPRIGHT",eq,"TOPRIGHT",0,0)
    eq.equip:SetScript("OnClick",function()
        if c.selectedSet and EquipmentManager_EquipSet then
            if PlaySound then PlaySound("igCharacterInfoTab") end
            EquipmentManager_EquipSet(c.selectedSet)
        end
    end)
    eq.save:SetScript("OnClick",function(self)
        if not c.selectedSet or not _G.GearManagerDialog then return end
        for _,row in ipairs(eq.rows) do
            if row.name==c.selectedSet then
                OpenSetPopup(c,row.name,row.icon:GetTexture())
                return
            end
        end
    end)
    eq.rows={}
    for i=1,(MAX_EQUIPMENT_SETS_PER_PLAYER or 10)+1 do
        local row=Own(CreateFrame("Button",nil,eq)); row:SetSize(208,32)
        row:SetPoint("TOPLEFT",eq,"TOPLEFT",0,-30-(i-1)*34)
        row.bg=Own(row:CreateTexture(nil,"BACKGROUND")); row.bg:SetTexture(flat); row.bg:SetAllPoints(row)
        row.hover=Own(row:CreateTexture(nil,"BORDER")); row.hover:SetTexture(flat); row.hover:SetAllPoints(row)
        row.hover:SetVertexColor(1,1,1,.07); row.hover:Hide()
        local edge=Own(row:CreateTexture(nil,"BORDER")); edge:SetTexture(flat); edge:SetVertexColor(0,0,0,1)
        edge:SetSize(30,30); edge:SetPoint("LEFT",row,"LEFT",1,0)
        row.icon=Own(row:CreateTexture(nil,"ARTWORK")); row.icon:SetSize(28,28); row.icon:SetPoint("LEFT",row,"LEFT",2,0)
        row.icon:SetTexCoord(.08,.92,.08,.92)
        row.text=Text(row,11); row.text:SetPoint("LEFT",row.icon,"RIGHT",8,0); row.text:SetPoint("RIGHT",row,"RIGHT",-42,0)
        row.text:SetJustifyH("LEFT")
        row.check=Own(row:CreateTexture(nil,"OVERLAY")); row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        row.check:SetSize(18,18); row.check:SetPoint("RIGHT",row,"RIGHT",-4,0); row.check:Hide()
        local function Mini(texture,size,tip)
            local b=Own(CreateFrame("Button",nil,row)); b:SetSize(size,size)
            b.tex=Own(b:CreateTexture(nil,"ARTWORK")); b.tex:SetTexture(texture); b.tex:SetAllPoints(b); b.tex:SetAlpha(.6)
            b:SetScript("OnEnter",function(self)
                self.tex:SetAlpha(1); SetRowHover(row,true)
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(tip); GameTooltip:Show()
            end)
            b:SetScript("OnLeave",function(self)
                self.tex:SetAlpha(.6); GameTooltip:Hide()
                if not (row.IsMouseOver and row:IsMouseOver()) then SetRowHover(row,false) end
            end)
            b:Hide(); return b
        end
        row.delete=Mini("Interface\\Buttons\\UI-GroupLoot-Pass-Up",14,DELETE or "Delete")
        row.delete:SetPoint("RIGHT",row,"RIGHT",-24,0)
        row.edit=Mini("Interface\\WorldMap\\GEAR_64GREY",16,E.L("Change Name/Icon"))
        row.edit:SetPoint("RIGHT",row.delete,"LEFT",-3,0)
        row.delete:SetScript("OnClick",function()
            if not row.name or not StaticPopup_Show then return end
            local dialog=StaticPopup_Show("CONFIRM_DELETE_EQUIPMENT_SET",row.name)
            if dialog then dialog.data=row.name end
        end)
        row.edit:SetScript("OnClick",function()
            if not row.name then return end
            c.selectedSet=row.name; UpdateEquipment(c)
            OpenSetPopup(c,row.name,row.icon:GetTexture())
        end)
        row:SetScript("OnClick",function(self)
            ClearIgnoredSlots()
            if self.name then
                c.selectedSet=self.name
                if PaperDollFrame_IgnoreSlotsForSet then PaperDollFrame_IgnoreSlotsForSet(self.name) end
                if _G.GearManagerDialogPopup then GearManagerDialogPopup:Hide() end
            else
                c.selectedSet=nil
                OpenSetPopup(c)
            end
            HideSetPrompts(); UpdateEquipment(c)
        end)
        row:SetScript("OnDoubleClick",function(self)
            if self.name and EquipmentManager_EquipSet then EquipmentManager_EquipSet(self.name) end
        end)
        if row.RegisterForDrag then row:RegisterForDrag("LeftButton") end
        row:SetScript("OnDragStart",function(self)
            if self.name and PickupEquipmentSetByName then PickupEquipmentSetByName(self.name) end
        end)
        row:SetScript("OnEnter",function(self)
            SetRowHover(self,true)
            if self.name and GameTooltip.SetEquipmentSet then
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetEquipmentSet(self.name); GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave",function(self)
            GameTooltip:Hide()
            if not (self.IsMouseOver and self:IsMouseOver()) then SetRowHover(self,false) end
        end)
        eq.rows[i]=row
    end
    for _,event in ipairs({"EQUIPMENT_SETS_CHANGED","EQUIPMENT_SWAP_FINISHED","PLAYER_EQUIPMENT_CHANGED"}) do eq:RegisterEvent(event) end
    eq:SetScript("OnEvent",function(self,event,completed,setName)
        if event=="EQUIPMENT_SWAP_FINISHED" and completed and setName then c.selectedSet=setName end
        if self:IsShown() then UpdateEquipment(c) end
    end)
    eq:SetScript("OnShow",function()
        UpdateEquipment(c)
        if PaperDollFrameItemPopoutButton_ShowAll then PaperDollFrameItemPopoutButton_ShowAll() end
    end)
    eq:SetScript("OnHide",function()
        ClearIgnoredSlots()
        if PaperDollFrameItemPopoutButton_HideAll then PaperDollFrameItemPopoutButton_HideAll() end
        if _G.GearManagerDialogPopup then GearManagerDialogPopup:Hide() end
        HideSetPrompts()
    end)
end
local function TabColor(c,kind)
    local button=c.tabs[kind]; if not button then return end
    if c.mode==kind then button.label:SetTextColor(1,.8,.2,1) else button.label:SetTextColor(.7,.7,.7,1) end
end
local function SetSidebarMode(c,kind)
    if InCombatLockdown() then return end
    local picker=_G.PlayerTitlePickerFrame
    if kind=="titles" and picker and picker:IsShown() then kind="stats" end
    c.mode=kind
    local stats=kind~="equipment"
    for _,obj in ipairs({c.summary,c.summaryLabel,c.health,c.scroll,c.scrollbar,c.better}) do
        if stats then obj:Show() else obj:Hide() end
    end
    if c.updateExtras then c.updateExtras(c) end
    if _G.GearManagerDialog then GearManagerDialog:Hide() end
    if kind=="equipment" then c.equipment:Show() else c.equipment:Hide() end
    if picker then
        if kind=="titles" then
            if not c.titleParent then c.titleParent=picker:GetParent() end
            picker:SetParent(c.frame)
            Place(c,picker,"TOPLEFT",c.sidebar,"TOPLEFT",0,-30)
            picker:Show()
        else picker:Hide() end
    end
    for tab in pairs(c.tabs) do TabColor(c,tab) end
end
local function Build(s,c)
    local host=Own(CreateFrame("Frame",nil,PaperDollFrame)); c.host=host
    host:SetAllPoints(s.frame); host:SetFrameLevel(PaperDollFrame:GetFrameLevel()+2)
    local header=Own(CreateFrame("Frame",nil,s.frame)); c.header=header
    header:SetAllPoints(s.frame); header:SetFrameLevel(s.frame:GetFrameLevel()+2)
    header:EnableMouse(false)
    c.name=Text(header,15); c.name:SetPoint("TOP",s.frame,"TOP",0,-22); c.name:SetWidth(550)
    c.level=Text(header,12); c.level:SetPoint("TOP",c.name,"BOTTOM",0,-5)
    local sidebar=Own(CreateFrame("Frame",nil,host)); c.sidebar=sidebar
    sidebar:SetSize(222,455); sidebar:SetPoint("TOPLEFT",s.frame,"TOPLEFT",414,-67)
    sidebar:SetBackdrop({bgFile=flat}); sidebar:SetBackdropColor(.04,.04,.04,.94)
    c.tabs={}
    for i,entry in ipairs({{"Character","stats"},{"Titles","titles"},{"Equipment","equipment"}}) do
        local button=Own(CreateFrame("Button",nil,sidebar)); button:SetSize(72,24)
        button:SetPoint("TOPLEFT",sidebar,"TOPLEFT",(i-1)*74,0)
        local label=Text(button,11); label:SetPoint("CENTER"); label:SetText(E.L(entry[1]))
        label:SetTextColor(i==1 and 1 or .7,i==1 and .8 or .7,i==1 and .2 or .7,1)
        local kind=entry[2]
        button:SetScript("OnClick",function() SetSidebarMode(c,kind) end)
        button:SetScript("OnEnter",function() label:SetTextColor(1,.8,.2,1) end)
        button:SetScript("OnLeave",function() TabColor(c,kind) end)
        c.tabs[kind]=button
        button.label=label
    end
    c.summary=Text(sidebar,23); c.summary:SetPoint("TOP",sidebar,"TOP",0,-39)
    c.summary:SetTextColor(.7,.36,.95,1)
    c.summaryLabel=Text(sidebar,11); c.summaryLabel:SetPoint("TOP",c.summary,"BOTTOM",0,-5)
    c.summaryLabel:SetText(E.L("Equipped Item Level")); c.summaryLabel:SetTextColor(.65,.65,.65,1)
    c.health=Text(sidebar,11); c.health:SetPoint("TOP",c.summaryLabel,"BOTTOM",0,-8)
    c.health:SetTextColor(.05,.82,.62,1)
    local scroll=Own(CreateFrame("ScrollFrame",nil,sidebar)); c.scroll=scroll
    scroll:SetSize(204,340); scroll:SetPoint("TOPLEFT",sidebar,"TOPLEFT",7,-116)
    local child=Own(CreateFrame("Frame",nil,scroll)); c.child=child; child:SetSize(204,1); scroll:SetScrollChild(child)
    local scrollbar=Own(CreateFrame("Slider",nil,sidebar)); c.scrollbar=scrollbar
    scrollbar:SetSize(6,340); scrollbar:SetPoint("TOPRIGHT",scroll,"TOPRIGHT",10,0)
    scrollbar:SetOrientation("VERTICAL"); scrollbar:SetMinMaxValues(0,1); scrollbar:SetValueStep(1)
    scrollbar:SetThumbTexture(flat)
    local thumb=scrollbar:GetThumbTexture(); thumb:SetSize(6,28); thumb:SetVertexColor(.3,.3,.3,1)
    scrollbar:SetScript("OnValueChanged",function(_,value) scroll:SetVerticalScroll(value) end)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel",function(_,delta) scrollbar:SetValue(math.max(0,math.min(c.maxScroll or 0,scroll:GetVerticalScroll()-delta*42))) end)
    c.sections={}
    for _,spec in ipairs(groups) do
        local section={rows={},prefix="EUI335CharacterStats"..spec.key,token=spec.token,color=spec.color,nativeColor=spec.color,key=spec.key,title=spec.text}
        local header=Own(CreateFrame("Button",nil,child)); section.header=header; header:SetSize(204,25)
        local label=Text(header,12); label:SetPoint("CENTER"); label:SetText(E.L(spec.text)); label:SetTextColor(unpack(spec.color))
        local line=Own(header:CreateTexture(nil,"BACKGROUND")); line:SetTexture(flat); line:SetVertexColor(unpack(spec.color))
        line:SetHeight(1); line:SetPoint("BOTTOMLEFT",header,"BOTTOMLEFT",2,0); line:SetPoint("BOTTOMRIGHT",header,"BOTTOMRIGHT",-2,0)
        section.label,section.line=label,line
        for _,arrow in ipairs({{"up",-1,"LEFT",2},{"down",1,"RIGHT",-2}}) do
            local b=Own(CreateFrame("Button",nil,header)); b:SetSize(18,18); b:SetPoint(arrow[3],header,arrow[3],arrow[4],1)
            local dir=arrow[1]=="up" and "Up" or "Down"
            b.tex=Own(b:CreateTexture(nil,"ARTWORK")); b.tex:SetAllPoints(b)
            b.tex:SetTexture("Interface\\Buttons\\UI-ScrollBar-Scroll"..dir.."Button-Up")
            b:SetScript("OnEnter",function(self) self.tex:SetVertexColor(1,.8,.2,1) end)
            b:SetScript("OnLeave",function(self) self.tex:SetVertexColor(1,1,1,1) end)
            local delta=arrow[2]
            b:SetScript("OnClick",function() MoveSection(c,section,delta); Flow(c) end)
            section[arrow[1]]=b
        end
        local title=E.L(spec.text)
        label:SetText(title.."  -")
        header:SetScript("OnClick",function()
            section.collapsed=not section.collapsed
            label:SetText(title..(section.collapsed and "  +" or "  -"))
            Flow(c)
        end)
        for i=1,6 do
            local name=section.prefix..i
            local row=Own(CreateFrame("Frame",name,child)); row:SetSize(198,20)
            row.label=Text(row,11,name.."Label"); row.label:SetPoint("LEFT",row,"LEFT",0,0); row.label:SetWidth(92); row.label:SetJustifyH("LEFT")
            row.value=Text(row,11,name.."StatText"); row.value:SetPoint("RIGHT",row,"RIGHT",0,0); row.value:SetWidth(100); row.value:SetJustifyH("RIGHT")
            row:EnableMouse(true)
            row:SetScript("OnEnter",function(self) if PaperDollStatTooltip then PaperDollStatTooltip(self) end; ns.StartStatHighlights(self) end)
            row:SetScript("OnLeave",function() GameTooltip:Hide(); ns.StopStatHighlights() end)
            section.rows[i]=row
        end
        c.sections[#c.sections+1]=section
    end
    c.itemLabels,c.enchantLabels,c.flags,c.slotButtons,c.slotSides={},{},{},{},{}
    local better=Own(CreateFrame("Button",nil,sidebar)); c.better=better
    better:SetSize(200,40); better:SetPoint("TOP",sidebar,"TOP",0,-34)
    better:SetScript("OnEnter",BetterItemsTooltip)
    better:SetScript("OnLeave",function() GameTooltip:Hide() end)
    c.betterArrow=Own(better:CreateTexture(nil,"OVERLAY")); c.betterArrow:SetSize(14,14)
    c.betterArrow:SetTexture("Interface\\Buttons\\UI-MicroStream-Green"); c.betterArrow:SetTexCoord(0,1,1,0)
    c.betterArrow:SetPoint("LEFT",c.summary,"RIGHT",4,0); c.betterArrow:Hide()
    c.durability=Text(sidebar,11)
    local eye=Own(CreateFrame("Button",nil,host)); c.eye=eye
    eye:SetSize(18,18); eye:SetPoint("TOPRIGHT",CharacterModelFrame,"TOPRIGHT",-4,-4)
    eye.tex=Own(eye:CreateTexture(nil,"ARTWORK")); eye.tex:SetAllPoints(eye)
    eye.tex:SetTexture("Interface\\Icons\\Spell_Shadow_EvilEye"); eye.tex:SetTexCoord(.08,.92,.08,.92)
    eye:SetScript("OnClick",function()
        c.textHidden=not c.textHidden
        if c.refresh then c.refresh(c) end
    end)
    eye:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(E.L(c.textHidden and "Show slot details" or "Hide slot details")); GameTooltip:Show()
    end)
    eye:SetScript("OnLeave",function() GameTooltip:Hide() end)
    c.mode="stats"
    BuildEquipment(c)
    c.frame:HookScript("OnHide",function()
        if _G.PlayerTitlePickerFrame and c.titleParent then PlayerTitlePickerFrame:Hide() end
        if c.mode=="titles" then c.mode="stats"; for tab in pairs(c.tabs) do TabColor(c,tab) end end
    end)
    c.frame:HookScript("OnShow",function() c.cacheRetries=75 end)
end
local function Refresh(c)
    local class,token=UnitClass("player")
    local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[token] or {r=1,g=.8,b=.2}
    c.name:SetText((UnitPVPName and UnitPVPName("player")) or UnitName("player"))
    c.level:SetText(string.format("%s %d %s %s",LEVEL or "Level",UnitLevel("player"),UnitRace("player") or "",class or ""))
    c.level:SetTextColor(color.r,color.g,color.b,1)
    Font(c.name,15); Font(c.level,12); Font(c.summary,23); Font(c.summaryLabel,11); Font(c.health,11)
    for _,button in pairs(c.tabs) do Font(button.label,11) end
    local total,pending,mainLevel,twoHand=0,false,nil,false
    local signature={}
    local ctx
    if ns.GetValue("characterMissingEnhancements")~=false and UnitLevel("player")>=(MAX_PLAYER_LEVEL or 80) then
        local _,classToken=UnitClass("player")
        ctx={hunter=classToken=="HUNTER",enchanter=ProfessionRank(7411)>=400,blacksmith=ProfessionRank(2018)>=400}
    end
    for slot,fs in pairs(c.itemLabels) do
        local id=ids[slot]; local link=GetInventoryItemLink("player",id)
        signature[#signature+1]=slot.."="..(link or "")
        local ilvl,quality,equip
        if link then
            local _,_,q,l,_,_,_,_,e=GetItemInfo(link); ilvl,quality,equip=l,q,e
            if not ilvl and id~=4 and id~=19 then pending=true end
        end
        Font(fs,11); fs:SetText(ilvl and tostring(ilvl) or "")
        if quality and GetItemQualityColor then fs:SetTextColor(GetItemQualityColor(quality)) end
        if ns.GetValue("characterItemLevels") and not c.textHidden then fs:Show() else fs:Hide() end
        if id~=4 and id~=19 then total=total+(ilvl or 0) end
        if id==16 then mainLevel,twoHand=ilvl,equip=="INVTYPE_2HWEAPON" end
        if not c.enchantLabels[slot] then c.enchantLabels[slot]=Text(c.host,9) end
        local extras,enchanted=SlotExtras(c,slot,ilvl and link,quality)
        ShowFlags(c,slot,ctx and link and ilvl and MissingFor(id,link,equip,ctx),extras,enchanted)
    end
    if twoHand and not GetInventoryItemLink("player",17) then total=total+(mainLevel or 0) end
    local key=table.concat(signature,";")
    if key~=c.cacheSignature or pending and not c.itemCachePending then c.cacheRetries=75 end
    c.cacheSignature,c.itemCachePending=key,pending
    c.summary:SetText(pending and "..." or string.format("%.2f",total/17))
    local score=not pending and ns.GearScore("player") or 0
    c.health:SetText(pending and "GearScore: ..." or string.format("GearScore: %d",score))
    if pending then c.health:SetTextColor(.65,.65,.65,1) else c.health:SetTextColor(ns.GearScoreColor(score)) end
    for _,section in ipairs(c.sections) do
        Font(section.label,12)
        local r,g,b=ns.SectionColor(section.title,unpack(section.nativeColor))
        section.color={r,g,b}
        section.label:SetTextColor(r,g,b,1); section.line:SetVertexColor(r,g,b,1)
        if UpdatePaperdollStats then UpdatePaperdollStats(section.prefix,section.token) end
        for _,row in ipairs(section.rows) do
            row.available=row:IsShown() and (row.label:GetText() or "")~=""
            Font(row.label,11); Font(row.value,11)
            row.label:SetTextColor(.65,.65,.65,1); row.value:SetTextColor(r,g,b,1)
        end
    end
    local now=GetTime and GetTime() or 0
    if not c.betterAt or now-c.betterAt>5 or c.betterKey~=key then
        c.betterAt,c.betterKey=now,key
        c.hasBetter=not pending and #ns.BetterBagItems()>0
    end
    if c.hasBetter then c.betterArrow:Show() else c.betterArrow:Hide() end
    if c.eye.tex.SetDesaturated then c.eye.tex:SetDesaturated(c.textHidden and true or false) end
    c.updateExtras(c)
    Flow(c)
end
local function UpdateExtras(c)
    local stats=c.mode~="equipment"
    local text=ns.GetValue("showCharSheetDurability") and DurabilityText()
    local location=ns.GetValue("charSheetDurabilityLocation")
    local fs=c.durability
    if text and (location~="header" or stats) then
        fs:ClearAllPoints()
        if location=="header" then fs:SetPoint("TOP",c.health,"BOTTOM",0,-3)
        elseif location=="footer" then fs:SetPoint("BOTTOMRIGHT",c.sidebar,"BOTTOMRIGHT",-4,-15)
        else fs:SetPoint("TOP",CharacterModelFrame,"TOP",0,-6) end
        Font(fs,11); fs:SetText(text); fs:Show()
    else fs:Hide() end
    c.scrollHeight=340
    if ns.SocketPanel then ns.SocketPanel.Update(c,stats) end
    if c.scroll:GetHeight()~=c.scrollHeight then Flow(c) end
end
function ns.CharacterNeedsRefresh()
    -- Wrath has no GET_ITEM_INFO_RECEIVED. Retry uncached equipment while
    -- the paper doll is visible, with a bound of 15 seconds per gear change.
    local s=_G.CharacterFrame and ns.states[CharacterFrame]
    local c=s and s.character
    if c and c.enhanced and c.itemCachePending and (c.cacheRetries or 0)>0
        and CharacterFrame:IsShown() and PaperDollFrame:IsShown() then
        c.cacheRetries=c.cacheRetries-1
        return true
    end
    return false
end
local function Clamp(v,low,high) return math.max(low,math.min(high,v)) end
-- Left-drag rotates through the native rotation field the rotate buttons use,
-- right-drag pans and the wheel zooms; the native item drop on mouse-up stays.
local function ModelControls(c)
    local model=_G.CharacterModelFrame
    if not model or c.modelHooked then
        if model and model.EnableMouseWheel then model:EnableMouseWheel(true) end
        return
    end
    c.modelHooked=true
    c.nativeWheel=model.IsMouseWheelEnabled and model:IsMouseWheelEnabled()
    if model.EnableMouseWheel then model:EnableMouseWheel(true) end
    model:HookScript("OnMouseDown",function(self,button)
        if not c.enhanced or not GetCursorPosition then return end
        local x,y=GetCursorPosition()
        local px,py,pz=0,0,0
        if self.GetPosition then px,py,pz=self:GetPosition() end
        c.drag={button=button,x=x,y=y,rotation=self.rotation or (self.GetFacing and self:GetFacing()) or 0,px=px or 0,py=py or 0,pz=pz or 0}
    end)
    model:HookScript("OnMouseUp",function() c.drag=nil end)
    model:HookScript("OnHide",function() c.drag=nil end)
    model:HookScript("OnUpdate",function(self)
        local d=c.drag
        if not d or not c.enhanced then return end
        local x,y=GetCursorPosition()
        local scale=self:GetEffectiveScale() or 1
        local dx,dy=(x-d.x)/scale,(y-d.y)/scale
        if d.button=="LeftButton" then
            local rotation=d.rotation+dx*.02
            if self.SetRotation then self.rotation=rotation; self:SetRotation(rotation)
            elseif self.SetFacing then self:SetFacing(rotation) end
        elseif d.button=="RightButton" and self.SetPosition then
            self:SetPosition(d.px,Clamp(d.py+dx/150,-1.5,1.5),Clamp(d.pz+dy/150,-1.5,1.5))
        end
    end)
    model:HookScript("OnMouseWheel",function(self,delta)
        if not c.enhanced or not self.SetPosition or not self.GetPosition then return end
        local x,y,z=self:GetPosition()
        self:SetPosition(Clamp((x or 0)+delta*.15,-1,2.5),y or 0,z or 0)
    end)
end
-- The Retail backdrop art is cover-cropped behind the slot columns and model.
local function Backdrop(s,c)
    if not c.backdrop then
        c.backdrop=Own(PaperDollFrame:CreateTexture(nil,"BORDER"))
        c.backdrop:SetTexture(backdrop)
    end
    local t=c.backdrop
    local w,h=382,458
    t:ClearAllPoints(); t:SetPoint("TOPLEFT",s.frame,"TOPLEFT",20,-70); t:SetWidth(w); t:SetHeight(h)
    local art,box=787/1030,w/h
    if box>art then local cut=(1-art/box)/2; t:SetTexCoord(0,1,cut,1-cut)
    else local cut=(1-box/art)/2; t:SetTexCoord(cut,1-cut,0,1) end
    t:SetVertexColor(1,1,1,.9); t:Show()
end
function ns.ApplyCharacter(s)
    local c=s.character
    if not c then c={geometry={},hidden={},frame=s.frame}; s.character=c end
    if ns.GetValue("enhancedCharacterSheet")==false or _G.PaperDollFrame and not PaperDollFrame:IsShown() then
        if c.enhanced then ns.RestoreCharacter(s) end
        LayoutTabs(s,c); return
    end
    if not _G.PaperDollFrame or not _G.CharacterModelFrame then LayoutTabs(s,c); return end
    if not c.host then Build(s,c) end
    c.refresh,c.updateExtras=Refresh,UpdateExtras
    c.enhanced=true
    Save(c,s.frame); s.frame:SetSize(660,580)
    if not c.widthSaved then c.nativePanelWidth=s.frame:GetAttribute("UIPanelLayout-width"); c.widthSaved=true end
    s.frame:SetAttribute("UIPanelLayout-width",660)
    Save(c,s.panel); s.panel:ClearAllPoints(); s.panel:SetPoint("TOPLEFT",s.frame,"TOPLEFT",11,-12); s.panel:SetPoint("BOTTOMRIGHT",s.frame,"BOTTOMRIGHT",-12,40)
    Place(c,_G.CharacterFrameCloseButton,"TOPRIGHT",s.frame,"TOPRIGHT",-18,-19)
    Place(c,CharacterModelFrame,"TOPLEFT",s.frame,"TOPLEFT",72,-80,278,375)
    Place(c,_G.CharacterModelFrameRotateLeftButton,"BOTTOMLEFT",CharacterModelFrame,"BOTTOMLEFT",8,5,20,20)
    Place(c,_G.CharacterModelFrameRotateRightButton,"BOTTOMRIGHT",CharacterModelFrame,"BOTTOMRIGHT",-8,5,20,20)
    ModelControls(c)
    Backdrop(s,c)
    for _,name in ipairs({"CharacterAttributesFrame","CharacterResistanceFrame","PlayerStatFrameLeftDropDown","PlayerStatFrameRightDropDown","PlayerTitleFrame","GearManagerToggleButton","GearManagerDialog"}) do HideNative(c,_G[name]) end
    for _,name in ipairs({"CharacterNameText","CharacterLevelText","CharacterFramePortrait"}) do
        local obj=_G[name]; if obj then Save(c,obj); obj:SetAlpha(0) end
    end
    local function Slot(slot,x,y,side)
        local button=_G["Character"..slot.."Slot"]; if not button then return end
        Place(c,button,"TOPLEFT",s.frame,"TOPLEFT",x,y,40,40)
        local icon=_G["Character"..slot.."SlotIconTexture"]
        if icon then Save(c,icon); icon:ClearAllPoints(); icon:SetPoint("TOPLEFT",button,"TOPLEFT",1,-1); icon:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-1,1) end
        if not c.itemLabels[slot] then c.itemLabels[slot]=Text(c.host,11) end
        c.slotButtons[slot],c.slotSides[slot]=button,side
        AnchorItemLabel(c,slot,c.flags[slot] and c.flags[slot][1]:IsShown())
    end
    for i,slot in ipairs(left) do Slot(slot,25,-80-(i-1)*48,"left") end
    for i,slot in ipairs(right) do Slot(slot,355,-80-(i-1)*48,"right") end
    for i,slot in ipairs(weapons) do Slot(slot,137+(i-1)*47,-474,"bottom") end
    Place(c,_G.CharacterAmmoSlot,"TOPLEFT",s.frame,"TOPLEFT",290,-481,27,27)
    local ammo=_G.CharacterAmmoSlotIconTexture
    if ammo and _G.CharacterAmmoSlot then
        Save(c,ammo); ammo:ClearAllPoints()
        ammo:SetPoint("TOPLEFT",CharacterAmmoSlot,"TOPLEFT",1,-1)
        ammo:SetPoint("BOTTOMRIGHT",CharacterAmmoSlot,"BOTTOMRIGHT",-1,1)
    end
    c.host:Show(); c.header:Show(); LayoutTabs(s,c); Refresh(c)
end
