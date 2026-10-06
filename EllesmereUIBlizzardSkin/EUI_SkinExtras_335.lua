-- Raid pullouts, battleground capture bars, the GM chat status box and Ace3
-- (AceGUI-3.0) widgets: flat dark backdrops in the window skin style. Native scripts, secure unit buttons and layout stay native.
local _,ns=...
if not ns.IsWrath then return end
local E=EllesmereUI
local flat="Interface\\Buttons\\WHITE8X8"
local X={}; ns.SkinExtras=X
table.insert(ns.extras,X)
local function Own(obj) ns.owned[obj]=true; return obj end
local function Kind(obj,kind) return obj and obj.GetObjectType and obj:GetObjectType()==kind end
local function Accent()
    local eg=E.ELLESMERE_GREEN or {}
    return eg.r or .047,eg.g or .824,eg.b or .616
end
local function Flat(frame,alpha)
    if not frame or not frame.SetBackdrop then return end
    frame:SetBackdrop({bgFile=flat,edgeFile=flat,edgeSize=1})
    frame:SetBackdropColor(.06,.06,.06,alpha or .9); frame:SetBackdropBorderColor(.2,.2,.2,1)
end

-- Raid pullouts ------------------------------------------------------------
local pullouts={}
local function PulloutBar(d,bar,on)
    if not bar or not bar.GetStatusBarTexture then return end
    local name=bar:GetName(); local border=name and _G[name.."Frame"]
    if on then
        if d.bars[bar]==nil then local texture=bar:GetStatusBarTexture(); d.bars[bar]=texture and texture:GetTexture() or false end
        bar:SetStatusBarTexture(flat)
        if border then border:SetAlpha(0) end
    elseif d.bars[bar]~=nil then
        if d.bars[bar] then bar:SetStatusBarTexture(d.bars[bar]) end
        if border then border:SetAlpha(1) end
    end
end
function X.SkinPullout(frame)
    if not frame or not frame.GetName or not frame:GetName() then return end
    local on=ns.WindowSkinEnabled("reskinRaidPullouts")
    local d=pullouts[frame]
    if not d then if not on then return end; d={bars={}}; pullouts[frame]=d end
    local menu=_G[frame:GetName().."MenuBackdrop"]
    if menu and menu.SetBackdrop then
        if on then
            if d.backdrop==nil then d.backdrop=menu:GetBackdrop() or false; d.alpha=menu:GetAlpha() end
            Flat(menu,.85); menu:SetAlpha(1)
        elseif d.backdrop~=nil then
            menu:SetBackdrop(d.backdrop or nil); menu:SetBackdropBorderColor(.5,.5,.5)
            local c=TOOLTIP_DEFAULT_BACKGROUND_COLOR
            if c then menu:SetBackdropColor(c.r,c.g,c.b) end
            menu:SetAlpha(d.alpha or .7)
        end
    end
    for _,button in ipairs(frame.buttons or {}) do PulloutBar(d,button.healthbar,on); PulloutBar(d,button.manabar,on) end
end
function X.SkinPullouts()
    for i=1,(tonumber(NUM_RAID_PULLOUT_FRAMES) or 0) do X.SkinPullout(_G["RaidPullout"..i]) end
end

-- Ace3 ---------------------------------------------------------------------
-- AceGUI recycles widgets, so each object is styled once when created.
-- Turning the toggle off applies to new widgets; /reload restores the rest.
local done={}
local function HideTextures(frame,keep)
    for _,region in ipairs({frame:GetRegions()}) do
        if Kind(region,"Texture") and region~=keep and not ns.owned[region] then region:SetAlpha(0) end
    end
end
local function Highlight(texture)
    if not texture then return end
    texture:SetTexture(flat); texture:SetTexCoord(0,1,0,1); texture:SetVertexColor(1,1,1,.1)
