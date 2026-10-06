-- EllesmereUIDataBars 3.3.5: Spacer block factory (port of Retail Blocks\Spacer.lua).
local _, ns = ...
if not ns.IsWrath then return end
local K = ns.BlockKit

local InstKey = K.InstKey

-------------------------------------------------------------------------------
--  SPACER (transparent block; the slot's optional bg tint still applies)
-------------------------------------------------------------------------------
ns.BlockFactories.spacer = function(blockCfg, slot, content, barCtx)
    local inst = { cfg = blockCfg, slot = slot, content = content, ctx = barCtx }
    inst.key = InstKey(barCtx, blockCfg)
    function inst:Refresh() end
    function inst:Enable() end
    function inst:Disable() end
    function inst:Destroy() self._dead = true end
    function inst:GetAutoLength() return 0 end
    return inst
end
