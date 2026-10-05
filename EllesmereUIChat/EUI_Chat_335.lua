-- Native Wrath windows remain responsible for routing, links and text input.
local ADDON_NAME, ns = ...
local E = EllesmereUI
if not E or not E.Lite or not ChatFrame1 then return end
E._ModuleNS[ADDON_NAME] = ns
local addon = E.Lite.NewAddon(ADDON_NAME)
ns.addon, ns.IsWrath, ns.ECHAT = addon, true, {}
local ECHAT = ns.ECHAT
local defaults = {profile={chat={
    enabled=true, bgAlpha=.65, bgR=.03, bgG=.045, bgB=.05,
    borderSize=1, borderR=0, borderG=0, borderB=0, borderA=1,
    font="__global", outlineMode="__global", chatFontSize=12,
    tabFont="__global", tabFontSize=11, editBoxFont="__chat", editBoxFontSize=12,
    skinTabs=true, skinEditBox=true, squareSkin=true, inputOnTop=false, hideButtons=false,
    showCopy=true, showSettings=true, clickableURLs=true,
    timestamps=true, timestampFormat="%H:%M", copyLines=500,
    mouseWheel=true, fadeMessages=false, fadeSeconds=120,
    width=420, height=180,
}}}
ns.defaults = defaults
local states, active, pending, resetPosition = {}, false, false, false
ns.states = states
local chrome = {"Background","TopLeftTexture","BottomLeftTexture","TopRightTexture",
    "BottomRightTexture","LeftTexture","RightTexture","BottomTexture","TopTexture"}
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function Points(f)
    local result={}; for i=1,f:GetNumPoints() do result[i]={f:GetPoint(i)} end; return result
end
local function SetPoints(f,points)
    f:ClearAllPoints(); for _,point in ipairs(points) do f:SetPoint(unpack(point)) end
end
function ns.GetSettings() return addon.db and addon.db.profile.chat end
ECHAT.DB = ns.GetSettings
local function FontPath(key)
    if key and key~="__global" and key~="__chat" and E.ResolveFontName then return E.ResolveFontName(key) end
    return E.GetFontPath and E.GetFontPath("chat") or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end
local function Outline(p)
    if p.outlineMode=="outline" then return "OUTLINE" end
    if p.outlineMode=="thick" then return "THICKOUTLINE" end
    if p.outlineMode=="none" then return "" end
    local flag=E.GetFontOutlineFlag and E.GetFontOutlineFlag("chat") or ""
    return (flag:gsub(",?%s*SLUG", "")) -- not a Wrath renderer flag
end
local function Panel(parent)
    local f=CreateFrame("Frame",nil,parent)
    f:SetFrameLevel(math.max(0,parent:GetFrameLevel()-1)); f:EnableMouse(false); return f
end
local function Backdrop(f,p)
    local n=math.max(0,math.min(8,tonumber(p.borderSize) or 0))
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile=n>0 and "Interface\\Buttons\\WHITE8X8" or nil,
        tile=false,edgeSize=math.max(1,n),insets={left=n,right=n,top=n,bottom=n}})
    f:SetBackdropColor(p.bgR,p.bgG,p.bgB,p.bgAlpha); f:SetBackdropBorderColor(p.borderR,p.borderG,p.borderB,p.borderA)
end
local function PlainURLs(text)
    return (text:gsub("(%S+)",function(token)
        if not (token:match("^https?://") or token:match("^www%.")) then return token end
        local url,tail=token:match("^(.-)([.,;!?)%]]*)$")
        if not url or #url<5 then return token end
        return "|Heuiurl:"..url.."|h["..url.."]|h"..tail
    end))
