"""Read-only: print TOC-loaded EUI lines that call SetClipsChildren,
CreateMaskTexture, SetAtlas with an else fallback, or EditBox Enable/Disable/IsEnabled."""
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from check_loaded_changes import loaded_files  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
PATTERNS = {
    'clip': re.compile(r'SetClipsChildren'),
    'mask': re.compile(r':CreateMaskTexture\('),
    'atlas-else': re.compile(r'SetAtlas.*\belse\b'),
    'editbox': re.compile(r'(?i)(edit|box|eb|input)\w*:(Enable|Disable|IsEnabled)\('),
}
want = sys.argv[1:] or list(PATTERNS)
for path in sorted(loaded_files()):
    if path.suffix.lower() != '.lua':
        continue
    rel = path.relative_to(ROOT)
    for no, line in enumerate(path.read_text(encoding='utf-8-sig', errors='replace').splitlines(), 1):
        for key in want:
            if PATTERNS[key].search(line):
                print('%-10s %s:%d: %s' % (key, rel, no, line.strip()[:150]))
