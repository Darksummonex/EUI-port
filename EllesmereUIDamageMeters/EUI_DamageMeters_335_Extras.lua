-- Standalone combat timer, Reset Data / Show-Hide keybinds and the window toggle.
local ADDON,ns=...
local E=EllesmereUI
local white="Interface\\Buttons\\WHITE8X8"
local timer,timerText
function ns.FormatTimer(s,decimal)
    s=math.max(0,s or 0)
    if decimal then return string.format("%d:%02d.%d",math.floor(s/60),math.floor(s%60),math.floor((s*10)%10)) end
    return string.format("%d:%02d",math.floor(s/60),math.floor(s%60))
end
local function Preview() return ns.preview or ns.optionsOpen end
local function TimerColor(p,live)
    local r,g,b
    if p.standaloneTimerUseAccent then r,g,b=ns.Accent()
    else local c=p.standaloneTimerColor or {}; r,g,b=c.r or 1,c.g or 1,c.b or 1 end
    if p.standaloneTimerDesatOOC and not live then local l=.299*r+.587*g+.114*b; r,g,b=l,l,l end
    return r,g,b
end
local function Outline(p)
    local o=p.standaloneTimerOutline or "INHERIT"
    if o=="NONE" then return "" elseif o=="THICKOUTLINE" then return "THICKOUTLINE" elseif o=="INHERIT" then return "GLOBAL" end
    return "OUTLINE"
end
-- "free" keeps a saved position; the corner anchors follow the highest or
-- lowest shown meter window.
local function PositionTimer(p,force)
    if E.IsUnlockAnchored and E.IsUnlockAnchored("EDM_CombatTimer") then return end
    local anchor=p.standaloneTimerAnchor or "free"
    local ref
    if anchor~="free" then
        local best
        for i in ipairs(p.windows) do
            local w=ns.windows[i]
            if w and w.frame:IsShown() then
                local v=(anchor=="topleft" or anchor=="topright") and w.frame:GetTop() or -(w.frame:GetBottom() or 0)
                if v and (not best or v>best) then best,ref=v,w.frame end
            end
        end
    end
    if not force and timer.anchor==anchor and timer.ref==ref then return end
    timer.anchor,timer.ref=anchor,ref
    timer:ClearAllPoints()
    if anchor=="free" then
        local locked=p.standaloneTimerLocked==true
        timer:SetMovable(not locked); timer:EnableMouse(not locked)
        local pos=p.standaloneTimerPos
        if pos and pos.point then timer:SetPoint(pos.point,UIParent,pos.relPoint or pos.point,pos.x or 0,pos.y or 0)
        elseif pos and pos.x and pos.y then timer:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",pos.x,pos.y)
        elseif ns.windows[1] then timer:SetPoint("BOTTOMRIGHT",ns.windows[1].frame,"TOPRIGHT",0,5)
        else timer:SetPoint("CENTER",UIParent,"CENTER",0,0) end
        return
    end
    timer:SetMovable(false); timer:EnableMouse(false)
    if not ref then timer:SetPoint("CENTER",UIParent,"CENTER",0,0); return end
    local left=anchor=="topleft" or anchor=="bottomleft"
    if anchor=="topleft" or anchor=="topright" then
        timer:SetPoint(left and "BOTTOMLEFT" or "BOTTOMRIGHT",ref,left and "TOPLEFT" or "TOPRIGHT",0,0)
    else timer:SetPoint(left and "TOPLEFT" or "TOPRIGHT",ref,left and "BOTTOMLEFT" or "BOTTOMRIGHT",0,0) end
