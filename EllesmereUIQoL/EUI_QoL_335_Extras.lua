-- Native 3.3.5 ports of Retail QoL extras: screenshot status, container opening,
-- reset announce, role check, world map coordinates, right-click guard, rested
-- indicator, transform cancelling, flyout item levels and the FPS keybind.
local _,ns=...
local E=EllesmereUI
if not ns.addon then return end
local Enabled=ns.Enabled
local white="Interface\\Buttons\\WHITE8X8"
local events=CreateFrame("Frame"); ns.extraEvents=events
local driver=CreateFrame("Frame"); ns.extraDriver=driver; driver:Hide()
local state={}
ns.interaction=state

local function HideActionStatus() local a=_G.ActionStatus; if a and a.Hide then a:Hide() end end

-- UseContainerItem sells, deposits, attaches or trades while these windows are
-- open, so container opening waits until every one of them has closed.
local INTERACTION={
    MERCHANT_SHOW={"merchant",true},MERCHANT_CLOSED={"merchant",false},MAIL_SHOW={"mail",true},MAIL_CLOSED={"mail",false},
    BANKFRAME_OPENED={"bank",true},BANKFRAME_CLOSED={"bank",false},TRADE_SHOW={"trade",true},TRADE_CLOSED={"trade",false},
    AUCTION_HOUSE_SHOW={"auction",true},AUCTION_HOUSE_CLOSED={"auction",false},GUILDBANKFRAME_OPENED={"guildbank",true},
    GUILDBANKFRAME_CLOSED={"guildbank",false},LOOT_OPENED={"loot",true},LOOT_CLOSED={"loot",false},
}
local openable,failed,pendingOpen,nextOpen={}, {}, nil, 0
local scan
local function Openable(bag,slot,id)
    if openable[id]~=nil then return openable[id] end
    scan=scan or _G.EUI335QoLOpenScan or CreateFrame("GameTooltip","EUI335QoLOpenScan",nil,"GameTooltipTemplate")
    scan:SetOwner(UIParent,"ANCHOR_NONE"); scan:ClearLines(); scan:SetBagItem(bag,slot)
    local lines,result=scan:NumLines() or 0,false
    for i=1,lines do local line=_G["EUI335QoLOpenScanTextLeft"..i]; if line and line:GetText()==ITEM_OPENABLE then result=true; break end end
    if lines>0 then openable[id]=result end
    return result
end
local function Busy()
    for key,open in pairs(state) do if open==true and key~="settle" then return true end end
    return InCombatLockdown() or GetTime()<(state.settle or 0) or (GetCursorInfo and GetCursorInfo()) or (SpellIsTargeting and SpellIsTargeting())
        or UnitCastingInfo("player") or UnitChannelInfo("player") or (MerchantFrame and MerchantFrame:IsShown())
end
function ns.AutoOpenStep()
    if not Enabled("autoOpen") then pendingOpen=nil; return end
    local now=GetTime()
    if pendingOpen then
        if now<pendingOpen.check or state.loot then return end
        local _,count,locked=GetContainerItemInfo(pendingOpen.bag,pendingOpen.slot)
        -- Unchanged and unlocked after the open settled: bags full or not openable here.
        if GetContainerItemLink(pendingOpen.bag,pendingOpen.slot)==pendingOpen.link and (count or 1)>=pendingOpen.count and not locked then failed[pendingOpen.id]=true end
        pendingOpen=nil; nextOpen=now+.3; ns.openDirty=true
    end
    if not ns.openDirty or now<nextOpen or Busy() then return end
    for bag=0,NUM_BAG_SLOTS or 4 do for slot=1,GetContainerNumSlots(bag) do
        local link=GetContainerItemLink(bag,slot); local id=link and tonumber(link:match("item:(%d+)"))
        if id and not failed[id] then
            local _,count,locked=GetContainerItemInfo(bag,slot)
            if not locked and Openable(bag,slot,id) then
                pendingOpen={bag=bag,slot=slot,id=id,link=link,count=count or 1,check=now+.6}
                UseContainerItem(bag,slot); return
            end
        end
    end end
    ns.openDirty=false
end

local RESET_FALLBACK={"has been reset","wurde zur","a été réinitialisé","ha sido reiniciada","è stato resettato","foi reiniciada","сброшен"}
local FAIL_FALLBACK={"players still","noch spieler","joueurs sont encore","jugadores todavía","giocatori sono ancora","jogadores ainda","игроки ещё"}
local function Pattern(fmt)
    if type(fmt)~="string" then return end
    return "^"..fmt:gsub("([%^%$%(%)%.%[%]%*%+%-%?])","%%%1"):gsub("%%s",".+"):gsub("%%d","%%d+").."$"
