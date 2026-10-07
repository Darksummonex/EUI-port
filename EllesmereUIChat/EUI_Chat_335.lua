-- Native Wrath windows remain responsible for routing, links, docking, tabs and
-- text input. The Retail EUI panel, tab strip, sidebar and text features are
-- drawn over them and handed back by ns.Restore().
local ADDON_NAME, ns = ...
local E = EllesmereUI
if not E or not E.Lite or not ChatFrame1 then return end
E._ModuleNS[ADDON_NAME] = ns
local addon = E.Lite.NewAddon(ADDON_NAME)
ns.addon, ns.IsWrath, ns.ECHAT = addon, true, {}
local ECHAT = ns.ECHAT
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MEDIA = "Interface\\AddOns\\EllesmereUIChat\\Media_335\\"
local PAD_X, PAD_TOP, GAP = 6, 4, 6
local floor, max, min = math.floor, math.max, math.min
if E.RegisterBorderDefaults then
    E.RegisterBorderDefaults("chat",{blizz={defaultSize="heavy",sizes={
        none={offsetX=0,offsetY=0,shiftX=0,shiftY=0},thin={offsetX=2,offsetY=1,shiftX=0,shiftY=0},
        normal={offsetX=3,offsetY=2,shiftX=0,shiftY=0},heavy={offsetX=4,offsetY=2,shiftX=1,shiftY=0},
        strong={offsetX=4,offsetY=2,shiftX=2,shiftY=0}}}})
end
local function RGBA(r,g,b,a) return {r=r,g=g,b=b,a=a} end
local defaults = {profile={
    chat={
        enabled=true, visibility="always",
        bgAlpha=.65, bgR=.03, bgG=.045, bgB=.05, bgTexture="none",
        timestampFormat="%I:%M ", timestampAll=false,
        font="__global", outlineMode="__global", chatFontSize=12,
        tabFont="__global", tabFontSize=11, tabFontColor=RGBA(1,1,1,.65), tabFontColorActive=RGBA(1,1,1,1),
        tabFontColorMode="custom", tabFontColorActiveMode="custom",
        editBoxFont="__chat", editBoxFontSize=12, editBoxHeight=23, inputOnTop=false,
        hideBorders=false, innerBorderColor=RGBA(1,1,1,.06), innerBorderColorMode="custom",
        panelBorderBehind=false, panelBorderTexture="solid", panelBorderThickness="none",
        panelBorderColorMode="custom", panelBorderColor={r=1,g=1,b=1}, panelBorderOpacity=.18,
        tabBackgroundTexture="none", activeTabBorder=true, tabBorderColorActive=RGBA(1,1,1,.18),
        extendBgBehindTabs=false, tabSpacing=1, tabPadding=0, syncTabBorder=true,
        tabBorderTexture="solid", tabBorderThickness="none", tabBorderColorMode="custom",
        tabBorderColor={r=1,g=1,b=1}, tabBorderOpacity=.18,
        alignTabsToPanel=false, tabHeight=24, tabInnerPaddingX=12, tabOffsetX=0,
        tabBackgroundColor=RGBA(.03,.045,.05,.44), tabBackgroundColorActive=RGBA(.03,.045,.05,.65),
        tabBackgroundColorActiveMode="custom",
        activeUnderline=true, activeUnderlineColorMode="accent", activeUnderlineColor=RGBA(.05,.82,.61,1),
        sidebarVisibility="always", sidebarRight=false, sidebarSeparate=false, sidebarSeparateSpacing=8,
        sidebarWidth=40, hideSidebarBg=false, scrollButtonOnChat=false,
        showFriends=true, showGuild=false, showDurability=false, showCopy=true, showVoice=false,
        showSettings=true, showScroll=true,
        iconR=1, iconG=1, iconB=1, iconUseAccent=false,
        sidebarIconScale=1, sidebarIconSpacing=10, freeMoveIcons=false, iconPositions={},
        sidebarIconOrder={showCopy=1,showVoice=3,showSettings=4},
        hideTooltipOnHover=true,
        idleFadeEnabled=true, idleFadeDelay=15, idleFadeStrength=40,
        useBlizzardStyle=false, useClassicStyle=false, lockChatSize=false,
        abbreviateChannels=true, abbreviateChannelLetters=false, classColorNames=true,
        persistChatHistory=true, persistChatHistoryMaxLines=100,
        whisperSoundKey="none",
        spamFilterEnabled=false, spamFilterWindow=15, spamFilterAnySender=false,
        spamFilterPublic=true, spamFilterGroup=false, spamFilterWhispers=false,
        spamFilterAchievements=false, spamFilterTrade=false, spamFilterRecruitment=false,
        spamFilterKeywordsEnabled=false, spamFilterKeywords="",
        spamFilterHardcoreDeaths=false, spamFilterHardcoreKeepLevel=81,
        clickableURLs=true, copyLines=500, mouseWheel=true, fadeMessages=false, fadeSeconds=120,
        width=420, height=180,
    },
    chatBubbles={
        enabled=false, say=true, yell=true, party=true, npc=true, emote=true, hideInInstances=false,
        padding=8, maxWidth=260, offsetY=0, background=true, bgColor={r=0,g=0,b=0}, bgAlpha=.5,
        borderSize=1, borderColor=RGBA(0,0,0,1), fontSize=12, textColor={r=1,g=1,b=1},
        followBlizzardColor=false,
    },
}}
ns.defaults = defaults
local states, active, pending, resetPosition = {}, false, false, false
local stampFrame, stampTime
ns.states = states
local chrome = {"Background","TopLeftTexture","BottomLeftTexture","TopRightTexture",
    "BottomRightTexture","LeftTexture","RightTexture","BottomTexture","TopTexture"}
local tabChrome = {"leftTexture","middleTexture","rightTexture","leftSelectedTexture","middleSelectedTexture",
    "rightSelectedTexture","leftHighlightTexture","middleHighlightTexture","rightHighlightTexture"}
local editChrome = {"Left","Right","Mid","FocusLeft","FocusRight","FocusMid"}
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function Shown(f,show) if not f then return end; if show then f:Show() else f:Hide() end end
local function Points(f)
    local result={}; for i=1,f:GetNumPoints() do result[i]={f:GetPoint(i)} end; return result
end
local function SetPoints(f,points)
    f:ClearAllPoints(); for _,point in ipairs(points) do f:SetPoint(unpack(point)) end
end
function ns.GetSettings() return addon.db and addon.db.profile.chat end
function ns.GetBubbleSettings() return addon.db and addon.db.profile.chatBubbles end
ECHAT.DB = ns.GetSettings
-- Style page flags are latched for the session; the page reloads on a switch.
-- Stock styles keep the native chrome.
local latchedStyle
function ns.ChatStyle()
    if latchedStyle then return latchedStyle end
    local p=ns.GetSettings(); if not p then return "eui" end
    latchedStyle=p.useClassicStyle and "classic" or p.useBlizzardStyle and "blizzard" or "eui"
    return latchedStyle
end
local function Skinned() return ns.ChatStyle()=="eui" end

-- 0.3 keys survive only where the user changed them (Lite strips defaults on
-- logout), so carrying them over keeps real customisations only.
local LABEL_OF_STEP = {[0]="none","thin","normal","heavy","strong"}
local OLD_STAMPS = {["%H:%M"]="%H:%M ",["%I:%M %p"]="%I:%M %p ",["%H:%M:%S"]="%H:%M:%S "}
function ns.Migrate(p)
    -- The 0.3 panel was a different look; a cleared 0.3 background would hide
    -- the Retail panel and sidebar, which share this opacity.
    if not p._wrath05 then
        p._wrath05=true
        if p.bgAlpha==0 and not p._wrath04 then p.bgAlpha=defaults.profile.chat.bgAlpha end
    end
    if p._wrath04 then return end
    p._wrath04=true
    if p.borderSize~=nil or p.borderR~=nil or p.borderG~=nil or p.borderB~=nil or p.borderA~=nil then
        local n=min(4,max(0,floor(tonumber(p.borderSize or 1) or 1)))
        if n>0 then
            p.panelBorderTexture,p.panelBorderThickness,p.panelBorderColorMode="solid",LABEL_OF_STEP[n],"custom"
            p.panelBorderColor={r=p.borderR or 0,g=p.borderG or 0,b=p.borderB or 0}; p.panelBorderOpacity=p.borderA or 1
        end
    end
    if p.timestamps==false then p.timestampFormat="none"
    elseif OLD_STAMPS[p.timestampFormat] then p.timestampFormat=OLD_STAMPS[p.timestampFormat] end
    for _,key in ipairs({"borderSize","borderR","borderG","borderB","borderA","timestamps","skinTabs",
        "skinEditBox","squareSkin","hideButtons"}) do p[key]=nil end
end

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
-- "Drop Shadow" is the no-outline mode, as on Retail.
local function ApplyFont(fs,path,size,p)
    if not fs or not fs.SetFont then return end
    local flag=Outline(p); fs:SetFont(path,size,flag)
    if fs.SetShadowOffset then
        if flag=="" then fs:SetShadowOffset(1,-1); if fs.SetShadowColor then fs:SetShadowColor(0,0,0,1) end
        else fs:SetShadowOffset(0,0) end
    end
end
local function RememberFont(f) return f and f.GetFont and {f:GetFont()} end
local function RestoreFont(f,font) if f and font and font[1] then f:SetFont(unpack(font)) end end
local function Accent()
    if E.GetAccentColor then local r,g,b=E.GetAccentColor(); if r then return r,g,b end end
    local eg=E.ELLESMERE_GREEN; if eg then return eg.r,eg.g,eg.b end
    return .05,.82,.61
end
local function ModeColor(mode,c,fallbackA)
    local a=(c and c.a~=nil) and c.a or fallbackA or 1
    if mode=="accent" then local r,g,b=Accent(); return r,g,b,a end
    if mode=="class" then
        local _,class=UnitClass("player"); local cc=class and RAID_CLASS_COLORS[class]
        if cc then return cc.r,cc.g,cc.b,a end
    end
    c=c or {}; return c.r or 1,c.g or 1,c.b or 1,a
end
local function Hex(r,g,b)
    if E.HexColor then return E.HexColor(r,g,b) end
    return string.format("|cff%02x%02x%02x",floor(r*255+.5),floor(g*255+.5),floor(b*255+.5))
