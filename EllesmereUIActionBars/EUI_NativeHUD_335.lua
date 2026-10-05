-- Wrath HUD: native menu/bag actions and aura buttons; independent data bars.
local _,ns=...
local E=EllesmereUI
if not ns.IsWrath then return end
local H={holders={},states={},dirty=true}
ns.NativeHUD=H
local flat="Interface\\Buttons\\WHITE8X8"
-- Bundled from the installed ElvUI Norm texture; ElvUI itself is not required.
local dataTexture="Interface\\AddOns\\EllesmereUIActionBars\\Media\\Textures_335\\elvui-norm.tga"
local definitions={
    {key="micro",label="Micro Menu",group="Action Bars",point="BOTTOMRIGHT",x=-10,y=10},
    {key="bags",label="Bag Bar",group="Action Bars",point="BOTTOMRIGHT",x=-10,y=48},
    {key="xp",label="Experience Bar",group="Data Bars",point="BOTTOM",x=0,y=16},
    {key="reputation",label="Reputation Bar",group="Data Bars",point="BOTTOM",x=0,y=36},
    {key="buffs",label="Player Buffs",group="Player Auras",point="TOPRIGHT",x=-200,y=-15},
    {key="debuffs",label="Player Debuffs",group="Player Auras",point="TOPRIGHT",x=-200,y=-110},
}
H.definitions=definitions
local micros={
    {"CharacterMicroButton","INV_Misc_Head_Human_01"},{"SpellbookMicroButton","INV_Misc_Book_09"},
    {"TalentMicroButton","Ability_Marksmanship"},{"AchievementMicroButton","Achievement_Level_80"},
    {"QuestLogMicroButton","INV_Misc_Note_01"},{"ParagonMicroButton","INV_Misc_Coin_01"},{"SocialsMicroButton","INV_Misc_GroupNeedMore"},
    {"PVPMicroButton","INV_BannerPVP_01"},{"LFDMicroButton","INV_Helmet_08"},
    {"CollectionsMicroButton","INV_Misc_Bag_10"},{"StoreMicroButton","INV_Misc_Coin_01"},
    {"MainMenuMicroButton","INV_Misc_Gear_01"},{"HelpMicroButton","INV_Misc_QuestionMark"},
}
local function Settings() local p=ns.GetSettings(); return p and p.nativeHUD,p end
local function Enabled(key) local p,r=Settings(); return r and r.enabled and p and p[key]~=false end
local function ProgressInDataBars(key)
    local bars=E._ModuleNS and E._ModuleNS.EllesmereUIDataBars
    return bars and bars.ProgressUsed and bars.ProgressUsed(key)
end
local function Clamp(v,a,b) return math.max(a,math.min(b,tonumber(v) or a)) end
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function State(key)
    if not H.states[key] then H.states[key]={frames={},textures={},fonts={},buttons={},owned={}} end
    return H.states[key]
end
local function Remember(s,f)
    if not f or s.frames[f] then return end
    local points={}; for i=1,f:GetNumPoints() do points[i]={f:GetPoint(i)} end
    s.frames[f]={points=points,parent=f:GetParent(),w=f:GetWidth(),h=f:GetHeight(),scale=f.GetScale and f:GetScale(),
        alpha=f:GetAlpha(),mouse=f.IsMouseEnabled and f:IsMouseEnabled(),hitRect=f.GetHitRectInsets and {f:GetHitRectInsets()}}
end
local function Texture(s,t,clear)
    if not t or s.owned[t] then return end
    if not s.textures[t] then s.textures[t]={path=t:GetTexture(),alpha=t:GetAlpha(),coords={t:GetTexCoord()}} end
    if clear then s.textures[t].clear=true; t:SetTexture(nil); t:SetAlpha(0) end
