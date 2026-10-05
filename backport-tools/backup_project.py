"""Dated working-tree backup of the EllesmereUI 3.3.5 backport.

Writes two archives next to the addons, each verified byte for byte with a SHA-256 file:
  EllesmereUI-3.3.5-HUD-backup-<stamp>.zip      installable EllesmereUI* addon folders
  EllesmereUI-3.3.5-project-backup-<stamp>.zip  the same plus tools, docs and patched extras
and records every addon version in .codex-backups/EllesmereUI-backup-<stamp>.json.
Existing archives are never overwritten.
"""
from datetime import datetime, timezone
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
import json
import re

root = Path(__file__).resolve().parents[1]
stamp = datetime.now().strftime('%Y%m%d-%H%M')
addons = sorted(p for p in root.glob('EllesmereUI*') if p.is_dir() and (p / f'{p.name}.toc').is_file())
extras = ['backport-tools', '.codex-tools', 'Bistooltip']
docs = ['ELLESMEREUI_335_CURRENT_BUILD.json', 'CODEX_HANDOFF_EllesmereUI_335_CURRENT.md',
        'ELLESMEREUI_335_BACKPORT_STATUS.md', 'ELLESMEREUI_PROJECT_PACK.md']


def files(folder):
    for path in sorted(folder.rglob('*')):
        if path.is_file() and '__pycache__' not in path.parts and path.suffix != '.pyc':
            yield path.relative_to(root).as_posix(), path


def write(output, members):
    assert not output.exists(), f'{output.name} already exists'
    with ZipFile(output, 'w', ZIP_DEFLATED, compresslevel=6) as z:
        for name, path in sorted(members.items()):
            z.write(path, name)
    with ZipFile(output) as z:
        assert z.testzip() is None
        assert set(z.namelist()) == set(members)
        for name, path in members.items():
            assert z.read(name) == path.read_bytes(), name
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix('.zip.sha256').write_text(f'{digest}  {output.name}\n', encoding='utf-8')
    print(f'PASS: {output.name}; {output.stat().st_size:,} bytes; {len(members)} files verified; SHA-256 saved.')


hud = {name: path for folder in addons for name, path in files(folder)}
project = dict(hud)
for folder in extras:
    if (root / folder).is_dir():
        project.update(files(root / folder))
for name in docs:
    if (root / name).is_file():
        project[name] = root / name

hud_zip = root / f'EllesmereUI-3.3.5-HUD-backup-{stamp}.zip'
project_zip = root / f'EllesmereUI-3.3.5-project-backup-{stamp}.zip'
write(hud_zip, hud)
write(project_zip, project)

versions = {}
for folder in addons:
    match = re.search(r'^## Version:\s*(.+)$', (folder / f'{folder.name}.toc').read_text(encoding='utf-8-sig'), re.M)
    versions[folder.name] = match.group(1).strip() if match else None
note = root / '.codex-backups' / f'EllesmereUI-backup-{stamp}.json'
note.parent.mkdir(exist_ok=True)
note.write_text(json.dumps({
    'created_at_utc': datetime.now(timezone.utc).isoformat(),
    'kind': 'working-tree backup (not official checkpoint)',
    'hud_zip': hud_zip.name,
    'project_zip': project_zip.name,
    'extras': [f for f in extras if (root / f).is_dir()],
    'versions': versions,
}, indent=2) + '\n', encoding='utf-8')
print(f'Versions recorded in {note.relative_to(root)}')
