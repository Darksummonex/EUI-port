-- Item link, enchant, gem, durability and item level helpers shared by the
-- character/inspect sheets, the socket strip, the merchant and tooltips.
local _,ns=...
if not ns.IsWrath then return end
local Items={}; ns.Items=Items
function ns.ApplyFont(fs,size,outline)
    local E=EllesmereUI
    local flags=outline or (E.GetFontOutlineFlag and E.GetFontOutlineFlag("blizzardSkin")) or ""
    flags=flags:gsub(",?%s*SLUG","")
    if not fs:SetFont(E.GetFontPath("blizzardSkin"),size,flags) then fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",size,"") end
end
function ns.ClassColor(unit)
    local _,class=UnitClass(unit)
    local colors=CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    local c=class and colors and colors[class]
    if c then return c.r,c.g,c.b end
end
-- Wrath's 17 combat slots: shirt and tabard excluded, ranged included.
Items.averageSlots={1,2,3,5,6,7,8,9,10,11,12,13,14,15,16,17,18}
function Items.Fields(link)
    local fields={}
    local body=link and link:match("item:([%-%d:]+)")
    if body then for v in (body..":"):gmatch("([^:]*):") do fields[#fields+1]=tonumber(v) or 0 end end
    for i=1,8 do fields[i]=fields[i] or 0 end
    return fields
end
local scanner
local function Scanner()
    if scanner==nil then
        local ok,tip=pcall(CreateFrame,"GameTooltip","EUI335ItemScanTooltip",nil,"GameTooltipTemplate")
        scanner=ok and tip or false
    end
    return scanner
end
-- Left tooltip lines with their colours, or nil when the client cannot fill it yet.
function Items.Lines(method,...)
    local tip=Scanner()
    if not (tip and tip[method] and tip.NumLines) then return nil end
    tip:SetOwner(WorldFrame,"ANCHOR_NONE"); tip:ClearLines()
    if not pcall(tip[method],tip,...) then tip:Hide(); return nil end
    local lines={}
    for i=1,tip:NumLines() do
        local fs=_G["EUI335ItemScanTooltipTextLeft"..i]; local text=fs and fs:GetText()
        if text and text~="" then local r,g,b=fs:GetTextColor(); lines[#lines+1]={text=text,r=r or 1,g=g or 1,b=b or 1} end
    end
    tip:Hide()
    return lines
end
local enchantNames={}
-- Wrath prints a permanent enchant as a bare green line. It is the one green
-- line the same item lacks once the enchant field of its link is zeroed.
function Items.EnchantText(link)
    local id=Items.Fields(link)[2]
    if id==0 then return nil end
    if enchantNames[id] then return enchantNames[id] end
    local itemString=link:match("item:[%-%d:]+"); if not itemString then return nil end
    local bare=itemString:gsub("^(item:%-?%d+):%-?%d+","%1:0",1)
    local with,without=Items.Lines("SetHyperlink",itemString),Items.Lines("SetHyperlink",bare)
    if not with or not without or #with<2 then return nil end
    local remaining={}
    for _,line in ipairs(without) do remaining[line.text]=(remaining[line.text] or 0)+1 end
    for _,line in ipairs(with) do
        if (remaining[line.text] or 0)>0 then remaining[line.text]=remaining[line.text]-1
        elseif line.g>.8 and line.r<.5 and line.b<.5 then enchantNames[id]=line.text; return line.text end
    end
end
function Items.ShortEnchant(text)
    if not text then return nil end
    return (text:gsub("^Enchanted:%s*",""):gsub("^Enchant%s+[%w%s]-%s+%-%s*",""))
end
-- Socketed gems in socket order. The link's gem fields are enchant IDs on
-- Wrath, so the gem items come from GetItemGem.
function Items.Gems(link)
    local list={}
    if not link or not GetItemGem then return list end
    for i=1,4 do
        local name,gemLink=GetItemGem(link,i)
        if gemLink then
            local _,_,quality,_,_,_,_,_,_,icon=GetItemInfo(gemLink)
            list[#list+1]={link=gemLink,name=name,quality=quality,icon=icon or (GetItemIcon and GetItemIcon(gemLink))}
        end
    end
    return list
end
local socketKinds
-- Empty sockets by colour from the tooltip text the client prints for them.
function Items.EmptySockets(method,...)
    if not socketKinds then
        socketKinds={}
        for key,kind in pairs({EMPTY_SOCKET_RED="Red",EMPTY_SOCKET_YELLOW="Yellow",EMPTY_SOCKET_BLUE="Blue",EMPTY_SOCKET_META="Meta",
            EMPTY_SOCKET_NO_COLOR="Prismatic",EMPTY_SOCKET_PRISMATIC="Prismatic"}) do
            if type(_G[key])=="string" then socketKinds[_G[key]]=kind end
        end
    end
    local list={}
    local lines=Items.Lines(method,...)
    for i=2,#(lines or {}) do local kind=socketKinds[lines[i].text]; if kind then list[#list+1]=kind end end
    return list
end
function Items.SocketArt(kind) return "Interface\\ItemSocketingFrame\\UI-EmptySocket-"..(kind or "Prismatic") end
function Items.Average(unit)
    local total,pending,main,twoHand=0,false,0,false
    for _,slot in ipairs(Items.averageSlots) do
        local link=GetInventoryItemLink(unit,slot)
        if link then
            local _,_,_,level,_,_,_,_,equip=GetItemInfo(link)
            if level then
                total=total+level
                if slot==16 then main,twoHand=level,equip=="INVTYPE_2HWEAPON" end
            else pending=true end
        end
    end
    if twoHand and not GetInventoryItemLink(unit,17) then total=total+main end
    return total/17,pending
end
function Items.LowestDurability()
    local lowest
    for slot=1,18 do
        local current,maximum=GetInventoryItemDurability(slot)
        if current and maximum and maximum>0 then
            local pct=current/maximum*100
            if not lowest or pct<lowest then lowest=pct end
        end
    end
    return lowest
end
function Items.DurabilityColor(pct)
    pct=math.max(0,math.min(100,pct or 100))
    if pct>=50 then return (100-pct)/50,1,0 end
    return 1,pct/50,0
end
-- The client prints a requirement this character fails in red.
function Items.Usable(method,...)
    local lines=Items.Lines(method,...)
    if not lines or #lines==0 then return false end
    for i=2,#lines do local l=lines[i]; if l.r>.95 and l.g<.2 and l.b<.2 then return false end end
    return true
end
function Items.QualityColor(quality)
    if quality and GetItemQualityColor then local r,g,b=GetItemQualityColor(quality); if r then return r,g,b end end
    return .9,.9,.9
end