end
local function Matches(msg,global,fallback)
    local pattern=Pattern(global); if pattern and msg:find(pattern) then return true end
    local lower=msg:lower()
    for _,text in ipairs(fallback) do if lower:find(text,1,true) then return true end end
end
local lastReset=0
function ns.ResetAnnounce(msg)
    if not Enabled("resetAnnounce") or type(msg)~="string" then return end
    local channel=GetNumRaidMembers()>0 and "RAID" or GetNumPartyMembers()>0 and "PARTY"
    if not channel or GetTime()-lastReset<2 then return end
    local text
    if Matches(msg,INSTANCE_RESET_SUCCESS,RESET_FALLBACK) then
        local custom=ns.GetSettings().resetMessage
        text=(custom and custom~="") and custom or "Instance has been reset - you can re-enter now!"
    elseif Matches(msg,INSTANCE_RESET_FAILED,FAIL_FALLBACK) then text="Reset failed - there are still players inside the instance." end
    if text then lastReset=GetTime(); SendChatMessage("[EUI] "..text,channel) end
end

local function AcceptRoleCheck()
    local popup,button=_G.LFDRoleCheckPopup,_G.LFDRoleCheckPopupAcceptButton
    if Enabled("roleCheck") and popup and popup:IsShown() and button and button:IsEnabled() then button:Click() end
end

function ns.UpdateMapCoords(f)
    local px,py=GetPlayerMapPosition("player")
    if px and py and px>0 and py>0 then f.player:SetText(string.format("P: %.0f, %.0f",px*100,py*100)); f.player:Show(); f.divider:Show()
    else f.player:Hide(); f.divider:Hide() end
    local text,d="0, 0",f:GetParent()
    local left,top,w,h=d:GetLeft(),d:GetTop(),d:GetWidth(),d:GetHeight()
    if left and top and w and w>0 and h and h>0 then
        local s=d:GetEffectiveScale(); local cx,cy=GetCursorPosition(); local nx,ny=(cx/s-left)/w,(top-cy/s)/h
        if nx>=0 and nx<=1 and ny>=0 and ny<=1 then text=string.format("%.0f, %.0f",nx*100,ny*100) end
    end
    f.cursor:SetText("C: "..text)
end
local function MapCoordFrame()
    if ns.mapCoordFrame then return ns.mapCoordFrame end
    local parent=_G.WorldMapDetailFrame or _G.WorldMapFrame; if not parent then return end
    local f=CreateFrame("Frame","EUI335QoLWorldMapCoords",parent); ns.mapCoordFrame=f
    f:SetFrameLevel((parent:GetFrameLevel() or 1)+20); ns.Size(f,1,1); f:SetPoint("BOTTOM",parent,"BOTTOM",0,10)
    f.divider=f:CreateTexture(nil,"OVERLAY"); f.divider:SetTexture(white); f.divider:SetVertexColor(1,1,1,.9); f.divider:SetPoint("BOTTOM",f,"BOTTOM",0,0)
    f.cursor=f:CreateFontString(nil,"OVERLAY"); f.cursor:SetPoint("RIGHT",f.divider,"LEFT",-10,0)
    f.player=f:CreateFontString(nil,"OVERLAY"); f.player:SetPoint("LEFT",f.divider,"RIGHT",10,0)
    f.elapsed=0
    f:SetScript("OnUpdate",function(self,dt) self.elapsed=self.elapsed+(dt or 0); if self.elapsed<.05 then return end; self.elapsed=0; ns.UpdateMapCoords(self) end)
    return f
end

local function SetupRightClick()
    if ns.rcState then return ns.rcState end
    local guard=CreateFrame("Frame"); guard:Hide(); ns.rcGuard=guard
    guard:SetScript("OnUpdate",function(self) if not IsMouseButtonDown("RightButton") then self:Hide(); if IsMouselooking() then MouselookStop() end end end)
    local look=CreateFrame("Button","EUI335QoLMouseLook",UIParent); look:RegisterForClicks("AnyDown","AnyUp")
    look:SetScript("OnClick",function(_,_,down)
        if down==false then guard:Hide(); if IsMouselooking() then MouselookStop() end; return end
        MouselookStart(); guard:Show()
    end)
    local s=CreateFrame("Frame","EUI335QoLRightClickGuard",UIParent,"SecureHandlerStateTemplate"); ns.rcState=s
    s:SetAttribute("_onstate-rclick",[[
        if newstate == "1" or newstate == 1 then self:SetBindingClick(true, "BUTTON2", "EUI335QoLMouseLook") else self:ClearBindings() end
    ]])
    return s
