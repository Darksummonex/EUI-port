local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
-- Retail page layout over the Wrath engine; only implemented controls are exposed.
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIActionBars
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local PAGE_DISPLAY,PAGE_HUD,PAGE_ANIM="Bar Display","Menu, Bags & XP Bars","Bar Animations"
    local byKey,barLabels,barOrder,shortLabels={},{},{},{}
    for _,d in ipairs(ns.definitions) do
        byKey[d.key]=d; barLabels[d.key]=d.label; barOrder[#barOrder+1]=d.key
        shortLabels[d.key]=d.label:gsub("Action ","")
    end
    local function Key()
        if not byKey[ns.selectedWrathBar] then ns.selectedWrathBar=barOrder[1] end
        return ns.selectedWrathBar
    end
    local function SB() return ns.GetSettings(Key()) end
    local function Root() return ns.GetSettings() end
    local function HUD() return ns.GetSettings().nativeHUD end
    local function Clamp(v,a,b) return math.max(a,math.min(b,tonumber(v) or a)) end
    function ns.SelectWrathBar(key,refresh)
        if not byKey[key] then return end
        ns.selectedWrathBar=key
        if E.InvalidateContentHeaderCache then E:InvalidateContentHeaderCache() end
        if E.InvalidatePageCache then E:InvalidatePageCache() end
        if refresh~=false and E.RefreshPage then E:RefreshPage(true) end
    end
    -- Unlock mode shortcuts open the matching page with the relevant bar selected.
    ns.RegisterSettingsTargets()

    local UpdatePreview
    local function Changed() ns.Apply(); if UpdatePreview then UpdatePreview() end end
    local function Cfg(store,kind,key,label,extra)
        local cfg={type=kind,text=label,
            getValue=function() local s=store(); return s and s[key] end,
            setValue=function(v) local s=store(); if s then s[key]=v; Changed() end end}
        for k,v in pairs(extra or {}) do cfg[k]=v end
        return cfg
    end
    -- Rows write to the bar they were built for, even if a stale widget fires after a switch.
    local function BarStore() local k=Key(); return function() return ns.GetSettings(k) end end
    local function Toggle(key,label,extra) return Cfg(BarStore(),"toggle",key,label,extra) end
    local function Slider(key,label,low,high,step,extra)
        extra=extra or {}; extra.min,extra.max,extra.step=low,high,step or 1
        return Cfg(BarStore(),"slider",key,label,extra)
    end
    local function Dropdown(key,label,values,order,extra)
        extra=extra or {}; extra.values,extra.order=values,order
        return Cfg(BarStore(),"dropdown",key,label,extra)
    end
    local function RootToggle(key,label,extra) return Cfg(Root,"toggle",key,label,extra) end
    local function RootSlider(key,label,low,high,step,extra)
        extra=extra or {}; extra.min,extra.max,extra.step=low,high,step or 1
        return Cfg(Root,"slider",key,label,extra)
    end
    local function HUDCfg(kind,key,label,low,high,step,fallback,extra)
        local cfg={type=kind,text=label,min=low,max=high,step=step,
            getValue=function()
                local p=HUD(); local v=p and p[key]
                if v==nil and fallback then v=p and p[fallback] end
                return v
            end,
            setValue=function(v) local p=HUD(); if p then p[key]=v; ns.Apply() end end}
        for k,v in pairs(extra or {}) do cfg[k]=v end
        return cfg
    end
    local BLANK={type="label",text=""}
    local function Blank() return E.BlankRowCfg and E.BlankRowCfg() or BLANK end
    local function Off(key,label) local store=BarStore(); return {disabled=function() return not store()[key] end,disabledTooltip=label} end
    local function NativeOff()
        local native=byKey[Key()].native~=nil
        return {disabled=function() return native end,disabledTooltip="Pet and stance slots follow Blizzard's own layout",rawTooltip=true}
    end

    -- Inline widgets (Retail idiom): chained right-to-left left of the row control.
    local function Inline(rgn) return rgn and not E._prebuilding and rgn end
    local function Chain(rgn,widget,gap)
        widget:ClearAllPoints()
        local anchor=rgn._lastInline or rgn._control
        if anchor then widget:SetPoint("RIGHT",anchor,"LEFT",-(gap or 12),0)
        else widget:SetPoint("RIGHT",rgn,"RIGHT",-20,0) end
        rgn._lastInline=widget
    end
    local function Swatch(rgn,store,key,hasAlpha,off,tip)
        if not Inline(rgn) or not E.BuildColorSwatch then return end
        local get=function() local c=store()[key] or {r=1,g=1,b=1,a=1}; return c.r,c.g,c.b,c.a or 1 end
        local set=function(r,g,b,a) store()[key]={r=r,g=g,b=b,a=hasAlpha and a or 1}; Changed() end
        local sw,update=E.BuildColorSwatch(rgn,rgn:GetFrameLevel()+5,get,set,hasAlpha,20)
        Chain(rgn,sw)
        if tip then
            sw:HookScript("OnEnter",function(btn) E.ShowWidgetTooltip(btn,tip) end)
            sw:HookScript("OnLeave",function() E.HideWidgetTooltip() end)
        end
        local function State()
            local disabled=off and off()
            sw:SetAlpha(disabled and .15 or 1); sw:EnableMouse(not disabled); update()
        end
        State(); E.RegisterWidgetRefresh(State)
        return sw
    end
    local function CogSlider(store,key,label,low,high,step)
        return {type="slider",label=label,min=low,max=high,step=step or 1,get=function() return store()[key] end,set=function(v) store()[key]=v; Changed() end}
    end
    local function CogToggle(store,key,label)
        return {type="toggle",label=label,get=function() return store()[key] end,set=function(v) store()[key]=v; Changed() end}
    end
    local function CogDropdown(store,key,label,values,order)
        return {type="dropdown",label=label,values=values,order=order,get=function() return store()[key] end,set=function(v) store()[key]=v; Changed() end}
    end
    local function Cog(rgn,title,rows,opts)
        if not Inline(rgn) or not E.BuildInlineCog then return end
        opts=opts or {}
        opts.title,opts.rows,opts.captureRegion=title,rows,rgn
        return E.BuildInlineCog(rgn,opts)
    end
    local function CopyValue(v)
        if type(v)~="table" then return v end
        local t={}; for k,x in pairs(v) do t[k]=CopyValue(x) end; return t
    end
    local function Same(a,b)
        if type(a)~="table" or type(b)~="table" then return a==b end
        for k,v in pairs(a) do if not Same(v,b[k]) then return false end end
        for k in pairs(b) do if a[k]==nil then return false end end
        return true
    end
    -- "Apply to all Bars" link: copies the listed keys (or a custom copy) from the selected bar.
    local function Sync(rgn,label,keys,copy,equals)
        if not Inline(rgn) or not E.BuildSyncIcon then return end
        copy=copy or function(dst,src) for _,f in ipairs(keys) do dst[f]=CopyValue(src[f]) end end
        equals=equals or function(a,b) for _,f in ipairs(keys) do if not Same(a[f],b[f]) then return false end end; return true end
        local function Apply(list)
            local src=SB()
            for _,k in ipairs(list) do local dst=ns.GetSettings(k); if dst~=src then copy(dst,src,k) end end
            Changed(); if E.RefreshPage then E:RefreshPage() end
        end
        E.BuildSyncIcon({region=rgn,tooltip="Apply "..label.." to all Bars",
            onClick=function() Apply(barOrder) end,
            isSynced=function() local src=SB(); for _,k in ipairs(barOrder) do if not equals(src,ns.GetSettings(k)) then return false end end; return true end,
            flashTargets=function() return {rgn} end,
            multiApply={elementKeys=barOrder,elementLabels=shortLabels,getCurrentKey=Key,onApply=Apply}})
    end

    ---------------------------------------------------------------------------
    --  Live preview (content header): real icons, keybinds and the bar's look.
    ---------------------------------------------------------------------------
    local HINT_H=29
    local preview,hint,overlays,headerBaseH=nil,nil,{},0
    local refs={}
    local function HintShown() return not (EllesmereUIDB and EllesmereUIDB.previewHintDismissed) end
    local function PreviewIcon(d,i)
        if d.key=="petBar" then
            if GetPetActionInfo then local _,_,tex,isToken=GetPetActionInfo(i); if tex then return isToken and _G[tex] or tex end end
            return nil
        elseif d.key=="stanceBar" then
            return GetShapeshiftFormInfo and (GetShapeshiftFormInfo(i)) or nil
        end
        return GetActionTexture and GetActionTexture((d.page-1)*12+i) or nil
    end
    local function RealText(d,i,field,suffix)
        local bar=ns.bars[d.key]; local b=bar and bar.buttons[i]
        local fs=b and (b[field] or _G[(b:GetName() or "")..suffix])
        if not fs or not fs.GetText or (field=="hotkey" and fs.IsShown and not fs:IsShown()) then return "" end
        return fs:GetText() or ""
    end
    local function CreatePreview(hdr)
        local pf=CreateFrame("Frame",nil,hdr)
        pf.bg=CreateFrame("Frame",nil,pf); pf.bg:EnableMouse(false)
        pf.buttons={}
        for i=1,12 do
            local b=CreateFrame("Frame",nil,pf)
            b.border=CreateFrame("Frame",nil,b)
            b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetAllPoints(b)
            b.outline=b:CreateTexture(nil,"OVERLAY"); b.outline:Hide()
            b.slot=b.border:CreateTexture(nil,"ARTWORK"); b.slot:Hide()
            local text=CreateFrame("Frame",nil,b); text:SetAllPoints(b); text:SetFrameLevel(b:GetFrameLevel()+3)
            b.hotkey,b.count,b.macro=text:CreateFontString(nil,"OVERLAY"),text:CreateFontString(nil,"OVERLAY"),text:CreateFontString(nil,"OVERLAY")
            pf.buttons[i]=b
        end
        return pf
    end
    local function PaintPreview()
        local pf=preview; if not pf then return 0 end
        local d,s,p=byKey[Key()],SB(),Root()
        local count=d.native and d.count or Clamp(s.buttons,1,12)
        if d.key=="stanceBar" then count=math.max(1,math.min(count,GetNumShapeshiftForms and GetNumShapeshiftForms() or count)) end
        local stride=math.min(count,Clamp(s.buttonsPerRow,1,d.count or 12))
        local vertical=s.orientation=="vertical"
        local lines=math.ceil(count/stride)
        local cols,rows=vertical and lines or stride,vertical and stride or lines
        local size,spacing=Clamp(s.size,16,120),Clamp(s.spacing,-10,20)
        local pad=(s.bgEnabled and Clamp(s.bgPadding,0,30) or 0)+Clamp(s.borderSize,0,5)+10
        local w,h=cols*(size+spacing)-spacing,rows*(size+spacing)-spacing
        local hdr=pf:GetParent()
        local avail=math.max(100,(hdr:GetWidth() or 600)-2*(E.CONTENT_PAD or 20))
        local scale=math.min(1,avail/(w+2*pad))
        pf:SetScale(scale); pf:SetWidth(w+2*pad); pf:SetHeight(h+2*pad)
        pf:SetAlpha(math.max(.25,Clamp(s.opacity,0,100)/100))
        local bg=pf.bg
        if s.bgEnabled then
            local bp=Clamp(s.bgPadding,0,30); local c,bc=s.bgColor or {},s.bgBorderColor or {}
            local edge=Clamp(s.bgBorderSize,0,8)
            bg:ClearAllPoints(); bg:SetPoint("TOPLEFT",pf,"TOPLEFT",pad-bp,-(pad-bp)); bg:SetPoint("BOTTOMRIGHT",pf,"BOTTOMRIGHT",-(pad-bp),pad-bp)
            bg:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=math.max(1,edge)})
            bg:SetBackdropColor(c.r or 0,c.g or 0,c.b or 0,c.a or .5)
            bg:SetBackdropBorderColor(bc.r or 0,bc.g or 0,bc.b or 0,edge>0 and (bc.a or 1) or 0)
            bg:Show()
        else bg:Hide() end
        local z=Clamp(p.iconZoom,0,15)/100
        local shape=ns.ShapeOf(s)
        local round,cut=ns.ROUND_SHAPES[shape],ns.CUT_SHAPES[shape]
        local slot=p.slotBgColor or {r=.15,g=.15,b=.15}
        local edge=Clamp(s.borderSize,0,5)
        local br,bgc,bb=(s.borderColor or {}).r or 0,(s.borderColor or {}).g or 0,(s.borderColor or {}).b or 0
        if s.borderClassColor and E.GetClassColor then local cc=E.GetClassColor(select(2,UnitClass("player"))); if cc then br,bgc,bb=cc.r,cc.g,cc.b end end
        for i,b in ipairs(pf.buttons) do
            if i<=count then
                local col,row=ns.GridPos(i-1,count,stride,vertical,s.iconOrder,s.growDirection)
                b:SetWidth(size); b:SetHeight(size); b:ClearAllPoints()
                b:SetPoint("TOPLEFT",pf,"TOPLEFT",pad+col*(size+spacing),-(pad+row*(size+spacing)))
                b.border:ClearAllPoints(); b.border:SetPoint("TOPLEFT",b,"TOPLEFT",-edge,edge); b.border:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",edge,-edge)
                b.border:SetFrameLevel(math.max(0,b:GetFrameLevel()-1))
                b.border:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=math.max(1,edge)})
                local slotA=Clamp(p.slotBgOpacity,0,100)/100
                b.border:SetBackdropColor(slot.r,slot.g,slot.b,cut and 0 or slotA)
                b.border:SetBackdropBorderColor(br,bgc,bb,(edge>0 and shape=="none") and 1 or 0)
                if shape~="none" then
                    b.outline:SetTexture(ns.ShapeTexture(shape,"border")); ns.FitShape(b.outline,b,size,shape)
                    b.outline:SetVertexColor(ns.ShapeBorderColor(s))
                    if edge>0 then b.outline:Show() else b.outline:Hide() end
                else b.outline:Hide() end
                if cut then
                    b.slot:SetTexture(ns.ShapeTexture(shape,"mask")); ns.FitShape(b.slot,b,size,shape)
                    b.slot:SetVertexColor(slot.r,slot.g,slot.b,slotA); b.slot:Show()
                else b.slot:Hide() end
                local tex=PreviewIcon(d,i)
                if tex and round and SetPortraitToTexture then SetPortraitToTexture(b.icon,tex); b.icon:SetTexCoord(0,1,0,1); b.icon:Show()
                elseif tex then b.icon:SetTexture(tex); b.icon:SetTexCoord(z,1-z,z,1-z); b.icon:Show() else b.icon:Hide() end
                ns.SetStrips(b.icon,b,shape,z)
                ns.StyleText(b.hotkey,s.keybindFontSize,s.keybindFontColor,1)
                ns.AnchorText(b.hotkey,b,s.keybindAnchor,s.keybindOffsetX,s.keybindOffsetY,1,true)
                b.hotkey:SetText(s.hideKeybind and "" or RealText(d,i,"hotkey","HotKey"))
                ns.StyleText(b.macro,s.macroFontSize,s.macroFontColor,1)
                ns.AnchorText(b.macro,b,s.macroAnchor or "BOTTOM",s.macroOffsetX,s.macroOffsetY,1,true)
                b.macro:SetText((s.hideMacroText or d.native) and "" or RealText(d,i,"actionName","Name"))
                ns.StyleText(b.count,s.countFontSize,s.countFontColor,1)
                ns.AnchorText(b.count,b,s.countAnchor or "BOTTOMRIGHT",s.countOffsetX,s.countOffsetY,1,false)
                b.count:SetText(RealText(d,i,"count","Count"))
                b:Show()
            else b:Hide() end
        end
        return (h+2*pad)*scale
    end
    local function SyncOverlays()
        for _,o in ipairs(overlays) do
            local on=o.el:IsShown() and (not o.text or (o.el:GetText() or "")~="")
            if on and o.text and o.btn._resizeToText then o.btn._resizeToText() end
            if on then o.btn:Show() else o.btn:Hide() end
        end
    end
    local DD_H,TOP,GAP=34,20,10
    local function PaintHeader()
        if not preview then return 0 end
        headerBaseH=TOP+DD_H+GAP+PaintPreview()+GAP
        SyncOverlays()
        local shown=hint and HintShown()
        if hint then if shown then hint:SetAlpha(.45); hint:Show() else hint:Hide() end end
        return headerBaseH+(shown and HINT_H or 0)
    end
    UpdatePreview=function()
        if not preview or not preview:IsVisible() then return end
        local h=PaintHeader()
        if E.SetContentHeaderHeightSilent then E:SetContentHeaderHeightSilent(h) end
    end
    -- Click-to-navigate: each preview element scrolls to and glows the row that configures it.
    local PlayGlow
    local function Glow(target)
        PlayGlow=PlayGlow or (E.MakeSettingGlow and E.MakeSettingGlow({color=E.ELLESMERE_GREEN,thickness=2,noSnap=true}))
        if PlayGlow then PlayGlow(target) end
    end
    local NAV={icon={"iconsHeader","borderRow","left"},keybind={"textHeader","keybindRow","right"},
        macro={"textHeader","macroRow","right"},count={"textHeader","countRow","left"},background={"bgHeader","bgRow","left"}}
    local function Navigate(key)
        local m=NAV[key]; local section,target=m and refs[m[1]],m and refs[m[2]]
        if not section or not target then return end
        if hint and E.DismissPreviewHint then E.DismissPreviewHint(hint,headerBaseH,HINT_H,17) end
        local _,_,_,_,y=section:GetPoint(1)
        if y and E.SmoothScrollTo then E.SmoothScrollTo(math.max(0,math.abs(y)-40)) end
        target=target[m[3]=="left" and "_leftRegion" or "_rightRegion"] or target
        C_Timer.After(.15,function() Glow(target) end)
    end
    ns.NavigatePreview=Navigate
    local HIT_STYLE={container=true,tightText=true}
    local function BuildOverlays()
        wipe(overlays)
        if not preview or not E.CreatePreviewHitOverlay then return end
        local function Hit(el,key,isText,level)
            local btn=E.CreatePreviewHitOverlay(el,Navigate,key,isText,level,nil,HIT_STYLE)
            overlays[#overlays+1]={btn=btn,el=el,text=isText}
        end
        Hit(preview.bg,"background",false,preview:GetFrameLevel()+1)
        for _,b in ipairs(preview.buttons) do
            local level=b:GetFrameLevel()+30
            Hit(b,"icon",false,b:GetFrameLevel()+20)
            Hit(b.hotkey,"keybind",true,level); Hit(b.macro,"macro",true,level); Hit(b.count,"count",true,level)
        end
    end
    local function HeaderBuilder(hdr)
        if E.BuildDropdownControl then
            local dd=E.BuildDropdownControl(hdr,350,hdr:GetFrameLevel()+5,barLabels,barOrder,Key,function(v) ns.SelectWrathBar(v) end)
            dd:SetPoint("TOP",hdr,"TOP",0,-TOP); dd:SetHeight(DD_H)
        end
        preview=CreatePreview(hdr)
        preview:SetPoint("TOP",hdr,"TOP",0,-(TOP+DD_H+GAP))
        hint=nil
        if HintShown() and E.MakeFont then
            -- Parented to the preview so it travels through the content-header cache with it.
            hint=E.MakeFont(preview,11,nil,1,1,1)
            hint:SetText(E.L and E.L("Click elements to scroll to and highlight their options") or "Click elements to scroll to and highlight their options")
            hint:ClearAllPoints(); hint:SetPoint("BOTTOM",hdr,"BOTTOM",0,17)
        end
        BuildOverlays()
        return PaintHeader()
    end
    if E.RegisterOnShow then E:RegisterOnShow(function() if UpdatePreview then UpdatePreview() end end) end

    local GROW_H,GROW_H_ORDER={left="Left",right="Right",center="Centered"},{"left","right","center"}
    local GROW_V,GROW_V_ORDER={up="Up",down="Down",center="Centered"},{"up","down","center"}
    local ORDER_VALUES={default="Default",reversed="Reversed",TOPLEFT="Top Left",TOPRIGHT="Top Right",BOTTOMLEFT="Bottom Left",BOTTOMRIGHT="Bottom Right"}
    local ORDER_KEYS={"default","reversed","TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"}
    local ANCHOR_VALUES={TOPLEFT="Top Left",TOP="Top",TOPRIGHT="Top Right",BOTTOMLEFT="Bottom Left",BOTTOM="Bottom",BOTTOMRIGHT="Bottom Right"}
    local PAGE_VALUES,PAGE_ORDER={[0]="None"},{0}
    for _,page in ipairs({1,6,5,3,4,2,7,8,9,10}) do PAGE_VALUES[page]=ns.PAGE_LABELS[page]; PAGE_ORDER[#PAGE_ORDER+1]=page end
    local INTERACTION_VALUES={[1]="Light",[2]="Medium",[3]="Strong",[4]="Solid Color",[5]="Border",[6]="None"}
    local INTERACTION_ORDER={1,2,3,4,5,6}
    local VIS_VALUES={always="Always",never="Never",mouseover="Mouseover",in_combat="In Combat",
        out_of_combat="Out of Combat",in_party="In Party",in_raid="In Raid Group",solo="Solo"}
    local VIS_ORDER={"always","never","mouseover","in_combat","out_of_combat","in_party","in_raid","solo"}
    local function ResetPositions(prefix,only)
        local p=Root(); if not p then return end
        for key in pairs(p.barPositions) do
            if (prefix and key:sub(1,#prefix)==prefix) or (not prefix and key:sub(1,4)~="hud_") or key==only then p.barPositions[key]=nil end
        end
        ns.Apply()
    end

    local C={}
    local function Row(a,b) local row,h=C.W:DualRow(C.parent,C.y,a,b); C.y=C.y-h; return row end
    local function Section(label) local header,h=C.W:SectionHeader(C.parent,label,C.y); C.y=C.y-h; return header end
    local function Button(label,fn) local _,h=C.W:WideButton(C.parent,label,C.y,fn); C.y=C.y-h end

    local function BuildBarDisplay()
        local parent,W,key=C.parent,C.W,Key()
        local SB,d=BarStore(),byKey[key]
        local function BarCount() return d.native and d.count or Clamp(SB().buttons,1,12) end
        local function VisStore()
            local s=SB()
            if s.enabled==false and s.barVisibility~="never" then s.barVisibility="never"; s.visibilityModes=nil end
            return s
        end
        local function VisChanged()
            local s=SB(); s.enabled=s.barVisibility~="never"; ns.visToggle[key]=nil
            Changed(); ns.RebuildToggleBindings()
        end
        local withPreview=E.SetContentHeader and not E._prebuilding
        if withPreview then E:SetContentHeader(HeaderBuilder) end
        -- Top action buttons (Retail: Quick Keybind | Blizzard Style).
        local function OpenQuickKeybind()
            if InCombatLockdown() then return end
            if ns.QuickKeybind then ns.QuickKeybind.Open() end
        end
        local function OpenUnlock() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end
        if E.MakeStyledButton and not E._prebuilding then
            local pad=E.CONTENT_PAD or 20
            local rowFrame=CreateFrame("Frame",nil,parent)
            rowFrame:SetWidth(parent:GetWidth()-pad*2); rowFrame:SetHeight(58)
            rowFrame:SetPoint("TOPLEFT",parent,"TOPLEFT",pad,C.y)
            local function Top(label,fn,point,x)
                local b=CreateFrame("Button",nil,rowFrame); b:SetWidth(312); b:SetHeight(38)
                b:SetPoint(point,rowFrame,"CENTER",x,0); b:SetFrameLevel(rowFrame:GetFrameLevel()+1)
                E.MakeStyledButton(b,label,14,E.WB_COLOURS,fn)
            end
            Top("Quick Keybind Mode (/kb)",OpenQuickKeybind,"RIGHT",-20)
            Top("Open Unlock Mode",OpenUnlock,"LEFT",20)
            C.y=C.y-58
        else
            Button("Quick Keybind Mode (/kb)",OpenQuickKeybind)
            Button("Open Unlock Mode",OpenUnlock)
        end
        local shared=ns.PageShare and ns.PageShare(key)
        if shared and E.BuildNoteRow then
            C.y=E.BuildNoteRow(parent,C.y,d.label.." shares its buttons with Action Bar 1 in "..shared..".")
            C.y=E.BuildNoteRow(parent,C.y,"Turn on Disable Form Paging on Action Bar 1 to give it its own slots.")
        end

        Section("VISIBILITY")
        local visRow
        if E.BuildVisibilityRow then
            local h
            visRow,h=E.BuildVisibilityRow(W,parent,C.y,{getStore=VisStore,legacyKey="barVisibility",
                caps={partyIncludesRaid=false,noOverrideMouseover=true},
                onChanged=VisChanged,onOptionChanged=function() ns.RefreshVisibility(); if UpdatePreview then UpdatePreview() end end},
                {type="label",text="Toggle Action Bar"})
            C.y=C.y-h
        else
            visRow=Row(Dropdown("barVisibility","Visibility",VIS_VALUES,VIS_ORDER,{setValue=function(v) SB().barVisibility=v; VisChanged() end}),
                {type="label",text="Toggle Action Bar"})
        end
        local visL,visR=Inline(visRow and visRow._leftRegion),Inline(visRow and visRow._rightRegion)
        Sync(visL,"Visibility",nil,function(dst,src,k)
            if E.VisFullCopy then E.VisFullCopy(dst,src,"barVisibility") else dst.barVisibility=src.barVisibility end
            dst.enabled=src.enabled; ns.visToggle[k]=nil
        end,function(a,b)
            if E.VisFullEquals then return E.VisFullEquals(a,"barVisibility",b,"barVisibility") end
            return a.barVisibility==b.barVisibility
        end)
        Cog(visL,"Visibility",{CogToggle(Root,"mouseoverShowAll","Show All on Mouseover")},{anchorTo=visL and visL._control})
        if visR and E.BuildKeybindButton then
            local kb,refresh=E.BuildKeybindButton(visR,{w=126,h=29,level=4,
                get=function() return SB().toggleVisKey end,
                set=function(v) SB().toggleVisKey=v; ns.RebuildToggleBindings() end,
                disabled=function() local v=SB().barVisibility or "always"; return v~="always" and v~="never" end,
                disabledTip="Visibility set to Always or Never",
                tooltip="Toggling an action bar is only available out of combat\n\nLeft-click to set a keybind.\nRight-click to unbind."})
            kb:SetPoint("RIGHT",visR,"RIGHT",-20,0)
            E.RegisterWidgetRefresh(refresh)
        end
        local row=Row(Slider("opacity","Bar Opacity",0,100,5),
            Toggle("showEmpty","Always Show Buttons",NativeOff()))
        Sync(Inline(row and row._leftRegion),"Bar Opacity",{"opacity"})
        row=Row(Toggle("clickThrough","Click Through"),Blank())
        Sync(Inline(row and row._leftRegion),"Click Through",{"clickThrough"})

        refs.layoutHeader=Section("LAYOUT")
        row=Row(Slider("size","Icon Size",16,120,1),Slider("spacing","Button Spacing",-10,20,1))
        refs.sizeRow=row
        Sync(Inline(row and row._leftRegion),"Icon Size",{"size"})
        Sync(Inline(row and row._rightRegion),"Button Spacing",{"spacing"})
        local iconsCfg=Slider("buttons","Number of Icons",1,12,1,NativeOff())
        iconsCfg.setValue=function(v)
            local s=SB(); local rows=math.ceil(BarCount()/math.max(1,s.buttonsPerRow))
            s.buttons=v; s.buttonsPerRow=math.ceil(v/rows); Changed()
        end
        row=Row(iconsCfg,{type="slider",text="Number of Rows",min=1,max=12,step=1,
            getValue=function() local s=SB(); return math.ceil(BarCount()/math.max(1,math.min(BarCount(),s.buttonsPerRow))) end,
            setValue=function(v) local s=SB(); s.buttonsPerRow=math.max(1,math.ceil(BarCount()/v)); Changed() end})
        Sync(Inline(row and row._leftRegion),"Number of Icons",{"buttons","buttonsPerRow"})
        local vertical=SB().orientation=="vertical"
        Cog(Inline(row and row._rightRegion),"Row Settings",{CogDropdown(SB,"growDirection","Grow Direction",
            vertical and GROW_V or GROW_H,vertical and GROW_V_ORDER or GROW_H_ORDER)})
        row=Row({type="toggle",text="Vertical Orientation",tooltip="Toggle between horizontal and vertical bar layout.",
                getValue=function() return SB().orientation=="vertical" end,
                setValue=function(v) local s=SB(); s.orientation=v and "vertical" or "horizontal"; s.growDirection=nil; Changed(); if E.RefreshPage then E:RefreshPage(true) end end},
            Dropdown("iconOrder","Icon Order",ORDER_VALUES,ORDER_KEYS,{tooltip="Order of the buttons on this bar; corner options place the first button in that corner."}))
        Sync(Inline(row and row._leftRegion),"Orientation",{"orientation","growDirection"})

        refs.bgHeader=Section("BAR BACKGROUND")
        local bgOff=Off("bgEnabled","Enable Bar Background")
        row=Row(Toggle("bgEnabled","Enable Bar Background"),Slider("bgPadding","Spacing",0,30,1,bgOff))
        refs.bgRow=row
        Sync(Inline(row and row._leftRegion),"Bar Background",{"bgEnabled","bgPadding","bgColor","bgBorderSize","bgBorderColor"})
        Row({type="colorpicker",text="Background Color",disabled=bgOff.disabled,disabledTooltip=bgOff.disabledTooltip,
                getValue=function() local c=SB().bgColor or {}; return c.r or 0,c.g or 0,c.b or 0,1 end,
                setValue=function(r,g,b) local s=SB(); local a=(s.bgColor or {}).a or .5; s.bgColor={r=r,g=g,b=b,a=a}; Changed() end},
            {type="slider",text="Background Opacity",min=0,max=100,step=5,disabled=bgOff.disabled,disabledTooltip=bgOff.disabledTooltip,
                getValue=function() return math.floor(((SB().bgColor or {}).a or .5)*100+.5) end,
                setValue=function(v) local s=SB(); local c=s.bgColor or {r=0,g=0,b=0}; s.bgColor={r=c.r,g=c.g,b=c.b,a=v/100}; Changed() end})
        row=Row(Slider("bgBorderSize","Border Size",0,8,1,bgOff),Blank())
        Swatch(Inline(row and row._leftRegion),SB,"bgBorderColor",true,bgOff.disabled)

        refs.iconsHeader=Section("ICONS")
        row=Row(Dropdown("buttonShape","Custom Button Shape",ns.SHAPE_LABELS,ns.SHAPE_ORDER,
            {tooltip="Circle and Portrait draw round icons, and Diamond, Hexagon and Shield crop the icon to the shape. Square and Curved Square outline the square icon. The outline uses the Border Size and colour below."}),Blank())
        refs.shapeRow=row
        Sync(Inline(row and row._leftRegion),"Custom Button Shape",{"buttonShape"})
        row=Row(Slider("borderSize","Border Size",0,5,1),RootSlider("iconZoom","Icon Zoom",0,15,.5))
        refs.borderRow=row
        local borderL=Inline(row and row._leftRegion)
        Swatch(borderL,SB,"borderColor",false,function() return SB().borderClassColor end)
        Cog(borderL,"Border Options",{CogToggle(SB,"borderClassColor","Class Colored Border")})
        Sync(borderL,"Border",{"borderSize","borderColor","borderClassColor"})
        row=Row(RootSlider("slotBgOpacity","Icon Background",0,100,5),Toggle("showCooldownText","Show Cooldown Numbers",
            {tooltip="EUI cooldown numbers on action buttons (Wrath has no Blizzard cooldown text)."}))
        Swatch(Inline(row and row._leftRegion),Root,"slotBgColor")
        Sync(Inline(row and row._rightRegion),"Cooldown Numbers",{"showCooldownText"})

        Section("ICON EFFECTS")
        Row(RootToggle("desaturateOnCooldown","Desaturate on Cooldown"),Toggle("disableTooltips","Disable Tooltips"))
        row=Row(Toggle("outOfRangeColoring","Out of Range Coloring"),RootToggle("clickOnDown","Cast on Key Down"))
        Swatch(Inline(row and row._leftRegion),SB,"outOfRangeColor",false,function() return not SB().outOfRangeColoring end)
        Sync(Inline(row and row._leftRegion),"Out of Range Coloring",{"outOfRangeColoring","outOfRangeColor"})
        Row(RootSlider("alphaWhenOnCD","Alpha when on CD",0,100,5),RootSlider("cdSwipeAlpha","CD Swipe Opacity",0,100,5))
        Row(RootToggle("lockActions","Lock Action Dragging",{tooltip="Hold Shift to drag actions off locked bars."}),Blank())

        if key=="bar1" then
            Section("PAGING")
            row=Row(Toggle("disableFormPaging","Disable Form Paging",{tooltip="Stances, forms and stealth keep Action Bar 1 on its own page."}),
                Toggle("pagingArrows","Show Paging Arrows"))
            Cog(Inline(row and row._rightRegion),"Paging Arrows",{CogToggle(SB,"pagingArrowsRight","Show Arrows on Right")},
                {disabled=function() return not SB().pagingArrows end,disabledTooltip="Show Paging Arrows"})
            Row(Dropdown("pagingShift","Shift Modifier",PAGE_VALUES,PAGE_ORDER),Dropdown("pagingCtrl","Ctrl Modifier",PAGE_VALUES,PAGE_ORDER))
            Row(Dropdown("pagingAlt","Alt Modifier",PAGE_VALUES,PAGE_ORDER),Blank())
            Row(Dropdown("pagingFriendly","Friendly Target",PAGE_VALUES,PAGE_ORDER),Dropdown("pagingHostile","Hostile Target",PAGE_VALUES,PAGE_ORDER))
        end

        refs.textHeader=Section("TEXT")
        local function TextCog(rgn,title,prefix,anchorKey)
            Cog(rgn,title,{CogDropdown(SB,anchorKey,"Position",ANCHOR_VALUES,ns.TEXT_ANCHOR_ORDER),
                CogSlider(SB,prefix.."OffsetX","X Offset",-20,20),CogSlider(SB,prefix.."OffsetY","Y Offset",-20,20)})
        end
        row=Row(Toggle("hideKeybind","Hide Keybind Text"),Slider("keybindFontSize","Keybind Text Size",6,32,1))
        refs.keybindRow=row
        local rgn=Inline(row and row._rightRegion)
        Swatch(rgn,SB,"keybindFontColor"); TextCog(rgn,"Keybind Text","keybind","keybindAnchor")
        Sync(Inline(row and row._leftRegion),"Keybind Text",{"hideKeybind","keybindFontSize","keybindFontColor","keybindAnchor","keybindOffsetX","keybindOffsetY"})
        row=Row(Toggle("hideMacroText","Hide Macro Text",NativeOff()),Slider("macroFontSize","Macro Text Size",6,32,1,NativeOff()))
        refs.macroRow=row
        rgn=Inline(row and row._rightRegion)
        Swatch(rgn,SB,"macroFontColor"); TextCog(rgn,"Macro Text","macro","macroAnchor")
        row=Row(Slider("countFontSize","Count Text Size",6,32,1),Slider("cooldownFontSize","Cooldown Text Size",6,32,1,NativeOff()))
        refs.countRow=row
        rgn=Inline(row and row._leftRegion)
        Swatch(rgn,SB,"countFontColor"); TextCog(rgn,"Count Text","count","countAnchor")
        rgn=Inline(row and row._rightRegion)
        Swatch(rgn,SB,"cooldownTextColor")
        Cog(rgn,"Cooldown Text",{CogSlider(SB,"cooldownTextXOffset","X Offset",-20,20),CogSlider(SB,"cooldownTextYOffset","Y Offset",-20,20)})

        Section("GENERAL")
        Row(RootToggle("enabled","Enable Action Bars"),RootToggle("hideArtwork","Hide Blizzard Bar Art"))
        Button("Reset Selected Bar Position",function() Root().barPositions[key]=nil; ns.Apply() end)
        Button("Reset All Bar Positions",function() ResetPositions() end)
    end

    local function BuildHUD()
        local function HUDToggle(key,label) return HUDCfg("toggle",key,label) end
        local function HUDOff(key,label) return {disabled=function() return HUD()[key]==false end,disabledTooltip=label} end
        Section("MICRO MENU & BAGS")
        Row(HUDToggle("micro","Micro Menu Skin"),HUDToggle("bags","Bag Bar Skin"))
        local microOff,bagOff=HUDOff("micro","Micro Menu Skin"),HUDOff("bags","Bag Bar Skin")
        Row(HUDCfg("slider","microSize","Micro Button Size",20,48,1,"buttonSize",microOff),HUDCfg("slider","microSpacing","Micro Spacing",0,12,1,"spacing",microOff))
        Row(HUDCfg("slider","bagsSize","Bag Button Size",20,48,1,"buttonSize",bagOff),HUDCfg("slider","bagsSpacing","Bag Spacing",0,12,1,"spacing",bagOff))
        Row(HUDCfg("toggle","bagsConsolidate","Consolidate Bags",nil,nil,nil,nil,
            {tooltip="One backpack button; opens the unified inventory.",disabled=bagOff.disabled,disabledTooltip=bagOff.disabledTooltip}),Blank())

        Section("EXPERIENCE BAR")
        local xpOff=HUDOff("xp","Enable Experience Bar")
        Row(HUDToggle("xp","Enable Experience Bar"),RootSlider("fontSize","Text Size",8,20,1,{tooltip="Experience and reputation bar text."}))
        Row(HUDCfg("slider","xpWidth","Width",120,1000,1,"barWidth",xpOff),HUDCfg("slider","xpHeight","Height",8,32,1,"barHeight",xpOff))
        Section("REPUTATION BAR")
        local repOff=HUDOff("reputation","Enable Reputation Bar")
        Row(HUDToggle("reputation","Enable Reputation Bar"),Blank())
        Row(HUDCfg("slider","reputationWidth","Width",120,1000,1,"barWidth",repOff),HUDCfg("slider","reputationHeight","Height",8,32,1,"barHeight",repOff))

        Section("PLAYER AURAS")
        Row(HUDToggle("buffs","Buff Mover"),HUDToggle("debuffs","Debuff Mover"))
        Row(HUDCfg("slider","buffsColumns","Buff Icons Per Row",1,16,1,"auraColumns",HUDOff("buffs","Buff Mover")),
            HUDCfg("slider","debuffsColumns","Debuff Icons Per Row",1,16,1,"auraColumns",HUDOff("debuffs","Debuff Mover")))
        Button("Reset Menu, Bags & XP Positions",function() ResetPositions("hud_") end)
    end

    local function BuildAnimations()
        Section("BAR INTERACTIONS")
        local function TypeCfg(key,label)
            return Cfg(Root,"dropdown",key,label,{values=INTERACTION_VALUES,order=INTERACTION_ORDER})
        end
        local row=Row(TypeCfg("pushedTextureType","Pushed Type"),TypeCfg("highlightTextureType","Highlight Type"))
        local function Side(rgn,prefix,title)
            rgn=Inline(rgn)
            Swatch(rgn,Root,prefix.."CustomColor",false,function() local p=Root(); return p[prefix.."UseClassColor"] or p[prefix.."TextureType"]==6 end)
            Cog(rgn,title,{CogToggle(Root,prefix.."UseClassColor","Class Colored"),CogSlider(Root,prefix.."BorderSize","Border Size",1,8)},
                {disabled=function() return Root()[prefix.."TextureType"]==6 end,disabledTooltip=title})
        end
        Side(row and row._leftRegion,"pushed","Pushed")
        Side(row and row._rightRegion,"highlight","Highlight")
        Row(RootToggle("showCastHighlight","Show Highlight on Spell Cast",{tooltip="Lights the button of the spell you are casting with the highlight look."}),Blank())
    end

    E:RegisterModule("EllesmereUIActionBars",{
        title="Action Bars",description="Action bars, Blizzard HUD skins and player aura positions for Wrath.",
        pages={PAGE_DISPLAY,PAGE_HUD,PAGE_ANIM},
        searchTerms="action bar keybind macro paging stance pet micro menu bag experience reputation buff debuff highlight pushed cooldown button shape circle round",
        buildPage=function(page,parent,y)
            C.W,C.parent,C.y=E.Widgets,parent,y
            parent._showRowDivider=true
            if page==PAGE_DISPLAY then BuildBarDisplay()
            elseif page==PAGE_HUD then BuildHUD()
            elseif page==PAGE_ANIM then BuildAnimations() end
            return math.abs(C.y)
        end,
        getHeaderBuilder=function(page) if page==PAGE_DISPLAY then return HeaderBuilder end end,
        onPageCacheRestore=function(page) if page==PAGE_DISPLAY and UpdatePreview then UpdatePreview() end end,
        onReset=function()
            if ns.addon.db and ns.addon.db.ResetProfile then ns.addon.db:ResetProfile() end
            ns.Apply(); E:InvalidatePageCache()
        end,
    })
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