end
local function AceButton(button)
    if not button or done[button] then return end
    done[button]=true
    local highlight=button.GetHighlightTexture and button:GetHighlightTexture()
    for _,getter in ipairs({"GetNormalTexture","GetPushedTexture","GetDisabledTexture"}) do
        local texture=button[getter] and button[getter](button)
        if texture then texture:SetAlpha(0) end
    end
    HideTextures(button,highlight); Highlight(highlight)
    Flat(button,.95); button:SetBackdropBorderColor(.25,.25,.25,1)
end
local function AceBox(frame,alpha)
    if not frame or done[frame] then return end
    done[frame]=true; Flat(frame,alpha)
end
local function AceEditBox(editbox)
    if not editbox or done[editbox] then return end
    done[editbox]=true
    HideTextures(editbox); Flat(editbox,.8)
end
local function AceTab(widget,tab)
    if not tab then return end
    if not done[tab] then
        done[tab]=true
        local highlight=tab.GetHighlightTexture and tab:GetHighlightTexture()
        HideTextures(tab,highlight)
        local bg=Own(CreateFrame("Frame",nil,tab)); bg:EnableMouse(false)
        bg:SetPoint("TOPLEFT",tab,"TOPLEFT",3,-3); bg:SetPoint("BOTTOMRIGHT",tab,"BOTTOMRIGHT",-3,1)
        bg:SetFrameLevel(math.max(0,tab:GetFrameLevel()-1)); Flat(bg,.95); tab.euiBg=bg
        if highlight then Highlight(highlight); highlight:ClearAllPoints(); highlight:SetAllPoints(bg) end
    end
    local r,g,b=Accent()
    if tab.selected then tab.euiBg:SetBackdropBorderColor(r,g,b,1) else tab.euiBg:SetBackdropBorderColor(.25,.25,.25,1) end
end
local function AceTabs(widget) for _,tab in ipairs(widget.tabs or {}) do AceTab(widget,tab) end end
local function AceChildren(frame)
    for _,child in ipairs({frame:GetChildren()}) do
        if Kind(child,"Button") and child.GetNormalTexture and child:GetNormalTexture() then AceButton(child) end
    end
