local ADDON,ns=...
local E=EllesmereUI
if not ns.addon or not ns.D then return end
local D=ns.D
-- Retail "Bar Glows": glow an action button while an aura is up (or missing).
ns.actionGlowButtons,ns.actionGlowMap={},{}
local want,mapAge={},0
function ns.NewBarGlowRule(auraID,spellID)
    return {enabled=true,auraID=auraID or 0,spellID=spellID or 0,unit="player",filter="HELPFUL",ownOnly=false,mode="active",onlyInCombat=false,atStacks=0,glowType=1,glowR=1,glowG=.82,glowB=.2}
end
function ns.PrepareActionGlows()
    if InCombatLockdown and InCombatLockdown() then return end
    local buttons={}
    ns.ForEachActionButton(function(button)
        if not button._eui335CdmGlow then
            local g=CreateFrame("Frame",nil,button); g:SetAllPoints(button); g:SetFrameLevel(button:GetFrameLevel()+5)
            button._eui335CdmGlow=g
        end
        buttons[#buttons+1]=button
    end)
    ns.actionGlowButtons=buttons
    ns.RefreshActionGlowMap()
end
function ns.RefreshActionGlowMap()
    local map={}
    for _,button in ipairs(ns.actionGlowButtons) do
        local slot=ns.ButtonSlot(button)
        local name=slot and (not HasAction or HasAction(slot)) and ns.ActionSpellName(slot)
        if name then local l=map[name]; if not l then l={}; map[name]=l end; l[#l+1]=button end
    end
    ns.actionGlowMap=map; mapAge=GetTime()
end
function ns.BarGlowActive(r,now)
    if r.enabled==false or (r.onlyInCombat and not ns.inCombat) then return false end
    local unit=r.unit or "player"
    if unit~="player" and not UnitExists(unit) then return false end
    local auraName=GetSpellInfo(tonumber(r.auraID) or 0); if not auraName then return false end
    local a=ns.FindAura(unit,r.filter=="HARMFUL" and "HARMFUL" or "HELPFUL",tonumber(r.auraID),auraName,nil,r.ownOnly,now)
    if r.mode=="missing" then return a==nil end
    return a~=nil and (a.count or 0)>=(tonumber(r.atStacks) or 0)
end
function ns.UpdateActionGlows(now)
    if now-mapAge>1 then ns.RefreshActionGlowMap() end
    wipe(want)
    local p=ns.Profile(); local lists=ns.Lists(); local cfg=lists and lists.barGlows
    if p and p.enabled and cfg and cfg.enabled and ns.auras then
        for _,r in ipairs(cfg.list or {}) do
            if ns.BarGlowActive(r,now) then
                local spellName=GetSpellInfo(tonumber(r.spellID) or 0)
                for _,button in ipairs(spellName and ns.actionGlowMap[spellName] or {}) do if not want[button] then want[button]=r end end
            end
        end
    end
    for _,button in ipairs(ns.actionGlowButtons) do
        local g=button._eui335CdmGlow; local r=want[button]
        if g then
            if r and button:IsVisible() then D.SetGlow(g,r.glowType or 1,button:GetWidth(),button:GetHeight(),r.glowR,r.glowG,r.glowB,nil,now)
            elseif g._cdmGlow or g.edges then D.SetGlow(g) end
        end
    end
end
