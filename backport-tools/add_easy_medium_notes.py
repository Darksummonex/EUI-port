"""One-off: TOC bumps, README entries and handoff for CDM 0.9 (hide modes, Empty Slot),
UF 0.21 (dispel type icon, focus aura borders) and Blizz UI Enhanced 0.29 (inspect enchant names)."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
ENTRIES = {
    'EllesmereUICooldownManager': ('0.8', '0.9', [
        '0.9: novos Cooldown States do Retail 9.4: "Hide Until Usable" (só aparece',
        'utilizável e fora de cooldown, como Overpower, Revenge, Victory Rush e Execute;',
        'falta de recurso não esconde) e "Hide Outside Form/Stance" (só na forma ou',
        'stance que a magia pede, mesmo em cooldown). Cada um fecha o espaço ou mantém',
        'o lugar (Keep Place). A forma vem da linha "Requires <forma>" do tooltip, que',
        'o cliente pinta de vermelho fora dela; sem essa linha vale a regra do Retail',
        '(usável em forma de caster, inutilizável transformado). Itens sempre aparecem.',
        'Novo "Empty Slot" no menu "+" (e no tipo de Add Entry): reserva uma posição',
        'na barra sem desenhar nada.',
        '',
    ]),
    'EllesmereUIUnitFrames': ('0.20', '0.21', [
        '0.21: "Type Icon Position" no Dispel Overlay do player (como no Retail e no',
        'Raid Frames): o ícone do tipo de debuff dispelável de maior prioridade num',
        'ponto da barra de vida, com tamanho e offsets na engrenagem; funciona mesmo',
        'com o overlay em None. Usa ícones das magias de dispel do Wrath (os do Retail',
        'são atlas). "Only Dispellable by You" saiu da engrenagem e fica ao',
        'lado, valendo para overlay, ícone e bordas. O focus ganhou Border Style,',
        'tamanho e cor das auras, como player e target.',
        '',
    ]),
    'EllesmereUIBlizzardSkin': ('0.28', '0.29', [
        '0.29: encantamentos na janela de Inspect como no Retail e na ficha do',
        'personagem: por padrão um ícone com o nome no hover; com "Show Inspect',
        'Enchant Names Instead of Icons" o nome, com contorno e tingido pela',
        'qualidade do item, limitado a 45% do vão entre as colunas (nome completo no',
        'hover), em tamanho próprio ("Inspect Enchant Name Size").',
        '',
    ]),
}
for folder, (old, new, lines) in ENTRIES.items():
    toc = root / folder / (folder + '.toc')
    raw = toc.read_bytes()
    assert not raw.startswith(b'\xef\xbb\xbf'), toc
    text = raw.decode('utf-8')
    if '## Version: 9.3.4-335-' + old + '\r' in text or '## Version: 9.3.4-335-' + old + '\n' in text:
        text = text.replace('## Version: 9.3.4-335-' + old, '## Version: 9.3.4-335-' + new, 1)
        toc.write_bytes(text.encode('utf-8'))
    assert '## Version: 9.3.4-335-' + new in text, toc

    path = root / folder / 'README-335.md'
    raw = path.read_bytes()
    assert not raw.startswith(b'\xef\xbb\xbf'), path
    eol = '\r\n' if b'\r\n' in raw else '\n'
    rows = raw.decode('utf-8').split(eol)
    if rows[0].endswith(old):
        rows[0] = rows[0][:-len(old)] + new
    assert rows[0].endswith(new), rows[0]
    if not rows[2].startswith(lines[0]):
        rows[2:2] = lines
    path.write_bytes(eol.join(rows).encode('utf-8'))
    print(folder, 'ok')

handoff = root / 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md'
raw = handoff.read_bytes()
eol = '\r\n' if b'\r\n' in raw else '\n'
text = raw.decode('utf-8')
for a, b in (('Blizz UI Enhanced (BlizzardSkin) 0.28', 'Blizz UI Enhanced (BlizzardSkin) 0.29'),
             ('Cooldown Manager 0.8;', 'Cooldown Manager 0.9;'),
             ('Resource Bars 0.5; Unit Frames 0.20.', 'Resource Bars 0.5; Unit Frames 0.21.')):
    text = text.replace(a, b, 1)
old_tail = ('Both add files: a full client restart is needed. The swipe\'s rotation hold and' + eol +
            'ScrollFrame clipping are untested in game.')
new_tail = ('Both add files: a full client restart is needed. Confirmed working in game.' + eol +
            'Retail 9.4 easy-medium batch: Cooldown Manager 0.9 Hide Until Usable / Hide Outside' + eol +
            'Form/Stance (ns.CD_STATE_HIDE; form from the tooltip "Requires <form>" line, red when' + eol +
            'unmet, Retail caster-form fallback) and Empty Slot entries (kind "empty");' + eol +
            'validate_cdm_hide_modes.py. Unit Frames 0.21 player Type Icon Position (dispel icon,' + eol +
            'Wrath spell icons) and focus aura border options. Blizz UI Enhanced 0.29 inspect' + eol +
            'enchant icon/hover or names (inspectEnchantNames, inspectEnchantSize).')
if old_tail in text:
    text = text.replace(old_tail, new_tail, 1)
assert 'Cooldown Manager 0.9;' in text and 'Unit Frames 0.21.' in text and 'BlizzardSkin) 0.29' in text
assert 'easy-medium batch' in text
handoff.write_bytes(text.encode('utf-8'))
print('handoff ok')
