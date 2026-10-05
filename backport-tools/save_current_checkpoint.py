"""Verify the packaged sources and save a manifest; never delete files."""
import ast
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
from zipfile import ZipFile

root = Path(__file__).resolve().parents[1]
tree = ast.parse((root / 'backport-tools/package_unitframes.py').read_text(encoding='utf-8-sig'))
assignments = {node.targets[0].id: node.value for node in tree.body
               if isinstance(node, ast.Assign) and isinstance(node.targets[0], ast.Name)}
versions = ast.literal_eval(assignments['versions'])
packages = {}
for key, value in zip(assignments['packages'].keys, assignments['packages'].values):
    if isinstance(value, ast.Call):
        assert isinstance(value.func, ast.Name) and value.func.id == 'list'
        assert len(value.args) == 1 and isinstance(value.args[0], ast.Name) and value.args[0].id == 'versions'
        folders = list(versions)
    else:
        folders = ast.literal_eval(value)
    packages[ast.literal_eval(key)] = folders

records = []
for name, folders in packages.items():
    archive = root / name
    assert archive.resolve().parent == root.resolve()
    with ZipFile(archive) as z:
        assert z.testzip() is None, name
        expected = {p.relative_to(root).as_posix(): p for folder in folders
                    for p in (root / folder).rglob('*') if p.is_file()}
        assert set(z.namelist()) == set(expected), name
        for member, source in expected.items():
            assert z.read(member) == source.read_bytes(), (name, member)
    records.append({'file': name, 'bytes': archive.stat().st_size,
                    'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(), 'addons': folders})

notes = []
for name in ['ELLESMEREUI_335_BACKPORT_STATUS.md', 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md']:
    path = root / name
    notes.append({'file': name, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
manifest = {'verified_at_utc': datetime.now(timezone.utc).isoformat(),
            'workspace': root.as_posix(), 'versions': versions, 'archives': records, 'notes': notes,
            'verification': 'Every archive member matches the installed addon source byte for byte; ZIP CRCs passed.'}
(root / 'ELLESMEREUI_335_CURRENT_BUILD.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
print(f'PASS: {len(records)} current archives match all installed addon files; SHA-256 manifest saved.')
