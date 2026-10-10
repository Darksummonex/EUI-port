-- Inspect sheet details: slot item levels and enchants, the average item level
-- and docking beside the character window. Native inspect code stays in charge.
local _,ns=...
if not ns.IsWrath then return end
local E=EllesmereUI
for key,value in pairs({inspectShowItemLevel=true,inspectShowEnchants=true,inspectEnchantNames=false,inspectEnchantSize=9,inspectMissingEnhancements=true,inspectDock=true}) do ns.defaults[key]=value end
local I={}; ns.Inspect=I
table.insert(ns.extras,I)
local leftSlots={Head=1,Neck=2,Shoulder=3,Back=15,Chest=5,Shirt=4,Tabard=19,Wrist=9}
local rightSlots={Hands=10,Waist=6,Legs=7,Feet=8,Finger0=11,Finger1=12,Trinket0=13,Trinket1=14}
local bottomSlots={MainHand=16,SecondaryHand=17,Ranged=18}
local labels={}; I.labels=labels
local retries=0
local function Own(obj) ns.owned[obj]=true; return obj end
local function Active() return _G.InspectFrame and InspectFrame:IsShown() and InspectFrame.unit and UnitExists(InspectFrame.unit) end
local ENCHANT_ICON="Interface\\Icons\\Trade_Engraving"
local ANCHORS={left={"LEFT","RIGHT",4,0,"LEFT"},right={"RIGHT","LEFT",-4,0,"RIGHT"},bottom={"BOTTOM","TOP",0,3,"CENTER"}}
local function EnchantTip(self)
    if not self.tip then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine(self.tip,.1,1,.1); GameTooltip:Show()
end
local function HideTip() GameTooltip:Hide() end
-- A name stops at 45% of the gap between the columns, clear of the model.
local function NameWidth()
    local lr=_G.InspectHeadSlot and InspectHeadSlot:GetRight()
    local rl=_G.InspectHandsSlot and InspectHandsSlot:GetLeft()
    if lr and rl and rl>lr then return math.floor((rl-lr)*.45) end
    return 90
end
local function Label(slot,side)
    local d=labels[slot]; if d then return d end
    local button=_G["Inspect"..slot.."Slot"]; if not button then return end
    d={button=button,anchor=ANCHORS[side] or ANCHORS.bottom}
    local a=d.anchor
    d.level=Own(button:CreateFontString(nil,"OVERLAY")); ns.ApplyFont(d.level,10,"OUTLINE")
    d.level:SetPoint("BOTTOM",button,"BOTTOM",0,2)
    d.enchant=Own(button:CreateFontString(nil,"OVERLAY")); ns.ApplyFont(d.enchant,9,"OUTLINE")
    if d.enchant.SetWordWrap then d.enchant:SetWordWrap(false) end
    d.enchant:SetPoint(a[1],button,a[2],a[3],a[4]); d.enchant:SetJustifyH(a[5])
    -- Icon mode draws the enchant icon here; both modes show the name on hover.
    d.hover=Own(CreateFrame("Frame",nil,button)); d.hover:EnableMouse(true); d.hover:Hide()
    d.hover.icon=Own(d.hover:CreateTexture(nil,"OVERLAY")); d.hover.icon:SetAllPoints(d.hover)
    d.hover.icon:SetTexture(ENCHANT_ICON); d.hover.icon:SetTexCoord(.08,.92,.08,.92)
    d.hover:SetScript("OnEnter",EnchantTip); d.hover:SetScript("OnLeave",HideTip)
    labels[slot]=d
    return d
end
local FLAT="Interface\\Buttons\\WHITE8X8"
local MAX_FLAGS=4
local function FlagTip(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(self.tip or "",1,.3,.3); GameTooltip:Show()
end
local function Flags(d)
    if d.flags then return d.flags end
    d.flags={}
    for i=1,MAX_FLAGS do
        local b=Own(CreateFrame("Frame",nil,d.button)); b:SetSize(14,14)
        b:SetBackdrop({bgFile=FLAT,edgeFile=FLAT,edgeSize=1})
        b:SetBackdropColor(0,0,0,.85); b:SetBackdropBorderColor(1,.2,.2,1)
        b.tex=Own(b:CreateTexture(nil,"ARTWORK"))
        b.tex:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.tex:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1)
        b:EnableMouse(true); b:SetScript("OnEnter",FlagTip); b:SetScript("OnLeave",HideTip)
        b:Hide(); d.flags[i]=b
    end
    return d.flags