end
local function StyleTimer(p)
    timer:SetFrameStrata(p.standaloneTimerStrata or "HIGH")
    local size=ns.Clamp(p.standaloneTimerSize,8,72)
    ns.Font(timerText,size,Outline(p))
    local previous=timerText:GetText() or ""
    -- Sized for the widest value so live digits never clip.
    timerText:SetText(p.standaloneTimerDecimal and "99:99.9" or "99:99")
    local w=timerText:GetStringWidth()+4
    local h=(timerText.GetStringHeight and timerText:GetStringHeight() or size)+4
    timerText:SetText(previous)
    local border=math.max(0,math.floor((p.standaloneTimerBorderSize or 0)+.5)); local inset=border>0 and border+3 or 0
    ns.Size(timer,w+inset*2,h+inset*2)
    local bg,bc=p.standaloneTimerBackgroundColor or {},p.standaloneTimerBorderColor or {}
    timer:SetBackdrop(border>0 and {bgFile=white,edgeFile=white,edgeSize=border} or {bgFile=white})
    timer:SetBackdropColor(bg.r or 0,bg.g or 0,bg.b or 0,bg.a or 0)
    if border>0 then timer:SetBackdropBorderColor(bc.r or 0,bc.g or 0,bc.b or 0,bc.a==nil and 1 or bc.a) end
    timerText:ClearAllPoints()
    timerText:SetPoint("LEFT",timer,"LEFT",inset,0); timerText:SetPoint("RIGHT",timer,"RIGHT",-inset,0)
    local anchor=p.standaloneTimerAnchor or "free"
    timerText:SetJustifyH((anchor=="topleft" or anchor=="bottomleft") and "LEFT" or "RIGHT")
    timer.live=nil
end
function ns.UpdateTimer()
    if not timer then return end
    local p=ns.Profile()
    if not p or not p.enabled or not p.standaloneTimer or ns.toggleHidden and p.toggleIncludeTimer and not Preview() then timer:Hide(); return end
    if (p.standaloneTimerAnchor or "free")~="free" then PositionTimer(p) end
    local live=ns.current~=nil; local text
    if live then text=ns.FormatTimer(ns.Duration(ns.current),p.standaloneTimerDecimal)
    elseif p.standaloneTimerShowOOC then
        local last=ns.history and ns.history.segments[1]
        text=ns.FormatTimer(last and last.duration or 0,p.standaloneTimerDecimal)
    elseif Preview() then text=p.standaloneTimerDecimal and "11:37.0" or "11:37" end
    if not text then timer:Hide(); return end
    timerText:SetText(text)
    if timer.live~=live then timer.live=live; timerText:SetTextColor(TimerColor(p,live)) end
    timer:Show()
end
local function RegisterTimerUnlock()
    if timer.registered or not E.RegisterUnlockElements or not E.MakeUnlockElement then return end
    timer.registered=true
    E:RegisterUnlockElements({E.MakeUnlockElement({key="EDM_CombatTimer",label="Combat Timer",group="Damage Meters",
        order=950+ns.MAX_WINDOWS+1,noResize=true,noAnchorTarget=true,
        getFrame=function() return timer end,
        getSize=function() return timer:GetWidth(),timer:GetHeight() end,
        isHidden=function() local p=ns.Profile(); return not p or not p.enabled or not p.standaloneTimer end,
        savePos=function(_,point,relPoint,x,y) local p=ns.Profile(); p.standaloneTimerPos={point=point,relPoint=relPoint,x=x,y=y}; p.standaloneTimerAnchor="free" end,
        loadPos=function() local pos=ns.Profile().standaloneTimerPos; return pos and pos.point and pos or nil end,
        clearPos=function() ns.Profile().standaloneTimerPos=nil end,
        applyPos=function() PositionTimer(ns.Profile(),true) end})},ADDON)
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    E._ELEMENT_SETTINGS_MAP.EDM_CombatTimer={module=ADDON,page="Windows",sectionName="STANDALONE COMBAT TIMER",highlightText="Standalone Combat Timer"}
end
local function CreateTimer()
    timer=CreateFrame("Frame","EllesmereUIDMStandaloneTimer",UIParent)
    ns.Size(timer,60,30); timer:SetClampedToScreen(true); timer:SetMovable(true); timer:EnableMouse(true)
    timerText=timer:CreateFontString(nil,"OVERLAY"); ns.Font(timerText,26); timerText:SetJustifyV("MIDDLE")
    timer.text=timerText; ns.standaloneTimer=timer
    -- Shift-drag moves a free, unlocked timer.
    timer:SetScript("OnMouseDown",function(self,button)
        local p=ns.Profile()
        if button=="LeftButton" and IsShiftKeyDown() and not p.standaloneTimerLocked and (p.standaloneTimerAnchor or "free")=="free" then
            self.moving=true; self:StartMoving()
        end
    end)
    timer:SetScript("OnMouseUp",function(self)
        if not self.moving then return end
        self.moving=nil; self:StopMovingOrSizing()
        local left,top=self:GetLeft(),self:GetTop()
        if left and top then ns.Profile().standaloneTimerPos={x=left,y=top} end
    end)
    timer.elapsed=0
    timer:SetScript("OnUpdate",function(self,dt)
        if not ns.current then return end
        self.elapsed=self.elapsed+dt
        if self.elapsed<.1 then return end
        self.elapsed=0; ns.UpdateTimer()
    end)
    timer:Hide()