end
-- Never nest URL links inside existing item/player links or texture escapes.
function ns.LinkURLs(text)
    local out, at = {}, 1
    while at<=#text do
        local first=text:find("|",at,true)
        if not first then out[#out+1]=PlainURLs(text:sub(at)); break end
        if first>at then out[#out+1]=PlainURLs(text:sub(at,first-1)) end
        local code=text:sub(first+1,first+1); local finish
        if code=="H" then
            local one=text:find("|h",first+2,true); finish=one and text:find("|h",one+2,true)
            if finish then finish=finish+1 end
        elseif code=="T" then finish=text:find("|t",first+2,true); if finish then finish=finish+1 end
        elseif code=="c" and text:sub(first+2,first+9):match("^%x%x%x%x%x%x%x%x$") then finish=first+9
        elseif code=="r" or code=="|" then finish=first+1 end
        if not finish then out[#out+1]=text:sub(first); break end
        out[#out+1]=text:sub(first,finish); at=finish+1
    end
    return table.concat(out)
end
function ns.PlainText(text)
    return (text:gsub("|H.-|h(.-)|h","%1"):gsub("|T.-|t",""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("||","|"))
end
local copyWindow
local function EnsureCopyWindow()
    if copyWindow then return copyWindow end
    local f=CreateFrame("Frame","EllesmereUIChat_Copy335",UIParent)
    Size(f,640,400); f:SetPoint("CENTER",UIParent,"CENTER",0,0); f:SetFrameStrata("DIALOG")
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    f:SetBackdropColor(.03,.045,.05,.98); f:SetBackdropBorderColor(0,0,0,1)
    local title=f:CreateFontString(nil,"OVERLAY","GameFontNormal")
    title:SetPoint("TOPLEFT",f,"TOPLEFT",16,-12); title:SetText("Copy Chat - Ctrl+C")
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
    close:SetScript("OnClick",function() f:Hide() end)
    local scroll=CreateFrame("ScrollFrame","EllesmereUIChat_Copy335Scroll",f,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",f,"TOPLEFT",16,-40); scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-34,16)
    local box=CreateFrame("EditBox",nil,scroll)
    box:SetMultiLine(true); box:SetMaxLetters(0); box:SetAutoFocus(false)
    Size(box,580,330); box:SetFont(FontPath(),12,"")
    box:SetScript("OnEscapePressed",function() f:Hide() end)
    box:SetScript("OnHide",function(self) self:ClearFocus() end)
    scroll:SetScrollChild(box); f:SetScript("OnHide",function() box:ClearFocus() end)
    f.box,f.scroll=box,scroll; f:Hide(); copyWindow=f; ns.copyWindow=f
    UISpecialFrames[#UISpecialFrames+1]="EllesmereUIChat_Copy335"
    return f
end
local function ShowCopy(text)
    local f=EnsureCopyWindow(); f:Show(); f.box:SetText(text); f.scroll:SetVerticalScroll(0)
    f.box:HighlightText(); f.box:SetFocus() -- explicit copy/URL click only
end
function ns.CopyChat(cf)
    cf=cf or (FCF_GetCurrentChatFrame and FCF_GetCurrentChatFrame()) or ChatFrame1
    local p=ns.GetSettings(); if not p then return end
    local lines={}
    local s=states[cf]
    if active and s then
        for _,line in ipairs(s.lines) do lines[#lines+1]=ns.PlainText(line) end
    elseif cf.GetNumMessages and cf.GetMessageInfo then
        local count=cf:GetNumMessages()
        for i=math.max(1,count-p.copyLines+1),count do
            local text=cf:GetMessageInfo(i); if type(text)=="string" then lines[#lines+1]=ns.PlainText(text) end
        end
    else
        for _,line in ipairs(s and s.lines or {}) do lines[#lines+1]=ns.PlainText(line) end
    end
    ShowCopy(table.concat(lines,"\n"))
end
local function Wheel(self,delta)
    if IsShiftKeyDown() then if delta>0 then self:ScrollToTop() else self:ScrollToBottom() end
    elseif delta>0 then self:ScrollUp() else self:ScrollDown() end
end
local function Button(parent,label,offset,fn)
    local f=CreateFrame("Button",nil,parent); Size(f,20,20); f:SetPoint("TOPLEFT",parent,"TOPRIGHT",6,offset)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); f:SetBackdropColor(.03,.045,.05,.8)
    local text=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); text:SetAllPoints(f); text:SetText(label)
    f:SetScript("OnClick",fn); return f
end
local function RememberFont(f) return f and f.GetFont and {f:GetFont()} end
local function RestoreFont(f,font) if f and font and font[1] then f:SetFont(unpack(font)) end end
local function HideTexture(s,texture)
    if not texture then return end
    if s.textures[texture]==nil then s.textures[texture]=texture:GetAlpha() end; texture:SetAlpha(0)
end
local tabChrome={"leftTexture","middleTexture","rightTexture","leftSelectedTexture","middleSelectedTexture",
    "rightSelectedTexture","leftHighlightTexture","middleHighlightTexture","rightHighlightTexture"}
local function Accent()
    if E.ResolveThemeColor and E.GetActiveTheme then return E.ResolveThemeColor(E.GetActiveTheme()) end
    return .05,.82,.61
end
local function RestoreSquare(s)
    for texture,alpha in pairs(s.squareTextures or {}) do texture:SetAlpha(alpha) end
    if s.tabPanel then s.tabPanel:Hide(); s.tabLine:Hide(); s.tab:SetFrameLevel(s.tabLevel) end
    if s.columnPanel then s.columnPanel:Hide() end
    for button,skin in pairs(s.squareButtons or {}) do
        skin.panel:Hide(); skin.label:Hide(); button:SetFrameLevel(skin.level)
    end
end
local function HideSquareTexture(s,texture)
    if not texture then return end
    if s.squareTextures[texture]==nil then s.squareTextures[texture]=texture:GetAlpha() end
    texture:SetAlpha(0)
end
local function PaintTab(s,selected)
    local p=ns.GetSettings()
    if not s.tabPanel or not active or not p or not p.squareSkin then return end
    for _,key in ipairs(tabChrome) do HideSquareTexture(s,s.tab[key]) end
    s.tab:SetFrameLevel(math.max(2,s.tabLevel))
    s.tabPanel:SetFrameLevel(math.max(0,s.tab:GetFrameLevel()-1))
    Backdrop(s.tabPanel,p)
    local r,g,b=Accent()
    if selected==nil then
        if not s.frame.isDocked then selected=true
        elseif FCFDock_GetSelectedWindow and GENERAL_CHAT_DOCK then selected=FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)==s.frame
        else selected=(SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME)==s.frame end
    end
    s.tabSelected=selected
    if selected then s.tabLine:SetVertexColor(r,g,b,1); s.tabLine:Show() else s.tabLine:Hide() end
    if s.tabHovered then s.tabPanel:SetBackdropBorderColor(r,g,b,1) end
    s.tabPanel:Show()
end
local function PaintSquareButton(s,button,skin)
    local p=ns.GetSettings(); if not active or not p or not p.squareSkin then return end
    for _,getter in ipairs({"GetNormalTexture","GetPushedTexture","GetHighlightTexture","GetDisabledTexture"}) do
        if button[getter] then HideSquareTexture(s,button[getter](button)) end
    end
    button:SetFrameLevel(math.max(2,skin.level)); skin.panel:SetFrameLevel(math.max(0,button:GetFrameLevel()-1))
    Backdrop(skin.panel,p)
    if skin.hovered then local r,g,b=Accent(); skin.panel:SetBackdropBorderColor(r,g,b,1) end
    skin.label:SetFont(FontPath(p.tabFont),12,Outline(p))
    local enabled=not button.IsEnabled or button:IsEnabled()
    skin.label:SetTextColor(enabled and 1 or .4,enabled and 1 or .4,enabled and 1 or .4)
    skin.panel:Show(); skin.label:Show()
end
local function CaptureSquare(cf,s)
    s.frame,s.tab=cf,_G[cf:GetName().."Tab"]
    s.squareTextures,s.squareButtons={},{}
    if s.buttonFrame then
        s.columnPanel=Panel(s.buttonFrame); s.columnPanel:SetAllPoints(s.buttonFrame)
    end
    if s.tab then
        s.tabLevel=s.tab:GetFrameLevel(); s.tabPanel=Panel(s.tab)
        -- Insets match the text band inside the native 32px tab. No change
        -- to tab width, anchors, parenting, docking or click/drag scripts.
        s.tabPanel:SetPoint("TOPLEFT",s.tab,"TOPLEFT",4,-8); s.tabPanel:SetPoint("BOTTOMRIGHT",s.tab,"BOTTOMRIGHT",-4,0)
        s.tabLine=s.tabPanel:CreateTexture(nil,"OVERLAY")
        s.tabLine:SetTexture("Interface\\Buttons\\WHITE8X8"); s.tabLine:SetHeight(2)
        s.tabLine:SetPoint("BOTTOMLEFT",s.tabPanel,"BOTTOMLEFT",1,1); s.tabLine:SetPoint("BOTTOMRIGHT",s.tabPanel,"BOTTOMRIGHT",-1,1)
        s.tab:HookScript("OnEnter",function() s.tabHovered=true; PaintTab(s,s.tabSelected) end)
        s.tab:HookScript("OnLeave",function() s.tabHovered=false; PaintTab(s,s.tabSelected) end)
        s.tab:HookScript("OnShow",function() PaintTab(s) end)
    end
    for suffix,label in pairs({UpButton="^",DownButton="v",BottomButton="="}) do
        local button=_G[cf:GetName().."ButtonFrame"..suffix]
        if button then
            local skin={level=button:GetFrameLevel()}; s.squareButtons[button]=skin
            skin.panel=Panel(button)
            skin.panel:SetPoint("TOPLEFT",button,"TOPLEFT",6,-6); skin.panel:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-6,6)
            skin.label=button:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); skin.label:SetAllPoints(skin.panel); skin.label:SetText(label)
            button:HookScript("OnEnter",function() skin.hovered=true; PaintSquareButton(s,button,skin) end)
            button:HookScript("OnLeave",function() skin.hovered=false; PaintSquareButton(s,button,skin) end)
            for _,method in ipairs({"Enable","Disable"}) do
                if button[method] then hooksecurefunc(button,method,function() PaintSquareButton(s,button,skin) end) end
            end
        end
    end
end
local function SeedHistory(cf,s)
    wipe(s.lines)
    if cf.GetNumMessages and cf.GetMessageInfo then
        local p=ns.GetSettings(); local count=cf:GetNumMessages()
        for i=math.max(1,count-p.copyLines+1),count do
            local text=cf:GetMessageInfo(i); if type(text)=="string" then s.lines[#s.lines+1]=text end
        end
    end
end
local function Style(cf,s)
    local p=ns.GetSettings(); if not active or not p then return end
    -- Wrath reserves 50px below native chat windows. Allow their bottom edge
    -- to reach screen Y=0, retaining the other native screen clamp margins.
    if cf.GetClampRectInsets and cf.SetClampRectInsets then
        if InCombatLockdown() then pending=true
        else
            local left,right,top,bottom=cf:GetClampRectInsets()
            if bottom~=0 then cf:SetClampRectInsets(left,right,top,0) end
        end
    end
    local name=cf:GetName(); for _,suffix in ipairs(chrome) do HideTexture(s,_G[name..suffix]) end
    Backdrop(s.panel,p); s.panel:Show(); cf:SetFont(FontPath(p.font),p.chatFontSize,Outline(p))
    cf:SetFading(p.fadeMessages); cf:SetTimeVisible(p.fadeSeconds)
    cf:EnableMouseWheel(p.mouseWheel); cf:SetScript("OnMouseWheel",p.mouseWheel and Wheel or s.wheel)
    if s.tabText then
        if p.skinTabs then s.tabText:SetFont(FontPath(p.tabFont),p.tabFontSize,Outline(p)) else RestoreFont(s.tabText,s.tabFont) end
    end
    if p.squareSkin then
        PaintTab(s)
        if s.columnPanel then
            for _,suffix in ipairs(chrome) do HideSquareTexture(s,_G[name.."ButtonFrame"..suffix]) end
            Backdrop(s.columnPanel,p); s.columnPanel:Show()
        end
        for button,skin in pairs(s.squareButtons) do PaintSquareButton(s,button,skin) end
        Backdrop(s.copy,p); Backdrop(s.settings,p)
    else
        RestoreSquare(s)
        s.copy:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); s.copy:SetBackdropColor(.03,.045,.05,.8)
        s.settings:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); s.settings:SetBackdropColor(.03,.045,.05,.8)
    end
    local eb=s.edit
    if eb then
        if p.skinEditBox then
            for _,suffix in ipairs({"Left","Right","Mid","FocusLeft","FocusRight","FocusMid"}) do HideTexture(s,_G[eb:GetName()..suffix]) end
            Backdrop(s.editPanel,p); s.editPanel:Show()
        else
            s.editPanel:Hide()
            for _,suffix in ipairs({"Left","Right","Mid","FocusLeft","FocusRight","FocusMid"}) do
                local t=_G[eb:GetName()..suffix]; if t and s.textures[t]~=nil then t:SetAlpha(s.textures[t]) end
            end
        end
        local key=p.editBoxFont=="__chat" and p.font or p.editBoxFont
        eb:SetFont(FontPath(key),p.editBoxFontSize,Outline(p)); eb:SetAutoFocus(false)
        if eb.header then eb.header:SetFont(FontPath(key),p.editBoxFontSize,Outline(p)) end
    end
    if s.buttonFrame then
        if p.hideButtons then s.buttonFrame:Hide()
        elseif s.buttonShown then s.buttonFrame:Show() end
    end
    if p.showCopy then s.copy:Show() else s.copy:Hide() end
    if p.showSettings and cf==ChatFrame1 then s.settings:Show() else s.settings:Hide() end
    while #s.lines>math.max(50,math.min(2000,tonumber(p.copyLines) or 500)) do table.remove(s.lines,1) end
end
local function Capture(cf)
    if states[cf] then return states[cf] end
    local name=cf:GetName(); local edit=cf.editBox or _G[name.."EditBox"]
    local tabText=_G[name.."TabText"]; local bf=cf.buttonFrame or _G[name.."ButtonFrame"]
    local s={lines={},textures={},font=RememberFont(cf),points=Points(cf),width=cf:GetWidth(),height=cf:GetHeight(),level=cf:GetFrameLevel(),
        fading=cf.GetFading and cf:GetFading(),timeVisible=cf.GetTimeVisible and cf:GetTimeVisible() or 120,wheel=cf:GetScript("OnMouseWheel"),
        wheelEnabled=cf:IsMouseWheelEnabled(),hyperlink=cf:GetScript("OnHyperlinkClick"),addMessage=cf.AddMessage,
        edit=edit,editFont=RememberFont(edit),editHeaderFont=edit and RememberFont(edit.header),
        editPoints=edit and Points(edit),autoFocus=edit and edit.IsAutoFocus and edit:IsAutoFocus(),tabText=tabText,tabFont=RememberFont(tabText),
        buttonFrame=bf,buttonShown=bf and bf:IsShown(),clampInsets=cf.GetClampRectInsets and {cf:GetClampRectInsets()}}
    states[cf]=s
    cf:SetFrameLevel(math.max(2,s.level)) -- keep the panel below the native text
    s.panel=Panel(cf); s.panel:SetPoint("TOPLEFT",cf,"TOPLEFT",-6,6); s.panel:SetPoint("BOTTOMRIGHT",cf,"BOTTOMRIGHT",6,-6)
    if edit then s.editPanel=Panel(edit); s.editPanel:SetAllPoints(edit) end
    s.copy=Button(cf,"C",0,function() ns.CopyChat(cf) end)
    s.settings=Button(cf,"O",-24,function() SlashCmdList.EUI335CHAT() end)
    CaptureSquare(cf,s)
    s.wrapper=function(self,text,...)
        local p=ns.GetSettings()
        if active and p and type(text)=="string" then
            if cf~=ChatFrame2 then
                if p.clickableURLs then text=ns.LinkURLs(text) end
                if p.timestamps then text="|cff999999["..date(p.timestampFormat).."]|r "..text end
            end
            s.lines[#s.lines+1]=text; if #s.lines>(tonumber(p.copyLines) or 500) then table.remove(s.lines,1) end
        end
        return s.addMessage(self,text,...)
    end
    s.linkWrapper=function(self,link,text,button,...)
        if active and type(link)=="string" and link:sub(1,7)=="euiurl:" then ShowCopy(link:sub(8)); return end
        if s.hyperlink then return s.hyperlink(self,link,text,button,...) end
    end
    cf:HookScript("OnShow",function() Style(cf,s) end)
    if edit then edit:HookScript("OnHide",function(self) self:ClearFocus() end) end
    if bf then bf:HookScript("OnShow",function(self) local p=ns.GetSettings(); if active and p and p.hideButtons then self:Hide() end end) end
    if cf.Clear then hooksecurefunc(cf,"Clear",function() wipe(s.lines) end) end
    SeedHistory(cf,s)
    return s
end
function ns.Restore()
    active=false; if copyWindow then copyWindow:Hide() end
    for cf,s in pairs(states) do
        if cf.AddMessage==s.wrapper then cf.AddMessage=s.addMessage; s.bridged=false end
        if cf:GetScript("OnHyperlinkClick")==s.linkWrapper then cf:SetScript("OnHyperlinkClick",s.hyperlink); s.linkBridged=false end
        if cf:GetScript("OnMouseWheel")==Wheel then cf:SetScript("OnMouseWheel",s.wheel) end
        cf:EnableMouseWheel(s.wheelEnabled); cf:SetFading(s.fading==nil or s.fading); cf:SetTimeVisible(s.timeVisible); RestoreFont(cf,s.font); cf:SetFrameLevel(s.level)
        if s.clampInsets and cf.SetClampRectInsets then cf:SetClampRectInsets(unpack(s.clampInsets)) end
        if cf==ChatFrame1 then SetPoints(cf,s.points); Size(cf,s.width,s.height) end
        RestoreFont(s.tabText,s.tabFont)
        RestoreSquare(s)
        if s.edit then
            SetPoints(s.edit,s.editPoints); RestoreFont(s.edit,s.editFont); RestoreFont(s.edit.header,s.editHeaderFont)
            s.edit:SetAutoFocus(s.autoFocus); s.editPanel:Hide()
        end
        for texture,alpha in pairs(s.textures) do texture:SetAlpha(alpha) end
        if s.buttonFrame then if s.buttonShown then s.buttonFrame:Show() else s.buttonFrame:Hide() end end
        s.panel:Hide(); s.copy:Hide(); s.settings:Hide()
    end
end
function ns.Apply()
    local p=ns.GetSettings(); if not p then return end
    if InCombatLockdown() then pending=true; return end
    pending=false; if not p.enabled then ns.Restore(); return end
    local wasActive=active; active=true
    local frames={}
    for i=1,NUM_CHAT_WINDOWS or 10 do frames["ChatFrame"..i]=true end
    for _,name in ipairs(CHAT_FRAMES or {}) do frames[name]=true end
    for name in pairs(frames) do
        local cf=_G[name]
        if cf then
            local s=Capture(cf)
            if not wasActive then SeedHistory(cf,s) end
            cf:SetFrameLevel(math.max(2,s.level))
            s.panel:SetFrameLevel(math.max(0,cf:GetFrameLevel()-1))
            -- A later addon may have wrapped our bridge. Re-wrapping that
            -- chain would recurse; leave it attached until it is removed.
            if not s.bridged then s.addMessage=cf.AddMessage; cf.AddMessage=s.wrapper; s.bridged=true end
            if not s.linkBridged then s.hyperlink=cf:GetScript("OnHyperlinkClick"); cf:SetScript("OnHyperlinkClick",s.linkWrapper); s.linkBridged=true end
            Style(cf,s)
            if s.edit then
                s.edit:ClearAllPoints()
                local edge,rel,y=p.inputOnTop and "BOTTOM" or "TOP",p.inputOnTop and "TOP" or "BOTTOM",p.inputOnTop and 28 or -8
                s.edit:SetPoint(edge.."LEFT",cf,rel.."LEFT",-6,y); s.edit:SetPoint(edge.."RIGHT",cf,rel.."RIGHT",6,y)
            end
        end
    end
    Size(ChatFrame1,math.max(200,math.min(900,p.width)),math.max(80,math.min(600,p.height)))
    if resetPosition and states[ChatFrame1] then SetPoints(ChatFrame1,states[ChatFrame1].points); resetPosition=false end
    if p.position then ChatFrame1:ClearAllPoints(); ChatFrame1:SetPoint(p.position.point,UIParent,p.position.relPoint,p.position.x,p.position.y) end
end
function ns.ResetPosition()
    local p=ns.GetSettings(); if not p then return end
    p.position=nil; resetPosition=true; ns.Apply()
end
ECHAT.ApplyFonts=ns.Apply; ECHAT.ApplyChatFontSize=ns.Apply; ECHAT.ApplyTabAppearance=ns.Apply
ECHAT.ApplyTabLayout=ns.Apply; ECHAT.ApplyBackground=ns.Apply
function addon:OnInitialize()
    -- Lua 5.1 xpcall in Lite does not forward self.
    addon.db=E.Lite.NewDB("EllesmereUIChatDB",defaults); _G._ECHAT_DB=addon.db
    _G._ECHAT_Apply=ns.Apply; _G._ECHAT_RefreshAll=ns.Apply -- Core profile reapply hook
    SLASH_EUI335CHAT1="/echat"
    SlashCmdList.EUI335CHAT=function()
        if InCombatLockdown() then return end
        if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; E:ShowModule(ADDON_NAME)
    end
    SLASH_EUI335COPYCHAT1="/ecopy"
    SlashCmdList.EUI335COPYCHAT=function() local p=ns.GetSettings(); if p and p.enabled then ns.CopyChat() end end
end
function addon:OnEnable()
    if not addon.db then return end
    ns.Apply()
    if type(FCFTab_UpdateColors)=="function" then
        hooksecurefunc("FCFTab_UpdateColors",function(tab,selected)
            local cf=_G["ChatFrame"..tab:GetID()]; local s=cf and states[cf]
            if s then PaintTab(s,selected) end
        end)
    end
    if E.RegisterUnlockElements and E.MakeUnlockElement then
        E:RegisterUnlockElements({E.MakeUnlockElement({key="EUI335_Chat",label="Chat",group="Chat",order=600,
            noResize=true,noAnchorTo=true,getFrame=function() return ChatFrame1 end,
            getSize=function() return ChatFrame1:GetWidth(),ChatFrame1:GetHeight() end,
            isHidden=function() local p=ns.GetSettings(); return not p or not p.enabled end,
            savePos=function(_,point,relPoint,x,y) local p=ns.GetSettings(); if p then p.position={point=point,relPoint=relPoint,x=x,y=y} end end,
            loadPos=function() local p=ns.GetSettings(); return p and p.position end,
            clearPos=ns.ResetPosition,
            applyPos=ns.Apply,
        })},ADDON_NAME)
    end
    local events=CreateFrame("Frame"); events:RegisterEvent("PLAYER_ENTERING_WORLD"); events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent",function(_,event) if event=="PLAYER_ENTERING_WORLD" or pending then ns.Apply() end end); ns.events=events
    for _,name in ipairs({"FCF_OpenNewWindow","FCF_OpenTemporaryWindow","FCF_SetChatWindowFontSize","FCF_SetWindowAlpha","FCF_SetWindowColor"}) do
        if type(_G[name])=="function" then hooksecurefunc(name,function() if active then ns.Apply() end end) end
    end
end
