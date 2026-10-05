-- Merchant list layout and gear item levels on the native merchant buttons.
-- Paging, item IDs, buying and the buyback tab stay with MerchantFrame.lua.
local _,ns=...
if not ns.IsWrath then return end
for key,value in pairs({merchantShowAsList=false,merchantListRowHeight=32,merchantShowItemLevel=false}) do ns.defaults[key]=value end
local M={}; ns.Merchant=M
table.insert(ns.extras,M)
local flat="Interface\\Buttons\\WHITE8X8"
local ROWS,ROW_W,GRID_BOTTOM=10,318,332
local saved,extras={},{}
M.extras=extras
local nativeHeight,signature
local function Own(obj) ns.owned[obj]=true; return obj end
local function Save(obj)
    if not obj or saved[obj] then return end
    local d={points={},width=obj:GetWidth(),height=obj:GetHeight(),alpha=obj:GetAlpha(),scale=obj.GetScale and obj:GetScale()}
    for i=1,obj:GetNumPoints() do d.points[i]={obj:GetPoint(i)} end
    saved[obj]=d
end
local function RestoreGeometry()
    for obj,d in pairs(saved) do
        obj:ClearAllPoints()
        for _,point in ipairs(d.points) do obj:SetPoint(unpack(point)) end
        obj:SetWidth(d.width); obj:SetHeight(d.height); obj:SetAlpha(d.alpha)
        if d.scale and obj.SetScale then obj:SetScale(d.scale) end
    end
    saved={}
    if nativeHeight and _G.MerchantFrame then MerchantFrame:SetHeight(nativeHeight) end
end
local function Extra(i)
    local d=extras[i]; if d then return d end
    local row,button=_G["MerchantItem"..i],_G["MerchantItem"..i.."ItemButton"]
    if not (row and button) then return end
    d={}
    d.bg=Own(row:CreateTexture(nil,"BACKGROUND")); d.bg:SetTexture(flat); d.bg:SetAllPoints(row); d.bg:Hide()
    d.level=Own(button:CreateFontString(nil,"OVERLAY")); ns.ApplyFont(d.level,10,"OUTLINE"); d.level:Hide()
    d.listLevel=Own(row:CreateFontString(nil,"OVERLAY")); ns.ApplyFont(d.listLevel,12,"OUTLINE"); d.listLevel:Hide()
    d.listLevel:SetPoint("RIGHT",row,"RIGHT",-8,0)
    extras[i]=d
    return d
end
local function RowHeight() return math.max(24,math.min(44,math.floor(tonumber(ns.GetValue("merchantListRowHeight")) or 32))) end
local function ListLayout()
    local h=RowHeight()
    nativeHeight=nativeHeight or MerchantFrame:GetHeight()
    for i=1,ROWS do
        local row,button=_G["MerchantItem"..i],_G["MerchantItem"..i.."ItemButton"]
        local d=Extra(i)
        if row and button and d then
            Save(row); row:ClearAllPoints(); row:SetPoint("TOPLEFT",MerchantFrame,"TOPLEFT",24,-76-(i-1)*(h+2)); row:SetWidth(ROW_W); row:SetHeight(h)
            Save(button); button:ClearAllPoints(); button:SetScale((h-4)/37); button:SetPoint("LEFT",row,"LEFT",2,0)
            for _,suffix in ipairs({"SlotTexture","NameFrame"}) do local t=_G["MerchantItem"..i..suffix]; if t then Save(t); t:SetAlpha(0) end end
            local name=_G["MerchantItem"..i.."Name"]
            if name then Save(name); name:ClearAllPoints(); name:SetPoint("TOPLEFT",row,"TOPLEFT",h+4,-2); name:SetWidth(ROW_W-h-60); name:SetHeight(math.floor(h/2)) end
            local money=_G["MerchantItem"..i.."MoneyFrame"]
            if money then Save(money); money:ClearAllPoints(); money:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",h+2,1) end
            local alt=_G["MerchantItem"..i.."AltCurrencyFrame"]
            if alt and not (money and money:IsShown()) then alt:ClearAllPoints(); alt:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",h+4,1) end
            d.bg:SetVertexColor(1,1,1,i%2==0 and .05 or .02); d.bg:Show()
        end
    end
    local buyback=_G.MerchantBuyBackItem
    if buyback and _G["MerchantItem"..ROWS] then
        Save(buyback); buyback:ClearAllPoints(); buyback:SetPoint("TOPRIGHT",_G["MerchantItem"..ROWS],"BOTTOMRIGHT",0,-53)
    end
    local bottom=76+ROWS*(h+2)
    MerchantFrame:SetHeight(nativeHeight+math.max(0,bottom-GRID_BOTTOM))
end
local function GridLayout()
    RestoreGeometry()
    for _,d in pairs(extras) do d.bg:Hide(); d.listLevel:Hide() end
end
local function ItemLevels(buyback)
    local show=ns.GetValue("merchantShowItemLevel") and not buyback
    local list=ns.GetValue("merchantShowAsList")
    for i=1,ROWS do
        local d=Extra(i)
        local button=_G["MerchantItem"..i.."ItemButton"]
        if d and button then
            local level,quality
            if show and button.hasItem and button.link then
                local _,_,q,l,_,_,_,_,equip=GetItemInfo(button.link)
                if l and equip and equip~="" and equip~="INVTYPE_BAG" and equip~="INVTYPE_AMMO" then level,quality=l,q end
            end
            d.level:Hide(); d.listLevel:Hide()
            if level then
                local fs=list and d.listLevel or d.level
                if not list then d.level:ClearAllPoints(); d.level:SetPoint("BOTTOMLEFT",button,"BOTTOMLEFT",2,2) end
                fs:SetText(level); fs:SetTextColor(ns.Items.QualityColor(quality)); fs:Show()
            end
        end
    end
end
function M.MerchantInfo()
    if ns.GetValue("merchantShowAsList") then ListLayout() else GridLayout() end
    ItemLevels(false)
end
function M.BuybackInfo()
    local restored=next(saved)~=nil
    GridLayout()
    if restored then
        for _,i in ipairs({3,5,7,9}) do
            local row=_G["MerchantItem"..i]
            if row then row:SetPoint("TOPLEFT","MerchantItem"..(i-2),"BOTTOMLEFT",0,-15) end
        end
    end
    ItemLevels(true)
end
function M.Apply()
    local key=tostring(ns.GetValue("merchantShowAsList"))..RowHeight()..tostring(ns.GetValue("merchantShowItemLevel"))
    if key==signature then return end
    signature=key
    if _G.MerchantFrame and MerchantFrame:IsShown() and MerchantFrame_Update then MerchantFrame_Update() end
end
function M.Enable()
    if M.hooked then return end
    M.hooked=true
    if type(_G.MerchantFrame_UpdateMerchantInfo)=="function" then hooksecurefunc("MerchantFrame_UpdateMerchantInfo",M.MerchantInfo) end
    if type(_G.MerchantFrame_UpdateBuybackInfo)=="function" then hooksecurefunc("MerchantFrame_UpdateBuybackInfo",M.BuybackInfo) end
end