end
local function InnerColor(p) return ModeColor(p.innerBorderColorMode,p.innerBorderColor,.06) end

if E.BuildBarTextureTables then
    ns.chatBgTextures,ns.chatBgTextureNames,ns.chatBgTextureOrder=E.BuildBarTextureTables(true)
end
if not (ns.chatBgTextures and ns.chatBgTextureNames and ns.chatBgTextureOrder) then
    ns.chatBgTextures,ns.chatBgTextureNames,ns.chatBgTextureOrder={},{none="None"},{"none"}
end
function ECHAT.RefreshBgTextureCatalogue()
    if E.AppendSharedMediaTextures then
        E.AppendSharedMediaTextures(ns.chatBgTextureNames,ns.chatBgTextureOrder,nil,ns.chatBgTextures)
    end
end
local function TexturePath(key)
    if not key or key=="none" then return nil end
    ECHAT.RefreshBgTextureCatalogue()
    if E.ResolveTexturePath then return E.ResolveTexturePath(ns.chatBgTextures,key,nil) end
    return ns.chatBgTextures[key]
end
local function Paint(tex,key,r,g,b,a) tex:SetTexture(TexturePath(key) or WHITE); tex:SetVertexColor(r,g,b,a) end
local function Edges(f,layer,region)
    region=region or f
    local edges={}
    for i,pair in ipairs({{"TOPLEFT","TOPRIGHT"},{"BOTTOMLEFT","BOTTOMRIGHT"},{"TOPLEFT","BOTTOMLEFT"},{"TOPRIGHT","BOTTOMRIGHT"}}) do
        local t=f:CreateTexture(nil,layer or "OVERLAY"); t:SetTexture(WHITE)
        t:SetPoint(pair[1],region,pair[1],0,0); t:SetPoint(pair[2],region,pair[2],0,0)
        if i<=2 then t:SetHeight(1) else t:SetWidth(1) end
        edges[i]=t
    end
    return edges
end
local function EdgeColor(edges,r,g,b,a) for _,t in ipairs(edges) do t:SetVertexColor(r,g,b,a) end end
local function EdgeSize(edges,n) for i,t in ipairs(edges) do if i<=2 then t:SetHeight(n) else t:SetWidth(n) end end end
local function ShowEdges(edges,show) for _,t in ipairs(edges) do Shown(t,show) end end
local STEP = {none=0,thin=1,normal=2,heavy=3,strong=4}
-- Same call shape as Retail; prefix is "panel" or "tab".
local function ApplyBorder(frame,p,prefix)
    local key=p[prefix.."BorderThickness"] or "none"; local step=STEP[key] or 0
    local mode=p[prefix.."BorderColorMode"] or "custom"
    local r,g,b=ModeColor(mode,p[prefix.."BorderColor"])
    local a=p[prefix.."BorderOpacity"]; if a==nil then a=mode=="custom" and .18 or .5 end
    local tex=p[prefix.."BorderTexture"] or "solid"
    if step==0 or not E.ApplyBorderStyle then frame:Hide(); return end
    local px=E.BorderPx and E.BorderPx(p[prefix.."BorderThicknessPx"],step,tex)
    E.ApplyBorderStyle(frame,step,r,g,b,a,tex,p[prefix.."BorderOffsetX"],p[prefix.."BorderOffsetY"],
        p[prefix.."BorderShiftX"],p[prefix.."BorderShiftY"],"chat",key,nil,px)
    frame:Show()
end
local function Geometry(p)
    local h=max(10,min(60,tonumber(p.editBoxHeight) or 23))
    local area=(p.tabHeight or 24)+(p.tabPadding or 0)
    local ext=p.extendBgBehindTabs and area or 0
    if p.inputOnTop then return GAP+h,PAD_TOP,ext,h end
    return PAD_TOP,GAP+h,ext,h
end

