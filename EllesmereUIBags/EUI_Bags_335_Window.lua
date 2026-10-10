-- Retail EllesmereUI Bags window on Wrath: header, category sidebar, sections,
-- item skin, footer, pin/assign select mode, physical sort and stack splitter.
local _,ns=...
local E=EllesmereUI
if not ns.addon then return end
local CM=ns.CM
local Size,Shown,Text,Solid,Font=ns.Size,ns.Shown,ns.Text,ns.Solid,ns.Font
local MEDIA=ns.MEDIA
local SLOT,SPACING,HEADER_H,FOOTER_H=ns.SLOT,ns.SPACING,ns.HEADER_H,ns.FOOTER_H
local STEP=SLOT+SPACING
local SB_W,SB_CW,SB_BTN_H,SB_ICON,SB_PAD,SB_INDENT,SB_HDR=160,32,26,18,2,16,24
local FIXED_H,START_X=650,10
local floor,ceil,max,min,format=math.floor,math.ceil,math.max,math.min,string.format
local function P() return ns.GetSettings() end
local function DB() EllesmereUIDB=EllesmereUIDB or {}; return EllesmereUIDB end
ns.unmerged={}

local function PinSet() local db=DB(); db.bagPinnedItems=db.bagPinnedItems or {}; return db.bagPinnedItems end
function ns.IsPinned(id) return id and PinSet()[id] and true or false end
function ns.TogglePin(id) if not id then return end; local s=PinSet(); s[id]=(not s[id]) or nil; ns.RefreshAll() end
local function IsGear(item) local c=CM:ClassOf(item.itemType,item.itemSubType); return c==CM.IC_WEAPON or c==CM.IC_ARMOR end
ns.IsGear=IsGear
local function QualityColor(q) local c=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]; if c then return c.r,c.g,c.b end end

-- BoE / unusable come from tooltip text on Wrath (no C_Item bind or usability API).
local scanTip,scanCache,scanSize=nil,{},0
function ns.ClearScanCache() scanCache,scanSize={},0 end
local function Scan(item)
    local key=item.bag..":"..item.slot..":"..item.link
    local hit=scanCache[key]; if hit then return hit[1] or nil,hit[2] end
    scanTip=scanTip or CreateFrame("GameTooltip","EUI335BagScanTip",nil,"GameTooltipTemplate")
    if not scanTip.NumLines then return end
    scanTip:SetOwner(UIParent,"ANCHOR_NONE"); scanTip:ClearLines()
    if item.bag==-1 then scanTip:SetInventoryItem("player",BankButtonIDToInvSlotID(item.slot)) else scanTip:SetBagItem(item.bag,item.slot) end
    local bind,unusable=false,false
    for i=2,scanTip:NumLines() do
        for _,side in ipairs({"Left","Right"}) do
            local fs=_G["EUI335BagScanTipText"..side..i]; local text=fs and fs:GetText()
            if text then
                if text==ITEM_BIND_ON_EQUIP then bind="BoE" elseif text==ITEM_BIND_ON_USE then bind="BoU" end
                local r,g,b=fs:GetTextColor(); if r and r>.99 and g<.15 and b<.15 then unusable=true end
            end
        end
    end
    scanTip:Hide()
    if scanSize>3000 then ns.ClearScanCache() end
    scanCache[key]={bind,unusable}; scanSize=scanSize+1
    return bind or nil,unusable
end

function ns.IconButton(parent,texture,size,title,hint,fn,alpha)
    local b=CreateFrame("Button",nil,parent); Size(b,size,size)
    b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetAllPoints(b); b.icon:SetTexture(texture)
    if texture:find("\\Icons\\",1,true) then b.icon:SetTexCoord(.08,.92,.08,.92) end
    b.baseAlpha,b.title,b.hint=alpha or .9,title,hint; b:SetAlpha(b.baseAlpha)
    b:SetScript("OnEnter",function(self)
        self:SetAlpha(1)
        if self.title then
            GameTooltip:SetOwner(self,"ANCHOR_BOTTOM"); GameTooltip:SetText(self.title,1,1,1)
            if self.hint then GameTooltip:AddLine(self.hint,.7,.7,.7,true) end; GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave",function(self) self:SetAlpha(self.locked and .3 or self.baseAlpha); GameTooltip:Hide() end)
    b:SetScript("OnClick",fn); return b
end

local function Commas(n) local s,r=tostring(n); repeat s,r=s:gsub("^(%d+)(%d%d%d)","%1,%2") until r==0; return s end
function ns.MoneyString(copper)
    copper=max(0,floor(tonumber(copper) or 0))
    local g,s,c=floor(copper/10000),floor(copper/100)%100,copper%100
    return Commas(g).."|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t "..format("%02d",s).."|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t "
        ..format("%02d",c).."|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t"
end

---------------------------------------------------------------------------
-- Popups: rename input, confirm with "Don't show me again", context menu
---------------------------------------------------------------------------
local function Trim(text) text=tostring(text or ""):gsub("^%s+",""); text=text:gsub("%s+$",""); return text end
function ns.Prompt(title,current,fn)
    local function Done(text) text=Trim(text); if text~="" then fn(text) end end
    if E.ShowInputPopup then E:ShowInputPopup({title=title,message="Enter a new name:",placeholder=current,confirmText="Save",cancelText="Cancel",onConfirm=Done}); return end
    if not StaticPopupDialogs or not StaticPopup_Show then return end
    StaticPopupDialogs.EUI335_BAGS_INPUT={text="%s",button1=ACCEPT or "Accept",button2=CANCEL or "Cancel",hasEditBox=1,timeout=0,whileDead=1,hideOnEscape=1,
        OnShow=function(self) local box=_G[self:GetName().."EditBox"]; if box then box:SetText(ns.promptCurrent or ""); box:SetFocus() end end,
        OnHide=function(self) local box=_G[self:GetName().."EditBox"]; if box then box:ClearFocus() end end,
        OnAccept=function(self) local box=_G[self:GetName().."EditBox"]; if box and ns.promptFn then ns.promptFn(box:GetText()) end end,
        EditBoxOnEnterPressed=function(self) local parent=self:GetParent(); if ns.promptFn then ns.promptFn(self:GetText()) end; parent:Hide() end,
        EditBoxOnEscapePressed=function(self) self:GetParent():Hide() end}
    ns.promptCurrent,ns.promptFn=current,Done; StaticPopup_Show("EUI335_BAGS_INPUT",title)
end
local function Panel(name,w,h,strata)
    local d=CreateFrame("Frame",name,UIParent); Size(d,w,h); d:SetFrameStrata(strata or "FULLSCREEN_DIALOG"); d:EnableMouse(true); d:Hide()
    d.bg=Solid(d,"BACKGROUND",.06,.06,.06,.95); d.bg:SetAllPoints(d); d.edges=ns.Border(d,.25,.25,.25,1)
    if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]=name end
    return d
end
local function CheckBox(parent,label)
    local c=CreateFrame("Button",nil,parent); Size(c,14,14)
    c.bg=Solid(c,"BACKGROUND",0,0,0,.5); c.bg:SetAllPoints(c); c.edges=ns.Border(c,.4,.4,.4,1)
    c.mark=c:CreateTexture(nil,"OVERLAY"); c.mark:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); c.mark:SetPoint("TOPLEFT",c,"TOPLEFT",-3,3); c.mark:SetPoint("BOTTOMRIGHT",c,"BOTTOMRIGHT",3,-3)
    c.label=Text(c,10); c.label:SetPoint("LEFT",c,"RIGHT",6,0); c.label:SetText(label); c.label:SetTextColor(.7,.7,.7)
    function c:SetOn(on) self.on=on and true or false; Shown(self.mark,self.on) end
    c:SetScript("OnClick",function(self) self:SetOn(not self.on) end); c:SetOn(false)
    return c
end
function ns.Confirm(text,dismissKey,fn)
    if dismissKey and DB()[dismissKey] then fn(); return end
    local d=ns.confirmDialog
    if not d then
        d=Panel("EUI335BagsConfirm",340,140); ns.confirmDialog=d; d:SetPoint("CENTER",UIParent,"CENTER",0,120)
        d.text=Text(d,12); d.text:SetPoint("TOP",d,"TOP",0,-18); d.text:SetWidth(300); d.text:SetTextColor(.9,.9,.9)
        d.check=CheckBox(d,"Don't show me again"); d.check:SetPoint("BOTTOMLEFT",d,"BOTTOMLEFT",20,48)
        d.ok=ns.FlatButton(d,"Continue",110,function() if d.key and d.check.on then DB()[d.key]=true end; local go=d.fn; d:Hide(); if go then go() end end)
        d.ok:SetPoint("BOTTOMRIGHT",d,"BOTTOM",-6,14)
        d.cancel=ns.FlatButton(d,"Cancel",110,function() d:Hide() end); d.cancel:SetPoint("BOTTOMLEFT",d,"BOTTOM",6,14)
    end
    d.text:SetText(text); d.fn,d.key=fn,dismissKey; d.check:SetOn(false); Shown(d.check,dismissKey~=nil); d:Show()
end
function ns.ShowMenu(list)
    if not EasyMenu then return end
    ns.menuFrame=ns.menuFrame or CreateFrame("Frame","EUI335BagsMenu",UIParent,"UIDropDownMenuTemplate")
    EasyMenu(list,ns.menuFrame,"cursor",0,0,"MENU")
end

---------------------------------------------------------------------------
-- Item buttons
---------------------------------------------------------------------------
local POOLS={main={"pool","savedPool",""},pin={"pinPool","savedPinPool","Pin"},recent={"recentPool","savedRecentPool","Recent"}}
local function ExtraTooltip(b)
    local item=b._item; if not item or not item.link then return end
    ns.AddOwnershipTooltip(item.link)
    if item._mergedN then GameTooltip:AddLine(format("%d stacks merged (%d total)",item._mergedN,item.mergedCount or 0),.6,.6,.6) end
    GameTooltip:Show()
end
local tooltipHooked
local function HookNativeTooltips()
    if tooltipHooked or not hooksecurefunc then return end; tooltipHooked=true
    for _,fn in ipairs({"ContainerFrameItemButton_OnEnter","BankFrameItemButton_OnEnter"}) do
        if type(_G[fn])=="function" then
            hooksecurefunc(fn,function(btn) if btn and btn._eui335 and GameTooltip.IsOwned and GameTooltip:IsOwned(btn) then ExtraTooltip(btn) end end)
        end
    end
end
local function ItemButton(f,item,which)
    local live=ns.IsLiveView(f); local spec=POOLS[which]
    local pool=f[live and spec[1] or spec[2]]; local bag,slot=item.bag,item.slot; local key=bag..":"..slot
    local b=pool[key]; if b then return b end
    if live and InCombatLockdown() then return end
    local pk=(live and "L" or "S")..which; local parents=f.bagParents[pk] or {}; f.bagParents[pk]=parents
    local parent=parents[bag]
    if not parent then parent=CreateFrame("Frame",nil,f.content); parent:SetID(bag); parent:SetAllPoints(f.content); parents[bag]=parent end
    local name="EUI335Item_"..(live and "" or "Saved")..spec[3]..(f.kind=="bank" and "Bank" or "Bags").."_"..(bag<0 and "N"..(-bag) or bag).."_"..slot
    -- Native templates keep pickup, use, split, trade, sell and bank purchase actions.
    b=CreateFrame(live and "CheckButton" or "Button",name,parent,live and (bag==-1 and "BankItemButtonGenericTemplate" or "ContainerFrameItemButtonTemplate") or nil)
    b:SetID(slot); b.bagID,b.slotID,b._eui335,b._live=bag,slot,true,live
    b.iconBg=b:CreateTexture(nil,"BACKGROUND"); b.iconBg:SetAllPoints(b); b.iconBg:SetTexture(MEDIA.."icon-bg")
    b.icon=_G[name.."IconTexture"] or b:CreateTexture(nil,"ARTWORK")
    b.icon:ClearAllPoints(); b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1)
    local nativeCount=_G[name.."Count"]; if nativeCount then nativeCount:Hide() end
    b.cooldown=_G[name.."Cooldown"] or CreateFrame("Cooldown",name.."Cooldown",b,"CooldownFrameTemplate")
    b.cooldown:ClearAllPoints(); b.cooldown:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.cooldown:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1)
    b.edges=ns.Border(b,.25,.25,.25,1,"OVERLAY")
    local t=CreateFrame("Frame",nil,b); t:SetAllPoints(b); t:SetFrameLevel(b:GetFrameLevel()+5); b.textFrame=t
    b.stackCount=Text(t,11); b.stackCount:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-2,2); b.stackCount:SetDrawLayer("OVERLAY"); b.stackCount:SetJustifyH("RIGHT"); b.stackCount:Hide()
    b.level=Text(t,12); b.level:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1)
    b.bind=Text(t,11); b.bind:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",1,2)
    b.setName=Text(t,9); b.setName:SetPoint("BOTTOM",b,"BOTTOM",0,2); b.setName:SetWidth(SLOT)
    b.quest=t:CreateTexture(nil,"OVERLAY"); Size(b.quest,22,22); b.quest:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",-3,2)
    b.quest:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon"); b.quest:Hide()
    b.junkCoin=t:CreateTexture(nil,"OVERLAY"); Size(b.junkCoin,14,14); b.junkCoin:SetPoint("TOPRIGHT",b,"TOPRIGHT",-1,-1)
    b.junkCoin:SetTexture("Interface\\Icons\\INV_Misc_Coin_01"); b.junkCoin:SetTexCoord(.08,.92,.08,.92); b.junkCoin:Hide()
    b:SetNormalTexture("")
    b:SetPushedTexture(MEDIA.."highlight-3")
    local pushed=b.GetPushedTexture and b:GetPushedTexture()
    if pushed then pushed:ClearAllPoints(); pushed:SetAllPoints(b); pushed:SetVertexColor(.973,.839,.604) end
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    local hl=b:GetHighlightTexture(); if hl then hl:SetAllPoints(b); hl:SetBlendMode("ADD") end
    if live then
        b:SetCheckedTexture("")
        HookNativeTooltips()
        if not b:GetScript("OnEnter") then
            b:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetBagItem(bag,slot); ExtraTooltip(self); GameTooltip:Show() end)
            b:SetScript("OnLeave",function() GameTooltip:Hide() end)
        end
        b:HookScript("OnMouseUp",function(self,button)
            if button=="MiddleButton" and f.kind=="bags" and self._item and self._item.itemID then ns.TogglePin(self._item.itemID) end
        end)
    else
        b:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            if self.link then GameTooltip:SetHyperlink(self.link) else GameTooltip:SetText("Empty slot") end
            GameTooltip:AddLine("Saved view - read only",1,.8,.2); ns.AddOwnershipTooltip(self.link); GameTooltip:Show()
        end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    end
    pool[key]=b; return b
