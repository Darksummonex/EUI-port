local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame
-- Retail Chat pages on Wrath widgets; every control has a native implementation.
local E=EllesmereUI
local ns=E and E._ModuleNS and E._ModuleNS.EllesmereUIChat
if not ns or not ns.IsWrath then return end
local init=CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local function DB() return ns.GetSettings() end
    local function Get(key,fallback) local p=DB(); if not p or p[key]==nil then return fallback end; return p[key] end
    local function Set(key,value) local p=DB(); if p then p[key]=value; ns.Apply() end end
    local function Toggle(key,label,fallback,tooltip,disabled)
        return {type="toggle",text=label,tooltip=tooltip,disabled=disabled,
            getValue=function() return Get(key,fallback or false) end,setValue=function(v) Set(key,v) end}
    end
    local function Slider(key,label,min,max,step,fallback,tooltip,disabled)
        return {type="slider",text=label,min=min,max=max,step=step,tooltip=tooltip,disabled=disabled,
            getValue=function() return Get(key,fallback) end,setValue=function(v) Set(key,v) end}
    end
    local function Dropdown(key,label,values,order,fallback,tooltip,disabled)
        return {type="dropdown",text=label,values=values,order=order,tooltip=tooltip,disabled=disabled,
            getValue=function() return Get(key,fallback) end,setValue=function(v) Set(key,v) end}
    end
    -- Color tables keyed {r,g,b[,a]}, as stored by Retail.
    local function Color(key,label,hasAlpha,fallback,tooltip,disabled)
        return {type="colorpicker",text=label,hasAlpha=hasAlpha,tooltip=tooltip,disabled=disabled,
            getValue=function()
                local c=Get(key) or fallback or {}
                return c.r or 1,c.g or 1,c.b or 1,c.a==nil and 1 or c.a
            end,
            setValue=function(r,g,b,a)
                local p=DB(); if not p then return end
                local c={r=r,g=g,b=b}; if hasAlpha then c.a=a or 1 end
                p[key]=c; ns.Apply()
            end}
    end
    local spacer={type="spacer"}
    local function Off(key) return function() return not Get(key,false) end end
    local function FilterScopesOff()
        for _,key in ipairs({"spamFilterEnabled","spamFilterKeywordsEnabled","spamFilterTrade","spamFilterRecruitment","spamFilterGoldSellers"}) do
            if Get(key,false) then return false end
        end
        return true
    end
    local function Stock() return ns.ChatStyle()~="eui" end
    local sources={custom="Custom",accent="Accent Color",class="Class Color"}
    local sourceOrder={"custom","accent","class"}
    local twoSources={custom="Custom",accent="Accent Color"}
    local twoOrder={"custom","accent"}
    local sizes={none="None",thin="Thin",normal="Normal",heavy="Heavy",strong="Strong"}
    local sizeOrder={"none","thin","normal","heavy","strong"}
    local function BorderTextures()
        if E.GetBorderTextureDropdown then
            local ok,values,order=pcall(E.GetBorderTextureDropdown)
            if ok and values and order then return values,order end
        end
        return {solid="Solid"},{"solid"}
    end
    local function BarTextures()
        if ns.ECHAT.RefreshBgTextureCatalogue then ns.ECHAT.RefreshBgTextureCatalogue() end
        local values,order={},{}
        for _,key in ipairs(ns.chatBgTextureOrder or {}) do
            if key~="---" then values[key]=(ns.chatBgTextureNames or {})[key] or key; order[#order+1]=key end
        end
        return values,order
    end
    local function Sounds()
        local values,order={none="None"},{"none"}
        local catalogue=E.GetAlertSoundCatalogue or E.BuildAlertSoundTables
        if catalogue then
            local _,names,o=catalogue()
            values,order={},{}
            for _,key in ipairs(o) do if key~="---" then values[key]=names[key] or key; order[#order+1]=key end end
            values.none="None"
        end
        return values,order
    end
    local stamps={__blizzard="Blizzard Default",none="None",["%I:%M "]="03:27",["%I:%M:%S "]="03:27:32",
        ["%I:%M %p "]="03:27 PM",["%I:%M:%S %p "]="03:27:32 PM",["%H:%M "]="15:27",["%H:%M:%S "]="15:27:32"}
    local stampOrder={"__blizzard","none","%I:%M ","%I:%M:%S ","%I:%M %p ","%I:%M:%S %p ","%H:%M ","%H:%M:%S "}
    local outlines={__global="EUI Global Default",none="Drop Shadow",outline="Outline",thick="Thick Outline"}
    local outlineOrder={"__global","none","outline","thick"}
    local iconLabels={showFriends="Friends",showGuild="Guild",showDurability="Durability",showCopy="Copy Chat",
        showVoice="Voice/Channels",showSettings="Settings",showScroll="Scroll to Bottom"}
    E:RegisterModule("EllesmereUIChat",{
        title="Chat",description="Wrath chat windows with the EllesmereUI panel, tabs, sidebar and chat bubbles.",
        pages={"Chat","Tabs","Sidebar","Chat Bubbles","Spam Filter"},
        searchTerms="chat copy url timestamp font tabs edit input scroll wheel background border position sidebar friends guild durability idle fade whisper sound history channel abbreviate class color bubbles spam filter repeated duplicate messages hardcore deaths slain hidden messages log",
        buildPage=function(page,parent,y)
            local W=E.Widgets
            local PP=E.PP or E.PanelPP
            local live=not E._prebuilding
            local function Row(left,right) local row,h=W:DualRow(parent,y,left,right); y=y-h; return row end
            local function Section(label) local _,h=W:SectionHeader(parent,label,y); y=y-h end
            local function Button(label,fn) local _,h=W:WideButton(parent,label,y,fn); y=y-h end
            local function Swatch(row,side,get,set,hasAlpha)
                local region=row and row[side]
                if not (live and E.BuildColorSwatch and region) then return end
                local swatch,refresh=E.BuildColorSwatch(region,row:GetFrameLevel()+3,get,set,hasAlpha,20)
                swatch:ClearAllPoints(); swatch:SetPoint("RIGHT",region._control or region,"LEFT",-8,0)
                if E.RegisterWidgetRefresh and refresh then E.RegisterWidgetRefresh(refresh) end
            end
            local function StockNote()
                if Stock() then Row({type="label",text="A stock chat style is active on the Style page: the panel, tabs and sidebar keep Blizzard's look."},spacer) end
            end
            if page=="Chat" then
                Section("DISPLAY")
                Row(Toggle("enabled","Enable Chat",true),
                    Toggle("lockChatSize","Lock Main Chat Size",false,"Hides the resize handle on the main chat frame, preventing accidental resizing."))
                local outlineCfg=Dropdown("outlineMode","Outline Mode",outlines,outlineOrder,"__global")
                if E.BuildVisibilityRow then
                    local _,h=E.BuildVisibilityRow(W,parent,y,{getStore=DB,legacyKey="visibility",
                        caps={partyIncludesRaid=false,noMouseover=true},
                        onChanged=function() ns.ResetIdle(); ns.Apply() end,onOptionChanged=ns.Apply},outlineCfg)
                    y=y-h
                else
                    Row(Dropdown("visibility","Visibility",{always="Always",never="Never",in_combat="In Combat",
                        out_of_combat="Out of Combat",in_party="In Party",in_raid="In Raid",solo="Solo"},
                        {"always","never","in_combat","out_of_combat","in_party","in_raid","solo"},"always"),outlineCfg)
                end
                local texValues,texOrder=BarTextures()
                local bgRow=Row(Slider("bgAlpha","Background Opacity",0,1,.05,.65),
                    Dropdown("bgTexture","Background Texture",texValues,texOrder,"none","Texture drawn with the chat background color."))
                Swatch(bgRow,"_leftRegion",function() return Get("bgR",.03),Get("bgG",.045),Get("bgB",.05) end,
                    function(r,g,b) local p=DB(); if p then p.bgR,p.bgG,p.bgB=r,g,b; ns.Apply() end end,false)
                local fonts,fontOrder=E.BuildFontDropdownData()
                local fontSize=Slider("chatFontSize","Font Size",8,27,1,12,"Every chat window. A tab menu size choice updates this value.")
                fontSize.setValue=function(v) ns.ECHAT.ApplyChatFontSize(v) end
                Row(Dropdown("font","Font",fonts,fontOrder,"__global"),fontSize)
                local borderValues,borderOrder=BorderTextures()
                local noBorder=function() return Get("panelBorderThickness","none")=="none" end
                Row(Dropdown("panelBorderTexture","Border Style",borderValues,borderOrder,"solid"),
                    Dropdown("panelBorderThickness","Border Size",sizes,sizeOrder,"none"))
                Row(Color("panelBorderColor","Border Color",false,{r=1,g=1,b=1},nil,noBorder),
                    Dropdown("panelBorderColorMode","Border Color Source",sources,sourceOrder,"custom",nil,noBorder))
                Row(Slider("panelBorderOpacity","Border Opacity",0,1,.05,.18,nil,noBorder),
                    Toggle("panelBorderBehind","Show Border Behind",false,"Draws the border below the chat background.",noBorder))
                Row(Slider("width","Main Chat Width",200,900,1,420),Slider("height","Main Chat Height",80,600,1,180))
                Section("IDLE FADE")
                Row(Toggle("idleFadeEnabled","Enable Idle Fade",true,"Fades the chat after a period without messages, hovering or typing."),
                    Slider("idleFadeDelay","Fade Delay (seconds)",5,30,1,15,nil,Off("idleFadeEnabled")))
                Row(Slider("idleFadeStrength","Fade Strength",0,100,1,40,"100 hides the chat completely until it is hovered.",Off("idleFadeEnabled")),spacer)
                Section("INPUT FIELD")
                Row(Toggle("inputOnTop","Input on Top",false,"Moves the input field above the messages."),
                    Slider("editBoxHeight","Edit Box Height",10,60,1,23))
                local ebFonts,ebOrder=E.BuildFontDropdownData(); ebFonts["__chat"]="Chat Font"; table.insert(ebOrder,1,"__chat")
                Row(Dropdown("editBoxFont","Edit Box Font",ebFonts,ebOrder,"__chat"),Slider("editBoxFontSize","Edit Box Font Size",8,24,1,12))
                Section("EXTRAS")
                Row(Toggle("persistChatHistory","Remember Last Chat Lines",true,"Shows the last lines of each chat window again after a reload or relog."),
                    Slider("persistChatHistoryMaxLines","Remembered Lines",20,300,10,100,nil,Off("persistChatHistory")))
                local soundValues,soundOrder=Sounds()
                Row(Toggle("hideTooltipOnHover","Hide Tooltip on Hover",true,"Off: hovering an item, spell, quest or achievement link shows its tooltip."),
                    Dropdown("whisperSoundKey","Whisper Sound",soundValues,soundOrder,"none",
                        "Plays with each incoming whisper, alongside the game's own whisper sound."))
                local bordersRow=Row(Toggle("hideBorders","Hide Borders",false,"Hides the thin dividers between the messages, input field and sidebar."),
                    Dropdown("innerBorderColorMode","Divider Color Source",twoSources,twoOrder,"custom",nil,function() return Get("hideBorders",false) end))
                Swatch(bordersRow,"_leftRegion",function() local c=Get("innerBorderColor",{}); return c.r or 1,c.g or 1,c.b or 1,c.a or .06 end,
                    function(r,g,b,a) Set("innerBorderColor",{r=r,g=g,b=b,a=a or .06}) end,true)
                Row(Toggle("timestampAll","Timestamp All Messages",false,"Off: only player chat is stamped, as the game does."),
                    Dropdown("timestampFormat","Timestamps",stamps,stampOrder,"%I:%M ","Blizzard Default keeps the Interface Options timestamp setting."))
                Row(Toggle("abbreviateChannels","Shortened Channel Names",true,"[Party] becomes [P], [2. Trade - City] becomes [2]."),
                    Toggle("abbreviateChannelLetters","Use Letters",false,"World channels as letters: General Ge, Trade T, LocalDefense LD, WorldDefense WD, LookingForGroup LFG.",Off("abbreviateChannels")))
                Row(Toggle("classColorNames","Class Colored Names",true,"Colors group and raid member names inside Say, Yell, Party and Raid messages."),
                    Toggle("clickableURLs","Clickable URLs",true,"Click an http, https or www address to copy it."))
                Row(Toggle("mouseWheel","Mouse Wheel Scrolling",true,"Hold Shift to scroll to the top or bottom."),
                    Slider("copyLines","Copy Buffer Lines",50,2000,50,500))
                Row(Toggle("fadeMessages","Fade Old Messages"),Slider("fadeSeconds","Message Fade Delay",10,600,5,120,nil,Off("fadeMessages")))
                Button("Copy Current Chat Window",function() ns.CopyChat() end)
                Button("Reset Position",function() ns.ResetPosition() end)
                Button("Unlock Mode",function() if E.ToggleUnlockMode then E:ToggleUnlockMode() end end)
            elseif page=="Spam Filter" then
                Section("REPEATED MESSAGES")
                Row(Toggle("spamFilterEnabled","Filter Repeated Messages",false,"Hide repeated messages within the repeat window. Your own messages are always shown. Requires Enable Chat."),
                    Slider("spamFilterWindow","Repeat Window (seconds)",1,120,1,15,"Time from the last displayed matching message. Hidden repeats do not extend the window.",Off("spamFilterEnabled")))
                Row(Toggle("spamFilterAnySender","Match Across Senders",false,"Off: match repeats from the same sender. On: also hide matching messages sent by other players in the same channel.",Off("spamFilterEnabled")),spacer)
                Section("REPEATS AND KEYWORDS IN")
                Row(Toggle("spamFilterPublic","Public Chat",true,"Say, Yell and numbered channels such as General, Trade and World. Scopes repeat, keyword, trade ad and recruitment filters.",FilterScopesOff),
                    Toggle("spamFilterGroup","Group and Guild Chat",false,"Party, raid (including warnings), battleground, guild and officer chat. Scopes repeat and keyword filters.",FilterScopesOff))
                Row(Toggle("spamFilterWhispers","Incoming Whispers",false,"Outgoing whispers and GM whispers are always shown. Scopes repeat and keyword filters.",FilterScopesOff),spacer)
                Row({type="label",text="Matches text ignoring letter case and extra spaces, within the same chat type and channel. NPC dialogue and other system messages are always shown."},spacer)
                Button("Show Hidden Messages",function() if ns.ShowHiddenLog then ns.ShowHiddenLog() end end)
                Button("Reset Repeat Memory",function() ns.ResetSpamFilter() end)
                Section("PRESET FILTERS")
                Row(Toggle("spamFilterGoldSellers","Filter Gold Sellers",true,"Hide gold-sale ads that include a website or cash price, including ads like sell 5000 G = 19 Web. Enabled by default. Uses Public Chat, Group and Guild Chat, and Incoming Whispers above."),spacer)
                Row(Toggle("spamFilterAchievements","Filter Achievements",false,"Hide player and guild achievement announcements. Your own achievements remain visible."),spacer)
                Row(Toggle("spamFilterTrade","Filter Trade Ads",false,"Hide public chat ads containing whole words such as WTS, WTB, WTT, LFW, selling, buying, vendo or compro. Needs Public Chat above. Does not hide the entire Trade channel."),
                    Toggle("spamFilterRecruitment","Filter Guild Recruitment",false,"Hide common English and Portuguese guild recruitment or looking-for-guild phrases in public chat. Raid ads such as <Guild> LF heal ICC are kept. Needs Public Chat above."))
                Section("HARDCORE")
                Row(Toggle("spamFilterHardcoreDeaths","Filter Hardcore Deaths",false,"Hide server death announcements such as \"Name the level 11 Gnome Warrior has been slain by ... in Westfall\". Works in every chat window, independent of the chat types above."),
                    Slider("spamFilterHardcoreKeepLevel","Keep Deaths From Level",1,81,1,81,"Deaths at this level or higher stay visible, for example 80 to still see max level deaths. 81 hides every death.",Off("spamFilterHardcoreDeaths")))
                Section("CUSTOM KEYWORDS")
                Row(Toggle("spamFilterKeywordsEnabled","Filter Keywords",false,"Hide messages containing any custom word or phrase, in the scopes selected above. Works independently of repeated-message filtering."),
                    {type="input",text="Blocked Keywords",inputStyle="popup",inputWidth=180,placeholder="boost, gold seller",tooltip="Separate words or phrases with commas or semicolons. Case insensitive, including accented letters, literal substring matching. Empty entries are ignored.",
                        getValue=function() return Get("spamFilterKeywords","") end,
                        setValue=function(v) Set("spamFilterKeywords",type(v)=="string" and v or "") end,
                        disabled=Off("spamFilterKeywordsEnabled")})
                Row({type="label",text="Preset filters work independently of repeats. Your own messages are preserved. Keyword and recruitment matches can hide legitimate messages; enable only the filters you want."},spacer)
            elseif page=="Tabs" then
                StockNote()
                Section("LAYOUT")
                Row(Toggle("extendBgBehindTabs","Tabs Inside Chat Panel",false,"Extends the chat background behind the tab strip."),
                    Toggle("alignTabsToPanel","Align Tabs to Full Panel",false,"Starts the tab strip at the sidebar edge."))
                Row(Slider("tabSpacing","Tab Spacing",0,10,1,1),Slider("tabPadding","Bottom Spacing",0,20,1,0))
                Row(Slider("tabHeight","Tab Height",18,40,1,24),Slider("tabInnerPaddingX","Inner Padding X",0,30,1,12))
                Row(Slider("tabOffsetX","Tab Offset X",-100,100,1,0),spacer)
                Section("TYPOGRAPHY")
                local fonts,fontOrder=E.BuildFontDropdownData()
                Row(Dropdown("tabFont","Tab Font",fonts,fontOrder,"__global"),Slider("tabFontSize","Tab Font Size",8,24,1,11))
                Row(Color("tabFontColor","Tab Font Color",true,{r=1,g=1,b=1,a=.65}),Color("tabFontColorActive","Active Tab Font Color",true,{r=1,g=1,b=1,a=1}))
                Row(Dropdown("tabFontColorMode","Tab Font Color Source",sources,sourceOrder,"custom"),
                    Dropdown("tabFontColorActiveMode","Active Font Color Source",sources,sourceOrder,"custom"))
                Section("APPEARANCE")
                Row(Color("tabBackgroundColor","Tab Background Color",true,{r=.03,g=.045,b=.05,a=.44}),
                    Color("tabBackgroundColorActive","Active Tab Background",true,{r=.03,g=.045,b=.05,a=.65}))
                local texValues,texOrder=BarTextures()
                Row(Dropdown("tabBackgroundColorActiveMode","Active Background Source",sources,sourceOrder,"custom"),
                    Dropdown("tabBackgroundTexture","Tab Texture",texValues,texOrder,"none"))
                Row(Toggle("activeUnderline","Active Underline",true),
                    Dropdown("activeUnderlineColorMode","Underline Color Source",sources,sourceOrder,"accent",nil,Off("activeUnderline")))
                Row(Color("activeUnderlineColor","Underline Color",false,{r=.05,g=.82,b=.61},nil,function()
                    return not Get("activeUnderline",true) or Get("activeUnderlineColorMode","accent")~="custom" end),spacer)
                Section("BORDER")
                local synced=function() return Get("syncTabBorder",true) end
                Row(Toggle("syncTabBorder","Sync Border with Chat Panel",true,"Tabs use the chat panel border style, size and color."),
                    Toggle("activeTabBorder","Active Tab Border",true,"A thin outline around the selected tab."))
                local borderValues,borderOrder=BorderTextures()
                Row(Dropdown("tabBorderTexture","Border Style",borderValues,borderOrder,"solid",nil,synced),
                    Dropdown("tabBorderThickness","Border Size",sizes,sizeOrder,"none",nil,synced))
                Row(Color("tabBorderColor","Border Color",false,{r=1,g=1,b=1},nil,synced),
                    Dropdown("tabBorderColorMode","Border Color Source",sources,sourceOrder,"custom",nil,synced))
                Row(Slider("tabBorderOpacity","Border Opacity",0,1,.05,.18,nil,synced),
                    Color("tabBorderColorActive","Active Border Color",true,{r=1,g=1,b=1,a=.18},nil,Off("activeTabBorder")))
            elseif page=="Sidebar" then
                StockNote()
                Section("SIDEBAR")
                Row(Dropdown("sidebarVisibility","Sidebar Visibility",{always="Always",mouseover="Mouseover",never="Never"},
                    {"always","mouseover","never"},"always"),Toggle("sidebarRight","Show on Right"))
                Row(Toggle("hideSidebarBg","Hide Sidebar Background"),Slider("sidebarWidth","Sidebar Width",30,100,1,40))
                Row(Toggle("sidebarSeparate","Separate Sidebar",false,"Detaches the sidebar from the chat panel with its own border."),
                    Slider("sidebarSeparateSpacing","Separate Spacing",0,30,1,8,nil,Off("sidebarSeparate")))
                Section("ICONS")
                Row({type="colorpicker",text="Sidebar Icons Color",hasAlpha=false,disabled=function() return Get("iconUseAccent",false) end,
                        getValue=function() return Get("iconR",1),Get("iconG",1),Get("iconB",1) end,
                        setValue=function(r,g,b) local p=DB(); if p then p.iconR,p.iconG,p.iconB=r,g,b; ns.Apply() end end},
                    Toggle("iconUseAccent","Use Accent Color"))
                local iconsRow=Row({type="dropdown",text="Sidebar Icons",tooltip="Check icons to show them; drag rows to reorder.",
                        values={__placeholder="..."},order={"__placeholder"},getValue=function() return "__placeholder" end,setValue=function() end},
                    Slider("sidebarIconScale","Sidebar Icon Size",.5,2,.05,1))
                local region=iconsRow and iconsRow._leftRegion
                if live and region and E.BuildReorderCBDropdown then
                    if region._control then region._control:Hide() end
                    local items={}
                    for _,key in ipairs(ns.ECHAT.ResolveSidebarIconOrder()) do items[#items+1]={key=key,label=iconLabels[key] or key} end
                    items[#items+1]={key="showScroll",label=iconLabels.showScroll,fixed=true}
                    local dd,refresh=E.BuildReorderCBDropdown(region,210,region:GetFrameLevel()+2,items,
                        function(k) return Get(k,false) and true or false end,function(k,v) Set(k,v) end,
                        {setOrder=function(keys)
                            local p=DB(); if not p then return end
                            p.sidebarIconOrder={}; for i,key in ipairs(keys) do p.sidebarIconOrder[key]=i end; ns.Apply()
                        end,hint="Drag to Reorder"})
                    if PP and PP.Point then PP.Point(dd,"RIGHT",region,"RIGHT",-20,0) else dd:SetPoint("RIGHT",region,"RIGHT",-20,0) end
                    region._control=dd; region._lastInline=nil
                    if E.RegisterWidgetRefresh and refresh then E.RegisterWidgetRefresh(refresh) end
                elseif not E.BuildReorderCBDropdown then
                    Row(Toggle("showFriends","Friends",true),Toggle("showGuild","Guild"))
                    Row(Toggle("showDurability","Durability"),Toggle("showCopy","Copy Chat",true))
                    Row(Toggle("showVoice","Voice/Channels"),Toggle("showSettings","Settings",true))
                    Row(Toggle("showScroll","Scroll to Bottom",true),spacer)
                end
                Row(Slider("sidebarIconSpacing","Icon Spacing",0,30,1,10),
                    Toggle("freeMoveIcons","Free Move Icons",false,"Drag sidebar icons anywhere on the sidebar. Reset Icon Positions returns them."))
                Row(Toggle("scrollButtonOnChat","Scroll Button on Chat Panel",false,"Moves the scroll-to-bottom button to the chat panel's lower right corner."),spacer)
                Button("Reset Icon Positions",function() local p=DB(); if p then p.iconPositions={}; ns.Apply() end end)
            elseif page=="Chat Bubbles" then
                local function BGet(key,fallback) local c=ns.GetBubbleSettings(); if not c or c[key]==nil then return fallback end; return c[key] end
                local function BSet(key,value) local c=ns.GetBubbleSettings(); if c then c[key]=value; ns.ApplyBubbles() end end
                local function BToggle(key,label,fallback,tooltip,disabled)
                    return {type="toggle",text=label,tooltip=tooltip,disabled=disabled,
                        getValue=function() return BGet(key,fallback or false) end,setValue=function(v) BSet(key,v) end}
                end
                local function BSlider(key,label,min,max,step,fallback,disabled)
                    return {type="slider",text=label,min=min,max=max,step=step,disabled=disabled,
                        getValue=function() return BGet(key,fallback) end,setValue=function(v) BSet(key,v) end}
                end
                local function BColor(key,label,hasAlpha,fallback,disabled)
                    return {type="colorpicker",text=label,hasAlpha=hasAlpha,disabled=disabled,
                        getValue=function() local c=BGet(key) or fallback; return c.r or 1,c.g or 1,c.b or 1,c.a==nil and 1 or c.a end,
                        setValue=function(r,g,b,a) local c={r=r,g=g,b=b}; if hasAlpha then c.a=a or 1 end; BSet(key,c) end}
                end
                local off=function() return not BGet("enabled",false) end
                Section("CHAT BUBBLES")
                Row(BToggle("enabled","Enable Chat Bubbles",false,"Restyles the game's chat bubbles and turns them on for the checked channels."),
                    BToggle("hideInInstances","Hide in Instances",false,"Turns chat bubbles off inside dungeons, raids, battlegrounds and arenas.",off))
                Section("CHANNELS")
                Row(BToggle("say","Say",true,nil,off),BToggle("yell","Yell",true,nil,off))
                Row(BToggle("party","Party",true,nil,off),BToggle("npc","NPC",true,nil,off))
                Row(BToggle("emote","Emote",true,nil,off),spacer)
                Section("APPEARANCE")
                Row(BSlider("padding","Padding",2,24,1,8,off),BSlider("maxWidth","Maximum Width",120,500,5,260,off))
                Row(BSlider("fontSize","Font Size",8,24,1,12,off),
                    BColor("textColor","Text Color",false,{r=1,g=1,b=1},function() return off() or BGet("followBlizzardColor",false) end))
                Row(BToggle("followBlizzardColor","Follow Blizzard Color",false,"Keeps the game's text color for each channel.",off),
                    BSlider("offsetY","Vertical Offset",-80,80,1,0,off))
                Row(BSlider("borderSize","Border",0,4,1,1,off),BColor("borderColor","Border Color",true,{r=0,g=0,b=0,a=1},off))
                Row(BToggle("background","Background",true,nil,off),BColor("bgColor","Background Color",false,{r=0,g=0,b=0},off))
                Row(BSlider("bgAlpha","Background Opacity",0,1,.05,.5,off),spacer)
            end
            return math.abs(y)
        end,
        onReset=function()
            if ns.addon.db and ns.addon.db.ResetProfile then ns.addon.db:ResetProfile() end
            ns.Apply(); E:InvalidatePageCache()
        end,
    })
end)
if IsLoggedIn() then init:GetScript("OnEvent")(init) end
