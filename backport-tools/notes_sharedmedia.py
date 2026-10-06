"""One-off: TOC bumps, README entries, patch notes and the handoff version line for
SharedMedia fonts, bar textures and sounds (Core 0.55 and nine modules)."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent

# folder: (toc old, toc new, patch-note old, patch-note new, README lines, feature)
MODULES = {
    'EllesmereUI': ('3.3.5-core-0.54', '3.3.5-core-0.55', 'Core 0.54', 'Core 0.55', [
        '0.55: SharedMedia completo. Fontes, texturas de barra e sons registrados na',
        'LibSharedMedia-3.0 por outros addons aparecem nos menus do EUI, inclusive os',
        'registrados depois do login (callback `LibSharedMedia_Registered` para sons,',
        'como já existia para texturas). Novos `EllesmereUI.ResolveSoundPath` (chave',
        '`sm:` -> arquivo via `LSM:Fetch`) e `EllesmereUI.GetAlertSoundCatalogue`',
        '(lista única de sons do EUI + SharedMedia, montada uma vez). A Party Mode',
        'toca sons `sm:` registrados tarde.',
    ], None),
    'EllesmereUIArena': ('9.3.4-335-0.2', '9.3.4-335-0.3', 'Arena 0.2', 'Arena 0.3', [
        'Bar Texture lista as texturas da LibSharedMedia (SharedMedia e outros',
        'addons) e as resolve em jogo.',
    ], ('SharedMedia Bar Textures', 'Bar Texture lists textures from SharedMedia and other addons using LibSharedMedia',
        'Nav("EllesmereUIArena", "Arena Frames")')),
    'EllesmereUIAuraBuffReminders': ('9.3.4-335-0.3', '9.3.4-335-0.4', 'Aura Buff Reminders 0.3', 'Aura Buff Reminders 0.4', [
        '0.4: os sons dos lembretes incluem os sons da LibSharedMedia, inclusive os',
        'registrados depois do login, e chaves `sm:` tocam via `ResolveSoundPath`.',
    ], ('SharedMedia Sounds', 'Reminder sounds include SharedMedia sounds, even from packs that load later', None)),
    'EllesmereUICooldownManager': ('9.3.4-335-0.2', '9.3.4-335-0.3', 'Cooldown Manager 0.2', 'Cooldown Manager 0.3', [
        '0.3: texturas das Tracking Bars incluem a LibSharedMedia. O Cast Sound da',
        'barra FocusKick mantém os 5 sons da Blizzard (`PlaySound`) e agora lista os',
        'sons do EUI e da SharedMedia, tocados com `PlaySoundFile`.',
    ], ('SharedMedia Textures and Sounds', 'Tracking bar textures include SharedMedia, and the FocusKick Cast Sound adds EllesmereUI and SharedMedia sounds to the Blizzard ones', None)),
    'EllesmereUIDamageMeters': ('9.3.4-335-0.6', '9.3.4-335-0.7', 'Damage Meters 0.6', 'Damage Meters 0.7', [
        '0.7: a textura das barras aceita chaves `sm:` (formato do resto do EUI)',
        'além de `lsm:`, então perfis com texturas da SharedMedia carregam certo.',
    ], ('SharedMedia Bar Textures', 'SharedMedia bar textures load whether a profile stores them in Damage Meters or EllesmereUI format',
        'Nav("EllesmereUIDamageMeters", "Windows")')),
    'EllesmereUINameplates': ('9.3.4-335-0.13', '9.3.4-335-0.14', 'Nameplates 0.13', 'Nameplates 0.14', [
        '0.14: texturas de vida e de cast bar incluem a LibSharedMedia e chaves',
        '`sm:` são resolvidas em jogo.',
    ], ('SharedMedia Bar Textures', 'Health and cast bar textures include textures from SharedMedia and other addons', None)),
    'EllesmereUIOptions': ('9.3.4-335-0.93', '9.3.4-335-0.94', 'Options 0.93', 'Options 0.94', [
        '0.94: no Textures, o bloco Damage Meters leva à Bar Texture de cada janela.',
        'O Cast Sound do FocusKick e os sons do Chat usam a lista compartilhada de',
        'sons (EUI + SharedMedia). A prévia dos indicadores de aura mostra texturas',
        '`sm:` da Raid Frames.',
    ], ('SharedMedia in Sound Menus', 'The FocusKick Cast Sound and the Chat sounds list EllesmereUI and SharedMedia sounds, and the Textures page links Damage Meters to its per-window Bar Texture', None)),
    'EllesmereUIQoL': ('9.3.4-335-0.11', '9.3.4-335-0.12', 'Quality of Life 0.11', 'Quality of Life 0.12', [
        '0.12: sons de alerta tocam chaves `sm:` de pacotes SharedMedia carregados',
        'depois do QoL.',
    ], ('SharedMedia Sounds', 'Alert sounds from SharedMedia packs that load after Quality of Life play too', None)),
    'EllesmereUIRaidFrames': ('9.3.4-335-0.12', '9.3.4-335-0.13', 'Raid Frames 0.12', 'Raid Frames 0.13', [
        '0.13: a textura de vida lista a LibSharedMedia e as resolve nos quadros e',
        'na prévia dos indicadores de aura.',
    ], ('SharedMedia Bar Textures', 'Health Bar Texture lists textures from SharedMedia and other addons, also in the aura indicator preview', None)),
    'EllesmereUIResourceBars': ('9.3.4-335-0.3', '9.3.4-335-0.4', 'Resource Bars 0.3', 'Resource Bars 0.4', [
        '0.4: as texturas das barras incluem a LibSharedMedia e chaves `sm:` são',
        'resolvidas em jogo.',
    ], ('SharedMedia Bar Textures', 'Bar textures include textures from SharedMedia and other addons', None)),
}
CORE_HERO = ('SharedMedia Fonts, Textures and Sounds',
             'Fonts, bar textures and sounds that other addons register with LibSharedMedia appear in the EllesmereUI menus, including ones registered after login.')


def split(path):
    data = path.read_bytes().decode('utf-8')
    eol = '\r\n' if '\r\n' in data else '\n'
    return data, eol


for folder, (toc_old, toc_new, _, note_new, readme, _) in MODULES.items():
    toc = ROOT / folder / f'{folder}.toc'
    raw = toc.read_bytes()
    old, new = f'## Version: {toc_old}'.encode(), f'## Version: {toc_new}'.encode()
    if new not in raw:
        assert raw.count(old) == 1, toc
        toc.write_bytes(raw.replace(old, new))

    path = ROOT / folder / 'README-335.md'
    data, eol = split(path)
    lines = data.split(eol)
    if readme[0] in lines:
        continue
    short_old, short_new = toc_old.rsplit('-', 1)[1], toc_new.rsplit('-', 1)[1]
    if folder == 'EllesmereUIArena':
        at = next(i for i, l in enumerate(lines) if l.startswith('## '))
        lines[at:at] = [f'## {toc_new}', ''] + readme + ['']
    else:
        if folder == 'EllesmereUIResourceBars':
            short_old = '0.1'
        assert lines[0].endswith(short_old), lines[0]
        lines[0] = lines[0][:-len(short_old)] + short_new
        lines[2:2] = readme + ['']
    path.write_bytes(eol.join(lines).encode('utf-8'))

notes = ROOT / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
data, eol = split(notes)
if 'Core 0.55' not in data:
    for folder, (_, _, note_old, note_new, _, feature) in MODULES.items():
        head = f'        version = "{note_old}",'
        assert data.count(head) == 1, head
        start = data.index(head)
        end = data.find(eol + '    },' + eol + '    {' + eol + '        version', start)
        end = len(data) if end < 0 else end
        block = data[start:end].replace(head, f'        version = "{note_new}",', 1)
        if feature:
            title, desc, nav = feature
            key = 'features'
            item = ['            {']
            if folder == 'EllesmereUIOptions':
                item.append('                module = "SharedMedia",')
                item += [f'                title  = "{title}",', f'                desc   = "{desc}",']
            else:
                item += [f'                title = "{title}",', f'                desc  = "{desc}",']
                if nav:
                    item.append(f'                nav   = {nav},')
            item.append('            },')
            anchor = f'        {key} = {{' + eol
        else:
            title, desc = CORE_HERO
            item = ['            {', f'                title = "{title}",', f'                desc  = "{desc}",', '            },']
            anchor = '        heroes = {' + eol
        assert anchor in block, (folder, anchor)
        block = block.replace(anchor, anchor + eol.join(item) + eol, 1)
        data = data[:start] + block + data[end:]
    notes.write_bytes(data.encode('utf-8'))

handoff = ROOT / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'
text, eol = split(handoff)
for old, new in [('Core 0.54;', 'Core 0.55;'), ('Arena 0.2;', 'Arena 0.3;'), ('AuraBuff Reminders 0.3;', 'AuraBuff Reminders 0.4;'),
                 ('Cooldown Manager 0.2;', 'Cooldown Manager 0.3;'), ('Damage Meters 0.6;', 'Damage Meters 0.7;'),
                 ('Nameplates 0.13;', 'Nameplates 0.14;'), ('Options 0.93;', 'Options 0.94;'), ('QoL 0.11;', 'QoL 0.12;'),
                 ('Raid Frames 0.12;', 'Raid Frames 0.13;'), ('Resource Bars 0.3;', 'Resource Bars 0.4;')]:
    if new not in text:
        assert text.count(old) == 1, old
        text = text.replace(old, new)
handoff.write_bytes(text.encode('utf-8'))
print('SharedMedia notes written')
