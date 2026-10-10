"""Compare the installed Retail EllesmereUI with the Retail files kept in the project.

Read-only. For every Retail file under EllesmereUI* folders, reports whether the
project has the same path, and if so whether it is identical or how many lines
were added/removed (difflib). Retail-only files are listed too. Writes the report
to %TEMP%/eui_retail_update.txt and per-file unified diffs to
%TEMP%/eui_retail_diffs/<folder>/<file>.diff.

Usage: python compare_retail_update.py
"""
import difflib
import os
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
RETAIL = pathlib.Path('D:/World of Warcraft/_retail_/Interface/AddOns')
TEMP = pathlib.Path(os.environ.get('TEMP', '.'))
OUT = TEMP / 'eui_retail_update.txt'
DIFFS = TEMP / 'eui_retail_diffs'
TEXT = {'.lua', '.toc', '.xml', '.md', '.txt'}


def lines(p):
    return p.read_bytes().decode('utf-8', 'replace').replace('\r\n', '\n').split('\n')


def main():
    report = []
    totals = {'same': 0, 'changed': 0, 'retail_only': 0, 'binary_changed': 0}
    for folder in sorted(RETAIL.glob('Ellesmere*')):
        if not folder.is_dir():
            continue
        rows = []
        for f in sorted(folder.rglob('*')):
            if not f.is_file():
                continue
            rel = f.relative_to(RETAIL)
            mine = ROOT / rel
            if not mine.exists():
                totals['retail_only'] += 1
                rows.append('  NEW-IN-RETAIL  %s (%d bytes)' % (rel, f.stat().st_size))
                continue
            a, b = mine.read_bytes(), f.read_bytes()
            if a == b:
                totals['same'] += 1
                continue
            if f.suffix.lower() not in TEXT:
                totals['binary_changed'] += 1
                rows.append('  BINARY-CHANGED %s' % rel)
                continue
            old, new = lines(mine), lines(f)
            diff = list(difflib.unified_diff(old, new, 'project/' + str(rel), 'retail/' + str(rel), n=2, lineterm=''))
            if not diff:
                totals['same'] += 1
                continue
            add = sum(1 for d in diff if d.startswith('+') and not d.startswith('+++'))
            rem = sum(1 for d in diff if d.startswith('-') and not d.startswith('---'))
            totals['changed'] += 1
            rows.append('  CHANGED        %s  +%d -%d' % (rel, add, rem))
            target = DIFFS / (str(rel) + '.diff')
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text('\n'.join(diff), encoding='utf-8')
        if rows:
            report.append(folder.name)
            report.extend(rows)
    report.append('')
    report.append('Totals: %s' % totals)
    OUT.write_text('\n'.join(report), encoding='utf-8')
    print('\n'.join(report))
    print('report:', OUT)
    print('diffs:', DIFFS)


if __name__ == '__main__':
    main()
