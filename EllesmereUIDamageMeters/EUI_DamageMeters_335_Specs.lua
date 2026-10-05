-- Own native talent collection. No external addon cache or inspection library.
local _,ns=...
ns.specs,ns.specAttempts={},{}
local classCoords={
 WARRIOR={0,.25,0,.25},MAGE={.25,.5,0,.25},ROGUE={.5,.75,0,.25},DRUID={.75,1,0,.25},
 HUNTER={0,.25,.25,.5},SHAMAN={.25,.5,.25,.5},PRIEST={.5,.75,.25,.5},WARLOCK={.75,1,.25,.5},
 PALADIN={0,.25,.5,.75},DEATHKNIGHT={.25,.5,.5,.75},
}
local function Talents(inspect)
    if not GetTalentTabInfo then return end
    local group=1
    if GetActiveTalentGroup then local ok,g=pcall(GetActiveTalentGroup,inspect); if ok and g then group=g end end
    local best,points=nil,0
    for tab=1,3 do
        local ok,name,icon,spent=pcall(GetTalentTabInfo,tab,inspect,false,group)
        if not ok or not name or type(spent)~="number" then return end
        if icon and spent>points then best={name=name,icon=icon,tab=tab}; points=spent end
    end
    return best
end
function ns.StoreSpec(guid,spec)
    if not guid then return end
    ns.specs[guid]={name=spec and spec.name,icon=spec and spec.icon,at=GetTime()}
    local function Stamp(segment,overwrite)
        local a=segment and segment.actors[guid]
        if a and (overwrite or not a.specIcon) then a.specIcon=spec and spec.icon; a.specName=spec and spec.name end
    end
    Stamp(ns.current,true)
    -- Backfill previously unknown actors without changing known old specs.
    if ns.history then
        Stamp(ns.history.overall,false)
        for _,segment in ipairs(ns.history.segments) do Stamp(segment,false) end
    end
end
function ns.RefreshPlayerSpec() ns.StoreSpec(UnitGUID("player"),Talents(false)) end
function ns.RowIcon(row)
    if row.specIcon then return row.specIcon,nil,row.specName end
    local spec=ns.specs[row.guid]
    if spec and spec.icon then return spec.icon,nil,spec.name end
    local coords=classCoords[row.class]
    if coords then return "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",coords end
end
function ns.InitializeSpecs()
    if ns.specHooks or not hooksecurefunc or not NotifyInspect then return end
    ns.specHooks=true
    hooksecurefunc("NotifyInspect",function(unit)
        ns.lastInspectGUID=UnitGUID(unit); ns.nextSpecInspect=GetTime()+5
        if not ns.requestingSpec then ns.pendingSpec=nil end
    end)
    if ClearInspectPlayer then hooksecurefunc("ClearInspectPlayer",function() ns.pendingSpec=nil; ns.lastInspectGUID=nil end) end
end
function ns.InspectSpecReady(guid)
    local pending=ns.pendingSpec
    if not pending or guid and guid~=pending.guid then return end
    ns.pendingSpec=nil
    if UnitGUID(pending.unit)~=pending.guid or ns.lastInspectGUID~=pending.guid then return end
    if InspectFrame and InspectFrame:IsShown() then return end
    local spec=Talents(true)
    -- Empty/incomplete data is not a specialization; leave the class fallback.
    if spec then ns.StoreSpec(pending.guid,spec) end
end
function ns.UpdateSpecs()
    local now=GetTime()
    if ns.pendingSpec then
        if now-ns.pendingSpec.at>8 then ns.pendingSpec=nil else return end
    end
    local p=ns.Profile()
    if not p or not p.enabled or InCombatLockdown() or not ns.specHooks or not CanInspect then return end
    if now<(ns.nextSpecInspect or 0) or InspectFrame and InspectFrame:IsShown() then return end
    local needed=false
    for _,cfg in ipairs(p.windows) do if cfg.enabled and cfg.showSpecIcons~=false then needed=true; break end end
    if not needed then return end
    ns.nextSpecInspect=now+5
    for _,unit in ipairs(ns.units or {}) do
        local guid=UnitGUID(unit); local spec=guid and ns.specs[guid]
        if guid and guid~=UnitGUID("player") and (not spec or now-spec.at>600)
            and now-(ns.specAttempts[guid] or -30)>=30 then
            local ok,can=pcall(CanInspect,unit)
            if ok and can and (not UnitIsVisible or UnitIsVisible(unit)) then
                ns.specAttempts[guid]=now; ns.pendingSpec={guid=guid,unit=unit,at=now}
                ns.requestingSpec=true; local sent=pcall(NotifyInspect,unit); ns.requestingSpec=nil
                if not sent then ns.pendingSpec=nil end
                return
            end
        end
    end
end
