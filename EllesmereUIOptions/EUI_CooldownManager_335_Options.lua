local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
-- Retail Cooldown Manager pages (CDM Bars, Bar Glows, Tracking Bars) on Wrath widgets.
local E=EllesmereUI
local ns=E._ModuleNS and E._ModuleNS.EllesmereUICooldownManager
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local O={entry=1,rule=1,addKind="spell",addID="",status=""}
    ns.Options=O
    function O.Refresh()
        if E.InvalidateContentHeaderCache then E:InvalidateContentHeaderCache() end
        E:InvalidatePageCache(); E:RefreshPage(true)
    end
    function O.Label(t) return {type="label",text=t or ""} end
    O.spacer={type="label",text=""}
    -- Stores: functions returning the table a control edits.
    function O.Bar() local b=ns.BarByKey(ns.selectedBar or "cooldowns") or ns.Bars()[1]; ns.selectedBar=b and b.key; return b end
    function O.Defaults() local b=O.Bar(); if b then b.spellDefaults=b.spellDefaults or {}; return b.spellDefaults end end
    function O.List() return ns.EntriesFor(O.Bar().key) end
    function O.Entry() return O.List()[O.entry] end
    function O.TBB() local l=ns.TBBList(); ns.selectedTBB=math.max(1,math.min(ns.selectedTBB or 1,#l)); return l[ns.selectedTBB] end
    function O.TBBGroupStore() local c=O.TBB(); return c and (c.groupID or 0)>0 and ns.TBBGroup(c.groupID) or nil end
    function O.Glows() local l=ns.Lists(); return l and l.barGlows end
    function O.Rule() local g=O.Glows(); return g and g.list and g.list[O.rule] end
    function O.Get(store,key,fallback) local t=store(); if not t or t[key]==nil then return fallback end; return t[key] end
    function O.Set(store,key,value) local t=store(); if t then t[key]=value; ns.Apply() end end
    function O.T(store,key,label,dis,tip)
        return {type="toggle",text=label,tooltip=tip,disabled=dis,getValue=function() return O.Get(store,key,false) and true or false end,setValue=function(v) O.Set(store,key,v) end}
    end
    function O.S(store,key,label,min,max,step,dis,tip)
        return {type="slider",text=label,min=min,max=max,step=step or 1,tooltip=tip,disabled=dis,getValue=function() return O.Get(store,key,min) end,setValue=function(v) O.Set(store,key,v) end}
    end
    function O.P(store,key,label,dis,tip)
        return {type="slider",text=label,min=0,max=100,step=5,tooltip=tip,disabled=dis,getValue=function() return math.floor(O.Get(store,key,1)*100+.5) end,setValue=function(v) O.Set(store,key,v/100) end}
    end
    function O.D(store,key,label,values,order,dis,tip,fallback)
        return {type="dropdown",text=label,values=values,order=order,tooltip=tip,disabled=dis,getValue=function() return O.Get(store,key,fallback) end,setValue=function(v) O.Set(store,key,v) end}
    end
    -- Per-entry override: "default" clears the key so the bar default applies.
    function O.ED(key,label,values,order,tip)
        return {type="dropdown",text=label,values=values,order=order,tooltip=tip,
            getValue=function() local e=O.Entry(); return e and e[key]~=nil and e[key] or "default" end,
            setValue=function(v) local e=O.Entry(); if e then if v=="default" then e[key]=nil else e[key]=v end; ns.Apply() end end}
    end
    function O.C(store,prefix,label,alpha,dis,tip)
        return {type="colorpicker",text=label,hasAlpha=alpha,tooltip=tip,disabled=dis,
            getValue=function() local t=store() or {}; return t[prefix.."R"] or 1,t[prefix.."G"] or 1,t[prefix.."B"] or 1,t[prefix.."A"] or 1 end,
            setValue=function(r,g,b,a) local t=store(); if not t then return end; t[prefix.."R"],t[prefix.."G"],t[prefix.."B"]=r,g,b; if alpha then t[prefix.."A"]=a or 1 end; ns.Apply() end}
    end
    function O.I(store,key,label,numeric,tip)
        return {type="input",text=label,tooltip=tip,getValue=function() local v=O.Get(store,key); return v~=nil and tostring(v) or "" end,
            setValue=function(v) if numeric then v=tonumber(v) or 0 elseif v=="" then v=nil end; O.Set(store,key,v) end}
    end
    function O.BorderTextures()
        if E.GetBorderTextureDropdown then local ok,v,o=pcall(E.GetBorderTextureDropdown); if ok and v and o then return v,o end end
        return {solid="Solid"},{"solid"}
    end
    O.glow={[0]="None"}; O.glowOrder={0}
    for _,i in ipairs(ns.GLOW_ORDER) do O.glow[i]=ns.GLOW_NAMES[i]; O.glowOrder[#O.glowOrder+1]=i end
    O.glowD={default="Bar Default",[0]="None"}; O.glowDOrder={"default",0}
    for _,i in ipairs(ns.GLOW_ORDER) do O.glowD[i]=ns.GLOW_NAMES[i]; O.glowDOrder[#O.glowDOrder+1]=i end
    O.cse={none="Always Show",lowerAlphaOnCD="Lower Opacity on Cooldown",hiddenOnCDShift="Hide on Cooldown",hiddenReadyShift="Hide When Ready",
        hiddenOnCD="Hide on Cooldown (Keep Place)",hiddenReady="Hide When Ready (Keep Place)",pixelGlowReady="Glow When Ready",pixelGlowReadyUsable="Glow When Ready and Usable",
        hiddenUnusableShift="Hide Until Usable",hiddenFormShift="Hide Outside Form/Stance",hiddenUnusable="Hide Until Usable (Keep Place)",hiddenForm="Hide Outside Form/Stance (Keep Place)"}
    O.cseOrder={"none","lowerAlphaOnCD","hiddenOnCDShift","hiddenReadyShift","hiddenUnusableShift","hiddenFormShift","hiddenOnCD","hiddenReady","hiddenUnusable","hiddenForm","pixelGlowReady","pixelGlowReadyUsable"}
    O.cseTip="Hide Until Usable: only shown while usable and off cooldown, such as Overpower or Victory Rush after a proc; low resources do not hide it. Hide Outside Form/Stance: only shown in the form or stance the spell needs, even on cooldown. Keep Place leaves the gap; the others close it."
    O.cseD={default="Bar Default"}; O.cseDOrder={"default"}
    for _,k in ipairs(O.cseOrder) do O.cseD[k]=O.cse[k]; O.cseDOrder[#O.cseDOrder+1]=k end
    O.strata={BACKGROUND="Background",LOW="Low",MEDIUM="Medium",HIGH="High",DIALOG="Dialog"}
    O.strataOrder={"BACKGROUND","LOW","MEDIUM","HIGH","DIALOG"}
    O.textPos={center="Center",top="Top",bottom="Bottom",left="Left",right="Right",topleft="Top Left",topright="Top Right",bottomleft="Bottom Left",bottomright="Bottom Right"}
    O.textPosOrder={"center","top","bottom","left","right","topleft","topright","bottomleft","bottomright"}
    O.corner={TOPLEFT="Top Left",TOPRIGHT="Top Right",BOTTOMLEFT="Bottom Left",BOTTOMRIGHT="Bottom Right",CENTER="Center"}
    O.cornerOrder={"TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT","CENTER"}
    O.units={player="Player",target="Target",focus="Focus",pet="Pet"}; O.unitOrder={"player","target","focus","pet"}
    O.filters={HELPFUL="Buff",HARMFUL="Debuff"}; O.filterOrder={"HELPFUL","HARMFUL"}
    O.sounds={none="None",RaidWarning="Raid Warning",ReadyCheck="Ready Check",igQuestFailed="Quest Failed",TellMessage="Whisper",AuctionWindowOpen="Auction Bell"}
    O.soundOrder={"none","RaidWarning","ReadyCheck","igQuestFailed","TellMessage","AuctionWindowOpen"}
    -- Then the shared alert sounds: EllesmereUI's own and SharedMedia ("sm:" keys).
    if E.GetAlertSoundCatalogue then
        local _,names,order=E.GetAlertSoundCatalogue(); local sep=true
        for _,key in ipairs(order) do
            if key=="---" then sep=true
            elseif key~="none" and not O.sounds[key] then
                if sep then O.soundOrder[#O.soundOrder+1]="---"; sep=false end
                O.sounds[key]=names[key] or key; O.soundOrder[#O.soundOrder+1]=key
            end
        end
    end
    O.barTypes={cooldowns="Cooldown Bar",utility="Utility Bar",buffs="Buff Bar",focuskick="FocusKick Bar"}
    function O.Context(W,parent,y)
        local B={y=y}
        function B.Row(a,b) local row,h=W:DualRow(parent,B.y,a,b or O.spacer); B.y=B.y-h; return row end
        function B.Section(t) local _,h=W:SectionHeader(parent,t,B.y); B.y=B.y-h end
        function B.Button(t,fn) local _,h=W:WideButton(parent,t,B.y,fn); B.y=B.y-h end
        function B.Visibility(store,rightCfg)
            if E.BuildVisibilityRow and not E._prebuilding then
                local ok,_,h=pcall(E.BuildVisibilityRow,W,parent,B.y,{getStore=store,legacyKey="barVisibility",caps={partyIncludesRaid=false},
                    onChanged=function() ns.Apply() end,onOptionChanged=function() ns.Update() end},rightCfg)
                if ok and h then B.y=B.y-h; return end
            end
            B.Row(O.D(store,"barVisibility","Visibility",{always="Always",never="Never",mouseover="Mouseover",in_combat="In Combat",out_of_combat="Out of Combat",in_raid="In Raid",in_party="In Party",solo="Solo"},
                {"always","never","mouseover","in_combat","out_of_combat","in_raid","in_party","solo"},nil,nil,"always"),rightCfg)
        end
        return B
    end
    function O.Header(B)
        B.Section("COOLDOWN MANAGER")
        B.Row(O.T(ns.Profile,"enabled","Enable Cooldown Manager"),O.Label("Assignments: "..ns.SpecKey()))
        B.Row({type="toggle",text="Preview",tooltip="Shows every bar with placeholder icons while the options are open.",getValue=function() return ns.optionsPreview end,
            setValue=function(v) ns.optionsPreview=v; ns.preview=v or ns.unlockPreview; ns.Apply() end},O.T(ns.Profile,"glowsOnlyInCombat","Glows Only In Combat"))
    end

    --------------------------------------------------------------------------
    -- Page: CDM Bars
    --------------------------------------------------------------------------
    function O.BarSelect(B)
        B.Section("BARS")
        B.Row(O.T(O.Bar,"enabled","Show This Bar"),O.Label("Type: "..(O.barTypes[O.Bar().barType] or O.Bar().barType)))
        B.Row(O.T(ns.Profile,"useClassicStyle","Classic Icon Style",nil,"Blizzard action button ring and press highlight."),O.T(ns.Profile,"swapPotions","Swap Out-of-Stock Potions",nil,"Item presets show the next potion of the family when one runs out."))
        B.Row(O.T(ns.Profile,"readySound","Cooldown Ready Sound"),O.spacer)
    end

    --------------------------------------------------------------------------
    -- CDM Bars header (Retail): bar dropdown with rename/delete/add, and the
    -- selected bar's icons (drag to reorder, click to edit, middle-click removes).
    --------------------------------------------------------------------------
    O.ICONS=(E.MEDIA_PATH or "Interface\\AddOns\\EllesmereUI\\media\\").."icons_335\\"
    O.QUESTION="Interface\\Icons\\INV_Misc_QuestionMark"
    O.MAX_CUSTOM=20
    O.addBarItems={{"cooldowns","+ Add New Cooldowns Bar"},{"utility","+ Add New Utility Bar"},{"buffs","+ Add New Buff Bar"}}
    O.DDS={BG_R=.075,BG_G=.113,BG_B=.141,BG_A=.9,BG_HA=.98,BRD_A=.2,BRD_HA=.3,TXT_A=.5,TXT_HA=1,ITEM_HL_A=.08,ITEM_SEL_A=.04}
    function O.IsBuiltin(key) return key=="cooldowns" or key=="utility" or key=="buffs" end
    function O.Font(parent,size,r,g,b,a)
        local fs
        if E.MakeFont then fs=E.MakeFont(parent,size,nil,r,g,b,a)
        else fs=parent:CreateFontString(nil,"OVERLAY"); fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",size,""); fs:SetTextColor(r,g,b,a or 1) end
        return fs
    end
    function O.Solid(parent,layer,r,g,b,a) local t=parent:CreateTexture(nil,layer); t:SetTexture(r,g,b,a or 1); return t end
    function O.Tip(owner,title,line)
        GameTooltip:SetOwner(owner,"ANCHOR_TOP"); GameTooltip:SetText(title or "",1,1,1)
        if line then GameTooltip:AddLine(line,.7,.7,.7,true) end
        GameTooltip:Show()
    end
    function O.HideTip() GameTooltip:Hide() end
    function O.EntryName(e)
        local m=ns.Resolve(e,O.Bar()); if m and m.name then return m.name end
        local id=tonumber(e.id); local n=id and (e.kind=="spell" or e.kind=="aura" or not e.kind) and GetSpellInfo(id)
        if e.kind=="slot" and id then
            local item=GetInventoryItemID("player",id); n=item and GetItemInfo(item)
            if n then n=n.." (passive, hidden: enable Show Passive Trinkets)" end
        end
        return n or ((e.kind or "spell").." "..tostring(e.id))
    end
    function O.EntryIcon(e)
        local m=ns.Resolve(e,O.Bar()); if m and m.icon then return m.icon,true end
        local k,id=e.kind or "spell",tonumber(e.id)
        if k=="preset" then local p=ns.ITEM_PRESET_BY_KEY[e.id]; return p and GetItemIcon and GetItemIcon(p.items[1]) or O.QUESTION end
        if id and (k=="spell" or k=="aura") then local _,_,icon=GetSpellInfo(id); if icon then return icon end end
        if id and k=="item" and GetItemIcon then return GetItemIcon(id) or O.QUESTION end
        if id and k=="slot" and GetInventoryItemTexture then return GetInventoryItemTexture("player",id) or O.QUESTION end
        return O.QUESTION
    end
    -- Scrolls to a section of the rebuilt page and glows its first control.
    function O.Navigate(y,row)
        if not y then return end
        if E.SmoothScrollTo then E.SmoothScrollTo(math.max(0,math.abs(y)-10)) end
        O.glowFn=O.glowFn or (E.MakeSettingGlow and E.MakeSettingGlow({color=E.ELLESMERE_GREEN or {r=.05,g=.82,b=.62},thickness=2,noSnap=true}))
        local target=row and (row._leftRegion or row)
        if O.glowFn and target and target.GetObjectType then O.glowFn(target) end
    end
    function O.SelectBar(key) ns.selectedBar=key; O.entry=1; O.Refresh() end
    function O.BuildMenu(btn,Hover)
        if O.menu then O.menu:Hide() end
        local S,ITEM_H,h=E.DD_STYLE or O.DDS,26,4
        local menu=CreateFrame("Frame",nil,UIParent); O.menu=menu; menu.items={}
        menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu:SetFrameLevel(300); menu:SetClampedToScreen(true); menu:EnableMouse(true)
        menu:SetPoint("TOPLEFT",btn,"BOTTOMLEFT",0,-2); menu:SetPoint("TOPRIGHT",btn,"BOTTOMRIGHT",0,-2)
        O.Solid(menu,"BACKGROUND",S.BG_R,S.BG_G,S.BG_B,S.BG_HA):SetAllPoints()
        if E.MakeBorder then E.MakeBorder(menu,1,1,1,S.BRD_A,E.PanelPP) end
        local function Item(text,selected,dim,onClick)
            local it=CreateFrame("Button",nil,menu); it:SetHeight(ITEM_H)
            it:SetPoint("TOPLEFT",menu,"TOPLEFT",1,-h); it:SetPoint("TOPRIGHT",menu,"TOPRIGHT",-1,-h); it:SetFrameLevel(menu:GetFrameLevel()+2)
            local hl=O.Solid(it,"ARTWORK",1,1,1,1); hl:SetAllPoints()
            local rest=selected and (S.ITEM_SEL_A or .04) or 0; hl:SetAlpha(rest)
            local l=O.Font(it,11,.7,.7,.7,dim and .3 or .85); l:SetJustifyH("LEFT"); l:SetPoint("LEFT",it,"LEFT",10,0); l:SetText(text)
            it.label,it.hl=l,hl
            function it.Hover(on) l:SetTextColor(on and 1 or .7,on and 1 or .7,on and 1 or .7,on and 1 or .85); hl:SetAlpha(on and (S.ITEM_HL_A or .08) or rest) end
            if onClick and not dim then
                it:SetScript("OnEnter",function() it.Hover(true) end)
                it:SetScript("OnLeave",function() if not ((it.edit and it.edit:IsMouseOver()) or (it.del and it.del:IsMouseOver())) then it.Hover(false) end end)
                it:SetScript("OnClick",function() menu:Hide(); onClick() end)
            end
            menu.items[text]=it; h=h+ITEM_H
            return it
        end
        local function IconBtn(it,tex,tip,anchor,x,fn)
            local b=CreateFrame("Button",nil,it); b:SetWidth(14); b:SetHeight(14); b:SetPoint("RIGHT",anchor,anchor==it and "RIGHT" or "LEFT",x,0)
            b:SetFrameLevel(it:GetFrameLevel()+2); b:SetAlpha(.75)
            local t=b:CreateTexture(nil,"OVERLAY"); t:SetAllPoints(); t:SetTexture(tex)
            b:SetScript("OnEnter",function() b:SetAlpha(1); it.Hover(true); O.Tip(b,tip) end)
            b:SetScript("OnLeave",function() b:SetAlpha(.75); O.HideTip(); if not it:IsMouseOver() then it.Hover(false) end end)
            b:SetScript("OnClick",function() menu:Hide(); fn() end)
            return b
        end
        local customs,hasKick=0,false
        for _,b in ipairs(ns.Bars()) do
            if b.barType=="focuskick" then hasKick=true elseif not O.IsBuiltin(b.key) then customs=customs+1 end
            local key,name=b.key,b.name or b.key
            local it=Item(name,key==O.Bar().key,false,function() O.SelectBar(key) end)
            if not O.IsBuiltin(key) then
                it.del=IconBtn(it,E.CLOSE_ICON_335 or (O.ICONS.."eui-close.tga"),"Delete",it,-8,function()
                    local function Delete() if ns.RemoveBar(key) then if ns.selectedBar==key then ns.selectedBar="cooldowns"; O.entry=1 end end; ns.Apply(); O.Refresh() end
                    if E.ShowConfirmPopup then E:ShowConfirmPopup({title="Delete Bar",message=('Are you sure you want to delete "%s"?'):format(name),confirmText="Delete",cancelText="Cancel",onConfirm=Delete})
                    else Delete() end
                end)
                it.edit=IconBtn(it,O.ICONS.."eui-edit.tga","Rename",it.del,-4,function()
                    if not E.ShowInputPopup then return end
                    E:ShowInputPopup({title="Rename Bar",message=('Enter a new name for "%s":'):format(name),placeholder=name,confirmText="Rename",cancelText="Cancel",
                        onConfirm=function(v) v=v and strtrim(v) or ""; if v~="" and v~=name then b.name=v; ns.Apply(); O.Refresh() end end})
                end)
                it.label:SetPoint("RIGHT",it.edit,"LEFT",-4,0)
            end
        end
        local div=O.Solid(menu,"ARTWORK",1,1,1,.1); div:SetHeight(1)
        div:SetPoint("TOPLEFT",menu,"TOPLEFT",1,-h-4); div:SetPoint("TOPRIGHT",menu,"TOPRIGHT",-1,-h-4); h=h+9
        local atCap=customs>=O.MAX_CUSTOM
        local function Add(barType) local b=ns.AddBar(barType); if b then ns.selectedBar=b.key; O.entry=1 end; ns.Apply(); O.Refresh() end
        for _,a in ipairs(O.addBarItems) do
            local barType=a[1]
            Item(atCap and ("%s (max %d)"):format(a[2],O.MAX_CUSTOM) or a[2],false,atCap,function() Add(barType) end)
        end
        if not hasKick then Item("+ Add FocusKick Bar",false,false,function() Add("focuskick") end) end
        menu:SetHeight(h+4)
        menu:SetScript("OnUpdate",function(m)
            if not m:IsMouseOver() and not btn:IsMouseOver() and IsMouseButtonDown and IsMouseButtonDown("LeftButton") then m:Hide() end
        end)
        menu:SetScript("OnHide",function(m) m:SetScript("OnUpdate",nil); if Hover then Hover(false) end end)
        menu:Show()
        return menu
    end
    function O.BarDropdown(hdr,top)
        local S=E.DD_STYLE or O.DDS
        local btn=CreateFrame("Button",nil,hdr); btn:SetWidth(350); btn:SetHeight(34)
        btn:SetPoint("TOP",hdr,"TOP",0,top); btn:SetFrameLevel(hdr:GetFrameLevel()+5)
        local bg=O.Solid(btn,"BACKGROUND",S.BG_R,S.BG_G,S.BG_B,S.BG_A); bg:SetAllPoints()
        local brd=E.MakeBorder and E.MakeBorder(btn,1,1,1,S.BRD_A,E.PanelPP)
        local lbl=O.Font(btn,13,1,1,1,1); lbl:SetAlpha(S.TXT_A); lbl:SetJustifyH("LEFT"); lbl:SetPoint("LEFT",btn,"LEFT",12,0)
        local arrow=E.MakeDropdownArrow and E.MakeDropdownArrow(btn,12,E.PanelPP)
        if arrow then lbl:SetPoint("RIGHT",arrow,"LEFT",-5,0) else lbl:SetPoint("RIGHT",btn,"RIGHT",-24,0) end
        lbl:SetText(O.Bar().name or O.Bar().key)
        local function Hover(on)
            lbl:SetAlpha(on and (S.TXT_HA or 1) or S.TXT_A); bg:SetTexture(S.BG_R,S.BG_G,S.BG_B,on and S.BG_HA or S.BG_A)
            if brd and brd.SetColor then brd:SetColor(1,1,1,on and (S.BRD_HA or .3) or S.BRD_A) end
        end
        btn:SetScript("OnEnter",function() Hover(true) end)
        btn:SetScript("OnLeave",function() if not (O.menu and O.menu:IsShown()) then Hover(false) end end)
        btn:SetScript("OnClick",function() if O.menu and O.menu:IsShown() then O.menu:Hide() else O.BuildMenu(btn,Hover) end end)
        btn:SetScript("OnHide",function() if O.menu then O.menu:Hide() end end)
        O.dropdown=btn
        return btn
    end
    -- Insertion slot (1..#entries+1) nearest the cursor, and the slot it sits beside.
    function O.DropSlot()
        local x,y=GetCursorPosition(); local best,bestD,after
        for _,s in ipairs(O.slots) do
            if s.index then
                local cx,cy=s:GetCenter(); local sc=s:GetEffectiveScale()
                if cx then
                    local d=(x/sc-cx)^2+(y/sc-cy)^2
                    if not bestD or d<bestD then best,bestD,after=s,d,x/sc>cx end
                end
            end
        end
        if not best then return end
        return after and best.index+1 or best.index,best,after
    end
    function O.MoveEntry(from,to)
        local l=O.List(); if not l[from] then return end
        if to>from then to=to-1 end
        to=math.max(1,math.min(to,#l))
        if to==from then return end
        local e=table.remove(l,from); table.insert(l,to,e); O.entry=to; ns.Apply(); O.Refresh()
    end
    function O.Ghost()
        if O.ghost then return O.ghost end
        local g=CreateFrame("Frame",nil,UIParent); g:SetFrameStrata("TOOLTIP"); g:SetWidth(36); g:SetHeight(36); g:SetAlpha(.7)
        g.icon=g:CreateTexture(nil,"ARTWORK"); g.icon:SetAllPoints(); g.icon:SetTexCoord(.07,.93,.07,.93)
        g:SetScript("OnUpdate",function(self) local x,y=GetCursorPosition(); local sc=UIParent:GetEffectiveScale(); self:ClearAllPoints(); self:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/sc,y/sc) end)
        g:Hide(); O.ghost=g
        return g
    end
    function O.StopDrag()
        local d=O.drag; O.drag=nil
        if O.ghost then O.ghost:Hide() end
        if O.insertLine then O.insertLine:Hide() end
        return d
    end
    --------------------------------------------------------------------------
    -- Retail add pickers under the '+' slots. Main '+': custom spell/item/slot,
    -- trinkets, racial, potions submenu and learned spells. Gold '+' and the '+'
    -- of a Buffs bar: custom aura, buff presets, class buffs and learned spells.
    --------------------------------------------------------------------------
    O.PICK_W,O.PICK_MAX_H,O.PICK_ITEM_H=240,350,26
    -- What the selected bar already tracks, for the greyed rows.
    function O.Tracked()
        local t={spell={},aura={},slot={},preset={},buff={},racial={}}
        for _,e in ipairs(O.List()) do
            local k,id=e.kind or "spell",tonumber(e.id)
            if k=="slot" or k=="preset" then t[k][id or e.id]=true
            elseif id then
                local n=GetSpellInfo(id); if n and t[k] then t[k][n]=true end
                if k=="spell" and ns.RACIAL_GROUP[id] then t.racial[ns.RACIAL_GROUP[id]]=true end
            end
            if e.preset then t.buff[e.preset]=true end
        end
        return t
    end
    -- The character's racial: the variant in the spellbook, else the race's first ID.
    function O.PlayerRacial()
        local _,race=UnitRace("player"); local list=race and ns.RACE_RACIALS[race]; if not list then return end
        for _,id in ipairs(list) do local n=GetSpellInfo(id); local m=n and ns.spells[n]; if m and m.id then return m.id,n end end
        local n=GetSpellInfo(list[1]); if n then return list[1],n end
    end
    -- Non-passive spells of the class tabs (the General tab holds racials and professions).
    function O.LearnedSpells()
        local general=0
        if GetSpellTabInfo then local _,_,off,num=GetSpellTabInfo(1); general=(off or 0)+(num or 0) end
        local seen,list={},{}
        for key,m in pairs(ns.spells or {}) do
            if type(key)=="string" and m.id and not m.passive and (m.slot or 0)>general and not seen[m.id] then seen[m.id]=true; list[#list+1]=m end
        end
        table.sort(list,function(a,b) return a.name<b.name end)
        return list
    end
    function O.ClassBuffs()
        local _,class=UnitClass("player"); local c=ns.catalog[class]; local seen,list={},{}
        for _,id in ipairs(c and c.buffs or {}) do
            local n,_,icon=GetSpellInfo(id); if n and not seen[n] then seen[n]=true; list[#list+1]={id=id,name=n,icon=icon} end
        end
        return list,seen
    end
    function O.ShowPicker(btn,slot,scroll)
        if O.picker then O.picker:Hide() end
        if O.menu then O.menu:Hide() end
        local S,IH,W=E.DD_STYLE or O.DDS,O.PICK_ITEM_H,O.PICK_W
        local buff=slot=="buff" or ns.IsBuffBar(O.Bar())
        local barName=O.Bar().name or O.Bar().key
        local menu=CreateFrame("Frame",nil,UIParent); O.picker=menu; menu.anchor,menu.items,menu.buff=btn,{},buff
        menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu:SetFrameLevel(300); menu:SetClampedToScreen(true); menu:EnableMouse(true); menu:EnableMouseWheel(true)
        menu:SetWidth(W); menu:SetPoint("TOP",btn,"BOTTOM",0,-4)
        O.Solid(menu,"BACKGROUND",S.BG_R,S.BG_G,S.BG_B,S.BG_HA):SetAllPoints()
        if E.MakeBorder then E.MakeBorder(menu,1,1,1,S.BRD_A,E.PanelPP) end
        -- Rows sit on the menu with explicit levels (as in O.BuildMenu) and scroll by being
        -- re-anchored and hidden outside the view; a ScrollFrame or inner frame drew nothing on 3.3.5.
        menu.offset=0
        local parts={}
        local h=4
        local function Row(parent,y,text,icon,used,onClick)
            local it=CreateFrame("Button",nil,parent); it:SetHeight(IH); it:SetFrameLevel(parent:GetFrameLevel()+2)
            it:SetPoint("TOPLEFT",parent,"TOPLEFT",1,-y); it:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-1,-y)
            local hl=O.Solid(it,"ARTWORK",1,1,1,1); hl:SetAllPoints(); hl:SetAlpha(0)
            local l=O.Font(it,11,.7,.7,.7,used and .3 or .85); l:SetJustifyH("LEFT"); l:SetPoint("LEFT",it,"LEFT",10,0); l:SetText(text)
            if icon then
                local t=it:CreateTexture(nil,"ARTWORK"); t:SetWidth(IH-2); t:SetHeight(IH-2); t:SetPoint("RIGHT",it,"RIGHT",-6,0)
                t:SetTexture(icon); t:SetTexCoord(.08,.92,.08,.92); it.icon=t
                if used then t:SetDesaturated(true); t:SetAlpha(.4) end
                l:SetPoint("RIGHT",t,"LEFT",-5,0)
            else l:SetPoint("RIGHT",it,"RIGHT",-8,0) end
            it.label,it.hl,it.used=l,hl,used
            if used then
                it:SetScript("OnEnter",function() hl:SetAlpha((S.ITEM_HL_A or .08)*.3); O.Tip(it,"Already on "..barName) end)
                it:SetScript("OnLeave",function() hl:SetAlpha(0); O.HideTip() end)
            else
                it:SetScript("OnEnter",function() l:SetTextColor(1,1,1,1); hl:SetAlpha(S.ITEM_HL_A or .08) end)
                it:SetScript("OnLeave",function() l:SetTextColor(.7,.7,.7,.85); hl:SetAlpha(0) end)
                if onClick then it:SetScript("OnClick",onClick) end
            end
            menu.items[text]=it
            return it
        end
        local function Add(text,icon,used,onClick) local it=Row(menu,h,text,icon,used,onClick); parts[#parts+1]={it,h,IH}; h=h+IH; return it end
        local function Div()
            local d=O.Solid(menu,"ARTWORK",1,1,1,.1); d:SetHeight(1)
            d:SetPoint("TOPLEFT",menu,"TOPLEFT",1,-h-4); d:SetPoint("TOPRIGHT",menu,"TOPRIGHT",-1,-h-4); parts[#parts+1]={d,h+4,1}; h=h+9
        end
        local function Close(fn) return function() menu:Hide(); fn() end end
        -- List rows keep the picker open: add, then reopen on the rebuilt '+' at the same scroll.
        local function Keep(kind,id) return function()
            local off=menu.offset or 0; O.AddEntry(kind,id)
            for _,s in ipairs(O.slots or {}) do if s.add==slot then O.ShowPicker(s,slot,off); return end end
        end end
        local function Popup(title,message,kind) return Close(function()
            if not E.ShowInputPopup then O.addKind=kind; O.Refresh(); O.Navigate(O.addY,O.addRow); return end
            E:ShowInputPopup({title=title,message=message,placeholder=kind=="slot" and "13" or "ID",confirmText="Add",cancelText="Cancel",
                onConfirm=function(v) O.AddEntry(kind,v and strtrim(v) or "") end})
        end) end
        local used=O.Tracked()
        if buff then
            Add("Custom Spell ID",nil,false,Popup("Custom Spell ID","Enter the spell ID of a buff or debuff to track:","aura"))
            Div()
            for _,p in ipairs(ns.BUFF_PRESETS) do Add(p.name,p.icon or select(3,GetSpellInfo(p.ids[1])),used.buff[p.key],Keep("buffpreset",p.key)) end
            local buffs,seen=O.ClassBuffs(); local learned={}
            for _,m in ipairs(O.LearnedSpells()) do if not seen[m.name] then learned[#learned+1]=m end end
            if #buffs+#learned>0 then Div() end
            for _,s in ipairs(buffs) do Add(s.name,s.icon,used.aura[s.name],Keep("aura",s.id)) end
            for _,m in ipairs(learned) do Add(m.name,m.icon,used.aura[m.name],Keep("aura",m.id)) end
        else
            Add("Custom Spell ID",nil,false,Popup("Custom Spell ID","Enter a spell ID to track:","spell"))
            Add("Custom Item ID",nil,false,Popup("Custom Item ID","Enter an item ID to track:","item"))
            Add("Equipment Slot",nil,false,Popup("Equipment Slot","Enter an equipment slot (1-19). Trinkets are 13 and 14.","slot"))
            Add("Empty Slot",nil,false,Close(function() O.AddEntry("empty") end))
            Div()
            for n,s in ipairs({13,14}) do
                Add("Trinket Slot "..n,GetInventoryItemTexture and GetInventoryItemTexture("player",s),used.slot[s],Close(function() O.AddEntry("slot",s) end))
            end
            local rid,rname=O.PlayerRacial()
            if rid then
                local _,_,icon=GetSpellInfo(rid)
                Add("Racial",icon,used.racial[ns.RACIAL_GROUP[rid] or rid] or used.spell[rname],Close(function() O.AddEntry("spell",rid) end))
            end
            local pot,sub
            local function ShowSub()
                if sub then sub:Show(); return end
                sub=CreateFrame("Frame",nil,menu); menu.sub=sub
                sub:SetFrameStrata("FULLSCREEN_DIALOG"); sub:SetFrameLevel(menu:GetFrameLevel()+10); sub:SetClampedToScreen(true); sub:EnableMouse(true)
                sub:SetWidth(220); sub:SetPoint("TOPLEFT",pot,"TOPRIGHT",2,0)
                O.Solid(sub,"BACKGROUND",S.BG_R,S.BG_G,S.BG_B,S.BG_HA):SetAllPoints()
                if E.MakeBorder then E.MakeBorder(sub,1,1,1,S.BRD_A,E.PanelPP) end
                local y=4
                for _,p in ipairs(ns.ITEM_PRESETS) do
                    Row(sub,y,p.name,GetItemIcon and GetItemIcon(p.items[1]),used.preset[p.key],Close(function() O.AddEntry("preset",p.key) end)); y=y+IH
                end
                sub:SetHeight(y+4)
            end
            pot=Add("Potions & Healthstone",nil,false,ShowSub); menu.pot=pot
            local arrow=O.Font(pot,12,.7,.7,.7,.7); arrow:SetPoint("RIGHT",pot,"RIGHT",-8,0); arrow:SetText(">")
            pot:SetScript("OnEnter",function() pot.label:SetTextColor(1,1,1,1); pot.hl:SetAlpha(S.ITEM_HL_A or .08); ShowSub() end)
            local spells=O.LearnedSpells()
            if #spells>0 then Div() end
            for _,m in ipairs(spells) do Add(m.name,m.icon,used.spell[m.name],Keep("spell",m.id)) end
        end
        local H=math.min(h+4,O.PICK_MAX_H); menu:SetHeight(H)
        local maxScroll=math.max(0,h+4-H); local thumb,th
        if maxScroll>0 then th=math.max(20,H*H/(h+4)); thumb=O.Solid(menu,"OVERLAY",1,1,1,.27); thumb:SetWidth(3); thumb:SetHeight(th) end
        local function SetScroll(v)
            v=math.max(0,math.min(maxScroll,v or 0)); menu.offset=v
            for _,p in ipairs(parts) do
                local f,y=p[1],p[2]-v
                f:ClearAllPoints(); f:SetPoint("TOPLEFT",menu,"TOPLEFT",1,-y); f:SetPoint("TOPRIGHT",menu,"TOPRIGHT",-1,-y)
                if p[2]>=v and p[2]+p[3]<=v+H then f:Show() else f:Hide() end
            end
            if thumb then thumb:ClearAllPoints(); thumb:SetPoint("TOPRIGHT",menu,"TOPRIGHT",-2,-(v/maxScroll)*(H-th)) end
        end
        menu.SetScroll=SetScroll
        menu:SetScript("OnMouseWheel",function(_,delta) SetScroll((menu.offset or 0)-delta*40) end)
        SetScroll(scroll)
        menu:SetScript("OnUpdate",function(m,elapsed)
            local s=m.sub; local overSub=s and s:IsShown() and s:IsMouseOver()
            if s and s:IsShown() and not overSub and not (m.pot and m.pot:IsMouseOver()) then
                m.subT=(m.subT or 0)+(elapsed or 0); if m.subT>.3 then s:Hide() end
            else m.subT=0 end
            if not m:IsMouseOver() and not btn:IsMouseOver() and not overSub and IsMouseButtonDown and IsMouseButtonDown("LeftButton") then m:Hide() end
        end)
        menu:SetScript("OnHide",function(m) m:SetScript("OnUpdate",nil); O.HideTip() end)
        menu:Show()
        return menu
    end
    function O.IconSlot(row,size,item)
        local b=CreateFrame("Button",nil,row); b:SetWidth(size); b:SetHeight(size)
        b:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp")
        O.Solid(b,"BACKGROUND",.08,.08,.08,.6):SetAllPoints()
        if E.MakeBorder then E.MakeBorder(b,item.add and .3 or 0,item.add and .3 or 0,item.add and .3 or 0,item.add and .5 or 1,E.PanelPP) end
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
        b.index,b.add=item.index,item.add
        if item.add then
            local gold=item.add=="buff"
            local r,g,bl=1,.82,.25
            if not gold and E.GetAccentColor then r,g,bl=E.GetAccentColor() end
            local plus=O.Font(b,22,r,g,bl,gold and .7 or .6); plus:SetPoint("CENTER",0,1); plus:SetText("+"); b.plus=plus
            local tip=(gold or ns.IsBuffBar(O.Bar())) and "Add a Buff Spell" or "Add a CD/Utility Spell"
            b:SetScript("OnEnter",function() plus:SetAlpha(1); O.Tip(b,tip) end)
            b:SetScript("OnLeave",function() plus:SetAlpha(gold and .7 or .6); O.HideTip() end)
            b:SetScript("OnClick",function()
                if O.picker and O.picker:IsShown() and O.picker.anchor==b then O.picker:Hide() else O.ShowPicker(b,item.add) end
            end)
            b:SetScript("OnHide",function() if O.picker and O.picker.anchor==b then O.picker:Hide() end end)
            return b
        end
        local icon=b:CreateTexture(nil,"ARTWORK"); icon:SetAllPoints(); icon:SetTexCoord(.07,.93,.07,.93); icon:SetTexture(item.tex); b.icon=icon
        if not item.ok then icon:SetDesaturated(true); icon:SetAlpha(.5) end
        if not item.index then b:EnableMouse(false); return b end
        local i,e=item.index,item.entry
        b:SetScript("OnEnter",function() if not O.drag then O.Tip(b,O.EntryName(e),"Click to edit. Middle-click to remove.") end end)
        b:SetScript("OnLeave",O.HideTip)
        b:SetScript("OnMouseDown",function(_,button)
            if button~="LeftButton" then return end
            local x,y=GetCursorPosition(); O.drag={from=i,x=x,y=y,tex=item.tex}
        end)
        b:SetScript("OnUpdate",function()
            local d=O.drag; if not d or d.from~=i then return end
            if not d.active then
                local x,y=GetCursorPosition()
                if math.abs(x-d.x)<3 and math.abs(y-d.y)<3 then return end
                d.active=true; O.HideTip(); local g=O.Ghost(); g.icon:SetTexture(d.tex); g:Show()
            end
            local _,s,after=O.DropSlot(); local line=O.insertLine
            if s and line then
                line:ClearAllPoints(); line:SetPoint("TOP",s,after and "TOPRIGHT" or "TOPLEFT",after and 2 or -2,2)
                line:SetHeight(s:GetHeight()+4); line:Show()
            end
        end)
        b:SetScript("OnMouseUp",function(_,button)
            if button~="LeftButton" then return end
            local d=O.StopDrag()
            if d and d.active then O.dragEnd=GetTime(); local to=O.DropSlot(); if to then O.MoveEntry(d.from,to) end end
        end)
        b:SetScript("OnClick",function(_,button)
            if O.dragEnd and GetTime()-O.dragEnd<.2 then return end
            if button=="MiddleButton" then
                table.remove(O.List(),i); ns.Apply(); O.Refresh()
            else
                O.entry=i; O.Refresh(); O.Navigate(O.entriesY,O.editRow)
            end
        end)
        return b
    end
    function O.IconRow(hdr,top)
        local bar=O.Bar(); local isKick=bar.barType=="focuskick"
        local size=math.max(20,math.min(48,bar.iconSize or 36)); local gap=math.max(2,math.min(10,bar.spacing or 2))
        local width=math.max(200,(hdr:GetWidth() or 700)-2*(E.CONTENT_PAD or 20))
        local items={}
        if isKick then
            local k=ns.KickEntry(bar); if k then local tex,ok=O.EntryIcon(k); items[1]={tex=tex,ok=ok} end
        else
            for i,e in ipairs(O.List()) do local tex,ok=O.EntryIcon(e); items[#items+1]={tex=tex,ok=ok and e.enabled~=false,index=i,entry=e} end
            items[#items+1]={add="main"}
            if not ns.IsBuffBar(bar) then items[#items+1]={add="buff"} end
        end
        local perRow=math.max(1,math.floor((width+gap)/(size+gap)))
        local rows=math.max(1,math.ceil(#items/perRow))
        local row=CreateFrame("Frame",nil,hdr); row:SetWidth(width); row:SetPoint("TOP",hdr,"TOP",0,top)
        O.slots={}
        for n,item in ipairs(items) do
            local r=math.floor((n-1)/perRow); local inRow=math.min(perRow,#items-r*perRow)
            local x=(width-(inRow*(size+gap)-gap))/2+((n-1)%perRow)*(size+gap)
            local b=O.IconSlot(row,size,item); b:SetPoint("TOPLEFT",row,"TOPLEFT",x,-r*(size+gap)); O.slots[#O.slots+1]=b
        end
        local line=O.Solid(row,"OVERLAY",.05,.82,.62,.9); line:SetWidth(2); line:Hide(); O.insertLine=line
        local eg=E.ELLESMERE_GREEN; if eg then line:SetTexture(eg.r,eg.g,eg.b,.9) end
        local gridH=rows*(size+gap)-gap
        local text
        if isKick then text=bar.focusKickUseTarget and "Shows your interrupt while your focus or target is casting." or "Shows your interrupt while your focus is casting."
        elseif ns.IsBuffBar(bar) then text="Drag to Reorder. Click to override display settings and add custom effects per icon"
        else text="Drag to Reorder. Click to add custom glows, active/cooldown state effects and more." end
        local hint=O.Font(row,11,.62,.62,.62,.9); hint:SetWidth(width-20); hint:SetJustifyH("CENTER")
        hint:SetPoint("TOP",row,"TOP",0,-(gridH+12)); hint:SetText(E.L and E.L(text) or text); O.hint=hint
        local h=gridH+12+math.max(14,hint:GetStringHeight() or 0)+6
        row:SetHeight(h)
        return h
    end
    function O.HeaderBuilder(hdr)
        if O.menu then O.menu:Hide() end
        if O.picker then O.picker:Hide() end
        O.StopDrag()
        local TOP,DD_H,GAP=20,34,10
        O.BarDropdown(hdr,-TOP)
        return TOP+DD_H+GAP+O.IconRow(hdr,-(TOP+DD_H+GAP))+GAP
    end
    function O.FocusKick(B)
        local s=O.Bar
        B.Section("FOCUSKICK OPTIONS")
        B.Row(O.I(s,"focusKickInterruptSpellID","Interrupt Spell",true,"Spell ID of the interrupt to show. 0 uses your class interrupt."),O.T(s,"focusKickUseTarget","Also Watch Target",nil,"Uses your target when no focus is casting."))
        B.Row(O.T(s,"focusReminderEnabled","Cast Reminder Text"),O.C(s,"focusReminder","Reminder Color",false))
        B.Row(O.S(s,"focusReminderSize","Reminder Size",8,32),O.D(s,"focusCastSoundKey","Cast Sound",O.sounds,O.soundOrder,nil,nil,"none"))
        B.Row(O.S(s,"focusReminderOffsetX","Reminder X",-200,200),O.S(s,"focusReminderOffsetY","Reminder Y",-200,200))
    end
    function O.Layout(B)
        local s=O.Bar
        local anchors,anchorOrder={none="None (Free Move)",mouse="Mouse Cursor"},{"none","mouse"}
        local overflow,overflowOrder={},{}
        for _,b in ipairs(ns.Bars()) do if b.key~=O.Bar().key then anchors[b.key]=b.name or b.key; anchorOrder[#anchorOrder+1]=b.key; overflow[b.key]=b.name or b.key; overflowOrder[#overflowOrder+1]=b.key end end
        B.Section("BAR LAYOUT")
        B.Row(O.S(s,"iconSize","Icon Size",16,80),O.S(s,"numRows","Rows",1,10))
        B.Row(O.S(s,"spacing","Spacing",0,20),O.D(s,"growDirection","Grow Direction",{RIGHT="Right",LEFT="Left",CENTER="Center"},{"RIGHT","LEFT","CENTER"}))
        B.Row(O.D(s,"rowGrowDirection","Row Grow Direction",{DOWN="Down",UP="Up"},{"DOWN","UP"}),O.T(s,"verticalOrientation","Vertical Orientation"))
        B.Row(O.S(s,"maxIcons","Max Icons",0,40,1,nil,"0 = no limit. Extra icons move to the overflow bar."),O.D(s,"overflowTarget","Overflow To",overflow,overflowOrder,function() return (O.Get(s,"maxIcons",0) or 0)==0 end))
        B.Row(O.D(s,"anchorTo","Anchor To",anchors,anchorOrder,nil,nil,"none"),O.D(s,"anchorPosition","Anchor Side",{left="Left",right="Right",top="Top",bottom="Bottom"},{"left","right","top","bottom"},function() local a=O.Get(s,"anchorTo","none"); return a=="none" or a=="mouse" end))
        B.Row(O.S(s,"anchorOffsetX","Anchor Offset X",-300,300),O.S(s,"anchorOffsetY","Anchor Offset Y",-300,300))
        B.Row(O.P(s,"barOpacity","Bar Opacity"),O.D(s,"barStrata","Frame Strata",O.strata,O.strataOrder,nil,nil,"MEDIUM"))
        B.Row(O.T(s,"oocFadeEnabled","Fade Out of Combat"),O.P(s,"oocFadeAlpha","Out of Combat Opacity",function() return not O.Get(s,"oocFadeEnabled") end))
        B.Row(O.D(s,"sort","Icon Order",{assigned="Assigned Order",remaining="Remaining Duration"},{"assigned","remaining"}),O.T(s,"suppressGCD","Ignore Global Cooldown"))
        B.Visibility(s)
        B.Row(O.T(s,"barBgEnabled","Bar Background"),O.C(s,"barBg","Bar Background Color",true,function() return not O.Get(s,"barBgEnabled") end))
        B.Section("ADDITIONAL BAR OFFSET")
        B.Row(O.S(s,"addOffsetX","Offset X",-200,200),O.S(s,"addOffsetY","Offset Y",-200,200))
    end
    function O.IconDisplay(B)
        local s=O.Bar; local tv,to=O.BorderTextures()
        local hasEdge=ns.D and ns.D.HasDrawEdge
        B.Section("ICON DISPLAY")
        B.Row(O.S(s,"iconZoom","Icon Zoom",0,.3,.01),O.D(s,"iconShape","Icon Shape",{none="Square",cropped="Cropped",circle="Circle"},{"none","cropped","circle"}))
        B.Row(O.S(s,"iconCropPercent","Crop Amount",5,25,1,function() return O.Get(s,"iconShape")~="cropped" end),O.C(s,"bg","Icon Background",true))
        B.Row(O.S(s,"borderSize","Border Size",0,8),O.C(s,"border","Border Color",true,function() return O.Get(s,"borderClassColor") end))
        B.Row(O.D(s,"borderTexture","Border Style",tv,to,nil,nil,"solid"),O.T(s,"borderClassColor","Class Colored Border"))
        B.Row(O.T(s,"showCooldownText","Cooldown Text"),O.S(s,"cooldownFontSize","Cooldown Text Size",6,32))
        B.Row(O.D(s,"cooldownTextPosition","Cooldown Text Position",O.textPos,O.textPosOrder),O.C(s,"cooldownText","Cooldown Text Color",false))
        B.Row(O.S(s,"cooldownTextX","Cooldown Text X",-30,30),O.S(s,"cooldownTextY","Cooldown Text Y",-30,30))
        B.Row(O.T(s,"showItemCount","Stacks / Item Count"),O.S(s,"stackCountSize","Stack Text Size",6,32))
        B.Row(O.D(s,"stackCountPosition","Stack Text Position",O.textPos,O.textPosOrder),O.C(s,"stackCount","Stack Text Color",false))
        B.Row(O.T(s,"showKeybind","Show Keybinds"),O.S(s,"keybindSize","Keybind Size",6,24))
        B.Row(O.D(s,"keybindAnchor","Keybind Position",O.corner,O.cornerOrder),O.C(s,"keybind","Keybind Color",true))
        B.Row(O.T(s,"showTooltip","Show Tooltip"),O.T(s,"desaturateOnCD","Desaturate on Cooldown"))
        B.Row(O.T(s,"showRange","Out of Range Color"),O.C(s,"range","Range Color",false,function() return not O.Get(s,"showRange") end))
        B.Row(O.T(s,"showNoMana","Not Enough Mana Color"),O.C(s,"mana","Mana Color",false,function() return not O.Get(s,"showNoMana") end))
        B.Row(O.P(s,"swipeAlpha","Swipe Opacity"),O.T(s,"showCooldownEdge","Cooldown Edge",function() return not hasEdge or O.Get(s,"swipeStyle")=="texture" end,"Bright line on the swipe edge (needs a client with Cooldown:SetDrawEdge; native swipe only)."))
        B.Row(O.D(s,"swipeStyle","Swipe Style",{native="Native",texture="Shaped"},{"native","texture"},nil,"Native: the client's dark square sweep. Shaped: a drawn sweep that follows round icons and takes the Swipe Color.","native"),
            O.C(s,"swipe","Swipe Color",false,function() return O.Get(s,"swipeStyle")~="texture" end))
        B.Row(O.T(s,"onlyShowNumbers","Only Show Numbers",nil,"Hides the swipe and keeps the timer."),O.T(s,"pressMirror","Show Key Presses",nil,"Flashes the icon when its action button is pressed."))
        B.Row(O.T(s,"showPassiveTrinkets","Show Passive Trinkets"),O.T(s,"hideItemsIfMissing","Hide Missing Items"))
        if ns.IsBuffBar(O.Bar()) then
            B.Row(O.T(s,"showInactiveBuffIcons","Always Show Buffs"),O.T(s,"desaturateInactiveBuffs","Desaturate Inactive Buffs",function() return not O.Get(s,"showInactiveBuffIcons") end))
            B.Row(O.T(s,"hidePlaceholderIcon","Keep Buffs in Same Place"),O.spacer)
        end
    end
    function O.Extras(B)
        local s,d=O.Bar,O.Defaults
        B.Section("EXTRAS")
        B.Row(O.D(d,"cdStateEffect","Cooldown State",O.cse,O.cseOrder,nil,"Default for every icon on this bar; icons can override it. "..O.cseTip,"none"),O.P(d,"cdStateLowerAlpha","Lower Opacity Amount"))
        B.Row(O.D(s,"procGlowStyle","Proc Glow",O.glow,O.glowOrder),O.D(d,"activeGlow","Active Aura Glow",O.glow,O.glowOrder,nil,nil,0))
        B.Row(O.T(s,"activeState","Show Active State",nil,"Spell icons show your own short buff from that spell instead of the cooldown."),O.D(s,"buffGlow","Buff Glow",O.glow,O.glowOrder,nil,nil,0))
        B.Row(O.T(s,"pandemicGlow","Pandemic Glow",nil,"Glow when an aura has 30% or less of its duration left."),O.D(s,"pandemicGlowStyle","Pandemic Glow Style",O.glow,O.glowOrder,function() return not O.Get(s,"pandemicGlow") end))
        B.Row(O.C(s,"pandemic","Pandemic Glow Color",false),O.S(s,"pixelGlowLines","Pixel Glow Lines",2,16))
        B.Row(O.S(s,"pixelGlowThickness","Pixel Glow Thickness",1,6),O.S(s,"pixelGlowSpeed","Pixel Glow Speed",1,10))
    end
    function O.Entries(B)
        local list=O.List(); local values,order={},{}
        for i,e in ipairs(list) do
            local m=ns.Resolve(e,O.Bar()); values[i]=i..". "..(m and m.name or ((e.kind or "spell").." "..tostring(e.id))); order[#order+1]=i
        end
        O.entriesY=B.y
        B.Section("TRACKED SPELLS")
        if #order==0 then B.Row(O.Label("No entries on this bar."),O.spacer); return end
        O.entry=math.max(1,math.min(O.entry,#order))
        local e=O.Entry(); local Ent=O.Entry
        O.editRow=B.Row({type="dropdown",text="Edit Entry",values=values,order=order,getValue=function() return O.entry end,setValue=function(v) O.entry=v; O.Refresh() end},O.T(Ent,"enabled","Enable Entry"))
        if e.kind=="aura" then
            B.Row(O.D(Ent,"unit","Aura Unit",O.units,O.unitOrder,nil,nil,"player"),O.D(Ent,"filter","Aura Type",O.filters,O.filterOrder,nil,nil,"HELPFUL"))
            B.Row(O.T(Ent,"ownOnly","Own Auras Only"),O.T(Ent,"alwaysShow","Always Show",nil,"Keeps the icon visible (dimmed) while the aura is down."))
            B.Row(O.ED("buffGlow","Buff Glow",O.glowD,O.glowDOrder),O.S(Ent,"maxStacks","Max Stacks",0,20,1,nil,"0 = off"))
            B.Row(O.D(Ent,"maxStacksGlow","Max Stacks Glow",O.glow,O.glowOrder,nil,nil,0),O.C(Ent,"glowColor","Glow Color",false))
        elseif e.kind=="empty" then
            B.Row(O.Label("Empty Slot: keeps this position free on the bar."),O.spacer)
        else
            B.Row(O.ED("cdStateEffect","Cooldown State",O.cseD,O.cseDOrder),O.ED("cdStateGlowStyle","Ready Glow Style",O.glowD,O.glowDOrder))
            if e.kind=="spell" then
                B.Row(O.ED("procGlow","Proc Glow",O.glowD,O.glowDOrder),O.ED("activeGlow","Active Aura Glow",O.glowD,O.glowDOrder))
                B.Row(O.I(Ent,"procAuraID","Proc Aura ID",true,"Buff that marks this spell as proc'd (0 = built-in list)."),O.S(Ent,"procStacks","Proc Stacks",0,10))
                B.Row(O.I(Ent,"activeAuraID","Active Aura ID",true,"Buff shown as the active state (0 = same-named buff)."),O.I(Ent,"activeDuration","Active Duration",true,"Seconds to show the active state after a cast, for spells without a buff."))
                B.Row(O.T(Ent,"activeBorderEnabled","Active Border"),O.C(Ent,"activeBorder","Active Border Color",true))
            end
            B.Row(O.T(Ent,"reverseSwipe","Reverse Swipe"),O.T(Ent,"hideCDSwipe","Hide Swipe"))
            B.Row(O.T(Ent,"suppressGCD","Ignore Global Cooldown"),O.C(Ent,"glowColor","Glow Color",false))
        end
        B.Row(O.I(Ent,"customIcon","Custom Icon",false,"Spell ID or texture path."),O.spacer)
        B.Row(O.I(Ent,"talentName","Talent Condition",false,"Talent name; the entry only shows when the condition matches."),
            {type="dropdown",text="Talent Must Be",values={taken="Taken",missing="Not Taken"},order={"taken","missing"},
                disabled=function() local x=O.Get(Ent,"talentName"); return not x or x=="" end,
                getValue=function() return O.Get(Ent,"talentTaken")==false and "missing" or "taken" end,
                setValue=function(v) O.Set(Ent,"talentTaken",v~="missing") end})
        B.Button("Move Entry Up",function() local l=O.List(); local i=O.entry; if i>1 then l[i],l[i-1]=l[i-1],l[i]; O.entry=i-1; ns.Apply(); O.Refresh() end end)
        B.Button("Move Entry Down",function() local l=O.List(); local i=O.entry; if i<#l then l[i],l[i+1]=l[i+1],l[i]; O.entry=i+1; ns.Apply(); O.Refresh() end end)
        B.Button("Remove Entry",function() table.remove(O.List(),O.entry); ns.Apply(); O.Refresh() end)
    end
    function O.AddEntry(kind,id)
        local l=O.List(); local isPreset=kind=="preset" or kind=="buffpreset"
        if #l>=40 then O.status="Maximum 40 entries per bar"; O.Refresh(); return end
        if kind=="empty" then
            l[#l+1]={kind="empty",enabled=true}; O.entry=#l
            O.status="Empty Slot added."; ns.Apply(); O.Refresh(); return
        end
        if not isPreset then
            id=tonumber(id)
            if not id or id<1 or id~=math.floor(id) or kind=="slot" and id>19 then O.status="Enter a valid ID or equipment slot 1-19"; O.Refresh(); return end
            if (kind=="spell" or kind=="aura") and not GetSpellInfo(id) then O.status="Spell ID unavailable in this client"; O.Refresh(); return end
        end
        local entry
        if kind=="buffpreset" then local p=ns.BUFF_PRESET_BY_KEY[id]; if not p then return end; entry={kind="aura",id=p.ids[1],preset=id,unit="player",filter="HELPFUL",enabled=true}
        else entry={kind=kind,id=id,enabled=true,unit="player",filter="HELPFUL"} end
        l[#l+1]=entry; O.entry=#l
        O.status="Added. Unlearned spells and empty slots stay hidden."; ns.Apply(); O.Refresh()
    end
    function O.Add(B)
        O.addY=B.y
        B.Section("ADD ENTRY")
        O.addRow=B.Row({type="dropdown",text="Entry Type",values={spell="Spell Cooldown",aura="Buff / Debuff",item="Item Cooldown",slot="Equipment Slot",empty="Empty Slot"},order={"spell","aura","item","slot","empty"},
            getValue=function() return O.addKind end,setValue=function(v) O.addKind=v end},{type="input",text="Spell / Item ID",getValue=function() return O.addID end,setValue=function(v) O.addID=v end})
        B.Button("Add Entry",function() O.AddEntry(O.addKind,O.addID) end)
        local learned,lo={},{}
        for key,m in pairs(ns.spells or {}) do if type(key)=="string" and m.id and not m.passive and not learned[m.id] then learned[m.id]=m.name; lo[#lo+1]=m.id end end
        table.sort(lo,function(a,b) return learned[a]<learned[b] end)
        B.Row({type="dropdown",text="Add Learned Spell",values=learned,order=lo,getValue=function() return nil end,setValue=function(v) O.AddEntry("spell",v) end},O.Label(O.status))
        local racial,ro,rn={},{},{}
        for _,id in ipairs(ns.racials) do local n=GetSpellInfo(id); if n and not rn[n] then rn[n]=true; racial[id]=n; ro[#ro+1]=id end end
        local items,io={},{}; for _,p in ipairs(ns.ITEM_PRESETS) do items[p.key]=p.name; io[#io+1]=p.key end
        B.Row({type="dropdown",text="Add Racial",values=racial,order=ro,getValue=function() return nil end,setValue=function(v) O.AddEntry("spell",v) end},
            {type="dropdown",text="Add Item Preset",values=items,order=io,getValue=function() return nil end,setValue=function(v) O.AddEntry("preset",v) end})
        local buffs,bo={},{}; for _,p in ipairs(ns.BUFF_PRESETS) do buffs[p.key]=p.name; bo[#bo+1]=p.key end
        B.Row({type="dropdown",text="Add Buff Preset",values=buffs,order=bo,getValue=function() return nil end,setValue=function(v) O.AddEntry("buffpreset",v) end},O.spacer)
        B.Button("Copy This Bar to Other Talent Group",function()
            local other=ns.ListsFor(ns.OtherSpecKey()); if other then other[O.Bar().key]=ns.Copy(O.List()); O.status="Copied to "..ns.OtherSpecKey(); O.Refresh() end
        end)
        B.Button("Restore Default Assignments For This Bar",function()
            local _,class=UnitClass("player"); local seed=ns.SeedLists(class)[O.Bar().key]
            ns.Lists()[O.Bar().key]=seed or {}; O.entry=1; ns.Apply(); O.Refresh()
        end)
    end
    function O.CDMBars(B)
        if ns.selectedEntry then
            for i,e in ipairs(O.List()) do if e==ns.selectedEntry then O.entry=i end end
            ns.selectedEntry=nil
        end
        O.entriesY,O.editRow,O.addY,O.addRow=nil,nil,nil,nil
        O.BarSelect(B)
        if O.Bar().barType=="focuskick" then O.FocusKick(B) end
        O.Layout(B); O.IconDisplay(B); O.Extras(B)
        if O.Bar().barType~="focuskick" then O.Entries(B); O.Add(B) end
        B.Section("POSITION")
        B.Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
        B.Button("Reset Bar Position",function() ns.Profile().positions[O.Bar().key]=nil; ns.Apply() end)
    end

    --------------------------------------------------------------------------
    -- Page: Bar Glows
    --------------------------------------------------------------------------
    function O.BarGlows(B)
        local g=O.Glows(); if not g then return end
        g.list=g.list or {}
        B.Section("BAR GLOWS")
        B.Row(O.T(O.Glows,"enabled","Enable Bar Glows",nil,"Glows action buttons (EUI, Blizzard and ElvUI bars) while an aura is up or missing."),O.Label("Assignments: "..ns.SpecKey()))
        local values,order={},{}
        for i,r in ipairs(g.list) do
            local a=GetSpellInfo(tonumber(r.auraID) or 0) or ("Aura "..tostring(r.auraID)); local s=GetSpellInfo(tonumber(r.spellID) or 0) or ("Spell "..tostring(r.spellID))
            values[i]=i..". "..a.." > "..s; order[#order+1]=i
        end
        if #order>0 then
            O.rule=math.max(1,math.min(O.rule,#order))
            local R=O.Rule
            B.Row({type="dropdown",text="Select Glow",values=values,order=order,getValue=function() return O.rule end,setValue=function(v) O.rule=v; O.Refresh() end},O.T(R,"enabled","Enable Glow"))
            B.Row(O.I(R,"auraID","Aura Spell ID",true,"Buff or debuff to watch."),O.I(R,"spellID","Action Button Spell ID",true,"Every action button holding this spell glows."))
            B.Row(O.D(R,"unit","Aura Unit",O.units,O.unitOrder,nil,nil,"player"),O.D(R,"filter","Aura Type",O.filters,O.filterOrder,nil,nil,"HELPFUL"))
            B.Row(O.D(R,"mode","Glow When",{active="Aura Active",missing="Aura Missing"},{"active","missing"},nil,nil,"active"),O.T(R,"ownOnly","Own Auras Only"))
            B.Row(O.S(R,"atStacks","At Stacks",0,20,1,nil,"0 = any stack count"),O.T(R,"onlyInCombat","Only In Combat"))
            B.Row(O.D(R,"glowType","Glow Type",O.glow,O.glowOrder,nil,nil,1),O.C(R,"glow","Glow Color",false))
            B.Button("Remove Glow",function() table.remove(g.list,O.rule); ns.Apply(); O.Refresh() end)
        else B.Row(O.Label("No bar glows yet."),O.spacer) end
        B.Button("Add Glow",function() g.list[#g.list+1]=ns.NewBarGlowRule(); O.rule=#g.list; ns.Apply(); O.Refresh() end)
    end

    --------------------------------------------------------------------------
    -- Page: Tracking Bars
    --------------------------------------------------------------------------
    function O.TBBSelect(B)
        local list=ns.TBBList(); local values,order={},{}
        for i,c in ipairs(list) do
            local n=(c.preset and ns.BUFF_PRESET_BY_KEY[c.preset] and ns.BUFF_PRESET_BY_KEY[c.preset].name) or GetSpellInfo(tonumber(c.spellID) or 0) or c.name or "Bar"
            values[i]=i..". "..n; order[#order+1]=i
        end
        B.Section("TRACKING BARS")
        B.Row(O.T(ns.Profile,"tbbSmooth","Smooth Animation"),O.T(ns.Profile,"useClassicStyleBars","Classic Bar Style"))
        if #order>0 then
            B.Row({type="dropdown",text="Select Bar",values=values,order=order,getValue=function() return ns.selectedTBB end,setValue=function(v) ns.selectedTBB=v; O.Refresh() end},O.T(O.TBB,"enabled","Enable Bar"))
        end
        B.Button("Add Tracking Bar",function() local _,i=ns.AddTrackedBar(0); if i then ns.selectedTBB=i end; ns.Apply(); O.Refresh() end)
        if #order>0 then B.Button("Remove Selected Bar",function()
            local i=ns.selectedTBB; table.remove(list,i)
            local pos=ns.Profile().positions
            for j=i,#list do pos["TBB_"..j]=pos["TBB_"..(j+1)] end
            pos["TBB_"..(#list+1)]=nil
            ns.selectedTBB=math.max(1,i-1); ns.Apply(); O.Refresh()
        end) end
        return #order>0
    end
    function O.TBBTracking(B)
        local s=O.TBB
        local buffs,bo={none="None"},{"none"}; for _,p in ipairs(ns.BUFF_PRESETS) do buffs[p.key]=p.name; bo[#bo+1]=p.key end
        B.Section("TRACKING")
        B.Row(O.D(s,"trackType","Track",{aura="Buff / Debuff",cooldown="Spell Cooldown"},{"aura","cooldown"},nil,nil,"aura"),O.I(s,"spellID","Spell ID",true))
        B.Row(O.I(s,"name","Bar Name",false),{type="dropdown",text="Buff Preset",values=buffs,order=bo,getValue=function() return O.Get(s,"preset") or "none" end,
            setValue=function(v) O.Set(s,"preset",v~="none" and v or nil) end})
        local auraOff=function() return O.Get(s,"trackType")=="cooldown" end
        B.Row(O.D(s,"unit","Aura Unit",O.units,O.unitOrder,auraOff,nil,"player"),O.D(s,"filter","Aura Type",O.filters,O.filterOrder,auraOff,nil,"HELPFUL"))
        B.Row(O.T(s,"ownOnly","Own Auras Only",auraOff),O.T(s,"fillUp","Fill Up",function() return not auraOff() end,"Cooldown bars fill as the cooldown recovers."))
        B.Row(O.T(s,"hideWhenInactive","Hide When Inactive"),O.T(s,"onlyInCombat","Only In Combat"))
        B.Visibility(s)
    end
    function O.TBBLayout(B)
        local s=O.TBB; local texOrder={}
        for _,k in ipairs(ns.TBB_TEXTURE_ORDER) do texOrder[#texOrder+1]=k end
        B.Section("BAR LAYOUT")
        B.Row(O.S(s,"width","Width",40,800),O.S(s,"height","Height",4,80))
        B.Row(O.T(s,"verticalOrientation","Vertical"),O.T(s,"reverseFill","Reverse Fill"))
        B.Row(O.D(s,"texture","Bar Texture",ns.TBB_TEXTURE_NAMES,texOrder,nil,nil,"none"),O.D(s,"barStrata","Frame Strata",O.strata,O.strataOrder,nil,nil,"MEDIUM"))
        B.Row(O.C(s,"fill","Fill Color",true,function() return O.Get(s,"useClassColor") end),O.T(s,"useClassColor","Class Colored Fill"))
        B.Row(O.C(s,"bg","Background Color",true),O.P(s,"opacity","Opacity"))
        B.Row(O.T(s,"gradientEnabled","Enable Gradient"),O.C(s,"gradient","Gradient End Color",true,function() return not O.Get(s,"gradientEnabled") end))
        B.Row(O.D(s,"gradientDir","Gradient Direction",{HORIZONTAL="Horizontal",VERTICAL="Vertical"},{"HORIZONTAL","VERTICAL"},function() return not O.Get(s,"gradientEnabled") end),O.T(s,"showSpark","Show Spark"))
        B.Row(O.S(s,"borderSize","Border Size",0,8),O.C(s,"border","Border Color",true))
        B.Row(O.D(s,"iconDisplay","Icon",{none="Hidden",left="Left",right="Right"},{"none","left","right"},nil,nil,"left"),O.S(s,"iconBorderSize","Icon Border",0,4))
        B.Row(O.S(s,"iconX","Icon X",-50,50),O.S(s,"iconY","Icon Y",-50,50))
    end
    function O.TBBText(B)
        local s=O.TBB; local pos={left="Left",center="Center",right="Right",top="Top",bottom="Bottom"}; local po={"left","center","right","top","bottom"}
        B.Section("TEXT")
        B.Row(O.T(s,"showName","Show Name"),O.S(s,"nameSize","Name Size",6,24))
        B.Row(O.D(s,"namePosition","Name Position",pos,po),O.C(s,"nameText","Name Color",true))
        B.Row(O.S(s,"nameX","Name X",-50,50),O.S(s,"nameY","Name Y",-50,50))
        B.Row(O.T(s,"showTimer","Show Timer"),O.S(s,"timerSize","Timer Size",6,24))
        B.Row(O.D(s,"timerPosition","Timer Position",pos,po),O.C(s,"timerText","Timer Color",true))
        B.Row(O.S(s,"timerX","Timer X",-50,50),O.S(s,"timerY","Timer Y",-50,50))
        B.Row(O.T(s,"decimals","Show Decimals"),O.S(s,"decimalThreshold","Decimals Below",1,30,1,function() return not O.Get(s,"decimals") end))
        B.Row(O.D(s,"stacksPosition","Stacks Position",pos,po),O.S(s,"stacksSize","Stacks Size",6,24))
        B.Row(O.C(s,"stacksText","Stacks Color",true),O.spacer)
    end
    function O.TBBStacks(B)
        local s=O.TBB
        local thr=function() return not O.Get(s,"stackThresholdEnabled") end
        local mx=function() return not O.Get(s,"stackThresholdMaxEnabled") end
        B.Section("STACKS")
        B.Row(O.T(s,"stackThresholdEnabled","Stack Threshold Color"),O.S(s,"stackThreshold","At Stacks",1,50,1,thr))
        B.Row(O.C(s,"stackThreshold","Threshold Color",true,thr),O.T(s,"stackBasedBar","Fill by Stacks",nil,"The bar shows stacks out of the maximum instead of time."))
        B.Row(O.T(s,"stackThresholdMaxEnabled","Stack Ticks"),O.S(s,"stackThresholdMax","Max Stacks",1,100,1,mx))
        B.Row(O.I(s,"stackThresholdTicks","Ticks at Stacks",false,"Comma separated, e.g. 3,5"),O.C(s,"stackThresholdTick","Tick Color",true,mx))
        B.Section("PANDEMIC GLOW")
        local pg=function() return not O.Get(s,"pandemicGlow") end
        B.Row(O.T(s,"pandemicGlow","Pandemic Glow",nil,"Glows in the last 30% of the duration."),O.D(s,"pandemicGlowStyle","Glow Style",{[1]="Pixel Glow",[4]="Auto-Cast Shine"},{1,4},pg))
        B.Row(O.C(s,"pandemicGlow","Glow Color",false,pg),O.S(s,"pandemicGlowLines","Lines",2,16,1,pg))
        B.Row(O.S(s,"pandemicGlowThickness","Thickness",1,6,1,pg),O.S(s,"pandemicGlowSpeed","Speed",1,10,1,pg))
    end
    function O.TBBGroups(B)
        local s=O.TBB; local G=O.TBBGroupStore; local off=function() return not G() end
        B.Section("GROUP SETTINGS")
        B.Row(O.D(s,"groupID","Group",{[0]="None",[1]="Group 1",[2]="Group 2",[3]="Group 3",[4]="Group 4"},{0,1,2,3,4},nil,"Grouped bars stack together and share one mover.",0),
            O.D(G,"growDirection","Grow Direction",{DOWN="Down",UP="Up",RIGHT="Right",LEFT="Left"},{"DOWN","UP","RIGHT","LEFT"},off,nil,"DOWN"))
        B.Row(O.S(G,"spacing","Group Spacing",0,40,1,off),O.T(G,"autoAdd","Add New Bars to Group",off))
    end
    function O.TrackingBars(B)
        if O.TBBSelect(B) and O.TBB() then O.TBBTracking(B); O.TBBLayout(B); O.TBBText(B); O.TBBStacks(B); O.TBBGroups(B) end
        B.Section("POSITION")
        B.Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
        B.Button("Reset Tracking Bar Positions",function()
            local pos=ns.Profile().positions
            for i=1,20 do pos["TBB_"..i]=nil end; for gid=1,4 do pos["TBBG_"..gid]=nil end
            ns.Apply()
        end)
    end
    E:RegisterModule("EllesmereUICooldownManager",{title="Cooldown Manager",description="Wrath spells, items and auras. Assignments are saved for each dual talent group.",
        pages={"CDM Bars","Bar Glows","Tracking Bars"},
        searchTerms="cooldown manager CDM tracking bars buffs debuffs spell aura item equipment trinket glow keybind duration stacks range preview focus kick interrupt pandemic racial potion",
        buildPage=function(page,parent,y)
            local B=O.Context(E.Widgets,parent,y)
            O.Header(B)
            if page=="Bar Glows" then O.BarGlows(B)
            elseif page=="Tracking Bars" then O.TrackingBars(B)
            else
                O.CDMBars(B)
                if E.SetContentHeader and not E._prebuilding then E:SetContentHeader(O.HeaderBuilder) end
            end
            return math.abs(B.y)
        end,
        getHeaderBuilder=function(page) if page=="CDM Bars" then return O.HeaderBuilder end end,
        onReset=function() ns.addon.db:ResetProfile(); ns.unlockSig=nil; ns.Apply(); O.Refresh() end})
    if E.RegisterOnHide then E:RegisterOnHide(function() ns.optionsPreview=false; ns.preview=ns.unlockPreview; ns.Update() end) end
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
