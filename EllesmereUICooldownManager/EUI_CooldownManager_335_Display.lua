local ADDON,ns=...
local E=EllesmereUI
local white="Interface\\Buttons\\WHITE8X8"
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function Font(fs,size,flags)
    local path=E.GetFontPath and E.GetFontPath("cdm") or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    flags=flags or "OUTLINE"
    if flags=="GLOBAL" then flags=(E.GetFontOutlineFlag and E.GetFontOutlineFlag("cdm") or "OUTLINE"):gsub(",?%s*SLUG","") end
    if not fs:SetFont(path,size,flags) then fs:SetFont("Fonts\\FRIZQT__.TTF",size,"OUTLINE") end
    fs:SetShadowColor(0,0,0,1); fs:SetShadowOffset(1,-1)
end
local function Text(parent,size)
    local fs=parent:CreateFontString(nil,"OVERLAY"); Font(fs,size); fs:SetTextColor(1,1,1); return fs
end
local function Border(parent)
    local edges={}
    for i=1,4 do local t=parent:CreateTexture(nil,"OVERLAY"); t:SetTexture(white); edges[i]=t; t:Hide() end
    local top,bottom,left,right=unpack(edges)
    top:SetPoint("TOPLEFT",parent,"TOPLEFT",-1,1); top:SetPoint("TOPRIGHT",parent,"TOPRIGHT",1,1); top:SetHeight(2)
    bottom:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",-1,-1); bottom:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",1,-1); bottom:SetHeight(2)
    left:SetPoint("TOPLEFT",parent,"TOPLEFT",-1,1); left:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",-1,-1); left:SetWidth(2)
    right:SetPoint("TOPRIGHT",parent,"TOPRIGHT",1,1); right:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",1,-1); right:SetWidth(2)
    return edges
end
local function Glow(edges,active,now)
    local r,g,b=.047,.824,.616
    if E.GetAccentColor then r,g,b=E.GetAccentColor() end
    for _,t in ipairs(edges) do if active then t:SetVertexColor(r,g,b,.55+.4*math.sin(now*5)^2); t:Show() else t:Hide() end end
end
local function Tooltip(self)
    local state=self.state; if not state or not ns.Config(self.key).tooltip then return end
    local e,m=state.entry,state.meta; GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    if m.kind=="spell" and GameTooltip.SetSpell then GameTooltip:SetSpell(m.slot,m.book)
    elseif m.kind=="slot" and GameTooltip.SetInventoryItem then GameTooltip:SetInventoryItem("player",m.slot)
    elseif m.kind=="item" then GameTooltip:SetHyperlink("item:"..m.id)
    elseif state.aura and GameTooltip.SetUnitAura then GameTooltip:SetUnitAura(e.unit or "player",state.aura.index,e.filter or "HELPFUL")
    else GameTooltip:AddLine(m.name) end
    GameTooltip:Show()
end
local function HideTooltip(self) if GameTooltip.GetOwner and GameTooltip:GetOwner()==self then GameTooltip:Hide() end end
local function NewIcon(parent,key,tracking)
    local b=CreateFrame("Button",nil,parent); b.key=key
    b:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); b:SetBackdropColor(.035,.045,.05,.9); b:SetBackdropBorderColor(0,0,0,1)
    b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetTexCoord(.08,.92,.08,.92)
    if tracking then
        b.bar=CreateFrame("StatusBar",nil,b); b.bar:SetStatusBarTexture(white); b.bar:SetMinMaxValues(0,1)
        b.host=CreateFrame("Frame",nil,b); b.host:SetAllPoints(b); b.host:SetFrameLevel(b.bar:GetFrameLevel()+2)
        b.name=Text(b.host,11); b.name:SetJustifyH("LEFT"); b.name:SetPoint("LEFT",b.host,"LEFT",28,0)
    else
        b.icon:SetPoint("TOPLEFT",b,"TOPLEFT",1,-1); b.icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1)
        b.cooldown=CreateFrame("Cooldown",nil,b); b.cooldown:SetAllPoints(b.icon); b.cooldown.noCooldownCount=true
        b.host=CreateFrame("Frame",nil,b); b.host:SetAllPoints(b); b.host:SetFrameLevel(b.cooldown:GetFrameLevel()+2)
    end
    b.timer=Text(b.host,12); b.timer:SetPoint(tracking and "RIGHT" or "CENTER",b.host,tracking and "RIGHT" or "CENTER",tracking and -5 or 0,0)
    b.count=Text(b.host,11); b.count:SetPoint("BOTTOMRIGHT",b.host,"BOTTOMRIGHT",-2,2)
    b.keybind=Text(b.host,9); b.keybind:SetPoint("TOPLEFT",b.host,"TOPLEFT",2,-2)
    b.glow=Border(b.host)
    b:SetScript("OnEnter",Tooltip); b:SetScript("OnLeave",HideTooltip); b:SetScript("OnHide",HideTooltip)
    b:SetScript("OnClick",function(self)
        if not self.state then return end
        ns.selectedBar=self.key; ns.selectedEntry=self.state.entry
        if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end
        if E.ShowModule then E:ShowModule(ADDON) end
    end)
    b:Hide(); return b
