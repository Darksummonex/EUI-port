-- Quick Keybind Mode (/kb): hover an action button and press a key to bind it.
-- Wrath has no Blizzard_QuickKeybind, so the dialog and key capture are EUI's own.
local _,ns=...
local E=EllesmereUI
if not ns.IsWrath then return end
local Q={overlays={}}
ns.QuickKeybind=Q
local FLAT="Interface\\Buttons\\WHITE8X8"
local HIGHLIGHT="Interface\\AddOns\\EllesmereUIActionBars\\Media\\Textures_335\\highlight-2.tga"
local DEFAULT_SET,ACCOUNT_SET,CHARACTER_SET=DEFAULT_BINDINGS or 0,ACCOUNT_BINDINGS or 1,CHARACTER_BINDINGS or 2
local IGNORED={LSHIFT=true,RSHIFT=true,LCTRL=true,RCTRL=true,LALT=true,RALT=true,UNKNOWN=true,LeftButton=true,RightButton=true}
local MOUSE={MiddleButton="BUTTON3",Button4="BUTTON4",Button5="BUTTON5"}
local NATIVE={petBar="BONUSACTIONBUTTON",stanceBar="SHAPESHIFTBUTTON"}
local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff0cd29fEllesmereUI|r: "..msg) end
function Q.Command(d,i) return d.binding and d.binding..i or NATIVE[d.key] and NATIVE[d.key]..i end
function Q.KeyString(key)
    if not key or IGNORED[key] then return nil end
    key=MOUSE[key] or key
    return (IsAltKeyDown() and "ALT-" or "")..(IsControlKeyDown() and "CTRL-" or "")..(IsShiftKeyDown() and "SHIFT-" or "")..key
end
-- Blizzard's binding UI shows two keys per command; a third replaces the oldest.
function Q.Bind(command,key)
    if not command or not key or InCombatLockdown() or GetBindingAction(key)==command then return end
    local keys={GetBindingKey(command)}
    if #keys>=2 then SetBinding(keys[1]) end
    SetBinding(key,command); Q.dirty=true
end
function Q.Clear(command)
    if not command or InCombatLockdown() then return end
    for _,key in ipairs({GetBindingKey(command)}) do SetBinding(key) end
    Q.dirty=true
end
local function Tooltip(o)
    GameTooltip:SetOwner(o,"ANCHOR_RIGHT")
    GameTooltip:AddLine(o.label,1,1,1)
    local keys={GetBindingKey(o.command)}
    if #keys==0 then GameTooltip:AddLine("Not bound",.6,.6,.6) end
    for _,key in ipairs(keys) do GameTooltip:AddLine(GetBindingText(key,"KEY_"),.047,.824,.616) end
    GameTooltip:AddLine("Press a key to bind it. Right-click to unbind.",.8,.8,.8,true)
    GameTooltip:Show()
end
local function Capture(o,key)
    local full=Q.KeyString(key)
    if full then Q.Bind(o.command,full); Tooltip(o) end
