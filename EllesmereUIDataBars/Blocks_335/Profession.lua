-- EllesmereUIDataBars 3.3.5: profession blocks (port of Retail Blocks\Profession.lua).
-- Wrath has no GetProfessions: professions are read from the skill lines and
-- identified by the localized names of their profession spells (Herbalism's
-- skill line is not named after its "Herb Gathering" spell, so an abandonable
-- skill line matching no other profession is Herbalism). "profession" shows
-- the two primary professions, "profession2" Cooking, First Aid and Fishing.
-- Each entry is a secure button: left-click casts the profession's opener
-- spell (Mining opens Smelting; gathering-only professions open the Skills
-- tab), right-click opens the Skills tab (primary) or casts Basic Campfire.
local _, ns = ...
if not ns.IsWrath then return end
local E = EllesmereUI
local L = ns.L
local MEDIA = ns.MEDIA
local K = ns.BlockKit

local CreateFrame      = CreateFrame
local InCombatLockdown = InCombatLockdown
local GetTime          = GetTime
local floor            = math.floor
local max              = math.max
local Size, Solid      = ns.Size, ns.Solid

local ICON_GAP             = K.ICON_GAP
local CONTENT_BASE         = K.CONTENT_BASE
local InstKey              = K.InstKey
local MakeEventFrame       = K.MakeEventFrame
local RegisterInstEvents   = K.RegisterInstEvents
local UnregisterInstEvents = K.UnregisterInstEvents
local VSlotW               = K.VSlotW
local MaybeRelayout        = K.MaybeRelayout
local AttachTextOffset     = K.AttachTextOffset
local BlockColorOf         = K.BlockColorOf
local IconColorOf          = K.IconColorOf
local ParkSecureFrame      = K.ParkSecureFrame

local MEDIA_PROF = MEDIA .. "profession\\"
local CAMPFIRE_SPELL = 818   -- Basic Campfire

-- spell = the spell whose localized name equals the skill line; open = the
-- spell that opens the trade window (nil: no window).
local PROFESSIONS = {
    { key = "alchemy",        spell = 2259,  open = 2259,  icon = "prof-alchemy" },
    { key = "blacksmithing",  spell = 2018,  open = 2018,  icon = "prof-blacksmith" },
    { key = "enchanting",     spell = 7411,  open = 7411,  icon = "prof-enchanting" },
    { key = "engineering",    spell = 4036,  open = 4036,  icon = "prof-engineer" },
    { key = "herbalism",      spell = 2366,                icon = "prof-herbalism" },
    { key = "inscription",    spell = 45357, open = 45357, icon = "prof-inscription" },
    { key = "jewelcrafting",  spell = 25229, open = 25229, icon = "prof-jewelcrafting" },
    { key = "leatherworking", spell = 2108,  open = 2108,  icon = "prof-leatherworking" },
    { key = "mining",         spell = 2575,  open = 2656,  icon = "prof-mining" },
    { key = "skinning",       spell = 8613,                icon = "prof-skinning" },
    { key = "tailoring",      spell = 3908,  open = 3908,  icon = "prof-tailoring" },
    { key = "cooking",        spell = 2550,  open = 2550,  icon = "prof-cooking",  secondary = 1 },
    { key = "firstaid",       spell = 3273,  open = 3273,  icon = "prof-firstaid", secondary = 2 },
    { key = "fishing",        spell = 7620,                icon = "prof-fishing",  secondary = 3 },
}
local HERBALISM = PROFESSIONS[5]

local byName
local function ProfessionByName(name)
    if not byName then
        byName = { Herbalism = HERBALISM }
        for i = 1, #PROFESSIONS do
            local def = PROFESSIONS[i]
            local n = GetSpellInfo(def.spell)
            if n then byName[n] = def end
        end
    end
    return byName[name]
end

