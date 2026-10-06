local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIArena
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame"); init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function Store() return ns.GetSettings() end
    local function Field(key,label,kind,min,max,tooltip)
        return {type=kind,text=label,min=min,max=max,step=1,tooltip=tooltip,
            getValue=function() local t=Store(); return t and t[key] end,
            setValue=function(value) local t=Store(); if t then t[key]=value; ns.Apply() end end}
    end
    local function Toggle(key,label,tooltip) return Field(key,label,"toggle",nil,nil,tooltip) end
    local function Slider(key,label,min,max,tooltip) return Field(key,label,"slider",min,max,tooltip) end
    local function Label(text) return {type="label",text=text} end
    local function Dropdown(key,label,values,order)
        local row=Field(key,label,"dropdown"); row.values=values; row.order=order; return row
    end
    local function Color(key,label)
        return {type="colorpicker",text=label,
            getValue=function() local t=Store(); local c=t and t[key] or {}; return c.r or 1,c.g or 1,c.b or 1,1 end,
            setValue=function(r,g,b) local t=Store(); if not t then return end
                local c=type(t[key])=="table" and t[key] or {}; t[key]=c; c.r,c.g,c.b=r,g,b; ns.Apply() end}
    end
    local SIDES,SIDE_ORDER={LEFT="Left",RIGHT="Right"},{"LEFT","RIGHT"}
    if ns.RegisterElementPanels then ns.RegisterElementPanels() end
    E:RegisterModule("EllesmereUIArena",{title="Arena Frames",description="Enemy arena frames with PvP trinket, crowd control and cast tracking.",pages={"Arena Frames"},
        searchTerms="arena enemy frames arena1 pvp trinket every man for himself crowd control cc immunity cast bar interrupt focus target stealth unseen class icon",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local function Row(a,b) local row,h=W:DualRow(parent,y,a,b or Label("")); y=y-h; return row end
            local function Section(label) local _,h=W:SectionHeader(parent,label,y); y=y-h end
            local function Button(label,fn) local _,h=W:WideButton(parent,label,y,fn); y=y-h end
            if page=="Arena Frames" then
                Section("GENERAL")
                Row(Toggle("enabled","Enable Arena Frames","Shows your arena opponents. Left click targets, right click sets focus."),
                    Toggle("hideBlizzard","Hide Blizzard Arena Frames","Hides the default arena enemy frames while these are enabled."))
                Row(Slider("previewCount","Preview Frames",2,5,"Number of test frames shown while this page is open or in Unlock Mode."),Label("Test frames: this page, Unlock Mode or /earena test"))
                Button("Unlock Arena Frames",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
                Section("LAYOUT")
                Row(Slider("width","Frame Width",100,350),Slider("height","Frame Height",20,80))
                Row(Slider("spacing","Frame Spacing",0,60),Dropdown("growth","Growth Direction",{DOWN="Down",UP="Up"},{"DOWN","UP"}))
                Row(Slider("borderSize","Border Size",0,3),Label(""))
                Section("HEALTH AND POWER")
                Row(Dropdown("texture","Bar Texture",ns.textureNames,ns.textureOrder),Toggle("classColored","Class Colored Health"))
                Row(Color("healthColor","Custom Health Color"),Slider("bgDarkness","Background Darkness",0,100))
                Row(Toggle("showPower","Show Power Bar"),Slider("powerHeight","Power Bar Height",2,20))
                Section("TEXT")
                Row(Slider("nameSize","Name Size",8,20),Toggle("classColoredNames","Class Colored Names"))
                Row(Dropdown("healthText","Health Text",{percent="Percent",current="Current",both="Current | Percent",none="None"},{"percent","current","both","none"}),Slider("healthTextSize","Health Text Size",8,20))
                Section("ICONS")
                Row(Toggle("classIcon","Show Class Icon"),Dropdown("iconSide","Class Icon Side",SIDES,SIDE_ORDER))
                Row(Toggle("ccOnIcon","Crowd Control on Class Icon","Replaces the class icon with the strongest stun, silence, fear, root or immunity on that enemy."),
                    Dropdown("iconStyle","Class Icon Style",{modern="Modern",blizzard="Blizzard"},{"modern","blizzard"}))
                Row(Toggle("trinket","Show PvP Trinket","Tracks PvP Trinket and Every Man for Himself (2 minute cooldown) from the combat log."),Dropdown("trinketSide","Trinket Side",SIDES,SIDE_ORDER))
                Row(Toggle("timers","Cooldown Timer Text"),Slider("timerSize","Timer Text Size",8,20))
                Section("CAST BAR")
                Row(Toggle("castBar","Show Cast Bar"),Slider("castBarHeight","Cast Bar Height",8,30))
                Row(Toggle("castIcon","Show Cast Icon"),Slider("castTextSize","Cast Text Size",8,18))
                Row(Color("castColor","Cast Color"),Color("uninterruptibleColor","Uninterruptible Color"))
                Section("TARGET AND VISIBILITY")
                Row(Toggle("targetBorder","Highlight Target"),Color("targetColor","Target Highlight Color"))
                Row(Slider("unseenAlpha","Unseen Opacity",10,100,"Opacity of enemies that are stealthed or out of sight."),Label(""))
            end
            return math.abs(y)
        end,
        onReset=function() ns.addon.db:ResetProfile(); ns.Apply(); E:InvalidatePageCache() end})
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
