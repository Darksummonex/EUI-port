"""One-off: "Sem bump" README notes (line 3) for the !!!ClassicAPI compatibility fix."""
import pathlib

root = pathlib.Path(__file__).resolve().parent.parent
NOTES = {
    'EllesmereUI': [
        'Sem bump: compatível com o addon !!!ClassicAPI. O SetClipsChildren dele',
        'move o frame para dentro de um ScrollFrame e o CreateMaskTexture retorna nil;',
        'o EUI agora usa `EUI335.SetClipsChildren`/`EUI335.CreateMaskTexture`/',
        '`EUI335.OwnFrame` (por frame, sem mexer nas metatables compartilhadas).',
        'Painel, Unlock Mode e glows animados não chamam mais as versões dele.',
        '',
    ],
    'EllesmereUIOptions': [
        'Sem bump: com o !!!ClassicAPI instalado nenhum dropdown abria (o',
        'SetClipsChildren dele prendia o menu num ScrollFrame vazio). Todo frame',
        'criado por `EllesmereUI.CreateOptionsFrame` passa por `EUI335.OwnFrame`.',
        '',
    ],
    'EllesmereUIUnitFrames': [
        'Sem bump: com o !!!ClassicAPI instalado, barras e retratos eram movidos para',
        'ScrollFrames pelo SetClipsChildren dele. `PatchRegion` agora sempre usa um',
        'SetClipsChildren vazio no próprio frame.',
        '',
    ],
}
for folder, lines in NOTES.items():
    path = root / folder / 'README-335.md'
    raw = path.read_bytes()
    assert not raw.startswith(b'\xef\xbb\xbf'), path
    eol = '\r\n' if b'\r\n' in raw else '\n'
    rows = raw.decode('utf-8').split(eol)
    if not rows[2].startswith(lines[0]):
        rows[2:2] = lines
        path.write_bytes(eol.join(rows).encode('utf-8'))
    print(folder, rows[2])
