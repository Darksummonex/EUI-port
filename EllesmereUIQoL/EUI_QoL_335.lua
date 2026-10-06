-- Native 3.3.5 tools. Retail files are retained as unloaded references.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
local addon=E.Lite.NewAddon(ADDON_NAME)
E._ModuleNS[ADDON_NAME]=ns
ns.addon,ns.EQOL,ns.IsWrath=addon,addon,true
local defaults={profile={enabled=true,autoRepair=false,guildRepair=false,autoSellJunk=false,quickLoot=false,
    trainAll=false,fillDelete=false,skipCinematics=false,hideErrors=false,hideTutorials=false,mailOpenAll=true,mailBulkAttach=true,
    hideScreenshot=false,autoOpen=false,resetAnnounce=false,resetMessage="",roleCheck=false,mapCoords=false,
    rightClickEnemy=false,rightClickAlly=false,hideTransforms=false,flyoutIlvl=false,
    fps=false,stats=false,coordinates=false,crosshair=false,durability=false,durabilityThreshold=40,
    combatAlert=false,deathAlert=false,bloodlust=false,battleRes=false,movement=false,movementSpellID=0,targetDistance=false,
    zoneText=true,hideBossModBars=true,
    fpsTextSize=12,statsTextSize=12,mapCoordsTextSize=12,combatAlertTextSize=22,groupDeathTextSize=26,
    durWarnTextSize=30,trackerTextSize=12,targetDistanceTextSize=18,crosshairSize=40,showReady=false,
    fpsWorld=false,fpsLocal=true,fpsLabels=true,fpsColorMode="custom",fpsColor={r=1,g=1,b=1},fpsInterval=1,fpsKey="",
    statsExtra=false,durabilityColor={r=1,g=.27,b=.27},
    combatAlertMode="both",combatEnterText="+Combat",combatLeaveText="-Combat",combatClassColor=false,
    combatEnterColor={r=1,g=1,b=1},combatLeaveColor={r=1,g=1,b=1},deathSound="none",
    crosshairThickness=2,crosshairColor={r=1,g=1,b=1,a=.75},crosshairBorder=0,crosshairBorderColor={r=0,g=0,b=0,a=1},
    crosshairVisibility="always",crosshairRange=false,crosshairRangeColor={r=1,g=0,b=0,a=1},targetDistanceFormat="range",
    trackerIconSize=30,movementCombatOnly=false,movementSound="none",
    cursor={enabled=false,size=36,combatOnly=false,classColor=false,trail=false,gcd=false,cast=false,texture="ring_normal",
        color={r=.05,g=.82,b=.62},opacity=100,instancesOnly=false,reticle=false},
    shifter={enabled=false,positions={}},raidTools={enabled=false,groupOnly=true,pullSeconds=10,pullSync=true,pullChat=true,scale=100},
    logging={enabled=false,raids=true,dungeons=false},positions={}}}
ns.defaults=defaults
local pending,merchant,merchantUntil,sellAttempts,trainerUntil,trainerAttempts=false,false,0,{},0,{}
local logOwned=false
local tutorialOriginal,errorOriginal,errorFilter
function ns.GetSettings() return addon.db and addon.db.profile end
function ns.Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
function ns.Font(fs,size)
    local path=(E.GetFontPath and E.GetFontPath("extras")) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local flags=((E.GetFontOutlineFlag and E.GetFontOutlineFlag("extras")) or "OUTLINE"):gsub(",?%s*SLUG","")
    if not fs:SetFont(path,math.max(8,tonumber(size) or 12),flags) then fs:SetFont("Fonts\\FRIZQT__.TTF",12,"OUTLINE") end
end
local function Enabled(key) local p=ns.GetSettings(); return p and p.enabled and p[key] end
ns.Enabled=Enabled
function ns.Print(text) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff0cd29fEllesmereUI:|r "..text) end end
function ns.Money(cost)
    local g,s,c=math.floor(cost/10000),math.floor(cost%10000/100),cost%100
    local out=(g>0 and g.."g" or "")
    if s>0 then out=out..(out~="" and " " or "")..s.."s" end
    if c>0 then out=out..(out~="" and " " or "")..c.."c" end
    return out~="" and out or "0c"
