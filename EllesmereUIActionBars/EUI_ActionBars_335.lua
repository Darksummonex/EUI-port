-- Native Wrath action bars. The Retail implementation remains an unloaded reference.
local ADDON_NAME, ns = ...
local E = EllesmereUI
if not E or not E.Lite then return end
local LAB = LibStub("LibActionButton-1.0-Ellesmere335")
local addon = E.Lite.NewAddon(ADDON_NAME)
ns.EAB, ns.addon, ns.IsWrath = addon, addon, true
E._ModuleNS[ADDON_NAME] = ns
local definitions = {
    {key="bar1",label="Action Bar 1",page=1,binding="ACTIONBUTTON",x=0,y=70},
    {key="bar2",label="Action Bar 2",page=6,binding="MULTIACTIONBAR1BUTTON",x=0,y=112},
    {key="bar3",label="Action Bar 3",page=5,binding="MULTIACTIONBAR2BUTTON",x=0,y=154},
    {key="bar4",label="Action Bar 4",page=3,binding="MULTIACTIONBAR3BUTTON",x=510,y=70},
    {key="bar5",label="Action Bar 5",page=4,binding="MULTIACTIONBAR4BUTTON",x=-510,y=70},
    {key="bar6",label="Action Bar 6",page=2,binding="EUI335_BAR6_BUTTON",x=0,y=196},
    {key="petBar",label="Pet Bar",native="PetActionButton",count=10,x=0,y=244},
    {key="stanceBar",label="Stance Bar",native="ShapeshiftButton",count=10,x=-320,y=244},
}
ns.definitions, ns.bars = definitions, {}
local defaults = {profile={enabled=true,lockActions=true,clickOnDown=false,
    showHotkeys=true,showMacroNames=true,fontSize=11,iconCrop=true,
    rangeColor=true,tooltip=true,borderSize=1,borderR=0,borderG=0,borderB=0,
    classBorder=false,hideArtwork=true,bars={},barPositions={},nativeHUD={micro=true,bags=true,bagsConsolidate=false,xp=true,reputation=true,
        buffs=true,debuffs=true,buttonSize=28,spacing=4,barWidth=400,barHeight=14,auraColumns=8}}}
for i,d in ipairs(definitions) do
    defaults.profile.bars[d.key]={enabled=i~=6,buttons=d.count or 12,
        buttonsPerRow=d.count or 12,size=d.native and 30 or 36,spacing=4,
        opacity=100,visibility="always",showEmpty=true}
end
ns.defaults=defaults
local original, decorations, active, pending = {}, {}, false, false
local artwork={}
local hidden = CreateFrame("Frame",nil,UIParent); hidden:Hide()
local events = CreateFrame("Frame",nil,UIParent)
ns.events=events
local function Size(f,w,h) f:SetWidth(w); f:SetHeight(h) end
local function Clamp(v,a,b) return math.max(a,math.min(b,tonumber(v) or a)) end
function ns.GetSettings(key)
    local p=addon.db and addon.db.profile
    return key and p and p.bars[key] or p
end
local function Snapshot(f)
    if not f or original[f] then return end
    local points={}
    for i=1,f:GetNumPoints() do points[i]={f:GetPoint(i)} end
    original[f]={parent=f:GetParent(),points=points,width=f:GetWidth(),height=f:GetHeight(),
        scale=f:GetScale(),alpha=f:GetAlpha(),shown=f:IsShown()}
end
local function RestoreArt()
    for texture,saved in pairs(artwork) do texture:SetTexture(saved.path); texture:SetAlpha(saved.alpha) end
