-- Explicit Wrath fixture plus execution of the module/library's real secure snippets.
-- Simulates contracts and rejects insecure protected writes; not a native taint test.
local methods=getmetatable(UIParent).__index
strmatch=string.match
format=string.format
combat,restricted,vehicle,bonus,page,form,stealth,pet,group,hover=false,false,false,0,1,0,false,true,nil,false
class="WARRIOR"
function UnitClass() return class,class end
function InCombatLockdown() return combat end
function MouseIsOver() return hover end
function GetNumShapeshiftForms() return 3 end
function methods:GetName() return self.name end
function methods:GetNumPoints() return #(self.points or {}) end
function methods:GetPoint(i) return unpack((self.points or {})[i or 1] or {}) end
function methods:SetPoint(...) self.points=self.points or {}; self.points[#self.points+1]={...} end
function methods:ClearAllPoints() self.points={} end
function methods:SetScale(v) self.scale=v end
function methods:GetScale() return self.scale or 1 end
function methods:SetAlpha(v) self.alpha=v end
function methods:GetAlpha() return self.alpha or 1 end
function methods:IsVisible() return self:IsShown() and (not self.parent or self.parent:IsVisible()) end
function methods:SetBackdrop(v) self.backdrop=v end
function methods:SetBackdropColor(...) self.bgColor={...} end
function methods:SetBackdropBorderColor(...) self.borderColor={...} end
function methods:EnableMouse(v) self.mouse=v end
function methods:IsMouseEnabled() return self.mouse~=false end
function methods:SetFrameRef(key,f) self.refs=self.refs or {}; self.refs[key]=f end
function methods:GetFrameRef(key) return self.refs and self.refs[key] end
function methods:ClearBindings() assert(not combat or restricted); self.bindings={} end
function methods:SetBindingClick(priority,key,name,button) assert(not combat or restricted); self.bindings[key]={name,button} end
function methods:RegisterForDrag(...) self.drags={...} end
function methods:RegisterForClicks(...) self.clicks={...} end
function methods:SetChecked(v) self.checked=v end
function methods:SetNormalTexture(path)
    local t=self.normalTexture or _G[self.name.."NormalTexture"]
    t:SetTexture(path)
end
function RunSnippet(frame,code,args,...)
    local control={}
    function control:RunFor(other,otherCode,...) return RunSnippet(other,otherCode,nil,...) end
    function control:RunAttribute(key,...) return RunSnippet(frame,frame:GetAttribute(key),nil,...) end
    function control:ChildUpdate(id,message)
        for _,other in ipairs(frame.children) do
            if other.parent==frame then
                local code=other:GetAttribute("_childupdate-"..id)
                if code then RunSnippet(other,code,{message=message}) end
            end
        end
    end
    local env=setmetatable({self=frame,control=control,format=string.format},{__index=_G})
    for k,v in pairs(args or {}) do env[k]=v end
    local f=assert(loadstring(code)); setfenv(f,env)
    local before=restricted; restricted=true; local result={f(...)}; restricted=before
    return unpack(result)
end
function methods:Execute(code) return RunSnippet(self,code) end
function methods:WrapScript(other,event,pre,post)
    other.wrapped=other.wrapped or {}; other.wrapped[event]=other.wrapped[event] or {}
    table.insert(other.wrapped[event],{pre=pre,post=post})
end
function methods:SetAttribute(key,value)
    assert(not combat or restricted,"insecure protected attribute write: "..key)
    local before=self.attributes[key]; self.attributes[key]=value
    if before~=value then
        local id=key:match("^state%-(.+)")
        if id and self.attributes["_onstate-"..id] then
            RunSnippet(self,self.attributes["_onstate-"..id],{newstate=value})
        end
        if self.scripts.OnAttributeChanged then self.scripts.OnAttributeChanged(self,key,value) end
    end
end
local create=CreateFrame
function CreateFrame(kind,name,parent,template)
    local f=create(kind,name,parent,template); f.name=name
    if template and template:find("ActionButtonTemplate",1,true) then
        for _,suffix in ipairs({"Icon","Flash","HotKey","Count","Name","Border","NormalTexture"}) do
            _G[name..suffix]=f:CreateTexture()
        end
        _G[name.."Cooldown"]=create("Cooldown",nil,f)
    end
    return f
end
local function Condition(text)
    for token in text:gmatch("[^,]+") do
        local good
        if token=="vehicleui" then good=vehicle elseif token=="novehicleui" then good=not vehicle
        elseif token=="combat" then good=combat elseif token=="nocombat" then good=not combat
        elseif token=="pet" then good=pet elseif token=="nopet" then good=not pet
        elseif token=="stealth" then good=stealth elseif token=="nostealth" then good=not stealth
        elseif token=="group" then good=group~=nil elseif token=="group:party" then good=group=="party"
        elseif token=="group:raid" then good=group=="raid"
        elseif token=="nogroup" then good=group==nil elseif token=="nogroup:raid" then good=group~="raid"
        elseif token=="mod:shift" then good=modShift elseif token=="mod:ctrl" then good=modCtrl elseif token=="mod:alt" then good=modAlt
        elseif token=="help" then good=targetReaction=="help" elseif token=="harm" then good=targetReaction=="harm"
        elseif token=="noharm" then good=targetReaction~="harm"
        elseif token=="exists" then good=targetReaction~=nil elseif token=="noexists" then good=targetReaction==nil
        elseif token=="mounted" then good=mounted elseif token=="nomounted" then good=not mounted
        elseif token:find("bonusbar:",1,true) then good=bonus==tonumber(token:match("%d+"))
        elseif token:find("bar:",1,true) then good=page==tonumber(token:match("%d+"))
        elseif token:find("form:",1,true) then good=form==tonumber(token:match("%d+"))
        else error("unmodeled secure condition: "..token) end
        if not good then return false end
    end
    return true
end
function SecureCmdOptionParse(driver)
    for term in driver:gmatch("[^;]+") do
        local cond,result=term:match("%[([^%]]+)%]%s*(%S+)")
        if cond then if Condition(cond) then return result end
        else return term:match("%S+") end
    end
end
drivers={}
function TickDrivers()
    local before=restricted; restricted=true
    for f,list in pairs(drivers) do
        for id,driver in pairs(list) do f:SetAttribute("state-"..id,SecureCmdOptionParse(driver)) end
    end
    restricted=before
end
function RegisterStateDriver(f,id,driver)
    assert(not combat or restricted); drivers[f]=drivers[f] or {}; drivers[f][id]=driver
    local before=restricted; restricted=true; f:SetAttribute("state-"..id,SecureCmdOptionParse(driver)); restricted=before
end
function UnregisterStateDriver(f,id) assert(not combat or restricted); if drivers[f] then drivers[f][id]=nil end end
bindingKeys={ACTIONBUTTON1={"1","SHIFT-1"},MULTIACTIONBAR1BUTTON1={"CTRL-1"},EUI335_BAR6_BUTTON1={"F6"}}
function GetBindingKey(command) return unpack(bindingKeys[command] or {}) end
function GetBindingText(key) return key end
function GetCVarBool() return true end
function IsModifiedClick() return modified or false end
function GetModifiedClick() return "SHIFT" end
function IsShiftKeyDown() return modified or false end
function IsAltKeyDown() return false end
function IsControlKeyDown() return false end
function GetActionInfo(slot) return "spell",slot end
function HasAction(slot) return slot~=12 end
function GetActionText(slot) return "Action "..slot end
function GetActionTexture(slot) return slot~=12 and "icon-"..slot or nil end
function GetActionCount() return 5 end
function GetActionCooldown() return 1,3,1 end
function IsAttackAction() return false end
function IsCurrentAction() return false end
function IsAutoRepeatAction() return false end
function IsEquippedAction() return false end
function IsUsableAction() return true,false end
function IsConsumableAction() return true end
function IsStackableAction() return false end
function IsActionInRange() return 1 end
function GetCursorInfo() end
function CooldownFrame_SetTimer(f,start,duration,enabled) f.start,f.duration,f.enabled=start,duration,enabled end
RANGE_INDICATOR="*"; ATTACK_BUTTON_FLASH_TIME=.4; TOOLTIP_UPDATE_TIME=.2
GameTooltip=CreateFrame("Frame")
function GameTooltip:GetOwner() return self.owner end
function GameTooltip:SetAction(slot) self.action=slot; return true end
function GameTooltip:SetOwner(f) self.owner=f end
function GameTooltip_SetDefaultAnchor(t,f) t.owner=f end
function SetBinding() error("saved bindings must not be changed") end
function SetBindingClick() error("saved bindings must not be changed") end
function EllesmereUI.GetFontPath() return "Fonts\\FRIZQT__.TTF" end
function EllesmereUI.GetClassColor() return {r=.7,g=.2,b=.1} end
function EllesmereUI:MakeUnlockElement(cfg) return cfg end
EllesmereUI.MakeUnlockElement=function(cfg) return cfg end
function EllesmereUI:RegisterUnlockElements(elements,folder) unlockElements,unlockFolder=elements,folder end
nativeParent=CreateFrame("Frame","NativeParent",UIParent)
for _,prefix in ipairs({"ActionButton","BonusActionButton","MultiBarBottomLeftButton","MultiBarBottomRightButton","MultiBarRightButton","MultiBarLeftButton","PetActionButton","ShapeshiftButton"}) do
    for i=1,12 do
        local b=CreateFrame("CheckButton",prefix..i,nativeParent)
        b:SetPoint("LEFT",nativeParent,"LEFT",i,2); b:SetWidth(36); b:SetHeight(36); b:SetScale(.9)
        b:SetScript("OnClick",function() nativeClicks=(nativeClicks or 0)+1 end)
        if prefix=="PetActionButton" or prefix=="ShapeshiftButton" then _G[prefix..i.."HotKey"]=b:CreateTexture() end
    end
end
for _,name in ipairs({"MainMenuBarTexture0","MainMenuBarLeftEndCap","ActionBarUpButton","MainMenuBarPageNumber","BonusActionBarFrame","PetActionBarFrame","ShapeshiftBarFrame","VehicleMenuBar","PossessBarFrame","MainMenuExpBar","CharacterMicroButton","MainMenuBarBackpackButton"}) do
    CreateFrame("Frame",name,nativeParent):SetAlpha(.8)
end
