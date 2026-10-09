-- Native Wrath artwork treatment: original scripts, content and input stay native.
local ADDON_NAME,ns=...
local E=EllesmereUI
if not E or not E.Lite then return end
local addon=E.Lite.NewAddon(ADDON_NAME)
E._ModuleNS[ADDON_NAME]=ns
ns.addon,ns.IsWrath=addon,true
local flat="Interface\\Buttons\\WHITE8X8"
local states,owned={},{}
ns.states=states
ns.owned=owned
local dirty=true
local windows={
    {id="charsheet",key="themedCharacterSheet",label="Character",frames={"CharacterFrame"},classic=true},
    {id="inspect",key="themedInspectSheet",label="Inspect",frames={"InspectFrame"},classic=true},
    {id="playerspells",key="reskinPlayerSpells",label="Spellbook, Talents & Glyphs",frames={"SpellBookFrame","PlayerTalentFrame","TalentFrame","PetTalentFrame","GlyphFrame"}},
    {id="socialui",key="reskinSocialUI",label="Friends, Guild & Raid",frames={"FriendsFrame","RaidInfoFrame"},classic=true},
    {id="guild",key="reskinGuild",label="Guild Bank & Guild Services",frames={"GuildBankFrame","GuildRegistrarFrame","PetitionFrame","TabardFrame"}},
    {id="quest",key="reskinQuest",label="Quest Log & Quest Dialogs",frames={"QuestLogFrame","QuestFrame"}},
    {id="gossip",key="reskinGossip",label="NPC Dialogs",frames={"GossipFrame"},classic=true},
    {id="merchant",key="reskinMerchant",label="Merchant",frames={"MerchantFrame"},classic=true},
    {id="mail",key="reskinMail",label="Mail",frames={"MailFrame","OpenMailFrame"},classic=true},
    {id="auctionhouse",key="reskinAuctionHouse",label="Auction House",frames={"AuctionFrame"},nativeOnly=true},
    {id="trade",key="reskinTrade",label="Trade",frames={"TradeFrame"},classic=true},
    {id="professions",key="reskinProfessions",label="Professions",frames={"TradeSkillFrame","CraftFrame"},classic=true},
    {id="trainer",key="reskinTrainer",label="Trainer, Stable & Taxi",frames={"ClassTrainerFrame","PetStableFrame","TaxiFrame"},classic=true},
    {id="socket",key="reskinSocket",label="Item Socketing",frames={"ItemSocketingFrame"}},
    {id="dressup",key="reskinDressUp",label="Dressing Room",frames={"DressUpFrame"},classic=true},
    {id="macros",key="reskinMacros",label="Macros",frames={"MacroFrame"}},
    {id="settings",key="reskinSettings",label="Options & Key Bindings",frames={"InterfaceOptionsFrame","VideoOptionsFrame","AudioOptionsFrame","KeyBindingFrame"}},
    -- optional: the toggle is hidden when the frame does not exist (stock 3.3.5 has no AddonList).
    {id="addonlist",key="reskinAddonList",label="AddOn List",frames={"AddonList"},optional=true},
    {id="achievements",key="reskinAchievements",label="Achievements",frames={"AchievementFrame"}},
    {id="calendar",key="reskinCalendar",label="Calendar",frames={"CalendarFrame"}},
    {id="lfg",key="reskinLFGMenu",label="Dungeon & Raid Finder",frames={"LFDParentFrame","LFRParentFrame","LFGParentFrame"}},
    {id="worldmap",key="reskinWorldMap",label="World Map",frames={"WorldMapFrame"}},
    {id="loot",key="reskinLoot",label="Loot",frames={"LootFrame"}},
    {id="lootroll",key="reskinLootRoll",label="Loot Rolls",frames={"GroupLootFrame1","GroupLootFrame2","GroupLootFrame3","GroupLootFrame4"}},
    {id="readycheck",key="reskinReadyCheck",label="Ready Check",frames={"ReadyCheckFrame"}},
    -- Frostmourne Rebuffed ships these as part of its own FrameXML.
    {id="collections",key="reskinCollections",label="Collections",frames={"CollectionsJournal"}},
    {id="transmog",key="reskinTransmog",label="Wardrobe & Transmog",frames={"WardrobeFrame"}},
    {id="barber",key="reskinBarber",label="Barber Shop",frames={"BarberShopFrame"}},
    {id="pvp",key="reskinPvP",label="PvP, Battlemasters & Arena Registrar",frames={"PVPParentFrame","BattlefieldFrame","ArenaFrame","ArenaRegistrarFrame","PVPBannerFrame"},classic=true},
    {id="battleground",key="reskinBattleground",label="Battleground Score & Minimap",frames={"WorldStateScoreFrame","BattlefieldMinimap","BattlefieldMinimapTab"}},
    {id="help",key="reskinHelp",label="Help & GM Requests",frames={"RebuffedHelpFrame","HelpFrame","GMSurveyFrame","TicketStatusFrame"}},
    {id="timers",key="reskinTimers",label="Breath/Fatigue Timers & Stopwatch",frames={"MirrorTimer1","MirrorTimer2","MirrorTimer3","StopwatchFrame","TimeManagerFrame"}},
    {id="debugtools",key="reskinDebugTools",label="Debug Tools",frames={"ScriptErrorsFrame","EventTraceFrame"}},
    -- Painted by EUI_SkinExtras_335.lua; listed here for the toggle and profile kill switch.
    {id="raidpullout",key="reskinRaidPullouts",label="Raid Pullouts",frames={}},
    {id="capturebar",key="reskinCaptureBar",label="Battleground Capture Bar",frames={}},
    {id="gmstatus",key="reskinGMStatus",label="GM Chat Status",frames={}},
    {id="ace3",key="reskinAce3",label="Ace3 Config Windows",frames={}},
}
ns.extras={}
ns.windows=windows
local defaults={customTooltips=true,reskinPopupsMenus=true,reskinGameMenu=true,reskinQueuePopup=true,
    tooltipFontScale=1,tooltipBgOpacity=.95,tooltipBorderSize=1,
    enhancedCharacterSheet=true,characterItemLevels=true,characterMissingEnhancements=true,
    worldMapReveal=false,worldMapRevealTint=true,worldMapZoneLevels=true,
    worldMapInstances=true,worldMapFlightPoints=true,worldMapCoords=true}
for _,spec in ipairs(windows) do defaults[spec.key]=true end
ns.defaults=defaults
function ns.GetSettings() EllesmereUIDB=EllesmereUIDB or {}; return EllesmereUIDB end
function ns.GetValue(key) local v=ns.GetSettings()[key]; if v==nil then return defaults[key] end; return v end
local function Killed()
    local p=E.GetActiveProfileData and E.GetActiveProfileData()
    return p and p.disableWindowSkins or false
end
E.BlizzWindowSkinsKilled=Killed
function ns.WindowSkinEnabled(key) return ns.GetValue(key)~=false and not Killed() end
function E.GetBlizzWindowStyle(id)
    for _,spec in ipairs(windows) do if spec.id==id then return not Killed() and ns.GetValue(spec.key)~=false and "eui" or "off" end end
    return "off"
end
function E.SetBlizzWindowStyle(id,style)
    if style~="eui" and style~="off" then return end
    for _,spec in ipairs(windows) do if spec.id==id then ns.GetSettings()[spec.key]=style~="off"; ns.Apply(); return end end
end
function E.DisableAllBlizzWindowSkins()
    for _,spec in ipairs(windows) do ns.GetSettings()[spec.key]=false end; ns.Apply()
