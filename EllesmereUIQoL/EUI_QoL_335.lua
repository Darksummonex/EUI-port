-- Native 3.3.5 tools. Retail files are retained as unloaded references.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
local addon=E.Lite.NewAddon(ADDON_NAME)
E._ModuleNS[ADDON_NAME]=ns
ns.addon,ns.EQOL,ns.IsWrath=addon,addon,true
local defaults={profile={enabled=true,autoRepair=false,guildRepair=false,autoSellJunk=false,quickLoot=false,
    trainAll=false,fillDelete=false,skipCinematics=false,hideErrors=false,hideTutorials=false,
    fps=false,stats=false,coordinates=false,crosshair=false,durability=false,durabilityThreshold=40,
    combatAlert=false,deathAlert=false,bloodlust=false,battleRes=false,movement=false,movementSpellID=0,
    fpsTextSize=12,statsTextSize=12,mapCoordsTextSize=12,combatAlertTextSize=22,groupDeathTextSize=26,
    durWarnTextSize=22,trackerTextSize=12,crosshairSize=14,showReady=false,
    cursor={enabled=false,size=36,combatOnly=false,classColor=false,trail=false,gcd=false,cast=false,texture="ring_normal"},
    shifter={enabled=false,positions={}},raidTools={enabled=false,groupOnly=true,pullSeconds=10,pullSync=true,pullChat=true},
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
local function Repair()
    local p=ns.GetSettings()
    if not Enabled("autoRepair") or InCombatLockdown() or not CanMerchantRepair or not CanMerchantRepair() then return end
    local cost,needed=GetRepairAllCost(); if not needed or not cost or cost<=0 then return end
    if p.guildRepair and CanGuildBankRepair and CanGuildBankRepair() and GetGuildBankWithdrawMoney and GetGuildBankMoney then
        local limit=GetGuildBankWithdrawMoney()
        if (limit==-1 or (limit or 0)>=cost) and (GetGuildBankMoney() or 0)>=cost then RepairAllItems(true); return end
    end
    if GetMoney()>=cost then RepairAllItems(false) end
end
local function SellJunk()
    if not merchant or not Enabled("autoSellJunk") or InCombatLockdown() or (GetCursorInfo and GetCursorInfo()) or GetTime()>merchantUntil then return end
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
local function QuickLoot()
    if not Enabled("quickLoot") then return end
    local auto=GetCVar("autoLootDefault")=="1"
    if IsModifiedClick and IsModifiedClick("AUTOLOOTTOGGLE") then auto=not auto end
    if auto then for i=GetNumLootItems(),1,-1 do LootSlot(i) end end
end
local function TrainStep()
    if trainerUntil==0 then return end
    if not Enabled("trainAll") or not ClassTrainerFrame or not ClassTrainerFrame:IsShown() or InCombatLockdown() or GetTime()>trainerUntil then trainerUntil=0; return end
    for i=1,GetNumTrainerServices() do
        local name,rank,kind=GetTrainerServiceInfo(i)
        local key=tostring(name)..":"..tostring(rank)
        if kind=="available" and not trainerAttempts[key] then
            if (GetTrainerServiceCost(i) or math.huge)>GetMoney() then trainerUntil=0; return end
            trainerAttempts[key]=true; BuyTrainerService(i); return
        end
    end
    trainerUntil=0
end
local function InstallTrainer()
    if not ClassTrainerFrame or ns.trainButton then return end
    local b=CreateFrame("Button",nil,ClassTrainerFrame,"UIPanelButtonTemplate"); ns.trainButton=b
    ns.Size(b,85,22); b:SetPoint("TOPRIGHT",ClassTrainerFrame,"TOPRIGHT",-40,-40); b:SetText("Train All")
    b:SetScript("OnClick",function() if not InCombatLockdown() and Enabled("trainAll") then trainerUntil=GetTime()+20; trainerAttempts={}; TrainStep() end end)
end
local function InstallDelete()
    for i=1,4 do local f=_G["StaticPopup"..i]
        if f and not f._euiQoLDelete then
            f._euiQoLDelete=true; f:HookScript("OnShow",function(self)
                if Enabled("fillDelete") and (self.which=="DELETE_GOOD_ITEM" or self.which=="DELETE_GOOD_QUEST_ITEM") then
                    local edit=self.editBox or _G[(self:GetName() or "").."EditBox"]
                    if edit then edit:SetText(DELETE_ITEM_CONFIRM_STRING or "DELETE") end
                end
            end)
        end
    end
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
    if InCombatLockdown() then pending=true; return end; pending=false
    InstallTrainer(); InstallDelete()
    if ns.trainButton then if Enabled("trainAll") then ns.trainButton:Show() else ns.trainButton:Hide(); trainerUntil=0 end end
    if UIErrorsFrame then
        if Enabled("hideErrors") then
            if not errorFilter then
                errorOriginal=UIErrorsFrame:GetScript("OnEvent")
                errorFilter=function(self,event,...)
                    if event~="UI_ERROR_MESSAGE" and errorOriginal then errorOriginal(self,event,...) end
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
    if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener(ADDON_NAME,function(active) ns.preview=active and true or false; ns.Apply() end) end
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
            if ns.Alert then ns.Alert("combatAlert","Combat",1,.3,.2) end
        elseif event=="PLAYER_REGEN_ENABLED" then if pending then ns.Apply() end; if ns.Alert then ns.Alert("combatAlert","Combat ended",.1,.85,.65) end
        elseif event=="PLAYER_ENTERING_WORLD" or event=="ADDON_LOADED" then ns.Apply()
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