end
local function ApplyRightClick()
    local macro=""
    if Enabled("rightClickEnemy") then macro=macro.."[target=mouseover,harm,nodead]1;" end
    if Enabled("rightClickAlly") then macro=macro.."[target=mouseover,help,nodead,combat]1;" end
    if macro==(ns.rcMacro or "") then return end
    ns.rcMacro=macro
    if macro~="" then
        local s=SetupRightClick()
        if SecureStateDriverManager then SecureStateDriverManager:RegisterEvent("UPDATE_MOUSEOVER_UNIT") end
        RegisterStateDriver(s,"rclick",macro.."0")
    elseif ns.rcState then
        UnregisterStateDriver(ns.rcState,"rclick"); ns.rcState:SetAttribute("state-rclick","0"); ClearOverrideBindings(ns.rcState)
    end
end

function ns.ApplyRested()
    local pf=_G.EllesmereUIUnitFrames_Player; local t=pf and pf._restIndicator; if not t then return end
    local db=EllesmereUIDB or {}
    if pf.Health then t:ClearAllPoints(); t:SetPoint("TOPLEFT",pf.Health,"TOPLEFT",3+(db.restedIndicatorXOffset or 0),-2+(db.restedIndicatorYOffset or 0)) end
    if db.showRestedIndicator==true and IsResting() then t:Show() else t:Hide() end
end

-- Retail's transform auras that exist in Wrath: Hallow's End wands and lantern,
-- Noblegarden bunny, Pilgrim's turkey and Noggenfogger.
local TRANSFORMS={[44212]=true,[24732]=true,[24735]=true,[24736]=true,[24712]=true,[24713]=true,[24710]=true,[24711]=true,
    [24708]=true,[24709]=true,[24723]=true,[24740]=true,[61734]=true,[61716]=true,[61781]=true,[16593]=true,[16595]=true}
ns.transformAuras=TRANSFORMS
function ns.CancelTransforms()
    if not Enabled("hideTransforms") or not CancelUnitBuff or InCombatLockdown() or UnitAffectingCombat("player") then return end
    for i=40,1,-1 do
        local name,_,_,_,_,_,_,_,_,_,id=UnitAura("player",i,"HELPFUL")
        if name and TRANSFORMS[id] then CancelUnitBuff("player",i,"HELPFUL") end
    end
end

local flyoutText=setmetatable({}, {__mode="k"})
local function FlyoutLink(button)
    local location=button.location
    if type(location)~="number" or location<0 or not EquipmentManager_UnpackLocation then return end
    if EQUIPMENTFLYOUT_FIRST_SPECIAL_LOCATION and location>=EQUIPMENTFLYOUT_FIRST_SPECIAL_LOCATION then return end
    local player,bank,bags,slot,bag=EquipmentManager_UnpackLocation(location)
    if bags then return bag and slot and GetContainerItemLink(bag,slot) end
    if (player or bank) and slot then return GetInventoryItemLink("player",slot) end
end
function ns.RefreshFlyout()
    local flyout=_G.EquipmentFlyoutFrame; if not flyout or not flyout.buttons then return end
    for _,button in ipairs(flyout.buttons) do
        local fs,link,quality,level=flyoutText[button]
        if Enabled("flyoutIlvl") and button:IsShown() then link=FlyoutLink(button) end
        if link then _,_,quality,level=GetItemInfo(link) end
        if level and level>0 then
            if not fs then fs=button:CreateFontString(nil,"OVERLAY"); fs:SetPoint("TOP",button,"TOP",0,-2); flyoutText[button]=fs end
            ns.Font(fs,12); fs:SetText(level)
            local c=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]; fs:SetTextColor(c and c.r or 1,c and c.g or 1,c and c.b or 1)
        elseif fs then fs:SetText("") end
    end
end