end
local function Kind(f,kind) return f and f.GetObjectType and f:GetObjectType()==kind end
local function Accent()
    local c=ns.GetSettings().blizzWinAccentBar
    if type(c)=="table" and c.useCustom and c.color then return c.color.r or 1,c.color.g or 1,c.color.b or 1 end
    local eg=E.ELLESMERE_GREEN or {}; return eg.r or .047,eg.g or .824,eg.b or .616
end
local function FontFlags()
    local f=E.GetFontOutlineFlag and E.GetFontOutlineFlag("blizzardSkin") or ""
    return f:gsub(",?%s*SLUG","")
end
local function NewPanel(parent)
    local f=CreateFrame("Frame",nil,parent); owned[f]=true; f:EnableMouse(false)
    f:SetFrameLevel(math.max(0,parent:GetFrameLevel()-1)); f:SetAllPoints(parent)
    -- Native controls can raise child frame levels after skinning. A filled
    -- child backdrop then covers the owner's icon/text. Paint the fill on the
    -- owner's BACKGROUND layer; the child frame draws only the thin border.
    local bg=parent:CreateTexture(nil,"BACKGROUND"); owned[bg]=true; bg:SetDrawLayer("BACKGROUND"); bg:SetTexture(flat); bg:SetAllPoints(f)
    f.background=bg; f:SetBackdrop({edgeFile=flat,edgeSize=1})
    f.SetBackdropColor=function(_,r,g,b,a) bg:SetVertexColor(r,g,b,a or 1) end
    f:HookScript("OnShow",function() bg:Show() end); f:HookScript("OnHide",function() bg:Hide() end)
    f:Hide(); bg:Hide(); return f
end
local function Fade(s,region)
    if not region or not region.GetAlpha then return end
    if s.regions[region]==nil then s.regions[region]=region:GetAlpha() end
    -- Alpha alone loses to native OnShow/animation updates. Keep the region and
    -- its native state, but remove its artwork until the skin is disabled.
    if Kind(region,"Texture") then
        if not s.cleared[region] then s.cleared[region]={path=region:GetTexture()} end
        region:SetTexture(nil)
    end
    region:SetAlpha(0)
end
local function Font(s,fs,scale)
    if not fs or not fs.GetFont or not fs.SetFont then return end
    local saved=s.fonts[fs]
    if not saved then
        local path,size,flags=fs:GetFont(); if not path or not size then return end
        saved={path,size,flags,color=fs.GetTextColor and {fs:GetTextColor()}}; s.fonts[fs]=saved
    end
    -- Re-setting an EditBox's font on every refresh hides its blinking cursor.
    local path,size,flags=E.GetFontPath("blizzardSkin"),saved[2]*(scale or 1),FontFlags()
    local curPath,curSize,curFlags=fs:GetFont()
    if curPath~=path or math.abs((curSize or 0)-size)>.01 or (curFlags or "")~=flags then fs:SetFont(path,size,flags) end
    if (s.spec.id=="quest" or s.spec.id=="gossip") and fs.GetText then
        local text=fs:GetText()
        if type(text)=="string" then
            local paint=text:gsub("|c(%x%x)(%x%x)(%x%x)(%x%x)",function(alpha,r,g,b)
                local red,green,blue=tonumber(r,16)/255,tonumber(g,16)/255,tonumber(b,16)/255
                if .2126*red+.7152*green+.0722*blue>=.55 then return "|c"..alpha..r..g..b end
                return string.format("|cff%02x%02x%02x",math.floor(191+64*red),math.floor(191+64*green),math.floor(191+64*blue))
            end)
            if paint~=text then
                s.questTexts=s.questTexts or {}; s.questTexts[fs]={native=text,paint=paint}; fs:SetText(paint)
            end
        end
    end
    local c=fs.GetTextColor and {fs:GetTextColor()}
    if c and c[1] and c[2] and c[3] then
        local quest=s.spec.id=="quest" or s.spec.id=="gossip"
        if quest and .2126*c[1]+.7152*c[2]+.0722*c[3]<.55 then
            -- Native parchment text includes dark gold/brown as well as black.
            -- Preserve its hue while giving it contrast on the dark skin.
            fs:SetTextColor(.75+.25*c[1],.75+.25*c[2],.75+.25*c[3],1)
        elseif c[1]<.25 and c[2]<.25 and c[3]<.25 then fs:SetTextColor(.9,.9,.9,c[4] or 1) end
    end
end
local chromeFamilies={"ui-character-general","ui-character-charactertab","ui-character-statbackground",
    "ui-petpaperdollframe-bot","skillframe-bot","ui-talentframe-bot","ui-classtrainer-horizontalbar",
    "ui-classtrainer-scrollbar","ui-character-scrollbar","ui-common-inputbox","ui-dropdownmenu",
    "ui-spellbook-top","ui-spellbook-bottom","ui-spellbook-middle","ui-spellbook-page",
    "ui-dialogbox","ui-innerborder","ui-panel-tab","ui-character-tab","ui-auctionframe-browse",
    "ui-guildbankframe","ui-mailframe","ui-tradeskill","ui-questlog-book","questbg",
    "ui-merchant-itembg","ui-mail-itembg","ui-questitemnameframe","common-input-border",
    "charactercreate-labelframe"}
-- Only chrome on these known native containers is swept wholesale. Tree art,
-- maps, status bars, trade acceptance overlays and content icons stay native.
local chromeFrames={}
for _,name in ipairs({"PaperDollFrame","PetPaperDollFrame","CharacterAttributesFrame","PetAttributesFrame",
    "CharacterModelFrame","InspectModelFrame","PlayerTitleFrame","PlayerTitlePickerFrame",
    "ReputationFrame","SkillFrame","TokenFrame","ReputationDetailFrame","TokenFramePopup",
    "QuestLogCount","QuestLogDetailFrame","QuestLogDetailScrollFrame","EmptyQuestLogFrame",
    "QuestFrameDetailPanel","QuestFrameProgressPanel","QuestFrameRewardPanel","QuestFrameGreetingPanel",
    "QuestDetailScrollFrame","QuestDetailScrollChildFrame","QuestRewardScrollFrame","QuestRewardScrollChildFrame",
    "QuestProgressScrollFrame","GossipFrameGreetingPanel","ItemTextScrollFrame","SendMailFrame",
    "SendMailScrollFrame","OpenMailScrollFrame","PlayerTalentFrameStatusFrame","PlayerTalentFramePointsBar",
    "PlayerTalentFramePreviewBar","PlayerTalentFramePreviewBarFiller","MacroFrameTextBackground",
    "MacroButtonScrollFrame","BrowseFilterScrollFrame","BrowseScrollFrame","BidScrollFrame","AuctionsScrollFrame",
    "AuctionDressUpFrame","WhoListScrollFrame","GuildListScrollFrame","GuildFrameLFGFrame",
    "ChannelListScrollFrame","ChannelRosterScrollFrame","TradeSkillListScrollFrame",
    "TradeSkillDetailScrollFrame","TradeSkillDetailScrollChildFrame","TradeSkillExpandButtonFrame",
    "InterfaceOptionsFrameCategoriesList","InterfaceOptionsFrameAddOnsList",
    "AchievementFrameSummary","AchievementFrameSummaryCategoriesHeader","AchievementFrameSummaryAchievementsHeader",
    "AchievementFrameStatsBG","AchievementFrameAchievements","AchievementFrameComparison",
    "AchievementFrameComparisonHeader","AchievementFrameComparisonSummaryPlayer","AchievementFrameComparisonSummaryFriend",
    "PVPFrame","PVPBattlegroundFrame","ArenaRegistrarGreetingFrame","ArenaRegistrarPurchaseFrame","StopwatchTabFrame"}) do chromeFrames[name]=true end
