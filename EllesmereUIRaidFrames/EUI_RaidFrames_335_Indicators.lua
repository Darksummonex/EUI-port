-- Retail-style Buffs/Debuffs indicator editor for the Raid Frames module (Wrath 3.3.5).
--
--  * Model: adds per-specialization indicator lists to E.WrathAuraIndicators.
--    The shared list stays in c.<prefix>Indicators; a spec (spec1..spec3 = talent tree)
--    may own a copy in c.<prefix>SpecIndicators. The active tree's list is used at runtime.
--  * UI: the fixed header (preview, Editing Spec, indicator list) and the settings page are
--    installed over the shared builders ONLY for the Raid Frames module, once the
--    load-on-demand options addon has loaded. Unit Frames keep the stock builders.
--  Nothing outside the EllesmereUIRaidFrames folder needs to be modified.
local E=EllesmereUI
local RF="EllesmereUIRaidFrames"
local A=E and E.WrathAuraIndicators
if not A then return end

---------------------------------------------------------------------------
-- Model (skipped when the core already provides it)
---------------------------------------------------------------------------
if not A.SpecKey then
    local specKey
    local function ReadSpec()
        if not GetNumTalentTabs then return "none" end
        local group=GetActiveTalentGroup and GetActiveTalentGroup() or 1
        local best,most=nil,0
        for i=1,(GetNumTalentTabs() or 0) do
            local _,_,points=GetTalentTabInfo(i,false,false,group)
            points=tonumber(points) or 0
            if points>most then best,most=i,points end
        end
        return best and ("spec"..best) or "none"
    end
    function A.SpecKey() if not specKey then specKey=ReadSpec() end return specKey end
    local function Copy(t)
        if type(t)~="table" then return t end
        local o={}; for k,v in pairs(t) do o[k]=Copy(v) end; return o
    end
    local sharedList=A.List
    function A.List(c,prefix,create,spec)
        spec=spec or A.SpecKey()
        local per=c[prefix.."SpecIndicators"]
        if spec~="all" and per and per[spec] then return per[spec] end
        return sharedList(c,prefix,create)
    end
    function A.HasOwn(c,prefix,spec)
        local per=c[prefix.."SpecIndicators"]; return spec~="all" and per~=nil and per[spec]~=nil
    end
    function A.Fork(c,prefix,spec)
        if spec=="all" or A.HasOwn(c,prefix,spec) then return end
        local base=sharedList(c,prefix,true)
        c[prefix.."SpecIndicators"]=c[prefix.."SpecIndicators"] or {}
        c[prefix.."SpecIndicators"][spec]=Copy(base)
    end
    function A.ClearOwn(c,prefix,spec)
        local per=c[prefix.."SpecIndicators"]; if per then per[spec]=nil end
    end
    local events=CreateFrame("Frame")
    events:RegisterEvent("PLAYER_LOGIN")
    events:RegisterEvent("PLAYER_TALENT_UPDATE")
    events:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    events:SetScript("OnEvent",function()
        local old=specKey; specKey=ReadSpec()
        if old==nil or old==specKey then return end
        local m=E._ModuleNS or {}
        local rf,uf=m[RF],m.EllesmereUIUnitFrames
        if rf and rf.Apply then pcall(rf.Apply) end
        if uf and uf.UF_ReloadAllAuraContainers then pcall(uf.UF_ReloadAllAuraContainers) end
    end)
end

