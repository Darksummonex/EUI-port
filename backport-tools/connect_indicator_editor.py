"""One-time migration: replace the old raid editor with the shared preview editor."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
path=root/'EllesmereUIOptions/EUI_RaidFrames_335_Options.lua'
text=path.read_text(encoding='utf-8-sig')
start=text.index('            if page=="Buffs" or page=="Debuffs" then')
end=text.index('            if page=="Click Casting" then',start)
text=text[:start]+'''            if page=="Buffs" or page=="Debuffs" then
                return E.BuildWrathAuraIndicators("EllesmereUIRaidFrames",page=="Buffs" and "buff" or "debuff",parent,y)
            end
'''+text[end:]
anchor='        onReset=function()'
assert anchor in text
text=text.replace(anchor,'''        getHeaderBuilder=function(page)
            if page=="Buffs" or page=="Debuffs" then return E.WrathAuraIndicatorHeader("EllesmereUIRaidFrames",page=="Buffs" and "buff" or "debuff") end
        end,
        onPageCacheRestore=function(page)
            if page=="Buffs" or page=="Debuffs" then E.UpdateWrathAuraIndicatorPreview("EllesmereUIRaidFrames",page=="Buffs" and "buff" or "debuff") end
        end,
'''+anchor,1)
path.write_text(text,encoding='utf-8')
for filename in ['validate_raidframes.py','validate_unitframes.py']:
    path=root/'backport-tools'/filename; text=path.read_text(encoding='utf-8-sig')
    if filename=='validate_raidframes.py':
        text=text.replace("'EllesmereUI/EUI_AuraFilters_335.lua',","'EllesmereUI/EUI_AuraFilters_335.lua','EllesmereUI/EUI_AuraIndicators_335.lua',")
        text=text.replace("'EllesmereUIOptions/EUI_AuraFilters_335_Options.lua'","'EllesmereUIOptions/EUI_AuraFilters_335_Options.lua','EllesmereUIOptions/EUI_AuraIndicators_335_Options.lua'")
    else:
        text=text.replace("'EUI_AuraFilters_335.lua']","'EUI_AuraFilters_335.lua','EUI_AuraIndicators_335.lua']")
    path.write_text(text,encoding='utf-8')
print('PASS: raid editor connected; regression fixtures load new shared helper.')
