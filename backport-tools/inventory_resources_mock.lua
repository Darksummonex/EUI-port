-- Focused legacy contract fixture: reject text without a font and bank reads
-- without a server bank session; native templates retain their own actions.
local m=getmetatable(UIParent).__index
combat=false; playerClass="WARRIOR"; bankSession=false; nativeCalls={}; itemActions={}; unlockByFolder={}
function InCombatLockdown() return combat end
function UnitClass() return playerClass,playerClass end
function m:SetFont(path,size,flags) self.font={path,size,flags}; return true end
function m:GetFont() if self.font then return unpack(self.font) end end
function m:SetText(text)
    assert(self.font or self.kind~="FontString" and self.kind~="EditBox","Font not set")
    self.text=text
    if self.kind=="EditBox" then self:RunScript("OnTextChanged",false) end
end
function m:GetName() return self.name end
function m:SetID(id) self.id=id end
function m:GetID() return self.id end
function m:SetPoint(...) self.points=self.points or {}; local point={...}; for i,p in ipairs(self.points) do if p[1]==point[1] then self.points[i]=point; return end end; self.points[#self.points+1]=point end
function m:GetPoint(i) return unpack((self.points or {})[i or 1] or {}) end
function m:GetNumPoints() return #(self.points or {}) end
function m:ClearAllPoints() self.points={} end
function m:SetAllPoints(f) self.allPoints=f end
function m:SetAlpha(a) self.alpha=a end
function m:GetAlpha() return self.alpha or 1 end
function m:SetScale(s) self.scale=s end
function m:GetScale() return self.scale or 1 end
function m:SetStatusBarColor(...) self.color={...} end
function m:SetStatusBarTexture(t) self.statusTexture=t end
function m:SetBackdrop(t) self.backdrop=t end
function m:SetBackdropColor(...) self.backdropColor={...} end
function m:SetBackdropBorderColor(...) self.borderColor={...} end
function m:SetMovable(v) self.movable=v end
function m:SetClampedToScreen(v) self.clamped=v end
function m:IsClampedToScreen() return self.clamped or false end
function m:RegisterForDrag(...) self.dragButtons={...} end
function m:StartMoving() self.moving=true end
function m:StopMovingOrSizing() self.moving=false end
function m:SetTextInsets(...) self.textInsets={...} end
function m:SetDrawLayer(layer) self.drawLayer=layer end
function m:GetDrawLayer() return self.drawLayer end
function m:SetTextColor(...) self.textColor={...} end
function m:SetScrollChild(f) self.scrollChild=f end
function m:SetNormalTexture(v) self.normal=self.normal or self:CreateTexture(); self.normal:SetTexture(v) end
function m:GetNormalTexture() return self.normal end
function m:SetPushedTexture(v) self.pushed=v end
function m:SetCheckedTexture(v) self.checked=v end
function m:SetHighlightTexture(v) self.highlight=self.highlight or self:CreateTexture(); self.highlight:SetTexture(v) end
function m:GetHighlightTexture() return self.highlight end
function m:RunScript(name,...)
    local script=self.scripts[name]; if script then script(self,...) end
    local hook=self.hooks[name]; if hook then hook(self,...) end
end
function m:Show() local changed=not self.shown; self.shown=true; if changed then self:RunScript("OnShow") end end
function m:Hide() local changed=self.shown; self.shown=false; if changed then self:RunScript("OnHide") end end
function NativeItemClick(self,button)
    itemActions[#itemActions+1]={self:GetParent():GetID(),self:GetID(),button}
end
function NativeItemDrag(self) NativeItemClick(self,"Drag") end
local create=CreateFrame
function CreateFrame(kind,name,parent,template)
    local f=create(kind,name,parent,template); f.name=name; f.template=template
    if kind=="Button" then
        setmetatable(f,{__index=function(_,key)
            if key=="SetCheckedTexture" then return nil end
            return m[key]
        end})
    end
    if template=="BankItemButtonGenericTemplate" or template=="ContainerFrameItemButtonTemplate" then
        assert(name)
        for _,suffix in ipairs({"IconTexture","Count"}) do
            local child=suffix=="Count" and f:CreateFontString() or f:CreateTexture()
            child:SetDrawLayer("BORDER")
            if suffix=="Count" then child:SetFont("Fonts\\FRIZQT__.TTF",10,""); child:Hide() end
            _G[name..suffix]=child
        end
        _G[name.."Cooldown"]=create("Cooldown",name.."Cooldown",f,"CooldownFrameTemplate")
        f:SetScript("OnClick",NativeItemClick); f:SetScript("OnDragStart",NativeItemDrag); f:SetScript("OnReceiveDrag",NativeItemDrag)
    end
    return f
end
function hooksecurefunc(target,key,fn)
    if type(target)=="table" then
        local original=target[key]
        target[key]=function(self,...) local out={original(self,...)}; fn(self,...); return unpack(out) end
    end
end
function CooldownFrame_SetTimer(f,start,duration,enabled) f.cooldown={start,duration,enabled} end
function GetMoney() return 12345 end
function GetCoinTextureString(v) return v.." copper" end
UISpecialFrames={}
GameTooltip=CreateFrame("GameTooltip","GameTooltip",UIParent)
function GameTooltip:SetOwner(f,anchor) self.owner,self.anchor=f,anchor end
function GameTooltip:SetBagItem(bag,slot) self.bag,self.slot=bag,slot end
function GameTooltip:SetHyperlink(link) self.link=link end
function GameTooltip:SetText(text) self.tooltipText=text end
function GameTooltip:AddLine(text) self.lines=self.lines or {}; self.lines[#self.lines+1]=text end
function GetRealmName() return 'Test Realm' end
function time() return 1790820000 end
function date(format,value) return os.date(format,value) end
function GetKeyRingSize() return bagSlots[-2] or 0 end
function ContainerIDToInventoryID(bag) return 19+bag end
function BankButtonIDToInvSlotID(bag) return 62+bag end
function GetInventoryItemLink(_,slot) return 'item:bag'..slot end
function GetInventoryItemTexture(_,slot) return 'bag-icon:'..slot end
purchasedBankSlots=1; cursorItem=false; bagActions={}
function GetNumBankSlots() assert(bankSession); return purchasedBankSlots end
function CursorHasItem() return cursorItem end
function PutItemInBag(slot) bagActions[#bagActions+1]={'put',slot} end
function PutItemInBackpack() bagActions[#bagActions+1]={'backpack'} end
function PutKeyInKeyRing() bagActions[#bagActions+1]={'keyring'} end
function PickupBagFromSlot(slot) bagActions[#bagActions+1]={'pickup',slot} end
function GetBankSlotCost(n) assert(bankSession); return (n+1)*10000 end
function PurchaseSlot() assert(bankSession); purchasedBankSlots=purchasedBankSlots+1 end
StaticPopupDialogs={}
function StaticPopup_Show(name,price) purchasePopup={name,price} end
BankFrame=CreateFrame("Frame","BankFrame",UIParent); BankFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",20,-30); BankFrame:SetAlpha(.8); BankFrame:SetClampedToScreen(true); BankFrame:Hide()
CastingBarFrame=CreateFrame("StatusBar","CastingBarFrame",UIParent); CastingBarFrame:SetAlpha(.7)
closeBankCount=0
function CloseBankFrame() closeBankCount=closeBankCount+1; bankSession=false; BankFrame:Hide() end
bagSlots={[0]=4,[1]=2,[-2]=1,[-1]=4,[5]=2}
items={['0:1']={link='item:1',name='Sword',quality=3,level=200,type='Weapon',equip='INVTYPE_WEAPON',count=1},
    ['0:2']={link='item:2',name='Healing Potion',quality=1,type='Consumable',count=12,cooldown=8},
    ['0:3']={link='item:3',name='Junk',quality=0,type='Miscellaneous',count=2,locked=true},
    ['1:1']={link='item:4',name='Armor',quality=4,level=232,type='Armor',equip='INVTYPE_CHEST',count=1,readable=true},
    ['-2:1']={link='item:5',name='Key',quality=1,type='Key',count=1},
    ['-1:1']={link='item:6',name='Bank Sword',quality=2,level=180,type='Weapon',equip='INVTYPE_WEAPON',count=1},
}
local function BankRead(bag) assert(not (bag==-1 or bag>4) or bankSession,"bank access outside server session") end
function GetContainerNumSlots(bag) BankRead(bag); return bagSlots[bag] or 0 end
function GetContainerItemInfo(bag,slot)
    BankRead(bag); local i=items[bag..":"..slot]
    if i then return "icon:"..i.link,i.count,i.locked,i.quality,i.readable,false,i.link end
end
function GetContainerItemLink(bag,slot) BankRead(bag); local i=items[bag..":"..slot]; return i and i.link end
function GetContainerItemCooldown(bag,slot) local i=items[bag..":"..slot]; return 1,i and i.cooldown or 0,1 end
function GetItemInfo(link)
    for _,i in pairs(items) do if i.link==link then if i.uncached then return end; return i.name,link,i.quality,i.level,0,i.type,i.subtype or "",20,i.equip or "","icon:"..link end end
end
for _,name in ipairs({"ToggleAllBags","ToggleBackpack","OpenAllBags","OpenBackpack","CloseAllBags","CloseBackpack","ToggleBag","OpenBag","CloseBag","IsBagOpen"}) do
    local entry=name; _G[entry]=function(...) nativeCalls[#nativeCalls+1]={entry,...}; return "native" end
end
function EllesmereUI:RegisterUnlockElements(elements,folder) unlockByFolder[folder]=elements end
function EllesmereUI.MakeUnlockElement(elem) return elem end
function EllesmereUI:RegisterUnlockModeListener(owner,fn) self.listeners=self.listeners or {}; self.listeners[owner]=fn end
function EllesmereUI.ModuleNS(folder) return EllesmereUI._ModuleNS[folder] end
function EllesmereUI.EnsureOptionsLoaded() optionsLoaded=true end
function EllesmereUI:ShowModule(name) shownModule=name end
function EllesmereUI:InvalidatePageCache() invalidated=true end
function EllesmereUI:RefreshPage() refreshed=true end
function EllesmereUI:GetFontOutlineFlag() return "OUTLINE,SLUG" end
modules={}
function EllesmereUI:RegisterModule(name,cfg) modules[name]=cfg end
rows={}; buttons={}
EllesmereUI.Widgets={}
function EllesmereUI.Widgets:DualRow(parent,y,a,b) rows[#rows+1]=a; rows[#rows+1]=b; return {},50 end
function EllesmereUI.Widgets:SectionHeader(parent,label,y) return {},30 end
function EllesmereUI.Widgets:WideButton(parent,label,y,fn) buttons[label]=fn; return {},40 end
function FindRow(label) for _,row in ipairs(rows) do if row.text==label then return row end end; error("missing row: "..label) end
powerType,powerToken,power,maxPower,comboPoints=0,"MANA",50,100,3
function UnitPowerType() return powerType,powerToken end
function UnitPower() return power end
function UnitPowerMax() return maxPower end
function GetComboPoints() return comboPoints end
RAID_CLASS_COLORS.ROGUE={r=1,g=.96,b=.4}; RAID_CLASS_COLORS.DEATHKNIGHT={r=.77,g=.12,b=.23}; RAID_CLASS_COLORS.DRUID={r=1,g=.49,b=.04}
PowerBarColor.RAGE={r=1,g=0,b=0}; PowerBarColor.ENERGY={r=1,g=1,b=0}; PowerBarColor.RUNIC_POWER={r=0,g=.82,b=1}
runes={}
for i=1,6 do runes[i]={start=0,duration=0,ready=true,type=math.ceil(i/2)} end
function GetRuneCooldown(i) local r=runes[i]; return r.start,r.duration,r.ready end
function GetRuneType(i) return runes[i].type end
totems={}
function GetTotemInfo(i) local t=totems[i]; if t then return true,t.name,t.start,t.duration,"totem-icon" end; return false,"",0,0 end
nativeCast,nativeChannel=nil,nil
function UnitCastingInfo() if nativeCast then return unpack(nativeCast) end end
function UnitChannelInfo() if nativeChannel then return unpack(nativeChannel) end end
gcdStart,gcdDuration,gcdEnabled=0,0,1
function GetSpellCooldown(id) assert(id==61304); return gcdStart,gcdDuration,gcdEnabled end
