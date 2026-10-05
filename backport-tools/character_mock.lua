-- Additional legacy contracts for the expanded character sheet.
local m=getmetatable(UIParent).__index
EllesmereUI.L=function(text) return text end
local register=m.RegisterEvent
function m:RegisterEvent(event)
    assert(event~='GET_ITEM_INFO_RECEIVED','Retail-only item-cache event registered on Wrath')
    return register(self,event)
end
local createFont=m.CreateFontString
function m:CreateFontString(name,...)
    local fs=createFont(self,...); fs.name=name; if name then _G[name]=fs end; return fs
end
function m:SetFont(...) assert(not combat); self.font={...}; return true end
function m:GetStringWidth() return #(self.text or "")*7 end
function m:SetSize(w,h) assert(not combat); self.width,self.height=w,h end
function m:GetNumPoints() return #(self.points or (self.point and {self.point}) or {}) end
function m:GetPoint(i) return unpack((self.points or (self.point and {self.point}) or {})[i or 1] or {}) end
function m:SetPoint(...)
    assert(not combat); self.point={...}; self.points=self.points or {}
    local replaced=false
    for i,point in ipairs(self.points) do
        if point[1]==self.point[1] then self.points[i]=self.point; replaced=true; break end
    end
    if not replaced then self.points[#self.points+1]=self.point end
    self.pointWrites=(self.pointWrites or 0)+1
end
function m:ClearAllPoints() assert(not combat); self.point=nil; self.points={} end
function m:SetJustifyH(v) self.justifyH=v end
function m:SetScrollChild(child) self.scrollChild=child end
function m:SetVerticalScroll(v) self.scroll=v end
function m:GetVerticalScroll() return self.scroll or 0 end
function m:SetValueStep(v) self.step=v end
function m:SetThumbTexture(path) self.thumb=self:CreateTexture(); self.thumb:SetTexture(path) end
function m:EnableMouseWheel(v) self.wheel=v end
function m:Click() self:RunScript('OnClick','LeftButton') end
function m:SetValue(v) self.value=v; if self.scripts.OnValueChanged then self:RunScript('OnValueChanged',v) end end
gearCacheMissing=false; gearTwoHand=false; statCalls=0
function GetInventoryItemLink(_,id)
    if gearTwoHand and id==17 then return end
    return 'item:'..id
end
function GetItemInfo(link)
    if gearCacheMissing and link=='item:1' then return end
    local id=tonumber(link:match('item:(%d+)'))
    return 'Gear',link,4,200+id,80,'Armor','Plate',1,(gearTwoHand and id==16) and 'INVTYPE_2HWEAPON' or 'INVTYPE_HEAD','icon'
end
function UpdatePaperdollStats(prefix,token)
    assert(token:find('PLAYERSTAT_',1,true))
    statCalls=statCalls+1
    for i=1,6 do
        local row=_G[prefix..i]; assert(row and _G[prefix..i..'Label'] and _G[prefix..i..'StatText'])
        _G[prefix..i..'Label']:SetText(i<=5 and 'Stat '..i or '')
        _G[prefix..i..'StatText']:SetText(100+i)
        row.tooltip='Native stat tooltip'; if i<=5 then row:Show() else row:Hide() end
    end
end
function PaperDollStatTooltip(row) nativeStatTooltip=row.tooltip end
function CreateCharacterFixture()
    local slots={'Head','Neck','Shoulder','Back','Chest','Shirt','Tabard','Wrist','Hands','Waist','Legs','Feet','Finger0','Finger1','Trinket0','Trinket1','MainHand','SecondaryHand','Ranged','Ammo'}
    for _,slot in ipairs(slots) do
        local name='Character'..slot..'Slot'
        local button=_G[name] or NativeButton(name,PaperDollFrame)
        local icon=_G[name..'IconTexture'] or button:CreateTexture()
        _G[name..'IconTexture']=icon; icon:SetTexture('Interface\\Icons\\INV_Helmet_01'); icon:SetPoint('CENTER',button,'CENTER',2,3)
        button:SetSize(36,36)
        button:SetScript('OnClick',function(self) self.nativeClicks=(self.nativeClicks or 0)+1 end)
    end
    for i=3,5 do local tab=NativeButton('CharacterFrameTab'..i,CharacterFrame); tab.id=i end
    CharacterFrameTab1.label:SetText('Character'); CharacterFrameTab2.label:SetText('Pet')
    CharacterFrameTab3.label:SetText('Reputation'); CharacterFrameTab4.label:SetText('Skills'); CharacterFrameTab5.label:SetText('Currency')
    CharacterFrameTab2:Hide()
    CharacterAttributesFrame=CreateFrame('Frame','CharacterAttributesFrame',PaperDollFrame)
    CharacterResistanceFrame=CreateFrame('Frame','CharacterResistanceFrame',PaperDollFrame)
    PlayerTitleFrame=CreateFrame('Frame','PlayerTitleFrame',PaperDollFrame)
    PlayerTitlePickerFrame=NativeWindow('PlayerTitlePickerFrame'); PlayerTitlePickerFrame:SetParent(PlayerTitleFrame); PlayerTitlePickerFrame:Hide()
    GearManagerDialog=NativeWindow('GearManagerDialog'); GearManagerDialog:Hide()
    GearManagerToggleButton=NativeButton('GearManagerToggleButton',PaperDollFrame)
    GearManagerToggleButton:SetScript('OnClick',function() GearManagerDialog:Show() end)
    CharacterNameText=CharacterFrame:CreateFontString(); CharacterNameText:SetText('Native Name')
    CharacterLevelText=CharacterFrame:CreateFontString(); CharacterLevelText:SetText('Level 80')
end