end
local function Repair()
    local p=ns.GetSettings()
    if not Enabled("autoRepair") or InCombatLockdown() or not CanMerchantRepair or not CanMerchantRepair() then return end
    local cost,needed=GetRepairAllCost(); if not needed or not cost or cost<=0 then return end
    if p.guildRepair and CanGuildBankRepair and CanGuildBankRepair() and GetGuildBankWithdrawMoney and GetGuildBankMoney then
        local limit=GetGuildBankWithdrawMoney()
        if (limit==-1 or (limit or 0)>=cost) and (GetGuildBankMoney() or 0)>=cost then
            RepairAllItems(true); ns.Print("Repaired all items for "..ns.Money(cost).." (guild bank)"); return
        end
    end
    if GetMoney()>=cost then RepairAllItems(false); ns.Print("Repaired all items for "..ns.Money(cost))
    else ns.Print("|cffff6060Not enough gold to repair.|r") end
end
local function JunkLeft()
    local left=0
    for key in pairs(sellAttempts) do
        local bag,slot,link=key:match("^(%-?%d+):(%d+):(.+)$")
        if bag and GetContainerItemLink(tonumber(bag),tonumber(slot))==link then left=left+1 end
    end
    return left
end
local function SellJunk()
    if not merchant or not Enabled("autoSellJunk") or InCombatLockdown() or (GetCursorInfo and GetCursorInfo()) then return end
    if GetTime()>merchantUntil then
        if not sellAttempts.reported then
            sellAttempts.reported=true; local left=JunkLeft()
            if left>0 then ns.Print(left.." junk item(s) could not be sold.") end
        end
        return
    end
    for bag=0,4 do for slot=1,GetContainerNumSlots(bag) do
        local link=GetContainerItemLink(bag,slot)
        if link then
            local _,_,locked,_,_,lootable=GetContainerItemInfo(bag,slot)
            local _,_,quality,_,_,_,_,_,_,_,price=GetItemInfo(link)
            local quest=false
            if GetContainerItemQuestInfo then local isQuest,questID=GetContainerItemQuestInfo(bag,slot); quest=isQuest or questID~=nil end
            local key=bag..":"..slot..":"..link
            if quality==0 and (price or 0)>0 and not locked and not lootable and not quest and not sellAttempts[key] then
                sellAttempts[key]=true; UseContainerItem(bag,slot); return
            end
        end
    end end
end
-- Retail: loot everything regardless of the Auto Loot setting; Shift shows the window.
local function QuickLoot()
    if not Enabled("quickLoot") or IsShiftKeyDown() then return end
    for i=GetNumLootItems(),1,-1 do
        local locked=GetLootSlotInfo and select(5,GetLootSlotInfo(i))
        if not locked then LootSlot(i) end
    end
end
-- Wrath reports free primary profession slots as the second character point value.
local function FreeProfessionSlots()
    if not UnitCharacterPoints then return 2 end
    local _,free=UnitCharacterPoints("player"); return tonumber(free) or 2
end
local function Affordable(i,wallet,slots)
    local _,_,kind=GetTrainerServiceInfo(i); if kind~="available" then return false end
    local cost,_,professionCost=GetTrainerServiceCost(i); cost=cost or math.huge
    if cost>wallet or ((professionCost or 0)>0 and slots<=0) then return false end
    return true,cost,(professionCost or 0)>0
end
function ns.TrainableSummary()
    if not GetNumTrainerServices then return 0,0 end
    local n,gold,wallet,slots=0,0,GetMoney(),FreeProfessionSlots()
    for i=1,GetNumTrainerServices() do local ok,cost=Affordable(i,wallet,slots); if ok then n=n+1; gold=gold+cost end end
    return n,gold
end
local function RefreshTrainButton()
    local b=ns.trainButton; if not b then return end
    if not Enabled("trainAll") then b:Hide(); return end
    b:Show(); if ns.TrainableSummary()>0 or trainerUntil>0 then b:Enable() else b:Disable() end
end
local function TrainStep()
    if trainerUntil==0 then return end
    if not Enabled("trainAll") or not ClassTrainerFrame or not ClassTrainerFrame:IsShown() or InCombatLockdown() or GetTime()>trainerUntil then trainerUntil=0; RefreshTrainButton(); return end
    local wallet,slots=GetMoney(),FreeProfessionSlots()
    for i=1,GetNumTrainerServices() do
        local name,rank=GetTrainerServiceInfo(i)
        local key=tostring(name)..":"..tostring(rank)
        if not trainerAttempts[key] and Affordable(i,wallet,slots) then trainerAttempts[key]=true; BuyTrainerService(i); return end
    end
    trainerUntil=0; RefreshTrainButton()