end
-- One badge row beside the slot, as on the character sheet.
local function PlaceInRow(d,frame,index,count)
    local button,side=d.button,d.anchor[1]
    frame:ClearAllPoints()
    if side=="LEFT" then frame:SetPoint("BOTTOMLEFT",button,"BOTTOMRIGHT",4+index*16,2)
    elseif side=="RIGHT" then frame:SetPoint("BOTTOMRIGHT",button,"BOTTOMLEFT",-4-index*16,2)
    else frame:SetPoint("BOTTOMLEFT",button,"TOPLEFT",((button:GetWidth() or 37)-(count*16-2))/2+index*16,3) end
end
local function ShowEnchant(d,enchant,quality,miss)
    local hover,a=d.hover,d.anchor
    local nMiss=miss and math.min(#miss,MAX_FLAGS) or 0
    local names=enchant and ns.GetValue("inspectEnchantNames")
    local lead=(enchant and not names) and 1 or 0
    if not enchant then d.enchant:Hide(); hover:Hide(); hover.tip=nil
    else
        hover.tip=enchant; hover:ClearAllPoints()
        if names then
            local size=math.max(6,math.min(16,tonumber(ns.GetValue("inspectEnchantSize")) or 9))
            ns.ApplyFont(d.enchant,size,"OUTLINE")
            local r,g,b=ns.Items.QualityColor(quality)
            d.enchant:SetTextColor(r+(1-r)*.5,g+(1-g)*.5,b+(1-b)*.5,.9)
            d.enchant:SetWidth(NameWidth()); d.enchant:SetText(enchant)
            d.enchant:ClearAllPoints()
            local raise=nMiss>0 and (a[1]=="BOTTOM" and 17 or 8) or 0
            d.enchant:SetPoint(a[1],d.button,a[2],a[3],a[4]+raise); d.enchant:Show()
            hover.icon:Hide(); hover:SetAllPoints(d.enchant)
        else
            d.enchant:Hide()
            hover:SetSize(14,14); PlaceInRow(d,hover,0,lead+nMiss); hover.icon:Show()
        end
        hover:Show()
    end
    if nMiss==0 and not d.flags then return end
    local art,tips=ns.missingArt or {},ns.missingTips or {}
    for i,b in ipairs(Flags(d)) do
        local kind=i<=nMiss and miss[i]
        local look=kind and art[kind]
        if look then
            b.tex:SetTexture(look[1])
            if look[2] then b.tex:SetTexCoord(.08,.92,.08,.92) else b.tex:SetTexCoord(0,1,0,1) end
            local tip=E.L(tips[kind] or kind)
            if kind=="sockets" and (miss.sockets or 0)>1 then tip=tip.." x"..miss.sockets end
            b.tip=tip; PlaceInRow(d,b,lead+i-1,lead+nMiss); b:Show()
        else b:Hide() end
    end
end
function I.Refresh()
    if not Active() then return end
    local unit=InspectFrame.unit
    local Items=ns.Items
    local showLevel,showEnchant=ns.GetValue("inspectShowItemLevel")~=false,ns.GetValue("inspectShowEnchants")~=false
    local pending=false
    local ctx
    if ns.MissingFor and ns.GetValue("inspectMissingEnhancements")~=false and (UnitLevel(unit) or 0)>=(MAX_PLAYER_LEVEL or 80) then
        local _,classToken=UnitClass(unit)
        ctx={unit=unit,hunter=classToken=="HUNTER"}
    end
    for _,group in ipairs({{leftSlots,"left"},{rightSlots,"right"},{bottomSlots,"bottom"}}) do
        for slot,id in pairs(group[1]) do
            local d=Label(slot,group[2])
            if d then
                local link=GetInventoryItemLink(unit,id)
                local level,quality,equip
                if link then
                    local _,_,q,l,_,_,_,_,e=GetItemInfo(link); level,quality,equip=l,q,e
                    if not level and id~=4 and id~=19 then pending=true end
                end
                if showLevel and level and id~=4 and id~=19 then
                    d.level:SetText(level); d.level:SetTextColor(Items.QualityColor(quality)); d.level:Show()
                else d.level:Hide() end
                ShowEnchant(d,showEnchant and link and level and Items.EnchantText(link),quality,
                    ctx and link and level and ns.MissingFor(id,link,equip,ctx))
            end
        end
    end
    if not I.average then
        I.average=Own(InspectPaperDollFrame:CreateFontString(nil,"OVERLAY")); ns.ApplyFont(I.average,12,"OUTLINE")
        I.average:SetPoint("BOTTOM",_G.InspectModelFrame or InspectPaperDollFrame,"BOTTOM",0,6)
    end
    local avg,unknown=Items.Average(unit)
    if showLevel and avg>0 then
        I.average:SetText(string.format("%s |cffffffff%s|r",E.L("Item Level"),unknown and "..." or string.format("%.1f",avg)))
        I.average:SetTextColor(1,.82,0,1); I.average:Show()
    else I.average:Hide() end
    if pending or unknown then if retries<25 then retries=retries+1; I.retryAt=GetTime()+.3 end else I.retryAt=nil end
end
-- Docking: after the panel manager places both windows, the inspect window
-- moves against the character window's visible right edge if it fits on screen.
function I.Dock()
    if InCombatLockdown() or not Active() or not _G.CharacterFrame or not CharacterFrame:IsShown() then return end
    if ns.GetValue("inspectDock")==false then return end
    local s=ns.states[CharacterFrame]
    local inset=s and s.character and s.character.enhanced and 12 or 32
    local right=CharacterFrame:GetRight()
    local width=InspectFrame:GetWidth()
    if not right or not width then return end
    local scale=CharacterFrame:GetEffectiveScale()/InspectFrame:GetEffectiveScale()
    if (right-inset-11)*scale+width>UIParent:GetRight()*(UIParent:GetEffectiveScale()/InspectFrame:GetEffectiveScale()) then return end
    InspectFrame:ClearAllPoints()
    InspectFrame:SetPoint("TOPLEFT",CharacterFrame,"TOPRIGHT",-inset-11+4,0)
end
local function Hook()
    if I.hooked or not _G.InspectFrame then return end
    I.hooked=true
    if type(_G.InspectPaperDollItemSlotButton_Update)=="function" then hooksecurefunc("InspectPaperDollItemSlotButton_Update",function() I.dirty=true end) end
    InspectFrame:HookScript("OnShow",function() retries=0; I.dirty=true; I.Dock() end)
    if type(_G.UpdateUIPanelPositions)=="function" then hooksecurefunc("UpdateUIPanelPositions",I.Dock) end
end
function I.Apply()
    Hook()
    if not Active() then return end
    if ns.GetValue("inspectShowItemLevel")==false and ns.GetValue("inspectShowEnchants")==false and ns.GetValue("inspectMissingEnhancements")==false then
        for _,d in pairs(labels) do
            d.level:Hide(); d.enchant:Hide(); d.hover:Hide()
            for _,b in ipairs(d.flags or {}) do b:Hide() end
        end
        if I.average then I.average:Hide() end
        return
    end
    I.Refresh()
end
function I.Enable()
    local f=CreateFrame("Frame"); I.events=f
    for _,event in ipairs({"ADDON_LOADED","INSPECT_TALENT_READY","UNIT_INVENTORY_CHANGED"}) do f:RegisterEvent(event) end
    f:SetScript("OnEvent",function(_,event,arg)
        if event=="ADDON_LOADED" then if arg=="Blizzard_InspectUI" then Hook() end
        elseif event=="UNIT_INVENTORY_CHANGED" then if Active() and UnitIsUnit(arg,InspectFrame.unit) then retries=0; I.dirty=true end
        else retries=0; I.dirty=true end
    end)
    f:SetScript("OnUpdate",function()
        if I.dirty or I.retryAt and GetTime()>=I.retryAt then I.dirty=false; I.retryAt=nil; I.Apply() end
    end)
    Hook()
end
