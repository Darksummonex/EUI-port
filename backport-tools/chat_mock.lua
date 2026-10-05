-- Explicit legacy chat contracts, native entry points are loaded by Python.
local m=getmetatable(UIParent).__index
combat,shift=false,false
C_Texture=nil; C_Spell=nil; C_CVar=nil; issecretvalue=nil
UISpecialFrames={}; CHAT_FRAMES={}; NUM_CHAT_WINDOWS=10
function InCombatLockdown() return combat end
function IsShiftKeyDown() return shift end
function date(fmt) assert(type(fmt)=="string"); return "13:07" end
function m:GetName() return self.name end
function m:GetID() return self.id end
function m:SetID(id) self.id=id end
function m:SetPoint(...) self.points=self.points or {}; self.points[#self.points+1]={...} end
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
    local f=CreateFrame("ScrollingMessageFrame",name,UIParent); f.id=id
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
    tab.fontString=CreateFrame("FontString",name.."TabText",tab)
    tab:SetScript("OnClick",function(self,button) FCF_Tab_OnClick(self,button) end)
    for key,suffix in pairs({leftTexture="Left",middleTexture="Middle",rightTexture="Right",
        leftSelectedTexture="SelectedLeft",middleSelectedTexture="SelectedMiddle",rightSelectedTexture="SelectedRight",
        leftHighlightTexture="HighlightLeft",middleHighlightTexture="HighlightMiddle",rightHighlightTexture="HighlightRight",glow="Glow"}) do
        tab[key]=CreateFrame("Texture",name.."Tab"..suffix,tab)
    end
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
function EllesmereUI:ShowModule(folder) shownModule=folder end
function EllesmereUI.EnsureOptionsLoaded() optionsLoaded=true end
function EllesmereUI:InvalidatePageCache() end
function EllesmereUI.GetFontOutlineFlag() return "OUTLINE, SLUG" end
function EllesmereUI.ResolveFontName(name) return name..".ttf" end
function EllesmereUI.BuildFontDropdownData() return {__global="Global",native="Native"},{"__global","native"} end
