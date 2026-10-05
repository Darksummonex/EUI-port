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

local function Hook(tooltip, method, callback)
    if type(tooltip[method]) == "function" then hooksecurefunc(tooltip, method, callback) end
end

local function Register(tooltip)
    if not tooltip or A[tooltip] then return end
    A[tooltip] = true
    tooltip:HookScript("OnTooltipCleared", function(self) self._eui335SpellID = nil end)
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
        local kind, id = GetActionInfo(slot)
        if kind == "spell" then
            A.Add(self, id)
        elseif kind == "macro" and GetMacroSpell and GetSpellLink then
            local spell, rank = GetMacroSpell(id)
            if spell then A.Add(self, LinkID(GetSpellLink(spell, rank))) end
        end
    end)
end

Register(GameTooltip)
Register(ItemRefTooltip)
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function() Register(GameTooltip); Register(ItemRefTooltip) end)
