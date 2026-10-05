from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import struct

root = Path(__file__).resolve().parents[1]
versions = {'EllesmereUI':'3.3.5-core-0.28','EllesmereUIOptions':'9.3.4-335-0.43','EllesmereUIUnitFrames':'9.3.4-335-0.8','EllesmereUIMinimap':'9.3.4-335-0.3','EllesmereUIActionBars':'9.3.4-335-0.12','EllesmereUIChat':'9.3.4-335-0.3','EllesmereUINameplates':'9.3.4-335-0.6','EllesmereUIBlizzardSkin':'9.3.4-335-0.7','EllesmereUIBags':'9.3.4-335-0.7','EllesmereUIResourceBars':'9.3.4-335-0.2','EllesmereUIQoL':'9.3.4-335-0.2','EllesmereUIRaidFrames':'9.3.4-335-0.4','EllesmereUIDataBars':'9.3.4-335-0.2','EllesmereUIDamageMeters':'9.3.4-335-0.3','EllesmereUICooldownManager':'9.3.4-335-0.1','EllesmereUIAuraBuffReminders':'9.3.4-335-0.1','EllesmereUIQuickdraw':'9.3.4-335-0.1','EllesmereUIFriends':'9.3.4-335-0.1','EllesmereUIQuestTracker':'9.3.4-335-0.1'}
for folder, version in versions.items():
    toc = (root/folder/(folder+'.toc')).read_text(encoding='utf-8-sig')
    assert '## Interface: 30300' in toc and '## Version: '+version in toc
    for line in toc.splitlines():
        if line.strip() and not line.startswith('#'):
            assert (root/folder/line.replace('\\','/')).is_file(), line
s = (root/'EllesmereUIOptions/EllesmereUIOptions_3.3.5_Compat.lua').read_text(encoding='utf-8-sig')
assert 'frame:SetAutoFocus(false)' in s and 'self:ClearFocus()' in s
assert 'if not C_Spell.GetSpellInfo then' in s
assert 'SetPropagateKeyboardInput' not in s
converted = list((root/'EllesmereUIUnitFrames/Media/Textures_335').glob('*.tga'))
assert len(converted) == 15
for p in converted:
    data = p.read_bytes()
    width, height, depth, flags = struct.unpack('<HHBB', data[12:18])
    assert (width, height, depth, flags) == (256, 64, 32, 8), p.name
    assert len(data) == 18 + width * height * 4

