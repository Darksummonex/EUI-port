-- DBM / BigWigs bars under AbilityTimeline. While the timeline shows a boss
-- mod's timers, that mod's own bars become invisible and click-through rather
-- than hidden: hidden frames stop their OnUpdate, and DBM reads the time left
-- back from its bar objects. Nothing is written to DBM or BigWigs settings.
local ADDON_NAME,ns=...
if not ns.addon then return end
local TIMELINE_GLOBAL="AbilityTimeline335"
local weak={__mode="k"}
local B={hidden={dbm=false,bigwigs=false},hooked={},anchors={},mouse=setmetatable({},weak),
    bwSeen=setmetatable({},weak),bwParents=setmetatable({},weak)}
ns.bossBars=B
-- BigWigs re-shows bars with SetAlpha(1) when its visible-bar limit frees up,
-- so its bars move under a transparent parent instead of being faded.
local holder=CreateFrame("Frame",nil,UIParent)
holder:SetAllPoints(UIParent); holder:SetAlpha(0); holder:EnableMouse(false)
B.holder=holder

local function Timeline()
    local at=_G[TIMELINE_GLOBAL]
    if type(at)=="table" and type(at.db)=="table" then return at end
end
B.Timeline=Timeline
-- "dbm" / "bigwigs" name both the timeline's source toggle and its adapter state.
local function Active(source)
    local p=ns.GetSettings(); local at=Timeline()
    if not (p and p.enabled and p.hideBossModBars and at and at.db.enabled and at.db[source]~=false) then return false end
    return type(at.Sources)~="table" or at.Sources[source]~=nil
end
B.Active=Active

local function DBTObject()
    local dbt=_G.DBT
    if type(dbt)=="table" and type(dbt.bars)=="table" then return dbt end
end
-- Same rule DBT uses when it creates a bar frame.
local function DBTMouse(dbt)
    local clickThrough=type(dbt.Options)=="table" and dbt.Options.ClickThrough
    return (not clickThrough) or (dbt.movable and true) or false
end
-- Every non-dummy DBT bar frame is a child of DBT's small-bar anchor (large
-- bars only anchor to the large one), so fading that parent covers them all,
-- skin overlays included. Dummy bars for the DBM options preview sit on UIParent.
local function ApplyDBM(hide)
    local dbt=DBTObject(); if not dbt then return end
    if dbt.movable then hide=false end
    if hide then
        for bar in pairs(dbt.bars) do
            local f=type(bar)=="table" and not bar.dummy and bar.frame
            if type(f)=="table" and f.GetParent then
                local parent=f:GetParent()
                if parent and parent~=UIParent and B.anchors[parent]==nil then B.anchors[parent]=parent:GetAlpha() or 1; parent:SetAlpha(0) end
                if f:IsMouseEnabled() then f:EnableMouse(false) end
                B.mouse[f]=true
            end
        end
    else
        for parent,alpha in pairs(B.anchors) do parent:SetAlpha(alpha); B.anchors[parent]=nil end
        local on=DBTMouse(dbt)
        for f in pairs(B.mouse) do f:EnableMouse(on); B.mouse[f]=nil end
    end
    B.hidden.dbm=hide
end

local function IsBigWigsBar(bar)
    return type(bar)=="table" and type(bar.Get)=="function" and (bar:Get("bigwigs:module") or bar:Get("bigwigs:anchor")) and true or false
end
local function HideBigWigsBar(bar)
    local parent=bar:GetParent()
    if parent~=holder then B.bwParents[bar]=parent or UIParent; bar:SetParent(holder) end
end
local function TrackBigWigsBar(bar)
    if type(bar)~="table" or type(bar.SetParent)~="function" then return end
    B.bwSeen[bar]=true
    if B.hidden.bigwigs then HideBigWigsBar(bar) end
end
B.TrackBigWigsBar=TrackBigWigsBar
local function ApplyBigWigs(hide)
    B.hidden.bigwigs=hide
    if hide then
        for bar in pairs(B.bwSeen) do if bar.running then HideBigWigsBar(bar) end end
    else
        -- LibCandyBar moves stopped bars back to UIParent; only restore bars still parked here.
        for bar,parent in pairs(B.bwParents) do
            if bar:GetParent()==holder then bar:SetParent(parent) end
            B.bwParents[bar]=nil
        end
    end
