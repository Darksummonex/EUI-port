-- Shared non-secure editor and preview for raid/party and unit-frame indicators.
local E=EllesmereUI
local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local A=E.WrathAuraIndicators
local views={}
E.WrathAuraIndicatorViews=views
local white="Interface\\Buttons\\WHITE8X8"
local function Context(folder,prefix)
    local ns=E._ModuleNS[folder]; local raid=folder=="EllesmereUIRaidFrames"
    local c=raid and ns.GetOptionSettings(ns.selectedWrathAuraGroup or "raid") or ns.UF_GetSettings(ns.selectedWrathAuraUnit or "player")
    return ns,c,raid
end
local function Selected(ns,c,prefix)
    local list=A.List(c,prefix,true)
    local index=math.max(1,math.min(#list,ns["selected"..prefix.."Indicator"] or 1))
    return list[index],index,list
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
    view.title:SetText((prefix=="buff" and "Buff" or "Debuff").." Indicators — "..(raid and (ns.selectedWrathAuraGroup or "raid").." "..(ns.selectedRaidLayout or ns.activeRaidLayout or "40") or (ns.selectedWrathAuraUnit or "player")))
    local used=0; local minX,maxX,minY,maxY=-w/2,w/2,-h/2,h/2
    for _,a in ipairs(view.icons) do a:Hide() end
    for n,d in ipairs(list) do
        local ids=A.SpellIDs(d); local limit=A.Limit(c,prefix,d)
        local b=view.items[n]; b.indicatorIndex=n; b:Show()
        b.label:SetText((n==index and "|cff0cd29f" or "|cffdddddd")..(d.name or "Indicator "..n).."|r")
        b.detail:SetText((d.position or "BOTTOMLEFT").." • "..(d.enabled==false and "Disabled" or tostring(#ids).." spells"))
        b.icon:SetTexture(ids[1] and select(3,GetSpellInfo(ids[1])) or "Interface\\Icons\\INV_Misc_QuestionMark")
        local ar,ag,ab=.05,.82,.61; if E.GetAccentColor then ar,ag,ab=E.GetAccentColor() end
        b:SetBackdropBorderColor(n==index and ar or .2,n==index and ag or .2,n==index and ab or .2,1)
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
end
function E.WrathAuraIndicatorHeader(folder,prefix)
    return function(parent,width)
        if E._prebuilding then return 0 end
        local key=folder..prefix; local v=views[key]
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
            v.hint=Font(root,10); v.hint:SetPoint("BOTTOMLEFT",root,"BOTTOMLEFT",16,8)
            local function Pick(n)
                local ns=Context(folder,prefix); ns["selected"..prefix.."Indicator"]=n
                E:InvalidatePageCache(); E:RefreshPage(true)
            end
            for i=1,8 do
                local a=A.NewIcon(host); v.icons[i]=a
                a:SetScript("OnClick",function(self) Pick(self.indicatorIndex) end)
                local b=CreateFrame("Button",nil,root); v.items[i]=b; b:SetWidth(216); b:SetHeight(24)
                b:SetPoint("TOPRIGHT",root,"TOPRIGHT",-12,-32-(i-1)*25)
                b:SetBackdrop({bgFile=white,edgeFile=white,edgeSize=1}); b:SetBackdropColor(.04,.05,.06,.9)
                b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetWidth(20); b.icon:SetHeight(20); b.icon:SetPoint("LEFT",b,"LEFT",2,0)
                b.label=Font(b,10); b.label:SetPoint("TOPLEFT",b,"TOPLEFT",26,-2); b.label:SetWidth(184); b.label:SetHeight(11); b.label:SetJustifyH("LEFT")
                b.detail=Font(b,8); b.detail:SetPoint("BOTTOMLEFT",b,"BOTTOMLEFT",26,2); b.detail:SetWidth(184); b.detail:SetHeight(9); b.detail:SetJustifyH("LEFT")
                b:SetScript("OnClick",function(self) Pick(self.indicatorIndex) end)
            end
        end
        v.root:SetParent(parent); v.root:ClearAllPoints(); v.root:SetPoint("TOPLEFT",parent,"TOPLEFT",0,0)
        v.root:SetWidth(width); v.root:SetHeight(244); v.root:Show()
        v.canvasWidth=math.max(120,width-260); v.canvas:SetWidth(v.canvasWidth)
        E.UpdateWrathAuraIndicatorPreview(folder,prefix)
        return 244
    end
end
function E.BuildWrathAuraIndicators(folder,prefix,parent,y)
    local ns,_,raid=Context(folder,prefix)
    local W=E.Widgets
    local function Settings() return select(2,Context(folder,prefix)) end
    local function Current() return Selected(ns,Settings(),prefix) end
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
            local d,_,list=Current()
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
    Section("ICON INDICATORS")
    local _,_,list=Current(); local values,order={},{}
    for i,d in ipairs(list) do values[i]=d.name or "Indicator "..i; order[i]=i end
    Row({type="dropdown",text="Select Indicator",values=values,order=order,getValue=function() return select(2,Current()) end,setValue=function(v) ns["selected"..prefix.."Indicator"]=v; Refresh() end},Property("enabled","Enable Indicator","toggle"))
    local function Add(d)
        local list=A.List(Settings(),prefix,true); local used=0
        for _,entry in ipairs(list) do used=used+A.Limit(Settings(),prefix,entry) end
        if #list>=8 or used>=8 then if E.PrintError then E.PrintError("Reduce Icons Per Indicator to make room (eight icons per aura type).") end; return end
        d.maxIcons=math.min(d.maxIcons or 1,8-used); list[#list+1]=d; ns["selected"..prefix.."Indicator"]=#list; Refresh()
    end
    Button("Add New Indicator",function() local d=A.Preset("manual"); d.name="Manual "..(prefix=="buff" and "Buffs" or "Debuffs"); d.maxIcons=1; Add(d) end)
    if prefix=="buff" then
        Button("Add Healer Buff Indicator",function() Add(A.Preset("healing")) end)
        Button("Add Personal Defensive Indicator",function() Add(A.Preset("defensive")) end)
        Button("Add External Cooldown Indicator",function() Add(A.Preset("external")) end)
    end
    Button("Remove Selected Indicator",function() local _,i,list=Current(); if #list<=1 then return end; table.remove(list,i); ns["selected"..prefix.."Indicator"]=1; Refresh() end)
    Row(Property("name","Indicator Name","input"),{type="label",text="Healing / defensives / externals; add other buffs manually"})
    Section("ASSIGNED SPELLS")
    Row(DD("filter","Indicator Filter",prefix=="buff" and {tracked="Only Assigned Spells"} or {tracked="Only Assigned Spells",own="Own Only",all="All Allowed"},prefix=="buff" and {"tracked"} or {"tracked","own","all"}),DD("showIn","Show In",{both=raid and "Raid and Party" or "Always",raid="Raid",party="Party"},{"both","raid","party"}))
    Row({type="input",text="Extra Spell IDs",inputStyle="popup",inputWidth=160,placeholder="974, 61295",getValue=function() return table.concat(A.SpellIDs(Current()),", ") end,setValue=function(v)
        local parsed=E.WrathAuraFilters.Parse(v); if not parsed then if E.PrintError then E.PrintError("Enter positive spell IDs separated by commas.") end; return end
        local d=Current(); d.spells=parsed; d.spellOrder={}; local seen={}
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
