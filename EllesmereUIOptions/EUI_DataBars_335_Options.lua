-------------------------------------------------------------------------------
--  EUI_DataBars_335_Options.lua
--  The "DataBars" options page for the Wrath multi-bar engine (port of Retail
--  EllesmereUIDataBars_Options.lua, kept as an unloaded reference).
--
--  Layout (body only; the Retail content header is folded into the page):
--    * DATABARS: bar selector, rename, new bar from template, delete, Unlock
--      Mode. Then a click-to-scroll preview of the selected bar and the
--      Auto Sized / Even Split toggle.
--    * BAR SETTINGS (topped by the Visibility row the Unlock Mode "Element
--      Options" link highlights), BLOCKS (add a block), then one section per
--      block in bar order. Zero bars renders a create-only state instead.
--
--  Everything talks to the runtime through the ns.* API of EUI_DataBars_335.lua.
-------------------------------------------------------------------------------
local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E = EllesmereUI
local ns = E and E._ModuleNS and E._ModuleNS.EllesmereUIDataBars
if not ns or not ns.IsWrath then return end

local ADDON, PAGE = "EllesmereUIDataBars", "DataBars"
local format, upper, floor, max, abs = string.format, string.upper, math.floor, math.max, math.abs

local init = CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    if not E.RegisterModule then return end

    ---------------------------------------------------------------------------
    --  Module state (survives page rebuilds; closures re-target each build)
    ---------------------------------------------------------------------------
    local O = { template = "bottom", blockType = "clock" }
    local OPT_FONT = E.EXPRESSWAY or "Fonts\\FRIZQT__.TTF"
    local function noop() end
    local function L(s) if E.L then return E.L(s) end; return s end
    local function BLANK() return { type = "label", text = "" } end

    local TYPE_LABEL = {}
    for _, t in ipairs(ns.BLOCK_TYPES) do TYPE_LABEL[t.key] = t.label end
    local TYPE_ORDER = {}
    for _, t in ipairs(ns.BLOCK_TYPES) do TYPE_ORDER[#TYPE_ORDER + 1] = t.key end

    -- Typical content extents (real-bar px) for blocks without a live measurement.
    local EST_LEN = {
        clock = 150, fps = 70, ms = 70, gold = 150, xprep = 140, spec = 130,
        profession = 120, travel = 40, micromenu = 300, currency = 90, spacer = 40,
        durability = 70, combat = 105, profession2 = 120, location = 140, coords = 70,
        ilvl = 70, bags = 50, audio = 110, ldb = 90,
    }

    local TEMPLATE_LABELS = {
        empty = "Start Empty", bottom = "Top/Bottom Info Bar",
        minimapc = "Minimap Companion", microstrip = "Micro Menu Strip",
    }
    local TEMPLATE_ORDER = {}
    for _, k in ipairs({ "empty", "bottom", "minimapc", "microstrip" }) do
        if ns.TEMPLATES and ns.TEMPLATES[k] then TEMPLATE_ORDER[#TEMPLATE_ORDER + 1] = k end
    end

    local STRATA_LABELS = E.FRAME_STRATA_LABELS or { BACKGROUND = "Background", LOW = "Low", MEDIUM = "Medium", HIGH = "High", DIALOG = "Dialog" }
    local STRATA_ORDER = E.FRAME_STRATA_ORDER_BASE or { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG" }

    ---------------------------------------------------------------------------
    --  Profile helpers
    ---------------------------------------------------------------------------
    local function Profile() return ns.GetProfile() end

    -- Selected bar, validated (falls back to the first bar).
    local function SelectedBar()
        local p = Profile()
        if not p then return nil end
        local bars = p.bars
        if not bars or #bars == 0 then ns.selectedBarId = nil; return nil end
        local cfg = p.selectedBarId and ns.GetBar(p.selectedBarId)
        if not cfg then cfg = bars[1]; p.selectedBarId = cfg.id end
        ns.selectedBarId = cfg.id
        return cfg
    end
    local function SelectBar(id)
        local p = Profile()
        if p then p.selectedBarId = id end
        ns.selectedBarId = id
    end

    local function ResolvedBarLength(cfg)
        if cfg.lengthMode == "full" then
            if cfg.orientation == "V" then return UIParent:GetHeight() end
            return UIParent:GetWidth()
        end
        return cfg.length or 400
    end

    local function HardRefresh()
        if E.InvalidatePageCache then E:InvalidatePageCache() end
        if E.RefreshPage then E:RefreshPage(true) end
    end
    local function SoftRefresh() if E.RefreshPage then E:RefreshPage() end end

    -- Structural CRUD returns nil in combat; say so instead of silently ignoring the click.
    local function CombatBlocked()
        if not InCombatLockdown() then return false end
        local msg = L("DataBars cannot be restructured in combat.")
        if E.Print then E.Print(msg) elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(msg) end
        return true
    end
    local function Restructure(fn)
        if CombatBlocked() then return end
        fn()
        HardRefresh()
    end

    local function RefreshPreviewTheme()
        local host = O.previewHost
        local cfg = SelectedBar()
        if host and host:IsShown() and cfg then ns.MakePreviewBackdrop(host, cfg.theme, not cfg.hideBorder) end
    end
    local function RelayoutPreview() if O.previewRelayout then O.previewRelayout() end end

    local function ClassRGB()
        local _, classFile = UnitClass("player")
        local cc = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
        if cc then return cc.r, cc.g, cc.b end
        return 1, 1, 1
    end
    local function IconDefault(bType)
        if ns.BlockIconDefault then return ns.BlockIconDefault(bType) end
        return 1, 1, 1
    end
    local function TextDynamic(bType)
        if ns.BlockTextDynamic then return ns.BlockTextDynamic(bType) end
        return 1, 1, 1
    end
    local function CVarOn(name)
        local ok, v = pcall(GetCVar, name)
        return ok and v == "1"
    end

    ---------------------------------------------------------------------------
    --  Row helpers (B = per-build context: W, parent, y, live, sections)
    ---------------------------------------------------------------------------
    local function Row(B, a, b)
        local row, h = B.W:DualRow(B.parent, B.y, a, b or BLANK())
        B.y = B.y - h
        return row
    end
    local function Section(B, text)
        local sec, h = B.W:SectionHeader(B.parent, text, B.y)
        B.y = B.y - h
        return sec
    end
    local function Cog(B, rgn, opts)
        if B.live and rgn and E.BuildInlineCog then return E.BuildInlineCog(rgn, opts) end
    end

    -- Inline color swatch left of a half-row's control (house pattern: greyed and
    -- click-blocked while disabledFn() is true).
    local function InlineSwatch(B, row, rgn, get, set, hasAlpha, disabledFn, disabledTip)
        if not (B.live and row and rgn and E.BuildColorSwatch) then return end
        local sw, update = E.BuildColorSwatch(rgn, row:GetFrameLevel() + 3, get, set, hasAlpha, 20)
        local anchor = rgn._lastInline or rgn._control
        sw:ClearAllPoints()
        if anchor then sw:SetPoint("RIGHT", anchor, "LEFT", -8, 0) else sw:SetPoint("RIGHT", rgn, "RIGHT", -20, 0) end
        rgn._lastInline = sw
        local blk
        if disabledFn then
            blk = CreateFrame("Frame", nil, sw)
            blk:SetAllPoints(sw)
            blk:SetFrameLevel(sw:GetFrameLevel() + 10)
            blk:EnableMouse(true)
            blk:SetScript("OnEnter", function()
                if E.ShowWidgetTooltip then
                    E.ShowWidgetTooltip(sw, E.DisabledTooltip and E.DisabledTooltip(disabledTip) or disabledTip)
                end
            end)
            blk:SetScript("OnLeave", function() if E.HideWidgetTooltip then E.HideWidgetTooltip() end end)
        end
        local function State()
            if update then update() end
            if blk then
                if disabledFn() then sw:SetAlpha(0.3); blk:Show() else sw:SetAlpha(1); blk:Hide() end
            end
        end
        State()
        if E.RegisterWidgetRefresh then E.RegisterWidgetRefresh(State) end
        return sw
    end

    -- Checklist dropdown swapped into a placeholder dropdown slot (Retail idiom).
    local function Checklist(label, tip, items, get, set)
        return { type = "dropdown", text = label, tooltip = tip,
            values = { __placeholder = "..." }, order = { "__placeholder" },
            getValue = function() return "__placeholder" end, setValue = noop,
            _inline = function(_, _, rgn)
                if not E.BuildVisOptsCBDropdown then return end
                if rgn._control then rgn._control:Hide() end
                local dd, refresh = E.BuildVisOptsCBDropdown(rgn, 210, rgn:GetFrameLevel() + 2, items, get, set)
                dd:ClearAllPoints()
                dd:SetPoint("RIGHT", rgn, "RIGHT", -20, 0)
                rgn._control = dd
                rgn._lastInline = nil
                if refresh and E.RegisterWidgetRefresh then E.RegisterWidgetRefresh(refresh) end
            end }
    end

    -- c = per-block context: b, s, cfg, barId, Apply, vertical
    local function MkToggle(c, label, key, tip)
        return { type = "toggle", text = label, tooltip = tip,
            getValue = function() return c.s[key] == true end,
            setValue = function(v) c.s[key] = v and true or false; c.Apply() end }
    end
    -- Default-ON setting: nil reads as true.
    local function MkToggleOn(c, label, key, tip)
        return { type = "toggle", text = label, tooltip = tip,
            getValue = function() return c.s[key] ~= false end,
            setValue = function(v) c.s[key] = v and true or false; c.Apply() end }
    end
    local function AlignValues(vertical)
        if vertical then return { LEFT = "Top", CENTER = "Center", RIGHT = "Bottom" } end
        return { LEFT = "Left", CENTER = "Center", RIGHT = "Right" }
    end

    ---------------------------------------------------------------------------
    --  Block color rows
    ---------------------------------------------------------------------------
    local DYNAMIC_TEXT = { durability = "Dynamic", location = "Reactive", coords = "Reactive", ilvl = "Band" }

    -- Text Color: Custom / Class / Accent (+ Coin Colored on gold, + the
    -- state-driven swatch on durability, location, coordinates and item level).
    local function TextColorCfg(c)
        local b = c.b
        local function Recolor(page) ns.ReflowBlocks(c.barId); if page then SoftRefresh() end end
        local function Clear() b.useClassColor, b.useAccentColor, b.useDynamicColor, b.useCoinColor = nil, nil, nil, nil end
        local function CustomOn() return not (b.useClassColor or b.useAccentColor or b.useDynamicColor or b.useCoinColor) end
        local sw = {
            { tooltip = "Custom Color", hasAlpha = false,
              getValue = function()
                  local col = b.color
                  if col then return col.r or 1, col.g or 1, col.b or 1 end
                  return 1, 1, 1
              end,
              setValue = function(r, g, bl) b.color = { r = r, g = g, b = bl }; Recolor() end,
              onClick = function(btn)
                  if not CustomOn() then Clear(); Recolor(true); return end
                  if btn._eabOrigClick then btn._eabOrigClick(btn) end
              end,
              refreshAlpha = function() return CustomOn() and 1 or 0.3 end },
            { tooltip = "Class Colored", hasAlpha = false, getValue = ClassRGB, setValue = noop,
              onClick = function() Clear(); b.useClassColor = true; Recolor(true) end,
              refreshAlpha = function() return b.useClassColor and 1 or 0.3 end },
            { tooltip = "Accent Color", hasAlpha = false, getValue = function() return ns.GetAccent() end, setValue = noop,
              onClick = function() Clear(); b.useAccentColor = true; Recolor(true) end,
              refreshAlpha = function() return b.useAccentColor and 1 or 0.3 end },
        }
        if b.type == "gold" then
            sw[4] = { tooltip = "Coin Colored", hasAlpha = false,
                getValue = function() return 0.886, 0.675, 0.478 end, setValue = noop,
                onClick = function() Clear(); b.useCoinColor = true; Recolor(true) end,
                refreshAlpha = function() return b.useCoinColor and 1 or 0.3 end }
        elseif DYNAMIC_TEXT[b.type] then
            sw[4] = { tooltip = DYNAMIC_TEXT[b.type], hasAlpha = false,
                getValue = function() return TextDynamic(b.type) end, setValue = noop,
                onClick = function() Clear(); b.useDynamicColor = true; Recolor(true) end,
                refreshAlpha = function() return b.useDynamicColor and 1 or 0.3 end }
        end
        return { type = "multiSwatch", text = "Text Color", swatches = sw }
    end

    local ICON_COLOR_BLOCKS = {
        durability = true, gold = true, travel = true, spec = true, profession = true, profession2 = true,
        currency = true, audio = true, location = true, coords = true, ilvl = true, bags = true, ldb = true,
    }

    -- Icon Color: Custom / Class / Accent / Default. Nothing stored = the themed default.
    local function IconColorCfg(c)
        local b = c.b
        local function Recolor(page) ns.ReflowBlocks(c.barId); if page then SoftRefresh() end end
        local function FlagsOff() return not b.useIconClassColor and not b.useIconAccentColor and not b.useIconDefaultColor end
        local function Clear() b.useIconClassColor, b.useIconAccentColor, b.useIconDefaultColor = nil, nil, nil end
        local sw = {
            { tooltip = "Custom Color", hasAlpha = false,
              getValue = function()
                  local col = b.iconColor
                  if col then return col.r or 1, col.g or 1, col.b or 1 end
                  return IconDefault(b.type)
              end,
              setValue = function(r, g, bl) b.iconColor = { r = r, g = g, b = bl }; Recolor() end,
              onClick = function(btn)
                  -- First click selects Custom (seeded from the default); the picker opens on the second.
                  if not FlagsOff() or b.iconColor == nil then
                      Clear()
                      if b.iconColor == nil then
                          local r, g, bl = IconDefault(b.type)
                          b.iconColor = { r = r, g = g, b = bl }
                      end
                      Recolor(true)
                      return
                  end
                  if btn._eabOrigClick then btn._eabOrigClick(btn) end
              end,
              refreshAlpha = function() return (FlagsOff() and b.iconColor ~= nil) and 1 or 0.3 end },
            { tooltip = "Class Colored", hasAlpha = false, getValue = ClassRGB, setValue = noop,
              onClick = function() Clear(); b.useIconClassColor = true; Recolor(true) end,
              refreshAlpha = function() return b.useIconClassColor and 1 or 0.3 end },
            { tooltip = "Accent Color", hasAlpha = false, getValue = function() return ns.GetAccent() end, setValue = noop,
              onClick = function() Clear(); b.useIconAccentColor = true; Recolor(true) end,
              refreshAlpha = function() return b.useIconAccentColor and 1 or 0.3 end },
            { tooltip = b.type == "durability" and "Dynamic" or "Default", hasAlpha = false,
              getValue = function() return IconDefault(b.type) end, setValue = noop,
              onClick = function() Clear(); b.useIconDefaultColor = true; Recolor(true) end,
              refreshAlpha = function()
                  return (b.useIconDefaultColor or (FlagsOff() and b.iconColor == nil)) and 1 or 0.3
              end },
        }
        if b.type == "spec" then
            -- Spec defaults to class color: no Default swatch, Class reads as selected when nothing is stored.
            sw[4] = nil
            sw[2].refreshAlpha = function()
                if b.useIconClassColor or b.useIconDefaultColor then return 1 end
                return (FlagsOff() and b.iconColor == nil) and 1 or 0.3
            end
        elseif b.type == "profession" or b.type == "profession2" then
            -- Professions default to accent (matches the skill-bar fill).
            sw[4] = nil
            sw[3].refreshAlpha = function()
                if b.useIconAccentColor then return 1 end
                return (FlagsOff() and b.iconColor == nil) and 1 or 0.3
            end
        end
        return { type = "multiSwatch", text = "Icon Color", swatches = sw }
    end

    -- The setting riding the Icon Color row's right slot.
    local ICON_RIGHT = {
        audio = function(c) return MkToggleOn(c, "Show Icon", "showIcon", "Shows the audio icon next to the volume bar.") end,
        profession = function(c) return MkToggleOn(c, "Show Icon", "showIcon", "Shows the profession icons next to the text.") end,
        profession2 = function(c) return MkToggleOn(c, "Show Icon", "showIcon", "Shows the profession icons next to the text.") end,
        spec = function(c) return MkToggleOn(c, "Show Icon", "showIcon", "Shows the spec icon next to the text.") end,
        location = function(c) return MkToggleOn(c, "Show Icon", "showIcon", "Shows the map pin next to the zone name.") end,
        coords = function(c) return MkToggleOn(c, "Show Icon", "showIcon", "Shows the marker icon next to the coordinates.") end,
        bags = function(c) return MkToggleOn(c, "Show Icon", "showIcon", "Shows the bag icon next to the slot count.") end,
        durability = function(c) return MkToggle(c, "Show Icon", "showIcon", "Shows the icon next to the durability readout.") end,
        gold = function(c) return MkToggle(c, "Show Silver and Copper", "showSmall", "Shows silver and copper, not just gold.") end,
        ilvl = function(c)
            local s = c.s
            return { type = "dropdown", text = "Prefix",
                tooltip = "What sits in front of the number. Icon shows the character icon; the color swatches on the left tint it.",
                values = { none = "None", short = "ILVL", long = "Item Level", icon = "Icon" },
                order = { "none", "short", "long", "icon" },
                getValue = function() return s.prefix or "short" end,
                setValue = function(v) s.prefix = v; c.Apply() end }
        end,
    }

    -- Latency icon color: Custom / Class / Accent inline on the Show Icon toggle,
    -- on the shared per-block icon keys (nothing stored = Custom white).
    local function MsIconSwatches(c)
        local b, s = c.b, c.s
        return function(B, row, rgn)
            if not E.BuildColorSwatch then return end
            local function IconOn() return s.showIcon == true end
            local function FlagsOff() return not b.useIconClassColor and not b.useIconAccentColor and not b.useIconDefaultColor end
            local function Clear() b.useIconClassColor, b.useIconAccentColor, b.useIconDefaultColor = nil, nil, nil end
            local function Recolor() ns.ReflowBlocks(c.barId); SoftRefresh() end
            local specs = {
                { tip = "Accent Color", get = function() return ns.GetAccent() end,
                  click = function() Clear(); b.useIconAccentColor = true; Recolor() end,
                  on = function() return b.useIconAccentColor == true end },
                { tip = "Class Colored", get = ClassRGB,
                  click = function() Clear(); b.useIconClassColor = true; Recolor() end,
                  on = function() return b.useIconClassColor == true end },
                { tip = "Custom Color",
                  get = function()
                      local col = b.iconColor
                      if col then return col.r or 1, col.g or 1, col.b or 1 end
                      return 1, 1, 1
                  end,
                  set = function(r, g, bl) b.iconColor = { r = r, g = g, b = bl }; ns.ReflowBlocks(c.barId) end,
                  click = function(btn)
                      if not FlagsOff() then Clear(); Recolor(); return end
                      if btn._eabOrigClick then btn._eabOrigClick(btn) end
                  end,
                  on = FlagsOff },
            }
            local anchor = rgn._control
            for i = 1, #specs do
                local sp = specs[i]
                local sw, update = E.BuildColorSwatch(rgn, row:GetFrameLevel() + 3,
                    function() local r, g, bl = sp.get(); return r, g, bl, 1 end, sp.set or noop, false, 20)
                sw._eabOrigClick = sw:GetScript("OnClick")
                sw:SetScript("OnClick", function(btn) sp.click(btn) end)
                sw:HookScript("OnEnter", function() if E.ShowWidgetTooltip then E.ShowWidgetTooltip(sw, sp.tip) end end)
                sw:HookScript("OnLeave", function() if E.HideWidgetTooltip then E.HideWidgetTooltip() end end)
                sw:ClearAllPoints()
                sw:SetPoint("RIGHT", anchor or rgn, anchor and "LEFT" or "RIGHT", anchor and -8 or -20, 0)
                anchor = sw
                local blk = CreateFrame("Frame", nil, sw)
                blk:SetAllPoints(sw)
                blk:SetFrameLevel(sw:GetFrameLevel() + 10)
                blk:EnableMouse(true)
                blk:SetScript("OnEnter", function()
                    if E.ShowWidgetTooltip then
                        E.ShowWidgetTooltip(sw, E.DisabledTooltip and E.DisabledTooltip("Show Icon") or "Show Icon")
                    end
                end)
                blk:SetScript("OnLeave", function() if E.HideWidgetTooltip then E.HideWidgetTooltip() end end)
                local function State()
                    if update then update() end
                    if not IconOn() then sw:SetAlpha(0.3); blk:Show()
                    else sw:SetAlpha(sp.on() and 1 or 0.3); blk:Hide() end
                end
                State()
                if E.RegisterWidgetRefresh then E.RegisterWidgetRefresh(State) end
            end
            rgn._lastInline = anchor
        end
    end

    ---------------------------------------------------------------------------
    --  Per-type rows (Retail keys; Wrath-only omissions noted in the report)
    ---------------------------------------------------------------------------
    local GOLD_TIP_ELEMENTS = {
        { key = "tipSession", label = "Session" },
        { key = "tipCharacters", label = "Characters" },
    }
    local MM_ELEMENTS = {
        { key = "menu", label = "Menu" },
        { key = "guild", label = "Guild" },
        { key = "social", label = "Social" },
        { key = "char", label = "Character" },
        { key = "spell", label = "Spellbook" },
        { key = "talent", label = "Talents" },
        { key = "ach", label = "Achievements" },
        { key = "quest", label = "Quests" },
        { key = "lfg", label = "Dungeon Finder" },
        { key = "pvp", label = "PvP" },
        { key = "help", label = "Help" },
    }
    local DECIMALS = { [0] = "None", [1] = "One", [2] = "Two" }
    local DECIMALS_ORDER = { 0, 1, 2 }

    local TYPE_ROWS = {}
    function TYPE_ROWS.audio(c)
        local s = c.s
        return {
            { type = "dropdown", text = "Audio Channel",
              tooltip = "Which audio channel the block's volume bar adjusts.",
              values = { master = "Master", sfx = "Sound Effects", music = "Music", ambience = "Ambience" },
              order = { "master", "sfx", "music", "ambience" },
              getValue = function() return s.channel or "master" end,
              setValue = function(v) s.channel = v; c.Apply() end },
        }
    end
    function TYPE_ROWS.clock(c)
        local s = c.s
        -- Untouched, the clock follows the Time Manager CVars; toggling stores a per-block override.
        return {
            { type = "toggle", text = "Local Time", tooltip = "Local computer time instead of server time.",
              getValue = function()
                  if s.localTime == nil then return CVarOn("timeMgrUseLocalTime") end
                  return s.localTime == true
              end,
              setValue = function(v) s.localTime = v and true or false; c.Apply() end },
            { type = "toggle", text = "24 Hour Clock", tooltip = "Use 24-hour time.",
              getValue = function()
                  if s.twentyFour == nil then return CVarOn("timeMgrUseMilitaryTime") end
                  return s.twentyFour == true
              end,
              setValue = function(v) s.twentyFour = v and true or false; c.Apply() end },
            MkToggle(c, "Mail Alert", "showMail", "Shows an envelope icon when you have unread mail."),
            MkToggle(c, "Resting Icon", "showResting", "Shows a rest icon while your character is resting."),
        }
    end
    function TYPE_ROWS.combat(c)
        return { MkToggle(c, "Show Only In Combat", "onlyInCombat", "Shows the combat status text only while your character is in combat.") }
    end
    function TYPE_ROWS.ms(c)
        local s = c.s
        return {
            { type = "dropdown", text = "Latency",
              tooltip = "Which latency to show: home, world, or both side by side.",
              values = { home = "Home", world = "World", both = "Both" }, order = { "home", "world", "both" },
              getValue = function()
                  if ns.LatencyMode then return ns.LatencyMode(s) end
                  return s.latencyMode or "home"
              end,
              setValue = function(v) s.latencyMode = v; c.Apply() end },
            { type = "toggle", text = "Show Icon",
              tooltip = "Shows a house or globe icon marking which latency each value is.",
              getValue = function() return s.showIcon == true end,
              setValue = function(v) s.showIcon = v and true or false; c.Apply(); SoftRefresh() end,
              _inline = MsIconSwatches(c) },
        }
    end
    function TYPE_ROWS.location(c)
        local s, cfg, blockId = c.s, c.cfg, c.b.id
        -- Width only matters when the solver reads this block's measured extent.
        local function WidthInert()
            if ns.BarSizingMode(cfg) ~= "auto" then return true end
            return ns.EnsureFillBlock(cfg) == blockId
        end
        local function WidthMode()
            if ns.LocationWidthMode then return ns.LocationWidthMode(s) end
            return s.widthMode or "auto"
        end
        local INERT_TIP = "This bar sizes its blocks itself, so the width is not this block's to choose."
        return {
            { type = "dropdown", text = "Width",
              tooltip = "Automatic follows the zone name. Manual holds the block at a fixed width and clips longer names, so it never shifts the blocks beside it.",
              values = { auto = "Automatic", manual = "Manual" }, order = { "auto", "manual" },
              disabled = WidthInert, disabledTooltip = INERT_TIP, rawTooltip = true,
              getValue = WidthMode,
              setValue = function(v) s.widthMode = v; c.Apply(); SoftRefresh() end },
            { type = "slider", pixel = true, text = "Max Width", min = 60, max = 400, step = 5,
              tooltip = "How wide the block stays, whatever the zone is called.",
              disabled = function() return WidthInert() or WidthMode() ~= "manual" end,
              disabledTooltip = function()
                  if WidthInert() then return INERT_TIP end
                  return "Manual width is required."
              end,
              rawTooltip = true,
              getValue = function() return s.maxWidth or ns.LOC_MAX_WIDTH_DEFAULT or 200 end,
              setValue = function(v) s.maxWidth = v; c.Apply() end },
            MkToggleOn(c, "Zone and Subzone", "showSubZone", "Shows the zone and the subzone together instead of the subzone alone."),
        }
    end
    function TYPE_ROWS.coords(c)
        local s = c.s
        return {
            { type = "dropdown", text = "Decimals",
              tooltip = "How precise the coordinates read. More decimals make the block wider.",
              values = DECIMALS, order = DECIMALS_ORDER,
              getValue = function() return s.precision or 0 end,
              setValue = function(v) s.precision = v; c.Apply() end },
            MkToggleOn(c, "Hide in Instance", "hideInInstance", "Removes the block from the bar in instanced content, where player coordinates are unavailable."),
        }
    end
    function TYPE_ROWS.gold(c)
        local s = c.s
        local rows = {
            MkToggle(c, "Show Icon", "showIcons", "Shows the coin icon next to the amount."),
            MkToggle(c, "Show Bag Space", "showBagSpace", "Shows your free bag slots."),
            MkToggle(c, "Coin Icons", "coinIcons", "Uses Blizzard's coin textures instead of the letter suffixes."),
            Checklist("Show Tooltip Data", "Which sections the gold tooltip shows.", GOLD_TIP_ELEMENTS,
                function(k) return s[k] ~= false end,
                function(k, v) s[k] = v and true or false end),
            MkToggle(c, "Abbreviate Amount", "abbreviate", "Shows large amounts using K/M suffixes (284,208g becomes 284.2Kg) instead of the full grouped number. The tooltip always shows the exact amount."),
        }
        if E.LocaleHasNumberAbbreviation and E.LocaleHasNumberAbbreviation() then
            rows[#rows + 1] = MkToggle(c, "Force English Units (K/M/B)", "forceEnglishUnits", "Always use K/M/B instead of localized units.")
        end
        return rows
    end
    function TYPE_ROWS.xprep(c)
        local s = c.s
        return {
            { type = "dropdown", text = "Mode",
              tooltip = "Automatic shows XP while leveling and reputation at max level.",
              values = { auto = "Automatic", xp = "Experience", rep = "Reputation" }, order = { "auto", "xp", "rep" },
              getValue = function() return s.mode or "auto" end,
              setValue = function(v) s.mode = v; c.Apply() end },
        }
    end
    function TYPE_ROWS.spec(c)
        return { MkToggle(c, "Uppercase Text", "useUppercase", "Renders the spec text in uppercase.") }
    end
    function TYPE_ROWS.micromenu(c)
        local b, s = c.b, c.s
        return {
            { type = "dropdown", text = "Align Content",
              tooltip = "Where the icon strip sits inside its slot.",
              values = AlignValues(c.vertical), order = { "LEFT", "CENTER", "RIGHT" },
              getValue = function() return b.align or "CENTER" end,
              setValue = function(v) b.align = v; c.Apply() end },
            { type = "slider", pixel = true, text = "Menu Spacing", min = 0, max = 16, step = 1,
              tooltip = "Gap between the main menu button and the icon row.",
              getValue = function() return s.mainMenuSpacing or 4 end,
              setValue = function(v) s.mainMenuSpacing = v; c.Apply() end },
            { type = "slider", pixel = true, text = "Icon Spacing", min = 0, max = 16, step = 1,
              tooltip = "Gap between the micro menu icons.",
              getValue = function() return s.iconSpacing or 2 end,
              setValue = function(v) s.iconSpacing = v; c.Apply() end },
            Checklist("Menu Elements", "Which micro menu buttons this block shows.", MM_ELEMENTS,
                function(k) return s[k] ~= false end,
                function(k, v) s[k] = v and true or false; c.Apply() end),
        }
    end
    function TYPE_ROWS.currency(c)
        local s = c.s
        local values, order = ns.BuildCurrencyList()
        values._noLoc = true
        values._menuOpts = { searchable = true, itemHeight = 26 }
        values[0] = L("Select a currency")
        table.insert(order, 1, 0)
        -- Keep a stored pick listed even when this character has not discovered it.
        if s.currencyId ~= nil and values[s.currencyId] == nil then
            values[s.currencyId] = tostring(s.currencyId) .. " |cff808080(" .. L("not discovered") .. ")|r"
            order[#order + 1] = s.currencyId
        end
        return {
            { type = "dropdown", text = "Currency",
              tooltip = "Pick any currency your character has discovered.",
              values = values, order = order,
              getValue = function() if s.currencyId == nil then return 0 end; return s.currencyId end,
              setValue = function(v)
                  if v == 0 then s.currencyId = nil else s.currencyId = v end
                  c.Apply()
              end },
            MkToggle(c, "Show Icon", "showIcon", "Shows the currency icon next to the amount."),
            MkToggleOn(c, "Show Description", "showDescription", "Shows the currency's description text in the tooltip. Turn off for a compact tooltip with just the name and the amount."),
        }
    end
    function TYPE_ROWS.bags(c)
        local s = c.s
        return {
            { type = "dropdown", text = "Display",
              tooltip = "Which slot count the block shows.",
              values = { free = "Free", used = "Used", freeTotal = "Free / Total", usedTotal = "Used / Total" },
              order = { "free", "used", "freeTotal", "usedTotal" },
              getValue = function() return s.value or "free" end,
              setValue = function(v) s.value = v; c.Apply() end },
            { type = "slider", text = "Low Space Warning", min = 0, max = 50, step = 1,
              tooltip = "Colors the number when free slots drop below this many; the swatch picks the color. Zero turns it off.",
              getValue = function() return s.lowThreshold or 0 end,
              setValue = function(v)
                  local wasOn = (s.lowThreshold or 0) > 0
                  s.lowThreshold = v
                  c.Apply()
                  if wasOn ~= (v > 0) then SoftRefresh() end
              end,
              _inline = function(B, row, rgn)
                  InlineSwatch(B, row, rgn,
                      function()
                          local d = ns.BAGS_LOW_COLOR or { 1, 0.35, 0.35 }
                          local col = s.lowColor
                          if col then return col.r or d[1], col.g or d[2], col.b or d[3] end
                          return d[1], d[2], d[3]
                      end,
                      function(r, g, bl) s.lowColor = { r = r, g = g, b = bl }; c.Apply() end,
                      false, function() return (s.lowThreshold or 0) <= 0 end, "Low Space Warning")
              end },
        }
    end
    function TYPE_ROWS.ilvl(c)
        local s = c.s
        return {
            { type = "dropdown", text = "Item Level",
              tooltip = "Equipped counts your worn gear. Total also counts upgrades sitting in your bags.",
              values = { equipped = "Equipped", total = "Total", both = "Both" }, order = { "equipped", "total", "both" },
              getValue = function() return s.value or "equipped" end,
              setValue = function(v) s.value = v; c.Apply() end },
            { type = "dropdown", text = "Decimals",
              tooltip = "How many decimal places the number carries.",
              values = DECIMALS, order = DECIMALS_ORDER,
              getValue = function() return s.precision or 0 end,
              setValue = function(v) s.precision = v; c.Apply() end },
        }
    end
    function TYPE_ROWS.ldb(c)
        local s = c.s
        -- Rebuilt on every page draw: EllesmereUI brokers register on their own schedule.
        local values, order = ns.BuildLDBList()
        values._noLoc = true
        values._menuOpts = { searchable = true, itemHeight = 26 }
        values[""] = L("Select a plugin")
        table.insert(order, 1, "")
        if s.source and not values[s.source] then
            values[s.source] = s.source .. " |cff808080(" .. L("not loaded") .. ")|r"
            order[#order + 1] = s.source
        end
        return {
            { type = "dropdown", text = "Plugin",
              tooltip = "An EllesmereUI LibDataBroker plugin registered right now. One block per plugin -- add the block again for a second one.",
              values = values, order = order,
              getValue = function() return s.source or "" end,
              setValue = function(v)
                  if v == "" then s.source = nil else s.source = v end
                  c.Apply()
              end },
            MkToggleOn(c, "Show Icon", "showIcon", "Shows the plugin's own icon next to its text."),
            MkToggleOn(c, "Show Text", "showText", "Shows the plugin's text. Off leaves an icon-only block that still carries the plugin's tooltip and clicks."),
            MkToggle(c, "Show Label", "showLabel", "Prefixes the plugin's own name to its text."),
            MkToggleOn(c, "Strip Colors", "stripColors", "Removes the color codes the plugin writes into its own text, so this block's Text Color applies. Off keeps the plugin's colors."),
            { type = "slider", pixel = true, text = "Max Width", min = 0, max = 400, step = 5,
              tooltip = "Holds the block at this width and clips longer text, so a plugin whose text keeps changing length never shifts the blocks beside it. Zero sizes the block to whatever the plugin currently says.",
              getValue = function() return s.maxWidth or 0 end,
              setValue = function(v)
                  if v == 0 then s.maxWidth = nil else s.maxWidth = v end
                  c.Apply()
              end },
        }
    end

    ---------------------------------------------------------------------------
    --  DATABARS: selector, rename, templates, delete
    ---------------------------------------------------------------------------
    local function TemplateRow(B, buttonText)
        local values = {}
        for _, k in ipairs(TEMPLATE_ORDER) do values[k] = TEMPLATE_LABELS[k] end
        Row(B,
            { type = "dropdown", text = "New Bar Template",
              tooltip = "Starter layout for the next bar you create.",
              values = values, order = TEMPLATE_ORDER,
              getValue = function() return O.template end,
              setValue = function(v) O.template = v end },
            { type = "button", text = buttonText, width = 180,
              onClick = function() Restructure(function() ns.CreateBar(O.template) end) end })
    end

    local function PromptDeleteBar(barId)
        if CombatBlocked() then return end
        local cfg = ns.GetBar(barId)
        if not cfg then return end
        local function Delete()
            if CombatBlocked() then return end
            ns.DeleteBar(barId)
            SelectedBar()
            HardRefresh()
            if E.SmoothScrollTo then E.SmoothScrollTo(0) end
        end
        if E.ShowConfirmPopup then
            E:ShowConfirmPopup({
                title = "Delete DataBar",
                message = format(L("Are you sure you want to delete \"%s\"?"), cfg.name or ""),
                confirmText = "Delete", cancelText = "Cancel",
                onConfirm = Delete,
            })
        else
            Delete()
        end
    end

    local function BuildManage(B, cfg)
        local barId = cfg.id
        Section(B, "DATABARS")
        local values, order = { _noLoc = true }, {}
        for _, bar in ipairs(ns.BarsInOrder()) do
            values[bar.id] = bar.name or ("DataBar " .. bar.id)
            order[#order + 1] = bar.id
        end
        local nameBox
        local row = Row(B,
            { type = "dropdown", text = "Select Bar",
              tooltip = "The bar this page edits.",
              values = values, order = order,
              getValue = function() local c = SelectedBar(); return c and c.id end,
              setValue = function(v) SelectBar(v); HardRefresh() end },
            { type = "input", text = "Bar Name", inputWidth = 170,
              tooltip = "Rename this bar. Press Enter to apply.",
              getValue = function() local c = ns.GetBar(barId); return c and c.name or "" end,
              setValue = function(v)
                  local c = ns.GetBar(barId)
                  if not c or type(v) ~= "string" then return end
                  v = v:gsub("^%s+", ""):gsub("%s+$", "")
                  if v == "" or v == c.name then return end
                  ns.RenameBar(barId, v)
                  if nameBox and nameBox:IsVisible() then HardRefresh()
                  elseif E.InvalidatePageCache then E:InvalidatePageCache() end
              end })
        -- The rename box must never keep keyboard focus once the page hides or rebuilds.
        if B.live and row and row._rightRegion then
            nameBox = row._rightRegion._control
            if nameBox and nameBox.HookScript and nameBox.ClearFocus then
                nameBox:SetAutoFocus(false)
                nameBox:HookScript("OnHide", function(box) box:ClearFocus() end)
            end
        end
        TemplateRow(B, "Create Bar")
        Row(B,
            { type = "labeledButton", text = "Delete Bar", buttonText = "Delete", width = 110,
              tooltip = "Deletes the selected bar and all of its blocks.",
              onClick = function() PromptDeleteBar(barId) end },
            { type = "labeledButton", text = "Position", buttonText = "Unlock Mode", width = 130,
              tooltip = "Move and resize bars in Unlock Mode.",
              onClick = function()
                  if CombatBlocked() then return end
                  if E.ToggleUnlockMode then E:ToggleUnlockMode() end
              end })
    end

    ---------------------------------------------------------------------------
    --  Preview strip: solved like the live bar, click = scroll to the block's
    --  section, right click = remove, hover = highlight the live slot.
    ---------------------------------------------------------------------------
    local function ScrollToBlock(B, blockId)
        local sec = blockId and B.sections[blockId]
        if not (sec and sec.GetPoint and E.SmoothScrollTo) then return end
        local _, _, _, _, headerY = sec:GetPoint(1)
        if headerY then E.SmoothScrollTo(max(0, abs(headerY) - 40)) end
    end

    local function BuildPreview(B, cfg)
        O.previewHost, O.previewRelayout = nil, nil
        if not B.live then return end
        local parent, barId = B.parent, cfg.id
        local vertical = cfg.orientation == "V"
        local pad = E.CONTENT_PAD or 10
        local thick = 40
        local len = vertical and 220 or max(100, (parent:GetWidth() or 640) - pad * 2)
        B.y = B.y - 15
        local host = CreateFrame("Frame", nil, parent)
        host._isSpacer = true
        if vertical then host:SetWidth(thick); host:SetHeight(len) else host:SetWidth(len); host:SetHeight(thick) end
        host:SetPoint("TOP", parent, "TOP", 0, B.y)
        host:SetFrameLevel(parent:GetFrameLevel() + 2)
        if E.PP and E.PP.CreateBorder then host._edbBorder = E.PP.CreateBorder(host, 0, 0, 0, 0.8, 1, "OVERLAY", 7) end
        ns.MakePreviewBackdrop(host, cfg.theme, not cfg.hideBorder)
        O.previewHost = host

        local segs = {}
        local function Seg(i)
            if segs[i] then return segs[i] end
            local seg = CreateFrame("Button", nil, host)
            seg:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            seg:SetFrameLevel(host:GetFrameLevel() + 3)
            local wash = seg:CreateTexture(nil, "ARTWORK")
            wash:SetAllPoints(seg)
            wash:SetTexture(1, 1, 1, 0.08)
            wash:Hide()
            local div = seg:CreateTexture(nil, "OVERLAY")
            div:SetTexture(1, 1, 1, 0.15)
            if vertical then
                div:SetHeight(1); div:SetPoint("BOTTOMLEFT", seg, "BOTTOMLEFT", 0, 0); div:SetPoint("BOTTOMRIGHT", seg, "BOTTOMRIGHT", 0, 0)
            else
                div:SetWidth(1); div:SetPoint("TOPRIGHT", seg, "TOPRIGHT", 0, 0); div:SetPoint("BOTTOMRIGHT", seg, "BOTTOMRIGHT", 0, 0)
            end
            local text = seg:CreateFontString(nil, "OVERLAY")
            text:SetFont(OPT_FONT, 10, "")
            text:SetPoint("CENTER", seg, "CENTER", 0, 0)
            seg.wash, seg.div, seg.text = wash, div, text
            seg:SetScript("OnEnter", function(btn)
                wash:Show()
                O.segHoverId = btn.blockId
                if btn.blockId then ns.SetBlockEditHighlight(barId, btn.blockId) end
                if E.ShowWidgetTooltip and btn.label then
                    E.ShowWidgetTooltip(btn, L(btn.label) .. "\n|cff999999" .. L("Click to scroll. Right Click to remove.") .. "|r")
                end
            end)
            seg:SetScript("OnLeave", function()
                wash:Hide()
                O.segHoverId = nil
                ns.SetBlockEditHighlight(nil, nil)
                if E.HideWidgetTooltip then E.HideWidgetTooltip() end
            end)
            seg:SetScript("OnClick", function(btn, button)
                if not btn.blockId then return end
                if button == "RightButton" then
                    local id = btn.blockId
                    Restructure(function() ns.RemoveBlock(barId, id) end)
                    return
                end
                ScrollToBlock(B, btn.blockId)
            end)
            segs[i] = seg
            return seg
        end

        local function Relayout()
            local c = ns.GetBar(barId)
            if not c or c.orientation ~= cfg.orientation then return end
            ns.MakePreviewBackdrop(host, c.theme, not c.hideBorder)
            local real = max(1, ResolvedBarLength(c))
            local scale = len / real
            local solved = ns.SolveLayout(c, real, function(b)
                local w = ns.GetLiveAutoLength and ns.GetLiveAutoLength(barId, b.id)
                if w and w > 0 then return w end
                if TYPE_LABEL[b.type] then return EST_LEN[b.type] or 80 end
                return 0
            end)
            local fillId = ns.BarSizingMode(c) == "auto" and ns.EnsureFillBlock(c)
            local ar, ag, ab = ns.GetAccent()
            for i = 1, #solved do
                local sg = solved[i]
                local f = Seg(i)
                local at = floor(sg.at * scale + 0.5)
                local px = max(1, floor(sg.px * scale + 0.5))
                f.blockId = sg.block.id
                f.label = TYPE_LABEL[sg.block.type]
                f:ClearAllPoints()
                if vertical then
                    f:SetWidth(thick); f:SetHeight(px); f:SetPoint("TOP", host, "TOP", 0, -at)
                else
                    f:SetWidth(px); f:SetHeight(thick); f:SetPoint("LEFT", host, "LEFT", at, 0)
                end
                f.text:SetText(f.label and L(f.label) or "")
                local room = vertical and (thick - 4) or (px - 6)
                if (vertical and px < 14) or f.text:GetStringWidth() > room then f.text:SetText("") end
                if fillId and sg.block.id == fillId then f.text:SetTextColor(ar, ag, ab, 0.9)
                else f.text:SetTextColor(1, 1, 1, 0.8) end
                if i == #solved then f.div:Hide() else f.div:Show() end
                f:Show()
            end
            for i = #solved + 1, #segs do segs[i]:Hide() end
        end
        O.previewRelayout = Relayout
        Relayout()
        -- Live instances measure themselves after this build: solve once more on the next frame.
        host:SetScript("OnUpdate", function(f) f:SetScript("OnUpdate", nil); Relayout() end)
        host:SetScript("OnShow", Relayout)
        host:SetScript("OnHide", function() ns.SetBlockEditHighlight(nil, nil) end)

        B.y = B.y - (vertical and len or thick) - 6
        local hint = host:CreateFontString(nil, "OVERLAY")
        hint:SetFont(OPT_FONT, 10, "")
        hint:SetTextColor(1, 1, 1, 0.4)
        hint:SetPoint("TOP", host, "BOTTOM", 0, -6)
        hint:SetText(L("Click a block to scroll to its settings. Right Click to remove it."))
        B.y = B.y - 16
    end

    ---------------------------------------------------------------------------
    --  Sizing mode: centered segmented Auto Sized / Even Split toggle
    ---------------------------------------------------------------------------
    local SIZING_MODES = { { key = "auto", label = "Auto Sized" }, { key = "even", label = "Even Split" } }
    local function BuildSizing(B, cfg)
        B.y = B.y - 15
        local BTN_W, BTN_H = 150, 26
        if B.live then
            local EG = E.ELLESMERE_GREEN or { r = 0.05, g = 0.82, b = 0.62 }
            local wrap = CreateFrame("Frame", nil, B.parent)
            wrap._isSpacer = true
            wrap:SetWidth(BTN_W * 2); wrap:SetHeight(BTN_H)
            wrap:SetPoint("TOP", B.parent, "TOP", 0, B.y)
            if E.PP and E.PP.CreateBorder then E.PP.CreateBorder(wrap, 1, 1, 1, 0.10, 1) end
            local cur = ns.BarSizingMode(cfg)
            for mi, m in ipairs(SIZING_MODES) do
                local btn = CreateFrame("Button", nil, wrap)
                btn:SetWidth(BTN_W); btn:SetHeight(BTN_H)
                btn:SetPoint("LEFT", wrap, "LEFT", (mi - 1) * BTN_W, 0)
                local bg = btn:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints(btn)
                local lbl = btn:CreateFontString(nil, "OVERLAY")
                lbl:SetFont(OPT_FONT, 12, "")
                lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
                lbl:SetText(L(m.label))
                if cur == m.key then
                    bg:SetTexture(EG.r, EG.g, EG.b, 0.85)
                    lbl:SetTextColor(1, 1, 1, 1)
                else
                    bg:SetTexture(0.10, 0.10, 0.11, 0.85)
                    lbl:SetTextColor(1, 1, 1, 0.55)
                    btn:SetScript("OnEnter", function() bg:SetTexture(0.16, 0.16, 0.17, 0.9); lbl:SetTextColor(1, 1, 1, 0.85) end)
                    btn:SetScript("OnLeave", function() bg:SetTexture(0.10, 0.10, 0.11, 0.85); lbl:SetTextColor(1, 1, 1, 0.55) end)
                    btn:SetScript("OnClick", function()
                        local c = ns.GetBar(cfg.id)
                        if not c then return end
                        c.sizingMode = m.key
                        ns.ApplyBar(c.id)
                        HardRefresh()
                    end)
                end
            end
        end
        B.y = B.y - (BTN_H + 15)
    end

    ---------------------------------------------------------------------------
    --  BAR SETTINGS
    ---------------------------------------------------------------------------
    local function BarTextureValues()
        if E.AppendSharedMediaTextures and ns.barTextureNames and ns.barTextureOrder then
            pcall(E.AppendSharedMediaTextures, ns.barTextureNames, ns.barTextureOrder, nil, ns.barTextures)
        end
        local values, order = {}, {}
        local names = ns.barTextureNames or {}
        for _, key in ipairs(ns.barTextureOrder or { "none" }) do
            if key ~= "---" then values[key] = names[key] or key; order[#order + 1] = key end
        end
        local lookup = ns.barTextures or {}
        values._menuOpts = { itemHeight = 28, background = function(key) return lookup[key] end }
        return values, order
    end

    local function BuildBarSettings(B, cfg)
        local barId = cfg.id
        local vertical = cfg.orientation == "V"
        local theme = cfg.theme
        if type(theme) ~= "table" then
            theme = { style = "eui", euiAlpha = 0.5, modernColor = { r = 0.067, g = 0.067, b = 0.067, a = 0.95 } }
            cfg.theme = theme
        end
        local function Apply() ns.ApplyBar(barId) end
        local function ApplyTheme() ns.ApplyTheme(barId); RefreshPreviewTheme() end
        local function IsModern() return theme.style == "modern" end
        local function ModernColor()
            local c = theme.modernColor
            if not c then c = { r = 0.067, g = 0.067, b = 0.067, a = 0.95 }; theme.modernColor = c end
            return c
        end

        Section(B, "BAR SETTINGS")

        -- Visibility | Hide Border ("Never" fully disables the bar's work).
        local hideBorderCfg = { type = "toggle", text = "Hide Border",
            tooltip = "Hide the 1-pixel outline around the bar.",
            getValue = function() return cfg.hideBorder == true end,
            setValue = function(v) cfg.hideBorder = v and true or false; ApplyTheme() end }
        local visRow
        if E.BuildVisibilityRow then
            local h
            visRow, h = E.BuildVisibilityRow(B.W, B.parent, B.y,
                { getStore = function() return ns.GetBar(barId) end,
                  legacyKey = "visibility",
                  caps = ns.EDB_VIS_CAPS,
                  onChanged = function() ns.ApplyBar(barId); ns.UpdateAllBarVisibility() end,
                  onOptionChanged = function() ns.UpdateAllBarVisibility() end },
                hideBorderCfg)
            B.y = B.y - h
        else
            visRow = Row(B,
                { type = "dropdown", text = "Visibility",
                  values = { always = "Always", never = "Never", mouseover = "Mouseover", in_combat = "In Combat",
                             out_of_combat = "Out of Combat", in_raid = "In Raid", in_party = "In Party", solo = "Solo" },
                  order = { "always", "never", "mouseover", "in_combat", "out_of_combat", "in_raid", "in_party", "solo" },
                  getValue = function() return cfg.visibility or "always" end,
                  setValue = function(v) cfg.visibility = v; ns.ApplyBar(barId); ns.UpdateAllBarVisibility() end },
                hideBorderCfg)
        end
        Cog(B, visRow and visRow._leftRegion, { icon = E.COGS_ICON, title = "Bar Layer",
            rows = {
                { type = "dropdown", label = "Bar Strata",
                  tooltip = "Screen layer this bar renders on. Raise it to draw over other frames, lower it to sit behind them.",
                  values = STRATA_LABELS, order = STRATA_ORDER,
                  get = function() local c = ns.GetBar(barId); return (c and c.barStrata) or "MEDIUM" end,
                  set = function(v) local c = ns.GetBar(barId); if c then c.barStrata = v; ns.ApplyBar(barId) end end },
            } })

        -- Orientation | Background Style (cog: EllesmereUI Backdrop Dim)
        local themeRow = Row(B,
            { type = "dropdown", text = "Orientation",
              tooltip = "Horizontal bars lay blocks left to right; vertical bars stack them top to bottom.",
              values = { H = "Horizontal", V = "Vertical" }, order = { "H", "V" },
              getValue = function() return cfg.orientation == "V" and "V" or "H" end,
              setValue = function(v)
                  cfg.orientation = v
                  local e = cfg.snapEdge
                  if v == "V" and (e == "bottom" or e == "top") then cfg.snapEdge = "left"
                  elseif v == "H" and (e == "left" or e == "right") then cfg.snapEdge = "bottom" end
                  Apply()
                  HardRefresh()
              end },
            { type = "dropdown", text = "Background Style",
              tooltip = "EllesmereUI matches the window-skin shell; Modern is a flat color.",
              values = { eui = "EllesmereUI", modern = "Modern" }, order = { "eui", "modern" },
              getValue = function() return IsModern() and "modern" or "eui" end,
              setValue = function(v)
                  theme.style = v
                  if v == "modern" then ModernColor().a = 0.95 end
                  ns.ApplyTheme(barId)
                  HardRefresh()
              end })
        Cog(B, themeRow and themeRow._rightRegion, { title = "EllesmereUI Background",
            disabled = function() return theme.style == "modern" end,
            disabledTooltip = "the EllesmereUI theme",
            rows = {
                { type = "slider", label = "Backdrop Dim", min = 0, max = 100, step = 1,
                  get = function() return floor((theme.euiAlpha or 0.5) * 100 + 0.5) end,
                  set = function(v) theme.euiAlpha = v / 100; ApplyTheme() end },
            } })

        -- Bar Opacity (+ Modern color swatch) | Bar Texture (Modern only)
        local texValues, texOrder = BarTextureValues()
        local opacityRow = Row(B,
            { type = "slider", text = "Bar Opacity", min = 0, max = 100, step = 1,
              tooltip = "Opacity of the bar's background; the swatch picks the Modern color.",
              getValue = function()
                  if IsModern() then return floor((ModernColor().a or 0.95) * 100 + 0.5) end
                  local a = theme.euiOpacity
                  if a == nil then a = 1 end
                  return floor(a * 100 + 0.5)
              end,
              setValue = function(v)
                  if IsModern() then ModernColor().a = v / 100 else theme.euiOpacity = v / 100 end
                  ApplyTheme()
              end },
            { type = "dropdown", text = "Bar Texture",
              tooltip = "Background texture for this bar, tinted by the bar's color and opacity.",
              disabled = function() return not IsModern() end,
              disabledTooltip = "Modern Background Style is required.", rawTooltip = true,
              values = texValues, order = texOrder,
              getValue = function() return cfg.barTexture or "none" end,
              setValue = function(v) cfg.barTexture = v; ns.ApplyTheme(barId); Apply() end })
        InlineSwatch(B, opacityRow, opacityRow and opacityRow._leftRegion,
            function()
                local c = ModernColor()
                return c.r or 0.067, c.g or 0.067, c.b or 0.067
            end,
            function(r, g, bl)
                local c = ModernColor()
                c.r, c.g, c.b = r, g, bl
                ApplyTheme()
            end,
            false, function() return not IsModern() end, "the Modern background style")

        -- Full Screen Width/Height | Snap to Screen Edge; Width | Height.
        -- Labels flip with orientation; cfg.length is always the along-axis extent.
        local lenLabel, fullLabel, thickLabel = "Width", "Full Screen Width", "Height"
        if vertical then lenLabel, fullLabel, thickLabel = "Height", "Full Screen Height", "Width" end
        Row(B,
            { type = "toggle", text = fullLabel,
              tooltip = "Sizes the bar to the full screen extent along its axis.",
              getValue = function() return cfg.lengthMode == "full" end,
              setValue = function(v)
                  cfg.lengthMode = v and "full" or "custom"
                  Apply()
                  RelayoutPreview()
                  SoftRefresh()
              end },
            { type = "dropdown", text = "Snap to Screen Edge",
              tooltip = "Pins the bar flush against a screen edge; moving the bar in unlock mode sets this back to None.",
              values = { none = "None", bottom = "Bottom", top = "Top", left = "Left", right = "Right" },
              order = { "none", "bottom", "top", "left", "right" },
              itemDisabled = function(v)
                  if vertical then return v == "bottom" or v == "top" end
                  return v == "left" or v == "right"
              end,
              itemDisabledTooltip = function(v)
                  if v == "bottom" or v == "top" then return "Not available for vertical bars" end
                  return "Not available for horizontal bars"
              end,
              getValue = function() return cfg.snapEdge or "none" end,
              setValue = function(v) cfg.snapEdge = v; ns.ApplyBarPosition(barId) end })
        Row(B,
            { type = "slider", text = lenLabel, min = 100, max = 3000, step = 10,
              tooltip = "Size of the bar along its block axis in pixels.",
              disabled = function() return cfg.lengthMode == "full" end,
              disabledTooltip = format(L("Disabled while %s is enabled."), L(fullLabel)), rawTooltip = true,
              getValue = function() return cfg.length or 400 end,
              setValue = function(v) cfg.length = v; Apply(); RelayoutPreview() end },
            { type = "slider", text = thickLabel, min = 16, max = 3000, step = 1,
              tooltip = "Size of the bar across its block axis in pixels.",
              getValue = function() return cfg.thickness or 30 end,
              setValue = function(v) cfg.thickness = v; Apply() end })

        -- Text Scale | Hover Highlight Blocks
        Row(B,
            { type = "slider", text = "Text Scale", min = 50, max = 150, step = 5,
              tooltip = "Scales every text element on this bar.",
              getValue = function() return cfg.fontScale or 100 end,
              setValue = function(v) cfg.fontScale = v; Apply() end },
            { type = "toggle", text = "Hover Highlight Blocks",
              tooltip = "Shows a faint white wash over each block on mouseover.",
              getValue = function() return cfg.hoverHighlight == true end,
              setValue = function(v) cfg.hoverHighlight = v and true or false; Apply() end })
    end

    ---------------------------------------------------------------------------
    --  BLOCKS: add a block, then one section per block
    ---------------------------------------------------------------------------
    local function BuildAddBlock(B, cfg)
        local barId = cfg.id
        Section(B, "BLOCKS")
        local values = {}
        for _, t in ipairs(ns.BLOCK_TYPES) do values[t.key] = t.label end
        if not TYPE_LABEL[O.blockType] then O.blockType = TYPE_ORDER[1] end
        Row(B,
            { type = "dropdown", text = "Block To Add",
              tooltip = "Block type the Add Block button appends to the end of this bar.",
              values = values, order = TYPE_ORDER,
              getValue = function() return O.blockType end,
              setValue = function(v) O.blockType = v end },
            { type = "button", text = "Add Block", width = 180,
              onClick = function() Restructure(function() ns.AddBlock(barId, O.blockType) end) end })
    end

    local function BuildBlock(B, cfg, b, index, count)
        local barId, blockId = cfg.id, b.id
        local s = b.settings
        if not s then s = {}; b.settings = s end
        local vertical = cfg.orientation == "V"
        local isSpacer = b.type == "spacer"
        local c = { b = b, s = s, cfg = cfg, barId = barId, vertical = vertical }
        function c.Apply() ns.ApplyBar(barId) end

        B.sections[blockId] = Section(B, index .. ". " .. upper(L(TYPE_LABEL[b.type] or b.type)))

        -- Order (Retail: drag in the preview strip)
        Row(B,
            { type = "button", text = vertical and "Move Up" or "Move Left", width = 160,
              disabled = function() return index <= 1 end,
              onClick = function() Restructure(function() ns.MoveBlock(barId, blockId, -1) end) end },
            { type = "button", text = vertical and "Move Down" or "Move Right", width = 160,
              disabled = function() return index >= count end,
              onClick = function() Restructure(function() ns.MoveBlock(barId, blockId, 1) end) end })

        -- Auto Sized: per-side gaps (all but the fill block) + Fill Remaining / Force Centered.
        local sizingRow
        if ns.BarSizingMode(cfg) == "auto" then
            if ns.EnsureFillBlock(cfg) ~= blockId then
                local gl, gr = "Left Gap", "Right Gap"
                if vertical then gl, gr = "Top Gap", "Bottom Gap" end
                sizingRow = Row(B,
                    { type = "slider", text = gl, min = 0, max = 200, step = 1,
                      tooltip = "Empty space reserved on this side of the block's content.",
                      getValue = function() local l = ns.ContentGapsOf(b); return l end,
                      setValue = function(v) b.contentGapL = v; c.Apply(); RelayoutPreview() end },
                    { type = "slider", text = gr, min = 0, max = 200, step = 1,
                      tooltip = "Empty space reserved on this side of the block's content.",
                      getValue = function() local _, r = ns.ContentGapsOf(b); return r end,
                      setValue = function(v) b.contentGapR = v; c.Apply(); RelayoutPreview() end })
            end
            local fillRow = Row(B,
                { type = "toggle", text = "Fill Remaining Space",
                  tooltip = "Stretches this block to absorb the space the sized blocks leave over; exactly one block per bar fills.",
                  disabled = function() return ns.EnsureFillBlock(cfg) == blockId end,
                  disabledTooltip = "This block is already the 'Fill Remaining Space' block. Check another block to move the role.",
                  rawTooltip = true,
                  getValue = function() return ns.EnsureFillBlock(cfg) == blockId end,
                  setValue = function(v) if v then ns.SetFillBlock(barId, blockId); HardRefresh() end end },
                { type = "toggle", text = "Force Centered",
                  tooltip = "Pins this block's content to the exact center of the bar; blocks before it pack left, blocks after pack right. Combined with Fill Remaining, the block also absorbs the leftover space around the center.",
                  getValue = function() return cfg.centerBlockId == blockId end,
                  setValue = function(v)
                      if v then ns.SetCenterBlock(barId, blockId)
                      elseif cfg.centerBlockId == blockId then ns.SetCenterBlock(barId, nil) end
                      HardRefresh()
                  end })
            sizingRow = sizingRow or fillRow
        end
        if sizingRow then B.hover[#B.hover + 1] = { id = blockId, rgn = sizingRow } end

        -- Text Align (cog: Text Position) | Content Scale (cog: Content Position)
        if not isSpacer then
            local leftCfg
            if b.type == "micromenu" then
                leftCfg = { type = "toggle", text = "Enable Text",
                    tooltip = "Shows the online friend and guild counters.",
                    getValue = function() return s.hideSocialText ~= true end,
                    setValue = function(v) s.hideSocialText = not v; c.Apply() end }
            else
                leftCfg = { type = "dropdown", text = "Text Align",
                    tooltip = "Where the block's content sits inside its slot.",
                    values = AlignValues(vertical), order = { "LEFT", "CENTER", "RIGHT" },
                    getValue = function() return b.align or "CENTER" end,
                    setValue = function(v) b.align = v; c.Apply() end }
            end
            local alignRow = Row(B, leftCfg,
                { type = "slider", text = "Content Scale", min = 50, max = 200, step = 5,
                  tooltip = "Scales this block's content as a group inside its slot.",
                  getValue = function() return b.scale or 100 end,
                  setValue = function(v) b.scale = v; c.Apply() end })
            Cog(B, alignRow and alignRow._leftRegion, { icon = E.DIRECTIONS_ICON, title = "Text Position",
                rows = {
                    { type = "slider", label = "X Offset", min = -50, max = 50, step = 1,
                      get = function() return b.textXOff or 0 end,
                      set = function(v) b.textXOff = v; ns.ReflowBlocks(barId) end },
                    { type = "slider", label = "Y Offset", min = -50, max = 50, step = 1,
                      get = function() return b.textYOff or 0 end,
                      set = function(v) b.textYOff = v; ns.ReflowBlocks(barId) end },
                } })
            Cog(B, alignRow and alignRow._rightRegion, { icon = E.DIRECTIONS_ICON, title = "Content Position",
                rows = {
                    { type = "slider", label = "X Offset", min = -50, max = 50, step = 1,
                      get = function() return b.xOff or 0 end,
                      set = function(v) b.xOff = v; c.Apply() end },
                    { type = "slider", label = "Y Offset", min = -50, max = 50, step = 1,
                      get = function() return b.yOff or 0 end,
                      set = function(v) b.yOff = v; c.Apply() end },
                } })
        end

        -- Block Background (+ swatch) | Text Color
        local bgRow = Row(B,
            { type = "toggle", text = "Block Background",
              tooltip = "Tints this block's slot with its own color.",
              getValue = function() return b.bg ~= nil end,
              setValue = function(v)
                  if v then b.bg = b.bg or { r = 0, g = 0, b = 0, a = 0.5 } else b.bg = nil end
                  c.Apply()
                  SoftRefresh()
              end },
            isSpacer and BLANK() or TextColorCfg(c))
        InlineSwatch(B, bgRow, bgRow and bgRow._leftRegion,
            function()
                local col = b.bg
                if not col then return 0, 0, 0, 0.5 end
                return col.r or 0, col.g or 0, col.b or 0, col.a or 0.5
            end,
            function(r, g, bl, a) b.bg = { r = r, g = g, b = bl, a = a }; c.Apply() end,
            true, function() return b.bg == nil end, "Enable Block Background")

        -- Icon Color | the icon-row setting of this type
        if ICON_COLOR_BLOCKS[b.type] then
            local right = ICON_RIGHT[b.type]
            Row(B, IconColorCfg(c), right and right(c) or BLANK())
        end

        -- Type rows, two per row; Remove Block fills the odd tail (or opens a row).
        local rows = {}
        local typeRows = TYPE_ROWS[b.type]
        if typeRows then rows = typeRows(c) end
        rows[#rows + 1] = { type = "labeledButton", text = "Remove Block", buttonText = "Remove", width = 110,
            tooltip = "Removes this block from the bar.",
            onClick = function() Restructure(function() ns.RemoveBlock(barId, blockId) end) end }
        for k = 1, #rows, 2 do
            local l, r = rows[k], rows[k + 1] or BLANK()
            local row = Row(B, l, r)
            if B.live and row then
                if l._inline then l._inline(B, row, row._leftRegion) end
                if r._inline then r._inline(B, row, row._rightRegion) end
            end
        end
    end

    -- While the cursor is over a block's sizing controls, wash that block on the live bar.
    local function BuildHoverWatcher(B, barId)
        if not B.live or #B.hover == 0 then return end
        local watcher = CreateFrame("Frame", nil, B.parent)
        watcher:SetWidth(1); watcher:SetHeight(1)
        local acc, cur = 0, nil
        local function SetHL(id)
            if id == cur then return end
            cur = id
            if id then ns.SetBlockEditHighlight(barId, id)
            elseif not O.segHoverId then ns.SetBlockEditHighlight(nil, nil) end
        end
        watcher:SetScript("OnUpdate", function(_, elapsed)
            acc = acc + (elapsed or 0)
            if acc < 0.1 then return end
            acc = 0
            local sf = E._scrollFrame
            if not ns.MouseOver(B.parent) or (sf and not ns.MouseOver(sf)) then SetHL(nil); return end
            local hit
            for k = 1, #B.hover do
                local hr = B.hover[k]
                if hr.rgn and ns.MouseOver(hr.rgn) then hit = hr.id; break end
            end
            SetHL(hit)
        end)
        watcher:SetScript("OnHide", function() SetHL(nil) end)
    end

    ---------------------------------------------------------------------------
    --  Page
    ---------------------------------------------------------------------------
    local function BuildPage(_, parent, yOffset)
        local B = { W = E.Widgets, parent = parent, y = yOffset, live = not E._prebuilding, sections = {}, hover = {} }
        if B.live and E.ClearContentHeader then E:ClearContentHeader() end
        parent._showRowDivider = true
        O.previewHost, O.previewRelayout = nil, nil

        if not Profile() then return abs(B.y) end
        local cfg = SelectedBar()
        if not cfg then
            Section(B, "CREATE NEW DATABAR")
            Row(B, { type = "label", text = "Create your first DataBar from a starter template, or start empty." }, BLANK())
            TemplateRow(B, "Create Bar")
            return abs(B.y)
        end

        BuildManage(B, cfg)
        BuildPreview(B, cfg)
        BuildSizing(B, cfg)
        BuildBarSettings(B, cfg)
        BuildAddBlock(B, cfg)
        local shown = {}
        for _, b in ipairs(cfg.blocks) do
            -- Saved types with no Wrath block (Retail crests / great vault) get no section.
            if TYPE_LABEL[b.type] then shown[#shown + 1] = b end
        end
        for i = 1, #shown do BuildBlock(B, cfg, shown[i], i, #shown) end
        BuildHoverWatcher(B, cfg.id)
        if B.W.Spacer then
            local _, h = B.W:Spacer(parent, B.y, 20)
            B.y = B.y - (h or 20)
        end
        return abs(B.y)
    end

    ---------------------------------------------------------------------------
    --  Module registration
    ---------------------------------------------------------------------------
    E:RegisterModule(ADDON, {
        title = "DataBars",
        description = "User-created info bars: clock, gold, XP, micro menu and more.",
        pages = { PAGE },
        searchTerms = "data bars clock fps latency gold bags bank inventory coordinates location durability experience XP reputation currency talent spec professions hearthstone travel micro menu item level audio volume broker spacer combat visibility strata",
        buildPage = function(pageName, parent, yOffset) return BuildPage(pageName, parent, yOffset) end,
        onPageCacheRestore = function(pageName)
            -- Bars can be resized in Unlock Mode between visits: re-solve the restored preview.
            if pageName == PAGE and O.previewRelayout then O.previewRelayout() end
        end,
        onReset = function()
            -- Resets the SELECTED bar's appearance/behavior; keeps its id, name and blocks.
            if InCombatLockdown() then return end
            local p = ns.GetProfile()
            if not p then return end
            local cfg = SelectedBar()
            if not cfg then return end
            cfg.orientation = "H"
            cfg.lengthMode = "custom"
            cfg.length = 400
            cfg.thickness = 30
            cfg.fontScale = 100
            cfg.theme = { style = "eui", euiAlpha = 0.5, modernColor = { r = 0.067, g = 0.067, b = 0.067, a = 0.95 } }
            cfg.hideBorder = nil
            cfg.visibility = "always"
            cfg.visibilityModes = nil
            cfg.visibilityMatch = nil
            for _, k in ipairs(E.VIS_OPT_KEYS or {}) do cfg[k] = nil end
            cfg.savedPos = nil
            ns.ApplyBar(cfg.id)
            ns.UpdateAllBarVisibility()
            if E.InvalidatePageCache then E:InvalidatePageCache() end
        end,
    })

    ---------------------------------------------------------------------------
    --  Slash command  /edb  opens EllesmereUI to the DataBars module
    ---------------------------------------------------------------------------
    SLASH_EUI335DATABARS1 = "/edb"
    SlashCmdList.EUI335DATABARS = function()
        if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end
        if E.ShowModule then E:ShowModule(ADDON) end
    end
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