local fpsButton=CreateFrame("Button","EUI335QoLFPSToggle",UIParent)
fpsButton:SetScript("OnClick",function()
    local p=ns.GetSettings(); if not p then return end
    p.fps=not p.fps
    if InCombatLockdown() then ns.UpdateDisplays() else ns.Apply() end
end)
local function ApplyFPSKey(p)
    local key=p.enabled and type(p.fpsKey)=="string" and p.fpsKey:upper():gsub("%s","") or ""
    if not key:find("^[%w%-]+$") then key="" end
    if key==(ns.fpsKeyBound or "") then return end
    ClearOverrideBindings(fpsButton); ns.fpsKeyBound=key
    if key~="" then SetOverrideBindingClick(fpsButton,true,key,"EUI335QoLFPSToggle") end
end

function ns.ExtrasStep()
    if ns.hideStatusNext then ns.hideStatusNext=false; HideActionStatus() end
    if ns.roleCheckAt and GetTime()>=ns.roleCheckAt then ns.roleCheckAt=nil; AcceptRoleCheck() end
    ns.AutoOpenStep()
    if not ns.hideStatusNext and not ns.roleCheckAt and not (Enabled("autoOpen") and (ns.openDirty or pendingOpen)) then driver:Hide() end
end
driver:SetScript("OnUpdate",ns.ExtrasStep)
for event in pairs(INTERACTION) do events:RegisterEvent(event) end
for _,event in ipairs({"SCREENSHOT_SUCCEEDED","SCREENSHOT_FAILED","PLAYER_REGEN_ENABLED","SPELLS_CHANGED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event,arg1)
    local flag=INTERACTION[event]
    if flag then
        state[flag[1]]=flag[2]
        if not flag[2] then state.settle=GetTime()+.5; ns.openDirty=true end
        if event=="LOOT_CLOSED" and pendingOpen then pendingOpen.check=GetTime()+.5 end
    elseif event=="BAG_UPDATE" then ns.openDirty=true
    elseif event=="SCREENSHOT_SUCCEEDED" or event=="SCREENSHOT_FAILED" then
        if not Enabled("hideScreenshot") then return end
        HideActionStatus(); ns.hideStatusNext=true
    elseif event=="CHAT_MSG_SYSTEM" then ns.ResetAnnounce(arg1); return
    elseif event=="LFG_ROLE_CHECK_SHOW" then
        if not Enabled("roleCheck") or IsShiftKeyDown() then return end
        ns.roleCheckAt=GetTime()+.1
    elseif event=="UNIT_AURA" then if arg1=="player" then ns.CancelTransforms() end; return
    elseif event=="PLAYER_REGEN_ENABLED" then ns.CancelTransforms(); ns.openDirty=true
    elseif event=="SPELLS_CHANGED" then ns.rangeSpells=nil; return end
    if ns.hideStatusNext or ns.roleCheckAt or (Enabled("autoOpen") and (ns.openDirty or pendingOpen)) then driver:Show() end
end)

function ns.ApplyExtras()
    local p=ns.GetSettings(); if not p then return end
    local function Watch(event,on) if on then events:RegisterEvent(event) else events:UnregisterEvent(event) end end
    Watch("CHAT_MSG_SYSTEM",Enabled("resetAnnounce")); Watch("BAG_UPDATE",Enabled("autoOpen"))
    Watch("UNIT_AURA",Enabled("hideTransforms")); Watch("LFG_ROLE_CHECK_SHOW",Enabled("roleCheck"))
    if Enabled("autoOpen") then ns.openDirty=true; driver:Show() else pendingOpen=nil end
    local coords=Enabled("mapCoords") and MapCoordFrame() or ns.mapCoordFrame
    if coords then
        if Enabled("mapCoords") then
            local size=tonumber(p.mapCoordsTextSize) or 12
            ns.Font(coords.cursor,size); ns.Font(coords.player,size); ns.Size(coords.divider,2,size); coords:Show()
        else coords:Hide() end
    end
    ApplyRightClick(); ns.ApplyRested(); ns.CancelTransforms(); ApplyFPSKey(p)
    if Enabled("flyoutIlvl") and not ns.flyoutHooked and hooksecurefunc then
        local name=type(_G.EquipmentFlyout_UpdateItems)=="function" and "EquipmentFlyout_UpdateItems" or type(_G.EquipmentFlyout_DisplayButton)=="function" and "EquipmentFlyout_DisplayButton"
        if name then ns.flyoutHooked=true; hooksecurefunc(name,ns.RefreshFlyout) end
    end
    ns.RefreshFlyout()
end