end
local function Paint(b,item,p,live,interactive)
    b._item=item; b.link=item.link; b.hasItem=item.link~=nil; b.readable=item.readable; b.lootable=item.lootable; b.locked=item.locked
    -- Native item and refund handlers expect a numeric count.
    b.count=item.count or 0
    if item.link then
        local z=p.bagItemIconZoom or .08
        b.icon:SetTexture(item.icon); b.icon:SetTexCoord(z,1-z,z,1-z); b.icon:Show(); b.iconBg:Hide()
        local junk=CM:IsJunk(item.itemID,item.quality)
        b.icon:SetDesaturated((item.locked or (p.bagDesaturateJunkItems and (item.quality==0 or junk))) and true or false)
        Shown(b.junkCoin,junk and p.bagShowJunkCoin)
        local bind,unusable; if live then bind,unusable=Scan(item) end
        if unusable then b.icon:SetVertexColor(1,.1,.1) else b.icon:SetVertexColor(1,1,1) end
        local r,g,bl=QualityColor(item.quality)
        if item.isQuest then ns.BorderColor(b.edges,1,.82,0,1); ns.BorderSize(b.edges,2)
        elseif r and (item.quality or 0)>=2 then ns.BorderColor(b.edges,r,g,bl,1); ns.BorderSize(b.edges,1)
        else ns.BorderColor(b.edges,.25,.25,.25,1); ns.BorderSize(b.edges,1) end
        local shown=item.mergedCount or item.count or 1
        Font(b.stackCount,p.bagCountFontSize)
        if shown>1 then b.stackCount:SetText(tostring(shown)); b.stackCount:Show() else b.stackCount:SetText(""); b.stackCount:Hide() end
        Font(b.level,p.itemlevelFontSize)
        if p.showItemlevelInBags and item._gear and (item.level or 0)>1 then b.level:SetText(tostring(item.level)); b.level:SetTextColor(r or 1,g or 1,bl or 1); b.level:Show()
        else b.level:SetText(""); b.level:Hide() end
        Font(b.bind,p.bagBindTypeFontSize)
        if p.bagDisplayBindType and bind then b.bind:SetText(bind); b.bind:SetTextColor(r or 1,g or 1,bl or 1); b.bind:Show() else b.bind:SetText(""); b.bind:Hide() end
        Font(b.setName,p.bagSetNameFontSize)
        if item._setName then b.setName:SetText(item._setName); b.setName:Show() else b.setName:SetText(""); b.setName:Hide() end
        Shown(b.quest,item.questStarter)
    else
        b.icon:SetTexture(nil); b.icon:SetDesaturated(false); b.icon:Hide(); b.iconBg:Show(); b.iconBg:SetAlpha(interactive and .6 or .35)
        ns.BorderColor(b.edges,.15,.15,.15,.5); ns.BorderSize(b.edges,1)
        b.stackCount:SetText(""); b.stackCount:Hide(); b.level:SetText(""); b.level:Hide()
        b.bind:SetText(""); b.bind:Hide(); b.setName:SetText(""); b.setName:Hide(); b.quest:Hide(); b.junkCoin:Hide()
    end
    local s,d,e=0,0,0
    if live and item.link then s,d,e=GetContainerItemCooldown(item.bag,item.slot) end
    if CooldownFrame_SetTimer then CooldownFrame_SetTimer(b.cooldown,s or 0,d or 0,e or 0) end
end
function ns.ApplySearch(f)
    local q=string.lower(f.search:GetText() or "")
    for _,b in ipairs(f.shownButtons or {}) do
        local item=b._item; local match=q==""
        if not match and item and item.link then
            match=(item.name or ""):lower():find(q,1,true) or (item.itemType or ""):lower():find(q,1,true) or (item.itemSubType or ""):lower():find(q,1,true)
        end
        b:SetAlpha(match and 1 or .2)
    end
end

---------------------------------------------------------------------------
-- Visual order (saved per section as itemID lists) and sort compare
---------------------------------------------------------------------------
local function VisualSortCompare(a,b)
    if (a._gear or false)~=(b._gear or false) then return a._gear and true or false end
    if a._gear and (a.level or 0)~=(b.level or 0) then return (a.level or 0)>(b.level or 0) end
    if (a.categoryIndex or 999)~=(b.categoryIndex or 999) then return (a.categoryIndex or 999)<(b.categoryIndex or 999) end
    if (a.itemType or "")~=(b.itemType or "") then return (a.itemType or "")<(b.itemType or "") end
    if (a.quality or 0)~=(b.quality or 0) then return (a.quality or 0)>(b.quality or 0) end
    if (a.name or "")~=(b.name or "") then return (a.name or "")<(b.name or "") end
    if (a.itemID or 0)~=(b.itemID or 0) then return (a.itemID or 0)<(b.itemID or 0) end
    if a.bag~=b.bag then return a.bag<b.bag end
    return a.slot<b.slot