end
function ns.UpdateArt()
    local p=ns.GetSettings()
    if not p or InCombatLockdown() then return end
    if not p.enabled or p.hideArtwork==false then RestoreArt(); return end
    local function StripTexture(texture)
        if not texture or not texture.GetObjectType or texture:GetObjectType()~="Texture" then return end
        if not artwork[texture] then artwork[texture]={path=texture:GetTexture(),alpha=texture:GetAlpha()} end
        texture:SetTexture(nil); texture:SetAlpha(0)
    end
    -- Art containers stay alive: their scripts and functional children continue
    -- to run, including bags/micro buttons when those skins are switched off.
    for _,name in ipairs({"MainMenuBar","MainMenuBarArtFrame","MainMenuBarArt","MainMenuBarArtFrameBackground",
        "MainMenuBarTexture0","MainMenuBarTexture1","MainMenuBarTexture2","MainMenuBarTexture3",
        "MainMenuBarLeftEndCap","MainMenuBarRightEndCap","MainMenuBarTextureExtender"}) do
        local f=_G[name]
        if f then
            if f.GetObjectType and f:GetObjectType()=="Texture" then StripTexture(f)
            elseif f.GetRegions then for _,region in ipairs({f:GetRegions()}) do StripTexture(region) end end
        end
    end
    for texture in pairs(artwork) do texture:SetTexture(nil); texture:SetAlpha(0) end
end
local function RestoreNative()
    for f,s in pairs(original) do
        f:SetParent(s.parent); f:ClearAllPoints()
        for _,point in ipairs(s.points) do f:SetPoint(unpack(point)) end
        Size(f,s.width,s.height); f:SetScale(s.scale); f:SetAlpha(s.alpha)
        if s.shown then f:Show() else f:Hide() end
    end
    for f,s in pairs(decorations) do
        f:SetAlpha(s.alpha)
        if s.mouse~=nil then f:EnableMouse(s.mouse) end
    end
    RestoreArt()
    if PetActionBar_Update and PetActionBarFrame then PetActionBar_Update(PetActionBarFrame) end
    if ShapeshiftBar_Update then ShapeshiftBar_Update() end
end
local function HideNativeActions()
    for _,prefix in ipairs({"ActionButton","BonusActionButton","MultiBarBottomLeftButton",
        "MultiBarBottomRightButton","MultiBarRightButton","MultiBarLeftButton"}) do
        for i=1,12 do
            local f=_G[prefix..i]
            if f then Snapshot(f); f:SetParent(hidden) end
        end
    end
    -- The bonus shell is also shown when entering a stance, independently of
    -- its buttons. EUI handles those action pages through its secure header.
    if BonusActionBarFrame then Snapshot(BonusActionBarFrame); BonusActionBarFrame:SetParent(hidden) end
    -- The original bar shells remain alive for micro/bag/data-bar children.
    -- Their invisible mouse surfaces can cover Bar 1 and swallow spell drops.
    for _,name in ipairs({"MainMenuBar","MainMenuBarArtFrame","MainMenuBarArt"}) do
        local f=_G[name]
        if f and f.EnableMouse and f.IsMouseEnabled then
            if not decorations[f] then decorations[f]={alpha=f:GetAlpha(),mouse=f:IsMouseEnabled()} end
            f:EnableMouse(false)
        end
    end
    -- Unused native paging controls stay hidden independently of the art toggle.
    for _,name in ipairs({"ActionBarUpButton","ActionBarDownButton","MainMenuBarPageNumber"}) do
        local f=_G[name]
        if f then
            if not decorations[f] then decorations[f]={alpha=f:GetAlpha(),mouse=f.IsMouseEnabled and f:IsMouseEnabled()} end
            f:SetAlpha(0); if f.EnableMouse then f:EnableMouse(false) end
        end
    end
    ns.UpdateArt()
end
function ns.GetPageDriver()
    local class=select(2,UnitClass("player"))
    local forms="[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; "
    if class=="DRUID" then forms="[bonusbar:1,stealth] 8; "..forms
    elseif class=="ROGUE" then forms="[form:3] 7; "..forms end
    return "[bonusbar:5] 11; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; "..forms.."1"
end
local visibility = {
    always="show",never="hide",in_combat="[combat] show; hide",
    out_of_combat="[combat] hide; show",in_party="[group:party] show; hide",
    in_raid="[group:raid] show; hide",solo="[group] hide; show",mouseover="show",
}
function ns.GetVisibilityDriver(d,p)
    if not ns.GetSettings().enabled or not p.enabled then return "hide" end
    if d.key=="stanceBar" and GetNumShapeshiftForms()==0 then return "hide" end
    local prefix="[vehicleui] hide; "
    if d.native then prefix=prefix.."[bonusbar:5] hide; " end
    if d.key=="petBar" then prefix=prefix.."[nopet] hide; " end
    return prefix..(visibility[p.visibility] or "show")
