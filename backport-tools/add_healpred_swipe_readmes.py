"""One-off: README entries for UF 0.20 (heal prediction), CDM 0.8 and Core 0.62 (texture swipe)."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
ENTRIES = {
    'EllesmereUI': ('0.61', '0.62', [
        '0.62: `EllesmereUI_TextureSwipe_335.lua` (arquivo novo, reinicie o cliente):',
        '`EllesmereUI.CreateTextureSwipe(parent)` desenha o giro do cooldown com',
        'texturas (quatro ScrollFrames recortam os quartos; a cunha gira por uma',
        'animação Rotation de duração zero com texcoords compensados). Aceita forma',
        '(`SetArt`) e cor (`SetTint`); `Start(start, duração, reverso)`/`Stop()`.',
        'Ideia tirada do !!!ClassicAPI, código próprio.',
        '',
    ]),
    'EllesmereUIUnitFrames': ('0.19', '0.20', [
        '0.20: Heal Prediction funciona no 3.3.5 (player, target e focus). O elemento',
        'do Retail depende de APIs que o Wrath não tem; `EUI_UnitFrames_335_HealPred.lua`',
        '(arquivo novo, reinicie o cliente) desenha seus heals e os dos outros depois',
        'da barra de vida, com as chaves do Retail (cor, outra cor, opacidade, textura,',
        'Overheal). Valores do LibHealComm-4.0, agora embutido também aqui (o LibStub',
        'mantém uma cópia só com o Raid Frames).',
        '',
    ]),
    'EllesmereUICooldownManager': ('0.7', '0.8', [
        '0.8: novo "Swipe Style" nas barras: Native (o giro quadrado do cliente) ou',
        'Shaped (o giro de textura do Core 0.62), que segue ícones redondos e usa a',
        '"Swipe Color". "Cooldown Edge" fica só para o Native.',
        '',
    ]),
}
for folder, (old, new, lines) in ENTRIES.items():
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