local function Content(region,path)
    local name=region.GetName and region:GetName() or ""
    return path:find("interface\\icons\\",1,true) or path:find("interface\\worldmap\\",1,true) and not path:find("ui-worldmap",1,true)
        or path:find("interface\\talentframe\\",1,true) and not path:find("ui-talentframe",1,true)
        -- Native TaxiFrame continent art is Interface\TaxiFrame\TAXIMAP<n>, not WorldMap tiles.
        or path:find("interface\\taxiframe\\taximap",1,true) or name=="TaxiMap"
        or name and (name:find("Portrait",1,true) or name:find("TradeHighlight",1,true)
            or name:find("Icon",1,true) or name:find("Arrow",1,true)
            -- Honor/arena currency symbols and arena team banner emblems.
            or name:find("Symbol",1,true) or name:find("Emblem",1,true))
end
local function Decor(region,root)
    if not Kind(region,"Texture") then return false end
    local path=region:GetTexture(); if type(path)~="string" then return false end
    path=path:lower()
    if Content(region,path) then return false end
    if root then return true end
    for _,family in ipairs(chromeFamilies) do if path:find(family,1,true) then return true end end
    if not path:find("ui-",1,true) then return false end
    for _,part in ipairs({"topleft","topright","bottomleft","bottomright","border","parchment","background"}) do
        if path:find(part,1,true) then return true end
    end
    return false
end
local function TextureStyle(s,texture,r,g,b,a)
    if not texture then return end
    if not s.textureStyles[texture] then
        s.textureStyles[texture]={path=texture:GetTexture(),coords={texture:GetTexCoord()},
            color=texture.GetVertexColor and {texture:GetVertexColor()},alpha=texture:GetAlpha()}
    end
    texture:SetTexture(flat); texture:SetTexCoord(0,1,0,1); texture:SetVertexColor(r,g,b,a or 1)
    s.textureStyles[texture].paint={r,g,b,a or 1}
end
local function SaveGeometry(s,obj)
    s.geometry=s.geometry or {}
    if s.geometry[obj] then return end
    local d={points={},width=obj:GetWidth(),height=obj:GetHeight(),parent=obj:GetParent()}; s.geometry[obj]=d
    for i=1,obj:GetNumPoints() do d.points[i]={obj:GetPoint(i)} end
end
local function InsetTexture(s,texture,owner,pad,r,g,b,a)
    if not texture then return end
    TextureStyle(s,texture,r,g,b,a); SaveGeometry(s,texture)
    texture:ClearAllPoints(); texture:SetPoint("TOPLEFT",owner,"TOPLEFT",pad,-pad); texture:SetPoint("BOTTOMRIGHT",owner,"BOTTOMRIGHT",-pad,pad)
end
-- Stock check buttons are mostly transparent margin around a smaller box.
-- Draw the box at the native art's size and fill it when checked.
local function CheckBox(s,button,d,r,g,b)
    local inset=math.floor(math.min(button:GetWidth(),button:GetHeight())*.18+.5)
    d.panel:ClearAllPoints(); d.panel:SetPoint("TOPLEFT",button,"TOPLEFT",inset,-inset); d.panel:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-inset,inset)
    if button.GetHighlightTexture then InsetTexture(s,button:GetHighlightTexture(),button,inset,1,1,1,.1) end
    if button.GetCheckedTexture then InsetTexture(s,button:GetCheckedTexture(),button,inset+3,r,g,b,1) end
    if button.GetDisabledCheckedTexture then InsetTexture(s,button:GetDisabledCheckedTexture(),button,inset+3,.5,.5,.5,1) end
end
local sheetFrames={PaperDollFrame=true,PetPaperDollFrame=true,ReputationFrame=true,SkillFrame=true,TokenFrame=true,
    QuestFrameDetailPanel=true,QuestFrameProgressPanel=true,QuestFrameRewardPanel=true,QuestFrameGreetingPanel=true,
    GossipFrameGreetingPanel=true,SendMailFrame=true,PVPFrame=true,PVPBattlegroundFrame=true,
    ArenaRegistrarGreetingFrame=true,ArenaRegistrarPurchaseFrame=true}
-- Unnamed border frames on the achievement pages sit above the list rows; a
-- fill there covers the rows, so they keep only the border.
local overlayParents={AchievementFrameAchievements=true,AchievementFrameSummary=true,
    AchievementFrameStats=true,AchievementFrameComparison=true}