end
local function ApplyTimer()
    local p=ns.Profile()
    if not p.standaloneTimer then if timer then timer:Hide() end; return end
    if not timer then CreateTimer() end
    RegisterTimerUnlock()
    StyleTimer(p); PositionTimer(p,true); ns.UpdateTimer()
end
-- Both keys use override bindings on hidden buttons. A rebind waits for the
-- end of combat; LoadBindings drops overrides, so UPDATE_BINDINGS re-applies
-- them, ignoring the echo of our own writes.
local resetButton=CreateFrame("Button","EllesmereUIDMResetBindBtn",UIParent); resetButton:Hide()
resetButton:SetScript("OnClick",function()
    if not ns.Reset() and DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff0cd29dEllesmereUI|r: finish combat before resetting meter data.") end
end)
local toggleButton=CreateFrame("Button","EllesmereUIDMToggleBindBtn",UIParent); toggleButton:Hide()
toggleButton:SetScript("OnClick",function() ns.ToggleWindows() end)
local bindWatch=CreateFrame("Frame"); ns.bindWatch=bindWatch
local selfWriteUntil,appliedReset,appliedToggle=0
local function WantKey(key)
    if type(key)~="string" then return nil end
    key=key:upper():gsub("%s+","")
    return key~="" and key or nil
end
function ns.ApplyKeybinds(force)
    local p=ns.Profile(); if not p then return end
    local wantReset,wantToggle=WantKey(p.resetDataKey),WantKey(p.toggleWindowsKey)
    if not force and wantReset==appliedReset and wantToggle==appliedToggle then return end
    if InCombatLockdown() then bindWatch:RegisterEvent("PLAYER_REGEN_ENABLED"); return end
    selfWriteUntil=GetTime()+.5
    ClearOverrideBindings(resetButton)
    if wantReset then pcall(SetOverrideBindingClick,resetButton,true,wantReset,"EllesmereUIDMResetBindBtn") end
    ClearOverrideBindings(toggleButton)
    if wantToggle then pcall(SetOverrideBindingClick,toggleButton,true,wantToggle,"EllesmereUIDMToggleBindBtn") end
    appliedReset,appliedToggle=wantReset,wantToggle
    if wantReset or wantToggle then bindWatch:RegisterEvent("UPDATE_BINDINGS") else bindWatch:UnregisterEvent("UPDATE_BINDINGS") end
end
bindWatch:SetScript("OnEvent",function(self,event)
    if event=="PLAYER_REGEN_ENABLED" then self:UnregisterEvent(event); ns.ApplyKeybinds(true); return end
    if GetTime()<selfWriteUntil then return end
    ns.ApplyKeybinds(true)
end)
function ns.ApplyToggleState(includeSpellHistory)
    if ns.toggleHidden then ns.HideBreakdownTooltip() end
    ns.Refresh()
    if includeSpellHistory==nil then includeSpellHistory=ns.Profile().toggleIncludeSpellHistory end
    if includeSpellHistory and ns.ApplySpellHistory then ns.ApplySpellHistory() end
end
function ns.ToggleWindows()
    ns.toggleHidden=not ns.toggleHidden
    ns.ApplyToggleState()
end
-- Previews (timer, Spell History) show while the meter options are open.
function ns.SetOptionsOpen(open)
    open=open and true or false
    if ns.optionsOpen==open then return end
    ns.optionsOpen=open
    if ns.Profile() then ns.ApplyExtras() end
end
if E.RegisterOnHide then E:RegisterOnHide(function() ns.SetOptionsOpen(false) end) end
if E.RegisterOnShow then E:RegisterOnShow(function() if E.GetActiveModule and E:GetActiveModule()==ADDON then ns.SetOptionsOpen(true) end end) end
function ns.ApplyExtras()
    if not ns.Profile() then return end
    ApplyTimer(); ns.ApplyKeybinds()
    if ns.ApplySpellHistory then ns.ApplySpellHistory() end
end
