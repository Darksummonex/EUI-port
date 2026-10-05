-- Wrath channel schedules, shared by Resource Bars and UnitFrames.
local E=EllesmereUI
if not E then return end
local T={byName={},byID={}}
E.WrathChannelTicks=T
-- Wrath counts follow the local ElvUI channel catalogue, not Retail counts.
-- Penance's first pulse is at channel start, leaving two intervals for 3 pulses.
for _,entry in ipairs({{1120,5},{689,5},{5138,5},{5740,4},{755,10},{1949,15},
    {740,4},{44203,4},{16914,10},{15407,3},{48045,5},{47540,3,true},
    {47757,3,true},{47758,3,true},{64843,4},{64901,4},{5143,5},{10,8},
    {12051,4},{1510,6},{58434,6},{42650,8}}) do
    local data={ticks=entry[2],atStart=entry[3]}
    T.byID[entry[1]]=data
    local name=GetSpellInfo and GetSpellInfo(entry[1])
    if name then T.byName[name]=data end -- localized names cover every rank
end
function T.Schedule(name,startTime,endTime,previous,spellID,updating)
    local data=T.byID[spellID] or T.byName[name]
    if not data or not startTime or not endTime or endTime<=startTime then return end
    if previous and previous.name==name and (updating or math.abs(previous.start-startTime)<.001) then return previous end
    local intervals=data.ticks-(data.atStart and 1 or 0)
    return {name=name,start=startTime,interval=(endTime-startTime)/intervals,intervals=intervals}
end
function T.Hide(bar)
    if not bar then return end
    for _,tick in ipairs(bar._euiChannelTicks or {}) do tick:Hide() end
    bar._euiChannelTickLayout=nil
end
function T.Draw(bar,schedule,startTime,endTime,enabled)
    if not enabled or not schedule or not startTime or not endTime or endTime<=startTime then T.Hide(bar); return end
    local width,height=bar:GetWidth(),bar:GetHeight()
    local old=bar._euiChannelTickLayout
    if old and old.schedule==schedule and old.start==startTime and old.finish==endTime and old.width==width and old.height==height then return end
    T.Hide(bar)
    local pool=bar._euiChannelTicks or {}; bar._euiChannelTicks=pool
    bar._euiChannelTickLayout={schedule=schedule,start=startTime,finish=endTime,width=width,height=height}
    local used=0
    for i=1,schedule.intervals-1 do
        local time=schedule.start+i*schedule.interval
        if time>startTime+.001 and time<endTime-.001 then
            used=used+1
            local tick=pool[used]
            if not tick then tick=bar:CreateTexture(nil,"OVERLAY",nil,6); tick:SetTexture("Interface\\Buttons\\WHITE8X8"); tick:SetVertexColor(1,1,1,.7); pool[used]=tick end
            tick:ClearAllPoints(); tick:SetWidth(1); tick:SetHeight(math.max(1,height-2))
            -- Channel fill drains right to left, so the remaining amount at
            -- this pulse is the marker's fixed position along the bar.
            tick:SetPoint("CENTER",bar,"LEFT",width*(endTime-time)/(endTime-startTime),0); tick:Show()
        end
    end
end