end
ns.VisualSortCompare=VisualSortCompare
local function OrderStore() local db=DB(); db.bagVisualOrder=db.bagVisualOrder or {}; return db.bagVisualOrder end
local function ApplyOrder(f,key,list)
    f._orderKeys[#f._orderKeys+1]=key
    local saved=OrderStore()[key]
    if saved then
        local positions={}
        for i,id in ipairs(saved) do local t=positions[id]; if not t then t={}; positions[id]=t end; t[#t+1]=i end
        table.sort(list,function(a,b) if a.bag~=b.bag then return a.bag<b.bag end; return a.slot<b.slot end)
        local placed,extra={}, {}
        for _,item in ipairs(list) do
            local t=positions[item.itemID or 0]
            if t and #t>0 then item._ord=table.remove(t,1); placed[#placed+1]=item else extra[#extra+1]=item end
        end
        table.sort(placed,function(a,b) return a._ord<b._ord end); table.sort(extra,VisualSortCompare)
        for i=#list,1,-1 do list[i]=nil end
        for _,item in ipairs(placed) do list[#list+1]=item end
        for _,item in ipairs(extra) do list[#list+1]=item end
    else table.sort(list,VisualSortCompare) end
    local ids={}; for i,item in ipairs(list) do ids[i]=item.itemID or 0 end
    if #ids>0 then OrderStore()[key]=ids end
    return list
end
function ns.ResetVisualOrder(f)
    local store=OrderStore(); for _,key in ipairs(f._orderKeys or {}) do store[key]=nil end
    ns.Refresh(f.kind)
end

---------------------------------------------------------------------------
-- Sections
---------------------------------------------------------------------------
local SLOT_BUCKETS={INVTYPE_HEAD={10,"Head"},INVTYPE_NECK={20,"Neck"},INVTYPE_SHOULDER={30,"Shoulder"},INVTYPE_CLOAK={40,"Back"},
    INVTYPE_CHEST={50,"Chest"},INVTYPE_ROBE={50,"Chest"},INVTYPE_BODY={52,"Shirt"},INVTYPE_TABARD={54,"Tabard"},INVTYPE_WRIST={60,"Wrist"},
    INVTYPE_HAND={70,"Hands"},INVTYPE_WAIST={80,"Waist"},INVTYPE_LEGS={90,"Legs"},INVTYPE_FEET={100,"Feet"},INVTYPE_FINGER={140,"Finger"},
    INVTYPE_TRINKET={150,"Trinket"},INVTYPE_2HWEAPON={160,"Two-Hand"},INVTYPE_WEAPON={170,"One-Hand"},INVTYPE_WEAPONMAINHAND={170,"One-Hand"},
    INVTYPE_WEAPONOFFHAND={180,"Off Hand"},INVTYPE_SHIELD={180,"Off Hand"},INVTYPE_HOLDABLE={180,"Off Hand"},INVTYPE_RANGED={190,"Ranged"},
    INVTYPE_RANGEDRIGHT={190,"Ranged"},INVTYPE_THROWN={190,"Ranged"},INVTYPE_RELIC={190,"Ranged"}}
local OTHER_BUCKET={999,"Other"}
local GEAR_CATS={["Weapons / Trinkets"]=true,["Armor"]=true,["Item Set Gear"]=true}
local function GearOnly(cats,indices)
    if #indices==0 then return false end
    for _,i in ipairs(indices) do local c=cats[i]; if not c or not (GEAR_CATS[c._defaultName] or c.isEquipSet) then return false end end
    return true
end
local function Buckets(list)
    local map,order={}, {}
    for _,item in ipairs(list) do
        local d=SLOT_BUCKETS[item.equip or ""] or OTHER_BUCKET; local b=map[d[2]]
        if not b then b={rank=d[1],label=d[2],items={}}; map[d[2]]=b; order[#order+1]=b end
        b.items[#b.items+1]=item
    end
    table.sort(order,function(a,b) return a.rank<b.rank end)
    return order
end
local function UsedTotal(list) local used=0; for _,item in ipairs(list) do if item.link then used=used+1 end end; return used,#list end
local function BagName(bag,snapshot)
    if bag==0 then return "Backpack" elseif bag==-1 then return "Bank" elseif bag==-2 then return "Keyring" end
    local c=snapshot and snapshot.containers[bag]; local name=c and c.link and GetItemInfo(c.link)
    return name or ("Bag "..(bag>4 and bag-4 or bag))
end
local function ByCategory(items)
    local byCat={}
    for _,item in ipairs(items) do
        if not item._mergedInto and item.categoryIndex then local t=byCat[item.categoryIndex]; if not t then t={}; byCat[item.categoryIndex]=t end; t[#t+1]=item end
    end
    return byCat
end
local function WithSetChildren(cats,byCat,ci,list,p)
    if p.bagSplitSetGearBySet and cats[ci] and cats[ci].isSetGear and not cats[ci].isEquipSet then
        for i,c in ipairs(cats) do if c.isEquipSet and byCat[i] then for _,item in ipairs(byCat[i]) do list[#list+1]=item end end end
    end
    return list
end
local function Copy(list) local out={}; for i,v in ipairs(list or {}) do out[i]=v end; return out end
local function PinnedSection(f,items,p)
    local pins=PinSet(); local list={}
    for _,item in ipairs(items) do if not item._mergedInto and item.itemID and pins[item.itemID] then list[#list+1]=item end end
    ApplyOrder(f,"P:Pinned",list)
    return {title=CM:GetCategories()[CM:IndexOf("Pinned Items") or 1].name,items=list,which="pin",pinAdd=true,hideKey="bagShowPinnedItems",
        hint=p.bagShowPinRecentTips and "(Middle Click to Add or Remove)" or nil}
end
local function RecentSection(f,items,p)
    local list={}
    for _,item in ipairs(items) do if not item._mergedInto and item.itemID and ns.recent[item.itemID] then list[#list+1]=item end end
    table.sort(list,function(a,b) local ta,tb=ns.recent[a.itemID],ns.recent[b.itemID]; if ta~=tb then return ta>tb end; return VisualSortCompare(a,b) end)
    return {title=CM:GetCategories()[CM:IndexOf("Recent Items") or 2].name,items=list,which="recent",alwaysShow=true,hideKey="bagShowRecentItems",
        clear=p.bagShowRecentClear and next(ns.recent)~=nil,hint=p.bagShowPinRecentTips and "(Extra quickview display, your items are also in their category)" or nil}
end
local function CategorySections(f,items,cats,p,pinRecent,live)
    local secs,byCat,done={},ByCategory(items),{}
    local hidden=p.bagHiddenInAllItems or {}
    for ci,cat in ipairs(cats) do
        if cat.isPinned then if pinRecent and p.bagShowPinnedItems then secs[#secs+1]=PinnedSection(f,items,p) end
        elseif cat.isRecent then if pinRecent and live and p.bagShowRecentItems then secs[#secs+1]=RecentSection(f,items,p) end
        elseif cat.isEquipSet then
        elseif cat.groupName then
            if not done[cat.groupName] then
                done[cat.groupName]=true
                if not hidden[cat.groupName] then
                    local members=CM:GetGroupMembers(cat.groupName); local list={}
                    for _,mi in ipairs(members) do for _,item in ipairs(byCat[mi] or {}) do list[#list+1]=item end; WithSetChildren(cats,byCat,mi,list,p) end
                    if #list>0 then ApplyOrder(f,"G:"..cat.groupName,list) end
                    secs[#secs+1]={title=cat.groupName,items=list,assign=members[1],gearOnly=GearOnly(cats,members)}
                end
            end
        elseif not hidden[cat._defaultName] then
            local list=WithSetChildren(cats,byCat,ci,Copy(byCat[ci]),p)
            if #list>0 then ApplyOrder(f,"C:"..cat._defaultName,list) end
            secs[#secs+1]={title=cat.name,items=list,assign=ci,userCat=cat.isUserCreated,gearOnly=GearOnly(cats,{ci})}
        end
    end
    return secs
end
local function FilteredSections(f,items,cats,p,live)
    local byCat=ByCategory(items)
    if f.view=="cat" then
        local ci,cat=CM:IndexOf(f.viewKey)
        if cat.isPinned then return {PinnedSection(f,items,p)} end
        if cat.isRecent then local s=RecentSection(f,items,p); return {s} end
        local list=WithSetChildren(cats,byCat,ci,Copy(byCat[ci]),p)
        if #list>0 then ApplyOrder(f,"C:"..cat._defaultName,list) end
        return {{title=cat.name,items=list,assign=ci,userCat=cat.isUserCreated,editIndex=cat.isUserCreated and ci or nil,alwaysShow=true,gearOnly=GearOnly(cats,{ci})}}
    end
    local secs={}
    for _,mi in ipairs(CM:GetGroupMembers(f.viewKey)) do
        local cat=cats[mi]; local list=WithSetChildren(cats,byCat,mi,Copy(byCat[mi]),p)
        if #list>0 or cat.isUserCreated or not p.bagHideEmptyCategories then
            if #list>0 then ApplyOrder(f,"C:"..cat._defaultName,list) end
            secs[#secs+1]={title=cat.name,items=list,assign=mi,userCat=cat.isUserCreated,alwaysShow=true,gearOnly=GearOnly(cats,{mi})}
        end
    end
    return secs
end
local function PhysicalSections(rows,snapshot,only)
    local order,byBag={}, {}
    for _,item in ipairs(rows) do
        if not only or item.bag==only then
            local t=byBag[item.bag]; if not t then t={}; byBag[item.bag]=t; order[#order+1]=item.bag end; t[#t+1]=item
        end
    end
    local secs={}
    for _,bag in ipairs(order) do local used,total=UsedTotal(byBag[bag]); secs[#secs+1]={title=format("%s (%d / %d)",BagName(bag,snapshot),used,total),items=byBag[bag],physical=true,raw=true} end
    return secs
end
local function BuildSections(f,rows,items,cats,p,live,snapshot)
    local view=f.view
    if view=="cat" or view=="group" then return FilteredSections(f,items,cats,p,live) end
    if f.kind=="bags" then
        if view=="onebag" then
            local secs={}
            if not p.bagHideOneBagWarning then secs[#secs+1]={warn="Changes made in OneBag will affect the positions of items in default Blizzard bags"} end
            if p.bagShowPinnedItems and p.bagPinnedInOneBag then secs[#secs+1]=PinnedSection(f,items,p) end
            if live and p.bagShowRecentItems and p.bagRecentInOneBag then secs[#secs+1]=RecentSection(f,items,p) end
            local main,keys={}, {}
            for _,item in ipairs(rows) do if item.bag==-2 then keys[#keys+1]=item else main[#main+1]=item end end
            if #main>0 then local used,total=UsedTotal(main); secs[#secs+1]={title=format("Main Bags (%d / %d)",used,total),items=main,physical=true,raw=true} end
            if #keys>0 then local used,total=UsedTotal(keys); secs[#secs+1]={title=format("Keyring (%d / %d)",used,total),items=keys,physical=true,raw=true} end
            return secs
        elseif view=="multibag" then return PhysicalSections(rows,snapshot) end
        return CategorySections(f,items,cats,p,true,live)
    end
    if view=="bag" then return PhysicalSections(rows,snapshot,f.viewKey) end
    if p.bankGroupByCategory then
        local secs=CategorySections(f,items,cats,p,false,live)
        if not p.bankHideEmptyWhenNested then
            local empty={}; for _,item in ipairs(rows) do if not item.link then empty[#empty+1]=item end end
            if #empty>0 then secs[#secs+1]={title=format("Empty Slots (%d)",#empty),items=empty,physical=true,raw=true} end
        end
        return secs
    end
    return PhysicalSections(rows,snapshot)
end

---------------------------------------------------------------------------
-- Content layout
---------------------------------------------------------------------------
local function NewPad(f)
    local pad=CreateFrame("Frame",nil,f.content); Size(pad,SLOT,SLOT)
    pad.tex=pad:CreateTexture(nil,"BACKGROUND"); pad.tex:SetAllPoints(pad); pad.tex:SetTexture(MEDIA.."icon-bg"); pad.tex:SetAlpha(.35)
    pad.edges=ns.Border(pad,0,0,0,.3); return pad
end
local function NewPlus(f)
    local o=CreateFrame("Button",nil,f.content); Size(o,SLOT,SLOT); o:RegisterForClicks("LeftButtonUp","RightButtonUp")
    o.iconBg=o:CreateTexture(nil,"BACKGROUND"); o.iconBg:SetAllPoints(o); o.iconBg:SetTexture(MEDIA.."icon-bg"); o.iconBg:SetAlpha(.6)
    o.edges=ns.Border(o,.15,.15,.15,.5)
    o.shade=Solid(o,"ARTWORK",0,0,0,.4); o.shade:SetAllPoints(o)
    o.plus=Text(o,18); o.plus:SetPoint("CENTER",o,"CENTER",0,1); o.plus:SetText("+"); o.plus:SetTextColor(1,1,1,.5)
    o:SetScript("OnEnter",function(self)
        self.plus:SetTextColor(1,1,1,1); GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:SetText(self.mode=="pin" and "Pin Items" or "Assign Items",1,1,1)
        GameTooltip:AddLine(self.mode=="pin" and "Drop an item here to pin it, or click to choose items." or "Drop an item here to move it into this category, or click to choose items.",.7,.7,.7,true)
        GameTooltip:Show()
    end)
    o:SetScript("OnLeave",function(self) self.plus:SetTextColor(1,1,1,.5); GameTooltip:Hide() end)
    o:SetScript("OnClick",function(self) ns.PlusClick(f,self) end)
    o:SetScript("OnReceiveDrag",function(self) ns.PlusClick(f,self) end)
    return o
end
local function SmallLink(parent,label,fn)
    local b=CreateFrame("Button",nil,parent); Size(b,30,16)
    b.fs=Text(b,9); b.fs:SetAllPoints(b); b.fs:SetText(label); b.fs:SetTextColor(.5,.5,.5,.7)
    b:SetScript("OnEnter",function(self) self.fs:SetTextColor(1,1,1,.9); if self.tip then GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(self.tip,1,1,1); GameTooltip:Show() end end)
    b:SetScript("OnLeave",function(self) self.fs:SetTextColor(.5,.5,.5,.7); GameTooltip:Hide() end)
    b:SetScript("OnClick",fn); return b
end
local function NewHeader(f)
    local h=CreateFrame("Frame",nil,f.content); h:SetHeight(20)
    h.label=Text(h,11); h.label:SetPoint("LEFT",h,"LEFT",0,0); h.label:SetTextColor(.7,.7,.7)
    h.hint=Text(h,10); h.hint:SetPoint("LEFT",h.label,"RIGHT",4,0); h.hint:SetTextColor(.7,.7,.7,.9)
    h.line=Solid(h,"ARTWORK",.7,.7,.7,.2); h.line:SetHeight(1)
    h.hide=SmallLink(h,"Hide",function(self) P()[self.key]=false; ns.RefreshAll() end)
    h.clear=SmallLink(h,"Clear",function() ns.ClearRecent() end); h.clear.tip="Clear Recent Items"
    h.edit=SmallLink(h,"Edit",function(self) ns.ShowCategoryEditor(f,self.index) end)
    h.delete=SmallLink(h,"Delete",function(self) ns.ConfirmDeleteCategory(self.index) end)
    return h
end
local function Columns(f,p,count)
    local base=floor((f.kind=="bank" and p.bankColumns or p.bagColumns) or 12)
    if p.bagAutoSize then base=max(base,ceil(math.sqrt(max(1,count)*2))) end
    return max(4,min(30,base))
end
local function Layout(f,secs,columns,p,live)
    local child=f.content; local gridW=columns*STEP-SPACING; local curY=-8
    local hi,pi,oi,si=0,0,0,0
    local cats=CM:GetCategories()
    f.shownButtons={}
    local function Place(item,which,col,y,interactive)
        local b=ItemButton(f,item,which); if not b then return end
        Paint(b,item,p,live,interactive)
        b:ClearAllPoints(); b:SetPoint("TOPLEFT",child,"TOPLEFT",START_X+col*STEP,y); Size(b,SLOT,SLOT); b:Show()
        f.shownButtons[#f.shownButtons+1]=b
    end
    local function Pad(col,y) pi=pi+1; local pad=f.pads[pi] or NewPad(f); f.pads[pi]=pad; pad:ClearAllPoints(); pad:SetPoint("TOPLEFT",child,"TOPLEFT",START_X+col*STEP,y); pad:Show() end
    local function Plus(col,y,mode,key) oi=oi+1; local o=f.plus[oi] or NewPlus(f); f.plus[oi]=o; o.mode,o.key=mode,key; o:ClearAllPoints(); o:SetPoint("TOPLEFT",child,"TOPLEFT",START_X+col*STEP,y); o:Show() end
    -- Lays list out from column `start` on the current row; returns the next column.
    local function Block(list,which,interactive,startCol,extra,pads)
        local col=startCol or 0
        for _,item in ipairs(list) do
            if col>=columns then col=0; curY=curY-STEP end
            Place(item,which,col,curY,interactive); col=col+1
        end
        if extra then if col>=columns then col=0; curY=curY-STEP end; Plus(col,curY,extra[1],extra[2]); col=col+1 end
        if pads then
            if col==0 then for c=0,columns-1 do Pad(c,curY) end; col=columns
            else for c=col,columns-1 do Pad(c,curY) end end
        end
        return col
    end
    local function SubHeader(label,x)
        si=si+1; local s=f.subHeaders[si] or Text(child,9); f.subHeaders[si]=s
        Font(s,max(8,p.bagCatTitleSize-2)); s:SetTextColor(.55,.55,.55); s:ClearAllPoints(); s:SetPoint("TOPLEFT",child,"TOPLEFT",START_X+x,curY-3); s:SetText(label); s:Show()
    end
    local function Header(sec)
        hi=hi+1; local h=f.headers[hi] or NewHeader(f); f.headers[hi]=h
        h:ClearAllPoints(); h:SetPoint("TOPLEFT",child,"TOPLEFT",START_X,curY); h:SetWidth(gridW)
        Font(h.label,p.bagCatTitleSize); Font(h.hint,max(8,p.bagCatTitleSize-1))
        if sec.hint then h.label:SetText(sec.title); h.hint:SetText(sec.hint)
        elseif sec.raw then h.label:SetText(sec.title); h.hint:SetText("")
        else h.label:SetText(sec.title.." ("..#sec.items..")"); h.hint:SetText("") end
        local anchor=h
        for _,link in ipairs({h.hide,h.clear,h.edit,h.delete}) do link:Hide() end
        local function Link(link) link:ClearAllPoints(); if anchor==h then link:SetPoint("RIGHT",h,"RIGHT",0,0) else link:SetPoint("RIGHT",anchor,"LEFT",-2,0) end; link:Show(); anchor=link end
        if sec.hideKey then h.hide.key=sec.hideKey; h.hide.tip=sec.hideKey=="bagShowPinnedItems" and "Hides Pinned Items. Re-show in settings." or "Hides Recent Items. Re-show in settings."; Link(h.hide) end
        if sec.clear then Link(h.clear) end
        if sec.editIndex and live then h.delete.index=sec.editIndex; h.edit.index=sec.editIndex; Link(h.delete); Link(h.edit) end
        h.line:ClearAllPoints(); h.line:SetPoint("LEFT",h.hint,"RIGHT",6,0)
        if anchor==h then h.line:SetPoint("RIGHT",h,"RIGHT",-SPACING,0) else h.line:SetPoint("RIGHT",anchor,"LEFT",-6,0) end
        h:Show(); curY=curY-22
    end
    for _,sec in ipairs(secs) do
        if sec.warn then
            f.warn=f.warn or Text(child,9); f.warn:SetTextColor(.5,.5,.5); f.warn:ClearAllPoints(); f.warn:SetPoint("TOPLEFT",child,"TOPLEFT",START_X,curY)
            f.warn:SetWidth(gridW); f.warn:SetJustifyH("LEFT"); f.warn:SetText(sec.warn); f.warn:Show(); curY=curY-18
        elseif #sec.items>0 or sec.userCat or sec.pinAdd or sec.alwaysShow or sec.physical then
            Header(sec)
            local extra
            if live and f.kind=="bags" then
                if sec.pinAdd then extra={"pin"}
                elseif sec.assign and CM:CanAssignToCategory(sec.assign) then extra={"assign",cats[sec.assign]._defaultName} end
            end
            local which=sec.which or "main"
            if p.bagArmoryGroupBySlot and sec.gearOnly and #sec.items>0 then
                local buckets=Buckets(sec.items)
                if p.bagCompactArmorySlotGroups then
                    -- Compact: small buckets share rows, each labelled above its first slot.
                    local i=1
                    while i<=#buckets do
                        local line,used={},0
                        repeat
                            local b=buckets[i]; local n=#b.items+((extra and i==1) and 1 or 0)
                            if #line>0 and used+n>columns then break end
                            line[#line+1]={b=b,first=i==1}; used=used+n; i=i+1
                        until i>#buckets or used>=columns
                        local col=0
                        for _,e in ipairs(line) do SubHeader(e.b.label.." ("..#e.b.items..")",col*STEP); col=col+#e.b.items+((extra and e.first) and 1 or 0) end
                        curY=curY-18; col=0
                        for _,e in ipairs(line) do col=Block(e.b.items,which,false,col,(extra and e.first) and extra or nil) end
                        curY=curY-STEP
                    end
                else
                    for k,b in ipairs(buckets) do
                        SubHeader(b.label.." ("..#b.items..")",0); curY=curY-18
                        Block(b.items,which,false,0,k==1 and extra or nil); curY=curY-STEP
                    end
                end
                curY=curY-6
            else
                Block(sec.items,which,sec.physical and live,0,extra,true)
                curY=curY-STEP-6
            end
        end
    end
    return -curY+4
end

---------------------------------------------------------------------------
-- Sidebar
---------------------------------------------------------------------------
local function Collapsed(f) local p=P(); return f.kind=="bank" and p.bankSidebarCollapsed or f.kind=="bags" and p.bagSidebarCollapsed end
local function SidebarWidth(f,p)
    if f.kind=="bank" and not p.bankCategorySidebar then return 0 end
    return Collapsed(f) and SB_CW or SB_W
end
local function IsSelected(f,e)
    if e.kind=="view" then return f.view==e.view end
    if e.kind=="bag" then return f.view=="bag" and f.viewKey==e.bag end
    if e.kind=="group" then return f.view=="group" and f.viewKey==e.group end
    if e.kind=="cat" then return f.view=="cat" and f.viewKey==e.cat._defaultName end
end
local function PaintSidebarButton(f,b)
    local e=b.entry; local sel=IsSelected(f,e); local ar,ag,ab=ns.Accent()
    b.ind:SetTexture(ar,ag,ab,1); Shown(b.ind,sel)
    if sel then b.bg:SetTexture(ar,ag,ab,.1) elseif b.hover then b.bg:SetTexture(1,1,1,.06) else b.bg:SetTexture(1,1,1,0) end
    local icon=e.icon or CM.DEFAULT_ICON; local size=e.indent and 16 or SB_ICON
    b.icon:SetTexture(icon); Size(b.icon,size,size); b.icon:SetAlpha(sel and 1 or .75)
    if icon:find("\\Icons\\",1,true) then b.icon:SetTexCoord(.08,.92,.08,.92) else b.icon:SetTexCoord(0,1,0,1) end
    b.icon:ClearAllPoints()
    if b.collapsed then b.icon:SetPoint("CENTER",b,"CENTER",0,0); b.label:Hide(); b.count:Hide()
    else
        b.icon:SetPoint("LEFT",b,"LEFT",8+(e.indent and SB_INDENT or 0),0)
        b.label:ClearAllPoints(); b.label:SetPoint("LEFT",b.icon,"RIGHT",6,0); b.label:SetPoint("RIGHT",b.count,"LEFT",-4,0)
        b.label:SetText(e.label); b.label:SetAlpha(sel and 1 or .75); b.label:Show()
        b.count:SetText(e.count and e.count>0 and tostring(e.count) or ""); b.count:Show()
    end
end
local function SidebarButton(f)
    local b=CreateFrame("Button",nil,f.Sidebar.content); b:SetHeight(SB_BTN_H)
    b:RegisterForClicks("LeftButtonUp","RightButtonUp"); b:RegisterForDrag("LeftButton")
    b.bg=Solid(b,"BACKGROUND",1,1,1,0); b.bg:SetAllPoints(b)
    b.ind=Solid(b,"ARTWORK",1,1,1,1); b.ind:SetWidth(2); b.ind:SetPoint("TOPLEFT",b,"TOPLEFT",0,0); b.ind:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",0,0)
    b.icon=b:CreateTexture(nil,"ARTWORK")
    b.label=Text(b,11); b.label:SetJustifyH("LEFT"); b.label:SetHeight(12)
    b.count=Text(b,10); b.count:SetPoint("RIGHT",b,"RIGHT",-6,0); b.count:SetTextColor(.5,.5,.5)
    b:SetScript("OnEnter",function(self)
        self.hover=true; PaintSidebarButton(f,self)
        if self.collapsed then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText(self.entry.label..(self.entry.count and self.entry.count>0 and " ("..self.entry.count..")" or ""),1,1,1); GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave",function(self) self.hover=false; PaintSidebarButton(f,self); GameTooltip:Hide() end)
    b:SetScript("OnClick",function(self,button) ns.SidebarClick(f,self.entry,button) end)
    b:SetScript("OnReceiveDrag",function(self) ns.SidebarClick(f,self.entry,"LeftButton") end)
    b:SetScript("OnDragStart",function(self)
        local e=self.entry; if e.kind~="cat" or e.cat.noMove or e.cat.isEquipSet or not ns.IsLiveView(f) then return end
        f._sbDrag=self; self:SetAlpha(.5)
    end)
    b:SetScript("OnDragStop",function(self)
        local src=f._sbDrag; f._sbDrag=nil; if not src then return end; src:SetAlpha(1)
        for _,t in ipairs(f.sbButtons) do
            if t~=src and t:IsShown() and t:IsMouseOver() then
                local te,to=t.entry
                if te.kind=="cat" and not te.cat.noMove then to=te.index elseif te.kind=="group" then to=CM:GetGroupMembers(te.group)[1] end
                if to then local from=src.entry.index; if from<to then to=to+1 end; CM:ReorderCategory(from,to); ns.RefreshAll() end
                return
            end
        end
    end)
    return b
end
local function SidebarEntries(f,cats,counts,itemTotal,p,rows)
    local e={}
    if f.kind=="bags" then
        local fixed={all={"All Items","Interface\\Icons\\INV_Misc_Bag_08",itemTotal},onebag={"OneBag","Interface\\Icons\\INV_Misc_Bag_10_Blue"},
            multibag={"MultiBag","Interface\\Icons\\INV_Misc_Bag_17"}}
        local order={"all","onebag","multibag"}; local def=fixed[p.bagDefaultBagType] and p.bagDefaultBagType or "all"
        for i,v in ipairs(order) do if v==def then table.remove(order,i); table.insert(order,1,v); break end end
        for _,v in ipairs(order) do e[#e+1]={kind="view",view=v,label=fixed[v][1],icon=fixed[v][2],count=fixed[v][3]} end
    else
        e[#e+1]={kind="view",view="all",label="All Items",icon="Interface\\Icons\\INV_Box_02",count=itemTotal}
        if not p.bankHideTabsInSidebar then
            local perBag,order={}, {}
            for _,item in ipairs(rows) do if not perBag[item.bag] then perBag[item.bag]=0; order[#order+1]=item.bag end; if item.link then perBag[item.bag]=perBag[item.bag]+1 end end
            for _,bag in ipairs(order) do e[#e+1]={kind="bag",bag=bag,label=bag==-1 and "Bank" or "Bank Bag "..(bag-4),icon=bag==-1 and "Interface\\Icons\\INV_Box_02" or "Interface\\Icons\\INV_Misc_Bag_09",count=perBag[bag]} end
        end
    end
    local hideEmpty=p.bagHideEmptyCategories
    local function Children(ci)
        local n=0
        if p.bagSplitSetGearBySet and cats[ci].isSetGear and not cats[ci].isEquipSet then for i,c in ipairs(cats) do if c.isEquipSet then n=n+(counts[i] or 0) end end end
        return n
    end
    local done,afterQuick={},false
    for ci,cat in ipairs(cats) do
        if cat.isPinned or cat.isRecent then
            if f.kind=="bags" and (cat.isPinned and p.bagShowPinnedItems or cat.isRecent and p.bagShowRecentItems) then
                e[#e+1]={kind="cat",index=ci,cat=cat,label=cat.name,icon=cat.icon,count=counts[ci] or 0}; afterQuick=true
            end
        else
            if afterQuick then e[#e+1]={kind="divider"}; afterQuick=false end
            if cat.groupName then
                if not done[cat.groupName] then
                    done[cat.groupName]=true
                    local members=CM:GetGroupMembers(cat.groupName); local sum=0
                    for _,mi in ipairs(members) do sum=sum+(counts[mi] or 0)+Children(mi) end
                    if not (hideEmpty and sum==0) then
                        e[#e+1]={kind="group",group=cat.groupName,label=cat.groupName,icon=cats[members[1]].icon,count=sum}
                        for _,mi in ipairs(members) do
                            local c=(counts[mi] or 0)+Children(mi)
                            if not (hideEmpty and c==0 and not cats[mi].isUserCreated) then e[#e+1]={kind="cat",index=mi,cat=cats[mi],label=cats[mi].name,icon=cats[mi].icon,count=c,indent=true} end
                        end
                    end
                end
            else
                local c=(counts[ci] or 0)+Children(ci)
                if not (hideEmpty and c==0 and not cat.isUserCreated) then e[#e+1]={kind="cat",index=ci,cat=cat,label=cat.name,icon=cat.icon,count=c} end
            end
        end
    end
    if afterQuick then e[#e+1]={kind="divider"} end
    return e
end
local function LayoutSidebar(f,entries,sbW,p,live)
    local sb=f.Sidebar
    if sbW<=0 then sb:Hide(); return 0 end
    sb:Show(); sb:SetWidth(sbW)
    local collapsed=Collapsed(f)
    Shown(sb.label,not collapsed)
    sb.toggle.icon:SetTexture(MEDIA..(collapsed and "eui-arrow-right" or "eui-arrow-left"))
    sb.toggle:ClearAllPoints()
    if collapsed then sb.toggle:SetPoint("TOP",sb,"TOP",0,-6) else sb.toggle:SetPoint("TOPRIGHT",sb,"TOPRIGHT",-8,-6) end
    if live and f.kind=="bags" and not p.bagHideAddCategory then entries[#entries+1]={kind="add",label="Add Category",icon="Interface\\Buttons\\UI-PlusButton-Up"} end
    local y,bi,di=0,0,0
    for _,e in ipairs(entries) do
        if e.kind=="divider" then
            di=di+1; local d=sb.dividers[di] or Solid(sb.content,"ARTWORK",1,1,1,.2); sb.dividers[di]=d
            d:ClearAllPoints(); d:SetPoint("TOPLEFT",sb.content,"TOPLEFT",8,y-3); d:SetPoint("TOPRIGHT",sb.content,"TOPRIGHT",-8,y-3); d:SetHeight(1); d:Show(); y=y-7
        else
            bi=bi+1; local b=f.sbButtons[bi] or SidebarButton(f); f.sbButtons[bi]=b
            b.entry,b.collapsed=e,collapsed; b:ClearAllPoints(); b:SetPoint("TOPLEFT",sb.content,"TOPLEFT",0,y); b:SetWidth(sbW-1)
            PaintSidebarButton(f,b); b:Show(); y=y-(SB_BTN_H+SB_PAD)
        end
    end
    Size(sb.content,sbW-1,max(1,-y))
    return SB_HDR-y+6
end
function ns.SidebarClick(f,entry,button)
    if not entry then return end
    if entry.kind=="add" then ns.ShowCategoryEditor(f); return end
    if button=="RightButton" then ns.SidebarMenu(f,entry); return end
    if ns.IsLiveView(f) and f.kind=="bags" and entry.kind=="cat" and CursorHasItem() then
        local ctype,id=GetCursorInfo()
        if ctype=="item" and id then
            if entry.cat.isPinned then PinSet()[id]=true; ClearCursor(); ns.RefreshAll(); return end
            if CM:CanAssignToCategory(entry.index) then CM:AssignItem(id,entry.cat._defaultName); ClearCursor(); ns.RefreshAll(); return end
        end
    end
    if entry.kind=="view" then f.view,f.viewKey=entry.view,nil
    elseif entry.kind=="bag" then f.view,f.viewKey="bag",entry.bag
    elseif entry.kind=="group" then f.view,f.viewKey="group",entry.group
    elseif entry.kind=="cat" then f.view,f.viewKey="cat",entry.cat._defaultName end
    f.scroll:SetVerticalScroll(0); ns.Refresh(f.kind)
end
function ns.SidebarMenu(f,entry)
    local cats=CM:GetCategories(); local p=P(); local list={}
    local function Add(text,fn) list[#list+1]={text=text,notCheckable=true,func=function() if CloseDropDownMenus then CloseDropDownMenus() end; fn() end} end
    local function HideToggle(key)
        local hidden=p.bagHiddenInAllItems and p.bagHiddenInAllItems[key]
        Add(hidden and "Show in All Items" or "Hide in All Items",function() p.bagHiddenInAllItems=p.bagHiddenInAllItems or {}; p.bagHiddenInAllItems[key]=(not hidden) or nil; ns.RefreshAll() end)
    end
    if entry.kind=="group" then
        local g=entry.group
        Add("Rename",function() ns.Prompt("Rename Group",g,function(text)
            CM:RenameGroup(g,text); CM:SetGroupNameCustom(text,true)
            if p.bagHiddenInAllItems and p.bagHiddenInAllItems[g] then p.bagHiddenInAllItems[text]=true; p.bagHiddenInAllItems[g]=nil end
            if f.viewKey==g then f.viewKey=text end; ns.RefreshAll()
        end) end)
        Add("Disband Group",function() CM:DisbandGroup(g); if f.viewKey==g then f.view,f.viewKey="all",nil end; ns.RefreshAll() end)
        HideToggle(g)
    elseif entry.kind=="cat" then
        local cat,ci=entry.cat,entry.index
        if cat.isPinned or cat.isRecent then
            Add(cat.isPinned and "Hide Pinned Items" or "Hide Recent Items",function() p[cat.isPinned and "bagShowPinnedItems" or "bagShowRecentItems"]=false; f.view,f.viewKey="all",nil; ns.RefreshAll() end)
            if cat.isRecent then Add("Clear Recent Items",ns.ClearRecent) end
        else
            Add("Rename",function() ns.Prompt("Rename Category",cat.name,function(text) CM:RenameCategory(ci,text); ns.RefreshAll() end) end)
            if cat.isUserCreated then
                Add("Edit Category",function() ns.ShowCategoryEditor(f,ci) end)
                Add("Delete Category",function() ns.ConfirmDeleteCategory(ci) end)
            end
            if cat.groupName then Add("Ungroup "..cat.name,function() CM:UngroupCategory(ci); ns.RefreshAll() end)
            elseif not cat.noGroup then
                local with={}
                for i,c in ipairs(cats) do
                    if i~=ci and not c.groupName and not c.noGroup and not c.isEquipSet then
                        local other=i; with[#with+1]={text=c.name,notCheckable=true,func=function() if CloseDropDownMenus then CloseDropDownMenus() end; CM:GroupCategories({ci,other}); ns.RefreshAll() end}
                    end
                end
                if #with>0 then list[#list+1]={text="Create Group With",notCheckable=true,hasArrow=true,menuList=with} end
                local groups={}
                for _,g in ipairs(CM:GetGroupNames()) do local name=g; groups[#groups+1]={text=g,notCheckable=true,func=function() if CloseDropDownMenus then CloseDropDownMenus() end; CM:AddToGroup(ci,name); ns.RefreshAll() end} end
                if #groups>0 then list[#list+1]={text="Add to Group",notCheckable=true,hasArrow=true,menuList=groups} end
            end
            if not cat.groupName then HideToggle(cat._defaultName) end
        end
    end
    if #list==0 then return end
    table.insert(list,1,{text=entry.label,isTitle=true,notCheckable=true})
    ns.ShowMenu(list)
end

---------------------------------------------------------------------------
-- Footer: currencies, money and the Gold Summary tooltip
---------------------------------------------------------------------------
function ns.CurrencyList()
    local list={}
    if not GetCurrencyListSize or not GetCurrencyListInfo then return list end
    for i=1,GetCurrencyListSize() do
        local name,isHeader,_,_,watched,count,extra,icon,itemID=GetCurrencyListInfo(i)
        if name and not isHeader then
            local coords
            if extra==1 then icon="Interface\\PVPFrame\\PVP-ArenaPoints-Icon"
            elseif extra==2 then icon="Interface\\TargetingFrame\\UI-PVP-"..(UnitFactionGroup("player") or "Alliance"); coords={.03,.6,.03,.6} end
            list[#list+1]={key=(itemID and itemID>0) and itemID or name,name=name,icon=icon,coords=coords,count=count or 0,watched=watched and true or false,index=i}
        end
    end
    return list
end
local function CharKey(record) return (record and record.realm or "").."-"..(record and record.name or "") end
function ns.CurrentCharKey() local realm,name=ns.CurrentCharacter(); return realm.."-"..name end
function ns.CaptureCurrencies()
    local realm,name=ns.CurrentCharacter(); if realm=="Unknown Realm" or name=="Unknown Character" then return end
    local list=ns.CurrencyList(); if #list==0 then return end
    local record=ns.CharacterRecord(realm,name,true); record.currencies={}
    for _,c in ipairs(list) do record.currencies[#record.currencies+1]={key=c.key,name=c.name,icon=c.icon,coords=c.coords,count=c.count,watched=c.watched} end
end
function ns.SelectedCurrencies(record,live)
    local all=live and ns.CurrencyList() or (record and record.currencies) or {}
    local chosen=DB().bagCurrencyByChar and DB().bagCurrencyByChar[CharKey(record)]
    local out={}
    if chosen then
        local byKey={}; for _,c in ipairs(all) do byKey[c.key]=c end
        for _,key in ipairs(chosen) do if byKey[key] then out[#out+1]=byKey[key] end end
    else for _,c in ipairs(all) do if c.watched then out[#out+1]=c end end end
    return out
end
local function CurrencyEntry(f)
    local c=CreateFrame("Frame",nil,f.Footer); c:SetHeight(17); c:EnableMouse(true)
    c.icon=c:CreateTexture(nil,"ARTWORK"); Size(c.icon,17,17); c.icon:SetPoint("LEFT",c,"LEFT",0,0)
    c.text=Text(c,11); c.text:SetPoint("LEFT",c.icon,"RIGHT",3,0)
    c:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_TOP")
        if self.data.index and self.live and GameTooltip.SetCurrencyToken then GameTooltip:SetCurrencyToken(self.data.index)
        else GameTooltip:SetText(self.data.name,1,1,1); GameTooltip:AddLine(tostring(self.data.count),.8,.8,.8) end
        GameTooltip:Show()
    end)
    c:SetScript("OnLeave",function() GameTooltip:Hide() end)
    return c
end
local function LayoutFooter(f,p,live,record,snapshot,free,total,width)
    local ft=f.Footer
    for _,c in ipairs(f.currencies) do c:Hide() end
    local money=live and GetMoney() or (record and record.money)
    f.money:SetText(money and ns.MoneyString(money) or "")
    local rows=1
    if f.kind=="bags" then
        local x,row,limit=10,0,width-180
        for i,data in ipairs(ns.SelectedCurrencies(record,live)) do
            local c=f.currencies[i] or CurrencyEntry(f); f.currencies[i]=c; c.data,c.live=data,live
            c.icon:SetTexture(data.icon); if data.coords then c.icon:SetTexCoord(unpack(data.coords)) else c.icon:SetTexCoord(.08,.92,.08,.92) end
            c.text:SetText(Commas(data.count)); local w=20+(c.text.GetStringWidth and c.text:GetStringWidth() or 30)
            if x+w>limit and x>10 then row=row+1; x=10 end
            c:SetWidth(w); c:ClearAllPoints(); c:SetPoint("TOPLEFT",ft,"TOPLEFT",x,-(6+row*18)); c:Show(); x=x+w+8
        end
        rows=row+1
    end
    local status=""
    if not snapshot then status=f.kind=="bank" and "Contents not ready - visit the bank to record it" or "Contents not ready"
    elseif not live then status="Saved "..date("%Y-%m-%d %H:%M",snapshot.updated)
    elseif f.kind=="bank" then status=free.." / "..total.." free" end
    f.footer:SetText(status)
    local height=max(FOOTER_H,10+rows*18)
    ft:SetHeight(height)
    return height
end
local function GoldTooltip(f)
    local t=ns.goldTip
    if not t then
        t=CreateFrame("Frame","EUI335GoldSummary",UIParent); ns.goldTip=t; t:SetFrameStrata("TOOLTIP"); t:Hide()
        t.bg=Solid(t,"BACKGROUND",.06,.06,.06,.9); t.bg:SetAllPoints(t); t.edges=ns.Border(t,.25,.25,.25,1)
        t.title=Text(t,12); t.title:SetPoint("TOPLEFT",t,"TOPLEFT",10,-8); t.title:SetText("Gold Summary"); t.title:SetTextColor(.8,.8,.8)
        t.rows={}; t.sep=Solid(t,"ARTWORK",1,1,1,.15); t.sep:SetHeight(1)
        t.totalL=Text(t,11); t.totalR=Text(t,11); t.totalL:SetText("Total"); t.totalL:SetTextColor(1,1,.5); t.totalR:SetTextColor(1,1,.5)
        t.hint=Text(t,10); t.hint:SetText("Ctrl + Right-Click: Reset all data"); t.hint:SetTextColor(1,.3,.3)
    end
    local total,_,entries=ns.GoldTotals(); local realm=ns.CurrentCharacter()
    table.sort(entries,function(a,b) return a.money>b.money end)
    local y,wide=-28,180
    for _,row in ipairs(t.rows) do row.l:Hide(); row.r:Hide() end
    for i,entry in ipairs(entries) do
        local row=t.rows[i]; if not row then row={l=Text(t,11),r=Text(t,11)}; t.rows[i]=row end
        local c=entry.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.class]
        row.l:SetText(entry.name..(entry.realm~=realm and " - "..entry.realm or "")); row.l:SetTextColor(c and c.r or 1,c and c.g or 1,c and c.b or 1)
        row.r:SetText(ns.MoneyString(entry.money)); row.r:SetTextColor(1,1,1)
        row.l:ClearAllPoints(); row.l:SetPoint("TOPLEFT",t,"TOPLEFT",10,y); row.r:ClearAllPoints(); row.r:SetPoint("TOPRIGHT",t,"TOPRIGHT",-10,y)
        row.l:Show(); row.r:Show(); y=y-16
        if row.l.GetStringWidth then wide=max(wide,row.l:GetStringWidth()+row.r:GetStringWidth()+40) end
    end
    t.sep:ClearAllPoints(); t.sep:SetPoint("TOPLEFT",t,"TOPLEFT",10,y-3); t.sep:SetPoint("TOPRIGHT",t,"TOPRIGHT",-10,y-3); y=y-8
    t.totalL:ClearAllPoints(); t.totalL:SetPoint("TOPLEFT",t,"TOPLEFT",10,y); t.totalR:ClearAllPoints(); t.totalR:SetPoint("TOPRIGHT",t,"TOPRIGHT",-10,y)
    t.totalR:SetText(ns.MoneyString(total)); y=y-18
    t.hint:ClearAllPoints(); t.hint:SetPoint("TOPLEFT",t,"TOPLEFT",10,y); y=y-16
    Size(t,wide,-y+6); t:ClearAllPoints(); t:SetPoint("BOTTOMRIGHT",f.moneyHit,"TOPRIGHT",4,4)
    t:SetAlpha(1); t:Show(); if UIFrameFadeIn then UIFrameFadeIn(t,.15,0,1) end
end

---------------------------------------------------------------------------
-- Pin / assign select mode
---------------------------------------------------------------------------
local sel
local function SpecialFrames(selecting)
    if not UISpecialFrames then return end
    for i=#UISpecialFrames,1,-1 do
        local n=UISpecialFrames[i]; if n=="EUI335Inventory_bags" or n=="EUI335Inventory_bank" or n=="EUI335BagSelectDim" then table.remove(UISpecialFrames,i) end
    end
    if selecting then UISpecialFrames[#UISpecialFrames+1]="EUI335BagSelectDim"
    else UISpecialFrames[#UISpecialFrames+1]="EUI335Inventory_bags"; UISpecialFrames[#UISpecialFrames+1]="EUI335Inventory_bank" end
end
function ns.EnterSelectMode(f,mode,key)
    if not sel then
        sel=CreateFrame("Frame","EUI335BagSelectDim",UIParent); sel:SetFrameStrata("DIALOG"); sel:SetAllPoints(UIParent); sel:EnableMouse(true); sel:Hide()
        sel.tex=Solid(sel,"BACKGROUND",0,0,0,.6); sel.tex:SetAllPoints(sel)
        sel.tip=Text(sel,14); sel.tip:SetPoint("TOP",sel,"TOP",0,-120); sel.tip:SetTextColor(1,1,1)
        sel:SetScript("OnMouseUp",function(_,button) if button=="RightButton" then ns.ExitSelectMode() end end)
        sel:SetScript("OnHide",function() ns.ExitSelectMode() end)
        local c=CreateFrame("Button",nil,sel); sel.catcher=c; c:SetFrameStrata("FULLSCREEN_DIALOG"); c:RegisterForClicks("LeftButtonUp","RightButtonUp"); c:EnableMouseWheel(true)
        sel.hl=CreateFrame("Frame",nil,c); sel.hl.fill=Solid(sel.hl,"ARTWORK",1,1,1,.4); sel.hl.fill:SetAllPoints(sel.hl)
        sel.hl.edges=ns.Border(sel.hl,1,1,1,1); ns.BorderSize(sel.hl.edges,2); sel.hl:Hide()
        c:SetScript("OnMouseWheel",function(_,delta) if sel.f then ns.ScrollBy(sel.f,-delta*STEP*2) end end)
        c:SetScript("OnUpdate",function()
            local hover
            if sel.f then for _,b in ipairs(sel.f.shownButtons or {}) do if b._item and b._item.link and b:IsVisible() and b:IsMouseOver() then hover=b; break end end end
            sel.hover=hover
            if hover then sel.hl:ClearAllPoints(); sel.hl:SetAllPoints(hover); sel.hl:Show() else sel.hl:Hide() end
        end)
        c:SetScript("OnClick",function(_,button)
            if button=="RightButton" then ns.ExitSelectMode(); return end
            local b=sel.hover; local id=b and b._item and b._item.itemID; if not id then return end
            if sel.mode=="pin" then ns.TogglePin(id)
            elseif sel.mode=="junk" then CM:ToggleJunk(id); ns.RefreshAll()
            else CM:AssignItem(id,sel.key); ns.RefreshAll() end
        end)
    end
    local ar,ag,ab=ns.Accent(); ns.BorderColor(sel.hl.edges,ar,ag,ab,1)
    sel.f,sel.mode,sel.key=f,mode,key
    sel.tip:SetText(mode=="pin" and "Click items to pin or unpin them. Right-click or Escape to finish."
        or mode=="junk" and "Click items to mark or unmark them as junk. Right-click or Escape to finish."
        or "Click items to move them into this category. Right-click or Escape to finish.")
    f.scroll:SetFrameStrata("FULLSCREEN_DIALOG")
    sel.catcher:ClearAllPoints(); sel.catcher:SetAllPoints(f.scroll); sel.catcher:SetFrameLevel(f.scroll:GetFrameLevel()+40)
    SpecialFrames(true); sel:Show()
end
function ns.ExitSelectMode()
    if not sel or not sel.f then return end
    local f=sel.f; sel.f=nil; sel.hover=nil
    f.scroll:SetFrameStrata(f:GetFrameStrata()); SpecialFrames(false)
    if sel:IsShown() then sel:Hide() end
end
function ns.PlusClick(f,o)
    local ctype,id=GetCursorInfo()
    if ctype=="item" and id then
        if o.mode=="pin" then PinSet()[id]=true else CM:AssignItem(id,o.key) end
        ClearCursor(); ns.RefreshAll(); return
    end
    ns.EnterSelectMode(f,o.mode,o.key)
end

---------------------------------------------------------------------------
-- Junk Marker: the header coin (mark mode) and Sell Junk at merchants
---------------------------------------------------------------------------
function ns.JunkClick(f)
    if InCombatLockdown() then return end
    local ctype,id=GetCursorInfo()
    if ctype=="item" and id then CM:ToggleJunk(id); ClearCursor(); ns.RefreshAll(); return end
    ns.EnterSelectMode(f,"junk")
end
-- Marked or grey junk worth something, outside equipment sets and pins; one
-- item every 0.15 s while the merchant stays open, out of combat, with an
-- empty cursor (a sale waiting on a confirmation stops the sweep).
function ns.SellJunk()
    if ns.junkSelling or InCombatLockdown() or not ns.merchantOpen then return end
    CM:RebuildSetLookup()
    local pins,slots,kept=PinSet(),{},0
    for bag=0,4 do
        for slot=1,GetContainerNumSlots(bag) or 0 do
            local link=GetContainerItemLink(bag,slot); local id=link and tonumber(link:match("item:(%d+)"))
            if id then
                local _,_,quality,_,_,_,_,_,_,_,price=GetItemInfo(link)
                if CM:IsJunk(id,quality) then
                    if (price or 0)<=0 or pins[id] or CM:SetNameAt(bag,slot) then kept=kept+1
                    else slots[#slots+1]={bag=bag,slot=slot,id=id,price=price} end
                end
            end
        end
    end
    ns.junkSelling=true
    local i,sold,earned=0,0,0
    local function Finish()
        ns.junkSelling=nil
        local tag="|cff0cd29fEllesmereUI:|r "
        if sold>0 then
            local msg=format("Sold %d junk item(s)",sold)
            if earned>0 and GetCoinTextureString then msg=msg.."  "..GetCoinTextureString(earned) end
            print(tag..msg)
        end
        local left=kept+#slots-sold
        if left>0 then print(tag..format("%d junk item(s) could not be sold.",left)) end
    end
    local function Step()
        if not ns.merchantOpen or InCombatLockdown() or CursorHasItem() then return Finish() end
        i=i+1; local s=slots[i]; if not s then return Finish() end
        local link=GetContainerItemLink(s.bag,s.slot); local _,count,locked=GetContainerItemInfo(s.bag,s.slot)
        if link and tonumber(link:match("item:(%d+)"))==s.id and not locked then
            UseContainerItem(s.bag,s.slot); sold=sold+1; earned=earned+s.price*(count or 1)
        end
        ns.After(.15,Step)
    end
    Step()
end

---------------------------------------------------------------------------
-- Physical sort: consolidate stacks, then selection-sort moves per bag family
---------------------------------------------------------------------------
local sorter=CreateFrame("Frame"); sorter:Hide()
local job
local function FamilyGroups(bags)
    local groups,byFam={}, {}
    for _,bag in ipairs(bags) do
        local n=GetContainerNumSlots(bag)
        if n and n>0 then
            local _,fam=GetContainerNumFreeSlots(bag); fam=(bag==0 or bag==-1) and 0 or (fam or 0)
            local g=byFam[fam]; if not g then g={family=fam,slots={}}; byFam[fam]=g; groups[#groups+1]=g end
            for s=1,n do g.slots[#g.slots+1]={bag=bag,slot=s} end
        end
    end
    return groups
end
function ns.SortGroups(kind,perBag)
    local bags=kind=="bank" and {-1,5,6,7,8,9,10,11} or {0,1,2,3,4}
    if not perBag then return FamilyGroups(bags) end
    local groups={}; for _,bag in ipairs(bags) do for _,g in ipairs(FamilyGroups({bag})) do groups[#groups+1]=g end end
    return groups
end
local function ScanSlots(slots)
    local list={}
    for i,pos in ipairs(slots) do
        local _,count,locked=GetContainerItemInfo(pos.bag,pos.slot); local link=GetContainerItemLink(pos.bag,pos.slot)
        local e={bag=pos.bag,slot=pos.slot,locked=locked}
        if link then
            local name,_,q,level,_,itemType,itemSubType,maxStack,equip=GetItemInfo(link)
            e.link,e.itemID,e.count,e.name,e.quality,e.level=link,tonumber(link:match("item:(%d+)")),count or 1,name or "",q or 1,level or 0
            e.itemType,e.itemSubType,e.equip,e.maxStack=itemType,itemSubType,equip,maxStack or 1
        end
        list[i]=e
    end
    return list
end
local function BuildPlan(slots)
    local items={}; for _,e in ipairs(slots) do if e.link then items[#items+1]=e end end
    CM:ClassifyAll(items,true); for _,e in ipairs(items) do e._gear=IsGear(e) end
    if job.random then for i=#items,2,-1 do local j=math.random(i); items[i],items[j]=items[j],items[i] end
    else table.sort(items,VisualSortCompare) end
    local n,total,bottom=#items,#slots,P().bagSortToBottom
    local plan={links={},targets={}}
    for i,e in ipairs(items) do plan.links[i]=e.link; plan.targets[i]=bottom and (total-n+i) or i end
    if bottom then
        -- Sort to Bottom walks from the last slot so the tail settles first.
        local l,t={}, {}; for i=n,1,-1 do l[#l+1]=plan.links[i]; t[#t+1]=plan.targets[i] end; plan.links,plan.targets=l,t
    end
    return plan
end
local function GroupPass(g)
    local slots=ScanSlots(g.slots)
    for _,e in ipairs(slots) do if e.locked then return "wait" end end
    if g.phase~="arrange" then
        g.cpass=(g.cpass or 0)+1
        local moved=false
        if g.cpass<=15 then
            local partial={}
            for _,e in ipairs(slots) do if e.link and e.maxStack>1 and e.count<e.maxStack then local t=partial[e.link]; if not t then t={}; partial[e.link]=t end; t[#t+1]=e end end
            for _,t in pairs(partial) do
                if #t>1 then table.sort(t,function(a,b) return a.count<b.count end); PickupContainerItem(t[1].bag,t[1].slot); PickupContainerItem(t[#t].bag,t[#t].slot); moved=true end
            end
        end
        if moved then return "wait" end
        g.phase,g.plan="arrange",BuildPlan(slots)
    end
    g.apass=(g.apass or 0)+1; if g.apass>30 then return "done" end
    local touched,settled,moved={}, {}, false
    for i,link in ipairs(g.plan.links) do
        local ti=g.plan.targets[i]; local cur=slots[ti]
        if cur.link==link then settled[ti]=true
        elseif not touched[ti] then
            local from
            for j=1,#slots do if j~=ti and not settled[j] and not touched[j] and slots[j].link==link then from=j; break end end
            if from then
                local src=slots[from]
                PickupContainerItem(src.bag,src.slot); PickupContainerItem(cur.bag,cur.slot)
                src.link,cur.link=cur.link,src.link; touched[ti],touched[from],settled[ti]=true,true,true; moved=true
            end
        end
    end
    return moved and "wait" or "done"
end
local function FinishSort()
    if not job then return end
    if job.started and CursorHasItem() then ClearCursor() end
    job=nil; sorter:UnregisterAllEvents(); sorter:Hide(); ns.sorting=false; ns.RefreshAll()
end
local function SortPass()
    if not job then return end
    if InCombatLockdown() or CursorHasItem() then return FinishSort() end
    job.started=true
    local waiting=false
    for _,g in ipairs(job.groups) do if not g.done then if GroupPass(g)=="done" then g.done=true else waiting=true end end end
    if waiting then job.wake=GetTime()+.6 else FinishSort() end
end
sorter:SetScript("OnEvent",function() if job then job.wake=GetTime()+.15 end end)
sorter:SetScript("OnUpdate",function() if job and job.wake and GetTime()>=job.wake then job.wake=nil; SortPass() end end)
function ns.StartPhysicalSort(groups,random)
    if job or InCombatLockdown() or CursorHasItem() or #groups==0 then return end
    job={groups=groups,random=random}; ns.sorting=true
    sorter:RegisterEvent("BAG_UPDATE"); sorter:RegisterEvent("ITEM_LOCK_CHANGED"); sorter:Show(); SortPass()
end
function ns.IsSorting() return job~=nil end
local function LockSort(f)
    f._sortLocked=true; f.sortBtn.locked=true; f.sortBtn:SetAlpha(.3)
    ns.After(3,function() f._sortLocked=nil; f.sortBtn.locked=nil; f.sortBtn:SetAlpha(f.sortBtn.baseAlpha) end)
end
function ns.SortClick(f)
    if f._sortLocked or not ns.IsLiveView(f) or InCombatLockdown() then return end
    local p=P()
    if f.kind=="bags" and f.view=="onebag" then
        ns.Confirm("Sorting OneBag physically moves items inside your bags. Continue?","bagSortWarningDismissed",function() LockSort(f); ns.StartPhysicalSort(ns.SortGroups("bags")) end)
    elseif f.kind=="bags" and f.view=="multibag" then
        ns.Confirm("Sorting MultiBag physically reorders the items inside each bag. Continue?","bagMultiSortWarningDismissed",function() LockSort(f); ns.StartPhysicalSort(ns.SortGroups("bags",true)) end)
    elseif f.kind=="bank" and (f.view=="bag" or f.view=="all" and not p.bankGroupByCategory) then
        ns.Confirm("Sorting physically moves items inside your bank. Continue?","bagSortWarningDismissed",function() LockSort(f); ns.StartPhysicalSort(ns.SortGroups("bank",f.view=="bag")) end)
    else LockSort(f); ns.ResetVisualOrder(f) end
end
function ns.RandomizeClick(f)
    if f._sortLocked or not ns.IsLiveView(f) or InCombatLockdown() then return end
    ns.Confirm("Randomize shuffles every item in your bags into random slots. Continue?","bagRandomizeWarningDismissed",function() LockSort(f); ns.StartPhysicalSort(ns.SortGroups("bags"),true) end)
end

---------------------------------------------------------------------------
-- Stack splitter (replaces StackSplitFrame for bag items when enabled)
---------------------------------------------------------------------------
local function FreeSlot(srcBag)
    local bags=(srcBag==-1 or srcBag>4) and {-1,5,6,7,8,9,10,11} or {0,1,2,3,4}
    local _,srcFam=GetContainerNumFreeSlots(srcBag); srcFam=(srcBag==0 or srcBag==-1) and 0 or (srcFam or 0)
    for _,bag in ipairs(bags) do
        local free,fam=GetContainerNumFreeSlots(bag); fam=(bag==0 or bag==-1) and 0 or (fam or 0)
        if (free or 0)>0 and (fam==0 or fam==srcFam) then
            for s=1,GetContainerNumSlots(bag) do if not GetContainerItemLink(bag,s) then return bag,s end end
        end
    end
end
local function SplitOnce(d,amount)
    local _,count,locked=GetContainerItemInfo(d.bag,d.slot)
    if locked or not count or count<=amount then return false end
    local bag,slot=FreeSlot(d.bag); if not bag then return false end
    SplitContainerItem(d.bag,d.slot,amount); PickupContainerItem(bag,slot); return true
end
function ns.ShowSplitter(b)
    local item=b._item; if not b._live or not item or not item.link or (item.count or 1)<2 then return end
    local d=ns.splitDialog
    if not d then
        d=Panel("EUI335BagsSplit",230,100,"DIALOG"); ns.splitDialog=d
        d.title=Text(d,12); d.title:SetPoint("TOPLEFT",d,"TOPLEFT",10,-8); d.title:SetText("Split Stack"); d.title:SetTextColor(.8,.8,.8)
        d.close=ns.IconButton(d,MEDIA.."eui-close",10,nil,nil,function() d:Hide() end,.7); d.close:SetPoint("TOPRIGHT",d,"TOPRIGHT",-8,-8)
        d.box=CreateFrame("EditBox",nil,d); Size(d.box,80,22); d.box:SetPoint("TOPLEFT",d,"TOPLEFT",10,-32); Font(d.box,12)
        d.box:SetAutoFocus(false); d.box:SetNumeric(true); d.box:SetTextInsets(6,6,0,0)
        d.box.bg=Solid(d.box,"BACKGROUND",.02,.02,.02,.9); d.box.bg:SetAllPoints(d.box); d.box.edges=ns.Border(d.box,.25,.25,.25,1)
        d.box:SetScript("OnEscapePressed",function(self) self:ClearFocus(); d:Hide() end)
        d.box:SetScript("OnEnterPressed",function(self) self:ClearFocus(); d.split:Click() end)
        d.of=Text(d,11); d.of:SetPoint("LEFT",d.box,"RIGHT",8,0); d.of:SetTextColor(.6,.6,.6)
        local function Amount() return max(1,min((d.max or 2)-1,tonumber(d.box:GetText()) or 1)) end
        d.split=ns.FlatButton(d,"Split",100,function()
            if InCombatLockdown() then return end
            ns.unmerged[d.itemID or 0]=true; SplitOnce(d,Amount()); d:Hide()
        end); d.split:SetPoint("BOTTOMLEFT",d,"BOTTOMLEFT",10,10)
        d.auto=ns.FlatButton(d,"Auto Split",100,function()
            if InCombatLockdown() then return end
            ns.unmerged[d.itemID or 0]=true; local amount,tries=Amount(),0
            local function Step()
                tries=tries+1; if tries>40 or InCombatLockdown() then return end
                local _,count,locked=GetContainerItemInfo(d.bag,d.slot)
                if locked then ns.After(.25,Step); return end
                if count and count>amount and SplitOnce(d,amount) then ns.After(.35,Step) end
            end
            Step(); d:Hide()
        end); d.auto:SetPoint("BOTTOMRIGHT",d,"BOTTOMRIGHT",-10,10)
        d:SetScript("OnHide",function(self) self.box:ClearFocus() end)
    end
    d.bag,d.slot,d.itemID,d.max=item.bag,item.slot,item.itemID,item.count
    d.box:SetText(tostring(floor(item.count/2))); d.of:SetText("of "..item.count)
    d:ClearAllPoints(); d:SetPoint("BOTTOMLEFT",b,"TOPRIGHT",0,0); d:Show(); d.box:SetFocus(); d.box:HighlightText()
end
function ns.HookSplitter()
    if ns.splitHooked or not hooksecurefunc or type(OpenStackSplitFrame)~="function" then return end
    ns.splitHooked=true
    hooksecurefunc("OpenStackSplitFrame",function(_,parent)
        if not P().bagStackSplitter or not parent or not parent._eui335 or not parent._live then return end
        if StackSplitFrame then StackSplitFrame:Hide() end
        ns.ShowSplitter(parent)
    end)
end

---------------------------------------------------------------------------
-- Add / edit custom category
---------------------------------------------------------------------------
local ICON_CHOICES={"INV_Misc_Bag_08","INV_Misc_Gem_01","INV_Misc_Herb_07","INV_Ore_Copper_01","INV_Fabric_Linen_01","INV_Potion_51",
    "INV_Misc_Food_15","INV_Scroll_03","INV_Misc_Key_03","INV_Misc_Coin_01","INV_Misc_Rune_01","INV_Sword_04","INV_Chest_Plate06",
    "INV_Jewelry_Ring_03","INV_Misc_Book_09","INV_Misc_Note_01","Spell_Holy_HolyBolt","INV_Misc_Toy_10","Ability_Mount_RidingHorse",
    "INV_Misc_Bone_HumanSkull_01","INV_Misc_Ticket_Tarot_Madness","INV_Misc_EngGizmos_01","Trade_Fishing","INV_Misc_QuestionMark"}
local function InputBox(parent,w)
    local box=CreateFrame("EditBox",nil,parent); Size(box,w,22); Font(box,11); box:SetAutoFocus(false); box:SetTextInsets(6,6,0,0)
    box.bg=Solid(box,"BACKGROUND",.02,.02,.02,.9); box.bg:SetAllPoints(box); box.edges=ns.Border(box,.25,.25,.25,1)
    box:SetScript("OnEscapePressed",function(self) self:ClearFocus() end); box:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    return box
end
function ns.ShowCategoryEditor(f,index)
    local d=ns.categoryEditor
    if not d then
        d=Panel("EUI335BagsCategoryEditor",300,262); ns.categoryEditor=d; d:SetPoint("CENTER",UIParent,"CENTER",0,80)
        d.title=Text(d,13); d.title:SetPoint("TOPLEFT",d,"TOPLEFT",12,-10); d.title:SetTextColor(.9,.9,.9)
        d.nameLabel=Text(d,10); d.nameLabel:SetPoint("TOPLEFT",d,"TOPLEFT",12,-34); d.nameLabel:SetText("Name"); d.nameLabel:SetTextColor(.6,.6,.6)
        d.name=InputBox(d,276); d.name:SetPoint("TOPLEFT",d,"TOPLEFT",12,-48)
        d.icons={}
        for i,icon in ipairs(ICON_CHOICES) do
            local b=CreateFrame("Button",nil,d); Size(b,30,30); d.icons[i]=b
            b:SetPoint("TOPLEFT",d,"TOPLEFT",12+((i-1)%8)*35,-80-floor((i-1)/8)*35)
            b.tex=b:CreateTexture(nil,"ARTWORK"); b.tex:SetAllPoints(b); b.tex:SetTexture("Interface\\Icons\\"..icon); b.tex:SetTexCoord(.08,.92,.08,.92)
            b.edges=ns.Border(b,.25,.25,.25,1); b.path="Interface\\Icons\\"..icon
            b:SetScript("OnClick",function(self) d.icon=self.path; d.custom:SetText(""); d:Paint() end)
        end
        d.customLabel=Text(d,10); d.customLabel:SetPoint("TOPLEFT",d,"TOPLEFT",12,-188); d.customLabel:SetText("Custom icon (name or path)"); d.customLabel:SetTextColor(.6,.6,.6)
        d.custom=InputBox(d,276); d.custom:SetPoint("TOPLEFT",d,"TOPLEFT",12,-202)
        d.custom:SetScript("OnTextChanged",function(self)
            local t=Trim(self:GetText()); if t~="" then d.icon=t:find("\\",1,true) and t or "Interface\\Icons\\"..t; d:Paint() end
        end)
        d.save=ns.FlatButton(d,"Save",100,function()
            local name=Trim(d.name:GetText()); if name=="" then return end
            if d.index then
                local cat=CM:GetCategories()[d.index]
                if cat and cat.name~=name then CM:RenameCategory(d.index,name) end
                CM:SetCategoryIcon(d.index,d.icon)
            else CM:AddCustomCategory(name,d.icon) end
            d:Hide(); ns.RefreshAll()
        end); d.save:SetPoint("BOTTOMRIGHT",d,"BOTTOM",-6,10)
        d.cancel=ns.FlatButton(d,"Cancel",100,function() d:Hide() end); d.cancel:SetPoint("BOTTOMLEFT",d,"BOTTOM",6,10)
        function d:Paint()
            local ar,ag,ab=ns.Accent()
            for _,b in ipairs(self.icons) do if b.path==self.icon then ns.BorderColor(b.edges,ar,ag,ab,1); ns.BorderSize(b.edges,2) else ns.BorderColor(b.edges,.25,.25,.25,1); ns.BorderSize(b.edges,1) end end
        end
        d:SetScript("OnHide",function(self) self.name:ClearFocus(); self.custom:ClearFocus() end)
    end
    local cat=index and CM:GetCategories()[index]
    d.index=cat and cat.isUserCreated and index or nil
    d.title:SetText(d.index and "Edit Category" or "Add Category")
    d.name:SetText(d.index and cat.name or ""); d.icon=d.index and cat.icon or CM.DEFAULT_ICON; d.custom:SetText("")
    d:Paint(); d:Show(); d.name:SetFocus()
end
function ns.ConfirmDeleteCategory(index)
    local cat=CM:GetCategories()[index]; if not cat or not cat.isUserCreated then return end
    ns.Confirm("Delete the category \""..cat.name.."\"? Its items return to their default categories.",nil,function()
        CM:RemoveCustomCategory(index)
        for _,f in pairs(ns.views) do if f.view=="cat" and f.viewKey==cat._defaultName then f.view,f.viewKey="all",nil end end
        ns.RefreshAll()
    end)
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local function ClampScroll(f)
    local visible=f._visibleH or 0; local contentH=f.content:GetHeight(); local range=max(0,contentH-visible)
    local v=min(max(f.scroll:GetVerticalScroll() or 0,0),range); f.scroll:SetVerticalScroll(v)
    if range>0 and visible>0 then
        local h=max(20,visible*visible/contentH); f.thumb:SetHeight(h); f.thumb:ClearAllPoints()
        f.thumb:SetPoint("TOPRIGHT",f.scroll,"TOPRIGHT",-2,-(v/range)*(visible-h)); f.thumb:Show()
    else f.thumb:Hide() end
end
function ns.ScrollBy(f,delta) f.scroll:SetVerticalScroll((f.scroll:GetVerticalScroll() or 0)+delta); ClampScroll(f) end
function ns.ResetView(f)
    local p=P(); f.viewKey=nil
    f.view=f.kind=="bags" and (p and p.bagDefaultBagType or "all") or "all"
    if f.view~="all" and f.view~="onebag" and f.view~="multibag" then f.view="all" end
end
local function ValidateView(f)
    if f.view=="cat" and not CM:IndexOf(f.viewKey) then f.view,f.viewKey="all",nil end
    if f.view=="group" and #CM:GetGroupMembers(f.viewKey)==0 then f.view,f.viewKey="all",nil end
    if f.kind=="bags" and f.view=="bag" or f.kind=="bank" and (f.view=="onebag" or f.view=="multibag") then f.view,f.viewKey="all",nil end
end
local function HideAll(f)
    for _,key in ipairs({"pool","savedPool","pinPool","savedPinPool","recentPool","savedRecentPool"}) do for _,b in pairs(f[key]) do b:Hide() end end
    for _,list in ipairs({f.headers,f.pads,f.plus,f.subHeaders,f.sbButtons,f.Sidebar.dividers}) do for _,x in ipairs(list) do x:Hide() end end
    if f.warn then f.warn:Hide() end
end
local function LayoutHeader(f,live,p)
    local list={}
    for _,b in ipairs({f.settingsBtn,f.sortBtn,f.randomBtn,f.bagsBtn,f.characters,f.bankButton,f.junkBtn,f.sellBtn}) do b:Hide() end
    list[1]=f.settingsBtn
    if live and p.bagShowSortIcon then list[#list+1]=f.sortBtn end
    if live and f.kind=="bags" and f.view=="onebag" and not p.bagHideRandomize then list[#list+1]=f.randomBtn end
    if live and f.junkBtn and CM:IsJunkMarkerEnabled() then
        list[#list+1]=f.junkBtn
        if ns.merchantOpen then list[#list+1]=f.sellBtn end
    end
    list[#list+1]=f.bagsBtn; list[#list+1]=f.characters
    if f.bankButton then list[#list+1]=f.bankButton end
    local prev=f.search
    for i,b in ipairs(list) do b:ClearAllPoints(); b:SetPoint("RIGHT",prev,"LEFT",i==1 and -13 or -6,0); b:Show(); prev=b end
    f.bagsBtn.baseAlpha=p.bagShowSlots and 1 or .9; f.bagsBtn:SetAlpha(f.bagsBtn.baseAlpha)
end
function ns.OpenSettings(kind)
    if InCombatLockdown() then return end
    if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end
    if not E.ShowModule then return end
    E:ShowModule("EllesmereUIBags")
    if kind=="bank" and E.SelectPage then
        local defer=CreateFrame("Frame")
        defer:SetScript("OnUpdate",function(self) self:SetScript("OnUpdate",nil); E:SelectPage("Bank") end)
    end
end
function ns.Render(f)
    local p=P(); local live=ns.IsLiveView(f)
    local rows,free,total,uncached,snapshot,record=ns.ViewItems(f)
    f._uncached=uncached
    local items={}; for _,item in ipairs(rows) do if item.link then items[#items+1]=item end end
    local counts,itemTotal=CM:ClassifyAll(items,live)
    local cats=CM:GetCategories()
    for _,item in ipairs(items) do item._gear=IsGear(item) end
    if f.kind=="bags" then
        local pins,pc,rc=PinSet(),0,0
        for _,item in ipairs(items) do
            if item.itemID and pins[item.itemID] then pc=pc+1 end
            if live and item.itemID and ns.recent[item.itemID] then rc=rc+1 end
        end
        for i,c in ipairs(cats) do if c.isPinned then counts[i]=pc elseif c.isRecent then counts[i]=rc end end
    end
    -- Merge non-gear duplicates by link; paused while a panel takes items.
    if p.bagMergeDuplicates and not ns.ItemPanelOpen() then
        local first={}
        for _,item in ipairs(items) do
            if not item._gear and not ns.unmerged[item.itemID or 0] then
                local head=first[item.link]
                if head then head.mergedCount=(head.mergedCount or head.count or 1)+(item.count or 1); head._mergedN=(head._mergedN or 1)+1; item._mergedInto=head
                else first[item.link]=item end
            end
        end
    end
    ValidateView(f); HideAll(f)
    f._orderKeys={}
    local columns=Columns(f,p,#rows)
    local sbW=SidebarWidth(f,p)
    local width=sbW+columns*STEP+20+18+2
    local secs=BuildSections(f,rows,items,cats,p,live,snapshot)
    local sbH=LayoutSidebar(f,sbW>0 and SidebarEntries(f,cats,counts,itemTotal,p,rows) or {},sbW,p,live)
    local contentH=Layout(f,secs,columns,p,live)
    local footerH=LayoutFooter(f,p,live,record,snapshot,free,total,width)
    local cap=p.bagAutoSize and floor(((GetScreenHeight and GetScreenHeight()) or 1080)*.95/(p.bagScale or 1)) or FIXED_H
    local height=min(max(HEADER_H+footerH+contentH,HEADER_H+footerH+sbH,200),cap)
    Size(f,width,height)
    f.scroll:ClearAllPoints(); f.scroll:SetPoint("TOPLEFT",f,"TOPLEFT",sbW,-HEADER_H); f.scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-2,footerH)
    f.Sidebar:ClearAllPoints(); f.Sidebar:SetPoint("TOPLEFT",f,"TOPLEFT",0,-HEADER_H); f.Sidebar:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,footerH)
    f._visibleH=height-HEADER_H-footerH
    Size(f.content,width-sbW-2,max(1,contentH)); ClampScroll(f)
    local _,current=ns.CurrentCharacter(); local base=f.kind=="bank" and "Bank" or "Bags"
    f.title:SetText(live and base or ((f.selectedName or current).." - "..base.." (Saved)"))
    if f.view=="cat" or f.view=="group" then local n=0; for _,b in ipairs(f.shownButtons) do if b._item and b._item.link then n=n+1 end end; f.itemCount:SetText(format("%d Items",n))
    else f.itemCount:SetText(format("%d / %d Items",total-free,total)) end
    LayoutHeader(f,live,p)
    ns.RefreshInventoryControls(f,snapshot)
    ns.ApplySearch(f)
end
function ns.OnFirstOpen(f)
    local db=DB(); if db.bagFirstOpenDone then return end
    db.bagFirstOpenDone=true; PinSet()[6948]=true; ns.Refresh(f.kind)
end
function ns.MakeView(kind)
    local f=CreateFrame("Frame","EUI335Inventory_"..kind,UIParent); f:Hide(); f.kind=kind
    f:SetFrameStrata("HIGH"); f:SetMovable(true); f:SetClampedToScreen(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) local p=P(); if not InCombatLockdown() and (p.bagMoveNoShift or IsShiftKeyDown()) then self:StartMoving() end end)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); ns.SavePosition(kind) end)
    f.pool,f.savedPool,f.pinPool,f.savedPinPool,f.recentPool,f.savedRecentPool={}, {}, {}, {}, {}, {}
    f.bagParents,f.headers,f.pads,f.plus,f.subHeaders,f.sbButtons,f.currencies,f.shownButtons={}, {}, {}, {}, {}, {}, {}, {}
    f.bg=f:CreateTexture(nil,"BACKGROUND"); f.bg:SetAllPoints(f); f.bg:SetTexture(MEDIA.."modern_blizz")
    f.tint=f:CreateTexture(nil,"BACKGROUND",nil,1); f.tint:SetAllPoints(f); f.tint:SetTexture(0,0,0,.25)
    f.edges=ns.Border(f,.1,.1,.1,1)
    -- Header
    local h=CreateFrame("Frame",nil,f); f.Header=h; h:SetPoint("TOPLEFT",f,"TOPLEFT",0,0); h:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0); h:SetHeight(HEADER_H)
    h.bg=Solid(h,"BACKGROUND",0,0,0,.5); h.bg:SetAllPoints(h)
    h.sep=Solid(h,"ARTWORK",1,1,1,.15); h.sep:SetHeight(1); h.sep:SetPoint("BOTTOMLEFT",h,"BOTTOMLEFT",0,0); h.sep:SetPoint("BOTTOMRIGHT",h,"BOTTOMRIGHT",0,0)
    f.title=Text(h,13); f.title:SetPoint("LEFT",h,"LEFT",10,0); f.title:SetText(kind=="bank" and "Bank" or "Bags")
    f.itemCount=Text(h,11); f.itemCount:SetPoint("LEFT",f.title,"RIGHT",8,0); f.itemCount:SetTextColor(.6,.6,.6)
    f.close=ns.IconButton(h,MEDIA.."eui-close",12,nil,nil,function() f:Hide() end,.7); f.close:SetPoint("RIGHT",h,"RIGHT",-9,0)
    local s=CreateFrame("EditBox",nil,h); f.search=s; Size(s,160,22); s:SetPoint("RIGHT",h,"RIGHT",-35,0)
    Font(s,11); s:SetAutoFocus(false); s:SetTextInsets(6,18,0,0)
    s.bg=Solid(s,"BACKGROUND",.02,.02,.02,.9); s.bg:SetAllPoints(s); s.edges=ns.Border(s,.25,.25,.25,1)
    s.placeholder=Text(s,11); s.placeholder:SetPoint("LEFT",s,"LEFT",6,0); s.placeholder:SetText("Search..."); s.placeholder:SetTextColor(.4,.4,.4)
    s.clear=CreateFrame("Button",nil,s); Size(s.clear,16,16); s.clear:SetPoint("RIGHT",s,"RIGHT",-2,0)
    s.clear.text=Text(s.clear,11); s.clear.text:SetPoint("CENTER",s.clear,"CENTER",0,0); s.clear.text:SetText("x"); s.clear.text:SetTextColor(.6,.6,.6); s.clear:Hide()
    s.clear:SetScript("OnClick",function() s:SetText(""); s:ClearFocus() end)
    s:SetScript("OnTextChanged",function(self)
        local t=self:GetText() or ""; Shown(self.placeholder,t=="" and not self.focused); Shown(self.clear,t~="")
        if f:IsShown() then ns.ApplySearch(f) end
    end)
    s:SetScript("OnEditFocusGained",function(self) self.focused=true; self.placeholder:Hide() end)
    s:SetScript("OnEditFocusLost",function(self) self.focused=false; Shown(self.placeholder,(self:GetText() or "")=="") end)
    s:SetScript("OnEscapePressed",function(self) self:ClearFocus(); self:SetText("") end)
    s:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
    f.sortBtn=ns.IconButton(h,MEDIA.."clean-up",24,"Sort","All Items: restore the default order. OneBag / MultiBag / Bank: physically sort the items.",function() ns.SortClick(f) end,.9)
    f.randomBtn=ns.IconButton(h,"Interface\\Buttons\\UI-GroupLoot-Dice-Up",22,"Randomize","Shuffle every item in your bags into random slots.",function() ns.RandomizeClick(f) end,.9)
    f.bagsBtn=ns.IconButton(h,"Interface\\Buttons\\Button-Backpack-Up",20,"Bags","Show or hide your equipped bag slots.",function() local p=P(); p.bagShowSlots=not p.bagShowSlots; ns.Refresh(kind) end,.9)
    if kind=="bags" then
        f.junkBtn=ns.IconButton(h,"Interface\\MoneyFrame\\UI-GoldIcon",16,"Junk Marker","Click items to mark or unmark them as junk. With an item on the cursor, marks or unmarks that item.",function() ns.JunkClick(f) end,.9)
        f.sellBtn=ns.FlatButton(h,"Sell Junk",64,function() ns.SellJunk() end); f.sellBtn:SetHeight(18)
    end
    f.settingsBtn=ns.IconButton(h,MEDIA.."eui-settings",18,"Settings","Open the EllesmereUI "..(kind=="bank" and "Bank" or "Bags").." settings.",function() ns.OpenSettings(kind) end,.7)
    -- Sidebar
    local sb=CreateFrame("Frame",nil,f); f.Sidebar=sb; sb.dividers={}
    sb.bg=Solid(sb,"BACKGROUND",0,0,0,.25); sb.bg:SetAllPoints(sb)
    sb.sep=Solid(sb,"ARTWORK",1,1,1,.15); sb.sep:SetWidth(1); sb.sep:SetPoint("TOPRIGHT",sb,"TOPRIGHT",0,0); sb.sep:SetPoint("BOTTOMRIGHT",sb,"BOTTOMRIGHT",0,0)
    sb.label=Text(sb,10); sb.label:SetPoint("TOPLEFT",sb,"TOPLEFT",10,-7); sb.label:SetText("Categories"); sb.label:SetTextColor(.5,.5,.5)
    sb.toggle=ns.IconButton(sb,MEDIA.."eui-arrow-left",12,nil,nil,function()
        local p=P(); local key=kind=="bank" and "bankSidebarCollapsed" or "bagSidebarCollapsed"; p[key]=not p[key]; ns.Refresh(kind)
    end,.4)
    sb.scroll=CreateFrame("ScrollFrame",nil,sb); sb.scroll:SetPoint("TOPLEFT",sb,"TOPLEFT",0,-SB_HDR); sb.scroll:SetPoint("BOTTOMRIGHT",sb,"BOTTOMRIGHT",-1,0)
    sb.content=CreateFrame("Frame",nil,sb.scroll); Size(sb.content,SB_W,1); sb.scroll:SetScrollChild(sb.content); sb.scroll:EnableMouseWheel(true)
    sb.scroll:SetScript("OnMouseWheel",function(self,delta)
        local range=max(0,sb.content:GetHeight()-(f._visibleH or 0)+SB_HDR)
        self:SetVerticalScroll(min(max((self:GetVerticalScroll() or 0)-delta*(SB_BTN_H+SB_PAD)*2,0),range))
    end)
    -- Content
    f.scroll=CreateFrame("ScrollFrame","EUI335InventoryScroll_"..kind,f)
    f.content=CreateFrame("Frame",nil,f.scroll); Size(f.content,400,200); f.scroll:SetScrollChild(f.content)
    f.scroll:EnableMouseWheel(true); f.scroll:SetScript("OnMouseWheel",function(_,delta) ns.ScrollBy(f,-delta*STEP*2) end)
    f.thumb=Solid(f,"OVERLAY",1,1,1,.25); f.thumb:SetWidth(3); f.thumb:Hide()
    -- Footer
    local ft=CreateFrame("Frame",nil,f); f.Footer=ft; ft:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0); ft:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",0,0); ft:SetHeight(FOOTER_H)
    ft.bg=Solid(ft,"BACKGROUND",0,0,0,.35); ft.bg:SetAllPoints(ft)
    f.money=Text(ft,11); f.money:SetPoint("BOTTOMRIGHT",ft,"BOTTOMRIGHT",-10,8)
    f.moneyHit=CreateFrame("Frame",nil,ft); f.moneyHit:SetAllPoints(f.money); f.moneyHit:EnableMouse(true)
    f.moneyHit:SetScript("OnEnter",function(self)
        if not P().enableGoldTracking then return end
        ns.CaptureMoney(); GoldTooltip(f)
    end)
    f.moneyHit:SetScript("OnLeave",function() local t=ns.goldTip; if t and t:IsShown() then if UIFrameFadeOut then UIFrameFadeOut(t,.15,1,0); ns.After(.16,function() t:Hide() end) else t:Hide() end end end)
    f.moneyHit:SetScript("OnMouseUp",function(self,button)
        if button=="RightButton" and IsControlKeyDown() and P().enableGoldTracking then ns.ResetGoldData(); if ns.goldTip and ns.goldTip:IsShown() then GoldTooltip(f) end end
    end)
    f.footer=Text(ft,11); f.footer:SetPoint("RIGHT",f.money,"LEFT",-12,0); f.footer:SetJustifyH("RIGHT"); f.footer:SetTextColor(.6,.6,.6)
    if kind=="bank" then f.native=ns.FlatButton(ft,"Native Bank",90,ns.UseNativeBank); f.native:SetPoint("LEFT",ft,"LEFT",6,0) end
    f:SetScript("OnHide",function(self)
        self.search:ClearFocus()
        if self.selector then self.selector:Hide() end
        if sel and sel.f==self then ns.ExitSelectMode() end
        if ns.splitDialog then ns.splitDialog:Hide() end
        if ns.goldTip then ns.goldTip:Hide() end
        if kind=="bank" and ns.IsBankOpen() and not self._restoring then ns.RestoreBank(); if CloseBankFrame then CloseBankFrame() end end
    end)
    ns.views[kind]=f; ns.BuildInventoryControls(f,kind); ns.ResetView(f)
    return f
end