end

local function HookTimeline()
    local at=Timeline()
    if B.hooked.refresh~=at and type(at.Refresh)=="function" then B.hooked.refresh=at; hooksecurefunc(at,"Refresh",function() B.Apply() end) end
    local src=at.Sources
    if type(src)=="table" and B.hooked.attach~=src and type(src.Attach)=="function" then B.hooked.attach=src; hooksecurefunc(src,"Attach",function() B.Apply() end) end
end
local function HookDBM()
    local dbt=DBTObject(); if not dbt or B.hooked.dbt==dbt then return end
    B.hooked.dbt=dbt
    if type(dbt.CreateBar)=="function" then
        hooksecurefunc(dbt,"CreateBar",function(_,_,_,_,_,_,_,isDummy) if not isDummy then B.Apply() end end)
    end
    -- SetOption covers ClickThrough; ShowMovableBar reveals the bars while they are being moved.
    for _,name in ipairs({"SetOption","ShowMovableBar"}) do
        if type(dbt[name])=="function" then hooksecurefunc(dbt,name,function() B.Apply() end) end
    end
end
-- Retail-style BigWigs announces bars by message; builds without those
-- messages are covered by LibCandyBar's shared Start, filtered to BigWigs bars.
local bwMessages={"BigWigs_BarCreated","BigWigs_BarEmphasized"}
local function OnBarMessage(_,_,bar) TrackBigWigsBar(bar) end
local function HookBigWigs()
    if not B.hooked.messages and (_G.BigWigsLoader or _G.BigWigs) then
        local loader=_G.BigWigsLoader
        if type(loader)=="table" and type(loader.RegisterMessage)=="function" then
            for _,msg in ipairs(bwMessages) do loader.RegisterMessage(B,msg,OnBarMessage) end
            B.hooked.messages="loader"
        else
            local ace=LibStub and LibStub("AceEvent-3.0",true)
            if ace then
                local receiver={}; ace:Embed(receiver)
                for _,msg in ipairs(bwMessages) do receiver:RegisterMessage(msg,OnBarMessage) end
                B.receiver=receiver; B.hooked.messages="aceevent"
            end
        end
    end
    local candy=LibStub and LibStub("LibCandyBar-3.0",true)
    local proto=type(candy)=="table" and candy.barPrototype
    if type(proto)=="table" and B.hooked.candy~=proto and type(proto.Start)=="function" then
        B.hooked.candy=proto
        hooksecurefunc(proto,"Start",function(bar) if IsBigWigsBar(bar) then TrackBigWigsBar(bar) end end)
    end
end

-- Combat-safe: only alpha, mouse and parents of non-secure boss mod frames change.
function B.Apply()
    if not Timeline() then return end
    HookTimeline(); HookDBM(); HookBigWigs()
    local dbm,bigwigs=Active("dbm"),Active("bigwigs")
    if dbm or B.hidden.dbm then ApplyDBM(dbm) end
    if bigwigs or B.hidden.bigwigs then ApplyBigWigs(bigwigs) end
end
ns.ApplyBossBars=B.Apply
function ns.BossBarsStatus()
    if not Timeline() then return "AbilityTimeline is not loaded" end
    local mods={}
    if B.hidden.dbm then mods[#mods+1]="DBM" end
    if B.hidden.bigwigs then mods[#mods+1]="BigWigs" end
    if #mods>0 then return "AbilityTimeline active: "..table.concat(mods," and ").." bars hidden" end
    return "AbilityTimeline loaded: no boss mod bars hidden"
end

-- The timeline, DBM and BigWigs (on demand) can load after QoL. Their own
-- ADDON_LOADED handlers may run after this one, so check again a frame later.
local events=CreateFrame("Frame"); B.events=events
events:RegisterEvent("ADDON_LOADED"); events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function(self) B.Apply(); self:Show() end)
events:SetScript("OnUpdate",function(self) self:Hide(); B.Apply() end)
events:Hide()