-- Shared skill-line scan for every profession block. Collapsed headers are
-- expanded for the read and collapsed again; the SKILL_LINES_CHANGED that
-- toggle fires is ignored for a short quiet window so blocks never ping-pong.
local skillCache, lastSkills, quietUntil = nil, nil, 0
local function ScanSkills(prev)
    local out = { primary = {}, secondary = {} }
    if not (GetNumSkillLines and GetSkillLineInfo) then return out end
    local collapsed
    local skillFrameOpen = SkillFrame and SkillFrame:IsVisible()
    local i = 1
    while i <= GetNumSkillLines() do
        local name, isHeader, isExpanded = GetSkillLineInfo(i)
        if name and isHeader and not isExpanded then
            -- Never fight the open Skills window: keep the last full read instead.
            if skillFrameOpen or not (ExpandSkillHeader and CollapseSkillHeader) then
                if prev then return prev end
            else
                collapsed = collapsed or {}
                collapsed[name] = true
                ExpandSkillHeader(i)
            end
        end
        i = i + 1
    end
    -- Unmatched abandonable lines count as Herbalism only under the primary
    -- professions' header (or, with none matched, outside the secondary one).
    local lines, header, profHeader, secHeader = {}, nil, nil, nil
    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank, abandonable = GetSkillLineInfo(i)
        if name and isHeader then
            header = name
        elseif name then
            local def = ProfessionByName(name)
            if def and def ~= HERBALISM then
                if def.secondary then secHeader = secHeader or header else profHeader = profHeader or header end
            end
            if def or abandonable then
                lines[#lines + 1] = { def = def, header = header, name = name, rank = rank or 0, maxRank = maxRank or 0 }
            end
        end
    end
    for i = 1, #lines do
        local row = lines[i]
        local def = row.def
        if not def and (row.header == profHeader or (not profHeader and row.header ~= secHeader)) then def = HERBALISM end
        if def then
            row.def, row.header, row.nameUpper = def, nil, row.name:upper()
            if def.secondary then out.secondary[#out.secondary + 1] = row
            else out.primary[#out.primary + 1] = row end
        end
    end
    table.sort(out.secondary, function(a, b) return a.def.secondary < b.def.secondary end)
    if collapsed then
        for i = GetNumSkillLines(), 1, -1 do
            local name, isHeader = GetSkillLineInfo(i)
            if isHeader and collapsed[name] then CollapseSkillHeader(i) end
        end
        quietUntil = GetTime() + 0.5
    end
    return out
end
local function GetSkills()
    if not skillCache then
        skillCache = ScanSkills(lastSkills)
        lastSkills = skillCache
    end
    return skillCache
end

local function OpenSkillsTab()
    if ToggleCharacter then ToggleCharacter("SkillFrame") end
end

-------------------------------------------------------------------------------
--  PROFESSION (secure opener buttons)
-------------------------------------------------------------------------------
local function MakeProfessionBlock(blockCfg, slot, content, barCtx, secondary)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)
    inst.events = { "SKILL_LINES_CHANGED", "TRADE_SKILL_UPDATE", "CHAT_MSG_SKILL", "PLAYER_ENTERING_WORLD",
        "PLAYER_REGEN_ENABLED" }

    local NUM = secondary and 3 or 2
    local profs = {}
    local entries = {}   -- [i] = { frame, icon, text, bar, barBg }
    local built, pendingRefresh = false, false

    local function BC() return barCtx.cfg end

    local function UpdateProfValues()
        local skills = GetSkills()
        local list = secondary and skills.secondary or skills.primary
        for i = 1, NUM do profs[i] = list[i] or {} end
    end

    local function StyleProfFrame(profData, e)
        local profFrame, profIcon, profText, profBar, profBarBg = e.frame, e.icon, e.text, e.bar, e.barBg
        if not profData or not profData.def then profFrame:Hide(); return end
        local barCfg = BC()
        local barH = barCtx.GetThickness()
        local fontSize = max(9, floor(CONTENT_BASE * 0.4333 + 0.5))
        local iconSize = fontSize + 8
        local isSide = barCtx.IsVertical()

        -- Secure attributes (OOC: Refresh never runs in combat).
        local opener = profData.def.open and GetSpellInfo(profData.def.open)
        if opener then
            profFrame:SetAttribute("*type1", "spell")
            profFrame:SetAttribute("*spell1", opener)
        else
            profFrame:SetAttribute("*type1", nil)
            profFrame:SetAttribute("*spell1", nil)
        end
        e.hasOpener = opener and true or false

        local showIcon = (blockCfg.settings or {}).showIcon ~= false
        profIcon:SetTexture(MEDIA_PROF .. profData.def.icon)
        if showIcon then
            Size(profIcon, iconSize, iconSize); profIcon:Show()
        else
            profIcon:Hide()
        end
        local pbr, pbg, pbb = BlockColorOf(blockCfg)
        do
            local ir, ig, ib = IconColorOf(blockCfg)
            profIcon:SetVertexColor(ir, ig, ib, 1)
        end

        ns.SetFont(profText, fontSize, barCfg)
        profText:SetTextColor(pbr, pbg, pbb, 1); profText:SetText(profData.name or "")

        if isSide then
            local frameW = VSlotW(inst)
            local innerW = max(30, frameW - 8)
            local totalH = 8 + iconSize + 2

            profIcon:ClearAllPoints()
            profIcon:SetPoint("TOP", profFrame, "TOP", 0, -4)

            if not showIcon then totalH = 8 + 2 end

            ns.SetWrappedText(profText, innerW, "CENTER")
            profText:ClearAllPoints()
            if showIcon then
                profText:SetPoint("TOP", profIcon, "BOTTOM", 0, -2)
            else
                profText:SetPoint("TOP", profFrame, "TOP", 0, -4)
            end
            totalH = totalH + ns.SnapToPixelGrid(profText:GetStringHeight())

            if profData.rank ~= profData.maxRank then
                local ar, ag, ab = ns.GetAccent()
                local bH = 3
                profBar:Show()
                profBar:SetMinMaxValues(1, max(1, profData.maxRank)); profBar:SetValue(profData.rank)
                profBar:SetStatusBarColor(ar, ag, ab, 1); Solid(profBarBg, 0.15, 0.15, 0.15, 0.6)
                Size(profBar, innerW, bH)
                profBar:ClearAllPoints()
                profBar:SetPoint("TOP", profText, "BOTTOM", 0, -3)
                totalH = totalH + 3 + bH
            else
                profBar:Hide()
            end

            Size(profFrame, frameW, max(totalH, barH))
            profFrame:Show()
        else
            ns.ResetInlineText(profText, "LEFT")
            profIcon:ClearAllPoints(); profIcon:SetPoint("LEFT", profFrame, "LEFT", 0, 0)

            local halfBand = iconSize / 2
            if profData.rank == profData.maxRank then
                profBar:Hide()
                profText:ClearAllPoints()
                if showIcon then
                    profText:SetPoint("LEFT", profIcon, "RIGHT", ICON_GAP, 0)
                else
                    profText:SetPoint("LEFT", profFrame, "LEFT", 0, 0)
                end
            else
                profBar:Show()
                profText:ClearAllPoints()
                if showIcon then
                    profText:SetPoint("TOPLEFT", profIcon, "TOPRIGHT", ICON_GAP, 0)
                else
                    profText:SetPoint("TOPLEFT", profFrame, "LEFT", 0, halfBand)
                end
                local ar, ag, ab = ns.GetAccent()
                profBar:SetMinMaxValues(1, max(1, profData.maxRank)); profBar:SetValue(profData.rank)
                profBar:SetStatusBarColor(ar, ag, ab, 1); Solid(profBarBg, 0.15, 0.15, 0.15, 0.6)
                -- Bar bottom-right, sharing the text's left edge and tracking TEXT width.
                local textW = max(profText:GetStringWidth(), 20)
                local bH = max(2, iconSize - fontSize - 3)
                Size(profBar, textW, bH)
                profBar:ClearAllPoints()
                if showIcon then
                    profBar:SetPoint("BOTTOMLEFT", profIcon, "BOTTOMRIGHT", ICON_GAP, 0)
                else
                    profBar:SetPoint("BOTTOMLEFT", profFrame, "LEFT", 0, -halfBand)
                end
            end
            local textW = max(profText:GetStringWidth(), 20)
            local effIcon = showIcon and (iconSize + ICON_GAP) or 0
            Size(profFrame, effIcon + textW, barH); profFrame:Show()
        end
    end

    local function ShowTip(f)
        ns.Tip_Begin(f)
        local title
        if secondary then
            title = SECONDARY_SKILLS or "Secondary Professions"
        else
            title = TRADE_SKILLS or "Professions"
        end
        title = title:gsub(":%s*$", "")
        ns.Tip_AddLine(title, 1, 1, 1)
        ns.Tip_AddLine(" ")
        local white = (E.COLOR_CODES and E.COLOR_CODES.WHITE) or "|cffffffff"
        for i = 1, NUM do
            local p = profs[i]
            if p and p.def then
                ns.Tip_AddDouble(p.name, white .. p.rank .. "|r / " .. p.maxRank, 1, 1, 1, 1, 1, 1)
            end
        end
        ns.Tip_AddLine(" ")
        local rightLabel = L["OPEN_PROFESSION_BOOK"]
        if secondary then rightLabel = L["START_CAMPFIRE"] end
        ns.Tip_AddDouble(L["LEFT_CLICK"], L["OPEN_PROFESSION"], 1, 1, 1, 1, 1, 1)
        ns.Tip_AddDouble(L["RIGHT_CLICK"], rightLabel, 1, 1, 1, 1, 1, 1)
        ns.Tip_Show()
    end

    local function Build()
        if built then return end
        built = true
        local campfire = GetSpellInfo(CAMPFIRE_SPELL)
        for i = 1, NUM do
            local f = CreateFrame("Button", "EllesmereUIDataBarsProf" .. i .. "_" .. inst.key, content, "SecureActionButtonTemplate")
            Size(f, 1, barCtx.GetThickness()); f:EnableMouse(true); f:RegisterForClicks("AnyUp")
            if secondary and campfire then
                f:SetAttribute("*type2", "spell")
                f:SetAttribute("*spell2", campfire)
            end
            local e = { frame = f }
            e.icon = f:CreateTexture(nil, "OVERLAY")
            e.text = f:CreateFontString(nil, "OVERLAY")
            e.bar = CreateFrame("StatusBar", nil, f); e.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
            e.barBg = e.bar:CreateTexture(nil, "BACKGROUND"); e.barBg:SetAllPoints()
            AttachTextOffset(inst, e.text)
            entries[i] = e
            -- HookScript, NOT SetScript: OnClick is SecureActionButton_OnClick.
            f:HookScript("OnClick", function(_, button)
                if button == "LeftButton" and not e.hasOpener then OpenSkillsTab()
                elseif button == "RightButton" and not secondary then OpenSkillsTab() end
            end)
            f:SetScript("OnEnter", function(self)
                local ar, ag, ab = ns.GetAccent()
                e.text:SetTextColor(ar, ag, ab, 1)
                e.icon:SetVertexColor(ar, ag, ab, 1)
                ShowTip(self)
            end)
            f:SetScript("OnLeave", function(self)
                local br, bgr, bb = BlockColorOf(blockCfg)
                e.text:SetTextColor(br, bgr, bb, 1)
                -- Icon restores through ICON color (accent by default), not the text color.
                local ir, ig, ib = IconColorOf(blockCfg)
                e.icon:SetVertexColor(ir, ig, ib, 1)
                ns.Tip_Hide(self)
            end)
        end
    end

    if InCombatLockdown() then
        ns.DeferUntilOOC("edbbuild:" .. inst.key, function()
            if inst._dead then return end
            Build()
            inst:Refresh()
        end)
    else
        Build()
    end

    function inst:Refresh()
        if not built then return end
        if InCombatLockdown() then pendingRefresh = true; return end
        pendingRefresh = false
        UpdateProfValues()
        local barH, gap = barCtx.GetThickness(), 5
        local isSide = barCtx.IsVertical()

        for i = 1, NUM do StyleProfFrame(profs[i], entries[i]) end

        local any = false
        if isSide then
            local slotW = VSlotW(inst)
            local totalH, prev = 0, nil
            for i = 1, NUM do
                local f = entries[i].frame
                if profs[i].def and f:IsShown() then
                    f:ClearAllPoints()
                    if prev then
                        f:SetPoint("TOP", prev, "BOTTOM", 0, -4)
                        totalH = totalH + 4
                    else
                        f:SetPoint("TOP", content, "TOP", 0, 0)
                    end
                    totalH = totalH + f:GetHeight()
                    prev, any = f, true
                end
            end
            Size(content, slotW, max(totalH, 1))
        else
            content:SetHeight(barH)
            local totalW, prev = 0, nil
            for i = 1, NUM do
                local f = entries[i].frame
                if profs[i].def and f:IsShown() then
                    f:ClearAllPoints()
                    if prev then
                        f:SetPoint("LEFT", prev, "RIGHT", gap, 0)
                        totalW = totalW + gap
                    else
                        f:SetPoint("LEFT", content, "LEFT", 0, 0)
                    end
                    totalW = totalW + f:GetWidth()
                    prev, any = f, true
                end
            end
            content:SetWidth(max(totalW, 1))
        end
        if any then content:Show() else content:Hide() end
        MaybeRelayout(inst)
    end

    inst.eventFrame = MakeEventFrame(inst, function(self, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if pendingRefresh then self:Refresh() end
            return
        end
        if event == "SKILL_LINES_CHANGED" and GetTime() < quietUntil then return end
        skillCache = nil
        self:Refresh()
    end)

    function inst:Enable()
        if not InCombatLockdown() then content:Show() end
        RegisterInstEvents(self)
    end

    function inst:Disable()
        UnregisterInstEvents(self)
        if not InCombatLockdown() then content:Hide() end
    end

    function inst:GetAutoLength()
        if not built then return 40 end
        -- No profession learned: collapse instead of reserving an empty gap.
        if not content:IsShown() then return 0 end
        if barCtx.IsVertical() then
            local barH = barCtx.GetThickness()
            local sum, n = 0, 0
            for i = 1, NUM do
                local f = entries[i] and entries[i].frame
                if f and f:IsShown() then sum = sum + (f:GetHeight() or 0); n = n + 1 end
            end
            if n > 1 then sum = sum + 5 * (n - 1) end
            return max(sum, barH, 50)
        end
        return max(content:GetWidth() or 80, 30)
    end

    function inst:Destroy()
        self._dead = true
        for i = 1, NUM do
            local e = entries[i]
            if e then
                ns.Tip_Hide(e.frame)
                ParkSecureFrame(e.frame, self.key .. "_prof" .. i)
            end
        end
        if not InCombatLockdown() then content:Hide() end
    end

    return inst
end

ns.BlockFactories.profession = function(blockCfg, slot, content, barCtx)
    return MakeProfessionBlock(blockCfg, slot, content, barCtx, false)
end

ns.BlockFactories.profession2 = function(blockCfg, slot, content, barCtx)
    return MakeProfessionBlock(blockCfg, slot, content, barCtx, true)
end
