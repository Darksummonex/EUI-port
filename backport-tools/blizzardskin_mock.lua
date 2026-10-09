-- Legacy frames only; reject skin writes in combat and modern namespaces.
C_Spell=nil; C_CVar=nil; C_Timer=nil; C_Texture=nil; C_NamePlate=nil; C_Item=nil
local m=getmetatable(UIParent).__index
local originalCreate=CreateFrame
function CreateFrame(kind,name,parent,template)
    assert(not combat,'Created skin in combat')
    local f=originalCreate(kind,name,parent,template); f.name=name; return f
end
function m:GetName() return self.name end
function m:GetObjectType() return self.kind end
function m:GetChildren() return unpack(self.children) end
function m:GetRegions() return unpack(self.regions or {}) end
local oldTexture,oldFont=m.CreateTexture,m.CreateFontString
local function Region(self,ctor)
    local r=ctor(self); table.remove(self.children); self.regions=self.regions or {}; table.insert(self.regions,r); return r
end
function m:CreateTexture() return Region(self,oldTexture) end
function m:CreateFontString() return Region(self,oldFont) end
function m:SetAlpha(v) assert(not combat); self.alpha=v end
function m:GetAlpha() return self.alpha or 1 end
function m:SetFont(...) assert(not combat); self.font={...} end
function m:GetFont() return unpack(self.font or {'Fonts\\FRIZQT__.TTF',12,''}) end
function m:SetTextColor(...) self.textColor={...} end
function m:GetTextColor() return unpack(self.textColor or {1,1,1,1}) end
function m:SetVertexColor(...) self.color={...} end
function m:GetVertexColor() return unpack(self.color or {1,1,1,1}) end
function m:SetDrawLayer(layer) self.drawLayer=layer end
function m:GetDrawLayer() return self.drawLayer or 'ARTWORK' end
function m:GetStringWidth() return #(self.text or '')*7 end
function m:GetNumPoints() return self.point and 1 or 0 end
function m:GetPoint() return unpack(self.point or {}) end
function m:SetTexture(v) assert(not combat); self.texture=v end
function m:GetHighlightTexture() return self.highlight end
function m:GetCheckedTexture() return self.checkedTexture end
function m:GetDisabledCheckedTexture() return self.disabledCheckedTexture end
function m:GetThumbTexture() return self.thumb end
function m:IsEnabled() return self.enabled~=false end
function m:GetID() return self.id or 1 end
function m:GetChecked() return self.checked end
function m:SetFrameLevel(v) assert(not combat); self.level=v end
function m:GetFrameLevel() return self.level or 10 end
function m:EnableMouse(v) self.mouse=v end
function m:SetBackdrop(v) assert(not combat); self.backdrop=v end
function m:GetBackdrop() return self.backdrop end
function m:SetBackdropColor(...) assert(not combat and select('#',...)>=3); self.bgColor={...} end
function m:SetBackdropBorderColor(...) assert(not combat and select('#',...)>=3); self.borderColor={...} end
function m:GetBackdropColor() if self.noBackdropColor then return end; return unpack(self.bgColor or {1,1,1,1}) end
function m:GetBackdropBorderColor() if self.noBackdropColor then return end; return unpack(self.borderColor or {1,1,1,1}) end
function m:SetPoint(...) assert(not combat); self.point={...}; self.pointWrites=(self.pointWrites or 0)+1 end
function m:ClearAllPoints() assert(not combat); self.point=nil end
function m:SetAllPoints(f) self.allPoints=f end
function m:GetTexCoord() return unpack(self.texcoords or {0,1,0,1}) end
function m:GetNormalTexture() return self.normal end
function m:GetPushedTexture() return self.pushed end
function m:GetDisabledTexture() return self.disabled end
function m:GetFontString() return self.label end
function m:HookScript(k,f)
    assert(not k:find('OnTooltip',1,true) or self.kind=='GameTooltip','GameTooltip-only script on a regular Frame')
    local previous=self.hooks[k]
    self.hooks[k]=function(...) if previous then previous(...) end; f(...) end
