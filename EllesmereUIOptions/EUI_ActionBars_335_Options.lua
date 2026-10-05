local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
-- Only controls implemented by the Wrath module are exposed here.
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIActionBars
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local byKey,actionKeys,values,order={},{},{},{}
    for _,d in ipairs(ns.definitions) do
        byKey[d.key]=d; actionKeys[d.key]=true; values[d.key]=d.label; order[#order+1]=d.key
    end
    if ns.NativeHUD then for _,d in ipairs(ns.NativeHUD.definitions) do
        byKey[d.key]=d; values[d.key]=d.label; order[#order+1]=d.key
    end end
    if not byKey[ns.selectedWrathBar] then ns.selectedWrathBar=order[1] end
    function ns.SelectWrathBar(key,refresh)
        if not byKey[key] then return end
        ns.selectedWrathBar=key
        if E.InvalidatePageCache then E:InvalidatePageCache() end
        if refresh~=false and E.RefreshPage then E:RefreshPage(true) end
    end
    -- Unlock mode shortcuts open the same panel with the relevant bar selected.
    E._ELEMENT_SETTINGS_MAP=E._ELEMENT_SETTINGS_MAP or {}
    for _,key in ipairs(order) do
        local selected=key
        local mover=actionKeys[key] and "EUI335_AB_"..key or "EUI335_HUD_"..key
        E._ELEMENT_SETTINGS_MAP[mover]={module="EllesmereUIActionBars",page="Action Bars",sectionName="BAR SELECTION",highlightText="Select Bar",
            preSelectFn=function() ns.SelectWrathBar(selected,false) end}
    end
    local function Field(key,label,kind,min,max,step,bar)
        local cfg={type=kind,text=label,min=min,max=max,step=step}
        cfg.getValue=function() local p=ns.GetSettings(bar); return p and p[key] end
        cfg.setValue=function(v) local p=ns.GetSettings(bar); if p then p[key]=v; ns.Apply() end end
        return cfg
    end
    local function Toggle(key,label,bar) return Field(key,label,"toggle",nil,nil,nil,bar) end
    local function Slider(key,label,min,max,step,bar) return Field(key,label,"slider",min,max,step,bar) end
    local function HUD(key,label,kind,min,max,step,fallback)
        return {type=kind,text=label,min=min,max=max,step=step,
            getValue=function()
                local p=ns.GetSettings(); local v=p and p.nativeHUD[key]
                if v==nil and fallback then v=p and p.nativeHUD[fallback] end
                return v
            end,
            setValue=function(v) local p=ns.GetSettings(); if p then p.nativeHUD[key]=v; ns.Apply() end end}
    end
    E:RegisterModule("EllesmereUIActionBars",{
        title="Action Bars",description="Action bars, Blizzard HUD skins and player aura positions for Wrath.",pages={"Action Bars"},
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(a,b) local _,h=W:DualRow(parent,y,a,b); y=y-h end
            local function Section(label) local _,h=W:SectionHeader(parent,label,y); y=y-h end
            local function Button(label,fn) local _,h=W:WideButton(parent,label,y,fn); y=y-h end
            local key=ns.selectedWrathBar
            local d=byKey[key]; if not d then return end
            local action=actionKeys[key]
            Section("BAR SELECTION")
            Row({type="dropdown",text="Select Bar",values=values,order=order,
                getValue=function() return ns.selectedWrathBar end,
                setValue=function(v) ns.SelectWrathBar(v) end},
                action and Toggle("enabled","Show Bar",key) or HUD(key,
                    (key=="buffs" or key=="debuffs") and "Enable Aura Mover" or "Enable Skin","toggle"))
            if action then
                Section("LAYOUT")
                Row(Slider("size","Button Size",20,64,1,key),Slider("spacing","Spacing",0,20,1,key))
                Row(Slider("buttonsPerRow","Buttons Per Row",1,d.count or 12,1,key),
                    d.native and {type="label",text="Native slots and actions"} or Slider("buttons","Button Count",1,12,1,key))
                local cfg=Field("visibility","Visibility","dropdown",nil,nil,nil,key)
                cfg.values={always="Always",never="Never",mouseover="Mouseover",in_combat="In Combat",
                    out_of_combat="Out of Combat",in_party="In Party",in_raid="In Raid",solo="Solo"}
                cfg.order={"always","never","mouseover","in_combat","out_of_combat","in_party","in_raid","solo"}
                Row(cfg,Slider("opacity","Opacity",0,100,1,key))
                Row(d.native and {type="label",text="Vehicles use Blizzard controls"} or Toggle("showEmpty","Show Empty Buttons",key),
                    {type="label",text=d.label})
            elseif key=="micro" or key=="bags" then
                Section("LAYOUT")
                Row(HUD(key.."Size","Button Size","slider",20,48,1,"buttonSize"),
                    HUD(key.."Spacing","Spacing","slider",0,12,1,"spacing"))
                if key=="bags" then Row(HUD("bagsConsolidate","Consolidate Bags","toggle"),{type="label",text="One backpack button; opens the unified inventory"}) end
            elseif key=="xp" or key=="reputation" then
                Section("LAYOUT")
                Row(HUD(key.."Width","Bar Width","slider",120,1000,1,"barWidth"),
                    HUD(key.."Height","Bar Height","slider",8,32,1,"barHeight"))
                Row({type="label",text=key=="xp" and "Blue XP / Purple Rested XP" or "Faction Standing Color"},
                    {type="label",text="ElvUI Norm Texture"})
            else
                Section("LAYOUT")
                Row(HUD(key.."Columns","Aura Icons Per Row","slider",1,16,1,"auraColumns"),
                    {type="label",text="Native auras, timers and cancellation"})
            end
            Button("Reset Selected Bar Position",function()
                ns.GetSettings().barPositions[action and key or "hud_"..key]=nil; ns.Apply()
            end)
            Section("GLOBAL SETTINGS")
            Row(Toggle("enabled","Enable Action Bars"),Toggle("hideArtwork","Hide Blizzard Bar Art"))
            Row(Toggle("lockActions","Lock Action Dragging"),Toggle("clickOnDown","Cast on Key Down"))
            Row(Toggle("showHotkeys","Show Hotkeys"),Toggle("showMacroNames","Show Macro Names"))
            Row(Toggle("rangeColor","Range & Resource Colors"),Toggle("iconCrop","Crop Icons"))
            Row(Toggle("tooltip","Show Tooltips"),Toggle("classBorder","Class Colored Border"))
            Row(Slider("fontSize","Text Size",8,20,1),Slider("borderSize","Border Size",0,5,1))
            Row({type="colorpicker",text="Border Color",
                getValue=function() local p=ns.GetSettings(); return p.borderR,p.borderG,p.borderB,1 end,
                setValue=function(r,g,b) local p=ns.GetSettings(); p.borderR,p.borderG,p.borderB=r,g,b; p.classBorder=false; ns.Apply() end},
                {type="label",text="Global settings apply to action buttons"})
            Section("POSITION & BINDINGS")
            Button("Open Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
            Button("Open Blizzard Key Bindings",function()
                if InCombatLockdown() then return end
                if not KeyBindingFrame then LoadAddOn("Blizzard_BindingUI") end
                if KeyBindingFrame then ShowUIPanel(KeyBindingFrame) end
            end)
            Button("Reset All Bar Positions",function() ns.GetSettings().barPositions={}; ns.Apply() end)
            return math.abs(y)
        end,
        onReset=function()
            if ns.addon.db and ns.addon.db.ResetProfile then ns.addon.db:ResetProfile() end
            ns.Apply(); E:InvalidatePageCache()
        end,
    })
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
