local _,ns=...
if not ns.addon then return end
ns.clickModifiers={none="",shift="shift-",ctrl="ctrl-",alt="alt-",["ctrl-shift"]="ctrl-shift-",["alt-shift"]="alt-shift-",["alt-ctrl"]="alt-ctrl-",["alt-ctrl-shift"]="alt-ctrl-shift-"}
local actions={target=true,menu=true,spell=true,focus=true,assist=true}
function ns.SaveBinding(mod,button,action,id)
    local p=ns.GetSettings(); button=tonumber(button)
    if not p or not ns.clickModifiers[mod] or not button or button%1~=0 or button<1 or button>5 or not actions[action] then return false end
    id=tonumber(id)
    if action=="spell" and (not id or id<=0 or id%1~=0 or not GetSpellInfo(id)) then return false end
    p.clickCasting.bindings[mod..":"..button]={action=action,spellID=action=="spell" and id or nil}; ns.Apply(); return true
end
function ns.ClearBinding(mod,button) local p=ns.GetSettings(); if p then p.clickCasting.bindings[mod..":"..button]=nil; ns.Apply() end end
function ns.ApplyBindings(b)
    if InCombatLockdown() or b._euiPreview then return end
    local c=ns.GetSettings().clickCasting
    -- Clear only attributes that this binding owner previously wrote. Clique
    -- can manage the frame while the built-in editor is disabled.
    for key,value in pairs(b._euiOwnedBindings or {}) do if b:GetAttribute(key)==value then b:SetAttribute(key,nil) end end
    b._euiOwnedBindings={}
    if not c.enabled then return end
    local function Set(key,value) b:SetAttribute(key,value); b._euiOwnedBindings[key]=value end
    for key,bind in pairs(c.bindings) do
        local mod,num=key:match("^([%a%-]+):([1-5])$"); local prefix=mod and ns.clickModifiers[mod]
        if prefix and actions[bind.action] then
            if bind.action=="spell" then local name=GetSpellInfo(bind.spellID)
                if name then Set(prefix.."type"..num,"spell"); Set(prefix.."spell"..num,name) end
            else Set(prefix.."type"..num,bind.action) end
        end
    end
end