end
local function Restore(key)
    local s=State(key); if not s.active then return end; s.active=false
    for f,d in pairs(s.frames) do
        f:SetParent(d.parent); f:ClearAllPoints(); for _,point in ipairs(d.points) do f:SetPoint(unpack(point)) end
        Size(f,d.w,d.h); if d.scale~=nil and f.SetScale then f:SetScale(d.scale) end; f:SetAlpha(d.alpha)
        if d.mouse~=nil then f:EnableMouse(d.mouse) end
        if d.hitRect and #d.hitRect==4 then f:SetHitRectInsets(unpack(d.hitRect)) end
    end
    for t,d in pairs(s.textures) do
        if d.clear then t:SetTexture(d.path) end
        t:SetAlpha(d.alpha); t:SetTexCoord(unpack(d.coords))
    end
    for fs,d in pairs(s.fonts) do fs:SetFont(unpack(d)) end
    for _,d in pairs(s.buttons) do d.panel:Hide(); if d.icon then d.icon:Hide() end end
    local f=H.holders[key]
    if f and f~=BuffFrame and f~=_G.DebuffFrame then f:Hide() end
end
local function Panel(parent)
    local f=CreateFrame("Frame",nil,parent); f:EnableMouse(false); f:SetAllPoints(parent)
    f:SetFrameLevel(math.max(0,parent:GetFrameLevel()-1))
    f:SetBackdrop({bgFile=flat,edgeFile=flat,edgeSize=1})
    f:SetBackdropColor(.045,.045,.045,.98); f:SetBackdropBorderColor(.2,.2,.2,1); return f
end
local function Holder(d)
    local f=H.holders[d.key]; if f then return f end
    f=CreateFrame("Frame","EUI335_HUD_"..d.key,UIParent)
    H.holders[d.key]=f; Size(f,240,32)
    return f
end
local function Position(d,f)
    local p=ns.GetSettings(); local pos=p and p.barPositions["hud_"..d.key]
    f:ClearAllPoints()
    if pos then f:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y)
    else f:SetPoint(d.point,UIParent,d.point,d.x,d.y) end
end
local function Button(s,b,iconPath,micro)
    Remember(s,b)
    local d=s.buttons[b]
    if not d then
        d={panel=Panel(b)}; s.buttons[b]=d
        if micro then
            d.icon=b:CreateTexture(nil,"ARTWORK"); s.owned[d.icon]=true
            d.icon:SetPoint("TOPLEFT",b,"TOPLEFT",3,-3); d.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-3,3)
            d.icon:SetTexCoord(.07,.93,.07,.93)
        end
        b:HookScript("OnEnter",function() if s.active then d.hover=true; d.panel:SetBackdropBorderColor(.047,.824,.616,1) end end)
        b:HookScript("OnLeave",function() d.hover=false; H.dirty=true end)
        b:HookScript("OnShow",function() H.dirty=true end)
    end
    local name=b:GetName() or ""
    local icon=not micro and (b.icon or _G[name.."IconTexture"])
    if micro then
        local source=_G[name.."Icon"] or _G[name.."IconTexture"]
        local sourcePath=source and (source:GetTexture() or s.textures[source] and s.textures[source].path)
        local sourceCoords=source and (s.textures[source] and s.textures[source].coords or {source:GetTexCoord()})
        for _,region in ipairs({b:GetRegions()}) do if region.GetObjectType and region:GetObjectType()=="Texture" then Texture(s,region,true) end end
        for _,suffix in ipairs({"Portrait","Background","BackgroundTexture"}) do Texture(s,_G[name..suffix],true) end
        d.icon:SetTexture("Interface\\Icons\\"..iconPath)
        if sourcePath then d.icon:SetTexture(sourcePath); d.icon:SetTexCoord(unpack(sourceCoords)) end
        if name=="CharacterMicroButton" and SetPortraitTexture then SetPortraitTexture(d.icon,"player") end
        d.icon:SetDesaturated(b.IsEnabled and not b:IsEnabled() or false); d.icon:Show()
    else
        for _,getter in ipairs({"GetNormalTexture","GetPushedTexture","GetHighlightTexture","GetDisabledTexture"}) do
            if b[getter] then local t=b[getter](b); if t~=icon then Texture(s,t,true) end end
        end
        if icon then Texture(s,icon,false); icon:SetTexCoord(.07,.93,.07,.93) end
        local fs=_G[name.."Count"]
        if fs and fs.GetFont then
            if not s.fonts[fs] then s.fonts[fs]={fs:GetFont()} end
            fs:SetFont(E.GetFontPath("actionBars"),11,"OUTLINE")
        end
    end
    local pressed=b.GetButtonState and b:GetButtonState()=="PUSHED"
    d.panel:SetBackdropBorderColor((d.hover or pressed) and .047 or .2,(d.hover or pressed) and .824 or .2,(d.hover or pressed) and .616 or .2,1)
    d.panel:Show()