---------------------------------------------------------------------------
-- Options UI (installed after the options addon has loaded)
---------------------------------------------------------------------------
local function Install()
    if E._rfIndicatorUI then return end
    E._rfIndicatorUI=true
    local origPreview,origHeader,origBuild=E.UpdateWrathAuraIndicatorPreview,E.WrathAuraIndicatorHeader,E.BuildWrathAuraIndicators
    local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
    local A=E.WrathAuraIndicators
    local views={}
    E.WrathAuraIndicatorViewsRF=views
    local white="Interface\\Buttons\\WHITE8X8"
    local function Context(folder,prefix)
        local ns=E._ModuleNS[folder]; local raid=folder=="EllesmereUIRaidFrames"
        local c=raid and ns.GetOptionSettings(ns.selectedWrathAuraGroup or "raid") or ns.UF_GetSettings(ns.selectedWrathAuraUnit or "player")
        return ns,c,raid
    end
    local function EditSpec()
        if A.editSpec then return A.editSpec end
        local k=A.SpecKey and A.SpecKey(); return (k and k~="none") and k or "all"
    end
    local function Selected(ns,c,prefix)
        local list=A.List(c,prefix,true,EditSpec())
        local index=math.max(1,math.min(#list,ns["selected"..prefix.."Indicator"] or 1))
        return list[index],index,list
    end
    -- Writes fork the shared list into a per-spec copy first (spec ~= "all").
    local function WritableList(c,prefix)
        local spec=EditSpec()
        if spec~="all" then A.Fork(c,prefix,spec) end
        return A.List(c,prefix,true,spec)
    end
    local function Font(parent,size)
        local f=parent:CreateFontString(nil,"OVERLAY")
        f:SetFont(E.GetFontPath("unitFrames"),size or 11,"OUTLINE"); f:SetTextColor(.92,.92,.92,1); return f
    end
    function E.UpdateWrathAuraIndicatorPreview(folder,prefix)
        local view=views[folder..prefix]; if not view then return end
        local ns,c,raid=Context(folder,prefix); if not c then return end
        local selected,index,list=Selected(ns,c,prefix)
        local w=math.max(60,math.min(300,tonumber(c.frameWidth) or 181))
        local h=raid and math.max(30,math.min(120,tonumber(c.frameHeight) or 52)) or (tonumber(c.healthHeight) or 46)+(tonumber(c.powerHeight) or 6)
        local power=raid and (c.showPower and math.min(h/3,math.max(2,tonumber(c.powerHeight) or 4)) or 0) or tonumber(c.powerHeight) or 6
        view.unit:SetWidth(w); view.unit:SetHeight(h)
        view.health:ClearAllPoints(); view.health:SetPoint("TOPLEFT",view.unit,"TOPLEFT",1,-1); view.health:SetPoint("BOTTOMRIGHT",view.unit,"BOTTOMRIGHT",-1,1+power)
        view.health:SetStatusBarTexture(E.ResolveTexturePath and E.ResolveTexturePath(c.healthBarTexture or "atrocity") or white)
        local class=select(2,UnitClass("player")); local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if c.healthClassColored and color then view.health:SetStatusBarColor(color.r,color.g,color.b) else view.health:SetStatusBarColor(.12,.55,.82) end
        view.health:SetMinMaxValues(0,100); view.health:SetValue(85)
        view.power:SetWidth(w-2); view.power:SetHeight(math.max(1,power)); view.power:SetStatusBarColor(.12,.3,.8); view.power:SetMinMaxValues(0,100); view.power:SetValue(65)
        if power>0 then view.power:Show() else view.power:Hide() end
        view.name:SetText(raid and "Healer Preview" or (UnitName("player") or "Player"))
        view.title:SetText((prefix=="buff" and "Buff" or "Debuff").." Indicators — "..(raid and (ns.selectedWrathAuraGroup or "raid").." "..(ns.selectedRaidLayout or ns.activeRaidLayout or ns.DEFAULT_RAID_LAYOUT or "25") or (ns.selectedWrathAuraUnit or "player")))
        local used=0; local minX,maxX,minY,maxY=-w/2,w/2,-h/2,h/2
        for _,a in ipairs(view.icons) do a:Hide() end
        for n,d in ipairs(list) do
            local ids=A.SpellIDs(d); local limit=A.Limit(c,prefix,d)
            if view.UpdateCard then view.UpdateCard(n,d,index,ids) end
            local samples=math.min(limit,math.max(1,#ids))
            for slot=1,samples do
                local a=view.icons[used+slot]; if not a then break end
                A.Place(a,view.health,c,prefix,d,slot,w,h,raid,raid and "raidFrames" or "unitFrames")
                local id=ids[slot]; a.indicatorIndex=n
                A.Paint(a,d,{id=id,icon=id and select(3,GetSpellInfo(id)),stacks=slot==1 and 3 or 1,duration=15,expiry=GetTime()+12},true)
                if d.enabled==false then a:SetAlpha(.25) end
                local size,point,x,y=A.Geometry(c,prefix,d,slot,w,h,raid)
                local px=point:find("RIGHT") and w/2-1 or point:find("LEFT") and -w/2+1 or 0
                local py=point:find("TOP") and h/2-1 or point:find("BOTTOM") and -h/2+1+power or power/2
                local l=px+x-(point:find("RIGHT") and size or point:find("LEFT") and 0 or size/2)
                local bottom=py+y-(point:find("TOP") and size or point:find("BOTTOM") and 0 or size/2)
                minX,maxX,minY,maxY=math.min(minX,l),math.max(maxX,l+size),math.min(minY,bottom),math.max(maxY,bottom+size)
            end
            used=used+limit; if used>8 then used=8 end
        end
        for n=#list+1,8 do view.items[n]:Hide() end
        local scale=math.min(1,(view.canvasWidth-24)/math.max(1,maxX-minX),170/math.max(1,maxY-minY))
        view.unit:SetScale(scale); view.unit:ClearAllPoints()
        view.unit:SetPoint("CENTER",view.canvas,"CENTER",-(maxX+minX)/2*scale,-(maxY+minY)/2*scale)
        view.hint:SetText(not raid and not c[prefix.."IndicatorMode"] and "Preview • enable Use Indicator Layout to apply" or "Preview • click an icon or indicator to edit")
        if view.UpdateSpec then view.UpdateSpec(ns,c,prefix) end
    end
    -- ---------------------------------------------------------------------------
    -- Retail-style header: live preview (settings only, no group needed), Editing
    -- Spec selector, and the indicator list with enable switch / delete / Add New.
    -- ---------------------------------------------------------------------------
    local POS_LABEL={TOPLEFT="Top Left",TOP="Top",TOPRIGHT="Top Right",LEFT="Left",CENTER="Center",RIGHT="Right",BOTTOMLEFT="Bottom Left",BOTTOM="Bottom",BOTTOMRIGHT="Bottom Right"}
    local function Accent() if E.GetAccentColor then return E.GetAccentColor() end return .05,.82,.61 end
    local function Ops(folder,prefix)
        local ns,_,raid=Context(folder,prefix)
        local o={}
        local function Settings() return select(2,Context(folder,prefix)) end
        local function Apply()
            if raid then ns.Apply() else ns.UF_ReloadAllAuraContainers() end
            E.UpdateWrathAuraIndicatorPreview(folder,prefix)
        end
        local function Rebuild() Apply(); E:InvalidatePageCache(); E:RefreshPage(true) end
        function o.Add(kind)
            local c=Settings(); if not c then return end
            local list=WritableList(c,prefix); local used=0
            for _,e in ipairs(list) do used=used+A.Limit(c,prefix,e) end
            if #list>=8 or used>=8 then
                if E.PrintError then E.PrintError("Reduce Icons Per Indicator to make room (eight icons per aura type).") end
                return
            end
            local d=A.Preset(kind)
            if kind=="manual" then d.name="Manual "..(prefix=="buff" and "Buffs" or "Debuffs"); d.maxIcons=1 end
            d.maxIcons=math.min(d.maxIcons or 1,8-used)
            list[#list+1]=d; ns["selected"..prefix.."Indicator"]=#list; Rebuild()
        end
        function o.Remove(i)
            local c=Settings(); if not c then return end
            local list=WritableList(c,prefix); if #list<=1 or not list[i] then return end
            table.remove(list,i)
            ns["selected"..prefix.."Indicator"]=math.max(1,math.min(i,#list)); Rebuild()
        end
        function o.Toggle(i)
            local c=Settings(); if not c then return end
            local list=WritableList(c,prefix); local d=list[i]; if not d then return end
            d.enabled=(d.enabled==false); Apply(); E:RefreshPage()
        end
        function o.Select(i) ns["selected"..prefix.."Indicator"]=i; E:InvalidatePageCache(); E:RefreshPage(true) end
        function o.UseShared()
            local c=Settings(); if not c then return end
            A.ClearOwn(c,prefix,EditSpec()); Rebuild()
        end
        return o
    end
    local function MakeSwitch(parent)
        local b=CreateFrame("Button",nil,parent); b:SetWidth(28); b:SetHeight(14)
        b.track=b:CreateTexture(nil,"BACKGROUND"); b.track:SetAllPoints(b); b.track:SetTexture(white)
        b.knob=b:CreateTexture(nil,"OVERLAY"); b.knob:SetTexture(white); b.knob:SetWidth(12); b.knob:SetHeight(12)
        function b:SetOn(on)
            local r,g,bl=Accent()
            if on then self.track:SetVertexColor(r,g,bl,1); self.knob:SetVertexColor(1,1,1,1)
            else self.track:SetVertexColor(.25,.25,.28,1); self.knob:SetVertexColor(.7,.7,.72,1) end
            self.knob:ClearAllPoints(); self.knob:SetPoint(on and "RIGHT" or "LEFT",self,on and "RIGHT" or "LEFT",on and -1 or 1,0)
        end
        return b
    end
    local function NewCard(root,w,ops)
        local b=CreateFrame("Button",nil,root); b:SetWidth(w); b:SetHeight(28)
        b:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); b:SetBackdropColor(.045,.05,.07,.95); b:SetBackdropBorderColor(.13,.14,.18,1)
        b.accent=b:CreateTexture(nil,"OVERLAY"); b.accent:SetTexture(white); b.accent:SetWidth(2)
        b.accent:SetPoint("TOPLEFT",b,"TOPLEFT",0,0); b.accent:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",0,0)
        b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetWidth(22); b.icon:SetHeight(22); b.icon:SetPoint("LEFT",b,"LEFT",7,0); b.icon:SetTexCoord(.08,.92,.08,.92)
        b.label=Font(b,11); b.label:SetPoint("TOPLEFT",b,"TOPLEFT",36,-4); b.label:SetWidth(w-36-62); b.label:SetHeight(11); b.label:SetJustifyH("LEFT")
        b.detail=Font(b,9); b.detail:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",36,4); b.detail:SetWidth(w-36-62); b.detail:SetHeight(9); b.detail:SetJustifyH("LEFT")
        b.detail:SetTextColor(.58,.6,.65,1)
        b.switch=MakeSwitch(b); b.switch:SetPoint("RIGHT",b,"RIGHT",-26,0)
        b.switch:SetScript("OnClick",function() ops().Toggle(b.indicatorIndex) end)
        b.del=CreateFrame("Button",nil,b); b.del:SetWidth(18); b.del:SetHeight(18); b.del:SetPoint("RIGHT",b,"RIGHT",-5,0)
        b.del.x=Font(b.del,13); b.del.x:SetPoint("CENTER"); b.del.x:SetText("x"); b.del.x:SetTextColor(.6,.6,.64,1)
        b.del:SetScript("OnEnter",function(self) self.x:SetTextColor(1,.3,.3,1) end)
        b.del:SetScript("OnLeave",function(self) self.x:SetTextColor(.6,.6,.64,1) end)
        b.del:SetScript("OnClick",function() ops().Remove(b.indicatorIndex) end)
        b:SetScript("OnClick",function() ops().Select(b.indicatorIndex) end)
        return b
    end
    local function ShowAddMenu(v,anchor,prefix,ops)
        local m=v.addMenu
        if not m then
            m=CreateFrame("Frame",nil,v.root); m:Hide(); m:SetFrameStrata("DIALOG"); m:EnableMouse(true); m.buttons={}
            m:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); m:SetBackdropColor(.04,.05,.07,.98); m:SetBackdropBorderColor(.22,.24,.3,1)
            m:SetScript("OnUpdate",function(self)
                if IsMouseButtonDown and IsMouseButtonDown("LeftButton") and not MouseIsOver(self) and not MouseIsOver(anchor) then self:Hide() end
            end)
            v.addMenu=m
        end
        local entries={{"Manual Indicator","manual"}}
        if prefix=="buff" then
            entries[2]={"Healer Buffs","healing"}; entries[3]={"Personal Defensives","defensive"}; entries[4]={"External Cooldowns","external"}
        end
        for i,e in ipairs(entries) do
            local b=m.buttons[i]
            if not b then
                b=CreateFrame("Button",nil,m); b:SetWidth(200); b:SetHeight(24); b:SetPoint("TOPLEFT",m,"TOPLEFT",4,-4-(i-1)*24)
                b.hl=b:CreateTexture(nil,"HIGHLIGHT"); b.hl:SetAllPoints(b); b.hl:SetTexture(white); b.hl:SetVertexColor(1,1,1,.08)
                b.text=Font(b,11); b.text:SetPoint("LEFT",b,"LEFT",8,0)
                m.buttons[i]=b
            end
            b.text:SetText(e[1]); b:SetScript("OnClick",function() m:Hide(); ops().Add(e[2]) end); b:Show()
        end
        for i=#entries+1,#m.buttons do m.buttons[i]:Hide() end
        m:SetWidth(208); m:SetHeight(8+#entries*24)
        m:ClearAllPoints(); m:SetPoint("BOTTOMRIGHT",anchor,"TOPRIGHT",0,4)
        if m:IsShown() then m:Hide() else m:Show() end
    end
    function E.WrathAuraIndicatorHeader(folder,prefix)
        return function(parent,width)
            if E._prebuilding then return 0 end
            local key=folder..prefix; local v=views[key]
            local HEIGHT,LISTW=292,300
            local function ops() return Ops(folder,prefix) end
            if not v then
                local root=CreateFrame("Frame",nil,parent); v={root=root,icons={},items={}}; views[key]=v
                root:EnableKeyboard(false)
                v.title=Font(root,12); v.title:SetPoint("TOPLEFT",root,"TOPLEFT",16,-10)
                v.canvas=CreateFrame("Frame",nil,root); v.canvas:SetPoint("TOPLEFT",root,"TOPLEFT",16,-32); v.canvas:SetHeight(184)
                v.unit=CreateFrame("Frame",nil,v.canvas); v.unit:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); v.unit:SetBackdropColor(.035,.04,.05,1); v.unit:SetBackdropBorderColor(.2,.2,.2,1)
                v.health=CreateFrame("StatusBar",nil,v.unit)
                v.power=CreateFrame("StatusBar",nil,v.unit); v.power:SetStatusBarTexture(white); v.power:SetPoint("BOTTOMLEFT",v.unit,"BOTTOMLEFT",1,1)
                local host=CreateFrame("Frame",nil,v.unit); host:SetAllPoints(v.unit); host:SetFrameLevel(v.unit:GetFrameLevel()+5); host:EnableMouse(false)
                v.name=Font(host,11); v.name:SetPoint("CENTER",v.unit,"CENTER",0,6)
                v.hint=Font(root,10); v.hint:SetPoint("BOTTOMLEFT",root,"BOTTOMLEFT",16,10)
                for i=1,8 do
                    local a=A.NewIcon(host); v.icons[i]=a
                    a:SetScript("OnClick",function(self) ops().Select(self.indicatorIndex) end)
                end
                -- Editing Spec
                v.specLabel=Font(root,11); v.specLabel:SetText("Editing Spec")
                if E.BuildDropdownControl then
                    local values,order={all="All Specs"},{"all"}
                    local class=UnitClass("player") or ""
                    for i=1,3 do
                        local tree=GetTalentTabInfo and GetTalentTabInfo(i)
                        values["spec"..i]=(tree or ("Spec "..i)).." "..class; order[#order+1]="spec"..i
                    end
                    v.specDD=E.BuildDropdownControl(root,176,root:GetFrameLevel()+3,values,order,
                        function() return EditSpec() end,
                        function(k) A.editSpec=k; E:InvalidatePageCache(); E:RefreshPage(true) end)
                end
                v.specNote=Font(root,9); v.specNote:SetWidth(176); v.specNote:SetJustifyH("LEFT"); v.specNote:SetTextColor(.6,.62,.67,1)
                v.shared=CreateFrame("Button",nil,root); v.shared:SetWidth(176); v.shared:SetHeight(22)
                v.shared:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); v.shared:SetBackdropColor(.05,.06,.08,.95); v.shared:SetBackdropBorderColor(.2,.22,.28,1)
                v.shared.text=Font(v.shared,10); v.shared.text:SetPoint("CENTER"); v.shared.text:SetText("Use Shared List")
                v.shared:SetScript("OnClick",function() ops().UseShared() end)
                -- Indicator list
                for i=1,8 do v.items[i]=NewCard(root,LISTW,ops) end
                v.add=CreateFrame("Button",nil,root); v.add:SetWidth(LISTW); v.add:SetHeight(26)
                v.add:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1})
                v.add.text=Font(v.add,12); v.add.text:SetPoint("CENTER"); v.add.text:SetText("Add New")
                v.add:SetScript("OnClick",function(self) ShowAddMenu(v,self,prefix,ops) end)
                function v.UpdateCard(n,d,index,ids)
                    local b=v.items[n]; if not b then return end
                    local r,g,bl=Accent()
                    b.indicatorIndex=n; b:Show()
                    b.label:SetText((d.name or "Indicator "..n)..(d.enabled==false and "  |cff777777(off)|r" or ""))
                    b.label:SetTextColor(n==index and 1 or .86,n==index and 1 or .86,n==index and 1 or .88,1)
                    local names={}
                    for k=1,math.min(2,#ids) do names[#names+1]=GetSpellInfo(ids[k]) or tostring(ids[k]) end
                    b.detail:SetText((POS_LABEL[d.position or "BOTTOMLEFT"] or "")..(#ids>0 and " • "..table.concat(names,", ")..(#ids>2 and ", …" or "") or ""))
                    b.icon:SetTexture(ids[1] and select(3,GetSpellInfo(ids[1])) or "Interface\\Icons\\INV_Misc_QuestionMark")
                    b.accent:SetVertexColor(r,g,bl,n==index and 1 or 0)
                    b:SetBackdropBorderColor(n==index and r*.6 or .13,n==index and g*.6 or .14,n==index and bl*.6 or .18,1)
                    b.switch:SetOn(d.enabled~=false)
                end
                function v.UpdateSpec(ns,c,pre)
                    local spec=EditSpec(); local list=A.List(c,pre,true,spec)
                    local r,g,bl=Accent(); v.add:SetBackdropColor(r*.25,g*.25,bl*.25,.95); v.add:SetBackdropBorderColor(r,g,bl,.8)
                    v.add.text:SetTextColor(r,g,bl,1)
                    v.add:SetAlpha(#list>=8 and .4 or 1)
                    local own=spec~="all" and A.HasOwn(c,pre,spec)
                    v.shared:SetShown(own)
                    if spec=="all" then v.specNote:SetText("Applies to every spec without its own list.")
                    elseif own then v.specNote:SetText("Custom list for this spec.")
                    else v.specNote:SetText("Using the shared list. Changing anything creates a copy for this spec.") end
                    if v.specDD and v.specDD._invalidateMenu then v.specDD._invalidateMenu() end
                end
            end
            v.root:SetParent(parent); v.root:ClearAllPoints(); v.root:SetPoint("TOPLEFT",parent,"TOPLEFT",0,0)
            v.root:SetWidth(width); v.root:SetHeight(HEIGHT); v.root:Show()
            local specW=190
            v.canvasWidth=math.max(120,width-LISTW-specW-56); v.canvas:SetWidth(v.canvasWidth)
            local sx=16+v.canvasWidth+16
            v.specLabel:ClearAllPoints(); v.specLabel:SetPoint("TOPLEFT",v.root,"TOPLEFT",sx,-36)
            if v.specDD then v.specDD:ClearAllPoints(); v.specDD:SetPoint("TOPLEFT",v.root,"TOPLEFT",sx,-54) end
            v.specNote:ClearAllPoints(); v.specNote:SetPoint("TOPLEFT",v.root,"TOPLEFT",sx,-92)
            v.shared:ClearAllPoints(); v.shared:SetPoint("TOPLEFT",v.root,"TOPLEFT",sx,-136)
            local lx=width-LISTW-12
            for i=1,8 do v.items[i]:ClearAllPoints(); v.items[i]:SetPoint("TOPLEFT",v.root,"TOPLEFT",lx,-12-(i-1)*30) end
            v.add:ClearAllPoints(); v.add:SetPoint("BOTTOMLEFT",v.root,"BOTTOMLEFT",lx,10)
            E.UpdateWrathAuraIndicatorPreview(folder,prefix)
            return HEIGHT
        end
    end
    function E.BuildWrathAuraIndicators(folder,prefix,parent,y)
        -- The panel only shows a content header when the page itself asks for one
        -- (getHeaderBuilder is just the cache hook), so request it here. Skipped while
        -- global search prebuilds hidden pages, and when our header is already showing.
        if not E._prebuilding and E.SetContentHeader then
            local v=views[folder..prefix]; local host=E._contentHeader
            if not (v and host and v.root:GetParent()==host and v.root:IsShown()) then
                E:SetContentHeader(E.WrathAuraIndicatorHeader(folder,prefix))
            end
        end
        local ns,_,raid=Context(folder,prefix)
        local W=E.Widgets
        local function Settings() return select(2,Context(folder,prefix)) end
        local function Current() return Selected(ns,Settings(),prefix) end
        local function CurrentW()
            local list=WritableList(Settings(),prefix)
            local index=math.max(1,math.min(#list,ns["selected"..prefix.."Indicator"] or 1))
            return list[index],index,list
        end
        local function Row(a,b) local _,h=W:DualRow(parent,y,a,b or {type="label",text=""}); y=y-h end
        local function Section(text) local _,h=W:SectionHeader(parent,text,y); y=y-h end
        local function Button(text,fn) local _,h=W:WideButton(parent,text,y,fn); y=y-h end
        local function Apply()
            if raid then ns.Apply() else ns.UF_ReloadAllAuraContainers() end
            E.UpdateWrathAuraIndicatorPreview(folder,prefix)
        end
        local function Refresh() Apply(); E:InvalidatePageCache(); E:RefreshPage(true) end
        local function Property(key,label,kind,min,max,step)
            return {type=kind,text=label,min=min,max=max,step=step or 1,getValue=function()
                local d=Current(); if d[key]~=nil then return d[key] end
                local c=Settings(); return key=="maxIcons" and A.Limit(c,prefix,d) or key=="size" and (c[prefix.."Size"] or c.auraSize or 18) or key=="stackSize" and (c.auraStackTextSize or 10) or key=="durationSize" and (c.auraDurationTextSize or 9) or key=="x" and 0 or key=="y" and 0 or false
            end,setValue=function(value)
                local d,_,list=CurrentW()
                if key=="maxIcons" then
                    local other=0; for _,entry in ipairs(list) do if entry~=d then other=other+A.Limit(Settings(),prefix,entry) end end
                    value=math.max(0,math.min(tonumber(value) or 0,8-other))
                end
                d[key]=value; Apply()
            end}
        end
        local function DD(key,label,values,order) local d=Property(key,label,"dropdown"); d.values,d.order=values,order; return d end
        Section(raid and "GROUP SELECTION" or "FRAME SELECTION")
        if raid then
            Row({type="dropdown",text="Select Group",values={raid="Raid",party="Party"},order={"raid","party"},getValue=function() return ns.selectedWrathAuraGroup or "raid" end,setValue=function(v) ns.selectedWrathAuraGroup=v; Refresh() end},ns.RaidLayoutDropdown())
        else
            Row({type="dropdown",text="Select Frame",values={player="Player",target="Target",focus="Focus",boss1="Boss Frames"},order={"player","target","focus","boss1"},getValue=function() return ns.selectedWrathAuraUnit or "player" end,setValue=function(v) ns.selectedWrathAuraUnit=v; Refresh() end},
                {type="toggle",text="Use Indicator Layout",tooltip="Enable the indicators previewed above. Disable to return to the existing aura rows.",getValue=function() return Settings()[prefix.."IndicatorMode"] or false end,setValue=function(v) Settings()[prefix.."IndicatorMode"]=v; Apply() end})
        end
        if prefix=="debuff" and raid then
            Section("DEBUFF OPTIONS")
            Row({type="toggle",text="Hide Sated / Exhaustion",tooltip="Hides the Bloodlust/Heroism lockout debuffs from the debuff icons.",
                    getValue=function() local c=Settings(); return c and c.hideLustDebuff~=false end,
                    setValue=function(v) local c=Settings(); if c then c.hideLustDebuff=v; Apply() end end},
                {type="label",text="Dispel overlay, border and colors: Raid / Party > DISPELS"})
        end
        do
            local cur=Current()
            Section("ICON INDICATOR"..(cur and cur.name and (" — "..string.upper(cur.name)) or ""))
            local nameCfg=Property("name","Indicator Name","input"); nameCfg.inputStyle="popup"; nameCfg.inputWidth=200
            Row(Property("enabled","Enable Indicator","toggle"),nameCfg)
        end
        Section(prefix=="buff" and "ASSIGNED BUFFS" or "ASSIGNED DEBUFFS")
        Row(DD("filter","Indicator Filter",prefix=="buff" and {tracked="Only Assigned Spells"} or {tracked="Only Assigned Spells",own="Own Only",all="All Allowed"},prefix=="buff" and {"tracked"} or {"tracked","own","all"}),DD("showIn","Show In",{both=raid and "Raid and Party" or "Always",raid="Raid",party="Party"},{"both","raid","party"}))
        Row({type="input",text="Extra Spell IDs",inputStyle="popup",inputWidth=160,placeholder="974, 61295",getValue=function() return table.concat(A.SpellIDs(Current()),", ") end,setValue=function(v)
            local parsed=E.WrathAuraFilters.Parse(v); if not parsed then if E.PrintError then E.PrintError("Enter positive spell IDs separated by commas.") end; return end
            local d=CurrentW(); d.spells=parsed; d.spellOrder={}; local seen={}
            for token in tostring(v):gmatch("[^,%s;]+") do local id=tonumber(token); if not seen[id] then d.spellOrder[#d.spellOrder+1]=id; seen[id]=true end end
            Apply()
        end},Property("customOrder","Use Extra Spell Order","toggle"))
        Row(Property("ownOnly","Own Only","toggle"),Property("maxIcons","Icons Per Indicator","slider",0,8))
        Section("POSITION")
        Row(DD("position","Position",{TOPLEFT="Top Left",TOP="Top",TOPRIGHT="Top Right",LEFT="Left",CENTER="Center",RIGHT="Right",BOTTOMLEFT="Bottom Left",BOTTOM="Bottom",BOTTOMRIGHT="Bottom Right"},{"TOPLEFT","TOP","TOPRIGHT","LEFT","CENTER","RIGHT","BOTTOMLEFT","BOTTOM","BOTTOMRIGHT"}),DD("growth","Growth Direction",{RIGHT="Right",LEFT="Left",UP="Up",DOWN="Down"},{"RIGHT","LEFT","UP","DOWN"}))
        Row(Property("x","X Offset","slider",-100,100),Property("y","Y Offset","slider",-100,100))
        Section("DISPLAY")
        Row(Property("size","Size","slider",6,raid and 30 or 64),Property("spacing","Spacing","slider",0,12))
        Row(Property("opacity","Opacity","slider",.1,1,.05),Property("border","Border","slider",0,3))
        Row(Property("durationSwipe","Duration Swipe","toggle"),Property("durationText","Duration Text","toggle"))
        Row(Property("showStacks","Show Stacks","toggle"),Property("hideIcons","Hide Icons","toggle"))
        Row(Property("durationSize","Duration Text Size","slider",8,18),Property("stackSize","Stack Text Size","slider",8,18))
        E.UpdateWrathAuraIndicatorPreview(folder,prefix)
        return math.abs(y)
    end

    local newPreview,newHeader,newBuild=E.UpdateWrathAuraIndicatorPreview,E.WrathAuraIndicatorHeader,E.BuildWrathAuraIndicators
    E.UpdateWrathAuraIndicatorPreview=function(folder,prefix)
        if folder==RF then return newPreview(folder,prefix) end
        if origPreview then return origPreview(folder,prefix) end
    end
    E.WrathAuraIndicatorHeader=function(folder,prefix)
        if folder==RF or not origHeader then return newHeader(folder,prefix) end
        return origHeader(folder,prefix)
    end
    E.BuildWrathAuraIndicators=function(folder,prefix,parent,y)
        if folder==RF or not origBuild then return newBuild(folder,prefix,parent,y) end
        return origBuild(folder,prefix,parent,y)
    end
end

if IsAddOnLoaded and IsAddOnLoaded("EllesmereUIOptions") then
    Install()
else
    local waiter=CreateFrame("Frame")
    waiter:RegisterEvent("ADDON_LOADED")
    waiter:SetScript("OnEvent",function(self,_,name)
        if name=="EllesmereUIOptions" then self:UnregisterEvent("ADDON_LOADED"); Install() end
    end)
end
