"""Refresh the unloaded Retail reference copies in the project from the Retail install.

The project keeps Retail files next to the Wrath port so validators can compare
against Retail. A Retail file is only refreshed when no port TOC (or XML it
includes) loads the project copy; loaded files are port code and are listed for
review instead. EllesmereUILocales is skipped (catalogs are trimmed and extended;
see build_locale_additions.py).

Usage: python sync_retail_references.py          (dry run, prints the plan)
       python sync_retail_references.py --apply  (backs up, then copies)
"""
import argparse
import datetime
import pathlib
import re
import shutil

ROOT = pathlib.Path(__file__).resolve().parent.parent
RETAIL = pathlib.Path('D:/World of Warcraft/_retail_/Interface/AddOns')
SKIP_FOLDERS = {'EllesmereUILocales'}
SKIP_SUFFIX = {'.toc'}
# The client loads Bindings.xml without a TOC entry, so it is always port code.
SKIP_NAMES = {'bindings.xml'}
XML_FILE = re.compile(r'file\s*=\s*"([^"]+)"', re.I)


def loaded_files():
    """Project files loaded by any port TOC, following XML includes."""
    loaded = set()

    def walk(path):
        path = path.resolve()
        if path in loaded or not path.exists():
            return
        loaded.add(path)
        if path.suffix.lower() == '.xml':
            text = path.read_text(encoding='utf-8-sig', errors='replace')
            for ref in XML_FILE.findall(text):
                walk(path.parent / ref.replace('\\', '/'))

    for toc in ROOT.glob('EllesmereUI*/*.toc'):
        for line in toc.read_text(encoding='utf-8-sig', errors='replace').splitlines():
            line = line.strip()
            if line and not line.startswith('#'):
                walk(toc.parent / line.replace('\\', '/'))
    return loaded


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    args = ap.parse_args()
    loaded = loaded_files()
    update, add, port_loaded = [], [], []
    for folder in sorted(RETAIL.glob('Ellesmere*')):
        if not folder.is_dir() or folder.name in SKIP_FOLDERS or not (ROOT / folder.name).is_dir():
            continue
        for src in sorted(folder.rglob('*')):
            if not src.is_file() or src.suffix.lower() in SKIP_SUFFIX or src.name.lower() in SKIP_NAMES:
                continue
            rel = src.relative_to(RETAIL)
            dst = ROOT / rel
            if dst.exists() and dst.read_bytes() == src.read_bytes():
                continue
            if dst.resolve() in loaded:
                port_loaded.append(rel)
            elif dst.exists():
                update.append(rel)
            else:
                add.append(rel)
    size = sum((RETAIL / r).stat().st_size for r in update + add)
    print('refresh %d unloaded references, add %d new Retail files (%.1f MB)' % (len(update), len(add), size / 1048576))
    print('loaded by the port, left unchanged (%d):' % len(port_loaded))
    for r in port_loaded:
        print('   ', r)
    if not args.apply:
        print('dry run; pass --apply to copy')
        return
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    backup = ROOT / '.codex-backups' / ('retail-references-before-sync-' + stamp)
    for r in update:
        target = backup / r
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / r, target)
    for r in update + add:
        target = ROOT / r
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(RETAIL / r, target)
    print('backup:', backup)


if __name__ == '__main__':
    main()