end
local aceSkins={
    Frame=function(w)
        HideTextures(w.frame); AceBox(w.frame,.92); AceChildren(w.frame)
        local status=w.statustext and w.statustext:GetParent()
        if status and status~=w.frame then AceBox(status,.6) end
    end,
    Window=function(w) HideTextures(w.frame); AceBox(w.frame,.92); AceChildren(w.frame) end,
    InlineGroup=function(w) local border=w.content and w.content:GetParent(); if border and border~=w.frame then AceBox(border,.5) end end,
    TreeGroup=function(w) AceBox(w.treeframe,.6); AceBox(w.border,.5) end,
    TabGroup=function(w)
        AceBox(w.border,.5)
        if type(w.BuildTabs)=="function" then hooksecurefunc(w,"BuildTabs",AceTabs) end
        if type(w.SelectTab)=="function" then hooksecurefunc(w,"SelectTab",AceTabs) end
        AceTabs(w)
    end,
    Button=function(w) AceButton(w.frame) end,
    Keybinding=function(w) AceButton(w.button) end,
    EditBox=function(w) AceEditBox(w.editbox); AceButton(w.button) end,
    MultiLineEditBox=function(w) AceBox(w.scrollBG,.8); AceButton(w.button) end,
    Dropdown=function(w)
        local dropdown=w.dropdown; if not dropdown or done[dropdown] then return end
        done[dropdown]=true; HideTextures(dropdown)
        local bg=Own(CreateFrame("Frame",nil,dropdown)); bg:EnableMouse(false)
        bg:SetPoint("TOPLEFT",dropdown,"TOPLEFT",16,-3); bg:SetPoint("BOTTOMRIGHT",dropdown,"BOTTOMRIGHT",-18,5)
        bg:SetFrameLevel(math.max(0,dropdown:GetFrameLevel()-1)); Flat(bg,.8)
    end,
    ["Dropdown-Pullout"]=function(w) AceBox(w.frame,.95); AceBox(w.slider,.6) end,
    Slider=function(w)
        local slider=w.slider; if not slider or done[slider] then return end
        done[slider]=true; Flat(slider,.8)
        local thumb=slider.GetThumbTexture and slider:GetThumbTexture()
        if thumb then thumb:SetTexture(flat); thumb:SetVertexColor(Accent()); thumb:SetWidth(8); thumb:SetHeight(14) end
        AceEditBox(w.editbox)
    end,
    Heading=function(w)
        for _,line in ipairs({w.left,w.right}) do
            if line and line.SetTexture then line:SetTexture(flat); line:SetTexCoord(0,1,0,1); line:SetVertexColor(.3,.3,.3,1); line:SetHeight(1) end
        end
    end,
    CheckBox=function(w)
        local bg=w.checkbg; if not bg or done[bg] then return end
        done[bg]=true
        local box=Own(CreateFrame("Frame",nil,w.frame)); box:EnableMouse(false)
        box:SetPoint("TOPLEFT",bg,"TOPLEFT",4,-4); box:SetPoint("BOTTOMRIGHT",bg,"BOTTOMRIGHT",-4,4)
        box:SetFrameLevel(math.max(0,w.frame:GetFrameLevel()-1)); Flat(box,.9); box:SetBackdropBorderColor(.3,.3,.3,1)
        bg:SetAlpha(0)
        if w.highlight then Highlight(w.highlight); w.highlight:ClearAllPoints(); w.highlight:SetAllPoints(box) end
    end,
}
function X.SkinAceWidget(widget)
    if type(widget)~="table" or done[widget] or not ns.WindowSkinEnabled("reskinAce3") then return end
    local skin=aceSkins[widget.type]
    if skin then done[widget]=true; pcall(skin,widget) end
end
local aceCreate
function X.HookAce()
    local lib=LibStub and LibStub("AceGUI-3.0",true)
    if not lib or type(lib.Create)~="function" or lib.Create==aceCreate then return end
    -- A newer AceGUI loaded by a later addon replaces Create; wrap it again.
    local native=lib.Create
    aceCreate=function(self,kind,...)
        local widget=native(self,kind,...)
        X.SkinAceWidget(widget)
        return widget
    end
    lib.Create=aceCreate
end

-- Battleground capture bar -------------------------------------------------
-- Flat faction-coloured zones; the art frame and icon glows are hidden.
local captures={}
local CAPTURE_COLORS={LeftBar={.1,.4,.95},RightBar={.9,.15,.15},MiddleBar={.85,.85,.85},LeftLine={0,0,0},RightLine={0,0,0}}
local function SaveTexture(d,t)
    if d.textures[t]==nil then d.textures[t]={t:GetTexture(),{t:GetTexCoord()},{t:GetVertexColor()}} end
end
local function Unnamed(frame)
    for _,region in ipairs({frame:GetRegions()}) do
        if Kind(region,"Texture") and not region:GetName() and not ns.owned[region] then return region end
    end