local function InnerPanel(s,frame)
    if not frame.GetBackdrop then return end
    local d=s.insets[frame]
    if not d then
        d={panel=NewPanel(frame),backdrop=frame:GetBackdrop(),bg={frame:GetBackdropColor()},border={frame:GetBackdropBorderColor()}}
        s.insets[frame]=d
        -- These sheets include the old texture's transparent overhang. Anchor
        -- only our background inside the new outer panel, leaving native
        -- content geometry and the accent header untouched.
        if s.panel and sheetFrames[frame:GetName()] then
            d.panel:ClearAllPoints(); d.panel:SetPoint("TOPLEFT",s.panel,"TOPLEFT",3,-4)
            d.panel:SetPoint("BOTTOMRIGHT",s.panel,"BOTTOMRIGHT",-3,3)
        end
        -- UIDropDownMenuTemplate frames include the label art's transparent
        -- margins, so a full-frame panel overhangs the window. Frame only the
        -- visible box, which ends at the arrow button.
        local name=frame:GetName()
        local arrow=name and name:find("DropDown$") and _G[name.."Button"]
        if arrow and arrow.GetParent and arrow:GetParent()==frame then
            d.panel:ClearAllPoints(); d.panel:SetPoint("TOPLEFT",frame,"TOPLEFT",17,-1)
            d.panel:SetPoint("BOTTOMRIGHT",arrow,"BOTTOMRIGHT",0,0)
        end
        frame:HookScript("OnShow",function() dirty=true end)
        frame:HookScript("OnHide",function() dirty=true end)
    end
    if frame:GetBackdrop() then frame:SetBackdrop(nil) end
    -- The border frame carries no fill. One level below its owner it can tie with
    -- the sheet whose BACKGROUND fill covers it (Send Mail's To/Subject boxes).
    if not (s.panel and sheetFrames[frame:GetName()]) then d.panel:SetFrameLevel(frame:GetFrameLevel()) end
    local parent=frame:GetParent()
    if not frame:GetName() and parent and overlayParents[parent:GetName() or ""] then
        d.panel:SetBackdropColor(0,0,0,0); d.panel:SetBackdropBorderColor(.18,.18,.18,1)
    elseif Kind(frame,"EditBox") then
        d.panel:SetBackdropColor(.06,.06,.06,.95); d.panel:SetBackdropBorderColor(.25,.25,.25,1)
    else
        d.panel:SetBackdropColor(.035,.035,.035,.9); d.panel:SetBackdropBorderColor(.18,.18,.18,1)
    end
    d.panel:Show()
end
local function Icon(s,button,icon)
    if not icon or not icon.GetTexCoord then return end
    local d=s.icons[icon]
    if not d then
        local border=CreateFrame("Frame",nil,button); owned[border]=true; border:EnableMouse(false)
        border:SetAllPoints(icon); border:SetFrameLevel(button:GetFrameLevel()+2)
        border:SetBackdrop({edgeFile=flat,edgeSize=1})
        local layer,sublevel=icon:GetDrawLayer()
        d={border=border,coords={icon:GetTexCoord()},layer=layer,sublevel=sublevel}; s.icons[icon]=d
    end
    icon:SetDrawLayer("ARTWORK"); icon:SetTexCoord(.08,.92,.08,.92); d.border:SetBackdropBorderColor(.25,.25,.25,1)
    -- Dropdown rows keep a hidden 16px Icon texture; frame it only while shown.
    if icon:IsShown() then d.border:Show() else d.border:Hide() end
    -- Mail attachment counts start in BORDER/ARTWORK. Raising their icon must
    -- keep the native quantity above it; native mail code still owns the text.
    local name=button.GetName and button:GetName()
    local count=name and _G[name.."Count"]
    if Kind(count,"FontString") then
        s.countLayers=s.countLayers or {}
        if not s.countLayers[count] then local layer,sublevel=count:GetDrawLayer(); s.countLayers[count]={layer=layer,sublevel=sublevel} end
        Font(s,count); count:SetDrawLayer("OVERLAY"); count:SetTextColor(1,1,1,1)
    end
end
local function Button(s,button)
    local name=button.GetName and button:GetName() or ""
    local label=button.GetFontString and button:GetFontString()
    -- Auction House footers name their "Close" text buttons BrowseCloseButton etc.
    local close=name and name:find("CloseButton$",1)~=nil and not (label and label:GetText())
    local normal=button.GetNormalTexture and button:GetNormalTexture()
    local path=normal and normal:GetTexture()
    local nativeTextButton=label and label:GetText() and type(path)=="string" and
        (path:lower():find("ui-panel-button",1,true) or path:lower():find("ui-dialogbox-button",1,true))
    local tab=name and (name:find("FrameTab%d+$") or name:find("FrameTabButton%d+$") or name:find("TabHeaderTab%d+$"))
    local arrow=name and (name:find("ScrollUpButton$") and "^" or name:find("ScrollDownButton$") and "v"
        or name:find("PrevPageButton$") and "<" or name:find("NextPageButton$") and ">"
        or name:find("DropDown.*Button$") and "v")
    local check=Kind(button,"CheckButton") and type(path)=="string" and path:lower():find("ui-checkbox",1,true)
    local icon=button.icon or button.Icon or button.iconTexture or button.IconTexture or name and (_G[name.."IconTexture"] or _G[name.."Icon"])
    if not icon and normal and type(path)=="string" and path:lower():find("interface\\icons\\",1,true) then icon=normal end
    if icon and Kind(icon,"Texture") then Icon(s,button,icon) else icon=nil end
    local d=s.buttons[button]
    if not d and not close and not nativeTextButton and not tab and not arrow and not check and not icon then return end
    if not d then
    d={panel=NewPanel(button),tab=tab,check=check,icon=icon}; s.buttons[button]=d
    d.panel:SetBackdropColor(.08,.08,.08,.95); d.panel:SetBackdropBorderColor(.25,.25,.25,1)
    for _,getter in ipairs({"GetNormalTexture","GetPushedTexture","GetDisabledTexture"}) do
        if button[getter] then local texture=button[getter](button); if texture~=icon then Fade(s,texture) end end
    end
    if tab then
        for _,region in ipairs({button:GetRegions()}) do if Kind(region,"Texture") and region~=icon and not owned[region] then Fade(s,region) end end
    elseif button.GetHighlightTexture then
        local highlight=button:GetHighlightTexture()
        if highlight then TextureStyle(s,highlight,1,1,1,.1) end
    end
    if close or arrow then
        d.label=button:CreateFontString(nil,"OVERLAY"); owned[d.label]=true
        d.label:SetFont(E.GetFontPath("blizzardSkin"),14,FontFlags()); d.label:SetText(close and "x" or arrow); d.label:SetPoint("CENTER",button,"CENTER",0,0)
        d.label:SetTextColor(1,1,1); d.label:Show()
    end
    button:HookScript("OnEnter",function() d.hover=true; if s.active and not InCombatLockdown() then local r,g,b=Accent(); d.panel:SetBackdropBorderColor(r,g,b,1) end end)
    button:HookScript("OnLeave",function() d.hover=false; dirty=true end)
    button:HookScript("OnClick",function() dirty=true end)
    button:HookScript("OnShow",function() dirty=true end)
    end
    if tab and not name:find("^CharacterFrameTab%d+$") and not name:find("^PlayerTalentFrameTab%d+$") then
        -- Stock panel tabs overlap their transparent artwork margins. Keep
        -- native placement/hit handling, and inset the visible rectangle.
        d.panel:ClearAllPoints(); d.panel:SetPoint("TOPLEFT",button,"TOPLEFT",10,-3); d.panel:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-10,3)
    end
    local r,g,b=Accent()
    local parent=button:GetParent()
    local selected=tab and parent and parent.selectedTab and button.GetID and parent.selectedTab==button:GetID()
    -- Character tabs also select by disabling the active native tab.
    if tab and not selected and button.IsEnabled then selected=not button:IsEnabled() end
    d.panel:SetBackdropColor(selected and .07 or .045,selected and .15 or .045,selected and .12 or .045,.97)
    d.panel:SetBackdropBorderColor((selected or d.hover) and r or .25,(selected or d.hover) and g or .25,(selected or d.hover) and b or .25,1)
    if d.check and not icon then
        CheckBox(s,button,d,r,g,b)
    elseif Kind(button,"CheckButton") and icon then
        if button.GetCheckedTexture then TextureStyle(s,button:GetCheckedTexture(),r,g,b,.3) end
        if button.GetDisabledCheckedTexture then TextureStyle(s,button:GetDisabledCheckedTexture(),.5,.5,.5,.3) end
    end
end
-- AddOn frames inside a nativeOnly window (Auctionator tabs and panels on
-- AuctionFrame) are anonymous or named from insecure code.
local function Foreign(obj)
    local name=obj.GetName and obj:GetName()
    if not name or name=="" or _G[name]~=obj then return true end
    return issecurevariable and not issecurevariable(name) or false
end
-- Inside foreign frames only fonts and stock text buttons are restyled; their
-- textures, backdrops and layout stay as the AddOn drew them.
local function WalkForeign(s,frame,depth)
    if owned[frame] or depth>6 then return end
    if Kind(frame,"Button") then
        local label=frame:GetFontString(); local normal=frame:GetNormalTexture()
        local path=normal and normal:GetTexture()
        if label and label:GetText() and type(path)=="string" and path:lower():find("ui-panel-button",1,true) then Button(s,frame) end
    end
    if frame.GetRegions then
        for _,region in ipairs({frame:GetRegions()}) do
            if not owned[region] and Kind(region,"FontString") then Font(s,region) end
        end
    end
    if frame.GetChildren then for _,child in ipairs({frame:GetChildren()}) do WalkForeign(s,child,depth+1) end end