end
local function InstallTrainer()
    if not ClassTrainerFrame or ns.trainButton then return end
    local b=CreateFrame("Button","EUI335QoLTrainAll",ClassTrainerFrame,"UIPanelButtonTemplate"); ns.trainButton=b
    local native=_G.ClassTrainerTrainButton
    ns.Size(b,80,native and native:GetHeight() or 22)
    if native then b:SetPoint("RIGHT",native,"LEFT",-2,0) else b:SetPoint("TOPRIGHT",ClassTrainerFrame,"TOPRIGHT",-40,-40) end
    b:SetText("Train All")
    b:SetScript("OnClick",function() if not InCombatLockdown() and Enabled("trainAll") then trainerUntil=GetTime()+20; trainerAttempts={}; TrainStep() end end)
    b:SetScript("OnEnter",function(self)
        local n,gold=ns.TrainableSummary(); if n<=0 or not GameTooltip then return end
        GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(string.format(n==1 and "Learn %d skill for %s" or "Learn %d skills for %s",n,ns.Money(gold)),1,1,1); GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
    if hooksecurefunc and type(_G.ClassTrainerFrame_Update)=="function" then hooksecurefunc("ClassTrainerFrame_Update",RefreshTrainButton) end
end
local function InstallDelete()
    for i=1,4 do local f=_G["StaticPopup"..i]
        if f and not f._euiQoLDelete then
            f._euiQoLDelete=true; f:HookScript("OnShow",function(self)
                if Enabled("fillDelete") and (self.which=="DELETE_GOOD_ITEM" or self.which=="DELETE_GOOD_QUEST_ITEM") then
                    local edit=self.editBox or _G[(self:GetName() or "").."EditBox"]
                    if edit then edit:SetText(DELETE_ITEM_CONFIRM_STRING or "DELETE"); if edit.SetFocus then edit:SetFocus() end end
                end
            end)
        end
    end
end
-- Retail keeps these red errors visible while the rest are hidden.
local keepErrors
local function KeepError(message)
    if not keepErrors then
        keepErrors={}
        for _,name in ipairs({"ERR_INV_FULL","ERR_QUEST_LOG_FULL","ERR_RAID_GROUP_ONLY","ERR_PARTY_LFG_BOOT_LIMIT",
            "ERR_PARTY_LFG_BOOT_DUNGEON_COMPLETE","ERR_PARTY_LFG_BOOT_IN_COMBAT","ERR_PARTY_LFG_BOOT_IN_PROGRESS",
            "ERR_PARTY_LFG_BOOT_LOOT_ROLLS","ERR_PARTY_LFG_TELEPORT_IN_COMBAT","ERR_PET_SPELL_DEAD","ERR_PLAYER_DEAD",
            "SPELL_FAILED_TARGET_NO_POCKETS","ERR_ALREADY_PICKPOCKETED"}) do
            local text=_G[name]; if text then keepErrors[text]=true end
        end
    end
    return message and keepErrors[message]
end
function ns.UpdateLogging()
    if not LoggingCombat then return end
    local p=ns.GetSettings(); local inside,kind=IsInInstance()
    local desired=p and p.enabled and p.logging.enabled and inside and ((kind=="raid" and p.logging.raids) or (kind=="party" and p.logging.dungeons))
    if desired and not LoggingCombat() then LoggingCombat(true); logOwned=true
    elseif not desired and logOwned then LoggingCombat(false); logOwned=false end
end
function ns.Apply()
    local p=ns.GetSettings(); if not p then return end
    if ns.ApplyBossBars then ns.ApplyBossBars() end
    if InCombatLockdown() then pending=true; return end; pending=false
    InstallTrainer(); InstallDelete()
    if ns.trainButton and not Enabled("trainAll") then trainerUntil=0 end
    RefreshTrainButton()
    if UIErrorsFrame then
        if Enabled("hideErrors") then
            if not errorFilter then
                errorOriginal=UIErrorsFrame:GetScript("OnEvent")
                errorFilter=function(self,event,message,...)
                    if (event~="UI_ERROR_MESSAGE" or KeepError(message)) and errorOriginal then errorOriginal(self,event,message,...) end
                end
                UIErrorsFrame:SetScript("OnEvent",errorFilter)
            end
        elseif errorFilter then
            if UIErrorsFrame:GetScript("OnEvent")==errorFilter then UIErrorsFrame:SetScript("OnEvent",errorOriginal) end
            errorFilter,errorOriginal=nil,nil
        end
    end
    if Enabled("hideTutorials") then
        if tutorialOriginal==nil then tutorialOriginal=GetCVar("showTutorials") end
        SetCVar("showTutorials","0"); if TutorialFrame then TutorialFrame:Hide() end
    elseif tutorialOriginal~=nil then
        if GetCVar("showTutorials")=="0" then SetCVar("showTutorials",tutorialOriginal) end; tutorialOriginal=nil
    end
    if ns.ApplyDisplays then ns.ApplyDisplays() end
    if ns.ApplyPanels then ns.ApplyPanels() end
    if ns.ApplyMail then ns.ApplyMail() end
    if ns.ApplyExtras then ns.ApplyExtras() end
    ns.UpdateLogging()
end
function addon:OnInitialize()
    addon.db=E.Lite.NewDB("EllesmereUIQoLDB",defaults); ns.db=addon.db
    _G._EQOL_RefreshAll=ns.Apply
    E.QoLExtrasGet=function(key) local p=ns.GetSettings(); return p and p[key] end
    E.QoLExtrasSet=function(key,value) local p=ns.GetSettings(); if p then p[key]=value; ns.Apply() end end
    SLASH_EUI335QOL1="/eqol"; SLASH_EUI335QOL2="/qol"
    SlashCmdList.EUI335QOL=function() if InCombatLockdown() then return end; if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; E:ShowModule(ADDON_NAME) end
end
function addon:OnEnable()
    ns.Apply(); if ns.RegisterMovers then ns.RegisterMovers() end
    if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener(ADDON_NAME,function(active)
        ns.preview=active and true or false
        if ns.RegisterElementSettings then ns.RegisterElementSettings() end
        ns.Apply()
    end) end
    local f=CreateFrame("Frame"); ns.events=f
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","ADDON_LOADED","MERCHANT_SHOW","MERCHANT_CLOSED","LOOT_OPENED","TRAINER_CLOSED","CINEMATIC_START","PLAY_MOVIE","ZONE_CHANGED_NEW_AREA","UNIT_AURA"}) do f:RegisterEvent(event) end
    f:SetScript("OnEvent",function(_,event,unit)
        if event=="MERCHANT_SHOW" then merchant=true; merchantUntil=GetTime()+8; sellAttempts={}; Repair(); SellJunk()
        elseif event=="MERCHANT_CLOSED" then merchant=false
        elseif event=="LOOT_OPENED" then QuickLoot()
        elseif event=="TRAINER_CLOSED" then trainerUntil=0
        elseif event=="CINEMATIC_START" and Enabled("skipCinematics") then if CinematicFrame_CancelCinematic then CinematicFrame_CancelCinematic() end
        elseif event=="PLAY_MOVIE" and Enabled("skipCinematics") then if MovieFrame and MovieFrame.StopMovie then MovieFrame:StopMovie() end
        elseif event=="PLAYER_REGEN_DISABLED" then
            if ns.CancelEarlyPull then ns.CancelEarlyPull() end
            if ns.CombatAlert then ns.CombatAlert("enter") end
        elseif event=="PLAYER_REGEN_ENABLED" then if pending then ns.Apply() end; if ns.CombatAlert then ns.CombatAlert("leave") end
        elseif event=="PLAYER_ENTERING_WORLD" or event=="ADDON_LOADED" then
            -- Core's unlock-mode init seeds Retail page names for shared keys at login.
            if event=="PLAYER_ENTERING_WORLD" and ns.RegisterElementSettings then ns.RegisterElementSettings() end
            ns.Apply()
        elseif event=="ZONE_CHANGED_NEW_AREA" then ns.mapDirty=true; ns.UpdateLogging()
        elseif event=="UNIT_AURA" and unit=="player" and ns.UpdateDisplays then ns.UpdateDisplays() end
    end)
    local elapsed=0
    f:SetScript("OnUpdate",function(_,dt)
        if ns.UpdateCursor then ns.UpdateCursor(dt) end
        if ns.FinishMoving then ns.FinishMoving() end
        elapsed=elapsed+dt; if elapsed<.25 then return end; elapsed=0
        SellJunk(); TrainStep()
        if ns.UpdateDisplays then ns.UpdateDisplays() end
        if ns.UpdatePull then ns.UpdatePull() end
    end)
end