end
local applyBindings = [[
    self:ClearBindings()
    if self:GetAttribute("state-eui-visible") ~= "show" then return end
    local count = self:GetAttribute("binding-count") or 0
    for i=1,count do
        self:SetBindingClick(true, self:GetAttribute("binding-key-"..i),
            self:GetAttribute("binding-button-"..i), "LeftButton")
    end
]]
local showState = [[
    if newstate == "show" then self:Show() else self:Hide() end
    control:RunAttribute("ApplyBindings")
]]
local pageState = [[
    if not newstate then return end
    self:SetAttribute("state",newstate)
    control:ChildUpdate("state",newstate)
]]
ns.secure={bindings=applyBindings,visibility=showState,page=pageState}
local function Skin(button)
    local p=ns.GetSettings()
    if not button._euiBorder then
        local border=CreateFrame("Frame",nil,button)
        border:SetFrameLevel(math.max(0,button:GetFrameLevel()-1)); button._euiBorder=border
    end
    local edge=Clamp(p.borderSize,0,5)
    local border=button._euiBorder
    border:ClearAllPoints(); border:SetPoint("TOPLEFT",button,"TOPLEFT",-edge,edge)
    border:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",edge,-edge)
    border:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=math.max(1,edge)})
    border:SetBackdropColor(.07,.07,.07,1)
    local r,g,b=p.borderR,p.borderG,p.borderB
    if p.classBorder then local c=E.GetClassColor(select(2,UnitClass("player"))); if c then r,g,b=c.r,c.g,c.b end end
    border:SetBackdropBorderColor(r,g,b,edge>0 and 1 or 0)
    button.normalTexture:SetAlpha(0)
    button.icon:ClearAllPoints(); button.icon:SetAllPoints(button)
    button.cooldown:ClearAllPoints(); button.cooldown:SetAllPoints(button)
    button.flash:SetAllPoints(button)
    button.hotkey:ClearAllPoints(); button.hotkey:SetPoint("TOPRIGHT",button,"TOPRIGHT",-2,-2)
    button.hotkey:SetWidth(math.max(1,button:GetWidth()-4))
    button.actionName:SetWidth(math.max(1,button:GetWidth()-4))
    if p.iconCrop then button.icon:SetTexCoord(.07,.93,.07,.93) else button.icon:SetTexCoord(0,1,0,1) end
    local font=E.GetFontPath("actionBars")
    local flags=E.GetIconTextOutlineFlag and E.GetIconTextOutlineFlag("actionBars") or "OUTLINE"
    for _,fs in ipairs({button.hotkey,button.count,button.actionName}) do
        E.ApplyModuleFont(fs,font,Clamp(p.fontSize,8,20),"actionBars",flags)
    end
end
local function Config(d)
    local p,s=ns.GetSettings(),ns.GetSettings(d.key)
    return {showGrid=s.showEmpty,clickOnDown=p.clickOnDown,tooltip=p.tooltip and "enabled" or "disabled",
        outOfRangeColoring="button",useColoring=p.rangeColor,keyBoundTarget=false,
        hideElements={macro=not p.showMacroNames,hotkey=not p.showHotkeys,equipped=false}}
end
local function CreateBar(d)
    local bar=CreateFrame("Frame","EllesmereUIActionBars_"..d.key,UIParent,"SecureHandlerStateTemplate")
    bar:SetFrameStrata("LOW"); bar.buttons={}; ns.bars[d.key]=bar
    bar:SetAttribute("ApplyBindings",applyBindings)
    bar:SetAttribute("_onstate-eui-visible",showState)
    if d.native then
        for i=1,d.count do
            local button=_G[d.native..i]
            if button then Snapshot(button); bar.buttons[i]=button end
        end
    else
        bar:SetAttribute("_onstate-page",pageState)
        for i=1,12 do
            local button=LAB:CreateButton(i,"EllesmereUIActionBars_"..d.key.."Button"..i,bar,Config(d))
            bar.buttons[i]=button
            button:SetState(0,"action",(d.page-1)*12+i)
            for page=1,11 do button:SetState(page,"action",(page-1)*12+i) end
            button:SetAttribute("checkselfcast",true); button:SetAttribute("checkfocuscast",true)
        end
    end
    return bar
