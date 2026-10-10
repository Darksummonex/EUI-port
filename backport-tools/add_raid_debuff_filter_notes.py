"""One-off: Raid Debuffs filter modes. Unit Frames 0.22 and Nameplates 0.16 TOC bumps,
README entries (Core note without bump), patch notes and handoff versions."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
NOTES = root / 'EllesmereUIOptions' / 'EUI__General_Options.lua'
HANDOFF = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'


def bump_toc(folder, old, new):
    toc = root / folder / (folder + '.toc')
    raw = toc.read_bytes()
    assert not raw.startswith(b'\xef\xbb\xbf')
    text = raw.decode('utf-8').replace('## Version: 9.3.4-335-' + old, '## Version: 9.3.4-335-' + new, 1)
    assert '## Version: 9.3.4-335-' + new in text, folder
    toc.write_bytes(text.encode('utf-8'))


def readme(folder, old, new, entry):
    path = root / folder / 'README-335.md'
    raw = path.read_bytes()
    eol = '\r\n' if b'\r\n' in raw else '\n'
    rows = raw.decode('utf-8').split(eol)
    if old and rows[0].endswith(old):
        rows[0] = rows[0][:-len(old)] + new
    if new:
        assert rows[0].endswith(new), folder
    if not rows[2].startswith(entry[0]):
        rows[2:2] = entry + ['']
    path.write_bytes(eol.join(rows).encode('utf-8'))


def patch_note(module, old, new, title, desc, nav):
    raw = NOTES.read_bytes()
    eol = '\r\n' if b'\r\n' in raw else '\n'
    text = raw.decode('utf-8')
    old_head = '        version = "%s %s",%s        heroes = {%s' % (module, old, eol, eol)
    new_head = '        version = "%s %s",%s        heroes = {%s' % (module, new, eol, eol)
    item = ('            {' + eol
            + '                title = "%s",' % title + eol
            + '                desc  = "%s",' % desc + eol
            + '                nav   = %s,' % nav + eol
            + '            },' + eol)
    if old_head in text:
        text = text.replace(old_head, new_head + item, 1)
    assert new_head in text, module
    NOTES.write_bytes(text.encode('utf-8'))


def handoff(module, old, new):
    text = HANDOFF.read_bytes().decode('utf-8')
    before = text
    for suffix in (';', ',', '.'):
        a = module + ' ' + old + suffix
        if a in text:
            text = text.replace(a, module + ' ' + new + suffix, 1)
            break
    assert text != before or (module + ' ' + new) in text, module
    HANDOFF.write_bytes(text.encode('utf-8'))


bump_toc('EllesmereUIUnitFrames', '0.21', '0.22')
bump_toc('EllesmereUINameplates', '0.15', '0.16')

readme('EllesmereUIUnitFrames', '0.21', '0.22', [
    '0.22: dois modos novos no Debuff Filter (Aura Filters e o menu de debuffs de cada',
    'frame): "Raid Debuffs" mostra só os debuffs de raid comuns de qualquer um, e "Own',
    'and Raid Debuffs" junta os seus. A lista (Core, EUI_AuraFilters_335.lua) cobre',
    'armadura (Sunder, Expose, Acid Spit, Faerie Fire, Curse of Weakness), dano mágico',
    '(Curse of the Elements, Earth and Moon, Ebon Plague), crítico mágico (Improved',
    'Scorch, Winter\'s Chill, Shadow Mastery), acerto (Misery), crítico recebido (Heart',
    'of the Crusader, Totem of Wrath), dano físico (Blood Frenzy, Savage Combat), bleed',
    '(Mangle, Trauma), AP (Demoralizing Shout/Roar, Vindication), velocidade de ataque',
    '(Thunder Clap, Frost Fever, Infected Wounds, Judgements of the Just), cura recebida',
    '(Mortal Strike, Wound Poison, Aimed Shot, Furious Attacks), conjuração (Curse of',
    'Tongues, Slow, Mind-numbing Poison, Lava Breath), Judgements of Light/Wisdom e',
    'Hunter\'s Mark. Compara pelo nome da magia, então vale qualquer rank. Tracked IDs',
    'continuam somando e Excluded continua escondendo. O Retail usa a flag "important"',
    'da Blizzard, que o Wrath não tem.',
])
readme('EllesmereUINameplates', '0.15', '0.16', [
    '0.16: Debuff Filter (aba Aura Filters) ganhou "Raid Debuffs" e "Own and Raid',
    'Debuffs", com a mesma lista de debuffs de raid dos Unit Frames (Core,',
    'EUI_AuraFilters_335.lua).',
])
readme('EllesmereUI', None, None, [
    'Sem bump: EUI_AuraFilters_335.lua ganhou F.RAID_DEBUFFS e F.IsRaidDebuff(id,',
    'nome) e os modos de debuff "raid"/"raidOwn" (Unit Frames 0.22, Nameplates 0.16).',
    'F.Allow recebe o nome da aura como 7º argumento para casar qualquer rank.',
])

patch_note('Unit Frames', '0.21', '0.22', 'Raid Debuffs Filter',
           "Two new debuff filter modes: Raid Debuffs shows the common raid debuffs from anyone "
           "(armor, spell and physical damage taken, crit taken, attack power, attack and cast speed, "
           "healing taken, Judgements and Hunter's Mark), and Own and Raid Debuffs adds yours.",
           'Nav("EllesmereUIUnitFrames", "Aura Filters")')
patch_note('Nameplates', '0.15', '0.16', 'Raid Debuffs Filter',
           'The Debuff Filter gets Raid Debuffs and Own and Raid Debuffs, with the same raid debuff list as the Unit Frames.',
           'Nav("EllesmereUINameplates", "Aura Filters")')

handoff('Unit Frames', '0.21', '0.22')
handoff('Nameplates', '0.15', '0.16')
print('ok')