end
local function Position(key,index)
    local f=ns.frames[key]; local p=ns.Profile().positions[key]
    f:ClearAllPoints()
    if p then f:SetPoint(p.point or "CENTER",UIParent,p.relPoint or p.point or "CENTER",p.x or 0,p.y or 0)
    else f:SetPoint("BOTTOM",UIParent,"BOTTOM",key=="tracking" and 340 or 0,300+(index-1)*64) end
end
function ns.CreateGroups()
    local elements={}
    for index,key in ipairs(ns.order) do
        local k=key; local cfg=ns.Config(k)
        local f=CreateFrame("Frame","EUI335Cooldown_"..k,UIParent); f:SetFrameStrata("MEDIUM"); f:SetClampedToScreen(true); f:SetMovable(true)
        f.pool,f.visible={},{}; f:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1})
        f.label=Text(f,11); f.label:SetPoint("BOTTOMLEFT",f,"TOPLEFT",0,3)
        for i=1,40 do f.pool[i]=NewIcon(f,k,k=="tracking") end
        f:EnableMouse(true); f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart",function() if ns.preview then f:StartMoving() end end)
        f:SetScript("OnDragStop",function()
            f:StopMovingOrSizing(); local x,y=f:GetCenter(); local ux,uy=UIParent:GetCenter(); local scale=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
            ns.Profile().positions[k]={point="CENTER",relPoint="CENTER",x=x*scale-ux,y=y*scale-uy}
        end)
        ns.frames[k]=f
        if E.MakeUnlockElement then elements[#elements+1]=E.MakeUnlockElement({key="CDM_"..k,label=cfg.name,group="Cooldown Manager",order=300+index,noResize=true,
            getFrame=function() return ns.frames[k] end,getSize=function() return f:GetWidth(),f:GetHeight() end,
            isHidden=function() return not ns.Profile().enabled or not ns.Config(k).enabled end,
            savePos=function(_,point,relPoint,x,y) ns.Profile().positions[k]={point=point,relPoint=relPoint,x=x,y=y} end,
            loadPos=function() return ns.Profile().positions[k] end,clearPos=function() ns.Profile().positions[k]=nil end,
            applyPos=function() Position(k,index) end}) end
        E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}; E._ELEMENT_SETTINGS_MAP["CDM_"..k]={module=ADDON,page="CDM Bars",sectionName="BAR SETTINGS",highlightText="Select Bar"}
    end
    if E.RegisterUnlockElements then E:RegisterUnlockElements(elements,ADDON) end
end
function ns.Layout()
    for index,key in ipairs(ns.order) do
        local cfg,f=ns.Config(key),ns.frames[key]; if f then
            cfg.iconSize=ns.Clamp(cfg.iconSize,16,80); cfg.columns=ns.Clamp(cfg.columns,1,40); cfg.spacing=ns.Clamp(cfg.spacing,0,20)
            f:SetScale(ns.Clamp(cfg.scale,.5,2)); f:SetAlpha(ns.Clamp(cfg.alpha,0,1)); f.label:SetText(cfg.name)
            f:SetBackdropColor(.03,.04,.05,ns.preview and .5 or 0); f:SetBackdropBorderColor(0,0,0,ns.preview and 1 or 0)
            Position(key,index)
            for _,b in ipairs(f.pool) do
                local size=key=="tracking" and ns.Clamp(cfg.height,16,40) or cfg.iconSize
                Size(b,key=="tracking" and ns.Clamp(cfg.width,120,600) or size,size)
                b:SetBackdropColor(.03,.04,.05,ns.Clamp(cfg.bgAlpha,0,1))
                Font(b.timer,cfg.textSize or 12,cfg.fontOutline); Font(b.count,cfg.textSize or 11,cfg.fontOutline); Font(b.keybind,9,cfg.fontOutline)
                if b.bar then
                    Size(b.icon,size-2,size-2); b.icon:SetPoint("LEFT",b,"LEFT",1,0)
                    b.bar:SetPoint("TOPLEFT",b,"TOPLEFT",size+1,-1); b.bar:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-1,1)
                    b.name:ClearAllPoints(); b.name:SetPoint("LEFT",b.host,"LEFT",size+5,0); b.name:SetWidth(b:GetWidth()-size-65); b.name:SetHeight(size)
                    Font(b.name,cfg.textSize or 11,cfg.fontOutline)
                end
            end
        end
    end