end
local function UpdateBindings(d,bar)
    local count=0
    if not d.native then
        local p=ns.GetSettings(d.key)
        for i=1,Clamp(p.buttons,1,12) do
            local command=d.binding..i
            local button=bar.buttons[i]
            local keys={GetBindingKey(command)}
            for _,key in ipairs({GetBindingKey("CLICK "..button:GetName()..":LeftButton")}) do keys[#keys+1]=key end
            for _,key in ipairs(keys) do
                count=count+1; bar:SetAttribute("binding-key-"..count,key)
                bar:SetAttribute("binding-button-"..count,button:GetName())
            end
            local config=Config(d); config.keyBoundTarget=command
            button:UpdateConfig(config); button:SetAttribute("buttonlock",ns.GetSettings().lockActions)
            Skin(button)
        end
    end
    bar:SetAttribute("binding-count",count)
    bar:Execute([[control:RunAttribute("ApplyBindings")]])
end
local function Layout(d,bar)
    local p=ns.GetSettings(d.key)
    local count=Clamp(p.buttons,1,d.count or 12)
    if d.key=="stanceBar" then count=math.max(1,math.min(count,GetNumShapeshiftForms())) end
    local columns=math.min(count,Clamp(p.buttonsPerRow,1,d.count or 12))
    local size,spacing=Clamp(p.size,20,64),Clamp(p.spacing,0,20)
    Size(bar,columns*(size+spacing)-spacing,math.ceil(count/columns)*(size+spacing)-spacing)
    local pos=ns.GetSettings().barPositions[d.key]
    bar:ClearAllPoints()
    if pos then bar:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y)
    else bar:SetPoint("BOTTOM",UIParent,"BOTTOM",d.x,d.y) end
    for i,button in ipairs(bar.buttons) do
        button:SetParent(bar); button:ClearAllPoints()
        local scale=1
        if d.native then scale=size/original[button].width; button:SetScale(scale)
        else Size(button,size,size); button:SetScale(1) end
        button:SetPoint("TOPLEFT",bar,"TOPLEFT",((i-1)%columns)*(size+spacing)/scale,-math.floor((i-1)/columns)*(size+spacing)/scale)
        -- Native pet/stance events still own the availability of individual slots.
        if not d.native then if i<=count then button:Show() else button:Hide() end end
    end
    if d.native then
        local nativeFrame=_G[d.key=="petBar" and "PetActionBarFrame" or "ShapeshiftBarFrame"]
        -- Blizzard's slide/show animations restore alpha on stance changes.
        -- Keep its event controller running under a hidden parent; the native
        -- buttons have already been moved to our independently visible header.
        if nativeFrame then Snapshot(nativeFrame); nativeFrame:SetParent(hidden); nativeFrame:SetAlpha(0) end
    end
    if not d.native then
        RegisterStateDriver(bar,"page",d.key=="bar1" and ns.GetPageDriver() or tostring(d.page))
    end
    UpdateBindings(d,bar)
    RegisterStateDriver(bar,"eui-visible",ns.GetVisibilityDriver(d,p))
end
function ns.UpdateAlpha()
    if not active then return end
    ns.UpdateArt()
    for _,d in ipairs(definitions) do
        local bar=ns.bars[d.key]
        if bar then
            local p=ns.GetSettings(d.key)
            local alpha=Clamp(p.opacity,0,100)/100
            if p.visibility=="mouseover" and not MouseIsOver(bar) and not (E.IsUnlockModeActive and E:IsUnlockModeActive()) then alpha=0 end
            bar:SetAlpha(alpha)
        end
    end
