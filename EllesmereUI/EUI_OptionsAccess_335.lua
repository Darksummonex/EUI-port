-- Wrath entry points for the existing, load-on-demand settings panel.
local E=EllesmereUI
if not E or not (EUI335 and EUI335.IsWrath) or E._wrathOptionsAccess then return end
local A={}
E._wrathOptionsAccess=A

function A.Open()
    if InCombatLockdown() then
        if E.PrintError then E.PrintError("Cannot open options during combat.") end
        return false
    end
    if E.EnsureOptionsLoaded and not E.EnsureOptionsLoaded() then return false end
    for _,name in ipairs({"InterfaceOptionsFrame","VideoOptionsFrame","AudioOptionsFrame","GameMenuFrame"}) do
        local f=_G[name]
        if f and f:IsShown() then HideUIPanel(f) end
    end
    E:Show()
    return true
end

local function ExistingCategory()
    for _,panel in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES or {}) do
        if panel.name=="EllesmereUI" and type(panel.parent)~="string" then return panel end
    end
end

local function RegisterCategory()
    if A.category or not InterfaceOptions_AddCategory then return end
    -- The Retail core may have listed its own entry first; its button closes
    -- the Retail SettingsPanel, so it is rewired to close the native windows.
    local existing=ExistingCategory()
    if existing then
        for _,child in ipairs({existing:GetChildren()}) do
            if child:IsObjectType("Button") then
                child:SetScript("OnClick",A.Open)
                existing.openButton=existing.openButton or child
            end
        end
        A.category=existing
        return
    end
    local panel=CreateFrame("Frame","EllesmereUI_InterfaceOptions335",UIParent)
    panel.name="EllesmereUI"
    local title=panel:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
    title:SetPoint("TOPLEFT",panel,"TOPLEFT",16,-16); title:SetText("EllesmereUI")
    local description=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    description:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-12)
    description:SetText("Open the EllesmereUI settings panel.")
    local button=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
    button:SetWidth(220); button:SetHeight(24)
    button:SetPoint("TOPLEFT",description,"BOTTOMLEFT",0,-20)
    button:SetText("Open EllesmereUI"); button:SetScript("OnClick",A.Open)
    panel.openButton=button; A.category=panel
    panel:Hide()
    InterfaceOptions_AddCategory(panel)
end

local function InAnchorChain(frame,button)
    local seen={}
    while frame and frame.GetPoint and not seen[frame] do
        if frame==button then return true end
        seen[frame]=true
        local _,relative=frame:GetPoint(1)
        frame=type(relative)=="string" and _G[relative] or relative
    end
    return false
end

function A.LayoutMenu()
    if InCombatLockdown() then return end
    local menu,logout,button=GameMenuFrame,GameMenuButtonLogout,A.menuButton
    if not menu or not logout or not button then return end
    button:SetWidth(logout:GetWidth()); button:SetHeight(logout:GetHeight())
    -- Other addons can insert their own button between ours and Logout.
    -- Leave that chain intact rather than creating a circular anchor.
    if not InAnchorChain(logout,button) then
        local point,relative,relPoint,x,y=logout:GetPoint(1)
        if not point or not relative then return end
        button:ClearAllPoints(); button:SetPoint(point,relative,relPoint,x or 0,-1)
        logout:ClearAllPoints(); logout:SetPoint(point,button,relPoint,0,y or -16)
    end
    button:Show()
    local continue=GameMenuButtonContinue
    local top,bottom=menu:GetTop(),continue and continue:GetBottom()
    if top and bottom then
        local required=top-bottom+16
        if menu:GetHeight()<required then menu:SetHeight(required) end
    elseif not A.menuHeightAdded then
        menu:SetHeight(menu:GetHeight()+button:GetHeight()+1)
    end
    A.menuHeightAdded=true
end

local function RegisterMenuButton()
    local menu=GameMenuFrame
    if A.menuButton or not menu or not GameMenuButtonLogout then return end
    -- The original Core already supplies the pooled Retail menu entry.
    if type(menu.Layout)=="function" and menu.buttonPool or EllesmereUI_GameMenuButton then return end
    local button=CreateFrame("Button","EllesmereUI_GameMenuButton",menu,"GameMenuButtonTemplate")
    button:SetText("EllesmereUI"); button:SetScript("OnClick",A.Open)
    A.menuButton=button
    menu:HookScript("OnShow",A.LayoutMenu)
    if menu:IsShown() then A.LayoutMenu() end
end

function A.Initialize()
    if InCombatLockdown() then return end
    RegisterCategory(); RegisterMenuButton()
    if A.menuButton and GameMenuFrame:IsShown() then A.LayoutMenu() end
end
local events=CreateFrame("Frame")
A.events=events
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",A.Initialize)
if IsLoggedIn and IsLoggedIn() then A.Initialize() end
