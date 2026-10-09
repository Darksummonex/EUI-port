-- Standalone Damage Meters: the few Core helpers the meter uses and a settings
-- window of its own. Stands in for the EllesmereUI core, options panel and Unlock
-- Mode, which the standalone build does not ship.
local ADDON = "EllesmereUIDamageMeters"
local E = {}
EllesmereUI = E
E._ModuleNS = {}
E.IS_STANDALONE = true

local MEDIA = "Interface\\AddOns\\EllesmereUIDamageMeters\\"
local FONT = MEDIA .. "media\\fonts\\Expressway.ttf"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local AR, AG, AB = 12/255, 210/255, 157/255
function E.GetAccentColor() return AR, AG, AB end

-- Fonts: Expressway plus everything registered with LibSharedMedia.
local function SharedMedia()
    local ok, lsm = pcall(LibStub, "LibSharedMedia-3.0", true)
    return ok and type(lsm) == "table" and lsm.Fetch and lsm or nil
end
do
    local lsm = SharedMedia()
    if lsm and lsm.Register then lsm:Register("font", "Expressway", FONT) end
end
function E.StandaloneFontPath(name)
    local lsm = SharedMedia()
    if name and name ~= "Expressway" and lsm then
        local ok, path = pcall(lsm.Fetch, lsm, "font", name, true)
        if ok and path then return path end
    end
    return FONT
end
function E.StandaloneFontChoices()
    local names, order = { Expressway = "Expressway" }, { "Expressway" }
    local lsm = SharedMedia()
    if lsm and lsm.List then
        for _, name in ipairs(lsm:List("font") or {}) do
            if not names[name] then names[name] = name; order[#order + 1] = name end
        end
    end
    return names, order
end
function E.GetFontPath()
    local ns = E._ModuleNS[ADDON]
    local profile = ns and ns.Profile and ns.Profile()
    return E.StandaloneFontPath(profile and profile.font)
end
function E.Print(msg) DEFAULT_CHAT_FRAME:AddMessage(tostring(msg)) end

-------------------------------------------------------------------------------
--  Addon lifecycle and settings (one profile per account, in the meter's own
--  SavedVariables)
-------------------------------------------------------------------------------
local function Merge(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dest[k]) ~= "table" then dest[k] = {} end
            Merge(dest[k], v)
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
end

local addons = {}
E.Lite = {}
function E.Lite.NewAddon(name)
    local addon = { name = name }
    addons[#addons + 1] = addon
    return addon
end
function E.Lite.NewDB(svName, defaults)
    local sv = _G[svName]
    if type(sv) ~= "table" then sv = {}; _G[svName] = sv end
    if type(sv.profile) ~= "table" then sv.profile = {} end
    local profileDefaults = defaults and defaults.profile or {}
    Merge(sv.profile, profileDefaults)
    local db = { sv = sv, profile = sv.profile }
    function db:ResetProfile()
        wipe(self.profile)
        Merge(self.profile, profileDefaults)
    end
    return db
end

local life = CreateFrame("Frame")
life:RegisterEvent("ADDON_LOADED")
life:RegisterEvent("PLAYER_LOGIN")
life:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" then
        if name ~= ADDON then return end
        self:UnregisterEvent("ADDON_LOADED")
        for _, addon in ipairs(addons) do if addon.OnInitialize then addon:OnInitialize() end end
        if not IsLoggedIn() then return end
    end
    self:UnregisterAllEvents()
    for _, addon in ipairs(addons) do if addon.OnEnable then addon:OnEnable() end end
end)

-------------------------------------------------------------------------------
--  Settings window
-------------------------------------------------------------------------------
local PAD, COLW, ROWH, CONTENTW = 16, 290, 44, 620
local module, current, win, content, popup
local showCallbacks, hideCallbacks, editBoxes = {}, {}, {}

local function Skin(frame, alpha)
    frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    frame:SetBackdropColor(.06, .06, .07, alpha or 1)
    frame:SetBackdropBorderColor(0, 0, 0, 1)
end

local function Text(parent, size, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, size or 12, "")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetTextColor(r or .9, g or .9, b or .9)
    return fs
end

local function Hover(frame, tooltip)
    frame:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(AR, AG, AB, 1)
        if tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0, 0, 0, 1)
        if tooltip then GameTooltip:Hide() end
    end)
end