-- Never nest URL links inside existing item/player links or texture escapes.
local function MapPlain(text,fn)
    local out, at = {}, 1
    while at<=#text do
        local first=text:find("|",at,true)
        if not first then out[#out+1]=fn(text:sub(at)); break end
        if first>at then out[#out+1]=fn(text:sub(at,first-1)) end
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
local function URLHex() local eg=E.ELLESMERE_GREEN or {r=.05,g=.82,b=.61}; return Hex(eg.r,eg.g,eg.b) end
local function PlainURLs(text)
    return (text:gsub("(%S+)",function(token)
        if not (token:match("^https?://") or token:match("^www%.")) then return token end
        local url,tail=token:match("^(.-)([.,;!?)%]]*)$")
        if not url or #url<5 then return token end
        return URLHex().."|Heuiurl:"..url.."|h["..url.."]|h|r"..tail
    end))
end
function ns.LinkURLs(text) return MapPlain(text,PlainURLs) end
function ns.PlainText(text)
    return (text:gsub("|H.-|h(.-)|h","%1"):gsub("|T.-|t",""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("||","|"))
end

-- Group links come from the localized CHAT_MSG_* labels; world channels
-- carry the player's own slot number in Wrath, so letters go by name.
local groupAbbr
local function GroupAbbr()
    if groupAbbr then return groupAbbr end
    groupAbbr={}
    for key,abbr in pairs({PARTY="P",PARTY_LEADER="PL",PARTY_GUIDE="PG",RAID="R",RAID_LEADER="RL",RAID_WARNING="RW",
        GUILD="G",OFFICER="O",BATTLEGROUND="BG",BATTLEGROUND_LEADER="BL"}) do
        local label=_G["CHAT_MSG_"..key]; if type(label)=="string" and label~="" then groupAbbr[label:lower()]=abbr end
    end
    for label,abbr in pairs({party="P",["party leader"]="PL",["dungeon guide"]="PG",raid="R",["raid leader"]="RL",
        ["raid warning"]="RW",guild="G",officer="O",battleground="BG",["battleground leader"]="BL"}) do
        if not groupAbbr[label] then groupAbbr[label]=abbr end
    end
    return groupAbbr
end
local WORLD_LETTERS = {general="Ge",trade="T",localdefense="LD",worlddefense="WD",lookingforgroup="LFG",guildrecruitment="GR"}
function ns.AbbreviateChannels(text,letters)
    if not text:find("|Hchannel:",1,true) then return text end
    return (text:gsub("(|Hchannel:[^|]*|h)%[([^%]]*)%](|h)",function(open,label,close)
        local num,name=label:match("^(%d+)%.%s*(.*)$")
        if num then
            if letters then
                local base=(name:match("^(.-)%s+%-") or name):gsub("%s",""):lower()
                if WORLD_LETTERS[base] then return open.."["..WORLD_LETTERS[base].."]"..close end
            end
            return open.."["..num.."]"..close
        end
        local abbr=GroupAbbr()[label:lower()]
        if abbr then return open.."["..abbr.."]"..close end
    end))
end

local roster = {}
ns.roster = roster
local function AddRoster(name,class)
    local c=name and class and (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class])
    if c then roster[(name:match("^[^%-]+") or name):lower()]=Hex(c.r,c.g,c.b) end
end
function ns.RebuildRoster()
    wipe(roster)
    local raid=GetNumRaidMembers and GetNumRaidMembers() or 0
    if raid>0 then
        for i=1,raid do local name,_,_,_,_,class=GetRaidRosterInfo(i); AddRoster(name,class) end
    else
        AddRoster(UnitName("player"),select(2,UnitClass("player")))
        for i=1,(GetNumPartyMembers and GetNumPartyMembers() or 0) do
            local unit="party"..i; AddRoster(UnitName(unit),select(2,UnitClass(unit)))
        end
    end
end
local function ColorPlain(chunk)
    return (chunk:gsub("[%a\128-\255]+",function(word) local hex=roster[word:lower()]; if hex then return hex..word.."|r" end end))
end
function ns.ColorNames(text) if not next(roster) then return text end; return MapPlain(text,ColorPlain) end

local function Dimmer(onClick)
    local d=CreateFrame("Button",nil,UIParent); d:SetAllPoints(UIParent); d:SetFrameStrata("DIALOG"); d:SetFrameLevel(10)
    local t=d:CreateTexture(nil,"BACKGROUND"); t:SetAllPoints(d); t:SetTexture(WHITE); t:SetVertexColor(0,0,0,.25)
    d:SetScript("OnClick",onClick); d:Hide(); return d
end
local function Popup(name,w,h)
    local f=CreateFrame("Frame",name,UIParent); Size(f,w,h); f:SetFrameStrata("DIALOG"); f:SetFrameLevel(20); f:EnableMouse(true)
    local bg=f:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(f); bg:SetTexture(WHITE); bg:SetVertexColor(.06,.08,.10,.95)
    EdgeColor(Edges(f),1,1,1,.15)
    UISpecialFrames[#UISpecialFrames+1]=name
    return f
end
local copyWindow, copyDimmer
local function EnsureCopyWindow()
    if copyWindow then return copyWindow end
    local f=Popup("EllesmereUIChat_Copy335",520,340); f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    copyDimmer=Dimmer(function() f:Hide() end)
    local title=f:CreateFontString(nil,"OVERLAY"); title:SetFont(FontPath(),13,""); title:SetTextColor(1,1,1,.9)
    title:SetPoint("TOPLEFT",f,"TOPLEFT",14,-12); title:SetText("Copy Chat")
    local hint=f:CreateFontString(nil,"OVERLAY"); hint:SetFont(FontPath(),9,""); hint:SetTextColor(1,1,1,.5)
    hint:SetPoint("TOPRIGHT",f,"TOPRIGHT",-14,-14); hint:SetText("Ctrl+C to copy, Escape to close")
    local scroll=CreateFrame("ScrollFrame","EllesmereUIChat_Copy335Scroll",f,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",f,"TOPLEFT",14,-36); scroll:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-32,46)
    local box=CreateFrame("EditBox",nil,scroll)
    box:SetMultiLine(true); box:SetMaxLetters(0); box:SetAutoFocus(false)
    Size(box,470,250); box:SetFont(FontPath(),12,"")
    box:SetScript("OnEscapePressed",function() f:Hide() end)
    box:SetScript("OnHide",function(self) self:ClearFocus() end)
    scroll:SetScrollChild(box)
    local close=CreateFrame("Button",nil,f); Size(close,90,24); close:SetPoint("BOTTOM",f,"BOTTOM",0,12)
    local cbg=close:CreateTexture(nil,"BACKGROUND"); cbg:SetAllPoints(close); cbg:SetTexture(WHITE); cbg:SetVertexColor(.10,.12,.16,1)
    local cedges=Edges(close); EdgeColor(cedges,1,1,1,.15)
    local clabel=close:CreateFontString(nil,"OVERLAY"); clabel:SetFont(FontPath(),12,""); clabel:SetPoint("CENTER",close,"CENTER",0,0)
    clabel:SetText("Close"); clabel:SetTextColor(1,1,1,.75)
    close:SetScript("OnEnter",function() clabel:SetTextColor(1,1,1,1); EdgeColor(cedges,1,1,1,.35) end)
    close:SetScript("OnLeave",function() clabel:SetTextColor(1,1,1,.75); EdgeColor(cedges,1,1,1,.15) end)
    close:SetScript("OnClick",function() f:Hide() end)
    f:SetScript("OnHide",function() box:ClearFocus(); copyDimmer:Hide() end)
    f.box,f.scroll,f.close,f.title=box,scroll,close,title; f:Hide(); copyWindow=f; ns.copyWindow=f
    return f
end
local function ShowCopy(text, heading)
    local f=EnsureCopyWindow(); f.title:SetText(heading or "Copy Chat")
    copyDimmer:Show(); f:Show(); f.box:SetText(text); f.scroll:SetVerticalScroll(0)
    f.box:HighlightText(); f.box:SetFocus() -- explicit copy click only
end
ns.ShowCopy=ShowCopy
local urlPopup, urlDimmer
local function HideURL() if urlPopup then urlPopup:Hide() end end
local function EnsureURLPopup()
    if urlPopup then return urlPopup end
    local f=Popup("EllesmereUIChat_URL335",340,52)
    urlDimmer=Dimmer(HideURL)
    local hint=f:CreateFontString(nil,"OVERLAY"); hint:SetFont(FontPath(),8,""); hint:SetTextColor(1,1,1,.5)
    hint:SetPoint("TOP",f,"TOP",0,-6); hint:SetText("Ctrl+C to copy, Escape to close")
    local box=CreateFrame("EditBox",nil,f); Size(box,300,16); box:SetPoint("TOP",hint,"BOTTOM",0,-6)
    box:SetFont(FontPath(),11,""); box:SetAutoFocus(false); box:SetJustifyH("CENTER")
    local bg=box:CreateTexture(nil,"BACKGROUND"); bg:SetTexture(WHITE); bg:SetVertexColor(.10,.12,.16,1)
    bg:SetPoint("TOPLEFT",box,"TOPLEFT",-6,4); bg:SetPoint("BOTTOMRIGHT",box,"BOTTOMRIGHT",6,-4)
    box:SetScript("OnEscapePressed",HideURL)
    box:SetScript("OnHide",function(self) self:ClearFocus() end)
    box:SetScript("OnKeyUp",function(_,key) if key=="C" and IsControlKeyDown and IsControlKeyDown() then HideURL() end end)
    box:SetScript("OnMouseUp",function(self) self:HighlightText() end)
    f:SetScript("OnMouseDown",function() box:SetFocus(); box:HighlightText() end)
    f:SetScript("OnHide",function() box:ClearFocus(); urlDimmer:Hide() end)
    f.box=box; f:Hide(); urlPopup=f; ns.urlPopup=f
    return f
end
local function ShowURL(url)
    local f=EnsureURLPopup(); f:ClearAllPoints()
    local x,y=0,0
    if GetCursorPosition then x,y=GetCursorPosition() end
    local scale=UIParent:GetEffectiveScale()
    f:SetPoint("BOTTOM",UIParent,"BOTTOMLEFT",x/scale,y/scale+10)
    urlDimmer:Show(); f:Show(); f.box:SetText(url); f.box:HighlightText(); f.box:SetFocus() -- explicit URL click only
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
        for i=max(1,count-p.copyLines+1),count do
            local text=cf:GetMessageInfo(i); if type(text)=="string" then lines[#lines+1]=ns.PlainText(text) end
        end
    end
    local text=table.concat(lines,"\n"); if text=="" then text="(No chat history)" end
    ShowCopy(text)
end
local function Wheel(self,delta)
    if IsShiftKeyDown() then if delta>0 then self:ScrollToTop() else self:ScrollToBottom() end
    elseif delta>0 then self:ScrollUp() else self:ScrollDown() end
end
local function HideTexture(s,texture)
    if not texture then return end
    if s.textures[texture]==nil then s.textures[texture]=texture:GetAlpha() end; texture:SetAlpha(0)
end
local function RestoreTextures(s) for texture,alpha in pairs(s.textures) do texture:SetAlpha(alpha) end; wipe(s.textures) end
local function Remember(s,text,r,g,b)
    local p=ns.GetSettings()
    s.lines[#s.lines+1]=text; s.colors[#s.lines]={r,g,b}
    local limit=max(50,min(2000,tonumber(p and p.copyLines) or 500))
    while #s.lines>limit do table.remove(s.lines,1); table.remove(s.colors,1) end
end
local function SeedHistory(cf,s)
    wipe(s.lines); wipe(s.colors)
    if cf.GetNumMessages and cf.GetMessageInfo then
        local p=ns.GetSettings(); local count=cf:GetNumMessages()
        for i=max(1,count-p.copyLines+1),count do
            local text,r,g,b=cf:GetMessageInfo(i); if type(text)=="string" then Remember(s,text,r,g,b) end
        end
    end
end
local function IsSelected(s)
    local cf=s.frame
    if not cf.isDocked then return true end
    if FCFDock_GetSelectedWindow and GENERAL_CHAT_DOCK then return FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)==cf end
    return (SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME)==cf
end
local function TabText(s)
    local fs=s.tabText; local text=fs and fs:GetText()
    if (not text or text=="") and s.tab and s.tab.GetText then text=s.tab:GetText() end
    return text or ""
end

-- Tab visuals live on UIParent: the native tab keeps clicks, drags, docking
-- and the menu, and its own alpha cycling never reaches the EUI look.
local function PaintTab(s)
    local p=ns.GetSettings(); local v=s.visual
    if not v or not p then return end
    if not (active and Skinned() and s.tab and s.tab:IsVisible()) then v:Hide(); return end
    local sel=s.selected
    v:SetHeight(max(18,min(40,p.tabHeight or 24)))
    ApplyFont(v.label,FontPath(p.tabFont),p.tabFontSize or 11,p)
    v.label:SetText(TabText(s))
    local r,g,b,a
    if sel then r,g,b,a=ModeColor(p.tabFontColorActiveMode,p.tabFontColorActive,1)
    else r,g,b,a=ModeColor(p.tabFontColorMode,p.tabFontColor,.65) end
    if s.alert and not sel then r,g,b=Accent(); a=1 elseif s.hovered and not sel then a=max(a,.9) end
    v.label:SetTextColor(r,g,b,a)
    if sel then r,g,b,a=ModeColor(p.tabBackgroundColorActiveMode,p.tabBackgroundColorActive,.65)
    else r,g,b,a=ModeColor("custom",p.tabBackgroundColor,.44) end
    Paint(v.bg,p.tabBackgroundTexture,r,g,b,a)
    if sel and p.activeUnderline then
        r,g,b=ModeColor(p.activeUnderlineColorMode,p.activeUnderlineColor); v.line:SetVertexColor(r,g,b,1); v.line:Show()
    else v.line:Hide() end
    ApplyBorder(v.border,p,p.syncTabBorder and "panel" or "tab")
    local c=p.tabBorderColorActive or {}
    EdgeColor(v.edges,c.r or 1,c.g or 1,c.b or 1,c.a or .18); ShowEdges(v.edges,sel and p.activeTabBorder)
    v:Show()
end
ns.PaintTab = PaintTab
local function NewTabVisual(s)
    local v=CreateFrame("Frame",nil,UIParent); v:EnableMouse(false); v:SetFrameStrata("LOW")
    v:SetPoint("BOTTOMLEFT",s.tab,"BOTTOMLEFT",0,0); v:SetPoint("BOTTOMRIGHT",s.tab,"BOTTOMRIGHT",0,0)
    v.bg=v:CreateTexture(nil,"BACKGROUND"); v.bg:SetAllPoints(v)
    v.line=v:CreateTexture(nil,"ARTWORK"); v.line:SetTexture(WHITE); v.line:SetHeight(2)
    v.line:SetPoint("BOTTOMLEFT",v,"BOTTOMLEFT",0,0); v.line:SetPoint("BOTTOMRIGHT",v,"BOTTOMRIGHT",0,0)
    v.edges=Edges(v)
    v.border=CreateFrame("Frame",nil,v); v.border:SetAllPoints(v); v.border:EnableMouse(false)
    v.label=v:CreateFontString(nil,"OVERLAY"); v.label:SetPoint("CENTER",v,"CENTER",0,0); v.label:SetFont(FontPath(),11,"")
    v:Hide(); s.visual=v
    s.tab:HookScript("OnEnter",function() s.hovered=true; PaintTab(s) end)
    s.tab:HookScript("OnLeave",function() s.hovered=false; PaintTab(s) end)
    s.tab:HookScript("OnShow",function() s.selected=IsSelected(s); PaintTab(s) end)
    s.tab:HookScript("OnHide",function() v:Hide() end)
end
local function SkinTab(s)
    local tab=s.tab; if not tab then return end
    for _,key in ipairs(tabChrome) do HideTexture(s,tab[key]) end
    if s.tabText then HideTexture(s,s.tabText) end
    if tab.glow and s.glowTexture==nil then s.glowTexture=tab.glow:GetTexture() or false; tab.glow:SetTexture(nil) end
end
local function UnskinTab(s)
    if s.tab and s.tab.glow and s.glowTexture~=nil then s.tab.glow:SetTexture(s.glowTexture or nil); s.glowTexture=nil end
    if s.visual then s.visual:Hide() end
end

local sidebar, scrollButton
local icons = {}
ns.icons = icons
local function SidebarParticipates(p) return Skinned() and (p.sidebarVisibility or "always")~="never" end
local function SidebarSpan(p)
    if not SidebarParticipates(p) then return 0 end
    return max(30,min(100,p.sidebarWidth or 40))+(p.sidebarSeparate and (p.sidebarSeparateSpacing or 8) or 0)
end
local function IncludeSidebar(p) return SidebarParticipates(p) and not p.hideSidebarBg and not p.sidebarSeparate end
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
    local name=cf:GetName(); local skin=Skinned()
    ApplyFont(cf,FontPath(p.font),p.chatFontSize,p)
    cf:SetFading(p.fadeMessages); cf:SetTimeVisible(p.fadeSeconds)
    cf:EnableMouseWheel(p.mouseWheel); cf:SetScript("OnMouseWheel",p.mouseWheel and Wheel or s.wheel)
    local eb=s.edit
    if eb then
        local key=p.editBoxFont=="__chat" and p.font or p.editBoxFont
        ApplyFont(eb,FontPath(key),p.editBoxFontSize,p); eb:SetAutoFocus(false)
        if eb.header then ApplyFont(eb.header,FontPath(key),p.editBoxFontSize,p) end
    end
    if not skin then
        RestoreTextures(s); UnskinTab(s); s.panel:Hide()
        if eb then SetPoints(eb,s.editPoints); eb:SetHeight(s.editHeight) end
        if s.buttonFrame and s.buttonShown then s.buttonFrame:Show() end
        return
    end
    for _,suffix in ipairs(chrome) do HideTexture(s,_G[name..suffix]) end
    local top,bottom,ext,h=Geometry(p)
    -- Docked windows share the primary's top: the docked combat log sits
    -- lower under its filter bar, which stays inside the panel this way.
    local topFrame=(cf.isDocked and cf~=ChatFrame1) and ChatFrame1 or cf
    s.panel:ClearAllPoints()
    s.panel:SetPoint("TOPLEFT",topFrame,"TOPLEFT",-PAD_X,top+ext); s.panel:SetPoint("BOTTOMRIGHT",cf,"BOTTOMRIGHT",PAD_X,-bottom)
    s.panel:SetFrameLevel(max(0,cf:GetFrameLevel()-1))
    Paint(s.bg,p.bgTexture,p.bgR,p.bgG,p.bgB,p.bgAlpha)
    s.divider:ClearAllPoints()
    local edge,y=p.inputOnTop and "TOP" or "BOTTOM",p.inputOnTop and GAP/2 or -GAP/2
    s.divider:SetPoint("LEFT",cf,edge.."LEFT",-PAD_X,y); s.divider:SetPoint("RIGHT",cf,edge.."RIGHT",PAD_X,y)
    s.divider:SetVertexColor(InnerColor(p)); Shown(s.divider,not p.hideBorders and eb~=nil)
    s.panel:Show()
    if eb then
        for _,suffix in ipairs(editChrome) do HideTexture(s,_G[eb:GetName()..suffix]) end
        eb:ClearAllPoints(); eb:SetHeight(h)
        if p.inputOnTop then
            eb:SetPoint("BOTTOMLEFT",cf,"TOPLEFT",-PAD_X,GAP); eb:SetPoint("BOTTOMRIGHT",cf,"TOPRIGHT",PAD_X,GAP)
        else
            eb:SetPoint("TOPLEFT",cf,"BOTTOMLEFT",-PAD_X,-GAP); eb:SetPoint("TOPRIGHT",cf,"BOTTOMRIGHT",PAD_X,-GAP)
        end
    end
    if s.buttonFrame then s.buttonFrame:Hide() end
    -- One border around the panel, and the attached sidebar for the dock.
    local border=s.border; border:ClearAllPoints()
    local withSidebar=sidebar and cf.isDocked and IncludeSidebar(p)
    local left=(withSidebar and not p.sidebarRight) and sidebar or s.panel
    local right=(withSidebar and p.sidebarRight) and sidebar or s.panel
    border:SetPoint("TOPLEFT",left,"TOPLEFT",0,0); border:SetPoint("BOTTOMRIGHT",right,"BOTTOMRIGHT",0,0)
    border:SetFrameLevel(p.panelBorderBehind and s.panel:GetFrameLevel() or cf:GetFrameLevel()+2)
    ApplyBorder(border,p,"panel")
    SkinTab(s)
end
local function Capture(cf)
    if states[cf] then return states[cf] end
    local name=cf:GetName(); local edit=cf.editBox or _G[name.."EditBox"]
    local bf=cf.buttonFrame or _G[name.."ButtonFrame"]
    local s={frame=cf,lines={},colors={},textures={},font=RememberFont(cf),points=Points(cf),width=cf:GetWidth(),height=cf:GetHeight(),
        level=cf:GetFrameLevel(),alpha=cf:GetAlpha(),shadow=cf.GetShadowOffset and {cf:GetShadowOffset()},
        fading=cf.GetFading and cf:GetFading(),timeVisible=cf.GetTimeVisible and cf:GetTimeVisible() or 120,wheel=cf:GetScript("OnMouseWheel"),
        wheelEnabled=cf:IsMouseWheelEnabled(),hyperlink=cf:GetScript("OnHyperlinkClick"),addMessage=cf.AddMessage,
        edit=edit,editFont=RememberFont(edit),editHeaderFont=edit and RememberFont(edit.header),
        editPoints=edit and Points(edit),editHeight=edit and edit:GetHeight(),autoFocus=edit and edit.IsAutoFocus and edit:IsAutoFocus(),
        tab=_G[name.."Tab"],tabText=_G[name.."TabText"],buttonFrame=bf,buttonShown=bf and bf:IsShown(),
        clampInsets=cf.GetClampRectInsets and {cf:GetClampRectInsets()}}
    states[cf]=s
    cf:SetFrameLevel(max(2,s.level)) -- keep the panel below the native text
    s.panel=CreateFrame("Frame",nil,cf); s.panel:EnableMouse(false)
    s.bg=s.panel:CreateTexture(nil,"BACKGROUND"); s.bg:SetAllPoints(s.panel); s.bg:SetTexture(WHITE)
    s.divider=s.panel:CreateTexture(nil,"ARTWORK"); s.divider:SetTexture(WHITE); s.divider:SetHeight(1)
    s.border=CreateFrame("Frame",nil,s.panel); s.border:EnableMouse(false)
    s.panel:Hide()
    if s.tab then NewTabVisual(s) end
    s.wrapper=function(self,text,r,g,b,...)
        local p=ns.GetSettings()
        if active and p and type(text)=="string" then
            local event=stampFrame==self and stampTime==GetTime()
            if event then stampFrame=nil end
            if cf~=ChatFrame2 then
                local fmt=p.timestampFormat or "__blizzard"
                if fmt~="__blizzard" then
                    if CHAT_TIMESTAMP_FORMAT and BetterDate then
                        local native=BetterDate(CHAT_TIMESTAMP_FORMAT,time())
                        if text:sub(1,#native)==native then text=text:sub(#native+1) end
                    end
                    if fmt~="none" and (event or p.timestampAll) then text=date(fmt)..text end
                end
                if p.abbreviateChannels then text=ns.AbbreviateChannels(text,p.abbreviateChannelLetters) end
                if p.clickableURLs then text=ns.LinkURLs(text) end
                if self:IsVisible() then ns.ResetIdle() end
            end
            Remember(s,text,r,g,b)
        end
        return s.addMessage(self,text,r,g,b,...)
    end
    s.linkWrapper=function(self,link,text,button,...)
        if active and type(link)=="string" and link:sub(1,7)=="euiurl:" then ShowURL(link:sub(8)); return end
        if s.hyperlink then return s.hyperlink(self,link,text,button,...) end
    end
    cf:HookScript("OnShow",function() Style(cf,s) end)
    if edit then
        edit:HookScript("OnHide",function(self) self:ClearFocus() end)
        edit:HookScript("OnEditFocusGained",function() ns.ResetIdle() end)
    end
    if bf then bf:HookScript("OnShow",function(self) if active and Skinned() then self:Hide() end end) end
    if cf.Clear then hooksecurefunc(cf,"Clear",function() wipe(s.lines); wipe(s.colors) end) end
    SeedHistory(cf,s)
    return s
end

-- Retail hides Blizzard's chat menu and social buttons; the sidebar replaces them.
local hiddenButtons = {}
local function HideNativeButton(name)
    local b=_G[name]; if not b then return end
    if hiddenButtons[b]==nil then
        hiddenButtons[b]=b:IsShown() and true or false
        b:HookScript("OnShow",function(self) if active and Skinned() and hiddenButtons[self]~=nil then self:Hide() end end)
    end
    b:Hide()
end
local function RestoreNativeButtons()
    for b,wasShown in pairs(hiddenButtons) do if wasShown then b:Show() end; hiddenButtons[b]=nil end
end
local resizeHooked, resizeWasShown
function ECHAT.ApplyLockChatSize()
    local p=ns.GetSettings(); local b=_G.ChatFrame1ResizeButton
    if not b or not p then return end
    if not resizeHooked then
        resizeHooked=true
        b:HookScript("OnShow",function(self) local q=ns.GetSettings(); if active and q and q.lockChatSize then self:Hide() end end)
    end
    if active and p.lockChatSize then
        if resizeWasShown==nil then resizeWasShown=b:IsShown() and true or false end
        b:Hide()
    elseif resizeWasShown~=nil then
        if resizeWasShown then b:Show() end
        resizeWasShown=nil
    end
end

local function ToggleSettings()
    local mf=E._mainFrame
    if mf and mf:IsShown() and E.GetActiveModule and E:GetActiveModule()==ADDON_NAME then mf:Hide()
    else SlashCmdList.EUI335CHAT() end
end
local function ScrollSelected()
    local cf=GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK) or SELECTED_DOCK_FRAME or ChatFrame1
    if cf and cf.ScrollToBottom then cf:ScrollToBottom() end
end
local ICONS = {
    showFriends={tex="chat_friends",size=26,label="Friends",count=7,click=function() if ToggleFriendsFrame then ToggleFriendsFrame(1) end end},
    showGuild={tex="chat_guild",size=26,label="Guild",count=7,click=function() if ToggleFriendsFrame and IsInGuild() then ToggleFriendsFrame(3) end end},
    showDurability={tex="chat_durability",size=22,label="Equipment Durability",count=0},
    showCopy={tex="chat_copy",size=22,label="Copy Chat",click=function() ns.CopyChat() end},
    showVoice={tex="chat_voice",size=22,label="Voice/Channels",click=function() if ToggleFriendsFrame then ToggleFriendsFrame(4) end end},
    showSettings={tex="chat_settings",size=22,label="Settings",click=ToggleSettings},
}
ns.SIDEBAR_ICONS = ICONS
local CHAIN = {"showFriends","showGuild","showDurability","showCopy","showVoice","showSettings"}
local FALLBACK = {showFriends=-20,showGuild=-15,showDurability=-10,showCopy=1,showVoice=3,showSettings=4}
function ECHAT.ResolveSidebarIconOrder()
    local p=ns.GetSettings(); local map=p and p.sidebarIconOrder or {}
    local keys,index={},{}
    for i,key in ipairs(CHAIN) do keys[i]=key; index[key]=i end
    local function OrderOf(key) local o=map[key]; if type(o)=="number" then return o end; return FALLBACK[key] or 999 end
    table.sort(keys,function(a,b) local oa,ob=OrderOf(a),OrderOf(b); if oa~=ob then return oa<ob end; return index[a]<index[b] end)
    return keys
end
local function IconColor(p) if p.iconUseAccent then return Accent() end; return p.iconR or 1,p.iconG or 1,p.iconB or 1 end
local function SidebarTip(btn,label)
    if btn.justDragged then return end
    local p=ns.GetSettings()
    GameTooltip:SetOwner(btn,(p and p.sidebarRight) and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
    GameTooltip:SetText(label,1,1,1); GameTooltip:Show()
end
local function MakeIcon(key,def,parent)
    local btn=CreateFrame("Button",nil,parent); btn.key,btn.base=key,def.size
    Size(btn,def.size,def.size)
    btn.icon=btn:CreateTexture(nil,"ARTWORK"); btn.icon:SetAllPoints(btn); btn.icon:SetTexture(MEDIA..def.tex)
    if btn.icon.SetDesaturated then btn.icon:SetDesaturated(true) end
    if def.count then
        btn.count=btn:CreateFontString(nil,"OVERLAY"); btn.count:SetPoint("TOP",btn,"BOTTOM",0,def.count)
        btn.count:SetFont(FontPath(),9,"") -- the client rejects SetText before a font
        btn.count:SetText(key=="showDurability" and "100%" or "0")
    end
    local function Tint(hover)
        local p=ns.GetSettings(); if not p then return end
        local r,g,b=IconColor(p); btn.icon:SetVertexColor(r,g,b,hover and .9 or .4)
        if btn.count then btn.count:SetTextColor(1,1,1,hover and .9 or .5) end
    end
    btn.Tint=Tint
    btn:SetScript("OnEnter",function(self) Tint(true); SidebarTip(self,def.label) end)
    btn:SetScript("OnLeave",function() Tint(false); GameTooltip:Hide() end)
    btn:SetScript("OnClick",function(self)
        if self.justDragged then self.justDragged=false; return end
        if def.click then def.click() end
    end)
    btn:SetMovable(true); btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart",function(self)
        local p=ns.GetSettings(); if p and p.freeMoveIcons and self~=scrollButton then self.dragging=true; self:StartMoving() end
    end)
    btn:SetScript("OnDragStop",function(self)
        if not self.dragging then return end
        self.dragging=false; self:StopMovingOrSizing()
        local p=ns.GetSettings(); if not p or not sidebar then return end
        local bx=self:GetCenter(); local sx=sidebar:GetCenter()
        p.iconPositions=p.iconPositions or {}
        p.iconPositions[self.key]={x=floor((bx-sx)+.5),y=floor((self:GetTop()-sidebar:GetTop())+.5)}
        self.justDragged=true; ns.LayoutSidebar()
    end)
    Tint(false)
    return btn
end
local lastRoster = -math.huge
local function UpdateCounts()
    local p=ns.GetSettings(); if not p or not sidebar then return end
    local friends=icons.showFriends
    if friends then
        local _,online=GetNumFriends(); online=online or 0
        if BNGetNumFriends then local ok,_,bn=pcall(BNGetNumFriends); if ok and bn then online=online+bn end end
        friends.count:SetText(online)
    end
    local guild=icons.showGuild
    if guild then
        local online=0
        if IsInGuild() then
            local now=GetTime()
            if now-lastRoster>=15 and GuildRoster then lastRoster=now; GuildRoster() end
            for i=1,(GetNumGuildMembers(true) or 0) do if select(9,GetGuildRosterInfo(i)) then online=online+1 end end
        end
        guild.count:SetText(online)
    end
    local dura=icons.showDurability
    if dura then
        local lowest=100
        for slot=1,18 do
            local cur,most=GetInventoryItemDurability(slot)
            if cur and most and most>0 then lowest=min(lowest,cur/most*100) end
        end
        dura.count:SetText(floor(lowest).."%")
    end
end
ns.UpdateCounts = UpdateCounts
local function EnsureSidebar()
    if sidebar then return sidebar end
    sidebar=CreateFrame("Frame","EllesmereUIChatSidebar",UIParent); sidebar:SetFrameStrata("BACKGROUND"); sidebar:EnableMouse(false)
    sidebar.bg=sidebar:CreateTexture(nil,"BACKGROUND"); sidebar.bg:SetAllPoints(sidebar); sidebar.bg:SetTexture(WHITE)
    sidebar.divider=sidebar:CreateTexture(nil,"OVERLAY"); sidebar.divider:SetTexture(WHITE); sidebar.divider:SetWidth(1)
    sidebar.border=CreateFrame("Frame",nil,sidebar); sidebar.border:SetAllPoints(sidebar); sidebar.border:EnableMouse(false)
    for key,def in pairs(ICONS) do icons[key]=MakeIcon(key,def,sidebar) end
    scrollButton=MakeIcon("showScroll",{tex="chat_scroll2",size=22,label="Scroll to Bottom",click=ScrollSelected},UIParent)
    scrollButton:SetFrameStrata("LOW"); icons.showScroll=scrollButton; ns.sidebar=sidebar
    local counts=CreateFrame("Frame",nil,sidebar)
    for _,event in ipairs({"FRIENDLIST_UPDATE","GUILD_ROSTER_UPDATE","PLAYER_GUILD_UPDATE","UPDATE_INVENTORY_DURABILITY",
        "UPDATE_INVENTORY_ALERTS","PLAYER_ENTERING_WORLD"}) do counts:RegisterEvent(event) end
    for _,event in ipairs({"BN_FRIEND_ACCOUNT_ONLINE","BN_FRIEND_ACCOUNT_OFFLINE","BN_CONNECTED","BN_DISCONNECTED"}) do
        pcall(counts.RegisterEvent,counts,event) -- the Battle.net set varies between Wrath builds
    end
    counts:SetScript("OnEvent",UpdateCounts); ns.countEvents=counts
    return sidebar
end
function ns.LayoutSidebar()
    local p=ns.GetSettings(); if not p then return end
    if not (active and SidebarParticipates(p)) then
        if sidebar then sidebar:Hide() end
        if scrollButton then Shown(scrollButton,active and Skinned() and p.showScroll and p.scrollButtonOnChat) end
        if not (active and Skinned()) then return end
    end
    local sb=EnsureSidebar()
    local top,bottom,ext=Geometry(p)
    local w=max(30,min(100,p.sidebarWidth or 40)); local gap=p.sidebarSeparate and (p.sidebarSeparateSpacing or 8) or 0
    sb:ClearAllPoints(); sb:SetWidth(w)
    if p.sidebarRight then
        sb:SetPoint("TOPLEFT",ChatFrame1,"TOPRIGHT",PAD_X+gap,top+ext); sb:SetPoint("BOTTOMLEFT",ChatFrame1,"BOTTOMRIGHT",PAD_X+gap,-bottom)
    else
        sb:SetPoint("TOPRIGHT",ChatFrame1,"TOPLEFT",-PAD_X-gap,top+ext); sb:SetPoint("BOTTOMRIGHT",ChatFrame1,"BOTTOMLEFT",-PAD_X-gap,-bottom)
    end
    sb:SetFrameLevel(max(0,ChatFrame1:GetFrameLevel()-1))
    Paint(sb.bg,p.bgTexture,p.bgR,p.bgG,p.bgB,p.hideSidebarBg and 0 or p.bgAlpha)
    sb.divider:ClearAllPoints()
    local side=p.sidebarRight and "LEFT" or "RIGHT"
    sb.divider:SetPoint("TOP"..side,sb,"TOP"..side,0,0); sb.divider:SetPoint("BOTTOM"..side,sb,"BOTTOM"..side,0,0)
    sb.divider:SetVertexColor(InnerColor(p)); Shown(sb.divider,not p.hideBorders and not p.sidebarSeparate and not p.hideSidebarBg)
    if p.sidebarSeparate and not p.hideSidebarBg then ApplyBorder(sb.border,p,"panel") else sb.border:Hide() end
    Shown(sb,SidebarParticipates(p))
    local scale=max(.5,min(2,p.sidebarIconScale or 1)); local spacing=p.sidebarIconSpacing or 10
    local font=FontPath(p.font); local anchor
    for _,key in ipairs(ECHAT.ResolveSidebarIconOrder()) do
        local btn=icons[key]
        if btn and p[key] then
            Size(btn,btn.base*scale,btn.base*scale); btn:ClearAllPoints()
            local pos=p.freeMoveIcons and type(p.iconPositions)=="table" and p.iconPositions[key]
            if pos then btn:SetPoint("TOP",sb,"TOP",pos.x or 0,pos.y or 0)
            else
                if anchor then btn:SetPoint("TOP",anchor,"BOTTOM",0,-spacing) else btn:SetPoint("TOP",sb,"TOP",0,-spacing) end
                anchor=btn.count or btn
            end
            if btn.count then btn.count:SetFont(font,max(7,9*scale),"") end
            btn.Tint(false); btn:Show()
        elseif btn then btn:Hide() end
    end
    Size(scrollButton,22*scale,22*scale); scrollButton:ClearAllPoints()
    if p.scrollButtonOnChat then scrollButton:SetPoint("BOTTOMRIGHT",ChatFrame1,"BOTTOMRIGHT",0,2)
    else scrollButton:SetPoint("BOTTOM",sb,"BOTTOM",0,spacing) end
    scrollButton.Tint(false)
    Shown(scrollButton,p.showScroll and (p.scrollButtonOnChat or SidebarParticipates(p)))
    UpdateCounts()
end

-- Static docked tabs get the Retail width, spacing and offsets. The dock
-- itself is moved so the native click targets sit under the EUI tabs.
local dockPoints
local function LayoutDock()
    local p=ns.GetSettings(); local dock=GENERAL_CHAT_DOCK
    if not (p and dock and dock.SetPoint and dock.DOCKED_CHAT_FRAMES) then return end
    if not (active and Skinned()) then return end
    if not dockPoints then dockPoints=Points(dock) end
    local top=Geometry(p)
    local span=SidebarSpan(p)
    local x=-PAD_X+(p.tabOffsetX or 0)
    if p.alignTabsToPanel and not p.sidebarRight then x=x-span end
    local right=PAD_X+((p.alignTabsToPanel and p.sidebarRight) and span or 0)
    -- Native tabs are 32px tall and centred in the 26px dock: 3px below it.
    local y=top+(p.tabPadding or 0)+3
    dock:ClearAllPoints(); dock:SetPoint("BOTTOMLEFT",ChatFrame1,"TOPLEFT",x,y); dock:SetPoint("BOTTOMRIGHT",ChatFrame1,"TOPRIGHT",right,y)
    local spacing=p.tabSpacing or 1; local pad=p.tabInnerPaddingX or 12
    local lastStatic,lastDynamic
    local child=dock.scrollFrame and dock.scrollFrame.GetScrollChild and dock.scrollFrame:GetScrollChild()
    for _,cf in ipairs(dock.DOCKED_CHAT_FRAMES) do
        local s=states[cf]; local tab=s and s.tab
        if tab and s.visual then
            if cf.isStaticDocked then
                ApplyFont(s.visual.label,FontPath(p.tabFont),p.tabFontSize or 11,p); s.visual.label:SetText(TabText(s))
                tab:SetWidth(max(24,floor(s.visual.label:GetStringWidth()+2*pad+.5))); tab:ClearAllPoints()
                if lastStatic then tab:SetPoint("LEFT",lastStatic,"RIGHT",spacing,0) else tab:SetPoint("LEFT",dock,"LEFT",0,0) end
                lastStatic=tab
            elseif child then
                tab:ClearAllPoints()
                if lastDynamic then tab:SetPoint("LEFT",lastDynamic,"RIGHT",spacing,0) else tab:SetPoint("LEFT",child,"LEFT",0,0) end
                lastDynamic=tab
            end
        end
    end
    if lastStatic and dock.scrollFrame then dock.scrollFrame:SetPoint("LEFT",lastStatic,"RIGHT",spacing,0) end
end
ns.LayoutDock = LayoutDock
local function RefreshTabs()
    for _,s in pairs(states) do s.selected=IsSelected(s); PaintTab(s) end
end

-- Idle fade and visibility ride one driver. Hover is read from screen rects,
-- so faded and hidden chat never catches clicks meant for the world.
local driver = CreateFrame("Frame"); driver:Hide(); ns.driver=driver
local alpha, target, sbAlpha, sbTarget, lastActivity, tick, passthrough = 1, 1, 1, 1, 0, 1, false
function ns.ResetIdle() lastActivity=GetTime() end
ECHAT.ResetIdleTimer = ns.ResetIdle
local function Over(f) return f and f:IsVisible() and MouseIsOver and MouseIsOver(f) end
local function Hovered()
    if sidebar and Over(sidebar) then return true end
    for cf,s in pairs(states) do
        if cf:IsVisible() and (Over(s.panel) or Over(cf)) then return true end
        if s.tab and Over(s.tab) then return true end
    end
end
local function Engaged()
    local eb=ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    return (eb and eb:IsShown()) or (copyWindow and copyWindow:IsShown()) or (urlPopup and urlPopup:IsShown())
end
function ns.Visible(p)
    local raid=GetNumRaidMembers()>0
    local state={inCombat=(UnitAffectingCombat("player") or InCombatLockdown()) and true or false,inRaid=raid,
        inParty=not raid and GetNumPartyMembers()>0}
    local v=E.EvalVisibilityExtended and E.EvalVisibilityExtended(p,"visibility",state)
    if v==nil then
        local mode=p.visibility or "always"
        if E.CheckVisibilityMode then v=E.CheckVisibilityMode(mode,state) and true or false else v=mode~="never" end
    end
    if v and E.CheckVisibilityOptions and E.CheckVisibilityOptions(p) then v=false end
    return v and true or false
end
local function ApplyAlpha()
    for cf,s in pairs(states) do
        cf:SetAlpha(alpha)
        if s.edit and s.edit:GetParent()~=cf then s.edit:SetAlpha(alpha) end
        if s.visual then s.visual:SetAlpha(alpha) end
    end
    local p=ns.GetSettings()
    if sidebar then sidebar:SetAlpha(alpha*sbAlpha) end
    if scrollButton then scrollButton:SetAlpha((p and p.scrollButtonOnChat) and alpha or alpha*sbAlpha) end
    local through=alpha<=.01
    if through~=passthrough then
        passthrough=through
        for cf,s in pairs(states) do
            if s.tab then s.tab:EnableMouse(not through) end
            if cf.SetHyperlinksEnabled then cf:SetHyperlinksEnabled(not through) end
        end
    end
    local iconsOff=alpha*sbAlpha<=.01
    for _,btn in pairs(icons) do btn:EnableMouse(not iconsOff) end
    if scrollButton and p and p.scrollButtonOnChat then scrollButton:EnableMouse(not through) end
end
local function Evaluate(p)
    local now=GetTime()
    local engaged=Engaged()
    if engaged or Hovered() then lastActivity=now end
    if not (engaged or ns.Visible(p)) then target=0
    elseif p.idleFadeEnabled and now-lastActivity>=(p.idleFadeDelay or 15) then
        target=1-min(100,max(0,p.idleFadeStrength or 40))/100
    else target=1 end
    local mode=p.sidebarVisibility or "always"
    if mode=="mouseover" then sbTarget=Over(sidebar) and 1 or 0 else sbTarget=mode=="never" and 0 or 1 end
    for _,s in pairs(states) do
        local glow=s.tab and s.tab.glow and s.tab.glow:IsShown() and true or false
        if glow~=s.alert then s.alert=glow; PaintTab(s) end
        if s.visual and s.visual:IsShown() and s.visual.label:GetText()~=TabText(s) then PaintTab(s) end
    end
end
local function Step(current,goal,elapsed,inTime,outTime)
    if current<goal then return min(goal,current+elapsed/inTime) end
    if current>goal then return max(goal,current-elapsed/outTime) end
    return current
end
driver:SetScript("OnUpdate",function(self,elapsed)
    local p=ns.GetSettings()
    if not active or not p then self:Hide(); return end
    tick=tick+elapsed
    if tick>=.1 then tick=0; Evaluate(p) end
    local a=Step(alpha,target,elapsed,.35,target==0 and 1 or 2)
    local sa=Step(sbAlpha,sbTarget,elapsed,.2,.4)
    if a~=alpha or sa~=sbAlpha then alpha,sbAlpha=a,sa; ApplyAlpha() end
end)

-- Wrath stamps only the generic player-chat branch; these filters flag the
-- frame for that same set, so "chat lines only" matches the native rule.
local STAMP_EVENTS = {"SAY","YELL","EMOTE","TEXT_EMOTE","WHISPER","WHISPER_INFORM","BN_WHISPER","BN_WHISPER_INFORM",
    "BN_CONVERSATION","PARTY","PARTY_LEADER","RAID","RAID_LEADER","RAID_WARNING","BATTLEGROUND","BATTLEGROUND_LEADER",
    "GUILD","OFFICER","CHANNEL","MONSTER_SAY","MONSTER_YELL","MONSTER_EMOTE","MONSTER_WHISPER","MONSTER_PARTY",
    "RAID_BOSS_EMOTE","RAID_BOSS_WHISPER","AFK","DND"}
local NAME_EVENTS = {"SAY","YELL","PARTY","PARTY_LEADER","RAID","RAID_LEADER","RAID_WARNING"}
local function StampFilter(self) stampFrame,stampTime=self,GetTime(); return false end
local function NameFilter(self,event,msg,...)
    local p=ns.GetSettings()
    if active and p and p.classColorNames and type(msg)=="string" then
        local colored=ns.ColorNames(msg)
        if colored~=msg then return false,colored,... end
    end
    return false
end
ns.StampFilter, ns.NameFilter = StampFilter, NameFilter
local TIP_TYPES = {achievement=true,enchant=true,glyph=true,item=true,quest=true,spell=true,talent=true}
local tipShown
local function LinkEnter(self,link)
    local p=ns.GetSettings()
    if not active or not p or p.hideTooltipOnHover or type(link)~="string" then return end
    if TIP_TYPES[link:match("^([^:]+)")] then
        GameTooltip:SetOwner(self,"ANCHOR_CURSOR"); GameTooltip:SetHyperlink(link); GameTooltip:Show(); tipShown=true
    end
end
local function LinkLeave() if tipShown then tipShown=false; GameTooltip:Hide() end end

local soundPaths
local function SoundPath(key)
    if not key or key=="none" then return nil end
    if not soundPaths and E.BuildAlertSoundTables then
        local names,order; soundPaths,names,order=E.BuildAlertSoundTables()
        if E.AppendSharedMediaSounds then E.AppendSharedMediaSounds(soundPaths,names,order) end
    end
    local path=soundPaths and soundPaths[key]
    if not path and LibStub then
        local lsm=LibStub("LibSharedMedia-3.0",true); path=lsm and lsm:Fetch("sound",(key:gsub("^sm:","")),true)
    end
    return path
end
ns.SoundPath = SoundPath

local historyReplayed = false
function ns.SaveHistory()
    local p=ns.GetSettings(); if not p then return end
    if not (p.enabled and p.persistChatHistory) then EllesmereUIChatScrollDB=nil; return end
    local limit=max(20,min(300,p.persistChatHistoryMaxLines or 100))
    local db={frames={}}
    for cf,s in pairs(states) do
        local name=cf:GetName(); local id=tonumber(name and name:match("^ChatFrame(%d+)$"))
        if cf~=ChatFrame2 and id and id<=(NUM_CHAT_WINDOWS or 10) and #s.lines>0 then
            local out={}
            for i=max(1,#s.lines-limit+1),#s.lines do
                local c=s.colors[i] or {}; out[#out+1]={t=s.lines[i],r=c[1],g=c[2],b=c[3]}
            end
            db.frames[name]=out
        end
    end
    EllesmereUIChatScrollDB=db
end
local function ReplayHistory()
    historyReplayed=true
    local p=ns.GetSettings(); local db=EllesmereUIChatScrollDB
    if not (p and p.persistChatHistory and type(db)=="table" and type(db.frames)=="table") then return end
    for name,list in pairs(db.frames) do
        local cf=_G[name]; local s=cf and states[cf]
        if s and type(list)=="table" then
            for _,entry in ipairs(list) do
                if type(entry)=="table" and type(entry.t)=="string" then
                    s.addMessage(cf,entry.t,entry.r,entry.g,entry.b); Remember(s,entry.t,entry.r,entry.g,entry.b)
                end
            end
        end
    end
end

-- Chat bubbles: Wrath bubbles are unnamed WorldFrame children wearing the
-- ChatBubble backdrop. A styled bubble drops that backdrop and its tail.
local bubbles = setmetatable({},{__mode="k"})
local recent = {}
ns.bubbles = bubbles
local BUBBLE_EVENTS = {CHAT_MSG_SAY="say",CHAT_MSG_YELL="yell",CHAT_MSG_PARTY="party",CHAT_MSG_PARTY_LEADER="party",
    CHAT_MSG_MONSTER_SAY="npc",CHAT_MSG_MONSTER_YELL="npc",CHAT_MSG_MONSTER_PARTY="npc",
    CHAT_MSG_EMOTE="emote",CHAT_MSG_TEXT_EMOTE="emote",CHAT_MSG_MONSTER_EMOTE="emote"}
local function IsBubble(f)
    if f:GetName() or not f.GetBackdrop then return false end
    local bd=f:GetBackdrop()
    return bd and bd.bgFile=="Interface\\Tooltips\\ChatBubble-Background" or false
end
local function CaptureBubble(f)
    local fs,tail
    for _,region in ipairs({f:GetRegions()}) do
        local kind=region.GetObjectType and region:GetObjectType()
        if kind=="FontString" then fs=region
        elseif kind=="Texture" and region:GetTexture()=="Interface\\Tooltips\\ChatBubble-Tail" then tail=region end
    end
    if not fs then return false end
    local d={fs=fs,tail=tail,backdrop=f:GetBackdrop(),bgColor={f:GetBackdropColor()},borderColor={f:GetBackdropBorderColor()},
        font={fs:GetFont()},color={fs:GetTextColor()},points=Points(fs),width=fs:GetWidth()}
    d.bg=f:CreateTexture(nil,"BACKGROUND"); d.bg:SetTexture(WHITE); d.bg:Hide()
    d.edges=Edges(f,"BORDER",d.bg); ShowEdges(d.edges,false)
    return d
end
-- Some bubbles (NPC speech) anchor the frame to its own text; anchoring that
-- text back to the frame is a circular SetPoint error.
local function AnchoredTo(f,target)
    for i=1,(f.GetNumPoints and f:GetNumPoints() or 0) do
        local _,rel=f:GetPoint(i); if rel==target then return true end
    end
    return false
end
local function RestoreBubble(f,d)
    if not d.styled then return end
    d.styled=false
    f:SetBackdrop(d.backdrop); f:SetBackdropColor(unpack(d.bgColor)); f:SetBackdropBorderColor(unpack(d.borderColor))
    if d.tail then d.tail:SetAlpha(1) end
    d.fs:SetFont(unpack(d.font)); d.fs:SetTextColor(unpack(d.color)); d.fs:SetWidth(d.width)
    if not AnchoredTo(f,d.fs) then SetPoints(d.fs,d.points) end
    d.bg:Hide(); ShowEdges(d.edges,false)
end
local function StyleBubble(f,d,cfg,channel)
    if not (cfg.enabled and channel and cfg[channel]~=false) then RestoreBubble(f,d); return end
    d.styled=true
    f:SetBackdrop(nil); if d.tail then d.tail:SetAlpha(0) end
    local fs=d.fs; fs:SetFont(d.font[1],cfg.fontSize or 12,d.font[3])
    if cfg.followBlizzardColor then fs:SetTextColor(unpack(d.color))
    else local c=cfg.textColor or {}; fs:SetTextColor(c.r or 1,c.g or 1,c.b or 1) end
    fs:SetWidth(min(cfg.maxWidth or 260,fs:GetStringWidth()+2))
    if not AnchoredTo(f,fs) then fs:ClearAllPoints(); fs:SetPoint("CENTER",f,"CENTER",0,cfg.offsetY or 0) end
    local pad=cfg.padding or 8
    d.bg:ClearAllPoints(); d.bg:SetPoint("TOPLEFT",fs,"TOPLEFT",-pad,pad); d.bg:SetPoint("BOTTOMRIGHT",fs,"BOTTOMRIGHT",pad,-pad)
    local bc=cfg.bgColor or {}
    d.bg:SetVertexColor(bc.r or 0,bc.g or 0,bc.b or 0,cfg.background and (cfg.bgAlpha or .5) or 0); d.bg:Show()
    local n=cfg.borderSize or 1; local c=cfg.borderColor or {}
    EdgeSize(d.edges,max(1,n)); EdgeColor(d.edges,c.r or 0,c.g or 0,c.b or 0,c.a or 1); ShowEdges(d.edges,n>0)
end
function ns.ScanBubbles(force)
    local cfg=ns.GetBubbleSettings(); if not cfg or not WorldFrame then return end
    for _,f in ipairs({WorldFrame:GetChildren()}) do
        local d=bubbles[f]
        if d==nil then d=IsBubble(f) and CaptureBubble(f) or false; bubbles[f]=d end
        if d and f:IsShown() then
            local text=d.fs:GetText()
            if force or text~=d.text then
                d.text=text; local seen=text and recent[text]
                StyleBubble(f,d,cfg,seen and seen.channel or "say")
            end
        end
    end
end
local bubbleScan = CreateFrame("Frame"); bubbleScan:Hide(); ns.bubbleScan=bubbleScan
local scanUntil, scanTick = 0, 0
bubbleScan:SetScript("OnUpdate",function(self,elapsed)
    scanTick=scanTick+elapsed
    if scanTick<.05 then return end
    scanTick=0; ns.ScanBubbles()
    if GetTime()>scanUntil then self:Hide() end
end)
local function SetCVarIfChanged(name,value) if GetCVar(name)~=value then SetCVar(name,value) end end
function ns.ApplyBubbles()
    local cfg=ns.GetBubbleSettings(); if not cfg then return end
    if cfg.enabled then
        if not cfg._savedCVars then cfg._savedCVars={chatBubbles=GetCVar("chatBubbles"),chatBubblesParty=GetCVar("chatBubblesParty")} end
        local blocked=cfg.hideInInstances and IsInInstance and IsInInstance()
        local main=(cfg.say~=false or cfg.yell~=false or cfg.npc~=false or cfg.emote~=false) and not blocked
        SetCVarIfChanged("chatBubbles",main and "1" or "0")
        SetCVarIfChanged("chatBubblesParty",(cfg.party~=false and not blocked) and "1" or "0")
    elseif cfg._savedCVars then
        SetCVarIfChanged("chatBubbles",cfg._savedCVars.chatBubbles or "1")
        SetCVarIfChanged("chatBubblesParty",cfg._savedCVars.chatBubblesParty or "1")
        cfg._savedCVars=nil
    end
    ns.ScanBubbles(true)
end

function ns.Restore()
    active=false; driver:Hide()
    if copyWindow then copyWindow:Hide() end
    HideURL()
    for cf,s in pairs(states) do
        if cf.AddMessage==s.wrapper then cf.AddMessage=s.addMessage; s.bridged=false end
        if cf:GetScript("OnHyperlinkClick")==s.linkWrapper then cf:SetScript("OnHyperlinkClick",s.hyperlink); s.linkBridged=false end
        if cf:GetScript("OnHyperlinkEnter")==LinkEnter then cf:SetScript("OnHyperlinkEnter",nil); cf:SetScript("OnHyperlinkLeave",nil) end
        if cf:GetScript("OnMouseWheel")==Wheel then cf:SetScript("OnMouseWheel",s.wheel) end
        cf:EnableMouseWheel(s.wheelEnabled); cf:SetFading(s.fading==nil or s.fading); cf:SetTimeVisible(s.timeVisible)
        RestoreFont(cf,s.font); cf:SetFrameLevel(s.level); cf:SetAlpha(s.alpha or 1)
        if s.shadow and cf.SetShadowOffset then cf:SetShadowOffset(unpack(s.shadow)) end
        if cf.SetHyperlinksEnabled then cf:SetHyperlinksEnabled(true) end
        if s.clampInsets and cf.SetClampRectInsets then cf:SetClampRectInsets(unpack(s.clampInsets)) end
        if cf==ChatFrame1 then
            SetPoints(cf,s.points); Size(cf,s.width,s.height)
            if s.userPlaced==false then cf:SetUserPlaced(false) end; s.userPlaced=nil
        end
        if s.edit then
            SetPoints(s.edit,s.editPoints); s.edit:SetHeight(s.editHeight); s.edit:SetAlpha(1)
            RestoreFont(s.edit,s.editFont); RestoreFont(s.edit.header,s.editHeaderFont); s.edit:SetAutoFocus(s.autoFocus)
        end
        if s.tab then s.tab:EnableMouse(true) end
        RestoreTextures(s); UnskinTab(s)
        if s.buttonFrame then if s.buttonShown then s.buttonFrame:Show() else s.buttonFrame:Hide() end end
        s.panel:Hide()
    end
    passthrough=false; alpha,sbAlpha=1,1
    if sidebar then sidebar:Hide() end
    if scrollButton then scrollButton:Hide() end
    RestoreNativeButtons(); ECHAT.ApplyLockChatSize()
    local dock=GENERAL_CHAT_DOCK
    if dockPoints and dock and dock.SetPoint then
        SetPoints(dock,dockPoints); dockPoints=nil
        if FCFDock_UpdateTabs and dock.DOCKED_CHAT_FRAMES then FCFDock_UpdateTabs(dock,true) end
    end
end
local sizeSynced, appliedW, appliedH = false
-- FCF_UpdateDockPosition re-adds its BOTTOMLEFT point (without clearing ours)
-- to a main chat that is not user placed, pulling it back to the corner.
local function MarkPlaced()
    if ChatFrame1.SetUserPlaced and ChatFrame1:IsMovable() and not ChatFrame1:IsUserPlaced() then
        local s=states[ChatFrame1]
        if s and s.userPlaced==nil then s.userPlaced=false end
        ChatFrame1:SetUserPlaced(true)
    end
end
function ns.Apply()
    local p=ns.GetSettings(); if not p then return end
    ns.ApplyBubbles()
    if ns.SyncSpamFilter then ns.SyncSpamFilter() end
    if InCombatLockdown() then pending=true; return end
    pending=false; if not p.enabled then ns.Restore(); return end
    ns.Migrate(p)
    local wasActive=active; active=true
    local frames={}
    for i=1,NUM_CHAT_WINDOWS or 10 do frames["ChatFrame"..i]=true end
    for _,name in ipairs(CHAT_FRAMES or {}) do frames[name]=true end
    if not sizeSynced and SetChatWindowSize then
        sizeSynced=true
        for i=1,NUM_CHAT_WINDOWS or 10 do if _G["ChatFrame"..i] then SetChatWindowSize(i,p.chatFontSize) end end
    end
    if Skinned() then
        EnsureSidebar()
        HideNativeButton("ChatFrameMenuButton"); HideNativeButton("FriendsMicroButton")
    else RestoreNativeButtons() end
    for name in pairs(frames) do
        local cf=_G[name]
        if cf then
            local s=Capture(cf)
            if not wasActive then SeedHistory(cf,s) end
            cf:SetFrameLevel(max(2,s.level))
            -- A later addon may have wrapped our bridge. Re-wrapping that
            -- chain would recurse; leave it attached until it is removed.
            if not s.bridged then s.addMessage=cf.AddMessage; cf.AddMessage=s.wrapper; s.bridged=true end
            if not s.linkBridged then s.hyperlink=cf:GetScript("OnHyperlinkClick"); cf:SetScript("OnHyperlinkClick",s.linkWrapper); s.linkBridged=true end
            if cf:GetScript("OnHyperlinkEnter")==nil then cf:SetScript("OnHyperlinkEnter",LinkEnter); cf:SetScript("OnHyperlinkLeave",LinkLeave) end
            Style(cf,s)
        end
    end
    local w,h=max(200,min(900,p.width)),max(80,min(600,p.height))
    if w~=appliedW or h~=appliedH then Size(ChatFrame1,w,h); appliedW,appliedH=w,h end
    if resetPosition and states[ChatFrame1] then SetPoints(ChatFrame1,states[ChatFrame1].points); resetPosition=false end
    if p.position then
        ChatFrame1:ClearAllPoints(); ChatFrame1:SetPoint(p.position.point,UIParent,p.position.relPoint,p.position.x,p.position.y)
        MarkPlaced()
    end
    ns.LayoutSidebar(); LayoutDock(); RefreshTabs(); ECHAT.ApplyLockChatSize()
    if not wasActive then ns.RebuildRoster(); ns.ResetIdle() end
    if not historyReplayed then ReplayHistory() end
    ApplyAlpha(); driver:Show(); tick=1
end
function ns.ResetPosition()
    local p=ns.GetSettings(); if not p then return end
    p.position=nil; resetPosition=true; ns.Apply()
end
function ECHAT.ApplyChatFontSize(size)
    local p=ns.GetSettings(); if not p then return end
    if type(size)=="number" and size>0 then
        p.chatFontSize=size
        if SetChatWindowSize then for i=1,NUM_CHAT_WINDOWS or 10 do if _G["ChatFrame"..i] then SetChatWindowSize(i,size) end end end
    end
    ns.Apply()
end
ECHAT.ApplyFonts=ns.Apply; ECHAT.ApplyTabAppearance=ns.Apply
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
    if ns.RegisterSpamFilters then ns.RegisterSpamFilters() end
    if not addon.db then return end
    if ChatFrame_AddMessageEventFilter then
        for _,kind in ipairs(STAMP_EVENTS) do ChatFrame_AddMessageEventFilter("CHAT_MSG_"..kind,StampFilter) end
        for _,kind in ipairs(NAME_EVENTS) do ChatFrame_AddMessageEventFilter("CHAT_MSG_"..kind,NameFilter) end
    end
    ns.Apply()
    if type(FCFTab_UpdateColors)=="function" then
        hooksecurefunc("FCFTab_UpdateColors",function(tab,selected)
            local cf=_G["ChatFrame"..tab:GetID()]; local s=cf and states[cf]
            if s then s.selected=selected and true or false; PaintTab(s) end
        end)
    end
    if type(FCFDock_UpdateTabs)=="function" then
        hooksecurefunc("FCFDock_UpdateTabs",function(dock) if active and dock==GENERAL_CHAT_DOCK then LayoutDock(); RefreshTabs() end end)
    end
    if type(FCF_SetChatWindowFontSize)=="function" then
        -- A tab menu size choice becomes the profile size, as on Retail.
        hooksecurefunc("FCF_SetChatWindowFontSize",function(menu,_,size)
            size=size or (type(menu)=="table" and menu.value)
            local p=ns.GetSettings()
            if active and p and type(size)=="number" and size~=p.chatFontSize then ECHAT.ApplyChatFontSize(size) end
        end)
    end
    if type(FCF_SavePositionAndDimensions)=="function" then
        hooksecurefunc("FCF_SavePositionAndDimensions",function(cf)
            local p=ns.GetSettings()
            if not (active and p and cf==ChatFrame1) then return end
            p.width,p.height=floor(cf:GetWidth()+.5),floor(cf:GetHeight()+.5); appliedW,appliedH=p.width,p.height
            local point,rel,relPoint,x,y=cf:GetPoint(1)
            if p.position and point and (rel==nil or rel==UIParent) then p.position={point=point,relPoint=relPoint,x=x,y=y} end
        end)
    end
    if E.RegisterUnlockElements and E.MakeUnlockElement then
        -- Retail's key: unlock mode keeps its SetPoint/size hooks off ECHAT_
        -- elements, which would taint FCF_OpenTemporaryWindow's chain.
        E:RegisterUnlockElements({E.MakeUnlockElement({key="ECHAT_MainChat",label="Chat",group="Chat",order=600,
            noResize=true,noAnchorTo=true,getFrame=function() return ChatFrame1 end,
            getSize=function() return ChatFrame1:GetWidth(),ChatFrame1:GetHeight() end,
            isHidden=function() local p=ns.GetSettings(); return not p or not p.enabled end,
            onLiveMove=MarkPlaced,
            savePos=function(_,point,relPoint,x,y)
                local p=ns.GetSettings(); if not p then return end
                p.position={point=point,relPoint=relPoint or point,x=x,y=y}
                if not E._unlockActive then ns.Apply() end
            end,
            loadPos=function() local p=ns.GetSettings(); return p and p.position end,
            clearPos=ns.ResetPosition,
            applyPos=ns.Apply,
        })},ADDON_NAME)
        -- Right-click / cog menu "Element Options" deep link.
        E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
        E._ELEMENT_SETTINGS_MAP.ECHAT_MainChat={module=ADDON_NAME,page="Chat",sectionName="DISPLAY",highlightText="Main Chat Width"}
    end
    -- Opening re-asserts the saved spot for the mover; closing lands the
    -- committed or reverted position.
    if E.RegisterUnlockModeListener then
        E:RegisterUnlockModeListener(ADDON_NAME,function() if active then ns.Apply() end end)
    end
    local events=CreateFrame("Frame")
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_LOGOUT","PARTY_MEMBERS_CHANGED",
        "RAID_ROSTER_UPDATE","ZONE_CHANGED_NEW_AREA","CHAT_MSG_WHISPER","CHAT_MSG_BN_WHISPER"}) do events:RegisterEvent(event) end
    for event in pairs(BUBBLE_EVENTS) do events:RegisterEvent(event) end
    local lastWhisper=0
    events:SetScript("OnEvent",function(_,event,msg)
        if event=="PLAYER_ENTERING_WORLD" then ns.Apply()
        elseif event=="PLAYER_REGEN_ENABLED" then if pending then ns.Apply() end
        elseif event=="PLAYER_LOGOUT" then ns.SaveHistory()
        elseif event=="PARTY_MEMBERS_CHANGED" or event=="RAID_ROSTER_UPDATE" then ns.RebuildRoster()
        elseif event=="ZONE_CHANGED_NEW_AREA" then ns.ApplyBubbles()
        elseif event=="CHAT_MSG_WHISPER" or event=="CHAT_MSG_BN_WHISPER" then
            local p=ns.GetSettings(); ns.ResetIdle()
            local path=active and p and SoundPath(p.whisperSoundKey)
            if path and GetTime()-lastWhisper>=1 then lastWhisper=GetTime(); PlaySoundFile(path) end
        end
        if BUBBLE_EVENTS[event] and type(msg)=="string" then
            local cfg=ns.GetBubbleSettings()
            if cfg and cfg.enabled then
                recent[msg]={channel=BUBBLE_EVENTS[event],time=GetTime()}
                for text,seen in pairs(recent) do if GetTime()-seen.time>30 then recent[text]=nil end end
                scanUntil=GetTime()+1; bubbleScan:Show()
            end
        end
    end)
    ns.events=events
    for _,name in ipairs({"FCF_OpenNewWindow","FCF_OpenTemporaryWindow","FCF_SetWindowAlpha","FCF_SetWindowColor","FCF_DockFrame","FCF_UnDockFrame"}) do
        if type(_G[name])=="function" then hooksecurefunc(name,function() if active then ns.Apply() end end) end
    end
end