end
local function Walk(s,frame,depth,root)
    if owned[frame] or depth>6 then return end
    if s.spec.nativeOnly and not root and Foreign(frame) then WalkForeign(s,frame,depth); return end
    local name=frame.GetName and frame:GetName() or ""
    local chrome=chromeFrames[name] or Kind(frame,"EditBox") or name and name:find("DropDown$")
    -- A text body scrolled inside a boxed scroll frame (Send Mail) is one line
    -- tall when empty; the scroll frame's box already frames it.
    local scroller=Kind(frame,"EditBox") and frame:GetParent()
    local scrolled=scroller and Kind(scroller,"ScrollFrame") and chromeFrames[scroller:GetName() or ""]
    if s.spec.tooltip or scrolled then
        -- Tooltips and scrolled text bodies get no inner box.
    elseif Kind(frame,"EditBox") or chrome or name and (name:find("DropDown$") or name:find("ScrollBar$")) then
        InnerPanel(s,frame)
    elseif frame~=s.frame and frame.GetBackdrop then
        local backdrop=frame:GetBackdrop()
        if backdrop and (backdrop.bgFile or backdrop.edgeFile) then InnerPanel(s,frame) end
    end
    local thumb=not s.spec.tooltip and Kind(frame,"Slider") and frame.GetThumbTexture and frame:GetThumbTexture()
    if thumb then
        local r,g,b=Accent(); TextureStyle(s,thumb,r,g,b,1)
        -- Native knobs are 32x32 art with transparent margins; flat paint
        -- would fill the whole square, so the painted knob is resized.
        local saved=s.textureStyles[thumb]
        if not saved.size then saved.size={thumb:GetWidth(),thumb:GetHeight()} end
        local vertical=frame.GetOrientation and frame:GetOrientation()=="VERTICAL"
        thumb:SetWidth(8); thumb:SetHeight(vertical and 20 or 16)
    end
    if not s.spec.tooltip and (Kind(frame,"Button") or Kind(frame,"CheckButton")) then Button(s,frame) end
    if frame.GetRegions then
        for _,region in ipairs({frame:GetRegions()}) do
            -- AddOn art parented to a nativeOnly root is anonymous; Blizzard's root art is named.
            local foreignArt=root and s.spec.nativeOnly and Kind(region,"Texture") and Foreign(region)
            if not owned[region] and not (s.keep and s.keep[region]) and not foreignArt then
                if Kind(region,"FontString") then Font(s,region,s.spec.tooltip and ns.GetValue("tooltipFontScale") or 1)
                elseif not s.spec.tooltip and not s.textureStyles[region] and
                    (Decor(region,root) or chrome and Kind(region,"Texture") and region:GetTexture()~=nil
                        and not Content(region,type(region:GetTexture())=="string" and region:GetTexture():lower() or "")) then Fade(s,region) end
            end
        end
    end
    if Kind(frame,"EditBox") then Font(s,frame) end
    if frame.GetChildren then for _,child in ipairs({frame:GetChildren()}) do Walk(s,child,depth+1,false) end end
end
local slots={{"Head",1},{"Neck",2},{"Shoulder",3},{"Shirt",4},{"Chest",5},{"Waist",6},{"Legs",7},{"Feet",8},
    {"Wrist",9},{"Hands",10},{"Finger0",11},{"Finger1",12},{"Trinket0",13},{"Trinket1",14},{"Back",15},
    {"MainHand",16},{"SecondaryHand",17},{"Ranged",18},{"Tabard",19}}
local function Equipment(s,prefix,unit)
    for _,entry in ipairs(slots) do
        local name=prefix..entry[1].."Slot"; local button=_G[name]; local icon=_G[name.."IconTexture"]
        if button and icon and icon.GetTexCoord then
            Icon(s,button,icon); local d=s.icons[icon]
            local quality=unit and GetInventoryItemQuality and GetInventoryItemQuality(unit,entry[2])
            if quality and GetItemQualityColor then local r,g,b=GetItemQualityColor(quality); d.border:SetBackdropBorderColor(r,g,b,1)
            else d.border:SetBackdropBorderColor(.25,.25,.25,1) end
            d.border:Show()
        end
    end
end
local function RestoreMapLayers(s)
    for region,saved in pairs(s.mapLayers or {}) do
        if saved.sublevel then region:SetDrawLayer(saved.layer,saved.sublevel) else region:SetDrawLayer(saved.layer) end
    end
end
local function TaxiMapContent(s)
    if s.frame~=_G.TaxiFrame then return end
    local map=_G.TaxiMap
    if not Kind(map,"Texture") then return end
    -- Root Walk would treat this as chrome, and the panel fill is a later
    -- BACKGROUND texture on the same frame. Keep the continent map native
    -- and above that fill so flight nodes stay on the current continent.
    s.regions[map]=nil
    if s.cleared[map] then
        map:SetTexture(s.cleared[map].path)
        s.cleared[map]=nil
    end
    map:SetAlpha(1)
    s.mapLayers=s.mapLayers or {}
    if not s.mapLayers[map] then
        local layer,sublevel=map:GetDrawLayer()
        s.mapLayers[map]={layer=layer,sublevel=sublevel}
    end
    map:SetDrawLayer("ARTWORK")
end
local function BattlefieldMinimapContent(s)
    if s.frame~=_G.BattlefieldMinimap then return end
    -- Tiles share BACKGROUND with the panel fill; BORDER keeps them above it
    -- and below the ARTWORK fog/POI overlays.
    s.mapLayers=s.mapLayers or {}
    for i=1,(NUM_WORLDMAP_DETAIL_TILES or 12) do
        local tile=_G["BattlefieldMinimap"..i]
        if Kind(tile,"Texture") then
            if not s.mapLayers[tile] then local layer,sublevel=tile:GetDrawLayer(); s.mapLayers[tile]={layer=layer,sublevel=sublevel} end
            tile:SetDrawLayer("BORDER")
        end
    end
    local options=_G.BattlefieldMinimapOptions
    local opacity=math.max(0,math.min(1,options and tonumber(options.opacity) or 0))
    s.panel:SetBackdropColor(.08,.08,.08,.95*(1-opacity))
end
local function MirrorTimerContent(s)
    local name=s.frame:GetName() or ""
    if not name:find("^MirrorTimer%d$") then return end
    local bar=_G[name.."StatusBar"]
    if not bar or not bar.GetStatusBarTexture then return end
    -- The native bar sits at its parent's frame level, so a fill on the
    -- parent could cover it. Fill the bar's own BACKGROUND instead.
    s.panel.background:SetAlpha(0)
    if not s.barBg then
        s.barBg=bar:CreateTexture(nil,"BACKGROUND"); owned[s.barBg]=true; s.barBg:SetTexture(flat); s.barBg:SetAllPoints(bar)
        s.barBg:SetVertexColor(.04,.04,.04,.9)
    end
    s.barBg:Show()
    s.statusBars=s.statusBars or {}
    if not s.statusBars[bar] then local texture=bar:GetStatusBarTexture(); s.statusBars[bar]=texture and texture:GetTexture() or "Interface\\TargetingFrame\\UI-StatusBar" end
    bar:SetStatusBarTexture(flat)
    s.panel:ClearAllPoints(); s.panel:SetPoint("TOPLEFT",bar,"TOPLEFT",-2,2); s.panel:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",2,-2)
end
-- WorldMapFrame keeps one large rectangle across windowed, full and quest
-- views. Fit the fill to the visible map, controls and quest panes instead.
local mapBounds={"WorldMapDetailFrame","WorldMapFrameTitle","WorldMapFrameCloseButton","WorldMapFrameSizeUpButton",
    "WorldMapFrameSizeDownButton","WorldMapZoneMinimapDropDown","WorldMapContinentDropDown","WorldMapZoneDropDown",
    "WorldMapZoomOutButton","WorldMapLevelDropDown","WorldMapQuestScrollFrame","WorldMapQuestScrollFrameScrollBar",
    "WorldMapQuestDetailScrollFrame","WorldMapQuestDetailScrollFrameScrollBar","WorldMapQuestRewardScrollFrame",
    "WorldMapQuestRewardScrollFrameScrollBar","WorldMapTrackQuest","WorldMapTrackQuestText",
    "WorldMapQuestShowObjectives","WorldMapQuestShowObjectivesText"}
