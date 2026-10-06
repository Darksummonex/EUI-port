"""One-off: README-335 entries for the per-element text outline release."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENTRIES = {
    'EllesmereUI': ('0.49', '0.50', """0.50: novo helper `EllesmereUI.ApplyTextOutline` (EllesmereUI_Fonts.lua) para
contorno por elemento de texto: Module Default, None, Outline, Thick Outline ou
Shadow. "Module Default" mantém o contorno do módulo (página Fonts); os outros
valem só para aquele texto. A sombra usa o mesmo FontObject do modo Drop Shadow
e a cor pintada do texto é preservada ao trocar o modo. Usado por Nameplates
0.13, Unit Frames 0.11 e QoL 0.10. Teste: backport-tools/validate_text_outline.py."""),
    'EllesmereUINameplates': ('0.12', '0.13', """0.13: cada texto da placa ganhou o menu "Outline" (Module Default, None,
Outline, Thick Outline, Shadow) logo abaixo do Size na sua engrenagem: nome
(e combinações de nome/nível), Level, Target of Target, textos de vida, Spell
Name, Cast Timer e Friendly Names. Aura Stacks e Debuff Duration (GENERAL TEXT)
ganharam uma engrenagem só com o contorno. Padrão: Module Default, então nada
muda até você escolher (requer Core 0.50)."""),
    'EllesmereUIUnitFrames': ('0.10', '0.11', """0.11: contorno por texto. As engrenagens de Left, Right, Center e Extra Text
(nome, vida, power, etc.), dos três textos da Bottom Text Bar e do Power
Percent ganharam o menu "Outline" (Module Default, None, Outline, Thick
Outline, Shadow) logo abaixo do Size, também nos frames menores. Vale ao vivo e
na prévia das opções. Padrão: Module Default (requer Core 0.50 e Options 0.86)."""),
    'EllesmereUIQoL': ('0.9', '0.10', """0.10: Displays > ZONE TEXT ganhou "Zone Text Outline" ao lado de "Move Zone
Text": Blizzard Default, None, Outline, Thick Outline ou Shadow, aplicado aos
textos de zona, subzona e status PvP mostrados ao entrar numa área. Blizzard
Default restaura a fonte original do jogo (requer Core 0.50)."""),
    'EllesmereUIOptions': ('0.85', '0.86', """0.86: menus "Outline" por texto nas engrenagens de Nameplates e Unit Frames e
"Zone Text Outline" em QoL > Displays. A prévia de Unit Frames mostra o
contorno escolhido em cada texto (requer Core 0.50)."""),
}

for module, (old, new, entry) in ENTRIES.items():
    path = ROOT / module / 'README-335.md'
    data = path.read_bytes().decode('utf-8')
    eol = '\r\n' if '\r\n' in data else '\n'
    lines = data.split(eol)
    if lines[0].endswith(' ' + new):
        print(f'{module}: already {new}')
        continue
    assert lines[0].endswith(' ' + old), (module, lines[0])
    lines[0] = lines[0][:-len(old)] + new
    assert lines[1] == '', module
    lines[2:2] = entry.split('\n') + ['']
    path.write_bytes(eol.join(lines).encode('utf-8'))
    print(f'{module}: {old} -> {new}')
