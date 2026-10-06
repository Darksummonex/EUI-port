"""Rewrite the given project files with CRLF line endings (repo files stored as CRLF)."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
for rel in sys.argv[1:]:
    path = ROOT / rel
    data = path.read_bytes()
    fixed = data.replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
    if fixed != data:
        path.write_bytes(fixed)
        print('crlf', rel)
    else:
        print('unchanged', rel)