local function WorldMapContent(s)
    local frame=s.frame
    if frame~=_G.WorldMapFrame or not frame.GetLeft then return end
    local scale,frameLeft,frameBottom=frame:GetEffectiveScale(),frame:GetLeft(),frame:GetBottom()
    if not scale or scale<=0 or not frameLeft or not frameBottom then return end
    local left,bottom,right,top
    for _,name in ipairs(mapBounds) do
        local obj=_G[name]
        if obj and obj.IsVisible and obj:IsVisible() then
            local l,b,r,t=obj:GetLeft(),obj:GetBottom(),obj:GetRight(),obj:GetTop()
            local owner=obj.GetEffectiveScale and obj or obj:GetParent()
            if l and b and r and t and owner then
                local k=owner:GetEffectiveScale()/scale
                l,b,r,t=l*k,b*k,r*k,t*k
                left=left and math.min(left,l) or l; bottom=bottom and math.min(bottom,b) or b
                right=right and math.max(right,r) or r; top=top and math.max(top,t) or t
            end
        end
    end
    if not left then return end
    s.panel:ClearAllPoints()
    s.panel:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",left-frameLeft-6,bottom-frameBottom-6)
    s.panel:SetPoint("TOPRIGHT",frame,"BOTTOMLEFT",right-frameLeft+6,top-frameBottom+6)
end
-- UI-GlyphFrame is a whole 1:1 window sheet (title bar, border, portrait
-- hole) drawn from GlyphFrame's TOPLEFT. Its parchment body spans x 22-342,
-- y 38-432; the top stops at 58 where the portrait hole ends.
local glyphBody={left=22,top=58,right=342,bottom=432}
local function KeepNative(s,region)
    if not region then return end
    s.keep=s.keep or {}; s.keep[region]=true
    if s.regions[region]~=nil then region:SetAlpha(s.regions[region]); s.regions[region]=nil end
    if s.cleared[region] then region:SetTexture(s.cleared[region].path); s.cleared[region]=nil end
end
local function RestoreGlyphContent(s)
    for frame,shown in pairs(s.glyphHidden or {}) do if shown then frame:Show() end end
    s.glyphHidden=nil
    local art=s.glyphArt
    if art then
        local bg=art.texture
        bg:ClearAllPoints(); for _,point in ipairs(art.points) do bg:SetPoint(unpack(point)) end
        bg:SetWidth(art.width); bg:SetHeight(art.height); bg:SetTexCoord(unpack(art.coords))
        s.glyphArt=nil
    end
end
local function GlyphContent(s)
    if s.frame~=_G.GlyphFrame then return end
    if not s.frame:IsShown() then RestoreGlyphContent(s); return end
    -- GlyphFrame is a higher-level sheet inside PlayerTalentFrame, not a
    -- second top-level window. Its fill must not cover shared tabs/header.
    local l,t,r,b=glyphBody.left,glyphBody.top,glyphBody.right,glyphBody.bottom
    s.panel:ClearAllPoints()
    s.panel:SetPoint("TOPLEFT",s.frame,"TOPLEFT",l,-t)
    s.panel:SetPoint("BOTTOMRIGHT",s.frame,"BOTTOMRIGHT",r-384,512-b)
    s.accent:Hide()
    local bg=_G.GlyphFrameBackground
    if Kind(bg,"Texture") then
        KeepNative(s,bg)
        if not s.glyphArt then
            local art={texture=bg,points={},width=bg:GetWidth(),height=bg:GetHeight(),coords={bg:GetTexCoord()}}
            for i=1,bg:GetNumPoints() do art.points[i]={bg:GetPoint(i)} end
            s.glyphArt=art
        end
        -- Keep the art at its native offset so the drawn rune lines stay under
        -- the sockets; inset 1px so the box's border frame stays visible.
        bg:ClearAllPoints(); bg:SetPoint("TOPLEFT",s.frame,"TOPLEFT",l+1,-(t+1))
        bg:SetWidth(r-l-2); bg:SetHeight(b-t-2)
        bg:SetTexCoord((l+1)/512,(r-1)/512,(t+1)/512,(b-1)/512)
    end
    KeepNative(s,_G.GlyphFrameGlow)
    s.glyphHidden=s.glyphHidden or {}
    for _,name in ipairs({"PlayerTalentFrameTitleText","PlayerTalentFrameScrollFrame","PlayerTalentFramePointsBar",
        "PlayerTalentFrameStatusFrame","PlayerTalentFramePreviewBar","PlayerTalentFrameActivateButton"}) do
        local frame=_G[name]
        if frame then
            if s.glyphHidden[frame]==nil then
                local shown=frame:IsShown(); s.glyphHidden[frame]=shown and shown~=0 or false
            end
            frame:Hide()
        end
    end
end
local function Restore(s)
    RestoreGlyphContent(s)
    RestoreMapLayers(s)
    for bar,path in pairs(s.statusBars or {}) do bar:SetStatusBarTexture(path) end
    if s.barBg then s.barBg:Hide() end
    if ns.RestoreCharacter and s.frame==_G.CharacterFrame then ns.RestoreCharacter(s) end
    s.active=false
    if s.panel then s.panel:Hide() end
    if s.accent then s.accent:Hide() end
    for region,alpha in pairs(s.regions) do region:SetAlpha(alpha) end
    for region,saved in pairs(s.cleared) do region:SetTexture(saved.path) end
    for texture,saved in pairs(s.textureStyles) do
        texture:SetTexture(saved.path); texture:SetTexCoord(unpack(saved.coords)); texture:SetAlpha(saved.alpha)
        if saved.color and #saved.color>=3 then texture:SetVertexColor(unpack(saved.color)) end
        if saved.size then texture:SetWidth(saved.size[1]); texture:SetHeight(saved.size[2]) end
    end
    for frame,d in pairs(s.insets) do
        d.panel:Hide(); frame:SetBackdrop(d.backdrop)
        if #d.bg>=3 then frame:SetBackdropColor(unpack(d.bg)) end
        if #d.border>=3 then frame:SetBackdropBorderColor(unpack(d.border)) end
    end
    for fs,saved in pairs(s.fonts) do
        fs:SetFont(saved[1],saved[2],saved[3] or "")
        if saved.color then fs:SetTextColor(unpack(saved.color)) end
    end
    for fs,text in pairs(s.questTexts or {}) do if fs:GetText()==text.paint then fs:SetText(text.native) end end
    s.questTexts=nil
    for _,d in pairs(s.buttons) do d.panel:Hide(); if d.label then d.label:Hide() end end
    for icon,d in pairs(s.icons) do icon:SetTexCoord(unpack(d.coords)); if d.sublevel then icon:SetDrawLayer(d.layer,d.sublevel) else icon:SetDrawLayer(d.layer) end; d.border:Hide() end
    for count,d in pairs(s.countLayers or {}) do if d.sublevel then count:SetDrawLayer(d.layer,d.sublevel) else count:SetDrawLayer(d.layer) end end
    for obj,d in pairs(s.geometry or {}) do
        obj:ClearAllPoints()
        if #d.points==0 and d.parent then obj:SetAllPoints(d.parent) end
        for _,point in ipairs(d.points) do obj:SetPoint(unpack(point)) end; obj:SetWidth(d.width); obj:SetHeight(d.height)
    end
    s.frame:SetBackdrop(s.backdrop)
    if #s.bg>=3 then s.frame:SetBackdropColor(unpack(s.bg)) end
    if #s.border>=3 then s.frame:SetBackdropBorderColor(unpack(s.border)) end