end
local function Overlay(button,d,i,command)
    local o=Q.overlays[button]
    if not o then
        o=CreateFrame("Frame",nil,UIParent); Q.overlays[button]=o
        o:SetFrameStrata("DIALOG"); o:SetAllPoints(button); o:EnableMouse(true); o:EnableMouseWheel(true); o:Hide()
        o.tex=o:CreateTexture(nil,"OVERLAY"); o.tex:SetAllPoints(o); o.tex:SetTexture(HIGHLIGHT); o.tex:SetAlpha(.5)
        o:SetScript("OnEnter",function(self) self:EnableKeyboard(true); self.tex:SetAlpha(1); Tooltip(self) end)
        o:SetScript("OnLeave",function(self) self:EnableKeyboard(false); self.tex:SetAlpha(.5); GameTooltip:Hide() end)
        o:SetScript("OnKeyDown",function(self,key)
            if key=="ESCAPE" then Q.Close(false) else Capture(self,key) end
        end)
        o:SetScript("OnMouseDown",function(self,mouse)
            if mouse=="RightButton" then Q.Clear(self.command); Tooltip(self) else Capture(self,mouse) end
        end)
        o:SetScript("OnMouseWheel",function(self,delta) Capture(self,delta>0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN") end)
        o:SetScript("OnHide",function(self) self:EnableKeyboard(false) end)
    end
    o.command,o.label=command,d.label.." - Button "..i
    o.tex:SetVertexColor(ns.InteractionColor("highlight"))
    return o
end
function Q.Refresh()
    for _,d in ipairs(ns.definitions) do
        local bar=ns.bars[d.key]
        if bar then for i,button in ipairs(bar.buttons) do
            local command=Q.Command(d,i)
            if command and Q.open and button:IsVisible() then Overlay(button,d,i,command):Show()
            elseif Q.overlays[button] then Q.overlays[button]:Hide() end
        end end
    end
end
local function StyledButton(parent,label,fn)
    local b=CreateFrame("Button",nil,parent); b:SetWidth(112); b:SetHeight(26)
    if E.MakeStyledButton and E.WB_COLOURS then E.MakeStyledButton(b,label,13,E.WB_COLOURS,fn)
    else b:SetScript("OnClick",fn) end
    return b
end
local function Text(parent,size,r,g,b)
    local fs=parent:CreateFontString(nil,"OVERLAY")
    fs:SetFont(E.GetFontPath and E.GetFontPath("actionBars") or STANDARD_TEXT_FONT,size,"")
    fs:SetTextColor(r,g,b); fs:SetJustifyH("CENTER")
    return fs
end
StaticPopupDialogs.EUI335_QK_RESET={text="Reset all keybindings to their defaults?",button1=OKAY,button2=CANCEL,
    OnAccept=function() if not InCombatLockdown() then LoadBindings(DEFAULT_SET); Q.dirty=true end end,
    timeout=0,whileDead=1,hideOnEscape=1}
StaticPopupDialogs.EUI335_QK_ACCOUNT={text="Switch to account-wide keybindings? Character-specific keybindings will be discarded when you press Okay.",
    button1=OKAY,button2=CANCEL,
    OnAccept=function() if not InCombatLockdown() then LoadBindings(ACCOUNT_SET); Q.set=ACCOUNT_SET; Q.dirty=true end end,
    OnCancel=function() if Q.frame then Q.frame.check:SetChecked(Q.set==CHARACTER_SET) end end,
    timeout=0,whileDead=1,hideOnEscape=1}
local function Dialog()
    if Q.frame then return Q.frame end
    local f=CreateFrame("Frame","EUI335QuickKeybindFrame",UIParent); Q.frame=f
    f:SetWidth(400); f:SetHeight(214); f:SetPoint("TOP",UIParent,"TOP",0,-110)
    f:SetFrameStrata("FULLSCREEN_DIALOG"); f:SetClampedToScreen(true); f:EnableMouse(true); f:SetMovable(true)
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing)
    f:SetBackdrop({bgFile=FLAT,edgeFile=FLAT,edgeSize=1}); f:SetBackdropColor(.05,.05,.05,.96); f:SetBackdropBorderColor(.2,.2,.2,1)
    local accent=E.ELLESMERE_GREEN or {r=.047,g=.824,b=.616}
    local title=Text(f,16,accent.r,accent.g,accent.b); title:SetPoint("TOP",f,"TOP",0,-14); title:SetText("Quick Keybind Mode")
    local body=Text(f,13,1,1,1); body:SetPoint("TOPLEFT",f,"TOPLEFT",20,-44); body:SetPoint("TOPRIGHT",f,"TOPRIGHT",-20,-44)
    body:SetText("You are in Quick Keybind Mode. Mouse over a button and press the desired key to set the binding for that button. Right-click a button to unbind it.\n\nCanceling will remove you from Quick Keybind Mode.")
    local check=CreateFrame("CheckButton",nil,f); f.check=check
    check:SetWidth(16); check:SetHeight(16); check:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",104,52)
    check:SetBackdrop({bgFile=FLAT,edgeFile=FLAT,edgeSize=1}); check:SetBackdropColor(.1,.1,.1,1); check:SetBackdropBorderColor(.35,.35,.35,1)
    local mark=check:CreateTexture(nil,"ARTWORK"); mark:SetTexture(FLAT); mark:SetPoint("TOPLEFT",check,"TOPLEFT",3,-3)
    mark:SetPoint("BOTTOMRIGHT",check,"BOTTOMRIGHT",-3,3); mark:SetVertexColor(accent.r,accent.g,accent.b); check:SetCheckedTexture(mark)
    local label=Text(f,12,.85,.85,.85); label:SetPoint("LEFT",check,"RIGHT",8,0); label:SetText("Character Specific Keybindings")
    check:SetScript("OnClick",function(self)
        if self:GetChecked() then Q.set=CHARACTER_SET; Q.dirty=true
        else self:SetChecked(true); StaticPopup_Show("EUI335_QK_ACCOUNT") end
    end)
    local okay=StyledButton(f,"Okay",function() Q.Close(true) end); okay:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",16,14)
    local reset=StyledButton(f,"Reset To Default",function() StaticPopup_Show("EUI335_QK_RESET") end); reset:SetPoint("BOTTOM",f,"BOTTOM",0,14)
    local cancel=StyledButton(f,"Cancel",function() Q.Close(false) end); cancel:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-16,14)
    f:SetScript("OnHide",function() if Q.open then Q.Close(false) end end)
    local elapsed=0
    f:SetScript("OnUpdate",function(_,dt) elapsed=elapsed+dt; if elapsed>=.25 then elapsed=0; Q.Refresh() end end)
    tinsert(UISpecialFrames,"EUI335QuickKeybindFrame")
    return f
end
function Q.Open()
    if Q.open then return end
    if InCombatLockdown() then Print("Quick Keybind Mode is not available in combat."); return end
    local p=ns.GetSettings()
    if not p or not p.enabled then Print("Enable Action Bars to use Quick Keybind Mode."); return end
    if E.IsShown and E:IsShown() and E.Hide then E:Hide() end
    Q.open,ns.quickKeybind,Q.dirty=true,true,false
    Q.originalSet=GetCurrentBindingSet and GetCurrentBindingSet() or ACCOUNT_SET
    Q.set=Q.originalSet
    ns.Apply()
    local f=Dialog(); f.check:SetChecked(Q.set==CHARACTER_SET); f:Show()
    Q.Refresh()
end
function Q.Close(save)
    if not Q.open then return end
    Q.open,ns.quickKeybind=false,nil
    if save then SaveBindings(Q.set) elseif Q.dirty then LoadBindings(Q.originalSet) end
    Q.dirty=false
    Q.Refresh(); GameTooltip:Hide()
    if Q.frame and Q.frame:IsShown() then Q.frame:Hide() end
    ns.Apply()
end
function Q.Toggle() if Q.open then Q.Close(true) else Q.Open() end end
local combat=CreateFrame("Frame")
combat:RegisterEvent("PLAYER_REGEN_DISABLED")
combat:SetScript("OnEvent",function()
    if Q.open then Q.Close(true); Print("Quick Keybind Mode saved and closed for combat.") end
end)
SLASH_EUI335QUICKKEYBIND1="/kb"
SlashCmdList.EUI335QUICKKEYBIND=Q.Toggle