end
function ns.Apply()
    if not addon.db then return end
    if InCombatLockdown() then pending=true; return end
    pending=false
    local p=ns.GetSettings()
    if ns.NativeHUD then ns.NativeHUD.Apply() end
    if not p.enabled then
        active=false
        for _,bar in pairs(ns.bars) do
            UnregisterStateDriver(bar,"eui-visible"); UnregisterStateDriver(bar,"page")
            bar:Execute([[self:ClearBindings()]])
            bar:SetAttribute("state-eui-visible",nil); bar:SetAttribute("state-page",nil); bar:Hide()
        end
        RestoreNative(); return
    end
    active=true; HideNativeActions()
    for _,d in ipairs(definitions) do Layout(d,ns.bars[d.key] or CreateBar(d)) end
    ns.UpdateAlpha()
end
function addon:ApplyAll() ns.Apply() end
function addon:ApplyBorders() if not InCombatLockdown() then for _,d in ipairs(definitions) do if not d.native and ns.bars[d.key] then for _,b in ipairs(ns.bars[d.key].buttons) do Skin(b) end end end end end
function ns.AB_Style() return "eui" end
function addon:OnInitialize()
    -- Lua 5.1 xpcall does not forward the Core dispatcher's extra arguments.
    -- Capture the instance, as the Wrath Minimap does, instead of relying on self.
    addon.db=E.Lite.NewDB("EllesmereUIActionBarsDB",defaults)
    _G._EAB_Apply=ns.Apply
    BINDING_HEADER_EUI335_ACTIONBARS="EllesmereUI Action Bars"
    for i=1,12 do _G["BINDING_NAME_EUI335_BAR6_BUTTON"..i]="Action Bar 6 - Button "..i end
    SLASH_EUI335ACTIONBARS1="/eab"
    SlashCmdList.EUI335ACTIONBARS=function()
        if InCombatLockdown() then return end
        if E.EnsureOptionsLoaded and E.EnsureOptionsLoaded() then E:ShowModule(ADDON_NAME) end
    end
end
function addon:OnEnable()
    if not addon.db then return end
    ns.Apply()
    if ns.NativeHUD then ns.NativeHUD.Enable() end
    if E.RegisterUnlockElements and E.MakeUnlockElement then
        local elements={}
        for i,d in ipairs(definitions) do
            local key=d.key
            elements[#elements+1]=E.MakeUnlockElement({key="EUI335_AB_"..key,label=d.label,group="Action Bars",order=100+i,
                noResize=true,noAnchorTo=true,getFrame=function() return ns.bars[key] end,
                getSize=function() local f=ns.bars[key]; return f and f:GetWidth() or 1,f and f:GetHeight() or 1 end,
                isHidden=function() local root,p=ns.GetSettings(),ns.GetSettings(key); return not root or not root.enabled or not p or not p.enabled end,
                savePos=function(_,point,relPoint,x,y)
                    local p=ns.GetSettings(); if p then p.barPositions[key]={point=point,relPoint=relPoint,x=x,y=y} end
                end,
                loadPos=function() local p=ns.GetSettings(); return p and p.barPositions[key] end,
                clearPos=function() local p=ns.GetSettings(); if p then p.barPositions[key]=nil end end,applyPos=ns.Apply,
            })
        end
        if ns.NativeHUD then for _,element in ipairs(ns.NativeHUD.Elements()) do elements[#elements+1]=element end end
        -- Register shortcuts before Options loads so the first mover cog can
        -- select its bar while opening the lazy settings panel.
        E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
        for _,element in ipairs(elements) do
            local key=element.key:match("^EUI335_AB_(.+)$") or element.key:match("^EUI335_HUD_(.+)$")
            if key then
                local selected=key
                E._ELEMENT_SETTINGS_MAP[element.key]={module=ADDON_NAME,page="Action Bars",sectionName="BAR SELECTION",highlightText="Select Bar",
                    preSelectFn=function()
                        ns.selectedWrathBar=selected
                        if ns.SelectWrathBar then ns.SelectWrathBar(selected,false) end
                    end}
            end
        end
        E:RegisterUnlockElements(elements,ADDON_NAME)
    end
    for _,event in ipairs({"PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD","UPDATE_BINDINGS","UPDATE_SHAPESHIFT_FORMS"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent",function(_,event)
        if event=="PLAYER_REGEN_ENABLED" then if pending then ns.Apply() end
        else ns.Apply() end
    end)
    local elapsed=0
    events:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        if elapsed>=.1 then elapsed=0; ns.UpdateAlpha() end
    end)
end
