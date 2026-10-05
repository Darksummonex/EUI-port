-- Right-click home for one window: meter bookmarks.
local _,ns=...
local E=EllesmereUI
local MAX_BOOKMARKS=12
local homeIcons={damage="dm_home_damage",dps="dm_home_damage",healing="dm_home_healing",hps="dm_home_healing",
    overheal="dm_home_healing",healingReceived="dm_home_healing",absorbed="dm_home_healing",interrupts="dm_home_interrupt",
    deaths="dm_home_deaths",dispels="dm_home_dispel",taken="dm_home_taken",friendlyFire="dm_home_taken",
    enemyTaken="dm_home_enemytaken",avoided="dm_home_avoidable",misses="dm_home_avoidable",blocked="dm_home_avoidable",
    resisted="dm_home_avoidable"}
function ns.MetricIcon(key) return ns.MEDIA..(homeIcons[key] or "dm_home_damage")..".tga" end
local function Accent() if E.GetAccentColor then return E.GetAccentColor() end; return .047,.824,.616 end
local function Bookmarks(cfg)
    local list={}
    for _,key in ipairs(type(cfg.bookmarks)=="table" and cfg.bookmarks or ns.windowExtras.bookmarks) do
        if ns.metricMap[key] and #list<MAX_BOOKMARKS then list[#list+1]=key end
    end
    cfg.bookmarks=list
    return list
end
local function Entry(parent,height)
    local b=ns.Button(parent,"",100,height)
    b.text:ClearAllPoints(); b.text:SetJustifyH("LEFT"); b.text:SetHeight(height)
    b.icon=b:CreateTexture(nil,"ARTWORK"); ns.Size(b.icon,14,14); b.icon:SetPoint("LEFT",b,"LEFT",5,0); b.icon:Hide()
    b.arrow=ns.Text(b,10); b.arrow:SetPoint("RIGHT",b,"RIGHT",-6,0); b.arrow:SetText(">"); b.arrow:Hide()
    return b
end
local function Mark(b,active)
    local r,g,bl=Accent()
    if active then b.text:SetTextColor(r,g,bl); b:SetBackdropBorderColor(r,g,bl,1)
    else b.text:SetTextColor(1,1,1); b:SetBackdropBorderColor(.2,.22,.25,1) end
end
function ns.HideHome(index)
    local r=ns.windows[index]; if r and r.home then r.home:Hide() end
end
function ns.AddBookmarkMenu(index,anchor)
    local cfg=ns.Profile().windows[index]; if not cfg then return end
    local have={}; for _,key in ipairs(Bookmarks(cfg)) do have[key]=true end
    local items={}
    for _,m in ipairs(ns.metrics) do
        if not have[m.key] then local key=m.key
            items[#items+1]={text=m.label,fn=function()
                local marks=Bookmarks(cfg); if #marks<MAX_BOOKMARKS then marks[#marks+1]=key end; ns.PaintHome(index)
            end}
        end
    end
    if #items>0 then ns.OpenMenu(anchor,items) end
end
function ns.CreateHome(index)
    local r=ns.windows[index]; if not r then return end
    if r.home then return r.home end
    local h=CreateFrame("Frame",nil,r.frame); r.home=h
    h:SetFrameLevel(r.frame:GetFrameLevel()+20); h:EnableMouse(true); ns.Skin(h,.97); h:Hide()
    h.metersLabel=ns.Text(h,10); h.metersLabel:SetText("METERS"); h.metersLabel:SetTextColor(.6,.65,.7)
    h.tiles={}
    for i=1,MAX_BOOKMARKS+1 do
        local tile=Entry(h,22)
        tile:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp")
        tile:SetScript("OnClick",function(self,button)
            local cfg=ns.Profile().windows[index]; if not cfg then return end
            if button=="RightButton" then ns.HideHome(index); return end
            if self.addNew then if button~="MiddleButton" then ns.AddBookmarkMenu(index,self) end; return end
            if button=="MiddleButton" then table.remove(Bookmarks(cfg),self.slot); ns.PaintHome(index); return end
            cfg.metric=self.metric; r.offset=0; ns.HideHome(index); ns.Refresh()
        end)
        h.tiles[i]=tile
    end
    h:SetScript("OnMouseUp",function(_,button) if button=="RightButton" then ns.HideHome(index) end end)
    return h
end
function ns.PaintHome(index)
    local r=ns.windows[index]; local h=r and r.home; local cfg=ns.Profile().windows[index]
    if not h or not cfg then return end
    local b=ns.Clamp(cfg.borderSize,0,4)
    local w=cfg.width-b*2; local pad=6; local colW=math.floor((w-pad*2-4)/2)
    h:ClearAllPoints(); h:SetPoint("TOPLEFT",r.frame,"TOPLEFT",b,-(b+cfg.headerHeight)); h:SetWidth(w)
    local y=-pad
    h.metersLabel:ClearAllPoints(); h.metersLabel:SetPoint("TOPLEFT",h,"TOPLEFT",pad,y); y=y-16
    local marks=Bookmarks(cfg); local tileRows=math.ceil(#marks/2)
    for i,tile in ipairs(h.tiles) do
        tile:ClearAllPoints(); tile.text:ClearAllPoints()
        if i<=#marks then
            local key=marks[i]
            tile.addNew,tile.metric,tile.slot=false,key,i
            ns.Size(tile,colW,22); tile:SetPoint("TOPLEFT",h,"TOPLEFT",pad+((i-1)%2)*(colW+4),y-math.floor((i-1)/2)*24)
            tile.icon:SetTexture(ns.MetricIcon(key)); tile.icon:Show(); tile.arrow:Show()
            tile.text:SetPoint("LEFT",tile.icon,"RIGHT",5,0); tile.text:SetPoint("RIGHT",tile,"RIGHT",-16,0)
            tile.text:SetText(ns.metricMap[key].label); Mark(tile,cfg.metric==key); tile:Show()
        elseif i==#marks+1 and #marks<MAX_BOOKMARKS then
            tile.addNew,tile.metric=true,nil
            ns.Size(tile,colW*2+4,20); tile:SetPoint("TOPLEFT",h,"TOPLEFT",pad,y-tileRows*24)
            tile.icon:Hide(); tile.arrow:Hide()
            tile.text:SetPoint("LEFT",tile,"LEFT",8,0); tile.text:SetPoint("RIGHT",tile,"RIGHT",-8,0)
            tile.text:SetText("+ ADD NEW  (middle click to remove)"); Mark(tile,false); tile.text:SetTextColor(.6,.65,.7)
            tile:Show()
        else tile:Hide() end
    end
    y=y-tileRows*24-(#marks<MAX_BOOKMARKS and 24 or 0)
    h:SetHeight(-y+pad)
end
function ns.ShowHome(index)
    local cfg=ns.Profile().windows[index]
    local h=cfg and ns.CreateHome(index); if not h then return end
    ns.PaintHome(index); h:Show()
end
