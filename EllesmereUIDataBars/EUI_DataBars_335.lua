-- Wrath multi-bar engine. Retail sources are retained as unloaded references.
local ADDON,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
E._ModuleNS[ADDON]=ns
local addon=E.Lite.NewAddon(ADDON)
ns.addon,ns.WB,ns.IsWrath=addon,addon,true
local white="Interface\\Buttons\\WHITE8X8"
ns.live,ns.registered={},{}
local defaults={profile={enabled=true,initialized=false,nextBarId=0,bars={}}}
ns.defaults=defaults
ns.BLOCK_TYPES={
    {key="clock",label="Clock"},{key="fps",label="FPS"},{key="ms",label="Latency"},
    {key="location",label="Location"},{key="coords",label="Coordinates"},{key="gold",label="Gold"},
    {key="bags",label="Bags"},{key="durability",label="Durability"},{key="combat",label="Combat Status"},
    {key="xprep",label="XP / Reputation"},{key="spec",label="Talent Specialization"},
    {key="profession",label="Professions"},{key="profession2",label="Secondary Professions"},
    {key="travel",label="Hearthstone"},{key="micromenu",label="Micro Menu"},
    {key="currency",label="Currency"},{key="ilvl",label="Item Level"},{key="audio",label="Audio"},
    {key="ldb",label="EUI Inventory Broker"},{key="spacer",label="Spacer"},
}
ns.BLOCK_DEFAULTS={clock={localTime=true,twentyFour=true},fps={},ms={},location={showSubZone=true},
    coords={precision=1,hideInInstance=true},gold={},bags={value="free"},durability={},combat={},
    xprep={mode="auto"},spec={},profession={},profession2={},travel={},micromenu={},
    currency={currencyKey=""},ilvl={precision=0},audio={channel="Master"},ldb={},spacer={}}
function ns.Copy(value)
    if type(value)~="table" then return value end
    local out={}; for k,v in pairs(value) do out[k]=ns.Copy(v) end; return out
end
function ns.Clamp(v,low,high) return math.max(low,math.min(high,tonumber(v) or low)) end
function ns.Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
function ns.Font(fs,size)
    local path=(E.GetFontPath and E.GetFontPath("dataBars")) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    local flags=((E.GetFontOutlineFlag and E.GetFontOutlineFlag("dataBars")) or "OUTLINE"):gsub(",?%s*SLUG","")
    if not fs:SetFont(path,size,flags) then fs:SetFont("Fonts\\FRIZQT__.TTF",size,"OUTLINE") end
end
function ns.GetProfile() return addon.db and addon.db.profile end
function ns.BarsInOrder() local p=ns.GetProfile(); return p and p.bars or {} end
function ns.GetBar(id) for _,cfg in ipairs(ns.BarsInOrder()) do if cfg.id==id then return cfg end end end
function ns.GetBlock(id,blockID)
    local cfg=ns.GetBar(id); if not cfg then return end
    for i,b in ipairs(cfg.blocks) do if b.id==blockID then return b,i end end
