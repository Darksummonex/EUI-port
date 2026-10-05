-- Inspect sheet details: slot item levels and enchants, the average item level
-- and docking beside the character window. Native inspect code stays in charge.
local _,ns=...
if not ns.IsWrath then return end
local E=EllesmereUI
for key,value in pairs({inspectShowItemLevel=true,inspectShowEnchants=true,inspectDock=true}) do ns.defaults[key]=value end
local I={}; ns.Inspect=I
table.insert(ns.extras,I)
local leftSlots={Head=1,Neck=2,Shoulder=3,Back=15,Chest=5,Shirt=4,Tabard=19,Wrist=9}
local rightSlots={Hands=10,Waist=6,Legs=7,Feet=8,Finger0=11,Finger1=12,Trinket0=13,Trinket1=14}
local bottomSlots={MainHand=16,SecondaryHand=17,Ranged=18}
local labels={}; I.labels=labels
local retries=0
local function Own(obj) ns.owned[obj]=true; return obj end
local function Active() return _G.InspectFrame and InspectFrame:IsShown() and InspectFrame.unit and UnitExists(InspectFrame.unit) end
local function Label(slot,side)
    local d=labels[slot]; if d then return d end
    local button=_G["Inspect"..slot.."Slot"]; if not button then return end
    d={button=button}
    d.level=Own(button:CreateFontString(nil,"OVERLAY")); ns.ApplyFont(d.level,10,"OUTLINE")
    d.level:SetPoint("BOTTOM",button,"BOTTOM",0,2)
    d.enchant=Own(button:CreateFontString(nil,"OVERLAY")); ns.ApplyFont(d.enchant,9,"OUTLINE")
    d.enchant:SetWidth(90); d.enchant:SetTextColor(.3,1,.3,1)
    if d.enchant.SetWordWrap then d.enchant:SetWordWrap(false) end
    if side=="left" then d.enchant:SetPoint("LEFT",button,"RIGHT",4,0); d.enchant:SetJustifyH("LEFT")
    elseif side=="right" then d.enchant:SetPoint("RIGHT",button,"LEFT",-4,0); d.enchant:SetJustifyH("RIGHT")
    else d.enchant:SetPoint("BOTTOM",button,"TOP",0,3); d.enchant:SetJustifyH("CENTER") end
    labels[slot]=d
    return d
end
function I.Refresh()
    if not Active() then return end
    local unit=InspectFrame.unit
    local Items=ns.Items
    local showLevel,showEnchant=ns.GetValue("inspectShowItemLevel")~=false,ns.GetValue("inspectShowEnchants")~=false
    local pending=false
    for _,group in ipairs({{leftSlots,"left"},{rightSlots,"right"},{bottomSlots,"bottom"}}) do
        for slot,id in pairs(group[1]) do
            local d=Label(slot,group[2])
            if d then
                local link=GetInventoryItemLink(unit,id)
                local level,quality
                if link then
                    local _,_,q,l=GetItemInfo(link); level,quality=l,q
                    if not level and id~=4 and id~=19 then pending=true end
                end
                if showLevel and level and id~=4 and id~=19 then
                    d.level:SetText(level); d.level:SetTextColor(Items.QualityColor(quality)); d.level:Show()
                else d.level:Hide() end
                local enchant=showEnchant and link and level and Items.EnchantText(link)
                if enchant then d.enchant:SetText(enchant); d.enchant:Show() else d.enchant:Hide() end
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
    if ns.GetValue("inspectShowItemLevel")==false and ns.GetValue("inspectShowEnchants")==false then
        for _,d in pairs(labels) do d.level:Hide(); d.enchant:Hide() end
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