end
local function TimeText(t)
    if t<=0 then return "" elseif t<3 then return string.format("%.1f",t) elseif t<60 then return tostring(math.ceil(t)) elseif t<3600 then return math.ceil(t/60).."m" end
    return math.ceil(t/3600).."h"
end
function ns.PaintGroup(key,now)
    local p,cfg,f=ns.Profile(),ns.Config(key),ns.frames[key]; if not f then return end
    local combat=InCombatLockdown()
    local allowed=p.enabled and p.cdmBars.enabled and cfg.enabled and (ns.preview or cfg.visibility=="always" or cfg.visibility=="combat" and combat or cfg.visibility=="target" and UnitExists("target"))
    if not allowed then f:Hide(); return end
    local visible=f.visible; for i=#visible,1,-1 do visible[i]=nil end
    for _,state in ipairs(ns.compiled[key] or {}) do
        local aura=state.meta.kind=="aura"
        local show=cfg.show=="always" or cfg.show=="active" and state.active or cfg.show=="cooldown" and not aura and state.active or cfg.show=="ready" and not aura and not state.active and state.usable
        if ns.preview or show then visible[#visible+1]=state end
    end
    if cfg.sort=="remaining" then table.sort(visible,function(a,b) if a.remaining==b.remaining then return a.meta.name<b.meta.name end; return a.remaining>b.remaining end) end
    local count=math.min(40,#visible); local tracking=key=="tracking"
    local columns=tracking and 1 or math.min(cfg.columns,math.max(1,count)); local rows=math.max(1,math.ceil(count/columns))
    local w=tracking and ns.Clamp(cfg.width,120,600) or cfg.iconSize; local h=tracking and ns.Clamp(cfg.height,16,40) or cfg.iconSize
    Size(f,columns*(w+cfg.spacing)-cfg.spacing,rows*(h+cfg.spacing)-cfg.spacing)
    if ns.preview then f.label:Show(); f:SetBackdropColor(.03,.04,.05,.5) else f.label:Hide(); f:SetBackdropColor(0,0,0,0) end
    if count==0 and not ns.preview then f:Hide() else f:Show() end
    local placeholder=ns.preview and count==0
    if placeholder then count=tracking and 1 or 3; Size(f,count*(w+cfg.spacing)-cfg.spacing,h); columns=count end
    for i,b in ipairs(f.pool) do
        local state=visible[i]; b.state=state
        if i<=count then
            local col,row=(i-1)%columns,math.floor((i-1)/columns)
            b:ClearAllPoints()
            if cfg.growDirection=="LEFT" then b:SetPoint("TOPRIGHT",f,"TOPRIGHT",-col*(w+cfg.spacing),-row*(h+cfg.spacing))
            elseif cfg.growDirection=="UP" then b:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",col*(w+cfg.spacing),row*(h+cfg.spacing))
            else b:SetPoint("TOPLEFT",f,"TOPLEFT",col*(w+cfg.spacing),-row*(h+cfg.spacing)) end
            b.icon:SetTexture(state and (state.aura and state.aura.icon or state.meta.icon) or "Interface\\Icons\\INV_Misc_QuestionMark")
            local grey=state and (state.meta.kind=="aura" and not state.active or state.meta.kind~="aura" and (state.active or not state.usable))
            b.icon:SetDesaturated(not not grey); b.icon:SetVertexColor(1,1,1,1)
            if state and cfg.showRange and state.meta.kind=="spell" and UnitExists("target") and IsSpellInRange and IsSpellInRange(state.meta.name,"target")==0 then b.icon:SetVertexColor(1,.25,.25,1) end
            local remaining=state and state.remaining or 0
            if b.cooldown then
                if state and state.duration>0 and remaining>0 then
                    if b.lastStart~=state.start or b.lastDuration~=state.duration then b.cooldown:SetCooldown(state.start,state.duration); b.lastStart,b.lastDuration=state.start,state.duration end
                    b.cooldown:Show()
                else b.cooldown:Hide(); b.lastStart,b.lastDuration=nil,nil end
            end
            local text=cfg.showText and TimeText(remaining) or ""; if b.timer:GetText()~=text then b.timer:SetText(text) end
            b.count:SetText(cfg.showStacks and state and state.count>1 and tostring(state.count) or "")
            b.keybind:SetText(cfg.showKeybind and state and state.keybind or "")
            if b.bar then
                local duration=state and state.duration or 0; b.bar:SetMinMaxValues(0,math.max(1,duration)); b.bar:SetValue(duration>0 and remaining or state and state.active and 1 or 0)
                local r,g,blue=.047,.824,.616; if E.GetAccentColor then r,g,blue=E.GetAccentColor() end; b.bar:SetStatusBarColor(r,g,blue,.8)
                b.name:SetText(state and state.meta.name or "Tracking Bar")
            end
            local glow=state and (cfg.glow=="active" and state.meta.kind=="aura" and state.active or cfg.glow=="ready" and state.meta.kind~="aura" and state.usable and not state.active or cfg.glow=="cooldown" and state.meta.kind~="aura" and state.active)
            Glow(b.glow,glow and (not p.glowsOnlyInCombat or combat),now); b:Show()
        else b:Hide(); Glow(b.glow,false,now) end
    end
end
local function Action(button)
    local kind,id
    if button.GetAction then kind,id=button:GetAction() else kind,id="action",button.action end
    if kind=="action" and id and GetActionInfo then return GetActionInfo(id) end
    return kind,id
end
function ns.PrepareActionGlows()
    local ab=E._ModuleNS.EllesmereUIActionBars
    for _,bar in pairs(ab and ab.bars or {}) do
        for _,button in ipairs(bar.buttons or {}) do if not ns.actionGlows[button] then ns.actionGlows[button]=Border(button) end end
    end
end
function ns.UpdateActionGlows(now)
    local p=ns.Profile(); local highlights={}; local ab=E._ModuleNS.EllesmereUIActionBars
    local bindings={}
    for _,bar in pairs(ab and ab.bars or {}) do for _,button in ipairs(bar.buttons or {}) do
        local kind,id=Action(button)
        if kind=="spell" then
            local name=GetSpellInfo(id)
            local key=button.config and button.config.keyBoundTarget and GetBindingKey and GetBindingKey(button.config.keyBoundTarget)
            key=key or button.bindingAction and GetBindingKey and GetBindingKey(button.bindingAction)
            if name and key then bindings[name]=key end
        end
    end end
    for _,entries in pairs(ns.compiled) do for _,state in ipairs(entries) do
        state.keybind=bindings[state.meta.name] or (GetBindingKey and GetBindingKey("SPELL "..state.meta.name))
        if state.entry.highlightSpellID and state.meta.kind=="aura" and state.active then
            local name=GetSpellInfo(state.entry.highlightSpellID); if name then highlights[name]=true end
        end
    end end
    for button,edges in pairs(ns.actionGlows) do
        local kind,id=Action(button); local name=kind=="spell" and GetSpellInfo(id)
        Glow(edges,p.enabled and p.cdmBars.enabled and p.actionBarGlows and (not p.glowsOnlyInCombat or InCombatLockdown()) and name and highlights[name],now)
    end
end
E.GetCDMBarFrame=function(key) return ns.frames[key] end
E.LayoutCDMBar=function() ns.Layout(); ns.Update() end
EllesmereUICDM=ns
SLASH_EUI335CDM1="/ecdm"
SlashCmdList.EUI335CDM=function(message)
    if message=="show" then ns.Profile().enabled=true; ns.Apply()
    elseif message=="hide" then ns.Profile().enabled=false; ns.Apply()
    else if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; if E.ShowModule then E:ShowModule(ADDON) end end
end
