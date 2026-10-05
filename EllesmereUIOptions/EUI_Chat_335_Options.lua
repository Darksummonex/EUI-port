local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
-- Only controls implemented by the Wrath chat module are exposed here.
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIChat
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function Get(key,fallback) local p=ns.GetSettings(); if not p or p[key]==nil then return fallback end; return p[key] end
    local function Set(key,value) local p=ns.GetSettings(); if p then p[key]=value; ns.Apply() end end
    local function Toggle(key,label,fallback,tooltip)
        return {type="toggle",text=label,tooltip=tooltip,getValue=function() return Get(key,fallback or false) end,setValue=function(v) Set(key,v) end}
    end
    local function Slider(key,label,min,max,step,fallback)
        return {type="slider",text=label,min=min,max=max,step=step,getValue=function() return Get(key,fallback) end,setValue=function(v) Set(key,v) end}
    end
    E:RegisterModule("EllesmereUIChat",{
        title="Chat",description="Native Wrath chat windows, fonts, copy and clickable URLs.",pages={"Chat","Fonts"},
        searchTerms="chat copy url timestamp font tabs edit input scroll wheel background border position",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(left,right) local _,h=W:DualRow(parent,y,left,right); y=y-h end
            local function Section(label) local _,h=W:SectionHeader(parent,label,y); y=y-h end
            if page=="Chat" then
                Section("DISPLAY")
                Row(Toggle("enabled","Enable Chat",true),Toggle("skinEditBox","Style Input Box",true))
                Row(Slider("width","Primary Window Width",200,900,1,420),Slider("height","Primary Window Height",80,600,1,180))
                Row(Slider("bgAlpha","Background Opacity",0,1,.05,.65),Slider("borderSize","Border Size",0,8,1,1))
                Row({type="colorpicker",text="Background Color",hasAlpha=false,
                    getValue=function() return Get("bgR",.03),Get("bgG",.045),Get("bgB",.05) end,
                    setValue=function(r,g,b) local p=ns.GetSettings(); if p then p.bgR,p.bgG,p.bgB=r,g,b; ns.Apply() end end},
                    {type="colorpicker",text="Border Color",hasAlpha=true,
                    getValue=function() return Get("borderR",0),Get("borderG",0),Get("borderB",0),Get("borderA",1) end,
                    setValue=function(r,g,b,a) local p=ns.GetSettings(); if p then p.borderR,p.borderG,p.borderB,p.borderA=r,g,b,a or 1; ns.Apply() end end})
                Row(Toggle("skinTabs","Style Tab Text",true),Toggle("inputOnTop","Input Above Chat"))
                Row(Toggle("hideButtons","Hide Native Button Column"),Toggle("showSettings","Show Options Button",true))
                Row(Toggle("squareSkin","Square Skin",true,"Flat square tabs and scroll buttons with a selected-tab accent. Native clicks, docking and dragging are preserved."),{type="label",text=""})
                Section("MESSAGES")
                Row(Toggle("timestamps","Timestamps",true),{type="dropdown",text="Timestamp Format",
                    values={["%H:%M"]="24 Hour",["%I:%M %p"]="12 Hour",["%H:%M:%S"]="Hours, Minutes, Seconds"},
                    order={"%H:%M","%I:%M %p","%H:%M:%S"},getValue=function() return Get("timestampFormat","%H:%M") end,
                    setValue=function(v) Set("timestampFormat",v) end})
                Row(Toggle("clickableURLs","Clickable URLs",true,"Click an http, https or www address to select it for Ctrl+C."),Toggle("showCopy","Show Copy Button",true))
                Row(Slider("copyLines","Copy Buffer Lines",50,2000,50,500),Toggle("mouseWheel","Mouse Wheel Scrolling",true,"Hold Shift to scroll to the top or bottom."))
                Row(Toggle("fadeMessages","Fade Old Messages"),Slider("fadeSeconds","Message Fade Delay",10,600,5,120))
                local _,h=W:WideButton(parent,"Copy Current Chat Window",y,function() ns.CopyChat() end); y=y-h
                _,h=W:WideButton(parent,"Reset Position",y,function() ns.ResetPosition() end); y=y-h
                _,h=W:WideButton(parent,"Unlock Mode",y,function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end); y=y-h
            elseif page=="Fonts" then
                Section("FONTS")
                local values,order=E.BuildFontDropdownData()
                local function Font(key,label,fallback)
                    return {type="dropdown",text=label,values=values,order=order,getValue=function() return Get(key,fallback) end,setValue=function(v) Set(key,v) end}
                end
                Row(Font("font","Chat Font","__global"),Slider("chatFontSize","Chat Font Size",8,27,1,12))
                Row(Font("tabFont","Tab Font","__global"),Slider("tabFontSize","Tab Font Size",8,24,1,11))
                local ebValues,ebOrder=E.BuildFontDropdownData(); ebValues["__chat"]="Chat Font"; table.insert(ebOrder,1,"__chat")
                Row({type="dropdown",text="Input Font",values=ebValues,order=ebOrder,getValue=function() return Get("editBoxFont","__chat") end,setValue=function(v) Set("editBoxFont",v) end},
                    Slider("editBoxFontSize","Input Font Size",8,24,1,12))
                Row({type="dropdown",text="Outline Mode",values={["__global"]="Global",none="None",outline="Outline",thick="Thick Outline"},
                    order={"__global","none","outline","thick"},getValue=function() return Get("outlineMode","__global") end,
                    setValue=function(v) Set("outlineMode",v) end},{type="label",text=""})
            end
            return math.abs(y)
        end,
        onReset=function() if ns.addon.db and ns.addon.db.ResetProfile then ns.addon.db:ResetProfile() end; ns.Apply(); E:InvalidatePageCache() end,
    })
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