local function Button(parent, width, height, label)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    Skin(b)
    b:SetBackdropColor(.12, .12, .14, 1)
    b.text = Text(b, 12)
    b.text:SetPoint("CENTER")
    b.text:SetText(label or "")
    Hover(b)
    return b
end

local function Swatch(parent, getValue, tooltip)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(20, 20)
    Skin(b)
    b.fill = b:CreateTexture(nil, "ARTWORK")
    b.fill:SetPoint("TOPLEFT", 2, -2)
    b.fill:SetPoint("BOTTOMRIGHT", -2, 2)
    b.fill:SetTexture(WHITE)
    function b:Update()
        local r, g, bl = getValue()
        self.fill:SetVertexColor(r or 1, g or 1, bl or 1)
    end
    b:Update()
    Hover(b, tooltip)
    return b
end

local function OpenColorPicker(getValue, setValue, hasAlpha, after)
    local r, g, b, a = getValue()
    a = a or 1
    local function Apply(previous)
        local nr, ng, nb, na
        if type(previous) == "table" then
            nr, ng, nb, na = previous.r, previous.g, previous.b, previous.a
        else
            nr, ng, nb = ColorPickerFrame:GetColorRGB()
            na = 1 - OpacitySliderFrame:GetValue()
        end
        setValue(nr, ng, nb, hasAlpha and na or nil)
        if after then after() end
    end
    ColorPickerFrame:Hide()
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = nil, nil, nil
    ColorPickerFrame.hasOpacity = hasAlpha and true or false
    ColorPickerFrame.opacity = 1 - a
    ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }
    ColorPickerFrame:SetColorRGB(r, g, b)
    ColorPickerFrame.func = function() Apply() end
    ColorPickerFrame.opacityFunc = function() Apply() end
    ColorPickerFrame.cancelFunc = Apply
    ColorPickerFrame:Show()
end

local function HidePopup() if popup then popup:Hide() end end

