-- Explicit legacy chat contracts, native entry points are loaded by Python.
local m=getmetatable(UIParent).__index
combat,shift=false,false
C_Texture=nil; C_Spell=nil; C_CVar=nil; issecretvalue=nil
UISpecialFrames={}; CHAT_FRAMES={}; NUM_CHAT_WINDOWS=10
function InCombatLockdown() return combat end
function IsShiftKeyDown() return shift end
function date(fmt) assert(type(fmt)=="string"); return "13:07"..(fmt:match("%s$") or "") end
function time() return 1000 end
function m:GetName() return self.name end
function m:GetID() return self.id end
function m:SetID(id) self.id=id end
function m:SetPoint(point,...)
    self.points=self.points or {}
    for i,p in ipairs(self.points) do if p[1]==point then self.points[i]={point,...}; return end end
    self.points[#self.points+1]={point,...}
end
function m:SetAllPoints(rel) self.points={{"TOPLEFT",rel or self.parent,"TOPLEFT",0,0},{"BOTTOMRIGHT",rel or self.parent,"BOTTOMRIGHT",0,0}} end
function m:GetNumPoints() return #(self.points or {}) end
function m:GetPoint(i) return unpack((self.points or {})[i or 1] or {}) end
function m:ClearAllPoints() self.points={} end
function m:SetClampRectInsets(...) self.clampInsets={...} end
function m:GetClampRectInsets() return unpack(self.clampInsets or {0,0,0,0}) end
function m:SetClampedToScreen(v) self.clamped=v end
function m:IsClampedToScreen() return self.clamped or false end
local oldGetBottom=m.GetBottom
function m:GetBottom()
    local p=(self.points or {})[1]
    if self.kind=='ScrollingMessageFrame' and p and p[2]==UIParent and p[3]=='BOTTOMLEFT' then
        local bottom=p[5]-(p[1]=='CENTER' and self:GetHeight()/2 or 0)
        -- Model the native clamp rectangle: bottom=-50 reserves 50px.
        if self:IsClampedToScreen() then bottom=math.max(-select(4,self:GetClampRectInsets()),bottom) end
        return bottom
    end
    return oldGetBottom(self)
end
function m:SetFont(...) self.font={...} end
function m:GetFont() return unpack(self.font or {"native.ttf",14,""}) end
function m:SetFrameLevel(v) self.level=v end
function m:GetFrameLevel() return self.level or 3 end
function m:SetAlpha(v) self.alpha=v end
function m:GetAlpha() if self.alpha~=nil then return self.alpha end; return .7 end
function m:EnableMouse(v) self.mouse=v end
function m:IsMouseEnabled() return self.mouse end
function m:EnableMouseWheel(v) self.wheelEnabled=v end
function m:IsMouseWheelEnabled() return self.wheelEnabled or false end
function m:SetFading(v) self.fading=v end
function m:GetFading() return self.fading end
function m:SetTimeVisible(v) self.timeVisible=v end
function m:GetTimeVisible() return self.timeVisible or 120 end
function m:SetBackdrop(v) self.backdrop=v end
function m:SetBackdropColor(...) self.bgColor={...} end
function m:SetBackdropBorderColor(...) self.borderColor={...} end
function m:HookScript(script,fn)
    self.hooks[script]=self.hooks[script] or {}; table.insert(self.hooks[script],fn)
end
function m:RunScript(script,...)
    if self.scripts[script] then self.scripts[script](self,...) end
    for _,fn in ipairs(self.hooks[script] or {}) do fn(self,...) end
end
function m:Show() local was=self.shown; self.shown=true; if not was then self:RunScript("OnShow") end end
function m:Hide() local was=self.shown; self.shown=false; if was then self:RunScript("OnHide") end end
function m:IsAutoFocus() return self.autoFocus or false end
function m:SetFocus() self.focus=true end
function m:HasFocus() return self.focus or false end
function m:SetMultiLine(v) self.multiline=v end
function m:SetMaxLetters(v) self.maxLetters=v end
function m:HighlightText() self.highlighted=true end
function m:SetScrollChild(v) self.scrollChild=v end
function m:SetVerticalScroll(v) self.verticalScroll=v end
function m:ScrollUp() self.scroll="up" end
function m:ScrollDown() self.scroll="down" end
function m:ScrollToTop() self.scroll="top" end
function m:ScrollToBottom() self.scroll="bottom" end
function m:AddMessage(text,...)
    self.messages=self.messages or {}; self.messages[#self.messages+1]={text,...}; return "native-result"
end
function m:GetNumMessages() return #(self.messages or {}) end
function m:GetMessageInfo(i) return unpack(self.messages[i]) end
function m:Clear() self.messages={} end
function m:SetVertexColor(...) self.vertex={...} end
function m:GetFontString() return self.fontString end
function m:Enable() self.enabled=true end
function m:Disable() self.enabled=false end
function m:IsEnabled() return self.enabled~=false end
function m:GetNormalTexture() return self.normal end
function m:GetPushedTexture() return self.pushed end
function m:GetDisabledTexture() return self.disabled end
function m:GetHighlightTexture() return self.highlight end
function m:GetVertexColor() return unpack(self.vertex or {.1,.2,.3,.7}) end
local nativeCreate=CreateFrame
function CreateFrame(kind,name,parent,template)
    local f=nativeCreate(kind,name,parent,template); f.name=name; return f
end
function NewChat(id)
    local name="ChatFrame"..id
    local f=CreateFrame("ScrollingMessageFrame",name,UIParent); f.id=id; f.movable=true
    f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",40,60); f:SetWidth(380); f:SetHeight(160)
    f:SetClampedToScreen(true); f:SetClampRectInsets(-35,35,id==1 and 38 or 26,-50)
    f:SetFading(true); f:SetTimeVisible(75); f:SetScript("OnEvent",function() nativeEvents=nativeEvents+1 end)
    f:SetScript("OnHyperlinkClick",ChatFrame_OnHyperlinkShow); f:SetScript("OnMouseWheel",FloatingChatFrame_OnMouseScroll)
    f:EnableMouseWheel(true)
    f.editBox=CreateFrame("EditBox",name.."EditBox",UIParent)
    f.editBox:SetPoint("TOPLEFT",f,"BOTTOMLEFT",-5,-2); f.editBox:SetPoint("TOPRIGHT",f,"BOTTOMRIGHT",5,-2)
    f.editBox:SetAutoFocus(false)
    f.editBox.header=CreateFrame("FontString",name.."EditBoxHeader",f.editBox)
    f.editBox:SetScript("OnEnterPressed",function() nativeSent=nativeSent+1 end)
    f.editBox:SetScript("OnEscapePressed",function(self) self:Hide() end)
    for _,suffix in ipairs({"Left","Right","Mid","FocusLeft","FocusRight","FocusMid"}) do CreateFrame("Texture",name.."EditBox"..suffix,f.editBox) end
    local tab=CreateFrame("Button",name.."Tab",UIParent); tab.id=id
    tab:SetWidth(64); tab:SetHeight(32); tab:SetPoint("BOTTOMLEFT",f,"TOPLEFT",2,0)
    tab.fontString=CreateFrame("FontString",name.."TabText",tab); tab.fontString:SetFont("tab.ttf",10,"")
    tab.fontString:SetText(id==2 and "Combat Log" or "General")
    tab:SetScript("OnClick",function(self,button) FCF_Tab_OnClick(self,button) end)
    for key,suffix in pairs({leftTexture="Left",middleTexture="Middle",rightTexture="Right",
        leftSelectedTexture="SelectedLeft",middleSelectedTexture="SelectedMiddle",rightSelectedTexture="SelectedRight",
        leftHighlightTexture="HighlightLeft",middleHighlightTexture="HighlightMiddle",rightHighlightTexture="HighlightRight",glow="Glow"}) do
        tab[key]=CreateFrame("Texture",name.."Tab"..suffix,tab)
    end
    tab.glow:SetTexture("Interface\\ChatFrame\\ChatFrameTab-NewMessage"); tab.glow:Hide()
    f.isDocked=true
    f.buttonFrame=CreateFrame("Frame",name.."ButtonFrame",f)
    f.buttonFrame:SetScript("OnMouseDown",function() nativeButtonClicks=nativeButtonClicks+1 end)
    for _,suffix in ipairs({"UpButton","DownButton","BottomButton"}) do
        local button=CreateFrame("Button",name.."ButtonFrame"..suffix,f.buttonFrame)
        for _,key in ipairs({"normal","pushed","highlight","disabled"}) do button[key]=CreateFrame("Texture",nil,button) end
        button:SetScript("OnClick",function() nativeButtonClicks=nativeButtonClicks+1 end)
    end
    for _,suffix in ipairs({"Background","TopLeftTexture","BottomLeftTexture","TopRightTexture","BottomRightTexture","LeftTexture","RightTexture","TopTexture","BottomTexture"}) do CreateFrame("Texture",name..suffix,f) end
    CHAT_FRAMES[#CHAT_FRAMES+1]=name
    if id~=1 then f:Hide() end
    return f
end
nativeEvents,nativeSent,nativeButtonClicks=0,0,0
function FCF_GetCurrentChatFrame() return selected or ChatFrame1 end
function SetItemRef(link,text,button,frame) itemRef={link,text,button,frame} end
function SetChatWindowSize(id,size) savedFontSize={id,size} end
function SetChatWindowAlpha(id,alpha) savedAlpha={id,alpha} end
function SetChatWindowColor(id,r,g,b) savedColor={id,r,g,b} end
function FCF_OpenTemporaryWindow() return NewChat(11) end
function FCF_OpenNewWindow() return ChatFrame3 end
NORMAL_FONT_COLOR={r=1,g=1,b=1}
DEFAULT_TAB_SELECTED_COLOR_TABLE={r=1,g=.5,b=.25}
GENERAL_CHAT_DOCK={}
function FCFDock_GetSelectedWindow() return SELECTED_DOCK_FRAME or ChatFrame1 end
function FCF_SelectDockFrame(cf)
    SELECTED_DOCK_FRAME=cf
    for _,name in ipairs(CHAT_FRAMES) do FCFTab_UpdateColors(_G[name.."Tab"],_G[name]==cf) end
end
function FCF_FadeInChatFrame() end
function CloseDropDownMenus() end
function ToggleDropDownMenu(...) dropDownArgs={...} end
function ChatEdit_SetLastActiveWindow(box) lastActiveBox=box end
function m:StopMovingOrSizing() end
function hooksecurefunc(target,name,fn)
    if type(target)=="string" then fn,name,target=name,target,_G end
    local old=target[name]; assert(type(old)=="function")
    target[name]=function(...) local results={old(...)}; fn(...); return unpack(results) end
end
CHAT_FRAME_TEXTURES={"Background","TopLeftTexture","BottomLeftTexture","TopRightTexture","BottomRightTexture","LeftTexture","RightTexture","TopTexture","BottomTexture"}
function m:GetObjectType() return self.kind end
for i=1,10 do NewChat(i) end
DEFAULT_CHAT_FRAME=ChatFrame1
function EllesmereUI.MakeUnlockElement(cfg) return cfg end
function EllesmereUI:RegisterUnlockElements(list,folder) unlockElements,unlockFolder=list,folder end
EllesmereUI._unlockModeListeners={}
function EllesmereUI:RegisterUnlockModeListener(owner,fn) self._unlockModeListeners[owner]=fn end
function EllesmereUI:ShowModule(folder) shownModule=folder end
function EllesmereUI.EnsureOptionsLoaded() optionsLoaded=true end
function EllesmereUI:InvalidatePageCache() end
function EllesmereUI.GetFontOutlineFlag() return "OUTLINE, SLUG" end
function EllesmereUI.ResolveFontName(name) return name..".ttf" end
function EllesmereUI.BuildFontDropdownData() return {__global="Global",native="Native"},{"__global","native"} end
-- Retail-port surface: dock, sidebar data sources, tooltips, CVars, bubbles.
function m:GetStringWidth() return #(self.text or "")*6 end
function m:SetShadowOffset(x,y) self.shadow={x,y} end
function m:GetShadowOffset() return unpack(self.shadow or {1,-1}) end
function m:SetShadowColor() end
function m:SetMovable(v) self.movable=v end
function m:IsMovable() return self.movable or false end
function m:SetUserPlaced(v) assert(self.movable,"Frame is not movable"); self.userPlaced=v end
function m:IsUserPlaced() return self.userPlaced or false end
-- The client rejects text on a font string that has no font yet.
function m:SetText(v)
    if self.kind=="FontString" and not self.font then error("FontString:SetText(): Font not set") end
    self.text=v
end
GetNumShapeshiftForms=function() return 0 end; HasPetUI=function() return false end; PetHasActionBar=function() return false end
MultiBarBottomLeft=CreateFrame("Frame","MultiBarBottomLeft",UIParent); MultiBarBottomLeft:Hide()
function FCF_DockUpdate() end
function m:RegisterForDrag() end
function m:StartMoving() self.moving=true end
function m:SetHyperlinksEnabled(v) self.hyperlinks=v end
function m:SetTextColor(...) self.textColor={...} end
function m:GetTextColor() return unpack(self.textColor or {1,1,1,1}) end
function m:GetBackdrop() return self.backdrop end
function m:GetBackdropColor() return unpack(self.bgColor or {0,0,0,1}) end
function m:GetBackdropBorderColor() return unpack(self.borderColor or {1,1,1,1}) end
function m:GetRegions()
    local out={}; for _,c in ipairs(self.children) do if c.kind=="Texture" or c.kind=="FontString" then out[#out+1]=c end end
    return unpack(out)
end
function m:GetChildren()
    local out={}; for _,c in ipairs(self.children) do if c.kind~="Texture" and c.kind~="FontString" then out[#out+1]=c end end
    return unpack(out)
end
function m:IsVisible() return self.shown and (not self.parent or self.parent==UIParent or self.parent:IsVisible()) end
hover={}
function MouseIsOver(f) return hover[f] and true or false end
function ChatEdit_GetActiveWindow() return activeEdit end
function GetNumFriends() return 3,2 end
function BNGetNumFriends() return 5,1 end
function IsInGuild() return true end
function GuildRoster() guildRosterCalls=(guildRosterCalls or 0)+1 end
function GetNumGuildMembers() return 3 end
function GetGuildRosterInfo(i) return "member"..i,"Rank",1,80,"Warrior","Dalaran","","",i~=3,0,"WARRIOR" end
function GetInventoryItemDurability(slot) if slot==1 then return 40,80 end end
function ToggleFriendsFrame(tab) friendsTab=tab end
function PlaySoundFile(path) playedSound=path end
cvars={chatBubbles="0",chatBubblesParty="0"}
function GetCVar(name) return cvars[name] or "1" end
function SetCVar(name,value) cvars[name]=value end
inInstance=false
function IsInInstance() return inInstance end
function GetCursorPosition() return 300,200 end
function IsControlKeyDown() return false end
GameTooltip=CreateFrame("Frame","GameTooltip",UIParent)
function GameTooltip:SetOwner(owner) self.owner=owner end
function GameTooltip:SetText(text) self.tipText=text end
function GameTooltip:SetHyperlink(link) self.link=link end
chatFilters={}
function ChatFrame_AddMessageEventFilter(event,fn) chatFilters[event]=chatFilters[event] or {}; table.insert(chatFilters[event],fn) end
CHAT_MSG_PARTY="Party"; CHAT_MSG_RAID="Raid"; CHAT_MSG_GUILD="Guild"
function EllesmereUI.BuildAlertSoundTables() return {airhorn="Interface\\sounds\\airhorn.ogg"},{none="None",airhorn="Airhorn"},{"none","airhorn"} end
borderCalls={}
function EllesmereUI.ApplyBorderStyle(frame,step,...) borderCalls[frame]={step,...} end
WorldFrame=CreateFrame("Frame","WorldFrame",UIParent)
ChatFrame1ResizeButton=CreateFrame("Button","ChatFrame1ResizeButton",ChatFrame1)
ChatFrameMenuButton=CreateFrame("Button","ChatFrameMenuButton",UIParent)
FriendsMicroButton=CreateFrame("Button","FriendsMicroButton",UIParent)
GENERAL_CHAT_DOCK=CreateFrame("Frame","GeneralDockManager",UIParent)
GENERAL_CHAT_DOCK:SetPoint("BOTTOMLEFT",ChatFrame1,"TOPLEFT",0,6)
GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES={ChatFrame1,ChatFrame2}
GENERAL_CHAT_DOCK.scrollFrame=CreateFrame("ScrollFrame",nil,GENERAL_CHAT_DOCK)
GENERAL_CHAT_DOCK.scrollFrame.child=CreateFrame("Frame",nil,GENERAL_CHAT_DOCK.scrollFrame)
function GENERAL_CHAT_DOCK.scrollFrame:GetScrollChild() return self.child end
GENERAL_CHAT_DOCK.overflowButton=CreateFrame("Button",nil,GENERAL_CHAT_DOCK); GENERAL_CHAT_DOCK.overflowButton.width=20
ChatFrame1.isStaticDocked=true; ChatFrame2.isStaticDocked=true
function FCFTab_UpdateAlpha() end
function PanelTemplates_TabResize(tab,padding,absolute) tab:SetWidth(absolute or 50) end
function FCFDock_CalculateTabSize() return 90,false end
function FCFDock_ScrollToSelectedTab() end
function FCFDock_GetSelectedWindow(dock) return SELECTED_DOCK_FRAME or ChatFrame1 end
