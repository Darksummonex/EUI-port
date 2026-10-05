-- LibDataBroker publishes the display; account SavedVariables own persistence.
local _,ns=...
if not ns.addon then return end
local brokerName="EllesmereUI Bags"
local function Totals(snapshot)
    local free,total,items=0,0,0
    if snapshot then for _,bag in pairs(snapshot.containers) do
        total=total+bag.slots
        for slot=1,bag.slots do local item=bag.items[slot]; if item then items=items+(item.count or 1) else free=free+1 end end
    end end
    return free,total,items
end
local function Copy(value)
    if type(value)~="table" then return value end
    local copy={}; for key,item in pairs(value) do copy[key]=Copy(item) end; return copy
end
function ns.InitializeBroker()
    if ns.broker then return end
    local lib=LibStub and LibStub:GetLibrary("LibDataBroker-1.1",true); if not lib then return end
    ns.broker=lib:NewDataObject(brokerName,{type="data source",label="Bags",icon="Interface\\Buttons\\Button-Backpack-Up",text="Bags",
        OnClick=function(_,button) if button=="RightButton" then ns.OpenCharacterBank() else ns.Toggle() end end,
        OnTooltipShow=function(tooltip)
            tooltip:AddLine("EllesmereUI Bags",1,1,1)
            tooltip:AddLine("Left-click: Bags   Right-click: Saved bank",.7,.9,.8)
            for i,entry in ipairs(ns.Characters()) do if i>12 then break end
                local record=ns.CharacterRecord(entry.realm,entry.name)
                local _,_,bagItems=Totals(record.bags); local _,_,bankItems=Totals(record.bank)
                tooltip:AddLine(entry.name.." - "..entry.realm..": Bags "..bagItems..", Bank "..(record.bank and bankItems or "?"),.8,.8,.8)
            end
            ns.AddGoldTooltip(tooltip)
        end,
        GetCharacters=function() return ns.Characters() end,
        GetInventory=function(realm,name,kind) local record=ns.CharacterRecord(realm,name); return record and Copy(record[kind=="bank" and "bank" or "bags"]) end,
    })
    ns.UpdateBroker()
end
function ns.UpdateBroker()
    local broker=ns.broker; if not broker then return end
    local realm,name=ns.CurrentCharacter(); local record=ns.CharacterRecord(realm,name)
    local free,total=Totals(record and record.bags); broker.text=free.." / "..total.." free"
end