local function ShowList(owner, cfg, onPick)
    if not popup then
        popup = CreateFrame("Frame", nil, UIParent)
        Skin(popup)
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:EnableMouse(true)
        popup:EnableMouseWheel(true)
        popup.rows = {}
        popup.catcher = CreateFrame("Button", nil, UIParent)
        popup.catcher:SetAllPoints(UIParent)
        popup.catcher:SetFrameStrata("FULLSCREEN")
        popup.catcher:SetScript("OnClick", HidePopup)
        popup.catcher:Hide()
        for i = 1, 14 do
            local row = CreateFrame("Button", nil, popup)
            row:SetHeight(20)
            row:SetPoint("TOPLEFT", 1, -1 - (i - 1) * 20)
            row:SetPoint("TOPRIGHT", -1, -1 - (i - 1) * 20)
            row.hl = row:CreateTexture(nil, "BACKGROUND")
            row.hl:SetAllPoints()
            row.hl:SetTexture(1, 1, 1, .08)
            row.hl:Hide()
            row.text = Text(row, 12)
            row.text:SetPoint("LEFT", 8, 0)
            row:SetScript("OnEnter", function(self) self.hl:Show() end)
            row:SetScript("OnLeave", function(self) self.hl:Hide() end)
            row:SetScript("OnClick", function(self) local pick = popup.onPick; HidePopup(); pick(self.key) end)
            popup.rows[i] = row
        end
        function popup:Fill()
            local selected = self.cfg.getValue()
            for i, row in ipairs(self.rows) do
                local key = self.order[i + self.offset]
                if key ~= nil and i <= self.visible then
                    row.key = key
                    row.text:SetFont(self.cfg.previewFont and self.cfg.previewFont(key) or FONT, 12, "")
                    row.text:SetText(self.cfg.values[key] or tostring(key))
                    if key == selected then row.text:SetTextColor(AR, AG, AB) else row.text:SetTextColor(.9, .9, .9) end
                    row:Show()
                else
                    row:Hide()
                end
            end
        end
        popup:SetScript("OnMouseWheel", function(self, delta)
            self.offset = math.max(0, math.min(self.offset - delta, #self.order - self.visible))
            self:Fill()
        end)
        popup:SetScript("OnHide", function(self) self.catcher:Hide() end)
    end
    popup.cfg, popup.onPick, popup.offset = cfg, onPick, 0
    popup.order = cfg.order or {}
    popup.visible = math.min(#popup.order, #popup.rows)
    popup:ClearAllPoints()
    popup:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
    popup:SetSize(owner:GetWidth(), popup.visible * 20 + 2)
    popup:Fill()
    popup.catcher:Show()
    popup:Show()
end

local function FormatNumber(value, step)
    if step and step < 1 then
        return (string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", ""))
    end
    return tostring(math.floor(value + .5))
end

local function EditBox(parent, width)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetSize(width, 20)
    Skin(box)
    box:SetFont(FONT, 12, "")
    box:SetTextInsets(5, 5, 0, 0)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBoxes[#editBoxes + 1] = box
    return box
end

local function Cell(row, cfg, x)
    if not cfg then return end
    local kind = cfg.type
    local cell = CreateFrame("Frame", nil, row)
    cell:SetSize(COLW, ROWH)
    cell:SetPoint("TOPLEFT", x, 0)
    cell.cfg = cfg
    row.cells[#row.cells + 1] = cell

    if kind == "label" then
        local fs = Text(cell, 11, .6, .6, .6)
        fs:SetPoint("TOPLEFT", 0, -6)
        fs:SetWidth(COLW)
        fs:SetJustifyH("LEFT")
        fs:SetText(cfg.text or "")
        return cell
    end

    local label = Text(cell, 12)
    label:SetJustifyH("LEFT")
    label:SetText(cfg.text or "")
    cell.label = label

    if kind == "toggle" then
        local box = CreateFrame("Button", nil, cell)
        box:SetSize(18, 18)
        box:SetPoint("LEFT", 0, 0)
        Skin(box)
        box.mark = box:CreateTexture(nil, "ARTWORK")
        box.mark:SetPoint("TOPLEFT", 3, -3)
        box.mark:SetPoint("BOTTOMRIGHT", -3, 3)
        box.mark:SetTexture(WHITE)
        box.mark:SetVertexColor(AR, AG, AB)
        local function Update() if cfg.getValue() then box.mark:Show() else box.mark:Hide() end end
        box:SetScript("OnClick", function() cfg.setValue(not cfg.getValue()); Update() end)
        Hover(box, cfg.tooltip)
        Update()
        label:SetPoint("LEFT", box, "RIGHT", 8, 0)
        label:SetWidth(COLW - 30)
        cell.toggle = box
    elseif kind == "slider" then
        label:SetPoint("TOPLEFT", 0, -4)
        local slider = CreateFrame("Slider", nil, cell)
        slider:SetOrientation("HORIZONTAL")
        slider:SetSize(COLW - 70, 10)
        slider:SetPoint("TOPLEFT", 0, -26)
        Skin(slider)
        slider:SetBackdropColor(.15, .15, .17, 1)
        slider:EnableMouse(true)
        slider:SetThumbTexture(WHITE)
        local thumb = slider:GetThumbTexture()
        thumb:SetSize(8, 14)
        thumb:SetVertexColor(AR, AG, AB)
        local min, max, step = cfg.min or 0, cfg.max or 1, cfg.step or 1
        slider:SetMinMaxValues(min, max)
        slider:SetValueStep(step)
        local box = EditBox(cell, 54)
        box:SetPoint("LEFT", slider, "RIGHT", 10, 0)
        box:SetJustifyH("CENTER")
        local value = tonumber(cfg.getValue()) or min
        local quiet = true
        slider:SetValue(math.max(min, math.min(max, value)))
        box:SetText(FormatNumber(value, step))
        quiet = false
        slider:SetScript("OnValueChanged", function(self, v)
            if quiet then return end
            v = min + math.floor((v - min) / step + .5) * step
            v = tonumber(string.format("%.4f", math.max(min, math.min(max, v))))
            box:SetText(FormatNumber(v, step))
            if v ~= cfg.getValue() then cfg.setValue(v) end
        end)
        box:SetScript("OnEnterPressed", function(self)
            local v = tonumber(self:GetText())
            if v then slider:SetValue(math.max(min, math.min(max, v))) end
            self:SetText(FormatNumber(tonumber(cfg.getValue()) or min, step))
            self:ClearFocus()
        end)
        cell.slider, cell.box = slider, box
    elseif kind == "dropdown" then
        label:SetPoint("TOPLEFT", 0, -4)
        local button = Button(cell, COLW - 20, 22, "")
        button:SetPoint("TOPLEFT", 0, -20)
        button.text:ClearAllPoints()
        button.text:SetPoint("LEFT", 8, 0)
        button.text:SetPoint("RIGHT", -22, 0)
        button.text:SetJustifyH("LEFT")
        local arrow = Text(button, 12, .6, .6, .6)
        arrow:SetPoint("RIGHT", -8, 0)
        arrow:SetText("v")
        local function Update()
            local v = cfg.getValue()
            if cfg.previewFont then button.text:SetFont(cfg.previewFont(v), 12, "") end
            button.text:SetText(cfg.values and cfg.values[v] or tostring(v or ""))
        end
        button:SetScript("OnClick", function(self)
            if popup and popup:IsShown() and popup.cfg == cfg then HidePopup(); return end
            ShowList(self, cfg, function(key) cfg.setValue(key); Update() end)
        end)
        Update()
        cell.dropdown = button
    elseif kind == "input" then
        label:SetPoint("TOPLEFT", 0, -4)
        local box = EditBox(cell, COLW - 20)
        box:SetPoint("TOPLEFT", 0, -20)
        box:SetText(tostring(cfg.getValue() or ""))
        local function Commit(self)
            local v = self:GetText()
            if v ~= tostring(cfg.getValue() or "") then cfg.setValue(v) end
            self:SetText(tostring(cfg.getValue() or ""))
        end
        box:SetScript("OnEnterPressed", function(self) Commit(self); self:ClearFocus() end)
        box:SetScript("OnEditFocusLost", Commit)
        cell.box = box
    elseif kind == "colorpicker" then
        local swatch
        swatch = Swatch(cell, cfg.getValue, cfg.tooltip)
        swatch:SetPoint("LEFT", 0, 0)
        swatch:SetScript("OnClick", function()
            OpenColorPicker(cfg.getValue, cfg.setValue, cfg.hasAlpha, function() swatch:Update() end)
        end)
        label:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
        label:SetWidth(COLW - 30)
        cell.swatches = { swatch }
    elseif kind == "multiSwatch" then
        cell.swatches = {}
        local last
        for i, entry in ipairs(cfg.swatches or {}) do
            local swatch = Swatch(cell, entry.getValue, entry.tooltip)
            if last then swatch:SetPoint("LEFT", last, "RIGHT", 6, 0) else swatch:SetPoint("LEFT", 0, 0) end
            swatch:SetAlpha(entry.refreshAlpha and entry.refreshAlpha() or 1)
            swatch._eabOrigClick = function()
                OpenColorPicker(entry.getValue, entry.setValue, entry.hasAlpha, function() swatch:Update() end)
            end
            swatch:SetScript("OnClick", function(self)
                if entry.onClick then entry.onClick(self) else self._eabOrigClick(self) end
            end)
            cell.swatches[i] = swatch
            last = swatch
        end
        if last then label:SetPoint("LEFT", last, "RIGHT", 8, 0) else label:SetPoint("LEFT", 0, 0) end
    else
        label:SetPoint("TOPLEFT", 0, -4)
    end
    return cell
end

local W = {}
E.Widgets = W
function W:SectionHeader(parent, text, y)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(CONTENTW - 2 * PAD, 30)
    f:SetPoint("TOPLEFT", PAD, y)
    local fs = Text(f, 13, AR, AG, AB)
    fs:SetPoint("BOTTOMLEFT", 0, 7)
    fs:SetText(text)
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetTexture(1, 1, 1, .12)
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    f.text = fs
    return f, 36
end
function W:DualRow(parent, y, a, b)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(CONTENTW, ROWH)
    f:SetPoint("TOPLEFT", 0, y)
    f.cells = {}
    Cell(f, a, PAD)
    Cell(f, b, PAD + COLW + 14)
    return f, ROWH + 4
end
function W:WideButton(parent, text, y, fn)
    if text == "Unlock Mode" then return nil, 0 end
    local b = Button(parent, 260, 24, text)
    b:SetPoint("TOPLEFT", PAD, y - 4)
    b:SetScript("OnClick", function() fn() end)
    return b, 32
end

local function Build()
    if not win or not module then return end
    HidePopup()
    for _, box in ipairs(editBoxes) do box:ClearFocus() end
    wipe(editBoxes)
    local scroll = win.scroll
    local offset = scroll:GetVerticalScroll() or 0
    if content then content:Hide() end
    content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(CONTENTW)
    content:SetHeight(10)
    scroll:SetScrollChild(content)
    local height = module.buildPage(current, content, -8) or 0
    content:SetHeight(height + 16)
    scroll:UpdateScrollChildRect()
    scroll:SetVerticalScroll(math.min(offset, scroll:GetVerticalScrollRange() or 0))
    for _, tab in ipairs(win.tabs) do
        local active = tab.page == current
        tab.text:SetTextColor(active and AR or .7, active and AG or .7, active and AB or .7)
        if active then tab.underline:Show() else tab.underline:Hide() end
    end
    win.content = content
end

local pendingBuild
local deferFrame = CreateFrame("Frame")
deferFrame:Hide()
deferFrame:SetScript("OnUpdate", function(self)
    if ColorPickerFrame and ColorPickerFrame:IsShown() then return end
    self:Hide()
    if pendingBuild and win and win:IsShown() then pendingBuild = nil; Build() end
end)

local function CreateWindow()
    win = CreateFrame("Frame", "EllesmereUIDMStandaloneSettings", UIParent)
    win:SetSize(CONTENTW + 40, 600)
    win:SetPoint("CENTER")
    Skin(win, .97)
    win:SetFrameStrata("HIGH")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:SetMovable(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    tinsert(UISpecialFrames, win:GetName())

    local title = Text(win, 15)
    title:SetPoint("TOPLEFT", PAD, -12)
    title:SetText("|cff0cd29fEllesmereUI|r " .. (module.title or "Damage Meters"))
    local close = Button(win, 22, 22, "x")
    close:SetPoint("TOPRIGHT", -8, -8)
    close:SetScript("OnClick", function() win:Hide() end)
    win.close = close

    win.tabs = {}
    for i, page in ipairs(module.pages) do
        local tab = CreateFrame("Button", nil, win)
        tab:SetSize(120, 24)
        tab:SetPoint("TOPLEFT", PAD + (i - 1) * 124, -38)
        tab.page = page
        tab.text = Text(tab, 13)
        tab.text:SetPoint("CENTER")
        tab.text:SetText(page)
        tab.underline = tab:CreateTexture(nil, "ARTWORK")
        tab.underline:SetTexture(WHITE)
        tab.underline:SetVertexColor(AR, AG, AB)
        tab.underline:SetHeight(2)
        tab.underline:SetPoint("BOTTOMLEFT")
        tab.underline:SetPoint("BOTTOMRIGHT")
        tab:SetScript("OnClick", function(self) E:SelectPage(self.page) end)
        win.tabs[i] = tab
    end

    local scroll = CreateFrame("ScrollFrame", "EllesmereUIDMStandaloneScroll", win, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -70)
    scroll:SetPoint("BOTTOMRIGHT", -30, 44)
    win.scroll = scroll

    local reset = Button(win, 160, 24, "Reset to Defaults")
    reset:SetPoint("BOTTOMLEFT", PAD, 12)
    reset:SetScript("OnClick", function(self)
        if not self.armed then
            self.armed = true
            self.text:SetText("Click to Confirm")
            return
        end
        self.armed = nil
        self.text:SetText("Reset to Defaults")
        if module.onReset then module.onReset() end
    end)
    reset:HookScript("OnLeave", function(self)
        self.armed = nil
        self.text:SetText("Reset to Defaults")
    end)
    win.reset = reset
    local hint = Text(win, 11, .5, .5, .5)
    hint:SetPoint("BOTTOMRIGHT", -PAD, 18)
    hint:SetText("/edm  -  /edm toggle")

    win:SetScript("OnShow", function()
        for _, fn in ipairs(showCallbacks) do fn() end
    end)
    win:SetScript("OnHide", function()
        HidePopup()
        for _, box in ipairs(editBoxes) do box:ClearFocus() end
        if module.onModuleLeave then module.onModuleLeave() end
        for _, fn in ipairs(hideCallbacks) do fn() end
    end)
    win:Hide()
end

function E:RegisterModule(key, cfg) if key == ADDON then module = cfg end end
function E:RegisterOnShow(fn) showCallbacks[#showCallbacks + 1] = fn end
function E:RegisterOnHide(fn) hideCallbacks[#hideCallbacks + 1] = fn end
function E.EnsureOptionsLoaded() return true end
function E:InvalidatePageCache() end
function E:GetActiveModule() return win and win:IsShown() and ADDON or nil end
function E:Hide() if win then win:Hide() end end
function E:ShowModule()
    if not module then return end
    if not win then CreateWindow() end
    current = current or module.pages[1]
    win:Show()
    Build()
end
function E:SelectPage(page)
    current = page
    if win and win:IsShown() then Build() end
end
function E:RefreshPage()
    pendingBuild = true
    deferFrame:Show()
end
E._StandaloneSettings = function() return win end
