-- EllesmereUIOptions compatibility layer for WoW 3.3.5 (Lua 5.1, no retail widget API).
-- Loads FIRST in the Options TOC. Everything is "define only if missing", so it is a
-- no-op on any client/server that already provides the API. Companion to the core's
-- EllesmereUI_3.3.5_Compat.lua (core shims C_Timer/C_AddOns/C_Spell/... ; this file
-- adds the widget-level methods the options panel and Widgets factory call).
EUI_CLIENT_BLOCKED = EUI_CLIENT_BLOCKED or false
EUI_CLIENT_FOREVER = EUI_CLIENT_FOREVER or false

local noop = function() end

---------------------------------------------------------------------------
-- 1. CreateFrame: 3.3.5 errors on unknown inherited templates
--    ("Couldn't find inherited node"). Strip the retail-only ones.
--    Keep the factory private: replacing Blizzard's global CreateFrame taints
--    native UI paths and frames subsequently created by load-on-demand addons.
---------------------------------------------------------------------------
do
    local STRIP = {
        BackdropTemplate = true, CooldownFrameTemplate = true,
        SecureHandlerBaseTemplate = false, -- exists in 3.3.5, keep
    }
    local orig = CreateFrame

    -- Screen-level popups (dropdown lists, menus, cog popups): some 3.3.5
    -- clients draw a popup's child rows under the popup's own background, and
    -- render a solid colour texture see-through. On every show (and again
    -- once the show has settled) each child is kept above its parent, and a
    -- nearly opaque solid background becomes a tinted white file, opaque.
    local WHITE = "Interface\\Buttons\\WHITE8X8"
    local function LiftChildren(f, depth)
        if depth > 12 then return end
        local lvl = f:GetFrameLevel()
        local kids = { f:GetChildren() }
        for i = 1, #kids do
            local c = kids[i]
            if c:GetFrameLevel() <= lvl then c:SetFrameLevel(lvl + 1) end
            LiftChildren(c, depth + 1)
        end
    end
    local function OpaqueBackground(f)
        local regions = { f:GetRegions() }
        for i = 1, #regions do
            local t = regions[i]
            if t._euiSolid and t._euiA and t._euiA >= 0.9 and t.GetDrawLayer
                and t:GetDrawLayer() == "BACKGROUND" then
                t:SetTexture(WHITE)
                t:SetVertexColor(t._euiR, t._euiG, t._euiB, 1)
            end
        end
    end
    local function FixPopup(f)
        OpaqueBackground(f)
        LiftChildren(f, 0)
    end
    local pending, driver = {}, nil
    local function OnPopupShow(f)
        FixPopup(f)
        if not driver then
            driver = orig("Frame")
            driver:Hide()
            driver:SetScript("OnUpdate", function(self)
                self:Hide()
                for p in pairs(pending) do
                    pending[p] = nil
                    if p:IsShown() then FixPopup(p) end
                end
            end)
        end
        pending[f] = true
        driver:Show()
    end
    EllesmereUI._FixOptionsPopup = FixPopup

    if orig and not EllesmereUI.CreateOptionsFrame then
        function EllesmereUI.CreateOptionsFrame(kind, name, parent, template, id)
            if type(template) == "string" and template ~= "" then
                local keep = {}
                for t in template:gmatch("[^,%s]+") do
                    if not STRIP[t] then keep[#keep + 1] = t end
                end
                template = #keep > 0 and table.concat(keep, ",") or nil
            end
            local frame = orig(kind, name, parent, template, id)
            -- Wrath EditBoxes can retain keyboard focus after their parent is hidden.
            -- Make every options-created EditBox opt-in to focus and always release it
            -- on hide. This also covers dropdown/search boxes created outside the main
            -- options frame hierarchy.
            if kind == "EditBox" and frame then
                if frame.SetAutoFocus then frame:SetAutoFocus(false) end
                if frame.HookScript and frame.ClearFocus then
                    frame:HookScript("OnHide", function(self) self:ClearFocus() end)
                end
            end
            if frame and kind == "Frame" and name == nil and frame.HookScript and (parent == UIParent
                or (parent and parent.GetName and parent:GetName() == "EllesmereUI_PadOverlayLayer")) then
                frame:HookScript("OnShow", OnPopupShow)
            end
            return frame
        end
    end
end

---------------------------------------------------------------------------
-- 2. Widget-method shims, applied to every widget metatable we can reach.
---------------------------------------------------------------------------
local function unpackColor(a, b, c, d)
    if type(a) == "table" then
        if a.GetRGBA then return a:GetRGBA() end
        return a.r or 0, a.g or 0, a.b or 0, a.a or 1
    end
    return a or 0, b or 0, c or 0, d or 1
end

local function patch(obj, isTexture)
    local mt = obj and getmetatable(obj)
    local idx = mt and mt.__index
    if type(idx) ~= "table" then return end

    if not idx.SetShown then
        idx.SetShown = function(self, show) if show then self:Show() else self:Hide() end end
    end
    if not idx.IsMouseOver and idx.GetLeft then
        idx.IsMouseOver = function(self) return MouseIsOver(self) end
    end
    -- Pixel-grid / retail-only presentation flags: no 3.3.5 equivalent, cosmetic only.
    for _, n in ipairs({
        "SetSnapToPixelGrid", "SetTexelSnappingBias", "SetClipsChildren",
        "SetIgnoreParentScale", "SetIgnoreParentAlpha",
        "SetMouseClickEnabled", "SetMouseMotionEnabled", "SetMaxLines", "SetNonSpaceWrap",
        "SetWordWrap", "EnableGamePadButton", "EnableGamePadStick", "SetHitRectInsets",
        "SetReverseFill", "SetSmoothing", "SetVertexOffset", "SetRotation", "SetAtlas",
        "SetNormalAtlas", "SetPushedAtlas", "SetHighlightAtlas", "SetDisabledAtlas",
        "AddMaskTexture", "RemoveMaskTexture", "SetDrawSwipe", "SetDrawEdge",
        "SetDrawBling", "SetSwipeColor", "SetSwipeTexture", "SetHideCountdownNumbers",
        "SetMotionScriptsWhileDisabled", "SetHorizTile", "SetVertTile", "SetReverse",
    }) do
        if not idx[n] then idx[n] = noop end
    end
    if not idx.SetFormattedText then
        idx.SetFormattedText = function(self, fmt, ...) self:SetText(string.format(fmt, ...)) end
    end
    if isTexture and not idx.SetColorTexture then
        idx.SetColorTexture = function(self, r, g, b, a) self:SetTexture(r, g, b, a or 1) end
    end
    if idx.ClearFocus and not idx.HasFocus then
        idx.HasFocus = function(self) return GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() == self end
    end
    if isTexture and idx.SetGradientAlpha and not idx._euiGradient then
        -- Retail: SetGradient(orient, minColor, maxColor). 3.3.5: SetGradientAlpha(orient, r,g,b,a, r,g,b,a).
        local origGradient = idx.SetGradient
        idx.SetGradient = function(self, orient, c1, c2, ...)
            if type(c1) == "table" and type(c2) == "table" then
                local r1, g1, b1, a1 = unpackColor(c1)
                local r2, g2, b2, a2 = unpackColor(c2)
                return self:SetGradientAlpha(orient, r1, g1, b1, a1, r2, g2, b2, a2)
            elseif origGradient then
                return origGradient(self, orient, c1, c2, ...)
            end
            return self:SetGradientAlpha(orient, c1, c2, ...)
        end
    end
end

do
    local probe = CreateFrame("Frame")
    -- Probes are not UI: the native EditBox defaults to autofocus. Keep all
    -- probe children invisible, especially after native windows close on Esc.
    probe:Hide()
    probe:EnableMouse(false)
    probe:EnableKeyboard(false)
    patch(probe)
    patch(probe:CreateTexture(), true)
    patch(probe:CreateFontString())
    for _,kind in ipairs({"Button","CheckButton","EditBox","ScrollFrame","Slider","StatusBar","Cooldown","Model","GameTooltip"}) do
        local widget=EllesmereUI.CreateOptionsFrame(kind,nil,probe)
        if kind=="EditBox" then widget:ClearFocus() end
        widget:EnableMouse(false); widget:EnableKeyboard(false); widget:Hide()
        patch(widget)
    end
    -- Animation objects
    local ag = probe:CreateAnimationGroup()
    local alpha = ag:CreateAnimation("Alpha")
    local amt = getmetatable(alpha) and getmetatable(alpha).__index
    if type(amt) == "table" then
        if not amt.SetFromAlpha then
            amt.SetFromAlpha = function(self, v)
                self._eFrom = v
                self:SetChange((self._eTo or 0) - v)
            end
        end
        if not amt.SetToAlpha then
            amt.SetToAlpha = function(self, v)
                self._eTo = v
                self:SetChange(v - (self._eFrom or 1))
            end
        end
    end
    local agmt = getmetatable(ag) and getmetatable(ag).__index
    if type(agmt) == "table" and not agmt.SetToFinalAlpha then agmt.SetToFinalAlpha = noop end

    -- Frame-level creators absent on 3.3.5: hand back inert texture objects so
    -- callers that only add masks / draw preview lines keep running. Never replace a
    -- method the client already has: these tables are shared with Blizzard frames,
    -- and an addon function there taints secure code (blocked actions on Esc).
    local fmt = getmetatable(probe).__index
    if not fmt.CreateMaskTexture then
        fmt.CreateMaskTexture = function(self) local t = self:CreateTexture(); t:Hide(); return t end
    end
    if not fmt.CreateLine then
        fmt.CreateLine = function(self)
            local t = self:CreateTexture()
            t.SetStartPoint, t.SetEndPoint, t.SetThickness = noop, noop, noop
            return t
        end
    end
end

---------------------------------------------------------------------------
-- 3. Globals / namespaces referenced by the options pages
---------------------------------------------------------------------------
Mixin = Mixin or function(obj, ...)
    for i = 1, select("#", ...) do
        for k, v in pairs((select(i, ...))) do obj[k] = v end
    end
    return obj
end
issecretvalue = issecretvalue or function() return false end
issecrettable = issecrettable or function() return false end
if not strtrim then strtrim = function(s) return (tostring(s):gsub("^%s+", ""):gsub("%s+$", "")) end end
if not tinsert then tinsert = table.insert end
if not wipe then wipe = function(t) for k in pairs(t) do t[k] = nil end return t end end

-- C_Spell: the companion core already supplies the Retail table shape.
-- Supply the same shape only when missing; loading Options must not replace it.
C_Spell = C_Spell or {}
if not C_Spell.GetSpellName then
    C_Spell.GetSpellName = function(id) return (GetSpellInfo(id)) end
end
if not C_Spell.SpellHasRange then
    C_Spell.SpellHasRange = function(id) local n = GetSpellInfo(id); return n and SpellHasRange and SpellHasRange(n) or false end
end
if not C_Spell.GetSpellInfo then
    C_Spell.GetSpellInfo = function(id)
        local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(id)
        if not name then return nil end
        return { name = name, subName = rank, iconID = icon, originalIconID = icon, castTime = castTime,
                 minRange = minRange, maxRange = maxRange, spellID = tonumber(id) }
    end
end


-- Options 0.4: namespaces used by the enabled core pages must be safe even when
-- the companion core does not provide a Retail atlas implementation. 3.3.5 has
-- no atlas database, so atlas lookup simply reports unavailable and the widget
-- code falls back to file textures / hides cosmetic icons.
C_Texture = C_Texture or {}
if EUI335_SafeAtlasInfo then EUI335_SafeAtlasInfo() end
C_Texture.GetAtlasInfo = C_Texture.GetAtlasInfo or function() return nil end

-- Retail spell texture helper used by dropdown previews.
C_Spell.GetSpellTexture = C_Spell.GetSpellTexture or function(id)
    local _, _, icon = GetSpellInfo(id)
    return icon
end

-- Avoid a hard dependency on a core-side CreateColor shim.
if not CreateColor then
    function CreateColor(r, g, b, a)
        local c = { r = r or 0, g = g or 0, b = b or 0, a = a == nil and 1 or a }
        function c:GetRGBA() return self.r, self.g, self.b, self.a end
        function c:GetRGB() return self.r, self.g, self.b end
        return c
    end
end

C_Item = C_Item or {}
C_Item.GetItemNameByID    = C_Item.GetItemNameByID    or function(id) return (GetItemInfo(id)) end
C_Item.GetItemSpell       = C_Item.GetItemSpell       or function(id) return GetItemSpell(id) end
C_Item.RequestLoadItemDataByID = C_Item.RequestLoadItemDataByID or noop

C_SpecializationInfo = C_SpecializationInfo or {}
C_SpecializationInfo.GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo or function() return nil end
C_SpecializationInfo.GetNumSpecializationsForClassID = C_SpecializationInfo.GetNumSpecializationsForClassID or function() return GetNumTalentTabs and GetNumTalentTabs() or 3 end

-- Core 0.9 maps Wrath talent tabs to the Retail specialization API. Expose the
-- equivalent legacy globals too because a few original options paths probe those
-- globals directly before showing per-spec controls.
if not GetSpecialization and C_SpecializationInfo.GetSpecialization then
    GetSpecialization = function() return C_SpecializationInfo.GetSpecialization() end
end
if not GetSpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
    GetSpecializationInfo = function(index)
        return C_SpecializationInfo.GetSpecializationInfo(index)
    end
end

C_ClassColor = C_ClassColor or {}
C_ClassColor.GetClassColor = C_ClassColor.GetClassColor or function(class)
    local c = (RAID_CLASS_COLORS or {})[class]
    if not c then return nil end
    return CreateColor(c.r, c.g, c.b, 1)
end

C_CVar = C_CVar or {}
C_CVar.GetCVarInfo = C_CVar.GetCVarInfo or function(n)
    local ok, cur = pcall(GetCVar, n)
    if not ok then return nil, nil end
    local def
    if GetCVarDefault then
        local okDef, value = pcall(GetCVarDefault, n)
        if okDef then def = value end
    end
    -- If this client cannot expose a default, use the current value. This keeps
    -- the original "only touch untouched defaults" logic harmless on 3.3.5.
    return cur, def or cur
end

C_VoiceChat = C_VoiceChat or {}
C_VoiceChat.GetTtsVoices = C_VoiceChat.GetTtsVoices or function() return {} end
C_VoiceChat.SpeakText    = C_VoiceChat.SpeakText    or noop

C_CurrencyInfo = C_CurrencyInfo or {}
C_CurrencyInfo.GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo or function() return nil end
C_CurrencyInfo.GetCurrencyListSize = C_CurrencyInfo.GetCurrencyListSize or function() return GetCurrencyListSize and GetCurrencyListSize() or 0 end
C_CurrencyInfo.GetCurrencyListInfo = C_CurrencyInfo.GetCurrencyListInfo or function() return nil end
C_CurrencyInfo.ExpandCurrencyList  = C_CurrencyInfo.ExpandCurrencyList  or noop

C_CooldownViewer = C_CooldownViewer or {}
C_CooldownViewer.GetCooldownViewerCooldownInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo or function() return nil end
C_ClassTalents = C_ClassTalents or {}
C_ClassTalents.GetActiveConfigID = C_ClassTalents.GetActiveConfigID or function() return nil end
C_Traits = C_Traits or {}
for _, n in ipairs({ "GetTreeNodes", "GetNodeInfo", "GetEntryInfo", "GetDefinitionInfo", "GetConfigInfo" }) do
    if not C_Traits[n] then C_Traits[n] = function() return nil end end
end
C_SpellBook = C_SpellBook or {}
C_SpellBook.FindSpellOverrideByID = C_SpellBook.FindSpellOverrideByID or function(id) return id end

C_ToyBox = C_ToyBox or {}
for _, n in ipairs({ "SetFilterString", "SetCollectedShown", "SetUncollectedShown", "SetUnusableShown", "ForceToyRefilter" }) do
    if not C_ToyBox[n] then C_ToyBox[n] = noop end
end
C_ToyBox.GetToyInfo = C_ToyBox.GetToyInfo or function() return nil end

C_Container = C_Container or {}
C_Container.GetSortBagsRightToLeft = C_Container.GetSortBagsRightToLeft or function() return false end
C_Container.SetSortBagsRightToLeft = C_Container.SetSortBagsRightToLeft or noop

Enum = Enum or {}
Enum.PowerType = Enum.PowerType or {}
for k, v in pairs({ Mana = 0, Rage = 1, Focus = 2, Energy = 3, ComboPoints = 4, Runes = 5,
                    RunicPower = 6, SoulShards = 7, HolyPower = 9 }) do
    if Enum.PowerType[k] == nil then Enum.PowerType[k] = v end
end
Enum.BagIndex = Enum.BagIndex or { Backpack = 0, ReagentBag = 5 }
Enum.StatusBarInterpolation = Enum.StatusBarInterpolation or { Immediate = 0, ExponentialEaseOut = 1 }
Enum.SpellBookItemType = Enum.SpellBookItemType or { Spell = 1, Flyout = 3 }
Enum.TraitNodeType = Enum.TraitNodeType or { Selection = 2, SubTreeSelection = 3 }

---------------------------------------------------------------------------
-- 4. Misc globals used by Widgets / General options
--    Core 0.9 supplies stable Wrath talent-tree specialization IDs, so the
--    options layer can safely expose specialization controls through those IDs.
---------------------------------------------------------------------------
if not GetPhysicalScreenSize then
    function GetPhysicalScreenSize()
        local ok, res = pcall(GetCVar, "gxResolution")
        local w, h = ((ok and res) or ""):match("(%d+)x(%d+)")
        if w and h then return tonumber(w), tonumber(h) end
        return floor(GetScreenWidth() * UIParent:GetEffectiveScale() + .5),
               floor(GetScreenHeight() * UIParent:GetEffectiveScale() + .5)
    end
end
if not GetCVarBool then GetCVarBool = function(n) local ok, v = pcall(GetCVar, n); return ok and v == "1" or false end end

-- Keybind capture (Widgets key-chord picker)
if not GetConvertedKeyOrButton then GetConvertedKeyOrButton = function(k) return k end end
if not GetBindingFromClick then
    GetBindingFromClick = function(k) return GetBindingAction and GetBindingAction(k) or nil end
end
if not IsKeyPressIgnoredForBinding then
    local IGNORED = { LSHIFT = 1, RSHIFT = 1, LCTRL = 1, RCTRL = 1, LALT = 1, RALT = 1, UNKNOWN = 1 }
    IsKeyPressIgnoredForBinding = function(k) return k == nil or IGNORED[k] == 1 end
end
if not CreateKeyChordStringUsingMetaKeyState then
    CreateKeyChordStringUsingMetaKeyState = function(key)
        if not key then return nil end
        local s = ""
        if IsAltKeyDown()     then s = s .. "ALT-"   end
        if IsControlKeyDown() then s = s .. "CTRL-"  end
        if IsShiftKeyDown()   then s = s .. "SHIFT-" end
        return s .. key
    end
end
