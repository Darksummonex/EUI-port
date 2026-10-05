local _,ns=...
-- Wrath spell IDs are name/rank anchors; only learned cooldown spells render.
ns.catalog={
 WARRIOR={cooldowns={1719,12292,46924,23920,871,12975,2565,676,6552,5246,3411,1680},utility={100,20252,3411,18499,55694,1160},buffs={46916,52437,18499,12292,1719}},
 PALADIN={cooldowns={31884,642,498,633,1044,1022,6940,1038,31821,20216,20473,31935,53385},utility={853,20066,96231,62124,54428,19752},buffs={31884,53601,53563,54149,59578,642}},
 HUNTER={cooldowns={3045,19574,19263,5384,23989,34490,53301,53209,19386},utility={781,1543,13809,1499,34477,20736,19801},buffs={19574,3045,56453,56342,53220}},
 ROGUE={cooldowns={13750,13877,51690,14177,14185,5277,31224,1856,57934,1766,51713},utility={2983,2094,1725,1776,408,51722},buffs={5171,32645,14177,51713,31665}},
 PRIEST={cooldowns={10060,33206,47788,47585,34433,64843,64901,47540,33076},utility={6346,586,15487,64044,10890},buffs={10060,33206,47788,59887,33151,63731,15286}},
 DEATHKNIGHT={cooldowns={48792,48707,49016,55233,51271,49206,51052,47568,49222,49028,48982,42650},utility={49576,47528,47476,48743,57330,49998},buffs={48792,48707,59052,51124,51271,55233}},
 SHAMAN={cooldowns={2825,32182,16188,16166,16190,30823,51533,51514,57994},utility={20608,8177,2484,5394,2894,2062},buffs={53817,53390,16246,49281,2825,32182}},
 MAGE={cooldowns={12042,12472,11129,11958,31687,45438,12051,2139,44572,55342},utility={1953,122,120,543,1463,66,30449},buffs={44401,48108,57761,44544,12042,12472,11129}},
 WARLOCK={cooldowns={47897,17962,50796,48181,47241,18540,1122,19647,7812},utility={48020,6789,5484,18220,18708,29858,17928},buffs={54277,34936,71165,47241,17941}},
 DRUID={cooldowns={17116,50334,61336,22812,22842,29166,48477,18562,50516,48505,33831},utility={5229,5217,1850,8983,6795,5209},buffs={16870,48517,48518,69369,5217,50334,22812}},
}
ns.racials={59752,20594,58984,20549,20572,26297,7744,28730,59547,59548,59549}
function ns.SeedLists(class)
    local seed=ns.catalog[class] or {cooldowns={},utility={},buffs={}}
    local lists={cooldowns={},utility={},buffs={},tracking={}}
    for _,key in ipairs({"cooldowns","utility","buffs"}) do
        for _,id in ipairs(seed[key]) do lists[key][#lists[key]+1]={kind=key=="buffs" and "aura" or "spell",id=id,unit="player",filter="HELPFUL",enabled=true} end
    end
    for _,id in ipairs(ns.racials) do lists.utility[#lists.utility+1]={kind="spell",id=id,enabled=true} end
    for _,slot in ipairs({13,14}) do lists.utility[#lists.utility+1]={kind="slot",id=slot,enabled=true} end
    for i=1,math.min(3,#lists.buffs) do local e=lists.buffs[i]; lists.tracking[i]={kind="aura",id=e.id,unit="player",filter="HELPFUL",enabled=true} end
    return lists
end