end
function X.SkinCaptureBar(bar)
    if not bar or not bar.GetName or not bar:GetName() then return end
    local on=ns.WindowSkinEnabled("reskinCaptureBar")
    local d=captures[bar]
    if not d then if not on then return end; d={textures={},hidden={}}; captures[bar]=d end
    local name=bar:GetName()
    local indicator=_G[name.."Indicator"]
    local marker=indicator and Unnamed(indicator)
    if on then
        if not d.panel then
            local panel=Own(CreateFrame("Frame",nil,bar)); panel:EnableMouse(false)
            local left,right=_G[name.."LeftBar"],_G[name.."RightBar"]
            panel:SetPoint("TOPLEFT",left or bar,"TOPLEFT",-1,1); panel:SetPoint("BOTTOMRIGHT",right or bar,"BOTTOMRIGHT",1,-1)
            panel:SetFrameLevel(math.max(0,bar:GetFrameLevel()-1)); Flat(panel,.9)
            d.panel=panel
        end
        d.panel:Show()
        for suffix,c in pairs(CAPTURE_COLORS) do
            local t=_G[name..suffix]
            if t then SaveTexture(d,t); t:SetTexture(flat); t:SetTexCoord(0,1,0,1); t:SetVertexColor(c[1],c[2],c[3],1) end
        end
        for _,line in ipairs({_G[name.."LeftLine"],_G[name.."RightLine"]}) do if line then line:SetWidth(1) end end
        for _,t in ipairs({Unnamed(bar),_G[name.."LeftIconHighlight"],_G[name.."RightIconHighlight"]}) do
            if t then d.hidden[t]=true; t:SetAlpha(0) end
        end
        if marker then
            SaveTexture(d,marker); marker:SetTexture(flat); marker:SetTexCoord(0,1,0,1); marker:SetVertexColor(1,1,1,1)
            if not d.size then d.size={indicator:GetWidth(),indicator:GetHeight()} end
            indicator:SetWidth(3); indicator:SetHeight(15)
        end
    else
        if d.panel then d.panel:Hide() end
        for t,saved in pairs(d.textures) do
            t:SetTexture(saved[1]); t:SetTexCoord(unpack(saved[2])); t:SetVertexColor(unpack(saved[3]))
        end
        for _,line in ipairs({_G[name.."LeftLine"],_G[name.."RightLine"]}) do if line then line:SetWidth(3) end end
        for t in pairs(d.hidden) do t:SetAlpha(1) end
        if d.size and indicator then indicator:SetWidth(d.size[1]); indicator:SetHeight(d.size[2]) end
        captures[bar]=nil
    end
end
function X.SkinCaptureBars()
    for i=1,(tonumber(NUM_EXTENDED_UI_FRAMES) or 0) do X.SkinCaptureBar(_G["WorldStateCaptureBar"..i]) end
end

-- GM chat status ------------------------------------------------------------
-- Blizzard_GMChatUI loads on demand; its backdrop sits on an unnamed child button.
local gm
function X.SkinGMStatus()
    local frame=_G.GMChatStatusFrame
    if not frame then return end
    local on=ns.WindowSkinEnabled("reskinGMStatus")
    if not gm then
        if not on then return end
        for _,child in ipairs({frame:GetChildren()}) do
            if Kind(child,"Button") and not child:GetName() and child.GetBackdrop and child:GetBackdrop() then gm={box=child,backdrop=child:GetBackdrop()}; break end
        end
        if not gm then return end
    end
    local box=gm.box
    if on then
        Flat(box,.92); box:SetBackdropBorderColor(Accent())
    else
        box:SetBackdrop(gm.backdrop)
        local border,bg=TOOLTIP_DEFAULT_COLOR,TOOLTIP_DEFAULT_BACKGROUND_COLOR
        if border then box:SetBackdropBorderColor(border.r,border.g,border.b) end
        if bg then box:SetBackdropColor(bg.r,bg.g,bg.b) end
        gm=nil
    end
end

local hooked,captureHooked=false,false
function X.Apply()
    if not hooked and type(_G.RaidPullout_Update)=="function" then
        hooked=true; hooksecurefunc("RaidPullout_Update",function(frame) X.SkinPullout(frame) end)
    end
    if not captureHooked and type(_G.WorldStateAlwaysUpFrame_Update)=="function" then
        captureHooked=true; hooksecurefunc("WorldStateAlwaysUpFrame_Update",X.SkinCaptureBars)
    end
    X.SkinPullouts()
    X.SkinCaptureBars()
    X.SkinGMStatus()
    X.HookAce()
end
