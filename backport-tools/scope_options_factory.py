"""One-time migration: scope template/focus adaptation to loaded EUI options."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
toc=root/'EllesmereUIOptions/EllesmereUIOptions.toc'
binding='local CreateFrame = EllesmereUI.CreateOptionsFrame or CreateFrame\n'
changed=[]
for line in toc.read_text(encoding='utf-8-sig').splitlines():
    line=line.strip()
    if not line or line.startswith('#') or not line.endswith('.lua') or line=='EllesmereUIOptions_3.3.5_Compat.lua': continue
    path=toc.parent/line.replace('\\','/')
    text=path.read_text(encoding='utf-8-sig')
    if 'CreateFrame(' not in text: continue
    if line=='EUI_UnitFrames_Options.lua':
        old='local CreateFrame = ns.Wrath and ns.Wrath.CreateFrame or CreateFrame'
        assert old in text
        text=text.replace(old,'local CreateFrame = ns.Wrath and ns.Wrath.CreateFrame or EllesmereUI.CreateOptionsFrame or CreateFrame',1)
    else:
        assert binding not in text
        text=binding+text
    path.write_text(text,encoding='utf-8'); changed.append(line)
print('PASS: private options factory bound in '+str(len(changed))+' active options files; unloaded Retail references untouched.')
