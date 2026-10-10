"""List game-setting writes (CVars, key bindings, chat window fonts) in the Lua files
the EllesmereUI TOCs load, for the Uninstall EUI audit."""
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent
pattern = re.compile(r'\b(SetCVar|SetBinding\w*|SetOverrideBinding\w*|SaveBindings|FCF_SetChatWindowFontSize|SetChatWindowSize|ConsoleExec)\s*\(')
for toc in sorted(root.glob('EllesmereUI*/*.toc')):
    folder = toc.parent
    for line in toc.read_text(encoding='utf-8-sig').splitlines():
        name = line.strip()
        if not name or name.startswith('#') or not name.lower().endswith('.lua'):
            continue
        path = folder / name.replace('\\', '/')
        if not path.exists():
            continue
        for i, text in enumerate(path.read_text(encoding='utf-8-sig', errors='replace').splitlines(), 1):
            if pattern.search(text):
                print(f'{path.relative_to(root)}:{i}: {text.strip()[:170]}')