end
local function LayoutButtons(key,f)
    local s=State(key); local p=Settings(); local list={}
    if key=="micro" then
        local paths={}; for _,entry in ipairs(micros) do paths[entry[1]]=entry[2] end
        local names=type(MICRO_BUTTONS)=="table" and #MICRO_BUTTONS>0 and MICRO_BUTTONS or nil
        if names then for _,value in ipairs(names) do
            local b=type(value)=="string" and _G[value] or value
            if b and b.GetName then list[#list+1]={b,paths[b:GetName()] or "INV_Misc_QuestionMark"} end
        end
        else for _,entry in ipairs(micros) do if _G[entry[1]] then list[#list+1]={_G[entry[1]],entry[2]} end end end
    else
        for _,name in ipairs({"MainMenuBarBackpackButton","CharacterBag0Slot","CharacterBag1Slot","CharacterBag2Slot","CharacterBag3Slot","KeyRingButton"}) do
            if _G[name] then list[#list+1]={_G[name]} end
        end
    end
    local size,gap=Clamp(p[key.."Size"] or p.buttonSize,20,48),Clamp(p[key.."Spacing"] or p.spacing,0,12)
    local consolidated=key=="bags" and p.bagsConsolidate
    if consolidated and not H.hiddenBags then H.hiddenBags=CreateFrame("Frame",nil,UIParent); H.hiddenBags:Hide() end
    Size(f,(consolidated and 1 or math.max(1,#list))*(size+gap)-gap,size); f:Show()
    for i,entry in ipairs(list) do
        local b=entry[1]; local keyring=b==_G.KeyRingButton
        Button(s,b,keyring and "INV_Misc_Key_03" or entry[2],key=="micro" or keyring)
        b:SetParent(consolidated and b~=_G.MainMenuBarBackpackButton and H.hiddenBags or f); b:SetScale(1); Size(b,size,size); b:ClearAllPoints()
        if b.SetHitRectInsets then b:SetHitRectInsets(0,0,0,0) end
        b:SetPoint("LEFT",f,"LEFT",(i-1)*(size+gap),0)
        -- Native events still decide availability and show/hide each slot.
    end
end
local function DataBar(key,f)
    if f.fill then return end
    f:SetFrameStrata("LOW")
    -- Keep the dark empty area on the holder, below its two inset status bars.
    f:SetBackdrop({bgFile=flat,edgeFile=flat,edgeSize=1})
    f:SetBackdropColor(.06,.06,.06,.95); f:SetBackdropBorderColor(.15,.15,.15,1)
    f.rested=CreateFrame("StatusBar",nil,f); f.rested:SetPoint("TOPLEFT",f,"TOPLEFT",1,-1); f.rested:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-1,1)
    f.rested:SetStatusBarTexture(dataTexture); f.rested:SetStatusBarColor(.5,0,.5,.8)
    f.fill=CreateFrame("StatusBar",nil,f); f.fill:SetPoint("TOPLEFT",f,"TOPLEFT",1,-1); f.fill:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-1,1)
    f.fill:SetStatusBarTexture(dataTexture)
    f.fill:SetFrameLevel(f.rested:GetFrameLevel()+1)
    f.text=f.fill:CreateFontString(nil,"OVERLAY"); f.text:SetPoint("CENTER",f,"CENTER",0,0)
    f:EnableMouse(true)
    f:SetScript("OnEnter",function()
        GameTooltip:SetOwner(f,"ANCHOR_TOP"); GameTooltip:AddLine(key=="xp" and "Experience" or f.faction or "Reputation",1,1,1)
        GameTooltip:AddLine(string.format("%d / %d (%.1f%%)",f.current or 0,f.maximum or 1,100*(f.current or 0)/(f.maximum or 1)),.9,.9,.9)
        if key=="xp" and GetXPExhaustion and GetXPExhaustion() then GameTooltip:AddLine("Rested: "..GetXPExhaustion(),.3,.6,1) end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave",function() GameTooltip:Hide() end)
    f:SetScript("OnMouseDown",function(_,button)
        local native=key=="xp" and MainMenuExpBar or ReputationWatchBar
        local handler=native and native:GetScript("OnMouseDown"); if handler then handler(native,button) end
    end)
end
function H.UpdateData()
    for _,key in ipairs({"xp","reputation"}) do
        local f=H.holders[key]
        if Enabled(key) and f and f.fill then
            -- Un-templated FontStrings need their font before the first text
            -- write in Wrath. Refresh here also applies text-size/font changes.
            f.text:SetFont(E.GetFontPath("actionBars"),Clamp(ns.GetSettings().fontSize,8,20),"OUTLINE")
            local current,maximum=0,1; local show=false
            if key=="xp" then
                current=UnitXP and UnitXP("player") or 0; maximum=math.max(1,UnitXPMax and UnitXPMax("player") or 1)
                show=UnitLevel("player")<(MAX_PLAYER_LEVEL or 80)
                local rested=GetXPExhaustion and GetXPExhaustion() or 0
                if rested>0 then
                    f.rested:SetMinMaxValues(0,maximum); f.rested:SetValue(math.min(maximum,current+rested)); f.rested:Show()
                    f.text:SetText(string.format("XP: %.1f%%  R: %.1f%%",100*current/maximum,100*rested/maximum))
                else
                    f.rested:SetMinMaxValues(0,1); f.rested:SetValue(0); f.rested:Hide()
                    f.text:SetText(string.format("XP: %.1f%%",100*current/maximum))
                end
                f.fill:SetStatusBarColor(0,.4,1,1)
                f.rested:SetStatusBarColor(.5,0,.5,.8)
            else
                local name,standing,minRep,maxRep,value
                if GetWatchedFactionInfo then name,standing,minRep,maxRep,value=GetWatchedFactionInfo() end
                f.faction=name; show=name~=nil
                if name then
                    current=math.max(0,(value or 0)-(minRep or 0)); maximum=math.max(1,(maxRep or 1)-(minRep or 0))
                    local color=FACTION_BAR_COLORS and FACTION_BAR_COLORS[standing] or {r=.047,g=.824,b=.616}
                    f.fill:SetStatusBarColor(color.r,color.g,color.b,1); f.text:SetText(name..string.format(": %.1f%%",100*current/maximum))
                else f.text:SetText("Reputation") end
                f.rested:Hide()
            end
            f.current,f.maximum=current,maximum; f.fill:SetMinMaxValues(0,maximum); f.fill:SetValue(current)
            if not ProgressInDataBars(key) and (show or E.IsUnlockModeActive and E:IsUnlockModeActive()) then f:Show() else f:Hide() end
        end
    end
end
local function AuraPosition(s,b,f,index,columns)
    if InCombatLockdown() and b.IsProtected and b:IsProtected() then H.dirty=true; return end
    local x,y=-((index-1)%columns)*36,-math.floor((index-1)/columns)*44
    local point,relative,relPoint,oldX,oldY=b:GetPoint(1)
    if b:GetNumPoints()==1 and point=="TOPRIGHT" and relative==f and relPoint=="TOPRIGHT" and oldX==x and oldY==y then return end
    Remember(s,b); b:ClearAllPoints()
    b:SetPoint("TOPRIGHT",f,"TOPRIGHT",x,y)
end
local function KeepBuffTop(f)
    if E.IsUnlockModeActive and E:IsUnlockModeActive() then return end
    local point,relative,relPoint,x,y=f:GetPoint(1)
    if not point or point:find("TOP",1,true) then return end
    -- Edit Mode can save CENTER/BOTTOM anchors. A taller holder then moves
    -- its top row upward even though individual icons use negative row Y.
    -- Pin the existing top-right corner before changing the holder height.
    local px=point:find("LEFT",1,true) and 0 or point:find("RIGHT",1,true) and 1 or .5
    local py=point:find("BOTTOM",1,true) and 0 or .5
    x=(x or 0)+(1-px)*f:GetWidth(); y=(y or 0)+(1-py)*f:GetHeight()
    f:ClearAllPoints(); f:SetPoint("TOPRIGHT",relative,relPoint,x,y)
    if relative==UIParent then ns.GetSettings().barPositions.hud_buffs={point="TOPRIGHT",relPoint=relPoint,x=x,y=y} end
end
function H.UpdateAuras()
    for _,key in ipairs({"buffs","debuffs"}) do
        local f=H.holders[key]
        if Enabled(key) and f then
            local s=State(key); local p=Settings(); local columns=Clamp(p[key.."Columns"] or p.auraColumns,1,16); local list={}
            if key=="buffs" then
                for i=1,3 do local b=_G["TempEnchant"..i]; if b and b:IsShown() then list[#list+1]=b end end
                if ConsolidatedBuffs and ConsolidatedBuffs:IsShown() then list[#list+1]=ConsolidatedBuffs end
            end
            local prefix=key=="buffs" and "BuffButton" or "DebuffButton"
            local max=key=="buffs" and (BUFF_ACTUAL_DISPLAY or BUFF_MAX_DISPLAY or 32) or (DEBUFF_MAX_DISPLAY or 16)
            for i=1,max do local b=_G[prefix..i]; if b and b:IsShown() then list[#list+1]=b end end
            for i,b in ipairs(list) do AuraPosition(s,b,f,i,columns) end
            if not InCombatLockdown() then
                if key=="buffs" then KeepBuffTop(f) end
                Size(f,columns*36-6,math.max(1,math.ceil(#list/columns))*44)
            end
            local native=key=="buffs" and _G.BuffFrame or _G.DebuffFrame
            if native and (not InCombatLockdown() or not native.IsProtected or not native:IsProtected()) then
                Remember(s,native)
                local point,relative=native:GetPoint(1)
                if native:GetNumPoints()~=1 or point~="TOPRIGHT" or relative~=f then
                    native:ClearAllPoints(); native:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
                end
                if not InCombatLockdown() then Size(native,f:GetWidth(),f:GetHeight()) end
            end
        end
    end
end
function H.Apply(forcePosition)
    if not ns.GetSettings() then return end
    if InCombatLockdown() then H.dirty=true; return end
    H.dirty=false
    for _,d in ipairs(definitions) do
        if not Enabled(d.key) then Restore(d.key)
        else
            local s=State(d.key)
            if d.key=="buffs" then Remember(s,_G.BuffFrame) elseif d.key=="debuffs" then Remember(s,_G.DebuffFrame) end
            local f=Holder(d); s.active=true
            if forcePosition~=false or not (E.IsUnlockModeActive and E:IsUnlockModeActive()) then Position(d,f) end
            if d.key=="micro" or d.key=="bags" then LayoutButtons(d.key,f)
            elseif d.key=="xp" or d.key=="reputation" then
                local p=Settings(); Size(f,Clamp(p[d.key.."Width"] or p.barWidth,120,1000),Clamp(p[d.key.."Height"] or p.barHeight,8,32)); DataBar(d.key,f)
                local names=d.key=="xp" and {"MainMenuExpBar","MainMenuBarMaxLevelBar","ExhaustionLevelFillBar","ExhaustionTick"} or {"ReputationWatchBar"}
                for _,name in ipairs(names) do
                    local native=_G[name]
                    if native then
                        -- ExhaustionLevelFillBar/ExhaustionTick are Texture
                        -- regions in Wrath: they have no Frame scale/scripts.
                        if native.GetObjectType and native:GetObjectType()=="Texture" then Texture(s,native,true)
                        else
                            Remember(s,native); native:SetAlpha(0); if native.EnableMouse then native:EnableMouse(false) end
                            if native.GetRegions then for _,region in ipairs({native:GetRegions()}) do
                                if region.GetObjectType and region:GetObjectType()=="Texture" then Texture(s,region,true) end
                            end end
                            if native.GetStatusBarTexture then Texture(s,native:GetStatusBarTexture(),true) end
                        end
                    end
                end
            else f:Show() end
        end
    end
    H.UpdateAuras(); H.UpdateData()
end
function H.Elements()
    local elements={}
    for i,d in ipairs(definitions) do
        local key=d.key
        elements[#elements+1]=E.MakeUnlockElement({key="EUI335_HUD_"..key,label=d.label,group=d.group,order=120+i,
            noResize=true,noAnchorTo=true,getFrame=function() return H.holders[key] end,
            getSize=function() local f=H.holders[key]; return f and f:GetWidth() or 240,f and f:GetHeight() or 32 end,
            isHidden=function() return not Enabled(key) or (key=="xp" or key=="reputation") and ProgressInDataBars(key) end,
            savePos=function(_,point,relPoint,x,y) local p=ns.GetSettings(); if p then p.barPositions["hud_"..key]={point=point,relPoint=relPoint,x=x,y=y} end end,
            loadPos=function() local p=ns.GetSettings(); return p and p.barPositions["hud_"..key] end,
            clearPos=function() local p=ns.GetSettings(); if p then p.barPositions["hud_"..key]=nil end end,
            applyPos=function() H.Apply() end})
    end
    return elements
end
function H.Enable()
    if H.events then return end
    local f=CreateFrame("Frame"); H.events=f
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_XP_UPDATE","PLAYER_LEVEL_UP",
        "UPDATE_EXHAUSTION","UPDATE_FACTION","UNIT_AURA","BAG_UPDATE","ADDON_LOADED"}) do f:RegisterEvent(event) end
    f:SetScript("OnEvent",function(_,event,unit)
        if event=="UNIT_AURA" and unit~="player" then return end
        if event=="PLAYER_XP_UPDATE" or event=="UPDATE_EXHAUSTION" or event=="UPDATE_FACTION" then H.UpdateData()
        elseif event=="UNIT_AURA" then H.UpdateAuras()
        else H.dirty=true end
    end)
    local elapsed=0
    f:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt; if elapsed<.2 then return end; elapsed=0
        if H.dirty and not InCombatLockdown() then H.Apply(false) end
        H.UpdateData()
    end)
    for _,name in ipairs({"BuffFrame_UpdateAllBuffAnchors","DebuffButton_UpdateAnchors","BuffFrame_Update",
        "UIParent_ManageFramePositions","MainMenuBar_UpdateExperienceBars","ReputationWatchBar_Update",
        "UpdateMicroButtons","MoveMicroButtons","UpdateMicroButtonsParent","MainMenuBarBackpackButton_UpdateFreeSlots"}) do
        if type(_G[name])=="function" then hooksecurefunc(name,function()
            H.dirty=true
            if name=="BuffFrame_UpdateAllBuffAnchors" or name=="DebuffButton_UpdateAnchors" then H.UpdateAuras() end
        end) end
    end
end