end
function m:RunScript(k,...) if self.scripts[k] then self.scripts[k](self,...) end; if self.hooks[k] then self.hooks[k](self,...) end end
function m:Show() local changed=not self.shown; self.shown=true; if changed then self:RunScript('OnShow') end end
function m:Hide() local changed=self.shown; self.shown=false; if changed then self:RunScript('OnHide') end end
function NativeButton(name,parent)
    local b=CreateFrame('Button',name,parent); b:SetWidth(100); b:SetHeight(22); b:SetPoint('CENTER',parent,'CENTER',0,0)
    b.label=b:CreateFontString(); b.label:SetText('Native action')
    b.normal=b:CreateTexture(); b.normal:SetTexture('Interface\\Buttons\\UI-Panel-Button-Up')
    b.pushed=b:CreateTexture(); b.pushed:SetTexture('Interface\\Buttons\\UI-Panel-Button-Down')
    b.disabled=b:CreateTexture(); b.disabled:SetTexture('Interface\\Buttons\\UI-Panel-Button-Disabled')
    b.nativeClicks=0; b:SetScript('OnClick',function(self) self.nativeClicks=self.nativeClicks+1; return 'native-result' end)
    return b
end
function NativeWindow(name)
    local f=CreateFrame('Frame',name,UIParent); f:SetWidth(384); f:SetHeight(512); f:SetPoint('CENTER',UIParent,'CENTER',20,30)
    f:SetBackdrop({bgFile='native-bg',edgeFile='native-edge',edgeSize=16}); f:SetBackdropColor(.4,.5,.6,.7); f:SetBackdropBorderColor(.8,.7,.6,.5)
    f.art=f:CreateTexture(); f.art:SetTexture('Interface\\QuestFrame\\UI-Quest-TopLeft'); f.art:SetAlpha(.8)
    f.title=f:CreateFontString(); f.title:SetText(name); f.title:SetFont('Fonts\\FRIZQT__.TTF',14,'')
    f.body=CreateFrame('Frame',nil,f)
    f.text=f.body:CreateFontString(); f.text:SetFont('Fonts\\FRIZQT__.TTF',12,''); f.text:SetTextColor(.1,.1,.1,1); f.text:SetText('Native content')
    f.icon=f.body:CreateTexture(); f.icon:SetTexture('Interface\\Icons\\Spell_Fire_Fireball')
    f.model=CreateFrame('PlayerModel',nil,f.body)
    f.button=NativeButton(name..'Button',f)
    -- UIPanelCloseButton: minimize art, no FontString.
    f.close=NativeButton(name..'CloseButton',f); f.close.label=nil
    f.close.normal:SetTexture('Interface\\Buttons\\UI-Panel-MinimizeButton-Up')
    f.edit=CreateFrame('EditBox',nil,f); f.edit:SetAutoFocus(false); f.edit:SetFont('Fonts\\FRIZQT__.TTF',12,'')
    f.edit:SetScript('OnEnterPressed',function() sent=(sent or 0)+1 end)
    return f
