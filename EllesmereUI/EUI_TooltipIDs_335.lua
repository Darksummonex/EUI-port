-- Native Wrath tooltips have no Retail TooltipDataProcessor.
local E = EllesmereUI
if not E or not _G.EUI_WOW_335 or E._wrathTooltipIDs then return end
local A = {}
E._wrathTooltipIDs = A

local function Enabled()
    local db = EllesmereUIDB
    if not db or not db.showSpellID then return false end
    local mod = db.spellIDModifier or "none"
    if mod == "shift" then return IsShiftKeyDown() end
    if mod == "control" then return IsControlKeyDown() end
    if mod == "alt" then return IsAltKeyDown() end
    return true
end

local function LinkID(link)
    return type(link) == "string" and tonumber(link:match("spell:(%d+)")) or nil
end

function A.Add(tooltip, id)
    id = tonumber(id)
    if not Enabled() or not tooltip or not id or id <= 0 then return end
    if tooltip._eui335SpellID == id then return end
    -- Coexist with the same line supplied by another addon.
    local name = tooltip:GetName()
    if name and tooltip.NumLines then
        for i = 1, tooltip:NumLines() do
            local fs = _G[name .. "TextLeft" .. i]
            local text = fs and fs:GetText()
            if text then
                text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                local right = _G[name .. "TextRight" .. i]
                if (text == "Spell ID" or text == "SpellID") and right and tonumber(right:GetText()) == id
                    or text:match("^ID%s*:?%s*" .. id .. "%f[%D]") then
                    tooltip._eui335SpellID = id
                    return
                end
            end
        end
    end
    tooltip._eui335SpellID = id
    local r, g, b = E.GetAccentColor()
    tooltip:AddDoubleLine("Spell ID", tostring(id), r, g, b, 1, 1, 1)
    tooltip:Show()
end

-- Retail shows ItemID and IconID with Spell ID on; showItemID/showIconID opt out.
-- Wrath item icons are texture paths, so the icon line shows the file name.
local function HasItemLine(tooltip, id)
    local name = tooltip:GetName()
    if not name or not tooltip.NumLines then return false end
    for i = 1, tooltip:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local text = fs and fs:GetText()
        if text then
            text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            local right = _G[name .. "TextRight" .. i]
            if (text == "Item ID" or text == "ItemID") and right and tonumber(right:GetText()) == id
                or text:match("^ItemID%s*:?%s*" .. id .. "%f[%D]") then
                return true
            end
        end
    end
    return false
end

function A.AddItem(tooltip, link)
    local id = type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
    if not Enabled() or not tooltip or not id or id <= 0 then return end
    if tooltip._eui335ItemID == id then return end
    tooltip._eui335ItemID = id
    local db = EllesmereUIDB
    local showItem, showIcon = db.showItemID ~= false, db.showIconID ~= false
    if not showItem and not showIcon then return end
    if showItem and HasItemLine(tooltip, id) then showItem = false end
    local icon = showIcon and GetItemIcon and GetItemIcon(id)
    if not showItem and type(icon) ~= "string" then return end
    local r, g, b = E.GetAccentColor()
    if showItem then tooltip:AddDoubleLine("Item ID", tostring(id), r, g, b, 1, 1, 1) end
    if type(icon) == "string" then tooltip:AddDoubleLine("Icon", icon:match("([^\\/]+)$") or icon, r, g, b, 1, 1, 1) end
    tooltip:Show()
end

local function Hook(tooltip, method, callback)
    if type(tooltip[method]) == "function" then hooksecurefunc(tooltip, method, callback) end
end

local function Register(tooltip)
    if not tooltip or A[tooltip] then return end
    A[tooltip] = true
    tooltip:HookScript("OnTooltipCleared", function(self) self._eui335SpellID = nil; self._eui335ItemID = nil end)
    tooltip:HookScript("OnTooltipSetItem", function(self)
        if not self.GetItem then return end
        local _, link = self:GetItem()
        A.AddItem(self, link)
    end)
    tooltip:HookScript("OnTooltipSetSpell", function(self)
        if not self.GetSpell then return end
        local _, second, third = self:GetSpell()
        A.Add(self, tonumber(third) or tonumber(second))
    end)
    Hook(tooltip, "SetHyperlink", function(self, link) A.Add(self, LinkID(link)) end)
    Hook(tooltip, "SetSpellByID", function(self, id) A.Add(self, id) end)
    for method, query in pairs({ SetUnitBuff = UnitBuff, SetUnitDebuff = UnitDebuff, SetUnitAura = UnitAura }) do
        Hook(tooltip, method, function(self, unit, index, filter)
            -- Wrath's aura ID is return 11 (return 2 is rank).
            A.Add(self, select(11, query(unit, index, filter)))
        end)
    end
    Hook(tooltip, "SetAction", function(self, slot)
        if not GetActionInfo then return end
        -- For spells id is the spellbook slot; the spell ID is the fourth return.
        local kind, id, subType, spellID = GetActionInfo(slot)
        if kind == "spell" then
            if not tonumber(spellID) and GetSpellLink then spellID = LinkID(GetSpellLink(id, subType or "spell")) end
            A.Add(self, tonumber(spellID))
        elseif kind == "macro" and GetMacroSpell and GetSpellLink then
            local spell, rank = GetMacroSpell(id)
            if spell then A.Add(self, LinkID(GetSpellLink(spell, rank))) end
        end
    end)
end

local function RegisterAll()
    Register(GameTooltip); Register(ItemRefTooltip)
    Register(_G.ShoppingTooltip1); Register(_G.ShoppingTooltip2)
end
RegisterAll()
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", RegisterAll)
