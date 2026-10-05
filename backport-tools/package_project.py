"""Save the current project and only explicitly selected test references."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
import json

root=Path(__file__).resolve().parents[1]
manifest=json.loads((root/'ELLESMEREUI_335_CURRENT_BUILD.json').read_text(encoding='utf-8-sig'))
bundle=next(a['file'] for a in manifest['archives'] if '-HUD-test-' in a['file'])
build=bundle.removeprefix('EllesmereUI-3.3.5-HUD-test-').removesuffix('.zip')
output=root/f'EllesmereUI-3.3.5-project-{build}.zip'
selected={}
def add(path):
    assert path.is_file(),path
    name=path.relative_to(root).as_posix()
    assert path.resolve().is_relative_to(root.resolve()),path
    selected[name]=path

for folder in list(manifest['versions'])+['backport-tools','.codex-tools','ElvUI/Libraries/LibAuraInfo-1.0']:
    for path in sorted((root/folder).rglob('*')):
        if path.is_file() and '__pycache__' not in path.parts and path.suffix!='.pyc': add(path)
add(root/'ElvUI/Media/Textures/normTex2.tga')
for name in ['ELLESMEREUI_335_CURRENT_BUILD.json','CODEX_HANDOFF_EllesmereUI_335_CURRENT.md','ELLESMEREUI_335_BACKPORT_STATUS.md','ELLESMEREUI_PROJECT_PACK.md']:
    add(root/name)
for archive in manifest['archives']:
    path=root/archive['file']
    assert path.stat().st_size==archive['bytes'] and hashlib.sha256(path.read_bytes()).hexdigest()==archive['sha256'],path
    add(path)
with ZipFile(output,'w',ZIP_DEFLATED,compresslevel=6) as z:
    for name,path in sorted(selected.items()): z.write(path,name)
with ZipFile(output) as z:
    assert z.testzip() is None
    assert set(z.namelist())==set(selected)
    for name,path in selected.items(): assert z.read(name)==path.read_bytes(),name
digest=hashlib.sha256(output.read_bytes()).hexdigest()
output.with_suffix('.zip.sha256').write_text(f'{digest}  {output.name}\n',encoding='utf-8')
print(f'PASS: {output.name}; {output.stat().st_size:,} bytes; {len(selected)} members verified byte for byte; SHA-256 saved.')