end
local templates={
    bottom={name="Bottom Info Bar",length=1000,thickness=30,lengthMode="full",point="BOTTOM",x=0,y=0,
        blocks={"spec","durability","clock","gold","fps","ms","travel"}},
    minimapc={name="Minimap Companion",length=240,thickness=26,point="TOPRIGHT",x=-5,y=-240,blocks={"clock","fps","ms"}},
    microstrip={name="Micro Menu Strip",length=450,thickness=30,point="BOTTOMRIGHT",x=-5,y=5,blocks={"micromenu"}},
    empty={name="New DataBar",length=420,thickness=30,point="CENTER",x=0,y=0,blocks={}},
}
function ns.CreateBar(template)
    if InCombatLockdown() then return end
    local p=ns.GetProfile(); if not p then return end
    local t=templates[template] or templates.empty
    p.nextBarId=p.nextBarId+1
    local cfg={id=p.nextBarId,name=t.name,enabled=true,orientation="H",lengthMode=t.lengthMode or "custom",
        length=t.length,thickness=t.thickness,scale=1,fontSize=11,fontScale=100,sizingMode="even",spacing=2,
        theme="eui",bgAlpha=.92,hideBorder=false,visibility="always",nextBlockId=0,blocks={},
        savedPos={point=t.point,relPoint=t.point,x=t.x,y=t.y}}
    p.bars[#p.bars+1]=cfg; ns.selectedBarId=cfg.id
    for _,key in ipairs(t.blocks) do
        cfg.nextBlockId=cfg.nextBlockId+1
        cfg.blocks[#cfg.blocks+1]={id=cfg.nextBlockId,type=key,settings=ns.Copy(ns.BLOCK_DEFAULTS[key]),width=100}
    end
    ns.Apply(); return cfg
end
function ns.DeleteBar(id)
    if InCombatLockdown() then return end
    local p=ns.GetProfile(); if not p then return end
    for i,cfg in ipairs(p.bars) do if cfg.id==id then table.remove(p.bars,i); break end end
    local first=p.bars[1]; ns.selectedBarId=first and first.id; ns.Apply()
end
function ns.RenameBar(id,name) local c=ns.GetBar(id); if c and type(name)=="string" and name:find("%S") then c.name=name; ns.Apply() end end
function ns.AddBlock(id,key)
    if InCombatLockdown() or not ns.BLOCK_DEFAULTS[key] then return end
    local cfg=ns.GetBar(id); if not cfg then return end
    cfg.nextBlockId=cfg.nextBlockId+1
    local b={id=cfg.nextBlockId,type=key,settings=ns.Copy(ns.BLOCK_DEFAULTS[key]),width=100}
    cfg.blocks[#cfg.blocks+1]=b; ns.Apply(); return b
end
function ns.RemoveBlock(id,blockID)
    if InCombatLockdown() then return end
    local b,index=ns.GetBlock(id,blockID); if b then table.remove(ns.GetBar(id).blocks,index); ns.Apply() end
end
function ns.MoveBlock(id,blockID,delta)
    if InCombatLockdown() then return end
    local cfg=ns.GetBar(id); local b,index=ns.GetBlock(id,blockID)
    local to=index and index+delta
    if b and to>=1 and to<=#cfg.blocks then cfg.blocks[index],cfg.blocks[to]=cfg.blocks[to],cfg.blocks[index]; ns.Apply() end
end
-- Never rotate StatusBar textures on this legacy client (native crash path).
function ns.SolveLayout(cfg,length,measure)
    local segments,n={},#cfg.blocks; if n==0 then return segments end
    local gap=ns.Clamp(cfg.spacing or 2,0,20)
    gap=math.min(gap,length/math.max(1,n-1))
    local available=math.max(0,length-gap*(n-1)); local weights,sum={},0
    for i,b in ipairs(cfg.blocks) do
        weights[i]=cfg.sizingMode=="even" and 1 or math.max(1,(measure and measure(b)) or tonumber(b.width) or 100)
        sum=sum+weights[i]
    end
    local offset=0
    for i,b in ipairs(cfg.blocks) do
        local size=available*weights[i]/sum
        segments[i]={id=b.id,offset=offset,length=size}; offset=offset+size+gap
    end
    return segments
end
function ns.Visible(cfg)
    local p=ns.GetProfile(); if not p or not p.enabled or not cfg.enabled then return false end
    if ns.preview then return true end
    if cfg.visibility=="combat" then return InCombatLockdown() end
    if cfg.visibility=="outofcombat" then return not InCombatLockdown() end
    if cfg.visibility=="group" then return GetNumRaidMembers()>0 or GetNumPartyMembers()>0 end
    return true
end
local function Position(cfg,f)
    local p=cfg.savedPos or {point="CENTER",relPoint="CENTER",x=0,y=0}
    f:ClearAllPoints(); f:SetPoint(p.point,UIParent,p.relPoint,p.x or 0,p.y or 0)
end
local function Register(cfg)
    if ns.registered[cfg.id] then ns.registered[cfg.id].label=cfg.name; return end
    if not E.RegisterUnlockElements or not E.MakeUnlockElement then return end
    local id=cfg.id
    local elem=E.MakeUnlockElement({key="EDB_"..id,label=cfg.name,group="Data Bars",order=900+id,noResize=true,noAnchorTo=true,
        getFrame=function() local r=ns.live[id]; return r and r.frame end,
        getSize=function() local r=ns.live[id]; return r and r.frame:GetWidth() or 400,r and r.frame:GetHeight() or 30 end,
        isHidden=function() local c=ns.GetBar(id); return not c or not ns.GetProfile().enabled or not c.enabled end,
        savePos=function(_,point,relPoint,x,y) local c=ns.GetBar(id); if c then c.savedPos={point=point,relPoint=relPoint,x=x,y=y} end end,
        loadPos=function() local c=ns.GetBar(id); return c and c.savedPos end,
        clearPos=function() local c=ns.GetBar(id); if c then c.savedPos=nil end end,
        applyPos=function() local c,r=ns.GetBar(id),ns.live[id]; if c and r and not InCombatLockdown() then Position(c,r.frame) end end})
    -- The registry adds new keys while retaining earlier bars and their tombstones.
    ns.registered[id]=elem; E:RegisterUnlockElements({elem},ADDON)
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    E._ELEMENT_SETTINGS_MAP["EDB_"..id]={module=ADDON,page="DataBars",sectionName="BAR SETTINGS",highlightText="Select Bar"}
end
function ns.ApplyBar(id)
    if InCombatLockdown() then ns.pending=true; return end
    local cfg=ns.GetBar(id); if not cfg then return end
    local rec=ns.live[id]
    if not rec then rec={frame=CreateFrame("Frame","EUI335DataBar_"..id,UIParent,"SecureHandlerStateTemplate"),slots={}}; ns.live[id]=rec end
    local f=rec.frame; f:SetFrameStrata("LOW"); f:SetClampedToScreen(true)
    local length=cfg.lengthMode=="full" and (cfg.orientation=="V" and UIParent:GetHeight() or UIParent:GetWidth())/ns.Clamp(cfg.scale,.5,2) or ns.Clamp(cfg.length,120,2500)
    local thickness=ns.Clamp(cfg.thickness,20,100)
    ns.Size(f,cfg.orientation=="V" and thickness or length,cfg.orientation=="V" and length or thickness)
    f:SetScale(ns.Clamp(cfg.scale,.5,2)); Position(cfg,f)
    f:SetBackdrop({bgFile=white,edgeFile=not cfg.hideBorder and white or nil,edgeSize=1})
    f:SetBackdropColor(.025,.035,.045,ns.Clamp(cfg.bgAlpha,0,1))
    if cfg.theme=="eui" then f:SetBackdropBorderColor(.047,.824,.616,.8) else f:SetBackdropBorderColor(.2,.2,.2,1) end
    local lengthInner=math.max(1,length-8); local segments=ns.SolveLayout(cfg,lengthInner)
    local active={}
    for i,b in ipairs(cfg.blocks) do
        active[b.id]=true
        local slot=rec.slots[b.id]
        if slot and slot.block.type~=b.type then slot:Hide(); slot=nil end
        if not slot then slot=ns.MakeBlock(f,b,id); rec.slots[b.id]=slot end
        slot:ClearAllPoints()
        if cfg.orientation=="V" then ns.Size(slot,math.max(1,thickness-8),math.max(1,segments[i].length)); slot:SetPoint("TOPLEFT",f,"TOPLEFT",4,-4-segments[i].offset)
        else ns.Size(slot,math.max(1,segments[i].length),math.max(1,thickness-8)); slot:SetPoint("TOPLEFT",f,"TOPLEFT",4+segments[i].offset,-4) end
        ns.Font(slot.text,ns.Clamp((cfg.fontSize or 11)*(cfg.fontScale or 100)/100,8,24))
        slot.text:SetTextColor(1,1,1,1); slot.text:SetWidth(math.max(1,slot:GetWidth()-6))
        if slot.secure then slot.secure:SetAllPoints(slot) end
        ns.UpdateBlock(slot,b,cfg); slot:Show()
    end
    for blockID,slot in pairs(rec.slots) do if not active[blockID] then slot:Hide() end end
    local p=ns.GetProfile()
    local driver="show"
    if not p.enabled or not cfg.enabled then driver="hide"
    elseif not ns.preview then
        if cfg.visibility=="combat" then driver="[combat] show; hide"
        elseif cfg.visibility=="outofcombat" then driver="[combat] hide; show"
        elseif cfg.visibility=="group" then driver="[group] show; hide" end
    end
    RegisterStateDriver(f,"visibility",driver)
    Register(cfg)
end
function ns.ProgressUsed(key)
    for _,cfg in ipairs(ns.BarsInOrder()) do if ns.Visible(cfg) then for _,b in ipairs(cfg.blocks) do
        if b.type=="xprep" then
            local mode=b.settings.mode or "auto"
            if mode=="auto" then mode=UnitLevel("player")<(MAX_PLAYER_LEVEL or 80) and "xp" or "reputation" end
            if key==mode then return true end
        end
    end end end
    return false
end
function ns.Update()
    for _,cfg in ipairs(ns.BarsInOrder()) do
        local rec=ns.live[cfg.id]
        if rec then
            -- Frames containing secure hearthstone children cannot be hidden in combat.
            if not InCombatLockdown() then if ns.Visible(cfg) then rec.frame:Show() else rec.frame:Hide() end end
            for _,b in ipairs(cfg.blocks) do local slot=rec.slots[b.id]; if slot then ns.UpdateBlock(slot,b,cfg) end end
        end
    end
end
function ns.Apply()
    if not ns.GetProfile() then return end
    if InCombatLockdown() then ns.pending=true; return end
    local profile=ns.GetProfile()
    if not profile.initialized then profile.initialized=true; ns.CreateBar("bottom"); return end
    ns.pending=false; local active={}
    for _,cfg in ipairs(ns.BarsInOrder()) do active[cfg.id]=true; ns.ApplyBar(cfg.id) end
    for id,rec in pairs(ns.live) do if not active[id] then RegisterStateDriver(rec.frame,"visibility","hide") end end
    local ab=E._ModuleNS.EllesmereUIActionBars
    if ab and ab.NativeHUD then ab.NativeHUD.UpdateData() end
end
ns.ApplyTheme,ns.RequestLayout=ns.ApplyBar,ns.ApplyBar
_G._EDB_Apply=ns.Apply
_G._EDB_RegisterUnlock=ns.Apply
function addon:OnInitialize()
    -- Lua 5.1 xpcall in the Core lifecycle does not forward its addon argument.
    addon.db=E.Lite.NewDB("EllesmereUIDataBarsDB",defaults); ns.db=addon.db
end
function addon:OnEnable()
    ns.Apply()
    local f=CreateFrame("Frame"); ns.events=f
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_MONEY","BAG_UPDATE","PLAYER_XP_UPDATE","PLAYER_LEVEL_UP","UPDATE_EXHAUSTION",
        "UPDATE_FACTION","CURRENCY_DISPLAY_UPDATE","PLAYER_EQUIPMENT_CHANGED","UPDATE_INVENTORY_ALERTS","PLAYER_TALENT_UPDATE",
        "ACTIVE_TALENT_GROUP_CHANGED","SKILL_LINES_CHANGED","ZONE_CHANGED","ZONE_CHANGED_NEW_AREA","MAIL_INBOX_UPDATE",
        "PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","DISPLAY_SIZE_CHANGED"}) do f:RegisterEvent(event) end
    f:SetScript("OnEvent",function(_,event)
        if event=="PLAYER_REGEN_DISABLED" then return end
        if ns.pending or event=="PLAYER_REGEN_ENABLED" or event=="DISPLAY_SIZE_CHANGED" then ns.Apply() else ns.Update() end
    end)
    local elapsed=0
    f:SetScript("OnUpdate",function(_,dt) elapsed=elapsed+dt; if elapsed<1 then return end; elapsed=0; ns.Update() end)
    if E.RegisterUnlockModeListener then E:RegisterUnlockModeListener(ADDON,function(active) ns.preview=active; ns.Apply() end) end
end
SLASH_EUI335DATABARS1="/edb"
SlashCmdList.EUI335DATABARS=function() if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; E:ShowModule(ADDON) end
