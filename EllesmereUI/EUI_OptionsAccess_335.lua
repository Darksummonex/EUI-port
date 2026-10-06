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

function A.Unlock()
    if InCombatLockdown() then
        if E.PrintError then E.PrintError("Cannot toggle Unlock Mode during combat.") end
        return false
    end
    if not E.ToggleUnlockMode then return false end
    if GameMenuFrame and GameMenuFrame:IsShown() then HideUIPanel(GameMenuFrame) end
    E:ToggleUnlockMode()
    return true
end

local function ButtonShown(button)
    local db=EllesmereUIDB
    if button==A.unlockButton then return db and db.hideUnlockMenuButton==false end
    return not (db and db.hideGameMenuButton)
end

local function IsOurs(frame) return frame and (frame==A.menuButton or frame==A.unlockButton) end

-- ElvUI, ACP and similar insert their entry right above Logout, so ours hang
-- off Macros instead; whatever followed Macros moves below our last entry.
-- Anchoring only to Macros or to each other keeps the chain acyclic.
function A.LayoutMenu()
    if InCombatLockdown() then return end
    local menu,anchor=GameMenuFrame,GameMenuButtonMacros or GameMenuButtonKeybindings
    if not menu or not anchor or not A.menuButton then return end
    local size=GameMenuButtonLogout or anchor
    local width,height=size:GetWidth(),size:GetHeight()
    local last,shown=anchor,0
    for _,button in ipairs({A.menuButton,A.unlockButton}) do
        button:SetWidth(width); button:SetHeight(height)
        if ButtonShown(button) then
            button:ClearAllPoints(); button:SetPoint("TOP",last,"BOTTOM",0,-1)
            button:Show(); last=button; shown=shown+1
        else
            button:Hide()
        end
    end
    for _,child in ipairs({menu:GetChildren()}) do
        if not IsOurs(child) and child.GetPoint then
            local point,relative,relPoint,x,y=child:GetPoint(1)
            relative=type(relative)=="string" and _G[relative] or relative
            if (relative==anchor or IsOurs(relative)) and relative~=last then
                child:ClearAllPoints(); child:SetPoint(point,last,relPoint,x or 0,y or 0)
            end
        end
    end
    local top,bottom=menu:GetTop(),nil
    for _,child in ipairs({menu:GetChildren()}) do
        if child.IsObjectType and child:IsObjectType("Button") and child:IsShown() then
            local edge=child:GetBottom()
            if edge then bottom=bottom and math.min(bottom,edge) or edge end
        end
    end
    if top and bottom then
        menu:SetHeight(math.max(menu:GetHeight(),top-bottom+16))
    elseif shown~=(A.menuHeightAdded or 0) then
        menu:SetHeight(menu:GetHeight()+(shown-(A.menuHeightAdded or 0))*(height+1))
        A.menuHeightAdded=shown
    end
end

local function RegisterMenuButton()
    local menu=GameMenuFrame
    if A.menuButton or not menu or not GameMenuButtonLogout then return end
    -- The original Core already supplies the pooled Retail menu entry.
    if type(menu.Layout)=="function" and menu.buttonPool or EllesmereUI_GameMenuButton then return end
    local button=CreateFrame("Button","EllesmereUI_GameMenuButton",menu,"GameMenuButtonTemplate")
    button:SetText("EllesmereUI"); button:SetScript("OnClick",A.Open)
    A.menuButton=button
    local unlock=CreateFrame("Button","EllesmereUI_UnlockMenuButton",menu,"GameMenuButtonTemplate")
    unlock:SetText("EUI Unlock Mode"); unlock:SetScript("OnClick",A.Unlock)
    A.unlockButton=unlock
    menu:HookScript("OnShow",A.LayoutMenu)
    if menu:IsShown() then A.LayoutMenu() end
end

function A.Initialize()
    -- Retail hides the Unlock entry until opted in; Wrath shows it by default.
    -- An explicit false keeps the General "EUI Buttons" dropdown in sync.
    if type(EllesmereUIDB)=="table" and EllesmereUIDB.hideUnlockMenuButton==nil then
        EllesmereUIDB.hideUnlockMenuButton=false
    end
    -- Wrath ignored hideGameMenuButton before core 0.40, so a saved true was
    -- never seen in game; clear it once instead of silently hiding the entry.
    if type(EllesmereUIDB)=="table" and not EllesmereUIDB.wrathGameMenuFlagsV1 then
        EllesmereUIDB.hideGameMenuButton=nil
        EllesmereUIDB.wrathGameMenuFlagsV1=true
    end
    if InCombatLockdown() then return end
    RegisterCategory(); RegisterMenuButton()
    if A.menuButton and GameMenuFrame:IsShown() then A.LayoutMenu() end
end
local events=CreateFrame("Frame")
A.events=events
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",A.Initialize)
if IsLoggedIn and IsLoggedIn() then A.Initialize() end