packages = {
    'EllesmereUI-3.3.5-core-0.28.zip':['EllesmereUI'],
    'EllesmereUIUnitFrames-3.3.5-0.8.zip':['EllesmereUIUnitFrames'],
    'EllesmereUIOptions-3.3.5-0.43.zip':['EllesmereUIOptions'],
    'EllesmereUIMinimap-3.3.5-0.3.zip':['EllesmereUIMinimap'],
    'EllesmereUIActionBars-3.3.5-0.12.zip':['EllesmereUIActionBars'],
    'EllesmereUIChat-3.3.5-0.3.zip':['EllesmereUIChat'],
    'EllesmereUINameplates-3.3.5-0.6.zip':['EllesmereUINameplates'],
    'EllesmereUIBlizzardSkin-3.3.5-0.7.zip':['EllesmereUIBlizzardSkin'],
    'EllesmereUIBags-3.3.5-0.7.zip':['EllesmereUIBags'],
    'EllesmereUIResourceBars-3.3.5-0.2.zip':['EllesmereUIResourceBars'],
    'EllesmereUIQoL-3.3.5-0.2.zip':['EllesmereUIQoL'],
    'EllesmereUIRaidFrames-3.3.5-0.4.zip':['EllesmereUIRaidFrames'],
    'EllesmereUIDataBars-3.3.5-0.2.zip':['EllesmereUIDataBars'],
    'EllesmereUIDamageMeters-3.3.5-0.3.zip':['EllesmereUIDamageMeters'],
    'EllesmereUICooldownManager-3.3.5-0.1.zip':['EllesmereUICooldownManager'],
    'EllesmereUIAuraBuffReminders-3.3.5-0.1.zip':['EllesmereUIAuraBuffReminders'],
    'EllesmereUIQuickdraw-3.3.5-0.1.zip':['EllesmereUIQuickdraw'],
    'EllesmereUIFriends-3.3.5-0.1.zip':['EllesmereUIFriends'],
    'EllesmereUIQuestTracker-3.3.5-0.1.zip':['EllesmereUIQuestTracker'],
    'EllesmereUI-3.3.5-HUD-test-0.38.zip':list(versions),
}
for filename, folders in packages.items():
    output=root/filename
    with ZipFile(output,'w',ZIP_DEFLATED) as z:
        for folder in folders:
            for p in sorted((root/folder).rglob('*')):
                if p.is_file(): z.write(p,p.relative_to(root).as_posix())
    with ZipFile(output) as z:
        assert z.testzip() is None
        assert {p.split('/')[0] for p in z.namelist()} == set(folders)
        for folder in folders:
            name=f'{folder}/{folder}.toc'
            assert z.read(name) == (root/name).read_bytes()
        if 'EllesmereUI' in folders:
            for name in ['EllesmereUI/EUI_UnlockMode.lua','EllesmereUI/EUI_OptionsAccess_335.lua','EllesmereUI/EUI_TooltipIDs_335.lua','EllesmereUI/EllesmereUI.lua','EllesmereUI/EllesmereUI_Panel.lua','EllesmereUI/EllesmereUI_UICore.lua']:
                assert z.read(name) == (root/name).read_bytes()
            for folder in ['backgrounds_335', 'icons_335']:
                for p in (root/'EllesmereUI/media'/folder).glob('*.tga'):
                    assert z.read(p.relative_to(root).as_posix()) == p.read_bytes()
        if 'EllesmereUIUnitFrames' in folders:
            for name in ['EllesmereUIUnitFrames/EUI_UnitFrames_335.lua', 'EllesmereUIUnitFrames/EllesmereUIUnitFrames.lua', 'EllesmereUIUnitFrames/EUI_UnitFrames_335_Textures.lua', 'EllesmereUIUnitFrames/Media/elite-badge-335.tga']:
                assert z.read(name) == (root/name).read_bytes()
            for p in (root/'EllesmereUIUnitFrames/Media/Textures_335').glob('*.tga'):
                assert z.read(p.relative_to(root).as_posix()) == p.read_bytes()
        if 'EllesmereUIOptions' in folders:
            for name in ['EllesmereUIOptions/EllesmereUI_Widgets.lua', 'EllesmereUIOptions/EUI_UnitFrames_Options.lua', 'EllesmereUIOptions/EUI_Minimap_335_Options.lua', 'EllesmereUIOptions/EUI_ActionBars_335_Options.lua', 'EllesmereUIOptions/EUI_Chat_335_Options.lua', 'EllesmereUIOptions/EUI_Fonts_Options.lua', 'EllesmereUIOptions/EUI_Textures_Options.lua', 'EllesmereUIOptions/EUI_Style_Options.lua']:
                assert z.read(name) == (root/name).read_bytes()
        if 'EllesmereUIMinimap' in folders:
            name='EllesmereUIMinimap/EUI_Minimap_335.lua'
            assert z.read(name) == (root/name).read_bytes()
        if 'EllesmereUIActionBars' in folders:
            for name in ['EllesmereUIActionBars/EUI_ActionBars_335.lua', 'EllesmereUIActionBars/EUI_NativeHUD_335.lua', 'EllesmereUIActionBars/Libs/LibActionButton-1.0-335.lua', 'EllesmereUIActionBars/Bindings.xml', 'EllesmereUIActionBars/Media/Textures_335/elvui-norm.tga']:
                assert z.read(name) == (root/name).read_bytes()
        if 'EllesmereUIChat' in folders:
            name='EllesmereUIChat/EUI_Chat_335.lua'
            assert z.read(name) == (root/name).read_bytes()
        if 'EllesmereUINameplates' in folders:
            name='EllesmereUINameplates/EUI_Nameplates_335.lua'
            assert z.read(name) == (root/name).read_bytes()
        if 'EllesmereUIOptions' in folders:
            name='EllesmereUIOptions/EUI_Nameplates_335_Options.lua'
            assert z.read(name) == (root/name).read_bytes()
            name='EllesmereUIOptions/EUI_BlizzardSkin_335_Options.lua'
            assert z.read(name) == (root/name).read_bytes()
        if 'EllesmereUIBlizzardSkin' in folders:
            for name in ['EllesmereUIBlizzardSkin/EUI_BlizzardSkin_335.lua','EllesmereUIBlizzardSkin/EUI_CharacterSheet_335.lua']:
                assert z.read(name) == (root/name).read_bytes()
    print(f'PASS: {output.name}; {output.stat().st_size:,} bytes; folder names, TOCs and ZIP integrity verified')