end
local function Enabled(spec)
    return ns.GetValue(spec.key)~=false and (spec.independent or not Killed())
end
local Paint
local function TalentTabs(s)
    if s.frame~=_G.PlayerTalentFrame then return end
    local function Save(obj) SaveGeometry(s,obj) end
    local available=math.max(80,s.frame:GetWidth()-20)
    local entries,x,row={},0,0
    for i=1,4 do local tab=_G["PlayerTalentFrameTab"..i]
        if tab and tab:IsShown() then
            local label=tab:GetFontString(); local width=math.min(available,math.max(48,(label and label:GetStringWidth() or 50)+16))
            if x>0 and x+width>available then x,row=0,row+1 end
            entries[#entries+1]={tab=tab,x=x,row=row,width=width}; x=x+width+6
        end
    end
    for _,entry in ipairs(entries) do
        local tab=entry.tab; Save(tab); tab:ClearAllPoints(); tab:SetPoint("BOTTOMLEFT",s.frame,"BOTTOMLEFT",8+entry.x,6+(row-entry.row)*30)
        tab:SetWidth(entry.width); tab:SetHeight(26)
    end
    -- The fill stops above the tab row and left of the dual-spec tabs, which
    -- hang off the art's right edge (TOPRIGHT -32) outside the window.
    local right=-32
    local spec,frameRight=_G.PlayerSpecTab1,s.frame:GetRight()
    local specLeft=spec and spec:IsShown() and spec:GetLeft()
    if specLeft and frameRight then right=math.min(-4,specLeft-frameRight-2) end
    -- Close button and points footer end at the talent scroll bar's right edge.
    local limit=right-5
    local scrollBar=_G.PlayerTalentFrameScrollFrameScrollBar
    local barRight=scrollBar and scrollBar:GetRight()
    if barRight and frameRight then limit=math.min(right-2,barRight-frameRight) end
    local bar=_G.PlayerTalentFramePointsBar
    if #entries>0 and bar then Save(bar); bar:ClearAllPoints(); bar:SetPoint("BOTTOMLEFT",s.frame,"BOTTOMLEFT",8,36+row*30); bar:SetPoint("BOTTOMRIGHT",s.frame,"BOTTOMRIGHT",limit,36+row*30) end
    local close=_G.PlayerTalentFrameCloseButton
    if close then
        Save(close)
        if not s.closeTop then local ft,ct=s.frame:GetTop(),close:GetTop(); s.closeTop=ft and ct and ct-ft or -8 end
        close:ClearAllPoints(); close:SetPoint("TOPRIGHT",s.frame,"TOPRIGHT",limit,s.closeTop)
    end
    s.panel:ClearAllPoints(); s.panel:SetPoint("TOPLEFT",s.frame,"TOPLEFT",4,-4)
    s.panel:SetPoint("BOTTOMRIGHT",s.frame,"BOTTOMRIGHT",right,#entries>0 and 34+row*30 or 4)
end
-- Visible art bodies measured from the client FrameXML: {left,top,right,bottom}.
local frameInsets={WorldStateScoreFrame={12,-14,-114,70},BattlefieldMinimap={-3,3,3,-3},
    TimeManagerFrame={11,-12,-48,4},HelpFrame={4,-4,-44,12},GMSurveyFrame={4,-4,-44,12},
    RaidInfoFrame={4,2,-2,4}}
-- Small bars and badges get no accent header.
local compact={MirrorTimer1=true,MirrorTimer2=true,MirrorTimer3=true,StopwatchFrame=true,
    BattlefieldMinimap=true,BattlefieldMinimapTab=true,TicketStatusFrame=true}
local function Capture(frame,spec)
    local s={frame=frame,spec=spec,regions={},cleared={},textureStyles={},insets={},fonts={},buttons={},icons={},backdrop=frame:GetBackdrop(),
        bg={frame:GetBackdropColor()},border={frame:GetBackdropBorderColor()},active=false}
    states[frame]=s
    if not spec.tooltip then
        s.panel=NewPanel(frame)
        local left,top,right,bottom=4,-4,-4,4
        if spec.classic then left,top,right,bottom=11,-12,-32,76 end
        local name=frame:GetName()
        if name=="SpellBookFrame" or name=="QuestFrame" then left,top,right,bottom=11,-12,-32,76
        elseif name=="QuestLogFrame" then left,top,right,bottom=11,-12,-1,11
        elseif name=="LootFrame" then left,top,right,bottom=16,-54,-77,8
        elseif frameInsets[name] then left,top,right,bottom=unpack(frameInsets[name]) end
        s.panel:ClearAllPoints(); s.panel:SetPoint("TOPLEFT",frame,"TOPLEFT",left,top); s.panel:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",right,bottom)
        s.accent=s.panel:CreateTexture(nil,"OVERLAY"); owned[s.accent]=true; s.accent:SetTexture(flat)
        s.accent:SetHeight(2); s.accent:SetPoint("TOPLEFT",s.panel,"TOPLEFT",1,-1); s.accent:SetPoint("TOPRIGHT",s.panel,"TOPRIGHT",-1,-1)
        s.accent:Hide()
    end
    local function RefreshShown() dirty=true; if not InCombatLockdown() then Paint(s) end end
    frame:HookScript("OnShow",RefreshShown)
    if frame==_G.GlyphFrame then
        frame:HookScript("OnHide",function()
            dirty=true
            if not InCombatLockdown() then RestoreGlyphContent(s) end
        end)
    end
    if spec.tooltip and Kind(frame,"GameTooltip") then
        for _,event in ipairs({"OnTooltipSetItem","OnTooltipSetUnit","OnTooltipSetSpell"}) do frame:HookScript(event,RefreshShown) end
    end
    return s
end
Paint=function(s)
    if not Enabled(s.spec) then if s.active then Restore(s) end; return end
    if s.frame==_G.GlyphFrame and not s.frame:IsShown() then RestoreGlyphContent(s) end
    if not s.frame:IsShown() then return end
    s.active=true
    if s.spec.tooltip then
        local n=math.max(0,math.min(4,tonumber(ns.GetValue("tooltipBorderSize")) or 1))
        s.frame:SetBackdrop({bgFile=flat,edgeFile=n>0 and flat or nil,edgeSize=math.max(1,n),insets={left=2,right=2,top=2,bottom=2}})
        local c=ns.GetSettings().tooltipBgColor or {}
        s.frame:SetBackdropColor(c.r or .04,c.g or .04,c.b or .04,ns.GetValue("tooltipBgOpacity"))
        s.frame:SetBackdropBorderColor(.25,.25,.25,1)
    else
        s.frame:SetBackdrop(nil); s.panel:SetBackdropColor(.08,.08,.08,.95); s.panel:SetBackdropBorderColor(.2,.2,.2,1); s.panel:Show()
        local c=ns.GetSettings().blizzWinAccentBar
        if type(c)~="table" or c.enabled~=false then s.accent:SetVertexColor(Accent()); s.accent:Show() else s.accent:Hide() end
    end
    Walk(s,s.frame,0,true)
    TaxiMapContent(s)
    WorldMapContent(s)
    TalentTabs(s)
    GlyphContent(s)
    BattlefieldMinimapContent(s)
    MirrorTimerContent(s)
    if s.accent and compact[s.frame:GetName() or ""] then s.accent:Hide() end
    for region in pairs(s.regions) do region:SetAlpha(0); if s.cleared[region] then region:SetTexture(nil) end end
    for texture,saved in pairs(s.textureStyles) do
        texture:SetTexture(flat); texture:SetTexCoord(0,1,0,1); texture:SetVertexColor(unpack(saved.paint))
    end
    for _,d in pairs(s.buttons) do d.panel:Show(); if d.label then d.label:SetFont(E.GetFontPath("blizzardSkin"),14,FontFlags()); d.label:Show() end end
    if s.frame==_G.CharacterFrame then
        Equipment(s,"Character","player")
        if ns.ApplyCharacter then ns.ApplyCharacter(s) end
    elseif s.frame==_G.InspectFrame then Equipment(s,"Inspect",s.frame.unit) end
end
local tooltips={"GameTooltip","ItemRefTooltip","ShoppingTooltip1","ShoppingTooltip2","ShoppingTooltip3",
    "ItemRefShoppingTooltip1","ItemRefShoppingTooltip2","ItemRefShoppingTooltip3","WorldMapTooltip","FriendsTooltip"}
local function Visit(name,spec)
    local f=_G[name]
    local friends=E._ModuleNS and E._ModuleNS.EllesmereUIFriends
    if name=="FriendsFrame" and friends and friends.IsWrath and friends.Config and friends.Config() and friends.Config().enabled then
        if states[f] and states[f].active then Restore(states[f]) end
        return
    end
    if f and f.GetBackdrop and f.SetBackdrop and f.GetRegions then
        local s=states[f] or Capture(f,spec); Paint(s)
    end
end
function ns.ReleaseWindow(frame)
    if InCombatLockdown() then return end
    if states[frame] and states[frame].active then Restore(states[frame]) end
end
function ns.Apply()
    if InCombatLockdown() then dirty=true; return end
    if ns.InstallContentHooks then ns.InstallContentHooks() end
    dirty=false
    for _,spec in ipairs(windows) do for _,name in ipairs(spec.frames) do Visit(name,spec) end end
    Visit("GameMenuFrame",{key="reskinGameMenu",independent=true})
    Visit("LFDDungeonReadyDialog",{key="reskinQueuePopup",independent=true})
    Visit("LFDDungeonReadyStatus",{key="reskinQueuePopup",independent=true})
    Visit("LFDRoleCheckPopup",{key="reskinQueuePopup",independent=true})
    for i=1,4 do Visit("StaticPopup"..i,{key="reskinPopupsMenus",independent=true}) end
    for i=1,2 do Visit("DropDownList"..i,{key="reskinPopupsMenus",independent=true}) end
    for _,name in ipairs(tooltips) do Visit(name,{key="customTooltips",independent=true,tooltip=true}) end
    for _,module in ipairs(ns.extras) do if module.Apply then module.Apply() end end
end
function ns.RequestRefresh() dirty=true end
function ns.SetValue(key,value)
    if defaults[key]==nil then return end
    ns.GetSettings()[key]=value; ns.Apply()
    if ns.RefreshWorldMap then ns.RefreshWorldMap() end
end
function ns.WindowsEnabled() return not Killed() end
function ns.SetWindowsEnabled(value)
    local p=E.GetActiveProfileData and E.GetActiveProfileData()
    if p then p.disableWindowSkins=not value; ns.Apply() end
end
function addon:OnInitialize()
    ns.GetSettings()
    SLASH_EUI335BLIZZARDSKIN1="/ebs"; SLASH_EUI335BLIZZARDSKIN2="/ebui"
    SlashCmdList.EUI335BLIZZARDSKIN=function()
        if InCombatLockdown() then return end
        if E.EnsureOptionsLoaded then E.EnsureOptionsLoaded() end; E:ShowModule(ADDON_NAME)
    end
end
local contentHooks={}
function ns.InstallContentHooks()
    for _,name in ipairs({"QuestInfo_Display","QuestLog_Update","GossipFrameUpdate","GossipTitleButton_OnEnter","GossipTitleButton_OnLeave","QuestFrameGreetingPanel_OnShow","QuestTitleButton_OnEnter","QuestTitleButton_OnLeave","PaperDollItemSlotButton_Update","InspectPaperDollItemSlotButton_Update",
        "UIDropDownMenu_Refresh","GameMenuFrame_UpdateVisibleButtons","StaticPopup_Show","PanelTemplates_SetTab",
        "PanelTemplates_SelectTab","PanelTemplates_DeselectTab","SpellButton_UpdateButton","SpellBookFrame_Update",
        "MerchantFrame_Update","TradeFrame_Update","SendMailFrame_Update","InboxFrame_Update","OpenMail_Update","OpenMail_UpdateAttachments","PlayerTalentFrame_Update",
        "ReputationFrame_Update","SkillFrame_Update","GuildBankFrame_Update","AuctionFrameBrowse_Update",
        "PetPaperDollFrame_UpdateIsAvailable","CharacterFrame_Update","PaperDollFrame_UpdateStats","SetCurrentTitle",
        "TokenFrame_Update","LFDQueueFrameRandom_UpdateFrame","LFDDungeonReadyDialogReward_SetReward","LFDDungeonReadyDialogReward_SetMisc",
        "WorldMapFrame_SetFullMapView","WorldMapFrame_SetQuestMapView","WorldMapFrame_SetMiniMode","WorldMapFrame_ToggleWindowSize",
        "WorldMapFrame_ToggleAdvanced","ToggleMapFramerate",
        "ToggleHelpFrame","RebuffedHelpFrame_Show","BattlefieldMinimap_UpdateOpacity","PVPFrame_Update","PVPTeamDetails_Update"}) do
        if not contentHooks[name] and type(_G[name])=="function" then hooksecurefunc(name,ns.RequestRefresh); contentHooks[name]=true end
    end
    local container=_G.TokenFrameContainer
    if container and not contentHooks[container] and type(container.update)=="function" then hooksecurefunc(container,"update",ns.RequestRefresh); contentHooks[container]=true end
end
function addon:OnEnable()
    for _,module in ipairs(ns.extras) do if module.Enable then module.Enable() end end
    ns.Apply()
    local f=CreateFrame("Frame"); ns.events=f
    for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_EQUIPMENT_CHANGED","UNIT_INVENTORY_CHANGED",
        "UNIT_STATS","UNIT_AURA","UNIT_DAMAGE","UNIT_ATTACK_POWER","UNIT_RANGED_ATTACK_POWER","UNIT_MAXHEALTH",
        "COMBAT_RATING_UPDATE","PLAYER_LEVEL_UP","PLAYER_TALENT_UPDATE","UPDATE_SHAPESHIFT_FORM","UNIT_NAME_UPDATE","KNOWN_TITLES_UPDATE"}) do f:RegisterEvent(event) end
    f:SetScript("OnEvent",function(_,event) if event=="PLAYER_REGEN_ENABLED" then ns.Apply() else dirty=true end end)
    local elapsed=0
    f:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        if elapsed>=.2 then
            elapsed=0
            if not InCombatLockdown() and (dirty or ns.CharacterNeedsRefresh and ns.CharacterNeedsRefresh()) then ns.Apply() end
        end
    end)
    if type(E.RefreshAllAddons)=="function" then hooksecurefunc(E,"RefreshAllAddons",ns.RequestRefresh) end
end
