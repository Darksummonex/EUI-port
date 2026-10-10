"""Replace the Style page builder (per-module rows) with Retail 9.4's look-card
checkbox dropdowns + Apply Styles. Keeps the port's per-module look limits."""
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / "EllesmereUIOptions" / "EUI_Style_Options.lua"

START = "local function StyleRowCfg(m)"

NEW = r'''function _G._EUI_BuildStylePage(pageName, parent, yOffset)
    local PP = EllesmereUI.PanelPP
    local y = yOffset

    -- Header: the first-install picker's look cards (three; four with WoW
    -- Forever on that client; EllesmereUI_StyleCards.lua), each one Apply
    -- to All for its look through the single reload prompt. The card for the
    -- look every loaded module already uses is marked IN USE, and its button
    -- stays live only while that look still has a font or window-skin change
    -- to apply. Under each card, a checkbox dropdown of the modules that use
    -- its look, and under those Apply Styles.
    -- Sized host + single TOPLEFT point per the search framework's geometry
    -- contract; the search prebuild only needs the y advance.
    local CARDS_TOP = 140
    local DD_GAP, DD_H, BTN_GAP, BTN_W, BTN_H = 14, 30, 26, 252, 45
    local DD_TOP = CARDS_TOP + (EllesmereUI.STYLE_CARD_H or 296) + DD_GAP
    local BTN_TOP = DD_TOP + DD_H + BTN_GAP
    local HERO_H = BTN_TOP + BTN_H + 4
    local hasHero = EllesmereUI.BuildStyleCards ~= nil
    if hasHero and not EllesmereUI._prebuilding then
        local FONT = EllesmereUI._font or "Interface\\AddOns\\EllesmereUI\\media\\fonts\\Expressway.ttf"
        local EG = EllesmereUI.ELLESMERE_GREEN
        local host = CreateFrame("Frame", nil, parent)
        PP.Size(host, parent:GetWidth() - EllesmereUI.CONTENT_PAD * 2, HERO_H)
        host:SetPoint("TOPLEFT", parent, "TOPLEFT", EllesmereUI.CONTENT_PAD, y - 20)

        local eyebrow = host:CreateFontString(nil, "OVERLAY")
        eyebrow:SetFont(FONT, 13, "")
        eyebrow:SetTextColor(EG.r, EG.g, EG.b, 0.9)
        PP.Point(eyebrow, "TOP", host, "TOP", 0, -4)
        eyebrow:SetText(EllesmereUI.L("CHOOSE YOUR LOOK"))

        local title = host:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT, 25, "")
        title:SetTextColor(1, 1, 1, 1)
        PP.Point(title, "TOP", eyebrow, "BOTTOM", 0, -6)
        title:SetText(EllesmereUI.L("Your UI, Restyled in Seconds"))

        local desc = host:CreateFontString(nil, "OVERLAY")
        desc:SetFont(FONT, 14, "")
        desc:SetTextColor(1, 1, 1, 0.5)
        desc:SetWidth(620)
        desc:SetJustifyH("CENTER")
        desc:SetWordWrap(true)
        PP.Point(desc, "TOP", title, "BOTTOM", 0, -10)
        desc:SetText(EllesmereUI.L("Your setup and every EllesmereUI feature carry over; only the look changes. Apply a style to every module in one click, or set each module below. Changing a style reloads the UI."))

        local cards = EllesmereUI.BuildStyleCards(host, -CARDS_TOP, {
            buttonText = "Apply to All",
            -- The card in use fades to half; its larger badge stays whole.
            inUseAlpha = 0.5,
            badgeSize = 13,
            onPick = function(styleKey)
                PromptStyleChanges(StyleChangesFor(styleKey), styleKey)
            end,
        })
        if cards then
            local function RefreshCards()
                local loaded = 0
                for i = 1, #MODULES do
                    if NS(MODULES[i].folder) ~= nil then loaded = loaded + 1 end
                end
                for key, handle in pairs(cards) do
                    local differ = 0
                    for i = 1, #MODULES do
                        local m = MODULES[i]
                        if NS(m.folder) ~= nil and m.get() ~= key and Supports(m, key) then differ = differ + 1 end
                    end
                    local inUse = loaded > 0 and differ == 0
                    local pickable = differ > 0 or FontPending(key)
                        or WholeUIWindowsPending(key)
                    -- "In Use" only on the card that is; with no styleable
                    -- module loaded a card with nothing to apply just dims.
                    handle:SetState(inUse, pickable, (inUse and not pickable) and "In Use" or nil)
                end
            end
            RefreshCards()
            -- Re-run on every page refresh and cached-page restore: a font or
            -- window skin set elsewhere changes what a card has to apply.
            EllesmereUI.RegisterWidgetRefresh(RefreshCards)

            -- Module picks: every module sits in exactly one look's dropdown,
            -- its saved style until moved, and shows there checked and locked:
            -- it moves only by being picked under another look (picking it
            -- under its saved look again undoes a move). Nothing is written
            -- until Apply Styles, whose reload prompt writes every move at
            -- once; leaving the page drops the picks. A look the module cannot
            -- draw on this client leaves it out of that look's list.
            local pending = {}   -- module key -> picked style, only where it differs
            local function Loaded(m) return NS(m.folder) ~= nil end
            local function PickOf(m) return pending[m.key] or m.get() end
            local function Pick(m, styleKey)
                pending[m.key] = (styleKey ~= m.get()) and styleKey or nil
            end
            local refreshers, applyBtn = {}, nil
            local function RefreshPicks()
                -- A profile switch can make a pick match its module again.
                for k, s in pairs(pending) do
                    local m = BY_KEY[k]
                    if not m or s == m.get() then pending[k] = nil end
                end
                for i = 1, #refreshers do refreshers[i]() end
                if applyBtn then
                    local on = next(pending) ~= nil
                    applyBtn:SetAlpha(on and 1 or 0.3)
                    applyBtn:EnableMouse(on)
                end
            end
            for styleKey, handle in pairs(cards) do
                local items = {}
                for i = 1, #MODULES do
                    local m = MODULES[i]
                    if Supports(m, styleKey) or m.get() == styleKey then
                        local function Off() return not Loaded(m) end
                        items[#items + 1] = { key = m.key, label = m.display, excludeFromSummaryFn = Off,
                            lockedFn = function() return Off() or PickOf(m) == styleKey end,
                            -- Only a disabled module explains itself; a checked one
                            -- just reads as fixed here.
                            lockedTooltip = function()
                                if not Off() then return nil end
                                return EllesmereUI.Lf("Enable %1$s to change its style.", EllesmereUI.L(m.enableName or m.display))
                            end }
                    end
                end
                local dd, ddRefresh = EllesmereUI.BuildVisOptsCBDropdown(
                    host, handle.card:GetWidth(), host:GetFrameLevel() + 3, items,
                    function(key) return PickOf(BY_KEY[key]) == styleKey end,
                    function(key, checked)
                        if checked then Pick(BY_KEY[key], styleKey) end
                    end,
                    RefreshPicks, 10, nil, nil, nil, { dimLocked = true })
                PP.Point(dd, "TOP", handle.card, "BOTTOM", 0, -DD_GAP)
                refreshers[#refreshers + 1] = ddRefresh
            end

            applyBtn = CreateFrame("Button", nil, host)
            applyBtn:SetFrameLevel(host:GetFrameLevel() + 3)
            PP.Size(applyBtn, BTN_W, BTN_H)
            PP.Point(applyBtn, "TOP", host, "TOP", 0, -BTN_TOP)
            EllesmereUI.MakeStyledButton(applyBtn, "Apply Styles", 16, EllesmereUI.WB_COLOURS, function()
                local changes = {}
                for i = 1, #MODULES do
                    local m = MODULES[i]
                    local s = pending[m.key]
                    if s and Loaded(m) and s ~= m.get() then
                        changes[#changes + 1] = { m = m, key = s }
                    end
                end
                PromptStyleChanges(changes)
            end)
            RefreshPicks()
            EllesmereUI.RegisterWidgetRefresh(RefreshPicks)
            host:HookScript("OnHide", function()
                if next(pending) then
                    wipe(pending)
                    RefreshPicks()
                end
            end)
        end
    end
    y = y - 20 - (hasHero and (HERO_H + 20) or 0)

    -- Framework contract: return the positive total content height.
    return math.abs(y)
end
'''


def main():
    raw = PATH.read_bytes()
    crlf = b"\r\n" in raw
    text = raw.decode("utf-8").replace("\r\n", "\n")
    i = text.index(START)
    text = text[:i] + NEW
    if crlf:
        text = text.replace("\n", "\r\n")
    PATH.write_bytes(text.encode("utf-8"))
    print("Style page builder replaced; CRLF" if crlf else "Style page builder replaced; LF")


if __name__ == "__main__":
    main()
