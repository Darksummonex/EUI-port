-- Popup extras: a pulsing border on the resurrect accept button and a
-- countdown bar on the Dungeon Finder ready dialog.
local _,ns=...
if not ns.IsWrath then return end
local E=EllesmereUI
local flat="Interface\\Buttons\\WHITE8X8"
for key,value in pairs({resurrectAcceptGlow=false,showQueueTimer=true,queueTimerTextSize=9,queueTimerBarHeight=11,queueTimerTextOffsetY=0}) do ns.defaults[key]=value end
local P={}; ns.Popups=P
table.insert(ns.extras,P)
local PROPOSAL_TIME=40
local RES_WHICH={RESURRECT=true,RESURRECT_NO_SICKNESS=true,RESURRECT_NO_TIMER=true}
local function Own(obj) ns.owned[obj]=true; return obj end
local function Accent()
    local eg=E.ELLESMERE_GREEN or {}
    return eg.r or .047,eg.g or .824,eg.b or .616
end
local glows={}
local function Glow(button)
    local g=glows[button]; if g then return g end
    g=Own(CreateFrame("Frame",nil,button))
    g:SetPoint("TOPLEFT",button,"TOPLEFT",-3,3); g:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",3,-3)
    g:SetFrameLevel(button:GetFrameLevel()+5); g:EnableMouse(false)
    g:SetBackdrop({edgeFile=flat,edgeSize=2}); g:Hide()
    if g.CreateAnimationGroup then
        local group=g:CreateAnimationGroup(); group:SetLooping("BOUNCE")
        local pulse=group:CreateAnimation("Alpha")
        if pulse.SetFromAlpha then pulse:SetFromAlpha(1); pulse:SetToAlpha(.15) else pulse:SetChange(-.85) end
        pulse:SetDuration(.7); if pulse.SetSmoothing then pulse:SetSmoothing("IN_OUT") end
        g.group=group
    end
    glows[button]=g
    return g
end
function P.UpdateGlows()
    for i=1,(STATICPOPUP_NUMDIALOGS or 4) do
        local popup=_G["StaticPopup"..i]
        local button=popup and (popup.button1 or _G["StaticPopup"..i.."Button1"])
        if button then
            local want=ns.GetValue("resurrectAcceptGlow") and popup:IsShown() and RES_WHICH[popup.which or ""]
            if want then
                local g=Glow(button); g:SetBackdropBorderColor(Accent()); g:SetAlpha(1); g:Show()
                if g.group and not g.group:IsPlaying() then g.group:Play() end
            elseif glows[button] then
                local g=glows[button]; if g.group then g.group:Stop() end; g:Hide()
            end
        end
    end
end
local timer
local function TimerColor()
    local c=ns.GetSettings().queueTimerTextColor
    local QT=E.QUEUE_TIMER or {}
    if type(c)=="table" then return c.r or 1,c.g or .831,c.b or 0 end
    return QT.TEXT_R or 1,QT.TEXT_G or .831,QT.TEXT_B or 0
end
local function BuildTimer()
    local dialog=_G.LFDDungeonReadyDialog; if not dialog or timer then return timer end
    timer=Own(CreateFrame("StatusBar",nil,dialog))
    timer:SetPoint("TOPLEFT",dialog,"BOTTOMLEFT",6,-2); timer:SetPoint("TOPRIGHT",dialog,"BOTTOMRIGHT",-6,-2)
    timer:SetStatusBarTexture(flat); timer:SetMinMaxValues(0,PROPOSAL_TIME)
    timer.bg=Own(timer:CreateTexture(nil,"BACKGROUND")); timer.bg:SetTexture(flat); timer.bg:SetAllPoints(timer); timer.bg:SetVertexColor(0,0,0,.6)
    timer.text=Own(timer:CreateFontString(nil,"OVERLAY"))
    timer:Hide()
    timer:SetScript("OnUpdate",function(self)
        local left=math.max(0,(self.expires or 0)-GetTime())
        self:SetValue(left); self.text:SetText(string.format("%d",math.ceil(left)))
        if left<=0 then self:Hide() end
    end)
    return timer
end
function P.StyleTimer()
    if not timer then return end
    local size=math.max(6,math.min(24,tonumber(ns.GetValue("queueTimerTextSize")) or 9))
    ns.ApplyFont(timer.text,size,"OUTLINE"); timer.text:SetTextColor(TimerColor())
    timer.text:ClearAllPoints(); timer.text:SetPoint("CENTER",timer,"CENTER",0,tonumber(ns.GetValue("queueTimerTextOffsetY")) or 0)
    timer:SetHeight(math.max(2,math.min(30,tonumber(ns.GetValue("queueTimerBarHeight")) or 11)))
    timer:SetStatusBarColor(Accent())
end
function P.StartTimer()
    if not ns.GetValue("showQueueTimer") or not BuildTimer() then return end
    P.StyleTimer()
    timer.expires=GetTime()+PROPOSAL_TIME; timer:Show()
end
function P.StopTimer() if timer then timer:Hide() end end
function P.Apply()
    P.UpdateGlows()
    if timer then
        P.StyleTimer()
        if not ns.GetValue("showQueueTimer") then timer:Hide() end
    end
end
function P.Enable()
    if type(_G.StaticPopup_Show)=="function" then hooksecurefunc("StaticPopup_Show",P.UpdateGlows) end
    for i=1,(STATICPOPUP_NUMDIALOGS or 4) do
        local popup=_G["StaticPopup"..i]
        if popup then popup:HookScript("OnHide",P.UpdateGlows) end
    end
    local f=CreateFrame("Frame"); P.events=f
    for _,event in ipairs({"LFG_PROPOSAL_SHOW","LFG_PROPOSAL_FAILED","LFG_PROPOSAL_SUCCEEDED"}) do pcall(f.RegisterEvent,f,event) end
    f:SetScript("OnEvent",function(_,event)
        if event=="LFG_PROPOSAL_SHOW" then P.StartTimer() else P.StopTimer() end
    end)
end
