"""Read-only: list files changed or added in the working tree (git status) that a
port TOC loads, directly or through XML includes. Those must never be Retail copies."""
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent
GIT = r'C:\Program Files\Git\cmd\git.exe'


def loaded_files():
    out = set()
    for toc in ROOT.glob('EllesmereUI*/*.toc'):
        folder = toc.parent
        queue = []
        for line in toc.read_text(encoding='utf-8-sig', errors='replace').splitlines():
            line = line.strip()
            if line and not line.startswith('#'):
                queue.append(folder / line.replace('\\', '/'))
        while queue:
            path = queue.pop()
            key = path.resolve()
            if key in out or not path.exists():
                continue
            out.add(key)
            if path.suffix.lower() == '.xml':
                text = path.read_text(encoding='utf-8-sig', errors='replace')
                for ref in re.findall(r'file\s*=\s*"([^"]+)"', text):
                    queue.append(path.parent / ref.replace('\\', '/'))
    return out


if __name__ == '__main__':
    status = subprocess.run([GIT, '-C', str(ROOT), 'status', '--porcelain', '-uall'],
                            capture_output=True, text=True, check=True).stdout.splitlines()
    loaded = loaded_files()
    print('changed/added files that are loaded:')
    for line in status:
        if (ROOT / line[3:].strip().strip('"')).resolve() in loaded:
            print('  ', line)
