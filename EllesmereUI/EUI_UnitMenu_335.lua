-- Unit right-click menus opened by addon frames run tainted on 3.3.5, so their
-- Set Focus / Clear Focus entries call the protected FocusUnit/ClearFocus and
-- trigger "blocked from an action only available to the Blizzard UI".
-- Out of combat a secure action button covers each entry, so the hardware click
-- focuses through the secure template. In combat secure buttons cannot be shown
-- or moved, so the entries are hidden instead. UnitPopup_HideButtons rewrites
-- every UnitPopupShown slot on each call, so this never leaks into Blizzard's menus.
-- The overlays are placed in UIParent coordinates, not anchored to the menu, so
-- DropDownList1 never becomes protected through them.
local E = EllesmereUI
if not E or not _G.EUI_WOW_335 or E.UnitMenuWithoutFocus then return end

local menus = {}
local actions = {
    SET_FOCUS = { type = "focus" },
    CLEAR_FOCUS = { type = "macro", macrotext = "/clearfocus" },
}
local overlays = {}

local function OwnMenu()
    local menu = UIDROPDOWNMENU_INIT_MENU
    if type(menu) == "string" then menu = _G[menu] end
    return menu and menus[menu] and menu
end

local function HideOverlays()
    for _, o in pairs(overlays) do o:Hide(); o:ClearAllPoints(); o.item = nil end
end

local function HideFocusButtons()
    if not InCombatLockdown() then return end
    local menu = OwnMenu()
    if not menu then return end
    local level = UIDROPDOWNMENU_MENU_LEVEL or 1
    local which = level == 1 and menu.which or UIDROPDOWNMENU_MENU_VALUE
    local list = UnitPopupMenus and which and UnitPopupMenus[which]
    local shown = UnitPopupShown and UnitPopupShown[level]
    if type(list) ~= "table" or type(shown) ~= "table" then return end
    for index, value in ipairs(list) do
        if actions[value] then shown[index] = 0 end
    end
end

local function Overlay(value)
    if overlays[value] then return overlays[value] end
    local o = CreateFrame("Button", "EUI335UnitMenu" .. value, UIParent, "SecureActionButtonTemplate")
    o:SetFrameStrata("TOOLTIP"); o:RegisterForClicks("AnyUp"); o:Hide()
    for key, v in pairs(actions[value]) do o:SetAttribute(key, v) end
    o:SetScript("OnEnter", function(self)
        if self.item then self.item:LockHighlight() end
        if UIDropDownMenu_StopCounting then UIDropDownMenu_StopCounting(DropDownList1) end
    end)
    o:SetScript("OnLeave", function(self)
        if self.item then self.item:UnlockHighlight() end
        if UIDropDownMenu_StartCounting then UIDropDownMenu_StartCounting(DropDownList1) end
    end)
    o:SetScript("PostClick", function() CloseDropDownMenus() end)
    overlays[value] = o
    return o
end

local function PlaceOverlays()
    if InCombatLockdown() then return end
    HideOverlays()
    local menu, list = OwnMenu(), _G.DropDownList1
    if not menu or not menu.unit or not list or not list:IsShown() then return end
    local scale = UIParent:GetEffectiveScale()
    for i = 1, list.numButtons or 0 do
        local item = _G["DropDownList1Button" .. i]
        if item and item:IsShown() and actions[item.value] then
            local left, bottom = item:GetLeft(), item:GetBottom()
            if left and bottom then
                local s = item:GetEffectiveScale() / scale
                local o = Overlay(item.value)
                o:SetAttribute("unit", menu.unit)
                o:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left * s, bottom * s)
                o:SetWidth(item:GetWidth() * s); o:SetHeight(item:GetHeight() * s)
                o.item = item; o:Show()
            end
        end
    end
end

function E.UnitMenuWithoutFocus(dropdown)
    if not dropdown then return end
    menus[dropdown] = true
    if E._unitMenuFocusHooked or type(UnitPopup_HideButtons) ~= "function" then return end
    E._unitMenuFocusHooked = true
    hooksecurefunc("UnitPopup_HideButtons", HideFocusButtons)
    if type(ToggleDropDownMenu) == "function" then hooksecurefunc("ToggleDropDownMenu", PlaceOverlays) end
    if DropDownList1 then
        DropDownList1:HookScript("OnHide", function() if not InCombatLockdown() then HideOverlays() end end)
    end
    -- Last moment secure frames may still change; a menu left open keeps clickable entries.
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
    watcher:SetScript("OnEvent", function()
        local open = false
        for _, o in pairs(overlays) do if o:IsShown() then open = true end end
        HideOverlays()
        if open then CloseDropDownMenus() end
    end)
end