end
CharacterFrame=NativeWindow('CharacterFrame'); MerchantFrame=NativeWindow('MerchantFrame')
QuestFrame=NativeWindow('QuestFrame'); QuestLogFrame=NativeWindow('QuestLogFrame')
GameMenuFrame=NativeWindow('GameMenuFrame'); StaticPopup1=NativeWindow('StaticPopup1')
DropDownList1=NativeWindow('DropDownList1'); LFDDungeonReadyDialog=NativeWindow('LFDDungeonReadyDialog')
GameTooltip=NativeWindow('GameTooltip'); GameTooltip.kind='GameTooltip'
FriendsTooltip=NativeWindow('FriendsTooltip')
CharacterHeadSlot=CreateFrame('Button','CharacterHeadSlot',CharacterFrame)
CharacterHeadSlotIconTexture=CharacterHeadSlot:CreateTexture(); CharacterHeadSlotIconTexture:SetTexture('Interface\\Icons\\INV_Helmet_01')
CharacterHeadSlotIconTexture:SetTexCoord(0,1,0,1)
-- Real missed Wrath chrome, with native actions/state rather than dummy skins.
PaperDollFrame=CreateFrame('Frame','PaperDollFrame',CharacterFrame)
PaperDollFrame.art=PaperDollFrame:CreateTexture(); PaperDollFrame.art:SetTexture('Interface\\CharacterFrame\\UI-Character-General-Middle')
PaperDollFrame:SetBackdrop({bgFile='native-inner',edgeFile='native-edge',edgeSize=16})
CharacterDialogButton=NativeButton('CharacterDialogButton',PaperDollFrame)
CharacterDialogButton.normal:SetTexture('Interface\\Buttons\\UI-DialogBox-Button-Up')
CharacterModelFrame=CreateFrame('PlayerModel','CharacterModelFrame',PaperDollFrame)
CharacterModelFrame.art=CharacterModelFrame:CreateTexture(); CharacterModelFrame.art:SetTexture('Interface\\CharacterFrame\\UI-Character-StatBackground')
CharacterFrame.edit.art=CharacterFrame.edit:CreateTexture(); CharacterFrame.edit.art:SetTexture('Interface\\Common\\Common-Input-Border')
CharacterFrame.edit:SetBackdrop({bgFile='native-edit'})
CharacterFrameTab1=NativeButton('CharacterFrameTab1',CharacterFrame)
CharacterFrameTab2=NativeButton('CharacterFrameTab2',CharacterFrame); CharacterFrameTab2.id=2
CharacterFrameTab1.normal:SetTexture('Interface\\CharacterFrame\\UI-Character-Tab-Left')
CharacterFrameTab2.normal:SetTexture('Interface\\CharacterFrame\\UI-Character-Tab-Left')
CharacterFrameTab1.highlight=CharacterFrameTab1:CreateTexture(); CharacterFrameTab1.highlight:SetTexture('native-tab-highlight')
CharacterFrame.selectedTab=1
function PanelTemplates_SetTab(frame,id) frame.selectedTab=id end
CharacterFrameTab2:SetScript('OnClick',function(self) self.nativeClicks=self.nativeClicks+1; PanelTemplates_SetTab(CharacterFrame,self.id) end)
CharacterTestScrollBar=CreateFrame('Slider','CharacterTestScrollBar',PaperDollFrame)
CharacterTestScrollBar:SetMinMaxValues(0,800); CharacterTestScrollBar:SetValue(250)
CharacterTestScrollBar.thumb=CharacterTestScrollBar:CreateTexture(); CharacterTestScrollBar.thumb:SetTexture('Interface\\Buttons\\UI-ScrollBar-Knob')
CharacterTestScrollBar.thumb:SetTexCoord(.1,.9,.2,.8); CharacterTestScrollBar.thumb:SetVertexColor(.6,.7,.8,1)
CharacterTestScrollBar.thumb:SetWidth(32); CharacterTestScrollBar.thumb:SetHeight(32); CharacterTestScrollBar:SetOrientation('VERTICAL')
OptionsTestSlider=CreateFrame('Slider','OptionsTestSlider',PaperDollFrame)
OptionsTestSlider.thumb=OptionsTestSlider:CreateTexture(); OptionsTestSlider.thumb:SetTexture('Interface\\Buttons\\UI-SliderBar-Button-Horizontal')
OptionsTestSlider.thumb:SetWidth(32); OptionsTestSlider.thumb:SetHeight(32)
CharacterTestScrollBarScrollDownButton=NativeButton('CharacterTestScrollBarScrollDownButton',CharacterTestScrollBar)
CharacterTestScrollBarScrollDownButton.normal:SetTexture('Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up')
CharacterTestScrollBarScrollDownButton:SetScript('OnClick',function() CharacterTestScrollBar:SetValue(CharacterTestScrollBar.value+50) end)
CharacterTestCheck=NativeButton('CharacterTestCheck',PaperDollFrame); CharacterTestCheck.kind='CheckButton'
CharacterTestCheck.normal:SetTexture('Interface\\Buttons\\UI-CheckBox-Up')
CharacterTestCheck.checkedTexture=CharacterTestCheck:CreateTexture(); CharacterTestCheck.checkedTexture:SetTexture('Interface\\Buttons\\UI-CheckBox-Check')
CharacterTestCheck:SetScript('OnClick',function(self) self.checked=not self.checked end)
PlayerStatFrameLeftDropDown=CreateFrame('Frame','PlayerStatFrameLeftDropDown',PaperDollFrame)
PlayerStatFrameLeftDropDown.art=PlayerStatFrameLeftDropDown:CreateTexture(); PlayerStatFrameLeftDropDown.art:SetTexture('Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame')
PlayerStatFrameLeftDropDownButton=NativeButton('PlayerStatFrameLeftDropDownButton',PlayerStatFrameLeftDropDown)
PlayerStatFrameLeftDropDownButton:SetScript('OnClick',function() dropdownOpened=true end)
SpellBookFrame=NativeWindow('SpellBookFrame')
SpellButton1=CreateFrame('Button','SpellButton1',SpellBookFrame)
SpellButton1IconTexture=SpellButton1:CreateTexture(); SpellButton1IconTexture:SetTexture('Interface\\Icons\\Spell_Frost_FrostBolt02')
SpellButton1.normal=SpellButton1:CreateTexture(); SpellButton1.normal:SetTexture('Interface\\Buttons\\UI-Quickslot2')
SpellButton1Cooldown=CreateFrame('Cooldown','SpellButton1Cooldown',SpellButton1); SpellButton1Cooldown:SetCooldown(10,20)
SpellBookSkillLineTab1=CreateFrame('CheckButton','SpellBookSkillLineTab1',SpellBookFrame)
SpellBookSkillLineTab1.normal=SpellBookSkillLineTab1:CreateTexture(); SpellBookSkillLineTab1.normal:SetTexture('Interface\\Icons\\Spell_Fire_Fire')
QuestFrameDetailPanel=CreateFrame('Frame','QuestFrameDetailPanel',QuestFrame)
QuestFrameDetailPanel.art=QuestFrameDetailPanel:CreateTexture(); QuestFrameDetailPanel.art:SetTexture('Interface\\QuestFrame\\QuestBG')
WorldMapFrame=NativeWindow('WorldMapFrame'); WorldMapFrame.map=WorldMapFrame:CreateTexture(); WorldMapFrame.map:SetTexture('Interface\\WorldMap\\Elwynn\\Elwynn1')
TaxiFrame=NativeWindow('TaxiFrame')
TaxiMap=TaxiFrame:CreateTexture(); TaxiMap.name='TaxiMap'; TaxiMap:SetDrawLayer('BACKGROUND')
TaxiMap:SetTexture('Interface\\TaxiFrame\\TAXIMAP3'); TaxiFrame.map=TaxiMap
PlayerTalentFrame=NativeWindow('PlayerTalentFrame'); PlayerTalentFrame.tree=PlayerTalentFrame:CreateTexture(); PlayerTalentFrame.tree:SetTexture('Interface\\TalentFrame\\MageFire-TopLeft')
TradeFrame=NativeWindow('TradeFrame'); TradeFrame.accept=TradeFrame:CreateTexture(); TradeFrame.accept.name='TradeHighlightPlayerTop'; TradeFrame.accept:SetTexture('Interface\\TradeFrame\\UI-TradeFrame-Highlight')
quality=4
function GetInventoryItemQuality(unit,id) assert(unit=='player' or unit=='target'); assert(id>=1 and id<=19); return quality end
function GetItemQualityColor(q) if q==4 then return .7,.2,1 else return .1,.4,.8 end end
combat=false
function InCombatLockdown() return combat end
function IsLoggedIn() return true end
activeProfile={}
function EllesmereUI.GetActiveProfileData() return activeProfile end
function EllesmereUI.GetFontOutlineFlag() return 'OUTLINE, SLUG' end
skinFont='Fonts\\ARIALN.TTF'
function EllesmereUI.GetFontPath() return skinFont end
function EllesmereUI.EnsureOptionsLoaded() optionsLoaded=true end
function EllesmereUI:ShowModule(v) shownModule=v end
function EllesmereUI:InvalidatePageCache() end
function EllesmereUI.RefreshAllAddons() end
function QuestInfo_Display() QuestFrame.text:SetTextColor(.1,.1,.1,1); return 'quest-native-result' end
function StaticPopup_Show() return 'popup-native-result' end
function hooksecurefunc(target,key,callback)
    if type(target)=='string' then callback=key; key=target; target=_G end
    local original=target[key]
    target[key]=function(...) local a,b,c=original(...); callback(...); return a,b,c end
end
rows={}; EllesmereUI.Widgets={}
function EllesmereUI.Widgets:DualRow(_,_,left,right) rows[#rows+1]={left,right}; return CreateFrame('Frame'),50 end
function EllesmereUI.Widgets:SectionHeader() return CreateFrame('Frame'),30 end
